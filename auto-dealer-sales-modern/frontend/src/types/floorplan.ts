// ──────────────────────────────────────────────
// Floor Plan — Add Vehicle
// ──────────────────────────────────────────────

export interface FloorPlanAddRequest {
  vin: string;
  lenderId: string;
  dealerCode: string;
  invoiceAmount?: number;
  floorDate?: string;
}

// ──────────────────────────────────────────────
// Floor Plan — Vehicle Response
// ──────────────────────────────────────────────

export interface FloorPlanVehicle {
  floorPlanId: number;
  vin: string;
  dealerCode: string;
  lenderId: string;
  lenderName: string;
  invoiceAmount: number;
  currentBalance: number;
  interestAccrued: number;
  floorDate: string;
  curtailmentDate: string;
  payoffDate: string | null;
  fpStatus: string;
  // Computed display fields
  statusName: string;
  daysOnFloor: number;
  daysToCurtailment: number;
  vehicleDescription: string;
}

// ──────────────────────────────────────────────
// Floor Plan — Payoff
// ──────────────────────────────────────────────

export interface FloorPlanPayoffRequest {
  vin: string;
}

export interface FloorPlanPayoffResponse {
  vin: string;
  floorPlanId: number;
  lenderId: string;
  originalFloorDate: string;
  payoffDate: string;
  originalBalance: number;
  finalInterest: number;
  totalPayoff: number;
  daysOnFloor: number;
  status: string;
}

// ──────────────────────────────────────────────
// Floor Plan — Interest Accrual
// ──────────────────────────────────────────────

export interface FloorPlanInterestRequest {
  mode: string;
  vin?: string;
  dealerCode?: string;
}

export interface FloorPlanInterestResponse {
  mode: string;
  processedCount: number;
  updatedCount: number;
  curtailmentWarningCount: number;
  errorCount: number;
  totalInterestAmount: number;
  details: FloorPlanInterestDetail[];
}

export interface FloorPlanInterestDetail {
  vin: string;
  dailyInterest: number;
  newAccrued: number;
  daysToCurtailment: number;
  warning: boolean;
}

// ──────────────────────────────────────────────
// Floor Plan — Exposure Report
// ──────────────────────────────────────────────

export interface FloorPlanExposureResponse {
  dealerCode: string;
  grandTotals: FloorPlanGrandTotals;
  lenderBreakdown: FloorPlanLenderBreakdown[];
  newUsedSplit: FloorPlanNewUsedSplit;
  ageBuckets: FloorPlanAgeBuckets;
}

export interface FloorPlanGrandTotals {
  totalVehicles: number;
  totalBalance: number;
  totalInterest: number;
  weightedAvgRate: number;
  avgDaysOnFloor: number;
}

export interface FloorPlanLenderBreakdown {
  lenderId: string;
  lenderName: string;
  vehicleCount: number;
  balance: number;
  interest: number;
  avgRate: number;
  avgDays: number;
}

export interface FloorPlanNewUsedSplit {
  newCount: number;
  usedCount: number;
  newBalance: number;
  usedBalance: number;
}

export interface FloorPlanAgeBuckets {
  count0to30: number;
  count31to60: number;
  count61to90: number;
  count91plus: number;
}

// ──────────────────────────────────────────────
// Floor Plan — Lender
// ──────────────────────────────────────────────

export interface FloorPlanLender {
  lenderId: string;
  lenderName: string;
  contactName: string;
  phone: string;
  baseRate: number;
  spread: number;
  effectiveRate: number;
  curtailmentDays: number;
  freeFloorDays: number;
}
