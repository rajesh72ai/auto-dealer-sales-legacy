const ACTIONS_BASE = '/api/agent/actions';

export interface ExecutionResult {
  token: string;
  toolName: string;
  status: 'EXECUTED' | 'REJECTED' | 'FAILED' | 'UNDONE';
  result?: unknown;
  auditId?: number;
  message?: string;
  reversible?: boolean;
  /** ISO timestamp after which Undo will fail (server-side clock). Forensics only. */
  undoExpiresAt?: string;
  /**
   * Duration in seconds the undo window is open, counted from this response.
   * Use this (not undoExpiresAt) for the countdown — avoids server/browser
   * timezone and clock-skew issues.
   */
  undoWindowSeconds?: number;
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function confirmProposal(token: string): Promise<ExecutionResult> {
  const response = await fetch(`${ACTIONS_BASE}/confirm/${encodeURIComponent(token)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
  });
  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`Confirm failed (${response.status}): ${text || response.statusText}`);
  }
  return response.json();
}

export async function rejectProposal(token: string): Promise<ExecutionResult> {
  const response = await fetch(`${ACTIONS_BASE}/reject/${encodeURIComponent(token)}`, {
    method: 'DELETE',
    headers: authHeaders(),
  });
  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`Reject failed (${response.status}): ${text || response.statusText}`);
  }
  return response.json();
}

export async function undoExecutedAction(auditId: number): Promise<ExecutionResult> {
  const response = await fetch(`${ACTIONS_BASE}/undo/${auditId}`, {
    method: 'POST',
    headers: authHeaders(),
  });
  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`Undo failed (${response.status}): ${text || response.statusText}`);
  }
  return response.json();
}
