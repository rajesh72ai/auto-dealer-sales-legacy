import { useState } from 'react';
import { Calculator, DollarSign, TrendingDown, Clock } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { calculateLoan } from '@/api/finance';
import type { LoanCalculatorResponse, TermComparison, AmortizationEntry } from '@/types/finance';

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

const TERM_OPTIONS = [
  { value: 36, label: '36 months' },
  { value: 48, label: '48 months' },
  { value: 60, label: '60 months' },
  { value: 72, label: '72 months' },
  { value: 84, label: '84 months' },
];

function LoanCalculatorPage() {
  const { addToast } = useToast();

  const [principal, setPrincipal] = useState(35000);
  const [downPayment, setDownPayment] = useState(5000);
  const [apr, setApr] = useState(5.99);
  const [termMonths, setTermMonths] = useState(60);
  const [calculating, setCalculating] = useState(false);
  const [result, setResult] = useState<LoanCalculatorResponse | null>(null);

  const handleCalculate = async () => {
    if (principal <= 0) {
      addToast('warning', 'Please enter a valid principal amount');
      return;
    }
    setCalculating(true);
    try {
      const resp = await calculateLoan({
        principal,
        apr,
        termMonths,
        downPayment,
      });
      setResult(resp);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Calculation failed');
    } finally {
      setCalculating(false);
    }
  };

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
          <Calculator className="h-5 w-5 text-emerald-600" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Loan Payment Calculator</h1>
          <p className="mt-0.5 text-sm text-gray-500">Estimate monthly payments, compare terms, and view amortization</p>
        </div>
      </div>

      {/* Input Card */}
      <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="border-b border-gray-100 bg-gradient-to-r from-emerald-50 to-blue-50 px-6 py-4">
          <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900">
            <DollarSign className="h-5 w-5 text-emerald-600" />
            Loan Parameters
          </h2>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
            {/* Principal */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Vehicle Price</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">$</span>
                <input
                  type="number"
                  value={principal || ''}
                  onChange={(e) => setPrincipal(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 py-2.5 pl-8 pr-3 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                  placeholder="35,000"
                />
              </div>
            </div>

            {/* Down Payment */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Down Payment</label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">$</span>
                <input
                  type="number"
                  value={downPayment || ''}
                  onChange={(e) => setDownPayment(Number(e.target.value))}
                  className="block w-full rounded-lg border border-gray-300 py-2.5 pl-8 pr-3 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                  placeholder="5,000"
                />
              </div>
            </div>

            {/* APR with slider */}
            <div>
              <label className="mb-1.5 flex items-center justify-between text-sm font-medium text-gray-700">
                <span>APR</span>
                <span className="text-emerald-600 font-semibold">{apr.toFixed(2)}%</span>
              </label>
              <input
                type="range"
                min={0}
                max={24}
                step={0.25}
                value={apr}
                onChange={(e) => setApr(Number(e.target.value))}
                className="mt-1 w-full accent-emerald-600"
              />
              <div className="mt-1 flex justify-between text-xs text-gray-400">
                <span>0%</span>
                <span>12%</span>
                <span>24%</span>
              </div>
            </div>

            {/* Term */}
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Loan Term</label>
              <select
                value={termMonths}
                onChange={(e) => setTermMonths(Number(e.target.value))}
                className="block w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm font-medium text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              >
                {TERM_OPTIONS.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="mt-6 flex items-center justify-between border-t border-gray-100 pt-4">
            <p className="text-sm text-gray-500">
              Net amount financed: <span className="font-semibold text-gray-900">{formatCurrencyWhole(Math.max(0, principal - downPayment))}</span>
            </p>
            <button
              onClick={handleCalculate}
              disabled={calculating}
              className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-6 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-emerald-700 disabled:opacity-50"
            >
              <Calculator className="h-4 w-4" />
              {calculating ? 'Calculating...' : 'Calculate Payment'}
            </button>
          </div>
        </div>
      </div>

      {result && (
        <>
          {/* Results Card */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
            <div className="bg-gradient-to-r from-blue-600 to-emerald-600 p-6 text-white">
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
                <div className="text-center sm:text-left">
                  <p className="text-sm font-medium text-blue-100">Monthly Payment</p>
                  <p className="mt-1 text-3xl font-bold">{formatCurrency(result.monthlyPayment)}</p>
                </div>
                <div className="text-center sm:text-left">
                  <p className="text-sm font-medium text-blue-100">Total of Payments</p>
                  <p className="mt-1 text-2xl font-bold">{formatCurrency(result.totalOfPayments)}</p>
                </div>
                <div className="text-center sm:text-left">
                  <p className="text-sm font-medium text-blue-100">Total Interest</p>
                  <p className="mt-1 text-2xl font-bold">{formatCurrency(result.totalInterest)}</p>
                </div>
                <div className="text-center sm:text-left">
                  <p className="text-sm font-medium text-blue-100">Net Principal</p>
                  <p className="mt-1 text-2xl font-bold">{formatCurrency(result.netPrincipal)}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Term Comparison */}
          {result.comparisons && result.comparisons.length > 0 && (
            <div>
              <h2 className="mb-4 flex items-center gap-2 text-base font-semibold text-gray-900">
                <Clock className="h-5 w-5 text-blue-600" />
                Term Comparison
              </h2>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {result.comparisons.map((comp: TermComparison) => {
                  const isSelected = comp.term === result.termMonths;
                  return (
                    <div
                      key={comp.term}
                      className={`rounded-xl border-2 p-5 transition-shadow ${
                        isSelected
                          ? 'border-blue-500 bg-blue-50/50 shadow-md shadow-blue-500/10'
                          : 'border-gray-200 bg-white hover:shadow-sm'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className={`text-lg font-bold ${isSelected ? 'text-blue-700' : 'text-gray-900'}`}>
                          {comp.term} mo
                        </span>
                        {isSelected && (
                          <span className="rounded-full bg-blue-600 px-2 py-0.5 text-xs font-medium text-white">
                            Selected
                          </span>
                        )}
                      </div>
                      <div className="mt-3 space-y-2">
                        <div>
                          <p className="text-xs text-gray-500">Monthly Payment</p>
                          <p className={`text-xl font-bold ${isSelected ? 'text-blue-700' : 'text-gray-900'}`}>
                            {formatCurrency(comp.monthlyPayment)}
                          </p>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-500">Total Cost</span>
                          <span className="font-medium text-gray-700">{formatCurrencyWhole(comp.totalPayments)}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-500">Total Interest</span>
                          <span className="font-medium text-red-600">{formatCurrencyWhole(comp.totalInterest)}</span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Amortization Table */}
          {result.amortizationSchedule && result.amortizationSchedule.length > 0 && (
            <div className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
              <div className="border-b border-gray-100 px-6 py-4">
                <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900">
                  <TrendingDown className="h-5 w-5 text-blue-600" />
                  Amortization Schedule
                  <span className="ml-2 text-xs font-normal text-gray-400">First 12 months</span>
                </h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 bg-gray-50">
                      <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Month</th>
                      <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Payment</th>
                      <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Principal</th>
                      <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Interest</th>
                      <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Cum. Interest</th>
                      <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Balance</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {result.amortizationSchedule.slice(0, 12).map((entry: AmortizationEntry) => (
                      <tr key={entry.month} className="hover:bg-gray-50/50">
                        <td className="px-4 py-3 font-medium text-gray-900">{entry.month}</td>
                        <td className="px-4 py-3 text-right text-gray-700">{formatCurrency(entry.payment)}</td>
                        <td className="px-4 py-3 text-right font-medium text-emerald-700">{formatCurrency(entry.principal)}</td>
                        <td className="px-4 py-3 text-right text-red-600">{formatCurrency(entry.interest)}</td>
                        <td className="px-4 py-3 text-right text-gray-500">{formatCurrency(entry.cumulativeInterest)}</td>
                        <td className="px-4 py-3 text-right font-medium text-gray-900">{formatCurrency(entry.balance)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}

      {/* Empty state */}
      {!result && !calculating && (
        <div className="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50/50 py-16 text-center">
          <Calculator className="mx-auto h-12 w-12 text-gray-300" />
          <p className="mt-4 text-sm font-medium text-gray-500">
            Enter loan parameters above and click <span className="text-emerald-600">Calculate Payment</span> to see results
          </p>
        </div>
      )}
    </div>
  );
}

export default LoanCalculatorPage;
