       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMPRD00.
      ****************************************************************
      * PROGRAM:    ADMPRD00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMF                                             *
      * MFS MID:    MFSADPRD (F&I PRODUCT CATALOG SCREEN)            *
      * MFS MOD:    ASPRDI00 (F&I PRODUCT INQUIRY RESPONSE)          *
      *                                                              *
      * PURPOSE:    F&I PRODUCT CATALOG MAINTENANCE. MAINTAINS THE   *
      *             CATALOG OF F&I PRODUCTS AVAILABLE FOR SALE        *
      *             (WARRANTY, GAP INSURANCE, SERVICE CONTRACTS,      *
      *             PAINT PROTECTION, ETC.). STORES IN SYSTEM_CONFIG  *
      *             WITH KEY PREFIX 'FI_PRODUCT_'.                    *
      *                                                              *
      * FUNCTIONS:  INQ - INQUIRY BY PRODUCT TYPE CODE               *
      *             ADD - ADD NEW F&I PRODUCT                        *
      *             UPD - UPDATE EXISTING PRODUCT                    *
      *             LST - LIST ALL F&I PRODUCTS                      *
      *                                                              *
      * DATA FORMAT (STORED IN SYSTEM_CONFIG.CONFIG_VALUE):           *
      *   PRODUCT-NAME(30)|TERM(3)|RETAIL-PRICE(10)|COST(10)         *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMPRD00'.
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
      *    KEY PREFIX FOR F&I PRODUCTS
      *
       01  WS-FI-PREFIX            PIC X(11)
                                    VALUE 'FI_PRODUCT_'.
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
               88  WS-FUNC-LST                VALUE 'LST'.
           05  WS-IN-PROD-TYPE      PIC X(04).
           05  WS-IN-PROD-NAME      PIC X(30).
           05  WS-IN-DEFAULT-TERM   PIC X(03).
           05  WS-IN-RETAIL-PRICE   PIC X(10).
           05  WS-IN-COST           PIC X(10).
           05  WS-IN-USER-ID        PIC X(08).
           05  FILLER               PIC X(100).
      *
      *    OUTPUT MESSAGE LAYOUT (SINGLE PRODUCT)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL            PIC S9(04) COMP.
           05  WS-OUT-ZZ            PIC S9(04) COMP.
           05  WS-OUT-MOD-NAME      PIC X(08).
           05  WS-OUT-FUNC-CODE     PIC X(03).
           05  WS-OUT-PROD-TYPE     PIC X(04).
           05  WS-OUT-PROD-NAME     PIC X(30).
           05  WS-OUT-DEFAULT-TERM  PIC Z(2)9.
           05  WS-OUT-RETAIL-PRICE  PIC $$$,$$$,$$9.99.
           05  WS-OUT-COST          PIC $$$,$$$,$$9.99.
           05  WS-OUT-MARGIN        PIC $$$,$$$,$$9.99.
           05  WS-OUT-MARGIN-PCT    PIC Z9.99.
           05  WS-OUT-CONFIG-KEY    PIC X(30).
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  FILLER               PIC X(50).
      *
      *    LIST OUTPUT - UP TO 15 F&I PRODUCTS
      *
       01  WS-LIST-OUTPUT.
           05  WS-LST-LL            PIC S9(04) COMP.
           05  WS-LST-ZZ            PIC S9(04) COMP.
           05  WS-LST-MOD-NAME      PIC X(08).
           05  WS-LST-COUNT         PIC 9(03).
           05  WS-LST-MSG           PIC X(79).
           05  WS-LST-ENTRY OCCURS 15 TIMES.
               10  WS-LST-PRD-TYPE PIC X(04).
               10  WS-LST-PRD-NAME PIC X(30).
               10  WS-LST-PRD-TERM PIC X(03).
               10  WS-LST-PRD-RPRC PIC $$$,$$$,$$9.99.
               10  WS-LST-PRD-COST PIC $$$,$$$,$$9.99.
           05  FILLER               PIC X(50).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-CONFIG-KEY-WORK  PIC X(30) VALUE SPACES.
           05  WS-CONFIG-VAL-WORK  PIC X(100) VALUE SPACES.
           05  WS-TERM-NUM         PIC 9(03) VALUE 0.
           05  WS-RETAIL-NUM       PIC S9(07)V9(02) COMP-3 VALUE 0.
           05  WS-COST-NUM         PIC S9(07)V9(02) COMP-3 VALUE 0.
           05  WS-MARGIN-NUM       PIC S9(07)V9(02) COMP-3 VALUE 0.
           05  WS-MARGIN-PCT       PIC S9(03)V9(02) COMP-3 VALUE 0.
           05  WS-LIST-IDX         PIC 9(03) VALUE 0.
           05  WS-ROWS-FETCHED     PIC 9(03) VALUE 0.
           05  WS-OLD-VALUE        PIC X(100) VALUE SPACES.
      *
      *    PARSED PRODUCT DATA FROM CONFIG VALUE
      *
       01  WS-PARSED-PRODUCT.
           05  WS-PP-NAME          PIC X(30).
           05  WS-PP-TERM          PIC X(03).
           05  WS-PP-RETAIL        PIC X(10).
           05  WS-PP-COST          PIC X(10).
      *
      *    VALID F&I PRODUCT TYPES
      *
       01  WS-PROD-TYPE-TABLE.
           05  FILLER              PIC X(04) VALUE 'EWTY'.
           05  FILLER              PIC X(04) VALUE 'GAPI'.
           05  FILLER              PIC X(04) VALUE 'SVCC'.
           05  FILLER              PIC X(04) VALUE 'PPRT'.
           05  FILLER              PIC X(04) VALUE 'FPRT'.
           05  FILLER              PIC X(04) VALUE 'TRST'.
           05  FILLER              PIC X(04) VALUE 'DNTC'.
           05  FILLER              PIC X(04) VALUE 'KEYR'.
           05  FILLER              PIC X(04) VALUE 'WIND'.
           05  FILLER              PIC X(04) VALUE 'THFT'.
       01  WS-PROD-TBL-R REDEFINES WS-PROD-TYPE-TABLE.
           05  WS-PROD-ENTRY       PIC X(04) OCCURS 10 TIMES.
       01  WS-PROD-IDX             PIC 9(02) VALUE 0.
       01  WS-PROD-VALID           PIC X(01) VALUE 'N'.
           88  WS-PROD-IS-VALID               VALUE 'Y'.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-CONFIG-DESC       PIC S9(04) COMP VALUE 0.
           05  NI-UPDATED-BY        PIC S9(04) COMP VALUE 0.
      *
      *    CURSOR WORK FIELDS
      *
       01  WS-CSR-KEY-TX           PIC X(30).
       01  WS-CSR-VAL-TX           PIC X(100).
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
      *    LIKE PATTERN FOR F&I PRODUCT KEYS
      *
       01  WS-LIKE-PATTERN         PIC X(30)
                                    VALUE 'FI_PRODUCT_%'.
      *
      *    CURSOR FOR F&I PRODUCT LIST
      *
           EXEC SQL
               DECLARE FI_PROD_LIST_CSR CURSOR FOR
               SELECT CONFIG_KEY,
                      CONFIG_VALUE
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_KEY LIKE :WS-LIKE-PATTERN
               ORDER BY CONFIG_KEY
               FETCH FIRST 15 ROWS ONLY
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
                       PERFORM 4000-ADD-PRODUCT
                   END-IF
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-PRODUCT
                   END-IF
               WHEN WS-FUNC-LST
                   PERFORM 6000-LIST-PRODUCTS
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INVALID FUNCTION: '
                          WS-IN-FUNC-CODE
                          '. USE INQ/ADD/UPD/LST'
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
      * 2000 - VALIDATE F&I PRODUCT INPUT                              *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
      *    PRODUCT TYPE CODE REQUIRED
      *
           IF WS-IN-PROD-TYPE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'PRODUCT TYPE CODE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE PRODUCT TYPE
      *
           MOVE 'N' TO WS-PROD-VALID
           PERFORM VARYING WS-PROD-IDX FROM 1 BY 1
               UNTIL WS-PROD-IDX > 10 OR WS-PROD-IS-VALID
               IF WS-IN-PROD-TYPE = WS-PROD-ENTRY(WS-PROD-IDX)
                   MOVE 'Y' TO WS-PROD-VALID
               END-IF
           END-PERFORM
      *
           IF NOT WS-PROD-IS-VALID
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'INVALID PRODUCT TYPE: '
                      WS-IN-PROD-TYPE
                      '. USE EWTY/GAPI/SVCC/PPRT/FPRT/TRST/...'
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    PRODUCT NAME REQUIRED
      *
           IF WS-IN-PROD-NAME = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'PRODUCT NAME IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    DEFAULT TERM - MUST BE NUMERIC IF PROVIDED
      *
           IF WS-IN-DEFAULT-TERM NOT = SPACES
               IF WS-IN-DEFAULT-TERM NOT NUMERIC
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE
                   'DEFAULT TERM MUST BE NUMERIC (MONTHS)'
                       TO WS-ERROR-MSG
                   GO TO 2000-EXIT
               END-IF
           END-IF
      *
      *    RETAIL PRICE REQUIRED AND > 0
      *
           IF WS-IN-RETAIL-PRICE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'RETAIL PRICE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           COMPUTE WS-RETAIL-NUM =
               FUNCTION NUMVAL(WS-IN-RETAIL-PRICE)
           IF WS-RETAIL-NUM <= 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'RETAIL PRICE MUST BE GREATER THAN ZERO'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    COST REQUIRED AND > 0
      *
           IF WS-IN-COST = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'COST IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           COMPUTE WS-COST-NUM =
               FUNCTION NUMVAL(WS-IN-COST)
           IF WS-COST-NUM <= 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'COST MUST BE GREATER THAN ZERO'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    RETAIL SHOULD BE >= COST
      *
           IF WS-RETAIL-NUM < WS-COST-NUM
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE
               'RETAIL PRICE SHOULD BE GREATER THAN OR EQUAL TO COST'
                   TO WS-ERROR-MSG
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2500 - BUILD CONFIG KEY FROM PRODUCT TYPE                      *
      *---------------------------------------------------------------*
       2500-BUILD-CONFIG-KEY.
      *
           MOVE SPACES TO WS-CONFIG-KEY-WORK
           STRING WS-FI-PREFIX
                  WS-IN-PROD-TYPE
               DELIMITED BY SIZE
               INTO WS-CONFIG-KEY-WORK
           .
       2500-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2600 - BUILD CONFIG VALUE FROM PRODUCT FIELDS                  *
      *        FORMAT: NAME(30)|TERM(3)|RETAIL(10)|COST(10)            *
      *---------------------------------------------------------------*
       2600-BUILD-CONFIG-VALUE.
      *
           MOVE SPACES TO WS-CONFIG-VAL-WORK
           STRING WS-IN-PROD-NAME
                  '|'
                  WS-IN-DEFAULT-TERM
                  '|'
                  WS-IN-RETAIL-PRICE
                  '|'
                  WS-IN-COST
               DELIMITED BY SIZE
               INTO WS-CONFIG-VAL-WORK
           .
       2600-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2700 - PARSE CONFIG VALUE INTO PRODUCT FIELDS                  *
      *---------------------------------------------------------------*
       2700-PARSE-CONFIG-VALUE.
      *
           INITIALIZE WS-PARSED-PRODUCT
      *
           UNSTRING WS-CONFIG-VAL-WORK
               DELIMITED BY '|'
               INTO WS-PP-NAME
                    WS-PP-TERM
                    WS-PP-RETAIL
                    WS-PP-COST
           .
       2700-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INQUIRY BY PRODUCT TYPE CODE                            *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-PROD-TYPE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'PRODUCT TYPE CODE IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           PERFORM 2500-BUILD-CONFIG-KEY
      *
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-CONFIG-KEY-WORK TRAILING))
               TO CONFIG-KEY-LN OF DCLSYSTEM-CONFIG
           MOVE WS-CONFIG-KEY-WORK
               TO CONFIG-KEY-TX OF DCLSYSTEM-CONFIG
      *
           EXEC SQL
               SELECT CONFIG_KEY,
                      CONFIG_VALUE,
                      CONFIG_DESC
               INTO   :DCLSYSTEM-CONFIG.CONFIG-KEY,
                      :DCLSYSTEM-CONFIG.CONFIG-VALUE,
                      :DCLSYSTEM-CONFIG.CONFIG-DESC
                          :NI-CONFIG-DESC
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_KEY = :DCLSYSTEM-CONFIG.CONFIG-KEY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE CONFIG-VALUE-TX OF DCLSYSTEM-CONFIG
                       TO WS-CONFIG-VAL-WORK
                   PERFORM 2700-PARSE-CONFIG-VALUE
                   PERFORM 3100-FORMAT-INQUIRY-OUTPUT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'F&I PRODUCT NOT FOUND: '
                          WS-IN-PROD-TYPE
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
      * 3100 - FORMAT INQUIRY OUTPUT WITH MARGIN CALCULATION           *
      *---------------------------------------------------------------*
       3100-FORMAT-INQUIRY-OUTPUT.
      *
           MOVE 500 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASPRDI00' TO WS-OUT-MOD-NAME
           MOVE 'INQ' TO WS-OUT-FUNC-CODE
           MOVE WS-IN-PROD-TYPE TO WS-OUT-PROD-TYPE
           MOVE WS-PP-NAME TO WS-OUT-PROD-NAME
      *
      *    TERM
      *
           IF WS-PP-TERM NUMERIC
               MOVE WS-PP-TERM TO WS-TERM-NUM
               MOVE WS-TERM-NUM TO WS-OUT-DEFAULT-TERM
           ELSE
               MOVE 0 TO WS-OUT-DEFAULT-TERM
           END-IF
      *
      *    RETAIL AND COST
      *
           COMPUTE WS-RETAIL-NUM =
               FUNCTION NUMVAL(WS-PP-RETAIL)
           COMPUTE WS-COST-NUM =
               FUNCTION NUMVAL(WS-PP-COST)
      *
           MOVE WS-RETAIL-NUM TO WS-OUT-RETAIL-PRICE
           MOVE WS-COST-NUM TO WS-OUT-COST
      *
      *    MARGIN
      *
           COMPUTE WS-MARGIN-NUM = WS-RETAIL-NUM - WS-COST-NUM
           MOVE WS-MARGIN-NUM TO WS-OUT-MARGIN
      *
           IF WS-RETAIL-NUM > 0
               COMPUTE WS-MARGIN-PCT =
                   (WS-MARGIN-NUM / WS-RETAIL-NUM) * 100
               MOVE WS-MARGIN-PCT TO WS-OUT-MARGIN-PCT
           ELSE
               MOVE 0 TO WS-OUT-MARGIN-PCT
           END-IF
      *
           MOVE WS-CONFIG-KEY-WORK TO WS-OUT-CONFIG-KEY
           MOVE 'F&I PRODUCT DISPLAYED SUCCESSFULLY'
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
      * 4000 - ADD NEW F&I PRODUCT                                     *
      *---------------------------------------------------------------*
       4000-ADD-PRODUCT.
      *
           PERFORM 2500-BUILD-CONFIG-KEY
           PERFORM 2600-BUILD-CONFIG-VALUE
      *
      *    SET UP DCLGEN FIELDS
      *
           MOVE WS-CONFIG-KEY-WORK
               TO CONFIG-KEY-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-CONFIG-KEY-WORK TRAILING))
               TO CONFIG-KEY-LN OF DCLSYSTEM-CONFIG
      *
           MOVE WS-CONFIG-VAL-WORK
               TO CONFIG-VALUE-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-CONFIG-VAL-WORK TRAILING))
               TO CONFIG-VALUE-LN OF DCLSYSTEM-CONFIG
      *
      *    DESCRIPTION = PRODUCT NAME
      *
           MOVE 0 TO NI-CONFIG-DESC
           MOVE WS-IN-PROD-NAME
               TO CONFIG-DESC-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-PROD-NAME TRAILING))
               TO CONFIG-DESC-LN OF DCLSYSTEM-CONFIG
      *
           EXEC SQL
               INSERT INTO AUTOSALE.SYSTEM_CONFIG
               ( CONFIG_KEY, CONFIG_VALUE,
                 CONFIG_DESC, UPDATED_BY, UPDATED_TS )
               VALUES
               ( :DCLSYSTEM-CONFIG.CONFIG-KEY,
                 :DCLSYSTEM-CONFIG.CONFIG-VALUE,
                 :DCLSYSTEM-CONFIG.CONFIG-DESC,
                 :WS-IN-USER-ID,
                 CURRENT TIMESTAMP )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 500 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASPRDI00' TO WS-OUT-MOD-NAME
                   MOVE 'ADD' TO WS-OUT-FUNC-CODE
                   MOVE WS-IN-PROD-TYPE TO WS-OUT-PROD-TYPE
                   MOVE WS-IN-PROD-NAME TO WS-OUT-PROD-NAME
                   STRING 'F&I PRODUCT ' WS-IN-PROD-TYPE
                          ' (' WS-IN-PROD-NAME
                          ') ADDED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN -803
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'F&I PRODUCT ' WS-IN-PROD-TYPE
                          ' ALREADY EXISTS'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '4000-ADD' TO WS-DBE-SECTION
                   MOVE 'SYSTEM_CONFIG' TO WS-DBE-TABLE
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
      * 5000 - UPDATE EXISTING F&I PRODUCT                             *
      *---------------------------------------------------------------*
       5000-UPDATE-PRODUCT.
      *
           PERFORM 2500-BUILD-CONFIG-KEY
      *
      *    FIRST RETRIEVE OLD VALUE FOR AUDIT
      *
           MOVE WS-CONFIG-KEY-WORK
               TO CONFIG-KEY-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-CONFIG-KEY-WORK TRAILING))
               TO CONFIG-KEY-LN OF DCLSYSTEM-CONFIG
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
               STRING 'F&I PRODUCT NOT FOUND: '
                      WS-IN-PROD-TYPE
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
      *    BUILD NEW VALUE
      *
           PERFORM 2600-BUILD-CONFIG-VALUE
      *
           MOVE WS-CONFIG-VAL-WORK
               TO CONFIG-VALUE-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-CONFIG-VAL-WORK TRAILING))
               TO CONFIG-VALUE-LN OF DCLSYSTEM-CONFIG
      *
           MOVE 0 TO NI-CONFIG-DESC
           MOVE WS-IN-PROD-NAME
               TO CONFIG-DESC-TX OF DCLSYSTEM-CONFIG
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-PROD-NAME TRAILING))
               TO CONFIG-DESC-LN OF DCLSYSTEM-CONFIG
      *
           EXEC SQL
               UPDATE AUTOSALE.SYSTEM_CONFIG
               SET    CONFIG_VALUE =
                          :DCLSYSTEM-CONFIG.CONFIG-VALUE,
                      CONFIG_DESC =
                          :DCLSYSTEM-CONFIG.CONFIG-DESC,
                      UPDATED_BY = :WS-IN-USER-ID,
                      UPDATED_TS = CURRENT TIMESTAMP
               WHERE  CONFIG_KEY = :DCLSYSTEM-CONFIG.CONFIG-KEY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 500 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASPRDI00' TO WS-OUT-MOD-NAME
                   MOVE 'UPD' TO WS-OUT-FUNC-CODE
                   MOVE WS-IN-PROD-TYPE TO WS-OUT-PROD-TYPE
                   MOVE WS-IN-PROD-NAME TO WS-OUT-PROD-NAME
                   STRING 'F&I PRODUCT ' WS-IN-PROD-TYPE
                          ' UPDATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
      *
      *            AUDIT WITH OLD AND NEW
      *
                   MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
                   MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
                   MOVE 'UPD' TO WS-AUD-ACTION
                   MOVE 'SYSTEM_CONFIG' TO WS-AUD-TABLE
                   MOVE WS-CONFIG-KEY-WORK TO WS-AUD-KEY
                   MOVE WS-OLD-VALUE TO WS-AUD-OLD-VAL
                   MOVE WS-CONFIG-VAL-WORK TO WS-AUD-NEW-VAL
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
                   STRING 'F&I PRODUCT NOT FOUND: '
                          WS-IN-PROD-TYPE
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
      * 6000 - LIST ALL F&I PRODUCTS                                   *
      *---------------------------------------------------------------*
       6000-LIST-PRODUCTS.
      *
           INITIALIZE WS-LIST-OUTPUT
           MOVE 0 TO WS-LIST-IDX
           MOVE 0 TO WS-ROWS-FETCHED
      *
           EXEC SQL
               OPEN FI_PROD_LIST_CSR
           END-EXEC
      *
           IF SQLCODE NOT = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ERROR OPENING F&I PRODUCT LIST CURSOR'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           PERFORM 6100-FETCH-PRODUCT
               UNTIL SQLCODE NOT = 0
               OR WS-LIST-IDX >= 15
      *
           EXEC SQL
               CLOSE FI_PROD_LIST_CSR
           END-EXEC
      *
           IF WS-ROWS-FETCHED = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'NO F&I PRODUCTS FOUND IN CATALOG'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
      *    SEND LIST
      *
           MOVE 1200 TO WS-LST-LL
           MOVE 0 TO WS-LST-ZZ
           MOVE 'ASPRDI00' TO WS-LST-MOD-NAME
           MOVE WS-ROWS-FETCHED TO WS-LST-COUNT
           STRING 'DISPLAYING ' WS-ROWS-FETCHED
                  ' F&I PRODUCT(S) IN CATALOG'
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
      * 6100 - FETCH NEXT PRODUCT FROM CURSOR                         *
      *---------------------------------------------------------------*
       6100-FETCH-PRODUCT.
      *
           EXEC SQL
               FETCH FI_PROD_LIST_CSR
               INTO  :WS-CSR-KEY-TX,
                     :WS-CSR-VAL-TX
           END-EXEC
      *
           IF SQLCODE = 0
               ADD 1 TO WS-LIST-IDX
               ADD 1 TO WS-ROWS-FETCHED
      *
      *        EXTRACT PRODUCT TYPE FROM KEY (AFTER PREFIX)
      *
               MOVE WS-CSR-KEY-TX(12:4)
                   TO WS-LST-PRD-TYPE(WS-LIST-IDX)
      *
      *        PARSE THE VALUE
      *
               MOVE WS-CSR-VAL-TX TO WS-CONFIG-VAL-WORK
               PERFORM 2700-PARSE-CONFIG-VALUE
      *
               MOVE WS-PP-NAME
                   TO WS-LST-PRD-NAME(WS-LIST-IDX)
               MOVE WS-PP-TERM
                   TO WS-LST-PRD-TERM(WS-LIST-IDX)
      *
               COMPUTE WS-RETAIL-NUM =
                   FUNCTION NUMVAL(WS-PP-RETAIL)
               MOVE WS-RETAIL-NUM
                   TO WS-LST-PRD-RPRC(WS-LIST-IDX)
      *
               COMPUTE WS-COST-NUM =
                   FUNCTION NUMVAL(WS-PP-COST)
               MOVE WS-COST-NUM
                   TO WS-LST-PRD-COST(WS-LIST-IDX)
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
           MOVE 500 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASPRDI00' TO WS-OUT-MOD-NAME
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
           MOVE 'INS' TO WS-AUD-ACTION
           MOVE 'SYSTEM_CONFIG' TO WS-AUD-TABLE
           MOVE WS-CONFIG-KEY-WORK TO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           MOVE WS-CONFIG-VAL-WORK TO WS-AUD-NEW-VAL
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
      * END OF ADMPRD00                                              *
      ****************************************************************
