import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft, User, History, CreditCard, Target, Phone, Mail, MapPin,
  Building2, Calendar, Edit2, DollarSign, TrendingUp, Award,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getCustomer, updateCustomer, getCustomerHistory } from '@/api/customers';
import { getCreditChecksByCustomer, runCreditCheck } from '@/api/creditChecks';
import { getLeads, createLead, updateLeadStatus } from '@/api/leads';
import type { Customer, CustomerRequest, CustomerHistory, CreditCheckResponse, Lead, LeadRequest } from '@/types/customer';

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

const CUSTOMER_TYPES: Record<string, string> = { I: 'Individual', B: 'Business', F: 'Fleet' };

const TIER_STYLES: Record<string, { bg: string; text: string; label: string }> = {
  A: { bg: 'bg-emerald-100', text: 'text-emerald-800', label: 'Excellent' },
  B: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Good' },
  C: { bg: 'bg-amber-100', text: 'text-amber-800', label: 'Fair' },
  D: { bg: 'bg-orange-100', text: 'text-orange-800', label: 'Poor' },
  E: { bg: 'bg-red-100', text: 'text-red-800', label: 'Very Poor' },
};

const LEAD_STATUS_STYLES: Record<string, { bg: string; text: string; label: string }> = {
  NW: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'New' },
  CT: { bg: 'bg-cyan-100', text: 'text-cyan-800', label: 'Contacted' },
  QF: { bg: 'bg-purple-100', text: 'text-purple-800', label: 'Qualified' },
  PR: { bg: 'bg-green-100', text: 'text-green-800', label: 'Proposal' },
  WN: { bg: 'bg-emerald-100', text: 'text-emerald-800', label: 'Won' },
  LS: { bg: 'bg-red-100', text: 'text-red-800', label: 'Lost' },
  DD: { bg: 'bg-gray-100', text: 'text-gray-600', label: 'Dead' },
};

const LEAD_STATUSES = Object.entries(LEAD_STATUS_STYLES).map(([value, s]) => ({ value, label: s.label }));

const LEAD_SOURCES = [
  { value: 'WLK', label: 'Walk-in' }, { value: 'PHN', label: 'Phone' }, { value: 'WEB', label: 'Website' },
  { value: 'REF', label: 'Referral' }, { value: 'ADV', label: 'Advertising' }, { value: 'EVT', label: 'Event' },
];

type TabKey = 'info' | 'history' | 'credit' | 'leads';

function ScoreGauge({ score }: { score: number }) {
  const maxScore = 850;
  const minScore = 300;
  const pct = Math.max(0, Math.min(1, (score - minScore) / (maxScore - minScore)));
  const angle = -90 + pct * 180;
  const color = score >= 750 ? '#10b981' : score >= 670 ? '#3b82f6' : score >= 580 ? '#f59e0b' : score >= 500 ? '#f97316' : '#ef4444';

  return (
    <div className="relative mx-auto h-32 w-56">
      <svg viewBox="0 0 200 110" className="w-full">
        {/* Background arc */}
        <path
          d="M 20 100 A 80 80 0 0 1 180 100"
          fill="none"
          stroke="#e5e7eb"
          strokeWidth="16"
          strokeLinecap="round"
        />
        {/* Colored arc */}
        <path
          d="M 20 100 A 80 80 0 0 1 180 100"
          fill="none"
          stroke={color}
          strokeWidth="16"
          strokeLinecap="round"
          strokeDasharray={`${pct * 251.2} 251.2`}
        />
        {/* Needle */}
        <g transform={`rotate(${angle}, 100, 100)`}>
          <line x1="100" y1="100" x2="100" y2="30" stroke="#374151" strokeWidth="2.5" strokeLinecap="round" />
          <circle cx="100" cy="100" r="5" fill="#374151" />
        </g>
        {/* Score text */}
        <text x="100" y="92" textAnchor="middle" className="text-3xl font-bold" fill="#111827" fontSize="28">
          {score}
        </text>
      </svg>
      <div className="flex justify-between px-2 text-xs text-gray-400">
        <span>300</span>
        <span>850</span>
      </div>
    </div>
  );
}

function CustomerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();

  const [customer, setCustomer] = useState<Customer | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabKey>('info');

  // History tab
  const [history, setHistory] = useState<CustomerHistory | null>(null);
  const [historyLoading, setHistoryLoading] = useState(false);

  // Credit tab
  const [creditChecks, setCreditChecks] = useState<CreditCheckResponse[]>([]);
  const [creditLoading, setCreditLoading] = useState(false);
  const [monthlyDebt, setMonthlyDebt] = useState('');
  const [runningCheck, setRunningCheck] = useState(false);

  // Leads tab
  const [leads, setLeads] = useState<Lead[]>([]);
  const [leadsLoading, setLeadsLoading] = useState(false);
  const [showLeadModal, setShowLeadModal] = useState(false);
  const [leadForm, setLeadForm] = useState<LeadRequest>({
    customerId: Number(id),
    dealerCode: '',
    leadSource: '',
    interestModel: '',
    interestYear: undefined,
    assignedSales: '',
    followUpDate: '',
    notes: '',
  });

  // Edit modal
  const [showEditModal, setShowEditModal] = useState(false);
  const [editForm, setEditForm] = useState<CustomerRequest | null>(null);
  const [editErrors, setEditErrors] = useState<Record<string, string>>({});

  const customerId = Number(id);

  const loadCustomer = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getCustomer(customerId);
      setCustomer(data);
    } catch {
      addToast('error', 'Failed to load customer');
    } finally {
      setLoading(false);
    }
  }, [customerId, addToast]);

  useEffect(() => { loadCustomer(); }, [loadCustomer]);

  const loadHistory = useCallback(async () => {
    setHistoryLoading(true);
    try {
      const data = await getCustomerHistory(customerId);
      setHistory(data);
    } catch {
      addToast('error', 'Failed to load customer history');
    } finally {
      setHistoryLoading(false);
    }
  }, [customerId, addToast]);

  const loadCreditChecks = useCallback(async () => {
    setCreditLoading(true);
    try {
      const data = await getCreditChecksByCustomer(customerId);
      setCreditChecks(data);
    } catch {
      addToast('error', 'Failed to load credit checks');
    } finally {
      setCreditLoading(false);
    }
  }, [customerId, addToast]);

  const loadLeads = useCallback(async () => {
    if (!customer) return;
    setLeadsLoading(true);
    try {
      const res = await getLeads({ dealerCode: customer.dealerCode, page: 0, size: 100 });
      setLeads(res.content.filter((l) => l.customerId === customerId));
    } catch {
      addToast('error', 'Failed to load leads');
    } finally {
      setLeadsLoading(false);
    }
  }, [customerId, customer, addToast]);

  useEffect(() => {
    if (activeTab === 'history' && !history) loadHistory();
    if (activeTab === 'credit' && creditChecks.length === 0) loadCreditChecks();
    if (activeTab === 'leads' && leads.length === 0 && customer) loadLeads();
  }, [activeTab, history, creditChecks.length, leads.length, customer, loadHistory, loadCreditChecks, loadLeads]);

  const handleRunCreditCheck = async () => {
    setRunningCheck(true);
    try {
      const result = await runCreditCheck({
        customerId,
        monthlyDebt: monthlyDebt ? Number(monthlyDebt) : undefined,
      });
      setCreditChecks((prev) => [result, ...prev]);
      setMonthlyDebt('');
      addToast('success', 'Credit check completed');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Credit check failed');
    } finally {
      setRunningCheck(false);
    }
  };

  const handleLeadStatusChange = async (leadId: number, newStatus: string) => {
    try {
      await updateLeadStatus(leadId, newStatus);
      setLeads((prev) => prev.map((l) => l.leadId === leadId ? { ...l, leadStatus: newStatus } : l));
      addToast('success', 'Lead status updated');
    } catch {
      addToast('error', 'Failed to update lead status');
    }
  };

  const handleCreateLead = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const created = await createLead({ ...leadForm, customerId });
      setLeads((prev) => [created, ...prev]);
      setShowLeadModal(false);
      addToast('success', 'Lead created');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create lead');
    }
  };

  const openEdit = () => {
    if (!customer) return;
    setEditForm({
      firstName: customer.firstName,
      lastName: customer.lastName,
      middleInit: customer.middleInit,
      dateOfBirth: customer.dateOfBirth,
      ssnLast4: customer.ssnLast4,
      driversLicense: customer.driversLicense,
      dlState: customer.dlState,
      addressLine1: customer.addressLine1,
      addressLine2: customer.addressLine2,
      city: customer.city,
      stateCode: customer.stateCode,
      zipCode: customer.zipCode,
      homePhone: customer.homePhone,
      cellPhone: customer.cellPhone,
      email: customer.email,
      employerName: customer.employerName,
      annualIncome: customer.annualIncome,
      customerType: customer.customerType,
      sourceCode: customer.sourceCode,
      dealerCode: customer.dealerCode,
      assignedSales: customer.assignedSales,
    });
    setEditErrors({});
    setShowEditModal(true);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editForm) return;
    const errs: Record<string, string> = {};
    if (!editForm.firstName.trim()) errs.firstName = 'Required';
    if (!editForm.lastName.trim()) errs.lastName = 'Required';
    if (!editForm.city.trim()) errs.city = 'Required';
    if (!editForm.stateCode) errs.stateCode = 'Required';
    if (!editForm.zipCode.trim()) errs.zipCode = 'Required';
    if (Object.keys(errs).length > 0) { setEditErrors(errs); return; }
    try {
      const updated = await updateCustomer(customerId, editForm);
      setCustomer(updated);
      setShowEditModal(false);
      addToast('success', 'Customer updated');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Update failed');
    }
  };

  const handleEditChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setEditForm((prev) => prev ? { ...prev, [name]: name === 'annualIncome' ? (value ? Number(value) : null) : value || null } : prev);
    if (editErrors[name]) setEditErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleEditChangeRequired = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setEditForm((prev) => prev ? { ...prev, [name]: value } : prev);
    if (editErrors[name]) setEditErrors((prev) => ({ ...prev, [name]: '' }));
  };

  if (loading) {
    return (
      <div className="mx-auto max-w-5xl">
        <div className="animate-pulse space-y-4">
          <div className="h-8 w-48 rounded bg-gray-200" />
          <div className="h-64 rounded-xl bg-gray-200" />
        </div>
      </div>
    );
  }

  if (!customer) {
    return (
      <div className="mx-auto max-w-5xl text-center py-20">
        <p className="text-gray-500">Customer not found.</p>
        <button onClick={() => navigate('/customers')} className="mt-4 text-brand-600 hover:text-brand-700 font-medium text-sm">
          Back to Customers
        </button>
      </div>
    );
  }

  const tabs: { key: TabKey; label: string; icon: React.ReactNode }[] = [
    { key: 'info', label: 'Info', icon: <User className="h-4 w-4" /> },
    { key: 'history', label: 'History', icon: <History className="h-4 w-4" /> },
    { key: 'credit', label: 'Credit', icon: <CreditCard className="h-4 w-4" /> },
    { key: 'leads', label: 'Leads', icon: <Target className="h-4 w-4" /> },
  ];

  const latestCredit = creditChecks[0] ?? null;

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate('/customers')}
          className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-300 text-gray-500 transition-colors hover:bg-gray-50 hover:text-gray-700"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">{customer.fullName}</h1>
          <p className="text-sm text-gray-500">
            ID: {customer.customerId} &middot; {CUSTOMER_TYPES[customer.customerType] || customer.customerType} &middot; Dealer: {customer.dealerCode}
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="flex gap-6">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`flex items-center gap-2 border-b-2 px-1 py-3 text-sm font-medium transition-colors ${
                activeTab === tab.key
                  ? 'border-brand-600 text-brand-600'
                  : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
              }`}
            >
              {tab.icon}
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'info' && (
        <div className="space-y-6">
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4">
              <h3 className="text-base font-semibold text-gray-900">Customer Information</h3>
              <button
                onClick={openEdit}
                className="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
              >
                <Edit2 className="h-3.5 w-3.5" />
                Edit
              </button>
            </div>
            <div className="grid grid-cols-2 gap-x-8 gap-y-5 p-6">
              <InfoRow icon={<User className="h-4 w-4" />} label="Full Name" value={customer.fullName} />
              <InfoRow icon={<Calendar className="h-4 w-4" />} label="Date of Birth" value={customer.dateOfBirth ?? '\u2014'} />
              <InfoRow icon={<Phone className="h-4 w-4" />} label="Home Phone" value={customer.formattedPhone || customer.homePhone || '\u2014'} />
              <InfoRow icon={<Phone className="h-4 w-4" />} label="Cell Phone" value={customer.formattedCellPhone || customer.cellPhone || '\u2014'} />
              <InfoRow icon={<Mail className="h-4 w-4" />} label="Email" value={customer.email || '\u2014'} />
              <InfoRow icon={<MapPin className="h-4 w-4" />} label="Address" value={`${customer.addressLine1}${customer.addressLine2 ? ', ' + customer.addressLine2 : ''}, ${customer.city}, ${customer.stateCode} ${customer.zipCode}`} />
              <InfoRow icon={<Building2 className="h-4 w-4" />} label="Employer" value={customer.employerName || '\u2014'} />
              <InfoRow icon={<DollarSign className="h-4 w-4" />} label="Annual Income" value={customer.annualIncome != null ? `$${customer.annualIncome.toLocaleString()}` : '\u2014'} />
              <InfoRow label="Driver's License" value={customer.driversLicense ? `${customer.driversLicense} (${customer.dlState})` : '\u2014'} />
              <InfoRow label="Assigned Sales" value={customer.assignedSales || '\u2014'} />
              <InfoRow label="Source" value={customer.sourceCode || '\u2014'} />
              <InfoRow label="Created" value={new Date(customer.createdTs).toLocaleString()} />
            </div>
          </div>
        </div>
      )}

      {activeTab === 'history' && (
        <div className="space-y-6">
          {historyLoading ? (
            <div className="animate-pulse space-y-4">
              <div className="h-24 rounded-xl bg-gray-200" />
              <div className="h-48 rounded-xl bg-gray-200" />
            </div>
          ) : history ? (
            <>
              {/* Summary Cards */}
              <div className="grid grid-cols-4 gap-4">
                <SummaryCard icon={<TrendingUp />} label="Total Purchases" value={String(history.totalPurchases)} color="blue" />
                <SummaryCard icon={<DollarSign />} label="Total Spent" value={`$${history.totalSpent.toLocaleString()}`} color="emerald" />
                <SummaryCard icon={<DollarSign />} label="Avg. Deal" value={`$${history.averageDeal.toLocaleString()}`} color="purple" />
                <SummaryCard icon={<Award />} label="Status" value={history.repeatStatus} color={history.repeatStatus === 'Repeat' ? 'amber' : 'gray'} />
              </div>

              {/* Deal List */}
              <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
                <div className="border-b border-gray-100 px-6 py-4">
                  <h3 className="text-base font-semibold text-gray-900">Purchase History</h3>
                </div>
                {history.deals.length === 0 ? (
                  <p className="px-6 py-8 text-center text-gray-400">No purchase history found.</p>
                ) : (
                  <table className="w-full text-left text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 bg-gray-50">
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Deal #</th>
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Date</th>
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">VIN</th>
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Vehicle</th>
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Type</th>
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Sale Price</th>
                        <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Trade</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {history.deals.map((deal) => (
                        <tr key={deal.dealNumber} className="hover:bg-gray-50">
                          <td className="px-4 py-3 font-medium text-gray-900">{deal.dealNumber}</td>
                          <td className="px-4 py-3 text-gray-700">{new Date(deal.dealDate).toLocaleDateString()}</td>
                          <td className="px-4 py-3 font-mono text-xs text-gray-600">{deal.vin}</td>
                          <td className="px-4 py-3 text-gray-700">{deal.yearMakeModel}</td>
                          <td className="px-4 py-3"><span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">{deal.dealType}</span></td>
                          <td className="px-4 py-3 text-right font-medium text-gray-900">${deal.salePrice.toLocaleString()}</td>
                          <td className="px-4 py-3 text-right text-gray-600">${deal.tradeAllow.toLocaleString()}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </>
          ) : (
            <p className="py-12 text-center text-gray-400">No history data available.</p>
          )}
        </div>
      )}

      {activeTab === 'credit' && (
        <div className="space-y-6">
          {/* Run New Check */}
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="border-b border-gray-100 px-6 py-4">
              <h3 className="text-base font-semibold text-gray-900">Run Credit Pre-Qualification</h3>
            </div>
            <div className="flex items-end gap-4 p-6">
              <div className="flex-1 max-w-xs">
                <label className="mb-1.5 block text-sm font-medium text-gray-700">Monthly Debt Obligations</label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">$</span>
                  <input
                    type="number"
                    value={monthlyDebt}
                    onChange={(e) => setMonthlyDebt(e.target.value)}
                    placeholder="0.00"
                    className="block w-full rounded-lg border border-gray-300 pl-7 pr-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                  />
                </div>
              </div>
              <button
                onClick={handleRunCreditCheck}
                disabled={runningCheck}
                className="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-brand-700 disabled:opacity-50"
              >
                <CreditCard className="h-4 w-4" />
                {runningCheck ? 'Processing...' : 'Run Credit Check'}
              </button>
            </div>
          </div>

          {/* Latest Result */}
          {latestCredit && (
            <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
              <div className="border-b border-gray-100 px-6 py-4">
                <h3 className="text-base font-semibold text-gray-900">Latest Credit Result</h3>
              </div>
              <div className="p-6">
                <div className="flex flex-col items-center gap-6 md:flex-row">
                  {/* Score Gauge */}
                  <div className="flex-shrink-0">
                    <ScoreGauge score={latestCredit.creditScore} />
                  </div>

                  {/* Result Details */}
                  <div className="flex-1 grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs font-medium text-gray-500 uppercase">Credit Tier</p>
                      <span className={`mt-1 inline-flex rounded-full px-3 py-1 text-sm font-semibold ${TIER_STYLES[latestCredit.creditTier]?.bg || 'bg-gray-100'} ${TIER_STYLES[latestCredit.creditTier]?.text || 'text-gray-700'}`}>
                        {latestCredit.creditTierDesc || latestCredit.creditTier}
                      </span>
                    </div>
                    <div>
                      <p className="text-xs font-medium text-gray-500 uppercase">Max Financing</p>
                      <p className="mt-1 text-xl font-bold text-gray-900">${latestCredit.maxFinancing.toLocaleString()}</p>
                    </div>
                    <div>
                      <p className="text-xs font-medium text-gray-500 uppercase">DTI Ratio</p>
                      <p className="mt-1 text-lg font-semibold text-gray-900">{latestCredit.dtiRatio}%</p>
                    </div>
                    <div>
                      <p className="text-xs font-medium text-gray-500 uppercase">Monthly Income</p>
                      <p className="mt-1 text-lg font-semibold text-gray-900">${latestCredit.monthlyIncome.toLocaleString()}</p>
                    </div>
                    <div>
                      <p className="text-xs font-medium text-gray-500 uppercase">Bureau</p>
                      <p className="mt-1 text-sm font-medium text-gray-700">{latestCredit.bureauCode}</p>
                    </div>
                    <div>
                      <p className="text-xs font-medium text-gray-500 uppercase">Expires</p>
                      <p className="mt-1 text-sm font-medium text-gray-700">{new Date(latestCredit.expiryDate).toLocaleDateString()}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Credit Check History */}
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="border-b border-gray-100 px-6 py-4">
              <h3 className="text-base font-semibold text-gray-900">Credit Check History</h3>
            </div>
            {creditLoading ? (
              <div className="animate-pulse p-6 space-y-3">
                <div className="h-8 rounded bg-gray-200" />
                <div className="h-8 rounded bg-gray-200" />
              </div>
            ) : creditChecks.length === 0 ? (
              <p className="px-6 py-8 text-center text-gray-400">No credit checks on file.</p>
            ) : (
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">ID</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Score</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Tier</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Bureau</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">DTI</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Max Financing</th>
                    <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Expires</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {creditChecks.map((cc) => (
                    <tr key={cc.creditId} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-gray-600">{cc.creditId}</td>
                      <td className="px-4 py-3 font-semibold text-gray-900">{cc.creditScore}</td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${TIER_STYLES[cc.creditTier]?.bg || 'bg-gray-100'} ${TIER_STYLES[cc.creditTier]?.text || 'text-gray-700'}`}>
                          {cc.creditTierDesc || cc.creditTier}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-600">{cc.bureauCode}</td>
                      <td className="px-4 py-3 text-gray-600">{cc.dtiRatio}%</td>
                      <td className="px-4 py-3 text-right font-medium text-gray-900">${cc.maxFinancing.toLocaleString()}</td>
                      <td className="px-4 py-3 text-gray-500 text-xs">{new Date(cc.expiryDate).toLocaleDateString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {activeTab === 'leads' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-base font-semibold text-gray-900">Customer Leads</h3>
            <button
              onClick={() => {
                setLeadForm({
                  customerId,
                  dealerCode: customer.dealerCode,
                  leadSource: '',
                  interestModel: '',
                  interestYear: undefined,
                  assignedSales: '',
                  followUpDate: '',
                  notes: '',
                });
                setShowLeadModal(true);
              }}
              className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
            >
              <Target className="h-4 w-4" />
              Add Lead
            </button>
          </div>

          {leadsLoading ? (
            <div className="animate-pulse space-y-3">
              <div className="h-16 rounded-xl bg-gray-200" />
              <div className="h-16 rounded-xl bg-gray-200" />
            </div>
          ) : leads.length === 0 ? (
            <div className="rounded-xl border border-gray-200 bg-white py-12 text-center text-gray-400">
              No leads for this customer.
            </div>
          ) : (
            <div className="space-y-3">
              {leads.map((lead) => {
                const st = LEAD_STATUS_STYLES[lead.leadStatus];
                return (
                  <div key={lead.leadId} className="overflow-hidden rounded-xl border border-gray-200 bg-white p-4 shadow-sm hover:shadow transition-shadow">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${st?.bg || 'bg-gray-100'} ${st?.text || 'text-gray-700'}`}>
                          {st?.label || lead.leadStatus}
                        </span>
                        <span className="text-sm font-medium text-gray-900">
                          {LEAD_SOURCES.find((s) => s.value === lead.leadSource)?.label || lead.leadSource}
                        </span>
                        {lead.interestModel && (
                          <span className="text-sm text-gray-500">
                            {lead.interestYear} {lead.interestModel}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-3">
                        {lead.overdue && (
                          <span className="rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-semibold text-red-700">Overdue</span>
                        )}
                        <select
                          value={lead.leadStatus}
                          onChange={(e) => handleLeadStatusChange(lead.leadId, e.target.value)}
                          className="rounded border border-gray-300 px-2 py-1 text-xs text-gray-700"
                        >
                          {LEAD_STATUSES.map((s) => (
                            <option key={s.value} value={s.value}>{s.label}</option>
                          ))}
                        </select>
                      </div>
                    </div>
                    <div className="mt-2 flex items-center gap-4 text-xs text-gray-500">
                      <span>Assigned: {lead.assignedSales}</span>
                      <span>Contacts: {lead.contactCount}</span>
                      {lead.followUpDate && <span>Follow-up: {new Date(lead.followUpDate).toLocaleDateString()}</span>}
                      <span>Created: {new Date(lead.createdTs).toLocaleDateString()}</span>
                    </div>
                    {lead.notes && <p className="mt-2 text-xs text-gray-500 italic">{lead.notes}</p>}
                  </div>
                );
              })}
            </div>
          )}

          {/* Add Lead Modal */}
          <Modal isOpen={showLeadModal} onClose={() => setShowLeadModal(false)} title="New Lead" size="lg">
            <form onSubmit={handleCreateLead} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  label="Lead Source"
                  name="leadSource"
                  type="select"
                  value={leadForm.leadSource}
                  onChange={(e) => setLeadForm((p) => ({ ...p, leadSource: e.target.value }))}
                  required
                  options={LEAD_SOURCES}
                />
                <FormField
                  label="Assigned Salesperson"
                  name="assignedSales"
                  value={leadForm.assignedSales}
                  onChange={(e) => setLeadForm((p) => ({ ...p, assignedSales: e.target.value }))}
                  required
                  placeholder="SLP001"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  label="Interest Model"
                  name="interestModel"
                  value={leadForm.interestModel ?? ''}
                  onChange={(e) => setLeadForm((p) => ({ ...p, interestModel: e.target.value }))}
                  placeholder="CAMRY"
                />
                <FormField
                  label="Interest Year"
                  name="interestYear"
                  type="number"
                  value={leadForm.interestYear ?? ''}
                  onChange={(e) => setLeadForm((p) => ({ ...p, interestYear: e.target.value ? Number(e.target.value) : undefined }))}
                  placeholder="2026"
                />
              </div>
              <FormField
                label="Follow-Up Date"
                name="followUpDate"
                type="date"
                value={leadForm.followUpDate ?? ''}
                onChange={(e) => setLeadForm((p) => ({ ...p, followUpDate: e.target.value }))}
              />
              <FormField
                label="Notes"
                name="notes"
                type="textarea"
                value={leadForm.notes ?? ''}
                onChange={(e) => setLeadForm((p) => ({ ...p, notes: e.target.value }))}
                placeholder="Customer interested in..."
              />
              <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
                <button type="button" onClick={() => setShowLeadModal(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
                <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">Create Lead</button>
              </div>
            </form>
          </Modal>
        </div>
      )}

      {/* Edit Customer Modal */}
      {editForm && (
        <Modal isOpen={showEditModal} onClose={() => setShowEditModal(false)} title="Edit Customer" size="xl">
          <form onSubmit={handleEditSubmit} className="space-y-4">
            <div className="grid grid-cols-3 gap-4">
              <FormField label="First Name" name="firstName" value={editForm.firstName} onChange={handleEditChangeRequired} error={editErrors.firstName} required />
              <FormField label="M.I." name="middleInit" value={editForm.middleInit ?? ''} onChange={handleEditChange} />
              <FormField label="Last Name" name="lastName" value={editForm.lastName} onChange={handleEditChangeRequired} error={editErrors.lastName} required />
            </div>
            <div className="grid grid-cols-3 gap-4">
              <FormField label="Home Phone" name="homePhone" value={editForm.homePhone ?? ''} onChange={handleEditChange} />
              <FormField label="Cell Phone" name="cellPhone" value={editForm.cellPhone ?? ''} onChange={handleEditChange} />
              <FormField label="Email" name="email" value={editForm.email ?? ''} onChange={handleEditChange} />
            </div>
            <FormField label="Address Line 1" name="addressLine1" value={editForm.addressLine1} onChange={handleEditChangeRequired} error={editErrors.addressLine1} required />
            <div className="grid grid-cols-3 gap-4">
              <FormField label="City" name="city" value={editForm.city} onChange={handleEditChangeRequired} error={editErrors.city} required />
              <FormField label="State" name="stateCode" type="select" value={editForm.stateCode} onChange={handleEditChangeRequired} error={editErrors.stateCode} required options={US_STATES} />
              <FormField label="ZIP" name="zipCode" value={editForm.zipCode} onChange={handleEditChangeRequired} error={editErrors.zipCode} required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Employer" name="employerName" value={editForm.employerName ?? ''} onChange={handleEditChange} />
              <FormField label="Annual Income" name="annualIncome" type="number" value={editForm.annualIncome ?? ''} onChange={handleEditChange} />
            </div>
            <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
              <button type="button" onClick={() => setShowEditModal(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
              <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">Save Changes</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

function InfoRow({ icon, label, value }: { icon?: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-start gap-3">
      {icon && <div className="mt-0.5 text-gray-400">{icon}</div>}
      <div>
        <p className="text-xs font-medium text-gray-500">{label}</p>
        <p className="mt-0.5 text-sm text-gray-900">{value}</p>
      </div>
    </div>
  );
}

function SummaryCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: string; color: string }) {
  const colorMap: Record<string, { bg: string; iconColor: string }> = {
    blue: { bg: 'bg-blue-50', iconColor: 'text-blue-600' },
    emerald: { bg: 'bg-emerald-50', iconColor: 'text-emerald-600' },
    purple: { bg: 'bg-purple-50', iconColor: 'text-purple-600' },
    amber: { bg: 'bg-amber-50', iconColor: 'text-amber-600' },
    gray: { bg: 'bg-gray-50', iconColor: 'text-gray-500' },
  };
  const c = colorMap[color] || colorMap.gray;
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
      <div className="flex items-center gap-3">
        <div className={`flex h-9 w-9 items-center justify-center rounded-lg ${c.bg}`}>
          <div className={`h-4 w-4 ${c.iconColor}`}>{icon}</div>
        </div>
        <div>
          <p className="text-xs font-medium text-gray-500">{label}</p>
          <p className="text-lg font-bold text-gray-900">{value}</p>
        </div>
      </div>
    </div>
  );
}

export default CustomerDetailPage;
