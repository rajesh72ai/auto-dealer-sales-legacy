import { useState, useEffect, useCallback } from 'react';
import { Plus, ClipboardCheck, Play, CheckCircle2, XCircle, Filter } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { listPdiSchedules, schedulePdi, startPdi, completePdi, failPdi } from '@/api/production';
import { getDealers } from '@/api/dealers';
import { useAuth } from '@/auth/useAuth';
import type { PdiScheduleItem, PdiScheduleRequest, PdiCompleteRequest } from '@/types/vehicle';
import type { Dealer } from '@/types/admin';

const PDI_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  SC: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Scheduled' },
  IP: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'In Progress' },
  CM: { bg: 'bg-green-50', text: 'text-green-700', label: 'Complete' },
  FL: { bg: 'bg-red-50', text: 'text-red-700', label: 'Failed' },
};

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  ...Object.entries(PDI_STATUS_CONFIG).map(([value, cfg]) => ({ value, label: cfg.label })),
];

const defaultScheduleForm: PdiScheduleRequest = {
  vin: '',
  dealerCode: '',
  scheduledDate: new Date().toISOString().split('T')[0],
  technicianId: '',
};

const defaultCompleteForm: PdiCompleteRequest = {
  itemsPassed: 0,
  itemsFailed: 0,
  notes: '',
};

function PdiSchedulePage() {
  const { addToast } = useToast();
  const { user } = useAuth();

  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [dealerCode, setDealerCode] = useState(user?.dealerCode || '');
  const [statusFilter, setStatusFilter] = useState('');
  const [items, setItems] = useState<PdiScheduleItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  const [scheduleOpen, setScheduleOpen] = useState(false);
  const [scheduleForm, setScheduleForm] = useState({ ...defaultScheduleForm });
  const [scheduleErrors, setScheduleErrors] = useState<Record<string, string>>({});

  const [completeOpen, setCompleteOpen] = useState(false);
  const [completeTarget, setCompleteTarget] = useState<{ pdiId: number; action: 'complete' | 'fail' } | null>(null);
  const [completeForm, setCompleteForm] = useState({ ...defaultCompleteForm });

  const [startTechOpen, setStartTechOpen] = useState(false);
  const [startTarget, setStartTarget] = useState<number | null>(null);
  const [startTechId, setStartTechId] = useState('');

  const [actionLoading, setActionLoading] = useState(false);

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
      const result = await listPdiSchedules({
        dealerCode,
        status: statusFilter || undefined,
        page,
        size: 20,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load PDI schedules');
    } finally {
      setLoading(false);
    }
  }, [dealerCode, statusFilter, page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleScheduleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setScheduleForm((prev) => ({ ...prev, [name]: value }));
    if (scheduleErrors[name]) setScheduleErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleScheduleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!scheduleForm.vin.trim()) errs.vin = 'VIN is required';
    if (!scheduleForm.scheduledDate) errs.scheduledDate = 'Date is required';
    setScheduleErrors(errs);
    if (Object.keys(errs).length > 0) return;
    try {
      await schedulePdi({ ...scheduleForm, dealerCode });
      addToast('success', 'PDI scheduled successfully');
      setScheduleOpen(false);
      setScheduleForm({ ...defaultScheduleForm });
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to schedule PDI');
    }
  };

  const handleStart = async () => {
    if (!startTarget || !startTechId.trim()) { addToast('error', 'Technician ID is required'); return; }
    setActionLoading(true);
    try {
      await startPdi(startTarget, startTechId);
      addToast('success', 'PDI started');
      setStartTechOpen(false);
      setStartTechId('');
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to start PDI');
    } finally {
      setActionLoading(false);
    }
  };

  const handleCompleteSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!completeTarget) return;
    setActionLoading(true);
    try {
      if (completeTarget.action === 'complete') {
        await completePdi(completeTarget.pdiId, completeForm);
        addToast('success', 'PDI completed');
      } else {
        await failPdi(completeTarget.pdiId, completeForm);
        addToast('success', 'PDI marked as failed');
      }
      setCompleteOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to update PDI');
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<PdiScheduleItem>[] = [
    { key: 'pdiId', header: 'ID', sortable: true },
    { key: 'vin', header: 'VIN', sortable: true },
    { key: 'vehicleDesc', header: 'Vehicle' },
    {
      key: 'scheduledDate',
      header: 'Scheduled',
      render: (row) => <span className="text-xs text-gray-600">{row.scheduledDate}</span>,
    },
    {
      key: 'technicianId',
      header: 'Technician',
      render: (row) => row.technicianId || <span className="text-xs text-gray-400">Unassigned</span>,
    },
    {
      key: 'pdiStatus',
      header: 'Status',
      render: (row) => {
        const cfg = PDI_STATUS_CONFIG[row.pdiStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.statusName };
        return (
          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${cfg.bg} ${cfg.text}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${cfg.text.replace('text-', 'bg-')}`} />
            {cfg.label}
          </span>
        );
      },
    },
    {
      key: 'itemsPassed',
      header: 'Passed/Failed',
      render: (row) => (
        <span className="text-xs">
          <span className="text-green-600">{row.itemsPassed}</span>
          {' / '}
          <span className="text-red-600">{row.itemsFailed}</span>
        </span>
      ),
    },
    {
      key: 'passRate',
      header: 'Pass Rate',
      render: (row) =>
        row.passRate != null ? (
          <span className={`text-xs font-medium ${row.passRate >= 100 ? 'text-green-600' : row.passRate >= 80 ? 'text-amber-600' : 'text-red-600'}`}>
            {row.passRate.toFixed(1)}%
          </span>
        ) : (
          <span className="text-xs text-gray-400">--</span>
        ),
    },
    {
      key: 'actions' as any,
      header: 'Actions',
      render: (row) => (
        <div className="flex items-center gap-1">
          {row.pdiStatus === 'SC' && (
            <button
              onClick={(e) => { e.stopPropagation(); setStartTarget(row.pdiId); setStartTechId(row.technicianId || ''); setStartTechOpen(true); }}
              className="rounded p-1 text-blue-600 hover:bg-blue-50" title="Start"
            >
              <Play className="h-4 w-4" />
            </button>
          )}
          {row.pdiStatus === 'IP' && (
            <>
              <button
                onClick={(e) => { e.stopPropagation(); setCompleteTarget({ pdiId: row.pdiId, action: 'complete' }); setCompleteForm({ ...defaultCompleteForm }); setCompleteOpen(true); }}
                className="rounded p-1 text-green-600 hover:bg-green-50" title="Complete"
              >
                <CheckCircle2 className="h-4 w-4" />
              </button>
              <button
                onClick={(e) => { e.stopPropagation(); setCompleteTarget({ pdiId: row.pdiId, action: 'fail' }); setCompleteForm({ ...defaultCompleteForm }); setCompleteOpen(true); }}
                className="rounded p-1 text-red-600 hover:bg-red-50" title="Fail"
              >
                <XCircle className="h-4 w-4" />
              </button>
            </>
          )}
          {(row.pdiStatus === 'CM' || row.pdiStatus === 'FL') && (
            <span className="text-xs text-gray-400">--</span>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50">
            <ClipboardCheck className="h-5 w-5 text-emerald-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">PDI Schedule</h1>
            <p className="mt-0.5 text-sm text-gray-500">Pre-delivery inspection scheduling and tracking</p>
          </div>
        </div>
        <button
          onClick={() => { setScheduleForm({ ...defaultScheduleForm }); setScheduleErrors({}); setScheduleOpen(true); }}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Schedule PDI
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-1.5 text-sm text-gray-500"><Filter className="h-4 w-4" /> Filters</div>
        <select value={dealerCode} onChange={(e) => { setDealerCode(e.target.value); setPage(0); }} className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
          {dealers.map((d) => <option key={d.dealerCode} value={d.dealerCode}>{d.dealerCode} - {d.dealerName}</option>)}
        </select>
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }} className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
          {STATUS_OPTIONS.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
        </select>
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
      />

      {/* Schedule PDI Modal */}
      <Modal isOpen={scheduleOpen} onClose={() => setScheduleOpen(false)} title="Schedule PDI">
        <form onSubmit={handleScheduleSubmit} className="space-y-4">
          <FormField label="VIN" name="vin" value={scheduleForm.vin} onChange={handleScheduleChange} error={scheduleErrors.vin} required placeholder="Vehicle Identification Number" />
          <FormField label="Scheduled Date" name="scheduledDate" type="date" value={scheduleForm.scheduledDate} onChange={handleScheduleChange} error={scheduleErrors.scheduledDate} required />
          <FormField label="Technician ID" name="technicianId" value={scheduleForm.technicianId} onChange={handleScheduleChange} placeholder="Optional - assign later" />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setScheduleOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">Schedule</button>
          </div>
        </form>
      </Modal>

      {/* Start PDI Modal (assign technician) */}
      <Modal isOpen={startTechOpen} onClose={() => setStartTechOpen(false)} title="Start PDI - Assign Technician">
        <div className="space-y-4">
          <FormField label="Technician ID" name="technicianId" value={startTechId} onChange={(e) => setStartTechId(e.target.value)} required placeholder="Enter technician ID" />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setStartTechOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button onClick={handleStart} disabled={actionLoading} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">{actionLoading ? 'Starting...' : 'Start PDI'}</button>
          </div>
        </div>
      </Modal>

      {/* Complete/Fail PDI Modal */}
      <Modal isOpen={completeOpen} onClose={() => setCompleteOpen(false)} title={completeTarget?.action === 'complete' ? 'Complete PDI' : 'Fail PDI'}>
        <form onSubmit={handleCompleteSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Items Passed" name="itemsPassed" type="number" value={completeForm.itemsPassed} onChange={(e) => setCompleteForm((p) => ({ ...p, itemsPassed: Number(e.target.value) }))} required />
            <FormField label="Items Failed" name="itemsFailed" type="number" value={completeForm.itemsFailed} onChange={(e) => setCompleteForm((p) => ({ ...p, itemsFailed: Number(e.target.value) }))} required />
          </div>
          <FormField label="Notes" name="notes" value={completeForm.notes || ''} onChange={(e) => setCompleteForm((p) => ({ ...p, notes: e.target.value }))} placeholder="Inspection notes..." />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setCompleteOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={actionLoading} className={`rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50 ${completeTarget?.action === 'complete' ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'}`}>
              {actionLoading ? 'Saving...' : completeTarget?.action === 'complete' ? 'Complete' : 'Mark Failed'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default PdiSchedulePage;
