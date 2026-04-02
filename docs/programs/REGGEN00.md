# REGGEN00 — Registration Document Generation

## Overview
- **Program ID:** REGGEN00
- **Module:** REG — Registration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** RGGE
- **Source:** cbl/online/reg/REGGEN00.cbl
- **Lines of Code:** 736
- **Complexity:** High

## Purpose
Assembles a vehicle registration packet from deal, vehicle, and customer data. Calculates state registration and title fees via COMTAXL0. Inserts a new registration record with status 'PR' (Preparing), validating the deal is in Delivered, F&I, or Contracted status before proceeding.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASRGGE00
- **Message Format:** Input: deal number, registration state, registration type (NW/TF/RN/DP), lien holder info. Output: deal/customer/vehicle details, registration status, fees, confirmation message.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Look up deal details (VIN, customer, status, price, trade) |
| AUTOSALE.VEHICLE | SELECT | Look up vehicle description (year, make, model, status) |
| AUTOSALE.CUSTOMER | SELECT | Look up customer name and address |
| AUTOSALE.REGISTRATION | SELECT COUNT | Check if registration already exists for deal |
| AUTOSALE.REGISTRATION | INSERT | Create new registration record with status 'PR' |
| AUTOSALE.REG_SEQ | NEXT VALUE | Generate unique registration ID |
| AUTOSALE.TAX_RATE | READ (via COMTAXL0) | Look up state tax/fee rates |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | Validate state code |
| COMTAXL0 | Calculate registration fees, title fees, and taxes |
| COMLGEL0 | Audit logging of registration creation |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Validates deal number, registration state, and registration type (NW=New, TF=Transfer, RN=Renewal, DP=Duplicate) are provided.
- State code validated via COMVALD0.
- Deal must be in status CT (Contracted), FI (F&I), or DL (Delivered).
- Checks that no registration already exists for the deal.
- Looks up vehicle info from deal's VIN.
- Looks up customer from deal's customer ID and formats name (Last, First).
- Calls COMTAXL0 with state code, vehicle price, and trade allowance to calculate registration fee and title fee.
- Generates registration ID from DB2 sequence AUTOSALE.REG_SEQ.
- Builds lien holder full name and formatted address.
- Inserts registration with status 'PR' (Preparing), computed reg fee and title fee.
- Logs the registration creation via COMLGEL0.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- SQLCODE +100 on deal lookup returns "DEAL NOT FOUND".
- Non-zero SQLCODE on any DB2 operation calls COMDBEL0 and sets error message.
- Fee calculation errors from COMTAXL0 are reported with the module's error message.
- Missing or invalid input fields produce specific validation messages.

## Modernization Notes
- **Target Module:** registration
- **Target Endpoint:** POST /api/registrations
- **React Page:** RegistrationTracker
- **Key Considerations:** Fee calculation logic currently delegates to COMTAXL0; modernize as a fee calculation service. Lien holder address formatting should be handled by the UI. Registration ID generation transitions from DB2 sequence to auto-increment or UUID. Status code 'PR' maps to a "preparing" state in the new workflow.
