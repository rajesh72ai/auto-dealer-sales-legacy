# ADMCFG00 — System Configuration Maintenance

## Overview
- **Program ID:** ADMCFG00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMC
- **Source:** cbl/online/adm/ADMCFG00.cbl
- **Lines of Code:** 664
- **Complexity:** Medium

## Purpose
Maintains the system-wide configuration key-value store in the SYSTEM_CONFIG table. Supports inquiry by config key, update of config values, and listing all configuration entries (up to 20). Enforces numeric validation on specific keys such as sequence numbers and threshold values.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADCFG (System Config Screen)
- **MFS Output (MOD):** ASCFGI00 (Config Inquiry Response)
- **Message Format:** Input includes function code (INQ/UPD/LST), config key (30), config value (100), description (60), user ID (8). Output returns key/value/description with timestamps and status messages. List output returns up to 20 entries.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SYSTEM_CONFIG | SELECT | Inquiry by config key |
| AUTOSALE.SYSTEM_CONFIG | UPDATE | Update config value and description |
| AUTOSALE.SYSTEM_CONFIG | SELECT (cursor) | List all config entries (max 20) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging — logs old/new values on update |
| COMDBEL0 | DB2 error handling — formats SQLCODE errors |

### Key Business Logic
- **Function routing:** INQ retrieves a single config entry by key; UPD modifies an existing entry; LST fetches up to 20 entries via cursor.
- **Numeric key validation:** Maintains a table of 6 keys that require numeric values (NEXT_STOCK_NUMBER, NEXT_DEAL_NUMBER, NEXT_CUSTOMER_NUMBER, MAX_DAYS_ON_LOT, FLOOR_PLAN_GRACE_DAYS, AGING_REPORT_THRESHOLD). If the key being updated matches one of these, the value is validated as numeric.
- **Null handling:** CONFIG_DESC and UPDATED_BY columns support null indicators. When description is blank on update, null indicator is set to -1.
- **Audit trail:** On successful update, the old and new config values are logged via COMLGEL0 with the user ID and program ID.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLSYSCF — DCLGEN for SYSTEM_CONFIG table

### Error Handling
SQLCODE is evaluated after each SQL operation. Code +100 produces a "not found" user message. Other non-zero codes trigger COMDBEL0, which formats the SQLCODE, SQLSTATE, and error category into a displayable message. IMS GU failures are caught by checking IO-STATUS-CODE. All errors set WS-ERROR-FLAG and route to the 8000-SEND-ERROR paragraph.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/admin/config/{key}, PUT /api/admin/config/{key}, GET /api/admin/config
- **React Page:** SystemConfiguration
- **Key Considerations:** The numeric key validation table is hardcoded and should be moved to metadata or schema validation. The 20-entry list limit should become paginated. Config keys that store sequences (NEXT_*) should be replaced with database sequences or auto-increment in the modern system.
