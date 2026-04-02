import { useState, useEffect, useCallback, useMemo } from 'react';
import { Plus, Target, AlertCircle, Phone, Globe, Users as UsersIcon, Gift, Megaphone, CalendarDays } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getLeads, createLead, updateLeadStatus } from '@/api/leads';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { Lead, LeadRequest } from '@/types/customer';
import type { Dealer } from '@/types/admin';

const LEAD_STATUS_CONFIG: Record<string, { bg: string; text: string; dot: string; label: string }> = {
  NW: { bg: 'bg-blue-50', text: 'text-blue-700', dot: 'bg-blue-500', label: 'New' },
  CT: { bg: 'bg-cyan-50', text: 'text-cyan-700', dot: 'bg-cyan-500', label: 'Contacted' },
  QF: { bg: 'bg-purple-50', text: 'text-purple-700', dot: 'bg-purple-500', label: 'Qualified' },
  PR: { bg: 'bg-green-50', text: 'text-green-700', dot: 'bg-green-500', label: 'Proposal' },
  WN: { bg: 'bg-emerald-50', text: 'text-emerald-700', dot: 'bg-emerald-500', label: 'Won' },
  LS: { bg: 'bg-red-50', text: 'text-red-700', dot: 'bg-red-500', label: 'Lost' },
  DD: { bg: 'bg-gray-100', text: 'text-gray-600', dot: 'bg-gray-400', label: 'Dead' },
};

const LEAD_STATUS_OPTIONS = Object.entries(LEAD_STATUS_CONFIG).map(([value, cfg]) => ({
  value,
  label: cfg.label,
}));

const SOURCE_CONFIG: Record<string, { icon: React.ReactNode; label: string; bg: string; text: string }> = {
  WLK: { icon: <UsersIcon className="h-3 w-3" />, label: 'Walk-in', bg: 'bg-blue-50', text: 'text-blue-700' },
  PHN: { icon: <Phone className="h-3 w-3" />, label: 'Phone', bg: 'bg-green-50', text: 'text-green-700' },
  WEB: { icon: <Globe className="h-3 w-3" />, label: 'Website', bg: 'bg-indigo-50', text: 'text-indigo-700' },
  REF: { icon: <Gift className="h-3 w-3" />, label: 'Referral', bg: 'bg-amber-50', text: 'text-amber-700' },
  ADV: { icon: <Megaphone className="h-3 w-3" />, label: 'Advertising', bg: 'bg-pink-50', text: 'text-pink-700' },
  EVT: { icon: <CalendarDays className="h-3 w-3" />, label: 'Event', bg: 'bg-purple-50', text: 'text-purple-700' },
};

const SOURCE_OPTIONS = Object.entries(SOURCE_CONFIG).map(([value, cfg]) => ({
  value,
  label: cfg.label,
}));

const defaultLeadForm: LeadRequest = {
  customerId: 0,
  dealerCode: '',
  leadSource: '',
  interestModel: '',
  interestYear: undefined,
  assignedSales: '',
  followUpDate: '',
  notes: '',
};

function LeadsPage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [items, setItems] = useState<Lead[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Filters
  const [dealerCode, setDealerCode] = useState(user?.dealerCode ?? '');
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [statusFilter, setStatusFilter] = useState('');
  const [salesFilter, setSalesFilter] = useState('');

  // Modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState<LeadRequest>({ ...defaultLeadForm });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});

  // Load dealers
  useEffect(() => {
    getDealers({ size: 100, active: 'Y' })
      .then((res) => setDealers(res.content))
      .catch(() => {});
  }, []);

  const fetchData = useCallback(async () => {
    if (!dealerCode) return;
    setLoading(true);
    try {
      const result = await getLeads({
        dealerCode,
        status: statusFilter || undefined,
        assignedSales: salesFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load leads');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusFilter, salesFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const overdueCount = useMemo(() => items.filter((l) => l.overdue).length, [items]);

  // Unique salespersons from current data for filter
  const salespersons = useMemo(() => {
    const set = new Set<string>();
    items.forEach((l) => { if (l.assignedSales) set.add(l.assignedSales); });
    return Array.from(set).sort();
  }, [items]);

  const handleStatusChange = async (leadId: number, newStatus: string) => {
    try {
      await updateLeadStatus(leadId, newStatus);
      setItems((prev) => prev.map((l) => l.leadId === leadId ? { ...l, leadStatus: newStatus } : l));
      addToast('success', 'Lead status updated');
    } catch {
      addToast('error', 'Failed to update status');
    }
  };

  const validateForm = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.customerId) errs.customerId = 'Customer ID is required';
    if (!form.leadSource) errs.leadSource = 'Source is required';
    if (!form.assignedSales.trim()) errs.assignedSales = 'Salesperson is required';
    setFormErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleCreateLead = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;
    try {
      await createLead({ ...form, dealerCode });
      addToast('success', 'Lead created successfully');
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create lead');
    }
  };

  const openCreate = () => {
    setForm({ ...defaultLeadForm, dealerCode });
    setFormErrors({});
    setIsModalOpen(true);
  };

  const columns: Column<Lead>[] = [
    {
      key: 'customerName',
      header: 'Customer',
      sortable: true,
      render: (row) => (
        <div>
          <span className="font-medium text-gray-900">{row.customerName}</span>
          <p className="text-xs text-gray-400">ID: {row.customerId}</p>
        </div>
      ),
    },
    {
      key: 'leadSource',
      header: 'Source',
      render: (row) => {
        const src = SOURCE_CONFIG[row.leadSource];
        return src ? (
          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${src.bg} ${src.text}`}>
            {src.icon}
            {src.label}
          </span>
        ) : (
          <span className="text-gray-600">{row.leadSource}</span>
        );
      },
    },
    {
      key: 'leadStatus',
      header: 'Status',
      render: (row) => {
        const cfg = LEAD_STATUS_CONFIG[row.leadStatus];
        return (
          <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
            <select
              value={row.leadStatus}
              onChange={(e) => handleStatusChange(row.leadId, e.target.value)}
              className={`appearance-none rounded-full border-0 px-3 py-1 text-xs font-semibold cursor-pointer focus:ring-2 focus:ring-brand-500/20 ${cfg?.bg || 'bg-gray-100'} ${cfg?.text || 'text-gray-700'}`}
            >
              {LEAD_STATUS_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
          </div>
        );
      },
    },
    {
      key: 'followUpDate',
      header: 'Follow-up',
      sortable: true,
      render: (row) => (
        <span className={`text-sm ${row.overdue ? 'font-semibold text-red-600' : 'text-gray-600'}`}>
          {row.followUpDate ? new Date(row.followUpDate).toLocaleDateString() : '\u2014'}
        </span>
      ),
    },
    {
      key: 'assignedSales',
      header: 'Assigned To',
      sortable: true,
      render: (row) => <span className="text-gray-700">{row.assignedSales}</span>,
    },
    {
      key: 'contactCount',
      header: 'Contacts',
      render: (row) => (
        <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-gray-100 text-xs font-semibold text-gray-700">
          {row.contactCount}
        </span>
      ),
    },
    {
      key: 'overdue',
      header: '',
      render: (row) =>
        row.overdue ? (
          <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-semibold text-red-700">
            <AlertCircle className="h-3 w-3" />
            Overdue
          </span>
        ) : null,
    },
  ];

  // Pipeline summary
  const pipelineCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    items.forEach((l) => {
      counts[l.leadStatus] = (counts[l.leadStatus] || 0) + 1;
    });
    return counts;
  }, [items]);

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50">
              <Target className="h-5 w-5 text-purple-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Lead Management</h1>
              <p className="mt-0.5 text-sm text-gray-500">Track and manage customer leads through the sales pipeline</p>
            </div>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-purple-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Lead
        </button>
      </div>

      {/* Overdue Alert */}
      {overdueCount > 0 && (
        <div className="flex items-center gap-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3">
          <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0" />
          <p className="text-sm font-medium text-red-800">
            {overdueCount} lead{overdueCount > 1 ? 's' : ''} overdue for follow-up. Please review and update.
          </p>
        </div>
      )}

      {/* Pipeline Summary */}
      {dealerCode && items.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {Object.entries(LEAD_STATUS_CONFIG).map(([code, cfg]) => {
            const count = pipelineCounts[code] || 0;
            if (count === 0) return null;
            return (
              <button
                key={code}
                onClick={() => setStatusFilter(statusFilter === code ? '' : code)}
                className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-semibold transition-all ${
                  statusFilter === code
                    ? `${cfg.bg} ${cfg.text} ring-2 ring-current/20`
                    : `${cfg.bg} ${cfg.text} opacity-80 hover:opacity-100`
                }`}
              >
                <span className={`h-2 w-2 rounded-full ${cfg.dot}`} />
                {cfg.label}
                <span className="ml-0.5 rounded-full bg-white/60 px-1.5 py-0.5 text-[10px] font-bold">
                  {count}
                </span>
              </button>
            );
          })}
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap items-end gap-3">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-500">Dealer</label>
          <select
            value={dealerCode}
            onChange={(e) => { setDealerCode(e.target.value); setPage(0); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          >
            <option value="">Select Dealer</option>
            {dealers.map((d) => (
              <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-500">Status</label>
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          >
            <option value="">All Statuses</option>
            {LEAD_STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-500">Salesperson</label>
          <select
            value={salesFilter}
            onChange={(e) => { setSalesFilter(e.target.value); setPage(0); }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          >
            <option value="">All Salespersons</option>
            {salespersons.map((sp) => (
              <option key={sp} value={sp}>{sp}</option>
            ))}
          </select>
        </div>
        {(statusFilter || salesFilter) && (
          <button
            onClick={() => { setStatusFilter(''); setSalesFilter(''); setPage(0); }}
            className="pb-2 text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
          >
            Clear filters
          </button>
        )}
      </div>

      {!dealerCode && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Please select a dealer to view leads.
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
          emptyMessage="No leads found. Create your first lead to get started."
        />
      )}

      {/* Create Lead Modal */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title="New Lead" size="lg">
        <form onSubmit={handleCreateLead} className="space-y-4">
          <FormField
            label="Customer ID"
            name="customerId"
            type="number"
            value={form.customerId || ''}
            onChange={(e) => {
              setForm((p) => ({ ...p, customerId: Number(e.target.value) }));
              if (formErrors.customerId) setFormErrors((p) => ({ ...p, customerId: '' }));
            }}
            error={formErrors.customerId}
            required
            placeholder="Enter customer ID"
          />
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Lead Source"
              name="leadSource"
              type="select"
              value={form.leadSource}
              onChange={(e) => {
                setForm((p) => ({ ...p, leadSource: e.target.value }));
                if (formErrors.leadSource) setFormErrors((p) => ({ ...p, leadSource: '' }));
              }}
              error={formErrors.leadSource}
              required
              options={SOURCE_OPTIONS}
            />
            <FormField
              label="Assigned Salesperson"
              name="assignedSales"
              value={form.assignedSales}
              onChange={(e) => {
                setForm((p) => ({ ...p, assignedSales: e.target.value }));
                if (formErrors.assignedSales) setFormErrors((p) => ({ ...p, assignedSales: '' }));
              }}
              error={formErrors.assignedSales}
              required
              placeholder="SLP001"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Interest Model"
              name="interestModel"
              value={form.interestModel ?? ''}
              onChange={(e) => setForm((p) => ({ ...p, interestModel: e.target.value }))}
              placeholder="e.g. CAMRY"
            />
            <FormField
              label="Interest Year"
              name="interestYear"
              type="number"
              value={form.interestYear ?? ''}
              onChange={(e) => setForm((p) => ({ ...p, interestYear: e.target.value ? Number(e.target.value) : undefined }))}
              placeholder="2026"
            />
          </div>
          <FormField
            label="Follow-Up Date"
            name="followUpDate"
            type="date"
            value={form.followUpDate ?? ''}
            onChange={(e) => setForm((p) => ({ ...p, followUpDate: e.target.value }))}
          />
          <FormField
            label="Notes"
            name="notes"
            type="textarea"
            value={form.notes ?? ''}
            onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))}
            placeholder="Additional details about the lead..."
          />
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
              className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-purple-700"
            >
              Create Lead
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default LeadsPage;
