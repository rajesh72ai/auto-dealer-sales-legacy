import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Truck,
  Package,
  MapPin,
  Calendar,
  Plus,
  Send,
  CheckCircle2,
  Loader2,
  AlertCircle,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getShipment, addVehicleToShipment, dispatchShipment, deliverShipment } from '@/api/production';
import type { ShipmentInfo, ShipmentVehicleRequest, ShipmentDeliverRequest } from '@/types/vehicle';

const STATUS_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  CR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Created' },
  DP: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Dispatched' },
  IT: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'In Transit' },
  DL: { bg: 'bg-green-50', text: 'text-green-700', label: 'Delivered' },
};

function ShipmentDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();

  const [shipment, setShipment] = useState<ShipmentInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const [addVehicleOpen, setAddVehicleOpen] = useState(false);
  const [vehicleForm, setVehicleForm] = useState<ShipmentVehicleRequest>({ vin: '', loadSequence: 1 });
  const [vehicleErrors, setVehicleErrors] = useState<Record<string, string>>({});

  const [deliverOpen, setDeliverOpen] = useState(false);
  const [deliverForm, setDeliverForm] = useState<ShipmentDeliverRequest>({ receivedBy: '', notes: '' });

  const fetchShipment = useCallback(async () => {
    if (!id) return;
    setLoading(true);
    try {
      const data = await getShipment(id);
      setShipment(data);
    } catch {
      addToast('error', 'Failed to load shipment details');
    } finally {
      setLoading(false);
    }
  }, [id, addToast]);

  useEffect(() => { fetchShipment(); }, [fetchShipment]);

  const handleAddVehicle = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!vehicleForm.vin.trim()) errs.vin = 'VIN is required';
    setVehicleErrors(errs);
    if (Object.keys(errs).length > 0) return;
    if (!id) return;
    setSubmitting(true);
    try {
      await addVehicleToShipment(id, vehicleForm);
      addToast('success', 'Vehicle added to shipment');
      setAddVehicleOpen(false);
      setVehicleForm({ vin: '', loadSequence: (shipment?.vehicles.length || 0) + 1 });
      fetchShipment();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to add vehicle');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDispatch = async () => {
    if (!id) return;
    setSubmitting(true);
    try {
      await dispatchShipment(id);
      addToast('success', 'Shipment dispatched');
      fetchShipment();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to dispatch');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeliver = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id || !deliverForm.receivedBy.trim()) {
      addToast('error', 'Received By is required');
      return;
    }
    setSubmitting(true);
    try {
      await deliverShipment(id, deliverForm);
      addToast('success', 'Shipment delivered');
      setDeliverOpen(false);
      fetchShipment();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to deliver');
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

  if (!shipment) {
    return (
      <div className="mx-auto max-w-4xl py-12 text-center">
        <AlertCircle className="mx-auto h-12 w-12 text-gray-300" />
        <h2 className="mt-4 text-lg font-semibold text-gray-700">Shipment not found</h2>
        <button onClick={() => navigate('/shipments')} className="mt-4 text-sm font-medium text-blue-600 hover:text-blue-700">Back to Shipments</button>
      </div>
    );
  }

  const badge = STATUS_BADGE[shipment.shipmentStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: shipment.statusName };

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/shipments')} className="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-gray-900">Shipment {shipment.shipmentId}</h1>
            <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium ${badge.bg} ${badge.text}`}>
              <span className={`h-1.5 w-1.5 rounded-full ${badge.text.replace('text-', 'bg-')}`} />
              {badge.label}
            </span>
          </div>
        </div>
        <div className="flex gap-2">
          {(shipment.shipmentStatus === 'CR') && (
            <>
              <button onClick={() => { setVehicleForm({ vin: '', loadSequence: (shipment.vehicles.length || 0) + 1 }); setVehicleErrors({}); setAddVehicleOpen(true); }} className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
                <Plus className="h-4 w-4" /> Add Vehicle
              </button>
              <button onClick={handleDispatch} disabled={submitting} className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
                <Send className="h-4 w-4" /> Dispatch
              </button>
            </>
          )}
          {(shipment.shipmentStatus === 'DP' || shipment.shipmentStatus === 'IT') && (
            <button onClick={() => { setDeliverForm({ receivedBy: '', notes: '' }); setDeliverOpen(true); }} disabled={submitting} className="inline-flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50">
              <CheckCircle2 className="h-4 w-4" /> Deliver
            </button>
          )}
        </div>
      </div>

      {/* Info Card */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">Shipment Details</h3>
        <div className="grid grid-cols-2 gap-6 lg:grid-cols-4">
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Truck className="h-3.5 w-3.5" /> Carrier</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.carrierCode}{shipment.carrierName && ` - ${shipment.carrierName}`}</dd>
          </div>
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><MapPin className="h-3.5 w-3.5" /> Origin</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.originPlant}</dd>
          </div>
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><MapPin className="h-3.5 w-3.5" /> Destination</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.destDealer}</dd>
          </div>
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Package className="h-3.5 w-3.5" /> Mode</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.transportMode}</dd>
          </div>
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Calendar className="h-3.5 w-3.5" /> Ship Date</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.shipDate || 'N/A'}</dd>
          </div>
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Calendar className="h-3.5 w-3.5" /> Est. Arrival</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.estArrivalDate || 'N/A'}</dd>
          </div>
          <div>
            <dt className="flex items-center gap-1.5 text-sm text-gray-500"><Calendar className="h-3.5 w-3.5" /> Act. Arrival</dt>
            <dd className="mt-1 text-sm font-medium text-gray-900">{shipment.actArrivalDate || 'N/A'}</dd>
          </div>
          <div>
            <dt className="text-sm text-gray-500">Vehicles</dt>
            <dd className="mt-1 text-sm font-bold text-gray-900">{shipment.vehicleCount}</dd>
          </div>
        </div>
      </div>

      {/* Vehicle Manifest */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="border-b border-gray-200 px-6 py-4">
          <h3 className="text-sm font-semibold text-gray-900">Vehicle Manifest</h3>
        </div>
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">VIN</th>
              <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Vehicle</th>
              <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Load Seq</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {(!shipment.vehicles || shipment.vehicles.length === 0) ? (
              <tr><td colSpan={3} className="px-4 py-12 text-center text-gray-400">No vehicles loaded</td></tr>
            ) : (
              shipment.vehicles.map((v) => (
                <tr key={v.vin} className="hover:bg-gray-50">
                  <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-gray-600">{v.vin}</td>
                  <td className="px-4 py-3 text-gray-700">{v.vehicleDesc}</td>
                  <td className="px-4 py-3 text-gray-600">{v.loadSequence}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Add Vehicle Modal */}
      <Modal isOpen={addVehicleOpen} onClose={() => setAddVehicleOpen(false)} title="Add Vehicle to Shipment">
        <form onSubmit={handleAddVehicle} className="space-y-4">
          <FormField label="VIN" name="vin" value={vehicleForm.vin} onChange={(e) => { setVehicleForm((p) => ({ ...p, vin: e.target.value })); if (vehicleErrors.vin) setVehicleErrors({}); }} error={vehicleErrors.vin} required placeholder="Vehicle Identification Number" />
          <FormField label="Load Sequence" name="loadSequence" type="number" value={vehicleForm.loadSequence} onChange={(e) => setVehicleForm((p) => ({ ...p, loadSequence: Number(e.target.value) }))} />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setAddVehicleOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={submitting} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">{submitting ? 'Adding...' : 'Add Vehicle'}</button>
          </div>
        </form>
      </Modal>

      {/* Deliver Modal */}
      <Modal isOpen={deliverOpen} onClose={() => setDeliverOpen(false)} title="Mark Shipment as Delivered">
        <form onSubmit={handleDeliver} className="space-y-4">
          <FormField label="Received By" name="receivedBy" value={deliverForm.receivedBy} onChange={(e) => setDeliverForm((p) => ({ ...p, receivedBy: e.target.value }))} required placeholder="Your name or ID" />
          <FormField label="Notes" name="notes" value={deliverForm.notes || ''} onChange={(e) => setDeliverForm((p) => ({ ...p, notes: e.target.value }))} placeholder="Delivery notes..." />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button type="button" onClick={() => setDeliverOpen(false)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={submitting} className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50">{submitting ? 'Delivering...' : 'Confirm Delivery'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default ShipmentDetailPage;
