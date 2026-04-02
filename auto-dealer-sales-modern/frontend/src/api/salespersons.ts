import apiClient from './axios';
import type {
  Salesperson,
  SalespersonRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getSalespersons(params: {
  dealerCode: string;
  active?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Salesperson>>(
    '/admin/salespersons',
    { params },
  );
  return data;
}

export async function getSalesperson(id: string) {
  const { data } = await apiClient.get<ApiDataResponse<Salesperson>>(
    `/admin/salespersons/${id}`,
  );
  return data.data;
}

export async function createSalesperson(request: SalespersonRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Salesperson>>(
    '/admin/salespersons',
    request,
  );
  return data.data;
}

export async function updateSalesperson(id: string, request: SalespersonRequest) {
  const { data } = await apiClient.put<ApiDataResponse<Salesperson>>(
    `/admin/salespersons/${id}`,
    request,
  );
  return data.data;
}
