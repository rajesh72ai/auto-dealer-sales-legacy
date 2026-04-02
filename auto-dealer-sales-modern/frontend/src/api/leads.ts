import apiClient from './axios';
import type { Lead, LeadRequest } from '@/types/customer';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';

export async function getLeads(params: {
  dealerCode: string;
  status?: string;
  assignedSales?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Lead>>(
    '/leads',
    { params },
  );
  return data;
}

export async function getLead(id: number) {
  const { data } = await apiClient.get<ApiDataResponse<Lead>>(
    `/leads/${id}`,
  );
  return data.data;
}

export async function createLead(request: LeadRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Lead>>(
    '/leads',
    request,
  );
  return data.data;
}

export async function updateLeadStatus(id: number, status: string) {
  const { data } = await apiClient.patch<ApiDataResponse<Lead>>(
    `/leads/${id}/status`,
    null,
    { params: { status } },
  );
  return data.data;
}
