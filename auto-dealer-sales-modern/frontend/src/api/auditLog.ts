import apiClient from './axios';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';

export interface AuditLogEntry {
  auditId: number;
  userId: string;
  programId: string | null;
  actionType: string;   // INS, UPD, DEL, APV
  tableName: string;
  keyValue: string;
  oldValue: string | null;
  newValue: string | null;
  auditTs: string;
}

export interface AuditLogSearchParams {
  userId?: string;
  tableName?: string;
  actionType?: string;
  from?: string;
  to?: string;
  page?: number;
  size?: number;
}

export async function searchAuditLog(params: AuditLogSearchParams) {
  const { data } = await apiClient.get<PaginatedApiResponse<AuditLogEntry>>(
    '/admin/audit-log',
    { params },
  );
  return data;
}

export async function getAuditStats() {
  const { data } = await apiClient.get<ApiDataResponse<Record<string, number>>>(
    '/admin/audit-log/stats',
  );
  return data.data;
}
