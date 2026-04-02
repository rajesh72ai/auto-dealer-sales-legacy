import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { AlertTriangle, Plus, Filter } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getRecallCampaigns, createRecallCampaign } from '@/api/warranty';
import type { RecallCampaign, RecallCampaignRequest } from '@/types/registration';

const SEVERITY_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  C: { bg: 'bg-red-100', text: 'text-red-800', label: 'Critical' },
  H: { bg: 'bg-orange-100', text: 'text-orange-800', label: 'High' },
  M: { bg: 'bg-amber-100', text: 'text-amber-800', label: 'Medium' },
  L: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Low' },
};

const defaultForm: RecallCampaignRequest = {
  recallId: '', nhtsaNum: '', recallDesc: '', severity: 'M',
  affectedYears: '', affectedModels: '', remedyDesc: '', announcedDate: new Date().toISOString().split('T')[0],
};

function RecallCampaignsPage() {
  const { addToast } = useToast();
  const navigate = useNavigate();

  const [items, setItems] = useState<RecallCampaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [statusFilter, setStatusFilter] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState<RecallCampaignRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getRecallCampaigns({
        status: statusFilter || undefined, page, size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load recall campaigns');
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleSubmit = async () => {
    const newErrors: Record<string, string> = {};
    if (!form.recallId) newErrors.recallId = 'Recall ID is required';
    if (!form.recallDesc) newErrors.recallDesc = 'Description is required';
    if (!form.affectedYears) newErrors.affectedYears = 'Affected years is required';
    if (!form.affectedModels) newErrors.affectedModels = 'Affected models is required';
    if (!form.remedyDesc) newErrors.remedyDesc = 'Remedy description is required';
    if (Object.keys(newErrors).length > 0) { setErrors(newErrors); return; }

    try {
      await createRecallCampaign(form);
      addToast('success', 'Recall campaign created successfully');
      setIsModalOpen(false);
      setForm({ ...defaultForm });
      setErrors({});
      fetchData();
    } catch {
      addToast('error', 'Failed to create recall campaign');
    }
  };

  const columns: Column<RecallCampaign>[] = [
    { key: 'recallId', label: 'Recall ID', sortable: true },
    { key: 'nhtsaNum', label: 'NHTSA #', render: (row) => row.nhtsaNum || '—' },
    { key: 'recallDesc', label: 'Description', render: (row) => (
      <span className="max-w-xs truncate block" title={row.recallDesc}>{row.recallDesc}</span>
    )},
    { key: 'severity', label: 'Severity', render: (row) => {
      const cfg = SEVERITY_CONFIG[row.severity] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.severity };
      return <span className={`px-2 py-0.5 rounded text-xs font-medium ${cfg.bg} ${cfg.text}`}>{cfg.label}</span>;
    }},
    { key: 'affectedModels', label: 'Models' },
    { key: 'totalAffected', label: 'Affected', sortable: true },
    { key: 'totalCompleted', label: 'Completed' },
    { key: 'completionPercentage', label: 'Progress', render: (row) => (
      <div className="flex items-center gap-2">
        <div className="w-16 bg-gray-200 rounded-full h-2">
          <div className="bg-emerald-500 h-2 rounded-full" style={{ width: `${Math.min(row.completionPercentage, 100)}%` }} />
        </div>
        <span className="text-xs text-gray-600">{row.completionPercentage}%</span>
      </div>
    )},
    { key: 'announcedDate', label: 'Announced', sortable: true },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <AlertTriangle className="h-7 w-7 text-red-600" /> Recall Campaigns
          </h1>
          <p className="text-sm text-gray-500 mt-1">{totalElements} campaigns</p>
        </div>
        <button onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">
          <Plus className="h-4 w-4" /> New Campaign
        </button>
      </div>

      <div className="flex items-center gap-4 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <Filter className="h-4 w-4 text-gray-400" />
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
          className="border border-gray-300 rounded-md px-3 py-1.5 text-sm">
          <option value="">All Statuses</option>
          <option value="A">Active</option>
          <option value="P">Pending</option>
          <option value="C">Closed</option>
        </select>
      </div>

      <DataTable columns={columns} data={items} loading={loading} page={page}
        totalPages={totalPages} onPageChange={setPage}
        onRowClick={(row) => navigate(`/recall/${row.recallId}`)}
        emptyMessage="No recall campaigns found" />

      <Modal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setErrors({}); }}
        title="Create Recall Campaign" size="lg">
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Recall ID" error={errors.recallId} required>
            <input type="text" value={form.recallId} maxLength={10}
              onChange={(e) => setForm({ ...form, recallId: e.target.value.toUpperCase() })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" placeholder="RCL2025004" />
          </FormField>
          <FormField label="NHTSA Number">
            <input type="text" value={form.nhtsaNum || ''} maxLength={12}
              onChange={(e) => setForm({ ...form, nhtsaNum: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Severity" required>
            <select value={form.severity} onChange={(e) => setForm({ ...form, severity: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm">
              {Object.entries(SEVERITY_CONFIG).map(([val, cfg]) => (
                <option key={val} value={val}>{cfg.label}</option>
              ))}
            </select>
          </FormField>
          <FormField label="Announced Date" required>
            <input type="date" value={form.announcedDate}
              onChange={(e) => setForm({ ...form, announcedDate: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
          <FormField label="Affected Years" error={errors.affectedYears} required>
            <input type="text" value={form.affectedYears} maxLength={40}
              onChange={(e) => setForm({ ...form, affectedYears: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" placeholder="2020-2023" />
          </FormField>
          <FormField label="Affected Models" error={errors.affectedModels} required>
            <input type="text" value={form.affectedModels} maxLength={100}
              onChange={(e) => setForm({ ...form, affectedModels: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" placeholder="F-150, Bronco" />
          </FormField>
          <div className="col-span-2">
            <FormField label="Description" error={errors.recallDesc} required>
              <textarea value={form.recallDesc} maxLength={200} rows={2}
                onChange={(e) => setForm({ ...form, recallDesc: e.target.value })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
            </FormField>
          </div>
          <div className="col-span-2">
            <FormField label="Remedy Description" error={errors.remedyDesc} required>
              <textarea value={form.remedyDesc} maxLength={200} rows={2}
                onChange={(e) => setForm({ ...form, remedyDesc: e.target.value })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
            </FormField>
          </div>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button onClick={() => { setIsModalOpen(false); setErrors({}); }}
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50">Cancel</button>
          <button onClick={handleSubmit}
            className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm hover:bg-red-700">Create</button>
        </div>
      </Modal>
    </div>
  );
}

export default RecallCampaignsPage;
