import apiClient from './axios';
import type { CreditCheckRequest, CreditCheckResponse } from '@/types/customer';
import type { ApiDataResponse } from '@/types/admin';

export async function runCreditCheck(request: CreditCheckRequest) {
  const { data } = await apiClient.post<ApiDataResponse<CreditCheckResponse>>(
    '/credit-checks',
    request,
  );
  return data.data;
}

export async function getCreditCheck(id: number) {
  const { data } = await apiClient.get<ApiDataResponse<CreditCheckResponse>>(
    `/credit-checks/${id}`,
  );
  return data.data;
}

export async function getCreditChecksByCustomer(customerId: number) {
  const { data } = await apiClient.get<ApiDataResponse<CreditCheckResponse[]>>(
    `/credit-checks/customer/${customerId}`,
  );
  return data.data;
}
