import apiClient from './axios';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';
import type { SystemUserInfo, CreateUserRequest, UpdateUserRequest } from '@/types/user';

export async function getUsers(params?: {
  page?: number;
  size?: number;
  dealerCode?: string;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<SystemUserInfo>>(
    '/admin/users',
    { params },
  );
  return data;
}

export async function getUser(userId: string) {
  const { data } = await apiClient.get<ApiDataResponse<SystemUserInfo>>(
    `/admin/users/${userId}`,
  );
  return data.data;
}

export async function createUser(request: CreateUserRequest) {
  const { data } = await apiClient.post<ApiDataResponse<SystemUserInfo>>(
    '/admin/users',
    request,
  );
  return data.data;
}

export async function updateUser(userId: string, request: UpdateUserRequest) {
  const { data } = await apiClient.put<ApiDataResponse<SystemUserInfo>>(
    `/admin/users/${userId}`,
    request,
  );
  return data.data;
}

export async function resetPassword(userId: string, newPassword: string) {
  const { data } = await apiClient.post<ApiDataResponse<void>>(
    `/admin/users/${userId}/reset-password`,
    { newPassword },
  );
  return data;
}

export async function lockUser(userId: string) {
  const { data } = await apiClient.post<ApiDataResponse<SystemUserInfo>>(
    `/admin/users/${userId}/lock`,
  );
  return data.data;
}

export async function unlockUser(userId: string) {
  const { data } = await apiClient.post<ApiDataResponse<SystemUserInfo>>(
    `/admin/users/${userId}/unlock`,
  );
  return data.data;
}
