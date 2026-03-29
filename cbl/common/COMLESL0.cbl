       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMLESL0.
      ****************************************************************
      * PROGRAM:  COMLESL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - LEASE CALCULATION MODULE                  *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CALCULATES COMPLETE LEASE PAYMENT STRUCTURE        *
      *           INCLUDING MONTHLY DEPRECIATION, FINANCE CHARGE,    *
      *           TAX, TOTAL PAYMENT, DRIVE-OFF AMOUNT, AND          *
      *           TOTAL COST SUMMARY.                                *
      * CALLABLE: YES - VIA CALL 'COMLESL0' USING LS-LEASE-REQUEST  *
      *                                            LS-LEASE-RESULT   *
      * INPUTS:   LS-LEASE-REQUEST                                   *
      *           - CAPITALIZED COST (MSRP OR NEGOTIATED PRICE)      *
      *           - CAP COST REDUCTION (DOWN PAYMENT)                *
      *           - RESIDUAL PERCENTAGE                              *
      *           - MONEY FACTOR (LEASE RATE)                        *
      *           - TERM IN MONTHS                                   *
      *           - TAX RATE                                         *
      *           - ACQUISITION FEE                                  *
      *           - SECURITY DEPOSIT AMOUNT                          *
      * OUTPUTS:  LS-LEASE-RESULT                                    *
      *           - FULL LEASE PAYMENT BREAKDOWN                     *
      *           - DRIVE-OFF AMOUNT                                 *
      *           - TOTAL COST SUMMARY                               *
      * NOTES:    MONEY FACTOR X 2400 = APPROXIMATE APR              *
      *           STANDARD LEASE TERMS: 24, 36, 39, 48 MONTHS       *
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
                                          VALUE 'COMLESL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    WORK FIELDS FOR LEASE CALCULATION
      *
       01  WS-CALC-WORK-FIELDS.
           05  WS-RESIDUAL-AMOUNT        PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-ADJUSTED-CAP-COST      PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NET-CAP-COST           PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-DEPRECIATION-TOTAL     PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-DEPRECIATION   PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-FINANCE-BASE           PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-FINANCE        PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-PRETAX         PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-TAX            PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-TOTAL          PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-OF-PAYMENTS      PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-INTEREST         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-TAX              PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-DRIVE-OFF-AMOUNT       PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-APPROX-APR             PIC S9(03)V9(04) COMP-3
                                                       VALUE +0.
           05  WS-WORK-AMOUNT            PIC S9(11)V9(04) COMP-3
                                                       VALUE +0.
      *
      *    VALIDATION FLAGS
      *
       01  WS-VALIDATION-FLAGS.
           05  WS-VALID-FLAG             PIC X(01)     VALUE 'Y'.
               88  WS-ALL-VALID                        VALUE 'Y'.
               88  WS-NOT-VALID                        VALUE 'N'.
           05  WS-ERROR-COUNT            PIC S9(04)    COMP
                                                       VALUE +0.
      *
      *    DISPLAY FORMATTING
      *
       01  WS-DISPLAY-FIELDS.
           05  WS-DISP-AMOUNT            PIC $ZZZ,ZZZ,ZZ9.99.
           05  WS-DISP-RATE              PIC Z9.9999.
      *
       LINKAGE SECTION.
      *
      *    LEASE CALCULATION REQUEST
      *
       01  LS-LEASE-REQUEST.
           05  LS-LR-FUNCTION            PIC X(04).
               88  LS-LR-CALCULATE                     VALUE 'CALC'.
               88  LS-LR-VALIDATE                      VALUE 'VALD'.
               88  LS-LR-ESTIMATE                      VALUE 'ESTM'.
           05  LS-LR-CAP-COST            PIC S9(09)V99 COMP-3.
           05  LS-LR-CAP-REDUCTION       PIC S9(09)V99 COMP-3.
           05  LS-LR-RESIDUAL-PCT        PIC S9(03)V99 COMP-3.
           05  LS-LR-MONEY-FACTOR        PIC S9(01)V9(06) COMP-3.
           05  LS-LR-TERM-MONTHS         PIC S9(04)    COMP.
           05  LS-LR-TAX-RATE            PIC S9(03)V9(04) COMP-3.
           05  LS-LR-ACQUISITION-FEE     PIC S9(05)V99 COMP-3.
           05  LS-LR-SECURITY-DEPOSIT    PIC S9(05)V99 COMP-3.
           05  LS-LR-DEALER-CODE         PIC X(05).
           05  LS-LR-VIN                 PIC X(17).
      *
      *    LEASE CALCULATION RESULT
      *
       01  LS-LEASE-RESULT.
           05  LS-RS-RETURN-CODE         PIC S9(04)    COMP.
           05  LS-RS-RETURN-MSG          PIC X(79).
           05  LS-RS-RESIDUAL-AMT        PIC S9(09)V99 COMP-3.
           05  LS-RS-ADJ-CAP-COST        PIC S9(09)V99 COMP-3.
           05  LS-RS-NET-CAP-COST        PIC S9(09)V99 COMP-3.
           05  LS-RS-DEPRECIATION        PIC S9(09)V99 COMP-3.
           05  LS-RS-MONTHLY-DEPR        PIC S9(07)V99 COMP-3.
           05  LS-RS-MONTHLY-FIN         PIC S9(07)V99 COMP-3.
           05  LS-RS-MONTHLY-TAX         PIC S9(07)V99 COMP-3.
           05  LS-RS-MONTHLY-TOTAL       PIC S9(07)V99 COMP-3.
           05  LS-RS-TOTAL-PAYMENTS      PIC S9(09)V99 COMP-3.
           05  LS-RS-TOTAL-INTEREST      PIC S9(09)V99 COMP-3.
           05  LS-RS-TOTAL-TAX           PIC S9(09)V99 COMP-3.
           05  LS-RS-DRIVE-OFF-AMT       PIC S9(09)V99 COMP-3.
           05  LS-RS-APPROX-APR          PIC S9(03)V9(04) COMP-3.
           05  LS-RS-FINANCE-CHARGE      PIC S9(09)V99 COMP-3.
           05  LS-RS-TOTAL-COST          PIC S9(09)V99 COMP-3.
      *
       PROCEDURE DIVISION USING LS-LEASE-REQUEST
                                LS-LEASE-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           EVALUATE TRUE
               WHEN LS-LR-CALCULATE
                   PERFORM 2000-VALIDATE-INPUTS
                   IF WS-ALL-VALID
                       PERFORM 3000-CALCULATE-LEASE
                       PERFORM 4000-CALCULATE-TOTALS
                       PERFORM 5000-CALCULATE-DRIVEOFF
                   END-IF
               WHEN LS-LR-VALIDATE
                   PERFORM 2000-VALIDATE-INPUTS
               WHEN LS-LR-ESTIMATE
                   PERFORM 2000-VALIDATE-INPUTS
                   IF WS-ALL-VALID
                       PERFORM 3000-CALCULATE-LEASE
                   END-IF
               WHEN OTHER
                   MOVE +16 TO LS-RS-RETURN-CODE
                   STRING 'COMLESL0: INVALID FUNCTION CODE: '
                          LS-LR-FUNCTION
                          DELIMITED BY SIZE
                          INTO LS-RS-RETURN-MSG
           END-EVALUATE
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR RESULT AREA AND WORK FIELDS       *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-LEASE-RESULT
           INITIALIZE WS-CALC-WORK-FIELDS
           MOVE 'Y' TO WS-VALID-FLAG
           MOVE +0  TO WS-ERROR-COUNT
           MOVE +0  TO LS-RS-RETURN-CODE
           .
      *
      ****************************************************************
      *    2000-VALIDATE-INPUTS - VALIDATE ALL LEASE PARAMETERS      *
      ****************************************************************
       2000-VALIDATE-INPUTS.
      *
      *    VALIDATE CAPITALIZED COST
      *
           IF LS-LR-CAP-COST < +1000.00
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: CAP COST MUST BE >= $1,000.00'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
      *    VALIDATE CAP COST REDUCTION (DOWN PAYMENT)
      *
           IF LS-LR-CAP-REDUCTION < +0
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: CAP COST REDUCTION CANNOT BE NEGATIVE'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-LR-CAP-REDUCTION >= LS-LR-CAP-COST
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: CAP REDUCTION EXCEEDS CAP COST'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
      *    VALIDATE MONEY FACTOR (MUST BE > 0)
      *
           IF LS-LR-MONEY-FACTOR <= +0
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: MONEY FACTOR MUST BE > 0'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
      *    VALIDATE MONEY FACTOR RANGE (TYPICAL: .00001 - .00500)
      *
           IF LS-LR-MONEY-FACTOR > +0.00500
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: MONEY FACTOR EXCEEDS .00500 LIMIT'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
      *    VALIDATE TERM (STANDARD LEASE TERMS)
      *
           EVALUATE LS-LR-TERM-MONTHS
               WHEN +24
               WHEN +36
               WHEN +39
               WHEN +48
                   CONTINUE
               WHEN OTHER
                   MOVE 'N' TO WS-VALID-FLAG
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE +8 TO LS-RS-RETURN-CODE
                   MOVE
                   'COMLESL0: TERM MUST BE 24, 36, 39, OR 48 MONTHS'
                       TO LS-RS-RETURN-MSG
           END-EVALUATE
      *
      *    VALIDATE RESIDUAL PERCENTAGE (20% TO 75%)
      *
           IF LS-LR-RESIDUAL-PCT < +20.00
            OR LS-LR-RESIDUAL-PCT > +75.00
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: RESIDUAL PCT MUST BE 20-75%'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
      *    VALIDATE TAX RATE
      *
           IF LS-LR-TAX-RATE < +0
            OR LS-LR-TAX-RATE > +15.0000
               MOVE 'N' TO WS-VALID-FLAG
               ADD +1 TO WS-ERROR-COUNT
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: TAX RATE OUT OF RANGE (0 - 15%)'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
      *    IF VALIDATION-ONLY AND ALL IS GOOD, REPORT SUCCESS
      *
           IF WS-ALL-VALID
               MOVE +0 TO LS-RS-RETURN-CODE
               MOVE 'COMLESL0: ALL INPUTS VALIDATED SUCCESSFULLY'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    3000-CALCULATE-LEASE - CORE LEASE PAYMENT CALCULATION     *
      *    STANDARD LEASE FORMULA:                                   *
      *    RESIDUAL = CAP COST * RESIDUAL PCT / 100                  *
      *    ADJ CAP = CAP COST + ACQ FEE - CAP REDUCTION             *
      *    DEPRECIATION = ADJ CAP - RESIDUAL                         *
      *    MONTHLY DEPR = DEPRECIATION / TERM                        *
      *    MONTHLY FIN  = (ADJ CAP + RESIDUAL) * MONEY FACTOR       *
      *    MONTHLY TAX  = (MONTHLY DEPR + MONTHLY FIN) * TAX RATE   *
      *    TOTAL MONTHLY = MONTHLY DEPR + MONTHLY FIN + MONTHLY TAX *
      ****************************************************************
       3000-CALCULATE-LEASE.
      *
      *    STEP 1: CALCULATE RESIDUAL VALUE
      *
           COMPUTE WS-RESIDUAL-AMOUNT ROUNDED =
               LS-LR-CAP-COST *
               (LS-LR-RESIDUAL-PCT / 100)
           END-COMPUTE
      *
      *    STEP 2: CALCULATE ADJUSTED CAPITALIZED COST
      *            (MSRP + ACQUISITION FEE - DOWN PAYMENT)
      *
           COMPUTE WS-ADJUSTED-CAP-COST ROUNDED =
               LS-LR-CAP-COST
               + LS-LR-ACQUISITION-FEE
               - LS-LR-CAP-REDUCTION
           END-COMPUTE
      *
      *    STEP 3: NET CAP COST (FOR REFERENCE)
      *
           COMPUTE WS-NET-CAP-COST ROUNDED =
               WS-ADJUSTED-CAP-COST
           END-COMPUTE
      *
      *    STEP 4: TOTAL DEPRECIATION OVER LEASE TERM
      *
           COMPUTE WS-DEPRECIATION-TOTAL ROUNDED =
               WS-ADJUSTED-CAP-COST - WS-RESIDUAL-AMOUNT
           END-COMPUTE
      *
      *    STEP 5: MONTHLY DEPRECIATION CHARGE
      *
           IF LS-LR-TERM-MONTHS > +0
               COMPUTE WS-MONTHLY-DEPRECIATION ROUNDED =
                   WS-DEPRECIATION-TOTAL / LS-LR-TERM-MONTHS
               END-COMPUTE
           ELSE
               MOVE +0 TO WS-MONTHLY-DEPRECIATION
           END-IF
      *
      *    STEP 6: FINANCE BASE (ADJ CAP + RESIDUAL)
      *
           COMPUTE WS-FINANCE-BASE ROUNDED =
               WS-ADJUSTED-CAP-COST + WS-RESIDUAL-AMOUNT
           END-COMPUTE
      *
      *    STEP 7: MONTHLY FINANCE CHARGE
      *            MONEY FACTOR * (ADJUSTED CAP + RESIDUAL)
      *
           COMPUTE WS-MONTHLY-FINANCE ROUNDED =
               WS-FINANCE-BASE * LS-LR-MONEY-FACTOR
           END-COMPUTE
      *
      *    STEP 8: MONTHLY PRETAX PAYMENT
      *
           COMPUTE WS-MONTHLY-PRETAX ROUNDED =
               WS-MONTHLY-DEPRECIATION + WS-MONTHLY-FINANCE
           END-COMPUTE
      *
      *    STEP 9: MONTHLY TAX
      *
           COMPUTE WS-MONTHLY-TAX ROUNDED =
               WS-MONTHLY-PRETAX * (LS-LR-TAX-RATE / 100)
           END-COMPUTE
      *
      *    STEP 10: TOTAL MONTHLY PAYMENT
      *
           COMPUTE WS-MONTHLY-TOTAL ROUNDED =
               WS-MONTHLY-PRETAX + WS-MONTHLY-TAX
           END-COMPUTE
      *
      *    STEP 11: APPROXIMATE APR (MONEY FACTOR * 2400)
      *
           COMPUTE WS-APPROX-APR ROUNDED =
               LS-LR-MONEY-FACTOR * 2400
           END-COMPUTE
      *
      *    POPULATE RESULT FIELDS
      *
           MOVE WS-RESIDUAL-AMOUNT     TO LS-RS-RESIDUAL-AMT
           MOVE WS-ADJUSTED-CAP-COST   TO LS-RS-ADJ-CAP-COST
           MOVE WS-NET-CAP-COST        TO LS-RS-NET-CAP-COST
           MOVE WS-DEPRECIATION-TOTAL  TO LS-RS-DEPRECIATION
           MOVE WS-MONTHLY-DEPRECIATION TO LS-RS-MONTHLY-DEPR
           MOVE WS-MONTHLY-FINANCE     TO LS-RS-MONTHLY-FIN
           MOVE WS-MONTHLY-TAX         TO LS-RS-MONTHLY-TAX
           MOVE WS-MONTHLY-TOTAL       TO LS-RS-MONTHLY-TOTAL
           MOVE WS-APPROX-APR          TO LS-RS-APPROX-APR
           .
      *
      ****************************************************************
      *    4000-CALCULATE-TOTALS - TOTAL OF PAYMENTS AND INTEREST    *
      ****************************************************************
       4000-CALCULATE-TOTALS.
      *
      *    TOTAL OF ALL MONTHLY PAYMENTS
      *
           COMPUTE WS-TOTAL-OF-PAYMENTS ROUNDED =
               WS-MONTHLY-TOTAL * LS-LR-TERM-MONTHS
           END-COMPUTE
      *
      *    TOTAL INTEREST COST (FINANCE CHARGES OVER TERM)
      *
           COMPUTE WS-TOTAL-INTEREST ROUNDED =
               WS-MONTHLY-FINANCE * LS-LR-TERM-MONTHS
           END-COMPUTE
      *
      *    TOTAL TAX OVER TERM
      *
           COMPUTE WS-TOTAL-TAX ROUNDED =
               WS-MONTHLY-TAX * LS-LR-TERM-MONTHS
           END-COMPUTE
      *
      *    TOTAL COST OF LEASE (PAYMENTS + DRIVE-OFF - SEC DEPOSIT)
      *
           COMPUTE LS-RS-FINANCE-CHARGE =
               WS-TOTAL-INTEREST
           END-COMPUTE
      *
           MOVE WS-TOTAL-OF-PAYMENTS  TO LS-RS-TOTAL-PAYMENTS
           MOVE WS-TOTAL-INTEREST     TO LS-RS-TOTAL-INTEREST
           MOVE WS-TOTAL-TAX          TO LS-RS-TOTAL-TAX
           .
      *
      ****************************************************************
      *    5000-CALCULATE-DRIVEOFF - DUE AT SIGNING AMOUNT           *
      *    = FIRST MONTH + SECURITY DEPOSIT + ACQ FEE + CAP REDUCT  *
      ****************************************************************
       5000-CALCULATE-DRIVEOFF.
      *
           COMPUTE WS-DRIVE-OFF-AMOUNT ROUNDED =
               WS-MONTHLY-TOTAL
               + LS-LR-SECURITY-DEPOSIT
               + LS-LR-ACQUISITION-FEE
               + LS-LR-CAP-REDUCTION
           END-COMPUTE
      *
           MOVE WS-DRIVE-OFF-AMOUNT TO LS-RS-DRIVE-OFF-AMT
      *
      *    TOTAL COST OF LEASE
      *    (ALL PAYMENTS + DRIVE-OFF - SECURITY DEPOSIT REFUND)
      *
           COMPUTE LS-RS-TOTAL-COST ROUNDED =
               WS-TOTAL-OF-PAYMENTS
               + LS-LR-CAP-REDUCTION
               + LS-LR-ACQUISITION-FEE
           END-COMPUTE
      *
      *    SET SUCCESS RETURN
      *
           MOVE +0 TO LS-RS-RETURN-CODE
           MOVE 'COMLESL0: LEASE CALCULATION COMPLETED SUCCESSFULLY'
               TO LS-RS-RETURN-MSG
           .
      ****************************************************************
      * END OF COMLESL0                                               *
      ****************************************************************
