// ──────────────────────────────────────────────
// Finance Application
// ──────────────────────────────────────────────

export interface FinanceApp {
  financeId: string;
  dealNumber: string;
  customerId: number;
  financeType: string;
  lenderCode: string;
  lenderName: string;
  appStatus: string;
  amountRequested: number;
  amountApproved: number;
  aprRequested: number;
  aprApproved: number;
  termMonths: number;
  monthlyPayment: number;
  downPayment: number;
  creditTier: string;
  stipulations: string;
  submittedTs: string;
  decisionTs: string;
  fundedTs: string;
  // Computed display fields
  financeTypeName: string;
  statusName: string;
  totalOfPayments: number;
  totalInterest: number;
}

export interface FinanceAppRequest {
  dealNumber: string;
  financeType: string;
  lenderCode?: string;
  amountRequested: number;
  aprRequested?: number;
  termMonths?: number;
  downPayment?: number;
}

// ──────────────────────────────────────────────
// Finance Approval
// ──────────────────────────────────────────────

export interface FinanceApprovalRequest {
  financeId: string;
  action: string;
  amountApproved?: number;
  aprApproved?: number;
  stipulations?: string;
}

export interface FinanceApprovalResponse {
  financeId: string;
  dealNumber: string;
  action: string;
  actionName: string;
  // Original terms
  originalAmount: number;
  originalApr: number;
  originalTerm: number;
  // Approved terms
  approvedAmount: number;
  approvedApr: number;
  // Calculated payment details
  monthlyPayment: number;
  totalOfPayments: number;
  totalInterest: number;
  stipulations: string;
  decisionTs: string;
  newStatus: string;
}

// ──────────────────────────────────────────────
// Loan Calculator
// ──────────────────────────────────────────────

export interface LoanCalculatorRequest {
  principal: number;
  apr: number;
  termMonths?: number;
  downPayment?: number;
}

export interface LoanCalculatorResponse {
  principal: number;
  downPayment: number;
  netPrincipal: number;
  apr: number;
  termMonths: number;
  monthlyPayment: number;
  totalOfPayments: number;
  totalInterest: number;
  comparisons: TermComparison[];
  amortizationSchedule: AmortizationEntry[];
}

export interface TermComparison {
  term: number;
  monthlyPayment: number;
  totalPayments: number;
  totalInterest: number;
}

export interface AmortizationEntry {
  month: number;
  payment: number;
  principal: number;
  interest: number;
  cumulativeInterest: number;
  balance: number;
}

// ──────────────────────────────────────────────
// Lease Calculator
// ──────────────────────────────────────────────

export interface LeaseCalculatorRequest {
  dealNumber?: string;
  capitalizedCost: number;
  capCostReduction?: number;
  residualPct?: number;
  moneyFactor?: number;
  termMonths?: number;
  taxRate?: number;
  acqFee?: number;
  securityDeposit?: number;
}

export interface LeaseCalculatorResponse {
  // Input echo
  capitalizedCost: number;
  capCostReduction: number;
  residualPct: number;
  moneyFactor: number;
  termMonths: number;
  taxRate: number;
  acqFee: number;
  securityDeposit: number;
  // Calculated breakdown
  adjustedCapCost: number;
  residualAmount: number;
  monthlyDepreciation: number;
  monthlyFinanceCharge: number;
  monthlyTax: number;
  totalMonthlyPayment: number;
  equivalentApr: number;
  // Totals
  driveOffAmount: number;
  totalOfPayments: number;
  totalInterestEquivalent: number;
}

// ──────────────────────────────────────────────
// Finance Products (F&I)
// ──────────────────────────────────────────────

export interface FinanceProductRequest {
  dealNumber: string;
  selectedProducts: string[];
}

export interface FinanceProductResponse {
  dealNumber: string;
  catalog: ProductItem[];
  selectedCount: number;
  totalRetail: number;
  totalCost: number;
  totalProfit: number;
}

export interface ProductItem {
  code: string;
  name: string;
  term: number;
  miles: number;
  retailPrice: number;
  dealerCost: number;
  profit: number;
  selected: boolean;
}

// ──────────────────────────────────────────────
// Deal Document
// ──────────────────────────────────────────────

export interface DealDocumentResponse {
  dealNumber: string;
  documentType: string;
  seller: DealDocumentSeller;
  buyer: DealDocumentBuyer;
  vehicle: DealDocumentVehicle;
  pricing: DealDocumentPricing;
  financeTerms: DealDocumentFinanceTerms;
  fiProducts: DealDocumentFiProduct[];
}

export interface DealDocumentSeller {
  dealerName: string;
  address: string;
  city: string;
  state: string;
  zip: string;
}

export interface DealDocumentBuyer {
  customerName: string;
  address: string;
  city: string;
  state: string;
  zip: string;
}

export interface DealDocumentVehicle {
  year: number;
  make: string;
  modelName: string;
  vin: string;
  stockNumber: string;
  odometer: number;
}

export interface DealDocumentPricing {
  vehiclePrice: number;
  options: number;
  destination: number;
  rebates: number;
  tradeAllowance: number;
  taxes: number;
  fees: number;
  totalPrice: number;
  downPayment: number;
  amountFinanced: number;
}

export interface DealDocumentFinanceTerms {
  apr: number;
  termMonths: number;
  monthlyPayment: number;
  totalOfPayments: number;
  financeCharge: number;
}

export interface DealDocumentFiProduct {
  productName: string;
  retailPrice: number;
}
