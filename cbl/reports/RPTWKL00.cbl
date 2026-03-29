       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTWKL00.
      ****************************************************************
      * PROGRAM:    RPTWKL00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    WEEKLY SALES SUMMARY REPORT. PRODUCES A DEALER   *
      *             X MODEL MATRIX WHERE COLUMNS ARE MODELS AND      *
      *             ROWS ARE DEALERS. CELL VALUE = UNITS SOLD THIS   *
      *             WEEK. SHOWS ROW TOTALS, COLUMN TOTALS, AND       *
      *             GRAND TOTAL. ALSO SHOWS AVG GROSS PER UNIT AND   *
      *             TOTAL REVENUE.                                   *
      *                                                              *
      * INPUT:      WEEK ENDING DATE PARAMETER                       *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
      *             AUTOSALE.MODEL_MASTER   (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTWKL00'.
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
           05  WS-EOF-FLAG             PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA                VALUE 'Y'.
      *
      *    INPUT PARAMETERS
      *
       01  WS-PARM-AREA.
           05  WS-WEEK-END-DATE        PIC X(10) VALUE SPACES.
           05  WS-WEEK-START-DATE      PIC X(10) VALUE SPACES.
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY            PIC 9(04).
           05  WS-CURR-MM              PIC 9(02).
           05  WS-CURR-DD              PIC 9(02).
           05  FILLER                  PIC X(13).
      *
      *    MODEL TABLE (MAX 10 MODELS FOR MATRIX)
      *
       01  WS-MAX-MODELS               PIC S9(04) COMP VALUE +10.
       01  WS-MODEL-COUNT              PIC S9(04) COMP VALUE +0.
       01  WS-MODEL-TABLE.
           05  WS-MODEL-ENTRY OCCURS 10 TIMES.
               10  WS-MT-MODEL-CODE    PIC X(06).
               10  WS-MT-MODEL-DESC    PIC X(12).
               10  WS-MT-COL-TOTAL     PIC S9(06) COMP VALUE +0.
      *
      *    DEALER TABLE (MAX 50 DEALERS)
      *
       01  WS-MAX-DEALERS              PIC S9(04) COMP VALUE +50.
       01  WS-DEALER-COUNT             PIC S9(04) COMP VALUE +0.
       01  WS-DEALER-TABLE.
           05  WS-DEALER-ENTRY OCCURS 50 TIMES.
               10  WS-DT-DEALER-CODE   PIC X(05).
               10  WS-DT-DEALER-NAME   PIC X(20).
               10  WS-DT-UNITS OCCURS 10 TIMES
                                        PIC S9(04) COMP VALUE +0.
               10  WS-DT-ROW-TOTAL     PIC S9(06) COMP VALUE +0.
               10  WS-DT-REVENUE       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
               10  WS-DT-GROSS         PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
      *    GRAND TOTALS
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-TOTAL-UNITS       PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-REVENUE     PIC S9(13)V99 COMP-3
                                                      VALUE +0.
           05  WS-GA-TOTAL-GROSS       PIC S9(13)V99 COMP-3
                                                      VALUE +0.
      *
      *    HOST VARIABLES
      *
       01  WS-HV-FIELDS.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(40).
           05  WS-HV-MODEL-CODE       PIC X(06).
           05  WS-HV-MODEL-DESC       PIC X(30).
           05  WS-HV-UNIT-COUNT       PIC S9(06) COMP.
           05  WS-HV-TOTAL-REVENUE    PIC S9(11)V99 COMP-3.
           05  WS-HV-TOTAL-GROSS      PIC S9(11)V99 COMP-3.
      *
      *    REPORT LINES
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE '  WEEKLY SALES SUMMARY REPORT '.
           05  FILLER                  PIC X(07) VALUE 'PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(49) VALUE SPACES.
      *
       01  WS-DATE-RANGE-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(14)
               VALUE 'WEEK PERIOD:  '.
           05  WS-DR-START             PIC X(10).
           05  FILLER                  PIC X(05) VALUE ' TO  '.
           05  WS-DR-END               PIC X(10).
           05  FILLER                  PIC X(92) VALUE SPACES.
      *
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-MATRIX-HDR.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(26)
               VALUE 'DEALER                    '.
           05  WS-MH-MODELS            PIC X(96) VALUE SPACES.
           05  FILLER                  PIC X(09) VALUE '  TOTAL  '.
      *
       01  WS-MATRIX-DETAIL.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-MD-DEALER-CODE       PIC X(05).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-MD-DEALER-NAME       PIC X(20).
           05  WS-MD-CELLS             PIC X(96) VALUE SPACES.
           05  WS-MD-ROW-TOTAL         PIC Z(5)9.
           05  FILLER                  PIC X(03) VALUE SPACES.
      *
       01  WS-MATRIX-COL-TOTALS.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(26)
               VALUE 'MODEL TOTALS:             '.
           05  WS-MC-CELLS             PIC X(96) VALUE SPACES.
           05  WS-MC-GRAND-TOTAL       PIC Z(5)9.
           05  FILLER                  PIC X(03) VALUE SPACES.
      *
       01  WS-REVENUE-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-RL-DEALER-CODE       PIC X(05).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-RL-DEALER-NAME       PIC X(20).
           05  FILLER                  PIC X(12)
               VALUE '  REVENUE:  '.
           05  WS-RL-REVENUE           PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(08) VALUE '  GROSS:'.
           05  WS-RL-GROSS             PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(10)
               VALUE '  AVG/UNIT'.
           05  WS-RL-AVG-GROSS         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(25) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(26) VALUE ALL '='.
           05  FILLER                  PIC X(12)
               VALUE '  REVENUE:  '.
           05  WS-GT-REVENUE           PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(08) VALUE '  GROSS:'.
           05  WS-GT-GROSS             PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(10)
               VALUE '  AVG/UNIT'.
           05  WS-GT-AVG-GROSS         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(25) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-IDX                  PIC S9(04) COMP VALUE +0.
           05  WS-IDX2                 PIC S9(04) COMP VALUE +0.
           05  WS-DLR-IDX             PIC S9(04) COMP VALUE +0.
           05  WS-MDL-IDX             PIC S9(04) COMP VALUE +0.
           05  WS-CELL-POS            PIC S9(04) COMP VALUE +0.
           05  WS-CELL-VALUE          PIC Z(4)9.
           05  WS-AVG-WORK            PIC S9(09)V99 COMP-3
                                                     VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_WKL_MODELS CURSOR FOR
               SELECT DISTINCT V.MODEL_CODE
                    , V.MODEL_DESC
               FROM   AUTOSALE.VEHICLE V
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   V.VIN = S.VIN
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-WEEK-START-DATE
                                          AND :WS-WEEK-END-DATE
               ORDER BY V.MODEL_CODE
               FETCH FIRST 10 ROWS ONLY
           END-EXEC
      *
           EXEC SQL DECLARE CSR_WKL_DATA CURSOR FOR
               SELECT S.DEALER_CODE
                    , D.DEALER_NAME
                    , V.MODEL_CODE
                    , V.MODEL_DESC
                    , COUNT(*) AS UNIT_COUNT
                    , SUM(S.TOTAL_PRICE) AS TOTAL_REVENUE
                    , SUM(S.TOTAL_PRICE - V.INVOICE_PRICE)
                                         AS TOTAL_GROSS
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.DEALER D
                 ON   S.DEALER_CODE = D.DEALER_CODE
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-WEEK-START-DATE
                                          AND :WS-WEEK-END-DATE
               GROUP BY S.DEALER_CODE, D.DEALER_NAME,
                        V.MODEL_CODE, V.MODEL_DESC
               ORDER BY S.DEALER_CODE, V.MODEL_CODE
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTWKL00: WEEKLY SALES SUMMARY - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 3000-LOAD-MODELS
               PERFORM 4000-LOAD-DATA
               PERFORM 5000-PRINT-MATRIX
               PERFORM 6000-PRINT-REVENUE-SECTION
               PERFORM 7000-PRINT-GRAND-TOTALS
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTWKL00: REPORT COMPLETE - '
                   WS-DEALER-COUNT ' DEALERS, '
                   WS-MODEL-COUNT ' MODELS'
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
           IF WS-WEEK-END-DATE = SPACES
               STRING WS-CURR-YYYY '-'
                      WS-CURR-MM   '-'
                      WS-CURR-DD
                      DELIMITED BY SIZE
                      INTO WS-WEEK-END-DATE
           END-IF
      *
      *    COMPUTE START DATE (7 DAYS BACK)
      *
           EXEC SQL
               SELECT CHAR(DATE(:WS-WEEK-END-DATE) - 6 DAYS,
                           ISO)
               INTO   :WS-WEEK-START-DATE
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'RPTWKL00: WEEK = ' WS-WEEK-START-DATE
                   ' TO ' WS-WEEK-END-DATE
      *
           INITIALIZE WS-MODEL-TABLE
           INITIALIZE WS-DEALER-TABLE
           INITIALIZE WS-GRAND-ACCUM
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTWKL00: ERROR OPENING REPORT FILE'
           END-IF
           .
      *
      ****************************************************************
      *    3000-LOAD-MODELS - BUILD MODEL COLUMN LIST                *
      ****************************************************************
       3000-LOAD-MODELS.
      *
           EXEC SQL OPEN CSR_WKL_MODELS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTWKL00: ERROR OPENING MODEL CURSOR'
               GO TO 3000-EXIT
           END-IF
      *
           MOVE +0 TO WS-MODEL-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               OR WS-MODEL-COUNT >= WS-MAX-MODELS
      *
               EXEC SQL FETCH CSR_WKL_MODELS
                   INTO :WS-HV-MODEL-CODE
                      , :WS-HV-MODEL-DESC
               END-EXEC
      *
               IF SQLCODE = +0
                   ADD +1 TO WS-MODEL-COUNT
                   MOVE WS-HV-MODEL-CODE
                       TO WS-MT-MODEL-CODE(WS-MODEL-COUNT)
                   MOVE WS-HV-MODEL-DESC(1:12)
                       TO WS-MT-MODEL-DESC(WS-MODEL-COUNT)
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_WKL_MODELS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOAD-DATA - POPULATE MATRIX FROM DB2                 *
      ****************************************************************
       4000-LOAD-DATA.
      *
           EXEC SQL OPEN CSR_WKL_DATA END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTWKL00: ERROR OPENING DATA CURSOR'
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_WKL_DATA
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
                      , :WS-HV-MODEL-CODE
                      , :WS-HV-MODEL-DESC
                      , :WS-HV-UNIT-COUNT
                      , :WS-HV-TOTAL-REVENUE
                      , :WS-HV-TOTAL-GROSS
               END-EXEC
      *
               IF SQLCODE = +0
                   PERFORM 4100-FIND-DEALER-SLOT
                   PERFORM 4200-FIND-MODEL-SLOT
                   IF WS-DLR-IDX > +0 AND WS-MDL-IDX > +0
                       ADD WS-HV-UNIT-COUNT
                         TO WS-DT-UNITS(WS-DLR-IDX, WS-MDL-IDX)
                       ADD WS-HV-UNIT-COUNT
                         TO WS-DT-ROW-TOTAL(WS-DLR-IDX)
                       ADD WS-HV-TOTAL-REVENUE
                         TO WS-DT-REVENUE(WS-DLR-IDX)
                       ADD WS-HV-TOTAL-GROSS
                         TO WS-DT-GROSS(WS-DLR-IDX)
                       ADD WS-HV-UNIT-COUNT
                         TO WS-MT-COL-TOTAL(WS-MDL-IDX)
                       ADD WS-HV-UNIT-COUNT
                         TO WS-GA-TOTAL-UNITS
                       ADD WS-HV-TOTAL-REVENUE
                         TO WS-GA-TOTAL-REVENUE
                       ADD WS-HV-TOTAL-GROSS
                         TO WS-GA-TOTAL-GROSS
                   END-IF
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_WKL_DATA END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FIND-DEALER-SLOT                                     *
      ****************************************************************
       4100-FIND-DEALER-SLOT.
      *
           MOVE +0 TO WS-DLR-IDX
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-DEALER-COUNT
               OR WS-DLR-IDX > +0
               IF WS-DT-DEALER-CODE(WS-IDX) = WS-HV-DLR-CODE
                   MOVE WS-IDX TO WS-DLR-IDX
               END-IF
           END-PERFORM
      *
           IF WS-DLR-IDX = +0
           AND WS-DEALER-COUNT < WS-MAX-DEALERS
               ADD +1 TO WS-DEALER-COUNT
               MOVE WS-DEALER-COUNT TO WS-DLR-IDX
               MOVE WS-HV-DLR-CODE
                   TO WS-DT-DEALER-CODE(WS-DLR-IDX)
               MOVE WS-HV-DLR-NAME(1:20)
                   TO WS-DT-DEALER-NAME(WS-DLR-IDX)
           END-IF
           .
      *
      ****************************************************************
      *    4200-FIND-MODEL-SLOT                                      *
      ****************************************************************
       4200-FIND-MODEL-SLOT.
      *
           MOVE +0 TO WS-MDL-IDX
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-MODEL-COUNT
               OR WS-MDL-IDX > +0
               IF WS-MT-MODEL-CODE(WS-IDX) = WS-HV-MODEL-CODE
                   MOVE WS-IDX TO WS-MDL-IDX
               END-IF
           END-PERFORM
           .
      *
      ****************************************************************
      *    5000-PRINT-MATRIX                                         *
      ****************************************************************
       5000-PRINT-MATRIX.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           MOVE WS-WEEK-START-DATE TO WS-DR-START
           MOVE WS-WEEK-END-DATE   TO WS-DR-END
           WRITE REPORT-RECORD FROM WS-DATE-RANGE-LINE
               AFTER ADVANCING 1
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
      *    BUILD MODEL COLUMN HEADERS
      *
           MOVE SPACES TO WS-MH-MODELS
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-MODEL-COUNT
               COMPUTE WS-CELL-POS =
                   ((WS-IDX - 1) * 9) + 1
               MOVE WS-MT-MODEL-DESC(WS-IDX)
                   TO WS-MH-MODELS(WS-CELL-POS:9)
           END-PERFORM
      *
           WRITE REPORT-RECORD FROM WS-MATRIX-HDR
               AFTER ADVANCING 2
           MOVE 8 TO WS-LINE-COUNT
      *
      *    PRINT EACH DEALER ROW
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-DEALER-COUNT
      *
               IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
                   PERFORM 5100-NEW-PAGE
               END-IF
      *
               INITIALIZE WS-MATRIX-DETAIL
               MOVE WS-DT-DEALER-CODE(WS-IDX)
                   TO WS-MD-DEALER-CODE
               MOVE WS-DT-DEALER-NAME(WS-IDX)
                   TO WS-MD-DEALER-NAME
      *
               PERFORM VARYING WS-IDX2 FROM 1 BY 1
                   UNTIL WS-IDX2 > WS-MODEL-COUNT
                   COMPUTE WS-CELL-POS =
                       ((WS-IDX2 - 1) * 9) + 1
                   MOVE WS-DT-UNITS(WS-IDX, WS-IDX2)
                       TO WS-CELL-VALUE
                   MOVE WS-CELL-VALUE
                       TO WS-MD-CELLS(WS-CELL-POS:6)
               END-PERFORM
      *
               MOVE WS-DT-ROW-TOTAL(WS-IDX)
                   TO WS-MD-ROW-TOTAL
      *
               WRITE REPORT-RECORD FROM WS-MATRIX-DETAIL
                   AFTER ADVANCING 1
               ADD +1 TO WS-LINE-COUNT
           END-PERFORM
      *
      *    COLUMN TOTALS ROW
      *
           MOVE SPACES TO WS-MC-CELLS
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-MODEL-COUNT
               COMPUTE WS-CELL-POS =
                   ((WS-IDX - 1) * 9) + 1
               MOVE WS-MT-COL-TOTAL(WS-IDX)
                   TO WS-CELL-VALUE
               MOVE WS-CELL-VALUE
                   TO WS-MC-CELLS(WS-CELL-POS:6)
           END-PERFORM
           MOVE WS-GA-TOTAL-UNITS TO WS-MC-GRAND-TOTAL
      *
           WRITE REPORT-RECORD FROM WS-MATRIX-COL-TOTALS
               AFTER ADVANCING 2
           .
      *
      ****************************************************************
      *    5100-NEW-PAGE                                             *
      ****************************************************************
       5100-NEW-PAGE.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
           MOVE 6 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-REVENUE-SECTION                                *
      ****************************************************************
       6000-PRINT-REVENUE-SECTION.
      *
           PERFORM 5100-NEW-PAGE
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-DEALER-COUNT
      *
               IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
                   PERFORM 5100-NEW-PAGE
               END-IF
      *
               MOVE WS-DT-DEALER-CODE(WS-IDX)
                   TO WS-RL-DEALER-CODE
               MOVE WS-DT-DEALER-NAME(WS-IDX)
                   TO WS-RL-DEALER-NAME
               MOVE WS-DT-REVENUE(WS-IDX)
                   TO WS-RL-REVENUE
               MOVE WS-DT-GROSS(WS-IDX)
                   TO WS-RL-GROSS
      *
               IF WS-DT-ROW-TOTAL(WS-IDX) > +0
                   COMPUTE WS-AVG-WORK =
                       WS-DT-GROSS(WS-IDX)
                       / WS-DT-ROW-TOTAL(WS-IDX)
               ELSE
                   MOVE +0 TO WS-AVG-WORK
               END-IF
               MOVE WS-AVG-WORK TO WS-RL-AVG-GROSS
      *
               WRITE REPORT-RECORD FROM WS-REVENUE-LINE
                   AFTER ADVANCING 1
               ADD +1 TO WS-LINE-COUNT
           END-PERFORM
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-TOTAL-REVENUE TO WS-GT-REVENUE
           MOVE WS-GA-TOTAL-GROSS   TO WS-GT-GROSS
      *
           IF WS-GA-TOTAL-UNITS > +0
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-GROSS / WS-GA-TOTAL-UNITS
           ELSE
               MOVE +0 TO WS-AVG-WORK
           END-IF
           MOVE WS-AVG-WORK TO WS-GT-AVG-GROSS
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 2
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE REPORT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTWKL00: ERROR CLOSING REPORT FILE'
           END-IF
           .
      ****************************************************************
      * END OF RPTWKL00                                              *
      ****************************************************************
