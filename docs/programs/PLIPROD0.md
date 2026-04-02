# PLIPROD0 — Production Completion

## Overview
- **Program ID:** PLIPROD0
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLPR
- **Source:** cbl/online/pli/PLIPROD0.cbl
- **Lines of Code:** 748
- **Complexity:** High

## Purpose
Receives production completion feed from the plant. Processes production records with VIN, model year, make, model, plant code, build date, colors, engine, transmission, and options. Validates VIN, checks for duplicates, inserts into PRODUCTION_ORDER and VEHICLE tables, and inserts VEHICLE_OPTION records. Sets initial status to PR (Produced). Handles both single online entry and batch mode.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: SG=single, BT=batch, IQ=inquiry), VIN (17), model year (4), make (3), model (6), plant (5), build date (10), ext color (3), int color (3), engine (4), trans (4), option count (2), options (20 entries of code+desc), batch count (4), MSRP. Output: VIN, plant, vehicle details, colors, status, option count, MSRP, batch summary.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Duplicate VIN check (COUNT) |
| AUTOSALE.VEHICLE | INSERT | Create vehicle record |
| AUTOSALE.PRODUCTION_ORDER | SELECT | Generate next order ID (MAX+1) |
| AUTOSALE.PRODUCTION_ORDER | INSERT | Create production order |
| AUTOSALE.VEHICLE_OPTION | INSERT | One per option (up to 20) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN format validation |
| COMVINL0 | VIN decode/lookup (manufacturer, year, assembly plant) |
| COMDBEL0 | DB2 error handler |
| COMLGEL0 | Audit logging |

### Key Business Logic
- VIN validation via COMVALD0 (format check) and COMVINL0 (decode: WMI, VDS, check digit, VIS, year code, plant code, sequence)
- Duplicate check: COUNT(*) from VEHICLE where VIN matches; rejects if > 0
- Model year validated: 1990-2030 range
- Production order ID generated via MAX+1 pattern
- Vehicle inserted with: VIN, year, make, model, colors, engine, transmission, status=PR, plant, build date, MSRP, dealer=NULL
- Options inserted in a loop (up to 20) with sequence number, code, description, installed date = build date
- **Batch mode**: processes single record but tracks batch counters (total/ok/errors)
- **Inquiry mode**: looks up existing production order by VIN
- Option insert failures are non-fatal (RC=4 warning)

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 4=warning (option insert), 8=validation, 12=DB2 error, 16=IMS error
- DB2 errors delegated to COMDBEL0
- IMS ISRT failure sets abend code 'PLIPROD0'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/production
- **React Page:** ProductionReceiptForm
- **Key Considerations:** This is the entry point for vehicles into the system. The VIN validation and decode logic (COMVALD0/COMVINL0) should be a shared service, potentially using NHTSA VIN decode API. The production order + vehicle + options insertion should be a single atomic transaction. The batch mode should use a bulk insert API or message queue (e.g., Kafka for plant feeds). Consider vehicle options as a JSON array rather than separate rows. MSRP should use BigDecimal.
