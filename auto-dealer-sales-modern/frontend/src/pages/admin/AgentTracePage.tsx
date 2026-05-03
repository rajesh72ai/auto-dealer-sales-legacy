import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  ChevronRight,
  Eye,
  RefreshCw,
  Search,
  ShieldAlert,
  Sparkles,
  Terminal,
} from 'lucide-react';
import {
  getRecentConversations,
  getTrace,
  type RecentConversation,
  type TraceResult,
  type TraceRow,
} from '@/api/agentTrace';

function formatTs(iso: string | null | undefined): string {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString();
  } catch {
    return iso;
  }
}

function tierBadge(tier: string): { label: string; classes: string } {
  switch (tier) {
    case 'R':
      return { label: 'READ', classes: 'bg-sky-100 text-sky-800' };
    case 'A':
      return { label: 'A', classes: 'bg-emerald-100 text-emerald-800' };
    case 'B':
      return { label: 'B', classes: 'bg-amber-100 text-amber-800' };
    case 'C':
      return { label: 'C', classes: 'bg-violet-100 text-violet-800' };
    case 'D':
      return { label: 'D', classes: 'bg-rose-100 text-rose-800' };
    default:
      return { label: tier || '?', classes: 'bg-gray-100 text-gray-700' };
  }
}

function statusBadge(status: string): { classes: string; icon: JSX.Element } {
  const base = 'inline-flex items-center gap-1 rounded px-2 py-0.5 text-[11px] font-semibold';
  switch (status) {
    case 'EXECUTED':
      return {
        classes: `${base} bg-emerald-50 text-emerald-700 border border-emerald-200`,
        icon: <CheckCircle2 className="h-3 w-3" />,
      };
    case 'PROPOSED':
      return {
        classes: `${base} bg-violet-50 text-violet-700 border border-violet-200`,
        icon: <Eye className="h-3 w-3" />,
      };
    case 'REJECTED':
      return {
        classes: `${base} bg-gray-50 text-gray-700 border border-gray-200`,
        icon: <ShieldAlert className="h-3 w-3" />,
      };
    case 'FAILED':
      return {
        classes: `${base} bg-rose-50 text-rose-700 border border-rose-200`,
        icon: <AlertTriangle className="h-3 w-3" />,
      };
    case 'CONFIRMED':
      return {
        classes: `${base} bg-sky-50 text-sky-700 border border-sky-200`,
        icon: <CheckCircle2 className="h-3 w-3" />,
      };
    default:
      return {
        classes: `${base} bg-gray-50 text-gray-700 border border-gray-200`,
        icon: <Activity className="h-3 w-3" />,
      };
  }
}

function safeJsonPreview(json: string | null): string {
  if (!json) return '';
  if (json.length <= 220) return json;
  return json.slice(0, 220) + '…';
}

function AgentTracePage() {
  const [recent, setRecent] = useState<RecentConversation[]>([]);
  const [recentLoading, setRecentLoading] = useState(true);
  const [recentError, setRecentError] = useState<string | null>(null);

  const [selected, setSelected] = useState<string | null>(null);
  const [trace, setTrace] = useState<TraceResult | null>(null);
  const [traceLoading, setTraceLoading] = useState(false);
  const [traceError, setTraceError] = useState<string | null>(null);

  const [filter, setFilter] = useState('');
  const [expanded, setExpanded] = useState<Set<number>>(new Set());

  const loadRecent = useCallback(async () => {
    setRecentLoading(true);
    setRecentError(null);
    try {
      const result = await getRecentConversations(50);
      if (!result) {
        setRecentError('Unable to load recent conversations — admin or manager role required.');
      } else {
        setRecent(result);
        if (!selected && result.length > 0) {
          setSelected(result[0].conversationId);
        }
      }
    } catch (e) {
      setRecentError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setRecentLoading(false);
    }
  }, [selected]);

  const loadTrace = useCallback(async (convId: string) => {
    setTraceLoading(true);
    setTraceError(null);
    setExpanded(new Set());
    try {
      const result = await getTrace(convId);
      if (!result) {
        setTraceError('Unable to load trace.');
        setTrace(null);
      } else {
        setTrace(result);
      }
    } catch (e) {
      setTraceError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setTraceLoading(false);
    }
  }, []);

  useEffect(() => {
    loadRecent();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (selected) loadTrace(selected);
  }, [selected, loadTrace]);

  const filteredRecent = useMemo(() => {
    const f = filter.trim().toLowerCase();
    if (!f) return recent;
    return recent.filter(
      (c) =>
        c.conversationId.toLowerCase().includes(f) ||
        c.userId.toLowerCase().includes(f) ||
        (c.dealerCode || '').toLowerCase().includes(f),
    );
  }, [recent, filter]);

  const toggleRow = (id: number) =>
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const stats = useMemo(() => {
    if (!trace) return null;
    const reads = trace.rows.filter((r) => r.tier === 'R').length;
    const writes = trace.rows.filter((r) => r.tier !== 'R').length;
    const failed = trace.rows.filter((r) => r.status === 'FAILED').length;
    const latencies = trace.rows
      .filter((r) => r.elapsedMs && r.elapsedMs > 0)
      .map((r) => r.elapsedMs as number)
      .sort((a, b) => a - b);
    const p50 = latencies.length ? latencies[Math.floor(latencies.length / 2)] : 0;
    const p95 = latencies.length ? latencies[Math.floor(latencies.length * 0.95)] : 0;
    return { reads, writes, failed, p50, p95 };
  }, [trace]);

  return (
    <div className="flex flex-1 flex-col gap-4 p-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100">
            <Sparkles className="h-5 w-5 text-indigo-700" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">AI Agent — Tool-Call Trace</h1>
            <p className="text-sm text-gray-500">
              Per-conversation timeline of every tool call, proposal, and execution.
            </p>
          </div>
        </div>
        <button
          onClick={loadRecent}
          className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm font-medium text-gray-600 shadow-sm hover:bg-gray-50"
        >
          <RefreshCw className={`h-4 w-4 ${recentLoading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[300px_1fr]">
        {/* Conversations list */}
        <aside className="flex flex-col gap-2">
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Filter by id, user, dealer…"
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="w-full rounded-lg border border-gray-200 bg-white py-2 pl-8 pr-3 text-sm shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>
          {recentError && (
            <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
              {recentError}
            </div>
          )}
          <div className="flex max-h-[70vh] flex-col gap-1 overflow-y-auto rounded-lg border border-gray-200 bg-white p-1 shadow-sm">
            {filteredRecent.length === 0 && !recentLoading && (
              <div className="px-3 py-6 text-center text-xs text-gray-400">No conversations.</div>
            )}
            {filteredRecent.map((c) => (
              <button
                key={c.conversationId}
                onClick={() => setSelected(c.conversationId)}
                className={`flex flex-col items-start gap-0.5 rounded px-3 py-2 text-left transition-colors ${
                  selected === c.conversationId
                    ? 'bg-indigo-50 text-indigo-900 ring-1 ring-indigo-200'
                    : 'hover:bg-gray-50'
                }`}
              >
                <div className="flex w-full items-center justify-between gap-2">
                  <span className="truncate font-mono text-xs">{c.conversationId.slice(0, 12)}…</span>
                  <ChevronRight className="h-3 w-3 text-gray-400" />
                </div>
                <div className="flex w-full items-center justify-between gap-2 text-[11px] text-gray-500">
                  <span>{c.userId}</span>
                  <span>{c.rowCount} calls</span>
                </div>
                <div className="text-[10px] text-gray-400">{formatTs(c.lastActivityTs)}</div>
              </button>
            ))}
          </div>
        </aside>

        {/* Trace timeline */}
        <main className="flex flex-col gap-3">
          {!selected && (
            <div className="rounded-lg border border-gray-200 bg-white p-12 text-center text-sm text-gray-400">
              Select a conversation on the left to view its trace.
            </div>
          )}

          {selected && (
            <>
              {/* Stats strip */}
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-5">
                <StatBox label="Conversation" value={selected.slice(0, 12) + '…'} mono />
                <StatBox label="Total calls" value={String(trace?.totalRows ?? 0)} />
                <StatBox label="Reads / Writes" value={`${stats?.reads ?? 0} / ${stats?.writes ?? 0}`} />
                <StatBox label="Failed" value={String(stats?.failed ?? 0)} highlight={(stats?.failed ?? 0) > 0} />
                <StatBox label="Latency p50/p95" value={`${stats?.p50 ?? 0} / ${stats?.p95 ?? 0} ms`} />
              </div>

              {traceError && (
                <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
                  {traceError}
                </div>
              )}

              {/* Timeline */}
              <div className="rounded-lg border border-gray-200 bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-gray-200 bg-gray-50 px-4 py-2">
                  <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-700">
                    <Terminal className="h-4 w-4 text-indigo-600" />
                    Timeline
                  </h2>
                  <span className="text-xs text-gray-500">click a row to expand args / result</span>
                </div>
                <div className="overflow-x-auto">
                  {traceLoading && !trace && (
                    <div className="px-4 py-12 text-center text-sm text-gray-400">Loading…</div>
                  )}
                  {trace && trace.rows.length === 0 && (
                    <div className="px-4 py-12 text-center text-sm text-gray-400">
                      No tool calls recorded for this conversation yet.
                    </div>
                  )}
                  {trace && trace.rows.length > 0 && (
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50">
                        <tr className="border-b border-gray-200 text-[11px] uppercase tracking-wide text-gray-600">
                          <th className="px-3 py-2 text-left font-semibold">Time</th>
                          <th className="px-3 py-2 text-left font-semibold">User</th>
                          <th className="px-3 py-2 text-left font-semibold">Tool</th>
                          <th className="px-3 py-2 text-left font-semibold">Tier</th>
                          <th className="px-3 py-2 text-left font-semibold">Status</th>
                          <th className="px-3 py-2 text-right font-semibold">Latency</th>
                        </tr>
                      </thead>
                      <tbody>
                        {trace.rows.map((row) => (
                          <TraceTimelineRow
                            key={row.auditId}
                            row={row}
                            expanded={expanded.has(row.auditId)}
                            onToggle={() => toggleRow(row.auditId)}
                          />
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>
            </>
          )}
        </main>
      </div>
    </div>
  );
}

function StatBox({
  label,
  value,
  highlight,
  mono,
}: {
  label: string;
  value: string;
  highlight?: boolean;
  mono?: boolean;
}) {
  return (
    <div
      className={`rounded-lg border p-3 ${
        highlight ? 'border-rose-200 bg-rose-50' : 'border-gray-200 bg-white'
      }`}
    >
      <p className="text-[10px] font-semibold uppercase tracking-wide text-gray-500">{label}</p>
      <p className={`mt-1 text-base font-bold text-gray-900 ${mono ? 'font-mono text-[13px]' : ''}`}>
        {value}
      </p>
    </div>
  );
}

function TraceTimelineRow({
  row,
  expanded,
  onToggle,
}: {
  row: TraceRow;
  expanded: boolean;
  onToggle: () => void;
}) {
  const tier = tierBadge(row.tier);
  const status = statusBadge(row.status);
  return (
    <>
      <tr
        className="cursor-pointer border-b border-gray-100 hover:bg-gray-50"
        onClick={onToggle}
      >
        <td className="px-3 py-2 font-mono text-xs text-gray-600">{formatTs(row.createdTs)}</td>
        <td className="px-3 py-2 text-xs text-gray-700">
          {row.userId}
          {row.dealerCode && <span className="ml-1 text-gray-400">/ {row.dealerCode}</span>}
        </td>
        <td className="px-3 py-2 font-mono text-xs font-semibold text-gray-900">{row.toolName}</td>
        <td className="px-3 py-2">
          <span className={`inline-flex rounded px-1.5 py-0.5 text-[10px] font-bold ${tier.classes}`}>
            {tier.label}
          </span>
        </td>
        <td className="px-3 py-2">
          <span className={status.classes}>
            {status.icon}
            {row.status}
          </span>
        </td>
        <td className="px-3 py-2 text-right text-xs text-gray-600">
          {row.elapsedMs != null ? `${row.elapsedMs} ms` : '—'}
        </td>
      </tr>
      {expanded && (
        <tr className="border-b border-gray-100 bg-gray-50">
          <td colSpan={6} className="px-6 py-3">
            <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
              <DetailBlock label="Args / Payload" json={row.payloadJson} />
              <DetailBlock label="Preview" json={row.previewJson} />
              <DetailBlock label="Result" json={row.responseJson} />
            </div>
            {row.errorMessage && (
              <div className="mt-2 rounded border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-800">
                <span className="font-semibold">Error:</span> {row.errorMessage}
              </div>
            )}
            {(row.proposalToken || row.endpoint) && (
              <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] text-gray-500">
                {row.proposalToken && (
                  <span>
                    proposalToken: <code className="rounded bg-white px-1">{row.proposalToken}</code>
                  </span>
                )}
                {row.endpoint && (
                  <span>
                    endpoint: <code className="rounded bg-white px-1">{row.endpoint}</code>
                  </span>
                )}
                {row.reversible && <span className="text-emerald-600">reversible</span>}
                {row.undone && <span className="text-amber-600">undone</span>}
              </div>
            )}
          </td>
        </tr>
      )}
    </>
  );
}

function DetailBlock({ label, json }: { label: string; json: string | null }) {
  if (!json) {
    return (
      <div>
        <p className="mb-1 text-[10px] font-semibold uppercase tracking-wide text-gray-500">
          {label}
        </p>
        <p className="rounded border border-gray-200 bg-white px-2 py-1 text-xs italic text-gray-400">
          (none)
        </p>
      </div>
    );
  }
  return (
    <div>
      <p className="mb-1 text-[10px] font-semibold uppercase tracking-wide text-gray-500">{label}</p>
      <pre className="max-h-48 overflow-auto rounded border border-gray-200 bg-white px-2 py-1 text-[11px] leading-tight text-gray-700">
        {safeJsonPreview(json)}
      </pre>
    </div>
  );
}

export default AgentTracePage;
