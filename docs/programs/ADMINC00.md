# ADMINC00 — Incentive Program Setup

## Overview
- **Program ID:** ADMINC00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMI
- **Source:** cbl/online/adm/ADMINC00.cbl
- **Lines of Code:** 1049
- **Complexity:** High

## Purpose
Manages the lifecycle of incentive programs (rebates, dealer cash, loyalty credits, etc.) via the INCENTIVE_PROGRAM table. Supports inquiry, add, update, activate, and deactivate operations. Validates date ranges, amounts, max units, model eligibility, and incentive type codes. Tracks units used vs. units remaining.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADINC (Incentive Program Screen)
- **MFS Output (MOD):** ASINCI00 (Incentive Inquiry Response)
- **Message Format:** Input includes function (INQ/ADD/UPD/ACT/DEAC), incentive ID (10), name (60), type (2), model year, make code, model code, region, amount (12), rate override (6), start/end dates, max units, stackable flag, user ID. Output includes decoded type description, formatted amounts, units used/remaining, active status.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.INCENTIVE_PROGRAM | SELECT | Inquiry by incentive ID |
| AUTOSALE.INCENTIVE_PROGRAM | INSERT | Add new incentive program |
| AUTOSALE.INCENTIVE_PROGRAM | UPDATE | Update incentive details |
| AUTOSALE.INCENTIVE_PROGRAM | UPDATE | Activate (set ACTIVE_FLAG='Y') |
| AUTOSALE.INCENTIVE_PROGRAM | UPDATE | Deactivate (set ACTIVE_FLAG='N') |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging for all data changes |
| COMDBEL0 | DB2 error handling |
| COMFMTL0 | Format currency amounts |

### Key Business Logic
- **Incentive types:** CR (Customer Rebate), RF (Rate Finance), DL (Dealer Cash), LR (Lease Rebate), LC (Loyalty Credit), BD (Bonus/Stair-Step). Validated against a hardcoded table of 6 entries.
- **Date validation:** End date must be after start date. Both dates required for add/update.
- **Amount validation:** Must be greater than zero.
- **Max units:** Optional, but if provided must be numeric and greater than zero.
- **Model year:** Optional, validated as numeric if provided.
- **Nullable fields:** Model year, make code, model code, region code, rate override, and max units all support null indicators — allowing incentives to apply broadly when these are not specified.
- **Activate/Deactivate:** ACT sets ACTIVE_FLAG='Y' only if currently 'N'; DEAC sets to 'N' only if currently 'Y'. Both log old/new flag values to audit.
- **Units tracking:** On inquiry, computes remaining units as MAX_UNITS minus UNITS_USED.
- **Type decoding:** Converts 2-char type codes to descriptive text (e.g., 'CR' to 'CUSTOMER REBATE') for display.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLINCPG — DCLGEN for INCENTIVE_PROGRAM table

### Error Handling
Standard SQLCODE evaluation: 0 = success, +100 = not found, -803 = duplicate on insert, other = COMDBEL0 call. Activate/deactivate use +100 to detect "not found or already in target state." All errors route to 8000-SEND-ERROR.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/incentives/{id}, POST /api/incentives, PUT /api/incentives/{id}, POST /api/incentives/{id}/activate, POST /api/incentives/{id}/deactivate
- **React Page:** IncentiveManagement
- **Key Considerations:** The incentive type table should become a database-driven lookup or enum. The activate/deactivate pattern maps well to REST action endpoints. Units tracking (used/remaining) is critical for concurrent access in a multi-user web app and should use optimistic locking. The nullable model/make/region fields implementing "applies to all" semantics need careful mapping to the new data model.
