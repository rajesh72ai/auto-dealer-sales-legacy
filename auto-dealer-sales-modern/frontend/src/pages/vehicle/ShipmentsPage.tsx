import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Truck, Filter } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import { listShipments } from '@/api/production';
import { getDealers } from '@/api/dealers';
import type { ShipmentInfo } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const SHIPMENT_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  CR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Created' },
  DP: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Dispatched' },
  IT: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'In Transit' },
  DL: { bg: 'bg-green-50', text: 'text-green-700', label: 'Delivered' },
};

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  ...Object.entries(SHIPMENT_STATUS_CONFIG).map(([value, cfg]) => ({ value, label: cfg.label })),
];

function ShipmentsPage() {
  const { addToast } = useToast();
  const navigate = useNavigate();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [items, setItems] = useState<ShipmentInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [statusFilter, setStatusFilter] = useState('');
  const [dealerFilter, setDealerFilter] = useState('');
  const [carrierFilter, setCarrierFilter] = useState('');

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => setDealers(r.content)).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listShipments({
        status: statusFilter || undefined,
        dealer: dealerFilter || undefined,
        carrier: carrierFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load shipments');
    } finally {
      setLoading(false);
    }
  }, [statusFilter, dealerFilter, carrierFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const columns: Column<ShipmentInfo>[] = [
    { key: 'shipmentId', header: 'ID', sortable: true },
    {
      key: 'carrierCode',
      header: 'Carrier',
      render: (row) => (
        <div>
          <span className="font-medium text-gray-900">{row.carrierCode}</span>
          {row.carrierName && <span className="ml-1 text-xs text-gray-500">({row.carrierName})</span>}
        </div>
      ),
    },
    { key: 'originPlant', header: 'Origin' },
    { key: 'destDealer', header: 'Destination' },
    { key: 'transportMode', header: 'Mode' },
    {
      key: 'vehicleCount',
      header: 'Vehicles',
      render: (row) => (
        <span className="inline-flex rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700">{row.vehicleCount}</span>
      ),
    },
    {
      key: 'shipDate',
      header: 'Ship Date',
      render: (row) => <span className="text-xs text-gray-600">{row.shipDate || 'N/A'}</span>,
    },
    {
      key: 'estArrivalDate',
      header: 'Est. Arrival',
      render: (row) => <span className="text-xs text-gray-600">{row.estArrivalDate || 'N/A'}</span>,
    },
    {
      key: 'shipmentStatus',
      header: 'Status',
      render: (row) => {
        const cfg = SHIPMENT_STATUS_CONFIG[row.shipmentStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.statusName };
        return (
          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${cfg.bg} ${cfg.text}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${cfg.text.replace('text-', 'bg-')}`} />
            {cfg.label}
          </span>
        );
      },
    },
  ];

  const hasFilters = statusFilter || dealerFilter || carrierFilter;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
          <Truck className="h-5 w-5 text-blue-600" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Shipments</h1>
          <p className="mt-0.5 text-sm text-gray-500">Track vehicle shipments from plant to dealer</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-1.5 text-sm text-gray-500"><Filter className="h-4 w-4" /> Filters</div>
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }} className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
          {STATUS_OPTIONS.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
        </select>
        <select value={dealerFilter} onChange={(e) => { setDealerFilter(e.target.value); setPage(0); }} className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
          <option value="">All Dealers</option>
          {dealers.map((d) => <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>)}
        </select>
        <input type="text" placeholder="Carrier..." value={carrierFilter} onChange={(e) => { setCarrierFilter(e.target.value); setPage(0); }} className="w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20" />
        {hasFilters && (
          <button onClick={() => { setStatusFilter(''); setDealerFilter(''); setCarrierFilter(''); setPage(0); }} className="text-sm font-medium text-blue-600 hover:text-blue-700">Clear filters</button>
        )}
      </div>

      {/* Table */}
      <DataTable
        columns={columns}
        data={items}
        loading={loading}
        page={page}
        totalPages={totalPages}
        totalElements={totalElements}
        onPageChange={setPage}
        onRowClick={(row) => navigate(`/shipments/${row.shipmentId}`)}
      />
    </div>
  );
}

export default ShipmentsPage;
