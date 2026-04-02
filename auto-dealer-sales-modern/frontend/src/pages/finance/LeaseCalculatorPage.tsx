import { useState } from 'react';
import { Calculator, CarFront, DollarSign, Percent } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { calculateLease } from '@/api/finance';
import type { LeaseCalculatorResponse } from '@/types/finance';

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

function formatCurrencyWhole(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function LeaseCalculatorPage() {
  const { addToast } = useToast();

  const [capitalizedCost, setCapitalizedCost] = useState(38000);
  const [capCostReduction, setCapCostReduction] = useState(3000);
  const [residualPct, setResidualPct] = useState(55);
  const [moneyFactor, setMoneyFactor] = useState(0.00125);
  const [termMonths, setTermMonths] = useState(36);
  const [taxRate, setTaxRate] = useState(7.0);
  const [acqFee, setAcqFee] = useState(695);
  const [securityDeposit, setSecurityDeposit] = useState(0);
  const [dealNumber, setDealNumber] = useState('');

  const [calculating, setCalculating] = useState(false);
  const [result, setResult] = useState<LeaseCalculatorResponse | null>(null);

  const handleCalculate = async () => {
    if (capitalizedCost <= 0) {
      addToast('warning', 'Please enter a valid capitalized cost');
      return;
    }
    setCalculating(true);
    try {
      const resp = await calculateLease({
        dealNumber: dealNumber.trim() || undefined,
        capitalizedCost,
        capCostReduction,
        residualPct,
        moneyFactor,
        termMonths,
        taxRate,
        acqFee,
        securityDeposit,
      });
      setResult(resp);
      if (dealNumber.trim()) {
        addToast('success', `Lease terms saved to deal ${dealNumber.trim()}`);
      }
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Calculation failed');
    } finally {
      setCalculating(false);
    }
  };

  // Payment breakdown percentages for visual bar
  const total = result ? result.totalMonthlyPayment : 0;
  const depPct = result && total > 0 ? (result.monthlyDepreciation / total) * 100 : 0;
  const finPct = result && total > 0 ? (result.monthlyFinanceCharge / total) * 100 : 0;
  const taxPctBar = result && total > 0 ? (result.monthlyTax / total) * 100 : 0;

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50">
          <CarFront className="h-5 w-5 text-purple-600" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Lease Payment Calculator</h1>
          <p className="mt-0.5 text-sm text-gray-500">Calculate lease payments with full depreciation and finance breakdown</p>
        </div>
      </div>

      {/* Input Card */}
      <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="border-b border-gray-100 bg-gradient-to-r from-purple-50 to-indigo-50 px-6 py-4">
          <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900">
            <Calculator className="h-5 w-5 text-purple-600" />
            Lease Parameters
          </h2>
        </div>
        <div className="p-6 space-y-6">
          {/* Deal Number (optional) */}
          <div className="max-w-sm">
            <label className="mb-1.5 block text-sm font-medium text-gray-700">
              Deal Number <span className="text-xs text-gray-400">(optional - saves lease terms to deal)</span>
            </label>
            <input
              type="text"
              value={dealNumber}
              onChange={(e) => setDealNumber(e.target.value)}
              placeholder="e.g. DL-10042"
              className="block w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
            {/* Capitalized Cost */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Capitalized Cost (MSRP)</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">$</span>
                <input
                  type="number"
                  value={capitalizedCost || ''}
                  onChange={(e) => setCapitalizedCost(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 py-2.5 pl-8 pr-3 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
              </div>
            </div>

            {/* Cap Cost Reduction */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Cap Cost Reduction</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">$</span>
                <input
                  type="number"
                  value={capCostReduction || ''}
                  onChange={(e) => setCapCostReduction(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 py-2.5 pl-8 pr-3 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
              </div>
            </div>

            {/* Residual % */}
            <div>
              <label className="mb-1.5 flex items-center justify-between text-sm font-medium text-gray-700">
                <span>Residual Value</span>
                <span className="text-purple-600 font-semibold">{residualPct}%</span>
              </label>
              <input
                type="range"
                min={30}
                max={75}
                step={1}
                value={residualPct}
                onChange={(e) => setResidualPct(Number(e.target.value))}
                className="mt-1 w-full accent-purple-600"
              />
              <div className="mt-1 flex justify-between text-xs text-gray-400">
                <span>30%</span>
                <span>{formatCurrencyWhole(capitalizedCost * residualPct / 100)}</span>
                <span>75%</span>
              </div>
            </div>

            {/* Money Factor */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Money Factor</label>
              <input
                type="number"
                step={0.0001}
                value={moneyFactor}
                onChange={(e) => setMoneyFactor(Number(e.target.value))}
                className="block w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
              <p className="mt-1 text-xs text-gray-400">
                Equiv. APR: {(moneyFactor * 2400).toFixed(2)}%
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
            {/* Term */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Lease Term</label>
              <select
                value={termMonths}
                onChange={(e) => setTermMonths(Number(e.target.value))}
                className="block w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              >
                <option value={24}>24 months</option>
                <option value={36}>36 months</option>
                <option value={39}>39 months</option>
                <option value={42}>42 months</option>
                <option value={48}>48 months</option>
              </select>
            </div>

            {/* Tax Rate */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Tax Rate</label>
              <div className="relative">
                <input
                  type="number"
                  step={0.1}
                  value={taxRate}
                  onChange={(e) => setTaxRate(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 px-3 py-2.5 pr-8 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">%</span>
              </div>
            </div>

            {/* Acquisition Fee */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Acquisition Fee</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">$</span>
                <input
                  type="number"
                  value={acqFee || ''}
                  onChange={(e) => setAcqFee(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 py-2.5 pl-8 pr-3 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
              </div>
            </div>

            {/* Security Deposit */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Security Deposit</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">$</span>
                <input
                  type="number"
                  value={securityDeposit || ''}
                  onChange={(e) => setSecurityDeposit(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 py-2.5 pl-8 pr-3 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
              </div>
            </div>
          </div>

          <div className="flex justify-end border-t border-gray-100 pt-4">
            <button
              onClick={handleCalculate}
              disabled={calculating}
              className="inline-flex items-center gap-2 rounded-lg bg-purple-600 px-6 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-purple-700 disabled:opacity-50"
            >
              <Calculator className="h-4 w-4" />
              {calculating ? 'Calculating...' : 'Calculate Lease'}
            </button>
          </div>
        </div>
      </div>

      {result && (
        <>
          {/* Monthly Payment Hero */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
            <div className="bg-gradient-to-r from-purple-600 to-indigo-600 px-6 py-8 text-white text-center">
              <p className="text-sm font-medium text-purple-200">Total Monthly Lease Payment</p>
              <p className="mt-2 text-4xl font-bold">{formatCurrency(result.totalMonthlyPayment)}</p>
              <p className="mt-2 text-sm text-purple-200">
                {termMonths} months &middot; Equiv. APR {result.equivalentApr?.toFixed(2) ?? (moneyFactor * 2400).toFixed(2)}%
              </p>
            </div>

            {/* Payment Breakdown Bar */}
            <div className="px-6 py-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Payment Breakdown</p>
              <div className="flex h-8 overflow-hidden rounded-full">
                <div className="bg-blue-500 transition-all" style={{ width: `${depPct}%` }} />
                <div className="bg-purple-500 transition-all" style={{ width: `${finPct}%` }} />
                <div className="bg-amber-500 transition-all" style={{ width: `${taxPctBar}%` }} />
              </div>
              <div className="mt-3 flex flex-wrap gap-6">
                <div className="flex items-center gap-2">
                  <div className="h-3 w-3 rounded-full bg-blue-500" />
                  <div>
                    <p className="text-xs text-gray-500">Depreciation</p>
                    <p className="text-sm font-semibold text-gray-900">{formatCurrency(result.monthlyDepreciation)}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-3 w-3 rounded-full bg-purple-500" />
                  <div>
                    <p className="text-xs text-gray-500">Finance Charge</p>
                    <p className="text-sm font-semibold text-gray-900">{formatCurrency(result.monthlyFinanceCharge)}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-3 w-3 rounded-full bg-amber-500" />
                  <div>
                    <p className="text-xs text-gray-500">Tax</p>
                    <p className="text-sm font-semibold text-gray-900">{formatCurrency(result.monthlyTax)}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Details Grid */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DetailCard
              icon={<DollarSign className="h-4 w-4 text-blue-600" />}
              iconBg="bg-blue-50"
              label="Adjusted Cap Cost"
              value={formatCurrency(result.adjustedCapCost)}
            />
            <DetailCard
              icon={<Percent className="h-4 w-4 text-purple-600" />}
              iconBg="bg-purple-50"
              label="Residual Amount"
              value={formatCurrency(result.residualAmount)}
              sub={`${result.residualPct}% of cap cost`}
            />
            <DetailCard
              icon={<CarFront className="h-4 w-4 text-emerald-600" />}
              iconBg="bg-emerald-50"
              label="Drive-Off Amount"
              value={formatCurrency(result.driveOffAmount)}
              sub="Due at signing"
            />
            <DetailCard
              icon={<DollarSign className="h-4 w-4 text-amber-600" />}
              iconBg="bg-amber-50"
              label="Equivalent APR"
              value={`${result.equivalentApr?.toFixed(2) ?? (moneyFactor * 2400).toFixed(2)}%`}
            />
          </div>

          {/* Totals Summary */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="border-b border-gray-100 px-6 py-4">
              <h3 className="text-base font-semibold text-gray-900">Lease Summary</h3>
            </div>
            <div className="divide-y divide-gray-100">
              <SummaryRow label="Capitalized Cost" value={formatCurrency(result.capitalizedCost)} />
              <SummaryRow label="Cap Cost Reduction" value={`- ${formatCurrency(result.capCostReduction)}`} />
              <SummaryRow label="Acquisition Fee" value={`+ ${formatCurrency(result.acqFee)}`} />
              <SummaryRow label="Adjusted Cap Cost" value={formatCurrency(result.adjustedCapCost)} bold />
              <SummaryRow label="Residual Amount" value={formatCurrency(result.residualAmount)} />
              <SummaryRow label="Security Deposit" value={formatCurrency(result.securityDeposit)} />
              <SummaryRow label="Total of Payments" value={formatCurrency(result.totalOfPayments)} bold />
              <SummaryRow label="Total Interest Equivalent" value={formatCurrency(result.totalInterestEquivalent)} accent />
            </div>
          </div>
        </>
      )}

      {/* Empty state */}
      {!result && !calculating && (
        <div className="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50/50 py-16 text-center">
          <CarFront className="mx-auto h-12 w-12 text-gray-300" />
          <p className="mt-4 text-sm font-medium text-gray-500">
            Enter lease parameters above and click <span className="text-purple-600">Calculate Lease</span> to see the full breakdown
          </p>
        </div>
      )}
    </div>
  );
}

function DetailCard({ icon, iconBg, label, value, sub }: { icon: React.ReactNode; iconBg: string; label: string; value: string; sub?: string }) {
  return (
    <div className="flex items-start gap-4 rounded-xl border border-gray-100 bg-white p-5 shadow-card transition-shadow hover:shadow-card-hover">
      <div className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl ${iconBg}`}>
        {icon}
      </div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="mt-0.5 text-lg font-bold text-gray-900">{value}</p>
        {sub && <p className="text-xs text-gray-400">{sub}</p>}
      </div>
    </div>
  );
}

function SummaryRow({ label, value, bold, accent }: { label: string; value: string; bold?: boolean; accent?: boolean }) {
  return (
    <div className="flex items-center justify-between px-6 py-3">
      <span className={`text-sm ${bold ? 'font-semibold text-gray-900' : 'text-gray-600'}`}>{label}</span>
      <span className={`text-sm ${bold ? 'font-bold text-gray-900' : accent ? 'font-semibold text-red-600' : 'font-medium text-gray-700'}`}>{value}</span>
    </div>
  );
}

export default LeaseCalculatorPage;
