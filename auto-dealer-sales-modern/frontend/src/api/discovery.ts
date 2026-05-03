const BASE = '/api/admin/discovery';

export interface AutoToolDescriptor {
  name: string;
  httpMethod: string;
  path: string;
  controller: string;
  javaMethod: string;
  description: string;
  parameters: { name: string; type: string; kind: string; required?: string }[];
  safetyLevel: string; // PUBLIC_READ | INTERNAL_READ | WRITE_VIA_PROPOSE | WRITE | ADMIN_ONLY | AGENT_NO
  tags: string[];
}

export interface DiscoveryStats {
  totalEndpoints: number;
  modules: number;
  publicReads: number;
  internalReads: number;
  writesViaPropose: number;
  otherWrites: number;
  adminOnly: number;
  agentNo: number;
  agentDiscoverable: number;
}

export interface ByModuleResponse {
  modules: Record<string, AutoToolDescriptor[]>;
  countsByLevel: Record<string, number>;
  totalEndpoints: number;
}

export interface CatalogResponse {
  total: number;
  totalUnfiltered: number;
  countsByLevel: Record<string, number>;
  descriptors: AutoToolDescriptor[];
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function getByModule(): Promise<ByModuleResponse | null> {
  try {
    const r = await fetch(`${BASE}/by-module`, { headers: authHeaders() });
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}

export async function searchCatalog(params: {
  search?: string;
  safetyLevel?: string;
  httpMethod?: string;
  tag?: string;
}): Promise<CatalogResponse | null> {
  const qs = new URLSearchParams();
  if (params.search) qs.set('search', params.search);
  if (params.safetyLevel) qs.set('safetyLevel', params.safetyLevel);
  if (params.httpMethod) qs.set('httpMethod', params.httpMethod);
  if (params.tag) qs.set('tag', params.tag);
  try {
    const r = await fetch(`${BASE}/catalog?${qs.toString()}`, { headers: authHeaders() });
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}

export async function getStats(): Promise<DiscoveryStats | null> {
  try {
    const r = await fetch(`${BASE}/stats`, { headers: authHeaders() });
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}
