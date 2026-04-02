# AUTOSALES Business Functions & Rules

## 1. Administration (ADM Module)

### Security Rules (ADMSEC00)
- **Authentication**: User ID and password validated against `SYSTEM_USER` table
- **Password Hash**: Compared using simplified hash (production would use external crypto)
- **Account Lockout**: Account locked after 5 consecutive failed attempts (`WS-MAX-FAILED VALUE 5`)
  - `FAILED_ATTEMPTS` incremented on each failure
  - When `FAILED_ATTEMPTS >= 5`: `LOCKED_FLAG = 'Y'`, account locked
  - Requires administrator intervention to unlock
- **Active Check**: Account must have `ACTIVE_FLAG = 'Y'`
- **Login Success**: Resets `FAILED_ATTEMPTS` to 0, updates `LAST_LOGIN_TS`
- **Audit Trail**: Both successful (LON) and failed (LOF) login attempts logged

### User Types and Authority Levels
| Type | Code | Authority |
|------|------|-----------|
| Admin | A | Full system access, all approvals |
| General Manager | G | All approvals including loser deals |
| Manager | M | Standard approvals, invoice visibility |
| Salesperson | S | Deal creation, customer management |
| F&I Manager | F | Finance applications, product selection |
| Clerk | C | Inquiry and basic data entry |

### Pricing Rules (ADMPRC00)
- MSRP must exceed Invoice price
- Holdback calculated as either fixed amount or percentage of MSRP
- Effective date logic controls price applicability
- Price history maintained per model

### Tax Rate Rules (ADMTAX00)
- Tax rates validated between 0 and 0.15 (0% to 15%)
- Three-level jurisdiction: State + County + City
- Combined rate displayed for verification

---

## 2. Customer Management (CUS Module)

### Customer Creation Rules (CUSADD00)
- **Required Fields**: Last name, first name, address, city, state, ZIP, phone
- **Validation**: State code, ZIP format, phone format, email format
- **Duplicate Detection**: Same last name + phone, or same last name + address
  - Warning displayed on duplicate match
  - Force-add allowed via `FA` function code
- **Auto-Assignment**: Salesperson assigned via round-robin if not specified

### Credit Pre-Qualification (CUSCRED0)
- **Credit Scoring Tiers** (based on annual income):

| Income Range | Tier | Score Range | Description |
|-------------|------|------------|-------------|
| > $100,000 | A | 750+ | Excellent |
| > $75,000 | B | 700-749 | Good |
| > $50,000 | C | 650-699 | Fair |
| > $35,000 | D | 600-649 | Below Average |
| < $35,000 | E | Below 600 | Subprime |

- **DTI Ratio**: Calculated if monthly debt info available (monthly debt / monthly income)
- **Credit Expiry**: Credit check valid for 30 days from check date
- **Max Financing**: Calculated based on tier and income

### Lead Lifecycle (CUSLEAD0)
```
NW (New) --> CT (Contacted) --> AP (Appointment) --> TS (Test Drive)
   --> QT (Quote) --> WN (Won) / LS (Lost) / DD (Dead)
```
- Overdue follow-ups generate alerts
- When status = WN (Won), links to deal creation

---

## 3. Sales Process (SAL Module)

### Deal Lifecycle State Machine

```
WS (Worksheet)
 |
 v
NE (Negotiating) <--+
 |                   |
 v                   |
PA (Pending Approval)|
 |                   |
 +---[Reject]--------+
 |
 v [Approve]
AP (Approved)
 |
 v
FI (In F&I)
 |
 v
DL (Delivered)
 |
 +---[Cancel/Unwind after delivery]--> UW (Unwound)
 |
 v
 (Complete)

At any stage before DL:
 +---[Cancel]--> CA (Cancelled)
```

**Status Codes:**
| Code | Status | Meaning |
|------|--------|---------|
| WS | Worksheet | Initial quote/deal worksheet created |
| NE | Negotiating | Active price negotiation |
| PA | Pending Approval | Submitted for manager approval |
| AP | Approved | Manager approved, ready for F&I |
| FI | In Finance | F&I processing (finance app, products) |
| DL | Delivered | Vehicle delivered to customer |
| CA | Cancelled | Deal cancelled before delivery |
| UW | Unwound | Deal reversed after delivery |

### Deal Worksheet / Quote Rules (SALQOT00)
- **Deal Types**: R=Retail, L=Lease, F=Fleet, W=Wholesale
- **Required Entities**: Customer ID, VIN, Salesperson ID, Dealer Code
- **Pricing Components Built**:
  - Base vehicle price (MSRP or negotiated)
  - Vehicle options total
  - Destination fee
  - Trade-in allowance (net of payoff)
  - Incentive/rebate amount
  - Tax (state + county + city) via COMTAXL0
  - Doc fee, title fee, registration fee
  - Total price, down payment, amount financed
  - Front gross profit
- **Deal Number**: Auto-generated via COMSEQL0 (format: D-XXXXX)
- **Initial Status**: WS (Worksheet)

### Negotiation Rules (SALNEG00)
- **Pricing Visibility**:
  - MSRP: Visible to all
  - Invoice price: Visible to Manager (M) and above only
  - Holdback: Hidden from display
  - Gross profit and margin %: Manager view only (controlled by user type)
- **Counter Offer Methods**:
  - Direct counter offer amount
  - Discount by dollar amount
  - Discount by percentage
- **Manager Desk Notes**: Visible to salesperson
- **Recalculation**: All deal financials recalculated on each counter offer
- **Status Change**: Updates to NE (Negotiating)

### Approval Authority Rules (SALAPV00)
- **Who Can Approve/Reject**:
  - Manager (M), General Manager (G), or Admin (A)
  - Salespeople and clerks cannot approve
- **Approval Thresholds**:
  - **Standard deal** (front gross >= $500): Any Manager can approve
  - **Low gross deal** (front gross < $500 but >= $0): Any Manager can approve
  - **Loser deal** (front gross < $0): **GM (G) or Admin (A) only**
- **Rejection**: Any Manager can reject; deal returns to NE (Negotiating) status
- **Approval**: Deal advances to AP (Approved), ready for F&I
- **Approval Record**: `SALES_APPROVAL` record inserted with approver ID, action, comments, timestamp
- **Gross Threshold**: `WS-GROSS-THRESHOLD VALUE +500.00`

### Deal Validation Rules (SALVAL00)
Comprehensive pre-approval checklist:
1. Customer valid and credit checked
2. Vehicle still available (not sold/transferred)
3. Pricing within dealer guidelines (minimum margin)
4. All required deal components present
5. Tax calculated
6. Trade-in payoff verified (if applicable)
7. Incentive eligibility still valid
- On pass: Status to PA (Pending Approval)
- On fail: Returns list of specific errors

### Sale Completion Checklist (SALCMP00)
Required before delivery (status DL):
1. Deal approved (status AP or FI)
2. Insurance verified (`WS-CI-INSURANCE-OK = 'Y'`)
3. Down payment received (method: CA=Cash, CK=Check, CC=Card, WR=Wire)
4. Credit/finance approved (if not cash deal)
5. Trade title received (if trade-in exists)

**On Completion**:
- `SALES_DEAL.STATUS` = DL (Delivered)
- `SALES_DEAL.DELIVERY_DATE` set
- `VEHICLE.STATUS` = SD (Sold)
- `STOCK_POSITION`: ON_HAND decremented, SOLD_MTD/SOLD_YTD incremented
- Warranty registration and title/registration data assembly triggered

### Cancellation / Unwind Rules (SALCAN00)
Full reversal of deal effects:
1. If vehicle marked sold: Status reverted to AV (Available)
2. If stock decremented: Reversed via COMSTCK0 (RECV function)
3. If incentives applied: `UNITS_USED` decremented on INCENTIVE_PROGRAM
4. If floor plan paid off: Payoff reversed
5. Status set to CA (Cancelled) or UW (Unwound if post-delivery)
6. Comprehensive audit trail for all reversals

### Trade-In Evaluation (SALTRD00)
- **ACV (Actual Cash Value) Calculation** based on condition code:

| Condition Code | Multiplier | Description |
|---------------|-----------|-------------|
| E (Excellent) | 100% | Full base value |
| G (Good) | 85% | 85% of base |
| F (Fair) | 70% | 70% of base |
| P (Poor) | 55% | 55% of base |

- Over-allowance permitted (manager decision)
- Payoff info captured: amount, bank, account number
- Trade VIN validated and decoded via COMVALD0/COMVINL0
- Net trade (ACV - payoff) applied to deal

### Incentive Application (SALINC00)
- **Eligibility Criteria**: Active flag, date range valid, model matches, region matches, units available
- **Stackable Rules**: Non-stackable incentives cannot be combined with others
- **Application**: INCENTIVE_APPLIED record inserted, UNITS_USED incremented
- **Deal Recalculation**: Totals recalculated with rebates applied

---

## 4. Finance & Insurance (FIN Module)

### Finance Types
| Type | Code | Processing |
|------|------|-----------|
| Loan | L | Full loan calculation via COMLONL0 |
| Lease | S | Lease calculation via COMLESL0 |
| Cash | C | Minimal -- records finance type only |

### Loan Amortization Formula (COMLONL0)

**Standard Amortization:**
```
M = P * [r(1+r)^n] / [(1+r)^n - 1]

Where:
  M = Monthly payment
  P = Principal (amount financed)
  r = Monthly rate (APR / 12 / 100)
  n = Number of months (term)
```

**Special Case: 0% APR:**
```
M = P / n  (simple division)
```

**Validation Constraints:**
- Principal: $500.00 to $999,999.99
- APR: 0% to 30% (0% allowed for promotional financing)
- Term: 6 to 84 months

**Output**: Monthly payment, total of payments, total interest, 12-month amortization schedule (month, payment, principal, interest, cumulative interest, remaining balance)

### Lease Payment Formula (COMLESL0)

```
Residual Amount   = Cap Cost * (Residual % / 100)
Adjusted Cap Cost = Cap Cost + Acquisition Fee - Cap Reduction (down payment)
Total Depreciation = Adjusted Cap Cost - Residual Amount
Monthly Depreciation = Total Depreciation / Term
Monthly Finance Charge = (Adjusted Cap Cost + Residual Amount) * Money Factor
Monthly Tax = (Monthly Depreciation + Monthly Finance) * Tax Rate
Total Monthly Payment = Monthly Depreciation + Monthly Finance + Monthly Tax
```

**Additional Calculations:**
- Approximate APR = Money Factor * 2400
- Drive-off amount = First month + security deposit + cap reduction + acquisition fee
- Total of payments = Monthly total * term
- Total interest (finance charges) = Monthly finance * term

**Validation Constraints:**
- Capitalized cost: >= $1,000.00
- Cap cost reduction: >= 0 and < cap cost
- Money factor: > 0 and <= 0.00500
- Standard lease terms: 24, 36, 39, or 48 months only
- Residual percentage: 20% to 75%
- Tax rate: 0% to 15%

### Finance Application (FINAPP00)
- Deal must be in AP (Approved) status
- Finance ID generated via COMSEQL0
- FINANCE_APP record inserted with status NW (New)
- SALES_DEAL status updated to FI (In F&I)

### Finance Approval (FINAPV00)
- **Approve (AP)**: Records approved APR/amount, recalculates payment
- **Conditional (CD)**: Stipulations required before funding
- **Decline (DN)**: Allows resubmit to different lender

### F&I Product Selection (FINPRD00)
Available products: Extended Warranty, GAP Insurance, Paint Protection, Fabric Guard, Theft Deterrent, Maintenance, Tire/Wheel, Dent Repair, Key Replacement, LoJack
- Multi-select supported
- Total F&I gross calculated
- SALES_DEAL.BACK_GROSS updated
- TOTAL_GROSS = FRONT_GROSS + BACK_GROSS

---

## 5. Floor Plan Management (FPL Module)

### Floor Plan Interest Calculation (COMINTL0)

**Day Count Conventions:**
| Convention | Divisor | Usage |
|-----------|---------|-------|
| 30/360 (Banker's Year) | 360 | Most common |
| Actual/365 | 365 | Some lenders |
| Actual/Actual | 365 or 366 | Leap year aware |

**Daily Interest Formula:**
```
Daily Rate = Annual Rate / Day Count Divisor
Daily Interest = Principal Balance * Daily Rate
Cumulative Interest = Sum of all daily interest from floor date
```

**Curtailment Periods:**
- New vehicles: 90 days (`WS-CURTAIL-LIMIT-NEW VALUE +90`)
- Used vehicles: 60 days (`WS-CURTAIL-LIMIT-USED VALUE +60`)
- Alert generated when within 15 days of curtailment

### Floor Plan Lifecycle
```
Add (AC=Active)
  |
  +--> Daily Interest Accrual
  |
  +--> Curtailment Warning (within 15 days)
  |
  +--> Payoff (PD=Paid) [on vehicle sale or transfer]
```

### Floor Plan Vehicle Add (FPLADD00)
- Invoice price used as initial balance
- Floor date = current date
- Curtailment date = floor date + lender curtailment days
- Status = AC (Active)

### Floor Plan Payoff (FPLPAY00)
- Final interest calculated up to payoff date
- Status set to PD (Paid)
- Payoff date and final balance recorded
- Cumulative interest fields updated

---

## 6. Tax Calculation (COMTAXL0)

### Tax Components
```
Net Taxable Amount = Vehicle Price - Trade-In Allowance (if state allows)

State Tax    = Net Taxable * State Rate
County Tax   = Net Taxable * County Rate
City Tax     = Net Taxable * City Rate
Total Tax    = State Tax + County Tax + City Tax

Fees:
  Doc Fee      (dealer-specific)
  Title Fee    (state-specific)
  Registration Fee (state-specific)

Total Fees   = Doc Fee + Title Fee + Registration Fee
Grand Total  = Total Tax + Total Fees
```

### Return Codes
| Code | Meaning |
|------|---------|
| 00 | Success |
| 04 | Tax rate not found for jurisdiction |
| 08 | Invalid input (blank state, negative amount) |
| 12 | DB2 error during tax rate lookup |

---

## 7. VIN Validation (COMVALD0)

### 17-Character VIN Structure
```
Position  1-3:   WMI (World Manufacturer Identifier)
Position  4-8:   VDS (Vehicle Descriptor Section)
Position  9:     Check Digit
Position  10:    Model Year
Position  11:    Assembly Plant
Position  12-17: Sequential Production Number
```

### Check Digit Algorithm
1. **Transliteration**: Convert each letter to numeric value
   - A=1, B=2, C=3, D=4, E=5, F=6, G=7, H=8
   - J=1, K=2, L=3, M=4, N=5, P=7, R=9
   - S=2, T=3, U=4, V=5, W=6, X=7, Y=8, Z=9
   - I, O, Q are invalid characters in VIN
2. **Position Weights**: 8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2
3. **Weighted Sum**: Multiply each transliterated value by its position weight, sum all products
4. **Modulo 11**: `Remainder = Weighted Sum MOD 11`
5. **Check Character**: If remainder = 10, check digit = 'X'; otherwise check digit = remainder digit
6. **Validation**: Compare calculated check digit with position 9

### Model Year Codes (Position 10)
```
A=2010, B=2011, C=2012, D=2013, E=2014, F=2015, G=2016, H=2017
J=2018, K=2019, L=2020, M=2021, N=2022, P=2023, R=2024
S=2025, T=2026, V=2027, W=2028, X=2029, Y=2030
1=2001, 2=2002, 3=2003, 4=2004, 5=2005, 6=2006, 7=2007, 8=2008, 9=2009
```

### Return Codes
| Code | Meaning |
|------|---------|
| 00 | VIN is valid |
| 04 | Invalid format (length or illegal characters I, O, Q) |
| 08 | Bad check digit (calculated does not match position 9) |
| 12 | Invalid position data (WMI or year code not recognized) |

---

## 8. Production & Logistics (PLI Module)

### Vehicle Lifecycle Flow
```
Production (PR) --> Allocation (AL) --> Shipment (SH) --> In Transit (IT)
  --> Delivered (DL) --> Available (AV) --> [Sell/Hold/Transfer]
```

### Vehicle Status Codes
| Code | Status | Description |
|------|--------|-------------|
| PR | Produced | Vehicle completed at factory |
| AL | Allocated | Assigned to a dealer |
| SH | Shipped | Loaded onto carrier |
| IT | In Transit | En route to dealer |
| DL | Delivered | Arrived at dealer dock |
| AV | Available | In dealer inventory, ready for sale |
| HD | On Hold | Customer deposit or manager hold |
| SD | Sold | Sold and delivered to customer |
| TR | Transfer | In transit between dealers |
| SV | Service | In service department |
| WO | Write-Off | Damaged beyond repair |
| RJ | Rejected | Dealer rejected delivery |

### Transit Status Events (PLITRNS0)
- DP = Departed origin
- AR = Arrived at checkpoint
- TF = Transferred to new carrier
- DL = Delivered to destination
- DY = Delayed

### PDI (Pre-Delivery Inspection) Statuses (PLIVPDS0)
- SC = Scheduled
- IP = In Progress
- CM = Complete (sets VEHICLE.PDI_COMPLETE = 'Y')
- FL = Failed (requires reschedule)

---

## 9. Registration & Title (REG Module)

### Registration Lifecycle
```
PR (Preparing)
  |
  v
VL (Validated) -- all fields and state rules checked
  |
  v
SB (Submitted) -- sent to state DMV with tracking number
  |
  +--> PG (Processing) -- DMV acknowledged receipt
  |
  +--> IS (Issued) -- plate/title numbers recorded
  |
  +--> RJ (Rejected) -- rejection reason recorded, can resubmit
```

### Registration Validation Rules (REGVAL00)
- Customer name and address present
- VIN present and valid
- Registration state exists in TAX_RATE table
- Registration type specified
- Fees calculated
- If pass: Status -> VL (Validated)
- If fail: Status remains PR with error messages

### Status Update Rules (REGSTS00)
- Only SB or PG status can be updated
- IS (Issued): Plate number, title number, and issued date recorded
- RJ (Rejected): Rejection reason recorded in TITLE_STATUS history
- PG (Processing): Marks in-progress at DMV

---

## 10. Warranty & Recall (WRC Module)

### Standard Warranty Coverages (WRCWAR00)
Created automatically on vehicle sale:

| Coverage Type | Duration | Mileage Limit |
|--------------|----------|---------------|
| Basic | 3 years | 36,000 miles |
| Powertrain | 5 years | 60,000 miles |
| Corrosion | 5 years | Unlimited |
| Emission | 8 years | 80,000 miles |

- Start date = sale date
- Expiry dates calculated from start date + duration

### Recall Management (WRCRCL00)
- **Campaign Statuses**: Active, Completed
- **Vehicle Recall Statuses**:
  - OP = Open (initial)
  - SC = Scheduled
  - IP = In Progress
  - CM = Complete (increments campaign TOTAL_COMPLETED)
  - NA = Not Applicable

### Recall Notification (WRCNOTF0)
For a given campaign:
1. Query all affected VINs from RECALL_VEHICLE
2. Find current owner via latest delivered SALES_DEAL
3. Check if notification already exists
4. If not, insert RECALL_NOTIFICATION record
5. Return counts: created, already-notified, no-owner-found

---

## Cross-Domain Business Rules

### Stock Position Updates (COMSTCK0)
All inventory movements flow through COMSTCK0:

| Function | ON_HAND | SOLD | ON_ORDER | HOLD | Description |
|----------|---------|------|----------|------|-------------|
| RECV | +1 | | -1 | | Vehicle received into inventory |
| SOLD | -1 | +1 | | | Vehicle sold to customer |
| HOLD | -1 | | | +1 | Vehicle placed on hold |
| RLSE | +1 | | | -1 | Vehicle released from hold |
| TRNI | +1 | | | | Transfer in from another dealer |
| TRNO | -1 | | | | Transfer out to another dealer |
| ALOC | | | +1 | | Vehicle allocated from production |

### Sequence Number Generation (COMSEQL0)
Uses DB2 SELECT FOR UPDATE on SYSTEM_CONFIG for concurrency:
- Deals: NEXT_DEAL_NUM -> D-XXXXX
- Registrations: NEXT_REG_NUM -> R-XXXXX
- Finance: NEXT_FIN_NUM -> F-XXXXX
- Transfers: NEXT_TRAN_NUM -> T-XXXXX
- Shipments: NEXT_SHIP_NUM -> S-XXXXX

### Batch Processing Schedule

| Frequency | Program | Key Activities |
|-----------|---------|---------------|
| Daily (Nightly) | BATDLY00 | Vehicle status sync, expire aged pending deals (30+ days), floor plan interest accrual |
| Daily | BATCRM00 | CRM customer extract |
| Daily | BATDMS00 | DMS deal/inventory export |
| Daily | BATGLINT | GL posting generation |
| Daily | BATDLAKE | Data lake change extract |
| Weekly (Sunday) | BATWKL00 | Inventory aging update, warranty expiration notices (30 days), recall % update |
| Weekly | BATVAL00 | Data integrity validation (orphans, VIN checksums, duplicates) |
| Monthly (Last BD) | BATMTH00 | Month-end statistics, MTD counter reset, deal archival (18+ months) |
| Quarterly | BATPUR00 | Archive registrations (2+ years), purge audit log (3+ years), purge recall notifications (1+ year) |
| As Received | BATINB00 | Manufacturer vehicle allocation feed processing |
