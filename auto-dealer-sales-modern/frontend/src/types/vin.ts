// ──────────────────────────────────────────────
// VIN Decode types
// Maps to com.autosales.common.util.VinDecodedInfo
// ──────────────────────────────────────────────

export interface VinDecodedInfo {
  wmi: string;
  countryOfOrigin: string;
  manufacturer: string;
  modelYear: number;
  plantCode: string;
  sequentialNumber: string;
}
