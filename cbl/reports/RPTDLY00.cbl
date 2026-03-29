       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTDLY00.
      ****************************************************************
      * PROGRAM:    RPTDLY00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    DAILY SALES FLASH REPORT. PRODUCES ONE PAGE PER  *
      *             DEALER SHOWING TODAY'S SALES COUNT, REVENUE,     *
      *             AND GROSS PROFIT. DETAIL LINE FOR EACH DEAL      *
      *             SOLD TODAY WITH DEAL#, CUSTOMER, VEHICLE, SALE   *
      *             PRICE, AND GROSS PROFIT. DEALER SUBTOTALS AND    *
      *             GRAND TOTAL ACROSS ALL DEALERS.                  *
      *                                                              *
      * INPUT:      REPORT DATE PARAMETER (DEFAULT CURRENT DATE)     *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.CUSTOMER       (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTDLY00'.
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
           05  WS-REPORT-DATE          PIC X(10) VALUE SPACES.
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
               VALUE '   DAILY SALES FLASH REPORT   '.
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
           05  FILLER                  PIC X(25) VALUE
               'CUSTOMER NAME            '.
           05  FILLER                  PIC X(06) VALUE 'YEAR  '.
           05  FILLER                  PIC X(20) VALUE
               'MODEL               '.
           05  FILLER                  PIC X(12) VALUE 'DEAL TYPE   '.
           05  FILLER                  PIC X(16) VALUE
               '    SALE PRICE  '.
           05  FILLER                  PIC X(16) VALUE
               '  GROSS PROFIT  '.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE '---------- '.
           05  FILLER                  PIC X(25) VALUE
               '------------------------ '.
           05  FILLER                  PIC X(06) VALUE '---- '.
           05  FILLER                  PIC X(20) VALUE
               '------------------- '.
           05  FILLER                  PIC X(12) VALUE '---------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DEAL-NUMBER      PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-CUST-NAME        PIC X(24).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-YEAR             PIC X(04).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-MODEL            PIC X(19).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DEAL-TYPE        PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-SALE-PRICE       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-GROSS-PROFIT     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-SUBTOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '-'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'DEALER TOTALS:  '.
           05  WS-ST-DEAL-COUNT        PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' DEALS  '.
           05  WS-ST-TOTAL-REVENUE     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-ST-TOTAL-GROSS       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'GRAND TOTALS:   '.
           05  WS-GT-DEAL-COUNT        PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' DEALS  '.
           05  WS-GT-TOTAL-REVENUE     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-GT-TOTAL-GROSS       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-GRAND-AVG-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(44) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'AVG PER DEAL:   '.
           05  FILLER                  PIC X(13) VALUE SPACES.
           05  WS-GA-AVG-REVENUE       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-GA-AVG-GROSS         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS
      *
       01  WS-DEALER-ACCUM.
           05  WS-DA-DEAL-COUNT        PIC S9(06) COMP VALUE +0.
           05  WS-DA-TOTAL-REVENUE     PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-TOTAL-GROSS       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-DEAL-COUNT        PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-REVENUE     PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-TOTAL-GROSS       PIC S9(13)V99 COMP-3
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
           05  WS-HV-MODEL-YEAR       PIC X(04).
           05  WS-HV-MODEL-DESC       PIC X(30).
           05  WS-HV-DEAL-TYPE        PIC X(02).
           05  WS-HV-TOTAL-PRICE      PIC S9(09)V99 COMP-3.
           05  WS-HV-VEHICLE-COST     PIC S9(09)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-GROSS-PROFIT        PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-DEAL-TYPE-DESC      PIC X(10) VALUE SPACES.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-CUST-FULL-NAME      PIC X(24) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_DLY_DLRS CURSOR FOR
               SELECT DISTINCT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   D.DEALER_CODE = S.DEALER_CODE
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE = :WS-REPORT-DATE
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_DLY_DEALS CURSOR FOR
               SELECT S.DEAL_NUMBER
                    , C.LAST_NAME
                    , C.FIRST_NAME
                    , V.MODEL_YEAR
                    , V.MODEL_DESC
                    , S.DEAL_TYPE
                    , S.TOTAL_PRICE
                    , V.INVOICE_PRICE
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   S.CUSTOMER_ID = C.CUSTOMER_ID
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE = :WS-REPORT-DATE
               ORDER BY S.DEAL_NUMBER
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTDLY00: DAILY SALES FLASH REPORT - START'
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
           DISPLAY 'RPTDLY00: REPORT COMPLETE - '
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
           IF WS-REPORT-DATE = SPACES
               STRING WS-CURR-YYYY '-'
                      WS-CURR-MM   '-'
                      WS-CURR-DD
                      DELIMITED BY SIZE
                      INTO WS-REPORT-DATE
           END-IF
      *
           DISPLAY 'RPTDLY00: REPORT DATE = ' WS-REPORT-DATE
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
               DISPLAY 'RPTDLY00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_DLY_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTDLY00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_DLY_DLRS
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
                       DISPLAY 'RPTDLY00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DLY_DLRS END-EXEC
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
           EXEC SQL OPEN CSR_DLY_DEALS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTDLY00: ERROR OPENING DEAL CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEAL
      *
           PERFORM UNTIL WS-DEALS-DONE
               EXEC SQL FETCH CSR_DLY_DEALS
                   INTO :WS-HV-DEAL-NUMBER
                      , :WS-HV-CUST-LAST
                      , :WS-HV-CUST-FIRST
                      , :WS-HV-MODEL-YEAR
                      , :WS-HV-MODEL-DESC
                      , :WS-HV-DEAL-TYPE
                      , :WS-HV-TOTAL-PRICE
                      , :WS-HV-VEHICLE-COST
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-DEALS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTDLY00: DB2 ERROR ON DEAL - '
                               SQLCODE
                       SET WS-DEALS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DLY_DEALS END-EXEC
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
           STRING WS-HV-CUST-LAST DELIMITED BY '  '
                  ', ' DELIMITED BY SIZE
                  WS-HV-CUST-FIRST DELIMITED BY '  '
                  INTO WS-CUST-FULL-NAME
           MOVE WS-CUST-FULL-NAME TO WS-DL-CUST-NAME
      *
           MOVE WS-HV-MODEL-YEAR TO WS-DL-YEAR
           MOVE WS-HV-MODEL-DESC(1:19) TO WS-DL-MODEL
      *
           EVALUATE WS-HV-DEAL-TYPE
               WHEN 'N'
                   MOVE 'NEW       ' TO WS-DL-DEAL-TYPE
               WHEN 'U'
                   MOVE 'USED      ' TO WS-DL-DEAL-TYPE
               WHEN 'L'
                   MOVE 'LEASE     ' TO WS-DL-DEAL-TYPE
               WHEN 'W'
                   MOVE 'WHOLESALE ' TO WS-DL-DEAL-TYPE
               WHEN OTHER
                   MOVE WS-HV-DEAL-TYPE TO WS-DL-DEAL-TYPE
           END-EVALUATE
      *
           MOVE WS-HV-TOTAL-PRICE TO WS-DL-SALE-PRICE
      *
           COMPUTE WS-GROSS-PROFIT =
               WS-HV-TOTAL-PRICE - WS-HV-VEHICLE-COST
           MOVE WS-GROSS-PROFIT TO WS-DL-GROSS-PROFIT
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
      *    ACCUMULATE
      *
           ADD +1 TO WS-DA-DEAL-COUNT
           ADD WS-HV-TOTAL-PRICE TO WS-DA-TOTAL-REVENUE
           ADD WS-GROSS-PROFIT TO WS-DA-TOTAL-GROSS
      *
           ADD +1 TO WS-GA-DEAL-COUNT
           ADD WS-HV-TOTAL-PRICE TO WS-GA-TOTAL-REVENUE
           ADD WS-GROSS-PROFIT TO WS-GA-TOTAL-GROSS
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-SUBTOTAL                                *
      ****************************************************************
       6000-PRINT-DEALER-SUBTOTAL.
      *
           MOVE WS-DA-DEAL-COUNT    TO WS-ST-DEAL-COUNT
           MOVE WS-DA-TOTAL-REVENUE TO WS-ST-TOTAL-REVENUE
           MOVE WS-DA-TOTAL-GROSS   TO WS-ST-TOTAL-GROSS
      *
           WRITE REPORT-RECORD FROM WS-SUBTOTAL-LINE
               AFTER ADVANCING 2
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-DEAL-COUNT    TO WS-GT-DEAL-COUNT
           MOVE WS-GA-TOTAL-REVENUE TO WS-GT-TOTAL-REVENUE
           MOVE WS-GA-TOTAL-GROSS   TO WS-GT-TOTAL-GROSS
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
      *
      *    AVERAGE PER DEAL
      *
           IF WS-GA-DEAL-COUNT > +0
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-REVENUE / WS-GA-DEAL-COUNT
               MOVE WS-AVG-WORK TO WS-GA-AVG-REVENUE
      *
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-GROSS / WS-GA-DEAL-COUNT
               MOVE WS-AVG-WORK TO WS-GA-AVG-GROSS
           ELSE
               MOVE +0 TO WS-GA-AVG-REVENUE
               MOVE +0 TO WS-GA-AVG-GROSS
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-GRAND-AVG-LINE
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
               DISPLAY 'RPTDLY00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTDLY00                                              *
      ****************************************************************
