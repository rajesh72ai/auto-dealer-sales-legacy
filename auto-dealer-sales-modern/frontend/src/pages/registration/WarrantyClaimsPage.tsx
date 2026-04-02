import { useState, useEffect, useCallback } from 'react';
import { Wrench, Plus, Filter } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getWarrantyClaims, createWarrantyClaim } from '@/api/warranty';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { WarrantyClaim, WarrantyClaimRequest } from '@/types/registration';
import type { Dealer } from '@/types/admin';

const CLAIM_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  NW: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'New' },
  IP: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'In Progress' },
  AP: { bg: 'bg-green-50', text: 'text-green-700', label: 'Approved' },
  PA: { bg: 'bg-green-100', text: 'text-green-800', label: 'Partially Approved' },
  PD: { bg: 'bg-emerald-50', text: 'text-emerald-700', label: 'Paid' },
  DN: { bg: 'bg-red-50', text: 'text-red-700', label: 'Denied' },
  CL: { bg: 'bg-gray-200', text: 'text-gray-600', label: 'Closed' },
};

const CLAIM_TYPE_OPTIONS = [
  { value: 'BA', label: 'Basic' },
  { value: 'PT', label: 'Powertrain' },
  { value: 'EX', label: 'Extended' },
  { value: 'GW', label: 'Goodwill' },
  { value: 'RC', label: 'Recall' },
  { value: 'CM', label: 'Campaign' },
  { value: 'PD', label: 'Pre-Delivery' },
];

const defaultForm: WarrantyClaimRequest = {
  vin: '', dealerCode: '', claimType: 'BA',
  claimDate: new Date().toISOString().split('T')[0],
  laborAmt: 0, partsAmt: 0, technicianId: '', repairOrderNum: '', notes: '',
};

function WarrantyClaimsPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [items, setItems] = useState<WarrantyClaim[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [statusFilter, setStatusFilter] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState<WarrantyClaimRequest>({ ...defaultForm });
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
      const result = await getWarrantyClaims({
        dealerCode, status: statusFilter || undefined, page, size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load warranty claims');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleSubmit = async () => {
    const newErrors: Record<string, string> = {};
    if (!form.vin || form.vin.length !== 17) newErrors.vin = 'VIN must be 17 characters';
    if (!form.laborAmt && !form.partsAmt) newErrors.laborAmt = 'At least one amount required';
    if (Object.keys(newErrors).length > 0) { setErrors(newErrors); return; }

    try {
      await createWarrantyClaim({ ...form, dealerCode });
      addToast('success', 'Warranty claim created successfully');
      setIsModalOpen(false);
      setForm({ ...defaultForm });
      setErrors({});
      fetchData();
    } catch {
      addToast('error', 'Failed to create warranty claim');
    }
  };

  const columns: Column<WarrantyClaim>[] = [
    { key: 'claimNumber', label: 'Claim #', sortable: true },
    { key: 'vin', label: 'VIN', render: (row) => <span className="font-mono text-xs">{row.vin}</span> },
    { key: 'claimTypeName', label: 'Type' },
    { key: 'claimDate', label: 'Claim Date', sortable: true },
    { key: 'claimStatus', label: 'Status', render: (row) => {
      const cfg = CLAIM_STATUS_CONFIG[row.claimStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.claimStatus };
      return <span className={`px-2 py-0.5 rounded text-xs font-medium ${cfg.bg} ${cfg.text}`}>{cfg.label}</span>;
    }},
    { key: 'formattedLabor', label: 'Labor' },
    { key: 'formattedParts', label: 'Parts' },
    { key: 'formattedTotal', label: 'Total' },
    { key: 'technicianId', label: 'Technician', render: (row) => row.technicianId || '—' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Wrench className="h-7 w-7 text-orange-600" /> Warranty Claims
          </h1>
          <p className="text-sm text-gray-500 mt-1">{totalElements} claims</p>
        </div>
        <button onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700">
          <Plus className="h-4 w-4" /> New Claim
        </button>
      </div>

      <div className="flex items-center gap-4 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <Filter className="h-4 w-4 text-gray-400" />
        <select value={dealerCode} onChange={(e) => { setDealerCode(e.target.value); setPage(0); }}
          className="border border-gray-300 rounded-md px-3 py-1.5 text-sm">
          {dealers.map((d) => <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} — {d.dealerName}</option>)}
        </select>
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
          className="border border-gray-300 rounded-md px-3 py-1.5 text-sm">
          <option value="">All Statuses</option>
          {Object.entries(CLAIM_STATUS_CONFIG).map(([val, cfg]) => (
            <option key={val} value={val}>{cfg.label}</option>
          ))}
        </select>
      </div>

      <DataTable columns={columns} data={items} loading={loading} page={page}
        totalPages={totalPages} onPageChange={setPage} emptyMessage="No warranty claims found" />

      <Modal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setErrors({}); }}
        title="Create Warranty Claim" size="lg">
        <div className="grid grid-cols-2 gap-4">
          <FormField label="VIN" error={errors.vin} required>
            <input type="text" value={form.vin} maxLength={17}
              onChange={(e) => setForm({ ...form, vin: e.target.value.toUpperCase() })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm font-mono" />
          </FormField>
          <FormField label="Claim Type" required>
            <select value={form.claimType} onChange={(e) => setForm({ ...form, claimType: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm">
              {CLAIM_TYPE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </FormField>
          <FormField label="Claim Date" required>
            <input type="date" value={form.claimDate}
              onChange={(e) => setForm({ ...form, claimDate: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Repair Date">
            <input type="date" value={form.repairDate || ''}
              onChange={(e) => setForm({ ...form, repairDate: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Labor Amount ($)" error={errors.laborAmt} required>
            <input type="number" step="0.01" value={form.laborAmt || ''}
              onChange={(e) => setForm({ ...form, laborAmt: parseFloat(e.target.value) || 0 })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Parts Amount ($)" required>
            <input type="number" step="0.01" value={form.partsAmt || ''}
              onChange={(e) => setForm({ ...form, partsAmt: parseFloat(e.target.value) || 0 })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Technician ID">
            <input type="text" value={form.technicianId || ''} maxLength={8}
              onChange={(e) => setForm({ ...form, technicianId: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Repair Order #">
            <input type="text" value={form.repairOrderNum || ''} maxLength={12}
              onChange={(e) => setForm({ ...form, repairOrderNum: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <div className="col-span-2">
            <FormField label="Notes">
              <textarea value={form.notes || ''} maxLength={200} rows={2}
                onChange={(e) => setForm({ ...form, notes: e.target.value })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
            </FormField>
          </div>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button onClick={() => { setIsModalOpen(false); setErrors({}); }}
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50">Cancel</button>
          <button onClick={handleSubmit}
            className="px-4 py-2 bg-orange-600 text-white rounded-lg text-sm hover:bg-orange-700">Create</button>
        </div>
      </Modal>
    </div>
  );
}

export default WarrantyClaimsPage;
