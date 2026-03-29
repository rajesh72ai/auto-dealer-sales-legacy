       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMINTL0.
      ****************************************************************
      * PROGRAM:  COMINTL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - INTEREST CALCULATION MODULE (FLOOR PLAN)  *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CALCULATES DAILY INTEREST FOR FLOOR PLAN VEHICLES. *
      *           SUPPORTS MULTIPLE DAY COUNT CONVENTIONS:            *
      *           - 30/360 (BANKER'S YEAR)                           *
      *           - ACTUAL/365                                       *
      *           - ACTUAL/ACTUAL                                    *
      *           DETERMINES CURTAILMENT STATUS AND CUMULATIVE       *
      *           INTEREST FROM THE FLOOR DATE.                      *
      * CALLABLE: YES - VIA CALL 'COMINTL0' USING LS-INT-REQUEST    *
      *                                            LS-INT-RESULT     *
      * TABLES:   AUTOSALE.FLOOR_PLAN_VEHICLE (READ)                *
      *           AUTOSALE.FLOOR_PLAN_INTEREST (INSERT)              *
      * NOTES:    CURTAILMENT PERIOD VARIES BY LENDER (TYPICALLY     *
      *           90 DAYS FOR NEW, 60 DAYS FOR USED)                 *
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
                                          VALUE 'COMINTL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    COPY IN SQLCA
      *
           COPY WSSQLCA.
      *
      *    COPY IN DCLGEN FOR FLOOR_PLAN_VEHICLE
      *
           COPY DCLFPVEH.
      *
      *    COPY IN DCLGEN FOR FLOOR_PLAN_INTEREST
      *
           COPY DCLFPINT.
      *
      *    COPY IN FLOOR PLAN WORKING STORAGE
      *
           COPY WSFPL000.
      *
      *    WORK FIELDS FOR INTEREST CALCULATION
      *
       01  WS-INT-WORK-FIELDS.
           05  WS-ANNUAL-RATE            PIC S9(03)V9(06) COMP-3
                                                       VALUE +0.
           05  WS-DAILY-RATE             PIC S9(01)V9(10) COMP-3
                                                       VALUE +0.
           05  WS-DAILY-INTEREST         PIC S9(07)V9(04) COMP-3
                                                       VALUE +0.
           05  WS-DAYS-ACCRUED           PIC S9(05)    COMP
                                                       VALUE +0.
           05  WS-CUMULATIVE-INT         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-PRINCIPAL-BALANCE      PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-DAY-COUNT-DIVISOR      PIC S9(05)    COMP
                                                       VALUE +360.
           05  WS-CURTAIL-DAYS           PIC S9(05)    COMP
                                                       VALUE +0.
           05  WS-CURTAIL-LIMIT-NEW      PIC S9(05)    COMP
                                                       VALUE +90.
           05  WS-CURTAIL-LIMIT-USED     PIC S9(05)    COMP
                                                       VALUE +60.
      *
      *    DATE CALCULATION FIELDS
      *
       01  WS-DATE-CALC-FIELDS.
           05  WS-CALC-DATE-INT          PIC S9(09)    COMP
                                                       VALUE +0.
           05  WS-LAST-CALC-INT          PIC S9(09)    COMP
                                                       VALUE +0.
           05  WS-FLOOR-DATE-INT         PIC S9(09)    COMP
                                                       VALUE +0.
           05  WS-CURTAIL-DATE-INT       PIC S9(09)    COMP
                                                       VALUE +0.
           05  WS-DAYS-BETWEEN           PIC S9(05)    COMP
                                                       VALUE +0.
           05  WS-DAYS-SINCE-FLOOR       PIC S9(05)    COMP
                                                       VALUE +0.
           05  WS-DAYS-SINCE-CURTAIL     PIC S9(05)    COMP
                                                       VALUE +0.
      *
      *    DATE DECOMPOSITION FOR INTEGER DATE CONVERSION
      *
       01  WS-DATE-DECOMP.
           05  WS-DD-YYYY               PIC 9(04)    VALUE ZEROS.
           05  WS-DD-MM                  PIC 9(02)    VALUE ZEROS.
           05  WS-DD-DD                  PIC 9(02)    VALUE ZEROS.
      *
      *    LEAP YEAR WORK FIELDS
      *
       01  WS-LEAP-YEAR-FIELDS.
           05  WS-LY-YEAR               PIC 9(04)    VALUE ZEROS.
           05  WS-LY-REMAINDER-4        PIC 9(04)    VALUE ZEROS.
           05  WS-LY-REMAINDER-100      PIC 9(04)    VALUE ZEROS.
           05  WS-LY-REMAINDER-400      PIC 9(04)    VALUE ZEROS.
           05  WS-LY-IS-LEAP            PIC X(01)    VALUE 'N'.
               88  WS-IS-LEAP-YEAR                   VALUE 'Y'.
               88  WS-NOT-LEAP-YEAR                  VALUE 'N'.
           05  WS-DAYS-IN-YEAR           PIC 9(03)    VALUE 365.
      *
      *    MONTH DAYS TABLE
      *
       01  WS-MONTH-DAYS-TABLE.
           05  FILLER                    PIC 9(02) VALUE 31.
           05  FILLER                    PIC 9(02) VALUE 28.
           05  FILLER                    PIC 9(02) VALUE 31.
           05  FILLER                    PIC 9(02) VALUE 30.
           05  FILLER                    PIC 9(02) VALUE 31.
           05  FILLER                    PIC 9(02) VALUE 30.
           05  FILLER                    PIC 9(02) VALUE 31.
           05  FILLER                    PIC 9(02) VALUE 31.
           05  FILLER                    PIC 9(02) VALUE 30.
           05  FILLER                    PIC 9(02) VALUE 31.
           05  FILLER                    PIC 9(02) VALUE 30.
           05  FILLER                    PIC 9(02) VALUE 31.
       01  WS-MONTH-DAYS REDEFINES WS-MONTH-DAYS-TABLE.
           05  WS-MDAY                   PIC 9(02)
                                          OCCURS 12 TIMES.
      *
      *    LOOP COUNTER
      *
       01  WS-LOOP-INDEX                 PIC S9(04)   COMP
                                                       VALUE +0.
      *
      *    DATETIME FIELDS
      *
       01  WS-DATETIME-FIELDS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURR-YYYY          PIC 9(04).
               10  WS-CURR-MM            PIC 9(02).
               10  WS-CURR-DD            PIC 9(02).
           05  WS-CURRENT-TIME-DATA.
               10  WS-CURR-HH            PIC 9(02).
               10  WS-CURR-MN            PIC 9(02).
               10  WS-CURR-SS            PIC 9(02).
               10  WS-CURR-HS            PIC 9(02).
           05  WS-DIFF-FROM-GMT          PIC S9(04).
      *
       LINKAGE SECTION.
      *
      *    INTEREST CALCULATION REQUEST
      *
       01  LS-INT-REQUEST.
           05  LS-IR-FUNCTION            PIC X(04).
               88  LS-IR-CALC-DAILY                    VALUE 'DALY'.
               88  LS-IR-CALC-RANGE                    VALUE 'RNGE'.
               88  LS-IR-CALC-CUMUL                    VALUE 'CUML'.
           05  LS-IR-PRINCIPAL           PIC S9(09)V99 COMP-3.
           05  LS-IR-ANNUAL-RATE         PIC S9(03)V9(06) COMP-3.
           05  LS-IR-CALC-DATE           PIC X(10).
           05  LS-IR-LAST-CALC-DATE      PIC X(10).
           05  LS-IR-FLOOR-DATE          PIC X(10).
           05  LS-IR-CURTAIL-DATE        PIC X(10).
           05  LS-IR-DAY-COUNT-BASIS     PIC X(05).
               88  LS-IR-BASIS-360                     VALUE '360  '.
               88  LS-IR-BASIS-365                     VALUE '365  '.
               88  LS-IR-BASIS-ACTUAL                  VALUE 'ACT  '.
           05  LS-IR-VEHICLE-TYPE        PIC X(02).
               88  LS-IR-NEW-VEHICLE                   VALUE 'NW'.
               88  LS-IR-USED-VEHICLE                  VALUE 'US'.
           05  LS-IR-FLOOR-PLAN-ID       PIC S9(09)   COMP.
      *
      *    INTEREST CALCULATION RESULT
      *
       01  LS-INT-RESULT.
           05  LS-RS-RETURN-CODE         PIC S9(04)   COMP.
           05  LS-RS-RETURN-MSG          PIC X(79).
           05  LS-RS-DAILY-RATE          PIC S9(01)V9(10) COMP-3.
           05  LS-RS-DAILY-INTEREST      PIC S9(07)V9(04) COMP-3.
           05  LS-RS-DAYS-ACCRUED        PIC S9(05)   COMP.
           05  LS-RS-CUMULATIVE-INT      PIC S9(09)V99 COMP-3.
           05  LS-RS-DAYS-ON-FLOOR       PIC S9(05)   COMP.
           05  LS-RS-CURTAIL-FLAG        PIC X(01).
               88  LS-RS-CURTAIL-DUE                   VALUE 'Y'.
               88  LS-RS-CURTAIL-OK                    VALUE 'N'.
           05  LS-RS-DAYS-PAST-CURTAIL   PIC S9(05)   COMP.
           05  LS-RS-PERIOD-INTEREST     PIC S9(09)V99 COMP-3.
           05  LS-RS-SQLCODE             PIC S9(09)   COMP.
      *
       PROCEDURE DIVISION USING LS-INT-REQUEST
                                LS-INT-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-VALIDATE-INPUTS
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 3000-DETERMINE-DAY-COUNT
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 4000-CALCULATE-DAILY-RATE
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN LS-IR-CALC-DAILY
                       PERFORM 5000-CALC-DAILY-INTEREST
                   WHEN LS-IR-CALC-RANGE
                       PERFORM 5000-CALC-DAILY-INTEREST
                       PERFORM 6000-CALC-RANGE-INTEREST
                   WHEN LS-IR-CALC-CUMUL
                       PERFORM 5000-CALC-DAILY-INTEREST
                       PERFORM 7000-CALC-CUMULATIVE
               END-EVALUATE
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 8000-CHECK-CURTAILMENT
           END-IF
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-INT-RESULT
           INITIALIZE WS-INT-WORK-FIELDS
           INITIALIZE WS-DATE-CALC-FIELDS
           MOVE +0  TO LS-RS-RETURN-CODE
           MOVE 'N' TO LS-RS-CURTAIL-FLAG
           MOVE +0  TO LS-RS-DAYS-PAST-CURTAIL
      *
           MOVE FUNCTION CURRENT-DATE
               TO WS-CURRENT-DATE-DATA
                  WS-CURRENT-TIME-DATA
                  WS-DIFF-FROM-GMT
           .
      *
      ****************************************************************
      *    2000-VALIDATE-INPUTS                                      *
      ****************************************************************
       2000-VALIDATE-INPUTS.
      *
           IF  NOT LS-IR-CALC-DAILY
           AND NOT LS-IR-CALC-RANGE
           AND NOT LS-IR-CALC-CUMUL
               MOVE +8 TO LS-RS-RETURN-CODE
               STRING 'COMINTL0: INVALID FUNCTION: '
                      LS-IR-FUNCTION
                      DELIMITED BY SIZE
                      INTO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-IR-PRINCIPAL <= +0
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMINTL0: PRINCIPAL BALANCE MUST BE > 0'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-IR-ANNUAL-RATE <= +0
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMINTL0: ANNUAL RATE MUST BE > 0'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-IR-ANNUAL-RATE > +25.000000
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMINTL0: ANNUAL RATE EXCEEDS 25% MAXIMUM'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-IR-CALC-DATE = SPACES
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMINTL0: CALCULATION DATE IS REQUIRED'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
           IF  NOT LS-IR-BASIS-360
           AND NOT LS-IR-BASIS-365
           AND NOT LS-IR-BASIS-ACTUAL
               MOVE +4 TO LS-RS-RETURN-CODE
               MOVE 'COMINTL0: INVALID BASIS - DEFAULTING TO 360'
                   TO LS-RS-RETURN-MSG
               MOVE '360  ' TO LS-IR-DAY-COUNT-BASIS
               MOVE +0 TO LS-RS-RETURN-CODE
           END-IF
      *
           MOVE LS-IR-PRINCIPAL TO WS-PRINCIPAL-BALANCE
           MOVE LS-IR-ANNUAL-RATE TO WS-ANNUAL-RATE
           .
      *
      ****************************************************************
      *    3000-DETERMINE-DAY-COUNT - SET DIVISOR AND CALC DAYS      *
      ****************************************************************
       3000-DETERMINE-DAY-COUNT.
      *
           EVALUATE TRUE
               WHEN LS-IR-BASIS-360
      *            BANKER'S YEAR: 360 DAYS
                   MOVE +360 TO WS-DAY-COUNT-DIVISOR
      *
               WHEN LS-IR-BASIS-365
      *            FIXED 365 DAYS
                   MOVE +365 TO WS-DAY-COUNT-DIVISOR
      *
               WHEN LS-IR-BASIS-ACTUAL
      *            ACTUAL DAYS IN THE YEAR
                   MOVE LS-IR-CALC-DATE(1:4) TO WS-LY-YEAR
                   PERFORM 9000-CHECK-LEAP-YEAR
                   IF WS-IS-LEAP-YEAR
                       MOVE +366 TO WS-DAY-COUNT-DIVISOR
                       MOVE 366 TO WS-DAYS-IN-YEAR
                   ELSE
                       MOVE +365 TO WS-DAY-COUNT-DIVISOR
                       MOVE 365 TO WS-DAYS-IN-YEAR
                   END-IF
           END-EVALUATE
      *
      *    CALCULATE DAYS FROM FLOOR DATE TO CALC DATE
      *
           IF LS-IR-FLOOR-DATE NOT = SPACES
               PERFORM 9100-DATE-TO-INTEGER-FLOOR
               PERFORM 9200-DATE-TO-INTEGER-CALC
               COMPUTE WS-DAYS-SINCE-FLOOR =
                   WS-CALC-DATE-INT - WS-FLOOR-DATE-INT
               END-COMPUTE
               MOVE WS-DAYS-SINCE-FLOOR TO LS-RS-DAYS-ON-FLOOR
           END-IF
      *
      *    CALCULATE DAYS FROM LAST CALC DATE TO CALC DATE
      *
           IF LS-IR-LAST-CALC-DATE NOT = SPACES
               PERFORM 9300-DATE-TO-INTEGER-LAST
               COMPUTE WS-DAYS-BETWEEN =
                   WS-CALC-DATE-INT - WS-LAST-CALC-INT
               END-COMPUTE
           ELSE
               MOVE +1 TO WS-DAYS-BETWEEN
           END-IF
      *
           MOVE WS-DAYS-BETWEEN TO WS-DAYS-ACCRUED
           .
      *
      ****************************************************************
      *    4000-CALCULATE-DAILY-RATE                                 *
      *    DAILY RATE = ANNUAL RATE / DAY-COUNT-DIVISOR / 100        *
      ****************************************************************
       4000-CALCULATE-DAILY-RATE.
      *
           COMPUTE WS-DAILY-RATE ROUNDED =
               WS-ANNUAL-RATE / WS-DAY-COUNT-DIVISOR / 100
           END-COMPUTE
      *
           MOVE WS-DAILY-RATE TO LS-RS-DAILY-RATE
           .
      *
      ****************************************************************
      *    5000-CALC-DAILY-INTEREST                                  *
      *    DAILY INTEREST = PRINCIPAL * DAILY RATE                   *
      ****************************************************************
       5000-CALC-DAILY-INTEREST.
      *
           COMPUTE WS-DAILY-INTEREST ROUNDED =
               WS-PRINCIPAL-BALANCE * WS-DAILY-RATE
           END-COMPUTE
      *
           MOVE WS-DAILY-INTEREST TO LS-RS-DAILY-INTEREST
           MOVE WS-DAYS-ACCRUED   TO LS-RS-DAYS-ACCRUED
      *
           MOVE +0 TO LS-RS-RETURN-CODE
           MOVE 'COMINTL0: DAILY INTEREST CALCULATED'
               TO LS-RS-RETURN-MSG
           .
      *
      ****************************************************************
      *    6000-CALC-RANGE-INTEREST - INTEREST FOR DATE RANGE        *
      ****************************************************************
       6000-CALC-RANGE-INTEREST.
      *
      *    PERIOD INTEREST = DAILY INTEREST * DAYS IN RANGE
      *
           IF WS-DAYS-BETWEEN > +0
               COMPUTE LS-RS-PERIOD-INTEREST ROUNDED =
                   WS-DAILY-INTEREST * WS-DAYS-BETWEEN
               END-COMPUTE
           ELSE
               MOVE +0 TO LS-RS-PERIOD-INTEREST
           END-IF
      *
           MOVE 'COMINTL0: RANGE INTEREST CALCULATED'
               TO LS-RS-RETURN-MSG
           .
      *
      ****************************************************************
      *    7000-CALC-CUMULATIVE - TOTAL INTEREST FROM FLOOR DATE     *
      ****************************************************************
       7000-CALC-CUMULATIVE.
      *
      *    CUMULATIVE = DAILY INTEREST * DAYS SINCE FLOOR
      *    (SIMPLIFIED CALCULATION - ASSUMES CONSTANT BALANCE)
      *
           IF WS-DAYS-SINCE-FLOOR > +0
               COMPUTE WS-CUMULATIVE-INT ROUNDED =
                   WS-DAILY-INTEREST * WS-DAYS-SINCE-FLOOR
               END-COMPUTE
           ELSE
               MOVE WS-DAILY-INTEREST TO WS-CUMULATIVE-INT
           END-IF
      *
           MOVE WS-CUMULATIVE-INT TO LS-RS-CUMULATIVE-INT
      *
      *    ALSO CALCULATE PERIOD INTEREST
      *
           IF WS-DAYS-BETWEEN > +0
               COMPUTE LS-RS-PERIOD-INTEREST ROUNDED =
                   WS-DAILY-INTEREST * WS-DAYS-BETWEEN
               END-COMPUTE
           END-IF
      *
      *    IF FLOOR_PLAN_ID PROVIDED, INSERT INTEREST RECORD
      *
           IF LS-IR-FLOOR-PLAN-ID > +0
               PERFORM 7100-INSERT-INTEREST-RECORD
           END-IF
      *
           MOVE 'COMINTL0: CUMULATIVE INTEREST CALCULATED'
               TO LS-RS-RETURN-MSG
           .
      *
      ****************************************************************
      *    7100-INSERT-INTEREST-RECORD - INSERT INTO DB2             *
      ****************************************************************
       7100-INSERT-INTEREST-RECORD.
      *
           MOVE LS-IR-FLOOR-PLAN-ID TO FLOOR-PLAN-ID
                                       OF DCLFLOOR-PLAN-INTEREST
           MOVE LS-IR-CALC-DATE     TO CALC-DATE
           MOVE WS-PRINCIPAL-BALANCE TO PRINCIPAL-BAL
           MOVE WS-ANNUAL-RATE      TO RATE-APPLIED
           MOVE WS-DAILY-INTEREST   TO DAILY-INTEREST
                                       OF DCLFLOOR-PLAN-INTEREST
           MOVE WS-CUMULATIVE-INT   TO CUMULATIVE-INT
      *
           EXEC SQL
               INSERT INTO AUTOSALE.FLOOR_PLAN_INTEREST
                    ( FLOOR_PLAN_ID
                    , CALC_DATE
                    , PRINCIPAL_BAL
                    , RATE_APPLIED
                    , DAILY_INTEREST
                    , CUMULATIVE_INT
                    )
               VALUES
                    ( :FLOOR-PLAN-ID
                       OF DCLFLOOR-PLAN-INTEREST
                    , :CALC-DATE
                    , :PRINCIPAL-BAL
                    , :RATE-APPLIED
                    , :DAILY-INTEREST
                       OF DCLFLOOR-PLAN-INTEREST
                    , :CUMULATIVE-INT
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO LS-RS-SQLCODE
               MOVE +4 TO LS-RS-RETURN-CODE
               MOVE
               'COMINTL0: WARNING - ERROR INSERTING INTEREST RECORD'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    8000-CHECK-CURTAILMENT - DETERMINE CURTAILMENT STATUS     *
      ****************************************************************
       8000-CHECK-CURTAILMENT.
      *
      *    DETERMINE CURTAILMENT LIMIT BY VEHICLE TYPE
      *
           IF LS-IR-NEW-VEHICLE
               MOVE WS-CURTAIL-LIMIT-NEW TO WS-CURTAIL-DAYS
           ELSE
               MOVE WS-CURTAIL-LIMIT-USED TO WS-CURTAIL-DAYS
           END-IF
      *
      *    CHECK IF CURTAILMENT DATE IS KNOWN
      *
           IF LS-IR-CURTAIL-DATE NOT = SPACES
      *        COMPARE CALC DATE TO CURTAILMENT DATE
               PERFORM 9400-DATE-TO-INTEGER-CURTAIL
               COMPUTE WS-DAYS-SINCE-CURTAIL =
                   WS-CALC-DATE-INT - WS-CURTAIL-DATE-INT
               END-COMPUTE
      *
               IF WS-DAYS-SINCE-CURTAIL > +0
      *            PAST CURTAILMENT DATE
                   MOVE 'Y' TO LS-RS-CURTAIL-FLAG
                   MOVE WS-DAYS-SINCE-CURTAIL
                       TO LS-RS-DAYS-PAST-CURTAIL
               ELSE
                   MOVE 'N' TO LS-RS-CURTAIL-FLAG
                   MOVE +0 TO LS-RS-DAYS-PAST-CURTAIL
               END-IF
           ELSE
      *        NO CURTAILMENT DATE - USE DAYS ON FLOOR
               IF WS-DAYS-SINCE-FLOOR > WS-CURTAIL-DAYS
                   MOVE 'Y' TO LS-RS-CURTAIL-FLAG
                   COMPUTE LS-RS-DAYS-PAST-CURTAIL =
                       WS-DAYS-SINCE-FLOOR - WS-CURTAIL-DAYS
                   END-COMPUTE
               ELSE
                   MOVE 'N' TO LS-RS-CURTAIL-FLAG
                   MOVE +0 TO LS-RS-DAYS-PAST-CURTAIL
               END-IF
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               MOVE 'COMINTL0: INTEREST CALCULATION COMPLETE'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    9000-CHECK-LEAP-YEAR                                      *
      ****************************************************************
       9000-CHECK-LEAP-YEAR.
      *
           MOVE 'N' TO WS-LY-IS-LEAP
      *
           DIVIDE WS-LY-YEAR BY 4
               GIVING WS-LY-YEAR REMAINDER WS-LY-REMAINDER-4
           DIVIDE WS-LY-YEAR BY 100
               GIVING WS-LY-YEAR REMAINDER WS-LY-REMAINDER-100
           DIVIDE WS-LY-YEAR BY 400
               GIVING WS-LY-YEAR REMAINDER WS-LY-REMAINDER-400
      *
           IF WS-LY-REMAINDER-4 = 0
               IF WS-LY-REMAINDER-100 NOT = 0
                   MOVE 'Y' TO WS-LY-IS-LEAP
               ELSE
                   IF WS-LY-REMAINDER-400 = 0
                       MOVE 'Y' TO WS-LY-IS-LEAP
                   END-IF
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    9100-DATE-TO-INTEGER-FLOOR - CONVERT FLOOR DATE           *
      ****************************************************************
       9100-DATE-TO-INTEGER-FLOOR.
      *
           MOVE LS-IR-FLOOR-DATE(1:4) TO WS-DD-YYYY
           MOVE LS-IR-FLOOR-DATE(6:2) TO WS-DD-MM
           MOVE LS-IR-FLOOR-DATE(9:2) TO WS-DD-DD
      *
           COMPUTE WS-FLOOR-DATE-INT =
               FUNCTION INTEGER-OF-DATE(
                   WS-DD-YYYY * 10000 +
                   WS-DD-MM * 100 +
                   WS-DD-DD)
           END-COMPUTE
           .
      *
      ****************************************************************
      *    9200-DATE-TO-INTEGER-CALC - CONVERT CALC DATE             *
      ****************************************************************
       9200-DATE-TO-INTEGER-CALC.
      *
           MOVE LS-IR-CALC-DATE(1:4) TO WS-DD-YYYY
           MOVE LS-IR-CALC-DATE(6:2) TO WS-DD-MM
           MOVE LS-IR-CALC-DATE(9:2) TO WS-DD-DD
      *
           COMPUTE WS-CALC-DATE-INT =
               FUNCTION INTEGER-OF-DATE(
                   WS-DD-YYYY * 10000 +
                   WS-DD-MM * 100 +
                   WS-DD-DD)
           END-COMPUTE
           .
      *
      ****************************************************************
      *    9300-DATE-TO-INTEGER-LAST - CONVERT LAST CALC DATE        *
      ****************************************************************
       9300-DATE-TO-INTEGER-LAST.
      *
           MOVE LS-IR-LAST-CALC-DATE(1:4) TO WS-DD-YYYY
           MOVE LS-IR-LAST-CALC-DATE(6:2) TO WS-DD-MM
           MOVE LS-IR-LAST-CALC-DATE(9:2) TO WS-DD-DD
      *
           COMPUTE WS-LAST-CALC-INT =
               FUNCTION INTEGER-OF-DATE(
                   WS-DD-YYYY * 10000 +
                   WS-DD-MM * 100 +
                   WS-DD-DD)
           END-COMPUTE
           .
      *
      ****************************************************************
      *    9400-DATE-TO-INTEGER-CURTAIL - CONVERT CURTAILMENT DATE   *
      ****************************************************************
       9400-DATE-TO-INTEGER-CURTAIL.
      *
           MOVE LS-IR-CURTAIL-DATE(1:4) TO WS-DD-YYYY
           MOVE LS-IR-CURTAIL-DATE(6:2) TO WS-DD-MM
           MOVE LS-IR-CURTAIL-DATE(9:2) TO WS-DD-DD
      *
           COMPUTE WS-CURTAIL-DATE-INT =
               FUNCTION INTEGER-OF-DATE(
                   WS-DD-YYYY * 10000 +
                   WS-DD-MM * 100 +
                   WS-DD-DD)
           END-COMPUTE
           .
      ****************************************************************
      * END OF COMINTL0                                               *
      ****************************************************************
