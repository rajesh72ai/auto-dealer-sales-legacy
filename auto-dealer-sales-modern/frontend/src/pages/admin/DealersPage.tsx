import { useState, useEffect, useCallback } from 'react';
import { Plus, Building2, Phone, MapPin } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import StatusBadge from '@/components/shared/StatusBadge';
import { getDealers, createDealer, updateDealer } from '@/api/dealers';
import type { Dealer, DealerRequest } from '@/types/admin';

const US_STATES = [
  { value: 'AL', label: 'Alabama' }, { value: 'AK', label: 'Alaska' }, { value: 'AZ', label: 'Arizona' },
  { value: 'AR', label: 'Arkansas' }, { value: 'CA', label: 'California' }, { value: 'CO', label: 'Colorado' },
  { value: 'CT', label: 'Connecticut' }, { value: 'DE', label: 'Delaware' }, { value: 'FL', label: 'Florida' },
  { value: 'GA', label: 'Georgia' }, { value: 'HI', label: 'Hawaii' }, { value: 'ID', label: 'Idaho' },
  { value: 'IL', label: 'Illinois' }, { value: 'IN', label: 'Indiana' }, { value: 'IA', label: 'Iowa' },
  { value: 'KS', label: 'Kansas' }, { value: 'KY', label: 'Kentucky' }, { value: 'LA', label: 'Louisiana' },
  { value: 'ME', label: 'Maine' }, { value: 'MD', label: 'Maryland' }, { value: 'MA', label: 'Massachusetts' },
  { value: 'MI', label: 'Michigan' }, { value: 'MN', label: 'Minnesota' }, { value: 'MS', label: 'Mississippi' },
  { value: 'MO', label: 'Missouri' }, { value: 'MT', label: 'Montana' }, { value: 'NE', label: 'Nebraska' },
  { value: 'NV', label: 'Nevada' }, { value: 'NH', label: 'New Hampshire' }, { value: 'NJ', label: 'New Jersey' },
  { value: 'NM', label: 'New Mexico' }, { value: 'NY', label: 'New York' }, { value: 'NC', label: 'North Carolina' },
  { value: 'ND', label: 'North Dakota' }, { value: 'OH', label: 'Ohio' }, { value: 'OK', label: 'Oklahoma' },
  { value: 'OR', label: 'Oregon' }, { value: 'PA', label: 'Pennsylvania' }, { value: 'RI', label: 'Rhode Island' },
  { value: 'SC', label: 'South Carolina' }, { value: 'SD', label: 'South Dakota' }, { value: 'TN', label: 'Tennessee' },
  { value: 'TX', label: 'Texas' }, { value: 'UT', label: 'Utah' }, { value: 'VT', label: 'Vermont' },
  { value: 'VA', label: 'Virginia' }, { value: 'WA', label: 'Washington' }, { value: 'WV', label: 'West Virginia' },
  { value: 'WI', label: 'Wisconsin' }, { value: 'WY', label: 'Wyoming' },
];

const REGIONS = [
  { value: 'NE', label: 'Northeast' },
  { value: 'SE', label: 'Southeast' },
  { value: 'MW', label: 'Midwest' },
  { value: 'SW', label: 'Southwest' },
  { value: 'WE', label: 'West' },
  { value: 'NW', label: 'Northwest' },
];

const ACTIVE_OPTIONS = [
  { value: 'Y', label: 'Active' },
  { value: 'N', label: 'Inactive' },
];

const defaultForm: DealerRequest = {
  dealerCode: '',
  dealerName: '',
  addressLine1: '',
  addressLine2: null,
  city: '',
  stateCode: '',
  zipCode: '',
  phoneNumber: '',
  faxNumber: null,
  dealerPrincipal: '',
  regionCode: '',
  zoneCode: '',
  oemDealerNum: '',
  floorPlanLenderId: null,
  maxInventory: 500,
  activeFlag: 'Y',
  openedDate: new Date().toISOString().split('T')[0],
};

function DealersPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<Dealer[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<Dealer | null>(null);
  const [form, setForm] = useState<DealerRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [regionFilter, setRegionFilter] = useState('');
  const [activeFilter, setActiveFilter] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getDealers({
        page,
        size: 20,
        region: regionFilter || undefined,
        active: activeFilter || undefined,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load dealers');
    } finally {
      setLoading(false);
    }
  }, [page, regionFilter, activeFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.dealerCode.trim()) errs.dealerCode = 'Dealer code is required';
    if (!form.dealerName.trim()) errs.dealerName = 'Dealer name is required';
    if (!form.city.trim()) errs.city = 'City is required';
    if (!form.stateCode) errs.stateCode = 'State is required';
    if (!form.zipCode.trim()) errs.zipCode = 'ZIP code is required';
    if (!form.phoneNumber.trim()) errs.phoneNumber = 'Phone is required';
    if (!form.regionCode) errs.regionCode = 'Region is required';
    if (!form.dealerPrincipal.trim()) errs.dealerPrincipal = 'Principal is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updateDealer(editing.dealerCode, form);
        addToast('success', 'Dealer updated successfully');
      } else {
        await createDealer(form);
        addToast('success', 'Dealer created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: name === 'maxInventory' ? Number(value) : value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (item: Dealer) => {
    setEditing(item);
    setForm({
      dealerCode: item.dealerCode,
      dealerName: item.dealerName,
      addressLine1: item.addressLine1,
      addressLine2: item.addressLine2,
      city: item.city,
      stateCode: item.stateCode,
      zipCode: item.zipCode,
      phoneNumber: item.phoneNumber,
      faxNumber: item.faxNumber,
      dealerPrincipal: item.dealerPrincipal,
      regionCode: item.regionCode,
      zoneCode: item.zoneCode,
      oemDealerNum: item.oemDealerNum,
      floorPlanLenderId: item.floorPlanLenderId,
      maxInventory: item.maxInventory,
      activeFlag: item.activeFlag,
      openedDate: item.openedDate,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const columns: Column<Dealer>[] = [
    { key: 'dealerCode', header: 'Code', sortable: true },
    { key: 'dealerName', header: 'Name', sortable: true },
    {
      key: 'city',
      header: 'Location',
      render: (row) => (
        <div className="flex items-center gap-1.5 text-gray-700">
          <MapPin className="h-3.5 w-3.5 text-gray-400" />
          {row.city}, {row.stateCode}
        </div>
      ),
    },
    {
      key: 'phoneNumber',
      header: 'Phone',
      render: (row) => (
        <div className="flex items-center gap-1.5 text-gray-700">
          <Phone className="h-3.5 w-3.5 text-gray-400" />
          {row.formattedPhone || row.phoneNumber}
        </div>
      ),
    },
    { key: 'regionCode', header: 'Region', sortable: true },
    {
      key: 'activeFlag',
      header: 'Status',
      render: (row) => (
        <StatusBadge status={row.activeFlag === 'Y' ? 'active' : 'inactive'} />
      ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50">
              <Building2 className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Dealers</h1>
              <p className="mt-0.5 text-sm text-gray-500">Manage dealership locations and contact information</p>
            </div>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Dealer
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={regionFilter}
          onChange={(e) => { setRegionFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Regions</option>
          {REGIONS.map((r) => (
            <option key={r.value} value={r.value}>{r.label}</option>
          ))}
        </select>
        <select
          value={activeFilter}
          onChange={(e) => { setActiveFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Status</option>
          <option value="Y">Active</option>
          <option value="N">Inactive</option>
        </select>
        {(regionFilter || activeFilter) && (
          <button
            onClick={() => { setRegionFilter(''); setActiveFilter(''); setPage(0); }}
            className="text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
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
        onRowClick={(row) => openEdit(row)}
      />

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editing ? 'Edit Dealer' : 'New Dealer'}
        size="xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Dealer Code"
              name="dealerCode"
              value={form.dealerCode}
              onChange={handleChange}
              error={errors.dealerCode}
              required
              disabled={!!editing}
              placeholder="e.g. DLR001"
            />
            <FormField
              label="Dealer Name"
              name="dealerName"
              value={form.dealerName}
              onChange={handleChange}
              error={errors.dealerName}
              required
              placeholder="ABC Motors"
            />
          </div>
          <FormField
            label="Address Line 1"
            name="addressLine1"
            value={form.addressLine1}
            onChange={handleChange}
            placeholder="123 Main Street"
          />
          <FormField
            label="Address Line 2"
            name="addressLine2"
            value={form.addressLine2 ?? ''}
            onChange={handleChange}
            placeholder="Suite 100"
          />
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="City"
              name="city"
              value={form.city}
              onChange={handleChange}
              error={errors.city}
              required
            />
            <FormField
              label="State"
              name="stateCode"
              type="select"
              value={form.stateCode}
              onChange={handleChange}
              error={errors.stateCode}
              required
              options={US_STATES}
            />
            <FormField
              label="ZIP Code"
              name="zipCode"
              value={form.zipCode}
              onChange={handleChange}
              error={errors.zipCode}
              required
              placeholder="60601"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Phone"
              name="phoneNumber"
              value={form.phoneNumber}
              onChange={handleChange}
              error={errors.phoneNumber}
              required
              placeholder="3125551234"
            />
            <FormField
              label="Fax"
              name="faxNumber"
              value={form.faxNumber ?? ''}
              onChange={handleChange}
              placeholder="3125551235"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Dealer Principal"
              name="dealerPrincipal"
              value={form.dealerPrincipal}
              onChange={handleChange}
              error={errors.dealerPrincipal}
              required
              placeholder="John Smith"
            />
            <FormField
              label="OEM Dealer Number"
              name="oemDealerNum"
              value={form.oemDealerNum}
              onChange={handleChange}
              placeholder="OEM12345"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Region"
              name="regionCode"
              type="select"
              value={form.regionCode}
              onChange={handleChange}
              error={errors.regionCode}
              required
              options={REGIONS}
            />
            <FormField
              label="Zone"
              name="zoneCode"
              value={form.zoneCode}
              onChange={handleChange}
              placeholder="Z01"
            />
            <FormField
              label="Max Inventory"
              name="maxInventory"
              type="number"
              value={form.maxInventory}
              onChange={handleChange}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Opened Date"
              name="openedDate"
              type="date"
              value={form.openedDate}
              onChange={handleChange}
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
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
            >
              {editing ? 'Update Dealer' : 'Create Dealer'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default DealersPage;
