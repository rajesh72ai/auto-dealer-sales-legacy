import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Users, Phone, MapPin, Search } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getCustomers, searchCustomers, createCustomer, updateCustomer } from '@/api/customers';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { Customer, CustomerRequest } from '@/types/customer';
import type { Dealer } from '@/types/admin';

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

const CUSTOMER_TYPES = [
  { value: 'I', label: 'Individual' },
  { value: 'B', label: 'Business' },
  { value: 'F', label: 'Fleet' },
];

const SEARCH_TYPES = [
  { value: 'LN', label: 'Last Name' },
  { value: 'FN', label: 'First Name' },
  { value: 'PH', label: 'Phone' },
  { value: 'DL', label: "Driver's License" },
  { value: 'ID', label: 'Customer ID' },
];

const SOURCE_CODES = [
  { value: 'WLK', label: 'Walk-in' },
  { value: 'PHN', label: 'Phone' },
  { value: 'WEB', label: 'Website' },
  { value: 'REF', label: 'Referral' },
  { value: 'RPT', label: 'Repeat' },
  { value: 'ADV', label: 'Advertising' },
  { value: 'EVT', label: 'Event' },
];

const TYPE_BADGE_STYLES: Record<string, string> = {
  I: 'bg-blue-50 text-blue-700',
  B: 'bg-purple-50 text-purple-700',
  F: 'bg-amber-50 text-amber-700',
};

const TYPE_LABELS: Record<string, string> = {
  I: 'Individual',
  B: 'Business',
  F: 'Fleet',
};

const defaultForm: CustomerRequest = {
  firstName: '',
  lastName: '',
  middleInit: null,
  dateOfBirth: null,
  ssnLast4: null,
  driversLicense: null,
  dlState: null,
  addressLine1: '',
  addressLine2: null,
  city: '',
  stateCode: '',
  zipCode: '',
  homePhone: null,
  cellPhone: null,
  email: null,
  employerName: null,
  annualIncome: null,
  customerType: 'I',
  sourceCode: null,
  dealerCode: '',
  assignedSales: null,
};

function CustomersPage() {
  const { addToast } = useToast();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [items, setItems] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Filters
  const [dealerCode, setDealerCode] = useState(user?.dealerCode ?? '');
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [searchType, setSearchType] = useState('LN');
  const [searchValue, setSearchValue] = useState('');
  const [isSearching, setIsSearching] = useState(false);

  // Modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<Customer | null>(null);
  const [form, setForm] = useState<CustomerRequest>({ ...defaultForm, dealerCode: user?.dealerCode ?? '' });
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Load dealers for filter
  useEffect(() => {
    getDealers({ size: 100, active: 'Y' })
      .then((res) => setDealers(res.content))
      .catch(() => {});
  }, []);

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      if (isSearching && searchValue.trim()) {
        const result = await searchCustomers({
          type: searchType,
          value: searchValue.trim(),
          dealerCode,
          page,
          size: 20,
        });
        setItems(result.content);
        setTotalPages(result.totalPages);
        setTotalElements(result.totalElements);
      } else {
        const result = await getCustomers({ dealerCode, page, size: 20 });
        setItems(result.content);
        setTotalPages(result.totalPages);
        setTotalElements(result.totalElements);
      }
    } catch {
      addToast('error', 'Failed to load customers');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, page, isSearching, searchType, searchValue, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleSearch = () => {
    if (!searchValue.trim()) {
      setIsSearching(false);
      setPage(0);
      return;
    }
    setIsSearching(true);
    setPage(0);
  };

  const clearSearch = () => {
    setSearchValue('');
    setIsSearching(false);
    setPage(0);
  };

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.firstName.trim()) errs.firstName = 'First name is required';
    if (!form.lastName.trim()) errs.lastName = 'Last name is required';
    if (!form.addressLine1.trim()) errs.addressLine1 = 'Address is required';
    if (!form.city.trim()) errs.city = 'City is required';
    if (!form.stateCode) errs.stateCode = 'State is required';
    if (!form.zipCode.trim()) errs.zipCode = 'ZIP code is required';
    if (!form.customerType) errs.customerType = 'Customer type is required';
    if (!form.dealerCode) errs.dealerCode = 'Dealer is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updateCustomer(editing.customerId, form);
        addToast('success', 'Customer updated successfully');
      } else {
        await createCustomer(form);
        addToast('success', 'Customer created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: name === 'annualIncome' ? (value ? Number(value) : null) : value || null,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleChangeRequired = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm, dealerCode: dealerCode || user?.dealerCode || '' });
    setErrors({});
    setIsModalOpen(true);
  };



  const columns: Column<Customer>[] = [
    { key: 'customerId', header: 'ID', sortable: true },
    {
      key: 'fullName',
      header: 'Name',
      sortable: true,
      render: (row) => (
        <div>
          <span className="font-medium text-gray-900">{row.fullName}</span>
          {row.email && (
            <p className="text-xs text-gray-400">{row.email}</p>
          )}
        </div>
      ),
    },
    {
      key: 'homePhone',
      header: 'Phone',
      render: (row) => (
        <div className="flex items-center gap-1.5 text-gray-700">
          <Phone className="h-3.5 w-3.5 text-gray-400" />
          {row.formattedPhone || row.homePhone || '\u2014'}
        </div>
      ),
    },
    {
      key: 'city',
      header: 'City / State',
      render: (row) => (
        <div className="flex items-center gap-1.5 text-gray-700">
          <MapPin className="h-3.5 w-3.5 text-gray-400" />
          {row.city}, {row.stateCode}
        </div>
      ),
    },
    {
      key: 'customerType',
      header: 'Type',
      render: (row) => (
        <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${TYPE_BADGE_STYLES[row.customerType] || 'bg-gray-100 text-gray-700'}`}>
          {TYPE_LABELS[row.customerType] || row.customerType}
        </span>
      ),
    },
    {
      key: 'sourceCode',
      header: 'Source',
      render: (row) => {
        const src = SOURCE_CODES.find((s) => s.value === row.sourceCode);
        return <span className="text-gray-600">{src?.label || row.sourceCode || '\u2014'}</span>;
      },
    },
    {
      key: 'createdTs',
      header: 'Created',
      sortable: true,
      render: (row) => (
        <span className="text-gray-500 text-xs">
          {new Date(row.createdTs).toLocaleDateString()}
        </span>
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
              <Users className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Customers</h1>
              <p className="mt-0.5 text-sm text-gray-500">Manage customer records and contact information</p>
            </div>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Customer
        </button>
      </div>

      {/* Filters & Search */}
      <div className="flex flex-wrap items-end gap-3">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-500">Dealer</label>
          <select
            value={dealerCode}
            onChange={(e) => { setDealerCode(e.target.value); setPage(0); setIsSearching(false); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          >
            <option value="">Select Dealer</option>
            {dealers.map((d) => (
              <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
            ))}
          </select>
        </div>

        <div className="flex items-end gap-2">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-gray-500">Search By</label>
            <select
              value={searchType}
              onChange={(e) => setSearchType(e.target.value)}
              className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            >
              {SEARCH_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>
          <div className="relative">
            <label className="mb-1.5 block text-xs font-medium text-gray-500">Search Value</label>
            <input
              type="text"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') handleSearch(); }}
              placeholder="Type and press Enter..."
              className="w-56 rounded-lg border border-gray-300 px-3 py-2 pr-9 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
            <button
              onClick={handleSearch}
              className="absolute right-2 top-[calc(50%+10px)] -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <Search className="h-4 w-4" />
            </button>
          </div>
          {isSearching && (
            <button
              onClick={clearSearch}
              className="pb-2 text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
            >
              Clear search
            </button>
          )}
        </div>
      </div>

      {!dealerCode && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Please select a dealer to view customers.
        </div>
      )}

      {/* Table */}
      {dealerCode && (
        <DataTable
          columns={columns}
          data={items}
          loading={loading}
          page={page}
          totalPages={totalPages}
          totalElements={totalElements}
          onPageChange={setPage}
          onRowClick={(row) => navigate(`/customers/${row.customerId}`)}
        />
      )}

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editing ? 'Edit Customer' : 'New Customer'}
        size="xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Name Row */}
          <div className="grid grid-cols-5 gap-4">
            <div className="col-span-2">
              <FormField
                label="First Name"
                name="firstName"
                value={form.firstName}
                onChange={handleChangeRequired}
                error={errors.firstName}
                required
                placeholder="John"
              />
            </div>
            <div className="col-span-1">
              <FormField
                label="M.I."
                name="middleInit"
                value={form.middleInit ?? ''}
                onChange={handleChange}
                placeholder="A"
              />
            </div>
            <div className="col-span-2">
              <FormField
                label="Last Name"
                name="lastName"
                value={form.lastName}
                onChange={handleChangeRequired}
                error={errors.lastName}
                required
                placeholder="Smith"
              />
            </div>
          </div>

          {/* Contact */}
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Home Phone"
              name="homePhone"
              value={form.homePhone ?? ''}
              onChange={handleChange}
              placeholder="3125551234"
            />
            <FormField
              label="Cell Phone"
              name="cellPhone"
              value={form.cellPhone ?? ''}
              onChange={handleChange}
              placeholder="3125555678"
            />
            <FormField
              label="Email"
              name="email"
              value={form.email ?? ''}
              onChange={handleChange}
              placeholder="john@example.com"
            />
          </div>

          {/* Address */}
          <FormField
            label="Address Line 1"
            name="addressLine1"
            value={form.addressLine1}
            onChange={handleChangeRequired}
            error={errors.addressLine1}
            required
            placeholder="123 Main Street"
          />
          <FormField
            label="Address Line 2"
            name="addressLine2"
            value={form.addressLine2 ?? ''}
            onChange={handleChange}
            placeholder="Apt 4B"
          />
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="City"
              name="city"
              value={form.city}
              onChange={handleChangeRequired}
              error={errors.city}
              required
            />
            <FormField
              label="State"
              name="stateCode"
              type="select"
              value={form.stateCode}
              onChange={handleChangeRequired}
              error={errors.stateCode}
              required
              options={US_STATES}
            />
            <FormField
              label="ZIP Code"
              name="zipCode"
              value={form.zipCode}
              onChange={handleChangeRequired}
              error={errors.zipCode}
              required
              placeholder="60601"
            />
          </div>

          {/* Identity */}
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Date of Birth"
              name="dateOfBirth"
              type="date"
              value={form.dateOfBirth ?? ''}
              onChange={handleChange}
            />
            <FormField
              label="Driver's License"
              name="driversLicense"
              value={form.driversLicense ?? ''}
              onChange={handleChange}
              placeholder="D12345678"
            />
            <FormField
              label="DL State"
              name="dlState"
              type="select"
              value={form.dlState ?? ''}
              onChange={handleChange}
              options={US_STATES}
            />
          </div>

          {/* Classification */}
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">
                Customer Type <span className="ml-0.5 text-red-500">*</span>
              </label>
              <div className="flex gap-4 pt-2">
                {CUSTOMER_TYPES.map((ct) => (
                  <label key={ct.value} className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                    <input
                      type="radio"
                      name="customerType"
                      value={ct.value}
                      checked={form.customerType === ct.value}
                      onChange={handleChangeRequired}
                      className="h-4 w-4 border-gray-300 text-brand-600 focus:ring-brand-500"
                    />
                    {ct.label}
                  </label>
                ))}
              </div>
              {errors.customerType && <p className="mt-1 text-xs text-red-600">{errors.customerType}</p>}
            </div>
            <FormField
              label="Source"
              name="sourceCode"
              type="select"
              value={form.sourceCode ?? ''}
              onChange={handleChange}
              options={SOURCE_CODES}
            />
            <FormField
              label="SSN Last 4"
              name="ssnLast4"
              value={form.ssnLast4 ?? ''}
              onChange={handleChange}
              placeholder="1234"
            />
          </div>

          {/* Employment / Income */}
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Employer"
              name="employerName"
              value={form.employerName ?? ''}
              onChange={handleChange}
              placeholder="Acme Corp"
            />
            <FormField
              label="Annual Income"
              name="annualIncome"
              type="number"
              value={form.annualIncome ?? ''}
              onChange={handleChange}
              placeholder="75000"
            />
          </div>

          {/* Dealer / Sales */}
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Dealer Code"
              name="dealerCode"
              value={form.dealerCode}
              onChange={handleChangeRequired}
              error={errors.dealerCode}
              required
              disabled={!!editing}
            />
            <FormField
              label="Assigned Salesperson"
              name="assignedSales"
              value={form.assignedSales ?? ''}
              onChange={handleChange}
              placeholder="SLP001"
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
              {editing ? 'Update Customer' : 'Create Customer'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default CustomersPage;
