# SALINC00 — Incentive / Rebate Application

## Overview
- **Program ID:** SALINC00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALI
- **Source:** cbl/online/sal/SALINC00.cbl
- **Lines of Code:** 792
- **Complexity:** High

## Purpose
Manages the application of manufacturer incentives and rebates to a sales deal. Queries eligible incentives based on active status, date range, model match, region match, and available units. Displays a list of applicable incentives for selection. Validates stackability rules (non-stackable incentives cannot be combined). Inserts INCENTIVE_APPLIED records, increments UNITS_USED on the program, and recalculates deal totals with rebates applied.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLIC00 (Incentive Response)
- **Message Format:** Input includes deal number (10), action (LS=list eligible, AP=apply selected), and up to 5 incentive IDs (10 each) to apply. Output shows deal header, vehicle info (year/make/model), column headers, up to 8 eligible incentive detail lines (ID, name, type, amount, stackable flag), and total rebates applied.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.INCENTIVE_PROGRAM | SELECT (cursor) | Query eligible incentives with complex criteria |
| AUTOSALE.INCENTIVE_PROGRAM | UPDATE | Increment UNITS_USED for each applied incentive |
| AUTOSALE.INCENTIVE_APPLIED | INSERT | Record incentive application to deal |
| AUTOSALE.SALES_DEAL | SELECT | Read deal details |
| AUTOSALE.SALES_DEAL | UPDATE | Recalculate deal totals with rebates |
| AUTOSALE.VEHICLE | SELECT | Get vehicle year/make/model for eligibility matching |
| AUTOSALE.CUSTOMER | SELECT | Get customer location for region matching |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMPRCL0 | Vehicle pricing lookup |
| COMTAXL0 | Tax recalculation after rebate adjustment |
| COMFMTL0 | Currency formatting |
| COMLGEL0 | Audit log entry |

### Key Business Logic
- **Eligibility criteria (cursor CSR_INCENTIVES):** Incentive must be: ACTIVE_FLAG='Y', current date between START_DATE and END_DATE, model year/make/model matches (or incentive has NULL for "all"), region matches customer's region (or NULL for "all"), UNITS_USED < MAX_UNITS (or MAX_UNITS is NULL for unlimited).
- **Stackability rules:** If any selected incentive has STACKABLE_FLAG='N', it cannot be combined with other incentives. WS-HAS-NON-STACK flag tracks this.
- **Apply flow:** For each selected incentive ID: validate it exists in the eligible list, check stackability conflict, INSERT into INCENTIVE_APPLIED, UPDATE INCENTIVE_PROGRAM to increment UNITS_USED.
- **Deal recalculation:** After applying incentives, total rebate amount is computed, deal totals are recalculated (subtotal - discount - rebates + tax + fees), and SALES_DEAL is updated.
- **Tax recalculation:** COMTAXL0 is called to recalculate tax after rebate adjustment (tax base may change with rebates in some jurisdictions).
- **Up to 5 incentives:** Input allows selecting up to 5 incentive IDs to apply in a single transaction.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLINCPG — DCLGEN for INCENTIVE_PROGRAM table
- DCLINAPP — DCLGEN for INCENTIVE_APPLIED table
- DCLVEHCL — DCLGEN for VEHICLE table

### Error Handling
Uses WS-ERROR-FLAG and WS-RETURN-CODE patterns. Validates deal exists, vehicle exists. Eligibility cursor handles empty results. Stackability conflict produces specific error message. UNITS_USED overflow (max units reached) caught during apply.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** GET /api/deals/{dealNumber}/eligible-incentives, POST /api/deals/{dealNumber}/incentives
- **React Page:** DealIncentives
- **Key Considerations:** The complex eligibility query with nullable model/make/region filters should become a dedicated incentive eligibility service. The stackability validation is a business rule that should be centralized. The UNITS_USED increment needs optimistic locking to prevent race conditions in a multi-user web environment. The deal recalculation after incentive changes should be a shared calculation service used across SALINC00, SALNEG00, and SALQOT00. Tax recalculation after rebate may need to account for state-specific rules about whether rebates reduce taxable amount.
