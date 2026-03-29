       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTAGN00.
      ****************************************************************
      * PROGRAM:    RPTAGN00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    AGED INVENTORY REPORT. REPORTS DEALER INVENTORY  *
      *             AGING FOR UNSOLD VEHICLES IN STOCK. DETAIL LINE  *
      *             PER VEHICLE: VIN, YEAR, MODEL, COLOR, STOCK      *
      *             DATE, DAYS IN STOCK, INVOICE COST, INTEREST      *
      *             CARRYING COST. AGE BUCKETS: 0-30, 31-60, 61-90, *
      *             91-120, 120+ DAYS. SUBTOTALS PER DEALER PER AGE *
      *             BUCKET. GRAND TOTALS WITH AGING DISTRIBUTION.    *
      *                                                              *
      * INPUT:      NONE (ALL IN-STOCK VEHICLES)                     *
      *                                                              *
      * TABLES:     AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
      *             AUTOSALE.MODEL_MASTER   (READ)                   *
      *             AUTOSALE.FLOOR_PLAN_VEHICLE (READ)               *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTAGN00'.
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
           05  WS-EOF-VEH             PIC X(01) VALUE 'N'.
               88  WS-VEHS-DONE                  VALUE 'Y'.
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
      *    INTEREST RATE FOR CARRYING COST CALCULATION
      *
       01  WS-FLOOR-RATE               PIC S9(03)V999 COMP-3
                                                       VALUE +6.500.
      *
      *    REPORT HEADER LINE (132 CHARS)
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE '   AGED INVENTORY REPORT      '.
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
           05  FILLER                  PIC X(06) VALUE 'COLOR '.
           05  FILLER                  PIC X(12) VALUE
               'STOCK DATE  '.
           05  FILLER                  PIC X(06) VALUE 'DAYS  '.
           05  FILLER                  PIC X(08) VALUE 'BUCKET  '.
           05  FILLER                  PIC X(16) VALUE
               '  INVOICE COST  '.
           05  FILLER                  PIC X(16) VALUE
               ' CARRYING COST  '.
           05  FILLER                  PIC X(20) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(19) VALUE
               '----------------- '.
           05  FILLER                  PIC X(06) VALUE '---- '.
           05  FILLER                  PIC X(22) VALUE
               '-------------------- '.
           05  FILLER                  PIC X(06) VALUE '----- '.
           05  FILLER                  PIC X(12) VALUE
               '---------- '.
           05  FILLER                  PIC X(06) VALUE '----- '.
           05  FILLER                  PIC X(08) VALUE '------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(16) VALUE
               '--------------- '.
           05  FILLER                  PIC X(20) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-VIN              PIC X(17).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-YEAR             PIC 9(04).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-MODEL            PIC X(20).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-COLOR            PIC X(03).
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-DL-STOCK-DATE       PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-DAYS             PIC Z(3)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-BUCKET           PIC X(06).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-INVOICE          PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-CARRYING         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-AGED-FLAG        PIC X(01).
           05  FILLER                  PIC X(18) VALUE SPACES.
      *
       01  WS-BUCKET-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(20)
               VALUE 'AGE BUCKET SUMMARY: '.
           05  FILLER                  PIC X(111) VALUE SPACES.
      *
       01  WS-BUCKET-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE '     '.
           05  WS-BL-BUCKET-NAME      PIC X(12).
           05  FILLER                  PIC X(02) VALUE ': '.
           05  WS-BL-COUNT            PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' UNITS  '.
           05  WS-BL-VALUE            PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(10) VALUE ' INVOICE  '.
           05  WS-BL-CARRY            PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(10) VALUE ' INTEREST '.
           05  WS-BL-PCT              PIC ZZ9.99.
           05  FILLER                  PIC X(01) VALUE '%'.
           05  FILLER                  PIC X(42) VALUE SPACES.
      *
       01  WS-SUBTOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '-'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'DEALER TOTALS:    '.
           05  WS-ST-VEH-COUNT         PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' UNITS  '.
           05  WS-ST-TOTAL-INVOICE     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-ST-TOTAL-CARRY       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'GRAND TOTALS:     '.
           05  WS-GT-VEH-COUNT         PIC Z(4)9.
           05  FILLER                  PIC X(08) VALUE ' UNITS  '.
           05  WS-GT-TOTAL-INVOICE     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-GT-TOTAL-CARRY       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(24) VALUE SPACES.
      *
       01  WS-GRAND-AVG-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(44) VALUE SPACES.
           05  FILLER                  PIC X(18)
               VALUE 'AVG DAYS IN STOCK:'.
           05  WS-GA-AVG-DAYS          PIC Z(4)9.
           05  FILLER                  PIC X(60) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS - DEALER LEVEL
      *
       01  WS-DEALER-ACCUM.
           05  WS-DA-VEH-COUNT         PIC S9(06) COMP VALUE +0.
           05  WS-DA-TOTAL-INVOICE     PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-TOTAL-CARRY       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-DA-TOTAL-DAYS        PIC S9(08) COMP VALUE +0.
      *
      *    BUCKET ACCUMULATORS (5 BUCKETS) - DEALER LEVEL
      *
       01  WS-DA-BUCKET-COUNTS.
           05  WS-DA-BKT-COUNT         PIC S9(06) COMP
                                        OCCURS 5 TIMES VALUE +0.
       01  WS-DA-BUCKET-VALUES.
           05  WS-DA-BKT-VALUE         PIC S9(13)V99 COMP-3
                                        OCCURS 5 TIMES VALUE +0.
       01  WS-DA-BUCKET-CARRY.
           05  WS-DA-BKT-CARRY         PIC S9(11)V99 COMP-3
                                        OCCURS 5 TIMES VALUE +0.
      *
      *    ACCUMULATOR FIELDS - GRAND LEVEL
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-VEH-COUNT         PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-INVOICE     PIC S9(15)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-TOTAL-CARRY       PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-TOTAL-DAYS        PIC S9(10) COMP VALUE +0.
           05  WS-GA-DEALER-COUNT      PIC S9(04) COMP VALUE +0.
      *
       01  WS-GA-BUCKET-COUNTS.
           05  WS-GA-BKT-COUNT         PIC S9(08) COMP
                                        OCCURS 5 TIMES VALUE +0.
       01  WS-GA-BUCKET-VALUES.
           05  WS-GA-BKT-VALUE         PIC S9(15)V99 COMP-3
                                        OCCURS 5 TIMES VALUE +0.
      *
      *    HOST VARIABLES - DEALER CURSOR
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
      *
      *    HOST VARIABLES - VEHICLE CURSOR
      *
       01  WS-HV-VEHICLE.
           05  WS-HV-VIN              PIC X(17).
           05  WS-HV-MODEL-YEAR       PIC S9(04) COMP.
           05  WS-HV-MODEL-NAME       PIC X(40).
           05  WS-HV-EXT-COLOR        PIC X(03).
           05  WS-HV-RECEIVE-DATE     PIC X(10).
           05  WS-HV-DAYS-IN-STOCK    PIC S9(04) COMP.
           05  WS-HV-INVOICE-AMT      PIC S9(09)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-BUCKET-IDX          PIC S9(02) COMP VALUE +0.
           05  WS-CARRYING-COST       PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-AVG-DAYS-WORK       PIC S9(06) COMP VALUE +0.
           05  WS-PCT-WORK            PIC S9(05)V99 COMP-3
                                                     VALUE +0.
           05  WS-BUCKET-NAMES.
               10  FILLER             PIC X(12)
                                      VALUE '0-30 DAYS   '.
               10  FILLER             PIC X(12)
                                      VALUE '31-60 DAYS  '.
               10  FILLER             PIC X(12)
                                      VALUE '61-90 DAYS  '.
               10  FILLER             PIC X(12)
                                      VALUE '91-120 DAYS '.
               10  FILLER             PIC X(12)
                                      VALUE '120+ DAYS   '.
           05  WS-BUCKET-NAME-TBL REDEFINES WS-BUCKET-NAMES.
               10  WS-BUCKET-NAME     PIC X(12) OCCURS 5 TIMES.
           05  WS-BUCKET-SHORT.
               10  FILLER             PIC X(06) VALUE '0-30  '.
               10  FILLER             PIC X(06) VALUE '31-60 '.
               10  FILLER             PIC X(06) VALUE '61-90 '.
               10  FILLER             PIC X(06) VALUE '91-120'.
               10  FILLER             PIC X(06) VALUE '120+  '.
           05  WS-BUCKET-SHORT-TBL REDEFINES WS-BUCKET-SHORT.
               10  WS-BKT-SHORT       PIC X(06) OCCURS 5 TIMES.
           05  WS-IDX                  PIC S9(02) COMP VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_AGN_DLRS CURSOR FOR
               SELECT DISTINCT D.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.DEALER D
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   D.DEALER_CODE = V.DEALER_CODE
               WHERE  V.VEHICLE_STATUS IN ('AV', 'HD')
               ORDER BY D.DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_AGN_VEHS CURSOR FOR
               SELECT V.VIN
                    , V.MODEL_YEAR
                    , M.MODEL_NAME
                    , V.EXTERIOR_COLOR
                    , CHAR(V.RECEIVE_DATE, ISO)
                    , V.DAYS_IN_STOCK
                    , COALESCE(F.INVOICE_AMOUNT, 0)
               FROM   AUTOSALE.VEHICLE V
               INNER JOIN AUTOSALE.MODEL_MASTER M
                 ON   V.MODEL_YEAR = M.MODEL_YEAR
                 AND  V.MAKE_CODE  = M.MAKE_CODE
                 AND  V.MODEL_CODE = M.MODEL_CODE
               LEFT JOIN AUTOSALE.FLOOR_PLAN_VEHICLE F
                 ON   V.VIN = F.VIN
                 AND  F.FP_STATUS = 'AC'
               WHERE  V.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  V.VEHICLE_STATUS IN ('AV', 'HD')
               ORDER BY V.DAYS_IN_STOCK DESC
                      , V.VIN
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTAGN00: AGED INVENTORY REPORT - START'
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
           DISPLAY 'RPTAGN00: REPORT COMPLETE - '
                   WS-GA-VEH-COUNT ' VEHICLES, '
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
           DISPLAY 'RPTAGN00: REPORT DATE = ' WS-REPORT-DATE
      *
           INITIALIZE WS-DEALER-ACCUM
           INITIALIZE WS-GRAND-ACCUM
           INITIALIZE WS-DA-BUCKET-COUNTS
           INITIALIZE WS-DA-BUCKET-VALUES
           INITIALIZE WS-DA-BUCKET-CARRY
           INITIALIZE WS-GA-BUCKET-COUNTS
           INITIALIZE WS-GA-BUCKET-VALUES
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
               DISPLAY 'RPTAGN00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_AGN_DLRS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTAGN00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_AGN_DLRS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-DEALER-COUNT
                       PERFORM 4000-NEW-DEALER-PAGE
                       PERFORM 5000-PROCESS-VEHICLES
                       PERFORM 6000-PRINT-DEALER-SUBTOTAL
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTAGN00: DB2 ERROR ON DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_AGN_DLRS END-EXEC
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
           INITIALIZE WS-DA-BUCKET-COUNTS
           INITIALIZE WS-DA-BUCKET-VALUES
           INITIALIZE WS-DA-BUCKET-CARRY
           .
      *
      ****************************************************************
      *    5000-PROCESS-VEHICLES - DETAIL FOR EACH VEHICLE           *
      ****************************************************************
       5000-PROCESS-VEHICLES.
      *
           EXEC SQL OPEN CSR_AGN_VEHS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTAGN00: ERROR OPENING VEH CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-VEH
      *
           PERFORM UNTIL WS-VEHS-DONE
               EXEC SQL FETCH CSR_AGN_VEHS
                   INTO :WS-HV-VIN
                      , :WS-HV-MODEL-YEAR
                      , :WS-HV-MODEL-NAME
                      , :WS-HV-EXT-COLOR
                      , :WS-HV-RECEIVE-DATE
                      , :WS-HV-DAYS-IN-STOCK
                      , :WS-HV-INVOICE-AMT
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-VEHS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTAGN00: DB2 ERROR ON VEH - '
                               SQLCODE
                       SET WS-VEHS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_AGN_VEHS END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FORMAT-DETAIL - FORMAT AND PRINT ONE VEHICLE LINE    *
      ****************************************************************
       5100-FORMAT-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 4000-NEW-DEALER-PAGE
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
      *
           MOVE WS-HV-VIN            TO WS-DL-VIN
           MOVE WS-HV-MODEL-YEAR     TO WS-DL-YEAR
           MOVE WS-HV-MODEL-NAME(1:20) TO WS-DL-MODEL
           MOVE WS-HV-EXT-COLOR      TO WS-DL-COLOR
           MOVE WS-HV-RECEIVE-DATE   TO WS-DL-STOCK-DATE
           MOVE WS-HV-DAYS-IN-STOCK  TO WS-DL-DAYS
      *
      *    DETERMINE AGE BUCKET
      *
           EVALUATE TRUE
               WHEN WS-HV-DAYS-IN-STOCK <= 30
                   MOVE 1 TO WS-BUCKET-IDX
                   MOVE '0-30  ' TO WS-DL-BUCKET
               WHEN WS-HV-DAYS-IN-STOCK <= 60
                   MOVE 2 TO WS-BUCKET-IDX
                   MOVE '31-60 ' TO WS-DL-BUCKET
               WHEN WS-HV-DAYS-IN-STOCK <= 90
                   MOVE 3 TO WS-BUCKET-IDX
                   MOVE '61-90 ' TO WS-DL-BUCKET
               WHEN WS-HV-DAYS-IN-STOCK <= 120
                   MOVE 4 TO WS-BUCKET-IDX
                   MOVE '91-120' TO WS-DL-BUCKET
               WHEN OTHER
                   MOVE 5 TO WS-BUCKET-IDX
                   MOVE '120+  ' TO WS-DL-BUCKET
           END-EVALUATE
      *
      *    CALCULATE CARRYING COST (DAILY INTEREST)
      *
           IF WS-HV-INVOICE-AMT > +0
               COMPUTE WS-CARRYING-COST =
                   WS-HV-INVOICE-AMT *
                   (WS-FLOOR-RATE / 100 / 365) *
                   WS-HV-DAYS-IN-STOCK
           ELSE
               MOVE +0 TO WS-CARRYING-COST
           END-IF
      *
           MOVE WS-HV-INVOICE-AMT TO WS-DL-INVOICE
           MOVE WS-CARRYING-COST  TO WS-DL-CARRYING
      *
      *    FLAG AGED STOCK (90+ DAYS)
      *
           IF WS-HV-DAYS-IN-STOCK >= 90
               MOVE '*' TO WS-DL-AGED-FLAG
           ELSE
               MOVE ' ' TO WS-DL-AGED-FLAG
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
      *    ACCUMULATE - DEALER
      *
           ADD +1 TO WS-DA-VEH-COUNT
           ADD WS-HV-INVOICE-AMT TO WS-DA-TOTAL-INVOICE
           ADD WS-CARRYING-COST  TO WS-DA-TOTAL-CARRY
           ADD WS-HV-DAYS-IN-STOCK TO WS-DA-TOTAL-DAYS
      *
           ADD +1 TO WS-DA-BKT-COUNT(WS-BUCKET-IDX)
           ADD WS-HV-INVOICE-AMT
               TO WS-DA-BKT-VALUE(WS-BUCKET-IDX)
           ADD WS-CARRYING-COST
               TO WS-DA-BKT-CARRY(WS-BUCKET-IDX)
      *
      *    ACCUMULATE - GRAND
      *
           ADD +1 TO WS-GA-VEH-COUNT
           ADD WS-HV-INVOICE-AMT TO WS-GA-TOTAL-INVOICE
           ADD WS-CARRYING-COST  TO WS-GA-TOTAL-CARRY
           ADD WS-HV-DAYS-IN-STOCK TO WS-GA-TOTAL-DAYS
      *
           ADD +1 TO WS-GA-BKT-COUNT(WS-BUCKET-IDX)
           ADD WS-HV-INVOICE-AMT
               TO WS-GA-BKT-VALUE(WS-BUCKET-IDX)
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-DEALER-SUBTOTAL                                *
      ****************************************************************
       6000-PRINT-DEALER-SUBTOTAL.
      *
           MOVE WS-DA-VEH-COUNT      TO WS-ST-VEH-COUNT
           MOVE WS-DA-TOTAL-INVOICE  TO WS-ST-TOTAL-INVOICE
           MOVE WS-DA-TOTAL-CARRY    TO WS-ST-TOTAL-CARRY
      *
           WRITE REPORT-RECORD FROM WS-SUBTOTAL-LINE
               AFTER ADVANCING 2
      *
      *    PRINT BUCKET BREAKDOWN
      *
           WRITE REPORT-RECORD FROM WS-BUCKET-HEADER
               AFTER ADVANCING 2
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               MOVE WS-BUCKET-NAME(WS-IDX)
                   TO WS-BL-BUCKET-NAME
               MOVE WS-DA-BKT-COUNT(WS-IDX)
                   TO WS-BL-COUNT
               MOVE WS-DA-BKT-VALUE(WS-IDX)
                   TO WS-BL-VALUE
               MOVE WS-DA-BKT-CARRY(WS-IDX)
                   TO WS-BL-CARRY
      *
               IF WS-DA-VEH-COUNT > +0
                   COMPUTE WS-PCT-WORK =
                       (WS-DA-BKT-COUNT(WS-IDX) /
                        WS-DA-VEH-COUNT) * 100
               ELSE
                   MOVE +0 TO WS-PCT-WORK
               END-IF
               MOVE WS-PCT-WORK TO WS-BL-PCT
      *
               WRITE REPORT-RECORD FROM WS-BUCKET-LINE
                   AFTER ADVANCING 1
           END-PERFORM
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-VEH-COUNT      TO WS-GT-VEH-COUNT
           MOVE WS-GA-TOTAL-INVOICE  TO WS-GT-TOTAL-INVOICE
           MOVE WS-GA-TOTAL-CARRY    TO WS-GT-TOTAL-CARRY
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
      *
      *    AVERAGE DAYS IN STOCK
      *
           IF WS-GA-VEH-COUNT > +0
               COMPUTE WS-AVG-DAYS-WORK =
                   WS-GA-TOTAL-DAYS / WS-GA-VEH-COUNT
               MOVE WS-AVG-DAYS-WORK TO WS-GA-AVG-DAYS
           ELSE
               MOVE +0 TO WS-GA-AVG-DAYS
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-GRAND-AVG-LINE
               AFTER ADVANCING 1
      *
      *    GRAND BUCKET DISTRIBUTION
      *
           WRITE REPORT-RECORD FROM WS-BUCKET-HEADER
               AFTER ADVANCING 2
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               MOVE WS-BUCKET-NAME(WS-IDX)
                   TO WS-BL-BUCKET-NAME
               MOVE WS-GA-BKT-COUNT(WS-IDX)
                   TO WS-BL-COUNT
               MOVE WS-GA-BKT-VALUE(WS-IDX)
                   TO WS-BL-VALUE
               MOVE +0 TO WS-BL-CARRY
      *
               IF WS-GA-VEH-COUNT > +0
                   COMPUTE WS-PCT-WORK =
                       (WS-GA-BKT-COUNT(WS-IDX) /
                        WS-GA-VEH-COUNT) * 100
               ELSE
                   MOVE +0 TO WS-PCT-WORK
               END-IF
               MOVE WS-PCT-WORK TO WS-BL-PCT
      *
               WRITE REPORT-RECORD FROM WS-BUCKET-LINE
                   AFTER ADVANCING 1
           END-PERFORM
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
               DISPLAY 'RPTAGN00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTAGN00                                              *
      ****************************************************************
