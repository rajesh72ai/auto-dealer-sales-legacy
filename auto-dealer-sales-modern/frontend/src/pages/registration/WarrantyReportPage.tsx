import { useState, useEffect } from 'react';
import { BarChart3, Download } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import FormField from '@/components/shared/FormField';
import { getWarrantyClaimReport } from '@/api/warranty';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { WarrantyClaimSummary } from '@/types/registration';
import type { Dealer } from '@/types/admin';

function WarrantyReportPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [report, setReport] = useState<WarrantyClaimSummary | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => {
      setDealers(r.content);
      if (!dealerCode && r.content.length > 0) setDealerCode(r.content[0].dealerCode);
    }).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleGenerate = async () => {
    if (!dealerCode) { addToast('error', 'Select a dealer'); return; }
    setLoading(true);
    try {
      const result = await getWarrantyClaimReport({
        dealerCode,
        fromDate: fromDate || undefined,
        toDate: toDate || undefined,
      });
      setReport(result);
      if (result.grandTotalClaims === 0) addToast('warning', 'No warranty claims found for selected criteria');
    } catch {
      addToast('error', 'Failed to generate report');
    } finally {
      setLoading(false);
    }
  };

  const fmt = (n: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <BarChart3 className="h-7 w-7 text-violet-600" /> Warranty Claims Report
        </h1>
        <p className="text-sm text-gray-500 mt-1">Summary report by claim type — WRCRPT00</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-end gap-4 flex-wrap">
          <div className="w-64">
            <FormField label="Dealer" required>
              <select value={dealerCode} onChange={(e) => setDealerCode(e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm">
                {dealers.map((d) => <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} — {d.dealerName}</option>)}
              </select>
            </FormField>
          </div>
          <div className="w-44">
            <FormField label="From Date">
              <input type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
            </FormField>
          </div>
          <div className="w-44">
            <FormField label="To Date">
              <input type="date" value={toDate} onChange={(e) => setToDate(e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
            </FormField>
          </div>
          <button onClick={handleGenerate} disabled={loading}
            className="flex items-center gap-2 px-4 py-2 bg-violet-600 text-white rounded-lg hover:bg-violet-700 disabled:opacity-50">
            <Download className="h-4 w-4" /> Generate
          </button>
        </div>
      </div>

      {loading && (
        <div className="flex justify-center p-8">
          <div className="animate-spin h-8 w-8 border-4 border-violet-500 border-t-transparent rounded-full" />
        </div>
      )}

      {report && !loading && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Total Claims', value: report.grandTotalClaims, color: 'text-gray-900' },
              { label: 'Grand Total', value: fmt(report.grandTotal), color: 'text-violet-600' },
              { label: 'Average Claim', value: fmt(report.averageClaimAmount), color: 'text-blue-600' },
              { label: 'Approved / Denied', value: `${report.totalApproved} / ${report.totalDenied}`, color: 'text-emerald-600' },
            ].map((card) => (
              <div key={card.label} className="bg-white rounded-xl shadow-sm border border-gray-200 p-5">
                <p className="text-xs text-gray-500 uppercase tracking-wide">{card.label}</p>
                <p className={`text-2xl font-bold mt-1 ${card.color}`}>{card.value}</p>
              </div>
            ))}
          </div>

          {/* Type Breakdown Table */}
          {report.byType.length > 0 && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="text-left px-4 py-3 font-medium text-gray-600">Claim Type</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-600">Claims</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-600">Labor</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-600">Parts</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-600">Total</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-600">Approved</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-600">Denied</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {report.byType.map((row) => (
                    <tr key={row.claimType} className="hover:bg-gray-50">
                      <td className="px-4 py-3 font-medium text-gray-900">{row.claimTypeName}</td>
                      <td className="px-4 py-3 text-right">{row.totalClaims}</td>
                      <td className="px-4 py-3 text-right">{fmt(row.laborTotal)}</td>
                      <td className="px-4 py-3 text-right">{fmt(row.partsTotal)}</td>
                      <td className="px-4 py-3 text-right font-medium">{fmt(row.claimTotal)}</td>
                      <td className="px-4 py-3 text-right text-green-600">{row.approvedCount}</td>
                      <td className="px-4 py-3 text-right text-red-600">{row.deniedCount}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot className="bg-gray-50 border-t-2 border-gray-300">
                  <tr className="font-semibold">
                    <td className="px-4 py-3">Grand Total</td>
                    <td className="px-4 py-3 text-right">{report.grandTotalClaims}</td>
                    <td className="px-4 py-3 text-right">{fmt(report.grandTotalLabor)}</td>
                    <td className="px-4 py-3 text-right">{fmt(report.grandTotalParts)}</td>
                    <td className="px-4 py-3 text-right">{fmt(report.grandTotal)}</td>
                    <td className="px-4 py-3 text-right text-green-600">{report.totalApproved}</td>
                    <td className="px-4 py-3 text-right text-red-600">{report.totalDenied}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default WarrantyReportPage;
