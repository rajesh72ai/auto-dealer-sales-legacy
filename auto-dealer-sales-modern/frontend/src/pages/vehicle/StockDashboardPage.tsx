import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Car,
  Truck,
  Tag,
  Lock,
  ShoppingCart,
  DollarSign,
  AlertTriangle,
  ArrowRight,
  BarChart3,
  RefreshCw,
  Repeat,
  Calculator,
  ClipboardCheck,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { getStockSummary, getAlerts } from '@/api/stock';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { StockSummary, StockAlert } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const ALERT_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  LOW_STOCK: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Low Stock' },
  OVER_AGE: { bg: 'bg-red-50', text: 'text-red-700', label: 'Over Age' },
};

function StockDashboardPage() {
  const { addToast } = useToast();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [summary, setSummary] = useState<StockSummary | null>(null);
  const [alerts, setAlerts] = useState<StockAlert[]>([]);
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
      const [summaryData, alertData] = await Promise.all([
        getStockSummary(dealerCode),
        getAlerts(dealerCode),
      ]);
      setSummary(summaryData);
      setAlerts(alertData);
    } catch {
      addToast('error', 'Failed to load stock dashboard');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const summaryCards = summary ? [
    { label: 'On Hand', value: summary.totalOnHand, icon: Car, color: 'blue' },
    { label: 'In Transit', value: summary.totalInTransit, icon: Truck, color: 'purple' },
    { label: 'Allocated', value: summary.totalAllocated, icon: Tag, color: 'indigo' },
    { label: 'On Hold', value: summary.totalOnHold, icon: Lock, color: 'amber' },
    { label: 'Sold MTD', value: summary.totalSoldMtd, icon: ShoppingCart, color: 'green' },
    { label: 'Sold YTD', value: summary.totalSoldYtd, icon: ShoppingCart, color: 'emerald' },
    { label: 'Total Value', value: `$${summary.totalValue.toLocaleString()}`, icon: DollarSign, color: 'cyan' },
  ] : [];

  const quickLinks = [
    { label: 'Positions', icon: BarChart3, path: '/stock/positions' },
    { label: 'Adjustments', icon: RefreshCw, path: '/stock/adjustments' },
    { label: 'Transfers', icon: Repeat, path: '/stock/transfers' },
    { label: 'Valuation', icon: Calculator, path: '/stock/valuation' },
    { label: 'Reconciliation', icon: ClipboardCheck, path: '/stock/reconciliation' },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
            <LayoutDashboard className="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Stock Dashboard</h1>
            <p className="mt-0.5 text-sm text-gray-500">Real-time inventory overview and alerts</p>
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

      {/* Summary Cards */}
      {loading ? (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-7">
          {Array.from({ length: 7 }).map((_, i) => (
            <div key={i} className="animate-pulse rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
              <div className="h-4 w-16 rounded bg-gray-200" />
              <div className="mt-3 h-7 w-12 rounded bg-gray-200" />
            </div>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-7">
          {summaryCards.map((card) => (
            <div key={card.label} className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm transition-shadow hover:shadow-md">
              <div className="flex items-center gap-2">
                <card.icon className={`h-4 w-4 text-${card.color}-500`} />
                <p className="text-xs font-medium text-gray-500">{card.label}</p>
              </div>
              <p className="mt-2 text-xl font-bold text-gray-900">{typeof card.value === 'number' ? card.value.toLocaleString() : card.value}</p>
            </div>
          ))}
        </div>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Alerts Panel */}
        <div className="lg:col-span-2">
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="flex items-center gap-2 border-b border-gray-200 px-6 py-4">
              <AlertTriangle className="h-4 w-4 text-amber-500" />
              <h3 className="text-sm font-semibold text-gray-900">Stock Alerts</h3>
              <span className="ml-auto rounded-full bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-700">{alerts.length}</span>
            </div>
            <div className="max-h-96 divide-y divide-gray-100 overflow-y-auto">
              {alerts.length === 0 ? (
                <div className="px-6 py-12 text-center text-sm text-gray-400">No active alerts</div>
              ) : (
                alerts.map((alert, idx) => {
                  const badge = ALERT_BADGE[alert.alertType] || { bg: 'bg-gray-100', text: 'text-gray-700', label: alert.alertType };
                  return (
                    <div key={idx} className="flex items-center gap-4 px-6 py-3 hover:bg-gray-50">
                      <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${badge.bg} ${badge.text}`}>{badge.label}</span>
                      <div className="flex-1 min-w-0">
                        <p className="truncate text-sm font-medium text-gray-700">{alert.modelYear} {alert.makeCode} {alert.modelCode}</p>
                        <p className="text-xs text-gray-500">{alert.modelDesc}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-medium text-gray-900">Current: {alert.currentCount}</p>
                        <p className="text-xs text-gray-500">Reorder: {alert.reorderPoint} | Suggested: {alert.suggestedOrder}</p>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>

        {/* Quick Links */}
        <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Quick Links</h3>
          <div className="space-y-2">
            {quickLinks.map((link) => (
              <button
                key={link.path}
                onClick={() => navigate(link.path)}
                className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-left transition-colors hover:bg-gray-50"
              >
                <link.icon className="h-5 w-5 text-gray-400" />
                <span className="flex-1 text-sm font-medium text-gray-700">{link.label}</span>
                <ArrowRight className="h-4 w-4 text-gray-300" />
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default StockDashboardPage;
