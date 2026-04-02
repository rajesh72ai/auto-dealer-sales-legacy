import apiClient from './axios';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';
import type {
  Warranty,
  WarrantyClaim,
  WarrantyClaimRequest,
  WarrantyClaimSummary,
  RecallCampaign,
  RecallCampaignRequest,
  RecallVehicle,
  RecallVehicleStatusRequest,
  RecallNotification,
} from '@/types/registration';

// ─── Warranty Coverage ──────────────────────────────────────────────

export async function getWarrantiesByVin(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<Warranty[]>>(
    `/warranties/by-vin/${vin}`,
  );
  return data.data;
}

export async function getWarrantiesByDeal(dealNumber: string) {
  const { data } = await apiClient.get<ApiDataResponse<Warranty[]>>(
    `/warranties/by-deal/${dealNumber}`,
  );
  return data.data;
}

export async function registerWarranties(vin: string, dealNumber: string, saleDate: string) {
  const { data } = await apiClient.post<ApiDataResponse<Warranty[]>>(
    '/warranties/register',
    null,
    { params: { vin, dealNumber, saleDate } },
  );
  return data.data;
}

// ─── Warranty Claims ────────────────────────────────────────────────

export async function getWarrantyClaims(params: {
  dealerCode: string;
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<WarrantyClaim>>(
    '/warranty-claims',
    { params },
  );
  return data;
}

export async function getWarrantyClaim(claimNumber: string) {
  const { data } = await apiClient.get<ApiDataResponse<WarrantyClaim>>(
    `/warranty-claims/${claimNumber}`,
  );
  return data.data;
}

export async function createWarrantyClaim(request: WarrantyClaimRequest) {
  const { data } = await apiClient.post<ApiDataResponse<WarrantyClaim>>(
    '/warranty-claims',
    request,
  );
  return data.data;
}

export async function updateWarrantyClaim(claimNumber: string, request: WarrantyClaimRequest) {
  const { data } = await apiClient.put<ApiDataResponse<WarrantyClaim>>(
    `/warranty-claims/${claimNumber}`,
    request,
  );
  return data.data;
}

export async function getWarrantyClaimReport(params: {
  dealerCode: string;
  fromDate?: string;
  toDate?: string;
}) {
  const { data } = await apiClient.get<ApiDataResponse<WarrantyClaimSummary>>(
    '/warranty-claims/report',
    { params },
  );
  return data.data;
}

// ─── Recall Campaigns ───────────────────────────────────────────────

export async function getRecallCampaigns(params: {
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<RecallCampaign>>(
    '/recalls',
    { params },
  );
  return data;
}

export async function getRecallCampaign(recallId: string) {
  const { data } = await apiClient.get<ApiDataResponse<RecallCampaign>>(
    `/recalls/${recallId}`,
  );
  return data.data;
}

export async function createRecallCampaign(request: RecallCampaignRequest) {
  const { data } = await apiClient.post<ApiDataResponse<RecallCampaign>>(
    '/recalls',
    request,
  );
  return data.data;
}

// ─── Recall Vehicles ────────────────────────────────────────────────

export async function getRecallVehicles(recallId: string, params: {
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<RecallVehicle>>(
    `/recalls/${recallId}/vehicles`,
    { params },
  );
  return data;
}

export async function addRecallVehicle(recallId: string, vin: string, dealerCode?: string) {
  const { data } = await apiClient.post<ApiDataResponse<RecallVehicle>>(
    `/recalls/${recallId}/vehicles`,
    null,
    { params: { vin, dealerCode } },
  );
  return data.data;
}

export async function updateRecallVehicleStatus(
  recallId: string,
  vin: string,
  request: RecallVehicleStatusRequest,
) {
  const { data } = await apiClient.patch<ApiDataResponse<RecallVehicle>>(
    `/recalls/${recallId}/vehicles/${vin}/status`,
    request,
  );
  return data.data;
}

export async function getRecallsByVin(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<RecallVehicle[]>>(
    `/recalls/by-vin/${vin}`,
  );
  return data.data;
}

// ─── Recall Notifications ───────────────────────────────────────────

export async function getRecallNotifications(recallId: string) {
  const { data } = await apiClient.get<ApiDataResponse<RecallNotification[]>>(
    `/recalls/${recallId}/notifications`,
  );
  return data.data;
}

export async function createRecallNotification(
  recallId: string,
  vin: string,
  customerId?: number,
  notifType?: string,
) {
  const { data } = await apiClient.post<ApiDataResponse<RecallNotification>>(
    `/recalls/${recallId}/notifications`,
    null,
    { params: { vin, customerId, notifType } },
  );
  return data.data;
}
