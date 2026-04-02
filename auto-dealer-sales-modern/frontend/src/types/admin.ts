// ──────────────────────────────────────────────
// Generic API response wrappers
// ──────────────────────────────────────────────

/** Paginated list response from backend */
export interface PaginatedApiResponse<T> {
  status: string;
  message: string | null;
  content: T[];
  page: number;
  totalPages: number;
  totalElements: number;
  timestamp: string;
}

/** Single-item wrapped response */
export interface ApiDataResponse<T> {
  status: string;
  message: string | null;
  data: T;
  timestamp: string;
}

// ──────────────────────────────────────────────
// Dealer
// ──────────────────────────────────────────────

export interface Dealer {
  dealerCode: string;
  dealerName: string;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  stateCode: string;
  zipCode: string;
  phoneNumber: string;
  faxNumber: string | null;
  dealerPrincipal: string;
  regionCode: string;
  zoneCode: string;
  oemDealerNum: string;
  floorPlanLenderId: string | null;
  maxInventory: number;
  activeFlag: string;
  openedDate: string;
  createdTs: string;
  updatedTs: string;
  formattedPhone: string;
  formattedFax: string | null;
}

export interface DealerRequest {
  dealerCode: string;
  dealerName: string;
  addressLine1: string;
  addressLine2?: string | null;
  city: string;
  stateCode: string;
  zipCode: string;
  phoneNumber: string;
  faxNumber?: string | null;
  dealerPrincipal: string;
  regionCode: string;
  zoneCode: string;
  oemDealerNum: string;
  floorPlanLenderId?: string | null;
  maxInventory: number;
  activeFlag: string;
  openedDate: string;
}

// ──────────────────────────────────────────────
// Model Master
// ──────────────────────────────────────────────

export interface ModelMaster {
  modelYear: number;
  makeCode: string;
  modelCode: string;
  modelName: string;
  bodyStyle: string;
  trimLevel: string;
  engineType: string;
  transmission: string;
  driveTrain: string;
  exteriorColors: string | null;
  interiorColors: string | null;
  curbWeight: number | null;
  fuelEconomyCity: number | null;
  fuelEconomyHwy: number | null;
  activeFlag: string;
  createdTs: string;
}

export interface ModelMasterRequest {
  modelYear: number;
  makeCode: string;
  modelCode: string;
  modelName: string;
  bodyStyle: string;
  trimLevel: string;
  engineType: string;
  transmission: string;
  driveTrain: string;
  exteriorColors?: string | null;
  interiorColors?: string | null;
  curbWeight?: number | null;
  fuelEconomyCity?: number | null;
  fuelEconomyHwy?: number | null;
  activeFlag: string;
}

// ──────────────────────────────────────────────
// Price Master
// ──────────────────────────────────────────────

export interface PriceMaster {
  modelYear: number;
  makeCode: string;
  modelCode: string;
  msrp: number;
  invoicePrice: number;
  holdbackAmt: number;
  holdbackPct: number;
  destinationFee: number;
  advertisingFee: number;
  effectiveDate: string;
  expiryDate: string | null;
  createdTs: string;
  dealerMargin: number;
  formattedMsrp: string;
  formattedInvoice: string;
}

export interface PriceMasterRequest {
  modelYear: number;
  makeCode: string;
  modelCode: string;
  msrp: number;
  invoicePrice: number;
  holdbackAmt: number;
  holdbackPct: number;
  destinationFee: number;
  advertisingFee: number;
  effectiveDate: string;
  expiryDate?: string | null;
}

// ──────────────────────────────────────────────
// Tax Rate
// ──────────────────────────────────────────────

export interface TaxRate {
  stateCode: string;
  countyCode: string;
  cityCode: string;
  stateRate: number;
  countyRate: number;
  cityRate: number;
  docFeeMax: number;
  titleFee: number;
  regFee: number;
  effectiveDate: string;
  expiryDate: string | null;
  combinedRate: number;
  combinedPct: string;
  testTaxOn30K: number;
}

export interface TaxRateRequest {
  stateCode: string;
  countyCode: string;
  cityCode: string;
  stateRate: number;
  countyRate: number;
  cityRate: number;
  docFeeMax: number;
  titleFee: number;
  regFee: number;
  effectiveDate: string;
  expiryDate?: string | null;
}

export interface TaxCalculationRequest {
  taxableAmount: number;
  tradeAllowance: number;
  stateCode: string;
  countyCode: string;
  cityCode: string;
}

// ──────────────────────────────────────────────
// Incentive Program
// ──────────────────────────────────────────────

export interface IncentiveProgram {
  incentiveId: string;
  incentiveName: string;
  incentiveType: string;
  modelYear: number | null;
  makeCode: string | null;
  modelCode: string | null;
  regionCode: string | null;
  amount: number;
  rateOverride: number | null;
  startDate: string;
  endDate: string;
  maxUnits: number | null;
  unitsUsed: number;
  stackableFlag: string;
  activeFlag: string;
  createdTs: string;
  unitsRemaining: number | null;
  isExpired: boolean;
  formattedAmount: string;
}

export interface IncentiveProgramRequest {
  incentiveId: string;
  incentiveName: string;
  incentiveType: string;
  modelYear?: number | null;
  makeCode?: string | null;
  modelCode?: string | null;
  regionCode?: string | null;
  amount: number;
  rateOverride?: number | null;
  startDate: string;
  endDate: string;
  maxUnits?: number | null;
  stackableFlag: string;
  activeFlag: string;
}

// ──────────────────────────────────────────────
// System Config
// ──────────────────────────────────────────────

export interface SystemConfig {
  configKey: string;
  configValue: string;
  configDesc: string | null;
  updatedBy: string | null;
  updatedTs: string;
}

export interface SystemConfigRequest {
  configValue: string;
  configDesc?: string;
}

// ──────────────────────────────────────────────
// Salesperson
// ──────────────────────────────────────────────

export interface Salesperson {
  salespersonId: string;
  salespersonName: string;
  dealerCode: string;
  hireDate: string | null;
  terminationDate: string | null;
  commissionPlan: string;
  activeFlag: string;
  createdTs: string;
  updatedTs: string;
  dealerName: string | null;
}

export interface SalespersonRequest {
  salespersonId: string;
  salespersonName: string;
  dealerCode: string;
  hireDate?: string | null;
  terminationDate?: string | null;
  commissionPlan: string;
  activeFlag: string;
}
