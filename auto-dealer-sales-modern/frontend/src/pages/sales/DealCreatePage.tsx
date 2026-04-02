import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, ArrowRight, Check, Search, User, Car, FileCheck } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { searchCustomers } from '@/api/customers';
import { createDeal } from '@/api/deals';
import { useAuth } from '@/auth/useAuth';
import type { Customer } from '@/types/customer';
import type { CreateDealRequest } from '@/types/sales';

const DEAL_TYPES = [
  { value: 'N', label: 'New Vehicle', desc: 'Brand new from manufacturer' },
  { value: 'U', label: 'Used Vehicle', desc: 'Pre-owned vehicle' },
  { value: 'L', label: 'Lease', desc: 'Lease agreement' },
  { value: 'C', label: 'CPO', desc: 'Certified Pre-Owned' },
];

const STEPS = [
  { label: 'Customer', icon: User },
  { label: 'Vehicle', icon: Car },
  { label: 'Confirm', icon: FileCheck },
];

function DealCreatePage() {
  const navigate = useNavigate();
  const { addToast } = useToast();
  const { user } = useAuth();
  const dealerCode = user?.dealerCode ?? '';

  const [step, setStep] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  // Step 1: Customer
  const [customerSearch, setCustomerSearch] = useState('');
  const [customerResults, setCustomerResults] = useState<Customer[]>([]);
  const [searching, setSearching] = useState(false);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);

  // Step 2: Vehicle
  const [vin, setVin] = useState('');
  const [salespersonId, setSalespersonId] = useState(user?.userId ?? '');
  const [dealType, setDealType] = useState('N');

  // ── Customer Search ──────────────────────────────────────────

  const searchForCustomer = async () => {
    if (!customerSearch.trim() || !dealerCode) return;
    setSearching(true);
    try {
      const result = await searchCustomers({
        type: 'LN',
        value: customerSearch.trim(),
        dealerCode,
        page: 0,
        size: 10,
      });
      setCustomerResults(result.content);
      if (result.content.length === 0) {
        addToast('warning', 'No customers found. Try a different search.');
      }
    } catch {
      addToast('error', 'Customer search failed');
    } finally {
      setSearching(false);
    }
  };

  // ── Submit ───────────────────────────────────────────────────

  const handleCreate = async () => {
    if (!selectedCustomer || !vin.trim()) return;
    setSubmitting(true);
    try {
      const request: CreateDealRequest = {
        dealerCode,
        customerId: selectedCustomer.customerId,
        vin: vin.trim(),
        salespersonId,
        dealType,
      };
      const deal = await createDeal(request);
      addToast('success', `Deal ${deal.dealNumber} created successfully`);
      navigate(`/deals/${deal.dealNumber}`);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create deal');
    } finally {
      setSubmitting(false);
    }
  };

  const canAdvance = (): boolean => {
    if (step === 0) return selectedCustomer !== null;
    if (step === 1) return vin.trim().length > 0 && salespersonId.trim().length > 0;
    return true;
  };

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate('/deals')}
          className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-200 text-gray-500 hover:bg-gray-50"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">New Deal Worksheet</h1>
          <p className="mt-0.5 text-sm text-gray-500">Create a deal in 3 steps</p>
        </div>
      </div>

      {/* Step indicator */}
      <div className="flex items-center gap-2">
        {STEPS.map((s, idx) => {
          const Icon = s.icon;
          const active = idx === step;
          const done = idx < step;
          return (
            <div key={s.label} className="flex items-center gap-2">
              {idx > 0 && <div className={`h-px w-12 ${done ? 'bg-blue-500' : 'bg-gray-200'}`} />}
              <div className={`flex items-center gap-2 rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors ${
                active ? 'bg-blue-600 text-white' : done ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-500'
              }`}>
                {done ? <Check className="h-4 w-4" /> : <Icon className="h-4 w-4" />}
                {s.label}
              </div>
            </div>
          );
        })}
      </div>

      {/* Step content */}
      <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
        {/* ── Step 1: Select Customer ─────────────────────── */}
        {step === 0 && (
          <div className="p-6 space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Select Customer</h2>
            <p className="text-sm text-gray-500">Search for an existing customer by last name or phone number.</p>

            <div className="flex gap-2">
              <div className="relative flex-1">
                <input
                  type="text"
                  value={customerSearch}
                  onChange={(e) => setCustomerSearch(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') searchForCustomer(); }}
                  placeholder="Customer last name..."
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 pr-10 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                />
                <Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              </div>
              <button
                onClick={searchForCustomer}
                disabled={searching}
                className="rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200 disabled:opacity-50"
              >
                {searching ? 'Searching...' : 'Search'}
              </button>
            </div>

            {/* Results */}
            {customerResults.length > 0 && (
              <div className="space-y-1 max-h-64 overflow-y-auto">
                {customerResults.map((c) => (
                  <button
                    key={c.customerId}
                    onClick={() => setSelectedCustomer(c)}
                    className={`flex w-full items-center justify-between rounded-lg border px-4 py-3 text-left transition-colors ${
                      selectedCustomer?.customerId === c.customerId
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:bg-gray-50'
                    }`}
                  >
                    <div>
                      <p className="text-sm font-medium text-gray-900">{c.fullName}</p>
                      <p className="text-xs text-gray-500">ID: {c.customerId} &middot; {c.city}, {c.stateCode} &middot; {c.homePhone || c.cellPhone || 'No phone'}</p>
                    </div>
                    {selectedCustomer?.customerId === c.customerId && (
                      <Check className="h-5 w-5 text-blue-600" />
                    )}
                  </button>
                ))}
              </div>
            )}

            {selectedCustomer && (
              <div className="rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-800">
                <Check className="mr-1 inline h-4 w-4" /> Selected: <strong>{selectedCustomer.fullName}</strong> (ID: {selectedCustomer.customerId})
              </div>
            )}
          </div>
        )}

        {/* ── Step 2: Select Vehicle ──────────────────────── */}
        {step === 1 && (
          <div className="p-6 space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Vehicle & Deal Info</h2>
            <p className="text-sm text-gray-500">Enter the vehicle VIN and deal details.</p>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Vehicle VIN <span className="text-red-500">*</span></label>
              <input
                type="text"
                value={vin}
                onChange={(e) => setVin(e.target.value.toUpperCase())}
                placeholder="Enter 17-character VIN"
                maxLength={17}
                className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-gray-700">Salesperson ID <span className="text-red-500">*</span></label>
              <input
                type="text"
                value={salespersonId}
                onChange={(e) => setSalespersonId(e.target.value)}
                placeholder="SLP001"
                className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-gray-700">Deal Type <span className="text-red-500">*</span></label>
              <div className="grid grid-cols-2 gap-3">
                {DEAL_TYPES.map((dt) => (
                  <button
                    key={dt.value}
                    type="button"
                    onClick={() => setDealType(dt.value)}
                    className={`rounded-lg border px-4 py-3 text-left transition-colors ${
                      dealType === dt.value
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:bg-gray-50'
                    }`}
                  >
                    <p className="text-sm font-medium text-gray-900">{dt.label}</p>
                    <p className="text-xs text-gray-500">{dt.desc}</p>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ── Step 3: Confirm ─────────────────────────────── */}
        {step === 2 && (
          <div className="p-6 space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Confirm & Create</h2>
            <p className="text-sm text-gray-500">Review the deal details before creating the worksheet.</p>

            <div className="rounded-lg border border-gray-200 divide-y divide-gray-100">
              <ConfirmRow label="Customer" value={selectedCustomer?.fullName || ''} sub={`ID: ${selectedCustomer?.customerId}`} />
              <ConfirmRow label="Vehicle VIN" value={vin} mono />
              <ConfirmRow label="Salesperson" value={salespersonId} />
              <ConfirmRow label="Deal Type" value={DEAL_TYPES.find((d) => d.value === dealType)?.label || dealType} />
              <ConfirmRow label="Dealer" value={dealerCode} />
            </div>
          </div>
        )}

        {/* Navigation buttons */}
        <div className="flex items-center justify-between border-t border-gray-200 px-6 py-4">
          <button
            onClick={() => step > 0 ? setStep(step - 1) : navigate('/deals')}
            className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            <ArrowLeft className="h-4 w-4" />
            {step === 0 ? 'Cancel' : 'Back'}
          </button>

          {step < 2 ? (
            <button
              onClick={() => setStep(step + 1)}
              disabled={!canAdvance()}
              className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
            >
              Next
              <ArrowRight className="h-4 w-4" />
            </button>
          ) : (
            <button
              onClick={handleCreate}
              disabled={submitting}
              className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-blue-700 disabled:opacity-50"
            >
              {submitting ? 'Creating...' : 'Create Deal Worksheet'}
              <Check className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function ConfirmRow({ label, value, sub, mono }: { label: string; value: string; sub?: string; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between px-4 py-3">
      <span className="text-sm text-gray-500">{label}</span>
      <div className="text-right">
        <span className={`text-sm font-medium text-gray-900 ${mono ? 'font-mono' : ''}`}>{value}</span>
        {sub && <p className="text-xs text-gray-400">{sub}</p>}
      </div>
    </div>
  );
}

export default DealCreatePage;
