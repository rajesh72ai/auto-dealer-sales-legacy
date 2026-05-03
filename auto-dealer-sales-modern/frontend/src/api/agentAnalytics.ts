const ANALYTICS_BASE = '/api/admin/agent-analytics';

export interface ToolCallStat {
  tool_name: string;
  calls: number;
  failures: number;
  p50_ms: number;
  p95_ms: number;
  avg_ms: number;
}

export interface DailyActivityRow {
  day: string;
  calls: number;
  conversations: number;
  users: number;
  reads: number;
  writes: number;
  failures: number;
}

export interface CostRow {
  day?: string;
  service?: string;
  cost_usd?: number;
  info?: string;
  error?: string;
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function getRange<T>(path: string, from: string, to: string): Promise<T | null> {
  try {
    const r = await fetch(`${ANALYTICS_BASE}/${path}?from=${from}&to=${to}`, {
      headers: authHeaders(),
    });
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}

export async function getToolCalls(
  from: string,
  to: string,
): Promise<{ from: string; to: string; rows: ToolCallStat[] } | null> {
  return getRange('tool-calls', from, to);
}

export async function getDailyActivity(
  from: string,
  to: string,
): Promise<{ from: string; to: string; rows: DailyActivityRow[] } | null> {
  return getRange('daily', from, to);
}

export async function getCost(
  from: string,
  to: string,
): Promise<{ from: string; to: string; rows: CostRow[] } | null> {
  return getRange('cost', from, to);
}
