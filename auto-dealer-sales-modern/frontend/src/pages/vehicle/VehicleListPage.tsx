import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Car,
  Plus,
  Filter,
  AlertCircle,
  CheckCircle2,
  Wrench,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getVehicles, receiveVehicle } from '@/api/vehicles';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { VehicleListItem, VehicleReceiveRequest } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const VEHICLE_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  AV: { bg: 'bg-green-50', text: 'text-green-700', label: 'Available' },
  SD: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Sold' },
  HD: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'On Hold' },
  IT: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'In Transit' },
  PR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Production' },
  TR: { bg: 'bg-cyan-50', text: 'text-cyan-700', label: 'Transfer' },
  AL: { bg: 'bg-indigo-50', text: 'text-indigo-700', label: 'Allocated' },
  SV: { bg: 'bg-rose-50', text: 'text-rose-700', label: 'Service' },
};

const STATUS_OPTIONS = Object.entries(VEHICLE_STATUS_CONFIG).map(([value, cfg]) => ({
  value,
  label: cfg.label,
}));

const defaultReceiveForm: VehicleReceiveRequest & { vin: string } = {
  vin: '',
  lotLocation: '',
  stockNumber: '',
  odometer: undefined,
  damageFlag: 'N',
  damageDesc: '',
  keyNumber: '',
  inspectionNotes: '',
};

function VehicleListPage() {
  const { addToast } = useToast();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [items, setItems] = useState<VehicleListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [statusFilter, setStatusFilter] = useState('');
  const [colorFilter, setColorFilter] = useState('');
  const [yearFilter, setYearFilter] = useState('');

  const [receiveOpen, setReceiveOpen] = useState(false);
  const [receiveForm, setReceiveForm] = useState({ ...defaultReceiveForm });
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    getDealers({ page: 0, size: 200 }).then((r) => {
      setDealers(r.content);
      if (!dealerCode && r.content.length > 0) {
        setDealerCode(r.content[0].dealerCode);
      }
    }).catch(() => addToast('error', 'Failed to load dealers'));
  }, [addToast]); // eslint-disable-line react-hooks/exhaustive-deps

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      const result = await getVehicles({
        dealerCode,
        status: statusFilter || undefined,
        color: colorFilter || undefined,
        modelYear: yearFilter ? Number(yearFilter) : undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load vehicles');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusFilter, colorFilter, yearFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleReceiveChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setReceiveForm((prev) => ({
      ...prev,
      [name]: name === 'odometer' ? (value ? Number(value) : undefined) : value,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleReceiveSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!receiveForm.vin.trim()) errs.vin = 'VIN is required';
    if (!receiveForm.lotLocation.trim()) errs.lotLocation = 'Lot location is required';
    if (!receiveForm.stockNumber.trim()) errs.stockNumber = 'Stock number is required';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    try {
      const { vin, ...req } = receiveForm;
      await receiveVehicle(vin, req);
      addToast('success', 'Vehicle received into inventory');
      setReceiveOpen(false);
      setReceiveForm({ ...defaultReceiveForm });
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to receive vehicle');
    }
  };

  const columns: Column<VehicleListItem>[] = [
    { key: 'vin', header: 'VIN', sortable: true },
    { key: 'stockNumber', header: 'Stock #', sortable: true },
    { key: 'vehicleDesc', header: 'Vehicle', sortable: true },
    {
      key: 'vehicleStatus',
      header: 'Status',
      render: (row) => {
        const cfg = VEHICLE_STATUS_CONFIG[row.vehicleStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.statusName };
        return (
          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${cfg.bg} ${cfg.text}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${cfg.text.replace('text-', 'bg-')}`} />
            {cfg.label}
          </span>
        );
      },
    },
    { key: 'exteriorColor', header: 'Color' },
    {
      key: 'daysInStock',
      header: 'Days In Stock',
      sortable: true,
      render: (row) => (
        <span className={row.daysInStock > 90 ? 'font-semibold text-red-600' : row.daysInStock > 60 ? 'text-amber-600' : 'text-gray-700'}>
          {row.daysInStock}
        </span>
      ),
    },
    {
      key: 'pdiComplete',
      header: 'PDI',
      render: (row) =>
        row.pdiComplete === 'Y' ? (
          <CheckCircle2 className="h-4 w-4 text-green-500" />
        ) : (
          <Wrench className="h-4 w-4 text-amber-500" />
        ),
    },
    {
      key: 'damageFlag',
      header: 'Damage',
      render: (row) =>
        row.damageFlag === 'Y' ? (
          <AlertCircle className="h-4 w-4 text-red-500" />
        ) : (
          <span className="text-xs text-gray-400">None</span>
        ),
    },
  ];

  const hasFilters = statusFilter || colorFilter || yearFilter;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
            <Car className="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Vehicle Inventory</h1>
            <p className="mt-0.5 text-sm text-gray-500">Browse and manage dealer vehicle stock</p>
          </div>
        </div>
        <button
          onClick={() => { setReceiveForm({ ...defaultReceiveForm }); setErrors({}); setReceiveOpen(true); }}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Receive Vehicle
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-1.5 text-sm text-gray-500">
          <Filter className="h-4 w-4" />
          Filters
        </div>
        <select
          value={dealerCode}
          onChange={(e) => { setDealerCode(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          {dealers.map((d) => (
            <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
          ))}
        </select>
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <option value="">All Statuses</option>
          {STATUS_OPTIONS.map((s) => (
            <option key={s.value} value={s.value}>{s.label}</option>
          ))}
        </select>
        <input
          type="text"
          placeholder="Color..."
          value={colorFilter}
          onChange={(e) => { setColorFilter(e.target.value); setPage(0); }}
          className="w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        />
        <input
          type="number"
          placeholder="Model Year"
          value={yearFilter}
          onChange={(e) => { setYearFilter(e.target.value); setPage(0); }}
          className="w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        />
        {hasFilters && (
          <button
            onClick={() => { setStatusFilter(''); setColorFilter(''); setYearFilter(''); setPage(0); }}
            className="text-sm font-medium text-blue-600 transition-colors hover:text-blue-700"
          >
            Clear filters
          </button>
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
        onRowClick={(row) => navigate(`/vehicles/${row.vin}`)}
      />

      {/* Receive Vehicle Modal */}
      <Modal isOpen={receiveOpen} onClose={() => setReceiveOpen(false)} title="Receive Vehicle" size="lg">
        <form onSubmit={handleReceiveSubmit} className="space-y-4">
          <FormField label="VIN" name="vin" value={receiveForm.vin} onChange={handleReceiveChange} error={errors.vin} required placeholder="e.g. 1HGCM82633A004352" />
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Lot Location" name="lotLocation" value={receiveForm.lotLocation} onChange={handleReceiveChange} error={errors.lotLocation} required placeholder="LOT-A" />
            <FormField label="Stock Number" name="stockNumber" value={receiveForm.stockNumber} onChange={handleReceiveChange} error={errors.stockNumber} required placeholder="STK001" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Odometer" name="odometer" type="number" value={receiveForm.odometer ?? ''} onChange={handleReceiveChange} placeholder="0" />
            <FormField label="Key Number" name="keyNumber" value={receiveForm.keyNumber ?? ''} onChange={handleReceiveChange} placeholder="K-001" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Damage?"
              name="damageFlag"
              type="select"
              value={receiveForm.damageFlag ?? 'N'}
              onChange={handleReceiveChange}
              options={[{ value: 'N', label: 'No' }, { value: 'Y', label: 'Yes' }]}
            />
            <FormField label="Damage Description" name="damageDesc" value={receiveForm.damageDesc ?? ''} onChange={handleReceiveChange} placeholder="Describe damage..." />
          </div>
          <FormField label="Inspection Notes" name="inspectionNotes" value={receiveForm.inspectionNotes ?? ''} onChange={handleReceiveChange} placeholder="Additional inspection notes..." />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setReceiveOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700">Receive Vehicle</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default VehicleListPage;
