import apiClient from './axios';
import type { ApiDataResponse } from '@/types/admin';
import type { VinDecodedInfo } from '@/types/vin';

export async function decodeVin(vin: string): Promise<VinDecodedInfo> {
  const { data } = await apiClient.get<ApiDataResponse<VinDecodedInfo>>(
    `/vin/decode/${encodeURIComponent(vin)}`,
  );
  return data.data;
}
