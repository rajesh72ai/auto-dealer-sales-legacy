const USAGE_BASE = '/api/agent/usage';

export interface QuotaStatus {
  userId: string;
  used: number;
  quota: number;
  enabled: boolean;
  percentage: number;
  remaining: number;
}

export interface UsageDailyBucket {
  date: string;
  conversations: number;
  turns: number;
  estimatedTokens: number;
  actualInputTokens: number;
  actualCacheReadTokens: number;
  actualCacheWrite5mTokens: number;
  actualCacheWrite1hTokens: number;
  actualOutputTokens: number;
  actualCost: number;
  activeUsers: string[];
  activeDealers: string[];
  modelBreakdown: Record<string, number>;
}

export interface UsageTotals {
  conversations: number;
  turns: number;
  estimatedTokens: number;
  actualInputTokens: number;
  actualCacheReadTokens: number;
  actualCacheWrite5mTokens: number;
  actualCacheWrite1hTokens: number;
  actualOutputTokens: number;
  actualCost: number;
  uniqueActiveUsers: number;
  uniqueActiveDealers: number;
}

export interface UsageActuals {
  from: string;
  to: string;
  actualsAvailable: boolean;
  actualsError?: string;
  currency: string;
  buckets: UsageDailyBucket[];
  totals: UsageTotals;
  pricing: {
    inputPerMillion: number;
    outputPerMillion: number;
    cacheReadPerMillion: number;
    cacheWrite5mPerMillion: number;
    cacheWrite1hPerMillion: number;
  };
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function getMyQuota(): Promise<QuotaStatus | null> {
  try {
    const response = await fetch(`${USAGE_BASE}/quota/me`, { headers: authHeaders() });
    if (!response.ok) return null;
    return response.json();
  } catch {
    return null;
  }
}

export async function getUsageActuals(from: string, to: string): Promise<UsageActuals | null> {
  const response = await fetch(`${USAGE_BASE}/actuals?from=${from}&to=${to}`, {
    headers: authHeaders(),
  });
  if (!response.ok) return null;
  return response.json();
}
