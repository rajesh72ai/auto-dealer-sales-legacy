import apiClient from './axios';
import type {
  SystemConfig,
  SystemConfigRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getConfigs(params?: {
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<SystemConfig>>(
    '/admin/config',
    { params },
  );
  return data;
}

export async function getConfig(key: string) {
  const { data } = await apiClient.get<ApiDataResponse<SystemConfig>>(
    `/admin/config/${key}`,
  );
  return data.data;
}

export async function updateConfig(key: string, request: SystemConfigRequest) {
  const { data } = await apiClient.put<ApiDataResponse<SystemConfig>>(
    `/admin/config/${key}`,
    request,
  );
  return data.data;
}
