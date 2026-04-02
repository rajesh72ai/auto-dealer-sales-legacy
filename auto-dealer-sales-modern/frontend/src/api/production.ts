import apiClient from './axios';
import type {
  PaginatedApiResponse,
  ApiDataResponse,
} from '@/types/admin';
import type {
  ProductionOrder,
  ProductionOrderRequest,
  ProductionAllocateRequest,
  ShipmentInfo,
  ShipmentRequest,
  ShipmentVehicleRequest,
  ShipmentDeliverRequest,
  TransitStatusEntry,
  TransitStatusRequest,
  EtaInfo,
  PdiScheduleItem,
  PdiScheduleRequest,
  PdiCompleteRequest,
  ProductionReconciliation,
} from '@/types/vehicle';

// ══════════════════════════════════════════════
// Production Orders
// ══════════════════════════════════════════════

export async function createOrder(request: ProductionOrderRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ProductionOrder>>(
    '/production/orders',
    request,
  );
  return data.data;
}

export async function listOrders(params: {
  status?: string;
  plantCode?: string;
  dealer?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<ProductionOrder>>(
    '/production/orders',
    { params },
  );
  return data;
}

export async function getOrder(id: string) {
  const { data } = await apiClient.get<ApiDataResponse<ProductionOrder>>(
    `/production/orders/${id}`,
  );
  return data.data;
}

export async function updateOrder(id: string, request: ProductionOrderRequest) {
  const { data } = await apiClient.put<ApiDataResponse<ProductionOrder>>(
    `/production/orders/${id}`,
    request,
  );
  return data.data;
}

export async function allocateOrder(id: string, request: ProductionAllocateRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ProductionOrder>>(
    `/production/orders/${id}/allocate`,
    request,
  );
  return data.data;
}

// ══════════════════════════════════════════════
// Shipments
// ══════════════════════════════════════════════

export async function createShipment(request: ShipmentRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ShipmentInfo>>(
    '/production/shipments',
    request,
  );
  return data.data;
}

export async function listShipments(params: {
  status?: string;
  dealer?: string;
  carrier?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<ShipmentInfo>>(
    '/production/shipments',
    { params },
  );
  return data;
}

export async function getShipment(id: string) {
  const { data } = await apiClient.get<ApiDataResponse<ShipmentInfo>>(
    `/production/shipments/${id}`,
  );
  return data.data;
}

export async function addVehicleToShipment(id: string, request: ShipmentVehicleRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ShipmentInfo>>(
    `/production/shipments/${id}/vehicles`,
    request,
  );
  return data.data;
}

export async function dispatchShipment(id: string) {
  const { data } = await apiClient.post<ApiDataResponse<ShipmentInfo>>(
    `/production/shipments/${id}/dispatch`,
  );
  return data.data;
}

export async function deliverShipment(id: string, request: ShipmentDeliverRequest) {
  const { data } = await apiClient.post<ApiDataResponse<ShipmentInfo>>(
    `/production/shipments/${id}/deliver`,
    request,
  );
  return data.data;
}

// ══════════════════════════════════════════════
// Transit
// ══════════════════════════════════════════════

export async function addTransitStatus(request: TransitStatusRequest) {
  const { data } = await apiClient.post<ApiDataResponse<TransitStatusEntry>>(
    '/production/transit',
    request,
  );
  return data.data;
}

export async function getTransitHistory(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<TransitStatusEntry[]>>(
    `/production/transit/${vin}`,
  );
  return data.data;
}

export async function calculateEta(vin: string) {
  const { data } = await apiClient.get<ApiDataResponse<EtaInfo>>(
    `/production/transit/${vin}/eta`,
  );
  return data.data;
}

// ══════════════════════════════════════════════
// PDI (Pre-Delivery Inspection)
// ══════════════════════════════════════════════

export async function schedulePdi(request: PdiScheduleRequest) {
  const { data } = await apiClient.post<ApiDataResponse<PdiScheduleItem>>(
    '/production/pdi/schedule',
    request,
  );
  return data.data;
}

export async function listPdiSchedules(params: {
  dealerCode: string;
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await apiClient.get<PaginatedApiResponse<PdiScheduleItem>>(
    '/production/pdi/schedule',
    { params },
  );
  return data;
}

export async function startPdi(pdiId: number, technicianId: string) {
  const { data } = await apiClient.post<ApiDataResponse<PdiScheduleItem>>(
    `/production/pdi/${pdiId}/start`,
    null,
    { params: { technicianId } },
  );
  return data.data;
}

export async function completePdi(pdiId: number, request: PdiCompleteRequest) {
  const { data } = await apiClient.post<ApiDataResponse<PdiScheduleItem>>(
    `/production/pdi/${pdiId}/complete`,
    request,
  );
  return data.data;
}

export async function failPdi(pdiId: number, request: PdiCompleteRequest) {
  const { data } = await apiClient.post<ApiDataResponse<PdiScheduleItem>>(
    `/production/pdi/${pdiId}/fail`,
    request,
  );
  return data.data;
}

// ══════════════════════════════════════════════
// Reconciliation
// ══════════════════════════════════════════════

export async function reconcileProduction(params: {
  plantCode?: string;
  modelYear?: number;
  makeCode?: string;
}) {
  const { data } = await apiClient.post<ApiDataResponse<ProductionReconciliation>>(
    '/production/reconcile',
    null,
    { params },
  );
  return data.data;
}
