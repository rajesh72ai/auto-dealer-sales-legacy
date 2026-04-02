import apiClient from './axios';
import type { ApiDataResponse } from '@/types/admin';
import type { LotLocation, LotLocationRequest } from '@/types/vehicle';

export async function getLotLocations(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<LotLocation[]>>(
    '/lot-locations',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getLotLocation(dealerCode: string, locationCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<LotLocation>>(
    `/lot-locations/${dealerCode}/${locationCode}`,
  );
  return data.data;
}

export async function createLotLocation(request: LotLocationRequest) {
  const { data } = await apiClient.post<ApiDataResponse<LotLocation>>(
    '/lot-locations',
    request,
  );
  return data.data;
}

export async function updateLotLocation(
  dealerCode: string,
  locationCode: string,
  request: LotLocationRequest,
) {
  const { data } = await apiClient.put<ApiDataResponse<LotLocation>>(
    `/lot-locations/${dealerCode}/${locationCode}`,
    request,
  );
  return data.data;
}

export async function deactivateLotLocation(dealerCode: string, locationCode: string) {
  const { data } = await apiClient.delete<ApiDataResponse<LotLocation>>(
    `/lot-locations/${dealerCode}/${locationCode}`,
  );
  return data.data;
}

export async function assignVehicle(
  dealerCode: string,
  locationCode: string,
  vin: string,
) {
  const { data } = await apiClient.post<ApiDataResponse<void>>(
    `/lot-locations/${dealerCode}/${locationCode}/assign`,
    null,
    { params: { vin } },
  );
  return data.data;
}
