import apiClient from './axios';
import type {
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';
import type { Snapshot, SnapshotCaptureRequest } from '@/types/vehicle';

export async function captureSnapshot(request: SnapshotCaptureRequest) {
  const { data } = await apiClient.post<ApiDataResponse<number>>(
    '/stock/snapshots/capture',
    request,
  );
  return data.data;
}

export async function getSnapshots(params: {
  dealerCode: string;
  from?: string;
  to?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<Snapshot>>(
    '/stock/snapshots',
    { params },
  );
  return data;
}
