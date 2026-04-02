import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { AlertTriangle, ArrowLeft, Plus, Bell } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import {
  getRecallCampaign,
  getRecallVehicles,
  addRecallVehicle,
  updateRecallVehicleStatus,
  getRecallNotifications,
  createRecallNotification,
} from '@/api/warranty';
import type {
  RecallCampaign,
  RecallVehicle,
  RecallNotification,
  RecallVehicleStatusRequest,
} from '@/types/registration';

const SEVERITY_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  C: { bg: 'bg-red-100', text: 'text-red-800', label: 'Critical' },
  H: { bg: 'bg-orange-100', text: 'text-orange-800', label: 'High' },
  M: { bg: 'bg-amber-100', text: 'text-amber-800', label: 'Medium' },
  L: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Low' },
};

const RECALL_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  OP: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Open' },
  SC: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Scheduled' },
  IP: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'In Progress' },
  CM: { bg: 'bg-green-50', text: 'text-green-700', label: 'Completed' },
  NA: { bg: 'bg-gray-200', text: 'text-gray-600', label: 'N/A' },
};

function RecallDetailPage() {
  const { recallId } = useParams<{ recallId: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();

  const [campaign, setCampaign] = useState<RecallCampaign | null>(null);
  const [vehicles, setVehicles] = useState<RecallVehicle[]>([]);
  const [notifications, setNotifications] = useState<RecallNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [vehiclePage, setVehiclePage] = useState(0);
  const [vehicleTotalPages, setVehicleTotalPages] = useState(0);
  const [statusFilter, setStatusFilter] = useState('');

  const [addVinOpen, setAddVinOpen] = useState(false);
  const [newVin, setNewVin] = useState('');
  const [newDealerCode, setNewDealerCode] = useState('');

  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [selectedVehicle, setSelectedVehicle] = useState<RecallVehicle | null>(null);
  const [statusForm, setStatusForm] = useState<RecallVehicleStatusRequest>({
    newStatus: 'SC', scheduledDate: '', technicianId: '',
  });

  useEffect(() => {
    if (!recallId) return;
    Promise.all([
      getRecallCampaign(recallId).then(setCampaign),
      getRecallNotifications(recallId).then(setNotifications),
    ]).catch(() => addToast('error', 'Failed to load recall details'))
      .finally(() => setLoading(false));
  }, [recallId, addToast]);

  const fetchVehicles = useCallback(async () => {
    if (!recallId) return;
    try {
      const result = await getRecallVehicles(recallId, {
        status: statusFilter || undefined, page: vehiclePage, size: 20,
      });
      setVehicles(result.content);
      setVehicleTotalPages(result.totalPages);
    } catch {
      addToast('error', 'Failed to load recall vehicles');
    }
  }, [recallId, vehiclePage, statusFilter, addToast]);

  useEffect(() => { fetchVehicles(); }, [fetchVehicles]);

  const handleAddVehicle = async () => {
    if (!recallId || !newVin) return;
    try {
      await addRecallVehicle(recallId, newVin, newDealerCode || undefined);
      addToast('success', 'Vehicle added to recall');
      setAddVinOpen(false);
      setNewVin('');
      setNewDealerCode('');
      fetchVehicles();
      if (recallId) getRecallCampaign(recallId).then(setCampaign);
    } catch {
      addToast('error', 'Failed to add vehicle');
    }
  };

  const handleStatusUpdate = async () => {
    if (!recallId || !selectedVehicle) return;
    try {
      await updateRecallVehicleStatus(recallId, selectedVehicle.vin, statusForm);
      addToast('success', 'Vehicle status updated');
      setStatusModalOpen(false);
      fetchVehicles();
      if (recallId) getRecallCampaign(recallId).then(setCampaign);
    } catch {
      addToast('error', 'Status update failed — check valid transitions');
    }
  };

  const handleNotify = async (vin: string) => {
    if (!recallId) return;
    try {
      await createRecallNotification(recallId, vin);
      addToast('success', 'Notification sent');
      getRecallNotifications(recallId).then(setNotifications);
    } catch {
      addToast('error', 'Failed to send notification — may already exist');
    }
  };

  const vehicleColumns: Column<RecallVehicle>[] = [
    { key: 'vin', label: 'VIN', render: (row) => <span className="font-mono text-xs">{row.vin}</span> },
    { key: 'dealerCode', label: 'Dealer', render: (row) => row.dealerCode || '—' },
    { key: 'recallStatus', label: 'Status', render: (row) => {
      const cfg = RECALL_STATUS_CONFIG[row.recallStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: row.recallStatus };
      return <span className={`px-2 py-0.5 rounded text-xs font-medium ${cfg.bg} ${cfg.text}`}>{cfg.label}</span>;
    }},
    { key: 'notifiedDate', label: 'Notified', render: (row) => row.notifiedDate || '—' },
    { key: 'scheduledDate', label: 'Scheduled', render: (row) => row.scheduledDate || '—' },
    { key: 'completedDate', label: 'Completed', render: (row) => row.completedDate || '—' },
    { key: 'technicianId', label: 'Tech', render: (row) => row.technicianId || '—' },
    { key: 'actions', label: 'Actions', render: (row) => (
      <div className="flex gap-1">
        {(row.recallStatus !== 'CM' && row.recallStatus !== 'NA') && (
          <button onClick={(e) => { e.stopPropagation(); setSelectedVehicle(row); setStatusModalOpen(true); }}
            className="text-xs px-2 py-1 bg-purple-50 text-purple-700 rounded hover:bg-purple-100">Update</button>
        )}
        <button onClick={(e) => { e.stopPropagation(); handleNotify(row.vin); }}
          className="text-xs px-2 py-1 bg-blue-50 text-blue-700 rounded hover:bg-blue-100">
          <Bell className="h-3 w-3 inline" /> Notify
        </button>
      </div>
    )},
  ];

  if (loading) return <div className="flex justify-center p-12"><div className="animate-spin h-8 w-8 border-4 border-red-500 border-t-transparent rounded-full" /></div>;
  if (!campaign) return <div className="text-center p-12 text-gray-500">Campaign not found</div>;

  const sevCfg = SEVERITY_CONFIG[campaign.severity] || { bg: 'bg-gray-100', text: 'text-gray-700', label: campaign.severity };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/recall')}
          className="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft className="h-5 w-5" /></button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <AlertTriangle className="h-7 w-7 text-red-600" /> {campaign.recallId}
          </h1>
          <p className="text-sm text-gray-500 mt-1">{campaign.recallDesc}</p>
        </div>
        <span className={`px-3 py-1 rounded-full text-sm font-medium ${sevCfg.bg} ${sevCfg.text}`}>
          {sevCfg.label}
        </span>
      </div>

      {/* Campaign Detail */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 lg:col-span-2">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Campaign Details</h2>
          <dl className="grid grid-cols-2 gap-3">
            {[
              ['NHTSA #', campaign.nhtsaNum || '—'],
              ['Announced', campaign.announcedDate],
              ['Affected Years', campaign.affectedYears],
              ['Affected Models', campaign.affectedModels],
              ['Remedy Available', campaign.remedyAvailDt || 'TBD'],
              ['Status', campaign.campaignStatusName],
            ].map(([label, value]) => (
              <div key={String(label)}>
                <dt className="text-xs text-gray-500 uppercase">{label}</dt>
                <dd className="text-sm font-medium text-gray-900 mt-0.5">{String(value)}</dd>
              </div>
            ))}
          </dl>
          <div className="mt-4">
            <dt className="text-xs text-gray-500 uppercase">Remedy Description</dt>
            <dd className="text-sm text-gray-700 mt-0.5">{campaign.remedyDesc}</dd>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Progress</h2>
          <div className="text-center">
            <div className="text-4xl font-bold text-emerald-600">{campaign.completionPercentage}%</div>
            <p className="text-sm text-gray-500 mt-1">
              {campaign.totalCompleted} / {campaign.totalAffected} completed
            </p>
            <div className="w-full bg-gray-200 rounded-full h-3 mt-4">
              <div className="bg-emerald-500 h-3 rounded-full transition-all"
                style={{ width: `${Math.min(campaign.completionPercentage, 100)}%` }} />
            </div>
          </div>
          <div className="mt-4 text-sm text-gray-500">
            Notifications sent: {notifications.length}
          </div>
        </div>
      </div>

      {/* Vehicles */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Affected Vehicles</h2>
          <div className="flex gap-3">
            <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setVehiclePage(0); }}
              className="border border-gray-300 rounded-md px-3 py-1.5 text-sm">
              <option value="">All Statuses</option>
              {Object.entries(RECALL_STATUS_CONFIG).map(([val, cfg]) => (
                <option key={val} value={val}>{cfg.label}</option>
              ))}
            </select>
            <button onClick={() => setAddVinOpen(true)}
              className="flex items-center gap-1 px-3 py-1.5 bg-red-600 text-white rounded-lg text-sm hover:bg-red-700">
              <Plus className="h-3 w-3" /> Add Vehicle
            </button>
          </div>
        </div>

        <DataTable columns={vehicleColumns} data={vehicles} loading={false}
          page={vehiclePage} totalPages={vehicleTotalPages} onPageChange={setVehiclePage}
          emptyMessage="No vehicles in this recall" />
      </div>

      {/* Add Vehicle Modal */}
      <Modal isOpen={addVinOpen} onClose={() => setAddVinOpen(false)} title="Add Vehicle to Recall">
        <div className="space-y-4">
          <FormField label="VIN" required>
            <input type="text" value={newVin} maxLength={17}
              onChange={(e) => setNewVin(e.target.value.toUpperCase())}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm font-mono" />
          </FormField>
          <FormField label="Dealer Code">
            <input type="text" value={newDealerCode} maxLength={5}
              onChange={(e) => setNewDealerCode(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button onClick={() => setAddVinOpen(false)}
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50">Cancel</button>
          <button onClick={handleAddVehicle}
            className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm hover:bg-red-700">Add</button>
        </div>
      </Modal>

      {/* Status Update Modal */}
      <Modal isOpen={statusModalOpen} onClose={() => setStatusModalOpen(false)}
        title={`Update Status — ${selectedVehicle?.vin || ''}`}>
        <div className="space-y-4">
          <FormField label="New Status" required>
            <select value={statusForm.newStatus}
              onChange={(e) => setStatusForm({ ...statusForm, newStatus: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm">
              <option value="SC">Scheduled</option>
              <option value="IP">In Progress</option>
              <option value="CM">Completed</option>
              <option value="NA">Not Applicable</option>
            </select>
          </FormField>
          {statusForm.newStatus === 'SC' && (
            <FormField label="Scheduled Date">
              <input type="date" value={statusForm.scheduledDate || ''}
                onChange={(e) => setStatusForm({ ...statusForm, scheduledDate: e.target.value })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
            </FormField>
          )}
          <FormField label="Technician ID">
            <input type="text" value={statusForm.technicianId || ''} maxLength={8}
              onChange={(e) => setStatusForm({ ...statusForm, technicianId: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button onClick={() => setStatusModalOpen(false)}
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50">Cancel</button>
          <button onClick={handleStatusUpdate}
            className="px-4 py-2 bg-purple-600 text-white rounded-lg text-sm hover:bg-purple-700">Update</button>
        </div>
      </Modal>
    </div>
  );
}

export default RecallDetailPage;
