import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  BarChart3,
  CalendarRange,
  CheckCircle2,
  DollarSign,
  RefreshCw,
  Sparkles,
  Timer,
} from 'lucide-react';
import {
  getCost,
  getDailyActivity,
  getToolCalls,
  type CostRow,
  type DailyActivityRow,
  type ToolCallStat,
} from '@/api/agentAnalytics';

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
  if (n === undefined || n === null) return '$0.0000';
  return `$${Number(n).toLocaleString('en-US', { minimumFractionDigits: 4, maximumFractionDigits: 4 })}`;
}

function compact(n: number | undefined): string {
  if (!n) return '0';
  if (n < 1000) return String(n);
  if (n < 1_000_000) return `${(n / 1000).toFixed(n < 10_000 ? 1 : 0)}K`;
  return `${(n / 1_000_000).toFixed(n < 10_000_000 ? 2 : 1)}M`;
}

function AgentAnalyticsPage() {
  const [range, setRange] = useState<RangeKey>('7d');
  const [tools, setTools] = useState<ToolCallStat[]>([]);
  const [daily, setDaily] = useState<DailyActivityRow[]>([]);
  const [cost, setCost] = useState<CostRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async (r: RangeKey) => {
    setLoading(true);
    setError(null);
    try {
      const { from, to } = rangeFor(r);
      const [tc, da, c] = await Promise.all([
        getToolCalls(from, to),
        getDailyActivity(from, to),
        getCost(from, to),
      ]);
      if (!tc && !da && !c) {
        setError('Analytics endpoints unreachable. Confirm BIGQUERY_ENABLED=true on Cloud Run and that the autosales-app SA has BigQuery roles.');
        setTools([]);
        setDaily([]);
        setCost([]);
        return;
      }
      setTools(tc?.rows ?? []);
      setDaily(da?.rows ?? []);
      setCost(c?.rows ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load analytics');
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

  const totals = useMemo(() => {
    const totalCalls = tools.reduce((s, r) => s + (r.calls || 0), 0);
    const totalFailures = tools.reduce((s, r) => s + (r.failures || 0), 0);
    const failureRate = totalCalls > 0 ? (totalFailures / totalCalls) * 100 : 0;
    const totalCost = cost.reduce((s, r) => s + (r.cost_usd || 0), 0);
    const totalConversations = daily.reduce((s, r) => s + (r.conversations || 0), 0);
    return { totalCalls, totalFailures, failureRate, totalCost, totalConversations };
  }, [tools, daily, cost]);

  const billingNotConfigured = useMemo(
    () => cost.some((r) => r.info && r.info.includes('Billing export not configured')),
    [cost],
  );

  return (
    <div className="flex flex-1 flex-col gap-4 p-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-violet-100">
            <BarChart3 className="h-5 w-5 text-violet-700" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">AI Agent — Analytics & Cost</h1>
            <p className="text-sm text-gray-500">
              BigQuery-backed: tool-call frequency, latency p50/p95, failure rate, Gemini spend.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
            {(['7d', '30d', 'mtd'] as RangeKey[]).map((r) => (
              <button
                key={r}
                onClick={() => setRange(r)}
                className={`px-3 py-1.5 text-sm font-medium ${
                  range === r ? 'bg-violet-600 text-white' : 'text-gray-600 hover:bg-gray-50'
                }`}
              >
                {rangeLabels[r]}
              </button>
            ))}
          </div>
          <button
            onClick={() => load(range)}
            className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm font-medium text-gray-600 shadow-sm hover:bg-gray-50"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
          {error}
        </div>
      )}

      {billingNotConfigured && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-[13px] text-amber-900">
          <AlertTriangle className="mr-1 inline h-4 w-4 text-amber-700" />
          Cloud Billing → BigQuery export isn't configured yet. Activity analytics work; cost
          numbers will populate once the export table id is set on Cloud Run via{' '}
          <code className="rounded bg-amber-100 px-1">BIGQUERY_BILLING_TABLE</code>.
        </div>
      )}

      {/* KPI cards */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          icon={<Activity className="h-5 w-5 text-violet-600" />}
          label="Tool calls"
          value={compact(totals.totalCalls)}
          sub={`${totals.totalConversations} conversations`}
        />
        <KpiCard
          icon={<AlertTriangle className={`h-5 w-5 ${totals.totalFailures > 0 ? 'text-rose-600' : 'text-gray-400'}`} />}
          label="Failures"
          value={compact(totals.totalFailures)}
          sub={`${totals.failureRate.toFixed(1)}% failure rate`}
          highlight={totals.totalFailures > 0}
        />
        <KpiCard
          icon={<Timer className="h-5 w-5 text-emerald-600" />}
          label="Tools tracked"
          value={String(tools.length)}
          sub="distinct tools called"
        />
        <KpiCard
          icon={<DollarSign className="h-5 w-5 text-emerald-600" />}
          label="Gemini spend"
          value={billingNotConfigured ? '—' : money(totals.totalCost)}
          sub={billingNotConfigured ? 'billing export not wired' : 'from Cloud Billing → BQ'}
          highlight={!billingNotConfigured && totals.totalCost > 0}
        />
      </div>

      {/* Tool-call breakdown */}
      <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-gray-200 bg-gray-50 px-4 py-2">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-700">
            <Sparkles className="h-4 w-4 text-violet-600" />
            Per-tool analytics
          </h2>
          <span className="text-xs text-gray-500">latency p50/p95 in ms</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr className="border-b border-gray-200 text-[11px] uppercase tracking-wide text-gray-600">
                <th className="px-4 py-2 text-left font-semibold">Tool</th>
                <th className="px-4 py-2 text-right font-semibold">Calls</th>
                <th className="px-4 py-2 text-right font-semibold">Failures</th>
                <th className="px-4 py-2 text-right font-semibold">p50 ms</th>
                <th className="px-4 py-2 text-right font-semibold">p95 ms</th>
                <th className="px-4 py-2 text-right font-semibold">avg ms</th>
              </tr>
            </thead>
            <tbody>
              {!loading && tools.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-400">
                    No tool calls in this range yet.
                  </td>
                </tr>
              )}
              {tools.map((row) => (
                <tr key={row.tool_name} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-2 font-mono text-xs font-semibold text-gray-900">{row.tool_name}</td>
                  <td className="px-4 py-2 text-right text-gray-700">{compact(row.calls)}</td>
                  <td className="px-4 py-2 text-right">
                    {row.failures > 0 ? (
                      <span className="text-rose-700">{row.failures}</span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-emerald-700">
                        <CheckCircle2 className="h-3 w-3" /> 0
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-2 text-right text-gray-600">{Math.round(row.p50_ms || 0)}</td>
                  <td className="px-4 py-2 text-right text-gray-600">{Math.round(row.p95_ms || 0)}</td>
                  <td className="px-4 py-2 text-right text-gray-600">{Math.round(row.avg_ms || 0)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Daily activity */}
      <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-gray-200 bg-gray-50 px-4 py-2">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-700">
            <CalendarRange className="h-4 w-4 text-violet-600" />
            Daily agent activity
          </h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr className="border-b border-gray-200 text-[11px] uppercase tracking-wide text-gray-600">
                <th className="px-4 py-2 text-left font-semibold">Date</th>
                <th className="px-4 py-2 text-right font-semibold">Calls</th>
                <th className="px-4 py-2 text-right font-semibold">Reads</th>
                <th className="px-4 py-2 text-right font-semibold">Writes</th>
                <th className="px-4 py-2 text-right font-semibold">Failures</th>
                <th className="px-4 py-2 text-right font-semibold">Conversations</th>
                <th className="px-4 py-2 text-right font-semibold">Users</th>
              </tr>
            </thead>
            <tbody>
              {!loading && daily.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-400">
                    No activity in this range.
                  </td>
                </tr>
              )}
              {daily.map((row) => (
                <tr key={row.day} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-2 font-mono text-xs text-gray-700">{row.day}</td>
                  <td className="px-4 py-2 text-right text-gray-700">{compact(row.calls)}</td>
                  <td className="px-4 py-2 text-right text-sky-700">{compact(row.reads)}</td>
                  <td className="px-4 py-2 text-right text-emerald-700">{compact(row.writes)}</td>
                  <td className="px-4 py-2 text-right">
                    {row.failures > 0 ? (
                      <span className="text-rose-700">{row.failures}</span>
                    ) : (
                      <span className="text-gray-400">0</span>
                    )}
                  </td>
                  <td className="px-4 py-2 text-right text-gray-700">{row.conversations}</td>
                  <td className="px-4 py-2 text-right text-gray-700">{row.users}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <p className="text-[11px] italic text-gray-400">
        Numbers come from BigQuery (autosales_analytics.tool_call_audit, mirrored async from Cloud SQL).
        Cost figures additionally read the Cloud Billing → BigQuery export when configured.
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

export default AgentAnalyticsPage;
