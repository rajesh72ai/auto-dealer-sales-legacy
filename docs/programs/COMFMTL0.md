# COMFMTL0 — Field Formatting Module

## Overview
- **Program ID:** COMFMTL0
- **Type:** Common Module
- **Source:** cbl/common/COMFMTL0.cbl
- **Lines of Code:** 526
- **Complexity:** Medium

## Purpose
Provides consistent formatting of currency, phone numbers, SSN (masked), VIN, percentages, rates, and names for display across the AUTOSALES system. Handles proper-case name formatting including special prefixes (Mc, Mac, O').

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMFMTL0' USING LK-FMT-FUNCTION LK-FMT-INPUT LK-FMT-OUTPUT LK-FMT-RETURN-CODE LK-FMT-ERROR-MSG`.

Function codes: CURR, PHON, SSNM, VINF, PCTF, RATF, NAME.

### Database Access
None.

### Called Subroutines
None.

### Key Business Logic
- **CURR (Currency):** Formats S9(09)V99 to $999,999,999.99. Handles negative amounts with leading minus sign.
- **PHON (Phone):** Strips non-digit characters, validates exactly 10 digits, formats as 999-999-9999.
- **SSNM (SSN Mask):** Strips non-digits, validates 9 digits, validates area/group/serial not all zeros, rejects area 666 and 900+. Output: XXX-XX-1234 (last 4 visible).
- **VINF (VIN Format):** Splits 17-char VIN into WMI-VDS-CHK-VIS with dashes.
- **PCTF (Percentage):** Formats S9(03)V99 as ZZ9.99%.
- **RATF (Rate):** Formats S9(02)V9(04) as Z9.9999.
- **NAME (Proper Case):** Converts to proper case respecting spaces, hyphens, and apostrophes. Special handling for Mc prefix (McDonald), Mac prefix (MacDonald), and these prefixes after spaces/hyphens.

### Copybooks Used
None.

### Input/Output
- **Input:** Function code, alpha input (40 chars), numeric input (various packed decimal formats)
- **Output:** Formatted string (40 chars), return code, error message

## Modernization Notes
- **Target:** Shared formatting utility library / UI formatting layer
- **Key considerations:** Most functions map to standard formatting libraries. The SSN validation rules and name proper-casing with Mc/Mac handling are the most complex. The SSN masking logic is a PII protection pattern.
- **Dependencies:** Used system-wide for display formatting. No external dependencies.
