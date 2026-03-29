       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATWKL00.
      ****************************************************************
      * PROGRAM:    BATWKL00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    WEEKLY BATCH PROCESSING. RUNS EVERY SUNDAY TO:   *
      *             1. AGE INVENTORY - UPDATE DAYS_IN_STOCK ON ALL   *
      *                VEHICLES CURRENTLY IN DEALER STOCK             *
      *             2. GENERATE WARRANTY EXPIRATION NOTICES FOR       *
      *                WARRANTIES EXPIRING WITHIN 30 DAYS             *
      *             3. UPDATE RECALL CAMPAIGN COMPLETION PERCENTAGES *
      *                BASED ON CURRENT RECALL_VEHICLE STATUSES       *
      *                                                              *
      * CHECKPOINT: EVERY 500 RECORDS PROCESSED VIA COMCKPL0        *
      *                                                              *
      * TABLES:     AUTOSALE.VEHICLE            (READ/UPDATE)        *
      *             AUTOSALE.WARRANTY           (READ)               *
      *             AUTOSALE.CUSTOMER           (READ)               *
      *             AUTOSALE.RECALL_CAMPAIGN    (READ/UPDATE)        *
      *             AUTOSALE.RECALL_VEHICLE     (READ)               *
      *             AUTOSALE.RECALL_NOTIFICATION(INSERT)             *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'BATWKL00'.
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
           05  WS-VEH-AGED-CT         PIC S9(09) COMP VALUE +0.
           05  WS-WARRANTY-NOTICE-CT   PIC S9(09) COMP VALUE +0.
           05  WS-RECALL-UPDATED-CT    PIC S9(09) COMP VALUE +0.
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
           05  WS-WARRANTY-CUTOFF      PIC X(10) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-DAYS-SINCE-RECV      PIC S9(05) COMP VALUE +0.
           05  WS-COMPLETION-PCT       PIC S9(03) COMP VALUE +0.
           05  WS-TOTAL-AFFECTED       PIC S9(09) COMP VALUE +0.
           05  WS-TOTAL-COMPLETED      PIC S9(09) COMP VALUE +0.
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
       01  WS-LOG-PROGRAM-ID          PIC X(08) VALUE 'BATWKL00'.
       01  WS-LOG-ACTION-TYPE         PIC X(03) VALUE SPACES.
       01  WS-LOG-TABLE-NAME          PIC X(30) VALUE SPACES.
       01  WS-LOG-KEY-VALUE           PIC X(50) VALUE SPACES.
       01  WS-LOG-OLD-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-NEW-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-RETURN-CODE         PIC S9(04) COMP VALUE +0.
       01  WS-LOG-ERROR-MSG           PIC X(79) VALUE SPACES.
      *
      *    HOST VARIABLES - INVENTORY AGING
      *
       01  WS-HV-AGING.
           05  WS-HV-AG-VIN           PIC X(17).
           05  WS-HV-AG-RECV-DATE     PIC X(10).
           05  WS-HV-AG-DAYS-STOCK    PIC S9(04) COMP.
      *
      *    HOST VARIABLES - WARRANTY EXPIRATION
      *
       01  WS-HV-WARRANTY.
           05  WS-HV-WR-WARRANTY-ID   PIC S9(09) COMP.
           05  WS-HV-WR-VIN           PIC X(17).
           05  WS-HV-WR-TYPE          PIC X(02).
           05  WS-HV-WR-EXPIRY-DATE   PIC X(10).
           05  WS-HV-WR-DEAL-NUMBER   PIC X(10).
           05  WS-HV-WR-CUSTOMER-ID   PIC S9(09) COMP.
      *
      *    HOST VARIABLES - RECALL CAMPAIGNS
      *
       01  WS-HV-RECALL.
           05  WS-HV-RC-RECALL-ID     PIC X(10).
           05  WS-HV-RC-TOTAL-AFF     PIC S9(09) COMP.
           05  WS-HV-RC-TOTAL-CMP     PIC S9(09) COMP.
      *
      *    EOF FLAGS
      *
       01  WS-EOF-FLAGS.
           05  WS-EOF-AGING           PIC X(01) VALUE 'N'.
               88  WS-AGING-DONE                VALUE 'Y'.
           05  WS-EOF-WARRANTY        PIC X(01) VALUE 'N'.
               88  WS-WARRANTY-DONE              VALUE 'Y'.
           05  WS-EOF-RECALL          PIC X(01) VALUE 'N'.
               88  WS-RECALL-DONE                VALUE 'Y'.
      *
      *    DB2 CURSORS
      *
      *    CURSOR: VEHICLES IN STOCK FOR AGING
      *
           EXEC SQL DECLARE CSR_AGING CURSOR FOR
               SELECT V.VIN
                    , CHAR(V.RECEIVE_DATE, ISO)
                    , V.DAYS_IN_STOCK
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VEHICLE_STATUS IN ('AV', 'HD', 'DL')
                 AND  V.RECEIVE_DATE IS NOT NULL
                 AND  V.DEALER_CODE IS NOT NULL
               ORDER BY V.VIN
           END-EXEC
      *
      *    CURSOR: WARRANTIES EXPIRING IN 30 DAYS
      *
           EXEC SQL DECLARE CSR_WARRANTY CURSOR FOR
               SELECT W.WARRANTY_ID
                    , W.VIN
                    , W.WARRANTY_TYPE
                    , CHAR(W.EXPIRY_DATE, ISO)
                    , W.DEAL_NUMBER
                    , S.CUSTOMER_ID
               FROM   AUTOSALE.WARRANTY W
               INNER JOIN AUTOSALE.SALES_DEAL S
                 ON   W.DEAL_NUMBER = S.DEAL_NUMBER
               WHERE  W.ACTIVE_FLAG = 'Y'
                 AND  W.EXPIRY_DATE BETWEEN CURRENT DATE
                                        AND :WS-WARRANTY-CUTOFF
               ORDER BY W.VIN
           END-EXEC
      *
      *    CURSOR: ACTIVE RECALL CAMPAIGNS FOR COMPLETION UPDATE
      *
           EXEC SQL DECLARE CSR_RECALL CURSOR FOR
               SELECT RC.RECALL_ID
                    , RC.TOTAL_AFFECTED
                    , RC.TOTAL_COMPLETED
               FROM   AUTOSALE.RECALL_CAMPAIGN RC
               WHERE  RC.CAMPAIGN_STATUS = 'A'
               ORDER BY RC.RECALL_ID
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATWKL00: WEEKLY BATCH PROCESSING - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-INIT-CHECKPOINT
      *
           PERFORM 3000-PROCESS-AGING
           PERFORM 4000-PROCESS-WARRANTY
           PERFORM 5000-PROCESS-RECALL
      *
           PERFORM 8000-MARK-COMPLETE
           PERFORM 9000-DISPLAY-STATS
      *
           DISPLAY 'BATWKL00: WEEKLY BATCH PROCESSING - END'
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
      *    WARRANTY CUTOFF = CURRENT DATE + 30 DAYS
      *
           EXEC SQL
               SELECT CHAR(CURRENT DATE + 30 DAYS, ISO)
               INTO :WS-WARRANTY-CUTOFF
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'BATWKL00: PROCESSING DATE     = ' WS-CURRENT-DATE
           DISPLAY 'BATWKL00: WARRANTY CUTOFF      = '
                   WS-WARRANTY-CUTOFF
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
           MOVE 'BATWKL00' TO WS-CF-PROGRAM-NAME
           MOVE 'BATWKL00' TO WS-CF-JOB-NAME
           MOVE 'WEEKLY  ' TO WS-CF-STEP-NAME
           MOVE +500       TO WS-CF-CHECKPOINT-FREQ
      *
           INITIALIZE WS-CHKP-DATA
           MOVE 'ASCHKP00' TO WS-CD-EYE-CATCHER
           MOVE 'BATWKL00' TO WS-CD-PROGRAM-ID
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE > +4
               DISPLAY 'BATWKL00: CHECKPOINT INIT FAILED - '
                       WS-CR-RETURN-MSG
               MOVE +16 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           DISPLAY 'BATWKL00: ' WS-CR-RETURN-MSG
      *
           MOVE +500 TO WS-CHECKPOINT-FREQ
           .
      *
      ****************************************************************
      *    3000-PROCESS-AGING - AGE INVENTORY DAYS IN STOCK          *
      ****************************************************************
       3000-PROCESS-AGING.
      *
           DISPLAY 'BATWKL00: PHASE 1 - INVENTORY AGING'
      *
           EXEC SQL OPEN CSR_AGING END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATWKL00: ERROR OPENING AGING CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-AGING
      *
           PERFORM UNTIL WS-AGING-DONE
               EXEC SQL FETCH CSR_AGING
                   INTO :WS-HV-AG-VIN
                      , :WS-HV-AG-RECV-DATE
                      , :WS-HV-AG-DAYS-STOCK
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 3100-UPDATE-DAYS-IN-STOCK
                   WHEN +100
                       SET WS-AGING-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATWKL00: DB2 ERROR FETCH AGING - '
                               SQLCODE
                       SET WS-AGING-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_AGING END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3100-UPDATE-DAYS-IN-STOCK                                 *
      ****************************************************************
       3100-UPDATE-DAYS-IN-STOCK.
      *
      *    CALCULATE ACTUAL DAYS SINCE RECEIVE DATE
      *
           EXEC SQL
               SELECT DAYS(CURRENT DATE)
                    - DAYS(:WS-HV-AG-RECV-DATE)
               INTO :WS-DAYS-SINCE-RECV
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               GO TO 3100-EXIT
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET DAYS_IN_STOCK = :WS-DAYS-SINCE-RECV
                    , UPDATED_TS    = CURRENT TIMESTAMP
               WHERE  VIN = :WS-HV-AG-VIN
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-VEH-AGED-CT
               ADD +1 TO WS-TOTAL-PROCESSED
               PERFORM 6000-CHECK-CHECKPOINT
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATWKL00: ERROR AGING VIN='
                       WS-HV-AG-VIN ' SQLCODE=' SQLCODE
           END-IF
           .
       3100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PROCESS-WARRANTY - WARRANTY EXPIRATION NOTICES       *
      ****************************************************************
       4000-PROCESS-WARRANTY.
      *
           DISPLAY 'BATWKL00: PHASE 2 - WARRANTY EXPIRATION NOTICES'
      *
           EXEC SQL OPEN CSR_WARRANTY END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATWKL00: ERROR OPENING WARRANTY CURSOR - '
                       SQLCODE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-WARRANTY
      *
           PERFORM UNTIL WS-WARRANTY-DONE
               EXEC SQL FETCH CSR_WARRANTY
                   INTO :WS-HV-WR-WARRANTY-ID
                      , :WS-HV-WR-VIN
                      , :WS-HV-WR-TYPE
                      , :WS-HV-WR-EXPIRY-DATE
                      , :WS-HV-WR-DEAL-NUMBER
                      , :WS-HV-WR-CUSTOMER-ID
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 4100-GENERATE-NOTICE
                   WHEN +100
                       SET WS-WARRANTY-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATWKL00: DB2 ERROR FETCH WARRANTY - '
                               SQLCODE
                       SET WS-WARRANTY-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_WARRANTY END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-GENERATE-NOTICE - INSERT WARRANTY EXPIRY NOTICE      *
      *    (REUSING RECALL_NOTIFICATION TABLE FOR NOTIFICATIONS)     *
      ****************************************************************
       4100-GENERATE-NOTICE.
      *
      *    CHECK IF NOTICE ALREADY SENT FOR THIS WARRANTY
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-TOTAL-COMPLETED
               FROM   AUTOSALE.RECALL_NOTIFICATION
               WHERE  VIN = :WS-HV-WR-VIN
                 AND  CUSTOMER_ID = :WS-HV-WR-CUSTOMER-ID
                 AND  NOTIF_TYPE = 'M'
                 AND  NOTIF_DATE >= CURRENT DATE - 30 DAYS
           END-EXEC
      *
           IF SQLCODE = +0 AND WS-TOTAL-COMPLETED = +0
      *
      *        NO RECENT NOTICE - GENERATE ONE
      *
               EXEC SQL
                   INSERT INTO AUTOSALE.RECALL_NOTIFICATION
                        ( RECALL_ID
                        , VIN
                        , CUSTOMER_ID
                        , NOTIF_TYPE
                        , NOTIF_DATE
                        , RESPONSE_FLAG
                        )
                   VALUES
                        ( 'WAREXP    '
                        , :WS-HV-WR-VIN
                        , :WS-HV-WR-CUSTOMER-ID
                        , 'M'
                        , CURRENT DATE
                        , 'N'
                        )
               END-EXEC
      *
               IF SQLCODE = +0
                   ADD +1 TO WS-WARRANTY-NOTICE-CT
                   ADD +1 TO WS-TOTAL-PROCESSED
                   PERFORM 6000-CHECK-CHECKPOINT
               ELSE
                   ADD +1 TO WS-ERROR-COUNT
                   DISPLAY 'BATWKL00: ERROR INSERT WARRANTY NOTICE '
                           'VIN=' WS-HV-WR-VIN
                           ' SQLCODE=' SQLCODE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    5000-PROCESS-RECALL - UPDATE CAMPAIGN COMPLETION PCT      *
      ****************************************************************
       5000-PROCESS-RECALL.
      *
           DISPLAY 'BATWKL00: PHASE 3 - RECALL COMPLETION UPDATE'
      *
           EXEC SQL OPEN CSR_RECALL END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATWKL00: ERROR OPENING RECALL CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-RECALL
      *
           PERFORM UNTIL WS-RECALL-DONE
               EXEC SQL FETCH CSR_RECALL
                   INTO :WS-HV-RC-RECALL-ID
                      , :WS-HV-RC-TOTAL-AFF
                      , :WS-HV-RC-TOTAL-CMP
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-UPDATE-RECALL-PCT
                   WHEN +100
                       SET WS-RECALL-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATWKL00: DB2 ERROR FETCH RECALL - '
                               SQLCODE
                       SET WS-RECALL-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_RECALL END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-UPDATE-RECALL-PCT                                    *
      ****************************************************************
       5100-UPDATE-RECALL-PCT.
      *
      *    COUNT COMPLETED RECALL VEHICLES FOR THIS CAMPAIGN
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-TOTAL-COMPLETED
               FROM   AUTOSALE.RECALL_VEHICLE
               WHERE  RECALL_ID = :WS-HV-RC-RECALL-ID
                 AND  RECALL_STATUS = 'CM'
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               GO TO 5100-EXIT
           END-IF
      *
      *    COUNT TOTAL AFFECTED VEHICLES FOR THIS CAMPAIGN
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-TOTAL-AFFECTED
               FROM   AUTOSALE.RECALL_VEHICLE
               WHERE  RECALL_ID = :WS-HV-RC-RECALL-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               GO TO 5100-EXIT
           END-IF
      *
      *    UPDATE CAMPAIGN WITH CURRENT COUNTS
      *
           EXEC SQL
               UPDATE AUTOSALE.RECALL_CAMPAIGN
                  SET TOTAL_COMPLETED = :WS-TOTAL-COMPLETED
                    , TOTAL_AFFECTED  = :WS-TOTAL-AFFECTED
               WHERE  RECALL_ID = :WS-HV-RC-RECALL-ID
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-RECALL-UPDATED-CT
               ADD +1 TO WS-TOTAL-PROCESSED
      *
      *        IF ALL COMPLETED, MARK CAMPAIGN COMPLETE
      *
               IF WS-TOTAL-AFFECTED > +0
                   AND WS-TOTAL-COMPLETED >= WS-TOTAL-AFFECTED
                   EXEC SQL
                       UPDATE AUTOSALE.RECALL_CAMPAIGN
                          SET CAMPAIGN_STATUS = 'C'
                       WHERE  RECALL_ID = :WS-HV-RC-RECALL-ID
                   END-EXEC
               END-IF
      *
               PERFORM 6000-CHECK-CHECKPOINT
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATWKL00: ERROR UPDATE RECALL='
                       WS-HV-RC-RECALL-ID ' SQLCODE=' SQLCODE
           END-IF
           .
       5100-EXIT.
           EXIT.
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
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE = +0
               EXEC SQL COMMIT END-EXEC
               MOVE +0 TO WS-RECORDS-SINCE-CHKP
               ADD +1 TO WS-CHECKPOINT-COUNT
               DISPLAY 'BATWKL00: CHECKPOINT #'
                       WS-CHECKPOINT-COUNT
                       ' AT RECORD ' WS-TOTAL-PROCESSED
           ELSE
               DISPLAY 'BATWKL00: CHECKPOINT FAILED - '
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
           DISPLAY 'BATWKL00: ' WS-CR-RETURN-MSG
           .
      *
      ****************************************************************
      *    9000-DISPLAY-STATS                                        *
      ****************************************************************
       9000-DISPLAY-STATS.
      *
           DISPLAY 'BATWKL00: ================================='
           DISPLAY 'BATWKL00: WEEKLY PROCESSING STATISTICS'
           DISPLAY 'BATWKL00: ================================='
           DISPLAY 'BATWKL00: VEHICLES AGED       = '
                   WS-VEH-AGED-CT
           DISPLAY 'BATWKL00: WARRANTY NOTICES     = '
                   WS-WARRANTY-NOTICE-CT
           DISPLAY 'BATWKL00: RECALLS UPDATED      = '
                   WS-RECALL-UPDATED-CT
           DISPLAY 'BATWKL00: TOTAL PROCESSED      = '
                   WS-TOTAL-PROCESSED
           DISPLAY 'BATWKL00: ERRORS               = '
                   WS-ERROR-COUNT
           DISPLAY 'BATWKL00: CHECKPOINTS TAKEN    = '
                   WS-CHECKPOINT-COUNT
           DISPLAY 'BATWKL00: ================================='
           .
      ****************************************************************
      * END OF BATWKL00                                              *
      ****************************************************************
