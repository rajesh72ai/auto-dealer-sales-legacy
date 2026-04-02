import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, ShoppingCart } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getDeals, createDeal } from '@/api/deals';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { Deal, CreateDealRequest } from '@/types/sales';
import type { Dealer } from '@/types/admin';

// ── Status pipeline constants ─────────────────────────────────────

const STATUS_BADGE_STYLES: Record<string, string> = {
  WS: 'bg-gray-100 text-gray-700',
  NE: 'bg-blue-50 text-blue-700',
  PA: 'bg-amber-50 text-amber-700',
  AP: 'bg-green-50 text-green-700',
  FI: 'bg-purple-50 text-purple-700',
  CT: 'bg-indigo-50 text-indigo-700',
  DL: 'bg-emerald-50 text-emerald-700',
  CA: 'bg-red-50 text-red-700',
  UW: 'bg-orange-50 text-orange-700',
};

const STATUS_LABELS: Record<string, string> = {
  WS: 'Worksheet',
  NE: 'Negotiating',
  PA: 'Pending Approval',
  AP: 'Approved',
  FI: 'Finance',
  CT: 'Contracting',
  DL: 'Delivered',
  CA: 'Cancelled',
  UW: 'Unwound',
};

const DEAL_TYPE_BADGES: Record<string, string> = {
  N: 'bg-blue-50 text-blue-700',
  U: 'bg-amber-50 text-amber-700',
  L: 'bg-purple-50 text-purple-700',
  C: 'bg-teal-50 text-teal-700',
};

const DEAL_TYPE_LABELS: Record<string, string> = {
  N: 'New',
  U: 'Used',
  L: 'Lease',
  C: 'CPO',
};

const DEAL_TYPES = [
  { value: 'N', label: 'New' },
  { value: 'U', label: 'Used' },
  { value: 'L', label: 'Lease' },
  { value: 'C', label: 'CPO' },
];

type StatusTab = 'ALL' | 'ACTIVE' | 'DL' | 'CA';

const STATUS_TABS: { key: StatusTab; label: string }[] = [
  { key: 'ALL', label: 'All Deals' },
  { key: 'ACTIVE', label: 'Active' },
  { key: 'DL', label: 'Delivered' },
  { key: 'CA', label: 'Cancelled' },
];

function statusFilterValue(tab: StatusTab): string | undefined {
  switch (tab) {
    case 'ACTIVE': return 'WS,NE,PA,AP,CT,FI';
    case 'DL': return 'DL';
    case 'CA': return 'CA,UW';
    default: return undefined;
  }
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

const defaultForm: CreateDealRequest = {
  dealerCode: '',
  customerId: 0,
  vin: '',
  salespersonId: '',
  dealType: 'N',
};

function DealPipelinePage() {
  const { addToast } = useToast();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [items, setItems] = useState<Deal[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Filters
  const [dealerCode, setDealerCode] = useState(user?.dealerCode ?? '');
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [statusTab, setStatusTab] = useState<StatusTab>('ACTIVE');

  // Create modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState<CreateDealRequest>({ ...defaultForm, dealerCode: user?.dealerCode ?? '' });
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    getDealers({ size: 100, active: 'Y' })
      .then((res) => setDealers(res.content))
      .catch(() => {});
  }, []);

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      const result = await getDeals({
        dealerCode,
        status: statusFilterValue(statusTab),
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load deals');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusTab, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.dealerCode) errs.dealerCode = 'Dealer is required';
    if (!form.customerId) errs.customerId = 'Customer ID is required';
    if (!form.vin.trim()) errs.vin = 'VIN is required';
    if (!form.salespersonId.trim()) errs.salespersonId = 'Salesperson is required';
    if (!form.dealType) errs.dealType = 'Deal type is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      const deal = await createDeal(form);
      addToast('success', `Deal ${deal.dealNumber} created`);
      setIsModalOpen(false);
      navigate(`/deals/${deal.dealNumber}`);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create deal');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: name === 'customerId' ? (value ? Number(value) : 0) : value,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setForm({ ...defaultForm, dealerCode: dealerCode || user?.dealerCode || '' });
    setErrors({});
    setIsModalOpen(true);
  };

  // ── Column definitions ─────────────────────────────────────────

  const columns: Column<Deal>[] = [
    {
      key: 'dealNumber',
      header: 'Deal #',
      sortable: true,
      render: (row) => (
        <span className="font-mono text-sm font-semibold text-gray-900">{row.dealNumber}</span>
      ),
    },
    {
      key: 'customerName',
      header: 'Customer',
      sortable: true,
      render: (row) => (
        <span className="font-medium text-gray-900">{row.customerName}</span>
      ),
    },
    {
      key: 'vehicleDesc',
      header: 'Vehicle',
      render: (row) => (
        <div>
          <span className="text-sm text-gray-900">{row.vehicleDesc}</span>
          <p className="text-xs text-gray-400 font-mono">{row.vin}</p>
        </div>
      ),
    },
    {
      key: 'dealType',
      header: 'Type',
      render: (row) => (
        <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${DEAL_TYPE_BADGES[row.dealType] || 'bg-gray-100 text-gray-700'}`}>
          {DEAL_TYPE_LABELS[row.dealType] || row.dealType}
        </span>
      ),
    },
    {
      key: 'dealStatus',
      header: 'Status',
      render: (row) => (
        <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${STATUS_BADGE_STYLES[row.dealStatus] || 'bg-gray-100 text-gray-700'}`}>
          <span className={`h-1.5 w-1.5 rounded-full ${
            row.dealStatus === 'WS' ? 'bg-gray-400' :
            row.dealStatus === 'NE' ? 'bg-blue-500' :
            row.dealStatus === 'PA' ? 'bg-amber-500' :
            row.dealStatus === 'AP' ? 'bg-green-500' :
            row.dealStatus === 'FI' ? 'bg-purple-500' :
            row.dealStatus === 'CT' ? 'bg-indigo-500' :
            row.dealStatus === 'DL' ? 'bg-emerald-500' :
            row.dealStatus === 'CA' ? 'bg-red-500' :
            row.dealStatus === 'UW' ? 'bg-orange-500' : 'bg-gray-400'
          }`} />
          {STATUS_LABELS[row.dealStatus] || row.dealStatus}
        </span>
      ),
    },
    {
      key: 'totalPrice',
      header: 'Price',
      sortable: true,
      render: (row) => (
        <span className="font-semibold text-gray-900">
          {row.formattedTotalPrice || formatCurrency(row.totalPrice)}
        </span>
      ),
    },
    {
      key: 'totalGross',
      header: 'Gross',
      sortable: true,
      render: (row) => (
        <span className={`font-semibold ${row.totalGross >= 0 ? 'text-green-700' : 'text-red-600'}`}>
          {formatCurrency(row.totalGross)}
        </span>
      ),
    },
    {
      key: 'dealDate',
      header: 'Date',
      sortable: true,
      render: (row) => (
        <span className="text-sm text-gray-500">
          {row.dealDate ? new Date(row.dealDate).toLocaleDateString() : '\u2014'}
        </span>
      ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
            <ShoppingCart className="h-5 w-5 text-indigo-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Deal Pipeline</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage deals from worksheet to delivery</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          New Deal
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-end gap-4">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-500">Dealer</label>
          <select
            value={dealerCode}
            onChange={(e) => { setDealerCode(e.target.value); setPage(0); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          >
            <option value="">Select Dealer</option>
            {dealers.map((d) => (
              <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
            ))}
          </select>
        </div>

        {/* Status tabs */}
        <div className="flex rounded-lg border border-gray-200 bg-gray-50 p-0.5">
          {STATUS_TABS.map((tab) => (
            <button
              key={tab.key}
              onClick={() => { setStatusTab(tab.key); setPage(0); }}
              className={`rounded-md px-3.5 py-1.5 text-sm font-medium transition-colors ${
                statusTab === tab.key
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {!dealerCode && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Please select a dealer to view deals.
        </div>
      )}

      {/* Table */}
      {dealerCode && (
        <DataTable
          columns={columns}
          data={items}
          loading={loading}
          page={page}
          totalPages={totalPages}
          totalElements={totalElements}
          onPageChange={setPage}
          onRowClick={(row) => navigate(`/deals/${row.dealNumber}`)}
        />
      )}

      {/* Create Deal Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="New Deal Worksheet"
        size="lg"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <FormField
            label="Dealer Code"
            name="dealerCode"
            value={form.dealerCode}
            onChange={handleChange}
            error={errors.dealerCode}
            required
            disabled
          />
          <FormField
            label="Customer ID"
            name="customerId"
            type="number"
            value={form.customerId || ''}
            onChange={handleChange}
            error={errors.customerId}
            required
            placeholder="Search by customer ID"
          />
          <FormField
            label="Vehicle VIN"
            name="vin"
            value={form.vin}
            onChange={handleChange}
            error={errors.vin}
            required
            placeholder="17-character VIN"
          />
          <FormField
            label="Salesperson ID"
            name="salespersonId"
            value={form.salespersonId}
            onChange={handleChange}
            error={errors.salespersonId}
            required
            placeholder="SLP001"
          />
          <FormField
            label="Deal Type"
            name="dealType"
            type="select"
            value={form.dealType}
            onChange={handleChange}
            error={errors.dealType}
            required
            options={DEAL_TYPES}
          />

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
              Create Worksheet
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default DealPipelinePage;
