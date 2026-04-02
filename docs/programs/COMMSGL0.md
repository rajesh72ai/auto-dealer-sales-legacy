# COMMSGL0 — IMS DC Message Builder

## Overview
- **Program ID:** COMMSGL0
- **Type:** Common Module
- **Source:** cbl/common/COMMSGL0.cbl
- **Lines of Code:** 419
- **Complexity:** Medium

## Purpose
Constructs formatted message segments for output to IMS terminals. All messages include LL/ZZ prefix (IMS message segment header), timestamp, severity indicator, and proper formatting for MFS (Message Format Service) screen display.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMMSGL0' USING LK-MSG-FUNCTION LK-MSG-TEXT LK-MSG-SEVERITY LK-MSG-PROGRAM-ID LK-MSG-OUTPUT-AREA LK-MSG-RETURN-CODE`.

Function codes: INFO, ERR, WARN, SCRN, CLR.

### Database Access
None.

### Called Subroutines
None.

### Key Business Logic
- **INFO:** Single-line message segment (83 bytes: 4 LL/ZZ + 79 status line). Format: MSG-ID SEVERITY TIMESTAMP TEXT.
- **ERR:** Two-line error segment (162 bytes). Header line + detail line with program ID and timestamp.
- **WARN:** Same format as INFO but with 'W' severity indicator.
- **SCRN:** Full screen message (1900 bytes). Header (system name + title + date/time), separator, 22 blank body lines, separator, footer (program ID + message + PF1=HELP).
- **CLR:** Minimum segment (83 bytes) to clear the terminal.
- **Message ID:** Auto-generated as 'AS' + 5-digit sequence number (e.g., AS00001).
- **Severity indicators:** I (Info), W (Warning), E (Error), S (Severe).
- **Truncation:** If message text exceeds 48 characters, it is truncated and RC=04 is returned.

### Copybooks Used
None.

### Input/Output
- **Input:** Function code, message text (200 chars), severity, program ID
- **Output:** IMS message segment with LL/ZZ header + formatted data (up to 1960 bytes), return code

## Modernization Notes
- **Target:** UI notification/toast service, logging framework, API response formatter
- **Key considerations:** The LL/ZZ IMS message format and MFS screen layout are IMS-specific. The severity-based message categorization and screen layout concepts transfer to modern UI frameworks. The 79-character line width is a 3270 terminal constraint.
- **Dependencies:** Used by IMS DC online transactions for terminal output. IMS-specific message format.
