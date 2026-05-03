import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  BookOpen,
  ChevronDown,
  ChevronRight,
  RefreshCw,
  Search,
  ShieldCheck,
  Lock,
  AlertTriangle,
  Eye,
  Sparkles,
} from 'lucide-react';
import { getByModule, type AutoToolDescriptor } from '@/api/discovery';

const SAFETY_BADGES: Record<string, { label: string; classes: string; icon: JSX.Element }> = {
  PUBLIC_READ: {
    label: 'PUBLIC READ',
    classes: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    icon: <Eye className="h-3 w-3" />,
  },
  INTERNAL_READ: {
    label: 'INTERNAL READ',
    classes: 'bg-sky-50 text-sky-700 border-sky-200',
    icon: <Eye className="h-3 w-3" />,
  },
  WRITE_VIA_PROPOSE: {
    label: 'WRITE (PROPOSE)',
    classes: 'bg-amber-50 text-amber-700 border-amber-200',
    icon: <ShieldCheck className="h-3 w-3" />,
  },
  WRITE: {
    label: 'WRITE',
    classes: 'bg-orange-50 text-orange-700 border-orange-200',
    icon: <AlertTriangle className="h-3 w-3" />,
  },
  ADMIN_ONLY: {
    label: 'ADMIN ONLY',
    classes: 'bg-violet-50 text-violet-700 border-violet-200',
    icon: <Lock className="h-3 w-3" />,
  },
  AGENT_NO: {
    label: 'AGENT BLOCKED',
    classes: 'bg-rose-50 text-rose-700 border-rose-200',
    icon: <Lock className="h-3 w-3" />,
  },
};

const METHOD_BADGES: Record<string, string> = {
  GET: 'bg-sky-100 text-sky-800',
  POST: 'bg-emerald-100 text-emerald-800',
  PUT: 'bg-amber-100 text-amber-800',
  PATCH: 'bg-amber-100 text-amber-800',
  DELETE: 'bg-rose-100 text-rose-800',
};

function ApiDocsPage() {
  const [data, setData] = useState<Record<string, AutoToolDescriptor[]> | null>(null);
  const [counts, setCounts] = useState<Record<string, number> | null>(null);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState('');
  const [methodFilter, setMethodFilter] = useState<string>('');
  const [safetyFilter, setSafetyFilter] = useState<string>('');
  const [collapsedModules, setCollapsedModules] = useState<Set<string>>(new Set());
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set());

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await getByModule();
      if (!result) {
        setError('Unable to load endpoint catalog — admin or manager role required.');
        return;
      }
      setData(result.modules);
      setCounts(result.countsByLevel);
      setTotal(result.totalEndpoints);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const filtered = useMemo(() => {
    if (!data) return null;
    const out: Record<string, AutoToolDescriptor[]> = {};
    const s = search.trim().toLowerCase();
    Object.entries(data).forEach(([module, descriptors]) => {
      const matches = descriptors.filter((d) => {
        if (methodFilter && d.httpMethod !== methodFilter) return false;
        if (safetyFilter && d.safetyLevel !== safetyFilter) return false;
        if (!s) return true;
        return (
          d.name.toLowerCase().includes(s) ||
          d.path.toLowerCase().includes(s) ||
          d.description.toLowerCase().includes(s) ||
          d.controller.toLowerCase().includes(s)
        );
      });
      if (matches.length > 0) out[module] = matches;
    });
    return out;
  }, [data, search, methodFilter, safetyFilter]);

  const matchedTotal = useMemo(() => {
    if (!filtered) return 0;
    return Object.values(filtered).reduce((sum, arr) => sum + arr.length, 0);
  }, [filtered]);

  const toggleModule = (m: string) => {
    setCollapsedModules((prev) => {
      const next = new Set(prev);
      if (next.has(m)) next.delete(m);
      else next.add(m);
      return next;
    });
  };

  const toggleRow = (key: string) => {
    setExpandedRows((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  return (
    <div className="flex flex-1 flex-col gap-4 p-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100">
            <BookOpen className="h-5 w-5 text-indigo-700" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">API Documentation</h1>
            <p className="text-sm text-gray-500">
              Auto-generated from the running backend. {total} endpoints across {data ? Object.keys(data).length : 0} modules.
            </p>
          </div>
        </div>
        <button
          onClick={load}
          className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm font-medium text-gray-600 shadow-sm hover:bg-gray-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Honesty banner */}
      <div className="flex items-start gap-2 rounded-lg border border-indigo-200 bg-indigo-50 px-3 py-2 text-[13px] text-indigo-900">
        <Sparkles className="mt-0.5 h-4 w-4 flex-shrink-0 text-indigo-700" />
        <div>
          <span className="font-semibold">One source, three consumers:</span> the same Spring controller scan
          that documents your APIs here also feeds the AI agent's runtime tool retrieval and the admin
          governance view. New endpoints appear automatically on next deploy — no separate documentation pipeline.
        </div>
      </div>

      {/* KPI strip */}
      {counts && (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          <CountCard label="Public reads" value={counts.PUBLIC_READ ?? 0} colors="bg-emerald-50 text-emerald-700 border-emerald-200" />
          <CountCard label="Internal reads" value={counts.INTERNAL_READ ?? 0} colors="bg-sky-50 text-sky-700 border-sky-200" />
          <CountCard label="Writes (propose)" value={counts.WRITE_VIA_PROPOSE ?? 0} colors="bg-amber-50 text-amber-700 border-amber-200" />
          <CountCard label="Other writes" value={counts.WRITE ?? 0} colors="bg-orange-50 text-orange-700 border-orange-200" />
          <CountCard label="Admin only" value={counts.ADMIN_ONLY ?? 0} colors="bg-violet-50 text-violet-700 border-violet-200" />
          <CountCard label="Agent blocked" value={counts.AGENT_NO ?? 0} colors="bg-rose-50 text-rose-700 border-rose-200" />
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2 rounded-lg border border-gray-200 bg-white p-2 shadow-sm">
        <div className="relative flex-1 min-w-[280px]">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search by path, name, controller, or description..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-gray-200 bg-white py-2 pl-8 pr-3 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>
        <select
          value={methodFilter}
          onChange={(e) => setMethodFilter(e.target.value)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm"
        >
          <option value="">All methods</option>
          <option value="GET">GET</option>
          <option value="POST">POST</option>
          <option value="PUT">PUT</option>
          <option value="PATCH">PATCH</option>
          <option value="DELETE">DELETE</option>
        </select>
        <select
          value={safetyFilter}
          onChange={(e) => setSafetyFilter(e.target.value)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm"
        >
          <option value="">All safety levels</option>
          <option value="PUBLIC_READ">Public reads</option>
          <option value="INTERNAL_READ">Internal reads</option>
          <option value="WRITE_VIA_PROPOSE">Writes (via propose)</option>
          <option value="WRITE">Other writes</option>
          <option value="ADMIN_ONLY">Admin only</option>
          <option value="AGENT_NO">Agent blocked</option>
        </select>
        <div className="px-2 text-xs text-gray-500">{matchedTotal} match</div>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
          {error}
        </div>
      )}

      {/* Modules */}
      <div className="flex flex-col gap-3">
        {filtered &&
          Object.entries(filtered).map(([module, descriptors]) => {
            const collapsed = collapsedModules.has(module);
            return (
              <div
                key={module}
                className="rounded-lg border border-gray-200 bg-white shadow-sm"
              >
                <button
                  onClick={() => toggleModule(module)}
                  className="flex w-full items-center justify-between border-b border-gray-200 bg-gray-50 px-4 py-2 hover:bg-gray-100"
                >
                  <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-700">
                    {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                    {module}
                    <span className="rounded-full bg-gray-200 px-2 py-0.5 text-[10px] font-medium text-gray-700">
                      {descriptors.length}
                    </span>
                  </h2>
                </button>
                {!collapsed && (
                  <div className="divide-y divide-gray-100">
                    {descriptors.map((d) => {
                      const key = `${d.httpMethod} ${d.path}`;
                      const expanded = expandedRows.has(key);
                      const safety = SAFETY_BADGES[d.safetyLevel] || SAFETY_BADGES.PUBLIC_READ;
                      const methodCls = METHOD_BADGES[d.httpMethod] || 'bg-gray-100 text-gray-700';
                      return (
                        <div key={key} className="px-4 py-2.5 hover:bg-gray-50">
                          <button
                            onClick={() => toggleRow(key)}
                            className="flex w-full items-start gap-2 text-left"
                          >
                            <span
                              className={`mt-0.5 inline-flex w-14 items-center justify-center rounded px-1.5 py-0.5 font-mono text-[11px] font-bold ${methodCls}`}
                            >
                              {d.httpMethod}
                            </span>
                            <div className="flex-1">
                              <div className="flex flex-wrap items-center gap-2">
                                <code className="font-mono text-[13px] font-semibold text-gray-900">
                                  {d.path}
                                </code>
                                <span
                                  className={`inline-flex items-center gap-1 rounded border px-1.5 py-0.5 text-[10px] font-semibold ${safety.classes}`}
                                >
                                  {safety.icon}
                                  {safety.label}
                                </span>
                              </div>
                              <p className="mt-0.5 text-[12px] text-gray-600">{d.description}</p>
                              <div className="mt-1 flex flex-wrap gap-1">
                                {d.tags?.map((t) => (
                                  <span
                                    key={t}
                                    className="rounded bg-gray-100 px-1.5 py-0.5 font-mono text-[10px] text-gray-600"
                                  >
                                    {t}
                                  </span>
                                ))}
                              </div>
                            </div>
                            {expanded ? (
                              <ChevronDown className="mt-1 h-4 w-4 text-gray-400" />
                            ) : (
                              <ChevronRight className="mt-1 h-4 w-4 text-gray-400" />
                            )}
                          </button>
                          {expanded && (
                            <div className="ml-16 mt-2 grid grid-cols-1 gap-2 rounded bg-gray-50 p-3 text-xs lg:grid-cols-2">
                              <div>
                                <p className="mb-1 font-semibold uppercase tracking-wide text-gray-500 text-[10px]">
                                  Implementation
                                </p>
                                <p>
                                  Controller:{' '}
                                  <code className="rounded bg-white px-1">{d.controller}</code>
                                </p>
                                <p>
                                  Method:{' '}
                                  <code className="rounded bg-white px-1">{d.javaMethod}</code>
                                </p>
                                <p>
                                  Synthetic name: <code className="rounded bg-white px-1">{d.name}</code>
                                </p>
                              </div>
                              <div>
                                <p className="mb-1 font-semibold uppercase tracking-wide text-gray-500 text-[10px]">
                                  Parameters ({d.parameters?.length ?? 0})
                                </p>
                                {(d.parameters?.length ?? 0) === 0 ? (
                                  <p className="italic text-gray-400">none</p>
                                ) : (
                                  <ul className="space-y-0.5">
                                    {d.parameters.map((p, i) => (
                                      <li key={i}>
                                        <code className="rounded bg-white px-1">{p.name}</code>
                                        <span className="text-gray-500"> ({p.type}, {p.kind}</span>
                                        {p.required === 'true' && (
                                          <span className="ml-1 text-rose-600 font-semibold">required</span>
                                        )}
                                        <span className="text-gray-500">)</span>
                                      </li>
                                    ))}
                                  </ul>
                                )}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        {filtered && Object.keys(filtered).length === 0 && !loading && (
          <div className="rounded-lg border border-gray-200 bg-white p-12 text-center text-sm text-gray-400">
            No endpoints match the current filters.
          </div>
        )}
      </div>

      <p className="text-[11px] italic text-gray-400">
        Catalog is generated at backend startup from Spring's RequestMappingHandlerMapping. Safety levels are
        applied via path-prefix rules; admin can refine per endpoint in a future release.
      </p>
    </div>
  );
}

function CountCard({ label, value, colors }: { label: string; value: number; colors: string }) {
  return (
    <div className={`rounded-lg border p-3 ${colors}`}>
      <p className="text-[10px] font-semibold uppercase tracking-wide opacity-80">{label}</p>
      <p className="mt-0.5 text-2xl font-bold">{value}</p>
    </div>
  );
}

export default ApiDocsPage;
