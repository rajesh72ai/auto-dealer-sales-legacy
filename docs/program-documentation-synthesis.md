# AUTOSALES Program Documentation Synthesis

## 1. Common Patterns Across Programs

### IMS DC Message Handling Pattern (Online Programs)

Every online program follows the same IMS DC message processing pattern:

```cobol
ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.

0000-MAIN-PROCESS.
    PERFORM 1000-RECEIVE-INPUT          *> IMS GU call
    PERFORM 2000-VALIDATE-INPUT         *> Field validation
    PERFORM 3000-PROCESS-REQUEST        *> Business logic + DB2
    PERFORM 8000-FORMAT-OUTPUT          *> Build response message
    PERFORM 9000-SEND-OUTPUT            *> IMS ISRT call
    GOBACK.
```

**Input message structure**: `LL(2) + ZZ(2) + TRAN-CODE(8) + FUNCTION(2-4) + KEY-DATA + BODY`
- LL: Message length (binary halfword)
- ZZ: Reserved (binary halfword, always 0)
- TRAN-CODE: 4-8 character IMS transaction code
- FUNCTION: Action code (INQ, ADD, UPD, LST, DEL, etc.)

**Output message structure**: `LL(2) + ZZ(2) + MOD-NAME(8) + MSG-ID(8) + MSG-TEXT(79) + BODY`
- MOD-NAME: MFS output MOD name for screen formatting

**GU/ISRT pattern**:
```cobol
CALL 'CBLTDLI' USING WS-IO-GU IO-PCB-MASK WS-INPUT-MSG
*> Check IO-STATUS-CODE for errors (SPACES = success)

CALL 'CBLTDLI' USING WS-IO-ISRT IO-PCB-MASK WS-OUTPUT-MSG
```

### DB2 Cursor Pattern

Programs that display lists use a consistent cursor pattern:

```cobol
*> DECLARE CURSOR (once, in WORKING-STORAGE or inline)
EXEC SQL DECLARE cursor-name CURSOR FOR
    SELECT columns FROM table WHERE conditions
    ORDER BY sort-column
END-EXEC

*> OPEN (in processing paragraph)
EXEC SQL OPEN cursor-name END-EXEC

*> FETCH LOOP
PERFORM UNTIL SQLCODE = +100 OR rows-fetched >= page-size
    EXEC SQL FETCH cursor-name INTO :host-variables END-EXEC
    *> process row
END-PERFORM

*> CLOSE
EXEC SQL CLOSE cursor-name END-EXEC
```

Pagination uses PF7 (backward) / PF8 (forward) keys with cursor repositioning. Page sizes vary: 10 (CUSINQ00), 12 (VEHLST00), 15 (CUSLST00).

### DB2 Error Handling Pattern

Nearly all DB2 operations follow this pattern:

```cobol
EXEC SQL
    [SQL statement]
END-EXEC

EVALUATE SQLCODE
    WHEN 0
        CONTINUE
    WHEN +100
        MOVE 'NOT FOUND' TO WS-ERROR-MSG
    WHEN OTHER
        MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
        MOVE 'paragraph-name' TO WS-DBE-SECTION
        MOVE 'TABLE_NAME' TO WS-DBE-TABLE
        MOVE 'OPERATION' TO WS-DBE-OPERATION
        CALL 'COMDBEL0' USING SQLCA
                               WS-DBE-PROGRAM
                               WS-DBE-SECTION
                               WS-DBE-TABLE
                               WS-DBE-OPERATION
                               WS-DBE-RESULT
END-EVALUATE
```

COMDBEL0 categorizes SQLCODEs:
| Return Code | Meaning | Action |
|------------|---------|--------|
| 00 | Success (SQLCODE 0) | Continue processing |
| 04 | Not found (SQLCODE +100) | Handle as business condition |
| 08 | Recoverable error | Display error, allow retry |
| 12 | Fatal error | Rollback, potential ABEND |

### Checkpoint/Restart Pattern (Batch Programs)

All batch programs use the same checkpoint/restart lifecycle:

```cobol
*> At program start:
CALL 'COMCKPL0' USING 'INIT' WS-CHKP-DATA WS-CHKP-RESULT
*> Checks RESTART_CONTROL for pending restart

*> If restart pending:
CALL 'COMCKPL0' USING 'XRST' WS-CHKP-DATA WS-CHKP-RESULT
*> Restores checkpoint data, repositions cursors

*> Every N records (N varies by program: 200-1000):
CALL 'COMCKPL0' USING 'CHKP' WS-CHKP-DATA WS-CHKP-RESULT
*> Issues IMS symbolic checkpoint, saves position

*> On successful completion:
CALL 'COMCKPL0' USING 'DONE' WS-CHKP-DATA WS-CHKP-RESULT
*> Marks job complete in RESTART_CONTROL

*> On failure:
CALL 'COMCKPL0' USING 'FAIL' WS-CHKP-DATA WS-CHKP-RESULT
*> Marks job failed, saves failure point
```

Checkpoint intervals by program:
| Program | Interval | Unit |
|---------|---------|------|
| BATDLY00 | 500 | Vehicles |
| BATWKL00 | 500 | Records |
| BATMTH00 | 100 | Dealers |
| BATCRM00 | 500 | Customers |
| BATDMS00 | 500 | Records |
| BATGLINT | 200 | Deals |
| BATDLAKE | 1000 | Records |
| BATINB00 | 500 | Records |
| BATPUR00 | 1000 | Records |
| BATVAL00 | 500 | Records |

### Audit Logging Pattern

Virtually all data-modifying programs call COMLGEL0:

```cobol
MOVE WS-USER-ID    TO WS-AUD-USER-ID
MOVE WS-MODULE-ID  TO WS-AUD-PROGRAM-ID
MOVE 'INS'         TO WS-AUD-ACTION      *> INS/UPD/DEL/LON/LOF
MOVE 'TABLE_NAME'  TO WS-AUD-TABLE
MOVE key-value      TO WS-AUD-KEY
MOVE old-value      TO WS-AUD-OLD-VAL    *> Blank for INSERT
MOVE new-value      TO WS-AUD-NEW-VAL    *> Blank for DELETE

CALL 'COMLGEL0' USING WS-AUD-USER-ID
                       WS-AUD-PROGRAM-ID
                       WS-AUD-ACTION
                       WS-AUD-TABLE
                       WS-AUD-KEY
                       WS-AUD-OLD-VAL
                       WS-AUD-NEW-VAL
                       WS-AUD-RC
                       WS-AUD-MSG
```

Action codes:
| Code | Meaning |
|------|---------|
| INS | Insert |
| UPD | Update |
| DEL | Delete |
| LON | Login successful |
| LOF | Login failed |

Design principle: Audit failures do NOT abend the calling program. The audit module swallows errors to prevent audit infrastructure from blocking business transactions.

---

## 2. Shared Data Access Patterns

### Tables Accessed by Multiple Programs

| Table | Read By | Written By |
|-------|---------|------------|
| **SYSTEM_USER** | ADMSEC00, SALAPV00, SALQOT00, SALNEG00, SALVAL00, CUSADD00 | ADMSEC00 |
| **CUSTOMER** | CUSINQ00, CUSLST00, CUSHIS00, CUSADD00, CUSUPD00, CUSCRED0, CUSLEAD0, SALQOT00, SALNEG00, FINCHK00, FINDOC00, WRCNOTF0, WRCINQ00, REGGEN00, REGVAL00, REGSUB00, BATCRM00, BATDMS00, BATDLAKE, BATVAL00 | CUSADD00, CUSUPD00, BATCRM00 |
| **VEHICLE** | VEHINQ00, VEHLST00, VEHAGE00, VEHRCV00, VEHUPD00, VEHALL00, VEHTRN00, SALQOT00, SALCMP00, SALCAN00, CUSHIS00, FPLADD00, FPLINQ00, PLIPROD0, PLIDLVR0, PLIETA00, PLISHPN0, PLITRNS0, PLIRECON, STKAGIN0, STKSNAP0, STKSUM00, STKVALS0, WRCINQ00, WRCRCLB0, WRCRCL00, REGGEN00, REGSUB00, BATDLY00, BATWKL00, BATDMS00, BATDLAKE, BATVAL00, BATINB00 | VEHRCV00, VEHUPD00, VEHALL00, SALCMP00, SALCAN00, PLIPROD0, PLIDLVR0, STKADJT0, STKAGIN0, BATDLY00, BATWKL00, BATINB00 |
| **SALES_DEAL** | SALQOT00, SALNEG00, SALAPV00, SALCMP00, SALCAN00, SALVAL00, SALINC00, CUSHIS00, FINAPP00, FINAPV00, FINDOC00, FINCHK00, FINPRD00, WRCINQ00, WRCWAR00, WRCNOTF0, REGGEN00, REGINQ00, BATDLY00, BATMTH00, BATCRM00, BATDMS00, BATDLAKE, BATGLINT, BATVAL00 | SALQOT00, SALNEG00, SALAPV00, SALCMP00, SALCAN00, SALVAL00, FINAPP00, FINAPV00, FINPRD00, BATDLY00, BATMTH00, BATGLINT |
| **STOCK_POSITION** | STKINQ00, STKALRT0, STKRCN00, STKSNAP0, STKSUM00, PLIALLO0 | COMSTCK0 (via RECV/SOLD/HOLD/RLSE/TRNI/TRNO/ALOC), STKRCN00, STKADJT0, BATMTH00 |
| **PRICE_MASTER** | ADMPRC00, COMPRCL0, SALQOT00, SALTRD00, STKAGIN0, STKSNAP0, STKVALS0, STKSUM00, VEHAGE00 | ADMPRC00 |
| **AUDIT_LOG** | BATDLAKE, BATPUR00 | COMLGEL0 (on behalf of all programs) |
| **FLOOR_PLAN_VEHICLE** | FPLINQ00, FPLINT00, FPLPAY00, FPLRPT00, STKVALS0, SALCAN00, COMINTL0 | FPLADD00, FPLINT00, FPLPAY00, SALCAN00, BATDLY00 |

### High-Contention Tables

These tables see the most concurrent access and are potential bottlenecks:

1. **SALES_DEAL** -- Read and written by SAL, FIN, BAT, REG, WRC modules
2. **VEHICLE** -- Read by nearly every module, written by VEH, SAL, PLI, STK, BAT
3. **CUSTOMER** -- Read by CUS, SAL, FIN, WRC, REG, BAT modules
4. **STOCK_POSITION** -- Updated by COMSTCK0 for every inventory movement
5. **SYSTEM_CONFIG** -- Used for sequences (SELECT FOR UPDATE by COMSEQL0)

---

## 3. Call Tree Analysis

### Most-Called Common Modules

| Rank | Module | Approximate Callers | Purpose |
|-----:|--------|-------------------:|---------|
| 1 | COMLGEL0 | ~65 programs | Audit logging |
| 2 | COMDBEL0 | ~55 programs | DB2 error handling |
| 3 | COMFMTL0 | ~45 programs | Field formatting |
| 4 | COMMSGL0 | ~20 programs | IMS message building |
| 5 | COMSTCK0 | ~15 programs | Stock count updates |
| 6 | COMVALD0 | ~12 programs | VIN validation |
| 7 | COMTAXL0 | ~8 programs | Tax calculation |
| 8 | COMPRCL0 | ~8 programs | Vehicle pricing |
| 9 | COMDTEL0 | ~8 programs | Date utilities |
| 10 | COMSEQL0 | ~7 programs | Sequence generation |
| 11 | COMCKPL0 | ~11 programs | Checkpoint/restart (all batch) |
| 12 | COMLONL0 | ~5 programs | Loan calculation |
| 13 | COMLESL0 | ~3 programs | Lease calculation |
| 14 | COMINTL0 | ~5 programs | Floor plan interest |
| 15 | COMVINL0 | ~5 programs | VIN decoding |
| 16 | COMEDIL0 | ~2 programs | EDI parsing |

### Call Depth Analysis

Maximum call depth observed is 2 levels (main program -> common module). No common module calls another common module, keeping the architecture flat and preventing cascading failures.

Example call chains:
```
SALQOT00 -> COMPRCL0 (pricing)
         -> COMTAXL0 (tax)
         -> COMSEQL0 (sequence)
         -> COMFMTL0 (formatting)
         -> COMLGEL0 (audit)
         -> COMDBEL0 (error handling)

BATDLY00 -> COMCKPL0 (checkpoint)
         -> COMINTL0 (interest calc)
         -> COMDBEL0 (error handling)
         -> COMLGEL0 (audit)
```

### Programs by Number of External Calls

| Program | External CALL Count | Description |
|---------|-------------------:|-------------|
| SALQOT00 | 6 | Deal worksheet -- most complex online program |
| VEHRCV00 | 5 | Vehicle receiving |
| SALTRD00 | 5 | Trade-in evaluation |
| SALCMP00 | 5 | Sale completion |
| FINDOC00 | 4 | Finance document generation |
| PLIDLVR0 | 3 | Delivery confirmation |
| PLIPROD0 | 4 | Production completion |
| REGGEN00 | 4 | Registration generation |

---

## 4. Error Handling Patterns

### Three-Level Error Strategy

1. **Business Validation Errors** (Return Code 4-8)
   - Invalid input, missing required fields, business rule violations
   - Handled inline with error messages returned to terminal
   - User can correct and resubmit
   - Pattern: Set `WS-ERROR-MSG`, set return code, GO TO exit paragraph

2. **DB2 Errors** (via COMDBEL0, Return Code 8-12)
   - SQLCODE evaluation centralized in COMDBEL0
   - Deadlocks and timeouts flagged as retryable (`WS-DBE-RETRY = 'Y'`)
   - NOT FOUND (SQLCODE +100) treated as business condition, not error
   - Fatal errors (SQLCODE < 0 except deadlock) trigger rollback consideration

3. **IMS Communication Errors**
   - IO-STATUS-CODE checked after every GU/ISRT call
   - Non-blank status = error
   - Pattern: `IF IO-STATUS-CODE NOT = SPACES` -> set error flag, build error message

### Error Recovery in Batch

Batch programs handle errors differently from online:
- Checkpoint every N records allows restart from last good point
- BATRSTRT utility provides manual checkpoint management:
  - DISP: Display last checkpoint info
  - RESET: Clear checkpoint for fresh re-run
  - COMPL: Mark job complete (skip restart)
- COMCKPL0 FAIL function records failure point for restart

### Null Handling Pattern

Programs use null indicators for nullable DB2 columns:

```cobol
01  WS-NULL-IND.
    05  NI-COMMENTS  PIC S9(04) COMP VALUE +0.

*> Before INSERT/UPDATE:
IF WS-FIELD = SPACES
    MOVE -1 TO NI-FIELD        *> -1 = NULL
ELSE
    MOVE +0 TO NI-FIELD        *> 0 = NOT NULL
END-IF

EXEC SQL INSERT INTO table (col) VALUES (:host-var :NI-FIELD) END-EXEC
```

---

## 5. Security Model Analysis

### Authentication Layer (ADMSEC00)

**Strengths:**
- Centralized sign-on through single program (ADMSEC00)
- Account lockout after 5 failed attempts prevents brute force
- Both success and failure audited to AUDIT_LOG
- Active flag provides soft-delete capability for user accounts
- Clear separation: authentication in ADMSEC00, authorization in business programs

**Authorization by User Type:**
| Operation | S (Sales) | F (F&I) | C (Clerk) | M (Mgr) | G (GM) | A (Admin) |
|-----------|-----------|---------|-----------|---------|--------|-----------|
| Create deals | Yes | No | No | Yes | Yes | Yes |
| View invoice price | No | No | No | Yes | Yes | Yes |
| View gross profit | No | No | No | Yes | Yes | Yes |
| Approve standard deal | No | No | No | Yes | Yes | Yes |
| Approve loser deal | No | No | No | No | Yes | Yes |
| Reject deal | No | No | No | Yes | Yes | Yes |
| System config | No | No | No | No | No | Yes |
| User management | No | No | No | No | No | Yes |

**Weaknesses/Observations:**
- Password hashing is simplified (direct comparison for demo purposes)
- No password complexity enforcement evident in the code
- No session timeout mechanism (IMS DC handles conversation timeout externally)
- No IP/terminal-based restrictions beyond IMS LTERM security
- Role-based access is hardcoded in individual programs rather than a centralized authorization table

---

## 6. Batch vs. Online Architectural Differences

| Aspect | Online (IMS DC MPP) | Batch (IMS BMP) |
|--------|---------------------|-----------------|
| **Entry Point** | `ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1` | `ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1` (same) |
| **Input Source** | IMS GU call from terminal | DB2 cursors, file DD statements |
| **Output Target** | IMS ISRT to terminal (MFS screen) | File DD statements, DB2 tables |
| **Processing Model** | Single transaction per invocation | Cursor-driven loop over many records |
| **Error Recovery** | Return error message, user retries | Checkpoint/restart via COMCKPL0 |
| **Commit Scope** | Implicit (IMS sync point at GU/ISRT) | Explicit checkpoint every N records |
| **Concurrency** | Multiple MPPs concurrent | Single BMP instance per job |
| **Duration** | Sub-second per transaction | Minutes to hours |
| **PSB** | Module-specific (PSBADM01, PSBSAL01, etc.) | Batch-specific (PSBBAT01-05) |
| **DB2 Access** | Embedded SQL in program | Embedded SQL with cursors |
| **File I/O** | None (message-based) | OPEN/READ/WRITE/CLOSE via DD names |
| **JCL** | Defined in IMS control region | Individual JCL per job (jcl/batch/) |

### PSB Allocation

| PSB | Used By |
|-----|---------|
| PSBADM01 | ADM module (8 programs) |
| PSBCUS01 | CUS module (7 programs) |
| PSBSAL01 | SAL module (8 programs) |
| PSBFIN01 | FIN module (7 programs) |
| PSBFPL01 | FPL module (5 programs) |
| PSBPLI01 | PLI module (8 programs) |
| PSBREG01 | REG module (5 programs) |
| PSBSTK01 | STK module (10 programs) |
| PSBVEH01 | VEH module (8 programs) |
| PSBWRC01 | WRC module (6 programs) |
| PSBRPT01 | RPT module (14 programs) |
| PSBBAT01-05 | BAT module (11 programs, grouped by DB access needs) |

### IMS Hierarchical DB Usage

The 5 DBDs provide hierarchical views used primarily for read performance optimization. The authoritative data store is DB2; the IMS hierarchical segments mirror DB2 data for fast parent-child navigation in online transactions:

| DBD | Root Segment | Child Segments | Primary Consumer |
|-----|-------------|----------------|-----------------|
| DBDAUTO1 | VEHICLE | VEHOPT, VEHSTAT, VEHLOC | VEH, STK modules |
| DBDAUTO2 | CUSTOMER | Deal history, Credit check | CUS module |
| DBDAUTO3 | DEAL | Line items, Trade-in, Finance | SAL, FIN modules |
| DBDAUTO4 | FLOOR_PLAN | Interest accrual, Payment | FPL module |
| DBDAUTO5 | WARRANTY | Campaign, Notification | WRC module |

---

## 7. Copybook Usage Patterns

### Common Copybooks (cpy/common/)

| Copybook | Purpose | Used By |
|----------|---------|---------|
| WSIOPCB | IMS I/O PCB mask and function codes | All online programs |
| WSSQLCA | DB2 SQLCA declaration | All programs using DB2 |
| WSMSGFMT | MFS message format working storage | Most online programs |
| WSCOMMON | Common working storage fields | Multiple programs |
| WSDBPCB | Database PCB definitions | All programs with DB PCBs |
| WSAUDIT | Audit log field definitions | Programs calling COMLGEL0 |
| WSPARAM | System parameter fields | Configuration-aware programs |
| WSCKPT00 | Checkpoint data area | All batch programs |
| WSRSTCTL | Restart control fields | Batch programs with restart |
| WSEDI000 | EDI segment layouts | COMEDIL0, PLITRNS0 |
| WSFPL000 | Floor plan working storage | FPL module programs |
| WSPLI000 | Production/logistics working storage | PLI module programs |
| WSSTOCK0 | Stock management working storage | STK module programs |
| WSWRC000 | Warranty/recall working storage | WRC module programs |

### DCLGEN Copybooks (cpy/dclgen/)

44 DCLGEN copybooks correspond to DB2 tables. Each contains host variable declarations generated by the DB2 DCLGEN utility. Naming convention: `DCL` + abbreviated table name.

Key DCLGEN copybooks and their table mappings:
| Copybook | DB2 Table |
|----------|-----------|
| DCLSYUSR | SYSTEM_USER |
| DCLDEALR | DEALER |
| DCLMODEL | MODEL_MASTER |
| DCLPRICE | PRICE_MASTER |
| DCLCUSTM | CUSTOMER |
| DCLVEHCL | VEHICLE |
| DCLSLDEL | SALES_DEAL |
| DCLDLITM | DEAL_LINE_ITEM |
| DCLSLAPV | SALES_APPROVAL |
| DCLFINAP | FINANCE_APP |
| DCLFPVEH | FLOOR_PLAN_VEHICLE |
| DCLFPINT | FLOOR_PLAN_INTEREST |
| DCLREGST | REGISTRATION |
| DCLWARTY | WARRANTY |
| DCLTAXRT | TAX_RATE |
| DCLAUDIT | AUDIT_LOG |
| DCLRSTCT | RESTART_CONTROL |

---

## 8. Naming Conventions Summary

| Element | Convention | Example |
|---------|-----------|---------|
| Program ID | 3-letter module + function + sequence | SALQOT00 |
| IMS Transaction | 4 characters | SALQ |
| MFS MID (input) | MFS + abbreviated screen name | MFSSLINP |
| MFS MOD (output) | AS + abbreviated response name | ASSLDL00 |
| Copybook (common) | WS + abbreviated name | WSIOPCB |
| Copybook (DCLGEN) | DCL + abbreviated table | DCLSLDEL |
| DB2 Table | Full descriptive name | SALES_DEAL |
| DB2 Schema | AUTOSALE | AUTOSALE.SALES_DEAL |
| Working Storage | WS- prefix | WS-MODULE-ID |
| Linkage Section | LK- or LS- prefix | LK-VIN-INPUT |
| PSB | PSB + module + sequence | PSBSAL01 |
| DBD | DBD + system + sequence | DBDAUTO1 |
| JCL (batch) | JCL + program suffix | JCLDLY00 |
| JCL (reports) | JCLRP + report suffix | JCLRPDLY |
| Paragraph Numbers | NNNN-DESCRIPTIVE-NAME | 3000-LOOKUP-USER |
