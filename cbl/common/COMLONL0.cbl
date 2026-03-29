       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMLONL0.
      ****************************************************************
      * PROGRAM:  COMLONL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - LOAN CALCULATION MODULE                   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CALCULATES AUTO LOAN PAYMENTS USING STANDARD       *
      *           AMORTIZATION FORMULA. PROVIDES MONTHLY PAYMENT,    *
      *           TOTAL INTEREST, TOTAL OF PAYMENTS, AND FIRST       *
      *           12-MONTH AMORTIZATION SCHEDULE.                    *
      * CALLABLE: YES - VIA CALL 'COMLONL0' USING LS-LOAN-REQUEST   *
      *                                            LS-LOAN-RESULT    *
      * FORMULA:  M = P * [r(1+r)^n] / [(1+r)^n - 1]               *
      *           WHERE: P = PRINCIPAL                               *
      *                  r = MONTHLY RATE (APR / 12 / 100)           *
      *                  n = NUMBER OF MONTHS                        *
      * NOTES:    HANDLES 0% APR AS SPECIAL CASE (SIMPLE DIVIDE)    *
      *           SHORT TERMS (< 12 MONTHS) ADJUST AMORT TABLE      *
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
                                          VALUE 'COMLONL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    WORK FIELDS FOR LOAN CALCULATION
      *
       01  WS-CALC-WORK-FIELDS.
           05  WS-MONTHLY-RATE           PIC S9(01)V9(10) COMP-3
                                                       VALUE +0.
           05  WS-POWER-FACTOR           PIC S9(07)V9(10) COMP-3
                                                       VALUE +0.
           05  WS-NUMERATOR              PIC S9(11)V9(06) COMP-3
                                                       VALUE +0.
           05  WS-DENOMINATOR            PIC S9(11)V9(06) COMP-3
                                                       VALUE +0.
           05  WS-MONTHLY-PAYMENT        PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-OF-PAYMENTS      PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-INTEREST         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-REMAINING-BALANCE      PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-INTEREST-PORTION       PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-PRINCIPAL-PORTION      PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-CUM-INTEREST           PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-CUM-PRINCIPAL          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    LOOP CONTROL
      *
       01  WS-LOOP-FIELDS.
           05  WS-MONTH-INDEX            PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-AMORT-MONTHS           PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-POWER-INDEX            PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-TEMP-POWER             PIC S9(07)V9(10) COMP-3
                                                       VALUE +0.
      *
      *    VALIDATION FLAGS
      *
       01  WS-VALIDATION-FLAGS.
           05  WS-VALID-FLAG             PIC X(01)     VALUE 'Y'.
               88  WS-ALL-VALID                        VALUE 'Y'.
               88  WS-NOT-VALID                        VALUE 'N'.
      *
       LINKAGE SECTION.
      *
      *    LOAN CALCULATION REQUEST
      *
       01  LS-LOAN-REQUEST.
           05  LS-LN-FUNCTION            PIC X(04).
               88  LS-LN-CALCULATE                     VALUE 'CALC'.
               88  LS-LN-VALIDATE                      VALUE 'VALD'.
               88  LS-LN-AMORT-ONLY                    VALUE 'AMRT'.
           05  LS-LN-PRINCIPAL           PIC S9(09)V99 COMP-3.
           05  LS-LN-APR                 PIC S9(03)V9(04) COMP-3.
           05  LS-LN-TERM-MONTHS        PIC S9(04)    COMP.
           05  LS-LN-DEALER-CODE         PIC X(05).
           05  LS-LN-VIN                 PIC X(17).
      *
      *    LOAN CALCULATION RESULT
      *
       01  LS-LOAN-RESULT.
           05  LS-LR-RETURN-CODE         PIC S9(04)    COMP.
           05  LS-LR-RETURN-MSG          PIC X(79).
           05  LS-LR-MONTHLY-PMT         PIC S9(07)V99 COMP-3.
           05  LS-LR-TOTAL-PAYMENTS      PIC S9(09)V99 COMP-3.
           05  LS-LR-TOTAL-INTEREST      PIC S9(09)V99 COMP-3.
           05  LS-LR-MONTHLY-RATE        PIC S9(01)V9(08) COMP-3.
           05  LS-LR-AMORT-MONTHS        PIC S9(04)    COMP.
           05  LS-LR-AMORT-TABLE.
               10  LS-LR-AMORT-ENTRY     OCCURS 12 TIMES.
                   15  LS-AM-MONTH-NUM    PIC S9(04)    COMP.
                   15  LS-AM-PAYMENT      PIC S9(07)V99 COMP-3.
                   15  LS-AM-PRINCIPAL    PIC S9(07)V99 COMP-3.
                   15  LS-AM-INTEREST     PIC S9(07)V99 COMP-3.
                   15  LS-AM-CUM-INT      PIC S9(09)V99 COMP-3.
                   15  LS-AM-BALANCE      PIC S9(09)V99 COMP-3.
      *
       PROCEDURE DIVISION USING LS-LOAN-REQUEST
                                LS-LOAN-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           EVALUATE TRUE
               WHEN LS-LN-CALCULATE
                   PERFORM 2000-VALIDATE-INPUTS
                   IF WS-ALL-VALID
                       PERFORM 3000-CALCULATE-PAYMENT
                       PERFORM 4000-BUILD-AMORT-TABLE
                   END-IF
               WHEN LS-LN-VALIDATE
                   PERFORM 2000-VALIDATE-INPUTS
               WHEN LS-LN-AMORT-ONLY
                   PERFORM 2000-VALIDATE-INPUTS
                   IF WS-ALL-VALID
                       PERFORM 3000-CALCULATE-PAYMENT
                       PERFORM 4000-BUILD-AMORT-TABLE
                   END-IF
               WHEN OTHER
                   MOVE +16 TO LS-LR-RETURN-CODE
                   STRING 'COMLONL0: INVALID FUNCTION CODE: '
                          LS-LN-FUNCTION
                          DELIMITED BY SIZE
                          INTO LS-LR-RETURN-MSG
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
           INITIALIZE LS-LOAN-RESULT
           INITIALIZE WS-CALC-WORK-FIELDS
           MOVE 'Y' TO WS-VALID-FLAG
           MOVE +0  TO LS-LR-RETURN-CODE
           .
      *
      ****************************************************************
      *    2000-VALIDATE-INPUTS - VALIDATE ALL LOAN PARAMETERS       *
      ****************************************************************
       2000-VALIDATE-INPUTS.
      *
      *    VALIDATE PRINCIPAL AMOUNT
      *
           IF LS-LN-PRINCIPAL < +500.00
               MOVE 'N' TO WS-VALID-FLAG
               MOVE +8 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: PRINCIPAL MUST BE >= $500.00'
                   TO LS-LR-RETURN-MSG
           END-IF
      *
           IF LS-LN-PRINCIPAL > +999999.99
               MOVE 'N' TO WS-VALID-FLAG
               MOVE +8 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: PRINCIPAL EXCEEDS $999,999.99'
                   TO LS-LR-RETURN-MSG
           END-IF
      *
      *    VALIDATE APR (0% IS ALLOWED AS SPECIAL PROMOTION)
      *
           IF LS-LN-APR < +0
               MOVE 'N' TO WS-VALID-FLAG
               MOVE +8 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: APR CANNOT BE NEGATIVE'
                   TO LS-LR-RETURN-MSG
           END-IF
      *
           IF LS-LN-APR > +30.0000
               MOVE 'N' TO WS-VALID-FLAG
               MOVE +8 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: APR EXCEEDS 30% MAXIMUM'
                   TO LS-LR-RETURN-MSG
           END-IF
      *
      *    VALIDATE TERM
      *
           IF LS-LN-TERM-MONTHS < +6
               MOVE 'N' TO WS-VALID-FLAG
               MOVE +8 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: TERM MUST BE >= 6 MONTHS'
                   TO LS-LR-RETURN-MSG
           END-IF
      *
           IF LS-LN-TERM-MONTHS > +84
               MOVE 'N' TO WS-VALID-FLAG
               MOVE +8 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: TERM EXCEEDS 84 MONTHS MAXIMUM'
                   TO LS-LR-RETURN-MSG
           END-IF
      *
      *    IF ALL VALID, SET SUCCESS
      *
           IF WS-ALL-VALID
               MOVE +0 TO LS-LR-RETURN-CODE
               MOVE 'COMLONL0: ALL INPUTS VALIDATED SUCCESSFULLY'
                   TO LS-LR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    3000-CALCULATE-PAYMENT - MONTHLY PAYMENT CALCULATION      *
      *    M = P * [r(1+r)^n] / [(1+r)^n - 1]                      *
      *    SPECIAL CASE: 0% APR = P / n                             *
      ****************************************************************
       3000-CALCULATE-PAYMENT.
      *
      *    CHECK FOR 0% APR SPECIAL CASE
      *
           IF LS-LN-APR = +0
      *
      *        0% FINANCING - SIMPLE DIVISION
      *
               COMPUTE WS-MONTHLY-PAYMENT ROUNDED =
                   LS-LN-PRINCIPAL / LS-LN-TERM-MONTHS
               END-COMPUTE
               MOVE +0 TO WS-MONTHLY-RATE
               MOVE +0 TO WS-TOTAL-INTEREST
               COMPUTE WS-TOTAL-OF-PAYMENTS ROUNDED =
                   WS-MONTHLY-PAYMENT * LS-LN-TERM-MONTHS
               END-COMPUTE
           ELSE
      *
      *        STANDARD AMORTIZATION CALCULATION
      *
      *        STEP 1: COMPUTE MONTHLY RATE
      *
               COMPUTE WS-MONTHLY-RATE ROUNDED =
                   LS-LN-APR / 12 / 100
               END-COMPUTE
      *
      *        STEP 2: COMPUTE (1 + r) ^ n
      *        USE ITERATIVE MULTIPLICATION FOR PRECISION
      *
               MOVE +1.0 TO WS-POWER-FACTOR
               PERFORM VARYING WS-POWER-INDEX
                   FROM +1 BY +1
                   UNTIL WS-POWER-INDEX > LS-LN-TERM-MONTHS
                   COMPUTE WS-POWER-FACTOR ROUNDED =
                       WS-POWER-FACTOR * (+1 + WS-MONTHLY-RATE)
                   END-COMPUTE
               END-PERFORM
      *
      *        STEP 3: COMPUTE NUMERATOR = P * r * (1+r)^n
      *
               COMPUTE WS-NUMERATOR ROUNDED =
                   LS-LN-PRINCIPAL * WS-MONTHLY-RATE
                   * WS-POWER-FACTOR
               END-COMPUTE
      *
      *        STEP 4: COMPUTE DENOMINATOR = (1+r)^n - 1
      *
               COMPUTE WS-DENOMINATOR ROUNDED =
                   WS-POWER-FACTOR - +1
               END-COMPUTE
      *
      *        STEP 5: COMPUTE MONTHLY PAYMENT
      *
               IF WS-DENOMINATOR NOT = +0
                   COMPUTE WS-MONTHLY-PAYMENT ROUNDED =
                       WS-NUMERATOR / WS-DENOMINATOR
                   END-COMPUTE
               ELSE
                   COMPUTE WS-MONTHLY-PAYMENT ROUNDED =
                       LS-LN-PRINCIPAL / LS-LN-TERM-MONTHS
                   END-COMPUTE
               END-IF
      *
      *        STEP 6: TOTAL OF PAYMENTS AND TOTAL INTEREST
      *
               COMPUTE WS-TOTAL-OF-PAYMENTS ROUNDED =
                   WS-MONTHLY-PAYMENT * LS-LN-TERM-MONTHS
               END-COMPUTE
      *
               COMPUTE WS-TOTAL-INTEREST ROUNDED =
                   WS-TOTAL-OF-PAYMENTS - LS-LN-PRINCIPAL
               END-COMPUTE
           END-IF
      *
      *    POPULATE RESULT FIELDS
      *
           MOVE WS-MONTHLY-PAYMENT    TO LS-LR-MONTHLY-PMT
           MOVE WS-TOTAL-OF-PAYMENTS  TO LS-LR-TOTAL-PAYMENTS
           MOVE WS-TOTAL-INTEREST     TO LS-LR-TOTAL-INTEREST
           MOVE WS-MONTHLY-RATE       TO LS-LR-MONTHLY-RATE
      *
           MOVE +0 TO LS-LR-RETURN-CODE
           MOVE 'COMLONL0: PAYMENT CALCULATION COMPLETED'
               TO LS-LR-RETURN-MSG
           .
      *
      ****************************************************************
      *    4000-BUILD-AMORT-TABLE - FIRST 12 MONTH AMORTIZATION     *
      ****************************************************************
       4000-BUILD-AMORT-TABLE.
      *
      *    DETERMINE NUMBER OF AMORTIZATION MONTHS TO SHOW
      *    (MINIMUM OF TERM OR 12)
      *
           IF LS-LN-TERM-MONTHS < +12
               MOVE LS-LN-TERM-MONTHS TO WS-AMORT-MONTHS
           ELSE
               MOVE +12 TO WS-AMORT-MONTHS
           END-IF
      *
           MOVE WS-AMORT-MONTHS TO LS-LR-AMORT-MONTHS
      *
      *    INITIALIZE RUNNING BALANCES
      *
           MOVE LS-LN-PRINCIPAL TO WS-REMAINING-BALANCE
           MOVE +0 TO WS-CUM-INTEREST
           MOVE +0 TO WS-CUM-PRINCIPAL
      *
      *    BUILD EACH AMORTIZATION ROW
      *
           PERFORM VARYING WS-MONTH-INDEX
               FROM +1 BY +1
               UNTIL WS-MONTH-INDEX > WS-AMORT-MONTHS
      *
      *        CHECK FOR 0% APR
      *
               IF LS-LN-APR = +0
                   MOVE +0 TO WS-INTEREST-PORTION
                   MOVE WS-MONTHLY-PAYMENT
                       TO WS-PRINCIPAL-PORTION
               ELSE
      *
      *            INTEREST FOR THIS MONTH
      *
                   COMPUTE WS-INTEREST-PORTION ROUNDED =
                       WS-REMAINING-BALANCE * WS-MONTHLY-RATE
                   END-COMPUTE
      *
      *            PRINCIPAL FOR THIS MONTH
      *
                   COMPUTE WS-PRINCIPAL-PORTION ROUNDED =
                       WS-MONTHLY-PAYMENT - WS-INTEREST-PORTION
                   END-COMPUTE
               END-IF
      *
      *        HANDLE LAST PAYMENT ADJUSTMENT
      *
               IF WS-MONTH-INDEX = LS-LN-TERM-MONTHS
                   IF WS-PRINCIPAL-PORTION > WS-REMAINING-BALANCE
                       MOVE WS-REMAINING-BALANCE
                           TO WS-PRINCIPAL-PORTION
                       COMPUTE WS-MONTHLY-PAYMENT ROUNDED =
                           WS-PRINCIPAL-PORTION
                           + WS-INTEREST-PORTION
                       END-COMPUTE
                   END-IF
               END-IF
      *
      *        UPDATE CUMULATIVE TOTALS
      *
               ADD WS-INTEREST-PORTION  TO WS-CUM-INTEREST
               ADD WS-PRINCIPAL-PORTION TO WS-CUM-PRINCIPAL
      *
      *        UPDATE REMAINING BALANCE
      *
               SUBTRACT WS-PRINCIPAL-PORTION
                   FROM WS-REMAINING-BALANCE
      *
      *        PREVENT NEGATIVE BALANCE DUE TO ROUNDING
      *
               IF WS-REMAINING-BALANCE < +0
                   MOVE +0 TO WS-REMAINING-BALANCE
               END-IF
      *
      *        POPULATE AMORTIZATION TABLE ROW
      *
               MOVE WS-MONTH-INDEX
                   TO LS-AM-MONTH-NUM(WS-MONTH-INDEX)
               MOVE WS-MONTHLY-PAYMENT
                   TO LS-AM-PAYMENT(WS-MONTH-INDEX)
               MOVE WS-PRINCIPAL-PORTION
                   TO LS-AM-PRINCIPAL(WS-MONTH-INDEX)
               MOVE WS-INTEREST-PORTION
                   TO LS-AM-INTEREST(WS-MONTH-INDEX)
               MOVE WS-CUM-INTEREST
                   TO LS-AM-CUM-INT(WS-MONTH-INDEX)
               MOVE WS-REMAINING-BALANCE
                   TO LS-AM-BALANCE(WS-MONTH-INDEX)
      *
           END-PERFORM
      *
           MOVE +0 TO LS-LR-RETURN-CODE
           MOVE 'COMLONL0: LOAN CALCULATION COMPLETED SUCCESSFULLY'
               TO LS-LR-RETURN-MSG
           .
      ****************************************************************
      * END OF COMLONL0                                               *
      ****************************************************************
