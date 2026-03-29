       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSCRED0.
      ****************************************************************
      * PROGRAM:  CUSCRED0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - CREDIT PRE-QUALIFICATION                *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PERFORMS CREDIT PRE-QUALIFICATION FOR A CUSTOMER.  *
      *           FETCHES CUSTOMER INCOME, CHECKS FOR EXISTING       *
      *           CREDIT REPORTS. SIMULATES CREDIT BUREAU CALL BY    *
      *           BUILDING REQUEST AND INSERTING CREDIT_CHECK WITH   *
      *           STATUS RQ. FOR DEMO: AUTO-GENERATES CREDIT SCORE   *
      *           BASED ON INCOME BRACKET (>100K=A, >75K=B, >50K=C, *
      *           >35K=D, <35K=E). CALCULATES DTI RATIO IF MONTHLY  *
      *           DEBT INFO AVAILABLE. UPDATES CREDIT_CHECK WITH     *
      *           RESULTS AND SETS EXPIRY (+30 DAYS). RETURNS        *
      *           CREDIT TIER, SCORE, AND MAX FINANCING AMOUNT.      *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSCR - CUSTOMER CREDIT                             *
      * CALLS:    COMFMTL0 - FORMAT CURRENCY                        *
      *           COMLGEL0 - AUDIT LOGGING                           *
      *           COMDBEL0 - DB2 ERROR HANDLING                      *
      * TABLES:   AUTOSALE.CUSTOMER (SELECT)                         *
      *           AUTOSALE.CREDIT_CHECK (SELECT, INSERT, UPDATE)     *
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
                                          VALUE 'CUSCRED0'.
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
           COPY WSAUDIT.
      *
      *    DCLGEN COPIES
      *
           COPY DCLCUSTM.
      *
           COPY DCLCRDCK.
      *
      *    INPUT FIELDS
      *
       01  WS-CRED-INPUT.
           05  WS-CI-FUNCTION            PIC X(02).
               88  WS-CI-CHECK                       VALUE 'CK'.
               88  WS-CI-VIEW                        VALUE 'VW'.
           05  WS-CI-CUST-ID             PIC X(09).
           05  WS-CI-MONTHLY-DEBT        PIC X(09).
           05  WS-CI-BUREAU-CODE         PIC X(02).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-CRED-OUTPUT.
           05  WS-CO-STATUS-LINE.
               10  WS-CO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-CO-MSG-TEXT       PIC X(70).
           05  WS-CO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-CO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- CREDIT PRE-QUALIFICATION ----      '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-CO-CUST-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'CUSTOMER ID: '.
               10  WS-CO-CUST-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'NAME: '.
               10  WS-CO-CUST-NAME      PIC X(40).
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-CO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-CO-INC-LINE.
               10  FILLER               PIC X(16)
                   VALUE 'ANNUAL INCOME:  '.
               10  WS-CO-INCOME         PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(16)
                   VALUE 'MONTHLY INCOME: '.
               10  WS-CO-MONTH-INC      PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(19) VALUE SPACES.
           05  WS-CO-BLANK-3            PIC X(79) VALUE SPACES.
           05  WS-CO-RESULT-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- CREDIT RESULTS ----      '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-CO-TIER-LINE.
               10  FILLER               PIC X(14)
                   VALUE 'CREDIT TIER:  '.
               10  WS-CO-TIER           PIC X(01).
               10  FILLER               PIC X(03) VALUE ' - '.
               10  WS-CO-TIER-DESC      PIC X(20).
               10  FILLER               PIC X(41) VALUE SPACES.
           05  WS-CO-SCORE-LINE.
               10  FILLER               PIC X(14)
                   VALUE 'CREDIT SCORE: '.
               10  WS-CO-SCORE          PIC Z(03)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'BUREAU: '.
               10  WS-CO-BUREAU         PIC X(02).
               10  FILLER               PIC X(45) VALUE SPACES.
           05  WS-CO-DTI-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'DTI RATIO:  '.
               10  WS-CO-DTI            PIC Z9.99.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(14)
                   VALUE 'MONTHLY DEBT: '.
               10  WS-CO-MONTH-DEBT     PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-CO-MAX-LINE.
               10  FILLER               PIC X(24)
                   VALUE 'MAX RECOMMENDED FINANCE:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-CO-MAX-FINANCE    PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(41) VALUE SPACES.
           05  WS-CO-EXPIRY-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'EXPIRY DATE: '.
               10  WS-CO-EXPIRY         PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-CO-STATUS         PIC X(02).
               10  FILLER               PIC X(02) VALUE ' ('.
               10  WS-CO-STATUS-DESC    PIC X(10).
               10  FILLER               PIC X(01) VALUE ')'.
               10  FILLER               PIC X(29) VALUE SPACES.
           05  WS-CO-BLANK-4            PIC X(79) VALUE SPACES.
           05  WS-CO-EXISTING-MSG.
               10  FILLER               PIC X(50)
                   VALUE 'NOTE: EXISTING VALID CREDIT CHECK FOUND
      -               ' - REUSED'.
               10  FILLER               PIC X(29) VALUE SPACES.
           05  WS-CO-FILLER             PIC X(300) VALUE SPACES.
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
      *    LOG CALL FIELDS
      *
       01  WS-LOG-REQUEST.
           05  WS-LOG-FUNCTION          PIC X(04).
           05  WS-LOG-PROGRAM           PIC X(08).
           05  WS-LOG-TABLE             PIC X(18).
           05  WS-LOG-ACTION            PIC X(03).
           05  WS-LOG-KEY               PIC X(40).
           05  WS-LOG-OLD-VAL           PIC X(200).
           05  WS-LOG-NEW-VAL           PIC X(200).
           05  WS-LOG-DESC              PIC X(80).
       01  WS-LOG-RESULT.
           05  WS-LOG-RC                PIC S9(04) COMP.
      *
      *    DB ERROR CALL FIELDS
      *
       01  WS-DBERR-REQUEST.
           05  WS-DBERR-FUNCTION        PIC X(04).
           05  WS-DBERR-PROGRAM         PIC X(08).
           05  WS-DBERR-SQLCODE         PIC S9(09) COMP.
           05  WS-DBERR-TABLE           PIC X(18).
           05  WS-DBERR-OPERATION       PIC X(10).
       01  WS-DBERR-RESULT.
           05  WS-DBERR-RC              PIC S9(04) COMP.
           05  WS-DBERR-MSG             PIC X(70).
      *
      *    WORKING FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-CUST-ID-NUM           PIC S9(09) COMP VALUE +0.
           05  WS-CREDIT-ID             PIC S9(09) COMP VALUE +0.
           05  WS-ANNUAL-INCOME         PIC S9(09)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-MONTHLY-INCOME        PIC S9(07)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-MONTHLY-DEBT          PIC S9(07)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-DTI-RATIO             PIC S9(03)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-CREDIT-SCORE          PIC S9(04) COMP VALUE +0.
           05  WS-CREDIT-TIER           PIC X(01)  VALUE SPACES.
           05  WS-MAX-FINANCE           PIC S9(09)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-EXISTING-FOUND        PIC X(01)  VALUE 'N'.
               88  WS-HAS-EXISTING                   VALUE 'Y'.
               88  WS-NO-EXISTING                    VALUE 'N'.
           05  WS-CUST-FIRST            PIC X(30)  VALUE SPACES.
           05  WS-CUST-LAST             PIC X(30)  VALUE SPACES.
           05  WS-BUREAU-CODE           PIC X(02)  VALUE 'EQ'.
           05  WS-EXPIRY-DATE           PIC X(10)  VALUE SPACES.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-INCOME             PIC S9(04) COMP VALUE +0.
           05  WS-NI-SCORE              PIC S9(04) COMP VALUE +0.
           05  WS-NI-TIER               PIC S9(04) COMP VALUE +0.
           05  WS-NI-RESPONSE-TS        PIC S9(04) COMP VALUE +0.
           05  WS-NI-MONTH-DEBT         PIC S9(04) COMP VALUE +0.
           05  WS-NI-MONTH-INC          PIC S9(04) COMP VALUE +0.
           05  WS-NI-DTI                PIC S9(04) COMP VALUE +0.
           05  WS-NI-EXPIRY             PIC S9(04) COMP VALUE +0.
      *
      *    EXISTING CREDIT CHECK FIELDS
      *
       01  WS-EXIST-CHECK.
           05  WS-EC-CREDIT-ID          PIC S9(09) COMP.
           05  WS-EC-SCORE              PIC S9(04) COMP.
           05  WS-EC-TIER               PIC X(01).
           05  WS-EC-DTI                PIC S9(03)V9(2) COMP-3.
           05  WS-EC-STATUS             PIC X(02).
           05  WS-EC-EXPIRY             PIC X(10).
           05  WS-EC-MONTH-DEBT         PIC S9(07)V9(2) COMP-3.
           05  WS-EC-MONTH-INC          PIC S9(07)V9(2) COMP-3.
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
               PERFORM 4000-FETCH-CUSTOMER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-CHECK-EXISTING-CREDIT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               AND WS-NO-EXISTING
               PERFORM 6000-SIMULATE-CREDIT-CHECK
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-FORMAT-OUTPUT
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
           INITIALIZE WS-CRED-OUTPUT
           MOVE 'CUSCRED0' TO WS-CO-MSG-ID
           MOVE 'N' TO WS-EXISTING-FOUND
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
                   TO WS-CO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION      TO WS-CI-FUNCTION
               MOVE WS-INP-KEY-DATA(1:9) TO WS-CI-CUST-ID
               MOVE WS-INP-BODY(1:9)     TO WS-CI-MONTHLY-DEBT
               MOVE WS-INP-BODY(10:2)    TO WS-CI-BUREAU-CODE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-CI-FUNCTION = SPACES
               MOVE 'CK' TO WS-CI-FUNCTION
           END-IF
      *
           IF WS-CI-CUST-ID = SPACES OR ZEROS
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER ID IS REQUIRED' TO WS-CO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           COMPUTE WS-CUST-ID-NUM =
               FUNCTION NUMVAL(WS-CI-CUST-ID)
      *
      *    SET BUREAU CODE (DEFAULT EQ=EQUIFAX)
      *
           IF WS-CI-BUREAU-CODE NOT = SPACES
               MOVE WS-CI-BUREAU-CODE TO WS-BUREAU-CODE
           ELSE
               MOVE 'EQ' TO WS-BUREAU-CODE
           END-IF
      *
      *    PARSE MONTHLY DEBT IF PROVIDED
      *
           IF WS-CI-MONTHLY-DEBT NOT = SPACES
               AND WS-CI-MONTHLY-DEBT NOT = ZEROS
               COMPUTE WS-MONTHLY-DEBT =
                   FUNCTION NUMVAL(WS-CI-MONTHLY-DEBT)
           ELSE
               MOVE +0 TO WS-MONTHLY-DEBT
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-FETCH-CUSTOMER - GET INCOME AND NAME                 *
      ****************************************************************
       4000-FETCH-CUSTOMER.
      *
           EXEC SQL
               SELECT FIRST_NAME
                    , LAST_NAME
                    , ANNUAL_INCOME
               INTO  :WS-CUST-FIRST
                   , :WS-CUST-LAST
                   , :WS-ANNUAL-INCOME
                              :WS-NI-INCOME
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-CO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON CUSTOMER LOOKUP'
                   TO WS-CO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    COMPUTE MONTHLY INCOME
      *
           IF WS-NI-INCOME >= +0 AND WS-ANNUAL-INCOME > +0
               COMPUTE WS-MONTHLY-INCOME =
                   WS-ANNUAL-INCOME / 12
           ELSE
               MOVE +0 TO WS-MONTHLY-INCOME
               MOVE +0 TO WS-ANNUAL-INCOME
           END-IF
      *
           MOVE WS-CUST-ID-NUM TO WS-CO-CUST-ID
           STRING WS-CUST-LAST  DELIMITED BY '  '
                  ', '           DELIMITED BY SIZE
                  WS-CUST-FIRST  DELIMITED BY '  '
               INTO WS-CO-CUST-NAME
           END-STRING
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-CHECK-EXISTING-CREDIT - LOOK FOR VALID RECENT CHECK  *
      ****************************************************************
       5000-CHECK-EXISTING-CREDIT.
      *
           EXEC SQL
               SELECT CREDIT_ID
                    , CREDIT_SCORE
                    , CREDIT_TIER
                    , DTI_RATIO
                    , STATUS
                    , EXPIRY_DATE
                    , MONTHLY_DEBT
                    , MONTHLY_INCOME
               INTO  :WS-EC-CREDIT-ID
                   , :WS-EC-SCORE
                              :WS-NI-SCORE
                   , :WS-EC-TIER
                              :WS-NI-TIER
                   , :WS-EC-DTI
                              :WS-NI-DTI
                   , :WS-EC-STATUS
                   , :WS-EC-EXPIRY
                              :WS-NI-EXPIRY
                   , :WS-EC-MONTH-DEBT
                              :WS-NI-MONTH-DEBT
                   , :WS-EC-MONTH-INC
                              :WS-NI-MONTH-INC
               FROM   AUTOSALE.CREDIT_CHECK
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
                 AND  STATUS      = 'AP'
                 AND  EXPIRY_DATE >= CURRENT DATE
               ORDER BY REQUEST_TS DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +0
      *        VALID EXISTING CHECK FOUND
               MOVE 'Y' TO WS-EXISTING-FOUND
               MOVE WS-EC-CREDIT-ID   TO WS-CREDIT-ID
               IF WS-NI-SCORE >= +0
                   MOVE WS-EC-SCORE    TO WS-CREDIT-SCORE
               END-IF
               IF WS-NI-TIER >= +0
                   MOVE WS-EC-TIER     TO WS-CREDIT-TIER
               END-IF
               IF WS-NI-DTI >= +0
                   MOVE WS-EC-DTI      TO WS-DTI-RATIO
               END-IF
               IF WS-NI-EXPIRY >= +0
                   MOVE WS-EC-EXPIRY   TO WS-EXPIRY-DATE
               END-IF
               IF WS-NI-MONTH-DEBT >= +0
                   MOVE WS-EC-MONTH-DEBT TO WS-MONTHLY-DEBT
               END-IF
               IF WS-NI-MONTH-INC >= +0
                   MOVE WS-EC-MONTH-INC  TO WS-MONTHLY-INCOME
               END-IF
      *
      *        COMPUTE MAX FINANCE FROM EXISTING DATA
      *
               PERFORM 6500-COMPUTE-MAX-FINANCE
           END-IF
           .
      *
      ****************************************************************
      *    6000-SIMULATE-CREDIT-CHECK                                *
      ****************************************************************
       6000-SIMULATE-CREDIT-CHECK.
      *
      *    STEP 1: INSERT REQUEST RECORD WITH STATUS RQ
      *
           EXEC SQL
               INSERT INTO AUTOSALE.CREDIT_CHECK
               ( CUSTOMER_ID
               , BUREAU_CODE
               , REQUEST_TS
               , STATUS
               )
               VALUES
               ( :WS-CUST-ID-NUM
               , :WS-BUREAU-CODE
               , CURRENT TIMESTAMP
               , 'RQ'
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSCRED0'          TO WS-DBERR-PROGRAM
               MOVE 'CREDIT_CHECK'      TO WS-DBERR-TABLE
               MOVE 'INSERT'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-CO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    GET AUTO-GENERATED CREDIT ID
      *
           EXEC SQL
               SELECT IDENTITY_VAL_LOCAL()
               INTO   :WS-CREDIT-ID
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    STEP 2: SIMULATE CREDIT SCORE BASED ON INCOME
      *    >100K=A (800), >75K=B (720), >50K=C (660),
      *    >35K=D (600), <35K=E (520)
      *
           EVALUATE TRUE
               WHEN WS-ANNUAL-INCOME > 100000
                   MOVE 'A' TO WS-CREDIT-TIER
                   MOVE +800 TO WS-CREDIT-SCORE
               WHEN WS-ANNUAL-INCOME > 75000
                   MOVE 'B' TO WS-CREDIT-TIER
                   MOVE +720 TO WS-CREDIT-SCORE
               WHEN WS-ANNUAL-INCOME > 50000
                   MOVE 'C' TO WS-CREDIT-TIER
                   MOVE +660 TO WS-CREDIT-SCORE
               WHEN WS-ANNUAL-INCOME > 35000
                   MOVE 'D' TO WS-CREDIT-TIER
                   MOVE +600 TO WS-CREDIT-SCORE
               WHEN OTHER
                   MOVE 'E' TO WS-CREDIT-TIER
                   MOVE +520 TO WS-CREDIT-SCORE
           END-EVALUATE
      *
      *    STEP 3: CALCULATE DTI IF MONTHLY DEBT AVAILABLE
      *
           IF WS-MONTHLY-DEBT > +0 AND WS-MONTHLY-INCOME > +0
               COMPUTE WS-DTI-RATIO =
                   (WS-MONTHLY-DEBT / WS-MONTHLY-INCOME)
                   * 100
           ELSE
               MOVE +0 TO WS-DTI-RATIO
           END-IF
      *
      *    STEP 4: COMPUTE MAX FINANCING
      *
           PERFORM 6500-COMPUTE-MAX-FINANCE
      *
      *    STEP 5: UPDATE CREDIT_CHECK WITH RESULTS
      *
           IF WS-MONTHLY-DEBT > +0
               MOVE +0 TO WS-NI-MONTH-DEBT
           ELSE
               MOVE -1 TO WS-NI-MONTH-DEBT
           END-IF
      *
           IF WS-MONTHLY-INCOME > +0
               MOVE +0 TO WS-NI-MONTH-INC
           ELSE
               MOVE -1 TO WS-NI-MONTH-INC
           END-IF
      *
           IF WS-DTI-RATIO > +0
               MOVE +0 TO WS-NI-DTI
           ELSE
               MOVE -1 TO WS-NI-DTI
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.CREDIT_CHECK
               SET    CREDIT_SCORE   = :WS-CREDIT-SCORE
                    , CREDIT_TIER    = :WS-CREDIT-TIER
                    , RESPONSE_TS    = CURRENT TIMESTAMP
                    , STATUS         = 'AP'
                    , MONTHLY_DEBT   = :WS-MONTHLY-DEBT
                                        :WS-NI-MONTH-DEBT
                    , MONTHLY_INCOME = :WS-MONTHLY-INCOME
                                        :WS-NI-MONTH-INC
                    , DTI_RATIO      = :WS-DTI-RATIO
                                        :WS-NI-DTI
                    , EXPIRY_DATE    = CURRENT DATE + 30 DAYS
               WHERE  CREDIT_ID = :WS-CREDIT-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSCRED0'          TO WS-DBERR-PROGRAM
               MOVE 'CREDIT_CHECK'      TO WS-DBERR-TABLE
               MOVE 'UPDATE'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-CO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    GET EXPIRY DATE
      *
           EXEC SQL
               SELECT CHAR(CURRENT DATE + 30 DAYS, ISO)
               INTO   :WS-EXPIRY-DATE
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    AUDIT LOG
      *
           MOVE 'LOGW'        TO WS-LOG-FUNCTION
           MOVE 'CUSCRED0'    TO WS-LOG-PROGRAM
           MOVE 'CREDIT_CHECK' TO WS-LOG-TABLE
           MOVE 'INS'         TO WS-LOG-ACTION
           MOVE WS-CREDIT-ID  TO WS-LOG-KEY
           MOVE SPACES         TO WS-LOG-OLD-VAL
           STRING 'CUST=' DELIMITED BY SIZE
                  WS-CI-CUST-ID    DELIMITED BY '  '
                  ' TIER=' DELIMITED BY SIZE
                  WS-CREDIT-TIER   DELIMITED BY SIZE
                  ' SCORE=' DELIMITED BY SIZE
                  WS-CREDIT-SCORE  DELIMITED BY SIZE
               INTO WS-LOG-NEW-VAL
           END-STRING
           MOVE 'CREDIT PRE-QUALIFICATION COMPLETED'
               TO WS-LOG-DESC
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
                                  WS-LOG-RESULT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6500-COMPUTE-MAX-FINANCE                                  *
      ****************************************************************
       6500-COMPUTE-MAX-FINANCE.
      *
      *    MAX FINANCING BASED ON TIER:
      *    A=5x INCOME, B=4x, C=3x, D=2x, E=1x
      *
           EVALUATE WS-CREDIT-TIER
               WHEN 'A'
                   COMPUTE WS-MAX-FINANCE =
                       WS-ANNUAL-INCOME * 5
               WHEN 'B'
                   COMPUTE WS-MAX-FINANCE =
                       WS-ANNUAL-INCOME * 4
               WHEN 'C'
                   COMPUTE WS-MAX-FINANCE =
                       WS-ANNUAL-INCOME * 3
               WHEN 'D'
                   COMPUTE WS-MAX-FINANCE =
                       WS-ANNUAL-INCOME * 2
               WHEN 'E'
                   COMPUTE WS-MAX-FINANCE =
                       WS-ANNUAL-INCOME * 1
               WHEN OTHER
                   MOVE +0 TO WS-MAX-FINANCE
           END-EVALUATE
      *
      *    ADJUST MAX FINANCE BY DTI IF APPLICABLE
      *    IF DTI > 50%, REDUCE BY 25%
      *    IF DTI > 40%, REDUCE BY 10%
      *
           IF WS-DTI-RATIO > 50
               COMPUTE WS-MAX-FINANCE =
                   WS-MAX-FINANCE * 0.75
           ELSE
               IF WS-DTI-RATIO > 40
                   COMPUTE WS-MAX-FINANCE =
                       WS-MAX-FINANCE * 0.90
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    7000-FORMAT-OUTPUT                                        *
      ****************************************************************
       7000-FORMAT-OUTPUT.
      *
           MOVE WS-ANNUAL-INCOME  TO WS-CO-INCOME
           MOVE WS-MONTHLY-INCOME TO WS-CO-MONTH-INC
           MOVE WS-CREDIT-TIER    TO WS-CO-TIER
           MOVE WS-CREDIT-SCORE   TO WS-CO-SCORE
           MOVE WS-BUREAU-CODE    TO WS-CO-BUREAU
           MOVE WS-DTI-RATIO      TO WS-CO-DTI
           MOVE WS-MONTHLY-DEBT   TO WS-CO-MONTH-DEBT
           MOVE WS-MAX-FINANCE    TO WS-CO-MAX-FINANCE
           MOVE WS-EXPIRY-DATE    TO WS-CO-EXPIRY
      *
      *    TIER DESCRIPTION
      *
           EVALUATE WS-CREDIT-TIER
               WHEN 'A'
                   MOVE 'EXCELLENT           ' TO WS-CO-TIER-DESC
               WHEN 'B'
                   MOVE 'GOOD                ' TO WS-CO-TIER-DESC
               WHEN 'C'
                   MOVE 'FAIR                ' TO WS-CO-TIER-DESC
               WHEN 'D'
                   MOVE 'BELOW AVERAGE       ' TO WS-CO-TIER-DESC
               WHEN 'E'
                   MOVE 'POOR                ' TO WS-CO-TIER-DESC
               WHEN OTHER
                   MOVE 'UNKNOWN             ' TO WS-CO-TIER-DESC
           END-EVALUATE
      *
      *    STATUS DESCRIPTION
      *
           IF WS-HAS-EXISTING
               MOVE 'AP' TO WS-CO-STATUS
               MOVE 'APPROVED  ' TO WS-CO-STATUS-DESC
           ELSE
               MOVE 'AP' TO WS-CO-STATUS
               MOVE 'APPROVED  ' TO WS-CO-STATUS-DESC
           END-IF
      *
      *    EXISTING CHECK MESSAGE
      *
           IF WS-HAS-EXISTING
               MOVE 'VALID CREDIT CHECK ON FILE - RESULTS REUSED'
                   TO WS-CO-MSG-TEXT
           ELSE
               MOVE 'CREDIT PRE-QUALIFICATION COMPLETE'
                   TO WS-CO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-CRED-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'CSCR' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSCRED0                                              *
      ****************************************************************
