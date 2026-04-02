import apiClient from './axios';
import type {
  ModelMaster,
  ModelMasterRequest,
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';

export async function getModels(params?: {
  year?: number;
  make?: string;
  active?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<ModelMaster>>(
    '/admin/models',
    { params },
  );
  return data;
}

export async function getModel(year: number, make: string, model: string) {
  const { data } = await apiClient.get<ApiDataResponse<ModelMaster>>(
    `/admin/models/${year}/${make}/${model}`,
  );
  return data.data;
}

export async function createModel(request: ModelMasterRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ModelMaster>>(
    '/admin/models',
    request,
  );
  return data.data;
}

export async function updateModel(
  year: number,
  make: string,
  model: string,
  request: ModelMasterRequest,
) {
  const { data } = await apiClient.put<ApiDataResponse<ModelMaster>>(
    `/admin/models/${year}/${make}/${model}`,
    request,
  );
  return data.data;
}
