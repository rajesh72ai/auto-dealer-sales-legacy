import { useState, useEffect, useCallback } from 'react';
import {
  Plus,
  Warehouse,
  Car,
  DollarSign,
  Clock,
  AlertTriangle,
  CreditCard,
  BanknoteIcon,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import StatusBadge from '@/components/shared/StatusBadge';
import {
  listFloorPlanVehicles,
  addVehicleToFloorPlan,
  payoffFloorPlan,
  listLenders,
} from '@/api/floorplan';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type {
  FloorPlanVehicle,
  FloorPlanAddRequest,
  FloorPlanPayoffResponse,
  FloorPlanLender,
} from '@/types/floorplan';
import type { Dealer } from '@/types/admin';

// ── Helpers ──────────────────────────────────────────────────────

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatCurrencyPrecise(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

// ── KPI Card ─────────────────────────────────────────────────────

interface KpiCardProps {
  title: string;
  value: string;
  icon: React.ReactNode;
  iconBg: string;
  subtitle?: string;
}

function KpiCard({ title, value, icon, iconBg, subtitle }: KpiCardProps) {
  return (
    <div className="rounded-xl border border-gray-100 bg-white p-6 shadow-card transition-shadow hover:shadow-card-hover">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className="mt-2 text-2xl font-bold text-gray-900">{value}</p>
          {subtitle && (
            <p className="mt-1 text-xs text-gray-400">{subtitle}</p>
          )}
        </div>
        <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${iconBg}`}>
          {icon}
        </div>
      </div>
    </div>
  );
}

// ── Status Filter Tabs ───────────────────────────────────────────

type StatusTab = 'ALL' | 'AC' | 'PD';

const STATUS_TABS: { key: StatusTab; label: string }[] = [
  { key: 'ALL', label: 'All Vehicles' },
  { key: 'AC', label: 'Active' },
  { key: 'PD', label: 'Paid Off' },
];

// ── Default Add Form ─────────────────────────────────────────────

const defaultAddForm: FloorPlanAddRequest = {
  vin: '',
  lenderId: '',
  dealerCode: '',
  invoiceAmount: undefined,
  floorDate: new Date().toISOString().split('T')[0],
};

// ── Main Component ───────────────────────────────────────────────

function FloorPlanPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  // Data
  const [items, setItems] = useState<FloorPlanVehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Filters
  const [dealerCode, setDealerCode] = useState(user?.dealerCode ?? '');
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [statusTab, setStatusTab] = useState<StatusTab>('AC');
  const [lenderFilter, setLenderFilter] = useState('');

  // Lenders for dropdowns
  const [lenders, setLenders] = useState<FloorPlanLender[]>([]);

  // Add Vehicle Modal
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [addForm, setAddForm] = useState<FloorPlanAddRequest>({ ...defaultAddForm, dealerCode: user?.dealerCode ?? '' });
  const [addErrors, setAddErrors] = useState<Record<string, string>>({});

  // Payoff Modal
  const [isPayoffModalOpen, setIsPayoffModalOpen] = useState(false);
  const [payoffTarget, setPayoffTarget] = useState<FloorPlanVehicle | null>(null);
  const [payoffProcessing, setPayoffProcessing] = useState(false);

  // KPI aggregates
  const [kpis, setKpis] = useState({ totalVehicles: 0, totalBalance: 0, totalInterest: 0, avgDays: 0 });

  // Load dealers & lenders
  useEffect(() => {
    getDealers({ size: 100, active: 'Y' })
      .then((res) => setDealers(res.content))
      .catch(() => {});
    listLenders()
      .then(setLenders)
      .catch(() => {});
  }, []);

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      const result = await listFloorPlanVehicles({
        dealerCode,
        status: statusTab === 'ALL' ? undefined : statusTab,
        lenderId: lenderFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);

      // Compute KPIs from current page (backend could provide aggregates)
      const vehicles = result.content;
      const totalBal = vehicles.reduce((s, v) => s + v.currentBalance, 0);
      const totalInt = vehicles.reduce((s, v) => s + v.interestAccrued, 0);
      const avgDays = vehicles.length
        ? Math.round(vehicles.reduce((s, v) => s + v.daysOnFloor, 0) / vehicles.length)
        : 0;
      setKpis({
        totalVehicles: result.totalElements,
        totalBalance: totalBal,
        totalInterest: totalInt,
        avgDays,
      });
    } catch {
      addToast('error', 'Failed to load floor plan vehicles');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusTab, lenderFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // ── Add Vehicle Handlers ─────────────────────────────────────

  const validateAdd = (): boolean => {
    const errs: Record<string, string> = {};
    if (!addForm.vin.trim()) errs.vin = 'VIN is required';
    else if (addForm.vin.trim().length !== 17) errs.vin = 'VIN must be 17 characters';
    if (!addForm.lenderId) errs.lenderId = 'Lender is required';
    if (!addForm.dealerCode) errs.dealerCode = 'Dealer code is required';
    setAddErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleAddChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setAddForm((prev) => ({
      ...prev,
      [name]: name === 'invoiceAmount' ? (value ? Number(value) : undefined) : value,
    }));
    if (addErrors[name]) setAddErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openAddModal = () => {
    setAddForm({ ...defaultAddForm, dealerCode: dealerCode || user?.dealerCode || '' });
    setAddErrors({});
    setIsAddModalOpen(true);
  };

  const handleAddSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateAdd()) return;
    try {
      await addVehicleToFloorPlan(addForm);
      addToast('success', 'Vehicle added to floor plan');
      setIsAddModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to add vehicle');
    }
  };

  // ── Payoff Handlers ──────────────────────────────────────────

  const openPayoff = (vehicle: FloorPlanVehicle) => {
    setPayoffTarget(vehicle);
    setIsPayoffModalOpen(true);
  };

  const handlePayoff = async () => {
    if (!payoffTarget) return;
    setPayoffProcessing(true);
    try {
      const result: FloorPlanPayoffResponse = await payoffFloorPlan({ vin: payoffTarget.vin });
      addToast('success', `Payoff completed for VIN ${result.vin} — Total: ${formatCurrencyPrecise(result.totalPayoff)}`);
      setIsPayoffModalOpen(false);
      setPayoffTarget(null);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Payoff failed');
    } finally {
      setPayoffProcessing(false);
    }
  };

  // ── Column Definitions ───────────────────────────────────────

  const columns: Column<FloorPlanVehicle>[] = [
    {
      key: 'vin',
      header: 'VIN',
      sortable: true,
      render: (row) => (
        <span className="font-mono text-sm font-semibold text-gray-900">{row.vin}</span>
      ),
    },
    {
      key: 'vehicleDescription',
      header: 'Vehicle',
      render: (row) => (
        <span className="text-sm text-gray-800">{row.vehicleDescription || '\u2014'}</span>
      ),
    },
    {
      key: 'lenderName',
      header: 'Lender',
      sortable: true,
      render: (row) => (
        <div>
          <span className="text-sm font-medium text-gray-900">{row.lenderName}</span>
          <p className="text-xs text-gray-400">{row.lenderId}</p>
        </div>
      ),
    },
    {
      key: 'floorDate',
      header: 'Floor Date',
      sortable: true,
      render: (row) => (
        <span className="text-sm text-gray-600">
          {row.floorDate ? new Date(row.floorDate).toLocaleDateString() : '\u2014'}
        </span>
      ),
    },
    {
      key: 'daysOnFloor',
      header: 'Days',
      sortable: true,
      render: (row) => (
        <span className={`text-sm font-semibold ${
          row.daysOnFloor > 90 ? 'text-red-600' :
          row.daysOnFloor > 60 ? 'text-orange-600' :
          row.daysOnFloor > 30 ? 'text-amber-600' : 'text-gray-700'
        }`}>
          {row.daysOnFloor}
        </span>
      ),
    },
    {
      key: 'currentBalance',
      header: 'Balance',
      sortable: true,
      render: (row) => (
        <span className="text-sm font-semibold text-gray-900">
          {formatCurrency(row.currentBalance)}
        </span>
      ),
    },
    {
      key: 'interestAccrued',
      header: 'Interest',
      sortable: true,
      render: (row) => (
        <span className="text-sm text-gray-700">
          {formatCurrencyPrecise(row.interestAccrued)}
        </span>
      ),
    },
    {
      key: 'curtailmentDate',
      header: 'Curtailment',
      render: (row) => {
        const isWarning = row.fpStatus === 'AC' && row.daysToCurtailment <= 15;
        return (
          <div className="flex items-center gap-1.5">
            <span className={`text-sm ${isWarning ? 'font-semibold text-amber-600' : 'text-gray-600'}`}>
              {row.curtailmentDate ? new Date(row.curtailmentDate).toLocaleDateString() : '\u2014'}
            </span>
            {isWarning && (
              <AlertTriangle className="h-3.5 w-3.5 text-amber-500" />
            )}
          </div>
        );
      },
    },
    {
      key: 'fpStatus',
      header: 'Status',
      render: (row) => (
        <StatusBadge
          status={row.fpStatus === 'AC' ? 'active' : 'expired'}
          label={row.fpStatus === 'AC' ? 'Active' : 'Paid Off'}
        />
      ),
    },
    {
      key: 'actions',
      header: '',
      render: (row) =>
        row.fpStatus === 'AC' ? (
          <button
            onClick={(e) => { e.stopPropagation(); openPayoff(row); }}
            className="inline-flex items-center gap-1.5 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-1.5 text-xs font-medium text-emerald-700 transition-colors hover:bg-emerald-100"
          >
            <BanknoteIcon className="h-3.5 w-3.5" />
            Payoff
          </button>
        ) : null,
    },
  ];

  // ── Render ───────────────────────────────────────────────────

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
            <Warehouse className="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Floor Plan</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage floor plan inventory and payoffs</p>
          </div>
        </div>
        <button
          onClick={openAddModal}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Vehicle
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

        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-500">Lender</label>
          <select
            value={lenderFilter}
            onChange={(e) => { setLenderFilter(e.target.value); setPage(0); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          >
            <option value="">All Lenders</option>
            {lenders.map((l) => (
              <option key={l.lenderId} value={l.lenderId}>{l.lenderName}</option>
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

        {(lenderFilter) && (
          <button
            onClick={() => { setLenderFilter(''); setPage(0); }}
            className="pb-2 text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
          >
            Clear filters
          </button>
        )}
      </div>

      {!dealerCode && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Please select a dealer to view floor plan vehicles.
        </div>
      )}

      {/* KPI Cards */}
      {dealerCode && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <KpiCard
            title="Total Vehicles"
            value={kpis.totalVehicles.toLocaleString()}
            icon={<Car className="h-5 w-5 text-blue-600" />}
            iconBg="bg-blue-50"
          />
          <KpiCard
            title="Total Balance"
            value={formatCurrency(kpis.totalBalance)}
            icon={<DollarSign className="h-5 w-5 text-emerald-600" />}
            iconBg="bg-emerald-50"
          />
          <KpiCard
            title="Total Interest Accrued"
            value={formatCurrencyPrecise(kpis.totalInterest)}
            icon={<CreditCard className="h-5 w-5 text-purple-600" />}
            iconBg="bg-purple-50"
          />
          <KpiCard
            title="Avg Days on Floor"
            value={`${kpis.avgDays} days`}
            icon={<Clock className="h-5 w-5 text-amber-600" />}
            iconBg="bg-amber-50"
          />
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
          emptyMessage="No floor plan vehicles found."
        />
      )}

      {/* Add Vehicle Modal */}
      <Modal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        title="Add Vehicle to Floor Plan"
        size="lg"
      >
        <form onSubmit={handleAddSubmit} className="space-y-4">
          <FormField
            label="VIN"
            name="vin"
            value={addForm.vin}
            onChange={handleAddChange}
            error={addErrors.vin}
            required
            placeholder="17-character VIN"
          />
          <FormField
            label="Lender"
            name="lenderId"
            type="select"
            value={addForm.lenderId}
            onChange={handleAddChange}
            error={addErrors.lenderId}
            required
            options={lenders.map((l) => ({ value: l.lenderId, label: l.lenderName }))}
          />
          <FormField
            label="Dealer Code"
            name="dealerCode"
            value={addForm.dealerCode}
            onChange={handleAddChange}
            error={addErrors.dealerCode}
            required
            disabled
          />
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Invoice Amount"
              name="invoiceAmount"
              type="number"
              value={addForm.invoiceAmount ?? ''}
              onChange={handleAddChange}
              placeholder="e.g. 35000"
            />
            <FormField
              label="Floor Date"
              name="floorDate"
              type="date"
              value={addForm.floorDate ?? ''}
              onChange={handleAddChange}
            />
          </div>

          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsAddModalOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
            >
              Add to Floor Plan
            </button>
          </div>
        </form>
      </Modal>

      {/* Payoff Confirmation Modal */}
      <Modal
        isOpen={isPayoffModalOpen}
        onClose={() => { setIsPayoffModalOpen(false); setPayoffTarget(null); }}
        title="Confirm Floor Plan Payoff"
        size="md"
      >
        {payoffTarget && (
          <div className="space-y-5">
            <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              <div className="flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 flex-shrink-0" />
                <span>This action will pay off the vehicle and cannot be undone.</span>
              </div>
            </div>

            <div className="space-y-3">
              <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                <span className="text-sm text-gray-500">VIN</span>
                <span className="font-mono text-sm font-semibold text-gray-900">{payoffTarget.vin}</span>
              </div>
              <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                <span className="text-sm text-gray-500">Vehicle</span>
                <span className="text-sm font-medium text-gray-900">{payoffTarget.vehicleDescription}</span>
              </div>
              <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                <span className="text-sm text-gray-500">Current Balance</span>
                <span className="text-sm font-semibold text-gray-900">{formatCurrencyPrecise(payoffTarget.currentBalance)}</span>
              </div>
              <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                <span className="text-sm text-gray-500">Estimated Final Interest</span>
                <span className="text-sm font-semibold text-gray-900">{formatCurrencyPrecise(payoffTarget.interestAccrued)}</span>
              </div>
              <div className="flex items-center justify-between rounded-lg border-2 border-blue-200 bg-blue-50 px-4 py-3">
                <span className="text-sm font-medium text-blue-700">Estimated Total Payoff</span>
                <span className="text-lg font-bold text-blue-900">
                  {formatCurrencyPrecise(payoffTarget.currentBalance + payoffTarget.interestAccrued)}
                </span>
              </div>
            </div>

            <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
              <button
                type="button"
                onClick={() => { setIsPayoffModalOpen(false); setPayoffTarget(null); }}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handlePayoff}
                disabled={payoffProcessing}
                className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {payoffProcessing ? (
                  <>
                    <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                    Processing...
                  </>
                ) : (
                  'Confirm Payoff'
                )}
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

export default FloorPlanPage;
