       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATPUR00.
      ****************************************************************
      * PROGRAM:    BATPUR00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    PURGE/ARCHIVE PROCESSING. RUNS QUARTERLY TO:     *
      *             1. ARCHIVE COMPLETED REGISTRATIONS OLDER THAN    *
      *                2 YEARS (UPDATE STATUS TO MARK AS ARCHIVED)   *
      *             2. PURGE AUDIT LOG ENTRIES OLDER THAN 3 YEARS    *
      *             3. PURGE EXPIRED RECALL NOTIFICATIONS OLDER      *
      *                THAN 1 YEAR                                    *
      *             4. MAINTAIN COUNTS OF RECORDS ARCHIVED/PURGED    *
      *                PER TABLE                                      *
      *                                                              *
      * CHECKPOINT: EVERY 1000 RECORDS PROCESSED VIA COMCKPL0       *
      *                                                              *
      * TABLES:     AUTOSALE.REGISTRATION       (READ/UPDATE)       *
      *             AUTOSALE.AUDIT_LOG          (READ/DELETE)        *
      *             AUTOSALE.RECALL_NOTIFICATION(READ/DELETE)        *
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
       01  WS-MODULE-ID                PIC X(08) VALUE 'BATPUR00'.
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
           05  WS-REG-ARCHIVED-CT      PIC S9(09) COMP VALUE +0.
           05  WS-AUDIT-PURGED-CT      PIC S9(09) COMP VALUE +0.
           05  WS-NOTIF-PURGED-CT      PIC S9(09) COMP VALUE +0.
           05  WS-TOTAL-PROCESSED      PIC S9(09) COMP VALUE +0.
           05  WS-ERROR-COUNT          PIC S9(09) COMP VALUE +0.
           05  WS-BATCH-DELETE-CT      PIC S9(09) COMP VALUE +0.
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
           05  WS-REG-CUTOFF           PIC X(10) VALUE SPACES.
           05  WS-AUDIT-CUTOFF-TS      PIC X(26) VALUE SPACES.
           05  WS-NOTIF-CUTOFF         PIC X(10) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-DELETE-BATCH-SIZE    PIC S9(09) COMP VALUE +500.
           05  WS-ROWS-AFFECTED       PIC S9(09) COMP VALUE +0.
           05  WS-MORE-TO-DELETE       PIC X(01) VALUE 'Y'.
               88  WS-DELETE-COMPLETE            VALUE 'N'.
               88  WS-DELETE-PENDING             VALUE 'Y'.
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
       01  WS-LOG-PROGRAM-ID          PIC X(08) VALUE 'BATPUR00'.
       01  WS-LOG-ACTION-TYPE         PIC X(03) VALUE SPACES.
       01  WS-LOG-TABLE-NAME          PIC X(30) VALUE SPACES.
       01  WS-LOG-KEY-VALUE           PIC X(50) VALUE SPACES.
       01  WS-LOG-OLD-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-NEW-VALUE           PIC X(200) VALUE SPACES.
       01  WS-LOG-RETURN-CODE         PIC S9(04) COMP VALUE +0.
       01  WS-LOG-ERROR-MSG           PIC X(79) VALUE SPACES.
      *
      *    HOST VARIABLES - REGISTRATION ARCHIVE
      *
       01  WS-HV-REG.
           05  WS-HV-RG-REG-ID        PIC X(12).
           05  WS-HV-RG-STATUS        PIC X(02).
           05  WS-HV-RG-ISSUED-DATE   PIC X(10).
      *
      *    EOF FLAGS
      *
       01  WS-EOF-FLAGS.
           05  WS-EOF-REG             PIC X(01) VALUE 'N'.
               88  WS-REG-DONE                  VALUE 'Y'.
      *
      *    DB2 CURSORS
      *
      *    CURSOR: COMPLETED REGISTRATIONS OLDER THAN 2 YEARS
      *
           EXEC SQL DECLARE CSR_OLD_REG CURSOR FOR
               SELECT REG_ID
                    , REG_STATUS
                    , CHAR(ISSUED_DATE, ISO)
               FROM   AUTOSALE.REGISTRATION
               WHERE  REG_STATUS = 'IS'
                 AND  ISSUED_DATE <= :WS-REG-CUTOFF
               ORDER BY REG_ID
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATPUR00: PURGE/ARCHIVE PROCESSING - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-INIT-CHECKPOINT
      *
           PERFORM 3000-ARCHIVE-REGISTRATIONS
           PERFORM 4000-PURGE-AUDIT-LOG
           PERFORM 5000-PURGE-NOTIFICATIONS
      *
           PERFORM 8000-MARK-COMPLETE
           PERFORM 9000-DISPLAY-STATS
      *
           DISPLAY 'BATPUR00: PURGE/ARCHIVE PROCESSING - END'
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
      *    REGISTRATION CUTOFF = 2 YEARS AGO
      *
           EXEC SQL
               SELECT CHAR(CURRENT DATE - 2 YEARS, ISO)
               INTO :WS-REG-CUTOFF
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    AUDIT LOG CUTOFF = 3 YEARS AGO (AS TIMESTAMP)
      *
           EXEC SQL
               SELECT CHAR(CURRENT TIMESTAMP - 3 YEARS, ISO)
               INTO :WS-AUDIT-CUTOFF-TS
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    NOTIFICATION CUTOFF = 1 YEAR AGO
      *
           EXEC SQL
               SELECT CHAR(CURRENT DATE - 1 YEAR, ISO)
               INTO :WS-NOTIF-CUTOFF
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
      *
           DISPLAY 'BATPUR00: PROCESSING DATE      = '
                   WS-CURRENT-DATE
           DISPLAY 'BATPUR00: REG ARCHIVE CUTOFF   = '
                   WS-REG-CUTOFF
           DISPLAY 'BATPUR00: AUDIT PURGE CUTOFF   = '
                   WS-AUDIT-CUTOFF-TS
           DISPLAY 'BATPUR00: NOTIF PURGE CUTOFF   = '
                   WS-NOTIF-CUTOFF
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
           MOVE 'BATPUR00' TO WS-CF-PROGRAM-NAME
           MOVE 'BATPUR00' TO WS-CF-JOB-NAME
           MOVE 'PURGE   ' TO WS-CF-STEP-NAME
           MOVE +1000      TO WS-CF-CHECKPOINT-FREQ
      *
           INITIALIZE WS-CHKP-DATA
           MOVE 'ASCHKP00' TO WS-CD-EYE-CATCHER
           MOVE 'BATPUR00' TO WS-CD-PROGRAM-ID
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE > +4
               DISPLAY 'BATPUR00: CHECKPOINT INIT FAILED - '
                       WS-CR-RETURN-MSG
               MOVE +16 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           DISPLAY 'BATPUR00: ' WS-CR-RETURN-MSG
      *
           MOVE +1000 TO WS-CHECKPOINT-FREQ
           .
      *
      ****************************************************************
      *    3000-ARCHIVE-REGISTRATIONS - 2+ YEAR OLD REGISTRATIONS    *
      ****************************************************************
       3000-ARCHIVE-REGISTRATIONS.
      *
           DISPLAY 'BATPUR00: PHASE 1 - ARCHIVE OLD REGISTRATIONS'
      *
           EXEC SQL OPEN CSR_OLD_REG END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATPUR00: ERROR OPENING REG CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-REG
      *
           PERFORM UNTIL WS-REG-DONE
               EXEC SQL FETCH CSR_OLD_REG
                   INTO :WS-HV-RG-REG-ID
                      , :WS-HV-RG-STATUS
                      , :WS-HV-RG-ISSUED-DATE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 3100-ARCHIVE-ONE-REG
                   WHEN +100
                       SET WS-REG-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATPUR00: DB2 ERROR FETCH REG - '
                               SQLCODE
                       SET WS-REG-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_OLD_REG END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3100-ARCHIVE-ONE-REG - MARK REGISTRATION AS ARCHIVED      *
      ****************************************************************
       3100-ARCHIVE-ONE-REG.
      *
      *    IN PRODUCTION, THIS WOULD COPY TO ARCHIVE TABLE THEN
      *    DELETE. HERE WE UPDATE STATUS TO INDICATE ARCHIVED.
      *
           EXEC SQL
               UPDATE AUTOSALE.REGISTRATION
                  SET REG_STATUS = 'ER'
                    , UPDATED_TS = CURRENT TIMESTAMP
               WHERE  REG_ID     = :WS-HV-RG-REG-ID
                 AND  REG_STATUS = 'IS'
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-REG-ARCHIVED-CT
               ADD +1 TO WS-TOTAL-PROCESSED
      *
               CALL 'COMLGEL0' USING WS-LOG-USER-ID
                                     WS-LOG-PROGRAM-ID
                                     'UPD'
                                     'REGISTRATION'
                                     WS-HV-RG-REG-ID
                                     'IS'
                                     'ER'
                                     WS-LOG-RETURN-CODE
                                     WS-LOG-ERROR-MSG
      *
               PERFORM 6000-CHECK-CHECKPOINT
           ELSE
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATPUR00: ERROR ARCHIVE REG='
                       WS-HV-RG-REG-ID ' SQLCODE=' SQLCODE
           END-IF
           .
      *
      ****************************************************************
      *    4000-PURGE-AUDIT-LOG - DELETE ENTRIES OLDER THAN 3 YEARS  *
      *    USES BATCHED DELETES TO AVOID LOCK ESCALATION             *
      ****************************************************************
       4000-PURGE-AUDIT-LOG.
      *
           DISPLAY 'BATPUR00: PHASE 2 - PURGE OLD AUDIT LOG ENTRIES'
      *
           MOVE 'Y' TO WS-MORE-TO-DELETE
      *
           PERFORM UNTIL WS-DELETE-COMPLETE
      *
      *        DELETE IN BATCHES OF 500 TO AVOID LOCK ESCALATION
      *
               EXEC SQL
                   DELETE FROM (
                       SELECT 1
                       FROM   AUTOSALE.AUDIT_LOG
                       WHERE  AUDIT_TS < :WS-AUDIT-CUTOFF-TS
                       FETCH FIRST 500 ROWS ONLY
                   )
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       MOVE SQLERRD(3) TO WS-ROWS-AFFECTED
                       ADD WS-ROWS-AFFECTED TO WS-AUDIT-PURGED-CT
                       ADD WS-ROWS-AFFECTED TO WS-TOTAL-PROCESSED
      *
                       IF WS-ROWS-AFFECTED < +500
                           SET WS-DELETE-COMPLETE TO TRUE
                       END-IF
      *
                       PERFORM 6000-CHECK-CHECKPOINT
      *
                   WHEN +100
                       SET WS-DELETE-COMPLETE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATPUR00: ERROR PURGE AUDIT - '
                               SQLCODE
                       ADD +1 TO WS-ERROR-COUNT
                       SET WS-DELETE-COMPLETE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           DISPLAY 'BATPUR00: AUDIT ENTRIES PURGED = '
                   WS-AUDIT-PURGED-CT
           .
      *
      ****************************************************************
      *    5000-PURGE-NOTIFICATIONS - 1+ YEAR OLD EXPIRED RECALLS    *
      ****************************************************************
       5000-PURGE-NOTIFICATIONS.
      *
           DISPLAY 'BATPUR00: PHASE 3 - PURGE EXPIRED NOTIFICATIONS'
      *
           MOVE 'Y' TO WS-MORE-TO-DELETE
      *
           PERFORM UNTIL WS-DELETE-COMPLETE
      *
               EXEC SQL
                   DELETE FROM (
                       SELECT 1
                       FROM   AUTOSALE.RECALL_NOTIFICATION
                       WHERE  NOTIF_DATE < :WS-NOTIF-CUTOFF
                         AND  RESPONSE_FLAG = 'N'
                       FETCH FIRST 500 ROWS ONLY
                   )
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       MOVE SQLERRD(3) TO WS-ROWS-AFFECTED
                       ADD WS-ROWS-AFFECTED TO WS-NOTIF-PURGED-CT
                       ADD WS-ROWS-AFFECTED TO WS-TOTAL-PROCESSED
      *
                       IF WS-ROWS-AFFECTED < +500
                           SET WS-DELETE-COMPLETE TO TRUE
                       END-IF
      *
                       PERFORM 6000-CHECK-CHECKPOINT
      *
                   WHEN +100
                       SET WS-DELETE-COMPLETE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATPUR00: ERROR PURGE NOTIF - '
                               SQLCODE
                       ADD +1 TO WS-ERROR-COUNT
                       SET WS-DELETE-COMPLETE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           DISPLAY 'BATPUR00: NOTIFICATIONS PURGED = '
                   WS-NOTIF-PURGED-CT
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
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE = +0
               EXEC SQL COMMIT END-EXEC
               MOVE +0 TO WS-RECORDS-SINCE-CHKP
               ADD +1 TO WS-CHECKPOINT-COUNT
               DISPLAY 'BATPUR00: CHECKPOINT #'
                       WS-CHECKPOINT-COUNT
                       ' AT RECORD ' WS-TOTAL-PROCESSED
           ELSE
               DISPLAY 'BATPUR00: CHECKPOINT FAILED - '
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
           DISPLAY 'BATPUR00: ' WS-CR-RETURN-MSG
           .
      *
      ****************************************************************
      *    9000-DISPLAY-STATS                                        *
      ****************************************************************
       9000-DISPLAY-STATS.
      *
           DISPLAY 'BATPUR00: ================================='
           DISPLAY 'BATPUR00: PURGE/ARCHIVE STATISTICS'
           DISPLAY 'BATPUR00: ================================='
           DISPLAY 'BATPUR00: REGS ARCHIVED        = '
                   WS-REG-ARCHIVED-CT
           DISPLAY 'BATPUR00: AUDIT ENTRIES PURGED  = '
                   WS-AUDIT-PURGED-CT
           DISPLAY 'BATPUR00: NOTIFICATIONS PURGED  = '
                   WS-NOTIF-PURGED-CT
           DISPLAY 'BATPUR00: TOTAL PROCESSED       = '
                   WS-TOTAL-PROCESSED
           DISPLAY 'BATPUR00: ERRORS                = '
                   WS-ERROR-COUNT
           DISPLAY 'BATPUR00: CHECKPOINTS TAKEN     = '
                   WS-CHECKPOINT-COUNT
           DISPLAY 'BATPUR00: ================================='
           .
      ****************************************************************
      * END OF BATPUR00                                              *
      ****************************************************************
