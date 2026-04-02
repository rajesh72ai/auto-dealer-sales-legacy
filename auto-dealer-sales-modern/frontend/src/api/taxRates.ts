import apiClient from './axios';
import type {
  TaxRate,
  TaxRateRequest,
  TaxCalculationRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getTaxRates(params?: {
  state?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<TaxRate>>(
    '/admin/tax-rates',
    { params },
  );
  return data;
}

export async function getTaxRate(state: string, county: string, city: string) {
  const { data } = await apiClient.get<ApiDataResponse<TaxRate>>(
    `/admin/tax-rates/${state}/${county}/${city}`,
  );
  return data.data;
}

export async function createTaxRate(request: TaxRateRequest) {
  const { data } = await apiClient.post<ApiDataResponse<TaxRate>>(
    '/admin/tax-rates',
    request,
  );
  return data.data;
}

export async function updateTaxRate(
  state: string,
  county: string,
  city: string,
  request: TaxRateRequest,
) {
  const { data } = await apiClient.put<ApiDataResponse<TaxRate>>(
    `/admin/tax-rates/${state}/${county}/${city}`,
    request,
  );
  return data.data;
}

export async function calculateTax(request: TaxCalculationRequest) {
  const { data } = await apiClient.post<ApiDataResponse<TaxRate>>(
    '/admin/tax-rates/calculate',
    request,
  );
  return data.data;
}
