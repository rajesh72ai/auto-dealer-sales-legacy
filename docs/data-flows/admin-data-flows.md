# Administration Domain -- Data Flows

## Overview

The Administration domain provides foundational configuration and reference data management for the entire AUTOSALES system. It covers dealer setup, model/make catalog maintenance, pricing master records, tax rate configuration, incentive program management, F&I product catalogs, system configuration key-value pairs, and user security/sign-on processing. Every other domain depends on reference data maintained here.

## Programs in This Domain

| Program  | Description                        | Transaction Code |
|----------|------------------------------------|-----------------|
| ADMCFG00 | System Configuration Maintenance   | ADMC            |
| ADMDLR00 | Dealer Master Maintenance          | ADMD            |
| ADMINC00 | Incentive Program Setup            | ADMI            |
| ADMMFG00 | Model/Make/Model Master Maintenance| ADMM            |
| ADMPRC00 | Pricing Master Maintenance         | ADMP            |
| ADMPRD00 | F&I Product Catalog Maintenance    | ADMF            |
| ADMSEC00 | Security / Sign-On Processing      | ADMS            |
| ADMTAX00 | Tax Rate Maintenance               | ADMT            |

## Data Stores

| Table/Database              | Type    | Key Fields                                          | Used By                          |
|-----------------------------|---------|-----------------------------------------------------|----------------------------------|
| AUTOSALE.SYSTEM_CONFIG      | DB2     | CONFIG_KEY (VARCHAR 30)                             | ADMCFG00, ADMPRD00               |
| AUTOSALE.DEALER             | DB2     | DEALER_CODE (CHAR 5)                                | ADMDLR00                         |
| AUTOSALE.INCENTIVE_PROGRAM  | DB2     | INCENTIVE_ID (CHAR 10)                              | ADMINC00                         |
| AUTOSALE.MODEL_MASTER       | DB2     | MODEL_YEAR, MAKE_CODE, MODEL_CODE                   | ADMMFG00                         |
| AUTOSALE.PRICE_MASTER       | DB2     | MODEL_YEAR, MAKE_CODE, MODEL_CODE, EFFECTIVE_DATE   | ADMPRC00                         |
| AUTOSALE.TAX_RATE           | DB2     | STATE_CODE, COUNTY_CODE, CITY_CODE, EFFECTIVE_DATE  | ADMTAX00                         |
| AUTOSALE.SYSTEM_USER        | DB2     | USER_ID (CHAR 8)                                    | ADMSEC00                         |
| AUTOSALE.AUDIT_LOG          | DB2     | AUDIT_ID (auto-gen)                                 | All programs via COMLGEL0        |

## Data Flow Diagrams

### System Configuration Flow (ADMCFG00)

```
[IMS Terminal]
    |
    | ADMC transaction
    v
[ADMCFG00] --GU--> [IO PCB] (receive input message)
    |
    |-- FUNC=INQ ---SELECT---> [SYSTEM_CONFIG]
    |                              |
    |                              v
    |                    [Format output via ASCFGI00]
    |                              |
    |                              v
    |                    [ISRT to IO PCB] --> [Terminal]
    |
    |-- FUNC=UPD ---SELECT---> [SYSTEM_CONFIG] (get old value)
    |                              |
    |               <--validate (numeric keys checked)--
    |                              |
    |               ---UPDATE---> [SYSTEM_CONFIG]
    |                              |
    |               ---CALL------> [COMLGEL0] --> [AUDIT_LOG]
    |                              |
    |               ---ISRT------> [Terminal]
    |
    |-- FUNC=LST ---CURSOR------> [SYSTEM_CONFIG]
                                   | (fetch up to 20 rows)
                                   v
                         [Format list output]
                                   |
                         [ISRT to IO PCB] --> [Terminal]
```

### Dealer Master Flow (ADMDLR00)

```
[IMS Terminal]
    |
    | ADMD transaction
    v
[ADMDLR00] --GU--> [IO PCB]
    |
    |-- FUNC=INQ ---SELECT---> [DEALER]
    |                              |
    |               ---CALL------> [COMFMTL0] (format phone/fax)
    |                              v
    |                    [ISRT response] --> [Terminal]
    |
    |-- FUNC=ADD ---validate fields--
    |               ---INSERT---> [DEALER]
    |               ---CALL------> [COMLGEL0] --> [AUDIT_LOG]
    |
    |-- FUNC=UPD ---SELECT---> [DEALER] (get old)
    |               ---UPDATE---> [DEALER]
    |               ---CALL------> [COMLGEL0] --> [AUDIT_LOG]
    |
    |-- FUNC=LST ---CURSOR---> [DEALER] (by REGION_CODE)
                                   v
                         [ISRT list] --> [Terminal]
```

### Security Sign-On Flow (ADMSEC00)

```
[IMS Terminal - SIGN-ON SCREEN]
    |
    | ADMS transaction (user ID + password)
    v
[ADMSEC00] --GU--> [IO PCB]
    |
    |---SELECT---> [SYSTEM_USER] (by USER_ID)
    |                  |
    |     [Check ACTIVE_FLAG = 'Y']
    |     [Check LOCKED_FLAG = 'N']
    |     [Validate password hash]
    |                  |
    +--SUCCESS---------+----------FAILURE----------+
    |                                               |
    |  UPDATE SYSTEM_USER:                          |  UPDATE SYSTEM_USER:
    |    LAST_LOGIN_TS = NOW                        |    FAILED_ATTEMPTS + 1
    |    FAILED_ATTEMPTS = 0                        |    IF >= 5: LOCKED = 'Y'
    |                                               |
    |  CALL COMLGEL0 (LOG action)                   |  CALL COMLGEL0 (LOG action)
    |                                               |
    |  ISRT ASMNU00 (Main Menu)                     |  ISRT MFSADMMN (Sign-On w/error)
    v                                               v
[Main Menu Screen]                           [Sign-On Screen + Error]
```

### Tax Rate Maintenance Flow (ADMTAX00)

```
[IMS Terminal]
    |
    | ADMT transaction
    v
[ADMTAX00] --GU--> [IO PCB]
    |
    |-- FUNC=INQ ---SELECT---> [TAX_RATE]
    |                  | (by STATE/COUNTY/CITY)
    |                  v
    |         [Calc combined rate = state + county + city]
    |         [Call COMTAXL0 for test calculation]
    |                  v
    |         [ISRT response] --> [Terminal]
    |
    |-- FUNC=ADD ---validate rates (0 to 0.15)--
    |               ---INSERT---> [TAX_RATE]
    |               ---CALL------> [COMLGEL0] --> [AUDIT_LOG]
    |
    |-- FUNC=UPD ---SELECT old --> UPDATE---> [TAX_RATE]
                    ---CALL------> [COMLGEL0] --> [AUDIT_LOG]
```

### Incentive Program Flow (ADMINC00)

```
[IMS Terminal]
    |
    | ADMI transaction
    v
[ADMINC00] --GU--> [IO PCB]
    |
    |-- FUNC=INQ  ---SELECT---> [INCENTIVE_PROGRAM]
    |-- FUNC=ADD  ---validate (dates, amounts, model)--
    |                ---INSERT---> [INCENTIVE_PROGRAM]
    |-- FUNC=UPD  ---UPDATE---> [INCENTIVE_PROGRAM]
    |-- FUNC=ACT  ---UPDATE ACTIVE_FLAG='Y'---> [INCENTIVE_PROGRAM]
    |-- FUNC=DEAC ---UPDATE ACTIVE_FLAG='N'---> [INCENTIVE_PROGRAM]
    |
    | (All mutations)
    +---CALL------> [COMLGEL0] --> [AUDIT_LOG]
```

## Field-Level Data Mapping

| Source Field (COBOL)         | Table.Column                        | Format         | Validation Rules                              |
|-----------------------------|--------------------------------------|----------------|-----------------------------------------------|
| WS-IN-CONFIG-KEY            | SYSTEM_CONFIG.CONFIG_KEY             | X(30)          | Required; trimmed before lookup                |
| WS-IN-CONFIG-VALUE          | SYSTEM_CONFIG.CONFIG_VALUE           | X(100)         | Required; numeric check for sequence keys      |
| WS-IN-DEALER-CODE           | DEALER.DEALER_CODE                   | X(05)          | Required for INQ/UPD                           |
| WS-IN-DEALER-NAME           | DEALER.DEALER_NAME                   | X(60)          | Required for ADD                               |
| WS-IN-STATE                 | DEALER.STATE_CODE                    | X(02)          | Valid 2-char state                             |
| WS-IN-PHONE                 | DEALER.PHONE_NUMBER                  | X(10)          | Formatted via COMFMTL0                         |
| WS-IN-MODEL-YEAR            | MODEL_MASTER.MODEL_YEAR              | X(04)/9(04)    | Required, numeric                              |
| WS-IN-MAKE-CODE             | MODEL_MASTER.MAKE_CODE               | X(03)          | Required                                       |
| WS-IN-MODEL-CODE            | MODEL_MASTER.MODEL_CODE              | X(06)          | Required                                       |
| WS-IN-BODY-STYLE            | MODEL_MASTER.BODY_STYLE              | X(02)          | SD/SV/TK/CP/HB/VN/CV                          |
| WS-IN-ENGINE-TYPE           | MODEL_MASTER.ENGINE_TYPE             | X(03)          | GAS/DSL/HYB/EV                                |
| WS-IN-MSRP                  | PRICE_MASTER.MSRP                    | X(12)->DEC(11,2)| Must be > INVOICE                             |
| WS-IN-INVOICE               | PRICE_MASTER.INVOICE_PRICE           | X(12)->DEC(11,2)| Must be > 0                                   |
| WS-IN-HOLDBACK-PCT          | PRICE_MASTER.HOLDBACK_PCT            | X(06)->DEC(5,3) | 0-100                                         |
| WS-IN-STATE-RATE            | TAX_RATE.STATE_RATE                  | X(08)->DEC(5,4) | 0 to 0.15 (15%)                               |
| WS-IN-COUNTY-RATE           | TAX_RATE.COUNTY_RATE                 | X(08)->DEC(5,4) | 0 to 0.15                                      |
| WS-IN-CITY-RATE             | TAX_RATE.CITY_RATE                   | X(08)->DEC(5,4) | 0 to 0.15                                      |
| WS-IN-USER-ID               | SYSTEM_USER.USER_ID                  | X(08)          | Required for sign-on                            |
| WS-IN-PASSWORD              | (hashed to SYSTEM_USER.PASSWORD_HASH)| X(20)          | Hashed before compare                          |
| WS-IN-INCENT-TYPE           | INCENTIVE_PROGRAM.INCENTIVE_TYPE     | X(02)          | CR/DR/LR/FR/LB                                |
| WS-IN-STACKABLE             | INCENTIVE_PROGRAM.STACKABLE_FLAG     | X(01)          | Y/N                                            |

## Error Paths

- **ADMCFG00**: SQLCODE +100 on SELECT returns "CONFIG KEY NOT FOUND". Non-zero SQLCODE calls COMDBEL0 for formatted DB2 error. Numeric validation rejects non-numeric values for sequence keys (NEXT_STOCK_NUMBER, etc.).
- **ADMDLR00**: Duplicate DEALER_CODE on INSERT returns SQLCODE -803. Invalid region on LST returns empty result set.
- **ADMSEC00**: Invalid USER_ID returns "USER NOT FOUND". Locked account returns "ACCOUNT LOCKED". Wrong password increments FAILED_ATTEMPTS; at 5 failures, LOCKED_FLAG set to 'Y'. All failures logged to AUDIT_LOG.
- **ADMTAX00**: Rate values outside 0-0.15 range rejected. Missing STATE_CODE rejected.
- **ADMINC00**: Date range validation (START_DATE must be before END_DATE). Amount must be > 0. Model eligibility checked if model fields provided.
- **ADMPRC00**: MSRP must be greater than INVOICE_PRICE. Effective date logic ensures no overlapping price periods.
- **All programs**: IMS GU failure (IO-STATUS-CODE not spaces) returns "IMS GU FAILED" with status code.

## Cross-Domain Dependencies

| Dependency Direction | Related Domain       | Data Exchanged                                          |
|---------------------|----------------------|---------------------------------------------------------|
| Admin --> Sales     | Sales reads PRICE_MASTER, INCENTIVE_PROGRAM, TAX_RATE, SYSTEM_CONFIG for deal building |
| Admin --> Finance   | Finance reads DEALER for document generation; SYSTEM_CONFIG for sequences |
| Admin --> Vehicle   | Vehicle domain reads MODEL_MASTER for VIN decode and descriptions |
| Admin --> Stock     | Stock reads MODEL_MASTER for descriptions, PRICE_MASTER for valuations |
| Admin --> Floor Plan| Floor Plan reads DEALER for lender association |
| Admin --> Registration | Registration reads TAX_RATE for fee calculations |
| Admin --> All       | SYSTEM_USER referenced by all programs for user validation; AUDIT_LOG written by all programs via COMLGEL0 |
