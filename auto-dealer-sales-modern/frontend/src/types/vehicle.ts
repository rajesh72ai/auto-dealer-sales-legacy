// ──────────────────────────────────────────────
// Wave 5: Vehicle & Inventory — TypeScript types
// Mirrors Java DTOs in com.autosales.modules.vehicle.dto
// ──────────────────────────────────────────────

// ──────────────────────────────────────────────
// Vehicle
// ──────────────────────────────────────────────

/** Full vehicle detail — VehicleResponse.java */
export interface Vehicle {
  vin: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  exteriorColor: string;
  interiorColor: string;
  engineNum: string;
  productionDate: string | null;
  shipDate: string | null;
  receiveDate: string | null;
  vehicleStatus: string;
  statusName: string;
  dealerCode: string;
  lotLocation: string | null;
  stockNumber: string | null;
  daysInStock: number;
  pdiComplete: string;
  damageFlag: string;
  damageDesc: string | null;
  odometer: number | null;
  keyNumber: string | null;
  vehicleDesc: string;
  options: VehicleOption[];
  history: VehicleHistoryEntry[];
  createdTs: string;
  updatedTs: string;
}

/** List/search row — VehicleListResponse.java */
export interface VehicleListItem {
  vin: string;
  stockNumber: string | null;
  vehicleDesc: string;
  vehicleStatus: string;
  statusName: string;
  exteriorColor: string;
  daysInStock: number;
  dealerCode: string;
  lotLocation: string | null;
  pdiComplete: string;
  damageFlag: string;
}

/** VehicleOptionResponse.java */
export interface VehicleOption {
  optionCode: string;
  optionDesc: string;
  optionPrice: number;
  installedFlag: string;
}

/** VehicleHistoryEntry.java */
export interface VehicleHistoryEntry {
  statusSeq: number;
  oldStatus: string;
  newStatus: string;
  changedBy: string;
  changeReason: string | null;
  changedTs: string;
}

/** VehicleUpdateRequest.java */
export interface VehicleUpdateRequest {
  vehicleStatus?: string;
  lotLocation?: string;
  odometer?: number;
  damageFlag?: string;
  damageDesc?: string;
  keyNumber?: string;
  reason?: string;
}

/** VehicleReceiveRequest.java */
export interface VehicleReceiveRequest {
  lotLocation: string;
  stockNumber: string;
  odometer?: number;
  damageFlag?: string;
  damageDesc?: string;
  keyNumber?: string;
  inspectionNotes?: string;
}

/** VehicleAllocateRequest.java */
export interface VehicleAllocateRequest {
  dealNumber: string;
  customerId: number;
  reason?: string;
}

/** VehicleOptionRequest.java */
export interface VehicleOptionRequest {
  optionCode: string;
  optionDesc: string;
  optionPrice: number;
  installedFlag: string;
}

// ──────────────────────────────────────────────
// Aging Report
// ──────────────────────────────────────────────

/** AgingReportResponse.java */
export interface AgingReport {
  dealerCode: string;
  totalVehicles: number;
  totalValue: number;
  avgDaysInStock: number;
  buckets: AgingBucket[];
  agedVehicles: VehicleListItem[];
}

/** AgingReportResponse.AgingBucket */
export interface AgingBucket {
  range: string;
  count: number;
  value: number;
  avgDays: number;
  pctOfTotal: number;
}

// ──────────────────────────────────────────────
// Lot Location
// ──────────────────────────────────────────────

/** LotLocationResponse.java */
export interface LotLocation {
  dealerCode: string;
  locationCode: string;
  locationDesc: string;
  locationType: string;
  maxCapacity: number;
  currentCount: number;
  activeFlag: string;
  availableSpots: number;
  utilizationPct: number;
}

/** LotLocationRequest.java */
export interface LotLocationRequest {
  dealerCode: string;
  locationCode: string;
  locationDesc: string;
  locationType: string;
  maxCapacity: number;
  activeFlag: string;
}

// ──────────────────────────────────────────────
// Stock Position & Summary
// ──────────────────────────────────────────────

/** StockPositionResponse.java */
export interface StockPosition {
  dealerCode: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  modelDesc: string;
  onHandCount: number;
  inTransitCount: number;
  allocatedCount: number;
  onHoldCount: number;
  soldMtd: number;
  soldYtd: number;
  reorderPoint: number;
  lowStockAlert: boolean;
}

/** StockSummaryResponse.java */
export interface StockSummary {
  dealerCode: string;
  dealerName: string;
  totalOnHand: number;
  totalInTransit: number;
  totalAllocated: number;
  totalOnHold: number;
  totalSoldMtd: number;
  totalSoldYtd: number;
  totalValue: number;
  avgDaysInStock: number;
}

// ──────────────────────────────────────────────
// Stock Adjustment
// ──────────────────────────────────────────────

/** StockAdjustmentResponse.java */
export interface StockAdjustment {
  adjustId: number;
  dealerCode: string;
  vin: string;
  vehicleDesc: string;
  adjustType: string;
  adjustTypeName: string;
  adjustReason: string;
  oldStatus: string;
  newStatus: string;
  adjustedBy: string;
  adjustedTs: string;
}

/** StockAdjustmentRequest.java */
export interface StockAdjustmentRequest {
  dealerCode: string;
  vin: string;
  adjustType: string;
  adjustReason: string;
  adjustedBy: string;
}

// ──────────────────────────────────────────────
// Stock Alert
// ──────────────────────────────────────────────

/** StockAlertResponse.java */
export interface StockAlert {
  alertType: string;
  dealerCode: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  modelDesc: string;
  currentCount: number;
  reorderPoint: number;
  deficit: number;
  suggestedOrder: number;
}

// ──────────────────────────────────────────────
// Stock Hold / Release
// ──────────────────────────────────────────────

/** StockHoldRequest.java */
export interface StockHoldRequest {
  reason: string;
  holdBy: string;
}

/** StockReleaseRequest.java */
export interface StockReleaseRequest {
  reason: string;
  releaseBy: string;
}

// ──────────────────────────────────────────────
// Stock Valuation
// ──────────────────────────────────────────────

/** StockValuationResponse.java */
export interface StockValuation {
  dealerCode: string;
  categories: ValuationCategory[];
  grandTotal: number;
  totalAccruedInterest: number;
}

/** StockValuationResponse.ValuationCategory */
export interface ValuationCategory {
  category: string;
  categoryName: string;
  count: number;
  totalInvoice: number;
  totalMsrp: number;
  avgDaysInStock: number;
  holdingCost: number;
}

// ──────────────────────────────────────────────
// Reconciliation
// ──────────────────────────────────────────────

/** ReconciliationResponse.java */
export interface Reconciliation {
  dealerCode: string;
  reconciliationDate: string;
  totalModels: number;
  discrepancies: Discrepancy[];
  totalVariance: number;
  reconciled: boolean;
}

/** ReconciliationResponse.Discrepancy */
export interface Discrepancy {
  modelYear: number;
  makeCode: string;
  modelCode: string;
  modelDesc: string;
  systemCount: number;
  actualCount: number;
  variance: number;
}

// ──────────────────────────────────────────────
// Transfer
// ──────────────────────────────────────────────

/** TransferResponse.java */
export interface Transfer {
  transferId: number;
  fromDealer: string;
  toDealer: string;
  vin: string;
  vehicleDesc: string;
  transferStatus: string;
  statusName: string;
  requestedBy: string;
  approvedBy: string | null;
  requestedTs: string;
  approvedTs: string | null;
  completedTs: string | null;
}

/** TransferRequest.java */
export interface TransferRequest {
  fromDealer: string;
  toDealer: string;
  vin: string;
  requestedBy: string;
  reason: string;
}

/** TransferApprovalRequest.java */
export interface TransferApprovalRequest {
  approvedBy: string;
  notes?: string;
}

// ──────────────────────────────────────────────
// Snapshot
// ──────────────────────────────────────────────

/** SnapshotResponse.java */
export interface Snapshot {
  snapshotDate: string;
  dealerCode: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  modelDesc: string;
  onHandCount: number;
  inTransitCount: number;
  onHoldCount: number;
  avgDaysInStock: number;
  totalValue: number;
}

/** SnapshotCaptureRequest.java */
export interface SnapshotCaptureRequest {
  dealerCode: string;
  snapshotDate: string;
}

// ──────────────────────────────────────────────
// Production Order
// ──────────────────────────────────────────────

/** ProductionOrderResponse.java */
export interface ProductionOrder {
  productionId: string;
  vin: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  vehicleDesc: string;
  plantCode: string;
  buildDate: string;
  buildStatus: string;
  buildStatusName: string;
  allocatedDealer: string | null;
  allocationDate: string | null;
  createdTs: string;
  updatedTs: string;
}

/** ProductionOrderRequest.java */
export interface ProductionOrderRequest {
  vin: string;
  modelYear: number;
  makeCode: string;
  modelCode: string;
  plantCode: string;
  buildDate: string;
}

/** ProductionAllocateRequest.java */
export interface ProductionAllocateRequest {
  allocatedDealer: string;
  priority: string;
}

// ──────────────────────────────────────────────
// Shipment (ShipmentInfo to avoid DOM Shipment collision)
// ──────────────────────────────────────────────

/** ShipmentResponse.java */
export interface ShipmentInfo {
  shipmentId: string;
  carrierCode: string;
  carrierName: string;
  originPlant: string;
  destDealer: string;
  transportMode: string;
  vehicleCount: number;
  shipDate: string | null;
  estArrivalDate: string | null;
  actArrivalDate: string | null;
  shipmentStatus: string;
  statusName: string;
  vehicles: ShipmentVehicle[];
  createdTs: string;
  updatedTs: string;
}

/** ShipmentRequest.java */
export interface ShipmentRequest {
  carrierCode: string;
  carrierName: string;
  originPlant: string;
  destDealer: string;
  transportMode: string;
  shipDate: string;
  estArrivalDate: string;
}

/** ShipmentVehicleResponse.java */
export interface ShipmentVehicle {
  shipmentId: string;
  vin: string;
  vehicleDesc: string;
  loadSequence: number;
}

/** ShipmentVehicleRequest.java */
export interface ShipmentVehicleRequest {
  vin: string;
  loadSequence: number;
}

/** ShipmentDeliverRequest.java */
export interface ShipmentDeliverRequest {
  receivedBy: string;
  notes?: string;
}

// ──────────────────────────────────────────────
// Transit
// ──────────────────────────────────────────────

/** TransitStatusResponse.java */
export interface TransitStatusEntry {
  vin: string;
  statusSeq: number;
  locationDesc: string;
  statusCode: string;
  statusName: string;
  ediRefNum: string | null;
  statusTs: string;
  receivedTs: string;
}

/** TransitStatusRequest.java */
export interface TransitStatusRequest {
  vin: string;
  locationDesc: string;
  statusCode: string;
  ediRefNum?: string;
}

/** EtaResponse.java */
export interface EtaInfo {
  vin: string;
  vehicleDesc: string;
  shipmentId: string;
  currentLocation: string;
  daysInTransit: number;
  estimatedDaysRemaining: number;
  estArrivalDate: string;
  transportMode: string;
}

// ──────────────────────────────────────────────
// PDI (Pre-Delivery Inspection)
// ──────────────────────────────────────────────

/** PdiScheduleResponse.java */
export interface PdiScheduleItem {
  pdiId: number;
  vin: string;
  vehicleDesc: string;
  dealerCode: string;
  scheduledDate: string;
  technicianId: string | null;
  pdiStatus: string;
  statusName: string;
  checklistItems: number;
  itemsPassed: number;
  itemsFailed: number;
  notes: string | null;
  completedTs: string | null;
  passRate: number | null;
}

/** PdiScheduleRequest.java */
export interface PdiScheduleRequest {
  vin: string;
  dealerCode: string;
  scheduledDate: string;
  technicianId: string;
}

/** PdiCompleteRequest.java — used for both complete and fail */
export interface PdiCompleteRequest {
  itemsPassed: number;
  itemsFailed: number;
  notes?: string;
}

// ──────────────────────────────────────────────
// Production Reconciliation
// ──────────────────────────────────────────────

/** ProductionReconciliationResponse.java */
export interface ProductionReconciliation {
  totalProduced: number;
  totalAllocated: number;
  totalShipped: number;
  totalDelivered: number;
  exceptions: ReconciliationException[];
}

/** ProductionReconciliationResponse.ReconciliationException */
export interface ReconciliationException {
  vin: string;
  productionStatus: string;
  vehicleStatus: string;
  reasonCode: string;
  reasonDesc: string;
  daysSinceBuild: number;
  plantCode: string;
}
