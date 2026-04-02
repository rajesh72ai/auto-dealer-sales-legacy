import apiClient from './axios';
import type {
  FinanceApp,
  FinanceAppRequest,
  FinanceApprovalRequest,
  FinanceApprovalResponse,
  LoanCalculatorRequest,
  LoanCalculatorResponse,
  LeaseCalculatorRequest,
  LeaseCalculatorResponse,
  FinanceProductRequest,
  FinanceProductResponse,
  DealDocumentResponse,
} from '@/types/finance';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';

// ──────────────────────────────────────────────
// Finance Applications
// ──────────────────────────────────────────────

export async function listFinanceApps(params?: {
  dealNumber?: string;
  status?: string;
  financeType?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<FinanceApp>>(
    '/finance/applications',
    { params },
  );
  return data;
}

export async function getFinanceApp(financeId: string) {
  const { data } = await apiClient.get<ApiDataResponse<FinanceApp>>(
    `/finance/applications/${financeId}`,
  );
  return data.data;
}

export async function createFinanceApp(request: FinanceAppRequest) {
  const { data } = await apiClient.post<ApiDataResponse<FinanceApp>>(
    '/finance/applications',
    request,
  );
  return data.data;
}

export async function approveOrDeclineFinanceApp(request: FinanceApprovalRequest) {
  const { data } = await apiClient.post<ApiDataResponse<FinanceApprovalResponse>>(
    '/finance/applications/approve',
    request,
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Calculators
// ──────────────────────────────────────────────

export async function calculateLoan(request: LoanCalculatorRequest) {
  const { data } = await apiClient.post<ApiDataResponse<LoanCalculatorResponse>>(
    '/finance/applications/loan-calculator',
    request,
  );
  return data.data;
}

export async function calculateLease(request: LeaseCalculatorRequest) {
  const { data } = await apiClient.post<ApiDataResponse<LeaseCalculatorResponse>>(
    '/finance/applications/lease-calculator',
    request,
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Finance Products (F&I)
// ──────────────────────────────────────────────

export async function getProductCatalog(dealNumber: string) {
  const { data } = await apiClient.get<ApiDataResponse<FinanceProductResponse>>(
    `/finance/products/${dealNumber}`,
  );
  return data.data;
}

export async function selectProducts(request: FinanceProductRequest) {
  const { data } = await apiClient.post<ApiDataResponse<FinanceProductResponse>>(
    '/finance/products',
    request,
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Deal Documents
// ──────────────────────────────────────────────

export async function generateDealDocument(dealNumber: string) {
  const { data } = await apiClient.get<ApiDataResponse<DealDocumentResponse>>(
    `/finance/documents/${dealNumber}`,
  );
  return data.data;
}
