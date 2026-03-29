       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTCUS00.
      ****************************************************************
      * PROGRAM:    RPTCUS00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    CUSTOMER ACTIVITY REPORT. SHOWS PURCHASE HISTORY *
      *             AND ACTIVITY PER CUSTOMER, SORTED BY DEALER      *
      *             THEN CUSTOMER. DETAIL: CUSTOMER ID, NAME, TOTAL  *
      *             PURCHASES, LAST PURCHASE DATE, TOTAL SPENT, AVG  *
      *             DEAL VALUE. SUBTOTALS PER DEALER WITH CUSTOMER   *
      *             COUNT AND TOTAL REVENUE. GRAND TOTALS WITH       *
      *             REPEAT BUYER PERCENTAGE.                         *
      *                                                              *
      * INPUT:      NONE (ALL DELIVERED DEALS)                       *
      *                                                              *
      * TABLES:     AUTOSALE.CUSTOMER       (READ)                   *
      *             AUTOSALE.SALES_DEAL     (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTCUS00'.
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
           05  WS-EOF-CUST             PIC X(01) VALUE 'N'.
               88  WS-CUSTS-DONE                 VALUE 'Y'.
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
               VALUE '  CUSTOMER ACTIVITY REPORT    '.
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
           05  FILLER                  PIC X(12) VALUE 'CUST ID   '.
           05  FILLER                  PIC X(30) VALUE
               'CUSTOMER NAME                 '.
           05  FILLER                  PIC X(10) VALUE 'PURCHASES '.
           05  FILLER                  PIC X(14) VALUE
               'LAST PURCHASE '.
           05  FILLER                  PIC X(18) VALUE
               '     TOTAL SPENT  '.
           05  FILLER                  PIC X(18) VALUE
               '  AVG DEAL VALUE  '.
           05  FILLER                  PIC X(29) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE '---------- '.
           05  FILLER                  PIC X(30) VALUE
               '---------------------------- '.
           05  FILLER                  PIC X(10) VALUE '--------- '.
           05  FILLER                  PIC X(14) VALUE
               '------------ '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(18) VALUE
               '----------------- '.
           05  FILLER                  PIC X(29) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-CUST-ID          PIC Z(9)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-CUST-NAME        PIC X(28).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-PURCHASES        PIC Z(4)9.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-DL-LAST-DATE        PIC X(10).
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-DL-TOTAL-SPENT      PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-AVG-DEAL         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-REPEAT-FLAG      PIC X(01).
           05  FILLER                  PIC X(26) VALUE SPACES.
      *
       01  WS-SUBTOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '-'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'DEALER SUBTOTALS: '.
           05  WS-ST-CUST-COUNT        PIC Z(4)9.
           05  FILLER                  PIC X(12) VALUE ' CUSTOMERS '.
           05  WS-ST-TOTAL-REVENUE     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-ST-REPEAT-COUNT      PIC Z(4)9.
           05  FILLER                  PIC X(09) VALUE ' REPEAT  '.
           05  FILLER                  PIC X(22) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'GRAND TOTALS:     '.
           05  WS-GT-CUST-COUNT        PIC Z(4)9.
           05  FILLER                  PIC X(12) VALUE ' CUSTOMERS '.
           05  WS-GT-TOTAL-REVENUE     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(37) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(44) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'REPEAT BUYERS:    '.
           05  WS-GT-REPEAT-COUNT      PIC Z(4)9.
           05  FILLER                  PIC X(05) VALUE '  OF '.
           05  WS-GT-REPEAT-TOTAL      PIC Z(4)9.
           05  FILLER                  PIC X(03) VALUE ' = '.
           05  WS-GT-REPEAT-PCT        PIC ZZ9.99.
           05  FILLER                  PIC X(01) VALUE '%'.
           05  FILLER                  PIC X(38) VALUE SPACES.
      *
       01  WS-GRAND-AVG-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(44) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'AVG PER CUSTOMER: '.
           05  FILLER                  PIC X(13) VALUE SPACES.
           05  WS-GA-AVG-REVENUE       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(41) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS
      *
       01  WS-DEALER-ACCUM.
           05  WS-DA-CUST-COUNT        PIC S9(06) COMP VALUE +0.
           05  WS-DA-TOTAL-REVENUE     PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-REPEAT-COUNT      PIC S9(06) COMP VALUE +0.
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-CUST-COUNT        PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-REVENUE     PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-REPEAT-COUNT      PIC S9(08) COMP VALUE +0.
           05  WS-GA-DEALER-COUNT      PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - CUSTOMER ACTIVITY CURSOR
      *
       01  WS-HV-CUST.
           05  WS-HV-CUST-ID          PIC S9(09) COMP.
           05  WS-HV-CUST-LAST        PIC X(30).
           05  WS-HV-CUST-FIRST       PIC X(30).
           05  WS-HV-PURCHASE-COUNT   PIC S9(06) COMP.
           05  WS-HV-LAST-DATE        PIC X(10).
           05  WS-HV-TOTAL-SPENT      PIC S9(11)V99 COMP-3.
           05  WS-HV-AVG-DEAL         PIC S9(09)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CUST-FULL-NAME      PIC X(28) VALUE SPACES.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-REPEAT-PCT-WORK     PIC S9(05)V99 COMP-3
                                                     VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_CUS_DLRS CURSOR FOR
               SELECT DISTINCT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   D.DEALER_CODE = C.DEALER_CODE
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   C.CUSTOMER_ID = S.CUSTOMER_ID
               WHERE  S.DEAL_STATUS = 'DL'
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_CUS_ACTIVITY CURSOR FOR
               SELECT C.CUSTOMER_ID
                    , C.LAST_NAME
                    , C.FIRST_NAME
                    , COUNT(*)
                    , MAX(CHAR(S.DELIVERY_DATE, ISO))
                    , SUM(S.TOTAL_PRICE)
                    , AVG(S.TOTAL_PRICE)
               FROM   AUTOSALE.CUSTOMER C
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   C.CUSTOMER_ID = S.CUSTOMER_ID
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
               GROUP BY C.CUSTOMER_ID
                      , C.LAST_NAME
                      , C.FIRST_NAME
               ORDER BY C.LAST_NAME
                      , C.FIRST_NAME
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTCUS00: CUSTOMER ACTIVITY REPORT - START'
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
           DISPLAY 'RPTCUS00: REPORT COMPLETE - '
                   WS-GA-CUST-COUNT ' CUSTOMERS, '
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
           DISPLAY 'RPTCUS00: REPORT DATE = ' WS-REPORT-DATE
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
               DISPLAY 'RPTCUS00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_CUS_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTCUS00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_CUS_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-PROCESS-CUSTOMERS
                       PERFORM 6000-PRINT-DEALER-SUBTOTAL
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTCUS00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_CUS_DLRS END-EXEC
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
      *    5000-PROCESS-CUSTOMERS - DETAIL FOR EACH CUSTOMER         *
      ****************************************************************
       5000-PROCESS-CUSTOMERS.
      *
           EXEC SQL OPEN CSR_CUS_ACTIVITY END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTCUS00: ERROR OPENING CUST CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-CUST
      *
           PERFORM UNTIL WS-CUSTS-DONE
               EXEC SQL FETCH CSR_CUS_ACTIVITY
                   INTO :WS-HV-CUST-ID
                      , :WS-HV-CUST-LAST
                      , :WS-HV-CUST-FIRST
                      , :WS-HV-PURCHASE-COUNT
                      , :WS-HV-LAST-DATE
                      , :WS-HV-TOTAL-SPENT
                      , :WS-HV-AVG-DEAL
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-CUSTS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTCUS00: DB2 ERROR ON CUST - '
                               SQLCODE
                       SET WS-CUSTS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_CUS_ACTIVITY END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FORMAT-DETAIL - FORMAT AND PRINT ONE CUSTOMER LINE   *
      ****************************************************************
       5100-FORMAT-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 4000-NEW-DEALER-PAGE
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
      *
           MOVE WS-HV-CUST-ID TO WS-DL-CUST-ID
      *
           INITIALIZE WS-CUST-FULL-NAME
           STRING WS-HV-CUST-LAST DELIMITED BY '  '
                  ', ' DELIMITED BY SIZE
                  WS-HV-CUST-FIRST DELIMITED BY '  '
                  INTO WS-CUST-FULL-NAME
           MOVE WS-CUST-FULL-NAME TO WS-DL-CUST-NAME
      *
           MOVE WS-HV-PURCHASE-COUNT TO WS-DL-PURCHASES
           MOVE WS-HV-LAST-DATE      TO WS-DL-LAST-DATE
           MOVE WS-HV-TOTAL-SPENT    TO WS-DL-TOTAL-SPENT
           MOVE WS-HV-AVG-DEAL       TO WS-DL-AVG-DEAL
      *
           IF WS-HV-PURCHASE-COUNT > 1
               MOVE '*' TO WS-DL-REPEAT-FLAG
               ADD +1 TO WS-DA-REPEAT-COUNT
               ADD +1 TO WS-GA-REPEAT-COUNT
           ELSE
               MOVE ' ' TO WS-DL-REPEAT-FLAG
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
      *    ACCUMULATE
      *
           ADD +1 TO WS-DA-CUST-COUNT
           ADD WS-HV-TOTAL-SPENT TO WS-DA-TOTAL-REVENUE
      *
           ADD +1 TO WS-GA-CUST-COUNT
           ADD WS-HV-TOTAL-SPENT TO WS-GA-TOTAL-REVENUE
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-SUBTOTAL                                *
      ****************************************************************
       6000-PRINT-DEALER-SUBTOTAL.
      *
           MOVE WS-DA-CUST-COUNT     TO WS-ST-CUST-COUNT
           MOVE WS-DA-TOTAL-REVENUE  TO WS-ST-TOTAL-REVENUE
           MOVE WS-DA-REPEAT-COUNT   TO WS-ST-REPEAT-COUNT
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
           MOVE WS-GA-CUST-COUNT     TO WS-GT-CUST-COUNT
           MOVE WS-GA-TOTAL-REVENUE  TO WS-GT-TOTAL-REVENUE
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE-1
               AFTER ADVANCING 3
      *
      *    REPEAT BUYER PERCENTAGE
      *
           MOVE WS-GA-REPEAT-COUNT   TO WS-GT-REPEAT-COUNT
           MOVE WS-GA-CUST-COUNT     TO WS-GT-REPEAT-TOTAL
      *
           IF WS-GA-CUST-COUNT > +0
               COMPUTE WS-REPEAT-PCT-WORK =
                   (WS-GA-REPEAT-COUNT / WS-GA-CUST-COUNT) * 100
               MOVE WS-REPEAT-PCT-WORK TO WS-GT-REPEAT-PCT
           ELSE
               MOVE +0 TO WS-GT-REPEAT-PCT
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE-2
               AFTER ADVANCING 1
      *
      *    AVERAGE PER CUSTOMER
      *
           IF WS-GA-CUST-COUNT > +0
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-REVENUE / WS-GA-CUST-COUNT
               MOVE WS-AVG-WORK TO WS-GA-AVG-REVENUE
           ELSE
               MOVE +0 TO WS-GA-AVG-REVENUE
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
               DISPLAY 'RPTCUS00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTCUS00                                              *
      ****************************************************************
