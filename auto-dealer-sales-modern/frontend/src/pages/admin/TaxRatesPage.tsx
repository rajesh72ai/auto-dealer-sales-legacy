import { useState, useEffect, useCallback } from 'react';
import { Plus, Percent, Calculator } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getTaxRates, createTaxRate, updateTaxRate, calculateTax } from '@/api/taxRates';
import type { TaxRate, TaxRateRequest } from '@/types/admin';

const US_STATES = [
  { value: 'AL', label: 'Alabama' }, { value: 'AK', label: 'Alaska' }, { value: 'AZ', label: 'Arizona' },
  { value: 'AR', label: 'Arkansas' }, { value: 'CA', label: 'California' }, { value: 'CO', label: 'Colorado' },
  { value: 'CT', label: 'Connecticut' }, { value: 'DE', label: 'Delaware' }, { value: 'FL', label: 'Florida' },
  { value: 'GA', label: 'Georgia' }, { value: 'HI', label: 'Hawaii' }, { value: 'ID', label: 'Idaho' },
  { value: 'IL', label: 'Illinois' }, { value: 'IN', label: 'Indiana' }, { value: 'IA', label: 'Iowa' },
  { value: 'KS', label: 'Kansas' }, { value: 'KY', label: 'Kentucky' }, { value: 'LA', label: 'Louisiana' },
  { value: 'ME', label: 'Maine' }, { value: 'MD', label: 'Maryland' }, { value: 'MA', label: 'Massachusetts' },
  { value: 'MI', label: 'Michigan' }, { value: 'MN', label: 'Minnesota' }, { value: 'MS', label: 'Mississippi' },
  { value: 'MO', label: 'Missouri' }, { value: 'MT', label: 'Montana' }, { value: 'NE', label: 'Nebraska' },
  { value: 'NV', label: 'Nevada' }, { value: 'NH', label: 'New Hampshire' }, { value: 'NJ', label: 'New Jersey' },
  { value: 'NM', label: 'New Mexico' }, { value: 'NY', label: 'New York' }, { value: 'NC', label: 'North Carolina' },
  { value: 'ND', label: 'North Dakota' }, { value: 'OH', label: 'Ohio' }, { value: 'OK', label: 'Oklahoma' },
  { value: 'OR', label: 'Oregon' }, { value: 'PA', label: 'Pennsylvania' }, { value: 'RI', label: 'Rhode Island' },
  { value: 'SC', label: 'South Carolina' }, { value: 'SD', label: 'South Dakota' }, { value: 'TN', label: 'Tennessee' },
  { value: 'TX', label: 'Texas' }, { value: 'UT', label: 'Utah' }, { value: 'VT', label: 'Vermont' },
  { value: 'VA', label: 'Virginia' }, { value: 'WA', label: 'Washington' }, { value: 'WV', label: 'West Virginia' },
  { value: 'WI', label: 'Wisconsin' }, { value: 'WY', label: 'Wyoming' },
];

const defaultForm: TaxRateRequest = {
  stateCode: '',
  countyCode: '',
  cityCode: '',
  stateRate: 0,
  countyRate: 0,
  cityRate: 0,
  docFeeMax: 0,
  titleFee: 0,
  regFee: 0,
  effectiveDate: new Date().toISOString().split('T')[0],
  expiryDate: null,
};

function formatRate(rate: number): string {
  return (rate * 100).toFixed(3) + '%';
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 2 }).format(amount);
}

function TaxRatesPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<TaxRate[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<TaxRate | null>(null);
  const [form, setForm] = useState<TaxRateRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [stateFilter, setStateFilter] = useState('');

  // Tax calculator state
  const [calcPrice, setCalcPrice] = useState<number>(30000);
  const [calcTradeIn, setCalcTradeIn] = useState<number>(0);
  const [calcState, setCalcState] = useState('');
  const [calcCounty, setCalcCounty] = useState('');
  const [calcCity, setCalcCity] = useState('');
  const [calcResult, setCalcResult] = useState<TaxRate | null>(null);
  const [calcLoading, setCalcLoading] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getTaxRates({
        page,
        size: 20,
        state: stateFilter || undefined,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load tax rates');
    } finally {
      setLoading(false);
    }
  }, [page, stateFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.stateCode) errs.stateCode = 'State is required';
    if (!form.countyCode.trim()) errs.countyCode = 'County code is required';
    if (!form.cityCode.trim()) errs.cityCode = 'City code is required';
    if (!form.effectiveDate) errs.effectiveDate = 'Effective date is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updateTaxRate(editing.stateCode, editing.countyCode, editing.cityCode, form);
        addToast('success', 'Tax rate updated successfully');
      } else {
        await createTaxRate(form);
        addToast('success', 'Tax rate created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    const numericFields = ['stateRate', 'countyRate', 'cityRate', 'docFeeMax', 'titleFee', 'regFee'];
    setForm((prev) => ({
      ...prev,
      [name]: numericFields.includes(name)
        ? (name.endsWith('Rate') ? Number(value) / 100 : Number(value))
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

  const openEdit = (item: TaxRate) => {
    setEditing(item);
    setForm({
      stateCode: item.stateCode,
      countyCode: item.countyCode,
      cityCode: item.cityCode,
      stateRate: item.stateRate,
      countyRate: item.countyRate,
      cityRate: item.cityRate,
      docFeeMax: item.docFeeMax,
      titleFee: item.titleFee,
      regFee: item.regFee,
      effectiveDate: item.effectiveDate,
      expiryDate: item.expiryDate,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const handleCalculate = async () => {
    if (!calcState || !calcCounty || !calcCity) {
      addToast('warning', 'Please enter state, county, and city codes');
      return;
    }
    setCalcLoading(true);
    try {
      const result = await calculateTax({
        taxableAmount: calcPrice,
        tradeAllowance: calcTradeIn,
        stateCode: calcState,
        countyCode: calcCounty,
        cityCode: calcCity,
      });
      setCalcResult(result);
    } catch {
      addToast('error', 'Tax calculation failed');
      setCalcResult(null);
    } finally {
      setCalcLoading(false);
    }
  };

  const columns: Column<TaxRate>[] = [
    { key: 'stateCode', header: 'State', sortable: true },
    { key: 'countyCode', header: 'County' },
    { key: 'cityCode', header: 'City' },
    {
      key: 'stateRate',
      header: 'State Rate',
      render: (row) => formatRate(row.stateRate),
    },
    {
      key: 'countyRate',
      header: 'County Rate',
      render: (row) => formatRate(row.countyRate),
    },
    {
      key: 'cityRate',
      header: 'City Rate',
      render: (row) => formatRate(row.cityRate),
    },
    {
      key: 'combinedRate',
      header: 'Combined',
      sortable: true,
      render: (row) => {
        const pct = row.combinedRate * 100;
        const highlight = pct > 10;
        return (
          <span className={`font-semibold ${highlight ? 'rounded bg-red-50 px-1.5 py-0.5 text-red-700' : 'text-gray-900'}`}>
            {row.combinedPct || formatRate(row.combinedRate)}
          </span>
        );
      },
    },
    {
      key: 'docFeeMax',
      header: 'Doc Fee',
      render: (row) => formatCurrency(row.docFeeMax),
    },
    { key: 'effectiveDate', header: 'Effective', sortable: true },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50">
            <Percent className="h-5 w-5 text-amber-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Tax Rates</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage state, county, and city tax rates for vehicle sales</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Tax Rate
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={stateFilter}
          onChange={(e) => { setStateFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All States</option>
          {US_STATES.map((s) => (
            <option key={s.value} value={s.value}>{s.label}</option>
          ))}
        </select>
        {stateFilter && (
          <button
            onClick={() => { setStateFilter(''); setPage(0); }}
            className="text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
          >
            Clear filter
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

      {/* Tax Calculator Panel */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center gap-2">
          <Calculator className="h-5 w-5 text-amber-600" />
          <h2 className="text-lg font-semibold text-gray-900">Tax Calculator</h2>
        </div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-6">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Vehicle Price ($)</label>
            <input
              type="number"
              value={calcPrice}
              onChange={(e) => setCalcPrice(Number(e.target.value))}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Trade-In ($)</label>
            <input
              type="number"
              value={calcTradeIn}
              onChange={(e) => setCalcTradeIn(Number(e.target.value))}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">State</label>
            <input
              type="text"
              value={calcState}
              onChange={(e) => setCalcState(e.target.value.toUpperCase())}
              placeholder="IL"
              maxLength={2}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">County Code</label>
            <input
              type="text"
              value={calcCounty}
              onChange={(e) => setCalcCounty(e.target.value.toUpperCase())}
              placeholder="COOK"
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">City Code</label>
            <input
              type="text"
              value={calcCity}
              onChange={(e) => setCalcCity(e.target.value.toUpperCase())}
              placeholder="CHI"
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <div className="flex items-end">
            <button
              onClick={handleCalculate}
              disabled={calcLoading}
              className="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-amber-700 disabled:opacity-50"
            >
              {calcLoading ? (
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
              ) : (
                <Calculator className="h-4 w-4" />
              )}
              Calculate
            </button>
          </div>
        </div>

        {calcResult && (
          <div className="mt-4 rounded-lg border border-amber-100 bg-amber-50 p-4">
            <h3 className="mb-3 text-sm font-semibold text-amber-800">Tax Breakdown</h3>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              <div>
                <p className="text-xs text-amber-600">Taxable Amount</p>
                <p className="text-sm font-semibold text-gray-900">{formatCurrency(calcPrice - calcTradeIn)}</p>
              </div>
              <div>
                <p className="text-xs text-amber-600">State Tax ({formatRate(calcResult.stateRate)})</p>
                <p className="text-sm font-semibold text-gray-900">{formatCurrency((calcPrice - calcTradeIn) * calcResult.stateRate)}</p>
              </div>
              <div>
                <p className="text-xs text-amber-600">County Tax ({formatRate(calcResult.countyRate)})</p>
                <p className="text-sm font-semibold text-gray-900">{formatCurrency((calcPrice - calcTradeIn) * calcResult.countyRate)}</p>
              </div>
              <div>
                <p className="text-xs text-amber-600">City Tax ({formatRate(calcResult.cityRate)})</p>
                <p className="text-sm font-semibold text-gray-900">{formatCurrency((calcPrice - calcTradeIn) * calcResult.cityRate)}</p>
              </div>
            </div>
            <div className="mt-3 flex items-center justify-between border-t border-amber-200 pt-3">
              <div>
                <p className="text-xs text-amber-600">Total Tax ({calcResult.combinedPct || formatRate(calcResult.combinedRate)})</p>
                <p className="text-lg font-bold text-gray-900">
                  {formatCurrency(calcResult.testTaxOn30K > 0 ? calcResult.testTaxOn30K : (calcPrice - calcTradeIn) * calcResult.combinedRate)}
                </p>
              </div>
              <div className="text-right">
                <p className="text-xs text-amber-600">Doc Fee / Title / Registration</p>
                <p className="text-sm font-semibold text-gray-900">
                  {formatCurrency(calcResult.docFeeMax)} / {formatCurrency(calcResult.titleFee)} / {formatCurrency(calcResult.regFee)}
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editing ? 'Edit Tax Rate' : 'New Tax Rate'}
        size="lg"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="State"
              name="stateCode"
              type="select"
              value={form.stateCode}
              onChange={handleChange}
              error={errors.stateCode}
              required
              options={US_STATES}
              disabled={!!editing}
            />
            <FormField
              label="County Code"
              name="countyCode"
              value={form.countyCode}
              onChange={handleChange}
              error={errors.countyCode}
              required
              placeholder="COOK"
              disabled={!!editing}
            />
            <FormField
              label="City Code"
              name="cityCode"
              value={form.cityCode}
              onChange={handleChange}
              error={errors.cityCode}
              required
              placeholder="CHI"
              disabled={!!editing}
            />
          </div>

          <p className="text-xs font-medium uppercase tracking-wide text-gray-500">Tax Rates (enter as percentages, e.g. 6.25 for 6.25%)</p>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="State Rate (%)"
              name="stateRate"
              type="number"
              value={Number((form.stateRate * 100).toFixed(4))}
              onChange={handleChange}
              placeholder="6.250"
            />
            <FormField
              label="County Rate (%)"
              name="countyRate"
              type="number"
              value={Number((form.countyRate * 100).toFixed(4))}
              onChange={handleChange}
              placeholder="1.750"
            />
            <FormField
              label="City Rate (%)"
              name="cityRate"
              type="number"
              value={Number((form.cityRate * 100).toFixed(4))}
              onChange={handleChange}
              placeholder="1.250"
            />
          </div>

          <p className="text-xs font-medium uppercase tracking-wide text-gray-500">Fees</p>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Doc Fee Max ($)"
              name="docFeeMax"
              type="number"
              value={form.docFeeMax}
              onChange={handleChange}
              placeholder="300"
            />
            <FormField
              label="Title Fee ($)"
              name="titleFee"
              type="number"
              value={form.titleFee}
              onChange={handleChange}
              placeholder="150"
            />
            <FormField
              label="Registration Fee ($)"
              name="regFee"
              type="number"
              value={form.regFee}
              onChange={handleChange}
              placeholder="101"
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
              {editing ? 'Update Tax Rate' : 'Create Tax Rate'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default TaxRatesPage;
