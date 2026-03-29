       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTINV00.
      ****************************************************************
      * PROGRAM:    RPTINV00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    INVENTORY STATUS REPORT. AGING BUCKETS: 0-30,    *
      *             31-60, 61-90, 91-120, 120+ DAYS. PER BUCKET:     *
      *             COUNT, TOTAL INVOICE VALUE, AVG DAYS. SUMMARY    *
      *             BY BODY STYLE AND BY MODEL. HIGHLIGHTS AGED      *
      *             STOCK (90+ DAYS WITH ASTERISK FLAG).             *
      *                                                              *
      * INPUT:      DEALER CODE (OPTIONAL, ALL IF BLANK)             *
      *                                                              *
      * TABLES:     AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
      *             AUTOSALE.PRICE_MASTER   (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTINV00'.
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
      *    INPUT PARAMETER
      *
       01  WS-PARM-DEALER-CODE        PIC X(05) VALUE SPACES.
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY            PIC 9(04).
           05  WS-CURR-MM              PIC 9(02).
           05  WS-CURR-DD              PIC 9(02).
           05  FILLER                  PIC X(13).
       01  WS-CURR-DATE-FMT            PIC X(10) VALUE SPACES.
      *
      *    HOST VARIABLES
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
       01  WS-HV-BUCKET-DATA.
           05  WS-HV-BUCKET-ID        PIC S9(04) COMP.
           05  WS-HV-BKT-COUNT        PIC S9(06) COMP.
           05  WS-HV-BKT-INVOICE      PIC S9(11)V99 COMP-3.
           05  WS-HV-BKT-AVG-DAYS     PIC S9(05) COMP.
      *
       01  WS-HV-BODY-DATA.
           05  WS-HV-BODY-STYLE       PIC X(10).
           05  WS-HV-BD-COUNT         PIC S9(06) COMP.
           05  WS-HV-BD-INVOICE       PIC S9(11)V99 COMP-3.
           05  WS-HV-BD-AVG-DAYS      PIC S9(05) COMP.
      *
       01  WS-HV-MODEL-DATA.
           05  WS-HV-MDL-CODE         PIC X(06).
           05  WS-HV-MDL-DESC         PIC X(25).
           05  WS-HV-MD-COUNT         PIC S9(06) COMP.
           05  WS-HV-MD-INVOICE       PIC S9(11)V99 COMP-3.
           05  WS-HV-MD-AVG-DAYS      PIC S9(05) COMP.
      *
      *    AGING BUCKET NAMES
      *
       01  WS-BUCKET-NAMES.
           05  FILLER PIC X(12) VALUE '0-30 DAYS   '.
           05  FILLER PIC X(12) VALUE '31-60 DAYS  '.
           05  FILLER PIC X(12) VALUE '61-90 DAYS  '.
           05  FILLER PIC X(12) VALUE '91-120 DAYS '.
           05  FILLER PIC X(12) VALUE '120+ DAYS   '.
       01  WS-BUCKET-NAME-TBL REDEFINES WS-BUCKET-NAMES.
           05  WS-BKT-NM OCCURS 5 TIMES PIC X(12).
      *
      *    GRAND ACCUMULATORS (PER BUCKET)
      *
       01  WS-GRAND-BUCKETS.
           05  WS-GB-ENTRY OCCURS 5 TIMES.
               10  WS-GB-COUNT        PIC S9(08) COMP VALUE +0.
               10  WS-GB-INVOICE      PIC S9(13)V99 COMP-3
                                                     VALUE +0.
               10  WS-GB-DAYS-SUM     PIC S9(11) COMP VALUE +0.
       01  WS-GRAND-TOTAL-UNITS        PIC S9(08) COMP VALUE +0.
       01  WS-GRAND-TOTAL-INVOICE      PIC S9(13)V99 COMP-3
                                                      VALUE +0.
      *
      *    REPORT LINES
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE '   INVENTORY STATUS REPORT    '.
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
           05  WS-DH-DLR-CODE         PIC X(05).
           05  FILLER                  PIC X(03) VALUE ' - '.
           05  WS-DH-DLR-NAME         PIC X(40).
           05  FILLER                  PIC X(74) VALUE SPACES.
      *
       01  WS-SECTION-TITLE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-STIT-TEXT            PIC X(50).
           05  FILLER                  PIC X(81) VALUE SPACES.
      *
       01  WS-BUCKET-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(14) VALUE
               'AGING BUCKET  '.
           05  FILLER                  PIC X(10) VALUE
               '   COUNT  '.
           05  FILLER                  PIC X(20) VALUE
               '   TOTAL INVOICE    '.
           05  FILLER                  PIC X(12) VALUE
               '  AVG DAYS  '.
           05  FILLER                  PIC X(05) VALUE 'FLAG '.
           05  FILLER                  PIC X(66) VALUE SPACES.
      *
       01  WS-BUCKET-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-BD-NAME             PIC X(12).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-BD-COUNT            PIC Z(5)9.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-BD-INVOICE          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-BD-AVG-DAYS         PIC Z(4)9.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-BD-FLAG             PIC X(03).
           05  FILLER                  PIC X(63) VALUE SPACES.
      *
       01  WS-BODY-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE
               'BODY STYLE  '.
           05  FILLER                  PIC X(10) VALUE
               '   COUNT  '.
           05  FILLER                  PIC X(20) VALUE
               '   TOTAL INVOICE    '.
           05  FILLER                  PIC X(12) VALUE
               '  AVG DAYS  '.
           05  FILLER                  PIC X(73) VALUE SPACES.
      *
       01  WS-BODY-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-BYD-STYLE           PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-BYD-COUNT           PIC Z(5)9.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-BYD-INVOICE         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-BYD-AVG-DAYS        PIC Z(4)9.
           05  FILLER                  PIC X(66) VALUE SPACES.
      *
       01  WS-MODEL-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(07) VALUE 'MODEL  '.
           05  FILLER                  PIC X(26) VALUE
               'DESCRIPTION               '.
           05  FILLER                  PIC X(10) VALUE
               '   COUNT  '.
           05  FILLER                  PIC X(20) VALUE
               '   TOTAL INVOICE    '.
           05  FILLER                  PIC X(12) VALUE
               '  AVG DAYS  '.
           05  FILLER                  PIC X(52) VALUE SPACES.
      *
       01  WS-MODEL-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-MDD-CODE            PIC X(06).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-MDD-DESC            PIC X(25).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-MDD-COUNT           PIC Z(5)9.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-MDD-INVOICE         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  WS-MDD-AVG-DAYS        PIC Z(4)9.
           05  FILLER                  PIC X(42) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18) VALUE ALL '='.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'GRAND TOTALS:   '.
           05  WS-GT-UNITS            PIC Z(6)9.
           05  FILLER                  PIC X(10)
               VALUE ' UNITS    '.
           05  WS-GT-INVOICE          PIC $$$$$,$$$,$$9.99.
           05  FILLER                  PIC X(12)
               VALUE '  INVOICE   '.
           05  FILLER                  PIC X(48) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-IDX                  PIC S9(04) COMP VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_INV_DLRS CURSOR FOR
               SELECT DEALER_CODE
                    , DEALER_NAME
               FROM   AUTOSALE.DEALER
               WHERE  ACTIVE_FLAG = 'Y'
                 AND  (DEALER_CODE = :WS-PARM-DEALER-CODE
                  OR   :WS-PARM-DEALER-CODE = '     ')
               ORDER BY DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_INV_BUCKETS CURSOR FOR
               SELECT CASE
                        WHEN V.DAYS_IN_STOCK <= 30  THEN 1
                        WHEN V.DAYS_IN_STOCK <= 60  THEN 2
                        WHEN V.DAYS_IN_STOCK <= 90  THEN 3
                        WHEN V.DAYS_IN_STOCK <= 120 THEN 4
                        ELSE 5
                      END AS BUCKET_ID
                    , COUNT(*)
                    , SUM(V.INVOICE_PRICE)
                    , AVG(V.DAYS_IN_STOCK)
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  V.VEHICLE_STATUS IN ('AV','HD','DM','AL')
               GROUP BY CASE
                        WHEN V.DAYS_IN_STOCK <= 30  THEN 1
                        WHEN V.DAYS_IN_STOCK <= 60  THEN 2
                        WHEN V.DAYS_IN_STOCK <= 90  THEN 3
                        WHEN V.DAYS_IN_STOCK <= 120 THEN 4
                        ELSE 5
                      END
               ORDER BY 1
           END-EXEC
      *
           EXEC SQL DECLARE CSR_INV_BODY CURSOR FOR
               SELECT V.BODY_STYLE
                    , COUNT(*)
                    , SUM(V.INVOICE_PRICE)
                    , AVG(V.DAYS_IN_STOCK)
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  V.VEHICLE_STATUS IN ('AV','HD','DM','AL')
               GROUP BY V.BODY_STYLE
               ORDER BY COUNT(*) DESC
           END-EXEC
      *
           EXEC SQL DECLARE CSR_INV_MODEL CURSOR FOR
               SELECT V.MODEL_CODE
                    , V.MODEL_DESC
                    , COUNT(*)
                    , SUM(V.INVOICE_PRICE)
                    , AVG(V.DAYS_IN_STOCK)
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  V.VEHICLE_STATUS IN ('AV','HD','DM','AL')
               GROUP BY V.MODEL_CODE, V.MODEL_DESC
               ORDER BY V.MODEL_CODE
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTINV00: INVENTORY STATUS REPORT - START'
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
           DISPLAY 'RPTINV00: REPORT COMPLETE - '
                   WS-GRAND-TOTAL-UNITS ' UNITS ACROSS '
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
           STRING WS-CURR-YYYY '-' WS-CURR-MM '-' WS-CURR-DD
                  DELIMITED BY SIZE INTO WS-CURR-DATE-FMT
      *
           INITIALIZE WS-GRAND-BUCKETS
           MOVE +0 TO WS-GRAND-TOTAL-UNITS
           MOVE +0 TO WS-GRAND-TOTAL-INVOICE
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTINV00: ERROR OPENING REPORT FILE'
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_INV_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTINV00: ERROR OPENING DEALER CURSOR'
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_INV_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               IF SQLCODE = +0
                   PERFORM 4000-PROCESS-DEALER-INV
               ELSE
                   SET WS-DEALERS-DONE TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_INV_DLRS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PROCESS-DEALER-INV                                   *
      ****************************************************************
       4000-PROCESS-DEALER-INV.
      *
           PERFORM 8000-NEW-PAGE
      *
           MOVE WS-HV-DLR-CODE TO WS-DH-DLR-CODE
           MOVE WS-HV-DLR-NAME TO WS-DH-DLR-NAME
           WRITE REPORT-RECORD FROM WS-DEALER-HEADER
               AFTER ADVANCING 2
      *
      *    AGING BUCKETS SECTION
      *
           MOVE 'AGING BUCKET SUMMARY' TO WS-STIT-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-BUCKET-COL-HDR
               AFTER ADVANCING 2
           ADD 10 TO WS-LINE-COUNT
      *
           PERFORM 4100-PRINT-BUCKETS
      *
      *    BODY STYLE SECTION
      *
           MOVE 'SUMMARY BY BODY STYLE' TO WS-STIT-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 3
           WRITE REPORT-RECORD FROM WS-BODY-COL-HDR
               AFTER ADVANCING 2
           ADD 5 TO WS-LINE-COUNT
      *
           PERFORM 4200-PRINT-BODY-STYLES
      *
      *    MODEL SECTION
      *
           IF WS-LINE-COUNT >= 40
               PERFORM 8000-NEW-PAGE
           END-IF
      *
           MOVE 'SUMMARY BY MODEL' TO WS-STIT-TEXT
           WRITE REPORT-RECORD FROM WS-SECTION-TITLE
               AFTER ADVANCING 3
           WRITE REPORT-RECORD FROM WS-MODEL-COL-HDR
               AFTER ADVANCING 2
           ADD 5 TO WS-LINE-COUNT
      *
           PERFORM 4300-PRINT-MODELS
           .
      *
      ****************************************************************
      *    4100-PRINT-BUCKETS                                        *
      ****************************************************************
       4100-PRINT-BUCKETS.
      *
           EXEC SQL OPEN CSR_INV_BUCKETS END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4100-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_INV_BUCKETS
                   INTO :WS-HV-BUCKET-ID
                      , :WS-HV-BKT-COUNT
                      , :WS-HV-BKT-INVOICE
                      , :WS-HV-BKT-AVG-DAYS
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE WS-BKT-NM(WS-HV-BUCKET-ID)
                       TO WS-BD-NAME
                   MOVE WS-HV-BKT-COUNT   TO WS-BD-COUNT
                   MOVE WS-HV-BKT-INVOICE TO WS-BD-INVOICE
                   MOVE WS-HV-BKT-AVG-DAYS TO WS-BD-AVG-DAYS
      *
                   IF WS-HV-BUCKET-ID >= 4
                       MOVE '***' TO WS-BD-FLAG
                   ELSE
                       MOVE SPACES TO WS-BD-FLAG
                   END-IF
      *
                   WRITE REPORT-RECORD FROM WS-BUCKET-DETAIL
                       AFTER ADVANCING 1
                   ADD +1 TO WS-LINE-COUNT
      *
      *            ACCUMULATE GRAND TOTALS
      *
                   ADD WS-HV-BKT-COUNT
                       TO WS-GB-COUNT(WS-HV-BUCKET-ID)
                   ADD WS-HV-BKT-INVOICE
                       TO WS-GB-INVOICE(WS-HV-BUCKET-ID)
                   ADD WS-HV-BKT-COUNT
                       TO WS-GRAND-TOTAL-UNITS
                   ADD WS-HV-BKT-INVOICE
                       TO WS-GRAND-TOTAL-INVOICE
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_INV_BUCKETS END-EXEC
           .
       4100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4200-PRINT-BODY-STYLES                                    *
      ****************************************************************
       4200-PRINT-BODY-STYLES.
      *
           EXEC SQL OPEN CSR_INV_BODY END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4200-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_INV_BODY
                   INTO :WS-HV-BODY-STYLE
                      , :WS-HV-BD-COUNT
                      , :WS-HV-BD-INVOICE
                      , :WS-HV-BD-AVG-DAYS
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE WS-HV-BODY-STYLE  TO WS-BYD-STYLE
                   MOVE WS-HV-BD-COUNT    TO WS-BYD-COUNT
                   MOVE WS-HV-BD-INVOICE  TO WS-BYD-INVOICE
                   MOVE WS-HV-BD-AVG-DAYS TO WS-BYD-AVG-DAYS
      *
                   WRITE REPORT-RECORD FROM WS-BODY-DETAIL
                       AFTER ADVANCING 1
                   ADD +1 TO WS-LINE-COUNT
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_INV_BODY END-EXEC
           .
       4200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4300-PRINT-MODELS                                         *
      ****************************************************************
       4300-PRINT-MODELS.
      *
           EXEC SQL OPEN CSR_INV_MODEL END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4300-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_INV_MODEL
                   INTO :WS-HV-MDL-CODE
                      , :WS-HV-MDL-DESC
                      , :WS-HV-MD-COUNT
                      , :WS-HV-MD-INVOICE
                      , :WS-HV-MD-AVG-DAYS
               END-EXEC
      *
               IF SQLCODE = +0
                   IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
                       PERFORM 8000-NEW-PAGE
                   END-IF
      *
                   MOVE WS-HV-MDL-CODE    TO WS-MDD-CODE
                   MOVE WS-HV-MDL-DESC    TO WS-MDD-DESC
                   MOVE WS-HV-MD-COUNT    TO WS-MDD-COUNT
                   MOVE WS-HV-MD-INVOICE  TO WS-MDD-INVOICE
                   MOVE WS-HV-MD-AVG-DAYS TO WS-MDD-AVG-DAYS
      *
                   WRITE REPORT-RECORD FROM WS-MODEL-DETAIL
                       AFTER ADVANCING 1
                   ADD +1 TO WS-LINE-COUNT
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_INV_MODEL END-EXEC
           .
       4300-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GRAND-TOTAL-UNITS   TO WS-GT-UNITS
           MOVE WS-GRAND-TOTAL-INVOICE TO WS-GT-INVOICE
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
           .
      *
      ****************************************************************
      *    8000-NEW-PAGE                                             *
      ****************************************************************
       8000-NEW-PAGE.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT   TO WS-RH1-PAGE
           MOVE WS-CURR-DATE-FMT TO WS-RH1-DATE
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
               DISPLAY 'RPTINV00: ERROR CLOSING REPORT FILE'
           END-IF
           .
      ****************************************************************
      * END OF RPTINV00                                              *
      ****************************************************************
