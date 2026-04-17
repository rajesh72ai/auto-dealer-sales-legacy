import { useState, useRef, useEffect, useCallback } from 'react';
import {
  X,
  Send,
  Loader2,
  Trash2,
  Sparkles,
  User,
  Stethoscope,
  UserCircle,
  TrendingUp,
  Car,
  Sunrise,
  Banknote,
  Shuffle,
  AlertTriangle,
  History,
  Plus,
  Maximize2,
  Minimize2,
  Monitor,
  Download,
  FileText,
  Mail,
  Copy,
  Check,
  ShieldCheck,
  CheckCircle2,
  XCircle,
  Clock,
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import {
  downloadMarkdown,
  downloadPdf,
  emailWithPdfAttachment,
  copyToClipboard,
} from '@/utils/agentExport';
import {
  streamAgentMessage,
  getAgentInfo,
  listConversations,
  getConversation,
  deleteConversation,
} from '@/api/agent';
import type { AgentProposal, ConversationSummary, TurnUsage } from '@/api/agent';
import { confirmProposal, rejectProposal, undoExecutedAction } from '@/api/actions';
import { getMyQuota } from '@/api/agentUsage';
import type { QuotaStatus } from '@/api/agentUsage';

type ProposalStatus = 'pending' | 'executing' | 'executed' | 'cancelled' | 'failed' | 'undoing' | 'undone';

interface DisplayMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  usage?: TurnUsage;
  proposal?: AgentProposal;
  proposalStatus?: ProposalStatus;
  proposalResultMessage?: string;
  proposalError?: string;
  /** Set after EXECUTED for reversible actions — drives the Undo button + countdown. */
  proposalAuditId?: number;
  proposalUndoExpiresAt?: number; // epoch ms
}

interface WorkflowRecipe {
  id: string;
  name: string;
  description: string;
  // Template with {placeholder} tokens. Clicking the card pre-fills the input
  // with this text and auto-selects the first {placeholder} so the user can
  // type their own value (e.g. a specific dealer/customer/deal identifier).
  template: string;
  Icon: React.ComponentType<{ className?: string }>;
  accent: string;
}

const WORKFLOW_RECIPES: WorkflowRecipe[] = [
  {
    id: 'deal-health',
    name: 'Deal Health Check',
    description: 'Inspect a deal for stalls, missing approvals, open recalls.',
    template: 'Run a deal health check on {deal-number}',
    Icon: Stethoscope,
    accent: 'bg-rose-50 text-rose-600 border-rose-200',
  },
  {
    id: 'customer-360',
    name: 'Customer 360',
    description: 'Full view: history, deals, credit freshness, loyalty signals.',
    template: 'Customer 360 for customer {customer-id}',
    Icon: UserCircle,
    accent: 'bg-blue-50 text-blue-600 border-blue-200',
  },
  {
    id: 'morning-briefing',
    name: 'Morning Briefing',
    description: 'Your top priorities for today, ranked and ready.',
    template: 'Morning briefing for {dealer}',
    Icon: Sunrise,
    accent: 'bg-violet-50 text-violet-600 border-violet-200',
  },
  {
    id: 'aging-triage',
    name: 'Inventory Aging Triage',
    description: 'What\u2019s sitting too long, and what it\u2019s costing you.',
    template: 'Inventory aging triage for {dealer}',
    Icon: Car,
    accent: 'bg-amber-50 text-amber-600 border-amber-200',
  },
  {
    id: 'lead-funnel',
    name: 'Lead-to-Deal Funnel',
    description: 'Qualify a lead and recommend next steps.',
    template: 'Qualify lead {lead-id} for a deal',
    Icon: TrendingUp,
    accent: 'bg-teal-50 text-teal-600 border-teal-200',
  },
  {
    id: 'finance-review',
    name: 'Finance Deal Review',
    description: 'APR sanity, payment math, credit-tier fit.',
    template: 'Finance review for deal {deal-number}',
    Icon: Banknote,
    accent: 'bg-emerald-50 text-emerald-600 border-emerald-200',
  },
  {
    id: 'rebalance',
    name: 'Inventory Rebalance',
    description: 'Suggest cross-dealer transfers to match aging stock with demand.',
    template: 'Rebalance inventory across our dealers',
    Icon: Shuffle,
    accent: 'bg-indigo-50 text-indigo-600 border-indigo-200',
  },
  {
    id: 'recall-impact',
    name: 'Recall Impact Report',
    description: 'Live NHTSA recalls cross-referenced against your inventory.',
    template: 'Recall impact report for {dealer}',
    Icon: AlertTriangle,
    accent: 'bg-orange-50 text-orange-600 border-orange-200',
  },
];

const QUICK_SUGGESTIONS = WORKFLOW_RECIPES.slice(0, 5).map((r) => r.template);
const PLACEHOLDER_RE = /\{[a-z0-9-]+\}/i;

type WindowSize = 'compact' | 'expanded' | 'fullscreen';

/** Compact token count display: 1234 → "1.2K", 456789 → "457K", 12345678 → "12.3M". */
function formatShort(n: number): string {
  if (n < 1000) return String(n);
  if (n < 1_000_000) {
    const k = n / 1000;
    return k < 10 ? `${k.toFixed(1)}K` : `${Math.round(k)}K`;
  }
  const m = n / 1_000_000;
  return m < 10 ? `${m.toFixed(1)}M` : `${Math.round(m)}M`;
}

function AgentWidget() {
  const [isOpen, setIsOpen] = useState(false);
  const [size, setSize] = useState<WindowSize>('compact');
  const [messages, setMessages] = useState<DisplayMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [statusText, setStatusText] = useState<string | null>(null);
  const [available, setAvailable] = useState<boolean | null>(null);
  const [modelLabel, setModelLabel] = useState('Claude Sonnet 4.6');
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [showHistory, setShowHistory] = useState(false);
  const [history, setHistory] = useState<ConversationSummary[]>([]);
  const [inputHint, setInputHint] = useState<string | null>(null);
  const [copiedIdx, setCopiedIdx] = useState<number | null>(null);
  const [quota, setQuota] = useState<QuotaStatus | null>(null);
  // Two-click arming for irreversible proposals: holds the message index
  // of the proposal whose Execute button has been clicked once. Cleared on
  // second click (executes) or Cancel click (disarms). No timer — the
  // 5-min backend token TTL is the ultimate stale-proposal safety net,
  // and a visible "Click again to confirm" button cannot be mistaken for
  // a normal Execute even if the user walks away and comes back.
  const [armedIrreversibleIdx, setArmedIrreversibleIdx] = useState<number | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    const token = sessionStorage.getItem('autosales_token');
    getAgentInfo(token).then((info) => {
      if (info) {
        setAvailable(info.available);
        if (info.model) {
          const friendly = info.model.replace('anthropic/', '').replace(/-/g, ' ');
          setModelLabel(friendly.replace(/\b\w/g, (c) => c.toUpperCase()));
        }
      } else {
        setAvailable(false);
      }
    });
    getMyQuota().then(setQuota);
  }, []);

  const refreshQuota = useCallback(() => {
    getMyQuota().then(setQuota);
  }, []);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, statusText, scrollToBottom]);

  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isOpen]);

  // Auto-grow the input textarea so long prompts stay visible. Caps at
  // ~7 lines (160px) so the chat area isn't crowded; scrolls beyond that.
  useEffect(() => {
    const el = inputRef.current;
    if (!el) return;
    el.style.height = 'auto';
    el.style.height = `${Math.min(el.scrollHeight, 160)}px`;
  }, [input]);

  // Drives the Undo countdown chip. We tick at 1Hz only when at least one
  // executed-with-undo card is currently showing, to avoid a permanent
  // background timer.
  const [, forceTick] = useState(0);
  useEffect(() => {
    const hasActiveUndo = messages.some(
      (m) => m.proposalUndoExpiresAt && m.proposalUndoExpiresAt > Date.now(),
    );
    if (!hasActiveUndo) return;
    const interval = setInterval(() => forceTick((n) => n + 1), 1000);
    return () => clearInterval(interval);
  }, [messages]);

  const refreshHistory = useCallback(async () => {
    const list = await listConversations();
    setHistory(list);
  }, []);

  const sendMessage = useCallback(
    async (text: string) => {
      const trimmed = text.trim();
      if (!trimmed || isLoading) return;

      // Block send when template placeholders are still present.
      const placeholderMatch = trimmed.match(PLACEHOLDER_RE);
      if (placeholderMatch) {
        setInputHint(
          `Please replace ${placeholderMatch[0]} with an actual value before sending.`,
        );
        inputRef.current?.focus();
        return;
      }
      setInputHint(null);

      const userMsg: DisplayMessage = {
        role: 'user',
        content: trimmed,
        timestamp: new Date(),
      };
      const pendingMsg: DisplayMessage = {
        role: 'assistant',
        content: '',
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, userMsg, pendingMsg]);
      setInput('');
      setIsLoading(true);
      setStatusText('Planning…');

      const controller = new AbortController();
      abortRef.current = controller;

      let assistantBuffer = '';
      try {
        await streamAgentMessage(
          trimmed,
          conversationId,
          {
            onConversationId: (id) => setConversationId(id),
            onStatus: (t) => setStatusText(t),
            onDelta: (chunk) => {
              assistantBuffer += chunk;
              setMessages((prev) => {
                const updated = [...prev];
                updated[updated.length - 1] = {
                  ...updated[updated.length - 1],
                  content: assistantBuffer,
                };
                return updated;
              });
              setStatusText(null);
            },
            onError: (err) => {
              setMessages((prev) => {
                const updated = [...prev];
                updated[updated.length - 1] = {
                  ...updated[updated.length - 1],
                  content: `The agent couldn't complete that request. ${err}`,
                };
                return updated;
              });
            },
            onProposal: (proposal) => {
              setMessages((prev) => {
                const updated = [...prev];
                const last = updated[updated.length - 1];
                updated[updated.length - 1] = {
                  ...last,
                  proposal,
                  proposalStatus: 'pending',
                };
                return updated;
              });
            },
            onProposalError: (errorMsg) => {
              setMessages((prev) => {
                const updated = [...prev];
                const last = updated[updated.length - 1];
                updated[updated.length - 1] = {
                  ...last,
                  proposalError: errorMsg,
                };
                return updated;
              });
            },
            onDone: (finalReply, convId, usage) => {
              setMessages((prev) => {
                const updated = [...prev];
                const last = updated[updated.length - 1];
                updated[updated.length - 1] = {
                  ...last,
                  content: finalReply && !assistantBuffer ? finalReply : last.content,
                  usage,
                };
                return updated;
              });
              if (convId) setConversationId(convId);
              refreshQuota();
            },
          },
          controller.signal,
        );
      } catch (err) {
        if (!(err instanceof DOMException && err.name === 'AbortError')) {
          const errorContent =
            err instanceof Error
              ? `The agent couldn't complete that request. ${err.message}`
              : 'Agent request failed.';
          setMessages((prev) => {
            const updated = [...prev];
            updated[updated.length - 1] = {
              ...updated[updated.length - 1],
              content: errorContent,
            };
            return updated;
          });
        }
      } finally {
        setIsLoading(false);
        setStatusText(null);
        abortRef.current = null;
      }
    },
    [isLoading, conversationId, refreshQuota],
  );

  const handleSend = useCallback(() => {
    sendMessage(input);
  }, [input, sendMessage]);

  const updateProposalStatus = useCallback(
    (
      msgIdx: number,
      status: ProposalStatus,
      message?: string,
      undo?: { auditId: number; expiresAt: number },
    ) => {
      setMessages((prev) => {
        if (msgIdx < 0 || msgIdx >= prev.length) return prev;
        const updated = [...prev];
        updated[msgIdx] = {
          ...updated[msgIdx],
          proposalStatus: status,
          proposalResultMessage: message,
          ...(undo
            ? { proposalAuditId: undo.auditId, proposalUndoExpiresAt: undo.expiresAt }
            : {}),
        };
        return updated;
      });
    },
    [],
  );

  const handleExecuteProposal = useCallback(
    async (msgIdx: number, proposal: AgentProposal) => {
      // Two-click arming for irreversible actions (approve_deal, mark_arrived,
      // close_warranty_claim). First click arms; second click executes.
      // Armed state persists until the user either confirms or cancels —
      // the 5-min backend token TTL bounds stale-proposal risk.
      if (!proposal.reversible && armedIrreversibleIdx !== msgIdx) {
        setArmedIrreversibleIdx(msgIdx);
        return;
      }
      setArmedIrreversibleIdx(null);
      updateProposalStatus(msgIdx, 'executing');
      try {
        const result = await confirmProposal(proposal.token);
        const isExecuted = result.status === 'EXECUTED';
        // Use the server-provided window duration + browser clock, NOT the
        // server's absolute timestamp (which is timezone-naive LocalDateTime
        // and would mis-parse across browser/server timezone boundaries).
        const undo =
          isExecuted && result.reversible && result.auditId && result.undoWindowSeconds
            ? {
                auditId: result.auditId,
                expiresAt: Date.now() + result.undoWindowSeconds * 1000,
              }
            : undefined;
        updateProposalStatus(
          msgIdx,
          isExecuted ? 'executed' : 'failed',
          result.message || `Audit #${result.auditId ?? '—'}`,
          undo,
        );
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Execution failed.';
        updateProposalStatus(msgIdx, 'failed', msg);
      }
    },
    [updateProposalStatus, armedIrreversibleIdx],
  );

  const handleCancelProposal = useCallback(
    async (msgIdx: number, proposal: AgentProposal) => {
      setArmedIrreversibleIdx((curr) => (curr === msgIdx ? null : curr));
      updateProposalStatus(msgIdx, 'executing');
      try {
        await rejectProposal(proposal.token);
        updateProposalStatus(msgIdx, 'cancelled', 'Action cancelled by user');
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Cancel failed.';
        updateProposalStatus(msgIdx, 'failed', msg);
      }
    },
    [updateProposalStatus],
  );

  const handleUndoExecuted = useCallback(
    async (msgIdx: number, auditId: number) => {
      updateProposalStatus(msgIdx, 'undoing', 'Undoing…');
      try {
        const result = await undoExecutedAction(auditId);
        updateProposalStatus(
          msgIdx,
          result.status === 'UNDONE' ? 'undone' : 'failed',
          result.message || `Compensation audit #${result.auditId ?? '—'}`,
        );
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Undo failed.';
        updateProposalStatus(msgIdx, 'failed', msg);
      }
    },
    [updateProposalStatus],
  );

  // Pre-fill input with a template and select the first placeholder so the
  // user can replace it by typing. Does NOT auto-send.
  const handlePickTemplate = useCallback((template: string) => {
    setInput(template);
    setInputHint(null);
    requestAnimationFrame(() => {
      const el = inputRef.current;
      if (!el) return;
      el.focus();
      const match = template.match(PLACEHOLDER_RE);
      if (match && match.index !== undefined) {
        el.setSelectionRange(match.index, match.index + match[0].length);
      } else {
        el.setSelectionRange(template.length, template.length);
      }
    });
  }, []);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend],
  );

  const handleNewChat = useCallback(() => {
    if (abortRef.current) abortRef.current.abort();
    setMessages([]);
    setConversationId(null);
    setIsLoading(false);
    setStatusText(null);
    setInputHint(null);
  }, []);

  const handleClear = useCallback(async () => {
    if (abortRef.current) abortRef.current.abort();
    if (conversationId) {
      await deleteConversation(conversationId);
    }
    setMessages([]);
    setConversationId(null);
    setIsLoading(false);
    setStatusText(null);
  }, [conversationId]);

  const handleToggle = useCallback(() => {
    setIsOpen((prev) => !prev);
  }, []);

  const handleCycleSize = useCallback(() => {
    setSize((prev) =>
      prev === 'compact' ? 'expanded' : prev === 'expanded' ? 'fullscreen' : 'compact',
    );
  }, []);

  const handleShowHistory = useCallback(async () => {
    await refreshHistory();
    setShowHistory(true);
  }, [refreshHistory]);

  const handleLoadConversation = useCallback(async (id: string) => {
    const detail = await getConversation(id);
    if (!detail) return;
    setConversationId(id);
    setMessages(
      detail.messages.map((m) => ({
        role: m.role === 'assistant' ? 'assistant' : 'user',
        content: m.content,
        timestamp: new Date(m.createdTs),
      })),
    );
    setShowHistory(false);
  }, []);

  const handleDeleteConversation = useCallback(
    async (id: string) => {
      await deleteConversation(id);
      if (conversationId === id) {
        setConversationId(null);
        setMessages([]);
      }
      await refreshHistory();
    },
    [conversationId, refreshHistory],
  );

  if (available === false) {
    return null;
  }

  const sizeClasses: Record<WindowSize, string> = {
    compact: 'right-4 top-16 h-[640px] w-[480px]',
    expanded: 'right-4 top-16 h-[calc(100vh-5rem)] w-[720px] max-w-[calc(100vw-2rem)]',
    fullscreen: 'inset-2 h-[calc(100vh-1rem)] w-[calc(100vw-1rem)]',
  };

  const SizeIcon = size === 'compact' ? Maximize2 : size === 'expanded' ? Monitor : Minimize2;
  const sizeTitle =
    size === 'compact'
      ? 'Expand window'
      : size === 'expanded'
      ? 'Maximize to full screen'
      : 'Shrink to compact';

  return (
    <>
      <button
        onClick={handleToggle}
        className={`flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors ${
          isOpen
            ? 'border-violet-600 bg-violet-600 text-white'
            : 'border-violet-200 bg-violet-50 text-violet-700 hover:border-violet-400 hover:bg-violet-100'
        }`}
        title={
          isOpen
            ? 'Close AI Agent'
            : 'AI Agent — multi-step workflows powered by Claude.\nChains API calls, applies domain rules, reasons across data.\nBest for: "Deal health check", "Customer 360", "Morning briefing", "Aging triage".'
        }
      >
        {isOpen ? <X className="h-4 w-4" /> : <Sparkles className="h-4 w-4" />}
        <span className="hidden sm:inline">AI Agent</span>
      </button>

      {isOpen && (
        <div
          className={`fixed z-50 flex flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl transition-[width,height] duration-200 ${sizeClasses[size]}`}
        >
          {/* Header */}
          <div className="flex items-center justify-between bg-gradient-to-r from-violet-800 via-violet-700 to-indigo-700 px-4 py-3">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-violet-500">
                <Sparkles className="h-4 w-4 text-white" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">AutoSales Agent</h3>
                <p className="text-[11px] text-violet-200">
                  {modelLabel} · skills-based{conversationId ? ' · saved' : ''}
                </p>
                {quota && quota.enabled && (
                  <div
                    className="mt-1 flex items-center gap-1.5"
                    title={`${quota.used.toLocaleString()} of ${quota.quota.toLocaleString()} tokens used today · resets at midnight`}
                  >
                    <div className="h-1 w-28 overflow-hidden rounded-full bg-violet-900/40">
                      <div
                        className={`h-full transition-all ${
                          quota.percentage >= 90
                            ? 'bg-rose-400'
                            : quota.percentage >= 70
                            ? 'bg-amber-300'
                            : 'bg-emerald-300'
                        }`}
                        style={{ width: `${Math.min(100, quota.percentage)}%` }}
                      />
                    </div>
                    <span className="text-[10px] font-medium text-violet-100">
                      {quota.percentage.toFixed(0)}% · {formatShort(quota.used)}/{formatShort(quota.quota)}
                    </span>
                  </div>
                )}
              </div>
            </div>
            <div className="flex items-center gap-1">
              <button
                onClick={handleNewChat}
                className="rounded-lg p-1.5 text-violet-200 transition-colors hover:bg-violet-600 hover:text-white"
                title="New chat"
              >
                <Plus className="h-4 w-4" />
              </button>
              <button
                onClick={handleShowHistory}
                className="rounded-lg p-1.5 text-violet-200 transition-colors hover:bg-violet-600 hover:text-white"
                title="Previous conversations"
              >
                <History className="h-4 w-4" />
              </button>
              <button
                onClick={handleClear}
                className="rounded-lg p-1.5 text-violet-200 transition-colors hover:bg-violet-600 hover:text-white"
                title="Delete this conversation"
              >
                <Trash2 className="h-4 w-4" />
              </button>
              <button
                onClick={handleCycleSize}
                className="rounded-lg p-1.5 text-violet-200 transition-colors hover:bg-violet-600 hover:text-white"
                title={sizeTitle}
              >
                <SizeIcon className="h-4 w-4" />
              </button>
              <button
                onClick={handleToggle}
                className="rounded-lg p-1.5 text-violet-200 transition-colors hover:bg-violet-600 hover:text-white"
                title="Close"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* History overlay */}
          {showHistory && (
            <div className="absolute left-0 right-0 top-[64px] bottom-0 z-10 bg-white">
              <div className="flex items-center justify-between border-b border-gray-200 px-4 py-2">
                <p className="text-sm font-semibold text-gray-800">Previous conversations</p>
                <button
                  onClick={() => setShowHistory(false)}
                  className="rounded p-1 text-gray-500 hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              <div className="h-[calc(100%-48px)] overflow-y-auto px-3 py-2">
                {history.length === 0 && (
                  <p className="mt-8 text-center text-xs text-gray-500">
                    No saved conversations yet.
                  </p>
                )}
                {history.map((c) => (
                  <div
                    key={c.conversationId}
                    className="group mb-2 flex items-start gap-2 rounded-lg border border-gray-100 bg-white p-2.5 hover:border-violet-300 hover:bg-violet-50"
                  >
                    <button
                      onClick={() => handleLoadConversation(c.conversationId)}
                      className="flex-1 text-left"
                    >
                      <p className="truncate text-[13px] font-semibold text-gray-800 group-hover:text-violet-700">
                        {c.title || '(untitled)'}
                      </p>
                      <p className="mt-0.5 text-[11px] text-gray-500">
                        {c.turnCount} turns · {new Date(c.updatedTs).toLocaleString()}
                      </p>
                    </button>
                    <button
                      onClick={() => handleDeleteConversation(c.conversationId)}
                      className="rounded p-1 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-500"
                      title="Delete"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Messages Area */}
          <div className="flex-1 overflow-y-auto px-4 py-3">
            {messages.length === 0 && (
              <div className="flex h-full flex-col">
                <div className="mb-3 flex items-center gap-2.5">
                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-violet-50">
                    <Sparkles className="h-5 w-5 text-violet-600" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-800">
                      Pick a workflow to get started
                    </p>
                    <p className="text-[11px] text-gray-500">
                      Click a card, replace the highlighted placeholder with your own value, then press Enter.
                    </p>
                  </div>
                </div>
                <div
                  className={`grid gap-2 ${
                    size === 'compact' ? 'grid-cols-1' : 'grid-cols-2'
                  }`}
                >
                  {WORKFLOW_RECIPES.map((r) => {
                    const Icon = r.Icon;
                    return (
                      <button
                        key={r.id}
                        onClick={() => handlePickTemplate(r.template)}
                        disabled={isLoading}
                        className="group flex items-start gap-2.5 rounded-xl border border-gray-200 bg-white p-2.5 text-left transition-colors hover:border-violet-300 hover:bg-violet-50 disabled:opacity-40"
                      >
                        <div
                          className={`flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg border ${r.accent}`}
                        >
                          <Icon className="h-4 w-4" />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="text-[13px] font-semibold text-gray-800 group-hover:text-violet-700">
                            {r.name}
                          </p>
                          <p className="mt-0.5 line-clamp-2 text-[11px] leading-snug text-gray-500">
                            {r.description}
                          </p>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {messages.map((msg, idx) => (
              <div
                key={idx}
                className={`mb-3 flex gap-2.5 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                {msg.role === 'assistant' && (
                  <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-violet-100">
                    <Sparkles className="h-3.5 w-3.5 text-violet-700" />
                  </div>
                )}
                <div
                  className={`rounded-2xl px-3.5 py-2.5 text-sm leading-relaxed ${
                    msg.role === 'user'
                      ? 'max-w-[80%] rounded-br-md bg-violet-600 text-white'
                      : 'max-w-[95%] rounded-bl-md bg-gray-50 text-gray-800 border border-gray-100'
                  }`}
                >
                  {msg.role === 'assistant' ? (
                    msg.content === '' ? (
                      <div className="flex items-center gap-2 text-gray-500">
                        <Loader2 className="h-4 w-4 animate-spin text-violet-500" />
                        <span className="text-sm">{statusText ?? 'Planning…'}</span>
                      </div>
                    ) : (
                      <>
                        <div className="overflow-x-auto text-sm [&_h1]:text-sm [&_h1]:font-bold [&_h1]:mb-1 [&_h2]:text-sm [&_h2]:font-bold [&_h2]:mb-1 [&_h3]:text-sm [&_h3]:font-semibold [&_h3]:mb-1 [&_p]:my-1 [&_ul]:my-1 [&_ul]:pl-4 [&_ul]:list-disc [&_ol]:my-1 [&_ol]:pl-4 [&_ol]:list-decimal [&_li]:my-0.5 [&_hr]:my-2 [&_hr]:border-gray-200 [&_table]:w-full [&_table]:text-[11px] [&_table]:border-collapse [&_table]:my-2 [&_th]:bg-violet-50 [&_th]:px-2 [&_th]:py-1 [&_th]:text-left [&_th]:font-semibold [&_th]:border [&_th]:border-violet-200 [&_td]:px-2 [&_td]:py-1 [&_td]:border [&_td]:border-gray-200 [&_strong]:font-semibold [&_code]:bg-violet-50 [&_code]:px-1 [&_code]:rounded [&_code]:text-xs [&_blockquote]:border-l-2 [&_blockquote]:border-violet-300 [&_blockquote]:pl-2 [&_blockquote]:text-gray-600">
                          <ReactMarkdown remarkPlugins={[remarkGfm]}>{msg.content}</ReactMarkdown>
                        </div>
                        {msg.usage && msg.usage.totalTokens > 0 && (
                          <div
                            className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md bg-violet-50 px-2.5 py-1.5 text-[11px] text-violet-800"
                            title={
                              'Per-turn counts are an estimate (~4 chars per token) — OpenClaw does not report real token counts. ' +
                              'The actual org bill is on the Admin → AI Usage page.'
                            }
                          >
                            <span className="font-semibold uppercase tracking-wide text-violet-600">
                              This turn
                            </span>
                            <span className="rounded bg-violet-200/60 px-1.5 py-0.5 font-bold text-violet-900">
                              ~{msg.usage.totalTokens.toLocaleString()} tokens
                            </span>
                            <span className="text-violet-600">
                              ({msg.usage.promptTokens.toLocaleString()} in ·{' '}
                              {msg.usage.completionTokens.toLocaleString()} out)
                            </span>
                            <span className="ml-auto text-[10px] italic text-violet-500">
                              estimate — real $ on Admin page
                            </span>
                          </div>
                        )}
                        {msg.proposalError && (
                          <div className="mt-3 rounded-lg border border-rose-300 bg-rose-50 p-3 text-sm text-rose-900">
                            <div className="flex items-center gap-2 font-semibold">
                              <XCircle className="h-4 w-4 text-rose-600" />
                              <span>Cannot propose action</span>
                            </div>
                            <p className="mt-1.5 text-[13px] leading-snug">{msg.proposalError}</p>
                          </div>
                        )}
                        {msg.proposal && (() => {
                          const isIrreversible = msg.proposal.reversible === false;
                          const isPending = !msg.proposalStatus || msg.proposalStatus === 'pending';
                          const isArmed = armedIrreversibleIdx === idx;
                          const pendingStyle = isIrreversible
                            ? 'border-rose-400 bg-rose-50 text-rose-900'
                            : 'border-amber-300 bg-amber-50 text-amber-900';
                          const undoSecondsLeft = msg.proposalUndoExpiresAt
                            ? Math.max(0, Math.ceil((msg.proposalUndoExpiresAt - Date.now()) / 1000))
                            : 0;
                          const canUndo =
                            msg.proposalStatus === 'executed' &&
                            msg.proposalAuditId !== undefined &&
                            undoSecondsLeft > 0;
                          return (
                          <div
                            className={`mt-3 rounded-lg border p-3 text-sm ${
                              msg.proposalStatus === 'undone'
                                ? 'border-sky-200 bg-sky-50 text-sky-900'
                                : msg.proposalStatus === 'executed'
                                ? 'border-emerald-200 bg-emerald-50 text-emerald-900'
                                : msg.proposalStatus === 'cancelled'
                                ? 'border-gray-200 bg-gray-50 text-gray-700'
                                : msg.proposalStatus === 'failed'
                                ? 'border-rose-200 bg-rose-50 text-rose-900'
                                : pendingStyle
                            } ${isIrreversible && isPending ? 'border-2' : ''}`}
                          >
                            <div className="flex items-center gap-2 font-semibold">
                              {msg.proposalStatus === 'undone' ? (
                                <Shuffle className="h-4 w-4 text-sky-600" />
                              ) : msg.proposalStatus === 'executed' ? (
                                <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                              ) : msg.proposalStatus === 'cancelled' ? (
                                <XCircle className="h-4 w-4 text-gray-500" />
                              ) : msg.proposalStatus === 'failed' ? (
                                <XCircle className="h-4 w-4 text-rose-600" />
                              ) : isIrreversible ? (
                                <AlertTriangle className="h-4 w-4 text-rose-700" />
                              ) : (
                                <ShieldCheck className="h-4 w-4 text-amber-700" />
                              )}
                              <span>
                                {msg.proposalStatus === 'undone'
                                  ? 'Undone'
                                  : msg.proposalStatus === 'executed'
                                  ? 'Executed'
                                  : msg.proposalStatus === 'cancelled'
                                  ? 'Cancelled'
                                  : msg.proposalStatus === 'failed'
                                  ? 'Failed'
                                  : msg.proposalStatus === 'executing'
                                  ? 'Executing…'
                                  : msg.proposalStatus === 'undoing'
                                  ? 'Undoing…'
                                  : isIrreversible
                                  ? 'Permanent action — review carefully'
                                  : 'Proposed action — awaiting confirmation'}
                              </span>
                              <span className="ml-1 rounded-full bg-white/60 px-1.5 py-0.5 text-[10px] font-mono">
                                {msg.proposal.toolName} · Tier {msg.proposal.tier}
                              </span>
                              {isIrreversible && isPending && (
                                <span className="rounded-full bg-rose-600 px-1.5 py-0.5 text-[10px] font-bold text-white">
                                  ⚠ PERMANENT
                                </span>
                              )}
                            </div>
                            {msg.proposal.preview?.summary && (
                              <p className="mt-1.5 text-[13px] leading-snug">
                                {msg.proposal.preview.summary}
                              </p>
                            )}
                            {msg.proposal.preview?.changes &&
                              msg.proposal.preview.changes.length > 0 && (
                                <ul className="mt-2 list-disc space-y-0.5 pl-5 text-[12px]">
                                  {msg.proposal.preview.changes.map((c, i) => (
                                    <li key={i}>{c}</li>
                                  ))}
                                </ul>
                              )}
                            {msg.proposal.preview?.warnings &&
                              msg.proposal.preview.warnings.length > 0 && (
                                <ul className="mt-2 list-disc space-y-0.5 pl-5 text-[12px] text-rose-700">
                                  {msg.proposal.preview.warnings.map((w, i) => (
                                    <li key={i}>{w}</li>
                                  ))}
                                </ul>
                              )}
                            {msg.proposalResultMessage && (
                              <p className="mt-1.5 text-[11px] italic opacity-80">
                                {msg.proposalResultMessage}
                              </p>
                            )}
                            {(!msg.proposalStatus || msg.proposalStatus === 'pending') && (
                              <div className="mt-2.5 flex items-center gap-2">
                                <button
                                  onClick={() => handleExecuteProposal(idx, msg.proposal!)}
                                  className={`flex items-center gap-1 rounded-md px-3 py-1.5 text-[12px] font-semibold text-white shadow-sm transition-colors ${
                                    isIrreversible
                                      ? isArmed
                                        ? 'bg-rose-700 ring-2 ring-rose-300 animate-pulse hover:bg-rose-800'
                                        : 'bg-rose-600 hover:bg-rose-700'
                                      : 'bg-emerald-600 hover:bg-emerald-700'
                                  }`}
                                >
                                  {isIrreversible ? (
                                    <AlertTriangle className="h-3.5 w-3.5" />
                                  ) : (
                                    <CheckCircle2 className="h-3.5 w-3.5" />
                                  )}
                                  {isIrreversible
                                    ? isArmed
                                      ? 'Click again to confirm (permanent)'
                                      : 'Execute — permanent'
                                    : 'Execute'}
                                </button>
                                <button
                                  onClick={() => handleCancelProposal(idx, msg.proposal!)}
                                  className="flex items-center gap-1 rounded-md border border-gray-300 bg-white px-3 py-1.5 text-[12px] font-semibold text-gray-700 transition-colors hover:bg-gray-50"
                                >
                                  <XCircle className="h-3.5 w-3.5" />
                                  Cancel
                                </button>
                                <span className="ml-auto flex items-center gap-1 text-[11px] text-amber-700">
                                  <Clock className="h-3 w-3" />
                                  expires{' '}
                                  {new Date(msg.proposal.expiresAt).toLocaleTimeString([], {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  })}
                                </span>
                              </div>
                            )}
                            {msg.proposalStatus === 'executing' && (
                              <div className="mt-2 flex items-center gap-2 text-[12px] text-amber-800">
                                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                Working…
                              </div>
                            )}
                            {canUndo && (
                              <div className="mt-2.5 flex items-center gap-2">
                                <button
                                  onClick={() =>
                                    handleUndoExecuted(idx, msg.proposalAuditId!)
                                  }
                                  className="flex items-center gap-1 rounded-md border border-emerald-300 bg-white px-3 py-1.5 text-[12px] font-semibold text-emerald-800 transition-colors hover:bg-emerald-50"
                                  title="Reverse this action via the recorded compensation"
                                >
                                  <Shuffle className="h-3.5 w-3.5" />
                                  Undo ({undoSecondsLeft}s)
                                </button>
                                <span className="text-[11px] italic text-emerald-700">
                                  reverses via compensation
                                </span>
                              </div>
                            )}
                            {msg.proposalStatus === 'undoing' && (
                              <div className="mt-2 flex items-center gap-2 text-[12px] text-sky-700">
                                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                Undoing…
                              </div>
                            )}
                          </div>
                          );
                        })()}
                        {msg.content.length > 0 && (
                          <div className="mt-2 flex flex-wrap items-center gap-1 border-t border-gray-200 pt-2">
                            <button
                              onClick={() => downloadMarkdown(msg.content, msg.timestamp)}
                              className="flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-medium text-gray-600 transition-colors hover:bg-violet-50 hover:text-violet-700"
                              title="Download as Markdown (.md)"
                            >
                              <Download className="h-3 w-3" />
                              Markdown
                            </button>
                            <button
                              onClick={() => {
                                const prev = messages[idx - 1];
                                const prompt =
                                  prev && prev.role === 'user' ? prev.content : undefined;
                                downloadPdf(msg.content, msg.timestamp, prompt);
                              }}
                              className="flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-medium text-gray-600 transition-colors hover:bg-violet-50 hover:text-violet-700"
                              title="Download as PDF"
                            >
                              <FileText className="h-3 w-3" />
                              PDF
                            </button>
                            <button
                              onClick={async () => {
                                const prev = messages[idx - 1];
                                const prompt =
                                  prev && prev.role === 'user' ? prev.content : undefined;
                                const filename = await emailWithPdfAttachment(
                                  msg.content,
                                  msg.timestamp,
                                  prompt,
                                );
                                setInputHint(
                                  `PDF "${filename}" was downloaded. Attach it to the email draft that just opened, then send.`,
                                );
                              }}
                              className="flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-medium text-gray-600 transition-colors hover:bg-violet-50 hover:text-violet-700"
                              title="Download PDF and open mail client — attach the downloaded PDF to send"
                            >
                              <Mail className="h-3 w-3" />
                              Email
                            </button>
                            <button
                              onClick={async () => {
                                const ok = await copyToClipboard(msg.content);
                                if (ok) {
                                  setCopiedIdx(idx);
                                  setTimeout(
                                    () => setCopiedIdx((c) => (c === idx ? null : c)),
                                    1500,
                                  );
                                }
                              }}
                              className="flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-medium text-gray-600 transition-colors hover:bg-violet-50 hover:text-violet-700"
                              title="Copy to clipboard"
                            >
                              {copiedIdx === idx ? (
                                <>
                                  <Check className="h-3 w-3 text-emerald-600" />
                                  Copied
                                </>
                              ) : (
                                <>
                                  <Copy className="h-3 w-3" />
                                  Copy
                                </>
                              )}
                            </button>
                          </div>
                        )}
                      </>
                    )
                  ) : (
                    <p className="whitespace-pre-wrap">{msg.content}</p>
                  )}
                  <p
                    className={`mt-1 text-[10px] ${
                      msg.role === 'user' ? 'text-violet-200' : 'text-gray-400'
                    }`}
                  >
                    {msg.timestamp.toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
                {msg.role === 'user' && (
                  <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-violet-100">
                    <User className="h-3.5 w-3.5 text-violet-700" />
                  </div>
                )}
              </div>
            ))}

            <div ref={messagesEndRef} />
          </div>

          {/* Workflow suggestions + Input */}
          <div className="border-t border-gray-200 bg-gray-50 px-3 pb-3 pt-2">
            <div className="mb-2 flex flex-wrap gap-1.5">
              {QUICK_SUGGESTIONS.map((template) => (
                <button
                  key={template}
                  onClick={() => handlePickTemplate(template)}
                  className="rounded-full border border-gray-200 bg-white px-2.5 py-1 text-[11px] font-medium text-gray-600 transition-colors hover:border-violet-300 hover:bg-violet-50 hover:text-violet-700"
                  title="Click to load this template — fill in the highlighted placeholder, then press Enter."
                >
                  {template}
                </button>
              ))}
            </div>
            {inputHint && (
              <p className="mb-1.5 text-[11px] font-medium text-amber-700">{inputHint}</p>
            )}
            <div className="flex items-end gap-2">
              <textarea
                ref={inputRef}
                value={input}
                onChange={(e) => {
                  setInput(e.target.value);
                  if (inputHint) setInputHint(null);
                }}
                onKeyDown={handleKeyDown}
                placeholder="Ask the agent… Enter to send, Shift+Enter for newline"
                disabled={isLoading}
                rows={3}
                className="flex-1 resize-none overflow-y-auto rounded-xl border border-gray-200 bg-white px-3.5 py-2.5 text-sm leading-snug text-gray-800 placeholder-gray-400 outline-none transition-colors focus:border-violet-400 focus:ring-2 focus:ring-violet-100 disabled:opacity-50"
              />
              <button
                onClick={handleSend}
                disabled={!input.trim() || isLoading}
                className="flex h-10 min-w-10 items-center justify-center rounded-xl bg-violet-600 text-white transition-colors hover:bg-violet-700 disabled:opacity-40 disabled:hover:bg-violet-600"
                title="Send message"
              >
                {isLoading ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
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

export default AgentWidget;
