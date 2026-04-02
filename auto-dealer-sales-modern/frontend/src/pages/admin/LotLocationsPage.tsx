import { useState, useEffect, useCallback } from 'react';
import { Plus, MapPin, Warehouse } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import StatusBadge from '@/components/shared/StatusBadge';
import { getLotLocations, createLotLocation, updateLotLocation } from '@/api/lotLocations';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { LotLocation, LotLocationRequest } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const LOCATION_TYPES = [
  { value: 'L', label: 'Lot' },
  { value: 'S', label: 'Showroom' },
  { value: 'V', label: 'Service' },
  { value: 'O', label: 'Overflow' },
];

const TYPE_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  L: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Lot' },
  S: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'Showroom' },
  V: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Service' },
  O: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Overflow' },
};

const ACTIVE_OPTIONS = [
  { value: 'Y', label: 'Active' },
  { value: 'N', label: 'Inactive' },
];

const defaultForm: LotLocationRequest = {
  dealerCode: '',
  locationCode: '',
  locationDesc: '',
  locationType: 'L',
  maxCapacity: 50,
  activeFlag: 'Y',
};

function LotLocationsPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [items, setItems] = useState<LotLocation[]>([]);
  const [loading, setLoading] = useState(true);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<LotLocation | null>(null);
  const [form, setForm] = useState<LotLocationRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});

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
      const data = await getLotLocations(dealerCode);
      setItems(data);
    } catch {
      addToast('error', 'Failed to load lot locations');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.locationCode.trim()) errs.locationCode = 'Code is required';
    if (!form.locationDesc.trim()) errs.locationDesc = 'Description is required';
    if (!form.maxCapacity || form.maxCapacity <= 0) errs.maxCapacity = 'Capacity must be positive';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      const request = { ...form, dealerCode };
      if (editing) {
        await updateLotLocation(editing.dealerCode, editing.locationCode, request);
        addToast('success', 'Location updated successfully');
      } else {
        await createLotLocation(request);
        addToast('success', 'Location created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: name === 'maxCapacity' ? Number(value) : value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm, dealerCode });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (item: LotLocation) => {
    setEditing(item);
    setForm({
      dealerCode: item.dealerCode,
      locationCode: item.locationCode,
      locationDesc: item.locationDesc,
      locationType: item.locationType,
      maxCapacity: item.maxCapacity,
      activeFlag: item.activeFlag,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const columns: Column<LotLocation>[] = [
    { key: 'locationCode', header: 'Code', sortable: true },
    { key: 'locationDesc', header: 'Description', sortable: true },
    {
      key: 'locationType',
      header: 'Type',
      render: (row) => {
        const cfg = TYPE_BADGE[row.locationType] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.locationType };
        return (
          <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${cfg.bg} ${cfg.text}`}>{cfg.label}</span>
        );
      },
    },
    { key: 'maxCapacity', header: 'Max Capacity', sortable: true },
    { key: 'currentCount', header: 'Current', sortable: true },
    {
      key: 'availableSpots',
      header: 'Available',
      render: (row) => (
        <span className={`font-medium ${row.availableSpots <= 2 ? 'text-red-600' : row.availableSpots <= 5 ? 'text-amber-600' : 'text-green-600'}`}>{row.availableSpots}</span>
      ),
    },
    {
      key: 'utilizationPct',
      header: 'Utilization',
      render: (row) => {
        const pct = row.utilizationPct;
        return (
          <div className="flex items-center gap-2">
            <div className="h-2 w-16 overflow-hidden rounded-full bg-gray-200">
              <div
                className={`h-full rounded-full transition-all ${pct >= 90 ? 'bg-red-500' : pct >= 70 ? 'bg-amber-500' : 'bg-green-500'}`}
                style={{ width: `${Math.min(pct, 100)}%` }}
              />
            </div>
            <span className="text-xs font-medium text-gray-600">{pct.toFixed(0)}%</span>
          </div>
        );
      },
    },
    {
      key: 'activeFlag',
      header: 'Active',
      render: (row) => <StatusBadge status={row.activeFlag === 'Y' ? 'active' : 'inactive'} />,
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50">
            <Warehouse className="h-5 w-5 text-violet-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Lot Locations</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage dealer lot, showroom, and service locations</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Location
        </button>
      </div>

      {/* Dealer Selector */}
      <div className="flex items-center gap-3">
        <MapPin className="h-4 w-4 text-gray-400" />
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

      {/* Table */}
      <DataTable
        columns={columns}
        data={items}
        loading={loading}
        page={0}
        totalPages={1}
        totalElements={items.length}
        onPageChange={() => {}}
        onRowClick={openEdit}
      />

      {/* Create/Edit Modal */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editing ? 'Edit Location' : 'New Location'} size="lg">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Location Code"
              name="locationCode"
              value={form.locationCode}
              onChange={handleChange}
              error={errors.locationCode}
              required
              disabled={!!editing}
              placeholder="e.g. LOT-A"
            />
            <FormField
              label="Description"
              name="locationDesc"
              value={form.locationDesc}
              onChange={handleChange}
              error={errors.locationDesc}
              required
              placeholder="Main Lot"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Type"
              name="locationType"
              type="select"
              value={form.locationType}
              onChange={handleChange}
              options={LOCATION_TYPES}
            />
            <FormField
              label="Max Capacity"
              name="maxCapacity"
              type="number"
              value={form.maxCapacity}
              onChange={handleChange}
              error={errors.maxCapacity}
              required
            />
            <FormField
              label="Status"
              name="activeFlag"
              type="select"
              value={form.activeFlag}
              onChange={handleChange}
              options={ACTIVE_OPTIONS}
            />
          </div>
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setIsModalOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700">{editing ? 'Update Location' : 'Create Location'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default LotLocationsPage;
