import { useState, useEffect, useCallback } from 'react';
import { FileSearch, BarChart3 } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import FormField from '@/components/shared/FormField';
import { searchAuditLog, getAuditStats } from '@/api/auditLog';
import type { AuditLogEntry } from '@/api/auditLog';

const ACTION_TYPES = [
  { value: 'INS', label: 'Insert' },
  { value: 'UPD', label: 'Update' },
  { value: 'DEL', label: 'Delete' },
  { value: 'APV', label: 'Approve' },
];

const ACTION_BADGE_COLORS: Record<string, { bg: string; text: string }> = {
  INS: { bg: 'bg-emerald-50', text: 'text-emerald-700' },
  UPD: { bg: 'bg-blue-50', text: 'text-blue-700' },
  DEL: { bg: 'bg-red-50', text: 'text-red-700' },
  APV: { bg: 'bg-purple-50', text: 'text-purple-700' },
};

const ACTION_LABELS: Record<string, string> = {
  INS: 'INSERT',
  UPD: 'UPDATE',
  DEL: 'DELETE',
  APV: 'APPROVE',
};

function ActionBadge({ action }: { action: string }) {
  const colors = ACTION_BADGE_COLORS[action] || { bg: 'bg-gray-100', text: 'text-gray-600' };
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${colors.bg} ${colors.text}`}>
      {ACTION_LABELS[action] || action}
    </span>
  );
}

function AuditLogPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Filters
  const [userIdFilter, setUserIdFilter] = useState('');
  const [tableNameFilter, setTableNameFilter] = useState('');
  const [actionFilter, setActionFilter] = useState('');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  // Stats
  const [stats, setStats] = useState<Record<string, number>>({});
  const [showStats, setShowStats] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await searchAuditLog({
        userId: userIdFilter || undefined,
        tableName: tableNameFilter || undefined,
        actionType: actionFilter || undefined,
        from: fromDate ? fromDate + 'T00:00:00' : undefined,
        to: toDate ? toDate + 'T23:59:59' : undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load audit log');
    } finally {
      setLoading(false);
    }
  }, [page, userIdFilter, tableNameFilter, actionFilter, fromDate, toDate, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const loadStats = async () => {
    try {
      const data = await getAuditStats();
      setStats(data);
      setShowStats(true);
    } catch {
      addToast('error', 'Failed to load audit statistics');
    }
  };

  const clearFilters = () => {
    setUserIdFilter('');
    setTableNameFilter('');
    setActionFilter('');
    setFromDate('');
    setToDate('');
    setPage(0);
  };

  const hasFilters = userIdFilter || tableNameFilter || actionFilter || fromDate || toDate;

  const columns: Column<AuditLogEntry>[] = [
    { key: 'auditId', header: 'ID', sortable: true },
    {
      key: 'auditTs',
      header: 'Timestamp',
      sortable: true,
      render: (row) => (
        <span className="text-xs text-gray-600">
          {new Date(row.auditTs).toLocaleString()}
        </span>
      ),
    },
    { key: 'userId', header: 'User', sortable: true },
    {
      key: 'actionType',
      header: 'Action',
      render: (row) => <ActionBadge action={row.actionType} />,
    },
    { key: 'tableName', header: 'Table', sortable: true },
    { key: 'keyValue', header: 'Key' },
    {
      key: 'oldValue',
      header: 'Old Value',
      render: (row) =>
        row.oldValue ? (
          <span className="max-w-[200px] truncate text-xs text-gray-500" title={row.oldValue}>
            {row.oldValue}
          </span>
        ) : (
          <span className="text-gray-300">--</span>
        ),
    },
    {
      key: 'newValue',
      header: 'New Value',
      render: (row) =>
        row.newValue ? (
          <span className="max-w-[200px] truncate text-xs text-gray-500" title={row.newValue}>
            {row.newValue}
          </span>
        ) : (
          <span className="text-gray-300">--</span>
        ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
              <FileSearch className="h-5 w-5 text-indigo-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Audit Trail</h1>
              <p className="mt-0.5 text-sm text-gray-500">Review all system data changes and approvals</p>
            </div>
          </div>
        </div>
        <button
          onClick={loadStats}
          className="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50"
        >
          <BarChart3 className="h-4 w-4" />
          View Stats
        </button>
      </div>

      {/* Stats cards */}
      {showStats && (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          {Object.entries(stats).map(([action, count]) => {
            const colors = ACTION_BADGE_COLORS[action] || { bg: 'bg-gray-100', text: 'text-gray-600' };
            return (
              <div key={action} className={`rounded-xl border border-gray-200 ${colors.bg} p-4`}>
                <p className={`text-sm font-medium ${colors.text}`}>{ACTION_LABELS[action] || action}</p>
                <p className={`mt-1 text-2xl font-bold ${colors.text}`}>{count.toLocaleString()}</p>
              </div>
            );
          })}
        </div>
      )}

      {/* Filters */}
      <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-5">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500 uppercase tracking-wide">User ID</label>
            <input
              type="text"
              value={userIdFilter}
              onChange={(e) => { setUserIdFilter(e.target.value); setPage(0); }}
              placeholder="Filter by user..."
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500 uppercase tracking-wide">Table</label>
            <input
              type="text"
              value={tableNameFilter}
              onChange={(e) => { setTableNameFilter(e.target.value); setPage(0); }}
              placeholder="Filter by table..."
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500 uppercase tracking-wide">Action</label>
            <select
              value={actionFilter}
              onChange={(e) => { setActionFilter(e.target.value); setPage(0); }}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            >
              <option value="">All Actions</option>
              {ACTION_TYPES.map((a) => (
                <option key={a.value} value={a.value}>{a.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500 uppercase tracking-wide">From</label>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => { setFromDate(e.target.value); setPage(0); }}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500 uppercase tracking-wide">To</label>
            <input
              type="date"
              value={toDate}
              onChange={(e) => { setToDate(e.target.value); setPage(0); }}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
        </div>
        {hasFilters && (
          <div className="mt-3 flex items-center justify-between border-t border-gray-100 pt-3">
            <p className="text-sm text-gray-500">
              Showing <span className="font-medium">{totalElements}</span> results
            </p>
            <button
              onClick={clearFilters}
              className="text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
            >
              Clear all filters
            </button>
          </div>
        )}
      </div>

      {/* Table */}
      <DataTable
        columns={columns}
        data={items}
        loading={loading}
        page={page}
        totalPages={totalPages}
        totalElements={totalElements}
        onPageChange={setPage}
        emptyMessage="No audit records found matching your filters."
      />
    </div>
  );
}

export default AuditLogPage;
