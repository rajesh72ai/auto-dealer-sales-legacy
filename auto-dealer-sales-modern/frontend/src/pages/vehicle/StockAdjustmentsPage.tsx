import { useState, useEffect, useCallback } from 'react';
import { Plus, RefreshCw } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getAdjustments, createAdjustment } from '@/api/stock';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { StockAdjustment, StockAdjustmentRequest } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const ADJUST_TYPES = [
  { value: 'DM', label: 'Damage' },
  { value: 'WO', label: 'Write Off' },
  { value: 'RC', label: 'Recount' },
  { value: 'PH', label: 'Physical' },
  { value: 'OT', label: 'Other' },
];

const defaultForm: Omit<StockAdjustmentRequest, 'dealerCode'> = {
  vin: '',
  adjustType: 'DM',
  adjustReason: '',
  adjustedBy: '',
};

function StockAdjustmentsPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [items, setItems] = useState<StockAdjustment[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});

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
      const result = await getAdjustments({ dealerCode, page, size: 20 });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load adjustments');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, page, addToast]);

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
    if (!form.adjustReason.trim()) errs.adjustReason = 'Reason is required';
    if (!form.adjustedBy.trim()) errs.adjustedBy = 'Adjusted by is required';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    try {
      await createAdjustment({ ...form, dealerCode });
      addToast('success', 'Adjustment created successfully');
      setModalOpen(false);
      setForm({ ...defaultForm });
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create adjustment');
    }
  };

  const columns: Column<StockAdjustment>[] = [
    { key: 'adjustId', header: 'ID', sortable: true },
    { key: 'vin', header: 'VIN', sortable: true },
    {
      key: 'adjustType',
      header: 'Type',
      render: (row) => (
        <span className="inline-flex rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-700">
          {row.adjustTypeName || row.adjustType}
        </span>
      ),
    },
    { key: 'adjustReason', header: 'Reason' },
    { key: 'oldStatus', header: 'Old Status' },
    { key: 'newStatus', header: 'New Status' },
    { key: 'adjustedBy', header: 'Adjusted By' },
    {
      key: 'adjustedTs',
      header: 'Timestamp',
      render: (row) => <span className="text-xs text-gray-500">{new Date(row.adjustedTs).toLocaleString()}</span>,
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-50">
            <RefreshCw className="h-5 w-5 text-orange-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Stock Adjustments</h1>
            <p className="mt-0.5 text-sm text-gray-500">Track and create inventory adjustments</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={dealerCode}
            onChange={(e) => { setDealerCode(e.target.value); setPage(0); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            {dealers.map((d) => (
              <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
            ))}
          </select>
          <button
            onClick={() => { setForm({ ...defaultForm }); setErrors({}); setModalOpen(true); }}
            className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            <Plus className="h-4 w-4" />
            New Adjustment
          </button>
        </div>
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

      {/* Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="New Stock Adjustment">
        <form onSubmit={handleSubmit} className="space-y-4">
          <FormField label="VIN" name="vin" value={form.vin} onChange={handleChange} error={errors.vin} required placeholder="Enter VIN" />
          <FormField
            label="Adjustment Type"
            name="adjustType"
            type="select"
            value={form.adjustType}
            onChange={handleChange}
            options={ADJUST_TYPES}
          />
          <FormField label="Reason" name="adjustReason" value={form.adjustReason} onChange={handleChange} error={errors.adjustReason} required placeholder="Reason for adjustment" />
          <FormField label="Adjusted By" name="adjustedBy" value={form.adjustedBy} onChange={handleChange} error={errors.adjustedBy} required placeholder="Your name or ID" />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setModalOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700">Create Adjustment</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default StockAdjustmentsPage;
