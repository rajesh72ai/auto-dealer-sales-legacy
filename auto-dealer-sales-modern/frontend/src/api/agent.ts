const AGENT_URL = '/api/agent';
const AGENT_STREAM_URL = '/api/agent/stream';
const AGENT_INFO_URL = '/api/agent/info';
const AGENT_CONVERSATIONS_URL = '/api/agent/conversations';

export interface AgentMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface AgentApiResponse {
  reply: string;
  model: string;
  conversationId?: string | null;
}

export interface AgentFeatures {
  streaming?: boolean;
  persistentMemory?: boolean;
  compositeTools?: boolean;
  externalDataSources?: string[];
}

export interface AgentInfo {
  available: boolean;
  model: string;
  label: string;
  skill: string;
  features?: AgentFeatures;
}

export interface ConversationSummary {
  conversationId: string;
  title: string;
  turnCount: number;
  tokenTotal: number;
  model: string;
  createdTs: string;
  updatedTs: string;
}

export interface ConversationDetail extends ConversationSummary {
  messages: { role: string; content: string; seq: number; createdTs: string }[];
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function getAgentInfo(token: string | null): Promise<AgentInfo | null> {
  try {
    const response = await fetch(AGENT_INFO_URL, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!response.ok) return null;
    return response.json();
  } catch {
    return null;
  }
}

/** Legacy — full history sent by client, no persistence. */
export async function sendAgentMessage(
  messages: AgentMessage[],
  signal?: AbortSignal,
): Promise<AgentApiResponse> {
  const response = await fetch(AGENT_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: JSON.stringify({ messages }),
    signal,
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`Agent error ${response.status}: ${text || response.statusText}`);
  }

  return response.json();
}

export interface TurnUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  inputCost: number;
  outputCost: number;
  totalCost: number;
  currency: string;
  estimated: boolean;
}

export interface ProposalPreview {
  toolName?: string;
  tier?: string;
  summary?: string;
  changes?: string[];
  warnings?: string[];
  detail?: Record<string, unknown>;
  reversible?: boolean;
}

export interface PrereqUnmet {
  payloadField: string;
  entityName: string;
  finderToolName?: string | null;
  satisfierToolName?: string | null;
  resultField?: string | null;
  userFacingHint?: string | null;
  requiredUserData?: string[];
}

export interface PrerequisiteGap {
  parentTool: string;
  parentTier: string;
  summary: string;
  unmet: PrereqUnmet[];
  originalPayload?: Record<string, unknown>;
}

export interface AgentProposal {
  token?: string | null;
  toolName: string;
  tier: string;
  preview?: ProposalPreview | null;
  expiresAt?: string | null;
  reversible: boolean;
  /** Present when ActionService detected unmet prerequisites and short-circuited. */
  prerequisiteGap?: PrerequisiteGap | null;
}

/** Persistent + optionally streamed. Frontend sends only the current turn. */
export interface StreamEventHandlers {
  onConversationId?: (id: string) => void;
  onStatus?: (text: string) => void;
  onDelta?: (text: string) => void;
  onFinish?: (reason: string) => void;
  onError?: (message: string) => void;
  onProposal?: (proposal: AgentProposal) => void;
  onProposalError?: (message: string) => void;
  onDone?: (
    reply: string,
    conversationId: string | null,
    usage?: TurnUsage,
  ) => void;
}

export async function streamAgentMessage(
  userMessage: string,
  conversationId: string | null,
  handlers: StreamEventHandlers,
  signal?: AbortSignal,
): Promise<void> {
  const response = await fetch(AGENT_STREAM_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
      ...authHeaders(),
    },
    body: JSON.stringify({ userMessage, conversationId }),
    signal,
  });

  if (!response.ok || !response.body) {
    const text = await response.text().catch(() => '');
    throw new Error(`Stream error ${response.status}: ${text || response.statusText}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder('utf-8');
  let buffer = '';

  // Watchdog — if the server stops sending events for longer than this,
  // cancel the reader so the while loop breaks, the promise resolves, and
  // the caller's finally() runs (unsticks the spinner). Any activity (bytes
  // received) resets the timer. Value is generous to accommodate slow
  // agent runs with lots of tool calls.
  const IDLE_WATCHDOG_MS = 180_000;
  let watchdog: ReturnType<typeof setTimeout> | null = null;
  let timedOut = false;
  const resetWatchdog = () => {
    if (watchdog) clearTimeout(watchdog);
    watchdog = setTimeout(() => {
      timedOut = true;
      try {
        reader.cancel();
      } catch {
        /* reader already closed */
      }
    }, IDLE_WATCHDOG_MS);
  };
  const clearWatchdog = () => {
    if (watchdog) {
      clearTimeout(watchdog);
      watchdog = null;
    }
  };

  resetWatchdog();

  let streamDone = false;
  try {
  // eslint-disable-next-line no-constant-condition
  while (!streamDone) {
    const { value, done } = await reader.read();
    if (done) break;
    resetWatchdog();
    buffer += decoder.decode(value, { stream: true });

    // SSE events separated by blank line
    const events = buffer.split(/\n\n/);
    buffer = events.pop() ?? '';
    for (const raw of events) {
      const lines = raw.split('\n');
      let eventName = 'message';
      const dataParts: string[] = [];
      for (const line of lines) {
        if (line.startsWith('event:')) {
          eventName = line.slice(6).trim();
        } else if (line.startsWith('data:')) {
          // SSE spec: strip exactly one leading space after 'data:' if present;
          // preserve all other whitespace inside the payload (content deltas
          // often have meaningful leading spaces). Multiple data lines are
          // joined with newlines.
          let chunk = line.slice(5);
          if (chunk.startsWith(' ')) chunk = chunk.slice(1);
          dataParts.push(chunk);
        }
      }
      const data = dataParts.join('\n');
      if (!data && eventName !== 'done') continue;
      switch (eventName) {
        case 'conversation':
          handlers.onConversationId?.(data);
          break;
        case 'status':
          handlers.onStatus?.(data);
          break;
        case 'delta':
          handlers.onDelta?.(data);
          break;
        case 'finish':
          handlers.onFinish?.(data);
          break;
        case 'error':
          handlers.onError?.(data);
          break;
        case 'proposal': {
          try {
            const parsed = JSON.parse(data);
            handlers.onProposal?.(parsed as AgentProposal);
          } catch {
            /* invalid proposal JSON — ignore */
          }
          break;
        }
        case 'proposal-error': {
          try {
            const parsed = JSON.parse(data);
            handlers.onProposalError?.(parsed.message ?? 'Proposal failed');
          } catch {
            handlers.onProposalError?.(data || 'Proposal failed');
          }
          break;
        }
        case 'done': {
          try {
            const parsed = JSON.parse(data);
            const usage: TurnUsage | undefined =
              parsed.promptTokens !== undefined
                ? {
                    promptTokens: Number(parsed.promptTokens) || 0,
                    completionTokens: Number(parsed.completionTokens) || 0,
                    totalTokens: Number(parsed.totalTokens) || 0,
                    inputCost: Number(parsed.inputCost) || 0,
                    outputCost: Number(parsed.outputCost) || 0,
                    totalCost: Number(parsed.totalCost) || 0,
                    currency: parsed.currency || 'USD',
                    estimated: parsed.estimated === 'true' || parsed.estimated === true,
                  }
                : undefined;
            handlers.onDone?.(parsed.reply ?? '', parsed.conversationId ?? null, usage);
          } catch {
            handlers.onDone?.(data, null);
          }
          // Break out of the reader loop immediately after done.
          // On Windows/Docker the SSE connection may not close cleanly,
          // leaving reader.read() hanging indefinitely. Cancel the reader
          // so the while-loop exits and the promise resolves.
          streamDone = true;
          reader.cancel().catch(() => {});
          break;
        }
        default:
          break;
      }
    }
  }
  } finally {
    clearWatchdog();
    if (timedOut) {
      handlers.onError?.(
        'The agent stopped responding (no events for 3 minutes). Your previous reply is saved; try a new prompt.',
      );
    }
  }
}

export async function listConversations(): Promise<ConversationSummary[]> {
  const response = await fetch(AGENT_CONVERSATIONS_URL, { headers: authHeaders() });
  if (!response.ok) return [];
  return response.json();
}

export async function getConversation(id: string): Promise<ConversationDetail | null> {
  const response = await fetch(`${AGENT_CONVERSATIONS_URL}/${id}`, { headers: authHeaders() });
  if (!response.ok) return null;
  return response.json();
}

export async function deleteConversation(id: string): Promise<boolean> {
  const response = await fetch(`${AGENT_CONVERSATIONS_URL}/${id}`, {
    method: 'DELETE',
    headers: authHeaders(),
  });
  return response.ok;
}
