       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMCFG00.
      ****************************************************************
      * PROGRAM:    ADMCFG00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMC                                             *
      * MFS MID:    MFSADCFG (SYSTEM CONFIG SCREEN)                  *
      * MFS MOD:    ASCFGI00 (CONFIG INQUIRY RESPONSE)               *
      *                                                              *
      * PURPOSE:    SYSTEM CONFIGURATION MAINTENANCE. PROVIDES       *
      *             INQUIRY, UPDATE, AND LIST OPERATIONS ON THE      *
      *             SYSTEM_CONFIG TABLE. DISPLAYS KEY-VALUE PAIRS    *
      *             WITH DESCRIPTIONS. VALIDATES CONSTRAINTS ON      *
      *             SPECIFIC KEYS (NUMERIC SEQUENCES, ETC.).         *
      *                                                              *
      * FUNCTIONS:  INQ - INQUIRY BY CONFIG KEY                      *
      *             UPD - UPDATE CONFIG VALUE                        *
      *             LST - LIST ALL CONFIG ENTRIES                    *
      *                                                              *
      * CALLS:      COMLGEL0 - AUDIT LOGGING                        *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMCFG00'.
      *
      *    IMS FUNCTION CODES
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR SYSTEM_CONFIG TABLE
      *
           COPY DCLSYSCF.
      *
      *    INPUT MESSAGE LAYOUT
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL             PIC S9(04) COMP.
           05  WS-IN-ZZ             PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE      PIC X(08).
           05  WS-IN-FUNC-CODE      PIC X(03).
               88  WS-FUNC-INQ                VALUE 'INQ'.
               88  WS-FUNC-UPD                VALUE 'UPD'.
               88  WS-FUNC-LST                VALUE 'LST'.
           05  WS-IN-CONFIG-KEY     PIC X(30).
           05  WS-IN-CONFIG-VALUE   PIC X(100).
           05  WS-IN-CONFIG-DESC    PIC X(60).
           05  WS-IN-USER-ID        PIC X(08).
           05  FILLER               PIC X(50).
      *
      *    OUTPUT MESSAGE LAYOUT (SINGLE ENTRY)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL            PIC S9(04) COMP.
           05  WS-OUT-ZZ            PIC S9(04) COMP.
           05  WS-OUT-MOD-NAME      PIC X(08).
           05  WS-OUT-FUNC-CODE     PIC X(03).
           05  WS-OUT-CONFIG-KEY    PIC X(30).
           05  WS-OUT-CONFIG-VALUE  PIC X(100).
           05  WS-OUT-CONFIG-DESC   PIC X(60).
           05  WS-OUT-UPDATED-BY    PIC X(08).
           05  WS-OUT-UPDATED-TS    PIC X(26).
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  FILLER               PIC X(30).
      *
      *    LIST OUTPUT - UP TO 20 CONFIG ENTRIES
      *
       01  WS-LIST-OUTPUT.
           05  WS-LST-LL            PIC S9(04) COMP.
           05  WS-LST-ZZ            PIC S9(04) COMP.
           05  WS-LST-MOD-NAME      PIC X(08).
           05  WS-LST-COUNT         PIC 9(03).
           05  WS-LST-MSG           PIC X(79).
           05  WS-LST-ENTRY OCCURS 20 TIMES.
               10  WS-LST-CFG-KEY  PIC X(30).
               10  WS-LST-CFG-VAL  PIC X(50).
               10  WS-LST-CFG-DESC PIC X(40).
               10  WS-LST-CFG-UPD  PIC X(08).
           05  FILLER               PIC X(50).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-LIST-IDX         PIC 9(03) VALUE 0.
           05  WS-ROWS-FETCHED     PIC 9(03) VALUE 0.
           05  WS-KEY-TRIMMED      PIC X(30) VALUE SPACES.
           05  WS-VAL-TRIMMED      PIC X(100) VALUE SPACES.
           05  WS-OLD-VALUE        PIC X(100) VALUE SPACES.
      *
      *    CONFIG KEYS THAT REQUIRE NUMERIC VALUES
      *
       01  WS-NUMERIC-KEYS.
           05  WS-NUMK-TABLE.
               10  FILLER          PIC X(30)
                   VALUE 'NEXT_STOCK_NUMBER             '.
               10  FILLER          PIC X(30)
                   VALUE 'NEXT_DEAL_NUMBER              '.
               10  FILLER          PIC X(30)
                   VALUE 'NEXT_CUSTOMER_NUMBER          '.
               10  FILLER          PIC X(30)
                   VALUE 'MAX_DAYS_ON_LOT               '.
               10  FILLER          PIC X(30)
                   VALUE 'FLOOR_PLAN_GRACE_DAYS         '.
               10  FILLER          PIC X(30)
                   VALUE 'AGING_REPORT_THRESHOLD        '.
           05  WS-NUMK-TBL-R REDEFINES WS-NUMK-TABLE.
               10  WS-NUMK-ENTRY  PIC X(30) OCCURS 6 TIMES.
           05  WS-NUMK-IDX        PIC 9(02) VALUE 0.
           05  WS-IS-NUMERIC-KEY   PIC X(01) VALUE 'N'.
               88  WS-KEY-IS-NUMERIC           VALUE 'Y'.
               88  WS-KEY-NOT-NUMERIC          VALUE 'N'.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-CONFIG-DESC       PIC S9(04) COMP VALUE 0.
           05  NI-UPDATED-BY        PIC S9(04) COMP VALUE 0.
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
      *    CONFIG LIST CURSOR WORK FIELDS
      *
       01  WS-CSR-KEY-TX           PIC X(30).
       01  WS-CSR-VAL-TX           PIC X(100).
       01  WS-CSR-DESC-TX          PIC X(60).
       01  WS-CSR-UPD-BY           PIC X(08).
       01  NI-CSR-DESC             PIC S9(04) COMP VALUE 0.
       01  NI-CSR-UPD-BY           PIC S9(04) COMP VALUE 0.
      *
      *    CURSOR FOR CONFIG LIST
      *
           EXEC SQL
               DECLARE CONFIG_LIST_CSR CURSOR FOR
               SELECT CONFIG_KEY,
                      CONFIG_VALUE,
                      CONFIG_DESC,
                      UPDATED_BY
               FROM   AUTOSALE.SYSTEM_CONFIG
               ORDER BY CONFIG_KEY
               FETCH FIRST 20 ROWS ONLY
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
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-CONFIG
                   END-IF
               WHEN WS-FUNC-LST
                   PERFORM 6000-LIST-CONFIG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INVALID FUNCTION: '
                          WS-IN-FUNC-CODE
                          '. USE INQ/UPD/LST'
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
      * 1000 - RECEIVE INPUT MESSAGE                                   *
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
      * 2000 - VALIDATE CONFIG INPUT FIELDS                            *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
      *    CONFIG KEY REQUIRED
      *
           IF WS-IN-CONFIG-KEY = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'CONFIG KEY IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    CONFIG VALUE REQUIRED
      *
           IF WS-IN-CONFIG-VALUE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'CONFIG VALUE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    CHECK IF THIS KEY REQUIRES A NUMERIC VALUE
      *
           MOVE 'N' TO WS-IS-NUMERIC-KEY
           PERFORM VARYING WS-NUMK-IDX FROM 1 BY 1
               UNTIL WS-NUMK-IDX > 6 OR WS-KEY-IS-NUMERIC
               IF WS-IN-CONFIG-KEY = WS-NUMK-ENTRY(WS-NUMK-IDX)
                   MOVE 'Y' TO WS-IS-NUMERIC-KEY
               END-IF
           END-PERFORM
      *
           IF WS-KEY-IS-NUMERIC
               MOVE FUNCTION TRIM(WS-IN-CONFIG-VALUE)
                   TO WS-VAL-TRIMMED
               IF WS-VAL-TRIMMED NOT NUMERIC
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'VALUE FOR '
                          WS-IN-CONFIG-KEY
                          ' MUST BE NUMERIC'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               END-IF
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INQUIRY BY CONFIG KEY                                   *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-CONFIG-KEY = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'CONFIG KEY IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           MOVE FUNCTION TRIM(WS-IN-CONFIG-KEY)
               TO WS-KEY-TRIMMED
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-CONFIG-KEY TRAILING))
               TO CONFIG-KEY-LN OF DCLSYSTEM-CONFIG
           MOVE WS-IN-CONFIG-KEY
               TO CONFIG-KEY-TX OF DCLSYSTEM-CONFIG
      *
           EXEC SQL
               SELECT CONFIG_KEY,
                      CONFIG_VALUE,
                      CONFIG_DESC,
                      UPDATED_BY,
                      UPDATED_TS
               INTO   :DCLSYSTEM-CONFIG.CONFIG-KEY,
                      :DCLSYSTEM-CONFIG.CONFIG-VALUE,
                      :DCLSYSTEM-CONFIG.CONFIG-DESC
                          :NI-CONFIG-DESC,
                      :DCLSYSTEM-CONFIG.UPDATED-BY
                          :NI-UPDATED-BY,
                      :DCLSYSTEM-CONFIG.UPDATED-TS
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_KEY = :DCLSYSTEM-CONFIG.CONFIG-KEY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 3100-FORMAT-INQUIRY-OUTPUT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'CONFIG KEY NOT FOUND: '
                          WS-IN-CONFIG-KEY
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-INQUIRY' TO WS-DBE-SECTION
                   MOVE 'SYSTEM_CONFIG' TO WS-DBE-TABLE
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
      * 3100 - FORMAT INQUIRY OUTPUT                                    *
      *---------------------------------------------------------------*
       3100-FORMAT-INQUIRY-OUTPUT.
      *
           MOVE 450 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASCFGI00' TO WS-OUT-MOD-NAME
           MOVE 'INQ' TO WS-OUT-FUNC-CODE
           MOVE CONFIG-KEY-TX OF DCLSYSTEM-CONFIG
               TO WS-OUT-CONFIG-KEY
           MOVE CONFIG-VALUE-TX OF DCLSYSTEM-CONFIG
               TO WS-OUT-CONFIG-VALUE
      *
           IF NI-CONFIG-DESC >= 0
               MOVE CONFIG-DESC-TX OF DCLSYSTEM-CONFIG
                   TO WS-OUT-CONFIG-DESC
           ELSE
               MOVE SPACES TO WS-OUT-CONFIG-DESC
           END-IF
      *
           IF NI-UPDATED-BY >= 0
               MOVE UPDATED-BY OF DCLSYSTEM-CONFIG
                   TO WS-OUT-UPDATED-BY
           ELSE
               MOVE 'SYSTEM' TO WS-OUT-UPDATED-BY
           END-IF
      *
           MOVE UPDATED-TS OF DCLSYSTEM-CONFIG
               TO WS-OUT-UPDATED-TS
      *
           MOVE 'CONFIG ENTRY DISPLAYED SUCCESSFULLY'
               TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       3100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - UPDATE CONFIG ENTRY                                     *
      *---------------------------------------------------------------*
       5000-UPDATE-CONFIG.
      *
      *    FIRST RETRIEVE OLD VALUE FOR AUDIT
      *
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-CONFIG-KEY TRAILING))
               TO CONFIG-KEY-LN OF DCLSYSTEM-CONFIG
           MOVE WS-IN-CONFIG-KEY
               TO CONFIG-KEY-TX OF DCLSYSTEM-CONFIG
      *
           EXEC SQL
               SELECT CONFIG_VALUE
               INTO   :WS-OLD-VALUE
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_KEY = :DCLSYSTEM-CONFIG.CONFIG-KEY
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'CONFIG KEY NOT FOUND: '
                      WS-IN-CONFIG-KEY
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
      *    PREPARE VALUE AND DESCRIPTION FOR UPDATE
      *
           MOVE WS-IN-CONFIG-VALUE
               TO CONFIG-VALUE-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-CONFIG-VALUE TRAILING))
               TO CONFIG-VALUE-LN OF DCLSYSTEM-CONFIG
      *
           IF WS-IN-CONFIG-DESC NOT = SPACES
               MOVE 0 TO NI-CONFIG-DESC
               MOVE WS-IN-CONFIG-DESC
                   TO CONFIG-DESC-TX OF DCLSYSTEM-CONFIG
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(WS-IN-CONFIG-DESC TRAILING))
                   TO CONFIG-DESC-LN OF DCLSYSTEM-CONFIG
           ELSE
               MOVE -1 TO NI-CONFIG-DESC
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.SYSTEM_CONFIG
               SET    CONFIG_VALUE =
                          :DCLSYSTEM-CONFIG.CONFIG-VALUE,
                      CONFIG_DESC =
                          :DCLSYSTEM-CONFIG.CONFIG-DESC
                          :NI-CONFIG-DESC,
                      UPDATED_BY = :WS-IN-USER-ID,
                      UPDATED_TS = CURRENT TIMESTAMP
               WHERE  CONFIG_KEY = :DCLSYSTEM-CONFIG.CONFIG-KEY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 450 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASCFGI00' TO WS-OUT-MOD-NAME
                   MOVE 'UPD' TO WS-OUT-FUNC-CODE
                   MOVE WS-IN-CONFIG-KEY TO WS-OUT-CONFIG-KEY
                   MOVE WS-IN-CONFIG-VALUE TO WS-OUT-CONFIG-VALUE
                   STRING 'CONFIG KEY ' WS-IN-CONFIG-KEY
                          ' UPDATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
      *
      *            AUDIT WITH OLD AND NEW VALUES
      *
                   MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
                   MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
                   MOVE 'UPD' TO WS-AUD-ACTION
                   MOVE 'SYSTEM_CONFIG' TO WS-AUD-TABLE
                   MOVE WS-IN-CONFIG-KEY TO WS-AUD-KEY
                   MOVE WS-OLD-VALUE TO WS-AUD-OLD-VAL
                   MOVE WS-IN-CONFIG-VALUE TO WS-AUD-NEW-VAL
                   CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                          WS-AUD-PROGRAM-ID
                                          WS-AUD-ACTION
                                          WS-AUD-TABLE
                                          WS-AUD-KEY
                                          WS-AUD-OLD-VAL
                                          WS-AUD-NEW-VAL
                                          WS-AUD-RC
                                          WS-AUD-MSG
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'CONFIG KEY NOT FOUND: '
                          WS-IN-CONFIG-KEY
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '5000-UPDATE' TO WS-DBE-SECTION
                   MOVE 'SYSTEM_CONFIG' TO WS-DBE-TABLE
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
      * 6000 - LIST ALL CONFIG ENTRIES                                  *
      *---------------------------------------------------------------*
       6000-LIST-CONFIG.
      *
           INITIALIZE WS-LIST-OUTPUT
           MOVE 0 TO WS-LIST-IDX
           MOVE 0 TO WS-ROWS-FETCHED
      *
           EXEC SQL
               OPEN CONFIG_LIST_CSR
           END-EXEC
      *
           IF SQLCODE NOT = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ERROR OPENING CONFIG LIST CURSOR'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           PERFORM 6100-FETCH-CONFIG
               UNTIL SQLCODE NOT = 0
               OR WS-LIST-IDX >= 20
      *
           EXEC SQL
               CLOSE CONFIG_LIST_CSR
           END-EXEC
      *
           IF WS-ROWS-FETCHED = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'NO CONFIGURATION ENTRIES FOUND'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
      *    FORMAT AND SEND LIST OUTPUT
      *
           MOVE 2700 TO WS-LST-LL
           MOVE 0 TO WS-LST-ZZ
           MOVE 'ASCFGI00' TO WS-LST-MOD-NAME
           MOVE WS-ROWS-FETCHED TO WS-LST-COUNT
           STRING 'DISPLAYING ' WS-ROWS-FETCHED
                  ' CONFIGURATION ENTRIES'
               DELIMITED BY SIZE
               INTO WS-LST-MSG
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-LIST-OUTPUT
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6100 - FETCH NEXT CONFIG ROW FROM CURSOR                       *
      *---------------------------------------------------------------*
       6100-FETCH-CONFIG.
      *
           EXEC SQL
               FETCH CONFIG_LIST_CSR
               INTO  :WS-CSR-KEY-TX,
                     :WS-CSR-VAL-TX,
                     :WS-CSR-DESC-TX :NI-CSR-DESC,
                     :WS-CSR-UPD-BY  :NI-CSR-UPD-BY
           END-EXEC
      *
           IF SQLCODE = 0
               ADD 1 TO WS-LIST-IDX
               ADD 1 TO WS-ROWS-FETCHED
               MOVE WS-CSR-KEY-TX
                   TO WS-LST-CFG-KEY(WS-LIST-IDX)
               MOVE WS-CSR-VAL-TX(1:50)
                   TO WS-LST-CFG-VAL(WS-LIST-IDX)
               IF NI-CSR-DESC >= 0
                   MOVE WS-CSR-DESC-TX(1:40)
                       TO WS-LST-CFG-DESC(WS-LIST-IDX)
               ELSE
                   MOVE SPACES
                       TO WS-LST-CFG-DESC(WS-LIST-IDX)
               END-IF
               IF NI-CSR-UPD-BY >= 0
                   MOVE WS-CSR-UPD-BY
                       TO WS-LST-CFG-UPD(WS-LIST-IDX)
               ELSE
                   MOVE 'SYSTEM'
                       TO WS-LST-CFG-UPD(WS-LIST-IDX)
               END-IF
           END-IF
           .
       6100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - SEND ERROR RESPONSE                                     *
      *---------------------------------------------------------------*
       8000-SEND-ERROR.
      *
           MOVE 450 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASCFGI00' TO WS-OUT-MOD-NAME
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
      ****************************************************************
      * END OF ADMCFG00                                              *
      ****************************************************************
