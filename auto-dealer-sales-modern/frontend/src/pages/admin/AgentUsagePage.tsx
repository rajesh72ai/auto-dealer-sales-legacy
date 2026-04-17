import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  BarChart3,
  CalendarRange,
  DollarSign,
  Info,
  MessageSquareText,
  RefreshCw,
  Sparkles,
  Users,
} from 'lucide-react';
import { getUsageActuals } from '@/api/agentUsage';
import type { UsageActuals } from '@/api/agentUsage';

type RangeKey = '7d' | '30d' | 'mtd';

function toISODate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

function rangeFor(kind: RangeKey): { from: string; to: string } {
  const today = new Date();
  const to = toISODate(today);
  if (kind === 'mtd') {
    const first = new Date(today.getFullYear(), today.getMonth(), 1);
    return { from: toISODate(first), to };
  }
  const days = kind === '7d' ? 6 : 29;
  const from = new Date(today);
  from.setDate(from.getDate() - days);
  return { from: toISODate(from), to };
}

function money(n: number | undefined): string {
  if (n === undefined || n === null) return '$0.00';
  return `$${Number(n).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function money4(n: number | undefined): string {
  if (n === undefined || n === null) return '$0.0000';
  return `$${Number(n).toLocaleString('en-US', { minimumFractionDigits: 4, maximumFractionDigits: 4 })}`;
}

function compact(n: number | undefined): string {
  if (!n) return '0';
  if (n < 1000) return String(n);
  if (n < 1_000_000) return `${(n / 1000).toFixed(n < 10_000 ? 1 : 0)}K`;
  return `${(n / 1_000_000).toFixed(n < 10_000_000 ? 2 : 1)}M`;
}

function AgentUsagePage() {
  const [range, setRange] = useState<RangeKey>('7d');
  const [data, setData] = useState<UsageActuals | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async (r: RangeKey) => {
    setLoading(true);
    setError(null);
    try {
      const { from, to } = rangeFor(r);
      const result = await getUsageActuals(from, to);
      if (!result) {
        setError('Unable to load usage data — you may lack ADMIN role or the server is unreachable.');
        setData(null);
      } else {
        setData(result);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load usage');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(range);
  }, [load, range]);

  const rangeLabels: Record<RangeKey, string> = useMemo(
    () => ({ '7d': 'Last 7 days', '30d': 'Last 30 days', mtd: 'Month to date' }),
    [],
  );

  const actualInput = data?.totals.actualInputTokens ?? 0;
  const actualCacheRead = data?.totals.actualCacheReadTokens ?? 0;
  const actualCacheWrite5m = data?.totals.actualCacheWrite5mTokens ?? 0;
  const actualCacheWrite1h = data?.totals.actualCacheWrite1hTokens ?? 0;
  const actualOutput = data?.totals.actualOutputTokens ?? 0;
  const grandTokens = actualInput + actualCacheRead + actualCacheWrite5m + actualCacheWrite1h + actualOutput;

  return (
    <div className="flex flex-1 flex-col gap-4 p-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-violet-100">
            <Sparkles className="h-5 w-5 text-violet-700" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">AI Agent — Usage & Cost</h1>
            <p className="text-sm text-gray-500">Real-spend rollup from Anthropic, cross-referenced with your local activity.</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
            {(['7d', '30d', 'mtd'] as RangeKey[]).map((r) => (
              <button
                key={r}
                onClick={() => setRange(r)}
                className={`px-3 py-1.5 text-sm font-medium transition-colors ${
                  range === r
                    ? 'bg-violet-600 text-white'
                    : 'bg-white text-gray-600 hover:bg-gray-50'
                }`}
              >
                {rangeLabels[r]}
              </button>
            ))}
          </div>
          <button
            onClick={() => load(range)}
            className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm font-medium text-gray-600 shadow-sm transition-colors hover:bg-gray-50"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {/* Honesty banner */}
      <div className="flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-[13px] text-amber-900">
        <Info className="mt-0.5 h-4 w-4 flex-shrink-0 text-amber-700" />
        <div>
          <span className="font-semibold">Per-turn badges in the Agent widget are estimates.</span>{' '}
          This page is the actual bill: token counts and USD here come from the Anthropic admin API
          ({`/v1/organizations/usage_report/messages`}) and use the pricing in <code className="rounded bg-amber-100 px-1">application.yml</code>.
          Local activity (conversations, turns, active users) comes from AutoSales' own DB.
        </div>
      </div>

      {/* Data unavailable banner */}
      {data && !data.actualsAvailable && (
        <div className="flex items-start gap-2 rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-[13px] text-rose-900">
          <AlertTriangle className="mt-0.5 h-4 w-4 flex-shrink-0 text-rose-700" />
          <div>
            <span className="font-semibold">Actuals unavailable.</span>{' '}
            {data.actualsError
              ? `Anthropic admin API error: ${data.actualsError}`
              : 'Anthropic admin API key not configured. Set ANTHROPIC_ADMIN_API_KEY to show real spend.'}
            <br />
            The local activity metrics below are still accurate.
          </div>
        </div>
      )}

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
          {error}
        </div>
      )}

      {/* KPI cards */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          icon={<DollarSign className="h-5 w-5 text-emerald-600" />}
          label="Actual spend"
          value={money(data?.totals.actualCost)}
          sub={
            data?.actualsAvailable
              ? `${compact(grandTokens)} tokens across all models`
              : 'No actuals — estimate below'
          }
          highlight={data?.actualsAvailable}
        />
        <KpiCard
          icon={<MessageSquareText className="h-5 w-5 text-violet-600" />}
          label="Conversations"
          value={String(data?.totals.conversations ?? 0)}
          sub={`${data?.totals.turns ?? 0} turns total`}
        />
        <KpiCard
          icon={<Users className="h-5 w-5 text-sky-600" />}
          label="Active users"
          value={String(data?.totals.uniqueActiveUsers ?? 0)}
          sub={`across ${data?.totals.uniqueActiveDealers ?? 0} dealers`}
        />
        <KpiCard
          icon={<Activity className="h-5 w-5 text-amber-600" />}
          label="Local estimate"
          value={compact(data?.totals.estimatedTokens)}
          sub="tokens — per-turn widget badges"
        />
      </div>

      {/* Token breakdown */}
      {data?.actualsAvailable && (
        <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
          <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold text-gray-700">
            <BarChart3 className="h-4 w-4 text-violet-600" />
            Token breakdown — what the bill is made of
          </h2>
          <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-5">
            <TokenLine label="Input (uncached)" value={actualInput} rate={data.pricing.inputPerMillion} />
            <TokenLine label="Cache read" value={actualCacheRead} rate={data.pricing.cacheReadPerMillion} />
            <TokenLine label="Cache write (5m)" value={actualCacheWrite5m} rate={data.pricing.cacheWrite5mPerMillion} />
            <TokenLine label="Cache write (1h)" value={actualCacheWrite1h} rate={data.pricing.cacheWrite1hPerMillion} />
            <TokenLine label="Output" value={actualOutput} rate={data.pricing.outputPerMillion} />
          </div>
        </div>
      )}

      {/* Daily buckets */}
      <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-gray-200 bg-gray-50 px-4 py-2">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-700">
            <CalendarRange className="h-4 w-4 text-violet-600" />
            Daily breakdown
          </h2>
          <span className="text-xs text-gray-500">
            {data?.from} → {data?.to}
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr className="border-b border-gray-200">
                <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">Date</th>
                <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">
                  Actual $ <span className="text-emerald-600">✓</span>
                </th>
                <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">In / Out tokens</th>
                <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">Cache read</th>
                <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">Conv.</th>
                <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">Turns</th>
                <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">Users</th>
                <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">Models</th>
              </tr>
            </thead>
            <tbody>
              {loading && !data && (
                <tr>
                  <td colSpan={8} className="px-4 py-8 text-center text-sm text-gray-400">
                    Loading…
                  </td>
                </tr>
              )}
              {data?.buckets.map((b) => (
                <tr key={b.date} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-2 font-mono text-xs text-gray-700">{b.date}</td>
                  <td className="px-4 py-2 text-right font-semibold text-emerald-700">{money4(b.actualCost)}</td>
                  <td className="px-4 py-2 text-right text-gray-600">
                    {compact(b.actualInputTokens)} / {compact(b.actualOutputTokens)}
                  </td>
                  <td className="px-4 py-2 text-right text-gray-500">{compact(b.actualCacheReadTokens)}</td>
                  <td className="px-4 py-2 text-right text-gray-700">{b.conversations}</td>
                  <td className="px-4 py-2 text-right text-gray-700">{b.turns}</td>
                  <td className="px-4 py-2 text-right text-gray-700">{b.activeUsers?.length ?? 0}</td>
                  <td className="px-4 py-2 text-xs text-gray-500">
                    {Object.keys(b.modelBreakdown ?? {}).join(', ') || '—'}
                  </td>
                </tr>
              ))}
              {!loading && data?.buckets.length === 0 && (
                <tr>
                  <td colSpan={8} className="px-4 py-8 text-center text-sm text-gray-400">
                    No data in range.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Footnote */}
      <p className="text-[11px] italic text-gray-400">
        Anthropic admin API bills in hourly buckets; we aggregate to days. Per-user attribution is not
        available — OpenClaw gateway does not forward per-request tags. For per-user spend, see the quota
        progress bar in each user's Agent widget (accurate, local counter).
      </p>
    </div>
  );
}

function KpiCard({
  icon,
  label,
  value,
  sub,
  highlight,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  sub: string;
  highlight?: boolean;
}) {
  return (
    <div
      className={`rounded-lg border p-4 shadow-sm ${
        highlight ? 'border-emerald-200 bg-emerald-50/40' : 'border-gray-200 bg-white'
      }`}
    >
      <div className="mb-1 flex items-center gap-2">
        {icon}
        <span className="text-[11px] font-semibold uppercase tracking-wide text-gray-500">{label}</span>
      </div>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      <p className="mt-0.5 text-[11px] text-gray-500">{sub}</p>
    </div>
  );
}

function TokenLine({ label, value, rate }: { label: string; value: number; rate: number }) {
  const cost = rate > 0 ? (value / 1_000_000) * rate : 0;
  return (
    <div>
      <p className="text-[11px] font-semibold uppercase tracking-wide text-gray-500">{label}</p>
      <p className="mt-0.5 text-sm font-bold text-gray-800">{compact(value)}</p>
      <p className="text-[10px] text-gray-500">
        @ ${rate}/M = {money4(cost)}
      </p>
    </div>
  );
}

export default AgentUsagePage;
