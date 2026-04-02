import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  DollarSign,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Repeat,
  Gift,
  Truck,
  Ban,
  ShieldCheck,
  Loader2,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import {
  getDeal,
  negotiateDeal,
  validateDeal,
  approveDeal,
  addTradeIn,
  applyIncentives,
  completeDeal,
  cancelDeal,
} from '@/api/deals';
import { useAuth } from '@/auth/useAuth';
import type {
  Deal,
  NegotiationRequest,
  ValidationResponse,
  ValidationItem,
  ApprovalRequest,
  TradeInRequest,
  ApplyIncentivesRequest,
  CompletionRequest,
  CancellationRequest,
} from '@/types/sales';

// ── Status styling ───────────────────────────────────────────────

const STATUS_BADGE_STYLES: Record<string, string> = {
  WS: 'bg-gray-100 text-gray-700',
  NE: 'bg-blue-50 text-blue-700',
  PA: 'bg-amber-50 text-amber-700',
  AP: 'bg-green-50 text-green-700',
  FI: 'bg-purple-50 text-purple-700',
  CT: 'bg-indigo-50 text-indigo-700',
  DL: 'bg-emerald-50 text-emerald-700',
  CA: 'bg-red-50 text-red-700',
  UW: 'bg-orange-50 text-orange-700',
};

const STATUS_DOT: Record<string, string> = {
  WS: 'bg-gray-400', NE: 'bg-blue-500', PA: 'bg-amber-500', AP: 'bg-green-500',
  FI: 'bg-purple-500', CT: 'bg-indigo-500', DL: 'bg-emerald-500', CA: 'bg-red-500', UW: 'bg-orange-500',
};

const STATUS_LABELS: Record<string, string> = {
  WS: 'Worksheet', NE: 'Negotiating', PA: 'Pending Approval', AP: 'Approved',
  FI: 'Finance', CT: 'Contracting', DL: 'Delivered', CA: 'Cancelled', UW: 'Unwound',
};

const CONDITION_OPTIONS = [
  { value: 'EX', label: 'Excellent' },
  { value: 'GD', label: 'Good' },
  { value: 'FR', label: 'Fair' },
  { value: 'PR', label: 'Poor' },
];

const DELIVERY_CHECKLIST_ITEMS = [
  { key: 'documentsComplete', label: 'All documents signed and complete' },
  { key: 'financingConfirmed', label: 'Financing approved and confirmed' },
  { key: 'vehicleInspected', label: 'Vehicle final inspection passed' },
  { key: 'plateRegistered', label: 'Plates / registration processed' },
  { key: 'customerOrientation', label: 'Customer vehicle orientation done' },
];

// ── Helpers ──────────────────────────────────────────────────────

function fmt(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0,
  }).format(amount);
}

function fmtFull(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency', currency: 'USD', minimumFractionDigits: 2,
  }).format(amount);
}

function grossColor(val: number): string {
  return val >= 0 ? 'text-green-700' : 'text-red-600';
}

// ── Sub-components ───────────────────────────────────────────────

function PriceLine({ label, value, bold, large, className }: {
  label: string; value: string; bold?: boolean; large?: boolean; className?: string;
}) {
  return (
    <div className={`flex items-center justify-between py-1 ${className || ''}`}>
      <span className={`text-sm ${bold ? 'font-semibold text-gray-900' : 'text-gray-600'}`}>{label}</span>
      <span className={`${large ? 'text-lg' : 'text-sm'} ${bold ? 'font-bold text-gray-900' : 'font-medium text-gray-800'}`}>
        {value}
      </span>
    </div>
  );
}

function SectionDivider({ label }: { label: string }) {
  return (
    <div className="mt-3 mb-1 border-t border-gray-200 pt-2">
      <span className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">{label}</span>
    </div>
  );
}

// ── Main Component ───────────────────────────────────────────────

function DealDetailPage() {
  const { dealNumber } = useParams<{ dealNumber: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();
  const { user } = useAuth();
  const isManager = user?.userType === 'ADMIN' || user?.userType === 'MANAGER';

  // Deal data
  const [deal, setDeal] = useState<Deal | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);

  // Modal states
  const [negotiateOpen, setNegotiateOpen] = useState(false);
  const [tradeInOpen, setTradeInOpen] = useState(false);
  const [validationOpen, setValidationOpen] = useState(false);
  const [approvalOpen, setApprovalOpen] = useState(false);
  const [incentivesOpen, setIncentivesOpen] = useState(false);
  const [completeOpen, setCompleteOpen] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);

  // Validation results
  const [validationResult, setValidationResult] = useState<ValidationResponse | null>(null);

  // ── Fetch deal ──────────────────────────────────────────────────

  const fetchDeal = useCallback(async () => {
    if (!dealNumber) return;
    try {
      const data = await getDeal(dealNumber);
      setDeal(data);
    } catch {
      addToast('error', 'Failed to load deal');
    } finally {
      setLoading(false);
    }
  }, [dealNumber, addToast]);

  useEffect(() => { fetchDeal(); }, [fetchDeal]);

  // ── Action handlers ─────────────────────────────────────────────

  const handleNegotiate = async (request: NegotiationRequest) => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      const result = await negotiateDeal(dealNumber, request);
      setDeal(result.deal);
      setNegotiateOpen(false);
      addToast('success', `Price updated: ${fmt(result.previousPrice)} -> ${fmt(result.newPrice)}`);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Negotiation failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleValidate = async () => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      const result = await validateDeal(dealNumber);
      setValidationResult(result);
      setValidationOpen(true);
      if (result.valid) {
        fetchDeal(); // refresh deal status
      }
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Validation failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleApproval = async (request: ApprovalRequest) => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      await approveDeal(dealNumber, request);
      setApprovalOpen(false);
      addToast('success', request.action === 'APPROVE' ? 'Deal approved' : 'Deal rejected');
      fetchDeal();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Approval action failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleTradeIn = async (request: TradeInRequest) => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      const result = await addTradeIn(dealNumber, request);
      setDeal(result.deal);
      setTradeInOpen(false);
      addToast('success', `Trade-in added: net ${fmt(result.netTrade)}`);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to add trade-in');
    } finally {
      setActionLoading(false);
    }
  };

  const handleApplyIncentives = async (request: ApplyIncentivesRequest) => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      const updated = await applyIncentives(dealNumber, request);
      setDeal(updated);
      setIncentivesOpen(false);
      addToast('success', 'Incentives applied');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to apply incentives');
    } finally {
      setActionLoading(false);
    }
  };

  const handleComplete = async (request: CompletionRequest) => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      const updated = await completeDeal(dealNumber, request);
      setDeal(updated);
      setCompleteOpen(false);
      addToast('success', 'Deal completed - vehicle delivered!');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Completion failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleCancel = async (request: CancellationRequest) => {
    if (!dealNumber) return;
    setActionLoading(true);
    try {
      const updated = await cancelDeal(dealNumber, request);
      setDeal(updated);
      setCancelOpen(false);
      addToast('success', 'Deal cancelled');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Cancellation failed');
    } finally {
      setActionLoading(false);
    }
  };

  // ── Loading / Error states ─────────────────────────────────────

  if (loading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
      </div>
    );
  }

  if (!deal) {
    return (
      <div className="mx-auto max-w-7xl py-12 text-center">
        <p className="text-lg text-gray-500">Deal not found.</p>
        <button onClick={() => navigate('/deals')} className="mt-4 text-sm font-medium text-brand-600 hover:text-brand-700">
          Back to Pipeline
        </button>
      </div>
    );
  }

  const status = deal.dealStatus;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* ── Header ───────────────────────────────────────────── */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/deals')}
            className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-200 text-gray-500 transition-colors hover:bg-gray-50"
          >
            <ArrowLeft className="h-4 w-4" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-bold text-gray-900">Deal {deal.dealNumber}</h1>
              <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold ${STATUS_BADGE_STYLES[status] || 'bg-gray-100 text-gray-700'}`}>
                <span className={`h-1.5 w-1.5 rounded-full ${STATUS_DOT[status] || 'bg-gray-400'}`} />
                {STATUS_LABELS[status] || status}
              </span>
            </div>
            <p className="mt-1 text-sm text-gray-500">
              {deal.customerName} &middot; {deal.vehicleDesc} &middot; {deal.salespersonName}
            </p>
          </div>
        </div>
      </div>

      {/* ── Main Layout: Pricing (2/3) + Actions (1/3) ───── */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left Column: Deal Pricing Breakdown */}
        <div className="lg:col-span-2 space-y-4">
          {/* Deal Sheet Card */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="border-b border-gray-100 px-6 py-4">
              <div className="flex items-center gap-2">
                <DollarSign className="h-5 w-5 text-gray-400" />
                <h2 className="text-lg font-semibold text-gray-900">Deal Sheet</h2>
              </div>
            </div>

            <div className="px-6 py-4 space-y-0">
              {/* Vehicle pricing */}
              <SectionDivider label="Vehicle" />
              <PriceLine label="Vehicle Price (MSRP)" value={fmtFull(deal.vehiclePrice)} />
              <PriceLine label="Options / Accessories" value={fmtFull(deal.totalOptions)} />
              <PriceLine label="Destination Fee" value={fmtFull(deal.destinationFee)} />
              <div className="border-t border-gray-300 mt-1 pt-1">
                <PriceLine label="Subtotal" value={fmtFull(deal.subtotal)} bold />
              </div>

              {/* Adjustments */}
              <SectionDivider label="Adjustments" />
              {deal.discountAmt > 0 && (
                <PriceLine label="Discount" value={`(${fmtFull(deal.discountAmt)})`} className="text-red-600" />
              )}
              {deal.rebatesApplied > 0 && (
                <PriceLine label="Rebates / Incentives" value={`(${fmtFull(deal.rebatesApplied)})`} className="text-red-600" />
              )}

              {/* Trade */}
              <SectionDivider label="Trade-In" />
              <PriceLine label="Trade Allowance" value={fmtFull(deal.tradeAllow)} />
              <PriceLine label="Trade Payoff" value={deal.tradePayoff > 0 ? `(${fmtFull(deal.tradePayoff)})` : fmtFull(0)} />
              <div className="border-t border-dashed border-gray-200 mt-1 pt-1">
                <PriceLine
                  label="Net Trade"
                  value={deal.netTrade >= 0 ? fmtFull(deal.netTrade) : `(${fmtFull(Math.abs(deal.netTrade))})`}
                  bold
                />
              </div>

              {/* Taxes & Fees */}
              <SectionDivider label="Taxes &amp; Fees" />
              <PriceLine label="State Tax" value={fmtFull(deal.stateTax)} />
              <PriceLine label="County Tax" value={fmtFull(deal.countyTax)} />
              <PriceLine label="City Tax" value={fmtFull(deal.cityTax)} />
              <PriceLine label="Doc Fee" value={fmtFull(deal.docFee)} />
              <PriceLine label="Title Fee" value={fmtFull(deal.titleFee)} />
              <PriceLine label="Registration Fee" value={fmtFull(deal.regFee)} />

              {/* Total */}
              <div className="mt-3 border-t-2 border-gray-900 pt-3">
                <PriceLine label="TOTAL PRICE" value={fmtFull(deal.totalPrice)} bold large />
              </div>

              {/* Financing */}
              <SectionDivider label="Financing" />
              <PriceLine label="Down Payment" value={fmtFull(deal.downPayment)} />
              <div className="mt-1 rounded-lg bg-blue-50 px-4 py-3">
                <PriceLine label="AMOUNT FINANCED" value={fmtFull(deal.amountFinanced)} bold large />
              </div>

              {/* Gross Profit */}
              <SectionDivider label="Dealer Gross Profit" />
              <div className="grid grid-cols-3 gap-4 py-2">
                <div className="rounded-lg border border-gray-200 px-4 py-3 text-center">
                  <p className="text-xs font-medium text-gray-500">Front Gross</p>
                  <p className={`mt-1 text-lg font-bold ${grossColor(deal.frontGross)}`}>{fmt(deal.frontGross)}</p>
                </div>
                <div className="rounded-lg border border-gray-200 px-4 py-3 text-center">
                  <p className="text-xs font-medium text-gray-500">Back Gross</p>
                  <p className={`mt-1 text-lg font-bold ${grossColor(deal.backGross)}`}>{fmt(deal.backGross)}</p>
                </div>
                <div className="rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-center">
                  <p className="text-xs font-medium text-gray-500">Total Gross</p>
                  <p className={`mt-1 text-xl font-bold ${grossColor(deal.totalGross)}`}>{fmt(deal.totalGross)}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Deal Info footer */}
          <div className="grid grid-cols-3 gap-4">
            <div className="rounded-lg border border-gray-200 bg-white px-4 py-3">
              <p className="text-xs font-medium text-gray-400">Deal Date</p>
              <p className="mt-0.5 text-sm font-semibold text-gray-900">
                {deal.dealDate ? new Date(deal.dealDate).toLocaleDateString() : '\u2014'}
              </p>
            </div>
            <div className="rounded-lg border border-gray-200 bg-white px-4 py-3">
              <p className="text-xs font-medium text-gray-400">Delivery Date</p>
              <p className="mt-0.5 text-sm font-semibold text-gray-900">
                {deal.deliveryDate ? new Date(deal.deliveryDate).toLocaleDateString() : '\u2014'}
              </p>
            </div>
            <div className="rounded-lg border border-gray-200 bg-white px-4 py-3">
              <p className="text-xs font-medium text-gray-400">Last Updated</p>
              <p className="mt-0.5 text-sm font-semibold text-gray-900">
                {new Date(deal.updatedTs).toLocaleString()}
              </p>
            </div>
          </div>
        </div>

        {/* Right Column: Action Panel */}
        <div className="space-y-4">
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="border-b border-gray-100 px-5 py-4">
              <h2 className="text-base font-semibold text-gray-900">Actions</h2>
              <p className="mt-0.5 text-xs text-gray-400">
                {STATUS_LABELS[status] || status} stage
              </p>
            </div>

            <div className="space-y-2 px-5 py-4">
              {/* WS: Worksheet actions */}
              {status === 'WS' && (
                <>
                  <ActionButton icon={<DollarSign />} label="Negotiate Price" onClick={() => setNegotiateOpen(true)} />
                  <ActionButton icon={<Repeat />} label="Add Trade-In" onClick={() => setTradeInOpen(true)} />
                  <ActionButton icon={<ShieldCheck />} label="Validate Deal" onClick={handleValidate} loading={actionLoading} primary />
                </>
              )}

              {/* NE: Negotiation actions */}
              {status === 'NE' && (
                <>
                  <ActionButton icon={<DollarSign />} label="Counter Offer" onClick={() => setNegotiateOpen(true)} />
                  <ActionButton icon={<DollarSign />} label="Apply Discount" onClick={() => setNegotiateOpen(true)} />
                  <ActionButton icon={<Repeat />} label="Add Trade-In" onClick={() => setTradeInOpen(true)} />
                  <ActionButton icon={<Gift />} label="Apply Incentives" onClick={() => setIncentivesOpen(true)} />
                  <ActionButton icon={<ShieldCheck />} label="Validate Deal" onClick={handleValidate} loading={actionLoading} primary />
                </>
              )}

              {/* PA: Pending Approval */}
              {status === 'PA' && (
                <>
                  {isManager ? (
                    <>
                      <ActionButton icon={<CheckCircle2 />} label="Approve Deal" onClick={() => setApprovalOpen(true)} primary />
                      <ActionButton icon={<XCircle />} label="Reject Deal" onClick={() => setApprovalOpen(true)} variant="danger" />
                    </>
                  ) : (
                    <div className="rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
                      <AlertTriangle className="mb-1 inline h-4 w-4" /> Awaiting manager approval
                    </div>
                  )}
                </>
              )}

              {/* AP / FI: Approved / Finance */}
              {(status === 'AP' || status === 'FI') && (
                <>
                  <ActionButton icon={<Gift />} label="Apply Incentives" onClick={() => setIncentivesOpen(true)} />
                  <ActionButton icon={<Truck />} label="Complete Sale" onClick={() => setCompleteOpen(true)} primary />
                </>
              )}

              {/* DL: Delivered */}
              {status === 'DL' && (
                <>
                  {isManager && (
                    <ActionButton icon={<Ban />} label="Unwind Deal" onClick={() => setCancelOpen(true)} variant="danger" />
                  )}
                  <div className="rounded-lg bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
                    <CheckCircle2 className="mb-1 inline h-4 w-4" /> This deal has been delivered.
                  </div>
                </>
              )}

              {/* CA / UW: Cancelled / Unwound */}
              {(status === 'CA' || status === 'UW') && (
                <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-800">
                  <Ban className="mb-1 inline h-4 w-4" /> This deal has been {status === 'UW' ? 'unwound' : 'cancelled'}.
                </div>
              )}

              {/* Cancel is available on any non-terminal status */}
              {!['DL', 'CA', 'UW'].includes(status) && (
                <div className="border-t border-gray-100 pt-3 mt-3">
                  <ActionButton icon={<Ban />} label="Cancel Deal" onClick={() => setCancelOpen(true)} variant="danger" />
                </div>
              )}
            </div>
          </div>

          {/* Quick Info Card */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm px-5 py-4 space-y-3">
            <h3 className="text-sm font-semibold text-gray-700">Deal Info</h3>
            <InfoRow label="VIN" value={deal.vin} mono />
            <InfoRow label="Customer ID" value={String(deal.customerId)} />
            <InfoRow label="Salesperson" value={deal.salespersonName || deal.salespersonId} />
            <InfoRow label="Manager" value={deal.salesManagerId || '\u2014'} />
            <InfoRow label="Deal Type" value={deal.dealType === 'N' ? 'New' : deal.dealType === 'U' ? 'Used' : deal.dealType === 'L' ? 'Lease' : deal.dealType === 'C' ? 'CPO' : deal.dealType} />
            <InfoRow label="Dealer" value={deal.dealerCode} />
          </div>
        </div>
      </div>

      {/* ── Modals ────────────────────────────────────────── */}

      <NegotiateModal
        isOpen={negotiateOpen}
        onClose={() => setNegotiateOpen(false)}
        onSubmit={handleNegotiate}
        loading={actionLoading}
      />

      <TradeInModal
        isOpen={tradeInOpen}
        onClose={() => setTradeInOpen(false)}
        onSubmit={handleTradeIn}
        loading={actionLoading}
      />

      <ValidationPanel
        isOpen={validationOpen}
        onClose={() => setValidationOpen(false)}
        result={validationResult}
      />

      <ApprovalModal
        isOpen={approvalOpen}
        onClose={() => setApprovalOpen(false)}
        onSubmit={handleApproval}
        deal={deal}
        loading={actionLoading}
      />

      <IncentivesModal
        isOpen={incentivesOpen}
        onClose={() => setIncentivesOpen(false)}
        onSubmit={handleApplyIncentives}
        loading={actionLoading}
      />

      <CompleteModal
        isOpen={completeOpen}
        onClose={() => setCompleteOpen(false)}
        onSubmit={handleComplete}
        loading={actionLoading}
      />

      <CancelModal
        isOpen={cancelOpen}
        onClose={() => setCancelOpen(false)}
        onSubmit={handleCancel}
        dealStatus={status}
        loading={actionLoading}
      />
    </div>
  );
}

// ── Action Button ────────────────────────────────────────────────

function ActionButton({ icon, label, onClick, primary, variant, loading }: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  primary?: boolean;
  variant?: 'danger';
  loading?: boolean;
}) {
  const base = 'flex w-full items-center gap-3 rounded-lg px-4 py-2.5 text-sm font-medium transition-colors disabled:opacity-50';
  const styles = variant === 'danger'
    ? `${base} border border-red-200 text-red-700 hover:bg-red-50`
    : primary
      ? `${base} bg-blue-600 text-white hover:bg-blue-700 shadow-sm`
      : `${base} border border-gray-200 text-gray-700 hover:bg-gray-50`;

  return (
    <button onClick={onClick} disabled={loading} className={styles}>
      <span className="h-4 w-4 flex-shrink-0">{icon}</span>
      {label}
      {loading && <Loader2 className="ml-auto h-4 w-4 animate-spin" />}
    </button>
  );
}

// ── Info Row ─────────────────────────────────────────────────────

function InfoRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-gray-400">{label}</span>
      <span className={`font-medium text-gray-900 ${mono ? 'font-mono text-xs' : ''}`}>{value}</span>
    </div>
  );
}

// ── Negotiate Modal ──────────────────────────────────────────────

function NegotiateModal({ isOpen, onClose, onSubmit, loading }: {
  isOpen: boolean; onClose: () => void; onSubmit: (r: NegotiationRequest) => void; loading: boolean;
}) {
  const [negotiationType, setNegotiationType] = useState('COUNTER');
  const [amount, setAmount] = useState('');
  const [isPercentage, setIsPercentage] = useState(false);
  const [deskNotes, setDeskNotes] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount) return;
    onSubmit({
      negotiationType,
      amount: Number(amount),
      isPercentage,
      deskNotes: deskNotes || undefined,
    });
  };

  const reset = () => { setNegotiationType('COUNTER'); setAmount(''); setIsPercentage(false); setDeskNotes(''); };

  return (
    <Modal isOpen={isOpen} onClose={() => { reset(); onClose(); }} title="Negotiate Price" size="md">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">Type</label>
          <div className="flex gap-4">
            {[{ value: 'COUNTER', label: 'Counter Offer' }, { value: 'DISCOUNT', label: 'Discount' }].map((opt) => (
              <label key={opt.value} className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input
                  type="radio"
                  name="negotiationType"
                  value={opt.value}
                  checked={negotiationType === opt.value}
                  onChange={(e) => setNegotiationType(e.target.value)}
                  className="h-4 w-4 border-gray-300 text-brand-600 focus:ring-brand-500"
                />
                {opt.label}
              </label>
            ))}
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            {negotiationType === 'COUNTER' ? 'Offer Amount ($)' : 'Discount Amount'}
          </label>
          <div className="flex items-center gap-3">
            <input
              type="number"
              step="0.01"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder={negotiationType === 'COUNTER' ? '35000' : '1500'}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              required
            />
            {negotiationType === 'DISCOUNT' && (
              <label className="flex items-center gap-2 whitespace-nowrap text-sm text-gray-600 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isPercentage}
                  onChange={(e) => setIsPercentage(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                />
                As %
              </label>
            )}
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">Desk Notes</label>
          <textarea
            value={deskNotes}
            onChange={(e) => setDeskNotes(e.target.value)}
            rows={2}
            placeholder="Optional notes for the desk log..."
            className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          />
        </div>

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <button type="button" onClick={() => { reset(); onClose(); }} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Cancel
          </button>
          <button type="submit" disabled={loading} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
            {loading ? 'Applying...' : 'Apply'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

// ── Trade-In Modal ───────────────────────────────────────────────

function TradeInModal({ isOpen, onClose, onSubmit, loading }: {
  isOpen: boolean; onClose: () => void; onSubmit: (r: TradeInRequest) => void; loading: boolean;
}) {
  const [form, setForm] = useState({
    tradeYear: '', tradeMake: '', tradeModel: '', tradeVin: '',
    condition: 'GD', odometer: '', tradeAllow: '', tradePayoff: '',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      tradeYear: Number(form.tradeYear),
      tradeMake: form.tradeMake,
      tradeModel: form.tradeModel,
      tradeVin: form.tradeVin,
      condition: form.condition,
      odometer: Number(form.odometer),
      tradeAllow: Number(form.tradeAllow),
      tradePayoff: Number(form.tradePayoff),
    });
  };

  const reset = () => setForm({
    tradeYear: '', tradeMake: '', tradeModel: '', tradeVin: '',
    condition: 'GD', odometer: '', tradeAllow: '', tradePayoff: '',
  });

  return (
    <Modal isOpen={isOpen} onClose={() => { reset(); onClose(); }} title="Add Trade-In Vehicle" size="xl">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-3 gap-4">
          <FormField label="Year" name="tradeYear" type="number" value={form.tradeYear} onChange={handleChange} required placeholder="2021" />
          <FormField label="Make" name="tradeMake" value={form.tradeMake} onChange={handleChange} required placeholder="Toyota" />
          <FormField label="Model" name="tradeModel" value={form.tradeModel} onChange={handleChange} required placeholder="Camry" />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Trade VIN" name="tradeVin" value={form.tradeVin} onChange={handleChange} required placeholder="17-character VIN" />
          <FormField label="Condition" name="condition" type="select" value={form.condition} onChange={handleChange} options={CONDITION_OPTIONS} />
        </div>
        <FormField label="Odometer" name="odometer" type="number" value={form.odometer} onChange={handleChange} required placeholder="45000" />
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Trade Allowance ($)" name="tradeAllow" type="number" value={form.tradeAllow} onChange={handleChange} required placeholder="18000" />
          <FormField label="Trade Payoff ($)" name="tradePayoff" type="number" value={form.tradePayoff} onChange={handleChange} placeholder="0" />
        </div>

        {form.tradeAllow && (
          <div className="rounded-lg bg-blue-50 px-4 py-3 text-sm">
            <span className="text-gray-600">Net Trade: </span>
            <span className="font-bold text-gray-900">{fmt(Number(form.tradeAllow) - Number(form.tradePayoff || 0))}</span>
          </div>
        )}

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <button type="button" onClick={() => { reset(); onClose(); }} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Cancel
          </button>
          <button type="submit" disabled={loading} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
            {loading ? 'Adding...' : 'Add Trade-In'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

// ── Validation Panel ─────────────────────────────────────────────

function ValidationPanel({ isOpen, onClose, result }: {
  isOpen: boolean; onClose: () => void; result: ValidationResponse | null;
}) {
  if (!result) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Deal Validation Results" size="lg">
      <div className="space-y-3">
        {/* Overall status */}
        <div className={`rounded-lg px-4 py-3 text-sm font-medium ${result.valid ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'}`}>
          {result.valid ? (
            <><CheckCircle2 className="mr-2 inline h-4 w-4" /> All validations passed - deal submitted for approval</>
          ) : (
            <><XCircle className="mr-2 inline h-4 w-4" /> Validation failed - please resolve the issues below</>
          )}
        </div>

        {/* Checklist */}
        <div className="space-y-1">
          {result.items.map((item: ValidationItem, idx: number) => (
            <div key={idx} className="flex items-start gap-3 rounded-lg border border-gray-100 px-4 py-2.5">
              {item.passed ? (
                <CheckCircle2 className="mt-0.5 h-4 w-4 flex-shrink-0 text-green-500" />
              ) : (
                <XCircle className="mt-0.5 h-4 w-4 flex-shrink-0 text-red-500" />
              )}
              <div className="min-w-0">
                <p className="text-sm font-medium text-gray-900">{item.description}</p>
                <p className="text-xs text-gray-500">{item.message}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="flex justify-end border-t border-gray-200 pt-4">
          <button onClick={onClose} className="rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200">
            Close
          </button>
        </div>
      </div>
    </Modal>
  );
}

// ── Approval Modal ───────────────────────────────────────────────

function ApprovalModal({ isOpen, onClose, onSubmit, deal, loading }: {
  isOpen: boolean; onClose: () => void; onSubmit: (r: ApprovalRequest) => void; deal: Deal; loading: boolean;
}) {
  const [comments, setComments] = useState('');

  const discountPct = deal.vehiclePrice > 0
    ? ((deal.discountAmt / deal.vehiclePrice) * 100).toFixed(1)
    : '0.0';

  const reset = () => setComments('');

  return (
    <Modal isOpen={isOpen} onClose={() => { reset(); onClose(); }} title="Deal Approval" size="lg">
      <div className="space-y-4">
        {/* Threshold info */}
        <div className="rounded-lg bg-gray-50 px-4 py-3">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-xs text-gray-400">Total Price</p>
              <p className="font-bold text-gray-900">{fmt(deal.totalPrice)}</p>
            </div>
            <div>
              <p className="text-xs text-gray-400">Discount</p>
              <p className="font-bold text-gray-900">{fmt(deal.discountAmt)} ({discountPct}%)</p>
            </div>
            <div>
              <p className="text-xs text-gray-400">Front Gross</p>
              <p className={`font-bold ${grossColor(deal.frontGross)}`}>{fmt(deal.frontGross)}</p>
            </div>
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">Comments</label>
          <textarea
            value={comments}
            onChange={(e) => setComments(e.target.value)}
            rows={3}
            placeholder="Add approval or rejection notes..."
            className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
          />
        </div>

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <button type="button" onClick={() => { reset(); onClose(); }} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Cancel
          </button>
          <button
            onClick={() => { onSubmit({ action: 'REJECT', comments: comments || undefined }); reset(); }}
            disabled={loading}
            className="rounded-lg border border-red-200 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-50 disabled:opacity-50"
          >
            Reject
          </button>
          <button
            onClick={() => { onSubmit({ action: 'APPROVE', comments: comments || undefined }); reset(); }}
            disabled={loading}
            className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50"
          >
            {loading ? 'Processing...' : 'Approve'}
          </button>
        </div>
      </div>
    </Modal>
  );
}

// ── Incentives Modal ─────────────────────────────────────────────

function IncentivesModal({ isOpen, onClose, onSubmit, loading }: {
  isOpen: boolean; onClose: () => void; onSubmit: (r: ApplyIncentivesRequest) => void; loading: boolean;
}) {
  const [incentiveIds, setIncentiveIds] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const ids = incentiveIds.split(',').map((s) => s.trim()).filter(Boolean);
    if (ids.length === 0) return;
    onSubmit({ incentiveIds: ids });
  };

  const reset = () => setIncentiveIds('');

  return (
    <Modal isOpen={isOpen} onClose={() => { reset(); onClose(); }} title="Apply Incentives" size="lg">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
          <AlertTriangle className="mr-1 inline h-4 w-4" />
          Non-stackable incentives cannot be combined. The system will validate compatibility.
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">Incentive IDs</label>
          <input
            type="text"
            value={incentiveIds}
            onChange={(e) => setIncentiveIds(e.target.value)}
            placeholder="INC-2026-001, INC-2026-002"
            className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            required
          />
          <p className="mt-1 text-xs text-gray-400">Enter comma-separated incentive program IDs</p>
        </div>

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <button type="button" onClick={() => { reset(); onClose(); }} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Cancel
          </button>
          <button type="submit" disabled={loading} className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
            {loading ? 'Applying...' : 'Apply Incentives'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

// ── Complete Modal ───────────────────────────────────────────────

function CompleteModal({ isOpen, onClose, onSubmit, loading }: {
  isOpen: boolean; onClose: () => void; onSubmit: (r: CompletionRequest) => void; loading: boolean;
}) {
  const [deliveryDate, setDeliveryDate] = useState(new Date().toISOString().split('T')[0]);
  const [finalDownPayment, setFinalDownPayment] = useState('');
  const [checklist, setChecklist] = useState<Record<string, boolean>>(
    Object.fromEntries(DELIVERY_CHECKLIST_ITEMS.map((item) => [item.key, false]))
  );

  const allChecked = DELIVERY_CHECKLIST_ITEMS.every((item) => checklist[item.key]);

  const toggleCheck = (key: string) => {
    setChecklist((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!allChecked) return;
    onSubmit({
      deliveryDate,
      finalDownPayment: Number(finalDownPayment) || 0,
      deliveryChecklist: checklist,
    });
  };

  const reset = () => {
    setDeliveryDate(new Date().toISOString().split('T')[0]);
    setFinalDownPayment('');
    setChecklist(Object.fromEntries(DELIVERY_CHECKLIST_ITEMS.map((item) => [item.key, false])));
  };

  return (
    <Modal isOpen={isOpen} onClose={() => { reset(); onClose(); }} title="Complete Sale & Deliver" size="lg">
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Delivery Checklist */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">Delivery Checklist</label>
          <div className="space-y-2">
            {DELIVERY_CHECKLIST_ITEMS.map((item) => (
              <label key={item.key} className="flex items-center gap-3 rounded-lg border border-gray-200 px-4 py-2.5 cursor-pointer hover:bg-gray-50 transition-colors">
                <input
                  type="checkbox"
                  checked={checklist[item.key]}
                  onChange={() => toggleCheck(item.key)}
                  className="h-4 w-4 rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                />
                <span className={`text-sm ${checklist[item.key] ? 'text-gray-900 font-medium' : 'text-gray-600'}`}>
                  {item.label}
                </span>
                {checklist[item.key] && <CheckCircle2 className="ml-auto h-4 w-4 text-green-500" />}
              </label>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Delivery Date</label>
            <input
              type="date"
              value={deliveryDate}
              onChange={(e) => setDeliveryDate(e.target.value)}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              required
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Final Down Payment ($)</label>
            <input
              type="number"
              step="0.01"
              value={finalDownPayment}
              onChange={(e) => setFinalDownPayment(e.target.value)}
              placeholder="5000"
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            />
          </div>
        </div>

        {!allChecked && (
          <div className="rounded-lg bg-amber-50 border border-amber-200 px-4 py-2.5 text-sm text-amber-800">
            <AlertTriangle className="mr-1 inline h-4 w-4" /> All checklist items must be completed before delivery.
          </div>
        )}

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <button type="button" onClick={() => { reset(); onClose(); }} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Cancel
          </button>
          <button type="submit" disabled={loading || !allChecked} className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50">
            {loading ? 'Completing...' : 'Complete & Deliver'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

// ── Cancel Modal ─────────────────────────────────────────────────

function CancelModal({ isOpen, onClose, onSubmit, dealStatus, loading }: {
  isOpen: boolean; onClose: () => void; onSubmit: (r: CancellationRequest) => void; dealStatus: string; loading: boolean;
}) {
  const [reason, setReason] = useState('');
  const isUnwind = dealStatus === 'DL';

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) return;
    onSubmit({ reason: reason.trim() });
  };

  const reset = () => setReason('');

  return (
    <Modal isOpen={isOpen} onClose={() => { reset(); onClose(); }} title={isUnwind ? 'Unwind Deal' : 'Cancel Deal'} size="md">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-800">
          <AlertTriangle className="mr-1 inline h-4 w-4" />
          {isUnwind
            ? 'This will reverse the delivery: vehicle returns to inventory, financing is reversed, and registration is voided.'
            : 'This will cancel the deal. Any applied incentives and trade-in records will be released.'
          }
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Reason <span className="text-red-500">*</span>
          </label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            placeholder={isUnwind ? 'Reason for unwinding this delivered deal...' : 'Reason for cancellation...'}
            className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
            required
          />
        </div>

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <button type="button" onClick={() => { reset(); onClose(); }} className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Go Back
          </button>
          <button type="submit" disabled={loading || !reason.trim()} className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50">
            {loading ? 'Processing...' : isUnwind ? 'Unwind Deal' : 'Cancel Deal'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

export default DealDetailPage;
