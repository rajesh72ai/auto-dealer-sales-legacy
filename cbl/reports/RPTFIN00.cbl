       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTFIN00.
      ****************************************************************
      * PROGRAM:    RPTFIN00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    FINANCE & INSURANCE SUMMARY REPORT. PRODUCES     *
      *             ONE PAGE PER DEALER SHOWING F&I PRODUCT          *
      *             PENETRATION AND REVENUE. DETAIL LINE FOR EACH    *
      *             DEAL WITH FINANCE TYPE, F&I PRODUCTS SOLD, AND   *
      *             TOTAL F&I REVENUE. DEALER SUBTOTALS WITH         *
      *             PENETRATION RATE AND GRAND TOTALS.               *
      *                                                              *
      * INPUT:      REPORT MONTH (YYYYMM) PARAMETER                 *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ)                   *
      *             AUTOSALE.FINANCE_APP    (READ)                   *
      *             AUTOSALE.FINANCE_PRODUCT(READ)                   *
      *             AUTOSALE.CUSTOMER       (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTFIN00'.
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
           05  WS-EOF-DEAL             PIC X(01) VALUE 'N'.
               88  WS-DEALS-DONE                 VALUE 'Y'.
      *
      *    INPUT PARAMETER
      *
       01  WS-PARM-AREA.
           05  WS-REPORT-MONTH         PIC X(06) VALUE SPACES.
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
      *    REPORT HEADER LINE (132 CHARS)
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE ' F&I PENETRATION SUMMARY RPT  '.
           05  FILLER                  PIC X(08) VALUE 'MONTH:  '.
           05  WS-RH1-MONTH           PIC X(06).
           05  FILLER                  PIC X(09) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(27) VALUE SPACES.
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
       01  WS-COLUMN-HEADERS.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE 'DEAL #    '.
           05  FILLER                  PIC X(22) VALUE
               'CUSTOMER              '.
           05  FILLER                  PIC X(18) VALUE
               'VEHICLE           '.
           05  FILLER                  PIC X(08) VALUE 'FIN TYP '.
           05  FILLER                  PIC X(08) VALUE 'PROD CT '.
           05  FILLER                  PIC X(16) VALUE
               '  F&I REVENUE   '.
           05  FILLER                  PIC X(16) VALUE
               '  F&I GROSS     '.
           05  FILLER                  PIC X(31) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE '---------- '.
           05  FILLER                  PIC X(22) VALUE
               '--------------------- '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(08) VALUE '------- '.
           05  FILLER                  PIC X(08) VALUE '------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(31) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DEAL-NUMBER      PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-CUST-NAME        PIC X(21).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-VEHICLE          PIC X(17).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-FIN-TYPE         PIC X(07).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-PROD-COUNT       PIC Z(4)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-FI-REVENUE       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-FI-GROSS         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(31) VALUE SPACES.
      *
       01  WS-SUBTOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '-'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'DEALER TOTALS:  '.
           05  WS-ST-DEAL-COUNT        PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' DEALS  '.
           05  WS-ST-FI-REVENUE        PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-ST-FI-GROSS          PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-PENETRATION-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(44) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'F&I PENETRATION:'.
           05  WS-PL-WITH-FI           PIC Z(4)9.
           05  FILLER                  PIC X(04) VALUE ' OF '.
           05  WS-PL-TOTAL             PIC Z(4)9.
           05  FILLER                  PIC X(02) VALUE ' ('.
           05  WS-PL-PCT               PIC ZZ9.9.
           05  FILLER                  PIC X(02) VALUE '%)'.
           05  FILLER                  PIC X(36) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'GRAND TOTALS:   '.
           05  WS-GT-DEAL-COUNT        PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' DEALS  '.
           05  WS-GT-FI-REVENUE        PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-GT-FI-GROSS          PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-GRAND-PEN-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(44) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'F&I PENETRATION:'.
           05  WS-GP-WITH-FI           PIC Z(4)9.
           05  FILLER                  PIC X(04) VALUE ' OF '.
           05  WS-GP-TOTAL             PIC Z(4)9.
           05  FILLER                  PIC X(02) VALUE ' ('.
           05  WS-GP-PCT               PIC ZZ9.9.
           05  FILLER                  PIC X(02) VALUE '%)'.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(12)
               VALUE 'AVG F&I/DL: '.
           05  WS-GP-AVG-FI            PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(04) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS
      *
       01  WS-DEALER-ACCUM.
           05  WS-DA-DEAL-COUNT        PIC S9(06) COMP VALUE +0.
           05  WS-DA-FI-DEAL-COUNT     PIC S9(06) COMP VALUE +0.
           05  WS-DA-FI-REVENUE        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-FI-GROSS          PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-DEAL-COUNT        PIC S9(08) COMP VALUE +0.
           05  WS-GA-FI-DEAL-COUNT     PIC S9(08) COMP VALUE +0.
           05  WS-GA-FI-REVENUE        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-FI-GROSS          PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-DEALER-COUNT      PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - DEAL CURSOR
      *
       01  WS-HV-DEAL.
           05  WS-HV-DEAL-NUMBER      PIC X(10).
           05  WS-HV-CUST-LAST        PIC X(25).
           05  WS-HV-CUST-FIRST       PIC X(15).
           05  WS-HV-MODEL-YEAR       PIC S9(04) COMP.
           05  WS-HV-MODEL-NAME       PIC X(30).
           05  WS-HV-FIN-TYPE         PIC X(01).
           05  WS-HV-PROD-COUNT       PIC S9(04) COMP.
           05  WS-HV-FI-REVENUE       PIC S9(09)V99 COMP-3.
           05  WS-HV-FI-GROSS         PIC S9(09)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-FIN-TYPE-DESC       PIC X(07) VALUE SPACES.
           05  WS-CUST-FULL-NAME      PIC X(21) VALUE SPACES.
           05  WS-VEHICLE-DESC        PIC X(17) VALUE SPACES.
           05  WS-YEAR-DISP           PIC 9(04) VALUE 0.
           05  WS-PEN-WORK            PIC S9(05)V9 COMP-3
                                                    VALUE +0.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                    VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_FIN_DLRS CURSOR FOR
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
           EXEC SQL DECLARE CSR_FIN_DEALS CURSOR FOR
               SELECT S.DEAL_NUMBER
                    , C.LAST_NAME
                    , C.FIRST_NAME
                    , M.MODEL_YEAR
                    , M.MODEL_NAME
                    , COALESCE(F.FINANCE_TYPE, 'C')
                    , COALESCE(FP.PROD_CNT, 0)
                    , COALESCE(FP.FI_REVENUE, 0)
                    , COALESCE(FP.FI_GROSS, 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   S.CUSTOMER_ID = C.CUSTOMER_ID
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               INNER JOIN AUTOSALE.MODEL_MASTER M
                 ON   V.MODEL_YEAR = M.MODEL_YEAR
                AND   V.MAKE_CODE  = M.MAKE_CODE
                AND   V.MODEL_CODE = M.MODEL_CODE
               LEFT OUTER JOIN AUTOSALE.FINANCE_APP F
                 ON   S.DEAL_NUMBER = F.DEAL_NUMBER
                AND   F.APP_STATUS IN ('CT', 'FD')
               LEFT OUTER JOIN
                 (SELECT DEAL_NUMBER
                       , COUNT(*) AS PROD_CNT
                       , SUM(RETAIL_PRICE) AS FI_REVENUE
                       , SUM(GROSS_PROFIT) AS FI_GROSS
                  FROM  AUTOSALE.FINANCE_PRODUCT
                  GROUP BY DEAL_NUMBER) FP
                 ON   S.DEAL_NUMBER = FP.DEAL_NUMBER
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE >= :WS-START-DATE
                 AND  S.DELIVERY_DATE <= :WS-END-DATE
               ORDER BY S.DEAL_NUMBER
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTFIN00: F&I PENETRATION SUMMARY - START'
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
           DISPLAY 'RPTFIN00: REPORT COMPLETE - '
                   WS-GA-DEAL-COUNT ' DEALS, '
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
           IF WS-REPORT-MONTH = SPACES
               STRING WS-CURR-YYYY
                      WS-CURR-MM
                      DELIMITED BY SIZE
                      INTO WS-REPORT-MONTH
           END-IF
      *
           STRING WS-REPORT-MONTH(1:4) '-'
                  WS-REPORT-MONTH(5:2) '-01'
                  DELIMITED BY SIZE
                  INTO WS-START-DATE
      *
           EXEC SQL
               SELECT CHAR(DATE(:WS-START-DATE)
                    + 1 MONTH - 1 DAY, ISO)
               INTO   :WS-END-DATE
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'RPTFIN00: MONTH = ' WS-REPORT-MONTH
                   ' (' WS-START-DATE ' TO ' WS-END-DATE ')'
      *
           INITIALIZE WS-DEALER-ACCUM
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
               DISPLAY 'RPTFIN00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_FIN_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTFIN00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_FIN_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-PROCESS-DEALS
                       PERFORM 6000-PRINT-DEALER-SUBTOTAL
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTFIN00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_FIN_DLRS END-EXEC
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
           MOVE WS-REPORT-MONTH TO WS-RH1-MONTH
      *
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           MOVE WS-HV-DLR-CODE TO WS-DH-DEALER-CODE
           MOVE WS-HV-DLR-NAME TO WS-DH-DEALER-NAME
           WRITE REPORT-RECORD FROM WS-DEALER-HEADER
               AFTER ADVANCING 2
      *
           WRITE REPORT-RECORD FROM WS-COLUMN-HEADERS
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-COLUMN-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 10 TO WS-LINE-COUNT
      *
           INITIALIZE WS-DEALER-ACCUM
           .
      *
      ****************************************************************
      *    5000-PROCESS-DEALS - DETAIL LINES FOR EACH DEAL           *
      ****************************************************************
       5000-PROCESS-DEALS.
      *
           EXEC SQL OPEN CSR_FIN_DEALS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTFIN00: ERROR OPENING DEAL CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEAL
      *
           PERFORM UNTIL WS-DEALS-DONE
               EXEC SQL FETCH CSR_FIN_DEALS
                   INTO :WS-HV-DEAL-NUMBER
                      , :WS-HV-CUST-LAST
                      , :WS-HV-CUST-FIRST
                      , :WS-HV-MODEL-YEAR
                      , :WS-HV-MODEL-NAME
                      , :WS-HV-FIN-TYPE
                      , :WS-HV-PROD-COUNT
                      , :WS-HV-FI-REVENUE
                      , :WS-HV-FI-GROSS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-DEALS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTFIN00: DB2 ERROR ON DEAL - '
                               SQLCODE
                       SET WS-DEALS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_FIN_DEALS END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FORMAT-DETAIL - FORMAT AND PRINT ONE DEAL LINE       *
      ****************************************************************
       5100-FORMAT-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 4000-NEW-DEALER-PAGE
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
      *
           MOVE WS-HV-DEAL-NUMBER TO WS-DL-DEAL-NUMBER
      *
           MOVE SPACES TO WS-CUST-FULL-NAME
           STRING WS-HV-CUST-LAST DELIMITED BY '  '
                  ', ' DELIMITED BY SIZE
                  WS-HV-CUST-FIRST DELIMITED BY '  '
                  INTO WS-CUST-FULL-NAME
           MOVE WS-CUST-FULL-NAME TO WS-DL-CUST-NAME
      *
           MOVE WS-HV-MODEL-YEAR TO WS-YEAR-DISP
           MOVE SPACES TO WS-VEHICLE-DESC
           STRING WS-YEAR-DISP DELIMITED BY SIZE
                  ' ' DELIMITED BY SIZE
                  WS-HV-MODEL-NAME DELIMITED BY '  '
                  INTO WS-VEHICLE-DESC
           MOVE WS-VEHICLE-DESC TO WS-DL-VEHICLE
      *
           EVALUATE WS-HV-FIN-TYPE
               WHEN 'L'
                   MOVE 'LOAN   ' TO WS-DL-FIN-TYPE
               WHEN 'S'
                   MOVE 'LEASE  ' TO WS-DL-FIN-TYPE
               WHEN 'C'
                   MOVE 'CASH   ' TO WS-DL-FIN-TYPE
               WHEN OTHER
                   MOVE WS-HV-FIN-TYPE TO WS-DL-FIN-TYPE
           END-EVALUATE
      *
           MOVE WS-HV-PROD-COUNT TO WS-DL-PROD-COUNT
           MOVE WS-HV-FI-REVENUE TO WS-DL-FI-REVENUE
           MOVE WS-HV-FI-GROSS   TO WS-DL-FI-GROSS
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
      *    ACCUMULATE
      *
           ADD +1 TO WS-DA-DEAL-COUNT
           ADD WS-HV-FI-REVENUE TO WS-DA-FI-REVENUE
           ADD WS-HV-FI-GROSS   TO WS-DA-FI-GROSS
      *
           IF WS-HV-PROD-COUNT > +0
               ADD +1 TO WS-DA-FI-DEAL-COUNT
           END-IF
      *
           ADD +1 TO WS-GA-DEAL-COUNT
           ADD WS-HV-FI-REVENUE TO WS-GA-FI-REVENUE
           ADD WS-HV-FI-GROSS   TO WS-GA-FI-GROSS
      *
           IF WS-HV-PROD-COUNT > +0
               ADD +1 TO WS-GA-FI-DEAL-COUNT
           END-IF
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-SUBTOTAL                                *
      ****************************************************************
       6000-PRINT-DEALER-SUBTOTAL.
      *
           MOVE WS-DA-DEAL-COUNT  TO WS-ST-DEAL-COUNT
           MOVE WS-DA-FI-REVENUE  TO WS-ST-FI-REVENUE
           MOVE WS-DA-FI-GROSS    TO WS-ST-FI-GROSS
      *
           WRITE REPORT-RECORD FROM WS-SUBTOTAL-LINE
               AFTER ADVANCING 2
      *
      *    PENETRATION RATE
      *
           MOVE WS-DA-FI-DEAL-COUNT TO WS-PL-WITH-FI
           MOVE WS-DA-DEAL-COUNT    TO WS-PL-TOTAL
      *
           IF WS-DA-DEAL-COUNT > +0
               COMPUTE WS-PEN-WORK =
                   (WS-DA-FI-DEAL-COUNT * 100)
                   / WS-DA-DEAL-COUNT
           ELSE
               MOVE +0 TO WS-PEN-WORK
           END-IF
           MOVE WS-PEN-WORK TO WS-PL-PCT
      *
           WRITE REPORT-RECORD FROM WS-PENETRATION-LINE
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-DEAL-COUNT  TO WS-GT-DEAL-COUNT
           MOVE WS-GA-FI-REVENUE  TO WS-GT-FI-REVENUE
           MOVE WS-GA-FI-GROSS    TO WS-GT-FI-GROSS
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
      *
      *    GRAND PENETRATION
      *
           MOVE WS-GA-FI-DEAL-COUNT TO WS-GP-WITH-FI
           MOVE WS-GA-DEAL-COUNT    TO WS-GP-TOTAL
      *
           IF WS-GA-DEAL-COUNT > +0
               COMPUTE WS-PEN-WORK =
                   (WS-GA-FI-DEAL-COUNT * 100)
                   / WS-GA-DEAL-COUNT
               COMPUTE WS-AVG-WORK =
                   WS-GA-FI-REVENUE / WS-GA-DEAL-COUNT
           ELSE
               MOVE +0 TO WS-PEN-WORK
               MOVE +0 TO WS-AVG-WORK
           END-IF
           MOVE WS-PEN-WORK TO WS-GP-PCT
           MOVE WS-AVG-WORK TO WS-GP-AVG-FI
      *
           WRITE REPORT-RECORD FROM WS-GRAND-PEN-LINE
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
               DISPLAY 'RPTFIN00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTFIN00                                              *
      ****************************************************************
