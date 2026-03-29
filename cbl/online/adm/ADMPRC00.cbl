       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMPRC00.
      ****************************************************************
      * PROGRAM:    ADMPRC00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMP                                             *
      * MFS MID:    MFSADPRC (PRICING MAINTENANCE SCREEN)            *
      * MFS MOD:    ASPRCI00 (PRICING INQUIRY RESPONSE)              *
      *                                                              *
      * PURPOSE:    PRICING MASTER MAINTENANCE. PROVIDES CRUD        *
      *             OPERATIONS ON THE PRICE_MASTER TABLE.             *
      *             VALIDATES BUSINESS RULES (MSRP > INVOICE,        *
      *             HOLDBACK CALCULATIONS, EFFECTIVE DATE LOGIC).     *
      *             SHOWS PRICE HISTORY FOR A GIVEN MODEL.            *
      *                                                              *
      * FUNCTIONS:  INQ - INQUIRY BY YEAR/MAKE/MODEL                 *
      *             ADD - ADD NEW PRICE RECORD                       *
      *             UPD - UPDATE EXISTING PRICE                      *
      *                                                              *
      * CALLS:      COMFMTL0 - FORMAT CURRENCY                      *
      *             COMLGEL0 - AUDIT LOGGING                         *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMPRC00'.
      *
      *    IMS FUNCTION CODES
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR PRICE_MASTER TABLE
      *
           COPY DCLPRICE.
      *
      *    INPUT MESSAGE LAYOUT
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL             PIC S9(04) COMP.
           05  WS-IN-ZZ             PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE      PIC X(08).
           05  WS-IN-FUNC-CODE      PIC X(03).
               88  WS-FUNC-INQ                VALUE 'INQ'.
               88  WS-FUNC-ADD                VALUE 'ADD'.
               88  WS-FUNC-UPD                VALUE 'UPD'.
           05  WS-IN-MODEL-YEAR     PIC X(04).
           05  WS-IN-MAKE-CODE      PIC X(03).
           05  WS-IN-MODEL-CODE     PIC X(06).
           05  WS-IN-MSRP           PIC X(12).
           05  WS-IN-INVOICE        PIC X(12).
           05  WS-IN-HOLDBACK-AMT   PIC X(10).
           05  WS-IN-HOLDBACK-PCT   PIC X(06).
           05  WS-IN-DEST-FEE       PIC X(08).
           05  WS-IN-ADV-FEE        PIC X(08).
           05  WS-IN-EFF-DATE       PIC X(10).
           05  WS-IN-EXP-DATE       PIC X(10).
           05  WS-IN-USER-ID        PIC X(08).
           05  FILLER               PIC X(100).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL            PIC S9(04) COMP.
           05  WS-OUT-ZZ            PIC S9(04) COMP.
           05  WS-OUT-MOD-NAME      PIC X(08).
           05  WS-OUT-FUNC-CODE     PIC X(03).
           05  WS-OUT-MODEL-YEAR    PIC 9(04).
           05  WS-OUT-MAKE-CODE     PIC X(03).
           05  WS-OUT-MODEL-CODE    PIC X(06).
           05  WS-OUT-MSRP          PIC $$$,$$$,$$9.99.
           05  WS-OUT-INVOICE       PIC $$$,$$$,$$9.99.
           05  WS-OUT-HOLDBACK-AMT  PIC $$$$,$$9.99.
           05  WS-OUT-HOLDBACK-PCT  PIC 99.999.
           05  WS-OUT-DEST-FEE      PIC $$$$$9.99.
           05  WS-OUT-ADV-FEE       PIC $$$$$9.99.
           05  WS-OUT-EFF-DATE      PIC X(10).
           05  WS-OUT-EXP-DATE      PIC X(10).
           05  WS-OUT-MARGIN        PIC $$$,$$$,$$9.99.
           05  WS-OUT-MARGIN-PCT    PIC Z9.99.
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
      *
      *    PRICE HISTORY OUTPUT (UP TO 5 PREVIOUS PRICES)
      *
           05  WS-OUT-HIST-COUNT    PIC 9(02).
           05  WS-OUT-HIST-ENTRY OCCURS 5 TIMES.
               10  WS-OUT-HIST-EFF PIC X(10).
               10  WS-OUT-HIST-EXP PIC X(10).
               10  WS-OUT-HIST-MSRP
                                    PIC $$$,$$$,$$9.99.
               10  WS-OUT-HIST-INV PIC $$$,$$$,$$9.99.
           05  FILLER               PIC X(20).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-MODEL-YEAR-NUM   PIC S9(04) COMP VALUE 0.
           05  WS-MSRP-NUM         PIC S9(09)V9(02) COMP-3 VALUE 0.
           05  WS-INVOICE-NUM      PIC S9(09)V9(02) COMP-3 VALUE 0.
           05  WS-HOLDBACK-AMT-NUM PIC S9(07)V9(02) COMP-3 VALUE 0.
           05  WS-HOLDBACK-PCT-NUM PIC S9(02)V9(03) COMP-3 VALUE 0.
           05  WS-DEST-FEE-NUM     PIC S9(05)V9(02) COMP-3 VALUE 0.
           05  WS-ADV-FEE-NUM      PIC S9(05)V9(02) COMP-3 VALUE 0.
           05  WS-MARGIN-WORK      PIC S9(09)V9(02) COMP-3 VALUE 0.
           05  WS-MARGIN-PCT-WORK  PIC S9(03)V9(02) COMP-3 VALUE 0.
           05  WS-HIST-IDX         PIC 9(02) VALUE 0.
           05  WS-HIST-COUNT       PIC 9(02) VALUE 0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-EXPIRY-DATE       PIC S9(04) COMP VALUE 0.
           05  NI-HIST-EXP          PIC S9(04) COMP VALUE 0.
      *
      *    HISTORY CURSOR WORK FIELDS
      *
       01  WS-HIST-WORK.
           05  WS-HIST-EFF-DATE    PIC X(10).
           05  WS-HIST-EXP-DATE    PIC X(10).
           05  WS-HIST-MSRP        PIC S9(09)V9(02) COMP-3.
           05  WS-HIST-INV         PIC S9(09)V9(02) COMP-3.
      *
      *    AUDIT LOGGING FIELDS
      *
       01  WS-AUDIT-FIELDS.
           05  WS-AUD-USER-ID      PIC X(08).
           05  WS-AUD-PROGRAM-ID   PIC X(08).
           05  WS-AUD-ACTION       PIC X(03).
           05  WS-AUD-TABLE        PIC X(30).
           05  WS-AUD-KEY          PIC X(50).
           05  WS-AUD-OLD-VAL      PIC X(200).
           05  WS-AUD-NEW-VAL      PIC X(200).
           05  WS-AUD-RC           PIC S9(04) COMP.
           05  WS-AUD-MSG          PIC X(50).
      *
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-FIELDS.
           05  WS-DBE-PROGRAM      PIC X(08).
           05  WS-DBE-SECTION      PIC X(30).
           05  WS-DBE-TABLE        PIC X(18).
           05  WS-DBE-OPERATION    PIC X(10).
           05  WS-DBE-RESULT.
               10  WS-DBE-RC      PIC S9(04) COMP.
               10  WS-DBE-RETRY   PIC X(01).
               10  WS-DBE-MSG     PIC X(120).
               10  WS-DBE-SQLCD   PIC X(10).
               10  WS-DBE-SQLST   PIC X(05).
               10  WS-DBE-CATEG   PIC X(20).
               10  WS-DBE-SEVER   PIC X(01).
               10  WS-DBE-ROWS    PIC S9(09) COMP.
      *
      *    CURSOR FOR PRICE HISTORY
      *
           EXEC SQL
               DECLARE PRICE_HIST_CSR CURSOR FOR
               SELECT EFFECTIVE_DATE,
                      EXPIRY_DATE,
                      MSRP,
                      INVOICE_PRICE
               FROM   AUTOSALE.PRICE_MASTER
               WHERE  MODEL_YEAR = :WS-MODEL-YEAR-NUM
               AND    MAKE_CODE  = :WS-IN-MAKE-CODE
               AND    MODEL_CODE = :WS-IN-MODEL-CODE
               ORDER BY EFFECTIVE_DATE DESC
               FETCH FIRST 5 ROWS ONLY
           END-EXEC.
      *
       LINKAGE SECTION.
      *
       01  LK-IO-PCB.
           05  LK-IO-LTERM         PIC X(08).
           05  FILLER              PIC X(02).
           05  LK-IO-STATUS        PIC X(02).
           05  LK-IO-DATE          PIC S9(07) COMP-3.
           05  LK-IO-TIME          PIC S9(07) COMP-3.
           05  LK-IO-SEQ           PIC S9(09) COMP.
           05  LK-IO-MOD           PIC X(08).
           05  LK-IO-USER          PIC X(08).
           05  LK-IO-GROUP         PIC X(08).
      *
       01  LK-DB-PCB-1.
           05  LK-DB1-DBD-NAME     PIC X(08).
           05  LK-DB1-SEG-LEVEL    PIC X(02).
           05  LK-DB1-STATUS       PIC X(02).
           05  LK-DB1-PROC-OPT     PIC X(04).
           05  FILLER              PIC S9(05) COMP.
           05  LK-DB1-SEG-NAME     PIC X(08).
           05  LK-DB1-KEY-LEN      PIC S9(05) COMP.
           05  LK-DB1-NSENS-SEGS   PIC S9(05) COMP.
           05  LK-DB1-KEY-FB       PIC X(50).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB-MASK
                              LK-DB-PCB-1.
      *
       0000-MAIN-PROCESS.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
      *
           PERFORM 1000-RECEIVE-INPUT
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR
               GOBACK
           END-IF
      *
           EVALUATE TRUE
               WHEN WS-FUNC-INQ
                   PERFORM 3000-INQUIRY
               WHEN WS-FUNC-ADD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 4000-ADD-PRICE
                   END-IF
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-PRICE
                   END-IF
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INVALID FUNCTION: '
                          WS-IN-FUNC-CODE
                          '. USE INQ/ADD/UPD'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
           END-EVALUATE
      *
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR
           END-IF
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - RECEIVE INPUT MESSAGE VIA IMS GU CALL                   *
      *---------------------------------------------------------------*
       1000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-IO-GU
                                IO-PCB-MASK
                                WS-INPUT-MSG
      *
           IF IO-STATUS-CODE NOT = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'IMS GU FAILED - STATUS: '
                      IO-STATUS-CODE
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
           END-IF
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - VALIDATE PRICING INPUT FIELDS                           *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
      *    MODEL YEAR REQUIRED AND NUMERIC
      *
           IF WS-IN-MODEL-YEAR NOT NUMERIC
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL YEAR MUST BE NUMERIC'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
           MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-NUM
      *
      *    MAKE CODE AND MODEL CODE REQUIRED
      *
           IF WS-IN-MAKE-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MAKE CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           IF WS-IN-MODEL-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    CONVERT AND VALIDATE MSRP
      *
           IF WS-IN-MSRP = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MSRP IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
           COMPUTE WS-MSRP-NUM = FUNCTION NUMVAL(WS-IN-MSRP)
      *
           IF WS-MSRP-NUM <= 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MSRP MUST BE GREATER THAN ZERO'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    CONVERT AND VALIDATE INVOICE PRICE
      *
           IF WS-IN-INVOICE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INVOICE PRICE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
           COMPUTE WS-INVOICE-NUM = FUNCTION NUMVAL(WS-IN-INVOICE)
      *
           IF WS-INVOICE-NUM <= 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INVOICE PRICE MUST BE GREATER THAN ZERO'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    MSRP MUST BE GREATER THAN INVOICE
      *
           IF WS-MSRP-NUM <= WS-INVOICE-NUM
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MSRP MUST BE GREATER THAN INVOICE PRICE'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    HOLDBACK - CALCULATE FROM PERCENTAGE IF AMOUNT NOT PROVIDED
      *
           IF WS-IN-HOLDBACK-AMT NOT = SPACES
               COMPUTE WS-HOLDBACK-AMT-NUM =
                   FUNCTION NUMVAL(WS-IN-HOLDBACK-AMT)
           ELSE
               IF WS-IN-HOLDBACK-PCT NOT = SPACES
                   COMPUTE WS-HOLDBACK-PCT-NUM =
                       FUNCTION NUMVAL(WS-IN-HOLDBACK-PCT)
                   COMPUTE WS-HOLDBACK-AMT-NUM =
                       WS-MSRP-NUM * WS-HOLDBACK-PCT-NUM / 100
               ELSE
      *            DEFAULT HOLDBACK: 3% OF MSRP
                   MOVE 3.000 TO WS-HOLDBACK-PCT-NUM
                   COMPUTE WS-HOLDBACK-AMT-NUM =
                       WS-MSRP-NUM * 0.03
               END-IF
           END-IF
      *
      *    COMPUTE HOLDBACK PERCENTAGE IF NOT PROVIDED
      *
           IF WS-IN-HOLDBACK-PCT = SPACES
           AND WS-MSRP-NUM > 0
               COMPUTE WS-HOLDBACK-PCT-NUM =
                   (WS-HOLDBACK-AMT-NUM / WS-MSRP-NUM) * 100
           END-IF
      *
      *    VALIDATE HOLDBACK IS REASONABLE (< 10% OF MSRP)
      *
           IF WS-HOLDBACK-PCT-NUM > 10.000
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'HOLDBACK EXCEEDS 10 PCT OF MSRP'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    DESTINATION FEE
      *
           IF WS-IN-DEST-FEE NOT = SPACES
               COMPUTE WS-DEST-FEE-NUM =
                   FUNCTION NUMVAL(WS-IN-DEST-FEE)
           ELSE
               MOVE 0 TO WS-DEST-FEE-NUM
           END-IF
      *
      *    ADVERTISING FEE
      *
           IF WS-IN-ADV-FEE NOT = SPACES
               COMPUTE WS-ADV-FEE-NUM =
                   FUNCTION NUMVAL(WS-IN-ADV-FEE)
           ELSE
               MOVE 0 TO WS-ADV-FEE-NUM
           END-IF
      *
      *    EFFECTIVE DATE REQUIRED
      *
           IF WS-IN-EFF-DATE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'EFFECTIVE DATE IS REQUIRED (YYYY-MM-DD)'
                   TO WS-ERROR-MSG
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INQUIRY - SELECT CURRENT PRICE AND SHOW HISTORY        *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-MODEL-YEAR NOT NUMERIC
           OR WS-IN-MAKE-CODE = SPACES
           OR WS-IN-MODEL-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'YEAR, MAKE, AND MODEL REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-NUM
      *
      *    GET CURRENT EFFECTIVE PRICE
      *
           EXEC SQL
               SELECT MODEL_YEAR, MAKE_CODE, MODEL_CODE,
                      MSRP, INVOICE_PRICE,
                      HOLDBACK_AMT, HOLDBACK_PCT,
                      DESTINATION_FEE, ADVERTISING_FEE,
                      EFFECTIVE_DATE, EXPIRY_DATE
               INTO   :DCLPRICE-MASTER.MODEL-YEAR,
                      :DCLPRICE-MASTER.MAKE-CODE,
                      :DCLPRICE-MASTER.MODEL-CODE,
                      :DCLPRICE-MASTER.MSRP,
                      :DCLPRICE-MASTER.INVOICE-PRICE,
                      :DCLPRICE-MASTER.HOLDBACK-AMT,
                      :DCLPRICE-MASTER.HOLDBACK-PCT,
                      :DCLPRICE-MASTER.DESTINATION-FEE,
                      :DCLPRICE-MASTER.ADVERTISING-FEE,
                      :DCLPRICE-MASTER.EFFECTIVE-DATE,
                      :DCLPRICE-MASTER.EXPIRY-DATE
                          :NI-EXPIRY-DATE
               FROM   AUTOSALE.PRICE_MASTER
               WHERE  MODEL_YEAR = :WS-MODEL-YEAR-NUM
               AND    MAKE_CODE  = :WS-IN-MAKE-CODE
               AND    MODEL_CODE = :WS-IN-MODEL-CODE
               AND    EFFECTIVE_DATE <= CURRENT DATE
               AND    (EXPIRY_DATE IS NULL
                       OR EXPIRY_DATE >= CURRENT DATE)
               ORDER BY EFFECTIVE_DATE DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 3100-FORMAT-PRICE-OUTPUT
                   PERFORM 3200-FETCH-PRICE-HISTORY
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'NO CURRENT PRICE FOUND FOR: '
                          WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-INQUIRY' TO WS-DBE-SECTION
                   MOVE 'PRICE_MASTER' TO WS-DBE-TABLE
                   MOVE 'SELECT' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM
                                         WS-DBE-SECTION
                                         WS-DBE-TABLE
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT
                   MOVE WS-DBE-MSG(1:79) TO WS-ERROR-MSG
           END-EVALUATE
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3100 - FORMAT PRICE INQUIRY OUTPUT                              *
      *---------------------------------------------------------------*
       3100-FORMAT-PRICE-OUTPUT.
      *
           MOVE 800 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASPRCI00' TO WS-OUT-MOD-NAME
           MOVE 'INQ' TO WS-OUT-FUNC-CODE
           MOVE MODEL-YEAR OF DCLPRICE-MASTER
               TO WS-OUT-MODEL-YEAR
           MOVE MAKE-CODE OF DCLPRICE-MASTER
               TO WS-OUT-MAKE-CODE
           MOVE MODEL-CODE OF DCLPRICE-MASTER
               TO WS-OUT-MODEL-CODE
           MOVE MSRP OF DCLPRICE-MASTER TO WS-OUT-MSRP
           MOVE INVOICE-PRICE OF DCLPRICE-MASTER
               TO WS-OUT-INVOICE
           MOVE HOLDBACK-AMT OF DCLPRICE-MASTER
               TO WS-OUT-HOLDBACK-AMT
           MOVE HOLDBACK-PCT OF DCLPRICE-MASTER
               TO WS-OUT-HOLDBACK-PCT
           MOVE DESTINATION-FEE OF DCLPRICE-MASTER
               TO WS-OUT-DEST-FEE
           MOVE ADVERTISING-FEE OF DCLPRICE-MASTER
               TO WS-OUT-ADV-FEE
           MOVE EFFECTIVE-DATE OF DCLPRICE-MASTER
               TO WS-OUT-EFF-DATE
      *
           IF NI-EXPIRY-DATE >= 0
               MOVE EXPIRY-DATE OF DCLPRICE-MASTER
                   TO WS-OUT-EXP-DATE
           ELSE
               MOVE '(CURRENT)' TO WS-OUT-EXP-DATE
           END-IF
      *
      *    CALCULATE MARGIN
      *
           COMPUTE WS-MARGIN-WORK =
               MSRP OF DCLPRICE-MASTER -
               INVOICE-PRICE OF DCLPRICE-MASTER
           MOVE WS-MARGIN-WORK TO WS-OUT-MARGIN
      *
           IF MSRP OF DCLPRICE-MASTER > 0
               COMPUTE WS-MARGIN-PCT-WORK =
                   (WS-MARGIN-WORK /
                    MSRP OF DCLPRICE-MASTER) * 100
               MOVE WS-MARGIN-PCT-WORK TO WS-OUT-MARGIN-PCT
           ELSE
               MOVE 0 TO WS-OUT-MARGIN-PCT
           END-IF
      *
           MOVE 'PRICING RECORD DISPLAYED SUCCESSFULLY'
               TO WS-OUT-MSG-LINE1
           .
       3100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3200 - FETCH PRICE HISTORY (PREVIOUS EFFECTIVE DATES)          *
      *---------------------------------------------------------------*
       3200-FETCH-PRICE-HISTORY.
      *
           MOVE 0 TO WS-HIST-IDX
           MOVE 0 TO WS-HIST-COUNT
      *
           EXEC SQL
               OPEN PRICE_HIST_CSR
           END-EXEC
      *
           IF SQLCODE NOT = 0
               GO TO 3200-EXIT
           END-IF
      *
           PERFORM 3210-FETCH-HIST-ROW
               UNTIL SQLCODE NOT = 0
               OR WS-HIST-IDX >= 5
      *
           EXEC SQL
               CLOSE PRICE_HIST_CSR
           END-EXEC
      *
           MOVE WS-HIST-COUNT TO WS-OUT-HIST-COUNT
      *
      *    SEND COMPLETE OUTPUT
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       3200-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3210 - FETCH NEXT HISTORY ROW                                  *
      *---------------------------------------------------------------*
       3210-FETCH-HIST-ROW.
      *
           EXEC SQL
               FETCH PRICE_HIST_CSR
               INTO  :WS-HIST-EFF-DATE,
                     :WS-HIST-EXP-DATE :NI-HIST-EXP,
                     :WS-HIST-MSRP,
                     :WS-HIST-INV
           END-EXEC
      *
           IF SQLCODE = 0
               ADD 1 TO WS-HIST-IDX
               ADD 1 TO WS-HIST-COUNT
               MOVE WS-HIST-EFF-DATE
                   TO WS-OUT-HIST-EFF(WS-HIST-IDX)
               IF NI-HIST-EXP >= 0
                   MOVE WS-HIST-EXP-DATE
                       TO WS-OUT-HIST-EXP(WS-HIST-IDX)
               ELSE
                   MOVE '(CURRENT) ' TO
                       WS-OUT-HIST-EXP(WS-HIST-IDX)
               END-IF
               MOVE WS-HIST-MSRP
                   TO WS-OUT-HIST-MSRP(WS-HIST-IDX)
               MOVE WS-HIST-INV
                   TO WS-OUT-HIST-INV(WS-HIST-IDX)
           END-IF
           .
       3210-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - ADD NEW PRICE RECORD                                    *
      *---------------------------------------------------------------*
       4000-ADD-PRICE.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               INSERT INTO AUTOSALE.PRICE_MASTER
               ( MODEL_YEAR, MAKE_CODE, MODEL_CODE,
                 MSRP, INVOICE_PRICE,
                 HOLDBACK_AMT, HOLDBACK_PCT,
                 DESTINATION_FEE, ADVERTISING_FEE,
                 EFFECTIVE_DATE, EXPIRY_DATE,
                 CREATED_TS )
               VALUES
               ( :DCLPRICE-MASTER.MODEL-YEAR,
                 :DCLPRICE-MASTER.MAKE-CODE,
                 :DCLPRICE-MASTER.MODEL-CODE,
                 :DCLPRICE-MASTER.MSRP,
                 :DCLPRICE-MASTER.INVOICE-PRICE,
                 :DCLPRICE-MASTER.HOLDBACK-AMT,
                 :DCLPRICE-MASTER.HOLDBACK-PCT,
                 :DCLPRICE-MASTER.DESTINATION-FEE,
                 :DCLPRICE-MASTER.ADVERTISING-FEE,
                 :DCLPRICE-MASTER.EFFECTIVE-DATE,
                 :DCLPRICE-MASTER.EXPIRY-DATE
                     :NI-EXPIRY-DATE,
                 CURRENT TIMESTAMP )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 800 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASPRCI00' TO WS-OUT-MOD-NAME
                   MOVE 'ADD' TO WS-OUT-FUNC-CODE
                   STRING 'PRICE RECORD ADDED FOR: '
                          WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN -803
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE
                   'PRICE RECORD ALREADY EXISTS FOR THIS DATE'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '4000-ADD-PRICE' TO WS-DBE-SECTION
                   MOVE 'PRICE_MASTER' TO WS-DBE-TABLE
                   MOVE 'INSERT' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM
                                         WS-DBE-SECTION
                                         WS-DBE-TABLE
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT
                   MOVE WS-DBE-MSG(1:79) TO WS-ERROR-MSG
           END-EVALUATE
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4100 - POPULATE DCLGEN FROM INPUT AND WORK FIELDS              *
      *---------------------------------------------------------------*
       4100-POPULATE-DCLGEN.
      *
           MOVE WS-MODEL-YEAR-NUM
               TO MODEL-YEAR OF DCLPRICE-MASTER
           MOVE WS-IN-MAKE-CODE TO MAKE-CODE OF DCLPRICE-MASTER
           MOVE WS-IN-MODEL-CODE TO MODEL-CODE OF DCLPRICE-MASTER
           MOVE WS-MSRP-NUM TO MSRP OF DCLPRICE-MASTER
           MOVE WS-INVOICE-NUM
               TO INVOICE-PRICE OF DCLPRICE-MASTER
           MOVE WS-HOLDBACK-AMT-NUM
               TO HOLDBACK-AMT OF DCLPRICE-MASTER
           MOVE WS-HOLDBACK-PCT-NUM
               TO HOLDBACK-PCT OF DCLPRICE-MASTER
           MOVE WS-DEST-FEE-NUM
               TO DESTINATION-FEE OF DCLPRICE-MASTER
           MOVE WS-ADV-FEE-NUM
               TO ADVERTISING-FEE OF DCLPRICE-MASTER
           MOVE WS-IN-EFF-DATE
               TO EFFECTIVE-DATE OF DCLPRICE-MASTER
      *
           IF WS-IN-EXP-DATE = SPACES
               MOVE -1 TO NI-EXPIRY-DATE
           ELSE
               MOVE 0 TO NI-EXPIRY-DATE
               MOVE WS-IN-EXP-DATE
                   TO EXPIRY-DATE OF DCLPRICE-MASTER
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - UPDATE EXISTING PRICE RECORD                            *
      *---------------------------------------------------------------*
       5000-UPDATE-PRICE.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               UPDATE AUTOSALE.PRICE_MASTER
               SET    MSRP = :DCLPRICE-MASTER.MSRP,
                      INVOICE_PRICE =
                          :DCLPRICE-MASTER.INVOICE-PRICE,
                      HOLDBACK_AMT =
                          :DCLPRICE-MASTER.HOLDBACK-AMT,
                      HOLDBACK_PCT =
                          :DCLPRICE-MASTER.HOLDBACK-PCT,
                      DESTINATION_FEE =
                          :DCLPRICE-MASTER.DESTINATION-FEE,
                      ADVERTISING_FEE =
                          :DCLPRICE-MASTER.ADVERTISING-FEE,
                      EXPIRY_DATE =
                          :DCLPRICE-MASTER.EXPIRY-DATE
                          :NI-EXPIRY-DATE
               WHERE  MODEL_YEAR = :WS-MODEL-YEAR-NUM
               AND    MAKE_CODE  = :WS-IN-MAKE-CODE
               AND    MODEL_CODE = :WS-IN-MODEL-CODE
               AND    EFFECTIVE_DATE = :WS-IN-EFF-DATE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 800 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASPRCI00' TO WS-OUT-MOD-NAME
                   MOVE 'UPD' TO WS-OUT-FUNC-CODE
                   STRING 'PRICE RECORD UPDATED FOR: '
                          WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'PRICE RECORD NOT FOUND FOR UPDATE'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '5000-UPDATE' TO WS-DBE-SECTION
                   MOVE 'PRICE_MASTER' TO WS-DBE-TABLE
                   MOVE 'UPDATE' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM
                                         WS-DBE-SECTION
                                         WS-DBE-TABLE
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT
                   MOVE WS-DBE-MSG(1:79) TO WS-ERROR-MSG
           END-EVALUATE
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - SEND ERROR RESPONSE                                     *
      *---------------------------------------------------------------*
       8000-SEND-ERROR.
      *
           MOVE 800 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASPRCI00' TO WS-OUT-MOD-NAME
           MOVE WS-IN-FUNC-CODE TO WS-OUT-FUNC-CODE
           MOVE WS-ERROR-MSG TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       8000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 9000 - LOG AUDIT TRAIL                                         *
      *---------------------------------------------------------------*
       9000-LOG-AUDIT.
      *
           MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
           MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
      *
           EVALUATE TRUE
               WHEN WS-FUNC-ADD
                   MOVE 'INS' TO WS-AUD-ACTION
               WHEN WS-FUNC-UPD
                   MOVE 'UPD' TO WS-AUD-ACTION
               WHEN OTHER
                   MOVE 'INQ' TO WS-AUD-ACTION
           END-EVALUATE
      *
           MOVE 'PRICE_MASTER' TO WS-AUD-TABLE
           STRING WS-IN-MODEL-YEAR ' '
                  WS-IN-MAKE-CODE ' '
                  WS-IN-MODEL-CODE ' '
                  WS-IN-EFF-DATE
               DELIMITED BY SIZE
               INTO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           STRING 'MSRP=' WS-IN-MSRP ' INV=' WS-IN-INVOICE
               DELIMITED BY SIZE
               INTO WS-AUD-NEW-VAL
      *
           CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                  WS-AUD-PROGRAM-ID
                                  WS-AUD-ACTION
                                  WS-AUD-TABLE
                                  WS-AUD-KEY
                                  WS-AUD-OLD-VAL
                                  WS-AUD-NEW-VAL
                                  WS-AUD-RC
                                  WS-AUD-MSG
           .
       9000-EXIT.
           EXIT.
      ****************************************************************
      * END OF ADMPRC00                                              *
      ****************************************************************
