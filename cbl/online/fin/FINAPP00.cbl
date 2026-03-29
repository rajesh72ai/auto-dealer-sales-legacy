       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINAPP00.
      ****************************************************************
      * PROGRAM:  FINAPP00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - FINANCE APPLICATION CAPTURE              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CAPTURES FINANCE APPLICATION FOR A SALES DEAL.     *
      *           SUPPORTS THREE FINANCE TYPES:                      *
      *             L = LOAN  (VALIDATES APR/TERM, CALC PAYMENT)     *
      *             S = LEASE (REDIRECTS TO LEASE-SPECIFIC PROCESS)  *
      *             C = CASH  (MINIMAL - RECORDS FINANCE TYPE ONLY)  *
      *           VALIDATES DEAL EXISTS WITH STATUS AP (APPROVED).   *
      *           GENERATES FINANCE ID VIA COMSEQL0.                 *
      *           INSERTS FINANCE_APP RECORD WITH STATUS NW (NEW).   *
      *           UPDATES SALES_DEAL STATUS TO FI (IN F AND I).      *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNAP - FINANCE APPLICATION                         *
      * CALLS:    COMLONL0 - LOAN CALCULATION                       *
      *           COMSEQL0 - SEQUENCE NUMBER GENERATOR               *
      *           COMFMTL0 - FIELD FORMATTING                       *
      *           COMLGEL0 - AUDIT LOGGING                          *
      *           COMDBEL0 - DB2 ERROR HANDLER                      *
      * TABLES:   AUTOSALE.SALES_DEAL                                *
      *           AUTOSALE.FINANCE_APP                                *
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
                                          VALUE 'FINAPP00'.
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
           COPY DCLSLDEL.
      *
           COPY DCLFINAP.
      *
      *    INPUT FIELDS
      *
       01  WS-APP-INPUT.
           05  WS-AI-DEAL-NUMBER         PIC X(10).
           05  WS-AI-FINANCE-TYPE        PIC X(01).
               88  WS-AI-TYPE-LOAN                   VALUE 'L'.
               88  WS-AI-TYPE-LEASE                  VALUE 'S'.
               88  WS-AI-TYPE-CASH                   VALUE 'C'.
           05  WS-AI-LENDER-CODE         PIC X(05).
           05  WS-AI-AMOUNT              PIC X(11).
           05  WS-AI-APR                 PIC X(06).
           05  WS-AI-TERM                PIC X(03).
           05  WS-AI-DOWN-PAYMENT        PIC X(11).
      *
      *    NUMERIC CONVERTED FIELDS
      *
       01  WS-NUM-FIELDS.
           05  WS-NUM-AMOUNT             PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-APR                PIC S9(03)V9(04) COMP-3
                                                       VALUE +0.
           05  WS-NUM-TERM               PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-NUM-DOWN-PMT           PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-APP-OUTPUT.
           05  WS-AO-STATUS-LINE.
               10  WS-AO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-MSG-TEXT       PIC X(70).
           05  WS-AO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-AO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- FINANCE APPLICATION CAPTURE ---- '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-AO-FIN-ID-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'FINANCE ID: '.
               10  WS-AO-FINANCE-ID     PIC X(12).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-AO-APP-STATUS     PIC X(02).
               10  FILLER               PIC X(40) VALUE SPACES.
           05  WS-AO-DEAL-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'DEAL:       '.
               10  WS-AO-DEAL-NUMBER    PIC X(10).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06)
                   VALUE 'TYPE: '.
               10  WS-AO-FIN-TYPE       PIC X(05).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'LENDER: '.
               10  WS-AO-LENDER         PIC X(05).
               10  FILLER               PIC X(23) VALUE SPACES.
           05  WS-AO-AMOUNT-LINE.
               10  FILLER               PIC X(18)
                   VALUE 'AMOUNT REQUESTED: '.
               10  WS-AO-AMT-REQ       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(06)
                   VALUE 'DOWN: '.
               10  WS-AO-DOWN-PMT      PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(22) VALUE SPACES.
           05  WS-AO-TERMS-LINE.
               10  FILLER               PIC X(05) VALUE 'APR: '.
               10  WS-AO-APR           PIC ZZ9.999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TERM: '.
               10  WS-AO-TERM          PIC Z(02)9.
               10  FILLER               PIC X(07)
                   VALUE ' MONTHS'.
               10  FILLER               PIC X(42) VALUE SPACES.
           05  WS-AO-PAYMENT-LINE.
               10  FILLER               PIC X(17)
                   VALUE 'MONTHLY PAYMENT: '.
               10  WS-AO-MONTHLY-PMT   PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(17)
                   VALUE 'TOTAL PAYMENTS: '.
               10  WS-AO-TOTAL-PMT     PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(15) VALUE SPACES.
           05  WS-AO-INTEREST-LINE.
               10  FILLER               PIC X(17)
                   VALUE 'TOTAL INTEREST:  '.
               10  WS-AO-TOTAL-INT     PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-AO-FILLER             PIC X(79) VALUE SPACES.
      *
      *    LOAN CALCULATION CALL FIELDS
      *
       01  WS-LOAN-REQUEST.
           05  WS-LN-FUNCTION           PIC X(04).
           05  WS-LN-PRINCIPAL          PIC S9(09)V99 COMP-3.
           05  WS-LN-APR                PIC S9(03)V9(04) COMP-3.
           05  WS-LN-TERM-MONTHS        PIC S9(04)    COMP.
           05  WS-LN-DEALER-CODE        PIC X(05).
           05  WS-LN-VIN                PIC X(17).
      *
       01  WS-LOAN-RESULT.
           05  WS-LR-RETURN-CODE        PIC S9(04)    COMP.
           05  WS-LR-RETURN-MSG         PIC X(79).
           05  WS-LR-MONTHLY-PMT        PIC S9(07)V99 COMP-3.
           05  WS-LR-TOTAL-PAYMENTS     PIC S9(09)V99 COMP-3.
           05  WS-LR-TOTAL-INTEREST     PIC S9(09)V99 COMP-3.
           05  WS-LR-MONTHLY-RATE       PIC S9(01)V9(08) COMP-3.
           05  WS-LR-AMORT-MONTHS       PIC S9(04)    COMP.
           05  WS-LR-AMORT-TABLE.
               10  WS-LR-AMORT-ENTRY    OCCURS 12 TIMES.
                   15  WS-AM-MONTH-NUM  PIC S9(04)    COMP.
                   15  WS-AM-PAYMENT    PIC S9(07)V99 COMP-3.
                   15  WS-AM-PRINCIPAL  PIC S9(07)V99 COMP-3.
                   15  WS-AM-INTEREST   PIC S9(07)V99 COMP-3.
                   15  WS-AM-CUM-INT    PIC S9(09)V99 COMP-3.
                   15  WS-AM-BALANCE    PIC S9(09)V99 COMP-3.
      *
      *    SEQUENCE GENERATOR CALL FIELDS
      *
       01  WS-SEQ-REQUEST.
           05  WS-SR-SEQ-TYPE           PIC X(04).
           05  WS-SR-DEALER-CODE        PIC X(05).
           05  WS-SR-USER-ID            PIC X(08).
       01  WS-SEQ-RESULT.
           05  WS-SQ-RETURN-CODE        PIC S9(04)    COMP.
           05  WS-SQ-RETURN-MSG         PIC X(79).
           05  WS-SQ-RAW-NUMBER         PIC S9(09)    COMP.
           05  WS-SQ-FORMATTED-NUM      PIC X(07).
           05  WS-SQ-SQLCODE            PIC S9(09)    COMP.
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
       01  WS-AUD-PROGRAM-ID           PIC X(08) VALUE 'FINAPP00'.
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
       01  WS-DBE-PROGRAM-NAME         PIC X(08) VALUE 'FINAPP00'.
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
       01  WS-GENERATED-FIN-ID         PIC X(12) VALUE SPACES.
      *
      *    TIMESTAMP
      *
       01  WS-CURRENT-TS               PIC X(26) VALUE SPACES.
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
           05  WS-NI-LENDER-CODE       PIC S9(04) COMP VALUE +0.
           05  WS-NI-LENDER-NAME       PIC S9(04) COMP VALUE -1.
           05  WS-NI-AMOUNT-APVD       PIC S9(04) COMP VALUE -1.
           05  WS-NI-APR-REQ           PIC S9(04) COMP VALUE +0.
           05  WS-NI-APR-APVD          PIC S9(04) COMP VALUE -1.
           05  WS-NI-TERM              PIC S9(04) COMP VALUE +0.
           05  WS-NI-MONTHLY-PMT       PIC S9(04) COMP VALUE -1.
           05  WS-NI-CREDIT-TIER       PIC S9(04) COMP VALUE -1.
           05  WS-NI-STIPULATIONS      PIC S9(04) COMP VALUE -1.
           05  WS-NI-SUBMITTED-TS      PIC S9(04) COMP VALUE +0.
           05  WS-NI-DECISION-TS       PIC S9(04) COMP VALUE -1.
           05  WS-NI-FUNDED-TS         PIC S9(04) COMP VALUE -1.
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
               PERFORM 4000-VALIDATE-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-PROCESS-FINANCE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-GENERATE-FINANCE-ID
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-INSERT-FINANCE-APP
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7500-UPDATE-DEAL-STATUS
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
           INITIALIZE WS-APP-OUTPUT
           INITIALIZE WS-APP-INPUT
           INITIALIZE WS-NUM-FIELDS
           MOVE 'FINAPP00' TO WS-AO-MSG-ID
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
                   TO WS-AO-MSG-TEXT
           ELSE
               MOVE WS-INP-KEY-DATA(1:10)
                   TO WS-AI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:1)
                   TO WS-AI-FINANCE-TYPE
               MOVE WS-INP-BODY(2:5)
                   TO WS-AI-LENDER-CODE
               MOVE WS-INP-BODY(7:11)
                   TO WS-AI-AMOUNT
               MOVE WS-INP-BODY(18:6)
                   TO WS-AI-APR
               MOVE WS-INP-BODY(24:3)
                   TO WS-AI-TERM
               MOVE WS-INP-BODY(27:11)
                   TO WS-AI-DOWN-PAYMENT
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-AI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF NOT WS-AI-TYPE-LOAN
           AND NOT WS-AI-TYPE-LEASE
           AND NOT WS-AI-TYPE-CASH
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FINANCE TYPE MUST BE L(LOAN) S(LEASE) C(CASH)'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    CONVERT NUMERIC FIELDS
      *
           IF WS-AI-AMOUNT NOT = SPACES
               COMPUTE WS-NUM-AMOUNT =
                   FUNCTION NUMVAL(WS-AI-AMOUNT)
               END-COMPUTE
           END-IF
      *
           IF WS-AI-APR NOT = SPACES
               COMPUTE WS-NUM-APR =
                   FUNCTION NUMVAL(WS-AI-APR)
               END-COMPUTE
           END-IF
      *
           IF WS-AI-TERM NOT = SPACES
               COMPUTE WS-NUM-TERM =
                   FUNCTION NUMVAL(WS-AI-TERM)
               END-COMPUTE
           END-IF
      *
           IF WS-AI-DOWN-PAYMENT NOT = SPACES
               COMPUTE WS-NUM-DOWN-PMT =
                   FUNCTION NUMVAL(WS-AI-DOWN-PAYMENT)
               END-COMPUTE
           END-IF
      *
      *    LOAN-SPECIFIC VALIDATIONS
      *
           IF WS-AI-TYPE-LOAN
               IF WS-NUM-APR < +0 OR WS-NUM-APR > +30.0000
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOAN APR MUST BE 0 - 30 PERCENT'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-NUM-TERM < +12 OR WS-NUM-TERM > +84
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOAN TERM MUST BE 12 - 84 MONTHS'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    NON-CASH REQUIRES LENDER
      *
           IF NOT WS-AI-TYPE-CASH
               IF WS-AI-LENDER-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LENDER CODE REQUIRED FOR LOAN OR LEASE'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-VALIDATE-DEAL - DEAL MUST EXIST AND BE APPROVED      *
      ****************************************************************
       4000-VALIDATE-DEAL.
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEALER_CODE
                    , CUSTOMER_ID
                    , VIN
                    , DEAL_STATUS
                    , TOTAL_PRICE
                    , DOWN_PAYMENT
                    , AMOUNT_FINANCED
               INTO  :DEAL-NUMBER    OF DCLSALES-DEAL
                    , :DEALER-CODE   OF DCLSALES-DEAL
                    , :CUSTOMER-ID   OF DCLSALES-DEAL
                    , :VIN           OF DCLSALES-DEAL
                    , :DEAL-STATUS   OF DCLSALES-DEAL
                    , :TOTAL-PRICE   OF DCLSALES-DEAL
                    , :DOWN-PAYMENT  OF DCLSALES-DEAL
                    , :AMOUNT-FINANCED OF DCLSALES-DEAL
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-AI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NOT FOUND' TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE '4000-VALIDATE-DEAL' TO WS-DBE-SECTION-NAME
               MOVE 'SALES_DEAL'         TO WS-DBE-TABLE-NAME
               MOVE 'SELECT'             TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON DEAL LOOKUP'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF DEAL-STATUS OF DCLSALES-DEAL NOT = 'AP'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL MUST BE IN AP (APPROVED) STATUS FOR F&I'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    DEFAULT AMOUNT TO DEAL AMOUNT FINANCED IF NOT PROVIDED
      *
           IF WS-NUM-AMOUNT = +0
               MOVE AMOUNT-FINANCED OF DCLSALES-DEAL
                   TO WS-NUM-AMOUNT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-FINANCE - TYPE-SPECIFIC PROCESSING           *
      ****************************************************************
       5000-PROCESS-FINANCE.
      *
           EVALUATE TRUE
               WHEN WS-AI-TYPE-CASH
                   PERFORM 5100-PROCESS-CASH
               WHEN WS-AI-TYPE-LOAN
                   PERFORM 5200-PROCESS-LOAN
               WHEN WS-AI-TYPE-LEASE
                   PERFORM 5300-PROCESS-LEASE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5100-PROCESS-CASH - MINIMAL PROCESSING FOR CASH DEAL      *
      ****************************************************************
       5100-PROCESS-CASH.
      *
           MOVE 'CASH'  TO WS-AO-FIN-TYPE
           MOVE SPACES  TO WS-AO-LENDER
           MOVE +0      TO WS-NI-LENDER-CODE
           MOVE -1      TO WS-NI-APR-REQ
           MOVE -1      TO WS-NI-TERM
           MOVE -1      TO WS-NI-MONTHLY-PMT
           MOVE 'CASH DEAL - NO FINANCING REQUIRED'
               TO WS-AO-MSG-TEXT
           .
      *
      ****************************************************************
      *    5200-PROCESS-LOAN - CALCULATE LOAN PAYMENT                *
      ****************************************************************
       5200-PROCESS-LOAN.
      *
           MOVE 'LOAN'  TO WS-AO-FIN-TYPE
           MOVE WS-AI-LENDER-CODE TO WS-AO-LENDER
      *
      *    SUBTRACT DOWN PAYMENT FROM AMOUNT FOR PRINCIPAL
      *
           IF WS-NUM-DOWN-PMT > +0
               COMPUTE WS-LN-PRINCIPAL =
                   WS-NUM-AMOUNT - WS-NUM-DOWN-PMT
               END-COMPUTE
           ELSE
               MOVE WS-NUM-AMOUNT TO WS-LN-PRINCIPAL
           END-IF
      *
           MOVE 'CALC'           TO WS-LN-FUNCTION
           MOVE WS-NUM-APR      TO WS-LN-APR
           MOVE WS-NUM-TERM     TO WS-LN-TERM-MONTHS
           MOVE DEALER-CODE OF DCLSALES-DEAL
                                 TO WS-LN-DEALER-CODE
           MOVE VIN OF DCLSALES-DEAL
                                 TO WS-LN-VIN
      *
           CALL 'COMLONL0' USING WS-LOAN-REQUEST
                                  WS-LOAN-RESULT
      *
           IF WS-LR-RETURN-CODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-LR-RETURN-MSG TO WS-AO-MSG-TEXT
               GO TO 5200-EXIT
           END-IF
      *
      *    FORMAT OUTPUT
      *
           MOVE WS-NUM-AMOUNT   TO WS-AO-AMT-REQ
           MOVE WS-NUM-DOWN-PMT TO WS-AO-DOWN-PMT
           MOVE WS-NUM-APR      TO WS-AO-APR
           MOVE WS-NUM-TERM     TO WS-AO-TERM
           MOVE WS-LR-MONTHLY-PMT   TO WS-AO-MONTHLY-PMT
           MOVE WS-LR-TOTAL-PAYMENTS TO WS-AO-TOTAL-PMT
           MOVE WS-LR-TOTAL-INTEREST TO WS-AO-TOTAL-INT
      *
           MOVE +0 TO WS-NI-APR-REQ
           MOVE +0 TO WS-NI-TERM
           MOVE +0 TO WS-NI-MONTHLY-PMT
           .
       5200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5300-PROCESS-LEASE - REDIRECT TO LEASE PROCESSING         *
      ****************************************************************
       5300-PROCESS-LEASE.
      *
           MOVE 'LEASE' TO WS-AO-FIN-TYPE
           MOVE WS-AI-LENDER-CODE TO WS-AO-LENDER
           MOVE WS-NUM-AMOUNT     TO WS-AO-AMT-REQ
           MOVE WS-NUM-DOWN-PMT   TO WS-AO-DOWN-PMT
      *
      *    LEASE DETAILS HANDLED BY FINLSE00 - MARK FOR LEASE CALC
      *
           MOVE -1 TO WS-NI-APR-REQ
           MOVE +0 TO WS-NI-TERM
           MOVE -1 TO WS-NI-MONTHLY-PMT
           .
      *
      ****************************************************************
      *    6000-GENERATE-FINANCE-ID VIA COMSEQL0                     *
      ****************************************************************
       6000-GENERATE-FINANCE-ID.
      *
           MOVE 'FIN ' TO WS-SR-SEQ-TYPE
           MOVE DEALER-CODE OF DCLSALES-DEAL
               TO WS-SR-DEALER-CODE
           MOVE IO-PCB-USER-ID TO WS-SR-USER-ID
      *
           CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                  WS-SEQ-RESULT
      *
           IF WS-SQ-RETURN-CODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'FAILED TO GENERATE FINANCE ID'
                   TO WS-AO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    BUILD 12-CHAR FINANCE ID: DEALER + F-NNNNN
      *
           STRING DEALER-CODE OF DCLSALES-DEAL
                  WS-SQ-FORMATTED-NUM
                  DELIMITED BY SIZE
                  INTO WS-GENERATED-FIN-ID
      *
           MOVE WS-GENERATED-FIN-ID TO WS-AO-FINANCE-ID
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-INSERT-FINANCE-APP RECORD                            *
      ****************************************************************
       7000-INSERT-FINANCE-APP.
      *
           MOVE WS-GENERATED-FIN-ID  TO FINANCE-ID
           MOVE WS-AI-DEAL-NUMBER    TO DEAL-NUMBER
                                        OF DCLFINANCE-APP
           MOVE CUSTOMER-ID OF DCLSALES-DEAL
                                      TO CUSTOMER-ID
                                        OF DCLFINANCE-APP
           MOVE WS-AI-FINANCE-TYPE   TO FINANCE-TYPE
           MOVE WS-AI-LENDER-CODE    TO LENDER-CODE
           MOVE 'NW'                 TO APP-STATUS
           MOVE WS-NUM-AMOUNT        TO AMOUNT-REQUESTED
           MOVE +0                   TO AMOUNT-APPROVED
           MOVE WS-NUM-APR           TO APR-REQUESTED
           MOVE +0                   TO APR-APPROVED
           MOVE WS-NUM-TERM          TO TERM-MONTHS
                                        OF DCLFINANCE-APP
           MOVE WS-LR-MONTHLY-PMT   TO MONTHLY-PAYMENT
           MOVE WS-NUM-DOWN-PMT     TO DOWN-PAYMENT
                                        OF DCLFINANCE-APP
           MOVE SPACES               TO CREDIT-TIER
                                        OF DCLFINANCE-APP
           MOVE +0                   TO STIPULATIONS-LN
           MOVE SPACES               TO STIPULATIONS-TX
           MOVE WS-CURRENT-TS       TO SUBMITTED-TS
           MOVE WS-CURRENT-TS       TO CREATED-TS
                                        OF DCLFINANCE-APP
           MOVE WS-CURRENT-TS       TO UPDATED-TS
                                        OF DCLFINANCE-APP
           MOVE +0                   TO LENDER-NAME-LN
           MOVE SPACES               TO LENDER-NAME-TX
      *
           EXEC SQL
               INSERT INTO AUTOSALE.FINANCE_APP
               ( FINANCE_ID
               , DEAL_NUMBER
               , CUSTOMER_ID
               , FINANCE_TYPE
               , LENDER_CODE
               , LENDER_NAME
               , APP_STATUS
               , AMOUNT_REQUESTED
               , AMOUNT_APPROVED
               , APR_REQUESTED
               , APR_APPROVED
               , TERM_MONTHS
               , MONTHLY_PAYMENT
               , DOWN_PAYMENT
               , CREDIT_TIER
               , STIPULATIONS
               , SUBMITTED_TS
               , DECISION_TS
               , FUNDED_TS
               , CREATED_TS
               , UPDATED_TS
               )
               VALUES
               ( :FINANCE-ID
               , :DEAL-NUMBER     OF DCLFINANCE-APP
               , :CUSTOMER-ID    OF DCLFINANCE-APP
               , :FINANCE-TYPE
               , :LENDER-CODE     :WS-NI-LENDER-CODE
               , :LENDER-NAME     :WS-NI-LENDER-NAME
               , :APP-STATUS
               , :AMOUNT-REQUESTED
               , :AMOUNT-APPROVED  :WS-NI-AMOUNT-APVD
               , :APR-REQUESTED    :WS-NI-APR-REQ
               , :APR-APPROVED     :WS-NI-APR-APVD
               , :TERM-MONTHS     OF DCLFINANCE-APP
                                   :WS-NI-TERM
               , :MONTHLY-PAYMENT  :WS-NI-MONTHLY-PMT
               , :DOWN-PAYMENT    OF DCLFINANCE-APP
               , :CREDIT-TIER    OF DCLFINANCE-APP
                                   :WS-NI-CREDIT-TIER
               , :STIPULATIONS     :WS-NI-STIPULATIONS
               , :SUBMITTED-TS    :WS-NI-SUBMITTED-TS
               , :DECISION-TS     :WS-NI-DECISION-TS
               , :FUNDED-TS       :WS-NI-FUNDED-TS
               , :CREATED-TS     OF DCLFINANCE-APP
               , :UPDATED-TS     OF DCLFINANCE-APP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '7000-INSERT'  TO WS-DBE-SECTION-NAME
               MOVE 'FINANCE_APP'  TO WS-DBE-TABLE-NAME
               MOVE 'INSERT'       TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON FINANCE_APP INSERT'
                   TO WS-AO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
           MOVE 'NW' TO WS-AO-APP-STATUS
      *
      *    AUDIT LOG
      *
           MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
           MOVE 'INSERT'       TO WS-AUD-ACTION-TYPE
           MOVE 'FINANCE_APP'  TO WS-AUD-TABLE-NAME
           MOVE WS-GENERATED-FIN-ID TO WS-AUD-KEY-VALUE
           MOVE SPACES         TO WS-AUD-OLD-VALUE
           STRING 'NEW FINANCE APP TYPE=' WS-AI-FINANCE-TYPE
                  ' DEAL=' WS-AI-DEAL-NUMBER
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
           MOVE 'FINANCE APPLICATION CREATED SUCCESSFULLY'
               TO WS-AO-MSG-TEXT
           .
       7000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7500-UPDATE-DEAL-STATUS - SET DEAL TO FI (IN F AND I)     *
      ****************************************************************
       7500-UPDATE-DEAL-STATUS.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS = 'FI'
                    , UPDATED_TS = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-AI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '7500-UPDATE'  TO WS-DBE-SECTION-NAME
               MOVE 'SALES_DEAL'   TO WS-DBE-TABLE-NAME
               MOVE 'UPDATE'       TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING DEAL STATUS TO FI'
                   TO WS-AO-MSG-TEXT
           ELSE
      *        AUDIT THE STATUS CHANGE
               MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
               MOVE 'UPDATE'       TO WS-AUD-ACTION-TYPE
               MOVE 'SALES_DEAL'   TO WS-AUD-TABLE-NAME
               MOVE WS-AI-DEAL-NUMBER TO WS-AUD-KEY-VALUE
               MOVE 'STATUS=AP'    TO WS-AUD-OLD-VALUE
               MOVE 'STATUS=FI'    TO WS-AUD-NEW-VALUE
               CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                      WS-AUD-PROGRAM-ID
                                      WS-AUD-ACTION-TYPE
                                      WS-AUD-TABLE-NAME
                                      WS-AUD-KEY-VALUE
                                      WS-AUD-OLD-VALUE
                                      WS-AUD-NEW-VALUE
                                      WS-AUD-RETURN-CODE
                                      WS-AUD-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-APP-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNAP' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINAPP00                                              *
      ****************************************************************
