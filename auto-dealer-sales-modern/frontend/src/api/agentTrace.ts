const TRACE_BASE = '/api/admin/agent-trace';

export interface TraceRow {
  auditId: number;
  createdTs: string;
  userId: string;
  userRole: string | null;
  dealerCode: string | null;
  toolName: string;
  tier: string; // R = read, A = sales, B = manager, C = operator, D = chained
  status: string; // PROPOSED | EXECUTED | REJECTED | FAILED | CONFIRMED
  dryRun: boolean;
  reversible: boolean;
  undone: boolean;
  elapsedMs: number | null;
  httpStatus: number | null;
  endpoint: string | null;
  proposalToken: string | null;
  payloadJson: string | null;
  previewJson: string | null;
  responseJson: string | null;
  errorMessage: string | null;
}

export interface TraceResult {
  conversationId: string;
  totalRows: number;
  page: number;
  size: number;
  rows: TraceRow[];
}

export interface RecentConversation {
  conversationId: string;
  lastActivityTs: string;
  rowCount: number;
  userId: string;
  dealerCode: string | null;
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function getRecentConversations(limit = 30): Promise<RecentConversation[] | null> {
  try {
    const r = await fetch(`${TRACE_BASE}/recent?limit=${limit}`, { headers: authHeaders() });
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}

export async function getTrace(conversationId: string): Promise<TraceResult | null> {
  try {
    const r = await fetch(`${TRACE_BASE}/${encodeURIComponent(conversationId)}`, {
      headers: authHeaders(),
    });
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}
