       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMTAX00.
      ****************************************************************
      * PROGRAM:    ADMTAX00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMT                                             *
      * MFS MID:    MFSADTAX (TAX RATE MAINTENANCE SCREEN)           *
      * MFS MOD:    ASTAXI00 (TAX RATE INQUIRY RESPONSE)             *
      *                                                              *
      * PURPOSE:    TAX RATE MAINTENANCE. PROVIDES CRUD OPERATIONS   *
      *             ON THE TAX_RATE TABLE BY STATE/COUNTY/CITY.       *
      *             VALIDATES RATES BETWEEN 0 AND 0.15 (15%).         *
      *             SHOWS COMBINED RATE CALCULATION.                  *
      *                                                              *
      * FUNCTIONS:  INQ - INQUIRY BY STATE/COUNTY/CITY               *
      *             ADD - ADD NEW TAX RATE RECORD                    *
      *             UPD - UPDATE EXISTING TAX RATE                   *
      *                                                              *
      * CALLS:      COMTAXL0 - TEST TAX CALCULATION                 *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMTAX00'.
      *
      *    IMS FUNCTION CODES
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR TAX_RATE TABLE
      *
           COPY DCLTAXRT.
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
           05  WS-IN-STATE-CODE     PIC X(02).
           05  WS-IN-COUNTY-CODE    PIC X(05).
           05  WS-IN-CITY-CODE      PIC X(05).
           05  WS-IN-STATE-RATE     PIC X(08).
           05  WS-IN-COUNTY-RATE    PIC X(08).
           05  WS-IN-CITY-RATE      PIC X(08).
           05  WS-IN-DOC-FEE-MAX    PIC X(10).
           05  WS-IN-TITLE-FEE      PIC X(10).
           05  WS-IN-REG-FEE        PIC X(10).
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
           05  WS-OUT-STATE-CODE    PIC X(02).
           05  WS-OUT-COUNTY-CODE   PIC X(05).
           05  WS-OUT-CITY-CODE     PIC X(05).
           05  WS-OUT-STATE-RATE    PIC 9.9999.
           05  WS-OUT-STATE-PCT     PIC Z9.99.
           05  WS-OUT-COUNTY-RATE   PIC 9.9999.
           05  WS-OUT-COUNTY-PCT    PIC Z9.99.
           05  WS-OUT-CITY-RATE     PIC 9.9999.
           05  WS-OUT-CITY-PCT      PIC Z9.99.
           05  WS-OUT-COMBINED-RATE PIC 9.9999.
           05  WS-OUT-COMBINED-PCT  PIC Z9.99.
           05  WS-OUT-DOC-FEE-MAX   PIC $$$$$9.99.
           05  WS-OUT-TITLE-FEE     PIC $$$$$9.99.
           05  WS-OUT-REG-FEE       PIC $$$$$9.99.
           05  WS-OUT-EFF-DATE      PIC X(10).
           05  WS-OUT-EXP-DATE      PIC X(10).
           05  WS-OUT-TEST-PRICE    PIC $$$,$$$,$$9.99.
           05  WS-OUT-TEST-TAX      PIC $$$,$$$,$$9.99.
           05  WS-OUT-TEST-TOTAL    PIC $$$,$$$,$$9.99.
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  FILLER               PIC X(30).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-STATE-RATE-NUM   PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-COUNTY-RATE-NUM  PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-CITY-RATE-NUM    PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-DOC-FEE-NUM      PIC S9(05)V9(02) COMP-3 VALUE 0.
           05  WS-TITLE-FEE-NUM    PIC S9(05)V9(02) COMP-3 VALUE 0.
           05  WS-REG-FEE-NUM      PIC S9(05)V9(02) COMP-3 VALUE 0.
           05  WS-COMBINED-RATE    PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-MAX-RATE         PIC S9(01)V9(04) COMP-3
                                                     VALUE 0.1500.
           05  WS-TEST-PRICE       PIC S9(09)V9(02) COMP-3
                                                     VALUE 30000.00.
           05  WS-TEST-TAX         PIC S9(09)V9(02) COMP-3 VALUE 0.
           05  WS-TEST-TOTAL       PIC S9(09)V9(02) COMP-3 VALUE 0.
           05  WS-PCT-WORK         PIC S9(03)V9(02) COMP-3 VALUE 0.
      *
      *    NULL INDICATOR FOR EXPIRY DATE
      *
       01  WS-NULL-IND.
           05  NI-EXPIRY-DATE       PIC S9(04) COMP VALUE 0.
      *
      *    TAX CALCULATION MODULE FIELDS
      *
       01  WS-TAX-CALC-FIELDS.
           05  WS-TC-STATE-CODE    PIC X(02).
           05  WS-TC-COUNTY-CODE   PIC X(05).
           05  WS-TC-CITY-CODE     PIC X(05).
           05  WS-TC-SALE-PRICE    PIC S9(09)V9(02) COMP-3.
           05  WS-TC-TAX-RESULT.
               10  WS-TC-TAX-AMT  PIC S9(09)V9(02) COMP-3.
               10  WS-TC-STATE-TAX PIC S9(09)V9(02) COMP-3.
               10  WS-TC-COUNTY-TAX PIC S9(09)V9(02) COMP-3.
               10  WS-TC-CITY-TAX PIC S9(09)V9(02) COMP-3.
               10  WS-TC-DOC-FEE  PIC S9(05)V9(02) COMP-3.
               10  WS-TC-TITLE-FEE PIC S9(05)V9(02) COMP-3.
               10  WS-TC-REG-FEE  PIC S9(05)V9(02) COMP-3.
               10  WS-TC-RC       PIC S9(04) COMP.
               10  WS-TC-MSG      PIC X(50).
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
                       PERFORM 4000-ADD-TAX-RATE
                   END-IF
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-TAX-RATE
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
      * 2000 - VALIDATE TAX RATE INPUT FIELDS                          *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
      *    STATE CODE REQUIRED
      *
           IF WS-IN-STATE-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'STATE CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    COUNTY CODE REQUIRED
      *
           IF WS-IN-COUNTY-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'COUNTY CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    CITY CODE REQUIRED
      *
           IF WS-IN-CITY-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'CITY CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    STATE TAX RATE - REQUIRED, 0 TO 0.15
      *
           IF WS-IN-STATE-RATE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'STATE TAX RATE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           COMPUTE WS-STATE-RATE-NUM =
               FUNCTION NUMVAL(WS-IN-STATE-RATE)
      *
           IF WS-STATE-RATE-NUM < 0
           OR WS-STATE-RATE-NUM > WS-MAX-RATE
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'STATE RATE MUST BE BETWEEN 0 AND 0.15 (15%)'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    COUNTY TAX RATE - REQUIRED, 0 TO 0.15
      *
           IF WS-IN-COUNTY-RATE = SPACES
               MOVE 0 TO WS-COUNTY-RATE-NUM
           ELSE
               COMPUTE WS-COUNTY-RATE-NUM =
                   FUNCTION NUMVAL(WS-IN-COUNTY-RATE)
               IF WS-COUNTY-RATE-NUM < 0
               OR WS-COUNTY-RATE-NUM > WS-MAX-RATE
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE
                   'COUNTY RATE MUST BE BETWEEN 0 AND 0.15 (15%)'
                       TO WS-ERROR-MSG
                   GO TO 2000-EXIT
               END-IF
           END-IF
      *
      *    CITY TAX RATE - REQUIRED, 0 TO 0.15
      *
           IF WS-IN-CITY-RATE = SPACES
               MOVE 0 TO WS-CITY-RATE-NUM
           ELSE
               COMPUTE WS-CITY-RATE-NUM =
                   FUNCTION NUMVAL(WS-IN-CITY-RATE)
               IF WS-CITY-RATE-NUM < 0
               OR WS-CITY-RATE-NUM > WS-MAX-RATE
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE
                   'CITY RATE MUST BE BETWEEN 0 AND 0.15 (15%)'
                       TO WS-ERROR-MSG
                   GO TO 2000-EXIT
               END-IF
           END-IF
      *
      *    VALIDATE COMBINED RATE NOT EXCESSIVE (< 20%)
      *
           COMPUTE WS-COMBINED-RATE =
               WS-STATE-RATE-NUM + WS-COUNTY-RATE-NUM
               + WS-CITY-RATE-NUM
      *
           IF WS-COMBINED-RATE > 0.2000
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'COMBINED TAX RATE EXCEEDS 20% - VERIFY'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    DOC FEE MAX
      *
           IF WS-IN-DOC-FEE-MAX NOT = SPACES
               COMPUTE WS-DOC-FEE-NUM =
                   FUNCTION NUMVAL(WS-IN-DOC-FEE-MAX)
           ELSE
               MOVE 0 TO WS-DOC-FEE-NUM
           END-IF
      *
      *    TITLE FEE
      *
           IF WS-IN-TITLE-FEE NOT = SPACES
               COMPUTE WS-TITLE-FEE-NUM =
                   FUNCTION NUMVAL(WS-IN-TITLE-FEE)
           ELSE
               MOVE 0 TO WS-TITLE-FEE-NUM
           END-IF
      *
      *    REG FEE
      *
           IF WS-IN-REG-FEE NOT = SPACES
               COMPUTE WS-REG-FEE-NUM =
                   FUNCTION NUMVAL(WS-IN-REG-FEE)
           ELSE
               MOVE 0 TO WS-REG-FEE-NUM
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
      * 3000 - INQUIRY BY STATE/COUNTY/CITY                            *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-STATE-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'STATE CODE IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-COUNTY-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'COUNTY CODE IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-CITY-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'CITY CODE IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT STATE_CODE, COUNTY_CODE, CITY_CODE,
                      STATE_RATE, COUNTY_RATE, CITY_RATE,
                      DOC_FEE_MAX, TITLE_FEE, REG_FEE,
                      EFFECTIVE_DATE, EXPIRY_DATE
               INTO   :DCLTAX-RATE.STATE-CODE,
                      :DCLTAX-RATE.COUNTY-CODE,
                      :DCLTAX-RATE.CITY-CODE,
                      :DCLTAX-RATE.STATE-RATE,
                      :DCLTAX-RATE.COUNTY-RATE,
                      :DCLTAX-RATE.CITY-RATE,
                      :DCLTAX-RATE.DOC-FEE-MAX,
                      :DCLTAX-RATE.TITLE-FEE,
                      :DCLTAX-RATE.REG-FEE,
                      :DCLTAX-RATE.EFFECTIVE-DATE,
                      :DCLTAX-RATE.EXPIRY-DATE
                          :NI-EXPIRY-DATE
               FROM   AUTOSALE.TAX_RATE
               WHERE  STATE_CODE  = :WS-IN-STATE-CODE
               AND    COUNTY_CODE = :WS-IN-COUNTY-CODE
               AND    CITY_CODE   = :WS-IN-CITY-CODE
               AND    EFFECTIVE_DATE <= CURRENT DATE
               AND    (EXPIRY_DATE IS NULL
                       OR EXPIRY_DATE >= CURRENT DATE)
               ORDER BY EFFECTIVE_DATE DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 3100-FORMAT-INQUIRY-OUTPUT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'TAX RATE NOT FOUND: '
                          WS-IN-STATE-CODE '/'
                          WS-IN-COUNTY-CODE '/'
                          WS-IN-CITY-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-INQUIRY' TO WS-DBE-SECTION
                   MOVE 'TAX_RATE' TO WS-DBE-TABLE
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
      * 3100 - FORMAT INQUIRY OUTPUT WITH COMBINED RATE CALC           *
      *---------------------------------------------------------------*
       3100-FORMAT-INQUIRY-OUTPUT.
      *
           MOVE 700 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASTAXI00' TO WS-OUT-MOD-NAME
           MOVE 'INQ' TO WS-OUT-FUNC-CODE
           MOVE STATE-CODE OF DCLTAX-RATE TO WS-OUT-STATE-CODE
           MOVE COUNTY-CODE OF DCLTAX-RATE TO WS-OUT-COUNTY-CODE
           MOVE CITY-CODE OF DCLTAX-RATE TO WS-OUT-CITY-CODE
      *
      *    STATE RATE AND PERCENTAGE
      *
           MOVE STATE-RATE OF DCLTAX-RATE TO WS-OUT-STATE-RATE
           COMPUTE WS-PCT-WORK =
               STATE-RATE OF DCLTAX-RATE * 100
           MOVE WS-PCT-WORK TO WS-OUT-STATE-PCT
      *
      *    COUNTY RATE AND PERCENTAGE
      *
           MOVE COUNTY-RATE OF DCLTAX-RATE TO WS-OUT-COUNTY-RATE
           COMPUTE WS-PCT-WORK =
               COUNTY-RATE OF DCLTAX-RATE * 100
           MOVE WS-PCT-WORK TO WS-OUT-COUNTY-PCT
      *
      *    CITY RATE AND PERCENTAGE
      *
           MOVE CITY-RATE OF DCLTAX-RATE TO WS-OUT-CITY-RATE
           COMPUTE WS-PCT-WORK =
               CITY-RATE OF DCLTAX-RATE * 100
           MOVE WS-PCT-WORK TO WS-OUT-CITY-PCT
      *
      *    COMBINED RATE
      *
           COMPUTE WS-COMBINED-RATE =
               STATE-RATE OF DCLTAX-RATE
               + COUNTY-RATE OF DCLTAX-RATE
               + CITY-RATE OF DCLTAX-RATE
           MOVE WS-COMBINED-RATE TO WS-OUT-COMBINED-RATE
           COMPUTE WS-PCT-WORK = WS-COMBINED-RATE * 100
           MOVE WS-PCT-WORK TO WS-OUT-COMBINED-PCT
      *
      *    FEES
      *
           MOVE DOC-FEE-MAX OF DCLTAX-RATE TO WS-OUT-DOC-FEE-MAX
           MOVE TITLE-FEE OF DCLTAX-RATE TO WS-OUT-TITLE-FEE
           MOVE REG-FEE OF DCLTAX-RATE TO WS-OUT-REG-FEE
      *
           MOVE EFFECTIVE-DATE OF DCLTAX-RATE TO WS-OUT-EFF-DATE
      *
           IF NI-EXPIRY-DATE >= 0
               MOVE EXPIRY-DATE OF DCLTAX-RATE
                   TO WS-OUT-EXP-DATE
           ELSE
               MOVE '(CURRENT) ' TO WS-OUT-EXP-DATE
           END-IF
      *
      *    TEST CALCULATION ON $30,000 SALE
      *
           MOVE WS-IN-STATE-CODE TO WS-TC-STATE-CODE
           MOVE WS-IN-COUNTY-CODE TO WS-TC-COUNTY-CODE
           MOVE WS-IN-CITY-CODE TO WS-TC-CITY-CODE
           MOVE WS-TEST-PRICE TO WS-TC-SALE-PRICE
      *
           CALL 'COMTAXL0' USING WS-TC-STATE-CODE
                                  WS-TC-COUNTY-CODE
                                  WS-TC-CITY-CODE
                                  WS-TC-SALE-PRICE
                                  WS-TC-TAX-RESULT
      *
           IF WS-TC-RC = 0
               MOVE WS-TEST-PRICE TO WS-OUT-TEST-PRICE
               MOVE WS-TC-TAX-AMT TO WS-OUT-TEST-TAX
               COMPUTE WS-TEST-TOTAL =
                   WS-TEST-PRICE + WS-TC-TAX-AMT
               MOVE WS-TEST-TOTAL TO WS-OUT-TEST-TOTAL
           ELSE
               MOVE WS-TEST-PRICE TO WS-OUT-TEST-PRICE
               COMPUTE WS-TEST-TAX =
                   WS-TEST-PRICE * WS-COMBINED-RATE
               MOVE WS-TEST-TAX TO WS-OUT-TEST-TAX
               COMPUTE WS-TEST-TOTAL =
                   WS-TEST-PRICE + WS-TEST-TAX
               MOVE WS-TEST-TOTAL TO WS-OUT-TEST-TOTAL
           END-IF
      *
           MOVE 'TAX RATE RECORD DISPLAYED SUCCESSFULLY'
               TO WS-OUT-MSG-LINE1
           STRING 'TEST: $30,000 SALE = TAX + FEES SHOWN ABOVE'
               DELIMITED BY SIZE
               INTO WS-OUT-MSG-LINE2
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       3100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - ADD NEW TAX RATE RECORD                                 *
      *---------------------------------------------------------------*
       4000-ADD-TAX-RATE.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               INSERT INTO AUTOSALE.TAX_RATE
               ( STATE_CODE, COUNTY_CODE, CITY_CODE,
                 STATE_RATE, COUNTY_RATE, CITY_RATE,
                 DOC_FEE_MAX, TITLE_FEE, REG_FEE,
                 EFFECTIVE_DATE, EXPIRY_DATE )
               VALUES
               ( :DCLTAX-RATE.STATE-CODE,
                 :DCLTAX-RATE.COUNTY-CODE,
                 :DCLTAX-RATE.CITY-CODE,
                 :DCLTAX-RATE.STATE-RATE,
                 :DCLTAX-RATE.COUNTY-RATE,
                 :DCLTAX-RATE.CITY-RATE,
                 :DCLTAX-RATE.DOC-FEE-MAX,
                 :DCLTAX-RATE.TITLE-FEE,
                 :DCLTAX-RATE.REG-FEE,
                 :DCLTAX-RATE.EFFECTIVE-DATE,
                 :DCLTAX-RATE.EXPIRY-DATE
                     :NI-EXPIRY-DATE )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 700 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASTAXI00' TO WS-OUT-MOD-NAME
                   MOVE 'ADD' TO WS-OUT-FUNC-CODE
                   STRING 'TAX RATE ADDED FOR: '
                          WS-IN-STATE-CODE '/'
                          WS-IN-COUNTY-CODE '/'
                          WS-IN-CITY-CODE
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN -803
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'TAX RATE ALREADY EXISTS FOR THIS DATE'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '4000-ADD' TO WS-DBE-SECTION
                   MOVE 'TAX_RATE' TO WS-DBE-TABLE
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
           MOVE WS-IN-STATE-CODE TO STATE-CODE OF DCLTAX-RATE
           MOVE WS-IN-COUNTY-CODE TO COUNTY-CODE OF DCLTAX-RATE
           MOVE WS-IN-CITY-CODE TO CITY-CODE OF DCLTAX-RATE
           MOVE WS-STATE-RATE-NUM TO STATE-RATE OF DCLTAX-RATE
           MOVE WS-COUNTY-RATE-NUM TO COUNTY-RATE OF DCLTAX-RATE
           MOVE WS-CITY-RATE-NUM TO CITY-RATE OF DCLTAX-RATE
           MOVE WS-DOC-FEE-NUM TO DOC-FEE-MAX OF DCLTAX-RATE
           MOVE WS-TITLE-FEE-NUM TO TITLE-FEE OF DCLTAX-RATE
           MOVE WS-REG-FEE-NUM TO REG-FEE OF DCLTAX-RATE
           MOVE WS-IN-EFF-DATE
               TO EFFECTIVE-DATE OF DCLTAX-RATE
      *
           IF WS-IN-EXP-DATE = SPACES
               MOVE -1 TO NI-EXPIRY-DATE
           ELSE
               MOVE 0 TO NI-EXPIRY-DATE
               MOVE WS-IN-EXP-DATE
                   TO EXPIRY-DATE OF DCLTAX-RATE
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - UPDATE EXISTING TAX RATE RECORD                         *
      *---------------------------------------------------------------*
       5000-UPDATE-TAX-RATE.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               UPDATE AUTOSALE.TAX_RATE
               SET    STATE_RATE = :DCLTAX-RATE.STATE-RATE,
                      COUNTY_RATE = :DCLTAX-RATE.COUNTY-RATE,
                      CITY_RATE = :DCLTAX-RATE.CITY-RATE,
                      DOC_FEE_MAX = :DCLTAX-RATE.DOC-FEE-MAX,
                      TITLE_FEE = :DCLTAX-RATE.TITLE-FEE,
                      REG_FEE = :DCLTAX-RATE.REG-FEE,
                      EXPIRY_DATE = :DCLTAX-RATE.EXPIRY-DATE
                          :NI-EXPIRY-DATE
               WHERE  STATE_CODE  = :WS-IN-STATE-CODE
               AND    COUNTY_CODE = :WS-IN-COUNTY-CODE
               AND    CITY_CODE   = :WS-IN-CITY-CODE
               AND    EFFECTIVE_DATE = :WS-IN-EFF-DATE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 700 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASTAXI00' TO WS-OUT-MOD-NAME
                   MOVE 'UPD' TO WS-OUT-FUNC-CODE
                   STRING 'TAX RATE UPDATED FOR: '
                          WS-IN-STATE-CODE '/'
                          WS-IN-COUNTY-CODE '/'
                          WS-IN-CITY-CODE
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'TAX RATE NOT FOUND FOR UPDATE'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '5000-UPDATE' TO WS-DBE-SECTION
                   MOVE 'TAX_RATE' TO WS-DBE-TABLE
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
           MOVE 700 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASTAXI00' TO WS-OUT-MOD-NAME
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
           MOVE 'TAX_RATE' TO WS-AUD-TABLE
           STRING WS-IN-STATE-CODE '/'
                  WS-IN-COUNTY-CODE '/'
                  WS-IN-CITY-CODE '/'
                  WS-IN-EFF-DATE
               DELIMITED BY SIZE
               INTO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           STRING 'ST=' WS-IN-STATE-RATE
                  ' CO=' WS-IN-COUNTY-RATE
                  ' CI=' WS-IN-CITY-RATE
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
      * END OF ADMTAX00                                              *
      ****************************************************************
