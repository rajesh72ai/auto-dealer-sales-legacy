import { useState, useEffect, useCallback } from 'react';
import {
  Plus,
  Landmark,
  Search,
  DollarSign,
  Percent,
  Clock,
  CheckCircle2,
  XCircle,
  AlertTriangle,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import {
  listFinanceApps,
  createFinanceApp,
  approveOrDeclineFinanceApp,
} from '@/api/finance';
import type {
  FinanceApp,
  FinanceAppRequest,
  FinanceApprovalRequest,
  FinanceApprovalResponse,
} from '@/types/finance';

// ── Status styling ──────────────────────────────────────────────

const STATUS_BADGE_STYLES: Record<string, string> = {
  NW: 'bg-blue-50 text-blue-700',
  AP: 'bg-green-50 text-green-700',
  CD: 'bg-yellow-50 text-yellow-700',
  DN: 'bg-red-50 text-red-700',
};

const STATUS_DOT: Record<string, string> = {
  NW: 'bg-blue-500',
  AP: 'bg-green-500',
  CD: 'bg-yellow-500',
  DN: 'bg-red-500',
};

const STATUS_LABELS: Record<string, string> = {
  NW: 'New',
  AP: 'Approved',
  CD: 'Conditional',
  DN: 'Declined',
};

const FINANCE_TYPE_LABELS: Record<string, string> = {
  L: 'Loan',
  S: 'Lease',
  C: 'Cash',
};

const STATUS_OPTIONS = [
  { value: '', label: 'All Status' },
  { value: 'NW', label: 'New' },
  { value: 'AP', label: 'Approved' },
  { value: 'CD', label: 'Conditional' },
  { value: 'DN', label: 'Declined' },
];

const FINANCE_TYPE_OPTIONS = [
  { value: '', label: 'All Types' },
  { value: 'L', label: 'Loan' },
  { value: 'S', label: 'Lease' },
  { value: 'C', label: 'Cash' },
];

const FINANCE_TYPE_FORM_OPTIONS = [
  { value: 'L', label: 'Loan' },
  { value: 'S', label: 'Lease' },
  { value: 'C', label: 'Cash' },
];

const APPROVAL_ACTIONS = [
  { value: 'AP', label: 'Approve' },
  { value: 'CD', label: 'Conditional Approval' },
  { value: 'DN', label: 'Decline' },
];

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatCurrencyDecimal(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

const defaultCreateForm: FinanceAppRequest = {
  dealNumber: '',
  financeType: 'L',
  lenderCode: '',
  amountRequested: 0,
  aprRequested: 0,
  termMonths: 60,
  downPayment: 0,
};

function FinanceApplicationsPage() {
  const { addToast } = useToast();

  // List state
  const [items, setItems] = useState<FinanceApp[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Filters
  const [statusFilter, setStatusFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [dealSearch, setDealSearch] = useState('');

  // Create modal
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState<FinanceAppRequest>({ ...defaultCreateForm });
  const [createErrors, setCreateErrors] = useState<Record<string, string>>({});

  // Approval modal
  const [isApprovalOpen, setIsApprovalOpen] = useState(false);
  const [selectedApp, setSelectedApp] = useState<FinanceApp | null>(null);
  const [approvalAction, setApprovalAction] = useState('AP');
  const [approvedAmount, setApprovedAmount] = useState(0);
  const [approvedApr, setApprovedApr] = useState(0);
  const [stipulations, setStipulations] = useState('');
  const [approvalResult, setApprovalResult] = useState<FinanceApprovalResponse | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listFinanceApps({
        status: statusFilter || undefined,
        financeType: typeFilter || undefined,
        dealNumber: dealSearch.trim() || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load finance applications');
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter, typeFilter, dealSearch, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // ── Create Handlers ─────────────────────────────────────────

  const validateCreate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!createForm.dealNumber.trim()) errs.dealNumber = 'Deal number is required';
    if (!createForm.financeType) errs.financeType = 'Finance type is required';
    if (!createForm.amountRequested || createForm.amountRequested <= 0) errs.amountRequested = 'Amount is required';
    setCreateErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleCreateChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setCreateForm((prev) => ({
      ...prev,
      [name]: ['amountRequested', 'aprRequested', 'termMonths', 'downPayment'].includes(name) ? Number(value) : value,
    }));
    if (createErrors[name]) setCreateErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateCreate()) return;
    setSubmitting(true);
    try {
      const app = await createFinanceApp(createForm);
      addToast('success', `Finance application ${app.financeId} created`);
      setIsCreateOpen(false);
      setCreateForm({ ...defaultCreateForm });
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create application');
    } finally {
      setSubmitting(false);
    }
  };

  const openCreate = () => {
    setCreateForm({ ...defaultCreateForm });
    setCreateErrors({});
    setIsCreateOpen(true);
  };

  // ── Approval Handlers ───────────────────────────────────────

  const openApproval = (app: FinanceApp) => {
    if (app.appStatus !== 'NW' && app.appStatus !== 'CD') return;
    setSelectedApp(app);
    setApprovalAction('AP');
    setApprovedAmount(app.amountRequested);
    setApprovedApr(app.aprRequested);
    setStipulations('');
    setApprovalResult(null);
    setIsApprovalOpen(true);
  };

  const handleApprovalSubmit = async () => {
    if (!selectedApp) return;
    setSubmitting(true);
    try {
      const request: FinanceApprovalRequest = {
        financeId: selectedApp.financeId,
        action: approvalAction,
        amountApproved: approvalAction === 'AP' ? approvedAmount : undefined,
        aprApproved: approvalAction === 'AP' ? approvedApr : undefined,
        stipulations: approvalAction === 'CD' ? stipulations : undefined,
      };
      const result = await approveOrDeclineFinanceApp(request);
      setApprovalResult(result);
      addToast('success', `Application ${result.actionName}`);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Approval action failed');
    } finally {
      setSubmitting(false);
    }
  };

  // ── KPI Cards ───────────────────────────────────────────────

  const kpiNew = items.filter((i) => i.appStatus === 'NW').length;
  const kpiApproved = items.filter((i) => i.appStatus === 'AP').length;
  const kpiConditional = items.filter((i) => i.appStatus === 'CD').length;
  const kpiDeclined = items.filter((i) => i.appStatus === 'DN').length;

  // ── Column Definitions ──────────────────────────────────────

  const columns: Column<FinanceApp>[] = [
    {
      key: 'financeId',
      header: 'Finance ID',
      sortable: true,
      render: (row) => (
        <span className="font-mono text-sm font-semibold text-gray-900">{row.financeId}</span>
      ),
    },
    {
      key: 'dealNumber',
      header: 'Deal #',
      sortable: true,
      render: (row) => (
        <span className="font-mono text-sm text-gray-700">{row.dealNumber}</span>
      ),
    },
    {
      key: 'financeType',
      header: 'Type',
      render: (row) => (
        <span className="inline-flex rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-700">
          {row.financeTypeName || FINANCE_TYPE_LABELS[row.financeType] || row.financeType}
        </span>
      ),
    },
    {
      key: 'lenderName',
      header: 'Lender',
      render: (row) => (
        <span className="text-sm text-gray-700">{row.lenderName || row.lenderCode || '\u2014'}</span>
      ),
    },
    {
      key: 'amountRequested',
      header: 'Amount',
      sortable: true,
      render: (row) => (
        <span className="text-sm font-semibold text-gray-900">{formatCurrency(row.amountRequested)}</span>
      ),
    },
    {
      key: 'aprRequested',
      header: 'APR',
      render: (row) => (
        <span className="text-sm text-gray-700">{row.aprRequested?.toFixed(2)}%</span>
      ),
    },
    {
      key: 'termMonths',
      header: 'Term',
      render: (row) => (
        <span className="text-sm text-gray-700">{row.termMonths} mo</span>
      ),
    },
    {
      key: 'monthlyPayment',
      header: 'Monthly',
      sortable: true,
      render: (row) => (
        <span className="text-sm font-semibold text-gray-900">
          {row.monthlyPayment ? formatCurrencyDecimal(row.monthlyPayment) : '\u2014'}
        </span>
      ),
    },
    {
      key: 'appStatus',
      header: 'Status',
      render: (row) => (
        <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${STATUS_BADGE_STYLES[row.appStatus] || 'bg-gray-100 text-gray-700'}`}>
          <span className={`h-1.5 w-1.5 rounded-full ${STATUS_DOT[row.appStatus] || 'bg-gray-400'}`} />
          {row.statusName || STATUS_LABELS[row.appStatus] || row.appStatus}
        </span>
      ),
    },
    {
      key: 'actions',
      header: '',
      render: (row) =>
        (row.appStatus === 'NW' || row.appStatus === 'CD') ? (
          <button
            onClick={(e) => { e.stopPropagation(); openApproval(row); }}
            className="rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-medium text-blue-700 transition-colors hover:bg-blue-100"
          >
            Review
          </button>
        ) : null,
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
            <Landmark className="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Finance Applications</h1>
            <p className="mt-0.5 text-sm text-gray-500">Review, approve, and manage financing requests</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          New Application
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiMini icon={<Clock className="h-4 w-4 text-blue-600" />} iconBg="bg-blue-50" label="Pending Review" value={kpiNew} />
        <KpiMini icon={<CheckCircle2 className="h-4 w-4 text-green-600" />} iconBg="bg-green-50" label="Approved" value={kpiApproved} />
        <KpiMini icon={<AlertTriangle className="h-4 w-4 text-yellow-600" />} iconBg="bg-yellow-50" label="Conditional" value={kpiConditional} />
        <KpiMini icon={<XCircle className="h-4 w-4 text-red-600" />} iconBg="bg-red-50" label="Declined" value={kpiDeclined} />
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
        <select
          value={typeFilter}
          onChange={(e) => { setTypeFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          {FINANCE_TYPE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
        <div className="relative">
          <input
            type="text"
            value={dealSearch}
            onChange={(e) => { setDealSearch(e.target.value); setPage(0); }}
            placeholder="Search deal #..."
            className="w-48 rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          />
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
        </div>
        {(statusFilter || typeFilter || dealSearch) && (
          <button
            onClick={() => { setStatusFilter(''); setTypeFilter(''); setDealSearch(''); setPage(0); }}
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
        onRowClick={(row) => openApproval(row)}
      />

      {/* ── Create Modal ──────────────────────────────────────── */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="New Finance Application"
        size="lg"
      >
        <form onSubmit={handleCreateSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Deal Number"
              name="dealNumber"
              value={createForm.dealNumber}
              onChange={handleCreateChange}
              error={createErrors.dealNumber}
              required
              placeholder="e.g. DL-10042"
            />
            <FormField
              label="Finance Type"
              name="financeType"
              type="select"
              value={createForm.financeType}
              onChange={handleCreateChange}
              error={createErrors.financeType}
              required
              options={FINANCE_TYPE_FORM_OPTIONS}
            />
          </div>
          <FormField
            label="Lender Code"
            name="lenderCode"
            value={createForm.lenderCode ?? ''}
            onChange={handleCreateChange}
            placeholder="e.g. CAPONE, ALLY"
          />
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Amount Requested"
              name="amountRequested"
              type="number"
              value={createForm.amountRequested || ''}
              onChange={handleCreateChange}
              error={createErrors.amountRequested}
              required
              placeholder="35000"
            />
            <FormField
              label="APR %"
              name="aprRequested"
              type="number"
              value={createForm.aprRequested || ''}
              onChange={handleCreateChange}
              placeholder="5.99"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Term (Months)"
              name="termMonths"
              type="number"
              value={createForm.termMonths || ''}
              onChange={handleCreateChange}
              placeholder="60"
            />
            <FormField
              label="Down Payment"
              name="downPayment"
              type="number"
              value={createForm.downPayment || ''}
              onChange={handleCreateChange}
              placeholder="5000"
            />
          </div>

          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsCreateOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:opacity-50"
            >
              {submitting ? 'Submitting...' : 'Submit Application'}
            </button>
          </div>
        </form>
      </Modal>

      {/* ── Approval Modal ────────────────────────────────────── */}
      <Modal
        isOpen={isApprovalOpen}
        onClose={() => setIsApprovalOpen(false)}
        title="Review Finance Application"
        size="xl"
      >
        {selectedApp && !approvalResult && (
          <div className="space-y-5">
            {/* Application Summary */}
            <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Finance ID</p>
                  <p className="mt-0.5 font-mono font-semibold text-gray-900">{selectedApp.financeId}</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Deal #</p>
                  <p className="mt-0.5 font-mono font-semibold text-gray-900">{selectedApp.dealNumber}</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Type</p>
                  <p className="mt-0.5 font-semibold text-gray-900">{FINANCE_TYPE_LABELS[selectedApp.financeType] || selectedApp.financeType}</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Lender</p>
                  <p className="mt-0.5 font-semibold text-gray-900">{selectedApp.lenderName || selectedApp.lenderCode}</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Amount</p>
                  <p className="mt-0.5 font-semibold text-gray-900">{formatCurrency(selectedApp.amountRequested)}</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">APR</p>
                  <p className="mt-0.5 font-semibold text-gray-900">{selectedApp.aprRequested?.toFixed(2)}%</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Term</p>
                  <p className="mt-0.5 font-semibold text-gray-900">{selectedApp.termMonths} months</p>
                </div>
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Down Payment</p>
                  <p className="mt-0.5 font-semibold text-gray-900">{formatCurrency(selectedApp.downPayment)}</p>
                </div>
              </div>
            </div>

            {/* Decision */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Decision</label>
              <div className="flex gap-2">
                {APPROVAL_ACTIONS.map((a) => (
                  <button
                    key={a.value}
                    type="button"
                    onClick={() => setApprovalAction(a.value)}
                    className={`flex-1 rounded-lg border px-3 py-2.5 text-sm font-medium transition-colors ${
                      approvalAction === a.value
                        ? a.value === 'AP' ? 'border-green-500 bg-green-50 text-green-700'
                          : a.value === 'CD' ? 'border-yellow-500 bg-yellow-50 text-yellow-700'
                          : 'border-red-500 bg-red-50 text-red-700'
                        : 'border-gray-200 text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    {a.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Approve fields */}
            {approvalAction === 'AP' && (
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-gray-700">Approved Amount</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">
                      <DollarSign className="h-4 w-4" />
                    </span>
                    <input
                      type="number"
                      value={approvedAmount || ''}
                      onChange={(e) => setApprovedAmount(Number(e.target.value))}
                      className="block w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                    />
                  </div>
                </div>
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-gray-700">Approved APR</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">
                      <Percent className="h-4 w-4" />
                    </span>
                    <input
                      type="number"
                      step="0.01"
                      value={approvedApr || ''}
                      onChange={(e) => setApprovedApr(Number(e.target.value))}
                      className="block w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Conditional fields */}
            {approvalAction === 'CD' && (
              <div>
                <label className="mb-1.5 block text-sm font-medium text-gray-700">Stipulations</label>
                <textarea
                  value={stipulations}
                  onChange={(e) => setStipulations(e.target.value)}
                  rows={3}
                  placeholder="Enter required stipulations for conditional approval..."
                  className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
              </div>
            )}

            <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
              <button
                type="button"
                onClick={() => setIsApprovalOpen(false)}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleApprovalSubmit}
                disabled={submitting}
                className={`rounded-lg px-4 py-2 text-sm font-medium text-white transition-colors disabled:opacity-50 ${
                  approvalAction === 'AP' ? 'bg-green-600 hover:bg-green-700'
                    : approvalAction === 'DN' ? 'bg-red-600 hover:bg-red-700'
                    : 'bg-yellow-600 hover:bg-yellow-700'
                }`}
              >
                {submitting ? 'Processing...' : `Confirm ${APPROVAL_ACTIONS.find((a) => a.value === approvalAction)?.label}`}
              </button>
            </div>
          </div>
        )}

        {/* Approval Result */}
        {approvalResult && (
          <div className="space-y-4">
            <div className="rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-800">
              <CheckCircle2 className="mr-1.5 inline h-4 w-4" />
              Decision recorded: <strong>{approvalResult.actionName}</strong>
            </div>

            {approvalResult.monthlyPayment > 0 && (
              <div className="rounded-lg border border-gray-200 bg-white p-4">
                <p className="text-xs font-medium uppercase text-gray-500">Recalculated Monthly Payment</p>
                <p className="mt-1 text-3xl font-bold text-gray-900">{formatCurrencyDecimal(approvalResult.monthlyPayment)}</p>
                <div className="mt-3 grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <p className="text-xs text-gray-500">Approved Amount</p>
                    <p className="font-semibold text-gray-900">{formatCurrency(approvalResult.approvedAmount)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Total of Payments</p>
                    <p className="font-semibold text-gray-900">{formatCurrencyDecimal(approvalResult.totalOfPayments)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Total Interest</p>
                    <p className="font-semibold text-gray-900">{formatCurrencyDecimal(approvalResult.totalInterest)}</p>
                  </div>
                </div>
              </div>
            )}

            <div className="flex justify-end border-t border-gray-200 pt-4">
              <button
                onClick={() => setIsApprovalOpen(false)}
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
              >
                Done
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

function KpiMini({ icon, iconBg, label, value }: { icon: React.ReactNode; iconBg: string; label: string; value: number }) {
  return (
    <div className="flex items-center gap-4 rounded-xl border border-gray-100 bg-white p-4 shadow-card transition-shadow hover:shadow-card-hover">
      <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${iconBg}`}>
        {icon}
      </div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="text-xl font-bold text-gray-900">{value}</p>
      </div>
    </div>
  );
}

export default FinanceApplicationsPage;
