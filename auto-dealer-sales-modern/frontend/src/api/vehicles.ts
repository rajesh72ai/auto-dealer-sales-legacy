import apiClient from './axios';
import type {
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';
import type {
  Vehicle,
  VehicleListItem,
  VehicleUpdateRequest,
  VehicleReceiveRequest,
  VehicleAllocateRequest,
  VehicleHistoryEntry,
  AgingReport,
} from '@/types/vehicle';

export async function getVehicles(params: {
  dealerCode: string;
  status?: string;
  modelYear?: number;
  makeCode?: string;
  modelCode?: string;
  color?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<VehicleListItem>>(
    '/vehicles',
    { params },
  );
  return data;
}

export async function getVehicle(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<Vehicle>>(
    `/vehicles/${vin}`,
  );
  return data.data;
}

export async function updateVehicle(vin: string, request: VehicleUpdateRequest) {
  const { data } = await apiClient.put<ApiDataResponse<Vehicle>>(
    `/vehicles/${vin}`,
    request,
  );
  return data.data;
}

export async function receiveVehicle(vin: string, request: VehicleReceiveRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Vehicle>>(
    `/vehicles/${vin}/receive`,
    request,
  );
  return data.data;
}

export async function allocateVehicle(vin: string, request: VehicleAllocateRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Vehicle>>(
    `/vehicles/${vin}/allocate`,
    request,
  );
  return data.data;
}

export async function getAgingReport(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<AgingReport>>(
    '/vehicles/aging',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getVehicleHistory(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<VehicleHistoryEntry[]>>(
    `/vehicles/${vin}/history`,
  );
  return data.data;
}
