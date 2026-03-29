       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTSUP00.
      ****************************************************************
      * PROGRAM:    RPTSUP00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    SUPERVISOR SUMMARY DASHBOARD REPORT. HIGH-LEVEL  *
      *             EXECUTIVE SUMMARY WITH KEY PERFORMANCE INDICATORS *
      *             SECTIONS: SALES (UNITS/REVENUE BY TYPE),         *
      *             INVENTORY (COUNT/VALUE/AVG AGE), F&I             *
      *             (PENETRATION/REVENUE), WARRANTY (OPEN CLAIMS/    *
      *             COST), REGISTRATION (PENDING/COMPLETED).         *
      *             ONE PAGE PER DEALER WITH ALL KPIS.               *
      *             GRAND SUMMARY PAGE WITH ALL-DEALER AVERAGES.     *
      *                                                              *
      * INPUT:      REPORT MONTH (YYYYMM, DEFAULT CURRENT)          *
      *                                                              *
      * TABLES:     AUTOSALE.DEALER             (READ)               *
      *             AUTOSALE.SALES_DEAL         (READ)               *
      *             AUTOSALE.VEHICLE            (READ)               *
      *             AUTOSALE.FINANCE_APP        (READ)               *
      *             AUTOSALE.FINANCE_PRODUCT    (READ)               *
      *             AUTOSALE.FLOOR_PLAN_VEHICLE (READ)               *
      *             AUTOSALE.WARRANTY           (READ)               *
      *             AUTOSALE.RECALL_VEHICLE     (READ)               *
      *             AUTOSALE.REGISTRATION       (READ)               *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTSUP00'.
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
           05  WS-REPORT-MONTH        PIC X(06) VALUE SPACES.
           05  WS-MONTH-START         PIC X(10) VALUE SPACES.
           05  WS-MONTH-END           PIC X(10) VALUE SPACES.
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
               VALUE 'SUPERVISOR SUMMARY DASHBOARD  '.
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
       01  WS-MONTH-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'REPORT PERIOD:  '.
           05  WS-MH-MONTH            PIC X(06).
           05  FILLER                  PIC X(05) VALUE '     '.
           05  FILLER                  PIC X(06) VALUE 'FROM: '.
           05  WS-MH-START            PIC X(10).
           05  FILLER                  PIC X(06) VALUE '  TO: '.
           05  WS-MH-END              PIC X(10).
           05  FILLER                  PIC X(72) VALUE SPACES.
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
           05  FILLER                  PIC X(02) VALUE '  '.
           05  WS-SH-SECTION-NAME     PIC X(50).
           05  FILLER                  PIC X(79) VALUE SPACES.
      *
       01  WS-SECTION-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE '  '.
           05  FILLER                  PIC X(50) VALUE ALL '-'.
           05  FILLER                  PIC X(79) VALUE SPACES.
      *
      *    KPI LINES - GENERIC TWO-COLUMN FORMAT
      *
       01  WS-KPI-LINE-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE '      '.
           05  WS-K1-LABEL1           PIC X(25).
           05  WS-K1-VALUE1           PIC X(20).
           05  FILLER                  PIC X(05) VALUE '     '.
           05  WS-K1-LABEL2           PIC X(25).
           05  WS-K1-VALUE2           PIC X(20).
           05  FILLER                  PIC X(30) VALUE SPACES.
      *
       01  WS-KPI-LINE-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE '      '.
           05  WS-K2-LABEL1           PIC X(25).
           05  WS-K2-VALUE1           PIC X(20).
           05  FILLER                  PIC X(05) VALUE '     '.
           05  WS-K2-LABEL2           PIC X(25).
           05  WS-K2-VALUE2           PIC X(20).
           05  FILLER                  PIC X(30) VALUE SPACES.
      *
       01  WS-BLANK-LINE.
           05  FILLER                  PIC X(132) VALUE SPACES.
      *
       01  WS-GRAND-TITLE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(45) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'ALL-DEALER SUMMARY AVERAGES             '.
           05  FILLER                  PIC X(45) VALUE SPACES.
      *
      *    PER-DEALER KPI VALUES
      *
       01  WS-KPI-SALES.
           05  WS-KS-NEW-UNITS        PIC S9(06) COMP VALUE +0.
           05  WS-KS-NEW-REVENUE      PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-KS-NEW-GROSS        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-KS-USED-UNITS       PIC S9(06) COMP VALUE +0.
           05  WS-KS-USED-REVENUE     PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-KS-USED-GROSS       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-KS-LEASE-UNITS      PIC S9(06) COMP VALUE +0.
           05  WS-KS-TOTAL-UNITS      PIC S9(06) COMP VALUE +0.
           05  WS-KS-TOTAL-REVENUE    PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-KS-TOTAL-GROSS      PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
       01  WS-KPI-INVENTORY.
           05  WS-KI-ON-HAND          PIC S9(06) COMP VALUE +0.
           05  WS-KI-TOTAL-VALUE      PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-KI-AVG-DAYS         PIC S9(06) COMP VALUE +0.
           05  WS-KI-AGED-COUNT       PIC S9(06) COMP VALUE +0.
      *
       01  WS-KPI-FI.
           05  WS-KF-TOTAL-DEALS      PIC S9(06) COMP VALUE +0.
           05  WS-KF-FI-DEALS         PIC S9(06) COMP VALUE +0.
           05  WS-KF-FI-REVENUE       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-KF-FI-GROSS         PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-KF-AVG-PER-DEAL     PIC S9(09)V99 COMP-3
                                                      VALUE +0.
      *
       01  WS-KPI-WARRANTY.
           05  WS-KW-OPEN-CLAIMS      PIC S9(06) COMP VALUE +0.
           05  WS-KW-OPEN-RECALLS     PIC S9(06) COMP VALUE +0.
      *
       01  WS-KPI-REG.
           05  WS-KR-PENDING          PIC S9(06) COMP VALUE +0.
           05  WS-KR-COMPLETED        PIC S9(06) COMP VALUE +0.
           05  WS-KR-REJECTED         PIC S9(06) COMP VALUE +0.
      *
      *    GRAND ACCUMULATORS
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-DEALER-COUNT     PIC S9(04) COMP VALUE +0.
           05  WS-GA-NEW-UNITS        PIC S9(08) COMP VALUE +0.
           05  WS-GA-NEW-REVENUE      PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-NEW-GROSS        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-USED-UNITS       PIC S9(08) COMP VALUE +0.
           05  WS-GA-USED-REVENUE     PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-USED-GROSS       PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-LEASE-UNITS      PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-UNITS      PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-REVENUE    PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-TOTAL-GROSS      PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-INV-COUNT        PIC S9(08) COMP VALUE +0.
           05  WS-GA-INV-VALUE        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-INV-DAYS         PIC S9(10) COMP VALUE +0.
           05  WS-GA-INV-AGED         PIC S9(08) COMP VALUE +0.
           05  WS-GA-FI-DEALS         PIC S9(08) COMP VALUE +0.
           05  WS-GA-FI-REVENUE       PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-FI-GROSS         PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-WR-OPEN          PIC S9(08) COMP VALUE +0.
           05  WS-GA-WR-RECALLS       PIC S9(08) COMP VALUE +0.
           05  WS-GA-RG-PENDING       PIC S9(08) COMP VALUE +0.
           05  WS-GA-RG-COMPLETED     PIC S9(08) COMP VALUE +0.
           05  WS-GA-RG-REJECTED      PIC S9(08) COMP VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - SALES SUMMARY
      *
       01  WS-HV-SALES.
           05  WS-HV-SL-UNITS         PIC S9(06) COMP.
           05  WS-HV-SL-REVENUE       PIC S9(11)V99 COMP-3.
           05  WS-HV-SL-GROSS         PIC S9(11)V99 COMP-3.
      *
      *    HOST VARIABLES - INVENTORY
      *
       01  WS-HV-INVENTORY.
           05  WS-HV-INV-COUNT        PIC S9(06) COMP.
           05  WS-HV-INV-VALUE        PIC S9(11)V99 COMP-3.
           05  WS-HV-INV-AVG-DAYS     PIC S9(06) COMP.
           05  WS-HV-INV-AGED         PIC S9(06) COMP.
      *
      *    HOST VARIABLES - F&I
      *
       01  WS-HV-FI.
           05  WS-HV-FI-TOTAL-DEALS   PIC S9(06) COMP.
           05  WS-HV-FI-DEALS         PIC S9(06) COMP.
           05  WS-HV-FI-REVENUE       PIC S9(11)V99 COMP-3.
           05  WS-HV-FI-GROSS         PIC S9(11)V99 COMP-3.
      *
      *    HOST VARIABLES - WARRANTY
      *
       01  WS-HV-WARRANTY.
           05  WS-HV-WR-OPEN          PIC S9(06) COMP.
           05  WS-HV-WR-RECALLS       PIC S9(06) COMP.
      *
      *    HOST VARIABLES - REGISTRATION
      *
       01  WS-HV-REG.
           05  WS-HV-RG-PENDING       PIC S9(06) COMP.
           05  WS-HV-RG-COMPLETED     PIC S9(06) COMP.
           05  WS-HV-RG-REJECTED      PIC S9(06) COMP.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-FMT-UNITS           PIC Z(5)9.
           05  WS-FMT-AMOUNT          PIC $$$,$$$,$$9.99.
           05  WS-FMT-DAYS            PIC Z(4)9.
           05  WS-FMT-PCT             PIC ZZ9.99.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-PCT-WORK            PIC S9(05)V99 COMP-3
                                                     VALUE +0.
           05  WS-FMT-VALUE20         PIC X(20) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_SUP_DLRS CURSOR FOR
               SELECT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               WHERE  D.ACTIVE_FLAG = 'Y'
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
      *    SALES BY TYPE: NEW
      *
           EXEC SQL DECLARE CSR_SUP_NEW CURSOR FOR
               SELECT COALESCE(COUNT(*), 0)
                    , COALESCE(SUM(S.TOTAL_PRICE), 0)
                    , COALESCE(SUM(S.TOTAL_GROSS), 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-MONTH-START
                 AND  S.DELIVERY_DATE <= :WS-MONTH-END
                 AND  S.DEAL_TYPE = 'R'
                 AND  V.ODOMETER < 500
           END-EXEC
      *
      *    SALES BY TYPE: USED
      *
           EXEC SQL DECLARE CSR_SUP_USED CURSOR FOR
               SELECT COALESCE(COUNT(*), 0)
                    , COALESCE(SUM(S.TOTAL_PRICE), 0)
                    , COALESCE(SUM(S.TOTAL_GROSS), 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-MONTH-START
                 AND  S.DELIVERY_DATE <= :WS-MONTH-END
                 AND  S.DEAL_TYPE = 'R'
                 AND  V.ODOMETER >= 500
           END-EXEC
      *
      *    SALES BY TYPE: LEASE
      *
           EXEC SQL DECLARE CSR_SUP_LEASE CURSOR FOR
               SELECT COALESCE(COUNT(*), 0)
                    , COALESCE(SUM(S.TOTAL_PRICE), 0)
                    , COALESCE(SUM(S.TOTAL_GROSS), 0)
               FROM   AUTOSALE.SALES_DEAL S
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-MONTH-START
                 AND  S.DELIVERY_DATE <= :WS-MONTH-END
                 AND  S.DEAL_TYPE = 'L'
           END-EXEC
      *
      *    INVENTORY SUMMARY
      *
           EXEC SQL DECLARE CSR_SUP_INV CURSOR FOR
               SELECT COALESCE(COUNT(*), 0)
                    , COALESCE(SUM(F.INVOICE_AMOUNT), 0)
                    , COALESCE(AVG(V.DAYS_IN_STOCK), 0)
                    , COALESCE(SUM(CASE WHEN V.DAYS_IN_STOCK > 90
                          THEN 1 ELSE 0 END), 0)
               FROM   AUTOSALE.VEHICLE V
               LEFT JOIN AUTOSALE.FLOOR_PLAN_VEHICLE F
                 ON   V.VIN = F.VIN
                 AND  F.FP_STATUS = 'AC'
               WHERE  V.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  V.VEHICLE_STATUS IN ('AV', 'HD')
           END-EXEC
      *
      *    F&I METRICS
      *
           EXEC SQL DECLARE CSR_SUP_FI CURSOR FOR
               SELECT COALESCE(
                          (SELECT COUNT(*)
                           FROM AUTOSALE.SALES_DEAL S2
                           WHERE S2.DEALER_CODE = :WS-HV-DLR-CODE
                             AND S2.DEAL_STATUS = 'DL'
                             AND S2.DELIVERY_DATE >= :WS-MONTH-START
                             AND S2.DELIVERY_DATE <= :WS-MONTH-END
                          ), 0)
                    , COUNT(DISTINCT FP.DEAL_NUMBER)
                    , COALESCE(SUM(FP.RETAIL_PRICE), 0)
                    , COALESCE(SUM(FP.GROSS_PROFIT), 0)
               FROM   AUTOSALE.FINANCE_PRODUCT FP
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   FP.DEAL_NUMBER = S.DEAL_NUMBER
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-MONTH-START
                 AND  S.DELIVERY_DATE <= :WS-MONTH-END
           END-EXEC
      *
      *    WARRANTY METRICS
      *
           EXEC SQL DECLARE CSR_SUP_WR CURSOR FOR
               SELECT COALESCE(
                          (SELECT COUNT(*)
                           FROM AUTOSALE.WARRANTY W
                           INNER JOIN AUTOSALE.VEHICLE V
                             ON W.VIN = V.VIN
                           WHERE V.DEALER_CODE = :WS-HV-DLR-CODE
                             AND W.ACTIVE_FLAG = 'Y'
                             AND W.EXPIRY_DATE >= CURRENT DATE
                          ), 0)
                    , COALESCE(
                          (SELECT COUNT(*)
                           FROM AUTOSALE.RECALL_VEHICLE R
                           WHERE R.DEALER_CODE = :WS-HV-DLR-CODE
                             AND R.RECALL_STATUS IN ('OP', 'SC')
                          ), 0)
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    REGISTRATION METRICS
      *
           EXEC SQL DECLARE CSR_SUP_REG CURSOR FOR
               SELECT COALESCE(SUM(CASE WHEN R.REG_STATUS
                          IN ('PR', 'VL', 'SB', 'PG')
                          THEN 1 ELSE 0 END), 0)
                    , COALESCE(SUM(CASE WHEN R.REG_STATUS = 'IS'
                          THEN 1 ELSE 0 END), 0)
                    , COALESCE(SUM(CASE WHEN R.REG_STATUS
                          IN ('RJ', 'ER')
                          THEN 1 ELSE 0 END), 0)
               FROM   AUTOSALE.REGISTRATION R
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   R.DEAL_NUMBER = S.DEAL_NUMBER
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DELIVERY_DATE >= :WS-MONTH-START
                 AND  S.DELIVERY_DATE <= :WS-MONTH-END
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTSUP00: SUPERVISOR DASHBOARD REPORT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 3000-PROCESS-DEALERS
               PERFORM 7000-PRINT-GRAND-SUMMARY
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTSUP00: REPORT COMPLETE - '
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
      *    DEFAULT REPORT MONTH: CURRENT MONTH
      *
           IF WS-REPORT-MONTH = SPACES
               STRING WS-CURR-YYYY
                      WS-CURR-MM
                      DELIMITED BY SIZE
                      INTO WS-REPORT-MONTH
           END-IF
      *
      *    BUILD DATE RANGE FROM MONTH
      *
           STRING WS-REPORT-MONTH(1:4) '-'
                  WS-REPORT-MONTH(5:2) '-01'
                  DELIMITED BY SIZE
                  INTO WS-MONTH-START
      *
           MOVE WS-REPORT-DATE TO WS-MONTH-END
      *
           DISPLAY 'RPTSUP00: REPORT MONTH = ' WS-REPORT-MONTH
           DISPLAY 'RPTSUP00: PERIOD ' WS-MONTH-START
                   ' TO ' WS-MONTH-END
      *
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
               DISPLAY 'RPTSUP00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_SUP_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTSUP00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_SUP_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-GATHER-KPIS
                       PERFORM 6000-PRINT-DEALER-KPI
                       PERFORM 6500-ACCUMULATE-GRAND
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTSUP00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_SUP_DLRS END-EXEC
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
           MOVE WS-REPORT-MONTH TO WS-MH-MONTH
           MOVE WS-MONTH-START  TO WS-MH-START
           MOVE WS-MONTH-END    TO WS-MH-END
           WRITE REPORT-RECORD FROM WS-MONTH-HEADER
               AFTER ADVANCING 2
      *
           MOVE WS-HV-DLR-CODE TO WS-DH-DEALER-CODE
           MOVE WS-HV-DLR-NAME TO WS-DH-DEALER-NAME
           WRITE REPORT-RECORD FROM WS-DEALER-HEADER
               AFTER ADVANCING 2
      *
           MOVE 8 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    5000-GATHER-KPIS - QUERY ALL KPI SECTIONS                 *
      ****************************************************************
       5000-GATHER-KPIS.
      *
           INITIALIZE WS-KPI-SALES
           INITIALIZE WS-KPI-INVENTORY
           INITIALIZE WS-KPI-FI
           INITIALIZE WS-KPI-WARRANTY
           INITIALIZE WS-KPI-REG
      *
      *    SALES - NEW
      *
           EXEC SQL OPEN CSR_SUP_NEW END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_NEW
                   INTO :WS-HV-SL-UNITS
                      , :WS-HV-SL-REVENUE
                      , :WS-HV-SL-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-SL-UNITS   TO WS-KS-NEW-UNITS
                   MOVE WS-HV-SL-REVENUE TO WS-KS-NEW-REVENUE
                   MOVE WS-HV-SL-GROSS   TO WS-KS-NEW-GROSS
               END-IF
               EXEC SQL CLOSE CSR_SUP_NEW END-EXEC
           END-IF
      *
      *    SALES - USED
      *
           EXEC SQL OPEN CSR_SUP_USED END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_USED
                   INTO :WS-HV-SL-UNITS
                      , :WS-HV-SL-REVENUE
                      , :WS-HV-SL-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-SL-UNITS   TO WS-KS-USED-UNITS
                   MOVE WS-HV-SL-REVENUE TO WS-KS-USED-REVENUE
                   MOVE WS-HV-SL-GROSS   TO WS-KS-USED-GROSS
               END-IF
               EXEC SQL CLOSE CSR_SUP_USED END-EXEC
           END-IF
      *
      *    SALES - LEASE
      *
           EXEC SQL OPEN CSR_SUP_LEASE END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_LEASE
                   INTO :WS-HV-SL-UNITS
                      , :WS-HV-SL-REVENUE
                      , :WS-HV-SL-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-SL-UNITS TO WS-KS-LEASE-UNITS
               END-IF
               EXEC SQL CLOSE CSR_SUP_LEASE END-EXEC
           END-IF
      *
      *    COMPUTE SALES TOTALS
      *
           COMPUTE WS-KS-TOTAL-UNITS =
               WS-KS-NEW-UNITS + WS-KS-USED-UNITS
               + WS-KS-LEASE-UNITS
           COMPUTE WS-KS-TOTAL-REVENUE =
               WS-KS-NEW-REVENUE + WS-KS-USED-REVENUE
           COMPUTE WS-KS-TOTAL-GROSS =
               WS-KS-NEW-GROSS + WS-KS-USED-GROSS
      *
      *    INVENTORY
      *
           EXEC SQL OPEN CSR_SUP_INV END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_INV
                   INTO :WS-HV-INV-COUNT
                      , :WS-HV-INV-VALUE
                      , :WS-HV-INV-AVG-DAYS
                      , :WS-HV-INV-AGED
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-INV-COUNT    TO WS-KI-ON-HAND
                   MOVE WS-HV-INV-VALUE    TO WS-KI-TOTAL-VALUE
                   MOVE WS-HV-INV-AVG-DAYS TO WS-KI-AVG-DAYS
                   MOVE WS-HV-INV-AGED     TO WS-KI-AGED-COUNT
               END-IF
               EXEC SQL CLOSE CSR_SUP_INV END-EXEC
           END-IF
      *
      *    F&I
      *
           EXEC SQL OPEN CSR_SUP_FI END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_FI
                   INTO :WS-HV-FI-TOTAL-DEALS
                      , :WS-HV-FI-DEALS
                      , :WS-HV-FI-REVENUE
                      , :WS-HV-FI-GROSS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-FI-TOTAL-DEALS TO WS-KF-TOTAL-DEALS
                   MOVE WS-HV-FI-DEALS       TO WS-KF-FI-DEALS
                   MOVE WS-HV-FI-REVENUE     TO WS-KF-FI-REVENUE
                   MOVE WS-HV-FI-GROSS       TO WS-KF-FI-GROSS
                   IF WS-KF-FI-DEALS > +0
                       COMPUTE WS-KF-AVG-PER-DEAL =
                           WS-KF-FI-GROSS / WS-KF-FI-DEALS
                   END-IF
               END-IF
               EXEC SQL CLOSE CSR_SUP_FI END-EXEC
           END-IF
      *
      *    WARRANTY
      *
           EXEC SQL OPEN CSR_SUP_WR END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_WR
                   INTO :WS-HV-WR-OPEN
                      , :WS-HV-WR-RECALLS
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-WR-OPEN    TO WS-KW-OPEN-CLAIMS
                   MOVE WS-HV-WR-RECALLS TO WS-KW-OPEN-RECALLS
               END-IF
               EXEC SQL CLOSE CSR_SUP_WR END-EXEC
           END-IF
      *
      *    REGISTRATION
      *
           EXEC SQL OPEN CSR_SUP_REG END-EXEC
           IF SQLCODE = +0
               EXEC SQL FETCH CSR_SUP_REG
                   INTO :WS-HV-RG-PENDING
                      , :WS-HV-RG-COMPLETED
                      , :WS-HV-RG-REJECTED
               END-EXEC
               IF SQLCODE = +0
                   MOVE WS-HV-RG-PENDING   TO WS-KR-PENDING
                   MOVE WS-HV-RG-COMPLETED TO WS-KR-COMPLETED
                   MOVE WS-HV-RG-REJECTED  TO WS-KR-REJECTED
               END-IF
               EXEC SQL CLOSE CSR_SUP_REG END-EXEC
           END-IF
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-KPI - PRINT ALL KPI SECTIONS            *
      ****************************************************************
       6000-PRINT-DEALER-KPI.
      *
      *    === SECTION 1: SALES PERFORMANCE ===
      *
           MOVE 'SALES PERFORMANCE' TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
      *    ROW 1: NEW UNITS / NEW REVENUE
      *
           MOVE 'New Vehicle Units:   ' TO WS-K1-LABEL1
           MOVE WS-KS-NEW-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'New Vehicle Revenue: ' TO WS-K1-LABEL2
           MOVE WS-KS-NEW-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    ROW 2: USED UNITS / USED REVENUE
      *
           MOVE 'Used Vehicle Units:  ' TO WS-K1-LABEL1
           MOVE WS-KS-USED-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Used Vehicle Revenue:' TO WS-K1-LABEL2
           MOVE WS-KS-USED-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    ROW 3: LEASE UNITS / TOTAL GROSS
      *
           MOVE 'Lease Units:         ' TO WS-K1-LABEL1
           MOVE WS-KS-LEASE-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Gross Profit:  ' TO WS-K1-LABEL2
           MOVE WS-KS-TOTAL-GROSS TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    ROW 4: TOTAL UNITS / TOTAL REVENUE
      *
           MOVE 'Total Units Sold:    ' TO WS-K1-LABEL1
           MOVE WS-KS-TOTAL-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Revenue:       ' TO WS-K1-LABEL2
           MOVE WS-KS-TOTAL-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === SECTION 2: INVENTORY ===
      *
           MOVE 'INVENTORY STATUS' TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
      *    ROW 1: ON HAND / TOTAL VALUE
      *
           MOVE 'Units On Hand:       ' TO WS-K1-LABEL1
           MOVE WS-KI-ON-HAND TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Inventory Value' TO WS-K1-LABEL2
           MOVE WS-KI-TOTAL-VALUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    ROW 2: AVG DAYS / AGED COUNT
      *
           MOVE 'Avg Days In Stock:   ' TO WS-K1-LABEL1
           MOVE WS-KI-AVG-DAYS TO WS-FMT-DAYS
           MOVE WS-FMT-DAYS TO WS-K1-VALUE1
           MOVE 'Aged Stock (90+ Days)' TO WS-K1-LABEL2
           MOVE WS-KI-AGED-COUNT TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === SECTION 3: F&I ===
      *
           MOVE 'FINANCE & INSURANCE' TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
      *    ROW 1: F&I PENETRATION / F&I REVENUE
      *
           MOVE 'F&I Deals:           ' TO WS-K1-LABEL1
           MOVE WS-KF-FI-DEALS TO WS-FMT-UNITS
           STRING WS-FMT-UNITS DELIMITED BY SIZE
                  ' OF ' DELIMITED BY SIZE
                  INTO WS-FMT-VALUE20
           MOVE WS-KF-TOTAL-DEALS TO WS-FMT-UNITS
           IF WS-KF-TOTAL-DEALS > +0
               COMPUTE WS-PCT-WORK =
                   (WS-KF-FI-DEALS / WS-KF-TOTAL-DEALS) * 100
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-FMT-VALUE20 TO WS-K1-VALUE1
           MOVE 'F&I Revenue:         ' TO WS-K1-LABEL2
           MOVE WS-KF-FI-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    ROW 2: PENETRATION PCT / AVG PER DEAL
      *
           MOVE 'Penetration Rate:    ' TO WS-K1-LABEL1
           MOVE WS-PCT-WORK TO WS-FMT-PCT
           STRING WS-FMT-PCT DELIMITED BY SPACES
                  '%' DELIMITED BY SIZE
                  INTO WS-FMT-VALUE20
           MOVE WS-FMT-VALUE20 TO WS-K1-VALUE1
           MOVE 'F&I Gross Per Deal:  ' TO WS-K1-LABEL2
           MOVE WS-KF-AVG-PER-DEAL TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === SECTION 4: WARRANTY ===
      *
           MOVE 'WARRANTY & RECALL STATUS' TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Active Warranties:   ' TO WS-K1-LABEL1
           MOVE WS-KW-OPEN-CLAIMS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Open Recall Actions: ' TO WS-K1-LABEL2
           MOVE WS-KW-OPEN-RECALLS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === SECTION 5: REGISTRATION ===
      *
           MOVE 'REGISTRATION & TITLE STATUS'
               TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Pending Registrations' TO WS-K1-LABEL1
           MOVE WS-KR-PENDING TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Completed:           ' TO WS-K1-LABEL2
           MOVE WS-KR-COMPLETED TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           MOVE 'Rejected/Errors:     ' TO WS-K1-LABEL1
           MOVE WS-KR-REJECTED TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE SPACES TO WS-K1-LABEL2
           MOVE SPACES TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    6500-ACCUMULATE-GRAND - ADD DEALER KPIS TO GRAND TOTALS   *
      ****************************************************************
       6500-ACCUMULATE-GRAND.
      *
           ADD WS-KS-NEW-UNITS    TO WS-GA-NEW-UNITS
           ADD WS-KS-NEW-REVENUE  TO WS-GA-NEW-REVENUE
           ADD WS-KS-NEW-GROSS    TO WS-GA-NEW-GROSS
           ADD WS-KS-USED-UNITS   TO WS-GA-USED-UNITS
           ADD WS-KS-USED-REVENUE TO WS-GA-USED-REVENUE
           ADD WS-KS-USED-GROSS   TO WS-GA-USED-GROSS
           ADD WS-KS-LEASE-UNITS  TO WS-GA-LEASE-UNITS
           ADD WS-KS-TOTAL-UNITS  TO WS-GA-TOTAL-UNITS
           ADD WS-KS-TOTAL-REVENUE TO WS-GA-TOTAL-REVENUE
           ADD WS-KS-TOTAL-GROSS  TO WS-GA-TOTAL-GROSS
      *
           ADD WS-KI-ON-HAND      TO WS-GA-INV-COUNT
           ADD WS-KI-TOTAL-VALUE  TO WS-GA-INV-VALUE
           ADD WS-KI-AVG-DAYS     TO WS-GA-INV-DAYS
           ADD WS-KI-AGED-COUNT   TO WS-GA-INV-AGED
      *
           ADD WS-KF-FI-DEALS     TO WS-GA-FI-DEALS
           ADD WS-KF-FI-REVENUE   TO WS-GA-FI-REVENUE
           ADD WS-KF-FI-GROSS     TO WS-GA-FI-GROSS
      *
           ADD WS-KW-OPEN-CLAIMS  TO WS-GA-WR-OPEN
           ADD WS-KW-OPEN-RECALLS TO WS-GA-WR-RECALLS
      *
           ADD WS-KR-PENDING      TO WS-GA-RG-PENDING
           ADD WS-KR-COMPLETED    TO WS-GA-RG-COMPLETED
           ADD WS-KR-REJECTED     TO WS-GA-RG-REJECTED
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-SUMMARY - ALL-DEALER AVERAGES PAGE       *
      ****************************************************************
       7000-PRINT-GRAND-SUMMARY.
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
           MOVE WS-REPORT-MONTH TO WS-MH-MONTH
           MOVE WS-MONTH-START  TO WS-MH-START
           MOVE WS-MONTH-END    TO WS-MH-END
           WRITE REPORT-RECORD FROM WS-MONTH-HEADER
               AFTER ADVANCING 2
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TITLE
               AFTER ADVANCING 2
      *
      *    === GRAND SALES ===
      *
           MOVE 'SALES PERFORMANCE - ALL DEALERS'
               TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Total New Units:     ' TO WS-K1-LABEL1
           MOVE WS-GA-NEW-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total New Revenue:   ' TO WS-K1-LABEL2
           MOVE WS-GA-NEW-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           MOVE 'Total Used Units:    ' TO WS-K1-LABEL1
           MOVE WS-GA-USED-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Used Revenue:  ' TO WS-K1-LABEL2
           MOVE WS-GA-USED-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           MOVE 'Total Lease Units:   ' TO WS-K1-LABEL1
           MOVE WS-GA-LEASE-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Gross Profit:  ' TO WS-K1-LABEL2
           MOVE WS-GA-TOTAL-GROSS TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           MOVE 'Grand Total Units:   ' TO WS-K1-LABEL1
           MOVE WS-GA-TOTAL-UNITS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Grand Total Revenue: ' TO WS-K1-LABEL2
           MOVE WS-GA-TOTAL-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    AVERAGES PER DEALER
      *
           IF WS-GA-DEALER-COUNT > +0
      *
               MOVE 'Avg Units/Dealer:    ' TO WS-K1-LABEL1
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-UNITS / WS-GA-DEALER-COUNT
               MOVE WS-AVG-WORK TO WS-FMT-UNITS
               MOVE WS-FMT-UNITS TO WS-K1-VALUE1
               MOVE 'Avg Revenue/Dealer:  ' TO WS-K1-LABEL2
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-REVENUE / WS-GA-DEALER-COUNT
               MOVE WS-AVG-WORK TO WS-FMT-AMOUNT
               MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
               WRITE REPORT-RECORD FROM WS-KPI-LINE-1
                   AFTER ADVANCING 1
      *
           END-IF
      *
      *    === GRAND INVENTORY ===
      *
           MOVE 'INVENTORY - ALL DEALERS'
               TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Total Units On Hand: ' TO WS-K1-LABEL1
           MOVE WS-GA-INV-COUNT TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Inventory Value' TO WS-K1-LABEL2
           MOVE WS-GA-INV-VALUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           IF WS-GA-DEALER-COUNT > +0
               MOVE 'Avg Days (All Dlrs): ' TO WS-K1-LABEL1
               COMPUTE WS-AVG-WORK =
                   WS-GA-INV-DAYS / WS-GA-DEALER-COUNT
               MOVE WS-AVG-WORK TO WS-FMT-DAYS
               MOVE WS-FMT-DAYS TO WS-K1-VALUE1
           ELSE
               MOVE 'Avg Days (All Dlrs): ' TO WS-K1-LABEL1
               MOVE '    0' TO WS-K1-VALUE1
           END-IF
           MOVE 'Total Aged Stock:    ' TO WS-K1-LABEL2
           MOVE WS-GA-INV-AGED TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === GRAND F&I ===
      *
           MOVE 'F&I - ALL DEALERS'
               TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Total F&I Deals:     ' TO WS-K1-LABEL1
           MOVE WS-GA-FI-DEALS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total F&I Revenue:   ' TO WS-K1-LABEL2
           MOVE WS-GA-FI-REVENUE TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           MOVE 'Total F&I Gross:     ' TO WS-K1-LABEL1
           MOVE WS-GA-FI-GROSS TO WS-FMT-AMOUNT
           MOVE WS-FMT-AMOUNT TO WS-K1-VALUE1
           MOVE SPACES TO WS-K1-LABEL2
           MOVE SPACES TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === GRAND WARRANTY ===
      *
           MOVE 'WARRANTY & RECALL - ALL DEALERS'
               TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Total Active Warr:   ' TO WS-K1-LABEL1
           MOVE WS-GA-WR-OPEN TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Open Recalls:  ' TO WS-K1-LABEL2
           MOVE WS-GA-WR-RECALLS TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
      *    === GRAND REGISTRATION ===
      *
           MOVE 'REGISTRATION - ALL DEALERS'
               TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SECTION-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 'Total Pending:       ' TO WS-K1-LABEL1
           MOVE WS-GA-RG-PENDING TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Total Completed:     ' TO WS-K1-LABEL2
           MOVE WS-GA-RG-COMPLETED TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
      *
           MOVE 'Total Rejected:      ' TO WS-K1-LABEL1
           MOVE WS-GA-RG-REJECTED TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE1
           MOVE 'Dealers Reported:    ' TO WS-K1-LABEL2
           MOVE WS-GA-DEALER-COUNT TO WS-FMT-UNITS
           MOVE WS-FMT-UNITS TO WS-K1-VALUE2
           WRITE REPORT-RECORD FROM WS-KPI-LINE-1
               AFTER ADVANCING 1
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
               DISPLAY 'RPTSUP00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTSUP00                                              *
      ****************************************************************
