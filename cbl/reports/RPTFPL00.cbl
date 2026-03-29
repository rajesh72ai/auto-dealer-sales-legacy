       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTFPL00.
      ****************************************************************
      * PROGRAM:    RPTFPL00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    FLOOR PLAN AGING REPORT. SHOWS DEALER FLOOR      *
      *             PLAN INVENTORY BY AGE BUCKET (0-30, 31-60,       *
      *             61-90, 91-120, 120+ DAYS). DETAIL LINE FOR       *
      *             EACH ACTIVE FLOOR PLAN VEHICLE WITH VIN, YEAR,   *
      *             MODEL, DAYS ON PLAN, INVOICE, AND ACCRUED        *
      *             INTEREST. SUBTOTALS PER DEALER BY AGE BUCKET     *
      *             AND GRAND TOTALS.                                *
      *                                                              *
      * INPUT:      REPORT DATE PARAMETER (DEFAULT CURRENT DATE)     *
      *                                                              *
      * TABLES:     AUTOSALE.FLOOR_PLAN_VEHICLE (READ)               *
      *             AUTOSALE.VEHICLE            (READ)               *
      *             AUTOSALE.MODEL_MASTER       (READ)               *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTFPL00'.
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
           05  WS-EOF-FP               PIC X(01) VALUE 'N'.
               88  WS-FP-DONE                    VALUE 'Y'.
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
               VALUE '  FLOOR PLAN AGING REPORT     '.
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
           05  FILLER                  PIC X(19) VALUE
               'VIN               '.
           05  FILLER                  PIC X(06) VALUE 'YEAR  '.
           05  FILLER                  PIC X(22) VALUE
               'MODEL                 '.
           05  FILLER                  PIC X(06) VALUE 'DAYS  '.
           05  FILLER                  PIC X(16) VALUE
               '  INVOICE AMT   '.
           05  FILLER                  PIC X(16) VALUE
               ' ACCRUED INTRS  '.
           05  FILLER                  PIC X(12) VALUE
               'AGE BUCKET  '.
           05  FILLER                  PIC X(34) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(19) VALUE
               '----------------- '.
           05  FILLER                  PIC X(06) VALUE '---- '.
           05  FILLER                  PIC X(22) VALUE
               '--------------------- '.
           05  FILLER                  PIC X(06) VALUE '----- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(12) VALUE
               '----------- '.
           05  FILLER                  PIC X(34) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-VIN              PIC X(17).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-YEAR             PIC 9(04).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-MODEL            PIC X(20).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-DAYS             PIC Z(3)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-INVOICE          PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-INTEREST         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-AGE-BUCKET       PIC X(11).
           05  FILLER                  PIC X(31) VALUE SPACES.
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
           05  FILLER                  PIC X(08) VALUE ' UNITS: '.
           05  WS-BL-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(12) VALUE '  INVOICED: '.
           05  WS-BL-INVOICE          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(12) VALUE '  INTEREST: '.
           05  WS-BL-INTEREST         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(39) VALUE SPACES.
      *
       01  WS-DEALER-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(12)
               VALUE 'ALL UNITS   '.
           05  FILLER                  PIC X(08) VALUE ' UNITS: '.
           05  WS-DTL-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(12) VALUE '  INVOICED: '.
           05  WS-DTL-INVOICE          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(12) VALUE '  INTEREST: '.
           05  WS-DTL-INTEREST         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(39) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'GRAND TOTALS:   '.
           05  WS-GT-UNIT-COUNT        PIC Z(5)9.
           05  FILLER                  PIC X(08) VALUE ' UNITS  '.
           05  WS-GT-INVOICE           PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-GT-INTEREST          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-GRAND-BUCKET-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-GB-BUCKET-NAME      PIC X(12).
           05  FILLER                  PIC X(08) VALUE ' UNITS: '.
           05  WS-GB-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(04) VALUE '  ( '.
           05  WS-GB-PCT              PIC ZZ9.9.
           05  FILLER                  PIC X(12) VALUE '%)  INVCE:  '.
           05  WS-GB-INVOICE          PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(12) VALUE '  INTEREST: '.
           05  WS-GB-INTEREST         PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(17) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS - PER DEALER (5 BUCKETS)
      *
       01  WS-DEALER-ACCUM.
           05  WS-DA-TOTAL-UNITS       PIC S9(06) COMP VALUE +0.
           05  WS-DA-TOTAL-INVOICE     PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-TOTAL-INTEREST    PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-BUCKET-COUNTS.
               10  WS-DA-B1-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B2-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B3-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B4-COUNT      PIC S9(06) COMP VALUE +0.
               10  WS-DA-B5-COUNT      PIC S9(06) COMP VALUE +0.
           05  WS-DA-BUCKET-INVOICE.
               10  WS-DA-B1-INV        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B2-INV        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B3-INV        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B4-INV        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B5-INV        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-BUCKET-INTEREST.
               10  WS-DA-B1-INT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B2-INT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B3-INT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B4-INT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DA-B5-INT        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
      *    GRAND ACCUMULATORS
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-TOTAL-UNITS       PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-INVOICE     PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-TOTAL-INTEREST    PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-BUCKET-COUNTS.
               10  WS-GA-B1-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B2-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B3-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B4-COUNT      PIC S9(08) COMP VALUE +0.
               10  WS-GA-B5-COUNT      PIC S9(08) COMP VALUE +0.
           05  WS-GA-BUCKET-INVOICE.
               10  WS-GA-B1-INV        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B2-INV        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B3-INV        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B4-INV        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B5-INV        PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-BUCKET-INTEREST.
               10  WS-GA-B1-INT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B2-INT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B3-INT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B4-INT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
               10  WS-GA-B5-INT        PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-DEALER-COUNT      PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - FLOOR PLAN CURSOR
      *
       01  WS-HV-FP.
           05  WS-HV-VIN              PIC X(17).
           05  WS-HV-MODEL-YEAR       PIC S9(04) COMP.
           05  WS-HV-MODEL-NAME       PIC X(30).
           05  WS-HV-DAYS-ON-FLOOR    PIC S9(06) COMP.
           05  WS-HV-INVOICE-AMT      PIC S9(09)V99 COMP-3.
           05  WS-HV-INTEREST-ACC     PIC S9(09)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-YEAR-DISP           PIC 9(04) VALUE 0.
           05  WS-PCT-WORK            PIC S9(05)V9 COMP-3
                                                    VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_FPL_DLRS CURSOR FOR
               SELECT DISTINCT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               INNER JOIN AUTOSALE.FLOOR_PLAN_VEHICLE FP
                 ON   D.DEALER_CODE = FP.DEALER_CODE
               WHERE  FP.FP_STATUS = 'AC'
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_FPL_VEHICLES CURSOR FOR
               SELECT FP.VIN
                    , M.MODEL_YEAR
                    , M.MODEL_NAME
                    , FP.DAYS_ON_FLOOR
                    , FP.INVOICE_AMOUNT
                    , FP.INTEREST_ACCRUED
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE FP
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   FP.VIN = V.VIN
               INNER JOIN AUTOSALE.MODEL_MASTER M
                 ON   V.MODEL_YEAR = M.MODEL_YEAR
                AND   V.MAKE_CODE  = M.MAKE_CODE
                AND   V.MODEL_CODE = M.MODEL_CODE
               WHERE  FP.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  FP.FP_STATUS = 'AC'
               ORDER BY FP.DAYS_ON_FLOOR DESC, FP.VIN
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTFPL00: FLOOR PLAN AGING REPORT - START'
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
           DISPLAY 'RPTFPL00: REPORT COMPLETE - '
                   WS-GA-TOTAL-UNITS ' UNITS, '
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
           DISPLAY 'RPTFPL00: REPORT DATE = ' WS-REPORT-DATE
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
               DISPLAY 'RPTFPL00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_FPL_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTFPL00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_FPL_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-PROCESS-FLOOR-PLAN
                       PERFORM 6000-PRINT-DEALER-SUBTOTAL
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTFPL00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_FPL_DLRS END-EXEC
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
      *    5000-PROCESS-FLOOR-PLAN - DETAIL LINES FOR FP VEHICLES    *
      ****************************************************************
       5000-PROCESS-FLOOR-PLAN.
      *
           EXEC SQL OPEN CSR_FPL_VEHICLES END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTFPL00: ERROR OPENING FP CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FP
      *
           PERFORM UNTIL WS-FP-DONE
               EXEC SQL FETCH CSR_FPL_VEHICLES
                   INTO :WS-HV-VIN
                      , :WS-HV-MODEL-YEAR
                      , :WS-HV-MODEL-NAME
                      , :WS-HV-DAYS-ON-FLOOR
                      , :WS-HV-INVOICE-AMT
                      , :WS-HV-INTEREST-ACC
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-FP-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTFPL00: DB2 ERROR ON FP - '
                               SQLCODE
                       SET WS-FP-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_FPL_VEHICLES END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FORMAT-DETAIL - FORMAT AND PRINT ONE FP LINE         *
      ****************************************************************
       5100-FORMAT-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 4000-NEW-DEALER-PAGE
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
      *
           MOVE WS-HV-VIN         TO WS-DL-VIN
           MOVE WS-HV-MODEL-YEAR  TO WS-DL-YEAR
           MOVE WS-HV-MODEL-NAME(1:20) TO WS-DL-MODEL
           MOVE WS-HV-DAYS-ON-FLOOR TO WS-DL-DAYS
           MOVE WS-HV-INVOICE-AMT TO WS-DL-INVOICE
           MOVE WS-HV-INTEREST-ACC TO WS-DL-INTEREST
      *
      *    DETERMINE AGE BUCKET AND ACCUMULATE
      *
           EVALUATE TRUE
               WHEN WS-HV-DAYS-ON-FLOOR <= 30
                   MOVE '0-30 DAYS  ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B1-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-DA-B1-INV
                   ADD WS-HV-INTEREST-ACC TO WS-DA-B1-INT
                   ADD +1 TO WS-GA-B1-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-GA-B1-INV
                   ADD WS-HV-INTEREST-ACC TO WS-GA-B1-INT
               WHEN WS-HV-DAYS-ON-FLOOR <= 60
                   MOVE '31-60 DAYS ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B2-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-DA-B2-INV
                   ADD WS-HV-INTEREST-ACC TO WS-DA-B2-INT
                   ADD +1 TO WS-GA-B2-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-GA-B2-INV
                   ADD WS-HV-INTEREST-ACC TO WS-GA-B2-INT
               WHEN WS-HV-DAYS-ON-FLOOR <= 90
                   MOVE '61-90 DAYS ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B3-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-DA-B3-INV
                   ADD WS-HV-INTEREST-ACC TO WS-DA-B3-INT
                   ADD +1 TO WS-GA-B3-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-GA-B3-INV
                   ADD WS-HV-INTEREST-ACC TO WS-GA-B3-INT
               WHEN WS-HV-DAYS-ON-FLOOR <= 120
                   MOVE '91-120 DAYS' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B4-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-DA-B4-INV
                   ADD WS-HV-INTEREST-ACC TO WS-DA-B4-INT
                   ADD +1 TO WS-GA-B4-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-GA-B4-INV
                   ADD WS-HV-INTEREST-ACC TO WS-GA-B4-INT
               WHEN OTHER
                   MOVE '120+ DAYS  ' TO WS-DL-AGE-BUCKET
                   ADD +1 TO WS-DA-B5-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-DA-B5-INV
                   ADD WS-HV-INTEREST-ACC TO WS-DA-B5-INT
                   ADD +1 TO WS-GA-B5-COUNT
                   ADD WS-HV-INVOICE-AMT TO WS-GA-B5-INV
                   ADD WS-HV-INTEREST-ACC TO WS-GA-B5-INT
           END-EVALUATE
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
           ADD +1 TO WS-DA-TOTAL-UNITS
           ADD WS-HV-INVOICE-AMT TO WS-DA-TOTAL-INVOICE
           ADD WS-HV-INTEREST-ACC TO WS-DA-TOTAL-INTEREST
      *
           ADD +1 TO WS-GA-TOTAL-UNITS
           ADD WS-HV-INVOICE-AMT TO WS-GA-TOTAL-INVOICE
           ADD WS-HV-INTEREST-ACC TO WS-GA-TOTAL-INTEREST
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
           MOVE WS-DA-B1-INV    TO WS-BL-INVOICE
           MOVE WS-DA-B1-INT    TO WS-BL-INTEREST
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '31-60 DAYS  ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B2-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B2-INV    TO WS-BL-INVOICE
           MOVE WS-DA-B2-INT    TO WS-BL-INTEREST
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '61-90 DAYS  ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B3-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B3-INV    TO WS-BL-INVOICE
           MOVE WS-DA-B3-INT    TO WS-BL-INTEREST
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '91-120 DAYS ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B4-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B4-INV    TO WS-BL-INVOICE
           MOVE WS-DA-B4-INT    TO WS-BL-INTEREST
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '120+ DAYS   ' TO WS-BL-BUCKET-NAME
           MOVE WS-DA-B5-COUNT  TO WS-BL-COUNT
           MOVE WS-DA-B5-INV    TO WS-BL-INVOICE
           MOVE WS-DA-B5-INT    TO WS-BL-INTEREST
           WRITE REPORT-RECORD FROM WS-BUCKET-LINE
               AFTER ADVANCING 1
      *
      *    DEALER TOTAL
      *
           MOVE WS-DA-TOTAL-UNITS    TO WS-DTL-COUNT
           MOVE WS-DA-TOTAL-INVOICE  TO WS-DTL-INVOICE
           MOVE WS-DA-TOTAL-INTEREST TO WS-DTL-INTEREST
           WRITE REPORT-RECORD FROM WS-DEALER-TOTAL-LINE
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-TOTAL-UNITS    TO WS-GT-UNIT-COUNT
           MOVE WS-GA-TOTAL-INVOICE  TO WS-GT-INVOICE
           MOVE WS-GA-TOTAL-INTEREST TO WS-GT-INTEREST
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
      *
      *    GRAND AGING SUMMARY WITH PERCENTAGES
      *
           MOVE '0-30 DAYS   ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B1-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B1-INV    TO WS-GB-INVOICE
           MOVE WS-GA-B1-INT    TO WS-GB-INTEREST
           IF WS-GA-TOTAL-UNITS > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B1-COUNT * 100) / WS-GA-TOTAL-UNITS
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '31-60 DAYS  ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B2-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B2-INV    TO WS-GB-INVOICE
           MOVE WS-GA-B2-INT    TO WS-GB-INTEREST
           IF WS-GA-TOTAL-UNITS > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B2-COUNT * 100) / WS-GA-TOTAL-UNITS
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '61-90 DAYS  ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B3-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B3-INV    TO WS-GB-INVOICE
           MOVE WS-GA-B3-INT    TO WS-GB-INTEREST
           IF WS-GA-TOTAL-UNITS > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B3-COUNT * 100) / WS-GA-TOTAL-UNITS
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '91-120 DAYS ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B4-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B4-INV    TO WS-GB-INVOICE
           MOVE WS-GA-B4-INT    TO WS-GB-INTEREST
           IF WS-GA-TOTAL-UNITS > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B4-COUNT * 100) / WS-GA-TOTAL-UNITS
           ELSE
               MOVE +0 TO WS-PCT-WORK
           END-IF
           MOVE WS-PCT-WORK TO WS-GB-PCT
           WRITE REPORT-RECORD FROM WS-GRAND-BUCKET-LINE
               AFTER ADVANCING 1
      *
           MOVE '120+ DAYS   ' TO WS-GB-BUCKET-NAME
           MOVE WS-GA-B5-COUNT  TO WS-GB-COUNT
           MOVE WS-GA-B5-INV    TO WS-GB-INVOICE
           MOVE WS-GA-B5-INT    TO WS-GB-INTEREST
           IF WS-GA-TOTAL-UNITS > +0
               COMPUTE WS-PCT-WORK =
                   (WS-GA-B5-COUNT * 100) / WS-GA-TOTAL-UNITS
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
               DISPLAY 'RPTFPL00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTFPL00                                              *
      ****************************************************************
