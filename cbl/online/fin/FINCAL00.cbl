       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINCAL00.
      ****************************************************************
      * PROGRAM:  FINCAL00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - PAYMENT CALCULATOR (LOAN)                *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PURE CALCULATION TOOL - NO DB2 UPDATES.            *
      *           CALCULATES LOAN PAYMENT USING COMLONL0.            *
      *           DISPLAYS MONTHLY PAYMENT, TOTAL OF PAYMENTS,       *
      *           TOTAL INTEREST, AND FIRST YEAR AMORTIZATION.       *
      *           SUPPORTS WHAT-IF: CHANGE APR OR TERM TO RECALC.   *
      *           SHOWS SIDE-BY-SIDE COMPARISON OF 36/48/60/72 MOS. *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNCL - FINANCE CALCULATOR                          *
      * CALLS:    COMLONL0 - LOAN CALCULATION                       *
      *           COMFMTL0 - FIELD FORMATTING                       *
      * TABLES:   NONE (READ-ONLY CALCULATOR)                        *
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
                                          VALUE 'FINCAL00'.
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
      *    INPUT FIELDS
      *
       01  WS-CALC-INPUT.
           05  WS-CI-PRINCIPAL           PIC X(11).
           05  WS-CI-APR                 PIC X(06).
           05  WS-CI-TERM               PIC X(03).
           05  WS-CI-DOWN-PAYMENT        PIC X(11).
      *
      *    NUMERIC CONVERTED FIELDS
      *
       01  WS-NUM-FIELDS.
           05  WS-NUM-PRINCIPAL          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-APR               PIC S9(03)V9(04) COMP-3
                                                       VALUE +0.
           05  WS-NUM-TERM              PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-NUM-DOWN-PMT          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NET-PRINCIPAL          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-CALC-OUTPUT.
           05  WS-CO-STATUS-LINE.
               10  WS-CO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-CO-MSG-TEXT       PIC X(70).
           05  WS-CO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-CO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- LOAN PAYMENT CALCULATOR ----     '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-CO-INPUT-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'PRINCIPAL:  '.
               10  WS-CO-PRINCIPAL      PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'DOWN: '.
               10  WS-CO-DOWN-PMT       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'NET: '.
               10  WS-CO-NET-PRINC      PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(02) VALUE SPACES.
           05  WS-CO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-CO-RESULT-HDR.
               10  FILLER               PIC X(30)
                   VALUE '---- CALCULATED PAYMENT ----  '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-CO-RESULT-LINE-1.
               10  FILLER               PIC X(05) VALUE 'APR: '.
               10  WS-CO-APR            PIC ZZ9.999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TERM: '.
               10  WS-CO-TERM           PIC Z(02)9.
               10  FILLER               PIC X(07)
                   VALUE ' MONTHS'.
               10  FILLER               PIC X(42) VALUE SPACES.
           05  WS-CO-RESULT-LINE-2.
               10  FILLER               PIC X(17)
                   VALUE 'MONTHLY PAYMENT: '.
               10  WS-CO-MONTHLY-PMT    PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-CO-RESULT-LINE-3.
               10  FILLER               PIC X(20)
                   VALUE 'TOTAL OF PAYMENTS:  '.
               10  WS-CO-TOTAL-PMT      PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(17)
                   VALUE 'TOTAL INTEREST: '.
               10  WS-CO-TOTAL-INT      PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(13) VALUE SPACES.
           05  WS-CO-BLANK-3            PIC X(79) VALUE SPACES.
      *
      *    COMPARISON SECTION
      *
           05  WS-CO-COMP-HDR.
               10  FILLER               PIC X(40)
                   VALUE '---- TERM COMPARISON (SAME APR) ---- '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-CO-COMP-COL-HDR.
               10  FILLER               PIC X(18)
                   VALUE '                  '.
               10  FILLER               PIC X(15)
                   VALUE '  36 MONTHS    '.
               10  FILLER               PIC X(15)
                   VALUE '  48 MONTHS    '.
               10  FILLER               PIC X(15)
                   VALUE '  60 MONTHS    '.
               10  FILLER               PIC X(16)
                   VALUE '  72 MONTHS     '.
           05  WS-CO-COMP-PMT-LINE.
               10  FILLER               PIC X(18)
                   VALUE 'MONTHLY PAYMENT:  '.
               10  WS-CO-CMP-PMT-36     PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  WS-CO-CMP-PMT-48     PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  WS-CO-CMP-PMT-60     PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  WS-CO-CMP-PMT-72     PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-CO-COMP-TOT-LINE.
               10  FILLER               PIC X(18)
                   VALUE 'TOTAL PAYMENTS:   '.
               10  WS-CO-CMP-TOT-36     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-CO-CMP-TOT-48     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-CO-CMP-TOT-60     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-CO-CMP-TOT-72     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
           05  WS-CO-COMP-INT-LINE.
               10  FILLER               PIC X(18)
                   VALUE 'TOTAL INTEREST:   '.
               10  WS-CO-CMP-INT-36     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-CO-CMP-INT-48     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-CO-CMP-INT-60     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-CO-CMP-INT-72     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
           05  WS-CO-BLANK-4            PIC X(79) VALUE SPACES.
      *
      *    AMORTIZATION SECTION
      *
           05  WS-CO-AMORT-HDR.
               10  FILLER               PIC X(40)
                   VALUE '---- FIRST YEAR AMORTIZATION ----     '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-CO-AMORT-COL-HDR.
               10  FILLER               PIC X(05) VALUE 'MONTH'.
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'PAYMENT   '.
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'PRINCIPAL '.
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'INTEREST  '.
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(12)
                   VALUE 'CUM INTEREST'.
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(12)
                   VALUE 'BALANCE     '.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-CO-AMORT-LINES.
               10  WS-CO-AMORT-LINE     OCCURS 12 TIMES.
                   15  WS-CO-AM-MONTH   PIC Z(04)9.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-CO-AM-PMT     PIC $Z,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-CO-AM-PRINC   PIC $Z,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-CO-AM-INT     PIC $Z,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-CO-AM-CUMINT  PIC $ZZ,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-CO-AM-BAL     PIC $ZZZ,ZZ9.99.
                   15  FILLER           PIC X(10) VALUE SPACES.
           05  WS-CO-FILLER             PIC X(79) VALUE SPACES.
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
      *    FORMAT CALL FIELDS
      *
       01  WS-FMT-REQUEST.
           05  WS-FMT-FUNCTION          PIC X(04).
           05  WS-FMT-INPUT             PIC X(30).
       01  WS-FMT-RESULT.
           05  WS-FMT-RC                PIC S9(04) COMP.
           05  WS-FMT-OUTPUT            PIC X(40).
      *
      *    COMPARISON TERM TABLE
      *
       01  WS-COMP-TERMS.
           05  FILLER                    PIC S9(04) COMP VALUE +36.
           05  FILLER                    PIC S9(04) COMP VALUE +48.
           05  FILLER                    PIC S9(04) COMP VALUE +60.
           05  FILLER                    PIC S9(04) COMP VALUE +72.
       01  WS-COMP-TERMS-R REDEFINES WS-COMP-TERMS.
           05  WS-COMP-TERM-ENTRY       PIC S9(04) COMP
                                         OCCURS 4 TIMES.
      *
      *    COMPARISON RESULT WORK AREAS
      *
       01  WS-COMP-RESULT-TABLE.
           05  WS-COMP-ENTRY            OCCURS 4 TIMES.
               10  WS-CMP-MONTHLY-PMT   PIC S9(07)V99 COMP-3.
               10  WS-CMP-TOTAL-PMT     PIC S9(09)V99 COMP-3.
               10  WS-CMP-TOTAL-INT     PIC S9(09)V99 COMP-3.
      *
      *    LOOP INDEX
      *
       01  WS-COMP-INDEX                PIC S9(04) COMP VALUE +0.
       01  WS-AMORT-INDEX               PIC S9(04) COMP VALUE +0.
       01  WS-RETURN-CODE               PIC S9(04) COMP VALUE +0.
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
               PERFORM 4000-CALCULATE-PAYMENT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-BUILD-COMPARISON
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-BUILD-AMORT-DISPLAY
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
           INITIALIZE WS-CALC-OUTPUT
           INITIALIZE WS-CALC-INPUT
           INITIALIZE WS-NUM-FIELDS
           MOVE 'FINCAL00' TO WS-CO-MSG-ID
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
               MOVE WS-INP-BODY(1:11)   TO WS-CI-PRINCIPAL
               MOVE WS-INP-BODY(12:6)   TO WS-CI-APR
               MOVE WS-INP-BODY(18:3)   TO WS-CI-TERM
               MOVE WS-INP-BODY(21:11)  TO WS-CI-DOWN-PAYMENT
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-CI-PRINCIPAL = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'PRINCIPAL AMOUNT IS REQUIRED'
                   TO WS-CO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           COMPUTE WS-NUM-PRINCIPAL =
               FUNCTION NUMVAL(WS-CI-PRINCIPAL)
           END-COMPUTE
      *
           IF WS-CI-APR NOT = SPACES
               COMPUTE WS-NUM-APR =
                   FUNCTION NUMVAL(WS-CI-APR)
               END-COMPUTE
           END-IF
      *
           IF WS-CI-TERM NOT = SPACES
               COMPUTE WS-NUM-TERM =
                   FUNCTION NUMVAL(WS-CI-TERM)
               END-COMPUTE
           ELSE
               MOVE +60 TO WS-NUM-TERM
           END-IF
      *
           IF WS-CI-DOWN-PAYMENT NOT = SPACES
               COMPUTE WS-NUM-DOWN-PMT =
                   FUNCTION NUMVAL(WS-CI-DOWN-PAYMENT)
               END-COMPUTE
           END-IF
      *
      *    CALCULATE NET PRINCIPAL
      *
           COMPUTE WS-NET-PRINCIPAL =
               WS-NUM-PRINCIPAL - WS-NUM-DOWN-PMT
           END-COMPUTE
      *
           IF WS-NET-PRINCIPAL < +500.00
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NET AMOUNT (PRINCIPAL - DOWN) MUST BE >= $500'
                   TO WS-CO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-NUM-APR < +0 OR WS-NUM-APR > +30.0000
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'APR MUST BE 0 - 30 PERCENT'
                   TO WS-CO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    FORMAT INPUT DISPLAY
      *
           MOVE WS-NUM-PRINCIPAL TO WS-CO-PRINCIPAL
           MOVE WS-NUM-DOWN-PMT  TO WS-CO-DOWN-PMT
           MOVE WS-NET-PRINCIPAL TO WS-CO-NET-PRINC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CALCULATE-PAYMENT - PRIMARY CALCULATION              *
      ****************************************************************
       4000-CALCULATE-PAYMENT.
      *
           MOVE 'CALC'          TO WS-LN-FUNCTION
           MOVE WS-NET-PRINCIPAL TO WS-LN-PRINCIPAL
           MOVE WS-NUM-APR      TO WS-LN-APR
           MOVE WS-NUM-TERM     TO WS-LN-TERM-MONTHS
           MOVE SPACES           TO WS-LN-DEALER-CODE
           MOVE SPACES           TO WS-LN-VIN
      *
           CALL 'COMLONL0' USING WS-LOAN-REQUEST
                                  WS-LOAN-RESULT
      *
           IF WS-LR-RETURN-CODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-LR-RETURN-MSG TO WS-CO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    FORMAT PRIMARY RESULT
      *
           MOVE WS-NUM-APR           TO WS-CO-APR
           MOVE WS-NUM-TERM          TO WS-CO-TERM
           MOVE WS-LR-MONTHLY-PMT   TO WS-CO-MONTHLY-PMT
           MOVE WS-LR-TOTAL-PAYMENTS TO WS-CO-TOTAL-PMT
           MOVE WS-LR-TOTAL-INTEREST TO WS-CO-TOTAL-INT
      *
           MOVE 'LOAN CALCULATION COMPLETE'
               TO WS-CO-MSG-TEXT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-BUILD-COMPARISON - 36/48/60/72 MONTH SIDE-BY-SIDE    *
      ****************************************************************
       5000-BUILD-COMPARISON.
      *
           PERFORM VARYING WS-COMP-INDEX
               FROM +1 BY +1
               UNTIL WS-COMP-INDEX > +4
      *
               MOVE 'CALC'           TO WS-LN-FUNCTION
               MOVE WS-NET-PRINCIPAL TO WS-LN-PRINCIPAL
               MOVE WS-NUM-APR      TO WS-LN-APR
               MOVE WS-COMP-TERM-ENTRY(WS-COMP-INDEX)
                   TO WS-LN-TERM-MONTHS
               MOVE SPACES           TO WS-LN-DEALER-CODE
               MOVE SPACES           TO WS-LN-VIN
      *
               CALL 'COMLONL0' USING WS-LOAN-REQUEST
                                      WS-LOAN-RESULT
      *
               IF WS-LR-RETURN-CODE = +0
                   MOVE WS-LR-MONTHLY-PMT
                       TO WS-CMP-MONTHLY-PMT(WS-COMP-INDEX)
                   MOVE WS-LR-TOTAL-PAYMENTS
                       TO WS-CMP-TOTAL-PMT(WS-COMP-INDEX)
                   MOVE WS-LR-TOTAL-INTEREST
                       TO WS-CMP-TOTAL-INT(WS-COMP-INDEX)
               ELSE
                   MOVE +0
                       TO WS-CMP-MONTHLY-PMT(WS-COMP-INDEX)
                   MOVE +0
                       TO WS-CMP-TOTAL-PMT(WS-COMP-INDEX)
                   MOVE +0
                       TO WS-CMP-TOTAL-INT(WS-COMP-INDEX)
               END-IF
      *
           END-PERFORM
      *
      *    FORMAT COMPARISON OUTPUT
      *
           MOVE WS-CMP-MONTHLY-PMT(1) TO WS-CO-CMP-PMT-36
           MOVE WS-CMP-MONTHLY-PMT(2) TO WS-CO-CMP-PMT-48
           MOVE WS-CMP-MONTHLY-PMT(3) TO WS-CO-CMP-PMT-60
           MOVE WS-CMP-MONTHLY-PMT(4) TO WS-CO-CMP-PMT-72
      *
           MOVE WS-CMP-TOTAL-PMT(1)   TO WS-CO-CMP-TOT-36
           MOVE WS-CMP-TOTAL-PMT(2)   TO WS-CO-CMP-TOT-48
           MOVE WS-CMP-TOTAL-PMT(3)   TO WS-CO-CMP-TOT-60
           MOVE WS-CMP-TOTAL-PMT(4)   TO WS-CO-CMP-TOT-72
      *
           MOVE WS-CMP-TOTAL-INT(1)   TO WS-CO-CMP-INT-36
           MOVE WS-CMP-TOTAL-INT(2)   TO WS-CO-CMP-INT-48
           MOVE WS-CMP-TOTAL-INT(3)   TO WS-CO-CMP-INT-60
           MOVE WS-CMP-TOTAL-INT(4)   TO WS-CO-CMP-INT-72
           .
      *
      ****************************************************************
      *    6000-BUILD-AMORT-DISPLAY - FIRST YEAR AMORTIZATION TABLE  *
      ****************************************************************
       6000-BUILD-AMORT-DISPLAY.
      *
      *    RECALCULATE WITH USER'S REQUESTED TERM FOR AMORT TABLE
      *
           MOVE 'CALC'          TO WS-LN-FUNCTION
           MOVE WS-NET-PRINCIPAL TO WS-LN-PRINCIPAL
           MOVE WS-NUM-APR      TO WS-LN-APR
           MOVE WS-NUM-TERM     TO WS-LN-TERM-MONTHS
           MOVE SPACES           TO WS-LN-DEALER-CODE
           MOVE SPACES           TO WS-LN-VIN
      *
           CALL 'COMLONL0' USING WS-LOAN-REQUEST
                                  WS-LOAN-RESULT
      *
           IF WS-LR-RETURN-CODE NOT = +0
               GO TO 6000-EXIT
           END-IF
      *
           PERFORM VARYING WS-AMORT-INDEX
               FROM +1 BY +1
               UNTIL WS-AMORT-INDEX > WS-LR-AMORT-MONTHS
      *
               MOVE WS-AM-MONTH-NUM(WS-AMORT-INDEX)
                   TO WS-CO-AM-MONTH(WS-AMORT-INDEX)
               MOVE WS-AM-PAYMENT(WS-AMORT-INDEX)
                   TO WS-CO-AM-PMT(WS-AMORT-INDEX)
               MOVE WS-AM-PRINCIPAL(WS-AMORT-INDEX)
                   TO WS-CO-AM-PRINC(WS-AMORT-INDEX)
               MOVE WS-AM-INTEREST(WS-AMORT-INDEX)
                   TO WS-CO-AM-INT(WS-AMORT-INDEX)
               MOVE WS-AM-CUM-INT(WS-AMORT-INDEX)
                   TO WS-CO-AM-CUMINT(WS-AMORT-INDEX)
               MOVE WS-AM-BALANCE(WS-AMORT-INDEX)
                   TO WS-CO-AM-BAL(WS-AMORT-INDEX)
      *
           END-PERFORM
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-CALC-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNCL' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINCAL00                                              *
      ****************************************************************
