       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTPRF00.
      ****************************************************************
      * PROGRAM:    RPTPRF00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    DEALER PROFITABILITY REPORT. ANALYZES PROFIT BY  *
      *             DEPARTMENT: NEW VEHICLE GROSS, USED VEHICLE      *
      *             GROSS, F&I INCOME, FLOOR PLAN COST. DETAIL PER  *
      *             DEALER: UNITS SOLD, GROSS REVENUE, TOTAL COST,  *
      *             GROSS PROFIT, AVG PROFIT PER UNIT. GRAND TOTALS *
      *             ACROSS ALL DEALERS.                              *
      *                                                              *
      * INPUT:      DATE RANGE (START/END DATE)                      *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL         (READ)               *
      *             AUTOSALE.VEHICLE            (READ)               *
      *             AUTOSALE.FINANCE_APP        (READ)               *
      *             AUTOSALE.FINANCE_PRODUCT    (READ)               *
      *             AUTOSALE.FLOOR_PLAN_VEHICLE (READ)               *
      *             AUTOSALE.DEALER             (READ)               *
      *                                                              *
      * OUTPUT:     SYSPRINT DD - PRINTED REPORT (132 CHARS)         *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REPORT-FILE
               ASSIGN TO SYSPRINT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  REPORT-RECORD               PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTPRF00'.
      *
       01  WS-FILE-STATUS              PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    REPORT CONTROL FIELDS
      *
       01  WS-REPORT-CONTROLS.
           05  WS-PAGE-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-LINE-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-LINES-PER-PAGE       PIC S9(04) COMP VALUE +56.
           05  WS-DETAIL-COUNT         PIC S9(06) COMP VALUE +0.
           05  WS-DEALER-COUNT         PIC S9(04) COMP VALUE +0.
           05  WS-EOF-DEALER           PIC X(01) VALUE 'N'.
               88  WS-DEALERS-DONE               VALUE 'Y'.
      *
      *    INPUT PARAMETERS
      *
       01  WS-PARM-AREA.
           05  WS-START-DATE           PIC X(10) VALUE SPACES.
           05  WS-END-DATE             PIC X(10) VALUE SPACES.
      *
      *    CURRENT DATE WORK FIELDS
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY            PIC 9(04).
           05  WS-CURR-MM              PIC 9(02).
           05  WS-CURR-DD              PIC 9(02).
           05  FILLER                  PIC X(13).
      *
       01  WS-REPORT-DATE              PIC X(10) VALUE SPACES.
      *
      *    REPORT HEADER LINE (132 CHARS)
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE ' DEALER PROFITABILITY REPORT   '.
           05  FILLER                  PIC X(07) VALUE 'DATE: '.
           05  WS-RH1-DATE            PIC X(10).
           05  FILLER                  PIC X(06) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(27) VALUE SPACES.
      *
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-DATE-RANGE-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(14)
               VALUE 'PERIOD FROM: '.
           05  WS-DR-START             PIC X(10).
           05  FILLER                  PIC X(06) VALUE '  TO: '.
           05  WS-DR-END               PIC X(10).
           05  FILLER                  PIC X(91) VALUE SPACES.
      *
       01  WS-DEALER-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(09) VALUE 'DEALER:  '.
           05  WS-DH-DEALER-CODE      PIC X(05).
           05  FILLER                  PIC X(03) VALUE ' - '.
           05  WS-DH-DEALER-NAME      PIC X(40).
           05  FILLER                  PIC X(74) VALUE SPACES.
      *
       01  WS-SECTION-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE '   '.
           05  WS-SH-SECTION-NAME     PIC X(30).
           05  FILLER                  PIC X(98) VALUE SPACES.
      *
       01  WS-PROFIT-COLUMN-HDR.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '        '.
           05  FILLER                  PIC X(08) VALUE 'UNITS   '.
           05  FILLER                  PIC X(18) VALUE
               '   GROSS REVENUE  '.
           05  FILLER                  PIC X(18) VALUE
               '    TOTAL COST    '.
           05  FILLER                  PIC X(18) VALUE
               '   GROSS PROFIT   '.
           05  FILLER                  PIC X(18) VALUE
               '  AVG PROFIT/UNIT '.
           05  FILLER                  PIC X(08) VALUE 'MARGIN  '.
           05  FILLER                  PIC X(35) VALUE SPACES.
      *
       01  WS-PROFIT-COLUMN-UND.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '        '.
           05  FILLER                  PIC X(08) VALUE '------- '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(08) VALUE '------- '.
           05  FILLER                  PIC X(35) VALUE SPACES.
      *
       01  WS-PROFIT-DETAIL.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '        '.
           05  WS-PD-UNITS            PIC Z(5)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-PD-REVENUE          PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-PD-COST             PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-PD-PROFIT           PIC -$$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-PD-AVG-PROFIT       PIC -$$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-PD-MARGIN           PIC -Z9.99.
           05  FILLER                  PIC X(01) VALUE '%'.
           05  FILLER                  PIC X(28) VALUE SPACES.
      *
       01  WS-DEALER-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '-'.
           05  FILLER                  PIC X(88) VALUE SPACES.
      *
       01  WS-DEALER-NET-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '        '.
           05  FILLER                  PIC X(22)
               VALUE 'NET DEALER PROFIT:    '.
           05  WS-DN-NET-PROFIT        PIC -$$$$,$$$,$$9.99.
           05  FILLER                  PIC X(05) VALUE '     '.
           05  FILLER                  PIC X(16)
               VALUE 'AVG PER UNIT:   '.
           05  WS-DN-AVG-PER-UNIT      PIC -$$$,$$$,$$9.99.
           05  FILLER                  PIC X(48) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'GRAND TOTALS:     '.
           05  WS-GT-TOTAL-UNITS       PIC Z(5)9.
           05  FILLER                  PIC X(08) VALUE ' DEALS  '.
           05  WS-GT-NET-PROFIT        PIC -$$$$,$$$,$$9.99.
           05  FILLER                  PIC X(07) VALUE ' PROFIT'.
           05  FILLER                  PIC X(30) VALUE SPACES.
      *
      *    DEPARTMENT ACCUMULATORS (PER DEALER)
      *    1=NEW, 2=USED, 3=F&I, 4=FLOOR PLAN
      *
       01  WS-DEPT-ACCUM.
           05  WS-DEPT OCCURS 4 TIMES.
               10  WS-DP-UNITS        PIC S9(06) COMP VALUE +0.
               10  WS-DP-REVENUE      PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-DP-COST         PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-DP-PROFIT       PIC S9(13)V99 COMP-3
                                                      VALUE +0.
      *
      *    GRAND DEPARTMENT ACCUMULATORS
      *
       01  WS-GRAND-DEPT-ACCUM.
           05  WS-GD OCCURS 4 TIMES.
               10  WS-GD-UNITS        PIC S9(08) COMP VALUE +0.
               10  WS-GD-REVENUE      PIC S9(15)V99 COMP-3
                                                      VALUE +0.
               10  WS-GD-COST         PIC S9(15)V99 COMP-3
                                                      VALUE +0.
               10  WS-GD-PROFIT       PIC S9(15)V99 COMP-3
                                                      VALUE +0.
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-TOTAL-UNITS       PIC S9(08) COMP VALUE +0.
           05  WS-GA-NET-PROFIT        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-DEALER-COUNT      PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - NEW VEHICLE SALES
      *
       01  WS-HV-NEW-SALES.
           05  WS-HV-NEW-UNITS        PIC S9(06) COMP.
           05  WS-HV-NEW-REVENUE      PIC S9(11)V99 COMP-3.
           05  WS-HV-NEW-COST         PIC S9(11)V99 COMP-3.
           05  WS-HV-NEW-GROSS        PIC S9(11)V99 COMP-3.
      *
      *    HOST VARIABLES - USED VEHICLE SALES
      *
       01  WS-HV-USED-SALES.
           05  WS-HV-USED-UNITS       PIC S9(06) COMP.
           05  WS-HV-USED-REVENUE     PIC S9(11)V99 COMP-3.
           05  WS-HV-USED-COST        PIC S9(11)V99 COMP-3.
           05  WS-HV-USED-GROSS       PIC S9(11)V99 COMP-3.
      *
      *    HOST VARIABLES - F&I INCOME
      *
       01  WS-HV-FI-INCOME.
           05  WS-HV-FI-DEALS         PIC S9(06) COMP.
           05  WS-HV-FI-REVENUE       PIC S9(11)V99 COMP-3.
           05  WS-HV-FI-COST          PIC S9(11)V99 COMP-3.
           05  WS-HV-FI-GROSS         PIC S9(11)V99 COMP-3.
      *
      *    HOST VARIABLES - FLOOR PLAN COST
      *
       01  WS-HV-FLOOR-PLAN.
           05  WS-HV-FP-COUNT         PIC S9(06) COMP.
           05  WS-HV-FP-INTEREST      PIC S9(11)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-NET-PROFIT          PIC S9(13)V99 COMP-3
                                                     VALUE +0.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-MARGIN-WORK         PIC S9(05)V99 COMP-3
                                                     VALUE +0.
           05  WS-TOTAL-UNITS         PIC S9(06) COMP VALUE +0.
           05  WS-DEPT-NAMES.
               10  FILLER             PIC X(30)
                   VALUE 'NEW VEHICLE SALES             '.
               10  FILLER             PIC X(30)
                   VALUE 'USED VEHICLE SALES            '.
               10  FILLER             PIC X(30)
                   VALUE 'F&I PRODUCTS INCOME           '.
               10  FILLER             PIC X(30)
                   VALUE 'FLOOR PLAN INTEREST EXPENSE   '.
           05  WS-DEPT-NAME-TBL REDEFINES WS-DEPT-NAMES.
               10  WS-DEPT-NAME       PIC X(30) OCCURS 4 TIMES.
           05  WS-IDX                  PIC S9(02) COMP VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_PRF_DLRS CURSOR FOR
               SELECT DISTINCT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   D.DEALER_CODE = S.DEALER_CODE
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-START-DATE
                 AND  S.DELIVERY_DATE <= :WS-END-DATE
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
      *    NEW VEHICLE SUMMARY PER DEALER
      *
           EXEC SQL DECLARE CSR_PRF_NEW CURSOR FOR
               SELECT COUNT(*)
                    , COALESCE(SUM(S.VEHICLE_PRICE
                          + S.TOTAL_OPTIONS
                          + S.DESTINATION_FEE), 0)
                    , COALESCE(SUM(V.INVOICE_PRICE), 0)
                    , COALESCE(SUM(S.FRONT_GROSS), 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DEAL_TYPE = 'R'
                 AND  S.DELIVERY_DATE >= :WS-START-DATE
                 AND  S.DELIVERY_DATE <= :WS-END-DATE
                 AND  V.VEHICLE_STATUS = 'SD'
                 AND  V.ODOMETER < 500
           END-EXEC
      *
      *    USED VEHICLE SUMMARY PER DEALER
      *
           EXEC SQL DECLARE CSR_PRF_USED CURSOR FOR
               SELECT COUNT(*)
                    , COALESCE(SUM(S.VEHICLE_PRICE
                          + S.TOTAL_OPTIONS), 0)
                    , COALESCE(SUM(V.INVOICE_PRICE), 0)
                    , COALESCE(SUM(S.FRONT_GROSS), 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DEAL_TYPE = 'R'
                 AND  S.DELIVERY_DATE >= :WS-START-DATE
                 AND  S.DELIVERY_DATE <= :WS-END-DATE
                 AND  V.ODOMETER >= 500
           END-EXEC
      *
      *    F&I PRODUCTS INCOME PER DEALER
      *
           EXEC SQL DECLARE CSR_PRF_FI CURSOR FOR
               SELECT COUNT(DISTINCT S.DEAL_NUMBER)
                    , COALESCE(SUM(FP.RETAIL_PRICE), 0)
                    , COALESCE(SUM(FP.DEALER_COST), 0)
                    , COALESCE(SUM(FP.GROSS_PROFIT), 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.FINANCE_PRODUCT FP
                 ON   S.DEAL_NUMBER = FP.DEAL_NUMBER
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-START-DATE
                 AND  S.DELIVERY_DATE <= :WS-END-DATE
           END-EXEC
      *
      *    FLOOR PLAN INTEREST EXPENSE PER DEALER
      *
           EXEC SQL DECLARE CSR_PRF_FP CURSOR FOR
               SELECT COUNT(*)
                    , COALESCE(SUM(F.INTEREST_ACCRUED), 0)
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE F
               WHERE  F.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  F.FP_STATUS IN ('AC', 'CT')
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTPRF00: DEALER PROFITABILITY REPORT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 3000-PROCESS-DEALERS
               PERFORM 7000-PRINT-GRAND-TOTALS
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTPRF00: REPORT COMPLETE - '
                   WS-GA-TOTAL-UNITS ' DEALS, '
                   WS-GA-DEALER-COUNT ' DEALERS'
      *
           STOP RUN.
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE FUNCTION CURRENT-DATE(1:8)
               TO WS-CURRENT-DATE-DATA
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-REPORT-DATE
      *
      *    DEFAULT DATE RANGE: CURRENT MONTH
      *
           IF WS-START-DATE = SPACES
               STRING WS-CURR-YYYY '-'
                      WS-CURR-MM   '-01'
                      DELIMITED BY SIZE
                      INTO WS-START-DATE
           END-IF
      *
           IF WS-END-DATE = SPACES
               MOVE WS-REPORT-DATE TO WS-END-DATE
           END-IF
      *
           DISPLAY 'RPTPRF00: PERIOD ' WS-START-DATE
                   ' TO ' WS-END-DATE
      *
           INITIALIZE WS-DEPT-ACCUM
           INITIALIZE WS-GRAND-DEPT-ACCUM
           INITIALIZE WS-GRAND-ACCUM
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
      *
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTPRF00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_PRF_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTPRF00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_PRF_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-GATHER-DEALER-DATA
                       PERFORM 6000-PRINT-DEALER-PROFIT
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTPRF00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_PRF_DLRS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-NEW-DEALER-PAGE - START NEW PAGE FOR EACH DEALER     *
      ****************************************************************
       4000-NEW-DEALER-PAGE.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           MOVE WS-REPORT-DATE TO WS-RH1-DATE
      *
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           MOVE WS-START-DATE TO WS-DR-START
           MOVE WS-END-DATE   TO WS-DR-END
           WRITE REPORT-RECORD FROM WS-DATE-RANGE-LINE
               AFTER ADVANCING 2
      *
           MOVE WS-HV-DLR-CODE TO WS-DH-DEALER-CODE
           MOVE WS-HV-DLR-NAME TO WS-DH-DEALER-NAME
           WRITE REPORT-RECORD FROM WS-DEALER-HEADER
               AFTER ADVANCING 2
      *
           MOVE 10 TO WS-LINE-COUNT
      *
           INITIALIZE WS-DEPT-ACCUM
           .
      *
      ****************************************************************
      *    5000-GATHER-DEALER-DATA - QUERY ALL 4 DEPARTMENTS        *
      ****************************************************************
       5000-GATHER-DEALER-DATA.
      *
      *    NEW VEHICLE SALES
      *
           EXEC SQL OPEN CSR_PRF_NEW END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_PRF_NEW
                   INTO :WS-HV-NEW-UNITS
                      , :WS-HV-NEW-REVENUE
                      , :WS-HV-NEW-COST
                      , :WS-HV-NEW-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-NEW-UNITS   TO WS-DP-UNITS(1)
                   MOVE WS-HV-NEW-REVENUE TO WS-DP-REVENUE(1)
                   MOVE WS-HV-NEW-COST    TO WS-DP-COST(1)
                   MOVE WS-HV-NEW-GROSS   TO WS-DP-PROFIT(1)
               END-IF
               EXEC SQL CLOSE CSR_PRF_NEW END-EXEC
           END-IF
      *
      *    USED VEHICLE SALES
      *
           EXEC SQL OPEN CSR_PRF_USED END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_PRF_USED
                   INTO :WS-HV-USED-UNITS
                      , :WS-HV-USED-REVENUE
                      , :WS-HV-USED-COST
                      , :WS-HV-USED-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-USED-UNITS   TO WS-DP-UNITS(2)
                   MOVE WS-HV-USED-REVENUE TO WS-DP-REVENUE(2)
                   MOVE WS-HV-USED-COST    TO WS-DP-COST(2)
                   MOVE WS-HV-USED-GROSS   TO WS-DP-PROFIT(2)
               END-IF
               EXEC SQL CLOSE CSR_PRF_USED END-EXEC
           END-IF
      *
      *    F&I PRODUCTS INCOME
      *
           EXEC SQL OPEN CSR_PRF_FI END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_PRF_FI
                   INTO :WS-HV-FI-DEALS
                      , :WS-HV-FI-REVENUE
                      , :WS-HV-FI-COST
                      , :WS-HV-FI-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-FI-DEALS   TO WS-DP-UNITS(3)
                   MOVE WS-HV-FI-REVENUE TO WS-DP-REVENUE(3)
                   MOVE WS-HV-FI-COST    TO WS-DP-COST(3)
                   MOVE WS-HV-FI-GROSS   TO WS-DP-PROFIT(3)
               END-IF
               EXEC SQL CLOSE CSR_PRF_FI END-EXEC
           END-IF
      *
      *    FLOOR PLAN INTEREST EXPENSE
      *
           EXEC SQL OPEN CSR_PRF_FP END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_PRF_FP
                   INTO :WS-HV-FP-COUNT
                      , :WS-HV-FP-INTEREST
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-FP-COUNT     TO WS-DP-UNITS(4)
                   MOVE WS-HV-FP-INTEREST  TO WS-DP-REVENUE(4)
                   MOVE +0                  TO WS-DP-COST(4)
                   COMPUTE WS-DP-PROFIT(4) =
                       +0 - WS-HV-FP-INTEREST
               END-IF
               EXEC SQL CLOSE CSR_PRF_FP END-EXEC
           END-IF
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-PROFIT - PRINT ALL DEPARTMENT SECTIONS  *
      ****************************************************************
       6000-PRINT-DEALER-PROFIT.
      *
           MOVE +0 TO WS-NET-PROFIT
           MOVE +0 TO WS-TOTAL-UNITS
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 4
      *
               MOVE WS-DEPT-NAME(WS-IDX) TO WS-SH-SECTION-NAME
               WRITE REPORT-RECORD FROM WS-SECTION-HEADER
                   AFTER ADVANCING 2
               WRITE REPORT-RECORD FROM WS-PROFIT-COLUMN-HDR
                   AFTER ADVANCING 1
               WRITE REPORT-RECORD FROM WS-PROFIT-COLUMN-UND
                   AFTER ADVANCING 1
      *
               MOVE WS-DP-UNITS(WS-IDX)   TO WS-PD-UNITS
               MOVE WS-DP-REVENUE(WS-IDX) TO WS-PD-REVENUE
               MOVE WS-DP-COST(WS-IDX)    TO WS-PD-COST
               MOVE WS-DP-PROFIT(WS-IDX)  TO WS-PD-PROFIT
      *
               IF WS-DP-UNITS(WS-IDX) > +0
                   COMPUTE WS-AVG-WORK =
                       WS-DP-PROFIT(WS-IDX) /
                       WS-DP-UNITS(WS-IDX)
                   MOVE WS-AVG-WORK TO WS-PD-AVG-PROFIT
      *
                   IF WS-DP-REVENUE(WS-IDX) > +0
                       COMPUTE WS-MARGIN-WORK =
                           (WS-DP-PROFIT(WS-IDX) /
                            WS-DP-REVENUE(WS-IDX)) * 100
                   ELSE
                       MOVE +0 TO WS-MARGIN-WORK
                   END-IF
                   MOVE WS-MARGIN-WORK TO WS-PD-MARGIN
               ELSE
                   MOVE +0 TO WS-PD-AVG-PROFIT
                   MOVE +0 TO WS-PD-MARGIN
               END-IF
      *
               WRITE REPORT-RECORD FROM WS-PROFIT-DETAIL
                   AFTER ADVANCING 1
      *
               ADD WS-DP-PROFIT(WS-IDX) TO WS-NET-PROFIT
      *
               IF WS-IDX NOT = 4
                   ADD WS-DP-UNITS(WS-IDX) TO WS-TOTAL-UNITS
               END-IF
      *
      *        ACCUMULATE GRAND LEVEL
      *
               ADD WS-DP-UNITS(WS-IDX)
                   TO WS-GD-UNITS(WS-IDX)
               ADD WS-DP-REVENUE(WS-IDX)
                   TO WS-GD-REVENUE(WS-IDX)
               ADD WS-DP-COST(WS-IDX)
                   TO WS-GD-COST(WS-IDX)
               ADD WS-DP-PROFIT(WS-IDX)
                   TO WS-GD-PROFIT(WS-IDX)
      *
               ADD +6 TO WS-LINE-COUNT
      *
           END-PERFORM
      *
      *    PRINT DEALER NET PROFIT
      *
           WRITE REPORT-RECORD FROM WS-DEALER-TOTAL-LINE
               AFTER ADVANCING 2
      *
           MOVE WS-NET-PROFIT TO WS-DN-NET-PROFIT
      *
           IF WS-TOTAL-UNITS > +0
               COMPUTE WS-AVG-WORK =
                   WS-NET-PROFIT / WS-TOTAL-UNITS
               MOVE WS-AVG-WORK TO WS-DN-AVG-PER-UNIT
           ELSE
               MOVE +0 TO WS-DN-AVG-PER-UNIT
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-DEALER-NET-LINE
               AFTER ADVANCING 1
      *
      *    GRAND ACCUMULATORS
      *
           ADD WS-TOTAL-UNITS TO WS-GA-TOTAL-UNITS
           ADD WS-NET-PROFIT  TO WS-GA-NET-PROFIT
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
      *    START NEW PAGE FOR GRAND SUMMARY
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           MOVE WS-REPORT-DATE TO WS-RH1-DATE
      *
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           MOVE WS-START-DATE TO WS-DR-START
           MOVE WS-END-DATE   TO WS-DR-END
           WRITE REPORT-RECORD FROM WS-DATE-RANGE-LINE
               AFTER ADVANCING 2
      *
           MOVE 'ALL DEALERS - GRAND SUMMARY' TO WS-DH-DEALER-CODE
           MOVE SPACES TO WS-DH-DEALER-NAME
           WRITE REPORT-RECORD FROM WS-DEALER-HEADER
               AFTER ADVANCING 2
      *
      *    PRINT EACH DEPARTMENT GRAND TOTAL
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 4
      *
               MOVE WS-DEPT-NAME(WS-IDX) TO WS-SH-SECTION-NAME
               WRITE REPORT-RECORD FROM WS-SECTION-HEADER
                   AFTER ADVANCING 2
               WRITE REPORT-RECORD FROM WS-PROFIT-COLUMN-HDR
                   AFTER ADVANCING 1
               WRITE REPORT-RECORD FROM WS-PROFIT-COLUMN-UND
                   AFTER ADVANCING 1
      *
               MOVE WS-GD-UNITS(WS-IDX)   TO WS-PD-UNITS
               MOVE WS-GD-REVENUE(WS-IDX) TO WS-PD-REVENUE
               MOVE WS-GD-COST(WS-IDX)    TO WS-PD-COST
               MOVE WS-GD-PROFIT(WS-IDX)  TO WS-PD-PROFIT
      *
               IF WS-GD-UNITS(WS-IDX) > +0
                   COMPUTE WS-AVG-WORK =
                       WS-GD-PROFIT(WS-IDX) /
                       WS-GD-UNITS(WS-IDX)
                   MOVE WS-AVG-WORK TO WS-PD-AVG-PROFIT
      *
                   IF WS-GD-REVENUE(WS-IDX) > +0
                       COMPUTE WS-MARGIN-WORK =
                           (WS-GD-PROFIT(WS-IDX) /
                            WS-GD-REVENUE(WS-IDX)) * 100
                   ELSE
                       MOVE +0 TO WS-MARGIN-WORK
                   END-IF
                   MOVE WS-MARGIN-WORK TO WS-PD-MARGIN
               ELSE
                   MOVE +0 TO WS-PD-AVG-PROFIT
                   MOVE +0 TO WS-PD-MARGIN
               END-IF
      *
               WRITE REPORT-RECORD FROM WS-PROFIT-DETAIL
                   AFTER ADVANCING 1
           END-PERFORM
      *
      *    GRAND NET LINE
      *
           MOVE WS-GA-TOTAL-UNITS  TO WS-GT-TOTAL-UNITS
           MOVE WS-GA-NET-PROFIT   TO WS-GT-NET-PROFIT
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE REPORT-FILE
      *
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTPRF00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTPRF00                                              *
      ****************************************************************
