# COMVALD0 — VIN Validation Module

## Overview
- **Program ID:** COMVALD0
- **Type:** Common Module
- **Source:** cbl/common/COMVALD0.cbl
- **Lines of Code:** 620
- **Complexity:** High

## Purpose
Validates 17-character Vehicle Identification Numbers per NHTSA standards including length check, illegal character detection (I, O, Q), WMI (World Manufacturer Identifier) region validation, check digit calculation (position 9), model year code validation (position 10), and full VIN decoding into component parts with manufacturer identification.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMVALD0' USING LK-VIN-INPUT LK-VIN-RETURN-CODE LK-VIN-ERROR-MSG LK-VIN-DECODED`.

Return codes: 00 (valid), 04 (invalid format), 08 (bad check digit), 12 (invalid position data).

### Database Access
None.

### Called Subroutines
None.

### Key Business Logic
- **Length validation:** Must be exactly 17 characters.
- **Character validation:** Only A-Z (except I, O, Q) and 0-9 are valid.
- **WMI validation (positions 1-3):** Position 1 must be a valid region code: 1-5 (North America), A-H (Africa), J-R (Asia), S-Z (Europe), 6-7 (Oceania), 8-9 (South America). WMI cannot be all zeros.
- **Check digit (position 9):** NHTSA algorithm: transliterate each character to a numeric value, multiply by position weight (8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2), sum all products, MOD 11. If remainder = 10, check digit = 'X'.
- **Transliteration table:** A=1, B=2, C=3, D=4, E=5, F=6, G=7, H=8, J=1, K=2, L=3, M=4, N=5, P=7, R=9, S=2, T=3, U=4, V=5, W=6, X=7, Y=8, Z=9.
- **Model year (position 10):** Maps codes to years: 1-9 = 2001-2009, A=2010, B=2011, ..., T=2026, V=2027, ..., Y=2030.
- **VIN decoding:** Extracts WMI (1-3), VDS (4-8), check digit (9), VIS (10-17), year code (10), plant code (11), sequence number (12-17).
- **Manufacturer identification:** Maps first 2 chars of WMI to manufacturer names (1G=GM USA, 1F=Ford, 1C=Chrysler, JT=Toyota Japan, WB=BMW, etc.).

### Copybooks Used
None.

### Input/Output
- **Input:** 17-character VIN
- **Output:** Return code, error message, decoded VIN (WMI, VDS, check digit, VIS, year code, plant code, sequence, manufacturer name, model year, assembly)

## Modernization Notes
- **Target:** VIN validation utility / shared library
- **Key considerations:** The NHTSA check digit algorithm is a federal standard and must be implemented exactly. The manufacturer lookup table should be externalized and expanded. Third-party VIN decoding APIs (NHTSA vPIC) could supplement this with additional vehicle details.
- **Dependencies:** Called by BATVAL00 for VIN validation. No external dependencies.
