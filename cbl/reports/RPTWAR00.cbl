       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTWAR00.
      ****************************************************************
      * PROGRAM:    RPTWAR00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    WARRANTY CLAIMS AGING REPORT. SHOWS OUTSTANDING  *
      *             WARRANTY CLAIMS BY AGE BUCKET (0-30, 31-60,      *
      *             61-90, 90+ DAYS) PER DEALER. DETAIL LINE FOR     *
      *             EACH OPEN CLAIM WITH CLAIM#, VIN, TYPE, DATE,    *
      *             AGE IN DAYS, AMOUNT, AND STATUS. SUBTOTALS PER   *
      *             DEALER PER AGE BUCKET AND GRAND TOTALS WITH      *
      *             AGING SUMMARY.                                   *
      *                                                              *
      * INPUT:      REPORT DATE PARAMETER (DEFAULT CURRENT DATE)     *
      *                                                              *
      * TABLES:     AUTOSALE.WARRANTY_CLAIM (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTWAR00'.
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
           05  WS-EOF-CLAIM            PIC X(01) VALUE 'N'.
               88  WS-CLAIMS-DONE                VALUE 'Y'.
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
               VALUE ' WARRANTY CLAIMS AGING REPORT '.
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
           05  FILLER                  PIC X(10) VALUE 'CLAIM #  '.
           05  FILLER                  PIC X(19) VALUE
               'VIN               '.
           05  FILLER                  PIC X(06) VALUE 'TYPE  '.
           05  FILLER                  PIC X(12) VALUE
               'CLAIM DATE  '.
           05  FILLER                  PIC X(06) VALUE 'AGE   '.
           05  FILLER                  PIC X(16) VALUE
               '  CLAIM AMOUNT  '.
           05  FILLER                  PIC X(10) VALUE
               'STATUS    '.
           05  FILLER                  PIC X(12) VALUE
               'AGE BUCKET  '.
           05  FILLER                  PIC X(40) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE '-------- '.
           05  FILLER                  PIC X(19) VALUE
               '----------------- '.
           05  FILLER                  PIC X(06) VALUE '---- '.
           05  FILLER                  PIC X(12) VALUE
               '---------- '.
           05  FILLER                  PIC X(06) VALUE '----- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(10) VALUE
               '--------- '.
           05  FILLER                  PIC X(12) VALUE
               '----------- '.
           05  FILLER                  PIC X(40) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-CLAIM-NUM        PIC X(08).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-VIN              PIC X(17).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-TYPE             PIC X(04).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-CLAIM-DATE       PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-AGE-DAYS         PIC Z(3)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-CLAIM-AMT        PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-STATUS           PIC X(09).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-AGE-BUCKET       PIC X(11).
           05  FILLER                  PIC X(29) VALUE SPACES.
      *
       01  WS-SUBTOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40) VALUE ALL '-'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(21)
               VALUE 'DEALER AGING SUMMARY:'.
           05  FILLER                  PIC X(69) VALUE SPACES.
      *
       01  WS-BUCKET-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-BL-BUCKET-NAME      PIC X(12).
           05  FILLER                  PIC X(09) VALUE ' CLAIMS: '.
           05  WS-BL-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(11) VALUE '   AMOUNT: '.
           05  WS-BL-AMOUNT           PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(73) VALUE SPACES.
      *
       01  WS-DEALER-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(12)
               VALUE 'ALL CLAIMS  '.
           05  FILLER                  PIC X(09) VALUE ' CLAIMS: '.
           05  WS-DTL-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(11) VALUE '   AMOUNT: '.
           05  WS-DTL-AMOUNT           PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(73) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'GRAND TOTALS:   '.
           05  WS-GT-CLAIM-COUNT       PIC Z(5)9.
           05  FILLER                  PIC X(09) VALUE ' CLAIMS  '.
           05  WS-GT-TOTAL-AMT         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(40) VALUE SPACES.
      *
       01  WS-GRAND-BUCKET-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-GB-BUCKET-NAME      PIC X(12).
           05  FILLER                  PIC X(09) VALUE ' CLAIMS: '.
           05  WS-GB-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(04) VALUE '  ( '.
           05  WS-GB-PCT              PIC ZZ9.9.
           05  FILLER                  PIC X(09) VALUE '%)  AMT: '.
           05  WS-GB-AMOUNT           PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(50) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS - PER DEALER
      *
       01  WS-DEALER-ACCUM.
           05  WS-DA-TOTAL-COUNT       PIC S9(06) COMP VALUE +0.
           05  WS-DA-TOTAL-AMT         PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-BUCKET-COUNTS.
               10  WS-DA-B1-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B2-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B3-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B4-COUNT      PIC S9(06) COMP VALUE +0.
           05  WS-DA-BUCKET-AMTS.
               10  WS-DA-B1-AMT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B2-AMT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B3-AMT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B4-AMT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
      *    GRAND ACCUMULATORS
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-TOTAL-COUNT       PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-AMT         PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-BUCKET-COUNTS.
               10  WS-GA-B1-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B2-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B3-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B4-COUNT      PIC S9(08) COMP VALUE +0.
           05  WS-GA-BUCKET-AMTS.
               10  WS-GA-B1-AMT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B2-AMT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B3-AMT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B4-AMT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-DEALER-COUNT      PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - CLAIM CURSOR
      *
       01  WS-HV-CLAIM.
           05  WS-HV-CLAIM-NUMBER     PIC X(08).
           05  WS-HV-VIN              PIC X(17).
           05  WS-HV-CLAIM-TYPE       PIC X(02).
           05  WS-HV-CLAIM-DATE       PIC X(10).
           05  WS-HV-AGE-DAYS         PIC S9(06) COMP.
           05  WS-HV-TOTAL-CLAIM      PIC S9(09)V99 COMP-3.
           05  WS-HV-CLAIM-STATUS     PIC X(02).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-TYPE-DESC           PIC X(04) VALUE SPACES.
           05  WS-STATUS-DESC         PIC X(09) VALUE SPACES.
           05  WS-BUCKET-DESC         PIC X(11) VALUE SPACES.
           05  WS-PCT-WORK            PIC S9(05)V9 COMP-3
                                                    VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_WAR_DLRS CURSOR FOR
               SELECT DISTINCT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               INNER JOIN AUTOSALE.WARRANTY_CLAIM WC
                 ON   D.DEALER_CODE = WC.DEALER_CODE
               WHERE  WC.CLAIM_STATUS NOT IN ('PD', 'DN', 'CL')
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_WAR_CLAIMS CURSOR FOR
               SELECT WC.CLAIM_NUMBER
                    , WC.VIN
                    , WC.CLAIM_TYPE
                    , CHAR(WC.CLAIM_DATE, ISO)
                    , DAYS(DATE(:WS-REPORT-DATE))
                    - DAYS(WC.CLAIM_DATE)
                    , WC.TOTAL_CLAIM
                    , WC.CLAIM_STATUS
               FROM   AUTOSALE.WARRANTY_CLAIM WC
               WHERE  WC.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  WC.CLAIM_STATUS NOT IN ('PD', 'DN', 'CL')
               ORDER BY WC.CLAIM_DATE, WC.CLAIM_NUMBER
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTWAR00: WARRANTY CLAIMS AGING REPORT - START'
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
           DISPLAY 'RPTWAR00: REPORT COMPLETE - '
                   WS-GA-TOTAL-COUNT ' CLAIMS, '
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
           DISPLAY 'RPTWAR00: REPORT DATE = ' WS-REPORT-DATE
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
               DISPLAY 'RPTWAR00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_WAR_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTWAR00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_WAR_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-PROCESS-CLAIMS
                       PERFORM 6000-PRINT-DEALER-SUBTOTAL
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTWAR00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_WAR_DLRS END-EXEC
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
      *    5000-PROCESS-CLAIMS - DETAIL LINES FOR EACH CLAIM         *
      ****************************************************************
       5000-PROCESS-CLAIMS.
      *
           EXEC SQL OPEN CSR_WAR_CLAIMS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTWAR00: ERROR OPENING CLAIM CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-CLAIM
      *
           PERFORM UNTIL WS-CLAIMS-DONE
               EXEC SQL FETCH CSR_WAR_CLAIMS
                   INTO :WS-HV-CLAIM-NUMBER
                      , :WS-HV-VIN
                      , :WS-HV-CLAIM-TYPE
                      , :WS-HV-CLAIM-DATE
                      , :WS-HV-AGE-DAYS
                      , :WS-HV-TOTAL-CLAIM
                      , :WS-HV-CLAIM-STATUS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-CLAIMS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTWAR00: DB2 ERROR ON CLAIM - '
                               SQLCODE
                       SET WS-CLAIMS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_WAR_CLAIMS END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FORMAT-DETAIL - FORMAT AND PRINT ONE CLAIM LINE      *
      ****************************************************************
       5100-FORMAT-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 4000-NEW-DEALER-PAGE
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
      *
           MOVE WS-HV-CLAIM-NUMBER TO WS-DL-CLAIM-NUM
           MOVE WS-HV-VIN          TO WS-DL-VIN
      *
           EVALUATE WS-HV-CLAIM-TYPE
               WHEN 'BT'
                   MOVE 'B2B ' TO WS-DL-TYPE
               WHEN 'PT'
                   MOVE 'PWRT' TO WS-DL-TYPE
               WHEN 'CR'
                   MOVE 'CORR' TO WS-DL-TYPE
               WHEN 'EM'
                   MOVE 'EMIS' TO WS-DL-TYPE
               WHEN OTHER
                   MOVE WS-HV-CLAIM-TYPE TO WS-DL-TYPE
           END-EVALUATE
      *
           MOVE WS-HV-CLAIM-DATE TO WS-DL-CLAIM-DATE
           MOVE WS-HV-AGE-DAYS   TO WS-DL-AGE-DAYS
           MOVE WS-HV-TOTAL-CLAIM TO WS-DL-CLAIM-AMT
      *
           EVALUATE WS-HV-CLAIM-STATUS
               WHEN 'NW'
                   MOVE 'NEW      ' TO WS-DL-STATUS
               WHEN 'SB'
                   MOVE 'SUBMITTED' TO WS-DL-STATUS
               WHEN 'AP'
                   MOVE 'APPROVED ' TO WS-DL-STATUS
               WHEN 'PA'
                   MOVE 'PARTIAL  ' TO WS-DL-STATUS
               WHEN 'RV'
                   MOVE 'IN REVIEW' TO WS-DL-STATUS
               WHEN OTHER
                   MOVE WS-HV-CLAIM-STATUS TO WS-DL-STATUS
           END-EVALUATE
      *
      *    DETERMINE AGE BUCKET
      *
           EVALUATE TRUE
               WHEN WS-HV-AGE-DAYS <= 30
                   MOVE '0-30 DAYS  ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B1-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-DA-B1-AMT
                   ADD +1 TO WS-GA-B1-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-GA-B1-AMT
               WHEN WS-HV-AGE-DAYS <= 60
                   MOVE '31-60 DAYS ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B2-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-DA-B2-AMT
                   ADD +1 TO WS-GA-B2-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-GA-B2-AMT
               WHEN WS-HV-AGE-DAYS <= 90
                   MOVE '61-90 DAYS ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B3-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-DA-B3-AMT
                   ADD +1 TO WS-GA-B3-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-GA-B3-AMT
               WHEN OTHER
                   MOVE '90+ DAYS   ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B4-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-DA-B4-AMT
                   ADD +1 TO WS-GA-B4-COUNT
                   ADD WS-HV-TOTAL-CLAIM TO WS-GA-B4-AMT
           END-EVALUATE
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
           ADD +1 TO WS-DA-TOTAL-COUNT
           ADD WS-HV-TOTAL-CLAIM TO WS-DA-TOTAL-AMT
      *
           ADD +1 TO WS-GA-TOTAL-COUNT
           ADD WS-HV-TOTAL-CLAIM TO WS-GA-TOTAL-AMT
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-SUBTOTAL                                *
      ****************************************************************
       6000-PRINT-DEALER-SUBTOTAL.
      *
           WRITE REPORT-RECORD FROM WS-SUBTOTAL-LINE
               AFTER ADVANCING 2
      *
      *    PRINT EACH AGE BUCKET
      *
           MOVE '0-30 DAYS   ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B1-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B1-AMT    TO WS-BL-AMOUNT
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '31-60 DAYS  ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B2-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B2-AMT    TO WS-BL-AMOUNT
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '61-90 DAYS  ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B3-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B3-AMT    TO WS-BL-AMOUNT
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '90+ DAYS    ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B4-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B4-AMT    TO WS-BL-AMOUNT
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
      *    DEALER TOTAL
      *
           MOVE WS-DA-TOTAL-COUNT TO WS-DTL-COUNT
           MOVE WS-DA-TOTAL-AMT   TO WS-DTL-AMOUNT
           WRITE REPORT-RECORD FROM WS-DEALER-TOTAL-LINE
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-TOTAL-COUNT TO WS-GT-CLAIM-COUNT
           MOVE WS-GA-TOTAL-AMT   TO WS-GT-TOTAL-AMT
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
      *
      *    GRAND AGING SUMMARY WITH PERCENTAGES
      *
           MOVE '0-30 DAYS   ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B1-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B1-AMT    TO WS-GB-AMOUNT
           IF WS-GA-TOTAL-COUNT > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B1-COUNT * 100) / WS-GA-TOTAL-COUNT
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '31-60 DAYS  ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B2-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B2-AMT    TO WS-GB-AMOUNT
           IF WS-GA-TOTAL-COUNT > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B2-COUNT * 100) / WS-GA-TOTAL-COUNT
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '61-90 DAYS  ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B3-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B3-AMT    TO WS-GB-AMOUNT
           IF WS-GA-TOTAL-COUNT > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B3-COUNT * 100) / WS-GA-TOTAL-COUNT
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '90+ DAYS    ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B4-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B4-AMT    TO WS-GB-AMOUNT
           IF WS-GA-TOTAL-COUNT > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B4-COUNT * 100) / WS-GA-TOTAL-COUNT
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
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
               DISPLAY 'RPTWAR00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTWAR00                                              *
      ****************************************************************
