import { useState, useEffect, useCallback } from 'react';
import { BarChart3, AlertTriangle } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import type { Column } from '@/components/shared/DataTable';
import { getStockPositions } from '@/api/stock';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { StockPosition } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

function StockPositionsPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [items, setItems] = useState<StockPosition[]>([]);
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
      const data = await getStockPositions(dealerCode);
      setItems(data);
    } catch {
      addToast('error', 'Failed to load stock positions');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const columns: Column<StockPosition>[] = [
    { key: 'modelYear', header: 'Year', sortable: true },
    { key: 'makeCode', header: 'Make', sortable: true },
    { key: 'modelCode', header: 'Model', sortable: true },
    { key: 'modelDesc', header: 'Description' },
    { key: 'onHandCount', header: 'On Hand', sortable: true },
    { key: 'inTransitCount', header: 'In Transit' },
    { key: 'allocatedCount', header: 'Allocated' },
    { key: 'onHoldCount', header: 'On Hold' },
    { key: 'soldMtd', header: 'Sold MTD' },
    { key: 'soldYtd', header: 'Sold YTD' },
    { key: 'reorderPoint', header: 'Reorder Pt' },
    {
      key: 'lowStockAlert',
      header: 'Alert',
      render: (row) =>
        row.lowStockAlert ? (
          <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-xs font-medium text-amber-700">
            <AlertTriangle className="h-3 w-3" />
            Low
          </span>
        ) : (
          <span className="text-xs text-gray-400">OK</span>
        ),
    },
  ];

  // Custom row class for low stock highlighting
  const dataWithStyle = items;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
            <BarChart3 className="h-5 w-5 text-indigo-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Stock Positions</h1>
            <p className="mt-0.5 text-sm text-gray-500">Inventory counts by model with reorder alerts</p>
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

      {/* Custom Table with row highlighting */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                {columns.map((col) => (
                  <th key={col.key} className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
                    {col.header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {columns.map((_, ci) => (
                      <td key={ci} className="px-4 py-3"><div className="h-4 rounded bg-gray-200" style={{ width: `${60 + Math.random() * 30}%` }} /></td>
                    ))}
                  </tr>
                ))
              ) : dataWithStyle.length === 0 ? (
                <tr><td colSpan={columns.length} className="px-4 py-12 text-center text-gray-400">No stock positions found</td></tr>
              ) : (
                dataWithStyle.map((row, idx) => (
                  <tr key={idx} className={`transition-colors hover:bg-gray-50 ${row.lowStockAlert ? 'bg-amber-50/50' : idx % 2 === 1 ? 'bg-gray-50/50' : ''}`}>
                    {columns.map((col) => (
                      <td key={col.key} className="whitespace-nowrap px-4 py-3 text-gray-700">
                        {col.render ? col.render(row) : ((row as unknown as Record<string, unknown>)[col.key] as React.ReactNode) ?? '\u2014'}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default StockPositionsPage;
