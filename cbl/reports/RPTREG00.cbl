       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTREG00.
      ****************************************************************
      * PROGRAM:    RPTREG00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    REGISTRATION STATUS REPORT. SHOWS PENDING AND    *
      *             COMPLETED REGISTRATIONS BY STATE. DETAIL LINE    *
      *             FOR EACH REGISTRATION WITH REG ID, DEAL#, VIN,  *
      *             CUSTOMER, STATE, STATUS, SUBMIT DATE, AND DAYS  *
      *             PENDING. SUBTOTALS PER STATE WITH PENDING AND   *
      *             COMPLETED COUNTS AND AVG DAYS TO COMPLETE.      *
      *             GRAND TOTALS ACROSS ALL STATES.                 *
      *                                                              *
      * INPUT:      REPORT DATE PARAMETER (DEFAULT CURRENT DATE)     *
      *                                                              *
      * TABLES:     AUTOSALE.REGISTRATION   (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.CUSTOMER       (READ)                   *
      *             AUTOSALE.SALES_DEAL     (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTREG00'.
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
           05  WS-STATE-COUNT          PIC S9(04) COMP VALUE +0.
           05  WS-EOF-STATE            PIC X(01) VALUE 'N'.
               88  WS-STATES-DONE               VALUE 'Y'.
           05  WS-EOF-REG              PIC X(01) VALUE 'N'.
               88  WS-REGS-DONE                 VALUE 'Y'.
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
               VALUE '  REGISTRATION STATUS REPORT  '.
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
       01  WS-STATE-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(09) VALUE 'STATE:   '.
           05  WS-SH-STATE-CODE       PIC X(02).
           05  FILLER                  PIC X(120) VALUE SPACES.
      *
       01  WS-COLUMN-HEADERS.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(14) VALUE
               'REG ID        '.
           05  FILLER                  PIC X(12) VALUE
               'DEAL #    '.
           05  FILLER                  PIC X(19) VALUE
               'VIN               '.
           05  FILLER                  PIC X(22) VALUE
               'CUSTOMER              '.
           05  FILLER                  PIC X(10) VALUE
               'STATUS    '.
           05  FILLER                  PIC X(08) VALUE
               'REG TYP '.
           05  FILLER                  PIC X(12) VALUE
               'SUBMIT DATE '.
           05  FILLER                  PIC X(08) VALUE
               'DAYS PND'.
           05  FILLER                  PIC X(26) VALUE SPACES.
      *
       01  WS-COLUMN-UNDERLINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(14) VALUE
               '------------ '.
           05  FILLER                  PIC X(12) VALUE
               '---------- '.
           05  FILLER                  PIC X(19) VALUE
               '----------------- '.
           05  FILLER                  PIC X(22) VALUE
               '--------------------- '.
           05  FILLER                  PIC X(10) VALUE
               '--------- '.
           05  FILLER                  PIC X(08) VALUE
               '------- '.
           05  FILLER                  PIC X(12) VALUE
               '----------- '.
           05  FILLER                  PIC X(08) VALUE
               '--------'.
           05  FILLER                  PIC X(26) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-REG-ID           PIC X(12).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-DEAL-NUMBER      PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-VIN              PIC X(17).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-CUST-NAME        PIC X(21).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-STATUS           PIC X(09).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-REG-TYPE         PIC X(07).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-SUBMIT-DATE      PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DL-DAYS-PENDING     PIC Z(4)9.
           05  FILLER                  PIC X(19) VALUE SPACES.
      *
       01  WS-SUBTOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '-'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'STATE TOTALS:   '.
           05  WS-ST-TOTAL-COUNT       PIC Z(4)9.
           05  FILLER                  PIC X(07) VALUE ' REGS  '.
           05  FILLER                  PIC X(59) VALUE SPACES.
      *
       01  WS-SUB-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(11)
               VALUE 'PENDING:   '.
           05  WS-SD-PENDING           PIC Z(4)9.
           05  FILLER                  PIC X(14)
               VALUE '   COMPLETED: '.
           05  WS-SD-COMPLETED         PIC Z(4)9.
           05  FILLER                  PIC X(14)
               VALUE '   ISSUED:    '.
           05  WS-SD-ISSUED            PIC Z(4)9.
           05  FILLER                  PIC X(14)
               VALUE '   REJECTED:  '.
           05  WS-SD-REJECTED          PIC Z(4)9.
           05  FILLER                  PIC X(42) VALUE SPACES.
      *
       01  WS-SUB-AVG-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(24)
               VALUE 'AVG DAYS TO COMPLETE:   '.
           05  WS-SA-AVG-DAYS          PIC ZZ,ZZ9.9.
           05  FILLER                  PIC X(90) VALUE SPACES.
      *
       01  WS-GRAND-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(43) VALUE ALL '='.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'GRAND TOTALS:   '.
           05  WS-GT-TOTAL-COUNT       PIC Z(5)9.
           05  FILLER                  PIC X(07) VALUE ' REGS  '.
           05  FILLER                  PIC X(58) VALUE SPACES.
      *
       01  WS-GRAND-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(11)
               VALUE 'PENDING:   '.
           05  WS-GD-PENDING           PIC Z(4)9.
           05  FILLER                  PIC X(14)
               VALUE '   COMPLETED: '.
           05  WS-GD-COMPLETED         PIC Z(4)9.
           05  FILLER                  PIC X(14)
               VALUE '   ISSUED:    '.
           05  WS-GD-ISSUED            PIC Z(4)9.
           05  FILLER                  PIC X(14)
               VALUE '   REJECTED:  '.
           05  WS-GD-REJECTED          PIC Z(4)9.
           05  FILLER                  PIC X(42) VALUE SPACES.
      *
       01  WS-GRAND-AVG-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(24)
               VALUE 'AVG DAYS TO COMPLETE:   '.
           05  WS-GA-AVG-DAYS          PIC ZZ,ZZ9.9.
           05  FILLER                  PIC X(12)
               VALUE '   STATES:  '.
           05  WS-GA-ST-COUNT          PIC Z(4)9.
           05  FILLER                  PIC X(68) VALUE SPACES.
      *
      *    ACCUMULATOR FIELDS - PER STATE
      *
       01  WS-STATE-ACCUM.
           05  WS-SA-TOTAL-COUNT       PIC S9(06) COMP VALUE +0.
           05  WS-SA-PENDING-COUNT     PIC S9(06) COMP VALUE +0.
           05  WS-SA-COMPLETED-COUNT   PIC S9(06) COMP VALUE +0.
           05  WS-SA-ISSUED-COUNT      PIC S9(06) COMP VALUE +0.
           05  WS-SA-REJECTED-COUNT    PIC S9(06) COMP VALUE +0.
           05  WS-SA-TOTAL-COMP-DAYS   PIC S9(09) COMP VALUE +0.
      *
      *    GRAND ACCUMULATORS
      *
       01  WS-GRAND-ACCUM.
           05  WS-GA-TOTAL-COUNT       PIC S9(08) COMP VALUE +0.
           05  WS-GA-PENDING-COUNT     PIC S9(08) COMP VALUE +0.
           05  WS-GA-COMPLETED-COUNT   PIC S9(08) COMP VALUE +0.
           05  WS-GA-ISSUED-COUNT      PIC S9(08) COMP VALUE +0.
           05  WS-GA-REJECTED-COUNT    PIC S9(08) COMP VALUE +0.
           05  WS-GA-TOTAL-COMP-DAYS   PIC S9(11) COMP VALUE +0.
           05  WS-GA-STATE-COUNT       PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - STATE CURSOR
      *
       01  WS-HV-STATE.
           05  WS-HV-REG-STATE        PIC X(02).
      *
      *    HOST VARIABLES - REGISTRATION CURSOR
      *
       01  WS-HV-REG.
           05  WS-HV-REG-ID           PIC X(12).
           05  WS-HV-DEAL-NUMBER      PIC X(10).
           05  WS-HV-VIN              PIC X(17).
           05  WS-HV-CUST-LAST        PIC X(25).
           05  WS-HV-CUST-FIRST       PIC X(15).
           05  WS-HV-REG-STATUS       PIC X(02).
           05  WS-HV-REG-TYPE         PIC X(02).
           05  WS-HV-SUBMIT-DATE      PIC X(10).
           05  WS-HV-DAYS-PENDING     PIC S9(06) COMP.
           05  WS-HV-DAYS-COMPLETE    PIC S9(06) COMP.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-STATUS-DESC         PIC X(09) VALUE SPACES.
           05  WS-TYPE-DESC           PIC X(07) VALUE SPACES.
           05  WS-CUST-FULL-NAME      PIC X(21) VALUE SPACES.
           05  WS-AVG-WORK            PIC S9(07)V9 COMP-3
                                                    VALUE +0.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_REG_STATES CURSOR FOR
               SELECT DISTINCT R.REG_STATE
               FROM   AUTOSALE.REGISTRATION R
               WHERE  R.REG_STATUS NOT IN ('IS')
                  OR  R.ISSUED_DATE >= DATE(:WS-REPORT-DATE)
                                     - 30 DAYS
               ORDER BY R.REG_STATE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_REG_DETAILS CURSOR FOR
               SELECT R.REG_ID
                    , R.DEAL_NUMBER
                    , R.VIN
                    , C.LAST_NAME
                    , C.FIRST_NAME
                    , R.REG_STATUS
                    , R.REG_TYPE
                    , COALESCE(CHAR(R.SUBMISSION_DATE, ISO),
                               '          ')
                    , CASE WHEN R.REG_STATUS
                           NOT IN ('IS', 'RJ')
                           AND R.SUBMISSION_DATE IS NOT NULL
                      THEN DAYS(DATE(:WS-REPORT-DATE))
                         - DAYS(R.SUBMISSION_DATE)
                      ELSE 0 END
                    , CASE WHEN R.REG_STATUS = 'IS'
                           AND R.ISSUED_DATE IS NOT NULL
                           AND R.SUBMISSION_DATE IS NOT NULL
                      THEN DAYS(R.ISSUED_DATE)
                         - DAYS(R.SUBMISSION_DATE)
                      ELSE 0 END
               FROM   AUTOSALE.REGISTRATION R
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   R.CUSTOMER_ID = C.CUSTOMER_ID
               WHERE  R.REG_STATE = :WS-HV-REG-STATE
                 AND  (R.REG_STATUS NOT IN ('IS')
                  OR   R.ISSUED_DATE >= DATE(:WS-REPORT-DATE)
                                      - 30 DAYS)
               ORDER BY R.REG_STATUS, R.SUBMISSION_DATE,
                        R.REG_ID
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTREG00: REGISTRATION STATUS REPORT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 3000-PROCESS-STATES
               PERFORM 7000-PRINT-GRAND-TOTALS
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTREG00: REPORT COMPLETE - '
                   WS-GA-TOTAL-COUNT ' REGS, '
                   WS-GA-STATE-COUNT ' STATES'
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
           DISPLAY 'RPTREG00: REPORT DATE = ' WS-REPORT-DATE
      *
           INITIALIZE WS-STATE-ACCUM
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
               DISPLAY 'RPTREG00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-STATES                                       *
      ****************************************************************
       3000-PROCESS-STATES.
      *
           EXEC SQL OPEN CSR_REG_STATES END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTREG00: ERROR OPENING STATE CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-STATE
      *
           PERFORM UNTIL WS-STATES-DONE
               EXEC SQL FETCH CSR_REG_STATES
                   INTO :WS-HV-REG-STATE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-GA-STATE-COUNT
                       PERFORM 4000-NEW-STATE-PAGE
                       PERFORM 5000-PROCESS-REGS
                       PERFORM 6000-PRINT-STATE-SUBTOTAL
                   WHEN +100
                       SET WS-STATES-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTREG00: DB2 ERROR ON STATE - '
                               SQLCODE
                       SET WS-STATES-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_REG_STATES END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-NEW-STATE-PAGE - START NEW PAGE FOR EACH STATE       *
      ****************************************************************
       4000-NEW-STATE-PAGE.
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
           MOVE WS-HV-REG-STATE TO WS-SH-STATE-CODE
           WRITE REPORT-RECORD FROM WS-STATE-HEADER
               AFTER ADVANCING 2
      *
           WRITE REPORT-RECORD FROM WS-COLUMN-HEADERS
               AFTER ADVANCING 2
           WRITE REPORT-RECORD FROM WS-COLUMN-UNDERLINE
               AFTER ADVANCING 1
      *
           MOVE 10 TO WS-LINE-COUNT
      *
           INITIALIZE WS-STATE-ACCUM
           .
      *
      ****************************************************************
      *    5000-PROCESS-REGS - DETAIL LINES FOR EACH REG             *
      ****************************************************************
       5000-PROCESS-REGS.
      *
           EXEC SQL OPEN CSR_REG_DETAILS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTREG00: ERROR OPENING REG CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-REG
      *
           PERFORM UNTIL WS-REGS-DONE
               EXEC SQL FETCH CSR_REG_DETAILS
                   INTO :WS-HV-REG-ID
                      , :WS-HV-DEAL-NUMBER
                      , :WS-HV-VIN
                      , :WS-HV-CUST-LAST
                      , :WS-HV-CUST-FIRST
                      , :WS-HV-REG-STATUS
                      , :WS-HV-REG-TYPE
                      , :WS-HV-SUBMIT-DATE
                      , :WS-HV-DAYS-PENDING
                      , :WS-HV-DAYS-COMPLETE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-FORMAT-DETAIL
                   WHEN +100
                       SET WS-REGS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'RPTREG00: DB2 ERROR ON REG - '
                               SQLCODE
                       SET WS-REGS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_REG_DETAILS END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FORMAT-DETAIL - FORMAT AND PRINT ONE REG LINE        *
      ****************************************************************
       5100-FORMAT-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 4000-NEW-STATE-PAGE
           END-IF
      *
           INITIALIZE WS-DETAIL-LINE
      *
           MOVE WS-HV-REG-ID      TO WS-DL-REG-ID
           MOVE WS-HV-DEAL-NUMBER TO WS-DL-DEAL-NUMBER
           MOVE WS-HV-VIN         TO WS-DL-VIN
      *
           MOVE SPACES TO WS-CUST-FULL-NAME
           STRING WS-HV-CUST-LAST DELIMITED BY '  '
                  ', ' DELIMITED BY SIZE
                  WS-HV-CUST-FIRST DELIMITED BY '  '
                  INTO WS-CUST-FULL-NAME
           MOVE WS-CUST-FULL-NAME TO WS-DL-CUST-NAME
      *
           EVALUATE WS-HV-REG-STATUS
               WHEN 'PR'
                   MOVE 'PREPARING' TO WS-DL-STATUS
               WHEN 'VL'
                   MOVE 'VALIDATED' TO WS-DL-STATUS
               WHEN 'SB'
                   MOVE 'SUBMITTED' TO WS-DL-STATUS
               WHEN 'PG'
                   MOVE 'PROCESSIN' TO WS-DL-STATUS
               WHEN 'IS'
                   MOVE 'ISSUED   ' TO WS-DL-STATUS
               WHEN 'RJ'
                   MOVE 'REJECTED ' TO WS-DL-STATUS
               WHEN 'ER'
                   MOVE 'ERROR    ' TO WS-DL-STATUS
               WHEN OTHER
                   MOVE WS-HV-REG-STATUS TO WS-DL-STATUS
           END-EVALUATE
      *
           EVALUATE WS-HV-REG-TYPE
               WHEN 'NW'
                   MOVE 'NEW    ' TO WS-DL-REG-TYPE
               WHEN 'TF'
                   MOVE 'TRANSFE' TO WS-DL-REG-TYPE
               WHEN 'RN'
                   MOVE 'RENEWAL' TO WS-DL-REG-TYPE
               WHEN 'DP'
                   MOVE 'DUPLICA' TO WS-DL-REG-TYPE
               WHEN OTHER
                   MOVE WS-HV-REG-TYPE TO WS-DL-REG-TYPE
           END-EVALUATE
      *
           MOVE WS-HV-SUBMIT-DATE TO WS-DL-SUBMIT-DATE
           MOVE WS-HV-DAYS-PENDING TO WS-DL-DAYS-PENDING
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
      *    ACCUMULATE
      *
           ADD +1 TO WS-SA-TOTAL-COUNT
           ADD +1 TO WS-GA-TOTAL-COUNT
      *
           EVALUATE WS-HV-REG-STATUS
               WHEN 'PR'
               WHEN 'VL'
               WHEN 'SB'
               WHEN 'PG'
                   ADD +1 TO WS-SA-PENDING-COUNT
                   ADD +1 TO WS-GA-PENDING-COUNT
               WHEN 'IS'
                   ADD +1 TO WS-SA-ISSUED-COUNT
                   ADD +1 TO WS-GA-ISSUED-COUNT
                   ADD +1 TO WS-SA-COMPLETED-COUNT
                   ADD +1 TO WS-GA-COMPLETED-COUNT
                   ADD WS-HV-DAYS-COMPLETE
                       TO WS-SA-TOTAL-COMP-DAYS
                   ADD WS-HV-DAYS-COMPLETE
                       TO WS-GA-TOTAL-COMP-DAYS
               WHEN 'RJ'
               WHEN 'ER'
                   ADD +1 TO WS-SA-REJECTED-COUNT
                   ADD +1 TO WS-GA-REJECTED-COUNT
           END-EVALUATE
      *
           ADD +1 TO WS-DETAIL-COUNT
           .
      *
      ****************************************************************
      *    6000-PRINT-STATE-SUBTOTAL                                 *
      ****************************************************************
       6000-PRINT-STATE-SUBTOTAL.
      *
           MOVE WS-SA-TOTAL-COUNT TO WS-ST-TOTAL-COUNT
      *
           WRITE REPORT-RECORD FROM WS-SUBTOTAL-LINE
               AFTER ADVANCING 2
      *
           MOVE WS-SA-PENDING-COUNT   TO WS-SD-PENDING
           MOVE WS-SA-COMPLETED-COUNT TO WS-SD-COMPLETED
           MOVE WS-SA-ISSUED-COUNT    TO WS-SD-ISSUED
           MOVE WS-SA-REJECTED-COUNT  TO WS-SD-REJECTED
      *
           WRITE REPORT-RECORD FROM WS-SUB-DETAIL-LINE
               AFTER ADVANCING 1
      *
      *    AVERAGE DAYS TO COMPLETE
      *
           IF WS-SA-COMPLETED-COUNT > +0
               COMPUTE WS-AVG-WORK =
                   WS-SA-TOTAL-COMP-DAYS
                   / WS-SA-COMPLETED-COUNT
           ELSE
               MOVE +0 TO WS-AVG-WORK
           END-IF
           MOVE WS-AVG-WORK TO WS-SA-AVG-DAYS
      *
           WRITE REPORT-RECORD FROM WS-SUB-AVG-LINE
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    7000-PRINT-GRAND-TOTALS                                   *
      ****************************************************************
       7000-PRINT-GRAND-TOTALS.
      *
           MOVE WS-GA-TOTAL-COUNT TO WS-GT-TOTAL-COUNT
      *
           WRITE REPORT-RECORD FROM WS-GRAND-TOTAL-LINE
               AFTER ADVANCING 3
      *
           MOVE WS-GA-PENDING-COUNT   TO WS-GD-PENDING
           MOVE WS-GA-COMPLETED-COUNT TO WS-GD-COMPLETED
           MOVE WS-GA-ISSUED-COUNT    TO WS-GD-ISSUED
           MOVE WS-GA-REJECTED-COUNT  TO WS-GD-REJECTED
      *
           WRITE REPORT-RECORD FROM WS-GRAND-DETAIL-LINE
               AFTER ADVANCING 1
      *
      *    GRAND AVERAGE DAYS TO COMPLETE
      *
           IF WS-GA-COMPLETED-COUNT > +0
               COMPUTE WS-AVG-WORK =
                   WS-GA-TOTAL-COMP-DAYS
                   / WS-GA-COMPLETED-COUNT
           ELSE
               MOVE +0 TO WS-AVG-WORK
           END-IF
           MOVE WS-AVG-WORK TO WS-GA-AVG-DAYS
           MOVE WS-GA-STATE-COUNT TO WS-GA-ST-COUNT
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
               DISPLAY 'RPTREG00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF RPTREG00                                              *
      ****************************************************************
