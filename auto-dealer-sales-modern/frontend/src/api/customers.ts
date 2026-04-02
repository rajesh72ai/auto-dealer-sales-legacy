import apiClient from './axios';
import type {
  Customer,
  CustomerRequest,
  CustomerHistory,
} from '@/types/customer';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';

export async function getCustomers(params: {
  dealerCode: string;
  sort?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Customer>>(
    '/customers',
    { params },
  );
  return data;
}

export async function searchCustomers(params: {
  type: string;
  value: string;
  dealerCode: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Customer>>(
    '/customers/search',
    { params },
  );
  return data;
}

export async function getCustomer(id: number) {
  const { data } = await apiClient.get<ApiDataResponse<Customer>>(
    `/customers/${id}`,
  );
  return data.data;
}

export async function getCustomerHistory(id: number) {
  const { data } = await apiClient.get<ApiDataResponse<CustomerHistory>>(
    `/customers/${id}/history`,
  );
  return data.data;
}

export async function createCustomer(request: CustomerRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Customer>>(
    '/customers',
    request,
  );
  return data.data;
}

export async function updateCustomer(id: number, request: CustomerRequest) {
  const { data } = await apiClient.put<ApiDataResponse<Customer>>(
    `/customers/${id}`,
    request,
  );
  return data.data;
}
