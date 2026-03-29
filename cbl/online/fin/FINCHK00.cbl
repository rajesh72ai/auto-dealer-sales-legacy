       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINCHK00.
      ****************************************************************
      * PROGRAM:  FINCHK00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - CREDIT CHECK INTERFACE                   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  INITIATES CREDIT CHECK FOR A CUSTOMER OR DEAL.     *
      *           CHECKS FOR EXISTING VALID (NON-EXPIRED) CREDIT     *
      *           REPORT FIRST. IF VALID REPORT EXISTS, DISPLAYS IT  *
      *           AND SKIPS BUREAU CALL. OTHERWISE INITIATES NEW     *
      *           CREDIT CHECK.                                      *
      *           FOR DEMO: SIMULATES BUREAU RESPONSE BY GENERATING  *
      *           CREDIT SCORE BASED ON CUSTOMER INCOME AND DEBT.    *
      *           UPDATES CREDIT_CHECK TABLE WITH SCORE, TIER, DTI   *
      *           RATIO, AND STATUS=RC (RECEIVED).                   *
      *           RETURNS TIER (A-E), SCORE, RECOMMENDED MAX         *
      *           FINANCE AMOUNT, AND MONTHLY BUDGET.                *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNCK - FINANCE CREDIT CHECK                        *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                       *
      *           COMLGEL0 - AUDIT LOGGING                          *
      *           COMDBEL0 - DB2 ERROR HANDLER                      *
      * TABLES:   AUTOSALE.CREDIT_CHECK                              *
      *           AUTOSALE.CUSTOMER                                   *
      *           AUTOSALE.SALES_DEAL                                 *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-3090.
       OBJECT-COMPUTER. IBM-3090.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       01  WS-PROGRAM-FIELDS.
           05  WS-PROGRAM-NAME           PIC X(08)
                                          VALUE 'FINCHK00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
           COPY WSMSGFMT.
      *
      *    DCLGEN COPIES
      *
           COPY DCLCRDCK.
      *
           COPY DCLCUSTM.
      *
           COPY DCLSLDEL.
      *
      *    INPUT FIELDS
      *
       01  WS-CHK-INPUT.
           05  WS-CI-FUNCTION            PIC X(02).
               88  WS-CI-BY-DEAL                     VALUE 'DL'.
               88  WS-CI-BY-CUST                     VALUE 'CU'.
           05  WS-CI-DEAL-NUMBER         PIC X(10).
           05  WS-CI-CUSTOMER-ID         PIC X(09).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CUST-ID-NUM           PIC S9(09) COMP VALUE +0.
           05  WS-EXISTING-CREDIT       PIC X(01) VALUE 'N'.
               88  WS-HAS-VALID-CREDIT               VALUE 'Y'.
               88  WS-NO-VALID-CREDIT                VALUE 'N'.
           05  WS-SIM-SCORE             PIC S9(04) COMP VALUE +0.
           05  WS-SIM-INCOME            PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-SIM-DEBT              PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-SIM-DTI               PIC S9(03)V99 COMP-3
                                                       VALUE +0.
           05  WS-SIM-TIER              PIC X(01) VALUE SPACES.
           05  WS-MAX-FINANCE           PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-BUDGET        PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-NEXT-CREDIT-ID        PIC S9(09) COMP VALUE +0.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-CHK-OUTPUT.
           05  WS-KO-STATUS-LINE.
               10  WS-KO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-KO-MSG-TEXT       PIC X(70).
           05  WS-KO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-KO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- CREDIT CHECK RESULTS ----        '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-KO-CUST-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'CUSTOMER: '.
               10  WS-KO-CUST-NAME      PIC X(40).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(04) VALUE 'ID: '.
               10  WS-KO-CUST-ID        PIC Z(08)9.
               10  FILLER               PIC X(11) VALUE SPACES.
           05  WS-KO-CUST-LINE-2.
               10  FILLER               PIC X(10)
                   VALUE 'SSN LAST4:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  FILLER               PIC X(07)
                   VALUE 'XXX-XX-'.
               10  WS-KO-SSN-LAST4      PIC X(04).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'DOB: '.
               10  WS-KO-DOB            PIC X(10).
               10  FILLER               PIC X(37) VALUE SPACES.
           05  WS-KO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-KO-SCORE-HDR.
               10  FILLER               PIC X(40)
                   VALUE '---- BUREAU RESPONSE ----             '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-KO-SCORE-LINE.
               10  FILLER               PIC X(14)
                   VALUE 'CREDIT SCORE: '.
               10  WS-KO-SCORE          PIC ZZZ9.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TIER: '.
               10  WS-KO-TIER           PIC X(01).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-KO-STATUS         PIC X(02).
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-KO-INCOME-LINE.
               10  FILLER               PIC X(15)
                   VALUE 'ANNUAL INCOME: '.
               10  WS-KO-INCOME         PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(14)
                   VALUE 'MONTHLY DEBT: '.
               10  WS-KO-DEBT           PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(14) VALUE SPACES.
           05  WS-KO-DTI-LINE.
               10  FILLER               PIC X(11)
                   VALUE 'DTI RATIO: '.
               10  WS-KO-DTI            PIC ZZ9.99.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(61) VALUE SPACES.
           05  WS-KO-BLANK-3            PIC X(79) VALUE SPACES.
           05  WS-KO-REC-HDR.
               10  FILLER               PIC X(40)
                   VALUE '---- RECOMMENDATIONS ----             '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-KO-MAX-LINE.
               10  FILLER               PIC X(21)
                   VALUE 'MAX FINANCE AMOUNT:  '.
               10  WS-KO-MAX-FIN        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(44) VALUE SPACES.
           05  WS-KO-BUDGET-LINE.
               10  FILLER               PIC X(21)
                   VALUE 'MONTHLY PMT BUDGET:  '.
               10  WS-KO-MONTHLY-BUD    PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(45) VALUE SPACES.
           05  WS-KO-FILLER             PIC X(79) VALUE SPACES.
      *
      *    FORMAT CALL FIELDS
      *
       01  WS-FMT-REQUEST.
           05  WS-FMT-FUNCTION          PIC X(04).
           05  WS-FMT-INPUT             PIC X(30).
       01  WS-FMT-RESULT.
           05  WS-FMT-RC                PIC S9(04) COMP.
           05  WS-FMT-OUTPUT            PIC X(40).
      *
      *    AUDIT LOG CALL FIELDS
      *
       01  WS-AUD-USER-ID              PIC X(08).
       01  WS-AUD-PROGRAM-ID           PIC X(08) VALUE 'FINCHK00'.
       01  WS-AUD-ACTION-TYPE          PIC X(08).
       01  WS-AUD-TABLE-NAME           PIC X(18).
       01  WS-AUD-KEY-VALUE            PIC X(30).
       01  WS-AUD-OLD-VALUE            PIC X(100).
       01  WS-AUD-NEW-VALUE            PIC X(100).
       01  WS-AUD-RETURN-CODE          PIC S9(04) COMP.
       01  WS-AUD-ERROR-MSG            PIC X(79).
      *
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-PROGRAM-NAME         PIC X(08) VALUE 'FINCHK00'.
       01  WS-DBE-SECTION-NAME         PIC X(30).
       01  WS-DBE-TABLE-NAME           PIC X(18).
       01  WS-DBE-OPERATION            PIC X(08).
       01  WS-DBE-RESULT-AREA.
           05  WS-DBE-RESULT-CODE      PIC S9(04) COMP.
           05  WS-DBE-RESULT-MSG       PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-RETURN-CODE              PIC S9(04) COMP VALUE +0.
      *
      *    TIMESTAMP
      *
       01  WS-CURRENT-TS               PIC X(26) VALUE SPACES.
       01  WS-CURRENT-DATE             PIC X(10) VALUE SPACES.
       01  WS-EXPIRY-DATE              PIC X(10) VALUE SPACES.
       01  WS-DATE-TIME-WORK.
           05  WS-DT-YYYY              PIC 9(04).
           05  WS-DT-MM                PIC 9(02).
           05  WS-DT-DD                PIC 9(02).
           05  WS-DT-HH                PIC 9(02).
           05  WS-DT-MN                PIC 9(02).
           05  WS-DT-SS                PIC 9(02).
           05  WS-DT-HS                PIC 9(02).
       01  WS-DIFF-GMT                 PIC S9(04).
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-SCORE             PIC S9(04) COMP VALUE +0.
           05  WS-NI-TIER              PIC S9(04) COMP VALUE +0.
           05  WS-NI-RESPONSE-TS       PIC S9(04) COMP VALUE +0.
           05  WS-NI-DEBT              PIC S9(04) COMP VALUE +0.
           05  WS-NI-INCOME            PIC S9(04) COMP VALUE +0.
           05  WS-NI-DTI               PIC S9(04) COMP VALUE +0.
           05  WS-NI-EXPIRY            PIC S9(04) COMP VALUE +0.
           05  WS-NI-DOB               PIC S9(04) COMP VALUE +0.
           05  WS-NI-SSN               PIC S9(04) COMP VALUE +0.
           05  WS-NI-EMPLOYER          PIC S9(04) COMP VALUE +0.
           05  WS-NI-ANN-INCOME        PIC S9(04) COMP VALUE +0.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-PCB-STATUS             PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-PCB-MOD-NAME           PIC X(08).
           05  IO-PCB-USER-ID            PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER                    PIC X(22).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4000-RESOLVE-CUSTOMER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-CHECK-EXISTING-CREDIT
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-NO-VALID-CREDIT
               PERFORM 6000-SIMULATE-BUREAU
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-BUILD-RECOMMENDATIONS
           END-IF
      *
           PERFORM 9000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE +0 TO WS-RETURN-CODE
           INITIALIZE WS-CHK-OUTPUT
           INITIALIZE WS-CHK-INPUT
           INITIALIZE WS-WORK-FIELDS
           MOVE 'FINCHK00' TO WS-KO-MSG-ID
           MOVE 'N' TO WS-EXISTING-CREDIT
      *
      *    GET CURRENT TIMESTAMP
      *
           MOVE FUNCTION CURRENT-DATE
               TO WS-DATE-TIME-WORK
                  WS-DIFF-GMT
           STRING WS-DT-YYYY '-' WS-DT-MM '-' WS-DT-DD '-'
                  WS-DT-HH '.' WS-DT-MN '.' WS-DT-SS '.000000'
                  DELIMITED BY SIZE
                  INTO WS-CURRENT-TS
           STRING WS-DT-YYYY '-' WS-DT-MM '-' WS-DT-DD
                  DELIMITED BY SIZE
                  INTO WS-CURRENT-DATE
      *
      *    EXPIRY DATE = CURRENT DATE + 30 DAYS (APPROX)
      *
           MOVE WS-CURRENT-DATE TO WS-EXPIRY-DATE
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT                                        *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'IMS GU FAILED - UNABLE TO RECEIVE INPUT'
                   TO WS-KO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-CI-FUNCTION
               MOVE WS-INP-KEY-DATA(1:10) TO WS-CI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:9)    TO WS-CI-CUSTOMER-ID
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-CI-FUNCTION = SPACES
               MOVE 'DL' TO WS-CI-FUNCTION
           END-IF
      *
           IF WS-CI-BY-DEAL
               IF WS-CI-DEAL-NUMBER = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEAL NUMBER IS REQUIRED FOR DEAL LOOKUP'
                       TO WS-KO-MSG-TEXT
               END-IF
           ELSE
               IF WS-CI-BY-CUST
                   IF WS-CI-CUSTOMER-ID = SPACES
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'CUSTOMER ID IS REQUIRED'
                           TO WS-KO-MSG-TEXT
                   ELSE
                       COMPUTE WS-CUST-ID-NUM =
                           FUNCTION NUMVAL(WS-CI-CUSTOMER-ID)
                       END-COMPUTE
                   END-IF
               ELSE
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'FUNCTION MUST BE DL (DEAL) OR CU (CUSTOMER)'
                       TO WS-KO-MSG-TEXT
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4000-RESOLVE-CUSTOMER - GET CUSTOMER FROM DEAL OR DIRECT  *
      ****************************************************************
       4000-RESOLVE-CUSTOMER.
      *
           IF WS-CI-BY-DEAL
      *        GET CUSTOMER ID FROM DEAL
               EXEC SQL
                   SELECT CUSTOMER_ID
                   INTO   :WS-CUST-ID-NUM
                   FROM   AUTOSALE.SALES_DEAL
                   WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
               END-EXEC
      *
               IF SQLCODE = +100
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEAL NOT FOUND' TO WS-KO-MSG-TEXT
                   GO TO 4000-EXIT
               END-IF
               IF SQLCODE NOT = +0
                   MOVE +16 TO WS-RETURN-CODE
                   MOVE 'DB2 ERROR ON DEAL LOOKUP'
                       TO WS-KO-MSG-TEXT
                   GO TO 4000-EXIT
               END-IF
           END-IF
      *
      *    FETCH CUSTOMER DETAILS
      *
           EXEC SQL
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , DATE_OF_BIRTH
                    , SSN_LAST4
                    , ANNUAL_INCOME
                    , EMPLOYER_NAME
               INTO  :CUSTOMER-ID    OF DCLCUSTOMER
                    , :FIRST-NAME    OF DCLCUSTOMER
                    , :LAST-NAME     OF DCLCUSTOMER
                    , :DATE-OF-BIRTH OF DCLCUSTOMER
                                      :WS-NI-DOB
                    , :SSN-LAST4     OF DCLCUSTOMER
                                      :WS-NI-SSN
                    , :ANNUAL-INCOME OF DCLCUSTOMER
                                      :WS-NI-ANN-INCOME
                    , :EMPLOYER-NAME OF DCLCUSTOMER
                                      :WS-NI-EMPLOYER
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-KO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE '4000-RESOLVE'   TO WS-DBE-SECTION-NAME
               MOVE 'CUSTOMER'       TO WS-DBE-TABLE-NAME
               MOVE 'SELECT'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON CUSTOMER LOOKUP'
                   TO WS-KO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    FORMAT CUSTOMER OUTPUT
      *
           STRING LAST-NAME-TX OF DCLCUSTOMER
                  DELIMITED BY '  '
                  ', '
                  DELIMITED BY SIZE
                  FIRST-NAME-TX OF DCLCUSTOMER
                  DELIMITED BY '  '
                  INTO WS-KO-CUST-NAME
           MOVE CUSTOMER-ID OF DCLCUSTOMER TO WS-KO-CUST-ID
      *
           IF WS-NI-SSN >= +0
               MOVE SSN-LAST4 OF DCLCUSTOMER TO WS-KO-SSN-LAST4
           ELSE
               MOVE 'N/A ' TO WS-KO-SSN-LAST4
           END-IF
      *
           IF WS-NI-DOB >= +0
               MOVE DATE-OF-BIRTH OF DCLCUSTOMER TO WS-KO-DOB
           ELSE
               MOVE 'N/A       ' TO WS-KO-DOB
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-CHECK-EXISTING-CREDIT - LOOK FOR VALID REPORT        *
      ****************************************************************
       5000-CHECK-EXISTING-CREDIT.
      *
           EXEC SQL
               SELECT CREDIT_ID
                    , CREDIT_SCORE
                    , CREDIT_TIER
                    , DTI_RATIO
                    , MONTHLY_DEBT
                    , MONTHLY_INCOME
                    , STATUS
                    , EXPIRY_DATE
               INTO  :CREDIT-ID      OF DCLCREDIT-CHECK
                    , :CREDIT-SCORE  OF DCLCREDIT-CHECK
                                      :WS-NI-SCORE
                    , :CREDIT-TIER   OF DCLCREDIT-CHECK
                                      :WS-NI-TIER
                    , :DTI-RATIO     OF DCLCREDIT-CHECK
                                      :WS-NI-DTI
                    , :MONTHLY-DEBT  OF DCLCREDIT-CHECK
                                      :WS-NI-DEBT
                    , :MONTHLY-INCOME OF DCLCREDIT-CHECK
                                      :WS-NI-INCOME
                    , :STATUS        OF DCLCREDIT-CHECK
                    , :EXPIRY-DATE   OF DCLCREDIT-CHECK
                                      :WS-NI-EXPIRY
               FROM   AUTOSALE.CREDIT_CHECK
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
                 AND  STATUS      = 'RC'
                 AND  EXPIRY_DATE >= CURRENT DATE
               ORDER BY REQUEST_TS DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +0
      *        VALID REPORT EXISTS - USE IT
               MOVE 'Y' TO WS-EXISTING-CREDIT
      *
               IF WS-NI-SCORE >= +0
                   MOVE CREDIT-SCORE OF DCLCREDIT-CHECK
                       TO WS-SIM-SCORE
                   MOVE CREDIT-SCORE OF DCLCREDIT-CHECK
                       TO WS-KO-SCORE
               END-IF
               IF WS-NI-TIER >= +0
                   MOVE CREDIT-TIER OF DCLCREDIT-CHECK
                       TO WS-SIM-TIER
                   MOVE CREDIT-TIER OF DCLCREDIT-CHECK
                       TO WS-KO-TIER
               END-IF
               IF WS-NI-DTI >= +0
                   MOVE DTI-RATIO OF DCLCREDIT-CHECK
                       TO WS-SIM-DTI
                   MOVE DTI-RATIO OF DCLCREDIT-CHECK
                       TO WS-KO-DTI
               END-IF
               IF WS-NI-DEBT >= +0
                   MOVE MONTHLY-DEBT OF DCLCREDIT-CHECK
                       TO WS-SIM-DEBT
                   MOVE MONTHLY-DEBT OF DCLCREDIT-CHECK
                       TO WS-KO-DEBT
               END-IF
               IF WS-NI-INCOME >= +0
                   MOVE MONTHLY-INCOME OF DCLCREDIT-CHECK
                       TO WS-SIM-INCOME
                   MOVE MONTHLY-INCOME OF DCLCREDIT-CHECK
                       TO WS-KO-INCOME
               END-IF
      *
               MOVE STATUS OF DCLCREDIT-CHECK TO WS-KO-STATUS
               MOVE 'EXISTING VALID CREDIT REPORT FOUND - NO NEW PULL'
                   TO WS-KO-MSG-TEXT
           ELSE
               IF SQLCODE = +100
      *            NO VALID REPORT - NEED NEW CHECK
                   MOVE 'N' TO WS-EXISTING-CREDIT
               ELSE
                   MOVE '5000-CHECK'     TO WS-DBE-SECTION-NAME
                   MOVE 'CREDIT_CHECK'   TO WS-DBE-TABLE-NAME
                   MOVE 'SELECT'         TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                          WS-DBE-PROGRAM-NAME
                                          WS-DBE-SECTION-NAME
                                          WS-DBE-TABLE-NAME
                                          WS-DBE-OPERATION
                                          WS-DBE-RESULT-AREA
                   MOVE +16 TO WS-RETURN-CODE
                   MOVE 'DB2 ERROR ON CREDIT CHECK LOOKUP'
                       TO WS-KO-MSG-TEXT
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    6000-SIMULATE-BUREAU - DEMO: GENERATE SCORE FROM INCOME   *
      ****************************************************************
       6000-SIMULATE-BUREAU.
      *
      *    GET NEXT CREDIT_ID
      *
           EXEC SQL
               SELECT COALESCE(MAX(CREDIT_ID), 0) + 1
               INTO   :WS-NEXT-CREDIT-ID
               FROM   AUTOSALE.CREDIT_CHECK
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR GETTING NEXT CREDIT ID'
                   TO WS-KO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    SIMULATE CREDIT SCORE BASED ON INCOME
      *    HIGHER INCOME = HIGHER SCORE (SIMPLIFIED DEMO)
      *
           IF WS-NI-ANN-INCOME >= +0
               AND ANNUAL-INCOME OF DCLCUSTOMER > +0
               MOVE ANNUAL-INCOME OF DCLCUSTOMER
                   TO WS-SIM-INCOME
      *
      *        INCOME-BASED SCORE SIMULATION
      *        $30K = 580, $50K = 650, $75K = 720, $100K+ = 780+
      *
               EVALUATE TRUE
                   WHEN ANNUAL-INCOME OF DCLCUSTOMER >= +100000
                       COMPUTE WS-SIM-SCORE = +780
                   WHEN ANNUAL-INCOME OF DCLCUSTOMER >= +75000
                       COMPUTE WS-SIM-SCORE = +720
                   WHEN ANNUAL-INCOME OF DCLCUSTOMER >= +50000
                       COMPUTE WS-SIM-SCORE = +650
                   WHEN ANNUAL-INCOME OF DCLCUSTOMER >= +30000
                       COMPUTE WS-SIM-SCORE = +580
                   WHEN OTHER
                       COMPUTE WS-SIM-SCORE = +520
               END-EVALUATE
           ELSE
      *        NO INCOME DATA - DEFAULT MIDDLE SCORE
               MOVE +620 TO WS-SIM-SCORE
               MOVE +50000.00 TO WS-SIM-INCOME
           END-IF
      *
      *    SIMULATE MONTHLY DEBT (15-30% OF MONTHLY INCOME)
      *
           COMPUTE WS-SIM-DEBT ROUNDED =
               (WS-SIM-INCOME / 12) * 0.20
           END-COMPUTE
      *
      *    CALCULATE DTI RATIO
      *
           IF WS-SIM-INCOME > +0
               COMPUTE WS-SIM-DTI ROUNDED =
                   (WS-SIM-DEBT / (WS-SIM-INCOME / 12)) * 100
               END-COMPUTE
           ELSE
               MOVE +50.00 TO WS-SIM-DTI
           END-IF
      *
      *    DETERMINE CREDIT TIER
      *
           EVALUATE TRUE
               WHEN WS-SIM-SCORE >= +750
                   MOVE 'A' TO WS-SIM-TIER
               WHEN WS-SIM-SCORE >= +700
                   MOVE 'B' TO WS-SIM-TIER
               WHEN WS-SIM-SCORE >= +650
                   MOVE 'C' TO WS-SIM-TIER
               WHEN WS-SIM-SCORE >= +600
                   MOVE 'D' TO WS-SIM-TIER
               WHEN OTHER
                   MOVE 'E' TO WS-SIM-TIER
           END-EVALUATE
      *
      *    INSERT CREDIT CHECK RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.CREDIT_CHECK
               ( CREDIT_ID
               , CUSTOMER_ID
               , BUREAU_CODE
               , CREDIT_SCORE
               , CREDIT_TIER
               , REQUEST_TS
               , RESPONSE_TS
               , STATUS
               , MONTHLY_DEBT
               , MONTHLY_INCOME
               , DTI_RATIO
               , EXPIRY_DATE
               )
               VALUES
               ( :WS-NEXT-CREDIT-ID
               , :WS-CUST-ID-NUM
               , 'EX'
               , :WS-SIM-SCORE
               , :WS-SIM-TIER
               , CURRENT TIMESTAMP
               , CURRENT TIMESTAMP
               , 'RC'
               , :WS-SIM-DEBT
               , :WS-SIM-INCOME
               , :WS-SIM-DTI
               , CURRENT DATE + 30 DAYS
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '6000-SIMULATE'  TO WS-DBE-SECTION-NAME
               MOVE 'CREDIT_CHECK'   TO WS-DBE-TABLE-NAME
               MOVE 'INSERT'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON CREDIT CHECK INSERT'
                   TO WS-KO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    FORMAT OUTPUT
      *
           MOVE WS-SIM-SCORE    TO WS-KO-SCORE
           MOVE WS-SIM-TIER     TO WS-KO-TIER
           MOVE 'RC'            TO WS-KO-STATUS
           MOVE WS-SIM-INCOME   TO WS-KO-INCOME
           MOVE WS-SIM-DEBT     TO WS-KO-DEBT
           MOVE WS-SIM-DTI      TO WS-KO-DTI
      *
      *    AUDIT LOG
      *
           MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
           MOVE 'INSERT'       TO WS-AUD-ACTION-TYPE
           MOVE 'CREDIT_CHECK' TO WS-AUD-TABLE-NAME
           MOVE WS-CI-CUSTOMER-ID TO WS-AUD-KEY-VALUE
           MOVE SPACES         TO WS-AUD-OLD-VALUE
           STRING 'CREDIT CHECK SCORE=' WS-KO-SCORE
                  ' TIER=' WS-SIM-TIER
                  DELIMITED BY SIZE
                  INTO WS-AUD-NEW-VALUE
           CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                  WS-AUD-PROGRAM-ID
                                  WS-AUD-ACTION-TYPE
                                  WS-AUD-TABLE-NAME
                                  WS-AUD-KEY-VALUE
                                  WS-AUD-OLD-VALUE
                                  WS-AUD-NEW-VALUE
                                  WS-AUD-RETURN-CODE
                                  WS-AUD-ERROR-MSG
      *
           MOVE 'CREDIT CHECK COMPLETED - NEW BUREAU PULL'
               TO WS-KO-MSG-TEXT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-BUILD-RECOMMENDATIONS - MAX FINANCE, MONTHLY BUDGET  *
      ****************************************************************
       7000-BUILD-RECOMMENDATIONS.
      *
      *    MAX FINANCE AMOUNT BASED ON TIER
      *    A = 125% INCOME, B = 100%, C = 75%, D = 50%, E = 25%
      *
           EVALUATE WS-SIM-TIER
               WHEN 'A'
                   COMPUTE WS-MAX-FINANCE ROUNDED =
                       WS-SIM-INCOME * 1.25
                   END-COMPUTE
               WHEN 'B'
                   COMPUTE WS-MAX-FINANCE ROUNDED =
                       WS-SIM-INCOME * 1.00
                   END-COMPUTE
               WHEN 'C'
                   COMPUTE WS-MAX-FINANCE ROUNDED =
                       WS-SIM-INCOME * 0.75
                   END-COMPUTE
               WHEN 'D'
                   COMPUTE WS-MAX-FINANCE ROUNDED =
                       WS-SIM-INCOME * 0.50
                   END-COMPUTE
               WHEN OTHER
                   COMPUTE WS-MAX-FINANCE ROUNDED =
                       WS-SIM-INCOME * 0.25
                   END-COMPUTE
           END-EVALUATE
      *
      *    MONTHLY BUDGET = (MONTHLY INCOME * 0.15) - EXISTING DEBT
      *    STANDARD: AUTO PAYMENT SHOULD NOT EXCEED 15% OF INCOME
      *
           COMPUTE WS-MONTHLY-BUDGET ROUNDED =
               ((WS-SIM-INCOME / 12) * 0.15) - WS-SIM-DEBT
           END-COMPUTE
      *
           IF WS-MONTHLY-BUDGET < +0
               MOVE +0 TO WS-MONTHLY-BUDGET
           END-IF
      *
           MOVE WS-MAX-FINANCE    TO WS-KO-MAX-FIN
           MOVE WS-MONTHLY-BUDGET TO WS-KO-MONTHLY-BUD
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-CHK-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNCK' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINCHK00                                              *
      ****************************************************************
