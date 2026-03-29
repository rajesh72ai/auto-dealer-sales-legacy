       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTMFG00.
      ****************************************************************
      * PROGRAM:    RPTMFG00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    MANUFACTURER COMPLIANCE REPORT. OEM REQUIRED     *
      *             FORMAT WITH ONE LINE PER VEHICLE SOLD SHOWING    *
      *             VIN, DEAL DATE, CUSTOMER STATE, SALE PRICE,      *
      *             DEAL TYPE, AND INCENTIVES APPLIED. SUMMARY BY    *
      *             MODEL WITH TOTAL UNITS AND INCENTIVE DOLLARS.    *
      *             ALSO GENERATES FLAT FILE OUTPUT (OUTFILE DD)     *
      *             FOR ELECTRONIC SUBMISSION TO MANUFACTURER.       *
      *                                                              *
      * INPUT:      REPORT MONTH (YYYY-MM)                           *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.CUSTOMER       (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
      *             AUTOSALE.INCENTIVE_APPLIED (READ)                *
      *                                                              *
      * OUTPUT:     SYSPRINT DD - PRINTED REPORT (132 CHARS)         *
      *             OUTFILE  DD - FLAT FILE FOR SUBMISSION            *
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
               FILE STATUS IS WS-RPT-STATUS.
           SELECT OUT-FILE
               ASSIGN TO OUTFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.
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
       FD  OUT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 200 CHARACTERS.
       01  OUT-RECORD                  PIC X(200).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTMFG00'.
       01  WS-RPT-STATUS               PIC X(02) VALUE SPACES.
       01  WS-OUT-STATUS               PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    REPORT CONTROL FIELDS
      *
       01  WS-REPORT-CONTROLS.
           05  WS-PAGE-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-LINE-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-LINES-PER-PAGE       PIC S9(04) COMP VALUE +56.
           05  WS-DETAIL-COUNT         PIC S9(08) COMP VALUE +0.
           05  WS-FLAT-COUNT           PIC S9(08) COMP VALUE +0.
           05  WS-EOF-FLAG             PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA                VALUE 'Y'.
           05  WS-EOF-SUMM            PIC X(01) VALUE 'N'.
               88  WS-SUMM-DONE                 VALUE 'Y'.
      *
      *    INPUT PARAMETERS
      *
       01  WS-PARM-AREA.
           05  WS-REPORT-MONTH        PIC X(07) VALUE SPACES.
           05  WS-MONTH-START         PIC X(10) VALUE SPACES.
           05  WS-MONTH-END           PIC X(10) VALUE SPACES.
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
       01  WS-HV-DETAIL.
           05  WS-HV-VIN              PIC X(17).
           05  WS-HV-DELIVERY-DATE    PIC X(10).
           05  WS-HV-CUST-STATE       PIC X(02).
           05  WS-HV-TOTAL-PRICE      PIC S9(09)V99 COMP-3.
           05  WS-HV-DEAL-TYPE        PIC X(02).
           05  WS-HV-MODEL-YEAR       PIC X(04).
           05  WS-HV-MODEL-CODE       PIC X(06).
           05  WS-HV-MODEL-DESC       PIC X(30).
           05  WS-HV-DEALER-CODE      PIC X(05).
           05  WS-HV-INCENTIVE-AMT    PIC S9(09)V99 COMP-3.
           05  WS-HV-INCENTIVE-CODE   PIC X(10).
      *
       01  WS-HV-SUMMARY.
           05  WS-HV-SUM-MODEL-CODE   PIC X(06).
           05  WS-HV-SUM-MODEL-DESC   PIC X(30).
           05  WS-HV-SUM-UNITS        PIC S9(06) COMP.
           05  WS-HV-SUM-INCENTIVES   PIC S9(11)V99 COMP-3.
      *
      *    REPORT LINES
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(35)
               VALUE 'MANUFACTURER COMPLIANCE REPORT       '.
           05  FILLER                  PIC X(06) VALUE 'PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(45) VALUE SPACES.
      *
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-MONTH-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(17)
               VALUE 'REPORTING MONTH: '.
           05  WS-ML-MONTH            PIC X(07).
           05  FILLER                  PIC X(107) VALUE SPACES.
      *
       01  WS-COLUMN-HEADERS.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(18) VALUE
               'VIN              '.
           05  FILLER                  PIC X(06) VALUE
               'DEALER'.
           05  FILLER                  PIC X(11) VALUE
               'DEAL DATE  '.
           05  FILLER                  PIC X(03) VALUE 'ST '.
           05  FILLER                  PIC X(05) VALUE 'YEAR '.
           05  FILLER                  PIC X(07) VALUE 'MODEL  '.
           05  FILLER                  PIC X(21) VALUE
               'MODEL DESCRIPTION    '.
           05  FILLER                  PIC X(03) VALUE 'TYP'.
           05  FILLER                  PIC X(16) VALUE
               '    SALE PRICE  '.
           05  FILLER                  PIC X(11) VALUE
               'INCENTIVE  '.
           05  FILLER                  PIC X(16) VALUE
               '   INCENT AMT   '.
           05  FILLER                  PIC X(14) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-VIN              PIC X(17).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DEALER           PIC X(05).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DEAL-DATE        PIC X(10).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-STATE            PIC X(02).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-YEAR             PIC X(04).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-MODEL-CODE       PIC X(06).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-MODEL-DESC       PIC X(20).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DEAL-TYPE        PIC X(02).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-SALE-PRICE       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-INCENT-CODE      PIC X(10).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-INCENT-AMT       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(13) VALUE SPACES.
      *
       01  WS-SUMMARY-HDR.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'MODEL SUMMARY                           '.
           05  FILLER                  PIC X(91) VALUE SPACES.
      *
       01  WS-SUMMARY-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(07) VALUE 'MODEL  '.
           05  FILLER                  PIC X(30)
               VALUE 'DESCRIPTION                   '.
           05  FILLER                  PIC X(08) VALUE '  UNITS '.
           05  FILLER                  PIC X(20)
               VALUE ' TOTAL INCENTIVES   '.
           05  FILLER                  PIC X(62) VALUE SPACES.
      *
       01  WS-SUMMARY-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-SL-MODEL-CODE       PIC X(06).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-SL-MODEL-DESC       PIC X(30).
           05  WS-SL-UNITS            PIC Z(5)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-SL-INCENTIVES       PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(62) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(37) VALUE ALL '='.
           05  WS-GT-UNITS            PIC Z(5)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-GT-INCENTIVES       PIC $$$$,$$$,$$9.99.
           05  FILLER                  PIC X(62) VALUE SPACES.
      *
      *    FLAT FILE OUTPUT RECORD
      *
       01  WS-FLAT-RECORD.
           05  WS-FR-VIN              PIC X(17).
           05  WS-FR-DEAL-DATE        PIC X(10).
           05  WS-FR-DEALER-CODE      PIC X(05).
           05  WS-FR-CUST-STATE       PIC X(02).
           05  WS-FR-MODEL-YEAR       PIC X(04).
           05  WS-FR-MODEL-CODE       PIC X(06).
           05  WS-FR-DEAL-TYPE        PIC X(02).
           05  WS-FR-SALE-PRICE       PIC 9(09)V99.
           05  WS-FR-INCENT-CODE      PIC X(10).
           05  WS-FR-INCENT-AMT       PIC 9(09)V99.
           05  FILLER                  PIC X(122) VALUE SPACES.
      *
      *    ACCUMULATORS
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-TOTAL-UNITS       PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-INCENTIVES  PIC S9(13)V99 COMP-3
                                                      VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_MFG_DETAIL CURSOR FOR
               SELECT V.VIN
                    , S.DELIVERY_DATE
                    , C.STATE_CODE
                    , S.TOTAL_PRICE
                    , S.DEAL_TYPE
                    , V.MODEL_YEAR
                    , V.MODEL_CODE
                    , V.MODEL_DESC
                    , S.DEALER_CODE
                    , COALESCE(I.INCENTIVE_AMOUNT, 0)
                    , COALESCE(I.INCENTIVE_CODE, ' ')
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   S.CUSTOMER_ID = C.CUSTOMER_ID
               LEFT OUTER JOIN AUTOSALE.INCENTIVE_APPLIED I
                 ON   S.DEAL_NUMBER = I.DEAL_NUMBER
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                          AND :WS-MONTH-END
               ORDER BY V.VIN
           END-EXEC
      *
           EXEC SQL DECLARE CSR_MFG_SUMMARY CURSOR FOR
               SELECT V.MODEL_CODE
                    , V.MODEL_DESC
                    , COUNT(*) AS UNITS
                    , COALESCE(SUM(I.INCENTIVE_AMOUNT), 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               LEFT OUTER JOIN AUTOSALE.INCENTIVE_APPLIED I
                 ON   S.DEAL_NUMBER = I.DEAL_NUMBER
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                          AND :WS-MONTH-END
               GROUP BY V.MODEL_CODE, V.MODEL_DESC
               ORDER BY V.MODEL_CODE
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTMFG00: MANUFACTURER COMPLIANCE RPT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-RPT-STATUS = '00' AND WS-OUT-STATUS = '00'
               PERFORM 3000-PRINT-HEADER
               PERFORM 4000-PROCESS-DETAIL
               PERFORM 5000-PRINT-SUMMARY
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTMFG00: COMPLETE - '
                   WS-DETAIL-COUNT ' DETAIL, '
                   WS-FLAT-COUNT ' FLAT RECORDS'
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
           EXEC SQL
               SELECT CHAR(DATE(:WS-MONTH-START)
                      + 1 MONTH - 1 DAY, ISO)
               INTO   :WS-MONTH-END
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'RPTMFG00: MONTH = ' WS-REPORT-MONTH
           INITIALIZE WS-GRAND-ACCUM
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPTMFG00: ERROR OPENING REPORT FILE'
           END-IF
      *
           OPEN OUTPUT OUT-FILE
           IF WS-OUT-STATUS NOT = '00'
               DISPLAY 'RPTMFG00: ERROR OPENING FLAT FILE'
           END-IF
           .
      *
      ****************************************************************
      *    3000-PRINT-HEADER                                         *
      ****************************************************************
       3000-PRINT-HEADER.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           MOVE WS-REPORT-MONTH TO WS-ML-MONTH
           WRITE REPORT-RECORD FROM WS-MONTH-LINE
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-COLUMN-HEADERS
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-COLUMN-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 9 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    4000-PROCESS-DETAIL                                       *
      ****************************************************************
       4000-PROCESS-DETAIL.
      *
           EXEC SQL OPEN CSR_MFG_DETAIL END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTMFG00: ERROR OPENING DETAIL CURSOR'
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_MFG_DETAIL
                   INTO :WS-HV-VIN
                      , :WS-HV-DELIVERY-DATE
                      , :WS-HV-CUST-STATE
                      , :WS-HV-TOTAL-PRICE
                      , :WS-HV-DEAL-TYPE
                      , :WS-HV-MODEL-YEAR
                      , :WS-HV-MODEL-CODE
                      , :WS-HV-MODEL-DESC
                      , :WS-HV-DEALER-CODE
                      , :WS-HV-INCENTIVE-AMT
                      , :WS-HV-INCENTIVE-CODE
               END-EXEC
      *
               IF SQLCODE = +0
                   PERFORM 4100-PRINT-DETAIL-LINE
                   PERFORM 4200-WRITE-FLAT-RECORD
               ELSE
                   SET WS-END-OF-DATA TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_MFG_DETAIL END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-PRINT-DETAIL-LINE                                    *
      ****************************************************************
       4100-PRINT-DETAIL-LINE.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 3000-PRINT-HEADER
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
           MOVE WS-HV-VIN           TO WS-DL-VIN
           MOVE WS-HV-DEALER-CODE   TO WS-DL-DEALER
           MOVE WS-HV-DELIVERY-DATE TO WS-DL-DEAL-DATE
           MOVE WS-HV-CUST-STATE    TO WS-DL-STATE
           MOVE WS-HV-MODEL-YEAR    TO WS-DL-YEAR
           MOVE WS-HV-MODEL-CODE    TO WS-DL-MODEL-CODE
           MOVE WS-HV-MODEL-DESC(1:20) TO WS-DL-MODEL-DESC
           MOVE WS-HV-DEAL-TYPE     TO WS-DL-DEAL-TYPE
           MOVE WS-HV-TOTAL-PRICE   TO WS-DL-SALE-PRICE
           MOVE WS-HV-INCENTIVE-CODE TO WS-DL-INCENT-CODE
           MOVE WS-HV-INCENTIVE-AMT  TO WS-DL-INCENT-AMT
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    4200-WRITE-FLAT-RECORD                                    *
      ****************************************************************
       4200-WRITE-FLAT-RECORD.
      *
           INITIALIZE WS-FLAT-RECORD
           MOVE WS-HV-VIN           TO WS-FR-VIN
           MOVE WS-HV-DELIVERY-DATE TO WS-FR-DEAL-DATE
           MOVE WS-HV-DEALER-CODE   TO WS-FR-DEALER-CODE
           MOVE WS-HV-CUST-STATE    TO WS-FR-CUST-STATE
           MOVE WS-HV-MODEL-YEAR    TO WS-FR-MODEL-YEAR
           MOVE WS-HV-MODEL-CODE    TO WS-FR-MODEL-CODE
           MOVE WS-HV-DEAL-TYPE     TO WS-FR-DEAL-TYPE
           MOVE WS-HV-TOTAL-PRICE   TO WS-FR-SALE-PRICE
           MOVE WS-HV-INCENTIVE-CODE TO WS-FR-INCENT-CODE
           MOVE WS-HV-INCENTIVE-AMT  TO WS-FR-INCENT-AMT
      *
           WRITE OUT-RECORD FROM WS-FLAT-RECORD
           ADD +1 TO WS-FLAT-COUNT
           .
      *
      ****************************************************************
      *    5000-PRINT-SUMMARY                                        *
      ****************************************************************
       5000-PRINT-SUMMARY.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           WRITE REPORT-RECORD FROM WS-SUMMARY-HDR
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-SUMMARY-COL-HDR
               AFTER ADVANCING 2
           MOVE 8 TO WS-LINE-COUNT
      *
           EXEC SQL OPEN CSR_MFG_SUMMARY END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTMFG00: ERROR OPENING SUMMARY CURSOR'
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-SUMM
      *
           PERFORM UNTIL WS-SUMM-DONE
               EXEC SQL FETCH CSR_MFG_SUMMARY
                   INTO :WS-HV-SUM-MODEL-CODE
                      , :WS-HV-SUM-MODEL-DESC
                      , :WS-HV-SUM-UNITS
                      , :WS-HV-SUM-INCENTIVES
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE WS-HV-SUM-MODEL-CODE TO WS-SL-MODEL-CODE
                   MOVE WS-HV-SUM-MODEL-DESC(1:30)
                       TO WS-SL-MODEL-DESC
                   MOVE WS-HV-SUM-UNITS TO WS-SL-UNITS
                   MOVE WS-HV-SUM-INCENTIVES TO WS-SL-INCENTIVES
      *
                   WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
                       AFTER ADVANCING 1
                   ADD +1 TO WS-LINE-COUNT
      *
                   ADD WS-HV-SUM-UNITS
                       TO WS-GA-TOTAL-UNITS
                   ADD WS-HV-SUM-INCENTIVES
                       TO WS-GA-TOTAL-INCENTIVES
               ELSE
                   SET WS-SUMM-DONE TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_MFG_SUMMARY END-EXEC
      *
      *    GRAND TOTALS
      *
           MOVE WS-GA-TOTAL-UNITS      TO WS-GT-UNITS
           MOVE WS-GA-TOTAL-INCENTIVES TO WS-GT-INCENTIVES
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 2
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE REPORT-FILE
           CLOSE OUT-FILE
           .
      ****************************************************************
      * END OF RPTMFG00                                              *
      ****************************************************************
