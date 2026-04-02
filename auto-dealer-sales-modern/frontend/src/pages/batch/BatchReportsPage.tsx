import { useState } from 'react';
import {
  getDailySales,
  getMonthlySnapshots,
  getCommissions,
  getUnpaidCommissions,
  getValidationReport,
  getGlPostingPreview,
  getPurgePreview,
} from '@/api/batch';
import type {
  DailySalesSummary,
  MonthlySnapshot,
  Commission,
  ValidationReport,
  GlPostingResult,
  PurgeResult,
} from '@/types/batch';

type ReportTab = 'daily' | 'monthly' | 'commissions' | 'validation' | 'gl' | 'purge';

const TABS: { key: ReportTab; label: string }[] = [
  { key: 'daily', label: 'Daily Sales' },
  { key: 'monthly', label: 'Monthly Snapshots' },
  { key: 'commissions', label: 'Commissions' },
  { key: 'validation', label: 'Data Validation' },
  { key: 'gl', label: 'GL Postings' },
  { key: 'purge', label: 'Purge Preview' },
];

const SEVERITY_STYLES: Record<string, string> = {
  HIGH: 'bg-red-100 text-red-800',
  MEDIUM: 'bg-amber-100 text-amber-800',
  LOW: 'bg-blue-100 text-blue-800',
};

export default function BatchReportsPage() {
  const [activeTab, setActiveTab] = useState<ReportTab>('daily');
  const [dealerCode, setDealerCode] = useState('D0001');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [payPeriod, setPayPeriod] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Report data states
  const [dailySales, setDailySales] = useState<DailySalesSummary[]>([]);
  const [snapshots, setSnapshots] = useState<MonthlySnapshot[]>([]);
  const [commissions, setCommissions] = useState<Commission[]>([]);
  const [validationReport, setValidationReport] = useState<ValidationReport | null>(null);
  const [glResult, setGlResult] = useState<GlPostingResult | null>(null);
  const [purgeResult, setPurgeResult] = useState<PurgeResult | null>(null);

  const fetchReport = async () => {
    setLoading(true);
    setError('');
    try {
      switch (activeTab) {
        case 'daily':
          if (!startDate || !endDate) { setError('Select date range'); return; }
          setDailySales(await getDailySales({ dealerCode, startDate, endDate }));
          break;
        case 'monthly':
          setSnapshots(await getMonthlySnapshots(dealerCode));
          break;
        case 'commissions':
          if (payPeriod) {
            setCommissions(await getCommissions(dealerCode, payPeriod));
          } else {
            setCommissions(await getUnpaidCommissions(dealerCode));
          }
          break;
        case 'validation':
          setValidationReport(await getValidationReport());
          break;
        case 'gl':
          setGlResult(await getGlPostingPreview());
          break;
        case 'purge':
          setPurgeResult(await getPurgePreview());
          break;
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load report');
    } finally {
      setLoading(false);
    }
  };

  const fmt = (n: number | null | undefined) =>
    n != null ? n.toLocaleString('en-US', { style: 'currency', currency: 'USD' }) : '-';

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Batch Reports & Analytics</h1>

      {/* Tab Navigation */}
      <div className="flex space-x-1 mb-6 bg-gray-100 rounded-lg p-1">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex-1 py-2 text-sm font-medium rounded-md transition ${
              activeTab === tab.key
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-end gap-3 mb-6">
        {(activeTab === 'daily' || activeTab === 'monthly' || activeTab === 'commissions') && (
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Dealer Code</label>
            <input
              type="text"
              value={dealerCode}
              onChange={(e) => setDealerCode(e.target.value)}
              className="border rounded-lg px-3 py-2 text-sm w-28"
            />
          </div>
        )}
        {activeTab === 'daily' && (
          <>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Start Date</label>
              <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)}
                className="border rounded-lg px-3 py-2 text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">End Date</label>
              <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)}
                className="border rounded-lg px-3 py-2 text-sm" />
            </div>
          </>
        )}
        {activeTab === 'commissions' && (
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Pay Period (YYYYMM)</label>
            <input type="text" value={payPeriod} onChange={(e) => setPayPeriod(e.target.value)}
              placeholder="Leave blank for unpaid"
              className="border rounded-lg px-3 py-2 text-sm w-48" />
          </div>
        )}
        <button
          onClick={fetchReport}
          disabled={loading}
          className="px-5 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition"
        >
          {loading ? 'Loading...' : 'Load Report'}
        </button>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-lg text-sm">{error}</div>
      )}

      {/* Daily Sales Table */}
      {activeTab === 'daily' && dailySales.length > 0 && (
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Date</th>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Make/Model</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Units</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Revenue</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Gross</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Front</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Back</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Avg GPU</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {dailySales.map((s, i) => (
                <tr key={i} className="hover:bg-gray-50">
                  <td className="px-3 py-2">{s.summaryDate}</td>
                  <td className="px-3 py-2">{s.modelYear} {s.makeCode} {s.modelCode}</td>
                  <td className="px-3 py-2 text-right font-medium">{s.unitsSold}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.totalRevenue)}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.totalGross)}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.frontGross)}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.backGross)}</td>
                  <td className="px-3 py-2 text-right font-medium">{fmt(s.avgGrossPerUnit)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Monthly Snapshots */}
      {activeTab === 'monthly' && snapshots.length > 0 && (
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Month</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Units</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Revenue</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Gross</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">F&I Gross</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">F&I/Deal</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Avg DTS</th>
                <th className="px-3 py-2 text-center text-xs font-medium text-gray-500">Frozen</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {snapshots.map((s, i) => (
                <tr key={i} className="hover:bg-gray-50">
                  <td className="px-3 py-2 font-medium">{s.snapshotMonth}</td>
                  <td className="px-3 py-2 text-right">{s.totalUnitsSold}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.totalRevenue)}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.totalGross)}</td>
                  <td className="px-3 py-2 text-right">{fmt(s.totalFiGross)}</td>
                  <td className="px-3 py-2 text-right font-medium">{fmt(s.fiPerDeal)}</td>
                  <td className="px-3 py-2 text-right">{s.avgDaysToSell}</td>
                  <td className="px-3 py-2 text-center">
                    {s.frozenFlag === 'Y' ? (
                      <span className="text-green-600 font-bold">Y</span>
                    ) : (
                      <span className="text-gray-400">N</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Commissions */}
      {activeTab === 'commissions' && commissions.length > 0 && (
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Salesperson</th>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Deal #</th>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Type</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Gross</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Rate</th>
                <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Amount</th>
                <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Period</th>
                <th className="px-3 py-2 text-center text-xs font-medium text-gray-500">Paid</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {commissions.map((c) => (
                <tr key={c.commissionId} className="hover:bg-gray-50">
                  <td className="px-3 py-2 font-mono">{c.salespersonId}</td>
                  <td className="px-3 py-2">{c.dealNumber}</td>
                  <td className="px-3 py-2">{c.commType}</td>
                  <td className="px-3 py-2 text-right">{fmt(c.grossAmount)}</td>
                  <td className="px-3 py-2 text-right">{(c.commRate * 100).toFixed(2)}%</td>
                  <td className="px-3 py-2 text-right font-medium">{fmt(c.commAmount)}</td>
                  <td className="px-3 py-2">{c.payPeriod}</td>
                  <td className="px-3 py-2 text-center">
                    {c.paidFlag === 'Y' ? (
                      <span className="text-green-600 font-bold">Y</span>
                    ) : (
                      <span className="text-red-500 font-bold">N</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Validation Report */}
      {activeTab === 'validation' && validationReport && (
        <div className="space-y-4">
          <div className="grid grid-cols-4 gap-4">
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-gray-900">{validationReport.totalExceptions}</div>
              <div className="text-xs text-gray-500">Total Exceptions</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-red-600">{validationReport.orphanedDeals.length}</div>
              <div className="text-xs text-gray-500">Orphaned Deals</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-amber-600">{validationReport.invalidVins.length}</div>
              <div className="text-xs text-gray-500">Invalid VINs</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-blue-600">{validationReport.duplicateCustomers.length}</div>
              <div className="text-xs text-gray-500">Duplicate Customers</div>
            </div>
          </div>
          {[
            { title: 'Orphaned Deals', items: validationReport.orphanedDeals },
            { title: 'Orphaned Vehicles', items: validationReport.orphanedVehicles },
            { title: 'Invalid VINs', items: validationReport.invalidVins },
            { title: 'Duplicate Customers', items: validationReport.duplicateCustomers },
          ].filter(section => section.items.length > 0).map((section) => (
            <div key={section.title} className="bg-white shadow rounded-lg p-4">
              <h3 className="text-sm font-semibold text-gray-900 mb-2">{section.title}</h3>
              <div className="space-y-1">
                {section.items.slice(0, 20).map((item, i) => (
                  <div key={i} className="flex items-center gap-3 text-sm">
                    <span className={`inline-flex px-2 py-0.5 text-xs rounded-full ${SEVERITY_STYLES[item.severity]}`}>
                      {item.severity}
                    </span>
                    <span className="font-mono text-gray-700">{item.entityId}</span>
                    <span className="text-gray-500">{item.description}</span>
                  </div>
                ))}
                {section.items.length > 20 && (
                  <div className="text-xs text-gray-400 pl-2">
                    ... and {section.items.length - 20} more
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* GL Postings */}
      {activeTab === 'gl' && glResult && (
        <div className="space-y-4">
          <div className="grid grid-cols-5 gap-4">
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-xl font-bold text-gray-900">{glResult.dealsProcessed}</div>
              <div className="text-xs text-gray-500">Deals</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-lg font-bold text-green-600">{fmt(glResult.totalRevenue)}</div>
              <div className="text-xs text-gray-500">Revenue</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-lg font-bold text-red-600">{fmt(glResult.totalCogs)}</div>
              <div className="text-xs text-gray-500">COGS</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-lg font-bold text-indigo-600">{fmt(glResult.totalFiIncome)}</div>
              <div className="text-xs text-gray-500">F&I Income</div>
            </div>
            <div className="bg-white shadow rounded-lg p-4 text-center">
              <div className="text-lg font-bold text-amber-600">{fmt(glResult.totalTax)}</div>
              <div className="text-xs text-gray-500">Tax</div>
            </div>
          </div>
          <div className="bg-white shadow rounded-lg overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Deal #</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Account</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Name</th>
                  <th className="px-3 py-2 text-center text-xs font-medium text-gray-500">DR/CR</th>
                  <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {glResult.entries.slice(0, 50).map((entry, i) => (
                  <tr key={i} className="hover:bg-gray-50">
                    <td className="px-3 py-2">{entry.dealNumber}</td>
                    <td className="px-3 py-2 font-mono">{entry.accountCode}</td>
                    <td className="px-3 py-2">{entry.accountName}</td>
                    <td className="px-3 py-2 text-center">
                      <span className={`px-2 py-0.5 text-xs rounded ${
                        entry.entryType === 'DR' ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-700'
                      }`}>
                        {entry.entryType}
                      </span>
                    </td>
                    <td className="px-3 py-2 text-right font-medium">{fmt(entry.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Purge Preview */}
      {activeTab === 'purge' && purgeResult && (
        <div className="bg-white shadow rounded-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Purge Preview</h3>
          <div className="grid grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-3xl font-bold text-gray-900">
                {purgeResult.registrationsArchived}
              </div>
              <div className="text-sm text-gray-500 mt-1">Registrations to Archive</div>
              <div className="text-xs text-gray-400">2+ years old</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-red-600">
                {purgeResult.auditLogsPurged}
              </div>
              <div className="text-sm text-gray-500 mt-1">Audit Logs to Purge</div>
              <div className="text-xs text-gray-400">3+ years old</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-amber-600">
                {purgeResult.notificationsPurged}
              </div>
              <div className="text-sm text-gray-500 mt-1">Notifications to Purge</div>
              <div className="text-xs text-gray-400">1+ year old, no response</div>
            </div>
          </div>
          <div className="mt-6 text-center">
            <span className={`inline-flex px-3 py-1 text-sm font-medium rounded-full ${
              purgeResult.status === 'PREVIEW' ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'
            }`}>
              {purgeResult.status}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
