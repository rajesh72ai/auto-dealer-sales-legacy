import apiClient from './axios';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';
import type {
  Registration,
  RegistrationRequest,
  RegistrationStatusUpdateRequest,
} from '@/types/registration';

export async function getRegistrations(params: {
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Registration>>(
    '/registrations',
    { params },
  );
  return data;
}

export async function getRegistration(regId: string) {
  const { data } = await apiClient.get<ApiDataResponse<Registration>>(
    `/registrations/${regId}`,
  );
  return data.data;
}

export async function getRegistrationByDeal(dealNumber: string) {
  const { data } = await apiClient.get<ApiDataResponse<Registration>>(
    `/registrations/by-deal/${dealNumber}`,
  );
  return data.data;
}

export async function getRegistrationsByVin(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<Registration[]>>(
    `/registrations/by-vin/${vin}`,
  );
  return data.data;
}

export async function createRegistration(request: RegistrationRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Registration>>(
    '/registrations',
    request,
  );
  return data.data;
}

export async function validateRegistration(regId: string) {
  const { data } = await apiClient.post<ApiDataResponse<Registration>>(
    `/registrations/${regId}/validate`,
  );
  return data.data;
}

export async function submitRegistration(regId: string) {
  const { data } = await apiClient.post<ApiDataResponse<Registration>>(
    `/registrations/${regId}/submit`,
  );
  return data.data;
}

export async function updateRegistrationStatus(
  regId: string,
  request: RegistrationStatusUpdateRequest,
) {
  const { data } = await apiClient.patch<ApiDataResponse<Registration>>(
    `/registrations/${regId}/status`,
    request,
  );
  return data.data;
}
