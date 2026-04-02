import { useState, useEffect, useCallback } from 'react';
import { Plus, DollarSign, History, TrendingUp, TrendingDown } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getPricing, createPrice, updatePrice, getPriceHistory } from '@/api/pricing';
import type { PriceMaster, PriceMasterRequest } from '@/types/admin';

const MAKES = [
  { value: 'FRD', label: 'Ford' },
  { value: 'TYT', label: 'Toyota' },
  { value: 'HND', label: 'Honda' },
  { value: 'CHV', label: 'Chevrolet' },
  { value: 'BMW', label: 'BMW' },
];

const currentYear = new Date().getFullYear();
const YEARS = Array.from({ length: 5 }, (_, i) => ({
  value: String(currentYear + 1 - i),
  label: String(currentYear + 1 - i),
}));

const defaultForm: PriceMasterRequest = {
  modelYear: currentYear,
  makeCode: '',
  modelCode: '',
  msrp: 0,
  invoicePrice: 0,
  holdbackAmt: 0,
  holdbackPct: 0,
  destinationFee: 0,
  advertisingFee: 0,
  effectiveDate: new Date().toISOString().split('T')[0],
  expiryDate: null,
};

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);
}

function PricingPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<PriceMaster[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [editing, setEditing] = useState<PriceMaster | null>(null);
  const [form, setForm] = useState<PriceMasterRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [makeFilter, setMakeFilter] = useState('');
  const [yearFilter, setYearFilter] = useState('');
  const [historyItems, setHistoryItems] = useState<PriceMaster[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [historyTitle, setHistoryTitle] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getPricing({
        page,
        size: 20,
        make: makeFilter || undefined,
        year: yearFilter ? Number(yearFilter) : undefined,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load pricing data');
    } finally {
      setLoading(false);
    }
  }, [page, makeFilter, yearFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const computedMargin = form.msrp - form.invoicePrice;

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.makeCode) errs.makeCode = 'Make is required';
    if (!form.modelCode.trim()) errs.modelCode = 'Model code is required';
    if (form.msrp <= 0) errs.msrp = 'MSRP must be greater than 0';
    if (form.invoicePrice <= 0) errs.invoicePrice = 'Invoice price must be greater than 0';
    if (!form.effectiveDate) errs.effectiveDate = 'Effective date is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updatePrice(editing.modelYear, editing.makeCode, editing.modelCode, form);
        addToast('success', 'Pricing updated successfully');
      } else {
        await createPrice(form);
        addToast('success', 'Pricing created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: ['modelYear', 'msrp', 'invoicePrice', 'holdbackAmt', 'holdbackPct', 'destinationFee', 'advertisingFee'].includes(name)
        ? Number(value)
        : value,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (item: PriceMaster) => {
    setEditing(item);
    setForm({
      modelYear: item.modelYear,
      makeCode: item.makeCode,
      modelCode: item.modelCode,
      msrp: item.msrp,
      invoicePrice: item.invoicePrice,
      holdbackAmt: item.holdbackAmt,
      holdbackPct: item.holdbackPct,
      destinationFee: item.destinationFee,
      advertisingFee: item.advertisingFee,
      effectiveDate: item.effectiveDate,
      expiryDate: item.expiryDate,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const openHistory = async (item: PriceMaster) => {
    setHistoryTitle(`${item.modelYear} ${item.makeCode} ${item.modelCode}`);
    setHistoryLoading(true);
    setIsHistoryOpen(true);
    try {
      const result = await getPriceHistory(item.modelYear, item.makeCode, item.modelCode);
      setHistoryItems(result.content.slice(0, 5));
    } catch {
      addToast('error', 'Failed to load price history');
      setHistoryItems([]);
    } finally {
      setHistoryLoading(false);
    }
  };

  const columns: Column<PriceMaster>[] = [
    { key: 'modelYear', header: 'Year', sortable: true },
    {
      key: 'makeCode',
      header: 'Make',
      sortable: true,
      render: (row) => (
        <span className="inline-flex items-center rounded-md bg-gray-100 px-2 py-0.5 text-xs font-semibold text-gray-700">
          {MAKES.find((m) => m.value === row.makeCode)?.label ?? row.makeCode}
        </span>
      ),
    },
    { key: 'modelCode', header: 'Model' },
    {
      key: 'msrp',
      header: 'MSRP',
      sortable: true,
      render: (row) => (
        <span className="font-semibold text-gray-900">{row.formattedMsrp || formatCurrency(row.msrp)}</span>
      ),
    },
    {
      key: 'invoicePrice',
      header: 'Invoice',
      render: (row) => (
        <span className="text-gray-700">{row.formattedInvoice || formatCurrency(row.invoicePrice)}</span>
      ),
    },
    {
      key: 'dealerMargin',
      header: 'Margin',
      sortable: true,
      render: (row) => {
        const margin = row.dealerMargin;
        const positive = margin > 0;
        return (
          <div className="flex items-center gap-1">
            {positive ? (
              <TrendingUp className="h-3.5 w-3.5 text-emerald-500" />
            ) : (
              <TrendingDown className="h-3.5 w-3.5 text-red-500" />
            )}
            <span className={`font-semibold ${positive ? 'text-emerald-600' : 'text-red-600'}`}>
              {formatCurrency(margin)}
            </span>
          </div>
        );
      },
    },
    {
      key: 'holdbackAmt',
      header: 'Holdback',
      render: (row) => formatCurrency(row.holdbackAmt),
    },
    { key: 'effectiveDate', header: 'Effective', sortable: true },
    {
      key: '_actions',
      header: '',
      render: (row) => (
        <button
          onClick={(e) => { e.stopPropagation(); openHistory(row); }}
          className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium text-brand-600 transition-colors hover:bg-brand-50"
          title="View price history"
        >
          <History className="h-3.5 w-3.5" />
          History
        </button>
      ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
            <DollarSign className="h-5 w-5 text-emerald-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Pricing</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage MSRP, invoice prices, holdbacks, and dealer margins</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Pricing
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={makeFilter}
          onChange={(e) => { setMakeFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Makes</option>
          {MAKES.map((m) => (
            <option key={m.value} value={m.value}>{m.label}</option>
          ))}
        </select>
        <select
          value={yearFilter}
          onChange={(e) => { setYearFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Years</option>
          {YEARS.map((y) => (
            <option key={y.value} value={y.value}>{y.label}</option>
          ))}
        </select>
        {(makeFilter || yearFilter) && (
          <button
            onClick={() => { setMakeFilter(''); setYearFilter(''); setPage(0); }}
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
        title={editing ? 'Edit Pricing' : 'New Pricing'}
        size="xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Model Year"
              name="modelYear"
              type="select"
              value={form.modelYear}
              onChange={handleChange}
              required
              options={YEARS}
              disabled={!!editing}
            />
            <FormField
              label="Make"
              name="makeCode"
              type="select"
              value={form.makeCode}
              onChange={handleChange}
              error={errors.makeCode}
              required
              options={MAKES}
              disabled={!!editing}
            />
            <FormField
              label="Model Code"
              name="modelCode"
              value={form.modelCode}
              onChange={handleChange}
              error={errors.modelCode}
              required
              placeholder="CAM"
              disabled={!!editing}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="MSRP ($)"
              name="msrp"
              type="number"
              value={form.msrp}
              onChange={handleChange}
              error={errors.msrp}
              required
              placeholder="28000"
            />
            <FormField
              label="Invoice Price ($)"
              name="invoicePrice"
              type="number"
              value={form.invoicePrice}
              onChange={handleChange}
              error={errors.invoicePrice}
              required
              placeholder="25500"
            />
          </div>

          {/* Computed margin display */}
          <div className="rounded-lg border border-gray-200 bg-gray-50 px-4 py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-600">Calculated Dealer Margin</span>
              <span className={`text-lg font-bold ${computedMargin > 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                {formatCurrency(computedMargin)}
              </span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Holdback Amount ($)"
              name="holdbackAmt"
              type="number"
              value={form.holdbackAmt}
              onChange={handleChange}
              placeholder="500"
            />
            <FormField
              label="Holdback %"
              name="holdbackPct"
              type="number"
              value={form.holdbackPct}
              onChange={handleChange}
              placeholder="2.0"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Destination Fee ($)"
              name="destinationFee"
              type="number"
              value={form.destinationFee}
              onChange={handleChange}
              placeholder="995"
            />
            <FormField
              label="Advertising Fee ($)"
              name="advertisingFee"
              type="number"
              value={form.advertisingFee}
              onChange={handleChange}
              placeholder="200"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Effective Date"
              name="effectiveDate"
              type="date"
              value={form.effectiveDate}
              onChange={handleChange}
              error={errors.effectiveDate}
              required
            />
            <FormField
              label="Expiry Date"
              name="expiryDate"
              type="date"
              value={form.expiryDate ?? ''}
              onChange={handleChange}
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
              {editing ? 'Update Pricing' : 'Create Pricing'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Price History Modal */}
      <Modal
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        title={`Price History \u2014 ${historyTitle}`}
        size="lg"
      >
        {historyLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-gray-200 border-t-brand-600" />
          </div>
        ) : historyItems.length === 0 ? (
          <p className="py-8 text-center text-sm text-gray-400">No price history available.</p>
        ) : (
          <div className="divide-y divide-gray-100">
            {historyItems.map((h, i) => (
              <div key={i} className="flex items-center justify-between px-2 py-3">
                <div>
                  <p className="text-sm font-medium text-gray-900">{formatCurrency(h.msrp)} MSRP</p>
                  <p className="text-xs text-gray-500">Invoice: {formatCurrency(h.invoicePrice)}</p>
                </div>
                <div className="text-right">
                  <p className={`text-sm font-semibold ${h.dealerMargin > 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                    {formatCurrency(h.dealerMargin)} margin
                  </p>
                  <p className="text-xs text-gray-400">Effective {h.effectiveDate}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </Modal>
    </div>
  );
}

export default PricingPage;
