# ADMMFG00 — Manufacturer / Make / Model Master Maintenance

## Overview
- **Program ID:** ADMMFG00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMM
- **Source:** cbl/online/adm/ADMMFG00.cbl
- **Lines of Code:** 1079
- **Complexity:** High

## Purpose
Maintains the MODEL_MASTER table, which stores vehicle make/model definitions with body style, engine, transmission, drivetrain, and fuel economy data. Supports inquiry by year/make/model composite key, add, update, and list by make code with optional year filter. Validates all code fields against hardcoded lookup tables.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADMFG (Model Master Screen)
- **MFS Output (MOD):** ASMDLI00 (Model Inquiry/List Response)
- **Message Format:** Input includes function (INQ/ADD/UPD/LST), model year (4), make code (3), model code (6), model name (40), body style (2), trim level (3), engine type (3), transmission (1), drive train (3), exterior/interior colors (200 each), curb weight, MPG city/hwy, active flag, user ID. Output includes decoded descriptions for body style, engine, and transmission.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.MODEL_MASTER | SELECT | Inquiry by year/make/model |
| AUTOSALE.MODEL_MASTER | INSERT | Add new model record |
| AUTOSALE.MODEL_MASTER | UPDATE | Update existing model |
| AUTOSALE.MODEL_MASTER | SELECT (cursor) | List by make code and optional year (max 15) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMMSGL0 | Message formatting |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Composite key:** MODEL_YEAR + MAKE_CODE + MODEL_CODE form the primary key.
- **Body style validation:** 9 valid codes — SD (Sedan), CP (Coupe), HB (Hatchback), WG (Wagon), CV (Convertible), SU (SUV), PU (Pickup), VN (Van), XT (Crossover).
- **Engine type validation:** 10 valid codes — I4, I6, V6, V8, V10, V12, EV, HYB, PHV, DSL.
- **Transmission validation:** 4 valid codes — A (Automatic), M (Manual), C (CVT), D (DCT).
- **Year range validation:** Must be between 1990 and 2030.
- **Code decoding:** Body style, engine type, and transmission codes are decoded to descriptive text for display output.
- **Nullable fields:** Exterior/interior colors, curb weight, MPG city, MPG hwy support null indicators.
- **List filtering:** The cursor supports filtering by make code with optional year (year=0 means all years). Results ordered by year descending, then model code.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLMODEL — DCLGEN for MODEL_MASTER table

### Error Handling
Standard SQLCODE evaluation pattern with COMDBEL0 for unexpected errors. Duplicate key (-803) caught on insert with specific message. Not found (+100) on inquiry/update. IMS GU failures detected via IO-STATUS-CODE.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/models/{year}/{make}/{model}, POST /api/models, PUT /api/models/{year}/{make}/{model}, GET /api/models?make={code}&year={year}
- **React Page:** ModelMasterManagement
- **Key Considerations:** The hardcoded body style, engine type, and transmission lookup tables should become database reference tables or enums. The composite key pattern maps to a path-parameter REST design. The 200-character color fields storing delimited lists should be normalized into a separate table. The decode logic for display should move to the frontend or a mapping layer.
