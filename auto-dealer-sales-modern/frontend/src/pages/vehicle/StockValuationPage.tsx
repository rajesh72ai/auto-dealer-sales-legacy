import { useState, useEffect, useCallback } from 'react';
import { Calculator, DollarSign, TrendingUp, Clock } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { getValuation } from '@/api/stock';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { StockValuation, ValuationCategory } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

function StockValuationPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [valuation, setValuation] = useState<StockValuation | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => {
      setDealers(r.content);
      if (!dealerCode && r.content.length > 0) setDealerCode(r.content[0].dealerCode);
    }).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]); // eslint-disable-line react-hooks/exhaustive-deps

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      const data = await getValuation(dealerCode);
      setValuation(data);
    } catch {
      addToast('error', 'Failed to load valuation');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const fmt = (n: number) => `$${n.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
  const totalCount = valuation?.categories.reduce((s, c) => s + c.count, 0) ?? 0;
  const totalInvoice = valuation?.categories.reduce((s, c) => s + c.totalInvoice, 0) ?? 0;
  const totalMsrp = valuation?.categories.reduce((s, c) => s + c.totalMsrp, 0) ?? 0;
  const totalHolding = valuation?.categories.reduce((s, c) => s + c.holdingCost, 0) ?? 0;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-green-50">
            <Calculator className="h-5 w-5 text-green-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Stock Valuation</h1>
            <p className="mt-0.5 text-sm text-gray-500">Inventory valuation by category with holding costs</p>
          </div>
        </div>
        <select
          value={dealerCode}
          onChange={(e) => setDealerCode(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          {dealers.map((d) => (
            <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
          ))}
        </select>
      </div>

      {loading ? (
        <div className="animate-pulse space-y-4">
          <div className="h-10 rounded-lg bg-gray-200" />
          {Array.from({ length: 4 }).map((_, i) => <div key={i} className="h-12 rounded-lg bg-gray-100" />)}
        </div>
      ) : valuation ? (
        <>
          {/* Summary cards */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-green-50 p-2.5"><DollarSign className="h-5 w-5 text-green-600" /></div>
                <div>
                  <p className="text-sm text-gray-500">Grand Total (Invoice)</p>
                  <p className="text-2xl font-bold text-gray-900">{fmt(valuation.grandTotal)}</p>
                </div>
              </div>
            </div>
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-amber-50 p-2.5"><TrendingUp className="h-5 w-5 text-amber-600" /></div>
                <div>
                  <p className="text-sm text-gray-500">Total Holding Cost</p>
                  <p className="text-2xl font-bold text-gray-900">{fmt(totalHolding)}</p>
                </div>
              </div>
            </div>
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-purple-50 p-2.5"><Clock className="h-5 w-5 text-purple-600" /></div>
                <div>
                  <p className="text-sm text-gray-500">Accrued Floor Plan Interest</p>
                  <p className="text-2xl font-bold text-gray-900">{fmt(valuation.totalAccruedInterest)}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Valuation Table */}
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Category</th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Count</th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Invoice Total</th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">MSRP Total</th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Avg Days</th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Holding Cost</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {valuation.categories.map((cat: ValuationCategory) => (
                  <tr key={cat.category} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div>
                        <span className="font-medium text-gray-900">{cat.categoryName}</span>
                        <span className="ml-2 text-xs text-gray-400">({cat.category})</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-gray-700">{cat.count}</td>
                    <td className="px-4 py-3 text-right font-medium text-gray-700">{fmt(cat.totalInvoice)}</td>
                    <td className="px-4 py-3 text-right text-gray-600">{fmt(cat.totalMsrp)}</td>
                    <td className="px-4 py-3 text-right text-gray-600">{cat.avgDaysInStock}</td>
                    <td className="px-4 py-3 text-right font-medium text-amber-700">{fmt(cat.holdingCost)}</td>
                  </tr>
                ))}
                {/* Grand total */}
                <tr className="border-t-2 border-gray-300 bg-gray-50 font-semibold">
                  <td className="px-4 py-3 text-gray-900">Grand Total</td>
                  <td className="px-4 py-3 text-right text-gray-900">{totalCount}</td>
                  <td className="px-4 py-3 text-right text-gray-900">{fmt(totalInvoice)}</td>
                  <td className="px-4 py-3 text-right text-gray-900">{fmt(totalMsrp)}</td>
                  <td className="px-4 py-3 text-right text-gray-500">--</td>
                  <td className="px-4 py-3 text-right text-amber-700">{fmt(totalHolding)}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <div className="rounded-xl border border-gray-200 bg-white p-12 text-center text-gray-400 shadow-sm">No valuation data available</div>
      )}
    </div>
  );
}

export default StockValuationPage;
