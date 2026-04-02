import apiClient from './axios';
import type {
  Deal,
  CreateDealRequest,
  NegotiationRequest,
  NegotiationResponse,
  ValidationResponse,
  ApprovalRequest,
  ApprovalResponse,
  TradeInRequest,
  TradeInResponse,
  ApplyIncentivesRequest,
  CompletionRequest,
  CancellationRequest,
} from '@/types/sales';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';

export async function getDeals(params: {
  dealerCode: string;
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Deal>>(
    '/deals',
    { params },
  );
  return data;
}

export async function getDeal(dealNumber: string) {
  const { data } = await apiClient.get<ApiDataResponse<Deal>>(
    `/deals/${dealNumber}`,
  );
  return data.data;
}

export async function createDeal(request: CreateDealRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Deal>>(
    '/deals',
    request,
  );
  return data.data;
}

export async function negotiateDeal(dealNumber: string, request: NegotiationRequest) {
  const { data } = await apiClient.post<ApiDataResponse<NegotiationResponse>>(
    `/deals/${dealNumber}/negotiate`,
    request,
  );
  return data.data;
}

export async function validateDeal(dealNumber: string) {
  const { data } = await apiClient.post<ApiDataResponse<ValidationResponse>>(
    `/deals/${dealNumber}/validate`,
  );
  return data.data;
}

export async function approveDeal(dealNumber: string, request: ApprovalRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ApprovalResponse>>(
    `/deals/${dealNumber}/approve`,
    request,
  );
  return data.data;
}

export async function addTradeIn(dealNumber: string, request: TradeInRequest) {
  const { data } = await apiClient.post<ApiDataResponse<TradeInResponse>>(
    `/deals/${dealNumber}/trade-in`,
    request,
  );
  return data.data;
}

export async function applyIncentives(dealNumber: string, request: ApplyIncentivesRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Deal>>(
    `/deals/${dealNumber}/incentives`,
    request,
  );
  return data.data;
}

export async function completeDeal(dealNumber: string, request: CompletionRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Deal>>(
    `/deals/${dealNumber}/complete`,
    request,
  );
  return data.data;
}

export async function cancelDeal(dealNumber: string, request: CancellationRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Deal>>(
    `/deals/${dealNumber}/cancel`,
    request,
  );
  return data.data;
}
