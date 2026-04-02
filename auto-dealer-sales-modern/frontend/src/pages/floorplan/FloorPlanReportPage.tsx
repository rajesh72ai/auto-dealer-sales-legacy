import { useState, useRef } from 'react';
import {
  FileBarChart2,
  Printer,
  Car,
  DollarSign,
  CreditCard,
  TrendingUp,
  Clock,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import { generateExposureReport } from '@/api/floorplan';
import { useAuth } from '@/auth/useAuth';
import type {
  FloorPlanExposureResponse,
  FloorPlanLenderBreakdown,
} from '@/types/floorplan';

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

function formatPercent(value: number): string {
  return `${value.toFixed(2)}%`;
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

// ── Age Bucket Card ──────────────────────────────────────────────

interface AgeBucketProps {
  label: string;
  count: number;
  total: number;
  color: string;
  barColor: string;
}

function AgeBucketCard({ label, count, total, color, barColor }: AgeBucketProps) {
  const pct = total > 0 ? (count / total) * 100 : 0;
  return (
    <div className="rounded-xl border border-gray-100 bg-white p-5 shadow-card">
      <div className="flex items-center justify-between">
        <span className={`text-sm font-semibold ${color}`}>{label}</span>
        <span className="text-xs text-gray-400">{pct.toFixed(0)}%</span>
      </div>
      <p className={`mt-2 text-3xl font-bold ${color}`}>{count}</p>
      <p className="mt-0.5 text-xs text-gray-400">vehicles</p>
      <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-gray-100">
        <div
          className={`h-full rounded-full transition-all duration-500 ${barColor}`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

// ── Donut Chart (CSS) ────────────────────────────────────────────

interface DonutProps {
  newPct: number;
}

function DonutChart({ newPct }: DonutProps) {
  const newDeg = (newPct / 100) * 360;
  return (
    <div
      className="mx-auto h-28 w-28 rounded-full"
      style={{
        background: `conic-gradient(
          #3b82f6 0deg ${newDeg}deg,
          #f59e0b ${newDeg}deg 360deg
        )`,
      }}
    >
      <div className="flex h-full w-full items-center justify-center">
        <div className="h-16 w-16 rounded-full bg-white" />
      </div>
    </div>
  );
}

// ── Main Component ───────────────────────────────────────────────

function FloorPlanReportPage() {
  const { addToast } = useToast();
  const { user } = useAuth();
  const reportRef = useRef<HTMLDivElement>(null);

  const [dealerCode, setDealerCode] = useState(user?.dealerCode ?? '');
  const [loading, setLoading] = useState(false);
  const [report, setReport] = useState<FloorPlanExposureResponse | null>(null);

  // Lender table pagination (client-side)
  const [lenderPage, setLenderPage] = useState(0);
  const lenderPageSize = 10;

  const handleGenerate = async () => {
    if (!dealerCode.trim()) {
      addToast('warning', 'Please enter a dealer code');
      return;
    }
    setLoading(true);
    setReport(null);
    try {
      const data = await generateExposureReport(dealerCode.trim());
      setReport(data);
      setLenderPage(0);
      addToast('success', 'Exposure report generated successfully');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to generate report');
    } finally {
      setLoading(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  // ── Lender Table Columns ─────────────────────────────────────

  const lenderColumns: Column<FloorPlanLenderBreakdown>[] = [
    {
      key: 'lenderId',
      header: 'Lender ID',
      sortable: true,
      render: (row) => (
        <span className="font-mono text-sm font-medium text-gray-700">{row.lenderId}</span>
      ),
    },
    {
      key: 'lenderName',
      header: 'Lender Name',
      sortable: true,
      render: (row) => (
        <span className="text-sm font-medium text-gray-900">{row.lenderName}</span>
      ),
    },
    {
      key: 'vehicleCount',
      header: 'Vehicles',
      sortable: true,
      render: (row) => (
        <span className="text-sm font-semibold text-gray-900">{row.vehicleCount}</span>
      ),
    },
    {
      key: 'balance',
      header: 'Balance',
      sortable: true,
      render: (row) => (
        <span className="text-sm font-semibold text-gray-900">{formatCurrency(row.balance)}</span>
      ),
    },
    {
      key: 'interest',
      header: 'Interest',
      sortable: true,
      render: (row) => (
        <span className="text-sm text-gray-700">{formatCurrencyPrecise(row.interest)}</span>
      ),
    },
    {
      key: 'avgRate',
      header: 'Avg Rate',
      sortable: true,
      render: (row) => (
        <span className="text-sm text-gray-700">{formatPercent(row.avgRate)}</span>
      ),
    },
    {
      key: 'avgDays',
      header: 'Avg Days',
      sortable: true,
      render: (row) => (
        <span className={`text-sm font-semibold ${
          row.avgDays > 60 ? 'text-orange-600' :
          row.avgDays > 30 ? 'text-amber-600' : 'text-gray-700'
        }`}>
          {Math.round(row.avgDays)}
        </span>
      ),
    },
  ];

  const allLenders = report?.lenderBreakdown ?? [];
  const paginatedLenders = allLenders.slice(
    lenderPage * lenderPageSize,
    (lenderPage + 1) * lenderPageSize,
  );
  const lenderTotalPages = Math.max(1, Math.ceil(allLenders.length / lenderPageSize));

  // New/Used split percentages
  const totalSplitBalance = report
    ? report.newUsedSplit.newBalance + report.newUsedSplit.usedBalance
    : 0;
  const newBalancePct = totalSplitBalance > 0
    ? (report!.newUsedSplit.newBalance / totalSplitBalance) * 100
    : 50;
  const usedBalancePct = totalSplitBalance > 0
    ? (report!.newUsedSplit.usedBalance / totalSplitBalance) * 100
    : 50;

  // Age bucket total
  const totalAgeBuckets = report
    ? report.ageBuckets.count0to30 + report.ageBuckets.count31to60 + report.ageBuckets.count61to90 + report.ageBuckets.count91plus
    : 0;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
            <FileBarChart2 className="h-5 w-5 text-indigo-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Floor Plan Exposure Report</h1>
            <p className="mt-0.5 text-sm text-gray-500">Comprehensive floor plan analysis by dealer</p>
          </div>
        </div>
        {report && (
          <button
            onClick={handlePrint}
            className="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500/20"
          >
            <Printer className="h-4 w-4" />
            Print Report
          </button>
        )}
      </div>

      {/* Dealer Code Input */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-card">
        <div className="flex items-end gap-4">
          <div className="flex-1 max-w-sm">
            <label className="mb-1.5 block text-xs font-medium text-gray-500">Dealer Code</label>
            <input
              type="text"
              value={dealerCode}
              onChange={(e) => setDealerCode(e.target.value.toUpperCase())}
              onKeyDown={(e) => { if (e.key === 'Enter') handleGenerate(); }}
              placeholder="e.g. DLR001"
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 shadow-sm transition-colors focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
          <button
            onClick={handleGenerate}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            {loading ? (
              <>
                <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Generating...
              </>
            ) : (
              <>
                <FileBarChart2 className="h-4 w-4" />
                Generate Report
              </>
            )}
          </button>
        </div>
      </div>

      {/* Report Content */}
      {report && (
        <div ref={reportRef} className="space-y-6 print:space-y-4">
          {/* Report Title Bar */}
          <div className="rounded-xl bg-gradient-to-r from-brand-600 to-brand-700 p-5 text-white shadow-lg shadow-brand-600/20">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold">Floor Plan Exposure Report</h2>
                <p className="mt-0.5 text-sm text-blue-100">Dealer: {report.dealerCode}</p>
              </div>
              <div className="rounded-lg bg-white/10 px-4 py-2 text-sm font-medium text-white backdrop-blur-sm">
                {new Date().toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </div>
            </div>
          </div>

          {/* Grand Totals KPI Cards */}
          <div>
            <h3 className="mb-3 text-base font-semibold text-gray-900">Grand Totals</h3>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
              <KpiCard
                title="Total Vehicles"
                value={report.grandTotals.totalVehicles.toLocaleString()}
                icon={<Car className="h-5 w-5 text-blue-600" />}
                iconBg="bg-blue-50"
              />
              <KpiCard
                title="Total Balance"
                value={formatCurrency(report.grandTotals.totalBalance)}
                icon={<DollarSign className="h-5 w-5 text-emerald-600" />}
                iconBg="bg-emerald-50"
              />
              <KpiCard
                title="Total Interest"
                value={formatCurrencyPrecise(report.grandTotals.totalInterest)}
                icon={<CreditCard className="h-5 w-5 text-purple-600" />}
                iconBg="bg-purple-50"
              />
              <KpiCard
                title="Weighted Avg Rate"
                value={formatPercent(report.grandTotals.weightedAvgRate)}
                icon={<TrendingUp className="h-5 w-5 text-teal-600" />}
                iconBg="bg-teal-50"
              />
              <KpiCard
                title="Avg Days on Floor"
                value={`${Math.round(report.grandTotals.avgDaysOnFloor)} days`}
                icon={<Clock className="h-5 w-5 text-amber-600" />}
                iconBg="bg-amber-50"
              />
            </div>
          </div>

          {/* Lender Breakdown */}
          <div>
            <h3 className="mb-3 text-base font-semibold text-gray-900">Lender Breakdown</h3>
            <DataTable
              columns={lenderColumns}
              data={paginatedLenders}
              loading={false}
              page={lenderPage}
              totalPages={lenderTotalPages}
              totalElements={allLenders.length}
              onPageChange={setLenderPage}
              emptyMessage="No lender data available."
            />
          </div>

          {/* New/Used Split */}
          <div>
            <h3 className="mb-3 text-base font-semibold text-gray-900">New vs. Used Split</h3>
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
              {/* New Vehicles Card */}
              <div className="rounded-xl border border-blue-200 bg-white p-6 shadow-card">
                <div className="flex items-center gap-2">
                  <div className="h-3 w-3 rounded-full bg-blue-500" />
                  <h4 className="text-sm font-semibold text-gray-700">New Vehicles</h4>
                </div>
                <p className="mt-3 text-3xl font-bold text-blue-700">{report.newUsedSplit.newCount}</p>
                <p className="mt-1 text-sm text-gray-500">
                  {formatCurrency(report.newUsedSplit.newBalance)}
                  <span className="ml-2 text-xs text-blue-500 font-medium">
                    ({newBalancePct.toFixed(1)}% of total)
                  </span>
                </p>
              </div>

              {/* Donut Visual */}
              <div className="flex flex-col items-center justify-center rounded-xl border border-gray-100 bg-white p-6 shadow-card">
                <DonutChart newPct={newBalancePct} />
                <div className="mt-4 flex items-center gap-6 text-xs">
                  <div className="flex items-center gap-1.5">
                    <div className="h-2.5 w-2.5 rounded-full bg-blue-500" />
                    <span className="text-gray-600">New ({newBalancePct.toFixed(1)}%)</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <div className="h-2.5 w-2.5 rounded-full bg-amber-500" />
                    <span className="text-gray-600">Used ({usedBalancePct.toFixed(1)}%)</span>
                  </div>
                </div>
              </div>

              {/* Used Vehicles Card */}
              <div className="rounded-xl border border-amber-200 bg-white p-6 shadow-card">
                <div className="flex items-center gap-2">
                  <div className="h-3 w-3 rounded-full bg-amber-500" />
                  <h4 className="text-sm font-semibold text-gray-700">Used Vehicles</h4>
                </div>
                <p className="mt-3 text-3xl font-bold text-amber-700">{report.newUsedSplit.usedCount}</p>
                <p className="mt-1 text-sm text-gray-500">
                  {formatCurrency(report.newUsedSplit.usedBalance)}
                  <span className="ml-2 text-xs text-amber-500 font-medium">
                    ({usedBalancePct.toFixed(1)}% of total)
                  </span>
                </p>
              </div>
            </div>
          </div>

          {/* Age Buckets */}
          <div>
            <h3 className="mb-3 text-base font-semibold text-gray-900">Inventory Age Distribution</h3>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <AgeBucketCard
                label="0 - 30 days"
                count={report.ageBuckets.count0to30}
                total={totalAgeBuckets}
                color="text-emerald-700"
                barColor="bg-emerald-500"
              />
              <AgeBucketCard
                label="31 - 60 days"
                count={report.ageBuckets.count31to60}
                total={totalAgeBuckets}
                color="text-yellow-700"
                barColor="bg-yellow-500"
              />
              <AgeBucketCard
                label="61 - 90 days"
                count={report.ageBuckets.count61to90}
                total={totalAgeBuckets}
                color="text-orange-700"
                barColor="bg-orange-500"
              />
              <AgeBucketCard
                label="91+ days"
                count={report.ageBuckets.count91plus}
                total={totalAgeBuckets}
                color="text-red-700"
                barColor="bg-red-500"
              />
            </div>
          </div>
        </div>
      )}

      {/* Empty state */}
      {!report && !loading && (
        <div className="rounded-xl border border-dashed border-gray-300 bg-gray-50/50 p-12 text-center">
          <FileBarChart2 className="mx-auto h-12 w-12 text-gray-300" />
          <h3 className="mt-4 text-sm font-semibold text-gray-600">No Report Generated</h3>
          <p className="mt-1 text-sm text-gray-400">
            Enter a dealer code and click "Generate Report" to view the floor plan exposure analysis.
          </p>
        </div>
      )}
    </div>
  );
}

export default FloorPlanReportPage;
