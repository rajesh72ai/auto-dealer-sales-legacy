// ──────────────────────────────────────────────
// Deal
// ──────────────────────────────────────────────

export interface Deal {
  dealNumber: string;
  dealerCode: string;
  customerId: number;
  vin: string;
  salespersonId: string;
  salesManagerId: string | null;
  dealType: string;
  dealStatus: string;
  vehiclePrice: number;
  totalOptions: number;
  destinationFee: number;
  subtotal: number;
  tradeAllow: number;
  tradePayoff: number;
  netTrade: number;
  rebatesApplied: number;
  discountAmt: number;
  docFee: number;
  stateTax: number;
  countyTax: number;
  cityTax: number;
  titleFee: number;
  regFee: number;
  totalPrice: number;
  downPayment: number;
  amountFinanced: number;
  frontGross: number;
  backGross: number;
  totalGross: number;
  dealDate: string | null;
  deliveryDate: string | null;
  createdTs: string;
  updatedTs: string;
  // Computed / joined fields
  customerName: string;
  vehicleDesc: string;
  salespersonName: string;
  statusDescription: string;
  formattedVehiclePrice: string;
  formattedTotalPrice: string;
  formattedFrontGross: string;
}

// ──────────────────────────────────────────────
// Create Deal
// ──────────────────────────────────────────────

export interface CreateDealRequest {
  dealerCode: string;
  customerId: number;
  vin: string;
  salespersonId: string;
  dealType: string;
}

// ──────────────────────────────────────────────
// Negotiation
// ──────────────────────────────────────────────

export interface NegotiationRequest {
  negotiationType: string; // COUNTER | DISCOUNT
  amount: number;
  isPercentage?: boolean;
  deskNotes?: string;
}

export interface NegotiationResponse {
  dealNumber: string;
  previousPrice: number;
  newPrice: number;
  discountApplied: number;
  negotiationType: string;
  deskNotes: string | null;
  deal: Deal;
}

// ──────────────────────────────────────────────
// Validation
// ──────────────────────────────────────────────

export interface ValidationItem {
  rule: string;
  description: string;
  passed: boolean;
  message: string;
}

export interface ValidationResponse {
  dealNumber: string;
  valid: boolean;
  items: ValidationItem[];
  validatedAt: string;
}

// ──────────────────────────────────────────────
// Approval
// ──────────────────────────────────────────────

export interface ApprovalRequest {
  action: string; // APPROVE | REJECT
  comments?: string;
}

export interface ApprovalResponse {
  dealNumber: string;
  action: string;
  approvedBy: string;
  newStatus: string;
  comments: string | null;
  thresholdExceeded: boolean;
  discountPercent: number;
  approvedAt: string;
}

// ──────────────────────────────────────────────
// Trade-In
// ──────────────────────────────────────────────

export interface TradeInRequest {
  tradeYear: number;
  tradeMake: string;
  tradeModel: string;
  tradeVin: string;
  condition: string;
  odometer: number;
  tradeAllow: number;
  tradePayoff: number;
}

export interface TradeInResponse {
  tradeId: number;
  dealNumber: string;
  tradeYear: number;
  tradeMake: string;
  tradeModel: string;
  tradeVin: string;
  condition: string;
  odometer: number;
  tradeAllow: number;
  tradePayoff: number;
  netTrade: number;
  deal: Deal;
}

// ──────────────────────────────────────────────
// Incentives
// ──────────────────────────────────────────────

export interface ApplyIncentivesRequest {
  incentiveIds: string[];
}

export interface EligibleIncentive {
  incentiveId: string;
  incentiveName: string;
  incentiveType: string;
  amount: number;
  stackable: boolean;
  alreadyApplied: boolean;
}

// ──────────────────────────────────────────────
// Completion
// ──────────────────────────────────────────────

export interface CompletionRequest {
  deliveryDate: string;
  finalDownPayment: number;
  deliveryChecklist: Record<string, boolean>;
}

// ──────────────────────────────────────────────
// Cancellation
// ──────────────────────────────────────────────

export interface CancellationRequest {
  reason: string;
}
