// ──────────────────────────────────────────────
// Batch module types — Wave 7
// Maps to com.autosales.modules.batch.dto.*
// ──────────────────────────────────────────────

// ── Batch Job Control ─────────────────────────

export interface BatchJob {
  programId: string;
  programName: string;
  lastRunDate: string | null;
  lastSyncDate: string | null;
  recordsProcessed: number;
  runStatus: string;
  statusDescription: string;
  createdTs: string;
  updatedTs: string;
}

export interface BatchRunResult {
  programId: string;
  status: string;
  recordsProcessed: number;
  recordsError: number;
  startedAt: string;
  completedAt: string;
  phases: string[];
  warnings: string[];
}

// ── Checkpoint (BATRSTRT) ─────────────────────

export interface Checkpoint {
  programId: string;
  checkpointSeq: number | null;
  checkpointTimestamp: string | null;
  lastKeyValue: string | null;
  recordsIn: number | null;
  recordsOut: number | null;
  recordsError: number | null;
  checkpointStatus: string;
}

export interface CheckpointActionRequest {
  programId: string;
  action: 'DISP' | 'RESET' | 'COMPL';
}

// ── Daily Sales Summary (BATDLY00) ────────────

export interface DailySalesSummary {
  summaryDate: string;
  dealerCode: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  unitsSold: number;
  totalRevenue: number;
  totalGross: number;
  frontGross: number;
  backGross: number;
  avgSellingPrice: number;
  avgGrossPerUnit: number;
}

// ── Monthly Snapshot (BATMTH00) ───────────────

export interface MonthlySnapshot {
  snapshotMonth: string;
  dealerCode: string;
  totalUnitsSold: number;
  totalRevenue: number;
  totalGross: number;
  totalFiGross: number;
  avgDaysToSell: number;
  inventoryTurn: number;
  fiPerDeal: number;
  csiScore: number | null;
  frozenFlag: string;
  createdTs: string;
}

// ── Commission ────────────────────────────────

export interface Commission {
  commissionId: number;
  dealerCode: string;
  salespersonId: string;
  dealNumber: string;
  commType: string;
  grossAmount: number;
  commRate: number;
  commAmount: number;
  payPeriod: string;
  paidFlag: string;
  calcTs: string;
}

// ── Validation Report (BATVAL00) ──────────────

export interface ValidationReport {
  generatedAt: string;
  totalExceptions: number;
  orphanedDeals: ValidationException[];
  orphanedVehicles: ValidationException[];
  invalidVins: ValidationException[];
  duplicateCustomers: ValidationException[];
}

export interface ValidationException {
  entityType: string;
  entityId: string;
  description: string;
  severity: 'HIGH' | 'MEDIUM' | 'LOW';
}

// ── GL Posting (BATGLINT) ─────────────────────

export interface GlPostingResult {
  generatedAt: string;
  dealsProcessed: number;
  totalRevenue: number;
  totalCogs: number;
  totalFiIncome: number;
  totalTax: number;
  entries: GlEntry[];
}

export interface GlEntry {
  dealNumber: string;
  accountCode: string;
  accountName: string;
  entryType: 'DR' | 'CR';
  amount: number;
}

// ── CRM Extract (BATCRM00) ───────────────────

export interface CrmExtractResult {
  extractedAt: string;
  customersExtracted: number;
  records: CrmCustomerRecord[];
}

export interface CrmCustomerRecord {
  customerId: number;
  firstName: string;
  lastName: string;
  email: string | null;
  cellPhone: string | null;
  dealerCode: string;
  totalDeals: number;
  totalSpent: number;
  lastDealDate: string | null;
  extractDate: string;
}

// ── Data Lake Extract (BATDLAKE) ──────────────

export interface DataLakeExtractResult {
  extractedAt: string;
  totalRecords: number;
  errorCount: number;
  records: DataLakeRecord[];
}

export interface DataLakeRecord {
  tableName: string;
  keyValue: string;
  actionType: string;
  auditTs: string;
  payload: string;
}

// ── DMS Extract (BATDMS00) ────────────────────

export interface DmsExtractResult {
  extractedAt: string;
  dealersProcessed: number;
  inventoryRecords: number;
  dealRecords: number;
  dealers: DmsDealerBlock[];
}

export interface DmsDealerBlock {
  dealerCode: string;
  dealerName: string;
  inventory: DmsInventoryRecord[];
  deals: DmsDealRecord[];
}

export interface DmsInventoryRecord {
  vin: string;
  makeCode: string;
  modelCode: string;
  modelYear: number;
  exteriorColor: string;
  vehicleStatus: string;
  daysInStock: number;
  msrp: number;
}

export interface DmsDealRecord {
  dealNumber: string;
  customerName: string;
  vin: string;
  dealType: string;
  dealStatus: string;
  totalPrice: number;
  dealDate: string;
}

// ── Inbound Vehicle (BATINB00) ────────────────

export interface InboundVehicleRequest {
  recordType: 'VH' | 'AL';
  vin: string;
  makeCode: string;
  modelCode: string;
  modelYear: number;
  trim?: string;
  exteriorColor?: string;
  interiorColor?: string;
  dealerCode: string;
  invoiceAmount: number;
  msrp?: number;
}

export interface InboundProcessingResult {
  processedAt: string;
  totalRecords: number;
  accepted: number;
  rejected: number;
  rejections: RejectedRecord[];
}

export interface RejectedRecord {
  vin: string;
  reasonCode: string;
  description: string;
}

// ── Purge (BATPUR00) ──────────────────────────

export interface PurgeResult {
  executedAt: string;
  registrationsArchived: number;
  auditLogsPurged: number;
  notificationsPurged: number;
  status: string;
}
