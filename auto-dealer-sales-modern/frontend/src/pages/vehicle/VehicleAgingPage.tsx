import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Clock, DollarSign, Car, TrendingUp } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import { getAgingReport } from '@/api/vehicles';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { AgingReport, AgingBucket, VehicleListItem } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const BUCKET_COLORS = [
  'bg-green-500',
  'bg-blue-500',
  'bg-amber-500',
  'bg-orange-500',
  'bg-red-500',
  'bg-red-700',
];

function VehicleAgingPage() {
  const { addToast } = useToast();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [report, setReport] = useState<AgingReport | null>(null);
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
      const data = await getAgingReport(dealerCode);
      setReport(data);
    } catch {
      addToast('error', 'Failed to load aging report');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const agedColumns: Column<VehicleListItem>[] = [
    { key: 'vin', header: 'VIN', sortable: true },
    { key: 'stockNumber', header: 'Stock #' },
    { key: 'vehicleDesc', header: 'Vehicle' },
    { key: 'exteriorColor', header: 'Color' },
    {
      key: 'daysInStock',
      header: 'Days',
      sortable: true,
      render: (row) => <span className="font-semibold text-red-600">{row.daysInStock}</span>,
    },
    { key: 'vehicleStatus', header: 'Status' },
  ];

  const maxBucket = report ? Math.max(...report.buckets.map((b) => b.count), 1) : 1;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50">
            <Clock className="h-5 w-5 text-amber-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Vehicle Aging</h1>
            <p className="mt-0.5 text-sm text-gray-500">Analyze inventory age and identify stale stock</p>
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
      {report && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-blue-50 p-2.5"><Car className="h-5 w-5 text-blue-600" /></div>
              <div>
                <p className="text-sm text-gray-500">Total Vehicles</p>
                <p className="text-2xl font-bold text-gray-900">{report.totalVehicles.toLocaleString()}</p>
              </div>
            </div>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-green-50 p-2.5"><DollarSign className="h-5 w-5 text-green-600" /></div>
              <div>
                <p className="text-sm text-gray-500">Total Value</p>
                <p className="text-2xl font-bold text-gray-900">${report.totalValue.toLocaleString()}</p>
              </div>
            </div>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-amber-50 p-2.5"><TrendingUp className="h-5 w-5 text-amber-600" /></div>
              <div>
                <p className="text-sm text-gray-500">Avg Days In Stock</p>
                <p className="text-2xl font-bold text-gray-900">{report.avgDaysInStock}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Aging Buckets */}
      {report && report.buckets.length > 0 && (
        <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Aging Distribution</h3>
          <div className="space-y-3">
            {report.buckets.map((bucket: AgingBucket, idx: number) => (
              <div key={bucket.range} className="flex items-center gap-4">
                <span className="w-24 text-right text-sm font-medium text-gray-600">{bucket.range}</span>
                <div className="flex-1">
                  <div className="relative h-8 overflow-hidden rounded-lg bg-gray-100">
                    <div
                      className={`absolute inset-y-0 left-0 rounded-lg ${BUCKET_COLORS[idx] || 'bg-gray-500'} transition-all duration-500`}
                      style={{ width: `${(bucket.count / maxBucket) * 100}%` }}
                    />
                    <div className="absolute inset-0 flex items-center px-3">
                      <span className="text-xs font-semibold text-white drop-shadow">{bucket.count} vehicles</span>
                    </div>
                  </div>
                </div>
                <div className="w-28 text-right">
                  <span className="text-sm font-medium text-gray-700">${bucket.value.toLocaleString()}</span>
                </div>
                <div className="w-16 text-right">
                  <span className="text-xs text-gray-500">{bucket.avgDays}d avg</span>
                </div>
                <div className="w-16 text-right">
                  <span className="text-xs font-medium text-gray-500">{bucket.pctOfTotal}%</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Aged Vehicles Table (90+ days) */}
      {report && report.agedVehicles.length > 0 && (
        <div>
          <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-red-600">Aged Vehicles (90+ Days)</h3>
          <DataTable
            columns={agedColumns}
            data={report.agedVehicles}
            loading={loading}
            page={0}
            totalPages={1}
            totalElements={report.agedVehicles.length}
            onPageChange={() => {}}
            onRowClick={(row) => navigate(`/vehicles/${row.vin}`)}
          />
        </div>
      )}
    </div>
  );
}

export default VehicleAgingPage;
