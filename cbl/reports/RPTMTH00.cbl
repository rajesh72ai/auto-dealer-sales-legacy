       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTMTH00.
      ****************************************************************
      * PROGRAM:    RPTMTH00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    MONTHLY CLOSE REPORT. MULTI-SECTION REPORT PER   *
      *             DEALER:                                          *
      *             SECTION 1: UNITS SOLD BY MODEL (NEW)             *
      *             SECTION 2: REVENUE AND GROSS PROFIT SUMMARY      *
      *             SECTION 3: F&I PERFORMANCE (PRODUCTS, AVG/DEAL)  *
      *             SECTION 4: INVENTORY STATUS (BEG/RECV/SOLD/END)  *
      *             SECTION 5: COMPARISON TO PRIOR MONTH AND PRIOR   *
      *                        YEAR SAME MONTH (MONTHLY_SNAPSHOT)    *
      *                                                              *
      * INPUT:      REPORT MONTH (YYYY-MM)                           *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
      *             AUTOSALE.FI_DEAL_PRODUCT (READ)                  *
      *             AUTOSALE.STOCK_POSITION (READ)                   *
      *             AUTOSALE.MONTHLY_SNAPSHOT (READ)                 *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTMTH00'.
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
           05  WS-EOF-DEALER           PIC X(01) VALUE 'N'.
               88  WS-DEALERS-DONE               VALUE 'Y'.
           05  WS-EOF-FLAG             PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA                VALUE 'Y'.
      *
      *    INPUT PARAMETERS
      *
       01  WS-PARM-AREA.
           05  WS-REPORT-MONTH        PIC X(07) VALUE SPACES.
           05  WS-MONTH-START         PIC X(10) VALUE SPACES.
           05  WS-MONTH-END           PIC X(10) VALUE SPACES.
           05  WS-PRIOR-MONTH         PIC X(07) VALUE SPACES.
           05  WS-PRIOR-YEAR-MONTH    PIC X(07) VALUE SPACES.
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY            PIC 9(04).
           05  WS-CURR-MM              PIC 9(02).
           05  WS-CURR-DD              PIC 9(02).
           05  FILLER                  PIC X(13).
      *
      *    HOST VARIABLES
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
       01  WS-HV-MODEL-SALES.
           05  WS-HV-MODEL-CODE       PIC X(06).
           05  WS-HV-MODEL-DESC       PIC X(30).
           05  WS-HV-UNITS-SOLD       PIC S9(06) COMP.
           05  WS-HV-REVENUE          PIC S9(11)V99 COMP-3.
           05  WS-HV-GROSS            PIC S9(11)V99 COMP-3.
      *
       01  WS-HV-FNI-DATA.
           05  WS-HV-PRODUCT-TYPE     PIC X(20).
           05  WS-HV-FNI-COUNT        PIC S9(06) COMP.
           05  WS-HV-FNI-REVENUE      PIC S9(09)V99 COMP-3.
           05  WS-HV-FNI-COST         PIC S9(09)V99 COMP-3.
      *
       01  WS-HV-INVENTORY.
           05  WS-HV-INV-BEGIN        PIC S9(06) COMP.
           05  WS-HV-INV-RECEIVED     PIC S9(06) COMP.
           05  WS-HV-INV-SOLD         PIC S9(06) COMP.
           05  WS-HV-INV-END          PIC S9(06) COMP.
      *
       01  WS-HV-SNAPSHOT.
           05  WS-HV-SNAP-UNITS       PIC S9(06) COMP.
           05  WS-HV-SNAP-REVENUE     PIC S9(11)V99 COMP-3.
           05  WS-HV-SNAP-GROSS       PIC S9(11)V99 COMP-3.
           05  WS-HV-SNAP-FNI         PIC S9(09)V99 COMP-3.
      *
      *    ACCUMULATORS
      *
       01  WS-SECTION-ACCUM.
           05  WS-SA-TOTAL-UNITS       PIC S9(06) COMP VALUE +0.
           05  WS-SA-TOTAL-REVENUE     PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-SA-TOTAL-GROSS       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-SA-FNI-TOTAL-CT      PIC S9(06) COMP VALUE +0.
           05  WS-SA-FNI-TOTAL-REV     PIC S9(09)V99 COMP-3
                                                      VALUE +0.
           05  WS-SA-FNI-TOTAL-PROFIT  PIC S9(09)V99 COMP-3
                                                      VALUE +0.
           05  WS-SA-DEAL-COUNT        PIC S9(06) COMP VALUE +0.
      *
      *    COMPARISON DATA
      *
       01  WS-PRIOR-MONTH-DATA.
           05  WS-PM-UNITS            PIC S9(06) COMP VALUE +0.
           05  WS-PM-REVENUE          PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-PM-GROSS            PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-PM-FNI              PIC S9(09)V99 COMP-3
                                                     VALUE +0.
      *
       01  WS-PRIOR-YEAR-DATA.
           05  WS-PY-UNITS            PIC S9(06) COMP VALUE +0.
           05  WS-PY-REVENUE          PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-PY-GROSS            PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-PY-FNI              PIC S9(09)V99 COMP-3
                                                     VALUE +0.
      *
      *    REPORT LINES
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE '    MONTHLY CLOSE REPORT      '.
           05  FILLER                  PIC X(08) VALUE 'MONTH:  '.
           05  WS-RH1-MONTH           PIC X(07).
           05  FILLER                  PIC X(08) VALUE '  PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(33) VALUE SPACES.
      *
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-DEALER-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(09) VALUE 'DEALER:  '.
           05  WS-DH-DEALER-CODE      PIC X(05).
           05  FILLER                  PIC X(03) VALUE ' - '.
           05  WS-DH-DEALER-NAME      PIC X(40).
           05  FILLER                  PIC X(74) VALUE SPACES.
      *
       01  WS-SECTION-TITLE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-SEC-TITLE-TEXT       PIC X(60).
           05  FILLER                  PIC X(71) VALUE SPACES.
      *
       01  WS-MODEL-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-MD-MODEL-CODE       PIC X(06).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-MD-MODEL-DESC       PIC X(25).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-MD-UNITS            PIC Z(4)9.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-MD-REVENUE          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-MD-GROSS            PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(48) VALUE SPACES.
      *
       01  WS-MODEL-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'MODEL '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(25)
               VALUE 'DESCRIPTION              '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE 'UNITS'.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE '     REVENUE    '.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE '  GROSS PROFIT  '.
           05  FILLER                  PIC X(48) VALUE SPACES.
      *
       01  WS-SECTION-TOTAL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(33) VALUE ALL '-'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-STL-UNITS           PIC Z(4)9.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-STL-REVENUE         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-STL-GROSS           PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(48) VALUE SPACES.
      *
       01  WS-FNI-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-FD-PRODUCT-TYPE      PIC X(20).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-FD-COUNT             PIC Z(4)9.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-FD-REVENUE           PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-FD-PROFIT            PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(06) VALUE SPACES.
           05  WS-FD-PENETRATION       PIC ZZ9.9.
           05  FILLER                  PIC X(01) VALUE '%'.
           05  FILLER                  PIC X(43) VALUE SPACES.
      *
       01  WS-FNI-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(20)
               VALUE 'PRODUCT TYPE        '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE 'COUNT'.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  FILLER                  PIC X(15)
               VALUE '    REVENUE    '.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  FILLER                  PIC X(15)
               VALUE '     PROFIT    '.
           05  FILLER                  PIC X(06) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE 'PENET'.
           05  FILLER                  PIC X(53) VALUE SPACES.
      *
       01  WS-INV-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(22)
               VALUE 'BEGINNING INVENTORY:  '.
           05  WS-INV-BEGIN            PIC Z(5)9.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(22)
               VALUE 'RECEIVED THIS MONTH:  '.
           05  WS-INV-RECV             PIC Z(5)9.
           05  FILLER                  PIC X(65) VALUE SPACES.
      *
       01  WS-INV-DETAIL-2.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(22)
               VALUE 'SOLD THIS MONTH:      '.
           05  WS-INV-SOLD             PIC Z(5)9.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(22)
               VALUE 'ENDING INVENTORY:     '.
           05  WS-INV-ENDING           PIC Z(5)9.
           05  FILLER                  PIC X(65) VALUE SPACES.
      *
       01  WS-COMPARE-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-CL-LABEL            PIC X(25).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-CL-CURRENT          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-CL-PRIOR            PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-CL-CHANGE           PIC -(5)9.9.
           05  FILLER                  PIC X(01) VALUE '%'.
           05  FILLER                  PIC X(43) VALUE SPACES.
      *
       01  WS-COMPARE-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(25)
               VALUE 'METRIC                   '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE '   CURRENT      '.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE '    PRIOR       '.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '  CHG % '.
           05  FILLER                  PIC X(52) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-PCT-CHANGE          PIC S9(05)V9 COMP-3
                                                     VALUE +0.
           05  WS-PENETRATION         PIC S9(03)V9 COMP-3
                                                     VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_MTH_DLRS CURSOR FOR
               SELECT DEALER_CODE
                    , DEALER_NAME
               FROM   AUTOSALE.DEALER
               WHERE  ACTIVE_FLAG = 'Y'
               ORDER BY DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_MTH_MODELS CURSOR FOR
               SELECT V.MODEL_CODE
                    , V.MODEL_DESC
                    , COUNT(*) AS UNITS_SOLD
                    , SUM(S.TOTAL_PRICE) AS REVENUE
                    , SUM(S.TOTAL_PRICE - V.INVOICE_PRICE)
                                         AS GROSS
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                          AND :WS-MONTH-END
                 AND  S.DEAL_TYPE = 'N'
               GROUP BY V.MODEL_CODE, V.MODEL_DESC
               ORDER BY V.MODEL_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_MTH_FNI CURSOR FOR
               SELECT FP.PRODUCT_TYPE
                    , COUNT(*) AS FNI_COUNT
                    , SUM(FP.SELLING_PRICE) AS FNI_REVENUE
                    , SUM(FP.DEALER_COST) AS FNI_COST
               FROM   AUTOSALE.FI_DEAL_PRODUCT FP
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   FP.DEAL_NUMBER = S.DEAL_NUMBER
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                          AND :WS-MONTH-END
               GROUP BY FP.PRODUCT_TYPE
               ORDER BY SUM(FP.SELLING_PRICE - FP.DEALER_COST)
                        DESC
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTMTH00: MONTHLY CLOSE REPORT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 3000-PROCESS-DEALERS
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTMTH00: REPORT COMPLETE'
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
           IF WS-REPORT-MONTH = SPACES
               STRING WS-CURR-YYYY '-'
                      WS-CURR-MM
                      DELIMITED BY SIZE
                      INTO WS-REPORT-MONTH
           END-IF
      *
           STRING WS-REPORT-MONTH '-01'
                  DELIMITED BY SIZE
                  INTO WS-MONTH-START
      *
      *    COMPUTE MONTH END DATE
      *
           EXEC SQL
               SELECT CHAR(DATE(:WS-MONTH-START)
                      + 1 MONTH - 1 DAY, ISO)
               INTO   :WS-MONTH-END
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    COMPUTE PRIOR MONTH
      *
           EXEC SQL
               SELECT CHAR(DATE(:WS-MONTH-START)
                      - 1 MONTH, ISO)
               INTO   :WS-PRIOR-MONTH
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
           MOVE WS-PRIOR-MONTH(1:7) TO WS-PRIOR-MONTH
      *
      *    COMPUTE PRIOR YEAR SAME MONTH
      *
           EXEC SQL
               SELECT CHAR(DATE(:WS-MONTH-START)
                      - 1 YEAR, ISO)
               INTO   :WS-PRIOR-YEAR-MONTH
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
           MOVE WS-PRIOR-YEAR-MONTH(1:7) TO WS-PRIOR-YEAR-MONTH
      *
           DISPLAY 'RPTMTH00: MONTH = ' WS-REPORT-MONTH
                   ' (' WS-MONTH-START ' TO ' WS-MONTH-END ')'
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTMTH00: ERROR OPENING REPORT FILE'
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_MTH_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTMTH00: ERROR OPENING DEALER CURSOR'
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_MTH_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 4000-PRINT-DEALER-REPORT
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTMTH00: DB2 ERROR - ' SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_MTH_DLRS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PRINT-DEALER-REPORT                                  *
      ****************************************************************
       4000-PRINT-DEALER-REPORT.
      *
           INITIALIZE WS-SECTION-ACCUM
      *
           PERFORM 4100-SECTION-1-UNITS-BY-MODEL
           PERFORM 4200-SECTION-2-REVENUE-SUMMARY
           PERFORM 4300-SECTION-3-FNI-PERFORMANCE
           PERFORM 4400-SECTION-4-INVENTORY-STATUS
           PERFORM 4500-SECTION-5-COMPARISON
           .
      *
      ****************************************************************
      *    4100-SECTION-1-UNITS-BY-MODEL (NEW VEHICLES)              *
      ****************************************************************
       4100-SECTION-1-UNITS-BY-MODEL.
      *
           PERFORM 8000-NEW-PAGE
      *
           MOVE WS-HV-DLR-CODE TO WS-DH-DEALER-CODE
           MOVE WS-HV-DLR-NAME TO WS-DH-DEALER-NAME
           WRITE REPORT-RECORD FROM WS-DEALER-HEADER
               AFTER ADVANCING 2
      *
           MOVE 'SECTION 1: NEW VEHICLE UNITS SOLD BY MODEL'
               TO WS-SEC-TITLE-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-MODEL-COL-HDR
               AFTER ADVANCING 2
           ADD 10 TO WS-LINE-COUNT
      *
           INITIALIZE WS-SECTION-ACCUM
      *
           EXEC SQL OPEN CSR_MTH_MODELS END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4100-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_MTH_MODELS
                   INTO :WS-HV-MODEL-CODE
                      , :WS-HV-MODEL-DESC
                      , :WS-HV-UNITS-SOLD
                      , :WS-HV-REVENUE
                      , :WS-HV-GROSS
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE WS-HV-MODEL-CODE TO WS-MD-MODEL-CODE
                   MOVE WS-HV-MODEL-DESC(1:25) TO WS-MD-MODEL-DESC
                   MOVE WS-HV-UNITS-SOLD TO WS-MD-UNITS
                   MOVE WS-HV-REVENUE    TO WS-MD-REVENUE
                   MOVE WS-HV-GROSS      TO WS-MD-GROSS
      *
                   WRITE REPORT-RECORD FROM WS-MODEL-DETAIL
                       AFTER ADVANCING 1
                   ADD +1 TO WS-LINE-COUNT
      *
                   ADD WS-HV-UNITS-SOLD TO WS-SA-TOTAL-UNITS
                   ADD WS-HV-REVENUE    TO WS-SA-TOTAL-REVENUE
                   ADD WS-HV-GROSS      TO WS-SA-TOTAL-GROSS
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_MTH_MODELS END-EXEC
      *
      *    SECTION TOTAL
      *
           MOVE WS-SA-TOTAL-UNITS   TO WS-STL-UNITS
           MOVE WS-SA-TOTAL-REVENUE TO WS-STL-REVENUE
           MOVE WS-SA-TOTAL-GROSS   TO WS-STL-GROSS
           WRITE REPORT-RECORD FROM WS-SECTION-TOTAL
               AFTER ADVANCING 2
           .
       4100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4200-SECTION-2-REVENUE-SUMMARY                            *
      ****************************************************************
       4200-SECTION-2-REVENUE-SUMMARY.
      *
           IF WS-LINE-COUNT >= 40
               PERFORM 8000-NEW-PAGE
           END-IF
      *
           MOVE 'SECTION 2: REVENUE AND GROSS PROFIT SUMMARY'
               TO WS-SEC-TITLE-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 3
      *
      *    GET TOTAL DEAL COUNT FOR THE MONTH (ALL TYPES)
      *
           EXEC SQL
               SELECT COUNT(*)
                    , COALESCE(SUM(TOTAL_PRICE), 0)
                    , COALESCE(SUM(TOTAL_PRICE
                               - VEHICLE_PRICE), 0)
               INTO :WS-SA-DEAL-COUNT
                  , :WS-SA-TOTAL-REVENUE
                  , :WS-SA-TOTAL-GROSS
               FROM  AUTOSALE.SALES_DEAL
               WHERE DEALER_CODE = :WS-HV-DLR-CODE
                 AND DEAL_STATUS = 'DL'
                 AND DELIVERY_DATE BETWEEN :WS-MONTH-START
                                       AND :WS-MONTH-END
           END-EXEC
      *
           MOVE 'TOTAL DEALS (ALL TYPES)  '
               TO WS-CL-LABEL
           MOVE WS-SA-DEAL-COUNT TO WS-CL-CURRENT
           MOVE SPACES TO WS-CL-PRIOR
           MOVE +0 TO WS-CL-CHANGE
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 2
      *
           MOVE 'TOTAL REVENUE            '
               TO WS-CL-LABEL
           MOVE WS-SA-TOTAL-REVENUE TO WS-CL-CURRENT
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 1
      *
           MOVE 'TOTAL GROSS PROFIT       '
               TO WS-CL-LABEL
           MOVE WS-SA-TOTAL-GROSS TO WS-CL-CURRENT
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 1
      *
           IF WS-SA-DEAL-COUNT > +0
               COMPUTE WS-AVG-WORK =
                   WS-SA-TOTAL-GROSS / WS-SA-DEAL-COUNT
           ELSE
               MOVE +0 TO WS-AVG-WORK
           END-IF
           MOVE 'AVG GROSS PER DEAL       '
               TO WS-CL-LABEL
           MOVE WS-AVG-WORK TO WS-CL-CURRENT
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 1
      *
           ADD 8 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    4300-SECTION-3-FNI-PERFORMANCE                            *
      ****************************************************************
       4300-SECTION-3-FNI-PERFORMANCE.
      *
           IF WS-LINE-COUNT >= 40
               PERFORM 8000-NEW-PAGE
           END-IF
      *
           MOVE 'SECTION 3: F&I PERFORMANCE'
               TO WS-SEC-TITLE-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 3
           WRITE REPORT-RECORD FROM WS-FNI-COL-HDR
               AFTER ADVANCING 2
           ADD 6 TO WS-LINE-COUNT
      *
           MOVE +0 TO WS-SA-FNI-TOTAL-CT
           MOVE +0 TO WS-SA-FNI-TOTAL-REV
           MOVE +0 TO WS-SA-FNI-TOTAL-PROFIT
      *
           EXEC SQL OPEN CSR_MTH_FNI END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4300-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_MTH_FNI
                   INTO :WS-HV-PRODUCT-TYPE
                      , :WS-HV-FNI-COUNT
                      , :WS-HV-FNI-REVENUE
                      , :WS-HV-FNI-COST
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE WS-HV-PRODUCT-TYPE TO WS-FD-PRODUCT-TYPE
                   MOVE WS-HV-FNI-COUNT    TO WS-FD-COUNT
                   MOVE WS-HV-FNI-REVENUE  TO WS-FD-REVENUE
                   COMPUTE WS-AVG-WORK =
                       WS-HV-FNI-REVENUE - WS-HV-FNI-COST
                   MOVE WS-AVG-WORK TO WS-FD-PROFIT
      *
                   IF WS-SA-DEAL-COUNT > +0
                       COMPUTE WS-PENETRATION =
                           (WS-HV-FNI-COUNT * 100)
                           / WS-SA-DEAL-COUNT
                   ELSE
                       MOVE +0 TO WS-PENETRATION
                   END-IF
                   MOVE WS-PENETRATION TO WS-FD-PENETRATION
      *
                   WRITE REPORT-RECORD FROM WS-FNI-DETAIL
                       AFTER ADVANCING 1
                   ADD +1 TO WS-LINE-COUNT
      *
                   ADD WS-HV-FNI-COUNT
                       TO WS-SA-FNI-TOTAL-CT
                   ADD WS-HV-FNI-REVENUE
                       TO WS-SA-FNI-TOTAL-REV
                   ADD WS-AVG-WORK
                       TO WS-SA-FNI-TOTAL-PROFIT
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_MTH_FNI END-EXEC
      *
      *    F&I SUMMARY
      *
           IF WS-SA-DEAL-COUNT > +0
               COMPUTE WS-AVG-WORK =
                   WS-SA-FNI-TOTAL-REV / WS-SA-DEAL-COUNT
           ELSE
               MOVE +0 TO WS-AVG-WORK
           END-IF
      *
           MOVE 'AVG F&I PER DEAL         '
               TO WS-CL-LABEL
           MOVE WS-AVG-WORK TO WS-CL-CURRENT
           MOVE SPACES TO WS-CL-PRIOR
           MOVE +0 TO WS-CL-CHANGE
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 2
           ADD 2 TO WS-LINE-COUNT
           .
       4300-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4400-SECTION-4-INVENTORY-STATUS                           *
      ****************************************************************
       4400-SECTION-4-INVENTORY-STATUS.
      *
           PERFORM 8000-NEW-PAGE
      *
           MOVE 'SECTION 4: INVENTORY STATUS'
               TO WS-SEC-TITLE-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 2
           ADD 4 TO WS-LINE-COUNT
      *
           EXEC SQL
               SELECT COALESCE(ON_HAND, 0)
                    , COALESCE(RECEIVED_MTD, 0)
                    , COALESCE(SOLD_MTD, 0)
                    , COALESCE(ON_HAND + SOLD_MTD
                               - RECEIVED_MTD, 0)
               INTO :WS-HV-INV-END
                  , :WS-HV-INV-RECEIVED
                  , :WS-HV-INV-SOLD
                  , :WS-HV-INV-BEGIN
               FROM  AUTOSALE.STOCK_POSITION
               WHERE DEALER_CODE = :WS-HV-DLR-CODE
               FETCH FIRST 1 ROWS ONLY
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE WS-HV-INV-BEGIN    TO WS-INV-BEGIN
               MOVE WS-HV-INV-RECEIVED TO WS-INV-RECV
               WRITE REPORT-RECORD FROM WS-INV-DETAIL
                   AFTER ADVANCING 2
      *
               MOVE WS-HV-INV-SOLD   TO WS-INV-SOLD
               MOVE WS-HV-INV-END    TO WS-INV-ENDING
               WRITE REPORT-RECORD FROM WS-INV-DETAIL-2
                   AFTER ADVANCING 1
               ADD 4 TO WS-LINE-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    4500-SECTION-5-COMPARISON                                 *
      ****************************************************************
       4500-SECTION-5-COMPARISON.
      *
           IF WS-LINE-COUNT >= 35
               PERFORM 8000-NEW-PAGE
           END-IF
      *
           MOVE 'SECTION 5: MONTH-OVER-MONTH COMPARISON'
               TO WS-SEC-TITLE-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 3
      *
           WRITE REPORT-RECORD FROM WS-COMPARE-HDR
               AFTER ADVANCING 2
           ADD 6 TO WS-LINE-COUNT
      *
      *    LOAD PRIOR MONTH SNAPSHOT
      *
           EXEC SQL
               SELECT COALESCE(UNITS_SOLD, 0)
                    , COALESCE(TOTAL_REVENUE, 0)
                    , COALESCE(TOTAL_GROSS, 0)
                    , COALESCE(FNI_GROSS, 0)
               INTO :WS-PM-UNITS
                  , :WS-PM-REVENUE
                  , :WS-PM-GROSS
                  , :WS-PM-FNI
               FROM  AUTOSALE.MONTHLY_SNAPSHOT
               WHERE DEALER_CODE = :WS-HV-DLR-CODE
                 AND SNAPSHOT_MONTH = :WS-PRIOR-MONTH
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +0 TO WS-PM-UNITS
               MOVE +0 TO WS-PM-REVENUE
               MOVE +0 TO WS-PM-GROSS
               MOVE +0 TO WS-PM-FNI
           END-IF
      *
      *    LOAD PRIOR YEAR SNAPSHOT
      *
           EXEC SQL
               SELECT COALESCE(UNITS_SOLD, 0)
                    , COALESCE(TOTAL_REVENUE, 0)
                    , COALESCE(TOTAL_GROSS, 0)
                    , COALESCE(FNI_GROSS, 0)
               INTO :WS-PY-UNITS
                  , :WS-PY-REVENUE
                  , :WS-PY-GROSS
                  , :WS-PY-FNI
               FROM  AUTOSALE.MONTHLY_SNAPSHOT
               WHERE DEALER_CODE = :WS-HV-DLR-CODE
                 AND SNAPSHOT_MONTH = :WS-PRIOR-YEAR-MONTH
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +0 TO WS-PY-UNITS
               MOVE +0 TO WS-PY-REVENUE
               MOVE +0 TO WS-PY-GROSS
               MOVE +0 TO WS-PY-FNI
           END-IF
      *
      *    PRINT COMPARISON: PRIOR MONTH
      *
           MOVE 'VS PRIOR MONTH - UNITS   '
               TO WS-CL-LABEL
           MOVE WS-SA-TOTAL-UNITS TO WS-CL-CURRENT
           MOVE WS-PM-UNITS       TO WS-CL-PRIOR
           IF WS-PM-UNITS > +0
               COMPUTE WS-PCT-CHANGE =
                   ((WS-SA-TOTAL-UNITS - WS-PM-UNITS)
                    * 100) / WS-PM-UNITS
           ELSE
               MOVE +0 TO WS-PCT-CHANGE
           END-IF
           MOVE WS-PCT-CHANGE TO WS-CL-CHANGE
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 1
      *
           MOVE 'VS PRIOR MONTH - REVENUE '
               TO WS-CL-LABEL
           MOVE WS-SA-TOTAL-REVENUE TO WS-CL-CURRENT
           MOVE WS-PM-REVENUE       TO WS-CL-PRIOR
           IF WS-PM-REVENUE > +0
               COMPUTE WS-PCT-CHANGE =
                   ((WS-SA-TOTAL-REVENUE - WS-PM-REVENUE)
                    * 100) / WS-PM-REVENUE
           ELSE
               MOVE +0 TO WS-PCT-CHANGE
           END-IF
           MOVE WS-PCT-CHANGE TO WS-CL-CHANGE
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 1
      *
      *    PRINT COMPARISON: PRIOR YEAR
      *
           MOVE 'VS PRIOR YEAR - UNITS    '
               TO WS-CL-LABEL
           MOVE WS-SA-TOTAL-UNITS TO WS-CL-CURRENT
           MOVE WS-PY-UNITS       TO WS-CL-PRIOR
           IF WS-PY-UNITS > +0
               COMPUTE WS-PCT-CHANGE =
                   ((WS-SA-TOTAL-UNITS - WS-PY-UNITS)
                    * 100) / WS-PY-UNITS
           ELSE
               MOVE +0 TO WS-PCT-CHANGE
           END-IF
           MOVE WS-PCT-CHANGE TO WS-CL-CHANGE
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 2
      *
           MOVE 'VS PRIOR YEAR - REVENUE  '
               TO WS-CL-LABEL
           MOVE WS-SA-TOTAL-REVENUE TO WS-CL-CURRENT
           MOVE WS-PY-REVENUE       TO WS-CL-PRIOR
           IF WS-PY-REVENUE > +0
               COMPUTE WS-PCT-CHANGE =
                   ((WS-SA-TOTAL-REVENUE - WS-PY-REVENUE)
                    * 100) / WS-PY-REVENUE
           ELSE
               MOVE +0 TO WS-PCT-CHANGE
           END-IF
           MOVE WS-PCT-CHANGE TO WS-CL-CHANGE
           WRITE REPORT-RECORD FROM WS-COMPARE-LINE
               AFTER ADVANCING 1
      *
           ADD 6 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    8000-NEW-PAGE                                             *
      ****************************************************************
       8000-NEW-PAGE.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           MOVE WS-REPORT-MONTH TO WS-RH1-MONTH
      *
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           MOVE 4 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE REPORT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTMTH00: ERROR CLOSING REPORT FILE'
           END-IF
           .
      ****************************************************************
      * END OF RPTMTH00                                              *
      ****************************************************************
