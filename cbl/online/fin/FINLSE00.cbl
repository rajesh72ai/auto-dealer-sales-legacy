       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINLSE00.
      ****************************************************************
      * PROGRAM:  FINLSE00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - LEASE CALCULATOR                         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  FULL LEASE PAYMENT CALCULATOR USING COMLESL0.      *
      *           INPUT: CAPITALIZED COST, CAP COST REDUCTION,       *
      *           RESIDUAL PERCENTAGE, MONEY FACTOR, TERM, TAX RATE. *
      *           DISPLAYS: ADJUSTED CAP COST, RESIDUAL AMOUNT,      *
      *           MONTHLY DEPRECIATION, MONTHLY FINANCE CHARGE,      *
      *           MONTHLY TAX, TOTAL MONTHLY PAYMENT, DRIVE-OFF      *
      *           AMOUNT, TOTAL OF PAYMENTS, TOTAL INTEREST.         *
      *           SUPPORTS WHAT-IF: CHANGE RESIDUAL OR MONEY FACTOR. *
      *           IF DEAL NUMBER PROVIDED: CREATES LEASE_TERMS       *
      *           RECORD IN DB2.                                     *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNLS - FINANCE LEASE CALC                          *
      * CALLS:    COMLESL0 - LEASE CALCULATION                       *
      *           COMFMTL0 - FIELD FORMATTING                       *
      *           COMLGEL0 - AUDIT LOGGING                          *
      * TABLES:   AUTOSALE.LEASE_TERMS (INSERT IF DEAL PROVIDED)     *
      *           AUTOSALE.FINANCE_APP  (LOOKUP FINANCE_ID)          *
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
                                          VALUE 'FINLSE00'.
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
           COPY DCLLSTRM.
      *
           COPY DCLFINAP.
      *
      *    INPUT FIELDS
      *
       01  WS-LSE-INPUT.
           05  WS-LI-DEAL-NUMBER         PIC X(10).
           05  WS-LI-CAP-COST            PIC X(11).
           05  WS-LI-CAP-REDUCTION       PIC X(11).
           05  WS-LI-RESIDUAL-PCT        PIC X(06).
           05  WS-LI-MONEY-FACTOR        PIC X(08).
           05  WS-LI-TERM                PIC X(03).
           05  WS-LI-TAX-RATE            PIC X(06).
           05  WS-LI-ACQ-FEE             PIC X(08).
           05  WS-LI-SEC-DEPOSIT         PIC X(08).
      *
      *    NUMERIC CONVERTED FIELDS
      *
       01  WS-NUM-FIELDS.
           05  WS-NUM-CAP-COST          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-CAP-REDUCE        PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-RESIDUAL-PCT      PIC S9(03)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-MONEY-FACTOR      PIC S9(01)V9(06) COMP-3
                                                       VALUE +0.
           05  WS-NUM-TERM              PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-NUM-TAX-RATE          PIC S9(03)V9(04) COMP-3
                                                       VALUE +0.
           05  WS-NUM-ACQ-FEE           PIC S9(05)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-SEC-DEPOSIT       PIC S9(05)V99 COMP-3
                                                       VALUE +0.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-LSE-OUTPUT.
           05  WS-LO-STATUS-LINE.
               10  WS-LO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LO-MSG-TEXT       PIC X(70).
           05  WS-LO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-LO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- LEASE PAYMENT CALCULATOR ----    '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-LO-INPUT-LINE-1.
               10  FILLER               PIC X(10)
                   VALUE 'CAP COST: '.
               10  WS-LO-CAP-COST       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'CAP RED:  '.
               10  WS-LO-CAP-REDUCE     PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(29) VALUE SPACES.
           05  WS-LO-INPUT-LINE-2.
               10  FILLER               PIC X(14)
                   VALUE 'RESIDUAL PCT: '.
               10  WS-LO-RES-PCT        PIC ZZ9.99.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(14)
                   VALUE 'MONEY FACTOR: '.
               10  WS-LO-MONEY-FAC      PIC 9.999999.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TERM: '.
               10  WS-LO-TERM           PIC Z(02)9.
               10  FILLER               PIC X(18) VALUE SPACES.
           05  WS-LO-INPUT-LINE-3.
               10  FILLER               PIC X(10)
                   VALUE 'TAX RATE: '.
               10  WS-LO-TAX-RATE       PIC ZZ9.9999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'ACQ FEE:  '.
               10  WS-LO-ACQ-FEE        PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'SEC DEP:  '.
               10  WS-LO-SEC-DEP        PIC $ZZ,ZZ9.99.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-LO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-LO-RESULT-HDR.
               10  FILLER               PIC X(40)
                   VALUE '---- LEASE PAYMENT BREAKDOWN ----     '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-LO-ADJ-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'ADJUSTED CAP COST:  '.
               10  WS-LO-ADJ-CAP        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(17)
                   VALUE 'RESIDUAL AMOUNT:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LO-RES-AMT        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-LO-DEPR-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'MONTHLY DEPRECIATN: '.
               10  WS-LO-MON-DEPR       PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(46) VALUE SPACES.
           05  WS-LO-FIN-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'MONTHLY FIN CHARGE: '.
               10  WS-LO-MON-FIN        PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(13)
                   VALUE 'APPROX APR: '.
               10  WS-LO-APR            PIC ZZ9.999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(25) VALUE SPACES.
           05  WS-LO-TAX-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'MONTHLY TAX:        '.
               10  WS-LO-MON-TAX        PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(46) VALUE SPACES.
           05  WS-LO-BLANK-3            PIC X(79) VALUE SPACES.
           05  WS-LO-TOTAL-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'TOTAL MONTHLY PMT:  '.
               10  WS-LO-MON-TOTAL      PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(46) VALUE SPACES.
           05  WS-LO-BLANK-4            PIC X(79) VALUE SPACES.
           05  WS-LO-DRIVEOFF-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'DUE AT SIGNING:     '.
               10  WS-LO-DRIVEOFF       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(45) VALUE SPACES.
           05  WS-LO-TOT-PMT-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'TOTAL OF PAYMENTS:  '.
               10  WS-LO-TOT-PMT        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(20)
                   VALUE 'TOTAL INTEREST EQ:  '.
               10  WS-LO-TOT-INT        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(08) VALUE SPACES.
           05  WS-LO-FILLER             PIC X(79) VALUE SPACES.
      *
      *    LEASE CALCULATION CALL FIELDS
      *
       01  WS-LEASE-REQUEST.
           05  WS-LSR-FUNCTION           PIC X(04).
           05  WS-LSR-CAP-COST           PIC S9(09)V99 COMP-3.
           05  WS-LSR-CAP-REDUCTION      PIC S9(09)V99 COMP-3.
           05  WS-LSR-RESIDUAL-PCT       PIC S9(03)V99 COMP-3.
           05  WS-LSR-MONEY-FACTOR       PIC S9(01)V9(06) COMP-3.
           05  WS-LSR-TERM-MONTHS        PIC S9(04)    COMP.
           05  WS-LSR-TAX-RATE           PIC S9(03)V9(04) COMP-3.
           05  WS-LSR-ACQUISITION-FEE    PIC S9(05)V99 COMP-3.
           05  WS-LSR-SECURITY-DEPOSIT   PIC S9(05)V99 COMP-3.
           05  WS-LSR-DEALER-CODE        PIC X(05).
           05  WS-LSR-VIN                PIC X(17).
      *
       01  WS-LEASE-RESULT.
           05  WS-LRS-RETURN-CODE        PIC S9(04)    COMP.
           05  WS-LRS-RETURN-MSG         PIC X(79).
           05  WS-LRS-RESIDUAL-AMT       PIC S9(09)V99 COMP-3.
           05  WS-LRS-ADJ-CAP-COST       PIC S9(09)V99 COMP-3.
           05  WS-LRS-NET-CAP-COST       PIC S9(09)V99 COMP-3.
           05  WS-LRS-DEPRECIATION       PIC S9(09)V99 COMP-3.
           05  WS-LRS-MONTHLY-DEPR       PIC S9(07)V99 COMP-3.
           05  WS-LRS-MONTHLY-FIN        PIC S9(07)V99 COMP-3.
           05  WS-LRS-MONTHLY-TAX        PIC S9(07)V99 COMP-3.
           05  WS-LRS-MONTHLY-TOTAL      PIC S9(07)V99 COMP-3.
           05  WS-LRS-TOTAL-PAYMENTS     PIC S9(09)V99 COMP-3.
           05  WS-LRS-TOTAL-INTEREST     PIC S9(09)V99 COMP-3.
           05  WS-LRS-TOTAL-TAX          PIC S9(09)V99 COMP-3.
           05  WS-LRS-DRIVE-OFF-AMT      PIC S9(09)V99 COMP-3.
           05  WS-LRS-APPROX-APR         PIC S9(03)V9(04) COMP-3.
           05  WS-LRS-FINANCE-CHARGE     PIC S9(09)V99 COMP-3.
           05  WS-LRS-TOTAL-COST         PIC S9(09)V99 COMP-3.
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
       01  WS-AUD-PROGRAM-ID           PIC X(08) VALUE 'FINLSE00'.
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
       01  WS-DBE-PROGRAM-NAME         PIC X(08) VALUE 'FINLSE00'.
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
       01  WS-HAS-DEAL                 PIC X(01) VALUE 'N'.
           88  WS-DEAL-PROVIDED                    VALUE 'Y'.
       01  WS-FINANCE-ID-WORK          PIC X(12) VALUE SPACES.
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
               PERFORM 4000-CALCULATE-LEASE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FORMAT-OUTPUT
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-DEAL-PROVIDED
               PERFORM 6000-RESOLVE-FINANCE-ID
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-DEAL-PROVIDED
           AND WS-FINANCE-ID-WORK NOT = SPACES
               PERFORM 7000-INSERT-LEASE-TERMS
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
           INITIALIZE WS-LSE-OUTPUT
           INITIALIZE WS-LSE-INPUT
           INITIALIZE WS-NUM-FIELDS
           MOVE 'FINLSE00' TO WS-LO-MSG-ID
           MOVE 'N' TO WS-HAS-DEAL
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
                   TO WS-LO-MSG-TEXT
           ELSE
               MOVE WS-INP-KEY-DATA(1:10)
                   TO WS-LI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:11)
                   TO WS-LI-CAP-COST
               MOVE WS-INP-BODY(12:11)
                   TO WS-LI-CAP-REDUCTION
               MOVE WS-INP-BODY(23:6)
                   TO WS-LI-RESIDUAL-PCT
               MOVE WS-INP-BODY(29:8)
                   TO WS-LI-MONEY-FACTOR
               MOVE WS-INP-BODY(37:3)
                   TO WS-LI-TERM
               MOVE WS-INP-BODY(40:6)
                   TO WS-LI-TAX-RATE
               MOVE WS-INP-BODY(46:8)
                   TO WS-LI-ACQ-FEE
               MOVE WS-INP-BODY(54:8)
                   TO WS-LI-SEC-DEPOSIT
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-LI-CAP-COST = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CAPITALIZED COST IS REQUIRED'
                   TO WS-LO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    CONVERT NUMERIC FIELDS
      *
           COMPUTE WS-NUM-CAP-COST =
               FUNCTION NUMVAL(WS-LI-CAP-COST)
           END-COMPUTE
      *
           IF WS-LI-CAP-REDUCTION NOT = SPACES
               COMPUTE WS-NUM-CAP-REDUCE =
                   FUNCTION NUMVAL(WS-LI-CAP-REDUCTION)
               END-COMPUTE
           END-IF
      *
           IF WS-LI-RESIDUAL-PCT NOT = SPACES
               COMPUTE WS-NUM-RESIDUAL-PCT =
                   FUNCTION NUMVAL(WS-LI-RESIDUAL-PCT)
               END-COMPUTE
           ELSE
               MOVE +55.00 TO WS-NUM-RESIDUAL-PCT
           END-IF
      *
           IF WS-LI-MONEY-FACTOR NOT = SPACES
               COMPUTE WS-NUM-MONEY-FACTOR =
                   FUNCTION NUMVAL(WS-LI-MONEY-FACTOR)
               END-COMPUTE
           ELSE
               MOVE +0.00125 TO WS-NUM-MONEY-FACTOR
           END-IF
      *
           IF WS-LI-TERM NOT = SPACES
               COMPUTE WS-NUM-TERM =
                   FUNCTION NUMVAL(WS-LI-TERM)
               END-COMPUTE
           ELSE
               MOVE +36 TO WS-NUM-TERM
           END-IF
      *
           IF WS-LI-TAX-RATE NOT = SPACES
               COMPUTE WS-NUM-TAX-RATE =
                   FUNCTION NUMVAL(WS-LI-TAX-RATE)
               END-COMPUTE
           ELSE
               MOVE +7.0000 TO WS-NUM-TAX-RATE
           END-IF
      *
           IF WS-LI-ACQ-FEE NOT = SPACES
               COMPUTE WS-NUM-ACQ-FEE =
                   FUNCTION NUMVAL(WS-LI-ACQ-FEE)
               END-COMPUTE
           ELSE
               MOVE +695.00 TO WS-NUM-ACQ-FEE
           END-IF
      *
           IF WS-LI-SEC-DEPOSIT NOT = SPACES
               COMPUTE WS-NUM-SEC-DEPOSIT =
                   FUNCTION NUMVAL(WS-LI-SEC-DEPOSIT)
               END-COMPUTE
           END-IF
      *
      *    CHECK IF DEAL NUMBER PROVIDED
      *
           IF WS-LI-DEAL-NUMBER NOT = SPACES
               MOVE 'Y' TO WS-HAS-DEAL
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CALCULATE-LEASE VIA COMLESL0                         *
      ****************************************************************
       4000-CALCULATE-LEASE.
      *
           MOVE 'CALC'               TO WS-LSR-FUNCTION
           MOVE WS-NUM-CAP-COST     TO WS-LSR-CAP-COST
           MOVE WS-NUM-CAP-REDUCE   TO WS-LSR-CAP-REDUCTION
           MOVE WS-NUM-RESIDUAL-PCT TO WS-LSR-RESIDUAL-PCT
           MOVE WS-NUM-MONEY-FACTOR TO WS-LSR-MONEY-FACTOR
           MOVE WS-NUM-TERM         TO WS-LSR-TERM-MONTHS
           MOVE WS-NUM-TAX-RATE     TO WS-LSR-TAX-RATE
           MOVE WS-NUM-ACQ-FEE      TO WS-LSR-ACQUISITION-FEE
           MOVE WS-NUM-SEC-DEPOSIT  TO WS-LSR-SECURITY-DEPOSIT
           MOVE SPACES               TO WS-LSR-DEALER-CODE
           MOVE SPACES               TO WS-LSR-VIN
      *
           CALL 'COMLESL0' USING WS-LEASE-REQUEST
                                  WS-LEASE-RESULT
      *
           IF WS-LRS-RETURN-CODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-LRS-RETURN-MSG TO WS-LO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    5000-FORMAT-OUTPUT                                        *
      ****************************************************************
       5000-FORMAT-OUTPUT.
      *
      *    INPUT ECHO
      *
           MOVE WS-NUM-CAP-COST     TO WS-LO-CAP-COST
           MOVE WS-NUM-CAP-REDUCE   TO WS-LO-CAP-REDUCE
           MOVE WS-NUM-RESIDUAL-PCT TO WS-LO-RES-PCT
           MOVE WS-NUM-MONEY-FACTOR TO WS-LO-MONEY-FAC
           MOVE WS-NUM-TERM         TO WS-LO-TERM
           MOVE WS-NUM-TAX-RATE     TO WS-LO-TAX-RATE
           MOVE WS-NUM-ACQ-FEE      TO WS-LO-ACQ-FEE
           MOVE WS-NUM-SEC-DEPOSIT  TO WS-LO-SEC-DEP
      *
      *    CALCULATED RESULTS
      *
           MOVE WS-LRS-ADJ-CAP-COST  TO WS-LO-ADJ-CAP
           MOVE WS-LRS-RESIDUAL-AMT  TO WS-LO-RES-AMT
           MOVE WS-LRS-MONTHLY-DEPR  TO WS-LO-MON-DEPR
           MOVE WS-LRS-MONTHLY-FIN   TO WS-LO-MON-FIN
           MOVE WS-LRS-APPROX-APR    TO WS-LO-APR
           MOVE WS-LRS-MONTHLY-TAX   TO WS-LO-MON-TAX
           MOVE WS-LRS-MONTHLY-TOTAL TO WS-LO-MON-TOTAL
           MOVE WS-LRS-DRIVE-OFF-AMT TO WS-LO-DRIVEOFF
           MOVE WS-LRS-TOTAL-PAYMENTS TO WS-LO-TOT-PMT
           MOVE WS-LRS-TOTAL-INTEREST TO WS-LO-TOT-INT
      *
           MOVE 'LEASE CALCULATION COMPLETE'
               TO WS-LO-MSG-TEXT
           .
      *
      ****************************************************************
      *    6000-RESOLVE-FINANCE-ID - FIND FINANCE ID FOR DEAL        *
      ****************************************************************
       6000-RESOLVE-FINANCE-ID.
      *
           EXEC SQL
               SELECT FINANCE_ID
               INTO   :WS-FINANCE-ID-WORK
               FROM   AUTOSALE.FINANCE_APP
               WHERE  DEAL_NUMBER = :WS-LI-DEAL-NUMBER
                 AND  FINANCE_TYPE = 'S'
               ORDER BY CREATED_TS DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +100
      *        NO LEASE FINANCE APP - SKIP LEASE TERMS INSERT
               MOVE SPACES TO WS-FINANCE-ID-WORK
               MOVE 'LEASE CALC COMPLETE (NO FINANCE APP FOUND FOR DE
      -        'AL)' TO WS-LO-MSG-TEXT
           ELSE
               IF SQLCODE NOT = +0
                   MOVE SPACES TO WS-FINANCE-ID-WORK
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    7000-INSERT-LEASE-TERMS                                   *
      ****************************************************************
       7000-INSERT-LEASE-TERMS.
      *
           MOVE WS-FINANCE-ID-WORK   TO FINANCE-ID
                                         OF DCLLEASE-TERMS
           MOVE WS-NUM-RESIDUAL-PCT  TO RESIDUAL-PCT
           MOVE WS-LRS-RESIDUAL-AMT  TO RESIDUAL-AMT
           MOVE WS-NUM-MONEY-FACTOR  TO MONEY-FACTOR
           MOVE WS-NUM-CAP-COST     TO CAPITALIZED-COST
           MOVE WS-NUM-CAP-REDUCE   TO CAP-COST-REDUCE
           MOVE WS-LRS-ADJ-CAP-COST  TO ADJ-CAP-COST
           MOVE WS-LRS-DEPRECIATION  TO DEPRECIATION-AMT
           MOVE WS-LRS-FINANCE-CHARGE TO FINANCE-CHARGE
                                         OF DCLLEASE-TERMS
           MOVE WS-LRS-MONTHLY-TAX   TO MONTHLY-TAX
           MOVE +12000                TO MILES-PER-YEAR
           MOVE +0.25                 TO EXCESS-MILE-CHG
           MOVE +395.00              TO DISPOSITION-FEE
           MOVE WS-NUM-ACQ-FEE      TO ACQ-FEE
           MOVE WS-NUM-SEC-DEPOSIT  TO SECURITY-DEPOSIT
      *
           EXEC SQL
               INSERT INTO AUTOSALE.LEASE_TERMS
               ( FINANCE_ID
               , RESIDUAL_PCT
               , RESIDUAL_AMT
               , MONEY_FACTOR
               , CAPITALIZED_COST
               , CAP_COST_REDUCE
               , ADJ_CAP_COST
               , DEPRECIATION_AMT
               , FINANCE_CHARGE
               , MONTHLY_TAX
               , MILES_PER_YEAR
               , EXCESS_MILE_CHG
               , DISPOSITION_FEE
               , ACQ_FEE
               , SECURITY_DEPOSIT
               )
               VALUES
               ( :FINANCE-ID      OF DCLLEASE-TERMS
               , :RESIDUAL-PCT
               , :RESIDUAL-AMT
               , :MONEY-FACTOR
               , :CAPITALIZED-COST
               , :CAP-COST-REDUCE
               , :ADJ-CAP-COST
               , :DEPRECIATION-AMT
               , :FINANCE-CHARGE  OF DCLLEASE-TERMS
               , :MONTHLY-TAX
               , :MILES-PER-YEAR
               , :EXCESS-MILE-CHG
               , :DISPOSITION-FEE
               , :ACQ-FEE
               , :SECURITY-DEPOSIT
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '7000-INSERT'    TO WS-DBE-SECTION-NAME
               MOVE 'LEASE_TERMS'    TO WS-DBE-TABLE-NAME
               MOVE 'INSERT'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
      *        NON-FATAL FOR LEASE TERMS INSERT FAILURE
               MOVE 'LEASE CALC COMPLETE BUT LEASE TERMS SAVE FAILED'
                   TO WS-LO-MSG-TEXT
           ELSE
      *        AUDIT LOG
               MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
               MOVE 'INSERT'       TO WS-AUD-ACTION-TYPE
               MOVE 'LEASE_TERMS'  TO WS-AUD-TABLE-NAME
               MOVE WS-FINANCE-ID-WORK TO WS-AUD-KEY-VALUE
               MOVE SPACES         TO WS-AUD-OLD-VALUE
               STRING 'LEASE TERMS CREATED MF='
                      WS-LO-MONEY-FAC
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
               MOVE 'LEASE CALC COMPLETE - TERMS SAVED TO DEAL'
                   TO WS-LO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-LSE-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNLS' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINLSE00                                              *
      ****************************************************************
