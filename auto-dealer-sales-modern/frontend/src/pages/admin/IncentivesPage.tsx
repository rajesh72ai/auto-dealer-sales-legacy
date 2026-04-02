import { useState, useEffect, useCallback } from 'react';
import { Plus, Gift, Power, PowerOff } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import StatusBadge from '@/components/shared/StatusBadge';
import {
  getIncentives,
  createIncentive,
  updateIncentive,
  activateIncentive,
  deactivateIncentive,
} from '@/api/incentives';
import type { IncentiveProgram, IncentiveProgramRequest } from '@/types/admin';

const INCENTIVE_TYPES = [
  { value: 'CR', label: 'Customer Rebate' },
  { value: 'DR', label: 'Dealer Rebate' },
  { value: 'LR', label: 'Loyalty Rebate' },
  { value: 'FR', label: 'Finance Rate' },
  { value: 'LB', label: 'Lease Bonus' },
];

const TYPE_BADGE_COLORS: Record<string, string> = {
  CR: 'bg-emerald-50 text-emerald-700',
  DR: 'bg-blue-50 text-blue-700',
  LR: 'bg-purple-50 text-purple-700',
  FR: 'bg-orange-50 text-orange-700',
  LB: 'bg-teal-50 text-teal-700',
};

const ACTIVE_OPTIONS = [
  { value: 'Y', label: 'Active' },
  { value: 'N', label: 'Inactive' },
];

const STACKABLE_OPTIONS = [
  { value: 'Y', label: 'Yes' },
  { value: 'N', label: 'No' },
];

const defaultForm: IncentiveProgramRequest = {
  incentiveId: '',
  incentiveName: '',
  incentiveType: '',
  modelYear: null,
  makeCode: null,
  modelCode: null,
  regionCode: null,
  amount: 0,
  rateOverride: null,
  startDate: new Date().toISOString().split('T')[0],
  endDate: '',
  maxUnits: null,
  stackableFlag: 'N',
  activeFlag: 'Y',
};

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(amount);
}

function typeLabel(code: string): string {
  return INCENTIVE_TYPES.find((t) => t.value === code)?.label ?? code;
}

function IncentivesPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<IncentiveProgram[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<IncentiveProgram | null>(null);
  const [form, setForm] = useState<IncentiveProgramRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [typeFilter, setTypeFilter] = useState('');
  const [activeFilter, setActiveFilter] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getIncentives({
        page,
        size: 20,
        type: typeFilter || undefined,
        active: activeFilter || undefined,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load incentive programs');
    } finally {
      setLoading(false);
    }
  }, [page, typeFilter, activeFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.incentiveId.trim()) errs.incentiveId = 'Incentive ID is required';
    if (!form.incentiveName.trim()) errs.incentiveName = 'Name is required';
    if (!form.incentiveType) errs.incentiveType = 'Type is required';
    if (form.amount <= 0) errs.amount = 'Amount must be greater than 0';
    if (!form.startDate) errs.startDate = 'Start date is required';
    if (!form.endDate) errs.endDate = 'End date is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updateIncentive(editing.incentiveId, form);
        addToast('success', 'Incentive updated successfully');
      } else {
        await createIncentive(form);
        addToast('success', 'Incentive created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    const numericFields = ['amount', 'rateOverride', 'maxUnits', 'modelYear'];
    setForm((prev) => ({
      ...prev,
      [name]: numericFields.includes(name) ? (value === '' ? null : Number(value)) : value,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (item: IncentiveProgram) => {
    setEditing(item);
    setForm({
      incentiveId: item.incentiveId,
      incentiveName: item.incentiveName,
      incentiveType: item.incentiveType,
      modelYear: item.modelYear,
      makeCode: item.makeCode,
      modelCode: item.modelCode,
      regionCode: item.regionCode,
      amount: item.amount,
      rateOverride: item.rateOverride,
      startDate: item.startDate,
      endDate: item.endDate,
      maxUnits: item.maxUnits,
      stackableFlag: item.stackableFlag,
      activeFlag: item.activeFlag,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const handleToggleActive = async (e: React.MouseEvent, item: IncentiveProgram) => {
    e.stopPropagation();
    try {
      if (item.activeFlag === 'Y') {
        await deactivateIncentive(item.incentiveId);
        addToast('success', 'Incentive deactivated');
      } else {
        await activateIncentive(item.incentiveId);
        addToast('success', 'Incentive activated');
      }
      fetchData();
    } catch {
      addToast('error', 'Failed to update incentive status');
    }
  };

  const columns: Column<IncentiveProgram>[] = [
    {
      key: 'incentiveId',
      header: 'ID',
      render: (row) => <span className="font-mono text-xs text-gray-600">{row.incentiveId}</span>,
    },
    {
      key: 'incentiveName',
      header: 'Name',
      sortable: true,
      render: (row) => <span className="font-medium text-gray-900">{row.incentiveName}</span>,
    },
    {
      key: 'incentiveType',
      header: 'Type',
      render: (row) => (
        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${TYPE_BADGE_COLORS[row.incentiveType] || 'bg-gray-100 text-gray-700'}`}>
          {typeLabel(row.incentiveType)}
        </span>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      sortable: true,
      render: (row) => (
        <span className="font-semibold text-gray-900">{row.formattedAmount || formatCurrency(row.amount)}</span>
      ),
    },
    { key: 'startDate', header: 'Start' },
    { key: 'endDate', header: 'End' },
    {
      key: 'unitsUsed',
      header: 'Units',
      render: (row) => {
        if (row.maxUnits === null) return <span className="text-xs text-gray-400">Unlimited</span>;
        const pct = Math.min((row.unitsUsed / row.maxUnits) * 100, 100);
        const barColor = pct > 90 ? 'bg-red-500' : pct > 70 ? 'bg-amber-500' : 'bg-emerald-500';
        return (
          <div className="w-24">
            <div className="mb-0.5 flex items-center justify-between text-xs">
              <span className="text-gray-600">{row.unitsUsed}</span>
              <span className="text-gray-400">/ {row.maxUnits}</span>
            </div>
            <div className="h-1.5 w-full overflow-hidden rounded-full bg-gray-100">
              <div className={`h-full rounded-full ${barColor} transition-all`} style={{ width: `${pct}%` }} />
            </div>
          </div>
        );
      },
    },
    {
      key: 'activeFlag',
      header: 'Status',
      render: (row) => {
        if (row.isExpired) return <StatusBadge status="expired" />;
        return <StatusBadge status={row.activeFlag === 'Y' ? 'active' : 'inactive'} />;
      },
    },
    {
      key: '_actions',
      header: '',
      render: (row) => (
        <div className="flex items-center gap-1">
          <button
            onClick={(e) => { e.stopPropagation(); openEdit(row); }}
            className="rounded-md px-2 py-1 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-100"
          >
            Edit
          </button>
          <button
            onClick={(e) => handleToggleActive(e, row)}
            className={`inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium transition-colors ${
              row.activeFlag === 'Y'
                ? 'text-red-600 hover:bg-red-50'
                : 'text-emerald-600 hover:bg-emerald-50'
            }`}
            title={row.activeFlag === 'Y' ? 'Deactivate' : 'Activate'}
          >
            {row.activeFlag === 'Y' ? (
              <><PowerOff className="h-3 w-3" /> Deactivate</>
            ) : (
              <><Power className="h-3 w-3" /> Activate</>
            )}
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-pink-50">
            <Gift className="h-5 w-5 text-pink-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Incentive Programs</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage manufacturer rebates, dealer incentives, and finance offers</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Incentive
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={typeFilter}
          onChange={(e) => { setTypeFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Types</option>
          {INCENTIVE_TYPES.map((t) => (
            <option key={t.value} value={t.value}>{t.label}</option>
          ))}
        </select>
        <select
          value={activeFilter}
          onChange={(e) => { setActiveFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Status</option>
          <option value="Y">Active</option>
          <option value="N">Inactive</option>
        </select>
        {(typeFilter || activeFilter) && (
          <button
            onClick={() => { setTypeFilter(''); setActiveFilter(''); setPage(0); }}
            className="text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
          >
            Clear filters
          </button>
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
        onRowClick={(row) => openEdit(row)}
      />

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editing ? 'Edit Incentive' : 'New Incentive'}
        size="xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Incentive ID"
              name="incentiveId"
              value={form.incentiveId}
              onChange={handleChange}
              error={errors.incentiveId}
              required
              placeholder="INC-2026-001"
              disabled={!!editing}
            />
            <FormField
              label="Type"
              name="incentiveType"
              type="select"
              value={form.incentiveType}
              onChange={handleChange}
              error={errors.incentiveType}
              required
              options={INCENTIVE_TYPES}
            />
          </div>
          <FormField
            label="Name"
            name="incentiveName"
            value={form.incentiveName}
            onChange={handleChange}
            error={errors.incentiveName}
            required
            placeholder="Spring Sales Event Rebate"
          />
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Model Year"
              name="modelYear"
              type="number"
              value={form.modelYear ?? ''}
              onChange={handleChange}
              placeholder="All years"
            />
            <FormField
              label="Make Code"
              name="makeCode"
              value={form.makeCode ?? ''}
              onChange={handleChange}
              placeholder="All makes"
            />
            <FormField
              label="Model Code"
              name="modelCode"
              value={form.modelCode ?? ''}
              onChange={handleChange}
              placeholder="All models"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Amount ($)"
              name="amount"
              type="number"
              value={form.amount}
              onChange={handleChange}
              error={errors.amount}
              required
              placeholder="1500"
            />
            <FormField
              label="Rate Override (%)"
              name="rateOverride"
              type="number"
              value={form.rateOverride ?? ''}
              onChange={handleChange}
              placeholder="Optional"
            />
            <FormField
              label="Region Code"
              name="regionCode"
              value={form.regionCode ?? ''}
              onChange={handleChange}
              placeholder="All regions"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Start Date"
              name="startDate"
              type="date"
              value={form.startDate}
              onChange={handleChange}
              error={errors.startDate}
              required
            />
            <FormField
              label="End Date"
              name="endDate"
              type="date"
              value={form.endDate}
              onChange={handleChange}
              error={errors.endDate}
              required
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Max Units"
              name="maxUnits"
              type="number"
              value={form.maxUnits ?? ''}
              onChange={handleChange}
              placeholder="Unlimited"
            />
            <FormField
              label="Stackable"
              name="stackableFlag"
              type="select"
              value={form.stackableFlag}
              onChange={handleChange}
              options={STACKABLE_OPTIONS}
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
              {editing ? 'Update Incentive' : 'Create Incentive'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default IncentivesPage;
