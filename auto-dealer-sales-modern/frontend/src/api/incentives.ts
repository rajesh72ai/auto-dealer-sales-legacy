import apiClient from './axios';
import type {
  IncentiveProgram,
  IncentiveProgramRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getIncentives(params?: {
  type?: string;
  active?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<IncentiveProgram>>(
    '/admin/incentives',
    { params },
  );
  return data;
}

export async function getIncentive(id: string) {
  const { data } = await apiClient.get<ApiDataResponse<IncentiveProgram>>(
    `/admin/incentives/${id}`,
  );
  return data.data;
}

export async function createIncentive(request: IncentiveProgramRequest) {
  const { data } = await apiClient.post<ApiDataResponse<IncentiveProgram>>(
    '/admin/incentives',
    request,
  );
  return data.data;
}

export async function updateIncentive(id: string, request: IncentiveProgramRequest) {
  const { data } = await apiClient.put<ApiDataResponse<IncentiveProgram>>(
    `/admin/incentives/${id}`,
    request,
  );
  return data.data;
}

export async function activateIncentive(id: string) {
  const { data } = await apiClient.patch<ApiDataResponse<IncentiveProgram>>(
    `/admin/incentives/${id}/activate`,
  );
  return data.data;
}

export async function deactivateIncentive(id: string) {
  const { data } = await apiClient.patch<ApiDataResponse<IncentiveProgram>>(
    `/admin/incentives/${id}/deactivate`,
  );
  return data.data;
}
