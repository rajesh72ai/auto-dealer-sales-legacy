import { useState, useRef, useEffect, useCallback } from 'react';
import {
  X,
  Send,
  Loader2,
  Trash2,
  Bot,
  User,
  ChevronDown,
  Maximize2,
  Minimize2,
  Monitor,
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { sendChatMessage, getProviders } from '@/api/chat';
import type { ChatMessage, ProviderInfo } from '@/api/chat';

interface DisplayMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

type WindowSize = 'compact' | 'expanded' | 'fullscreen';

function ChatWidget() {
  const [isOpen, setIsOpen] = useState(false);
  const [size, setSize] = useState<WindowSize>('compact');
  const [messages, setMessages] = useState<DisplayMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [providers, setProviders] = useState<ProviderInfo[]>([]);
  const [providersLoaded, setProvidersLoaded] = useState(false);
  const [selectedProvider, setSelectedProvider] = useState('');
  const [modelLabel, setModelLabel] = useState('AI Assistant');
  const [cooldown, setCooldown] = useState(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const abortRef = useRef<AbortController | null>(null);
  const cooldownRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Cooldown timer for rate-limited providers (Groq)
  const startCooldown = useCallback((seconds: number) => {
    setCooldown(seconds);
    if (cooldownRef.current) clearInterval(cooldownRef.current);
    cooldownRef.current = setInterval(() => {
      setCooldown((prev) => {
        if (prev <= 1) {
          if (cooldownRef.current) clearInterval(cooldownRef.current);
          cooldownRef.current = null;
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  }, []);

  const cooldownSeconds: Record<string, number> = { groq: 20, mistral: 30 };
  const needsCooldown = selectedProvider in cooldownSeconds;

  // Load available providers on mount. If none are configured (e.g. on the
  // GCP profile where the free-tier providers are intentionally disabled),
  // the widget hides itself completely so users don't see a non-functional
  // chat icon. The AI Agent widget remains visible regardless.
  useEffect(() => {
    const token = sessionStorage.getItem('autosales_token');
    getProviders(token)
      .then((data) => {
        setProviders(data.providers);
        if (data.defaultProvider) {
          setSelectedProvider(data.defaultProvider);
          const def = data.providers.find((p) => p.key === data.defaultProvider);
          if (def) setModelLabel(def.label);
        }
      })
      .finally(() => setProvidersLoaded(true));
  }, []);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, scrollToBottom]);

  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isOpen]);

  const handleProviderChange = useCallback(
    (key: string) => {
      setSelectedProvider(key);
      const p = providers.find((pr) => pr.key === key);
      if (p) setModelLabel(p.label);
      // Clear cooldown when switching providers
      setCooldown(0);
      if (cooldownRef.current) {
        clearInterval(cooldownRef.current);
        cooldownRef.current = null;
      }
    },
    [providers],
  );

  const sendMessage = useCallback(async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed || isLoading || cooldown > 0) return;

    const userMsg: DisplayMessage = {
      role: 'user',
      content: trimmed,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsLoading(true);

    const history: ChatMessage[] = [
      ...messages.map((m) => ({ role: m.role, content: m.content })),
      { role: 'user' as const, content: trimmed },
    ];

    const controller = new AbortController();
    abortRef.current = controller;

    try {
      const assistantMsg: DisplayMessage = {
        role: 'assistant',
        content: '',
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, assistantMsg]);

      const response = await sendChatMessage(history, selectedProvider, controller.signal);
      setMessages((prev) => {
        const updated = [...prev];
        updated[updated.length - 1] = { ...assistantMsg, content: response.reply };
        return updated;
      });
      if (needsCooldown) startCooldown(cooldownSeconds[selectedProvider]);
    } catch (err) {
      if (!(err instanceof DOMException && err.name === 'AbortError')) {
        const errorContent =
          err instanceof Error
            ? `Sorry, I couldn't connect to the AI service. ${err.message}`
            : 'Sorry, something went wrong.';
        setMessages((prev) => [
          ...prev.filter((m) => m.content !== ''),
          {
            role: 'assistant',
            content: errorContent,
            timestamp: new Date(),
          },
        ]);
      }
    } finally {
      setIsLoading(false);
      abortRef.current = null;
    }
  }, [isLoading, cooldown, messages, selectedProvider, needsCooldown, startCooldown, cooldownSeconds]);

  const handleSend = useCallback(() => {
    sendMessage(input);
  }, [input, sendMessage]);

  const handleSuggestion = useCallback((text: string) => {
    setInput(text);
    sendMessage(text);
  }, [sendMessage]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend],
  );

  const handleClear = useCallback(() => {
    if (abortRef.current) abortRef.current.abort();
    setMessages([]);
    setIsLoading(false);
  }, []);

  const handleToggle = useCallback(() => {
    setIsOpen((prev) => !prev);
  }, []);

  const handleCycleSize = useCallback(() => {
    setSize((prev) =>
      prev === 'compact' ? 'expanded' : prev === 'expanded' ? 'fullscreen' : 'compact',
    );
  }, []);

  const sizeClasses: Record<WindowSize, string> = {
    compact: 'right-4 top-16 h-[560px] w-[400px]',
    expanded: 'right-4 top-16 h-[calc(100vh-5rem)] w-[640px] max-w-[calc(100vw-2rem)]',
    fullscreen: 'inset-2 h-[calc(100vh-1rem)] w-[calc(100vw-1rem)]',
  };

  const SizeIcon = size === 'compact' ? Maximize2 : size === 'expanded' ? Monitor : Minimize2;
  const sizeTitle =
    size === 'compact'
      ? 'Expand window'
      : size === 'expanded'
      ? 'Maximize to full screen'
      : 'Shrink to compact';

  // Hide the AI Assistant widget entirely when no chat providers are
  // configured (e.g. GCP profile). Avoids a confusing dead icon in the
  // header. The AI Agent widget is independent and stays visible.
  if (providersLoaded && providers.length === 0) {
    return null;
  }

  return (
    <>
      <button
        onClick={handleToggle}
        className={`flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors ${
          isOpen
            ? 'border-brand-600 bg-brand-600 text-white'
            : 'border-brand-200 bg-brand-50 text-brand-700 hover:border-brand-400 hover:bg-brand-100'
        }`}
        title={
          isOpen
            ? 'Close AI Assistant'
            : 'AI Assistant — fast lookups and simple questions.\nPick a free-tier model (Groq, Gemini, Together, Mistral).\nBest for: "Show deal DL01…", "List vehicles", "Calculate loan".'
        }
      >
        {isOpen ? <X className="h-4 w-4" /> : <Bot className="h-4 w-4" />}
        <span className="hidden sm:inline">AI Assistant</span>
      </button>

      {isOpen && (
        <div
          className={`fixed z-50 flex flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl transition-[width,height] duration-200 ${sizeClasses[size]}`}
        >
          {/* Header */}
          <div className="flex items-center justify-between bg-gradient-to-r from-slate-800 to-slate-700 px-4 py-3">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-500">
                <Bot className="h-4.5 w-4.5 text-white" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">AutoSales AI</h3>
                {/* Provider selector */}
                {providers.length > 1 ? (
                  <div className="relative">
                    <select
                      value={selectedProvider}
                      onChange={(e) => handleProviderChange(e.target.value)}
                      className="appearance-none bg-transparent pr-4 text-[11px] text-slate-300 outline-none cursor-pointer hover:text-white"
                    >
                      {providers.map((p) => (
                        <option key={p.key} value={p.key} className="bg-slate-800 text-white">
                          {p.label}
                        </option>
                      ))}
                    </select>
                    <ChevronDown className="pointer-events-none absolute right-0 top-0.5 h-3 w-3 text-slate-400" />
                  </div>
                ) : (
                  <p className="text-[11px] text-slate-300">{modelLabel}</p>
                )}
              </div>
            </div>
            <div className="flex items-center gap-1">
              <button
                onClick={handleClear}
                className="rounded-lg p-1.5 text-slate-400 transition-colors hover:bg-slate-600 hover:text-white"
                title="Clear conversation"
              >
                <Trash2 className="h-4 w-4" />
              </button>
              <button
                onClick={handleCycleSize}
                className="rounded-lg p-1.5 text-slate-400 transition-colors hover:bg-slate-600 hover:text-white"
                title={sizeTitle}
              >
                <SizeIcon className="h-4 w-4" />
              </button>
              <button
                onClick={handleToggle}
                className="rounded-lg p-1.5 text-slate-400 transition-colors hover:bg-slate-600 hover:text-white"
                title="Close"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Messages Area */}
          <div className="flex-1 overflow-y-auto px-4 py-3">
            {messages.length === 0 && (
              <div className="flex h-full flex-col items-center justify-center text-center">
                <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-brand-50">
                  <Bot className="h-6 w-6 text-brand-600" />
                </div>
                <p className="text-sm font-medium text-gray-700">
                  How can I help you today?
                </p>
                <p className="mt-1 text-xs text-gray-400">
                  Ask about vehicles, deals, inventory, or run calculations
                </p>
              </div>
            )}

            {messages.map((msg, idx) => (
              <div
                key={idx}
                className={`mb-3 flex gap-2.5 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                {msg.role === 'assistant' && (
                  <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-slate-100">
                    <Bot className="h-3.5 w-3.5 text-slate-600" />
                  </div>
                )}
                <div
                  className={`rounded-2xl px-3.5 py-2.5 text-sm leading-relaxed ${
                    msg.role === 'user'
                      ? 'max-w-[80%] rounded-br-md bg-brand-600 text-white'
                      : 'max-w-[95%] rounded-bl-md bg-gray-100 text-gray-800'
                  }`}
                >
                  {msg.role === 'assistant' ? (
                    <div className="overflow-x-auto text-sm [&_h1]:text-sm [&_h1]:font-bold [&_h1]:mb-1 [&_h2]:text-sm [&_h2]:font-bold [&_h2]:mb-1 [&_h3]:text-sm [&_h3]:font-semibold [&_h3]:mb-1 [&_p]:my-1 [&_ul]:my-1 [&_ul]:pl-4 [&_ul]:list-disc [&_ol]:my-1 [&_ol]:pl-4 [&_ol]:list-decimal [&_li]:my-0.5 [&_table]:w-full [&_table]:text-[11px] [&_table]:border-collapse [&_table]:my-2 [&_th]:bg-gray-200 [&_th]:px-2 [&_th]:py-1 [&_th]:text-left [&_th]:font-semibold [&_th]:border [&_th]:border-gray-300 [&_td]:px-2 [&_td]:py-1 [&_td]:border [&_td]:border-gray-200 [&_strong]:font-semibold [&_code]:bg-gray-200 [&_code]:px-1 [&_code]:rounded [&_code]:text-xs">
                      <ReactMarkdown remarkPlugins={[remarkGfm]}>{msg.content}</ReactMarkdown>
                    </div>
                  ) : (
                    <p className="whitespace-pre-wrap">{msg.content}</p>
                  )}
                  <p
                    className={`mt-1 text-[10px] ${
                      msg.role === 'user' ? 'text-brand-200' : 'text-gray-400'
                    }`}
                  >
                    {msg.timestamp.toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
                {msg.role === 'user' && (
                  <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-brand-100">
                    <User className="h-3.5 w-3.5 text-brand-700" />
                  </div>
                )}
              </div>
            ))}

            {isLoading && messages[messages.length - 1]?.content === '' && (
              <div className="mb-3 flex items-center gap-2.5">
                <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-slate-100">
                  <Bot className="h-3.5 w-3.5 text-slate-600" />
                </div>
                <div className="flex items-center gap-2 rounded-2xl rounded-bl-md bg-gray-100 px-3.5 py-2.5">
                  <Loader2 className="h-4 w-4 animate-spin text-gray-500" />
                  <span className="text-sm text-gray-500">Thinking...</span>
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Quick Prompts + Input Area */}
          <div className="border-t border-gray-200 bg-gray-50 px-3 pb-3 pt-2">
            <div className="mb-2 flex flex-wrap gap-1.5">
              {[
                'Show stock summary',
                'List recent deals',
                'Calculate a loan payment',
                'Any low stock alerts?',
                'List all customers',
                'Show warranty claims',
              ].map((suggestion) => (
                <button
                  key={suggestion}
                  onClick={() => handleSuggestion(suggestion)}
                  disabled={isLoading || cooldown > 0}
                  className="rounded-full border border-gray-200 px-2.5 py-1 text-[11px] font-medium text-gray-500 transition-colors hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700 disabled:opacity-40"
                >
                  {suggestion}
                </button>
              ))}
            </div>
            <div className="flex items-center gap-2">
              <input
                ref={inputRef}
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Ask anything..."
                disabled={isLoading}
                className="flex-1 rounded-xl border border-gray-200 bg-white px-3.5 py-2.5 text-sm text-gray-800 placeholder-gray-400 outline-none transition-colors focus:border-brand-400 focus:ring-2 focus:ring-brand-100 disabled:opacity-50"
              />
              <button
                onClick={handleSend}
                disabled={!input.trim() || isLoading || cooldown > 0}
                className="flex h-10 min-w-10 items-center justify-center rounded-xl bg-brand-600 text-white transition-colors hover:bg-brand-700 disabled:opacity-40 disabled:hover:bg-brand-600"
                title={cooldown > 0 ? `Ready in ${cooldown}s` : 'Send message'}
              >
                {isLoading ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : cooldown > 0 ? (
                  <span className="text-xs font-semibold">{cooldown}s</span>
                ) : (
                  <Send className="h-4 w-4" />
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default ChatWidget;
