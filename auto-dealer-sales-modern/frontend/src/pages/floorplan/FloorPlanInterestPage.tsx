import { useState } from 'react';
import {
  Calculator,
  AlertTriangle,
  CheckCircle,
  XCircle,
  RefreshCw,
  Zap,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import { calculateInterest } from '@/api/floorplan';
import { useAuth } from '@/auth/useAuth';
import type {
  FloorPlanInterestResponse,
  FloorPlanInterestDetail,
} from '@/types/floorplan';

// ── Helpers ──────────────────────────────────────────────────────

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
  value: string | number;
  icon: React.ReactNode;
  iconBg: string;
  valueColor?: string;
}

function KpiCard({ title, value, icon, iconBg, valueColor = 'text-gray-900' }: KpiCardProps) {
  return (
    <div className="rounded-xl border border-gray-100 bg-white p-6 shadow-card transition-shadow hover:shadow-card-hover">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className={`mt-2 text-2xl font-bold ${valueColor}`}>{value}</p>
        </div>
        <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${iconBg}`}>
          {icon}
        </div>
      </div>
    </div>
  );
}

// ── Mode Types ───────────────────────────────────────────────────

type ProcessingMode = 'single' | 'batch';

// ── Main Component ───────────────────────────────────────────────

function FloorPlanInterestPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [mode, setMode] = useState<ProcessingMode>('single');

  // Single mode
  const [singleVin, setSingleVin] = useState('');

  // Batch mode
  const [batchDealerCode, setBatchDealerCode] = useState(user?.dealerCode ?? '');

  // Shared state
  const [processing, setProcessing] = useState(false);
  const [result, setResult] = useState<FloorPlanInterestResponse | null>(null);

  // Detail table pagination (client-side)
  const [detailPage, setDetailPage] = useState(0);
  const pageSize = 20;

  const handleCalculate = async () => {
    if (mode === 'single' && !singleVin.trim()) {
      addToast('warning', 'Please enter a VIN');
      return;
    }
    if (mode === 'batch' && !batchDealerCode.trim()) {
      addToast('warning', 'Please enter a dealer code');
      return;
    }

    setProcessing(true);
    setResult(null);
    setDetailPage(0);

    try {
      const response = await calculateInterest({
        mode: mode === 'single' ? 'SINGLE' : 'BATCH',
        vin: mode === 'single' ? singleVin.trim() : undefined,
        dealerCode: mode === 'batch' ? batchDealerCode.trim() : undefined,
      });
      setResult(response);
      if (response.errorCount > 0) {
        addToast('warning', `Processing complete with ${response.errorCount} error(s)`);
      } else {
        addToast('success', `Interest calculated for ${response.processedCount} vehicle(s)`);
      }
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to calculate interest');
    } finally {
      setProcessing(false);
    }
  };

  // ── Detail Table Columns ─────────────────────────────────────

  const detailColumns: Column<FloorPlanInterestDetail>[] = [
    {
      key: 'vin',
      header: 'VIN',
      render: (row) => (
        <span className="font-mono text-sm font-semibold text-gray-900">{row.vin}</span>
      ),
    },
    {
      key: 'dailyInterest',
      header: 'Daily Interest',
      render: (row) => (
        <span className="text-sm font-medium text-gray-700">{formatCurrencyPrecise(row.dailyInterest)}</span>
      ),
    },
    {
      key: 'newAccrued',
      header: 'New Accrued Total',
      render: (row) => (
        <span className="text-sm font-semibold text-gray-900">{formatCurrencyPrecise(row.newAccrued)}</span>
      ),
    },
    {
      key: 'daysToCurtailment',
      header: 'Days to Curtailment',
      render: (row) => (
        <span className={`text-sm font-semibold ${
          row.daysToCurtailment <= 15 ? 'text-amber-600' :
          row.daysToCurtailment <= 30 ? 'text-yellow-600' : 'text-gray-700'
        }`}>
          {row.daysToCurtailment}
        </span>
      ),
    },
    {
      key: 'warning',
      header: 'Warning',
      render: (row) =>
        row.warning ? (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-semibold text-amber-700">
            <AlertTriangle className="h-3 w-3" />
            Approaching
          </span>
        ) : (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700">
            <CheckCircle className="h-3 w-3" />
            OK
          </span>
        ),
    },
  ];

  // Client-side pagination for detail rows
  const allDetails = result?.details ?? [];
  const paginatedDetails = allDetails.slice(detailPage * pageSize, (detailPage + 1) * pageSize);
  const detailTotalPages = Math.max(1, Math.ceil(allDetails.length / pageSize));

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50">
          <Calculator className="h-5 w-5 text-purple-600" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Interest Calculation</h1>
          <p className="mt-0.5 text-sm text-gray-500">Calculate and accrue floor plan interest</p>
        </div>
      </div>

      {/* Mode Selector */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-card">
        <div className="flex flex-wrap items-end gap-6">
          {/* Mode Tabs */}
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500">Processing Mode</label>
            <div className="flex rounded-lg border border-gray-200 bg-gray-50 p-0.5">
              <button
                onClick={() => { setMode('single'); setResult(null); }}
                className={`rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                  mode === 'single'
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                Single Vehicle
              </button>
              <button
                onClick={() => { setMode('batch'); setResult(null); }}
                className={`rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                  mode === 'batch'
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                Batch Processing
              </button>
            </div>
          </div>

          {/* Input */}
          {mode === 'single' ? (
            <div className="flex-1">
              <label className="mb-1.5 block text-xs font-medium text-gray-500">Vehicle VIN</label>
              <input
                type="text"
                value={singleVin}
                onChange={(e) => setSingleVin(e.target.value.toUpperCase())}
                placeholder="Enter 17-character VIN"
                maxLength={17}
                className="block w-full max-w-md rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 shadow-sm transition-colors focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
            </div>
          ) : (
            <div className="flex-1">
              <label className="mb-1.5 block text-xs font-medium text-gray-500">Dealer Code</label>
              <input
                type="text"
                value={batchDealerCode}
                onChange={(e) => setBatchDealerCode(e.target.value.toUpperCase())}
                placeholder="e.g. DLR001"
                className="block w-full max-w-md rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 shadow-sm transition-colors focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
            </div>
          )}

          {/* Action Button */}
          <button
            onClick={handleCalculate}
            disabled={processing}
            className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            {processing ? (
              <>
                <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Processing...
              </>
            ) : mode === 'single' ? (
              <>
                <Zap className="h-4 w-4" />
                Calculate &amp; Accrue
              </>
            ) : (
              <>
                <RefreshCw className="h-4 w-4" />
                Process All Active
              </>
            )}
          </button>
        </div>

        {/* Progress indicator */}
        {processing && (
          <div className="mt-4">
            <div className="h-1.5 w-full overflow-hidden rounded-full bg-gray-200">
              <div className="h-full animate-pulse rounded-full bg-blue-500" style={{ width: '70%' }} />
            </div>
            <p className="mt-2 text-xs text-gray-500">
              {mode === 'single' ? 'Calculating interest for vehicle...' : 'Processing all active vehicles...'}
            </p>
          </div>
        )}
      </div>

      {/* Single Vehicle Result Card */}
      {result && mode === 'single' && result.details.length > 0 && (
        <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-card">
          <h3 className="mb-4 text-base font-semibold text-gray-900">Calculation Result</h3>
          <div className="space-y-3">
            {(() => {
              const detail = result.details[0];
              return (
                <>
                  <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                    <span className="text-sm text-gray-500">VIN</span>
                    <span className="font-mono text-sm font-semibold text-gray-900">{detail.vin}</span>
                  </div>
                  <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                    <span className="text-sm text-gray-500">Daily Interest</span>
                    <span className="text-sm font-semibold text-gray-900">{formatCurrencyPrecise(detail.dailyInterest)}</span>
                  </div>
                  <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                    <span className="text-sm text-gray-500">New Accrued Total</span>
                    <span className="text-sm font-bold text-gray-900">{formatCurrencyPrecise(detail.newAccrued)}</span>
                  </div>
                  <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
                    <span className="text-sm text-gray-500">Days to Curtailment</span>
                    <span className={`text-sm font-semibold ${
                      detail.daysToCurtailment <= 15 ? 'text-amber-600' : 'text-gray-900'
                    }`}>
                      {detail.daysToCurtailment} days
                    </span>
                  </div>
                  {detail.warning && (
                    <div className="flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
                      <AlertTriangle className="h-4 w-4 flex-shrink-0" />
                      <span className="font-medium">Curtailment approaching! This vehicle is within 15 days of its curtailment date.</span>
                    </div>
                  )}
                </>
              );
            })()}
          </div>
        </div>
      )}

      {/* Batch Results */}
      {result && mode === 'batch' && (
        <>
          {/* Summary KPI Cards */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <KpiCard
              title="Processed"
              value={result.processedCount}
              icon={<RefreshCw className="h-5 w-5 text-blue-600" />}
              iconBg="bg-blue-50"
            />
            <KpiCard
              title="Updated"
              value={result.updatedCount}
              icon={<CheckCircle className="h-5 w-5 text-emerald-600" />}
              iconBg="bg-emerald-50"
              valueColor="text-emerald-700"
            />
            <KpiCard
              title="Curtailment Warnings"
              value={result.curtailmentWarningCount}
              icon={<AlertTriangle className="h-5 w-5 text-amber-600" />}
              iconBg="bg-amber-50"
              valueColor={result.curtailmentWarningCount > 0 ? 'text-amber-700' : 'text-gray-900'}
            />
            <KpiCard
              title="Errors"
              value={result.errorCount}
              icon={<XCircle className="h-5 w-5 text-red-600" />}
              iconBg="bg-red-50"
              valueColor={result.errorCount > 0 ? 'text-red-700' : 'text-gray-900'}
            />
          </div>

          {/* Total Interest Processed */}
          <div className="rounded-xl border border-blue-200 bg-blue-50 px-6 py-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-blue-700">Total Interest Amount Processed</span>
              <span className="text-lg font-bold text-blue-900">{formatCurrencyPrecise(result.totalInterestAmount)}</span>
            </div>
          </div>

          {/* Detail Table */}
          {allDetails.length > 0 && (
            <DataTable
              columns={detailColumns}
              data={paginatedDetails}
              loading={false}
              page={detailPage}
              totalPages={detailTotalPages}
              totalElements={allDetails.length}
              onPageChange={setDetailPage}
              emptyMessage="No detail records."
            />
          )}
        </>
      )}

      {/* Empty state when no result */}
      {!result && !processing && (
        <div className="rounded-xl border border-dashed border-gray-300 bg-gray-50/50 p-12 text-center">
          <Calculator className="mx-auto h-12 w-12 text-gray-300" />
          <h3 className="mt-4 text-sm font-semibold text-gray-600">No Results Yet</h3>
          <p className="mt-1 text-sm text-gray-400">
            {mode === 'single'
              ? 'Enter a VIN and click "Calculate & Accrue" to calculate interest.'
              : 'Enter a dealer code and click "Process All Active" to run batch interest accrual.'}
          </p>
        </div>
      )}
    </div>
  );
}

export default FloorPlanInterestPage;
