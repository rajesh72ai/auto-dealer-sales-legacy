      ****************************************************************
      * COPYBOOK: WSFPL000                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  FLOOR PLAN DATA AREA FOR VEHICLE FINANCING       *
      *           BETWEEN DEALER AND FLOOR PLAN LENDER              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    FLOOR PLAN IS THE CREDIT LINE DEALERS USE TO     *
      *           FINANCE VEHICLE INVENTORY. INTEREST ACCRUES      *
      *           DAILY FROM THE DATE THE VEHICLE IS FLOORED        *
      *           UNTIL IT IS SOLD AND THE LENDER IS PAID OFF.     *
      ****************************************************************
      *
      *    FLOOR PLAN VEHICLE RECORD
      *
       01  WS-FLOOR-PLAN-RECORD.
           05  WS-FPL-FLOOR-NUM       PIC X(12)    VALUE SPACES.
           05  WS-FPL-DEALER-CODE     PIC X(05)    VALUE SPACES.
           05  WS-FPL-VIN             PIC X(17)    VALUE SPACES.
           05  WS-FPL-STOCK-NUM       PIC X(10)    VALUE SPACES.
           05  WS-FPL-LENDER-CODE     PIC X(04)    VALUE SPACES.
           05  WS-FPL-LENDER-NAME     PIC X(35)    VALUE SPACES.
           05  WS-FPL-ACCOUNT-NUM     PIC X(15)    VALUE SPACES.
           05  WS-FPL-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-FPL-ACTIVE                   VALUE 'AC'.
               88  WS-FPL-PAID-OFF                 VALUE 'PO'.
               88  WS-FPL-OVERDUE                  VALUE 'OD'.
               88  WS-FPL-SUSPENDED                VALUE 'SU'.
               88  WS-FPL-CURTAILED                VALUE 'CT'.
               88  WS-FPL-AUDIT-HOLD               VALUE 'AH'.
           05  WS-FPL-FLOOR-DATE      PIC X(10)    VALUE SPACES.
           05  WS-FPL-MATURITY-DATE   PIC X(10)    VALUE SPACES.
           05  WS-FPL-PAYOFF-DATE     PIC X(10)    VALUE SPACES.
           05  WS-FPL-INVOICE-AMT     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-FLOOR-AMT       PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-PRINCIPAL-BAL   PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-CURTAIL-AMT     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-CURTAIL-DUE     PIC X(10)    VALUE SPACES.
           05  WS-FPL-VEHICLE-TYPE    PIC X(02)    VALUE SPACES.
               88  WS-FPL-NEW-VEHICLE              VALUE 'NW'.
               88  WS-FPL-USED-VEHICLE             VALUE 'US'.
               88  WS-FPL-DEMO                     VALUE 'DM'.
      *
      *    INTEREST CALCULATION FIELDS
      *
       01  WS-FPL-INTEREST-CALC.
           05  WS-FPL-INT-RATE-TYPE   PIC X(01)    VALUE SPACES.
               88  WS-FPL-RATE-FIXED               VALUE 'F'.
               88  WS-FPL-RATE-VARIABLE            VALUE 'V'.
           05  WS-FPL-BASE-RATE       PIC S9(03)V9(06) COMP-3
                                                    VALUE +0.
           05  WS-FPL-SPREAD          PIC S9(03)V9(06) COMP-3
                                                    VALUE +0.
           05  WS-FPL-EFF-RATE        PIC S9(03)V9(06) COMP-3
                                                    VALUE +0.
           05  WS-FPL-DAILY-RATE      PIC S9(01)V9(08) COMP-3
                                                    VALUE +0.
           05  WS-FPL-DAYS-FLOORED    PIC S9(05)   COMP-3
                                                    VALUE +0.
           05  WS-FPL-DAYS-SINCE-CURT PIC S9(05)   COMP-3
                                                    VALUE +0.
           05  WS-FPL-INT-ACCRUED     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-INT-PAID        PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-INT-DUE         PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-INT-MTD         PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-INT-YTD         PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-CALC-DATE       PIC X(10)    VALUE SPACES.
           05  WS-FPL-DAY-COUNT-BASIS PIC X(05)    VALUE '360  '.
               88  WS-FPL-BASIS-360                VALUE '360  '.
               88  WS-FPL-BASIS-365                VALUE '365  '.
               88  WS-FPL-BASIS-ACTUAL             VALUE 'ACT  '.
      *
      *    FLOOR PLAN SUMMARY FIELDS
      *
       01  WS-FPL-SUMMARY.
           05  WS-FPL-SUM-TOTAL-UNITS PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-TOTAL-BAL   PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-TOTAL-INT   PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-OVERDUE-CNT PIC S9(05)   COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-OVERDUE-AMT PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-CREDIT-LIM  PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-AVAILABLE   PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-FPL-SUM-UTIL-PCT    PIC S9(03)V99 COMP-3
                                                    VALUE +0.
      *
      *    FLOOR PLAN SEARCH CRITERIA
      *
       01  WS-FPL-SEARCH.
           05  WS-FPL-SRCH-DEALER     PIC X(05)    VALUE SPACES.
           05  WS-FPL-SRCH-LENDER     PIC X(04)    VALUE SPACES.
           05  WS-FPL-SRCH-STATUS     PIC X(02)    VALUE SPACES.
           05  WS-FPL-SRCH-VIN        PIC X(17)    VALUE SPACES.
           05  WS-FPL-SRCH-FROM-DATE  PIC X(10)    VALUE SPACES.
           05  WS-FPL-SRCH-TO-DATE    PIC X(10)    VALUE SPACES.
           05  WS-FPL-SRCH-OVERDUE    PIC X(01)    VALUE 'N'.
               88  WS-FPL-SRCH-OVERDUE-ONLY        VALUE 'Y'.
               88  WS-FPL-SRCH-ALL                 VALUE 'N'.
      ****************************************************************
      * END OF WSFPL000                                              *
      ****************************************************************
