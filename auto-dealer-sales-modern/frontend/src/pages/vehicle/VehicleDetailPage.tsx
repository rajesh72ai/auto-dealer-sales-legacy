import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Car,
  Settings2,
  History,
  Zap,
  CheckCircle2,
  AlertCircle,
  Wrench,
  Loader2,
  MapPin,
  Calendar,
  Gauge,
  Key,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import VinDecodePanel from '@/components/shared/VinDecodePanel';
import { getVehicle, updateVehicle, allocateVehicle } from '@/api/vehicles';
import { holdVehicle, releaseVehicle } from '@/api/stock';
import { useAuth } from '@/auth/useAuth';
import type { Vehicle, VehicleUpdateRequest, VehicleAllocateRequest } from '@/types/vehicle';

const STATUS_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  AV: { bg: 'bg-green-50', text: 'text-green-700', label: 'Available' },
  SD: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Sold' },
  HD: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'On Hold' },
  IT: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'In Transit' },
  PR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Production' },
  TR: { bg: 'bg-cyan-50', text: 'text-cyan-700', label: 'Transfer' },
  AL: { bg: 'bg-indigo-50', text: 'text-indigo-700', label: 'Allocated' },
  SV: { bg: 'bg-rose-50', text: 'text-rose-700', label: 'Service' },
};

const VALID_TRANSITIONS: Record<string, string[]> = {
  AV: ['HD', 'AL', 'SD', 'TR', 'SV'],
  HD: ['AV'],
  AL: ['AV', 'SD'],
  IT: ['AV'],
  PR: ['IT'],
  TR: ['AV'],
  SD: [],
  SV: ['AV'],
};

const TABS = [
  { key: 'info', label: 'Info', icon: Car },
  { key: 'options', label: 'Options', icon: Settings2 },
  { key: 'history', label: 'History', icon: History },
  { key: 'actions', label: 'Actions', icon: Zap },
] as const;

type TabKey = typeof TABS[number]['key'];

function VehicleDetailPage() {
  const { vin } = useParams<{ vin: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();
  const { user } = useAuth();

  const [vehicle, setVehicle] = useState<Vehicle | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabKey>('info');

  // Update status form
  const [statusForm, setStatusForm] = useState<VehicleUpdateRequest>({ vehicleStatus: '', reason: '' });
  const [allocateForm, setAllocateForm] = useState<VehicleAllocateRequest>({ dealNumber: '', customerId: 0, reason: '' });
  const [allocateOpen, setAllocateOpen] = useState(false);
  const [holdReason, setHoldReason] = useState('');
  const [releaseReason, setReleaseReason] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const fetchVehicle = useCallback(async () => {
    if (!vin) return;
    setLoading(true);
    try {
      const data = await getVehicle(vin);
      setVehicle(data);
    } catch {
      addToast('error', 'Failed to load vehicle details');
    } finally {
      setLoading(false);
    }
  }, [vin, addToast]);

  useEffect(() => { fetchVehicle(); }, [fetchVehicle]);

  const handleUpdateStatus = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!vin || !statusForm.vehicleStatus) return;
    setSubmitting(true);
    try {
      await updateVehicle(vin, statusForm);
      addToast('success', 'Vehicle status updated');
      setStatusForm({ vehicleStatus: '', reason: '' });
      fetchVehicle();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to update status');
    } finally {
      setSubmitting(false);
    }
  };

  const handleHold = async () => {
    if (!vin || !holdReason.trim()) { addToast('error', 'Please enter a hold reason'); return; }
    setSubmitting(true);
    try {
      await holdVehicle(vin, { reason: holdReason, holdBy: user?.dealerCode || 'SYSTEM' });
      addToast('success', 'Vehicle placed on hold');
      setHoldReason('');
      fetchVehicle();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to hold vehicle');
    } finally {
      setSubmitting(false);
    }
  };

  const handleRelease = async () => {
    if (!vin || !releaseReason.trim()) { addToast('error', 'Please enter a release reason'); return; }
    setSubmitting(true);
    try {
      await releaseVehicle(vin, { reason: releaseReason, releaseBy: user?.dealerCode || 'SYSTEM' });
      addToast('success', 'Vehicle released from hold');
      setReleaseReason('');
      fetchVehicle();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to release vehicle');
    } finally {
      setSubmitting(false);
    }
  };

  const handleAllocate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!vin) return;
    setSubmitting(true);
    try {
      await allocateVehicle(vin, allocateForm);
      addToast('success', 'Vehicle allocated successfully');
      setAllocateOpen(false);
      fetchVehicle();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to allocate vehicle');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (!vehicle) {
    return (
      <div className="mx-auto max-w-4xl py-12 text-center">
        <AlertCircle className="mx-auto h-12 w-12 text-gray-300" />
        <h2 className="mt-4 text-lg font-semibold text-gray-700">Vehicle not found</h2>
        <button onClick={() => navigate('/vehicles')} className="mt-4 text-sm font-medium text-blue-600 hover:text-blue-700">Back to Vehicles</button>
      </div>
    );
  }

  const badge = STATUS_BADGE[vehicle.vehicleStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: vehicle.statusName };
  const transitions = VALID_TRANSITIONS[vehicle.vehicleStatus] || [];

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/vehicles')} className="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-gray-900">{vehicle.vehicleDesc}</h1>
            <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium ${badge.bg} ${badge.text}`}>
              <span className={`h-1.5 w-1.5 rounded-full ${badge.text.replace('text-', 'bg-')}`} />
              {badge.label}
            </span>
          </div>
          <p className="mt-1 text-sm text-gray-500">VIN: {vehicle.vin} | Stock: {vehicle.stockNumber || 'N/A'}</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex gap-6">
          {TABS.map(({ key, label, icon: Icon }) => (
            <button
              key={key}
              onClick={() => setActiveTab(key)}
              className={`inline-flex items-center gap-2 border-b-2 px-1 py-3 text-sm font-medium transition-colors ${
                activeTab === key
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
              }`}
            >
              <Icon className="h-4 w-4" />
              {label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'info' && (<>
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Vehicle Information</h3>
            <dl className="space-y-3">
              {[
                ['Year', vehicle.modelYear],
                ['Make', vehicle.makeCode],
                ['Model', vehicle.modelCode],
                ['VIN', vehicle.vin],
                ['Stock #', vehicle.stockNumber || 'N/A'],
                ['Engine', vehicle.engineNum || 'N/A'],
              ].map(([label, val]) => (
                <div key={String(label)} className="flex justify-between">
                  <dt className="text-sm text-gray-500">{label}</dt>
                  <dd className="text-sm font-medium text-gray-900">{String(val)}</dd>
                </div>
              ))}
            </dl>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Location & Status</h3>
            <dl className="space-y-3">
              <div className="flex items-center justify-between">
                <dt className="flex items-center gap-1.5 text-sm text-gray-500"><MapPin className="h-3.5 w-3.5" />Dealer</dt>
                <dd className="text-sm font-medium text-gray-900">{vehicle.dealerCode}</dd>
              </div>
              <div className="flex items-center justify-between">
                <dt className="flex items-center gap-1.5 text-sm text-gray-500"><MapPin className="h-3.5 w-3.5" />Lot</dt>
                <dd className="text-sm font-medium text-gray-900">{vehicle.lotLocation || 'Unassigned'}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">Ext Color</dt>
                <dd className="text-sm font-medium text-gray-900">{vehicle.exteriorColor}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">Int Color</dt>
                <dd className="text-sm font-medium text-gray-900">{vehicle.interiorColor}</dd>
              </div>
              <div className="flex items-center justify-between">
                <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Gauge className="h-3.5 w-3.5" />Odometer</dt>
                <dd className="text-sm font-medium text-gray-900">{vehicle.odometer?.toLocaleString() ?? 'N/A'} mi</dd>
              </div>
              <div className="flex items-center justify-between">
                <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Key className="h-3.5 w-3.5" />Key #</dt>
                <dd className="text-sm font-medium text-gray-900">{vehicle.keyNumber || 'N/A'}</dd>
              </div>
            </dl>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Condition & Inspection</h3>
            <dl className="space-y-3">
              <div className="flex items-center justify-between">
                <dt className="text-sm text-gray-500">Days In Stock</dt>
                <dd className={`text-sm font-semibold ${vehicle.daysInStock > 90 ? 'text-red-600' : vehicle.daysInStock > 60 ? 'text-amber-600' : 'text-gray-900'}`}>{vehicle.daysInStock}</dd>
              </div>
              <div className="flex items-center justify-between">
                <dt className="text-sm text-gray-500">PDI Status</dt>
                <dd className="flex items-center gap-1.5 text-sm font-medium">
                  {vehicle.pdiComplete === 'Y' ? <><CheckCircle2 className="h-4 w-4 text-green-500" /> Complete</> : <><Wrench className="h-4 w-4 text-amber-500" /> Pending</>}
                </dd>
              </div>
              <div className="flex items-center justify-between">
                <dt className="text-sm text-gray-500">Damage</dt>
                <dd className="flex items-center gap-1.5 text-sm font-medium">
                  {vehicle.damageFlag === 'Y' ? <><AlertCircle className="h-4 w-4 text-red-500" /> {vehicle.damageDesc || 'Yes'}</> : <><CheckCircle2 className="h-4 w-4 text-green-500" /> None</>}
                </dd>
              </div>
            </dl>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Key Dates</h3>
            <dl className="space-y-3">
              {[
                ['Production', vehicle.productionDate],
                ['Shipped', vehicle.shipDate],
                ['Received', vehicle.receiveDate],
                ['Created', vehicle.createdTs?.split('T')[0]],
                ['Updated', vehicle.updatedTs?.split('T')[0]],
              ].map(([label, val]) => (
                <div key={String(label)} className="flex items-center justify-between">
                  <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Calendar className="h-3.5 w-3.5" />{label}</dt>
                  <dd className="text-sm font-medium text-gray-900">{val || 'N/A'}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
        <VinDecodePanel vin={vehicle.vin} />
      </>)}

      {activeTab === 'options' && (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Code</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Description</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Price</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Installed</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {vehicle.options.length === 0 ? (
                <tr><td colSpan={4} className="px-4 py-12 text-center text-gray-400">No options recorded</td></tr>
              ) : (
                vehicle.options.map((opt) => (
                  <tr key={opt.optionCode} className="hover:bg-gray-50">
                    <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-gray-600">{opt.optionCode}</td>
                    <td className="px-4 py-3 text-gray-700">{opt.optionDesc}</td>
                    <td className="px-4 py-3 font-medium text-gray-900">${opt.optionPrice.toLocaleString()}</td>
                    <td className="px-4 py-3">
                      {opt.installedFlag === 'Y' ? <CheckCircle2 className="h-4 w-4 text-green-500" /> : <span className="text-gray-400">No</span>}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {activeTab === 'history' && (
        <div className="space-y-0">
          {vehicle.history.length === 0 ? (
            <div className="rounded-xl border border-gray-200 bg-white p-12 text-center text-gray-400 shadow-sm">
              No status changes recorded
            </div>
          ) : (
            <div className="relative ml-4 border-l-2 border-gray-200 pl-8">
              {vehicle.history.map((entry) => {
                const fromBadge = STATUS_BADGE[entry.oldStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: entry.oldStatus };
                const toBadge = STATUS_BADGE[entry.newStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: entry.newStatus };
                return (
                  <div key={entry.statusSeq} className="relative mb-6">
                    <div className="absolute -left-[2.55rem] top-1 h-4 w-4 rounded-full border-2 border-white bg-blue-500" />
                    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
                      <div className="flex items-center gap-2 text-sm">
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${fromBadge.bg} ${fromBadge.text}`}>{fromBadge.label}</span>
                        <span className="text-gray-400">&rarr;</span>
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${toBadge.bg} ${toBadge.text}`}>{toBadge.label}</span>
                      </div>
                      <p className="mt-2 text-xs text-gray-500">
                        By <span className="font-medium text-gray-700">{entry.changedBy}</span>
                        {entry.changeReason && <> &mdash; {entry.changeReason}</>}
                      </p>
                      <p className="mt-1 text-xs text-gray-400">{new Date(entry.changedTs).toLocaleString()}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {activeTab === 'actions' && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Update Status */}
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Update Status</h3>
            {transitions.length === 0 ? (
              <p className="text-sm text-gray-400">No valid transitions from current status</p>
            ) : (
              <form onSubmit={handleUpdateStatus} className="space-y-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">New Status</label>
                  <select
                    value={statusForm.vehicleStatus || ''}
                    onChange={(e) => setStatusForm((p) => ({ ...p, vehicleStatus: e.target.value }))}
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                  >
                    <option value="">Select status...</option>
                    {transitions.map((s) => {
                      const b = STATUS_BADGE[s] || { label: s };
                      return <option key={s} value={s}>{b.label} ({s})</option>;
                    })}
                  </select>
                </div>
                <FormField label="Reason" name="reason" value={statusForm.reason || ''} onChange={(e) => setStatusForm((p) => ({ ...p, reason: e.target.value }))} placeholder="Reason for status change" />
                <button type="submit" disabled={submitting || !statusForm.vehicleStatus} className="w-full rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:opacity-50">
                  {submitting ? 'Updating...' : 'Update Status'}
                </button>
              </form>
            )}
          </div>

          {/* Hold / Release */}
          <div className="space-y-6">
            {vehicle.vehicleStatus === 'AV' && (
              <div className="rounded-xl border border-amber-200 bg-amber-50/50 p-6 shadow-sm">
                <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-amber-700">Place On Hold</h3>
                <input
                  value={holdReason}
                  onChange={(e) => setHoldReason(e.target.value)}
                  placeholder="Hold reason..."
                  className="mb-3 w-full rounded-lg border border-amber-300 bg-white px-3 py-2 text-sm focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500/20"
                />
                <button onClick={handleHold} disabled={submitting} className="w-full rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-amber-700 disabled:opacity-50">
                  {submitting ? 'Processing...' : 'Hold Vehicle'}
                </button>
              </div>
            )}
            {vehicle.vehicleStatus === 'HD' && (
              <div className="rounded-xl border border-green-200 bg-green-50/50 p-6 shadow-sm">
                <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-green-700">Release Hold</h3>
                <input
                  value={releaseReason}
                  onChange={(e) => setReleaseReason(e.target.value)}
                  placeholder="Release reason..."
                  className="mb-3 w-full rounded-lg border border-green-300 bg-white px-3 py-2 text-sm focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-500/20"
                />
                <button onClick={handleRelease} disabled={submitting} className="w-full rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-green-700 disabled:opacity-50">
                  {submitting ? 'Processing...' : 'Release Vehicle'}
                </button>
              </div>
            )}

            {/* Allocate */}
            {(vehicle.vehicleStatus === 'AV' || vehicle.vehicleStatus === 'IT') && (
              <div className="rounded-xl border border-indigo-200 bg-indigo-50/50 p-6 shadow-sm">
                <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-indigo-700">Allocate Vehicle</h3>
                <button
                  onClick={() => { setAllocateForm({ dealNumber: '', customerId: 0, reason: '' }); setAllocateOpen(true); }}
                  className="w-full rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-indigo-700"
                >
                  Open Allocate Form
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Allocate Modal */}
      <Modal isOpen={allocateOpen} onClose={() => setAllocateOpen(false)} title="Allocate Vehicle">
        <form onSubmit={handleAllocate} className="space-y-4">
          <FormField label="Deal Number" name="dealNumber" value={allocateForm.dealNumber} onChange={(e) => setAllocateForm((p) => ({ ...p, dealNumber: e.target.value }))} required placeholder="DL-001" />
          <FormField label="Customer ID" name="customerId" type="number" value={allocateForm.customerId || ''} onChange={(e) => setAllocateForm((p) => ({ ...p, customerId: Number(e.target.value) }))} required placeholder="1001" />
          <FormField label="Reason" name="reason" value={allocateForm.reason || ''} onChange={(e) => setAllocateForm((p) => ({ ...p, reason: e.target.value }))} placeholder="Allocation reason..." />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setAllocateOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={submitting} className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-indigo-700 disabled:opacity-50">
              {submitting ? 'Allocating...' : 'Allocate'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default VehicleDetailPage;
