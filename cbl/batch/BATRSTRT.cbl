       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATRSTRT.
      ****************************************************************
      * PROGRAM:    BATRSTRT                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH UTILITIES                            *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    RESTART UTILITY FOR BATCH ABEND RECOVERY.        *
      *             READS CHECKPOINT RECORDS FROM BATCH_CHECKPOINT,  *
      *             DISPLAYS LAST CHECKPOINT INFO, AND PROVIDES      *
      *             OPTIONS TO RESET CHECKPOINT FOR RE-RUN OR MARK   *
      *             A BATCH JOB AS COMPLETE (SKIP RESTART).          *
      *                                                              *
      * INPUT:      SYSIN DD - CONTROL CARD                          *
      *              COL 1-8   PROGRAM ID                            *
      *              COL 10-15 ACTION (DISP/RESET/COMPL)             *
      *                                                              *
      * TABLES:     AUTOSALE.BATCH_CHECKPOINT (READ/UPDATE/DELETE)   *
      *                                                              *
      * OUTPUT:     SYSPRINT DD - CHECKPOINT STATUS DISPLAY          *
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
           SELECT CONTROL-FILE
               ASSIGN TO SYSIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SYSIN-STATUS.
      *
           SELECT REPORT-FILE
               ASSIGN TO SYSPRINT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SYSPRINT-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  CONTROL-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS.
       01  CONTROL-RECORD                PIC X(80).
      *
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  REPORT-RECORD                 PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                  PIC X(08) VALUE 'BATRSTRT'.
      *
       01  WS-SYSIN-STATUS               PIC X(02) VALUE SPACES.
       01  WS-SYSPRINT-STATUS            PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    CONTROL CARD LAYOUT
      *
       01  WS-CONTROL-CARD.
           05  WS-CC-PROGRAM-ID          PIC X(08).
           05  FILLER                    PIC X(01).
           05  WS-CC-ACTION              PIC X(05).
               88  WS-ACTION-DISPLAY               VALUE 'DISP '.
               88  WS-ACTION-RESET                 VALUE 'RESET'.
               88  WS-ACTION-COMPLETE              VALUE 'COMPL'.
           05  FILLER                    PIC X(66).
      *
      *    EOF FLAG
      *
       01  WS-EOF-FLAG                   PIC X(01) VALUE 'N'.
           88  WS-END-OF-FILE                      VALUE 'Y'.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-CARDS-READ                 PIC S9(04) COMP VALUE +0.
       01  WS-ACTIONS-TAKEN              PIC S9(04) COMP VALUE +0.
      *
      *    HOST VARIABLES - CHECKPOINT
      *
       01  WS-HV-CKPT.
           05  WS-HV-PROGRAM-ID          PIC X(08).
           05  WS-HV-CKPT-SEQ            PIC S9(09) COMP.
           05  WS-HV-CKPT-TIMESTAMP      PIC X(26).
           05  WS-HV-CKPT-LAST-KEY       PIC X(30).
           05  WS-HV-CKPT-RECORDS-IN     PIC S9(09) COMP.
           05  WS-HV-CKPT-RECORDS-OUT    PIC S9(09) COMP.
           05  WS-HV-CKPT-RECORDS-ERR    PIC S9(09) COMP.
           05  WS-HV-CKPT-STATUS         PIC X(02).
      *
      *    DISPLAY FIELDS
      *
       01  WS-DISP-RECORDS-IN            PIC Z(8)9.
       01  WS-DISP-RECORDS-OUT           PIC Z(8)9.
       01  WS-DISP-RECORDS-ERR           PIC Z(8)9.
       01  WS-DISP-CKPT-SEQ              PIC Z(8)9.
      *
      *    REPORT LINES
      *
       01  WS-RPT-HEADER-1.
           05  FILLER                    PIC X(01) VALUE SPACES.
           05  FILLER                    PIC X(40)
               VALUE 'AUTOSALES BATCH RESTART UTILITY          '.
           05  FILLER                    PIC X(30)
               VALUE '         BATRSTRT             '.
           05  FILLER                    PIC X(61) VALUE SPACES.
      *
       01  WS-RPT-HEADER-2.
           05  FILLER                    PIC X(01) VALUE SPACES.
           05  FILLER                    PIC X(70) VALUE ALL '='.
           05  FILLER                    PIC X(61) VALUE SPACES.
      *
       01  WS-RPT-DETAIL.
           05  FILLER                    PIC X(01) VALUE SPACES.
           05  WS-RD-LABEL               PIC X(25).
           05  WS-RD-VALUE               PIC X(50).
           05  FILLER                    PIC X(56) VALUE SPACES.
      *
       01  WS-RPT-ACTION-LINE.
           05  FILLER                    PIC X(01) VALUE SPACES.
           05  FILLER                    PIC X(10) VALUE 'ACTION:   '.
           05  WS-RA-PROGRAM             PIC X(08).
           05  FILLER                    PIC X(03) VALUE ' - '.
           05  WS-RA-RESULT              PIC X(50).
           05  FILLER                    PIC X(60) VALUE SPACES.
      *
       01  WS-RPT-SEPARATOR.
           05  FILLER                    PIC X(01) VALUE SPACES.
           05  FILLER                    PIC X(70) VALUE ALL '-'.
           05  FILLER                    PIC X(61) VALUE SPACES.
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY              PIC 9(04).
           05  WS-CURR-MM                PIC 9(02).
           05  WS-CURR-DD                PIC 9(02).
           05  FILLER                    PIC X(13).
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATRSTRT: RESTART UTILITY - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF  WS-SYSIN-STATUS = '00'
           AND WS-SYSPRINT-STATUS = '00'
               PERFORM 2500-WRITE-REPORT-HEADER
               PERFORM 3000-PROCESS-CONTROL-CARDS
                   UNTIL WS-END-OF-FILE
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATRSTRT: COMPLETE - '
                   WS-CARDS-READ ' CARDS, '
                   WS-ACTIONS-TAKEN ' ACTIONS'
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
           MOVE +0 TO WS-CARDS-READ
           MOVE +0 TO WS-ACTIONS-TAKEN
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN INPUT CONTROL-FILE
      *
           IF WS-SYSIN-STATUS NOT = '00'
               DISPLAY 'BATRSTRT: ERROR OPENING SYSIN - '
                       WS-SYSIN-STATUS
           END-IF
      *
           OPEN OUTPUT REPORT-FILE
      *
           IF WS-SYSPRINT-STATUS NOT = '00'
               DISPLAY 'BATRSTRT: ERROR OPENING SYSPRINT - '
                       WS-SYSPRINT-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    2500-WRITE-REPORT-HEADER                                  *
      ****************************************************************
       2500-WRITE-REPORT-HEADER.
      *
           WRITE REPORT-RECORD FROM WS-RPT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-RPT-HEADER-2
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    3000-PROCESS-CONTROL-CARDS                                *
      ****************************************************************
       3000-PROCESS-CONTROL-CARDS.
      *
           READ CONTROL-FILE INTO WS-CONTROL-CARD
      *
           EVALUATE WS-SYSIN-STATUS
               WHEN '00'
                   ADD +1 TO WS-CARDS-READ
      *
                   IF WS-CC-PROGRAM-ID = SPACES
                       DISPLAY 'BATRSTRT: BLANK CARD - SKIPPED'
                   ELSE
                       EVALUATE TRUE
                           WHEN WS-ACTION-DISPLAY
                               PERFORM 4000-DISPLAY-CHECKPOINT
                           WHEN WS-ACTION-RESET
                               PERFORM 5000-RESET-CHECKPOINT
                           WHEN WS-ACTION-COMPLETE
                               PERFORM 6000-MARK-COMPLETE
                           WHEN OTHER
                               DISPLAY 'BATRSTRT: INVALID ACTION - '
                                       WS-CC-ACTION
                                       ' FOR ' WS-CC-PROGRAM-ID
                       END-EVALUATE
                   END-IF
               WHEN '10'
                   SET WS-END-OF-FILE TO TRUE
               WHEN OTHER
                   DISPLAY 'BATRSTRT: READ ERROR - '
                           WS-SYSIN-STATUS
                   SET WS-END-OF-FILE TO TRUE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4000-DISPLAY-CHECKPOINT                                   *
      ****************************************************************
       4000-DISPLAY-CHECKPOINT.
      *
           EXEC SQL
               SELECT PROGRAM_ID
                    , CHECKPOINT_SEQ
                    , CHECKPOINT_TIMESTAMP
                    , LAST_KEY_VALUE
                    , RECORDS_IN
                    , RECORDS_OUT
                    , RECORDS_ERROR
                    , CHECKPOINT_STATUS
               INTO  :WS-HV-PROGRAM-ID
                   , :WS-HV-CKPT-SEQ
                   , :WS-HV-CKPT-TIMESTAMP
                   , :WS-HV-CKPT-LAST-KEY
                   , :WS-HV-CKPT-RECORDS-IN
                   , :WS-HV-CKPT-RECORDS-OUT
                   , :WS-HV-CKPT-RECORDS-ERR
                   , :WS-HV-CKPT-STATUS
               FROM  AUTOSALE.BATCH_CHECKPOINT
               WHERE PROGRAM_ID = :WS-CC-PROGRAM-ID
               ORDER BY CHECKPOINT_SEQ DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +0
               WRITE REPORT-RECORD FROM WS-RPT-SEPARATOR
                   AFTER ADVANCING 2
      *
               MOVE 'PROGRAM ID:' TO WS-RD-LABEL
               MOVE WS-HV-PROGRAM-ID TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE 'CHECKPOINT STATUS:' TO WS-RD-LABEL
               MOVE WS-HV-CKPT-STATUS TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE WS-HV-CKPT-SEQ TO WS-DISP-CKPT-SEQ
               MOVE 'CHECKPOINT SEQUENCE:' TO WS-RD-LABEL
               MOVE WS-DISP-CKPT-SEQ TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE 'CHECKPOINT TIMESTAMP:' TO WS-RD-LABEL
               MOVE WS-HV-CKPT-TIMESTAMP TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE 'LAST KEY VALUE:' TO WS-RD-LABEL
               MOVE WS-HV-CKPT-LAST-KEY TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE WS-HV-CKPT-RECORDS-IN TO WS-DISP-RECORDS-IN
               MOVE 'RECORDS IN:' TO WS-RD-LABEL
               MOVE WS-DISP-RECORDS-IN TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE WS-HV-CKPT-RECORDS-OUT TO WS-DISP-RECORDS-OUT
               MOVE 'RECORDS OUT:' TO WS-RD-LABEL
               MOVE WS-DISP-RECORDS-OUT TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               MOVE WS-HV-CKPT-RECORDS-ERR TO WS-DISP-RECORDS-ERR
               MOVE 'RECORDS ERROR:' TO WS-RD-LABEL
               MOVE WS-DISP-RECORDS-ERR TO WS-RD-VALUE
               WRITE REPORT-RECORD FROM WS-RPT-DETAIL
                   AFTER ADVANCING 1
      *
               ADD +1 TO WS-ACTIONS-TAKEN
      *
               DISPLAY 'BATRSTRT: DISPLAYED CHECKPOINT FOR '
                       WS-CC-PROGRAM-ID
           ELSE
               IF SQLCODE = +100
                   MOVE WS-CC-PROGRAM-ID TO WS-RA-PROGRAM
                   MOVE 'NO CHECKPOINT RECORD FOUND'
                       TO WS-RA-RESULT
                   WRITE REPORT-RECORD FROM WS-RPT-ACTION-LINE
                       AFTER ADVANCING 2
                   DISPLAY 'BATRSTRT: NO CHECKPOINT FOR '
                           WS-CC-PROGRAM-ID
               ELSE
                   DISPLAY 'BATRSTRT: DB2 ERROR - ' SQLCODE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    5000-RESET-CHECKPOINT - DELETE CHECKPOINT FOR RE-RUN      *
      ****************************************************************
       5000-RESET-CHECKPOINT.
      *
      *    FIRST DISPLAY CURRENT STATE
      *
           PERFORM 4000-DISPLAY-CHECKPOINT
      *
           EXEC SQL
               DELETE FROM AUTOSALE.BATCH_CHECKPOINT
               WHERE  PROGRAM_ID = :WS-CC-PROGRAM-ID
           END-EXEC
      *
           IF SQLCODE = +0
               EXEC SQL COMMIT END-EXEC
      *
               MOVE WS-CC-PROGRAM-ID TO WS-RA-PROGRAM
               MOVE 'CHECKPOINT RESET - READY FOR RE-RUN'
                   TO WS-RA-RESULT
               WRITE REPORT-RECORD FROM WS-RPT-ACTION-LINE
                   AFTER ADVANCING 2
      *
               ADD +1 TO WS-ACTIONS-TAKEN
      *
               DISPLAY 'BATRSTRT: CHECKPOINT RESET FOR '
                       WS-CC-PROGRAM-ID
           ELSE
               IF SQLCODE = +100
                   MOVE WS-CC-PROGRAM-ID TO WS-RA-PROGRAM
                   MOVE 'NO CHECKPOINT TO RESET'
                       TO WS-RA-RESULT
                   WRITE REPORT-RECORD FROM WS-RPT-ACTION-LINE
                       AFTER ADVANCING 2
               ELSE
                   DISPLAY 'BATRSTRT: DB2 ERROR ON DELETE - '
                           SQLCODE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    6000-MARK-COMPLETE - MARK BATCH AS COMPLETE               *
      ****************************************************************
       6000-MARK-COMPLETE.
      *
           EXEC SQL
               UPDATE AUTOSALE.BATCH_CHECKPOINT
               SET    CHECKPOINT_STATUS = 'CP'
               WHERE  PROGRAM_ID = :WS-CC-PROGRAM-ID
           END-EXEC
      *
           IF SQLCODE = +0
               EXEC SQL COMMIT END-EXEC
      *
               MOVE WS-CC-PROGRAM-ID TO WS-RA-PROGRAM
               MOVE 'MARKED COMPLETE - RESTART WILL BE SKIPPED'
                   TO WS-RA-RESULT
               WRITE REPORT-RECORD FROM WS-RPT-ACTION-LINE
                   AFTER ADVANCING 2
      *
               ADD +1 TO WS-ACTIONS-TAKEN
      *
               DISPLAY 'BATRSTRT: MARKED COMPLETE - '
                       WS-CC-PROGRAM-ID
           ELSE
               IF SQLCODE = +100
                   MOVE WS-CC-PROGRAM-ID TO WS-RA-PROGRAM
                   MOVE 'NO CHECKPOINT FOUND TO MARK COMPLETE'
                       TO WS-RA-RESULT
                   WRITE REPORT-RECORD FROM WS-RPT-ACTION-LINE
                       AFTER ADVANCING 2
               ELSE
                   DISPLAY 'BATRSTRT: DB2 ERROR ON UPDATE - '
                           SQLCODE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE CONTROL-FILE
      *
           IF WS-SYSIN-STATUS NOT = '00'
               DISPLAY 'BATRSTRT: ERROR CLOSING SYSIN - '
                       WS-SYSIN-STATUS
           END-IF
      *
           CLOSE REPORT-FILE
      *
           IF WS-SYSPRINT-STATUS NOT = '00'
               DISPLAY 'BATRSTRT: ERROR CLOSING SYSPRINT - '
                       WS-SYSPRINT-STATUS
           END-IF
           .
      ****************************************************************
      * END OF BATRSTRT                                              *
      ****************************************************************
