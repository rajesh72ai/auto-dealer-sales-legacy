# COMVINL0 — VIN Decoder Module

## Overview
- **Program ID:** COMVINL0
- **Type:** Common Module
- **Source:** cbl/common/COMVINL0.cbl
- **Lines of Code:** 822
- **Complexity:** High

## Purpose
Decodes a 17-character VIN per NHTSA/ISO 3779 standard. Validates the check digit (position 9), extracts country of origin, manufacturer, model year, assembly plant, and production sequence number. Provides both validation (VALD) and decode (DECO) functions, plus a combined validate-and-decode (FULL) function.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMVINL0' USING LS-VIN-REQUEST LS-VIN-RESULT`.

Function codes: VALD (validate only), DECO (decode only), FULL (validate + decode).

### Database Access
None (pure algorithmic logic).

### Called Subroutines
None.

### Key Business Logic
- **VIN structure:** WMI (positions 1-3: World Manufacturer Identifier), VDS (positions 4-8: Vehicle Descriptor Section), Check digit (position 9), VIS (positions 10-17: Vehicle Identifier Section including year, plant, sequence).
- **Validation:** Same NHTSA check digit algorithm as COMVALD0: transliterate characters to values, multiply by position weights, sum, MOD 11.
- **Country decoding:** Position 1 maps to country/region: 1=USA, 2=Canada, 3=Mexico, 4=USA, 5=USA, J=Japan, K=Korea, S=UK, W=Germany, Z=Italy, etc.
- **Manufacturer decoding:** Extended lookup table mapping WMI codes to manufacturer names including domestic (GM, Ford, Chrysler/Stellantis, Tesla) and imports (Toyota, Honda, Nissan, Hyundai/Kia, BMW, Mercedes, VW, Audi, Porsche, Volvo, Subaru, Mazda).
- **Model year decoding:** Position 10 character-to-year mapping covering 2001-2030.
- **Assembly plant:** Position 11 identified (plant code returned, not decoded to plant name).
- **Production sequence:** Positions 12-17 extracted as 6-character serial number.
- **Error handling:** Validates length, illegal characters (I/O/Q), check digit, and year code. Returns specific error messages for each failure type.

### Copybooks Used
None.

### Input/Output
- **Input:** VIN (17 chars), function code (VALD/DECO/FULL)
- **Output:** Return code (00=valid, 04=format error, 08=check digit error, 12=invalid data), return message, valid flag, country name, manufacturer name, model year (4-digit), plant code, sequence number, WMI, VDS, check digit, VIS

## Modernization Notes
- **Target:** VIN decoding utility / shared library, or integration with NHTSA vPIC API
- **Key considerations:** This module overlaps significantly with COMVALD0 but has a richer manufacturer lookup and different function interface. In modernization, these should be consolidated into a single VIN service. Consider supplementing with the NHTSA vPIC web API for real-time VIN data.
- **Dependencies:** Called by BATVAL00 for VIN validation during data integrity checks. Also used by online transactions for VIN entry validation.
