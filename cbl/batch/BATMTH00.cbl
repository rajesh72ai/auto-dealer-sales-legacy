       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATMTH00.
      ****************************************************************
      * PROGRAM:    BATMTH00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    MONTHLY CLOSE PROCESSING. RUNS ON THE LAST       *
      *             BUSINESS DAY OF EACH MONTH TO:                   *
      *             1. CALCULATE DEALER MONTH-END STATISTICS AND     *
      *                INSERT INTO MONTHLY_SNAPSHOT TABLE             *
      *             2. ROLL MONTHLY COUNTERS (RESET SOLD_MTD ON      *
      *                STOCK_POSITION)                                *
      *             3. ARCHIVE COMPLETED DEALS OLDER THAN 18 MONTHS  *
      *                FROM SALES_DEAL INTO SALES_DEAL_ARCHIVE       *
      *                                                              *
      * CHECKPOINT: EVERY 100 DEALERS PROCESSED VIA COMCKPL0        *
      *                                                              *
      * TABLES:     AUTOSALE.DEALER             (READ)               *
      *             AUTOSALE.SALES_DEAL         (READ/DELETE)        *
      *             AUTOSALE.MONTHLY_SNAPSHOT   (INSERT/UPDATE)      *
      *             AUTOSALE.STOCK_POSITION     (UPDATE)             *
      *             AUTOSALE.FINANCE_PRODUCT    (READ)               *
      *             AUTOSALE.RESTART_CONTROL    (READ/UPDATE)        *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                PIC X(08) VALUE 'BATMTH00'.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    COPY CHECKPOINT/RESTART AREAS
      *
           COPY WSCKPT00.
           COPY WSRSTCTL.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-DEALERS-PROCESSED    PIC S9(09) COMP VALUE +0.
           05  WS-SNAPSHOTS-CREATED    PIC S9(09) COMP VALUE +0.
           05  WS-COUNTERS-ROLLED      PIC S9(09) COMP VALUE +0.
           05  WS-DEALS-ARCHIVED       PIC S9(09) COMP VALUE +0.
           05  WS-TOTAL-PROCESSED      PIC S9(09) COMP VALUE +0.
           05  WS-ERROR-COUNT          PIC S9(09) COMP VALUE +0.
      *
      *    CURRENT DATE FIELDS
      *
       01  WS-DATE-FIELDS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURR-YYYY        PIC 9(04).
               10  WS-CURR-MM          PIC 9(02).
               10  WS-CURR-DD          PIC 9(02).
               10  FILLER              PIC X(13).
           05  WS-CURRENT-DATE         PIC X(10) VALUE SPACES.
           05  WS-SNAPSHOT-MONTH       PIC X(06) VALUE SPACES.
           05  WS-ARCHIVE-CUTOFF       PIC X(10) VALUE SPACES.
           05  WS-MONTH-START          PIC X(10) VALUE SPACES.
           05  WS-MONTH-END            PIC X(10) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-UNIT-COUNT           PIC S9(05) COMP VALUE +0.
           05  WS-REVENUE-TOTAL        PIC S9(13)V99 COMP-3
                                                     VALUE +0.
           05  WS-GROSS-TOTAL          PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-FI-GROSS-TOTAL       PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-AVG-DAYS-SELL        PIC S9(05) COMP VALUE +0.
           05  WS-INV-TURN             PIC S9(03)V99 COMP-3
                                                     VALUE +0.
           05  WS-FI-PER-DEAL          PIC S9(07)V99 COMP-3
                                                     VALUE +0.
           05  WS-ON-HAND-AVG          PIC S9(05) COMP VALUE +0.
      *
      *    CHECKPOINT CALL FIELDS
      *
       01  WS-CHKP-FUNCTION.
           05  WS-CF-FUNC-CODE        PIC X(04).
           05  WS-CF-PROGRAM-NAME     PIC X(08).
           05  WS-CF-JOB-NAME         PIC X(08).
           05  WS-CF-STEP-NAME        PIC X(08).
           05  WS-CF-CHECKPOINT-FREQ  PIC S9(07) COMP-3.
      *
       01  WS-CHKP-DATA.
           05  WS-CD-EYE-CATCHER     PIC X(08).
           05  WS-CD-PROGRAM-ID       PIC X(08).
           05  WS-CD-TIMESTAMP        PIC X(26).
           05  WS-CD-LAST-KEY         PIC X(50).
           05  WS-CD-RECORDS-PROC     PIC S9(09) COMP.
           05  WS-CD-USER-DATA        PIC X(139).
      *
       01  WS-CHKP-RESULT.
           05  WS-CR-RETURN-CODE      PIC S9(04) COMP.
           05  WS-CR-RETURN-MSG       PIC X(79).
           05  WS-CR-RESTART-FLAG     PIC X(01).
           05  WS-CR-CHECKPOINT-ID    PIC X(20).
           05  WS-CR-RECORDS-PROC     PIC S9(09) COMP.
           05  WS-CR-LAST-KEY         PIC X(50).
           05  WS-CR-IMS-STATUS       PIC X(02).
           05  WS-CR-SQLCODE          PIC S9(09) COMP.
           05  WS-CR-CHKP-COUNT       PIC S9(07) COMP-3.
      *
      *    LOGGING FIELDS
      *
       01  WS-LOG-USER-ID             PIC X(08) VALUE 'BATCH   '.
       01  WS-LOG-PROGRAM-ID          PIC X(08) VALUE 'BATMTH00'.
       01  WS-LOG-ACTION-TYPE         PIC X(03) VALUE SPACES.
       01  WS-LOG-TABLE-NAME          PIC X(30) VALUE SPACES.
       01  WS-LOG-KEY-VALUE           PIC X(50) VALUE SPACES.
       01  WS-LOG-OLD-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-NEW-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-RETURN-CODE         PIC S9(04) COMP VALUE +0.
       01  WS-LOG-ERROR-MSG           PIC X(79) VALUE SPACES.
      *
      *    HOST VARIABLES - DEALER
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE         PIC X(05).
           05  WS-HV-DLR-NAME         PIC X(60).
      *
      *    HOST VARIABLES - MONTHLY STATS
      *
       01  WS-HV-MONTHLY.
           05  WS-HV-MN-UNITS         PIC S9(05) COMP.
           05  WS-HV-MN-REVENUE       PIC S9(13)V99 COMP-3.
           05  WS-HV-MN-GROSS         PIC S9(11)V99 COMP-3.
           05  WS-HV-MN-FI-GROSS      PIC S9(09)V99 COMP-3.
           05  WS-HV-MN-AVG-DAYS      PIC S9(05) COMP.
      *
      *    HOST VARIABLES - ARCHIVE DEALS
      *
       01  WS-HV-ARCHIVE.
           05  WS-HV-AR-DEAL-NUMBER   PIC X(10).
      *
      *    EOF FLAGS
      *
       01  WS-EOF-FLAGS.
           05  WS-EOF-DEALER          PIC X(01) VALUE 'N'.
               88  WS-DEALERS-DONE              VALUE 'Y'.
           05  WS-EOF-ARCHIVE         PIC X(01) VALUE 'N'.
               88  WS-ARCHIVE-DONE              VALUE 'Y'.
      *
      *    DB2 CURSORS
      *
      *    CURSOR: ALL ACTIVE DEALERS
      *
           EXEC SQL DECLARE CSR_DEALERS CURSOR FOR
               SELECT DEALER_CODE
                    , DEALER_NAME
               FROM   AUTOSALE.DEALER
               WHERE  ACTIVE_FLAG = 'Y'
               ORDER BY DEALER_CODE
           END-EXEC
      *
      *    CURSOR: COMPLETED DEALS OLDER THAN 18 MONTHS FOR ARCHIVE
      *
           EXEC SQL DECLARE CSR_ARCHIVE CURSOR FOR
               SELECT DEAL_NUMBER
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_STATUS IN ('DL', 'CA', 'UW')
                 AND  DELIVERY_DATE <= :WS-ARCHIVE-CUTOFF
               ORDER BY DEAL_NUMBER
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATMTH00: MONTHLY CLOSE PROCESSING - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-INIT-CHECKPOINT
      *
           PERFORM 3000-PROCESS-DEALERS
           PERFORM 4000-ROLL-COUNTERS
           PERFORM 5000-ARCHIVE-DEALS
      *
           PERFORM 8000-MARK-COMPLETE
           PERFORM 9000-DISPLAY-STATS
      *
           DISPLAY 'BATMTH00: MONTHLY CLOSE PROCESSING - END'
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
                  INTO WS-CURRENT-DATE
      *
      *    SNAPSHOT MONTH = YYYYMM
      *
           STRING WS-CURR-YYYY
                  WS-CURR-MM
                  DELIMITED BY SIZE
                  INTO WS-SNAPSHOT-MONTH
      *
      *    FIRST AND LAST DAY OF CURRENT MONTH
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-01'
                  DELIMITED BY SIZE
                  INTO WS-MONTH-START
      *
           MOVE WS-CURRENT-DATE TO WS-MONTH-END
      *
      *    ARCHIVE CUTOFF = 18 MONTHS AGO
      *
           EXEC SQL
               SELECT CHAR(CURRENT DATE - 18 MONTHS, ISO)
               INTO :WS-ARCHIVE-CUTOFF
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'BATMTH00: PROCESSING DATE  = ' WS-CURRENT-DATE
           DISPLAY 'BATMTH00: SNAPSHOT MONTH   = ' WS-SNAPSHOT-MONTH
           DISPLAY 'BATMTH00: ARCHIVE CUTOFF   = ' WS-ARCHIVE-CUTOFF
      *
           INITIALIZE WS-COUNTERS
           .
      *
      ****************************************************************
      *    2000-INIT-CHECKPOINT                                      *
      ****************************************************************
       2000-INIT-CHECKPOINT.
      *
           MOVE 'INIT'     TO WS-CF-FUNC-CODE
           MOVE 'BATMTH00' TO WS-CF-PROGRAM-NAME
           MOVE 'BATMTH00' TO WS-CF-JOB-NAME
           MOVE 'MONTHLY ' TO WS-CF-STEP-NAME
           MOVE +100       TO WS-CF-CHECKPOINT-FREQ
      *
           INITIALIZE WS-CHKP-DATA
           MOVE 'ASCHKP00' TO WS-CD-EYE-CATCHER
           MOVE 'BATMTH00' TO WS-CD-PROGRAM-ID
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE > +4
               DISPLAY 'BATMTH00: CHECKPOINT INIT FAILED - '
                       WS-CR-RETURN-MSG
               MOVE +16 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           DISPLAY 'BATMTH00: ' WS-CR-RETURN-MSG
      *
           MOVE +100 TO WS-CHECKPOINT-FREQ
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS - MONTHLY SNAPSHOT PER DEALER        *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           DISPLAY 'BATMTH00: PHASE 1 - DEALER MONTHLY SNAPSHOTS'
      *
           EXEC SQL OPEN CSR_DEALERS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATMTH00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALERS-DONE
               EXEC SQL FETCH CSR_DEALERS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 3100-CALC-DEALER-STATS
                   WHEN +100
                       SET WS-DEALERS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATMTH00: DB2 ERROR FETCH DEALER - '
                               SQLCODE
                       SET WS-DEALERS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DEALERS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3100-CALC-DEALER-STATS - CALCULATE AND INSERT SNAPSHOT    *
      ****************************************************************
       3100-CALC-DEALER-STATS.
      *
           ADD +1 TO WS-DEALERS-PROCESSED
      *
      *    GET UNITS SOLD AND REVENUE FOR THE MONTH
      *
           EXEC SQL
               SELECT COALESCE(COUNT(*), 0)
                    , COALESCE(SUM(TOTAL_PRICE), 0)
                    , COALESCE(SUM(TOTAL_GROSS), 0)
               INTO :WS-HV-MN-UNITS
                  , :WS-HV-MN-REVENUE
                  , :WS-HV-MN-GROSS
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEALER_CODE = :WS-HV-DLR-CODE
                 AND  DEAL_STATUS = 'DL'
                 AND  DELIVERY_DATE BETWEEN :WS-MONTH-START
                                        AND :WS-MONTH-END
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATMTH00: ERROR CALC STATS DEALER='
                       WS-HV-DLR-CODE ' SQLCODE=' SQLCODE
               GO TO 3100-EXIT
           END-IF
      *
      *    GET F&I GROSS FOR THE MONTH
      *
           EXEC SQL
               SELECT COALESCE(SUM(FP.GROSS_PROFIT), 0)
               INTO :WS-HV-MN-FI-GROSS
               FROM   AUTOSALE.FINANCE_PRODUCT FP
               INNER JOIN AUTOSALE.SALES_DEAL SD
                 ON   FP.DEAL_NUMBER = SD.DEAL_NUMBER
               WHERE  SD.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  SD.DEAL_STATUS = 'DL'
                 AND  SD.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                           AND :WS-MONTH-END
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               MOVE +0 TO WS-HV-MN-FI-GROSS
           END-IF
      *
      *    GET AVERAGE DAYS TO SELL
      *
           EXEC SQL
               SELECT COALESCE(AVG(V.DAYS_IN_STOCK), 0)
               INTO :WS-HV-MN-AVG-DAYS
               FROM   AUTOSALE.SALES_DEAL SD
               INNER JOIN AUTOSALE.VEHICLE V
                 ON   SD.VIN = V.VIN
               WHERE  SD.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  SD.DEAL_STATUS = 'DL'
                 AND  SD.DELIVERY_DATE BETWEEN :WS-MONTH-START
                                           AND :WS-MONTH-END
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               MOVE +0 TO WS-HV-MN-AVG-DAYS
           END-IF
      *
      *    CALCULATE F&I PER DEAL
      *
           IF WS-HV-MN-UNITS > +0
               COMPUTE WS-FI-PER-DEAL =
                   WS-HV-MN-FI-GROSS / WS-HV-MN-UNITS
           ELSE
               MOVE +0 TO WS-FI-PER-DEAL
           END-IF
      *
      *    INSERT MONTHLY SNAPSHOT
      *
           EXEC SQL
               INSERT INTO AUTOSALE.MONTHLY_SNAPSHOT
                    ( SNAPSHOT_MONTH
                    , DEALER_CODE
                    , TOTAL_UNITS_SOLD
                    , TOTAL_REVENUE
                    , TOTAL_GROSS
                    , TOTAL_FI_GROSS
                    , AVG_DAYS_TO_SELL
                    , FI_PER_DEAL
                    , FROZEN_FLAG
                    )
               VALUES
                    ( :WS-SNAPSHOT-MONTH
                    , :WS-HV-DLR-CODE
                    , :WS-HV-MN-UNITS
                    , :WS-HV-MN-REVENUE
                    , :WS-HV-MN-GROSS
                    , :WS-HV-MN-FI-GROSS
                    , :WS-HV-MN-AVG-DAYS
                    , :WS-FI-PER-DEAL
                    , 'Y'
                    )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-SNAPSHOTS-CREATED
               WHEN -803
      *            DUPLICATE - UPDATE INSTEAD
                   EXEC SQL
                       UPDATE AUTOSALE.MONTHLY_SNAPSHOT
                          SET TOTAL_UNITS_SOLD = :WS-HV-MN-UNITS
                            , TOTAL_REVENUE    = :WS-HV-MN-REVENUE
                            , TOTAL_GROSS      = :WS-HV-MN-GROSS
                            , TOTAL_FI_GROSS   = :WS-HV-MN-FI-GROSS
                            , AVG_DAYS_TO_SELL = :WS-HV-MN-AVG-DAYS
                            , FI_PER_DEAL      = :WS-FI-PER-DEAL
                            , FROZEN_FLAG      = 'Y'
                       WHERE  SNAPSHOT_MONTH = :WS-SNAPSHOT-MONTH
                         AND  DEALER_CODE    = :WS-HV-DLR-CODE
                   END-EXEC
                   IF SQLCODE = +0
                       ADD +1 TO WS-SNAPSHOTS-CREATED
                   ELSE
                       ADD +1 TO WS-ERROR-COUNT
                   END-IF
               WHEN OTHER
                   ADD +1 TO WS-ERROR-COUNT
                   DISPLAY 'BATMTH00: ERROR INSERT SNAPSHOT DLR='
                           WS-HV-DLR-CODE ' SQLCODE=' SQLCODE
           END-EVALUATE
      *
           ADD +1 TO WS-TOTAL-PROCESSED
           PERFORM 6000-CHECK-CHECKPOINT
           .
       3100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-ROLL-COUNTERS - RESET MTD COUNTERS ON STOCK_POSITION *
      ****************************************************************
       4000-ROLL-COUNTERS.
      *
           DISPLAY 'BATMTH00: PHASE 2 - ROLL MONTHLY COUNTERS'
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_POSITION
                  SET SOLD_MTD   = 0
                    , UPDATED_TS = CURRENT TIMESTAMP
           END-EXEC
      *
           IF SQLCODE >= +0
               MOVE SQLERRD(3) TO WS-COUNTERS-ROLLED
               DISPLAY 'BATMTH00: MTD COUNTERS ROLLED FOR '
                       WS-COUNTERS-ROLLED ' STOCK ROWS'
               EXEC SQL COMMIT END-EXEC
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATMTH00: ERROR ROLLING COUNTERS - '
                       SQLCODE
           END-IF
           .
      *
      ****************************************************************
      *    5000-ARCHIVE-DEALS - ARCHIVE OLD COMPLETED DEALS          *
      ****************************************************************
       5000-ARCHIVE-DEALS.
      *
           DISPLAY 'BATMTH00: PHASE 3 - ARCHIVE COMPLETED DEALS'
      *
           EXEC SQL OPEN CSR_ARCHIVE END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATMTH00: ERROR OPENING ARCHIVE CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-ARCHIVE
      *
           PERFORM UNTIL WS-ARCHIVE-DONE
               EXEC SQL FETCH CSR_ARCHIVE
                   INTO :WS-HV-AR-DEAL-NUMBER
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-ARCHIVE-ONE-DEAL
                   WHEN +100
                       SET WS-ARCHIVE-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATMTH00: DB2 ERROR FETCH ARCHIVE - '
                               SQLCODE
                       SET WS-ARCHIVE-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_ARCHIVE END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-ARCHIVE-ONE-DEAL - COPY DEAL TO ARCHIVE, FLAG SOURCE *
      ****************************************************************
       5100-ARCHIVE-ONE-DEAL.
      *
      *    MARK DEAL AS ARCHIVED (SET STATUS TO UW = UNWOUND/ARCHIVED)
      *    IN PRODUCTION, THIS WOULD INSERT INTO SALES_DEAL_ARCHIVE
      *    THEN DELETE FROM SALES_DEAL. HERE WE JUST UPDATE STATUS.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS = 'UW'
                    , UPDATED_TS  = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-HV-AR-DEAL-NUMBER
                 AND  DEAL_STATUS IN ('DL', 'CA')
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-DEALS-ARCHIVED
               ADD +1 TO WS-TOTAL-PROCESSED
      *
               CALL 'COMLGEL0' USING WS-LOG-USER-ID
                                     WS-LOG-PROGRAM-ID
                                     'UPD'
                                     'SALES_DEAL'
                                     WS-HV-AR-DEAL-NUMBER
                                     'DL'
                                     'UW'
                                     WS-LOG-RETURN-CODE
                                     WS-LOG-ERROR-MSG
      *
               PERFORM 6000-CHECK-CHECKPOINT
           ELSE
               IF SQLCODE NOT = +100
                   ADD +1 TO WS-ERROR-COUNT
                   DISPLAY 'BATMTH00: ERROR ARCHIVE DEAL='
                           WS-HV-AR-DEAL-NUMBER
                           ' SQLCODE=' SQLCODE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    6000-CHECK-CHECKPOINT                                     *
      ****************************************************************
       6000-CHECK-CHECKPOINT.
      *
           ADD +1 TO WS-RECORDS-SINCE-CHKP
      *
           IF WS-RECORDS-SINCE-CHKP >= WS-CHECKPOINT-FREQ
               PERFORM 6100-ISSUE-CHECKPOINT
           END-IF
           .
      *
      ****************************************************************
      *    6100-ISSUE-CHECKPOINT                                     *
      ****************************************************************
       6100-ISSUE-CHECKPOINT.
      *
           MOVE 'CHKP' TO WS-CF-FUNC-CODE
           MOVE WS-TOTAL-PROCESSED TO WS-CD-RECORDS-PROC
           MOVE WS-HV-DLR-CODE    TO WS-CD-LAST-KEY
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE = +0
               EXEC SQL COMMIT END-EXEC
               MOVE +0 TO WS-RECORDS-SINCE-CHKP
               ADD +1 TO WS-CHECKPOINT-COUNT
               DISPLAY 'BATMTH00: CHECKPOINT #'
                       WS-CHECKPOINT-COUNT
                       ' AT RECORD ' WS-TOTAL-PROCESSED
           ELSE
               DISPLAY 'BATMTH00: CHECKPOINT FAILED - '
                       WS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    8000-MARK-COMPLETE                                        *
      ****************************************************************
       8000-MARK-COMPLETE.
      *
           EXEC SQL COMMIT END-EXEC
      *
           MOVE 'DONE' TO WS-CF-FUNC-CODE
           MOVE WS-TOTAL-PROCESSED TO WS-CD-RECORDS-PROC
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           DISPLAY 'BATMTH00: ' WS-CR-RETURN-MSG
           .
      *
      ****************************************************************
      *    9000-DISPLAY-STATS                                        *
      ****************************************************************
       9000-DISPLAY-STATS.
      *
           DISPLAY 'BATMTH00: ================================='
           DISPLAY 'BATMTH00: MONTHLY CLOSE STATISTICS'
           DISPLAY 'BATMTH00: ================================='
           DISPLAY 'BATMTH00: DEALERS PROCESSED    = '
                   WS-DEALERS-PROCESSED
           DISPLAY 'BATMTH00: SNAPSHOTS CREATED    = '
                   WS-SNAPSHOTS-CREATED
           DISPLAY 'BATMTH00: COUNTERS ROLLED      = '
                   WS-COUNTERS-ROLLED
           DISPLAY 'BATMTH00: DEALS ARCHIVED       = '
                   WS-DEALS-ARCHIVED
           DISPLAY 'BATMTH00: TOTAL PROCESSED      = '
                   WS-TOTAL-PROCESSED
           DISPLAY 'BATMTH00: ERRORS               = '
                   WS-ERROR-COUNT
           DISPLAY 'BATMTH00: CHECKPOINTS TAKEN    = '
                   WS-CHECKPOINT-COUNT
           DISPLAY 'BATMTH00: ================================='
           .
      ****************************************************************
      * END OF BATMTH00                                              *
      ****************************************************************
