import apiClient from './axios';
import type {
  Dealer,
  DealerRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getDealers(params?: {
  region?: string;
  active?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Dealer>>(
    '/admin/dealers',
    { params },
  );
  return data;
}

export async function getDealer(code: string) {
  const { data } = await apiClient.get<ApiDataResponse<Dealer>>(
    `/admin/dealers/${code}`,
  );
  return data.data;
}

export async function createDealer(request: DealerRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Dealer>>(
    '/admin/dealers',
    request,
  );
  return data.data;
}

export async function updateDealer(code: string, request: DealerRequest) {
  const { data } = await apiClient.put<ApiDataResponse<Dealer>>(
    `/admin/dealers/${code}`,
    request,
  );
  return data.data;
}
