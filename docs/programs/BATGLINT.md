# BATGLINT — General Ledger Interface

## Overview
- **Program ID:** BATGLINT
- **Type:** Batch
- **Source:** cbl/batch/BATGLINT.cbl
- **Lines of Code:** 658
- **Complexity:** High

## Purpose
Generates General Ledger posting entries from completed deals that have not yet been posted (GL_POSTED_FLAG = 'N'). Creates balanced double-entry journal entries for vehicle revenue, cost of goods sold, F&I income, and sales tax collected. Updates the GL_POSTED_FLAG on each processed deal.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Uses STOP RUN to terminate.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Read delivered deals not yet GL-posted |
| AUTOSALE.SALES_DEAL | UPDATE | Set GL_POSTED_FLAG = 'Y' and GL_POSTED_DATE |
| AUTOSALE.VEHICLE | SELECT | Look up invoice price (cost of goods) |
| AUTOSALE.BATCH_CHECKPOINT | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management |
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Logging utility |

### Key Business Logic
- **GL Account Codes:** Vehicle Revenue (4010-00-00), COGS (5010-00-00), F&I Income (4020-00-00), Tax Collected (2300-00-00), Accounts Receivable (1200-00-00), Inventory (1400-00-00).
- **Revenue entry:** Debit A/R, Credit Vehicle Revenue for (TOTAL_PRICE - TAX - FNI).
- **COGS entry:** Debit COGS, Credit Inventory for invoice price (vehicle cost).
- **F&I entry (if > 0):** Debit A/R, Credit F&I Income.
- **Tax entry (if > 0):** Debit A/R, Credit Tax Payable.
- **Accumulation:** Running totals for revenue, COGS, F&I, and tax for the trailer record.
- **Trailer:** Writes a summary record with total revenue and COGS.
- **Checkpointing:** Every 200 deals.

### Copybooks Used
- WSCKPT00
- SQLCA

### Input/Output
- **Input:** AUTOSALE.SALES_DEAL (unposted delivered deals)
- **Output:** GLFILE DD - Fixed-format 200-byte GL posting records (HD=header, DT=debit, CT=credit, TR=trailer)

## Modernization Notes
- **Target:** Accounting/GL Integration service, ERP connector
- **Key considerations:** The double-entry accounting logic is a critical business rule. GL account mapping must be preserved exactly. Modern systems would post via API to an ERP (SAP, NetSuite, etc.).
- **Dependencies:** Depends on COMCKPL0, COMDBEL0, COMLGEL0. Downstream GL system consumes the output file.
