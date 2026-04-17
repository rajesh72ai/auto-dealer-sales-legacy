const BASE = '/api/capability-gaps';

export interface CapabilityGap {
  gapId: number;
  appId: string;
  appName: string;
  sourceSystem: string;
  userId: string | null;
  dealerCode: string | null;
  requestedCapability: string;
  category: string;
  userInput: string;
  scenarioDescription: string;
  agentReasoning: string;
  suggestedAlternative: string | null;
  priorityHint: string;
  status: string;
  resolutionNotes: string | null;
  createdTs: string;
  resolvedTs: string | null;
}

export interface GapSummaryItem {
  capability: string;
  category: string;
  appId: string;
  requestCount: number;
  lastRequested: string;
}

export interface GapDashboard {
  totalNew: number;
  totalReviewed: number;
  totalPlanned: number;
  totalImplemented: number;
  topRequested: GapSummaryItem[];
  recentGaps: CapabilityGap[];
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function getGapDashboard(): Promise<GapDashboard | null> {
  try {
    const res = await fetch(`${BASE}/dashboard`, { headers: authHeaders() });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export async function getGapList(
  page = 0,
  size = 20,
  status?: string,
): Promise<{ content: CapabilityGap[]; totalElements: number } | null> {
  try {
    const params = new URLSearchParams({ page: String(page), size: String(size) });
    if (status) params.set('status', status);
    const res = await fetch(`${BASE}?${params}`, { headers: authHeaders() });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export async function updateGapStatus(
  gapId: number,
  status: string,
  resolutionNotes?: string,
): Promise<boolean> {
  try {
    const res = await fetch(`${BASE}/${gapId}/status`, {
      method: 'PATCH',
      headers: { ...authHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, resolutionNotes }),
    });
    return res.ok;
  } catch {
    return false;
  }
}
