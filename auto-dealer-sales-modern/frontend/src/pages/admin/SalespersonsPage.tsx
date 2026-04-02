import { useState, useEffect, useCallback } from 'react';
import { Plus, Users } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import StatusBadge from '@/components/shared/StatusBadge';
import { getSalespersons, createSalesperson, updateSalesperson } from '@/api/salespersons';
import { getDealers } from '@/api/dealers';
import type { Salesperson, SalespersonRequest, Dealer } from '@/types/admin';

const COMMISSION_PLANS = [
  { value: 'ST', label: 'Standard' },
  { value: 'SR', label: 'Senior' },
  { value: 'MG', label: 'Manager' },
  { value: 'TR', label: 'Trainee' },
];

const COMMISSION_BADGE_COLORS: Record<string, string> = {
  ST: 'bg-blue-50 text-blue-700',
  SR: 'bg-purple-50 text-purple-700',
  MG: 'bg-amber-50 text-amber-700',
  TR: 'bg-gray-100 text-gray-600',
};

const ACTIVE_OPTIONS = [
  { value: 'Y', label: 'Active' },
  { value: 'N', label: 'Inactive' },
];

const defaultForm: SalespersonRequest = {
  salespersonId: '',
  salespersonName: '',
  dealerCode: '',
  hireDate: new Date().toISOString().split('T')[0],
  terminationDate: null,
  commissionPlan: 'ST',
  activeFlag: 'Y',
};

function commissionLabel(code: string): string {
  return COMMISSION_PLANS.find((c) => c.value === code)?.label ?? code;
}

function SalespersonsPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<Salesperson[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<Salesperson | null>(null);
  const [form, setForm] = useState<SalespersonRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [dealerFilter, setDealerFilter] = useState('');
  const [activeFilter, setActiveFilter] = useState('');
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealersLoading, setDealersLoading] = useState(true);

  // Load dealers for the filter dropdown
  useEffect(() => {
    async function loadDealers() {
      try {
        const result = await getDealers({ page: 0, size: 200, active: 'Y' });
        setDealers(result.content);
        if (result.content.length > 0 && !dealerFilter) {
          setDealerFilter(result.content[0].dealerCode);
        }
      } catch {
        addToast('error', 'Failed to load dealers');
      } finally {
        setDealersLoading(false);
      }
    }
    loadDealers();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const fetchData = useCallback(async () => {
    if (!dealerFilter) return;
    setLoading(true);
    try {
      const result = await getSalespersons({
        dealerCode: dealerFilter,
        active: activeFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load salespersons');
    } finally {
      setLoading(false);
    }
  }, [page, dealerFilter, activeFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.salespersonId.trim()) errs.salespersonId = 'Salesperson ID is required';
    if (!form.salespersonName.trim()) errs.salespersonName = 'Name is required';
    if (!form.dealerCode) errs.dealerCode = 'Dealer is required';
    if (!form.commissionPlan) errs.commissionPlan = 'Commission plan is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updateSalesperson(editing.salespersonId, form);
        addToast('success', 'Salesperson updated successfully');
      } else {
        await createSalesperson(form);
        addToast('success', 'Salesperson created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm, dealerCode: dealerFilter });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (item: Salesperson) => {
    setEditing(item);
    setForm({
      salespersonId: item.salespersonId,
      salespersonName: item.salespersonName,
      dealerCode: item.dealerCode,
      hireDate: item.hireDate,
      terminationDate: item.terminationDate,
      commissionPlan: item.commissionPlan,
      activeFlag: item.activeFlag,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const dealerOptions = dealers.map((d) => ({
    value: d.dealerCode,
    label: `${d.dealerCode} - ${d.dealerName}`,
  }));

  const columns: Column<Salesperson>[] = [
    {
      key: 'salespersonId',
      header: 'ID',
      render: (row) => <span className="font-mono text-xs text-gray-600">{row.salespersonId}</span>,
    },
    {
      key: 'salespersonName',
      header: 'Name',
      sortable: true,
      render: (row) => <span className="font-medium text-gray-900">{row.salespersonName}</span>,
    },
    {
      key: 'dealerCode',
      header: 'Dealer',
      render: (row) => (
        <div>
          <span className="text-sm text-gray-700">{row.dealerCode}</span>
          {row.dealerName && (
            <span className="ml-1.5 text-xs text-gray-400">{row.dealerName}</span>
          )}
        </div>
      ),
    },
    {
      key: 'hireDate',
      header: 'Hire Date',
      render: (row) => row.hireDate ?? '\u2014',
    },
    {
      key: 'commissionPlan',
      header: 'Commission Plan',
      render: (row) => (
        <span
          className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${
            COMMISSION_BADGE_COLORS[row.commissionPlan] || 'bg-gray-100 text-gray-700'
          }`}
        >
          {commissionLabel(row.commissionPlan)}
        </span>
      ),
    },
    {
      key: 'activeFlag',
      header: 'Status',
      render: (row) => <StatusBadge status={row.activeFlag === 'Y' ? 'active' : 'inactive'} />,
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
            <Users className="h-5 w-5 text-indigo-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Salespersons</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage sales staff assignments and commission plans</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          disabled={!dealerFilter}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <Plus className="h-4 w-4" />
          Add Salesperson
        </button>
      </div>

      {/* Filters - dealer is required */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium text-gray-700">Dealer<span className="ml-0.5 text-red-500">*</span></label>
          <select
            value={dealerFilter}
            onChange={(e) => { setDealerFilter(e.target.value); setPage(0); }}
            disabled={dealersLoading}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20 disabled:bg-gray-50"
          >
            {dealersLoading ? (
              <option>Loading dealers...</option>
            ) : (
              <>
                <option value="">Select a dealer</option>
                {dealers.map((d) => (
                  <option key={d.dealerCode} value={d.dealerCode}>
                    {d.dealerCode} - {d.dealerName}
                  </option>
                ))}
              </>
            )}
          </select>
        </div>
        <select
          value={activeFilter}
          onChange={(e) => { setActiveFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Status</option>
          <option value="Y">Active</option>
          <option value="N">Inactive</option>
        </select>
        {activeFilter && (
          <button
            onClick={() => { setActiveFilter(''); setPage(0); }}
            className="text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
          >
            Clear filter
          </button>
        )}
      </div>

      {/* Info banner when no dealer selected */}
      {!dealerFilter && !dealersLoading && (
        <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3">
          <p className="text-sm text-blue-700">Please select a dealer above to view salespersons.</p>
        </div>
      )}

      {/* Table */}
      {dealerFilter && (
        <DataTable
          columns={columns}
          data={items}
          loading={loading}
          page={page}
          totalPages={totalPages}
          totalElements={totalElements}
          onPageChange={setPage}
          onRowClick={(row) => openEdit(row)}
        />
      )}

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editing ? 'Edit Salesperson' : 'New Salesperson'}
        size="lg"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Salesperson ID"
              name="salespersonId"
              value={form.salespersonId}
              onChange={handleChange}
              error={errors.salespersonId}
              required
              placeholder="SP001"
              disabled={!!editing}
            />
            <FormField
              label="Name"
              name="salespersonName"
              value={form.salespersonName}
              onChange={handleChange}
              error={errors.salespersonName}
              required
              placeholder="John Smith"
            />
          </div>
          <FormField
            label="Dealer"
            name="dealerCode"
            type="select"
            value={form.dealerCode}
            onChange={handleChange}
            error={errors.dealerCode}
            required
            options={dealerOptions}
          />
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Hire Date"
              name="hireDate"
              type="date"
              value={form.hireDate ?? ''}
              onChange={handleChange}
            />
            <FormField
              label="Termination Date"
              name="terminationDate"
              type="date"
              value={form.terminationDate ?? ''}
              onChange={handleChange}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Commission Plan"
              name="commissionPlan"
              type="select"
              value={form.commissionPlan}
              onChange={handleChange}
              error={errors.commissionPlan}
              required
              options={COMMISSION_PLANS}
            />
            <FormField
              label="Status"
              name="activeFlag"
              type="select"
              value={form.activeFlag}
              onChange={handleChange}
              options={ACTIVE_OPTIONS}
            />
          </div>

          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
            >
              {editing ? 'Update Salesperson' : 'Create Salesperson'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default SalespersonsPage;
