import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileText, Plus, Filter } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getRegistrations, createRegistration } from '@/api/registration';
import type { Registration, RegistrationRequest } from '@/types/registration';

const REG_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  PR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Preparing' },
  VL: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Validated' },
  SB: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Submitted' },
  PG: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'Processing' },
  IS: { bg: 'bg-green-50', text: 'text-green-700', label: 'Issued' },
  RJ: { bg: 'bg-red-50', text: 'text-red-700', label: 'Rejected' },
  ER: { bg: 'bg-red-100', text: 'text-red-800', label: 'Error' },
};

const REG_TYPE_OPTIONS = [
  { value: 'NW', label: 'New' },
  { value: 'TF', label: 'Transfer' },
  { value: 'RN', label: 'Renewal' },
  { value: 'DP', label: 'Duplicate' },
];

const defaultForm: RegistrationRequest = {
  dealNumber: '', vin: '', customerId: 0, regState: '', regType: 'NW',
  lienHolder: '', lienHolderAddr: '', regFeePaid: 0, titleFeePaid: 0,
};

function RegistrationsPage() {
  const { addToast } = useToast();
  const navigate = useNavigate();

  const [items, setItems] = useState<Registration[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [statusFilter, setStatusFilter] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState<RegistrationRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getRegistrations({
        status: statusFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load registrations');
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleSubmit = async () => {
    const newErrors: Record<string, string> = {};
    if (!form.dealNumber) newErrors.dealNumber = 'Deal number is required';
    if (!form.vin || form.vin.length !== 17) newErrors.vin = 'VIN must be 17 characters';
    if (!form.customerId) newErrors.customerId = 'Customer ID is required';
    if (!form.regState || form.regState.length !== 2) newErrors.regState = 'State code is required (2 chars)';
    if (Object.keys(newErrors).length > 0) { setErrors(newErrors); return; }

    try {
      await createRegistration(form);
      addToast('success', 'Registration created successfully');
      setIsModalOpen(false);
      setForm({ ...defaultForm });
      setErrors({});
      fetchData();
    } catch {
      addToast('error', 'Failed to create registration');
    }
  };

  const columns: Column<Registration>[] = [
    { key: 'regId', label: 'Reg ID', sortable: true },
    { key: 'dealNumber', label: 'Deal #', sortable: true },
    { key: 'vin', label: 'VIN', render: (row) => (
      <span className="font-mono text-xs">{row.vin}</span>
    )},
    { key: 'regState', label: 'State' },
    { key: 'regTypeName', label: 'Type' },
    { key: 'regStatus', label: 'Status', render: (row) => {
      const cfg = REG_STATUS_CONFIG[row.regStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.regStatus };
      return <span className={`px-2 py-0.5 rounded text-xs font-medium ${cfg.bg} ${cfg.text}`}>{cfg.label}</span>;
    }},
    { key: 'formattedRegFee', label: 'Reg Fee' },
    { key: 'formattedTitleFee', label: 'Title Fee' },
    { key: 'submissionDate', label: 'Submitted', render: (row) => row.submissionDate || '—' },
    { key: 'issuedDate', label: 'Issued', render: (row) => row.issuedDate || '—' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <FileText className="h-7 w-7 text-indigo-600" /> Vehicle Registrations
          </h1>
          <p className="text-sm text-gray-500 mt-1">{totalElements} registrations</p>
        </div>
        <button onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors">
          <Plus className="h-4 w-4" /> New Registration
        </button>
      </div>

      <div className="flex items-center gap-4 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <Filter className="h-4 w-4 text-gray-400" />
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
          className="border border-gray-300 rounded-md px-3 py-1.5 text-sm">
          <option value="">All Statuses</option>
          {Object.entries(REG_STATUS_CONFIG).map(([val, cfg]) => (
            <option key={val} value={val}>{cfg.label}</option>
          ))}
        </select>
      </div>

      <DataTable
        columns={columns}
        data={items}
        loading={loading}
        page={page}
        totalPages={totalPages}
        onPageChange={setPage}
        onRowClick={(row) => navigate(`/registration/${row.regId}`)}
        emptyMessage="No registrations found"
      />

      <Modal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setErrors({}); }}
        title="Create Registration" size="lg">
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Deal Number" error={errors.dealNumber} required>
            <input type="text" value={form.dealNumber} maxLength={10}
              onChange={(e) => setForm({ ...form, dealNumber: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="VIN" error={errors.vin} required>
            <input type="text" value={form.vin} maxLength={17}
              onChange={(e) => setForm({ ...form, vin: e.target.value.toUpperCase() })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm font-mono" />
          </FormField>
          <FormField label="Customer ID" error={errors.customerId} required>
            <input type="number" value={form.customerId || ''}
              onChange={(e) => setForm({ ...form, customerId: parseInt(e.target.value) || 0 })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="State" error={errors.regState} required>
            <input type="text" value={form.regState} maxLength={2}
              onChange={(e) => setForm({ ...form, regState: e.target.value.toUpperCase() })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" placeholder="CO" />
          </FormField>
          <FormField label="Registration Type" required>
            <select value={form.regType} onChange={(e) => setForm({ ...form, regType: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm">
              {REG_TYPE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </FormField>
          <FormField label="Lien Holder">
            <input type="text" value={form.lienHolder || ''} maxLength={60}
              onChange={(e) => setForm({ ...form, lienHolder: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Registration Fee ($)">
            <input type="number" step="0.01" value={form.regFeePaid || ''}
              onChange={(e) => setForm({ ...form, regFeePaid: parseFloat(e.target.value) || 0 })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Title Fee ($)">
            <input type="number" step="0.01" value={form.titleFeePaid || ''}
              onChange={(e) => setForm({ ...form, titleFeePaid: parseFloat(e.target.value) || 0 })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button onClick={() => { setIsModalOpen(false); setErrors({}); }}
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50">Cancel</button>
          <button onClick={handleSubmit}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm hover:bg-indigo-700">Create</button>
        </div>
      </Modal>
    </div>
  );
}

export default RegistrationsPage;
