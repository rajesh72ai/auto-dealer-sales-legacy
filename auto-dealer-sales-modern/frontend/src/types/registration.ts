// ──────────────────────────────────────────────
// Registration & Title
// ──────────────────────────────────────────────

export interface Registration {
  regId: string;
  dealNumber: string;
  vin: string;
  customerId: number;
  regState: string;
  regType: string;
  plateNumber: string | null;
  titleNumber: string | null;
  lienHolder: string | null;
  lienHolderAddr: string | null;
  regStatus: string;
  submissionDate: string | null;
  issuedDate: string | null;
  regFeePaid: number;
  titleFeePaid: number;
  createdTs: string;
  updatedTs: string;
  regTypeName: string;
  regStatusName: string;
  formattedRegFee: string;
  formattedTitleFee: string;
  statusHistory: TitleStatus[];
}

export interface TitleStatus {
  regId: string;
  statusSeq: number;
  statusCode: string;
  statusDesc: string;
  statusTs: string;
  statusName: string;
}

export interface RegistrationRequest {
  dealNumber: string;
  vin: string;
  customerId: number;
  regState: string;
  regType: string;
  lienHolder?: string;
  lienHolderAddr?: string;
  regFeePaid?: number;
  titleFeePaid?: number;
}

export interface RegistrationStatusUpdateRequest {
  newStatus: string;
  plateNumber?: string;
  titleNumber?: string;
  statusDesc?: string;
}

// ──────────────────────────────────────────────
// Warranty
// ──────────────────────────────────────────────

export interface Warranty {
  warrantyId: number;
  vin: string;
  dealNumber: string;
  warrantyType: string;
  startDate: string;
  expiryDate: string;
  mileageLimit: number;
  deductible: number;
  activeFlag: string;
  registeredTs: string;
  warrantyTypeName: string;
  formattedDeductible: string;
  status: string;
  remainingDays: number;
}

// ──────────────────────────────────────────────
// Warranty Claims
// ──────────────────────────────────────────────

export interface WarrantyClaim {
  claimNumber: string;
  vin: string;
  dealerCode: string;
  claimType: string;
  claimDate: string;
  repairDate: string | null;
  laborAmt: number;
  partsAmt: number;
  totalClaim: number;
  claimStatus: string;
  technicianId: string | null;
  repairOrderNum: string | null;
  notes: string | null;
  createdTs: string;
  updatedTs: string;
  claimTypeName: string;
  claimStatusName: string;
  formattedLabor: string;
  formattedParts: string;
  formattedTotal: string;
}

export interface WarrantyClaimRequest {
  vin: string;
  dealerCode: string;
  claimType: string;
  claimDate: string;
  repairDate?: string;
  laborAmt: number;
  partsAmt: number;
  technicianId?: string;
  repairOrderNum?: string;
  notes?: string;
  claimStatus?: string;
}

export interface ClaimTypeSummary {
  claimType: string;
  claimTypeName: string;
  totalClaims: number;
  laborTotal: number;
  partsTotal: number;
  claimTotal: number;
  approvedCount: number;
  deniedCount: number;
}

export interface WarrantyClaimSummary {
  dealerCode: string;
  fromDate: string | null;
  toDate: string | null;
  byType: ClaimTypeSummary[];
  grandTotalClaims: number;
  grandTotalLabor: number;
  grandTotalParts: number;
  grandTotal: number;
  averageClaimAmount: number;
  totalApproved: number;
  totalDenied: number;
}

// ──────────────────────────────────────────────
// Recall Campaigns
// ──────────────────────────────────────────────

export interface RecallCampaign {
  recallId: string;
  nhtsaNum: string | null;
  recallDesc: string;
  severity: string;
  affectedYears: string;
  affectedModels: string;
  remedyDesc: string;
  remedyAvailDt: string | null;
  announcedDate: string;
  totalAffected: number;
  totalCompleted: number;
  campaignStatus: string;
  createdTs: string;
  severityName: string;
  campaignStatusName: string;
  completionPercentage: number;
}

export interface RecallCampaignRequest {
  recallId: string;
  nhtsaNum?: string;
  recallDesc: string;
  severity: string;
  affectedYears: string;
  affectedModels: string;
  remedyDesc: string;
  remedyAvailDt?: string;
  announcedDate: string;
}

export interface RecallVehicle {
  recallId: string;
  vin: string;
  dealerCode: string | null;
  recallStatus: string;
  notifiedDate: string | null;
  scheduledDate: string | null;
  completedDate: string | null;
  technicianId: string | null;
  partsOrdered: string;
  partsAvail: string;
  recallStatusName: string;
}

export interface RecallVehicleStatusRequest {
  newStatus: string;
  scheduledDate?: string;
  technicianId?: string;
}

export interface RecallNotification {
  notifId: number;
  recallId: string;
  vin: string;
  customerId: number | null;
  notifType: string;
  notifDate: string;
  responseFlag: string;
  notifTypeName: string;
}
