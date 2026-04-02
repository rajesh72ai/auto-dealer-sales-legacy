// ──────────────────────────────────────────────
// Customer
// ──────────────────────────────────────────────

export interface Customer {
  customerId: number;
  firstName: string;
  lastName: string;
  middleInit: string | null;
  dateOfBirth: string | null;
  ssnLast4: string | null;
  driversLicense: string | null;
  dlState: string | null;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  stateCode: string;
  zipCode: string;
  homePhone: string | null;
  cellPhone: string | null;
  email: string | null;
  employerName: string | null;
  annualIncome: number | null;
  customerType: string;
  sourceCode: string | null;
  dealerCode: string;
  assignedSales: string | null;
  createdTs: string;
  updatedTs: string;
  formattedPhone: string | null;
  formattedCellPhone: string | null;
  fullName: string;
}

export interface CustomerRequest {
  firstName: string;
  lastName: string;
  middleInit?: string | null;
  dateOfBirth?: string | null;
  ssnLast4?: string | null;
  driversLicense?: string | null;
  dlState?: string | null;
  addressLine1: string;
  addressLine2?: string | null;
  city: string;
  stateCode: string;
  zipCode: string;
  homePhone?: string | null;
  cellPhone?: string | null;
  email?: string | null;
  employerName?: string | null;
  annualIncome?: number | null;
  customerType: string;
  sourceCode?: string | null;
  dealerCode: string;
  assignedSales?: string | null;
}

// ──────────────────────────────────────────────
// Customer History
// ──────────────────────────────────────────────

export interface CustomerHistory {
  customerId: number;
  customerName: string;
  repeatStatus: string;
  totalPurchases: number;
  totalSpent: number;
  averageDeal: number;
  deals: DealSummary[];
}

export interface DealSummary {
  dealNumber: string;
  dealDate: string;
  vin: string;
  yearMakeModel: string;
  dealType: string;
  salePrice: number;
  tradeAllow: number;
}

// ──────────────────────────────────────────────
// Credit Check
// ──────────────────────────────────────────────

export interface CreditCheckRequest {
  customerId: number;
  monthlyDebt?: number;
  bureauCode?: string;
}

export interface CreditCheckResponse {
  creditId: number;
  customerId: number;
  customerName: string;
  annualIncome: number;
  monthlyIncome: number;
  creditTier: string;
  creditTierDesc: string;
  creditScore: number;
  bureauCode: string;
  dtiRatio: number;
  monthlyDebt: number;
  maxFinancing: number;
  expiryDate: string;
  status: string;
  message: string;
}

// ──────────────────────────────────────────────
// Customer Lead
// ──────────────────────────────────────────────

export interface Lead {
  leadId: number;
  customerId: number;
  dealerCode: string;
  leadSource: string;
  interestModel: string | null;
  interestYear: number | null;
  leadStatus: string;
  assignedSales: string;
  followUpDate: string | null;
  lastContactDt: string | null;
  contactCount: number;
  notes: string | null;
  createdTs: string;
  updatedTs: string;
  customerName: string;
  overdue: boolean;
}

export interface LeadRequest {
  customerId: number;
  dealerCode: string;
  leadSource: string;
  interestModel?: string;
  interestYear?: number;
  assignedSales: string;
  followUpDate?: string;
  notes?: string;
}
