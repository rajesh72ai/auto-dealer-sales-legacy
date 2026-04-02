import apiClient from './axios';
import type {
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';
import type {
  StockPosition,
  StockSummary,
  StockAdjustment,
  StockAdjustmentRequest,
  AgingReport,
  StockAlert,
  StockHoldRequest,
  StockReleaseRequest,
  Reconciliation,
  StockValuation,
} from '@/types/vehicle';

export async function getStockPositions(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<StockPosition[]>>(
    '/stock/positions',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getStockSummary(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<StockSummary>>(
    '/stock/summary',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function createAdjustment(request: StockAdjustmentRequest) {
  const { data } = await apiClient.post<ApiDataResponse<StockAdjustment>>(
    '/stock/adjustments',
    request,
  );
  return data.data;
}

export async function getAdjustments(params: {
  dealerCode: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<StockAdjustment>>(
    '/stock/adjustments',
    { params },
  );
  return data;
}

export async function getAgingAnalysis(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<AgingReport>>(
    '/stock/aging',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getAlerts(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<StockAlert[]>>(
    '/stock/alerts',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function holdVehicle(vin: string, request: StockHoldRequest) {
  const { data } = await apiClient.post<ApiDataResponse<unknown>>(
    `/stock/${vin}/hold`,
    request,
  );
  return data.data;
}

export async function releaseVehicle(vin: string, request: StockReleaseRequest) {
  const { data } = await apiClient.post<ApiDataResponse<unknown>>(
    `/stock/${vin}/release`,
    request,
  );
  return data.data;
}

export async function reconcileStock(dealerCode: string) {
  const { data } = await apiClient.post<ApiDataResponse<Reconciliation>>(
    '/stock/reconcile',
    null,
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getValuation(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<StockValuation>>(
    '/stock/valuation',
    { params: { dealerCode } },
  );
  return data.data;
}
