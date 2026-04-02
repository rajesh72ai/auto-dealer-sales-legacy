# ADMSEC00 — Security / Sign-On Processing

## Overview
- **Program ID:** ADMSEC00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMS
- **Source:** cbl/online/adm/ADMSEC00.cbl
- **Lines of Code:** 615
- **Complexity:** Medium

## Purpose
Handles user authentication for the AUTOSALES system. Receives user credentials from the sign-on screen, validates against the SYSTEM_USER table, and either grants access (displaying the main menu) or denies access with appropriate error messages. Implements account lockout after 5 failed attempts and comprehensive audit logging for both successful and failed login attempts.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADMMN (Sign-On Screen)
- **MFS Output (MOD):** ASMNU00 (Main Menu on success), MFSADMMN (Sign-On Screen on failure)
- **Message Format:** Input includes user ID (8) and password (20). Success output includes user ID, user name (40), user type (1), dealer code (5), welcome message, and status 'S'. Failure output returns to sign-on screen with error message and status 'F'.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SYSTEM_USER | SELECT | Look up user by ID — retrieves name, password hash, type, dealer code, active flag, failed attempts, locked flag |
| AUTOSALE.SYSTEM_USER | UPDATE | On failure: increment failed_attempts, set locked_flag if >= 5 |
| AUTOSALE.SYSTEM_USER | UPDATE | On success: reset failed_attempts to 0, set last_login_ts |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging — logs LOF (Login Failed) and LON (Login Success) actions |
| COMMSGL0 | Message formatting for error/success display messages |

### Key Business Logic
- **Authentication flow:** 1) Receive input, 2) Validate user ID and password not blank, 3) Look up user in SYSTEM_USER, 4) Check ACTIVE_FLAG = 'Y', 5) Check LOCKED_FLAG != 'Y', 6) Validate password hash, 7) On success: update login timestamp and reset failures, 8) On failure: increment counter and lock if >= 5.
- **Account lockout:** After 5 failed attempts (WS-MAX-FAILED = 5), the account is locked by setting LOCKED_FLAG = 'Y'. Locked accounts show "CONTACT ADMINISTRATOR" message.
- **Inactive accounts:** If ACTIVE_FLAG != 'Y', login is rejected with "ACCOUNT IS INACTIVE" message.
- **Password validation:** Simplified comparison (noted as demo — production would use crypto hash module). Password is STRING'd into a hash field and compared with stored HASH.
- **Audit trail:** Failed login attempts logged with action 'LOF', successful logins with 'LON'. Both include user ID and error/success details.
- **Security messages:** Invalid user/password returns generic "INVALID USER ID OR PASSWORD" to avoid revealing whether the user exists.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes (used with REPLACING for linkage section)
- WSSQLCA — DB2 SQLCA
- DCLSYUSR — DCLGEN for SYSTEM_USER table

### Error Handling
SQLCODE evaluation after user lookup. Code +100 returns generic invalid credentials message (security best practice). Non-zero codes trigger COMDBEL0. Failed attempt counter updates have their own error handling. Message formatting uses COMMSGL0 with message codes (ADMS0001 for error, ADMS0002 for success).

## Modernization Notes
- **Target Module:** admin (authentication)
- **Target Endpoint:** POST /api/auth/login, POST /api/auth/logout
- **React Page:** LoginPage
- **Key Considerations:** This maps directly to JWT/OAuth2 authentication in the modern system. The password hash comparison is simplified and must use bcrypt or similar in production. The account lockout logic should be preserved but potentially enhanced with time-based unlock. The main menu routing on success becomes a frontend redirect. The audit logging for login attempts is a security compliance requirement that must be preserved.
