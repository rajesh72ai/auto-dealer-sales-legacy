import apiClient from './axios';
import type {
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';
import type {
  Transfer,
  TransferRequest,
  TransferApprovalRequest,
} from '@/types/vehicle';

export async function requestTransfer(request: TransferRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Transfer>>(
    '/stock/transfers',
    request,
  );
  return data.data;
}

export async function getTransfers(params: {
  dealerCode: string;
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Transfer>>(
    '/stock/transfers',
    { params },
  );
  return data;
}

export async function getTransfer(id: number) {
  const { data } = await apiClient.get<ApiDataResponse<Transfer>>(
    `/stock/transfers/${id}`,
  );
  return data.data;
}

export async function approveTransfer(id: number, request: TransferApprovalRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Transfer>>(
    `/stock/transfers/${id}/approve`,
    request,
  );
  return data.data;
}

export async function completeTransfer(id: number) {
  const { data } = await apiClient.post<ApiDataResponse<Transfer>>(
    `/stock/transfers/${id}/complete`,
  );
  return data.data;
}

export async function cancelTransfer(id: number) {
  const { data } = await apiClient.post<ApiDataResponse<Transfer>>(
    `/stock/transfers/${id}/cancel`,
  );
  return data.data;
}
