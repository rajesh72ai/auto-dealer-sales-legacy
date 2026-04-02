import apiClient from './axios';
import type {
  PriceMaster,
  PriceMasterRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getPricing(params?: {
  year?: number;
  make?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<PriceMaster>>(
    '/admin/pricing',
    { params },
  );
  return data;
}

export async function getPrice(year: number, make: string, model: string) {
  const { data } = await apiClient.get<ApiDataResponse<PriceMaster>>(
    `/admin/pricing/${year}/${make}/${model}`,
  );
  return data.data;
}

export async function createPrice(request: PriceMasterRequest) {
  const { data } = await apiClient.post<ApiDataResponse<PriceMaster>>(
    '/admin/pricing',
    request,
  );
  return data.data;
}

export async function updatePrice(
  year: number,
  make: string,
  model: string,
  request: PriceMasterRequest,
) {
  const { data } = await apiClient.put<ApiDataResponse<PriceMaster>>(
    `/admin/pricing/${year}/${make}/${model}`,
    request,
  );
  return data.data;
}

export async function getPriceHistory(year: number, make: string, model: string) {
  const { data } = await apiClient.get<PaginatedApiResponse<PriceMaster>>(
    `/admin/pricing/${year}/${make}/${model}/history`,
  );
  return data;
}

export async function getCurrentEffectivePrice(year: number, make: string, model: string) {
  const { data } = await apiClient.get<ApiDataResponse<PriceMaster>>(
    `/admin/pricing/${year}/${make}/${model}/effective`,
  );
  return data.data;
}
