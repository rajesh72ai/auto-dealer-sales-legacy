       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATDLY00.
      ****************************************************************
      * PROGRAM:    BATDLY00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    DAILY END-OF-DAY PROCESSING. RUNS NIGHTLY TO:    *
      *             1. UPDATE VEHICLE STATUS FOR DELIVERED VEHICLES   *
      *                (STOCK -> SOLD) BASED ON DEAL DELIVERY DATE   *
      *             2. EXPIRE AGED PENDING DEALS (30+ DAYS PENDING)  *
      *             3. CALCULATE DAILY FLOOR PLAN INTEREST ACCRUAL   *
      *                FOR ALL ACTIVE FLOOR PLAN VEHICLES             *
      *             4. INSERT INTEREST RECORDS INTO                   *
      *                FLOOR_PLAN_INTEREST TABLE                      *
      *                                                              *
      * CHECKPOINT: EVERY 500 VEHICLES PROCESSED VIA COMCKPL0       *
      *                                                              *
      * TABLES:     AUTOSALE.VEHICLE            (READ/UPDATE)        *
      *             AUTOSALE.SALES_DEAL         (READ/UPDATE)        *
      *             AUTOSALE.FLOOR_PLAN_VEHICLE (READ/UPDATE)        *
      *             AUTOSALE.FLOOR_PLAN_LENDER  (READ)               *
      *             AUTOSALE.FLOOR_PLAN_INTEREST(INSERT)             *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'BATDLY00'.
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
           05  WS-VEH-DELIVERED-CT     PIC S9(09) COMP VALUE +0.
           05  WS-VEH-UPDATED-CT       PIC S9(09) COMP VALUE +0.
           05  WS-DEALS-EXPIRED-CT     PIC S9(09) COMP VALUE +0.
           05  WS-FP-VEHICLES-CT       PIC S9(09) COMP VALUE +0.
           05  WS-FP-INTEREST-CT       PIC S9(09) COMP VALUE +0.
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
           05  WS-CUTOFF-DATE          PIC X(10) VALUE SPACES.
           05  WS-FORMATTED-TS         PIC X(26) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-DAILY-RATE           PIC S9(05)V9(6) COMP-3
                                                       VALUE +0.
           05  WS-DAILY-INTEREST       PIC S9(09)V9(4) COMP-3
                                                       VALUE +0.
           05  WS-CUMULATIVE-INT       PIC S9(09)V99   COMP-3
                                                       VALUE +0.
           05  WS-COMBINED-RATE        PIC S9(05)V9(3) COMP-3
                                                       VALUE +0.
           05  WS-RETURN-CODE          PIC S9(04) COMP VALUE +0.
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
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-PROGRAM-NAME        PIC X(08) VALUE 'BATDLY00'.
       01  WS-DBE-SECTION-NAME        PIC X(30) VALUE SPACES.
       01  WS-DBE-TABLE-NAME          PIC X(30) VALUE SPACES.
       01  WS-DBE-OPERATION           PIC X(10) VALUE SPACES.
       01  WS-DBE-RESULT-AREA.
           05  WS-DBE-RESULT-CODE     PIC S9(04) COMP VALUE +0.
           05  WS-DBE-RESULT-MSG      PIC X(79) VALUE SPACES.
      *
      *    LOGGING FIELDS
      *
       01  WS-LOG-USER-ID             PIC X(08) VALUE 'BATCH   '.
       01  WS-LOG-PROGRAM-ID          PIC X(08) VALUE 'BATDLY00'.
       01  WS-LOG-ACTION-TYPE         PIC X(03) VALUE SPACES.
       01  WS-LOG-TABLE-NAME          PIC X(30) VALUE SPACES.
       01  WS-LOG-KEY-VALUE           PIC X(50) VALUE SPACES.
       01  WS-LOG-OLD-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-NEW-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-RETURN-CODE         PIC S9(04) COMP VALUE +0.
       01  WS-LOG-ERROR-MSG           PIC X(79) VALUE SPACES.
      *
      *    HOST VARIABLES - DELIVERED VEHICLES
      *
       01  WS-HV-DELIVERED.
           05  WS-HV-DV-VIN           PIC X(17).
           05  WS-HV-DV-DEAL-NUMBER   PIC X(10).
           05  WS-HV-DV-STATUS        PIC X(02).
      *
      *    HOST VARIABLES - PENDING DEALS
      *
       01  WS-HV-PENDING.
           05  WS-HV-PD-DEAL-NUMBER   PIC X(10).
           05  WS-HV-PD-DEAL-DATE     PIC X(10).
           05  WS-HV-PD-STATUS        PIC X(02).
      *
      *    HOST VARIABLES - FLOOR PLAN
      *
       01  WS-HV-FLOOR-PLAN.
           05  WS-HV-FP-PLAN-ID       PIC S9(09) COMP.
           05  WS-HV-FP-VIN           PIC X(17).
           05  WS-HV-FP-BALANCE       PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-INTEREST-ACC  PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-LENDER-ID     PIC X(05).
           05  WS-HV-FP-BASE-RATE     PIC S9(03)V9(3) COMP-3.
           05  WS-HV-FP-SPREAD        PIC S9(03)V9(3) COMP-3.
           05  WS-HV-FP-DAYS-FLOOR    PIC S9(04) COMP.
      *
      *    EOF FLAGS
      *
       01  WS-EOF-FLAGS.
           05  WS-EOF-DELIVERED        PIC X(01) VALUE 'N'.
               88  WS-DELIVERED-DONE             VALUE 'Y'.
           05  WS-EOF-PENDING          PIC X(01) VALUE 'N'.
               88  WS-PENDING-DONE               VALUE 'Y'.
           05  WS-EOF-FLOOR-PLAN       PIC X(01) VALUE 'N'.
               88  WS-FLOOR-PLAN-DONE            VALUE 'Y'.
      *
      *    DB2 CURSORS
      *
      *    CURSOR: VEHICLES DELIVERED TODAY STILL IN STOCK STATUS
      *
           EXEC SQL DECLARE CSR_DELIVERED CURSOR FOR
               SELECT V.VIN
                    , S.DEAL_NUMBER
                    , V.VEHICLE_STATUS
               FROM   AUTOSALE.VEHICLE V
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   V.VIN = S.VIN
               WHERE  S.DEAL_STATUS = 'DL'
                 AND  S.DELIVERY_DATE = :WS-CURRENT-DATE
                 AND  V.VEHICLE_STATUS <> 'SD'
               ORDER BY V.VIN
           END-EXEC
      *
      *    CURSOR: PENDING DEALS OLDER THAN 30 DAYS
      *
           EXEC SQL DECLARE CSR_PENDING CURSOR FOR
               SELECT S.DEAL_NUMBER
                    , S.DEAL_DATE
                    , S.DEAL_STATUS
               FROM   AUTOSALE.SALES_DEAL S
               WHERE  S.DEAL_STATUS IN ('WS', 'NE', 'PA')
                 AND  S.DEAL_DATE <= :WS-CUTOFF-DATE
               ORDER BY S.DEAL_NUMBER
           END-EXEC
      *
      *    CURSOR: ACTIVE FLOOR PLAN VEHICLES WITH LENDER RATES
      *
           EXEC SQL DECLARE CSR_FLOOR_PLAN CURSOR FOR
               SELECT FPV.FLOOR_PLAN_ID
                    , FPV.VIN
                    , FPV.CURRENT_BALANCE
                    , FPV.INTEREST_ACCRUED
                    , FPV.LENDER_ID
                    , FPL.BASE_RATE
                    , FPL.SPREAD
                    , FPV.DAYS_ON_FLOOR
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE FPV
               INNER JOIN AUTOSALE.FLOOR_PLAN_LENDER FPL
                 ON   FPV.LENDER_ID = FPL.LENDER_ID
               WHERE  FPV.FP_STATUS = 'AC'
               ORDER BY FPV.VIN
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATDLY00: DAILY END-OF-DAY PROCESSING - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-INIT-CHECKPOINT
      *
           PERFORM 3000-PROCESS-DELIVERED
           PERFORM 4000-PROCESS-PENDING-DEALS
           PERFORM 5000-PROCESS-FLOOR-PLAN
      *
           PERFORM 8000-MARK-COMPLETE
           PERFORM 9000-DISPLAY-STATS
      *
           DISPLAY 'BATDLY00: DAILY END-OF-DAY PROCESSING - END'
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
      *    CUTOFF DATE = 30 DAYS AGO FOR PENDING DEALS
      *
           EXEC SQL
               SELECT CHAR(CURRENT DATE - 30 DAYS, ISO)
               INTO :WS-CUTOFF-DATE
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'BATDLY00: PROCESSING DATE  = ' WS-CURRENT-DATE
           DISPLAY 'BATDLY00: EXPIRY CUTOFF    = ' WS-CUTOFF-DATE
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
           MOVE 'BATDLY00' TO WS-CF-PROGRAM-NAME
           MOVE 'BATDLY00' TO WS-CF-JOB-NAME
           MOVE 'DAILY   ' TO WS-CF-STEP-NAME
           MOVE +500       TO WS-CF-CHECKPOINT-FREQ
      *
           INITIALIZE WS-CHKP-DATA
           MOVE 'ASCHKP00' TO WS-CD-EYE-CATCHER
           MOVE 'BATDLY00' TO WS-CD-PROGRAM-ID
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE > +4
               DISPLAY 'BATDLY00: CHECKPOINT INIT FAILED - '
                       WS-CR-RETURN-MSG
               MOVE +16 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           DISPLAY 'BATDLY00: ' WS-CR-RETURN-MSG
      *
           MOVE +500 TO WS-CHECKPOINT-FREQ
           .
      *
      ****************************************************************
      *    3000-PROCESS-DELIVERED - UPDATE DELIVERED VEHICLES TO SOLD *
      ****************************************************************
       3000-PROCESS-DELIVERED.
      *
           DISPLAY 'BATDLY00: PHASE 1 - DELIVERED VEHICLE UPDATES'
      *
           EXEC SQL OPEN CSR_DELIVERED END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDLY00: ERROR OPENING DELIVERED CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DELIVERED
      *
           PERFORM UNTIL WS-DELIVERED-DONE
               EXEC SQL FETCH CSR_DELIVERED
                   INTO :WS-HV-DV-VIN
                      , :WS-HV-DV-DEAL-NUMBER
                      , :WS-HV-DV-STATUS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 3100-UPDATE-VEHICLE-SOLD
                   WHEN +100
                       SET WS-DELIVERED-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDLY00: DB2 ERROR FETCH DELIVERED - '
                               SQLCODE
                       SET WS-DELIVERED-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DELIVERED END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3100-UPDATE-VEHICLE-SOLD                                  *
      ****************************************************************
       3100-UPDATE-VEHICLE-SOLD.
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = 'SD'
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :WS-HV-DV-VIN
                 AND  VEHICLE_STATUS <> 'SD'
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-VEH-UPDATED-CT
               ADD +1 TO WS-VEH-DELIVERED-CT
               ADD +1 TO WS-TOTAL-PROCESSED
      *
               CALL 'COMLGEL0' USING WS-LOG-USER-ID
                                     WS-LOG-PROGRAM-ID
                                     'UPD'
                                     'VEHICLE'
                                     WS-HV-DV-VIN
                                     WS-HV-DV-STATUS
                                     'SD'
                                     WS-LOG-RETURN-CODE
                                     WS-LOG-ERROR-MSG
      *
               PERFORM 3200-CHECK-CHECKPOINT
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATDLY00: ERROR UPDATING VIN='
                       WS-HV-DV-VIN ' SQLCODE=' SQLCODE
           END-IF
           .
      *
      ****************************************************************
      *    3200-CHECK-CHECKPOINT                                     *
      ****************************************************************
       3200-CHECK-CHECKPOINT.
      *
           ADD +1 TO WS-RECORDS-SINCE-CHKP
      *
           IF WS-RECORDS-SINCE-CHKP >= WS-CHECKPOINT-FREQ
               PERFORM 3300-ISSUE-CHECKPOINT
           END-IF
           .
      *
      ****************************************************************
      *    3300-ISSUE-CHECKPOINT                                     *
      ****************************************************************
       3300-ISSUE-CHECKPOINT.
      *
           MOVE 'CHKP' TO WS-CF-FUNC-CODE
           MOVE WS-TOTAL-PROCESSED TO WS-CD-RECORDS-PROC
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE = +0
               EXEC SQL COMMIT END-EXEC
               MOVE +0 TO WS-RECORDS-SINCE-CHKP
               ADD +1 TO WS-CHECKPOINT-COUNT
               DISPLAY 'BATDLY00: CHECKPOINT #'
                       WS-CHECKPOINT-COUNT
                       ' AT RECORD ' WS-TOTAL-PROCESSED
           ELSE
               DISPLAY 'BATDLY00: CHECKPOINT FAILED - '
                       WS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    4000-PROCESS-PENDING-DEALS - EXPIRE AGED PENDING DEALS    *
      ****************************************************************
       4000-PROCESS-PENDING-DEALS.
      *
           DISPLAY 'BATDLY00: PHASE 2 - EXPIRE AGED PENDING DEALS'
      *
           EXEC SQL OPEN CSR_PENDING END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDLY00: ERROR OPENING PENDING CURSOR - '
                       SQLCODE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-PENDING
      *
           PERFORM UNTIL WS-PENDING-DONE
               EXEC SQL FETCH CSR_PENDING
                   INTO :WS-HV-PD-DEAL-NUMBER
                      , :WS-HV-PD-DEAL-DATE
                      , :WS-HV-PD-STATUS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 4100-EXPIRE-DEAL
                   WHEN +100
                       SET WS-PENDING-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDLY00: DB2 ERROR FETCH PENDING - '
                               SQLCODE
                       SET WS-PENDING-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_PENDING END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-EXPIRE-DEAL                                          *
      ****************************************************************
       4100-EXPIRE-DEAL.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS = 'CA'
                    , UPDATED_TS  = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-HV-PD-DEAL-NUMBER
                 AND  DEAL_STATUS IN ('WS', 'NE', 'PA')
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-DEALS-EXPIRED-CT
               ADD +1 TO WS-TOTAL-PROCESSED
      *
               CALL 'COMLGEL0' USING WS-LOG-USER-ID
                                     WS-LOG-PROGRAM-ID
                                     'UPD'
                                     'SALES_DEAL'
                                     WS-HV-PD-DEAL-NUMBER
                                     WS-HV-PD-STATUS
                                     'CA'
                                     WS-LOG-RETURN-CODE
                                     WS-LOG-ERROR-MSG
      *
               PERFORM 3200-CHECK-CHECKPOINT
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATDLY00: ERROR EXPIRING DEAL='
                       WS-HV-PD-DEAL-NUMBER ' SQLCODE=' SQLCODE
           END-IF
           .
      *
      ****************************************************************
      *    5000-PROCESS-FLOOR-PLAN - DAILY INTEREST ACCRUAL          *
      ****************************************************************
       5000-PROCESS-FLOOR-PLAN.
      *
           DISPLAY 'BATDLY00: PHASE 3 - FLOOR PLAN INTEREST ACCRUAL'
      *
           EXEC SQL OPEN CSR_FLOOR_PLAN END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDLY00: ERROR OPENING FLOOR PLAN CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLOOR-PLAN
      *
           PERFORM UNTIL WS-FLOOR-PLAN-DONE
               EXEC SQL FETCH CSR_FLOOR_PLAN
                   INTO :WS-HV-FP-PLAN-ID
                      , :WS-HV-FP-VIN
                      , :WS-HV-FP-BALANCE
                      , :WS-HV-FP-INTEREST-ACC
                      , :WS-HV-FP-LENDER-ID
                      , :WS-HV-FP-BASE-RATE
                      , :WS-HV-FP-SPREAD
                      , :WS-HV-FP-DAYS-FLOOR
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-CALC-DAILY-INTEREST
                   WHEN +100
                       SET WS-FLOOR-PLAN-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDLY00: DB2 ERROR FETCH FP - '
                               SQLCODE
                       SET WS-FLOOR-PLAN-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_FLOOR_PLAN END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-CALC-DAILY-INTEREST                                  *
      ****************************************************************
       5100-CALC-DAILY-INTEREST.
      *
           ADD +1 TO WS-FP-VEHICLES-CT
      *
      *    COMBINED RATE = BASE + SPREAD, DAILY = RATE / 365
      *
           COMPUTE WS-COMBINED-RATE =
               WS-HV-FP-BASE-RATE + WS-HV-FP-SPREAD
      *
           COMPUTE WS-DAILY-RATE =
               WS-COMBINED-RATE / 365
      *
      *    DAILY INTEREST = BALANCE * DAILY RATE / 100
      *
           COMPUTE WS-DAILY-INTEREST =
               WS-HV-FP-BALANCE * WS-DAILY-RATE / 100
      *
      *    CUMULATIVE = PRIOR ACCRUED + TODAY
      *
           COMPUTE WS-CUMULATIVE-INT =
               WS-HV-FP-INTEREST-ACC + WS-DAILY-INTEREST
      *
      *    INSERT INTEREST RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.FLOOR_PLAN_INTEREST
                    ( FLOOR_PLAN_ID
                    , CALC_DATE
                    , PRINCIPAL_BAL
                    , RATE_APPLIED
                    , DAILY_INTEREST
                    , CUMULATIVE_INT
                    )
               VALUES
                    ( :WS-HV-FP-PLAN-ID
                    , CURRENT DATE
                    , :WS-HV-FP-BALANCE
                    , :WS-COMBINED-RATE
                    , :WS-DAILY-INTEREST
                    , :WS-CUMULATIVE-INT
                    )
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-FP-INTEREST-CT
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATDLY00: ERROR INSERT FP INTEREST VIN='
                       WS-HV-FP-VIN ' SQLCODE=' SQLCODE
               GO TO 5100-EXIT
           END-IF
      *
      *    UPDATE FLOOR PLAN VEHICLE ACCRUED INTEREST & DAYS
      *
           EXEC SQL
               UPDATE AUTOSALE.FLOOR_PLAN_VEHICLE
                  SET INTEREST_ACCRUED  = :WS-CUMULATIVE-INT
                    , DAYS_ON_FLOOR     = DAYS_ON_FLOOR + 1
                    , LAST_INTEREST_DT  = CURRENT DATE
               WHERE  FLOOR_PLAN_ID = :WS-HV-FP-PLAN-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATDLY00: ERROR UPDATE FP VEH ID='
                       WS-HV-FP-PLAN-ID ' SQLCODE=' SQLCODE
           END-IF
      *
           ADD +1 TO WS-TOTAL-PROCESSED
           PERFORM 3200-CHECK-CHECKPOINT
           .
       5100-EXIT.
           EXIT.
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
           DISPLAY 'BATDLY00: ' WS-CR-RETURN-MSG
           .
      *
      ****************************************************************
      *    9000-DISPLAY-STATS                                        *
      ****************************************************************
       9000-DISPLAY-STATS.
      *
           DISPLAY 'BATDLY00: ================================='
           DISPLAY 'BATDLY00: DAILY PROCESSING STATISTICS'
           DISPLAY 'BATDLY00: ================================='
           DISPLAY 'BATDLY00: VEHICLES DELIVERED  = '
                   WS-VEH-DELIVERED-CT
           DISPLAY 'BATDLY00: VEHICLES UPDATED    = '
                   WS-VEH-UPDATED-CT
           DISPLAY 'BATDLY00: DEALS EXPIRED       = '
                   WS-DEALS-EXPIRED-CT
           DISPLAY 'BATDLY00: FP VEHICLES CALC    = '
                   WS-FP-VEHICLES-CT
           DISPLAY 'BATDLY00: FP INTEREST RECORDS = '
                   WS-FP-INTEREST-CT
           DISPLAY 'BATDLY00: TOTAL PROCESSED     = '
                   WS-TOTAL-PROCESSED
           DISPLAY 'BATDLY00: ERRORS              = '
                   WS-ERROR-COUNT
           DISPLAY 'BATDLY00: CHECKPOINTS TAKEN   = '
                   WS-CHECKPOINT-COUNT
           DISPLAY 'BATDLY00: ================================='
           .
      ****************************************************************
      * END OF BATDLY00                                              *
      ****************************************************************
