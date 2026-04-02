# COMEDIL0 — EDI Message Parser

## Overview
- **Program ID:** COMEDIL0
- **Type:** Common Module
- **Source:** cbl/common/COMEDIL0.cbl
- **Lines of Code:** 739
- **Complexity:** High

## Purpose
Parses inbound EDI messages for vehicle shipment and delivery tracking. Supports EDI 214 (Carrier Shipment Status) and EDI 856 (Advance Ship Notice/Manifest). Uses STRING/UNSTRING to parse ANSI X12 004010 standard segments delimited by '*' (element separator) and '~' (segment terminator).

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMEDIL0' USING LS-EDI-REQUEST LS-EDI-RESULT`.

Message types: '214' (shipment status), '856' (advance ship notice).

### Database Access
None (pure parsing logic).

### Called Subroutines
None.

### Key Business Logic
- **Envelope parsing:** Validates ISA (interchange), GS (functional group), and ST (transaction set) header segments. Extracts control numbers.
- **EDI 214 segments:** B10 (beginning - shipment ID, SCAC), L11 (reference - VIN via qualifier 'VN'), AT7 (status code), AT8 (status date/time), MS1 (city/state/zip), N1 (destination dealer via qualifier 'ST'), DTM (ETA date via qualifier '017').
- **EDI 856 segments:** BSN (beginning - shipment ID, ship date), HL (hierarchical level - shipment vs item), TD5 (carrier SCAC), REF (VIN via qualifier 'VN', BOL via qualifier 'BM'), N1 (destination dealer), LIN (line item), DTM (ship date via qualifier '011'). Supports up to 25 vehicles per ASN.
- **Segment parsing:** Extracts next segment by scanning for '~' terminator, then UNSTRINGs elements on '*' delimiter into a 10-element work area, then copies to an indexed table.
- **Trailer validation:** Validates SE segment count against parsed count.

### Copybooks Used
- WSEDI000 (EDI layout definitions)

### Input/Output
- **Input:** EDI message buffer (up to 4096 bytes), message type code
- **Output:** Parsed fields for 214 or 856, segment count, error count, ISA/GS/ST control numbers

## Modernization Notes
- **Target:** EDI integration middleware or translator (e.g., MuleSoft, BizTalk, or cloud EDI service)
- **Key considerations:** EDI parsing is well-served by modern EDI translation tools. The specific segment/element mappings are the key business knowledge to preserve. The 25-vehicle limit per ASN may need to be configurable.
- **Dependencies:** Used by vehicle shipment tracking. WSEDI000 copybook provides layout definitions.
