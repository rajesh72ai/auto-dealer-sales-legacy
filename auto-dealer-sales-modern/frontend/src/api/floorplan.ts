import apiClient from './axios';
import type {
  FloorPlanVehicle,
  FloorPlanAddRequest,
  FloorPlanPayoffRequest,
  FloorPlanPayoffResponse,
  FloorPlanInterestRequest,
  FloorPlanInterestResponse,
  FloorPlanLender,
  FloorPlanExposureResponse,
} from '@/types/floorplan';
import type { PaginatedApiResponse, ApiDataResponse } from '@/types/admin';

// ──────────────────────────────────────────────
// Floor Plan Vehicles
// ──────────────────────────────────────────────

export async function listFloorPlanVehicles(params: {
  dealerCode: string;
  status?: string;
  lenderId?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<FloorPlanVehicle>>(
    '/floorplan/vehicles',
    { params },
  );
  return data;
}

export async function addVehicleToFloorPlan(request: FloorPlanAddRequest) {
  const { data } = await apiClient.post<ApiDataResponse<FloorPlanVehicle>>(
    '/floorplan/vehicles',
    request,
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Payoff
// ──────────────────────────────────────────────

export async function payoffFloorPlan(request: FloorPlanPayoffRequest) {
  const { data } = await apiClient.post<ApiDataResponse<FloorPlanPayoffResponse>>(
    '/floorplan/vehicles/payoff',
    request,
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Interest Accrual
// ──────────────────────────────────────────────

export async function calculateInterest(request: FloorPlanInterestRequest) {
  const { data } = await apiClient.post<ApiDataResponse<FloorPlanInterestResponse>>(
    '/floorplan/interest',
    request,
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Lenders
// ──────────────────────────────────────────────

export async function listLenders() {
  const { data } = await apiClient.get<ApiDataResponse<FloorPlanLender[]>>(
    '/floorplan/lenders',
  );
  return data.data;
}

// ──────────────────────────────────────────────
// Exposure Report
// ──────────────────────────────────────────────

export async function generateExposureReport(dealerCode: string) {
  const { data } = await apiClient.get<ApiDataResponse<FloorPlanExposureResponse>>(
    '/floorplan/reports/exposure',
    { params: { dealerCode } },
  );
  return data.data;
}
