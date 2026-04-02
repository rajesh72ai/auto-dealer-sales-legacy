import { useState, useEffect } from 'react';
import { ClipboardCheck, Play, CheckCircle2, XCircle, Loader2 } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { reconcileStock } from '@/api/stock';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { Reconciliation, Discrepancy } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

function StockReconciliationPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [result, setResult] = useState<Reconciliation | null>(null);
  const [running, setRunning] = useState(false);

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => {
      setDealers(r.content);
      if (!dealerCode && r.content.length > 0) setDealerCode(r.content[0].dealerCode);
    }).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleReconcile = async () => {
    if (!dealerCode) return;
    setRunning(true);
    try {
      const data = await reconcileStock(dealerCode);
      setResult(data);
      addToast('success', 'Reconciliation completed');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Reconciliation failed');
    } finally {
      setRunning(false);
    }
  };

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-teal-50">
            <ClipboardCheck className="h-5 w-5 text-teal-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Stock Reconciliation</h1>
            <p className="mt-0.5 text-sm text-gray-500">Compare system stock against physical counts</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={dealerCode}
            onChange={(e) => { setDealerCode(e.target.value); setResult(null); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            {dealers.map((d) => (
              <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
            ))}
          </select>
          <button
            onClick={handleReconcile}
            disabled={running}
            className="inline-flex items-center gap-2 rounded-lg bg-teal-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20 disabled:opacity-50"
          >
            {running ? <Loader2 className="h-4 w-4 animate-spin" /> : <Play className="h-4 w-4" />}
            Run Reconciliation
          </button>
        </div>
      </div>

      {/* Results */}
      {result && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <p className="text-sm text-gray-500">Date</p>
              <p className="mt-1 text-lg font-bold text-gray-900">{result.reconciliationDate}</p>
            </div>
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <p className="text-sm text-gray-500">Total Models</p>
              <p className="mt-1 text-lg font-bold text-gray-900">{result.totalModels}</p>
            </div>
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <p className="text-sm text-gray-500">Total Variance</p>
              <p className={`mt-1 text-lg font-bold ${result.totalVariance !== 0 ? 'text-red-600' : 'text-gray-900'}`}>{result.totalVariance}</p>
            </div>
            <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <p className="text-sm text-gray-500">Reconciled</p>
              <div className="mt-1 flex items-center gap-2">
                {result.reconciled ? (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-green-50 px-3 py-1 text-sm font-medium text-green-700">
                    <CheckCircle2 className="h-4 w-4" /> Yes
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-3 py-1 text-sm font-medium text-red-700">
                    <XCircle className="h-4 w-4" /> No
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Discrepancy Table */}
          {result.discrepancies.length > 0 && (
            <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
              <div className="border-b border-gray-200 bg-red-50/50 px-6 py-3">
                <h3 className="text-sm font-semibold text-red-700">Discrepancies ({result.discrepancies.length})</h3>
              </div>
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Year</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Make</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Model</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Description</th>
                    <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">System</th>
                    <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Actual</th>
                    <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Variance</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {result.discrepancies.map((d: Discrepancy, idx: number) => (
                    <tr key={idx} className={`hover:bg-gray-50 ${d.variance !== 0 ? 'bg-red-50/30' : ''}`}>
                      <td className="px-4 py-3 text-gray-700">{d.modelYear}</td>
                      <td className="px-4 py-3 text-gray-700">{d.makeCode}</td>
                      <td className="px-4 py-3 text-gray-700">{d.modelCode}</td>
                      <td className="px-4 py-3 text-gray-700">{d.modelDesc}</td>
                      <td className="px-4 py-3 text-right font-medium text-gray-900">{d.systemCount}</td>
                      <td className="px-4 py-3 text-right font-medium text-gray-900">{d.actualCount}</td>
                      <td className={`px-4 py-3 text-right font-bold ${d.variance !== 0 ? 'text-red-600' : 'text-green-600'}`}>{d.variance > 0 ? `+${d.variance}` : d.variance}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {result.discrepancies.length === 0 && (
            <div className="rounded-xl border border-green-200 bg-green-50 p-8 text-center">
              <CheckCircle2 className="mx-auto h-10 w-10 text-green-500" />
              <p className="mt-3 text-sm font-medium text-green-700">All stock counts match. No discrepancies found.</p>
            </div>
          )}
        </>
      )}

      {!result && !running && (
        <div className="rounded-xl border border-gray-200 bg-white p-16 text-center text-gray-400 shadow-sm">
          <ClipboardCheck className="mx-auto h-12 w-12 text-gray-300" />
          <p className="mt-4 text-sm">Select a dealer and click "Run Reconciliation" to start</p>
        </div>
      )}
    </div>
  );
}

export default StockReconciliationPage;
