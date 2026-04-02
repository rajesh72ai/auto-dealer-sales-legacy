import { useState, useEffect, useCallback } from 'react';
import { Plus, Repeat, Check, X, Truck } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getTransfers, requestTransfer, approveTransfer, completeTransfer, cancelTransfer } from '@/api/transfers';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { Transfer, TransferRequest } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const TRANSFER_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  RQ: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Requested' },
  AP: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Approved' },
  CM: { bg: 'bg-green-50', text: 'text-green-700', label: 'Completed' },
  RJ: { bg: 'bg-red-50', text: 'text-red-700', label: 'Rejected' },
  CN: { bg: 'bg-gray-100', text: 'text-gray-600', label: 'Cancelled' },
};

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  ...Object.entries(TRANSFER_STATUS_CONFIG).map(([value, cfg]) => ({ value, label: cfg.label })),
];

const defaultForm: Omit<TransferRequest, 'fromDealer'> = {
  toDealer: '',
  vin: '',
  requestedBy: '',
  reason: '',
};

function StockTransfersPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [statusFilter, setStatusFilter] = useState('');
  const [items, setItems] = useState<Transfer[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [actionLoading, setActionLoading] = useState<number | null>(null);

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => {
      setDealers(r.content);
      if (!dealerCode && r.content.length > 0) setDealerCode(r.content[0].dealerCode);
    }).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]); // eslint-disable-line react-hooks/exhaustive-deps

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      const result = await getTransfers({
        dealerCode,
        status: statusFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load transfers');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!form.vin.trim()) errs.vin = 'VIN is required';
    if (!form.toDealer.trim()) errs.toDealer = 'Destination dealer is required';
    if (!form.reason.trim()) errs.reason = 'Reason is required';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    try {
      await requestTransfer({ ...form, fromDealer: dealerCode, requestedBy: form.requestedBy || user?.dealerCode || 'SYSTEM' });
      addToast('success', 'Transfer request created');
      setModalOpen(false);
      setForm({ ...defaultForm });
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create transfer');
    }
  };

  const handleAction = async (id: number, action: 'approve' | 'complete' | 'cancel') => {
    setActionLoading(id);
    try {
      if (action === 'approve') {
        await approveTransfer(id, { approvedBy: user?.dealerCode || 'SYSTEM' });
        addToast('success', 'Transfer approved');
      } else if (action === 'complete') {
        await completeTransfer(id);
        addToast('success', 'Transfer completed');
      } else {
        await cancelTransfer(id);
        addToast('success', 'Transfer cancelled');
      }
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || `Failed to ${action} transfer`);
    } finally {
      setActionLoading(null);
    }
  };

  const columns: Column<Transfer>[] = [
    { key: 'transferId', header: 'ID', sortable: true },
    { key: 'vin', header: 'VIN', sortable: true },
    { key: 'vehicleDesc', header: 'Vehicle' },
    { key: 'fromDealer', header: 'From' },
    { key: 'toDealer', header: 'To' },
    {
      key: 'transferStatus',
      header: 'Status',
      render: (row) => {
        const cfg = TRANSFER_STATUS_CONFIG[row.transferStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.statusName };
        return (
          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${cfg.bg} ${cfg.text}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${cfg.text.replace('text-', 'bg-')}`} />
            {cfg.label}
          </span>
        );
      },
    },
    { key: 'requestedBy', header: 'Requested By' },
    {
      key: 'requestedTs',
      header: 'Date',
      render: (row) => <span className="text-xs text-gray-500">{new Date(row.requestedTs).toLocaleDateString()}</span>,
    },
    {
      key: 'actions' as any,
      header: 'Actions',
      render: (row) => {
        const isLoading = actionLoading === row.transferId;
        return (
          <div className="flex items-center gap-1">
            {row.transferStatus === 'RQ' && (
              <>
                <button
                  onClick={(e) => { e.stopPropagation(); handleAction(row.transferId, 'approve'); }}
                  disabled={isLoading}
                  className="rounded p-1 text-blue-600 transition-colors hover:bg-blue-50 disabled:opacity-50"
                  title="Approve"
                >
                  <Check className="h-4 w-4" />
                </button>
                <button
                  onClick={(e) => { e.stopPropagation(); handleAction(row.transferId, 'cancel'); }}
                  disabled={isLoading}
                  className="rounded p-1 text-red-600 transition-colors hover:bg-red-50 disabled:opacity-50"
                  title="Cancel"
                >
                  <X className="h-4 w-4" />
                </button>
              </>
            )}
            {row.transferStatus === 'AP' && (
              <>
                <button
                  onClick={(e) => { e.stopPropagation(); handleAction(row.transferId, 'complete'); }}
                  disabled={isLoading}
                  className="rounded p-1 text-green-600 transition-colors hover:bg-green-50 disabled:opacity-50"
                  title="Complete"
                >
                  <Truck className="h-4 w-4" />
                </button>
                <button
                  onClick={(e) => { e.stopPropagation(); handleAction(row.transferId, 'cancel'); }}
                  disabled={isLoading}
                  className="rounded p-1 text-red-600 transition-colors hover:bg-red-50 disabled:opacity-50"
                  title="Cancel"
                >
                  <X className="h-4 w-4" />
                </button>
              </>
            )}
            {(row.transferStatus === 'CM' || row.transferStatus === 'RJ' || row.transferStatus === 'CN') && (
              <span className="text-xs text-gray-400">--</span>
            )}
          </div>
        );
      },
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-cyan-50">
            <Repeat className="h-5 w-5 text-cyan-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Stock Transfers</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage dealer-to-dealer vehicle transfers</p>
          </div>
        </div>
        <button
          onClick={() => { setForm({ ...defaultForm }); setErrors({}); setModalOpen(true); }}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Request Transfer
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={dealerCode}
          onChange={(e) => { setDealerCode(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          {dealers.map((d) => (
            <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
          ))}
        </select>
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          {STATUS_OPTIONS.map((s) => (
            <option key={s.value} value={s.value}>{s.label}</option>
          ))}
        </select>
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
      />

      {/* Request Transfer Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Request Transfer">
        <form onSubmit={handleSubmit} className="space-y-4">
          <FormField label="VIN" name="vin" value={form.vin} onChange={handleChange} error={errors.vin} required placeholder="Enter VIN" />
          <FormField
            label="To Dealer"
            name="toDealer"
            type="select"
            value={form.toDealer}
            onChange={handleChange}
            error={errors.toDealer}
            required
            options={dealers.filter((d) => d.dealerCode !== dealerCode).map((d) => ({ value: d.dealerCode, label: `${d.dealerCode} - ${d.dealerName}` }))}
          />
          <FormField label="Reason" name="reason" value={form.reason} onChange={handleChange} error={errors.reason} required placeholder="Reason for transfer" />
          <FormField label="Requested By" name="requestedBy" value={form.requestedBy} onChange={handleChange} placeholder="Your name or ID" />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setModalOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700">Request Transfer</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default StockTransfersPage;
