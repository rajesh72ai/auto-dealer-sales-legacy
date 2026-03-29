       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTCOM00.
      ****************************************************************
      * PROGRAM:    RPTCOM00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     RPT - REPORTS                                    *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    COMMISSION STATEMENT REPORT. ONE PAGE PER        *
      *             SALESPERSON PER DEALER. DETAIL: EACH DEAL WITH   *
      *             DEAL#, CUSTOMER, VEHICLE, FRONT GROSS, BACK      *
      *             GROSS, COMMISSION RATE, COMMISSION AMOUNT.       *
      *             SUBTOTALS: TOTAL DEALS, TOTAL GROSS, TOTAL       *
      *             COMMISSION. SHOWS COMMISSION TIERS FROM          *
      *             SYSTEM_CONFIG (E.G., 25% UP TO $2000 GROSS,      *
      *             30% ABOVE).                                      *
      *                                                              *
      * INPUT:      REPORT MONTH (YYYY-MM)                           *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ)                   *
      *             AUTOSALE.VEHICLE        (READ)                   *
      *             AUTOSALE.CUSTOMER       (READ)                   *
      *             AUTOSALE.DEALER         (READ)                   *
      *             AUTOSALE.SALESPERSON    (READ)                   *
      *             AUTOSALE.FI_DEAL_PRODUCT (READ)                  *
      *             AUTOSALE.SYSTEM_CONFIG  (READ)                   *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'RPTCOM00'.
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
           05  WS-EOF-SP               PIC X(01) VALUE 'N'.
               88  WS-SP-DONE                    VALUE 'Y'.
           05  WS-EOF-DEAL             PIC X(01) VALUE 'N'.
               88  WS-DEALS-DONE                 VALUE 'Y'.
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
      *    COMMISSION TIERS (FROM SYSTEM_CONFIG)
      *
       01  WS-MAX-TIERS                PIC S9(04) COMP VALUE +5.
       01  WS-TIER-COUNT               PIC S9(04) COMP VALUE +0.
       01  WS-COMMISSION-TIERS.
           05  WS-TIER-ENTRY OCCURS 5 TIMES.
               10  WS-CT-MIN-GROSS     PIC S9(09)V99 COMP-3
                                                      VALUE +0.
               10  WS-CT-MAX-GROSS     PIC S9(09)V99 COMP-3
                                                      VALUE +0.
               10  WS-CT-RATE          PIC S9(02)V9(04) COMP-3
                                                      VALUE +0.
      *
      *    HOST VARIABLES
      *
       01  WS-HV-SALESPERSON.
           05  WS-HV-SP-ID            PIC X(08).
           05  WS-HV-SP-NAME          PIC X(30).
           05  WS-HV-SP-DLR-CODE      PIC X(05).
           05  WS-HV-SP-DLR-NAME      PIC X(40).
      *
       01  WS-HV-DEAL.
           05  WS-HV-DEAL-NUMBER      PIC X(10).
           05  WS-HV-CUST-NAME        PIC X(30).
           05  WS-HV-MODEL-YEAR       PIC X(04).
           05  WS-HV-MODEL-DESC       PIC X(20).
           05  WS-HV-FRONT-GROSS      PIC S9(09)V99 COMP-3.
           05  WS-HV-BACK-GROSS       PIC S9(09)V99 COMP-3.
      *
       01  WS-HV-CONFIG.
           05  WS-HV-CFG-MIN          PIC S9(09)V99 COMP-3.
           05  WS-HV-CFG-MAX          PIC S9(09)V99 COMP-3.
           05  WS-HV-CFG-RATE         PIC S9(02)V9(04) COMP-3.
      *
      *    ACCUMULATORS
      *
       01  WS-SP-ACCUM.
           05  WS-SPA-DEAL-COUNT       PIC S9(06) COMP VALUE +0.
           05  WS-SPA-FRONT-GROSS      PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-SPA-BACK-GROSS       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-SPA-TOTAL-COMM       PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-TOTAL-GROSS         PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-COMM-RATE           PIC S9(02)V9(04) COMP-3
                                                     VALUE +0.
           05  WS-COMM-AMOUNT         PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-IDX                  PIC S9(04) COMP VALUE +0.
      *
      *    REPORT LINES
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE '   COMMISSION STATEMENT       '.
           05  FILLER                  PIC X(08) VALUE 'MONTH:  '.
           05  WS-RH1-MONTH           PIC X(07).
           05  FILLER                  PIC X(08) VALUE '  PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(33) VALUE SPACES.
      *
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-SP-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(14)
               VALUE 'SALESPERSON:  '.
           05  WS-SH-SP-NAME          PIC X(30).
           05  FILLER                  PIC X(06) VALUE '  ID: '.
           05  WS-SH-SP-ID            PIC X(08).
           05  FILLER                  PIC X(10)
               VALUE '  DEALER: '.
           05  WS-SH-DLR-CODE         PIC X(05).
           05  FILLER                  PIC X(03) VALUE ' - '.
           05  WS-SH-DLR-NAME         PIC X(30).
           05  FILLER                  PIC X(25) VALUE SPACES.
      *
       01  WS-TIER-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(50)
               VALUE 'COMMISSION TIERS:                                '.
           05  FILLER                  PIC X(81) VALUE SPACES.
      *
       01  WS-TIER-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-TL-LABEL            PIC X(30).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-TL-RATE             PIC ZZ9.99.
           05  FILLER                  PIC X(01) VALUE '%'.
           05  FILLER                  PIC X(87) VALUE SPACES.
      *
       01  WS-DEAL-COL-HDR.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE
               'DEAL #    '.
           05  FILLER                  PIC X(25) VALUE
               'CUSTOMER                 '.
           05  FILLER                  PIC X(05) VALUE 'YEAR '.
           05  FILLER                  PIC X(21) VALUE
               'VEHICLE              '.
           05  FILLER                  PIC X(15) VALUE
               '  FRONT GROSS  '.
           05  FILLER                  PIC X(15) VALUE
               '  BACK GROSS   '.
           05  FILLER                  PIC X(07) VALUE
               ' RATE  '.
           05  FILLER                  PIC X(16) VALUE
               '   COMMISSION   '.
           05  FILLER                  PIC X(15) VALUE SPACES.
      *
       01  WS-DEAL-DETAIL.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DD-DEAL-NUMBER      PIC X(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-DD-CUST-NAME        PIC X(24).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DD-YEAR             PIC X(04).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DD-MODEL            PIC X(20).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DD-FRONT-GROSS      PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DD-BACK-GROSS       PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DD-COMM-RATE        PIC Z9.99.
           05  FILLER                  PIC X(02) VALUE '% '.
           05  WS-DD-COMM-AMT         PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(14) VALUE SPACES.
      *
       01  WS-SP-TOTAL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(37) VALUE ALL '-'.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-SPT-DEAL-COUNT      PIC Z(4)9.
           05  FILLER                  PIC X(07)
               VALUE ' DEALS '.
           05  WS-SPT-FRONT-GROSS     PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-SPT-BACK-GROSS      PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(08) VALUE SPACES.
           05  WS-SPT-TOTAL-COMM      PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(14) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_COM_SP CURSOR FOR
               SELECT SP.SALESPERSON_ID
                    , SP.SALESPERSON_NAME
                    , SP.DEALER_CODE
                    , D.DEALER_NAME
               FROM   AUTOSALE.SALESPERSON SP
               INNER JOIN AUTOSALE.DEALER D
                 ON   SP.DEALER_CODE = D.DEALER_CODE
               WHERE  SP.ACTIVE_FLAG = 'Y'
               ORDER BY SP.DEALER_CODE, SP.SALESPERSON_ID
           END-EXEC
      *
           EXEC SQL DECLARE CSR_COM_DEALS CURSOR FOR
               SELECT S.DEAL_NUMBER
                    , C.LAST_NAME
                    , V.MODEL_YEAR
                    , V.MODEL_DESC
                    , S.TOTAL_PRICE - V.INVOICE_PRICE
                    , COALESCE(
                        (SELECT SUM(FP.SELLING_PRICE
                                    - FP.DEALER_COST)
                         FROM AUTOSALE.FI_DEAL_PRODUCT FP
                         WHERE FP.DEAL_NUMBER = S.DEAL_NUMBER)
                      , 0)
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   S.CUSTOMER_ID = C.CUSTOMER_ID
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   S.VIN = V.VIN
               WHERE  S.SALESPERSON_ID = :WS-HV-SP-ID
                 AND  S.DEALER_CODE = :WS-HV-SP-DLR-CODE
                 AND  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                          AND :WS-MONTH-END
               ORDER BY S.DEAL_NUMBER
           END-EXEC
      *
           EXEC SQL DECLARE CSR_COM_TIERS CURSOR FOR
               SELECT CAST(CONFIG_VALUE_1 AS DECIMAL(11,2))
                    , CAST(CONFIG_VALUE_2 AS DECIMAL(11,2))
                    , CAST(CONFIG_VALUE_3 AS DECIMAL(4,4))
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_CATEGORY = 'COMMISSION'
                 AND  CONFIG_TYPE = 'TIER'
                 AND  ACTIVE_FLAG = 'Y'
               ORDER BY CAST(CONFIG_VALUE_1 AS DECIMAL(11,2))
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'RPTCOM00: COMMISSION STATEMENT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 2500-LOAD-TIERS
               PERFORM 3000-PROCESS-SALESPERSONS
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'RPTCOM00: REPORT COMPLETE'
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
           DISPLAY 'RPTCOM00: MONTH = ' WS-REPORT-MONTH
           INITIALIZE WS-COMMISSION-TIERS
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'RPTCOM00: ERROR OPENING REPORT FILE'
           END-IF
           .
      *
      ****************************************************************
      *    2500-LOAD-TIERS - READ COMMISSION TIERS FROM CONFIG       *
      ****************************************************************
       2500-LOAD-TIERS.
      *
           EXEC SQL OPEN CSR_COM_TIERS END-EXEC
      *
           IF SQLCODE NOT = +0
      *        DEFAULT TIERS IF CONFIG NOT AVAILABLE
               MOVE +1 TO WS-TIER-COUNT
               MOVE +0     TO WS-CT-MIN-GROSS(1)
               MOVE +999999 TO WS-CT-MAX-GROSS(1)
               MOVE +0.2500 TO WS-CT-RATE(1)
               GO TO 2500-EXIT
           END-IF
      *
           MOVE +0 TO WS-TIER-COUNT
           MOVE 'N' TO WS-EOF-SP
      *
           PERFORM UNTIL WS-SP-DONE
               OR WS-TIER-COUNT >= WS-MAX-TIERS
               EXEC SQL FETCH CSR_COM_TIERS
                   INTO :WS-HV-CFG-MIN
                      , :WS-HV-CFG-MAX
                      , :WS-HV-CFG-RATE
               END-EXEC
      *
               IF SQLCODE = +0
                   ADD +1 TO WS-TIER-COUNT
                   MOVE WS-HV-CFG-MIN
                       TO WS-CT-MIN-GROSS(WS-TIER-COUNT)
                   MOVE WS-HV-CFG-MAX
                       TO WS-CT-MAX-GROSS(WS-TIER-COUNT)
                   MOVE WS-HV-CFG-RATE
                       TO WS-CT-RATE(WS-TIER-COUNT)
               ELSE
                   SET WS-SP-DONE TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_COM_TIERS END-EXEC
      *
           IF WS-TIER-COUNT = +0
               MOVE +1 TO WS-TIER-COUNT
               MOVE +0     TO WS-CT-MIN-GROSS(1)
               MOVE +999999 TO WS-CT-MAX-GROSS(1)
               MOVE +0.2500 TO WS-CT-RATE(1)
           END-IF
           .
       2500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3000-PROCESS-SALESPERSONS                                 *
      ****************************************************************
       3000-PROCESS-SALESPERSONS.
      *
           EXEC SQL OPEN CSR_COM_SP END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'RPTCOM00: ERROR OPENING SP CURSOR'
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-SP
      *
           PERFORM UNTIL WS-SP-DONE
               EXEC SQL FETCH CSR_COM_SP
                   INTO :WS-HV-SP-ID
                      , :WS-HV-SP-NAME
                      , :WS-HV-SP-DLR-CODE
                      , :WS-HV-SP-DLR-NAME
               END-EXEC
      *
               IF SQLCODE = +0
                   PERFORM 4000-PROCESS-SP-DEALS
               ELSE
                   SET WS-SP-DONE TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_COM_SP END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PROCESS-SP-DEALS                                     *
      ****************************************************************
       4000-PROCESS-SP-DEALS.
      *
           INITIALIZE WS-SP-ACCUM
      *
      *    NEW PAGE FOR EACH SALESPERSON
      *
           PERFORM 8000-NEW-PAGE
      *
           MOVE WS-HV-SP-NAME     TO WS-SH-SP-NAME
           MOVE WS-HV-SP-ID       TO WS-SH-SP-ID
           MOVE WS-HV-SP-DLR-CODE TO WS-SH-DLR-CODE
           MOVE WS-HV-SP-DLR-NAME(1:30) TO WS-SH-DLR-NAME
           WRITE REPORT-RECORD FROM WS-SP-HEADER
               AFTER ADVANCING 2
      *
      *    PRINT TIER INFO
      *
           WRITE REPORT-RECORD FROM WS-TIER-HEADER
               AFTER ADVANCING 2
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-TIER-COUNT
               INITIALIZE WS-TIER-LINE
               STRING 'GROSS $'
                      WS-CT-MIN-GROSS(WS-IDX)
                      ' TO $'
                      WS-CT-MAX-GROSS(WS-IDX)
                      DELIMITED BY SIZE
                      INTO WS-TL-LABEL
               COMPUTE WS-TL-RATE =
                   WS-CT-RATE(WS-IDX) * 100
               WRITE REPORT-RECORD FROM WS-TIER-LINE
                   AFTER ADVANCING 1
           END-PERFORM
      *
           WRITE REPORT-RECORD FROM WS-DEAL-COL-HDR
               AFTER ADVANCING 2
           MOVE 14 TO WS-LINE-COUNT
      *
      *    PROCESS DEALS
      *
           EXEC SQL OPEN CSR_COM_DEALS END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEAL
      *
           PERFORM UNTIL WS-DEALS-DONE
               EXEC SQL FETCH CSR_COM_DEALS
                   INTO :WS-HV-DEAL-NUMBER
                      , :WS-HV-CUST-NAME
                      , :WS-HV-MODEL-YEAR
                      , :WS-HV-MODEL-DESC
                      , :WS-HV-FRONT-GROSS
                      , :WS-HV-BACK-GROSS
               END-EXEC
      *
               IF SQLCODE = +0
                   PERFORM 4100-CALC-COMMISSION
                   PERFORM 4200-PRINT-DEAL-LINE
               ELSE
                   SET WS-DEALS-DONE TO TRUE
               END-IF
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_COM_DEALS END-EXEC
      *
      *    PRINT SP TOTALS
      *
           PERFORM 4300-PRINT-SP-TOTALS
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-CALC-COMMISSION                                      *
      ****************************************************************
       4100-CALC-COMMISSION.
      *
           COMPUTE WS-TOTAL-GROSS =
               WS-HV-FRONT-GROSS + WS-HV-BACK-GROSS
      *
      *    FIND APPLICABLE TIER
      *
           MOVE +0.2500 TO WS-COMM-RATE
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-TIER-COUNT
               IF WS-TOTAL-GROSS >= WS-CT-MIN-GROSS(WS-IDX)
               AND WS-TOTAL-GROSS <= WS-CT-MAX-GROSS(WS-IDX)
                   MOVE WS-CT-RATE(WS-IDX) TO WS-COMM-RATE
               END-IF
           END-PERFORM
      *
           COMPUTE WS-COMM-AMOUNT =
               WS-TOTAL-GROSS * WS-COMM-RATE
           .
      *
      ****************************************************************
      *    4200-PRINT-DEAL-LINE                                      *
      ****************************************************************
       4200-PRINT-DEAL-LINE.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 8000-NEW-PAGE
               WRITE REPORT-RECORD FROM WS-SP-HEADER
                   AFTER ADVANCING 2
               WRITE REPORT-RECORD FROM WS-DEAL-COL-HDR
                   AFTER ADVANCING 2
               ADD 6 TO WS-LINE-COUNT
           END-IF
      *
           INITIALIZE WS-DEAL-DETAIL
           MOVE WS-HV-DEAL-NUMBER    TO WS-DD-DEAL-NUMBER
           MOVE WS-HV-CUST-NAME(1:24) TO WS-DD-CUST-NAME
           MOVE WS-HV-MODEL-YEAR     TO WS-DD-YEAR
           MOVE WS-HV-MODEL-DESC     TO WS-DD-MODEL
           MOVE WS-HV-FRONT-GROSS    TO WS-DD-FRONT-GROSS
           MOVE WS-HV-BACK-GROSS     TO WS-DD-BACK-GROSS
           COMPUTE WS-DD-COMM-RATE = WS-COMM-RATE * 100
           MOVE WS-COMM-AMOUNT       TO WS-DD-COMM-AMT
      *
           WRITE REPORT-RECORD FROM WS-DEAL-DETAIL
               AFTER ADVANCING 1
           ADD +1 TO WS-LINE-COUNT
      *
      *    ACCUMULATE
      *
           ADD +1 TO WS-SPA-DEAL-COUNT
           ADD WS-HV-FRONT-GROSS TO WS-SPA-FRONT-GROSS
           ADD WS-HV-BACK-GROSS  TO WS-SPA-BACK-GROSS
           ADD WS-COMM-AMOUNT    TO WS-SPA-TOTAL-COMM
           .
      *
      ****************************************************************
      *    4300-PRINT-SP-TOTALS                                      *
      ****************************************************************
       4300-PRINT-SP-TOTALS.
      *
           MOVE WS-SPA-DEAL-COUNT  TO WS-SPT-DEAL-COUNT
           MOVE WS-SPA-FRONT-GROSS TO WS-SPT-FRONT-GROSS
           MOVE WS-SPA-BACK-GROSS  TO WS-SPT-BACK-GROSS
           MOVE WS-SPA-TOTAL-COMM  TO WS-SPT-TOTAL-COMM
      *
           WRITE REPORT-RECORD FROM WS-SP-TOTAL-LINE
               AFTER ADVANCING 2
           .
      *
      ****************************************************************
      *    8000-NEW-PAGE                                             *
      ****************************************************************
       8000-NEW-PAGE.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT    TO WS-RH1-PAGE
           MOVE WS-REPORT-MONTH  TO WS-RH1-MONTH
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
               DISPLAY 'RPTCOM00: ERROR CLOSING REPORT FILE'
           END-IF
           .
      ****************************************************************
      * END OF RPTCOM00                                              *
      ****************************************************************
