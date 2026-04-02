import { useState, useEffect, useCallback } from 'react';
import { Plus, Factory, Filter } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { listOrders, createOrder, allocateOrder } from '@/api/production';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { ProductionOrder, ProductionOrderRequest, ProductionAllocateRequest } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const BUILD_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  PR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Production' },
  AL: { bg: 'bg-indigo-50', text: 'text-indigo-700', label: 'Allocated' },
  SH: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'Shipped' },
  CM: { bg: 'bg-green-50', text: 'text-green-700', label: 'Complete' },
};

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  ...Object.entries(BUILD_STATUS_CONFIG).map(([value, cfg]) => ({ value, label: cfg.label })),
];

const defaultOrderForm: ProductionOrderRequest = {
  vin: '',
  modelYear: new Date().getFullYear(),
  makeCode: '',
  modelCode: '',
  plantCode: '',
  buildDate: new Date().toISOString().split('T')[0],
};

const defaultAllocateForm: ProductionAllocateRequest = {
  allocatedDealer: '',
  priority: 'N',
};

function ProductionOrdersPage() {
  const { addToast } = useToast();
  useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [items, setItems] = useState<ProductionOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [statusFilter, setStatusFilter] = useState('');
  const [plantFilter, setPlantFilter] = useState('');
  const [dealerFilter, setDealerFilter] = useState('');

  const [createOpen, setCreateOpen] = useState(false);
  const [orderForm, setOrderForm] = useState({ ...defaultOrderForm });
  const [orderErrors, setOrderErrors] = useState<Record<string, string>>({});

  const [allocateOpen, setAllocateOpen] = useState(false);
  const [allocateTarget, setAllocateTarget] = useState<string>('');
  const [allocateForm, setAllocateForm] = useState({ ...defaultAllocateForm });

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => setDealers(r.content)).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listOrders({
        status: statusFilter || undefined,
        plantCode: plantFilter || undefined,
        dealer: dealerFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load production orders');
    } finally {
      setLoading(false);
    }
  }, [statusFilter, plantFilter, dealerFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleOrderChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setOrderForm((prev) => ({ ...prev, [name]: name === 'modelYear' ? Number(value) : value }));
    if (orderErrors[name]) setOrderErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!orderForm.vin.trim()) errs.vin = 'VIN is required';
    if (!orderForm.makeCode.trim()) errs.makeCode = 'Make is required';
    if (!orderForm.modelCode.trim()) errs.modelCode = 'Model is required';
    if (!orderForm.plantCode.trim()) errs.plantCode = 'Plant is required';
    setOrderErrors(errs);
    if (Object.keys(errs).length > 0) return;
    try {
      await createOrder(orderForm);
      addToast('success', 'Production order created');
      setCreateOpen(false);
      setOrderForm({ ...defaultOrderForm });
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create order');
    }
  };

  const handleAllocateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!allocateForm.allocatedDealer) { addToast('error', 'Select a dealer'); return; }
    try {
      await allocateOrder(allocateTarget, allocateForm);
      addToast('success', 'Order allocated to dealer');
      setAllocateOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to allocate order');
    }
  };

  const openAllocate = (order: ProductionOrder) => {
    setAllocateTarget(order.productionId);
    setAllocateForm({ ...defaultAllocateForm });
    setAllocateOpen(true);
  };

  const columns: Column<ProductionOrder>[] = [
    { key: 'productionId', header: 'ID', sortable: true },
    { key: 'vin', header: 'VIN', sortable: true },
    {
      key: 'vehicleDesc',
      header: 'Year/Make/Model',
      render: (row) => <span>{row.modelYear} {row.makeCode} {row.modelCode}</span>,
    },
    { key: 'plantCode', header: 'Plant' },
    {
      key: 'buildDate',
      header: 'Build Date',
      render: (row) => <span className="text-xs text-gray-600">{row.buildDate}</span>,
    },
    {
      key: 'buildStatus',
      header: 'Status',
      render: (row) => {
        const cfg = BUILD_STATUS_CONFIG[row.buildStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.buildStatusName };
        return (
          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${cfg.bg} ${cfg.text}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${cfg.text.replace('text-', 'bg-')}`} />
            {cfg.label}
          </span>
        );
      },
    },
    {
      key: 'allocatedDealer',
      header: 'Allocated Dealer',
      render: (row) => row.allocatedDealer || <span className="text-xs text-gray-400">Unallocated</span>,
    },
  ];

  const hasFilters = statusFilter || plantFilter || dealerFilter;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50">
            <Factory className="h-5 w-5 text-purple-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Production Orders</h1>
            <p className="mt-0.5 text-sm text-gray-500">Track vehicle production and factory allocation</p>
          </div>
        </div>
        <button
          onClick={() => { setOrderForm({ ...defaultOrderForm }); setOrderErrors({}); setCreateOpen(true); }}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Create Order
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-1.5 text-sm text-gray-500"><Filter className="h-4 w-4" /> Filters</div>
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }} className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
          {STATUS_OPTIONS.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
        </select>
        <input type="text" placeholder="Plant code..." value={plantFilter} onChange={(e) => { setPlantFilter(e.target.value); setPage(0); }} className="w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20" />
        <select value={dealerFilter} onChange={(e) => { setDealerFilter(e.target.value); setPage(0); }} className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
          <option value="">All Dealers</option>
          {dealers.map((d) => <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>)}
        </select>
        {hasFilters && (
          <button onClick={() => { setStatusFilter(''); setPlantFilter(''); setDealerFilter(''); setPage(0); }} className="text-sm font-medium text-blue-600 hover:text-blue-700">Clear filters</button>
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
        onRowClick={(row) => row.buildStatus === 'PR' && openAllocate(row)}
      />

      {/* Create Order Modal */}
      <Modal isOpen={createOpen} onClose={() => setCreateOpen(false)} title="Create Production Order" size="lg">
        <form onSubmit={handleCreateSubmit} className="space-y-4">
          <FormField label="VIN" name="vin" value={orderForm.vin} onChange={handleOrderChange} error={orderErrors.vin} required placeholder="Vehicle Identification Number" />
          <div className="grid grid-cols-3 gap-4">
            <FormField label="Model Year" name="modelYear" type="number" value={orderForm.modelYear} onChange={handleOrderChange} required />
            <FormField label="Make Code" name="makeCode" value={orderForm.makeCode} onChange={handleOrderChange} error={orderErrors.makeCode} required placeholder="e.g. TOY" />
            <FormField label="Model Code" name="modelCode" value={orderForm.modelCode} onChange={handleOrderChange} error={orderErrors.modelCode} required placeholder="e.g. CAM" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Plant Code" name="plantCode" value={orderForm.plantCode} onChange={handleOrderChange} error={orderErrors.plantCode} required placeholder="e.g. PLT01" />
            <FormField label="Build Date" name="buildDate" type="date" value={orderForm.buildDate} onChange={handleOrderChange} required />
          </div>
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setCreateOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">Create Order</button>
          </div>
        </form>
      </Modal>

      {/* Allocate Modal */}
      <Modal isOpen={allocateOpen} onClose={() => setAllocateOpen(false)} title="Allocate Order to Dealer">
        <form onSubmit={handleAllocateSubmit} className="space-y-4">
          <FormField
            label="Dealer"
            name="allocatedDealer"
            type="select"
            value={allocateForm.allocatedDealer}
            onChange={(e) => setAllocateForm((p) => ({ ...p, allocatedDealer: e.target.value }))}
            required
            options={dealers.map((d) => ({ value: d.dealerCode, label: `${d.dealerCode} - ${d.dealerName}` }))}
          />
          <FormField
            label="Priority"
            name="priority"
            type="select"
            value={allocateForm.priority}
            onChange={(e) => setAllocateForm((p) => ({ ...p, priority: e.target.value }))}
            options={[{ value: 'N', label: 'Normal' }, { value: 'H', label: 'High' }, { value: 'U', label: 'Urgent' }]}
          />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setAllocateOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">Allocate</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default ProductionOrdersPage;
