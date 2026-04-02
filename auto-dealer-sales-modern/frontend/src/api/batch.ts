import apiClient from './axios';
import type { ApiDataResponse } from '@/types/admin';
import type {
  BatchJob,
  BatchRunResult,
  Checkpoint,
  CheckpointActionRequest,
  DailySalesSummary,
  MonthlySnapshot,
  Commission,
  ValidationReport,
  GlPostingResult,
  CrmExtractResult,
  DataLakeExtractResult,
  DmsExtractResult,
  InboundVehicleRequest,
  InboundProcessingResult,
  PurgeResult,
} from '@/types/batch';

// ── Batch Job Management ──────────────────────

export async function getBatchJobs() {
  const { data } = await apiClient.get<ApiDataResponse<BatchJob[]>>('/batch/jobs');
  return data.data;
}

export async function getBatchJob(programId: string) {
  const { data } = await apiClient.get<ApiDataResponse<BatchJob>>(
    `/batch/jobs/${programId}`,
  );
  return data.data;
}

// ── Checkpoint Operations ─────────────────────

export async function getCheckpoints(programId: string) {
  const { data } = await apiClient.get<ApiDataResponse<Checkpoint[]>>(
    `/batch/jobs/${programId}/checkpoints`,
  );
  return data.data;
}

export async function executeCheckpointAction(request: CheckpointActionRequest) {
  const { data } = await apiClient.post<ApiDataResponse<Checkpoint>>(
    '/batch/jobs/checkpoints/action',
    request,
  );
  return data.data;
}

// ── Batch Job Execution ───────────────────────

export async function runDailyBatch() {
  const { data } = await apiClient.post<ApiDataResponse<BatchRunResult>>(
    '/batch/jobs/run/daily',
  );
  return data.data;
}

export async function runMonthlyBatch() {
  const { data } = await apiClient.post<ApiDataResponse<BatchRunResult>>(
    '/batch/jobs/run/monthly',
  );
  return data.data;
}

export async function runWeeklyBatch() {
  const { data } = await apiClient.post<ApiDataResponse<BatchRunResult>>(
    '/batch/jobs/run/weekly',
  );
  return data.data;
}

export async function runPurgeBatch() {
  const { data } = await apiClient.post<ApiDataResponse<BatchRunResult>>(
    '/batch/jobs/run/purge',
  );
  return data.data;
}

export async function runValidationBatch() {
  const { data } = await apiClient.post<ApiDataResponse<BatchRunResult>>(
    '/batch/jobs/run/validation',
  );
  return data.data;
}

export async function runGlPostingBatch() {
  const { data } = await apiClient.post<ApiDataResponse<BatchRunResult>>(
    '/batch/jobs/run/gl-posting',
  );
  return data.data;
}

export async function runCrmExtract() {
  const { data } = await apiClient.post<ApiDataResponse<CrmExtractResult>>(
    '/batch/jobs/run/crm-extract',
  );
  return data.data;
}

export async function runDmsExtract() {
  const { data } = await apiClient.post<ApiDataResponse<DmsExtractResult>>(
    '/batch/jobs/run/dms-extract',
  );
  return data.data;
}

export async function runDataLakeExtract() {
  const { data } = await apiClient.post<ApiDataResponse<DataLakeExtractResult>>(
    '/batch/jobs/run/datalake-extract',
  );
  return data.data;
}

export async function runInboundProcessing(records: InboundVehicleRequest[]) {
  const { data } = await apiClient.post<ApiDataResponse<InboundProcessingResult>>(
    '/batch/jobs/run/inbound',
    records,
  );
  return data.data;
}

// ── Reporting Endpoints ───────────────────────

export async function getDailySales(params: {
  dealerCode: string;
  startDate: string;
  endDate: string;
}) {
  const { data } = await apiClient.get<ApiDataResponse<DailySalesSummary[]>>(
    '/batch/reports/daily-sales',
    { params },
  );
  return data.data;
}

export async function getMonthlySnapshots(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<MonthlySnapshot[]>>(
    '/batch/reports/monthly-snapshots',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getCommissions(dealerCode: string, payPeriod: string) {
  const { data } = await apiClient.get<ApiDataResponse<Commission[]>>(
    '/batch/reports/commissions',
    { params: { dealerCode, payPeriod } },
  );
  return data.data;
}

export async function getUnpaidCommissions(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<Commission[]>>(
    '/batch/reports/commissions/unpaid',
    { params: { dealerCode } },
  );
  return data.data;
}

export async function getValidationReport() {
  const { data } = await apiClient.get<ApiDataResponse<ValidationReport>>(
    '/batch/reports/validation',
  );
  return data.data;
}

export async function getGlPostingPreview() {
  const { data } = await apiClient.get<ApiDataResponse<GlPostingResult>>(
    '/batch/reports/gl-postings',
  );
  return data.data;
}

export async function getPurgePreview() {
  const { data } = await apiClient.get<ApiDataResponse<PurgeResult>>(
    '/batch/reports/purge-preview',
  );
  return data.data;
}
