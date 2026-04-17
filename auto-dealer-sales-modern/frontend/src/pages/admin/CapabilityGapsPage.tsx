import { useCallback, useEffect, useState } from 'react';
import {
  AlertTriangle,
  ArrowUpRight,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  Clock,
  Eye,
  Lightbulb,
  ListTodo,
  RefreshCw,
  Sparkles,
  XCircle,
} from 'lucide-react';
import {
  getGapDashboard,
  getGapList,
  updateGapStatus,
} from '@/api/capabilityGaps';
import type { CapabilityGap, GapDashboard, GapSummaryItem } from '@/api/capabilityGaps';

const STATUS_COLORS: Record<string, string> = {
  NEW: 'bg-blue-100 text-blue-800',
  REVIEWED: 'bg-amber-100 text-amber-800',
  PLANNED: 'bg-violet-100 text-violet-800',
  IMPLEMENTED: 'bg-emerald-100 text-emerald-800',
  WONT_DO: 'bg-gray-100 text-gray-600',
};

const PRIORITY_COLORS: Record<string, string> = {
  CRITICAL: 'bg-rose-100 text-rose-800',
  HIGH: 'bg-orange-100 text-orange-800',
  MEDIUM: 'bg-sky-100 text-sky-800',
  LOW: 'bg-gray-100 text-gray-600',
};

const CATEGORY_COLORS: Record<string, string> = {
  CRUD: 'bg-blue-50 text-blue-700',
  CONFIG: 'bg-amber-50 text-amber-700',
  BATCH: 'bg-purple-50 text-purple-700',
  REPORTING: 'bg-emerald-50 text-emerald-700',
  WORKFLOW: 'bg-pink-50 text-pink-700',
  INTEGRATION: 'bg-cyan-50 text-cyan-700',
  UNKNOWN: 'bg-gray-50 text-gray-600',
};

type FilterStatus = 'ALL' | 'NEW' | 'REVIEWED' | 'PLANNED' | 'IMPLEMENTED' | 'WONT_DO';

function CapabilityGapsPage() {
  const [dashboard, setDashboard] = useState<GapDashboard | null>(null);
  const [gaps, setGaps] = useState<CapabilityGap[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [page, setPage] = useState(0);
  const [filterStatus, setFilterStatus] = useState<FilterStatus>('ALL');
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadDashboard = useCallback(async () => {
    const d = await getGapDashboard();
    if (d) setDashboard(d);
  }, []);

  const loadGaps = useCallback(async (p: number, status: FilterStatus) => {
    setLoading(true);
    setError(null);
    try {
      const result = await getGapList(p, 15, status === 'ALL' ? undefined : status);
      if (result) {
        setGaps(result.content);
        setTotalElements(result.totalElements);
      } else {
        setError('Failed to load capability gaps. Ensure you have ADMIN role.');
      }
    } catch {
      setError('Failed to load data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadDashboard();
    loadGaps(page, filterStatus);
  }, [loadDashboard, loadGaps, page, filterStatus]);

  const handleStatusChange = async (gapId: number, newStatus: string) => {
    const ok = await updateGapStatus(gapId, newStatus);
    if (ok) {
      loadGaps(page, filterStatus);
      loadDashboard();
    }
  };

  const totalPages = Math.ceil(totalElements / 15);

  return (
    <div className="flex flex-1 flex-col gap-4 p-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
            <Lightbulb className="h-5 w-5 text-amber-700" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">AI Capability Backlog</h1>
            <p className="text-sm text-gray-500">
              Actions users asked the AI to perform that aren't supported yet. Ranked by demand.
            </p>
          </div>
        </div>
        <button
          onClick={() => { loadDashboard(); loadGaps(page, filterStatus); }}
          className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm font-medium text-gray-600 shadow-sm transition-colors hover:bg-gray-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">{error}</div>
      )}

      {/* KPI cards */}
      {dashboard && (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <KpiCard icon={<Clock className="h-5 w-5 text-blue-600" />} label="New" value={dashboard.totalNew} color="blue" />
          <KpiCard icon={<Eye className="h-5 w-5 text-amber-600" />} label="Reviewed" value={dashboard.totalReviewed} color="amber" />
          <KpiCard icon={<ListTodo className="h-5 w-5 text-violet-600" />} label="Planned" value={dashboard.totalPlanned} color="violet" />
          <KpiCard icon={<CheckCircle2 className="h-5 w-5 text-emerald-600" />} label="Implemented" value={dashboard.totalImplemented} color="emerald" />
        </div>
      )}

      {/* Top requested — frequency rank */}
      {dashboard && dashboard.topRequested.length > 0 && (
        <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
          <div className="border-b border-gray-200 bg-gray-50 px-4 py-2">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <ArrowUpRight className="h-4 w-4 text-amber-600" />
              Most Requested Capabilities
            </h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr className="border-b border-gray-200">
                  <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">Rank</th>
                  <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">App</th>
                  <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">Capability</th>
                  <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">Category</th>
                  <th className="px-4 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-600">Requests</th>
                  <th className="px-4 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-600">Last Asked</th>
                </tr>
              </thead>
              <tbody>
                {dashboard.topRequested.map((item: GapSummaryItem, idx: number) => (
                  <tr key={item.capability} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="px-4 py-2 text-gray-500">#{idx + 1}</td>
                    <td className="px-4 py-2 text-xs font-medium text-gray-700">{item.appId}</td>
                    <td className="px-4 py-2 font-mono text-xs font-semibold text-gray-800">{item.capability}</td>
                    <td className="px-4 py-2">
                      <span className={`inline-block rounded px-2 py-0.5 text-[11px] font-medium ${CATEGORY_COLORS[item.category] ?? CATEGORY_COLORS.UNKNOWN}`}>
                        {item.category}
                      </span>
                    </td>
                    <td className="px-4 py-2 text-right font-bold text-gray-800">{item.requestCount}</td>
                    <td className="px-4 py-2 text-xs text-gray-500">{item.lastRequested?.slice(0, 16).replace('T', ' ')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Filter bar */}
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium text-gray-600">Filter:</span>
        <div className="flex overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
          {(['ALL', 'NEW', 'REVIEWED', 'PLANNED', 'IMPLEMENTED', 'WONT_DO'] as FilterStatus[]).map((s) => (
            <button
              key={s}
              onClick={() => { setFilterStatus(s); setPage(0); }}
              className={`px-3 py-1.5 text-xs font-medium transition-colors ${
                filterStatus === s ? 'bg-violet-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-50'
              }`}
            >
              {s === 'WONT_DO' ? "Won't Do" : s.charAt(0) + s.slice(1).toLowerCase()}
            </button>
          ))}
        </div>
        <span className="ml-auto text-xs text-gray-400">{totalElements} total</span>
      </div>

      {/* Gap list — expandable rows */}
      <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
        {loading && gaps.length === 0 && (
          <div className="px-4 py-8 text-center text-sm text-gray-400">Loading...</div>
        )}
        {!loading && gaps.length === 0 && (
          <div className="px-4 py-8 text-center text-sm text-gray-400">
            No capability gaps logged yet. Once the AI agent declines a request, it will appear here.
          </div>
        )}
        {gaps.map((gap) => {
          const isExpanded = expandedId === gap.gapId;
          return (
            <div key={gap.gapId} className="border-b border-gray-100 last:border-b-0">
              <button
                onClick={() => setExpandedId(isExpanded ? null : gap.gapId)}
                className="flex w-full items-center gap-3 px-4 py-3 text-left hover:bg-gray-50"
              >
                {isExpanded
                  ? <ChevronDown className="h-4 w-4 flex-shrink-0 text-gray-400" />
                  : <ChevronRight className="h-4 w-4 flex-shrink-0 text-gray-400" />}
                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-2">
                    <span className="font-mono text-sm font-semibold text-gray-800">{gap.requestedCapability}</span>
                    <span className={`inline-block rounded px-1.5 py-0.5 text-[10px] font-medium ${CATEGORY_COLORS[gap.category] ?? CATEGORY_COLORS.UNKNOWN}`}>
                      {gap.category}
                    </span>
                    <span className={`inline-block rounded px-1.5 py-0.5 text-[10px] font-medium ${PRIORITY_COLORS[gap.priorityHint] ?? PRIORITY_COLORS.MEDIUM}`}>
                      {gap.priorityHint}
                    </span>
                    <span className={`inline-block rounded px-1.5 py-0.5 text-[10px] font-medium ${STATUS_COLORS[gap.status] ?? STATUS_COLORS.NEW}`}>
                      {gap.status}
                    </span>
                  </span>
                  <span className="mt-0.5 block truncate text-xs text-gray-500">{gap.userInput}</span>
                </span>
                <span className="flex-shrink-0 text-[11px] text-gray-400">{gap.createdTs?.slice(0, 16).replace('T', ' ')}</span>
              </button>
              {isExpanded && (
                <div className="border-t border-gray-100 bg-gray-50/50 px-4 py-3">
                  <div className="grid grid-cols-1 gap-3 text-sm lg:grid-cols-2">
                    <DetailBlock label="User Input" value={gap.userInput} icon={<Sparkles className="h-3.5 w-3.5" />} />
                    <DetailBlock label="Scenario" value={gap.scenarioDescription} icon={<AlertTriangle className="h-3.5 w-3.5" />} />
                    <DetailBlock label="Agent Reasoning" value={gap.agentReasoning} icon={<XCircle className="h-3.5 w-3.5" />} />
                    <DetailBlock label="Suggested Alternative" value={gap.suggestedAlternative ?? '—'} icon={<Lightbulb className="h-3.5 w-3.5" />} />
                  </div>
                  <div className="mt-3 flex items-center gap-4 border-t border-gray-200 pt-3 text-xs text-gray-500">
                    <span>App: <strong>{gap.appName}</strong> ({gap.appId})</span>
                    <span>User: <strong>{gap.userId ?? 'unknown'}</strong></span>
                    <span>Dealer: <strong>{gap.dealerCode ?? '—'}</strong></span>
                    <span>Source: <strong>{gap.sourceSystem}</strong></span>
                    <span className="ml-auto flex gap-1.5">
                      {gap.status !== 'REVIEWED' && (
                        <ActionBtn label="Mark Reviewed" onClick={() => handleStatusChange(gap.gapId, 'REVIEWED')} />
                      )}
                      {gap.status !== 'PLANNED' && (
                        <ActionBtn label="Plan" onClick={() => handleStatusChange(gap.gapId, 'PLANNED')} />
                      )}
                      {gap.status !== 'IMPLEMENTED' && (
                        <ActionBtn label="Done" onClick={() => handleStatusChange(gap.gapId, 'IMPLEMENTED')} color="emerald" />
                      )}
                      {gap.status !== 'WONT_DO' && (
                        <ActionBtn label="Won't Do" onClick={() => handleStatusChange(gap.gapId, 'WONT_DO')} color="gray" />
                      )}
                    </span>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-2">
          <button
            disabled={page === 0}
            onClick={() => setPage(page - 1)}
            className="rounded border border-gray-200 px-3 py-1 text-sm disabled:opacity-40"
          >
            Prev
          </button>
          <span className="text-sm text-gray-600">
            Page {page + 1} of {totalPages}
          </span>
          <button
            disabled={page >= totalPages - 1}
            onClick={() => setPage(page + 1)}
            className="rounded border border-gray-200 px-3 py-1 text-sm disabled:opacity-40"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}

function DetailBlock({ label, value, icon }: { label: string; value: string; icon: React.ReactNode }) {
  return (
    <div>
      <p className="mb-1 flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wide text-gray-500">
        {icon} {label}
      </p>
      <p className="whitespace-pre-wrap text-sm text-gray-700">{value}</p>
    </div>
  );
}

function KpiCard({ icon, label, value, color = 'gray' }: { icon: React.ReactNode; label: string; value: number; color?: string }) {
  const border = color === 'blue' ? 'border-blue-200 bg-blue-50/40'
    : color === 'amber' ? 'border-amber-200 bg-amber-50/40'
    : color === 'violet' ? 'border-violet-200 bg-violet-50/40'
    : color === 'emerald' ? 'border-emerald-200 bg-emerald-50/40'
    : 'border-gray-200 bg-white';
  return (
    <div className={`rounded-lg border p-4 shadow-sm ${border}`}>
      <div className="mb-1 flex items-center gap-2">
        {icon}
        <span className="text-[11px] font-semibold uppercase tracking-wide text-gray-500">{label}</span>
      </div>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
    </div>
  );
}

function ActionBtn({ label, onClick, color = 'violet' }: { label: string; onClick: () => void; color?: string }) {
  const cls = color === 'emerald'
    ? 'border-emerald-300 text-emerald-700 hover:bg-emerald-50'
    : color === 'gray'
      ? 'border-gray-300 text-gray-600 hover:bg-gray-50'
      : 'border-violet-300 text-violet-700 hover:bg-violet-50';
  return (
    <button onClick={onClick} className={`rounded border px-2 py-0.5 text-[11px] font-medium transition-colors ${cls}`}>
      {label}
    </button>
  );
}

export default CapabilityGapsPage;
