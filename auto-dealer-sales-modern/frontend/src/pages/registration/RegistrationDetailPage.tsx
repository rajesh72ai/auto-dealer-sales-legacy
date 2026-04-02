import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { FileText, ArrowLeft, CheckCircle2, Send, RefreshCw } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import {
  getRegistration,
  validateRegistration,
  submitRegistration,
  updateRegistrationStatus,
} from '@/api/registration';
import type { Registration, RegistrationStatusUpdateRequest } from '@/types/registration';

const REG_STATUS_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  PR: { bg: 'bg-gray-100', text: 'text-gray-700', label: 'Preparing' },
  VL: { bg: 'bg-blue-50', text: 'text-blue-700', label: 'Validated' },
  SB: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Submitted' },
  PG: { bg: 'bg-purple-50', text: 'text-purple-700', label: 'Processing' },
  IS: { bg: 'bg-green-50', text: 'text-green-700', label: 'Issued' },
  RJ: { bg: 'bg-red-50', text: 'text-red-700', label: 'Rejected' },
  ER: { bg: 'bg-red-100', text: 'text-red-800', label: 'Error' },
};

function RegistrationDetailPage() {
  const { regId } = useParams<{ regId: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();

  const [reg, setReg] = useState<Registration | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [statusForm, setStatusForm] = useState<RegistrationStatusUpdateRequest>({
    newStatus: 'PG', plateNumber: '', titleNumber: '', statusDesc: '',
  });

  useEffect(() => {
    if (!regId) return;
    setLoading(true);
    getRegistration(regId)
      .then(setReg)
      .catch(() => addToast('error', 'Failed to load registration'))
      .finally(() => setLoading(false));
  }, [regId, addToast]);

  const handleValidate = async () => {
    if (!regId) return;
    try {
      const updated = await validateRegistration(regId);
      setReg(updated);
      addToast('success', 'Registration validated successfully');
    } catch {
      addToast('error', 'Validation failed — check VIN, fees, and state');
    }
  };

  const handleSubmit = async () => {
    if (!regId) return;
    try {
      const updated = await submitRegistration(regId);
      setReg(updated);
      addToast('success', 'Registration submitted to state DMV');
    } catch {
      addToast('error', 'Submission failed — registration must be validated first');
    }
  };

  const handleStatusUpdate = async () => {
    if (!regId) return;
    try {
      const updated = await updateRegistrationStatus(regId, statusForm);
      setReg(updated);
      setStatusModalOpen(false);
      addToast('success', 'Status updated successfully');
    } catch {
      addToast('error', 'Status update failed');
    }
  };

  if (loading) return <div className="flex justify-center p-12"><div className="animate-spin h-8 w-8 border-4 border-indigo-500 border-t-transparent rounded-full" /></div>;
  if (!reg) return <div className="text-center p-12 text-gray-500">Registration not found</div>;

  const statusCfg = REG_STATUS_CONFIG[reg.regStatus] || { bg: 'bg-gray-100', text: 'text-gray-700', label: reg.regStatus };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/registration')}
          className="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft className="h-5 w-5" /></button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <FileText className="h-7 w-7 text-indigo-600" /> Registration {reg.regId}
          </h1>
          <p className="text-sm text-gray-500 mt-1">Deal: {reg.dealNumber} | VIN: {reg.vin}</p>
        </div>
        <span className={`px-3 py-1 rounded-full text-sm font-medium ${statusCfg.bg} ${statusCfg.text}`}>
          {statusCfg.label}
        </span>
      </div>

      {/* Action buttons based on current status */}
      <div className="flex gap-3">
        {reg.regStatus === 'PR' && (
          <button onClick={handleValidate}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            <CheckCircle2 className="h-4 w-4" /> Validate
          </button>
        )}
        {reg.regStatus === 'VL' && (
          <button onClick={handleSubmit}
            className="flex items-center gap-2 px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700">
            <Send className="h-4 w-4" /> Submit to DMV
          </button>
        )}
        {(reg.regStatus === 'SB' || reg.regStatus === 'PG') && (
          <button onClick={() => setStatusModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">
            <RefreshCw className="h-4 w-4" /> Update Status
          </button>
        )}
      </div>

      {/* Detail Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Registration Details</h2>
          <dl className="space-y-3">
            {[
              ['Registration ID', reg.regId],
              ['Deal Number', reg.dealNumber],
              ['VIN', reg.vin],
              ['Customer ID', reg.customerId],
              ['State', reg.regState],
              ['Type', reg.regTypeName],
              ['Registration Fee', reg.formattedRegFee],
              ['Title Fee', reg.formattedTitleFee],
            ].map(([label, value]) => (
              <div key={String(label)} className="flex justify-between">
                <dt className="text-sm text-gray-500">{label}</dt>
                <dd className="text-sm font-medium text-gray-900">{String(value)}</dd>
              </div>
            ))}
          </dl>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">DMV Response</h2>
          <dl className="space-y-3">
            {[
              ['Plate Number', reg.plateNumber || '—'],
              ['Title Number', reg.titleNumber || '—'],
              ['Lien Holder', reg.lienHolder || '—'],
              ['Submission Date', reg.submissionDate || '—'],
              ['Issued Date', reg.issuedDate || '—'],
            ].map(([label, value]) => (
              <div key={String(label)} className="flex justify-between">
                <dt className="text-sm text-gray-500">{label}</dt>
                <dd className="text-sm font-medium text-gray-900">{String(value)}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>

      {/* Status History */}
      {reg.statusHistory && reg.statusHistory.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Status History</h2>
          <div className="space-y-3">
            {reg.statusHistory.map((ts, i) => (
              <div key={i} className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg">
                <div className={`px-2 py-0.5 rounded text-xs font-medium ${
                  (REG_STATUS_CONFIG[ts.statusCode] || { bg: 'bg-gray-100', text: 'text-gray-700' }).bg
                } ${(REG_STATUS_CONFIG[ts.statusCode] || { bg: 'bg-gray-100', text: 'text-gray-700' }).text}`}>
                  {ts.statusName}
                </div>
                <span className="text-sm text-gray-600 flex-1">{ts.statusDesc}</span>
                <span className="text-xs text-gray-400">{new Date(ts.statusTs).toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Status Update Modal */}
      <Modal isOpen={statusModalOpen} onClose={() => setStatusModalOpen(false)}
        title="Update Registration Status">
        <div className="space-y-4">
          <FormField label="New Status" required>
            <select value={statusForm.newStatus}
              onChange={(e) => setStatusForm({ ...statusForm, newStatus: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm">
              <option value="PG">Processing</option>
              <option value="IS">Issued</option>
              <option value="RJ">Rejected</option>
              <option value="ER">Error</option>
            </select>
          </FormField>
          {statusForm.newStatus === 'IS' && (
            <>
              <FormField label="Plate Number" required>
                <input type="text" value={statusForm.plateNumber || ''} maxLength={10}
                  onChange={(e) => setStatusForm({ ...statusForm, plateNumber: e.target.value.toUpperCase() })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
              </FormField>
              <FormField label="Title Number" required>
                <input type="text" value={statusForm.titleNumber || ''} maxLength={20}
                  onChange={(e) => setStatusForm({ ...statusForm, titleNumber: e.target.value })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
              </FormField>
            </>
          )}
          <FormField label={statusForm.newStatus === 'RJ' ? 'Rejection Reason' : 'Description'}>
            <input type="text" value={statusForm.statusDesc || ''}
              onChange={(e) => setStatusForm({ ...statusForm, statusDesc: e.target.value })}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm" />
          </FormField>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button onClick={() => setStatusModalOpen(false)}
            className="px-4 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50">Cancel</button>
          <button onClick={handleStatusUpdate}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm hover:bg-indigo-700">Update</button>
        </div>
      </Modal>
    </div>
  );
}

export default RegistrationDetailPage;
