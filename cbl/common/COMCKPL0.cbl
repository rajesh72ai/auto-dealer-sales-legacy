       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMCKPL0.
      ****************************************************************
      * PROGRAM:  COMCKPL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - CHECKPOINT/RESTART HANDLER MODULE         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  MANAGES IMS CHECKPOINT/RESTART FOR BATCH PROGRAMS  *
      *           ISSUES CHKP AND XRST CALLS TO IMS DL/I AND        *
      *           TRACKS RESTART CONTROL IN DB2 TABLE.               *
      * CALLABLE: YES - VIA CALL 'COMCKPL0' USING LS-CHKP-FUNCTION  *
      *                                            LS-CHKP-DATA     *
      *                                            LS-CHKP-RESULT   *
      * FUNCTIONS:                                                   *
      *   INIT - INITIALIZE CHECKPOINT, CHECK FOR PENDING RESTART    *
      *   CHKP - ISSUE IMS SYMBOLIC CHECKPOINT                      *
      *   XRST - ISSUE EXTENDED RESTART (RESTORE CHECKPOINT DATA)   *
      *   DONE - MARK JOB COMPLETE IN RESTART_CONTROL TABLE         *
      *   FAIL - MARK JOB FAILED IN RESTART_CONTROL TABLE           *
      * TABLES:   AUTOSALE.RESTART_CONTROL                           *
      * DL/I:     CHKP, XRST CALLS VIA CBLTDLI                     *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-3090.
       OBJECT-COMPUTER. IBM-3090.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       01  WS-PROGRAM-FIELDS.
           05  WS-PROGRAM-NAME           PIC X(08)
                                          VALUE 'COMCKPL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    COPY IN SQLCA FOR DB2 OPERATIONS
      *
           COPY WSSQLCA.
      *
      *    COPY IN RESTART CONTROL HOST VARIABLES
      *
           COPY DCLRSTCT.
      *
      *    IMS DL/I FUNCTION CODES
      *
       01  WS-DLI-FUNCTIONS.
           05  WS-FUNC-CHKP              PIC X(04)    VALUE 'CHKP'.
           05  WS-FUNC-XRST              PIC X(04)    VALUE 'XRST'.
           05  WS-FUNC-PCB               PIC X(04)    VALUE 'PCB '.
      *
      *    IMS PCB ADDRESS LIST
      *
       01  WS-IO-PCB-PTR                 POINTER.
       01  WS-IO-PCB-MASK.
           05  WS-IO-LTERM               PIC X(08).
           05  FILLER                    PIC X(02).
           05  WS-IO-STATUS              PIC X(02).
      *
      *    CHECKPOINT WORK FIELDS
      *
       01  WS-CHKP-WORK-FIELDS.
           05  WS-CHKP-IO-AREA           PIC X(08)    VALUE SPACES.
           05  WS-CHKP-AREA-LEN          PIC S9(09)   COMP
                                                       VALUE +240.
           05  WS-CHKP-SEQ-NUM           PIC 9(08)    VALUE 0.
           05  WS-CHKP-SEQ-DISP          PIC X(08)    VALUE SPACES.
           05  WS-XRST-AREA-LEN          PIC S9(09)   COMP
                                                       VALUE +240.
      *
      *    CHECKPOINT DATA SAVE AREA (240 BYTES)
      *
       01  WS-CHKP-SAVE-AREA.
           05  WS-CHKP-EYE-CATCHER      PIC X(08)
                                          VALUE 'ASCHKP00'.
           05  WS-CHKP-PGM-ID           PIC X(08)    VALUE SPACES.
           05  WS-CHKP-TIMESTAMP        PIC X(26)    VALUE SPACES.
           05  WS-CHKP-LAST-KEY         PIC X(50)    VALUE SPACES.
           05  WS-CHKP-REC-COUNT        PIC S9(09)   COMP
                                                       VALUE +0.
           05  WS-CHKP-FILLER           PIC X(139)   VALUE SPACES.
      *
      *    DATE/TIME FIELDS
      *
       01  WS-DATETIME-FIELDS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURR-YYYY          PIC 9(04).
               10  WS-CURR-MM            PIC 9(02).
               10  WS-CURR-DD            PIC 9(02).
           05  WS-CURRENT-TIME-DATA.
               10  WS-CURR-HH            PIC 9(02).
               10  WS-CURR-MN            PIC 9(02).
               10  WS-CURR-SS            PIC 9(02).
               10  WS-CURR-HS            PIC 9(02).
           05  WS-DIFF-FROM-GMT          PIC S9(04).
           05  WS-FORMATTED-TS           PIC X(26)    VALUE SPACES.
      *
      *    NULL INDICATORS FOR RESTART_CONTROL
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-LAST-KEY            PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-NI-COMPLETED-TS        PIC S9(04)   COMP
                                                       VALUE -1.
      *
      *    DB2 CURSOR DECLARATION FOR RESTART CHECK
      *
           EXEC SQL
               DECLARE CSR_RESTART CURSOR FOR
               SELECT JOB_NAME
                    , STEP_NAME
                    , CHECKPOINT_ID
                    , RECORDS_PROCESSED
                    , LAST_KEY_VALUE
                    , RESTART_FLAG
                    , STATUS
                    , STARTED_TS
                    , CHECKPOINT_TS
               FROM   AUTOSALE.RESTART_CONTROL
               WHERE  JOB_NAME = :JOB-NAME
                 AND  STATUS IN ('S', 'P', 'A')
               ORDER BY STARTED_TS DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC.
      *
       LINKAGE SECTION.
      *
      *    CHECKPOINT FUNCTION REQUEST
      *
       01  LS-CHKP-FUNCTION.
           05  LS-CF-FUNC-CODE           PIC X(04).
               88  LS-CF-INIT                          VALUE 'INIT'.
               88  LS-CF-CHKP                          VALUE 'CHKP'.
               88  LS-CF-XRST                          VALUE 'XRST'.
               88  LS-CF-DONE                          VALUE 'DONE'.
               88  LS-CF-FAIL                          VALUE 'FAIL'.
           05  LS-CF-PROGRAM-NAME        PIC X(08).
           05  LS-CF-JOB-NAME            PIC X(08).
           05  LS-CF-STEP-NAME           PIC X(08).
           05  LS-CF-CHECKPOINT-FREQ     PIC S9(07)   COMP-3.
      *
      *    CHECKPOINT DATA AREA (PASSED TO/FROM CALLER)
      *
       01  LS-CHKP-DATA.
           05  LS-CD-EYE-CATCHER        PIC X(08).
           05  LS-CD-PROGRAM-ID          PIC X(08).
           05  LS-CD-TIMESTAMP           PIC X(26).
           05  LS-CD-LAST-KEY            PIC X(50).
           05  LS-CD-RECORDS-PROCESSED   PIC S9(09)   COMP.
           05  LS-CD-USER-DATA           PIC X(139).
      *
      *    CHECKPOINT RESULT AREA
      *
       01  LS-CHKP-RESULT.
           05  LS-CR-RETURN-CODE         PIC S9(04)   COMP.
           05  LS-CR-RETURN-MSG          PIC X(79).
           05  LS-CR-RESTART-FLAG        PIC X(01).
               88  LS-CR-IS-RESTART                    VALUE 'Y'.
               88  LS-CR-NORMAL-START                  VALUE 'N'.
           05  LS-CR-CHECKPOINT-ID       PIC X(20).
           05  LS-CR-RECORDS-PROCESSED   PIC S9(09)   COMP.
           05  LS-CR-LAST-KEY            PIC X(50).
           05  LS-CR-IMS-STATUS          PIC X(02).
           05  LS-CR-SQLCODE             PIC S9(09)   COMP.
           05  LS-CR-CHECKPOINT-COUNT    PIC S9(07)   COMP-3.
      *
      *    I/O PCB PASSED BY CALLER FOR DL/I CALLS
      *
       01  LS-IO-PCB.
           05  LS-IO-LTERM               PIC X(08).
           05  FILLER                    PIC X(02).
           05  LS-IO-STATUS              PIC X(02).
      *
       PROCEDURE DIVISION USING LS-CHKP-FUNCTION
                                LS-CHKP-DATA
                                LS-CHKP-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           EVALUATE TRUE
               WHEN LS-CF-INIT
                   PERFORM 2000-INIT-CHECKPOINT
               WHEN LS-CF-CHKP
                   PERFORM 3000-ISSUE-CHECKPOINT
               WHEN LS-CF-XRST
                   PERFORM 4000-ISSUE-RESTART
               WHEN LS-CF-DONE
                   PERFORM 5000-MARK-COMPLETE
               WHEN LS-CF-FAIL
                   PERFORM 6000-MARK-FAILED
               WHEN OTHER
                   MOVE +16 TO LS-CR-RETURN-CODE
                   STRING 'COMCKPL0: INVALID FUNCTION: '
                          LS-CF-FUNC-CODE
                          DELIMITED BY SIZE
                          INTO LS-CR-RETURN-MSG
           END-EVALUATE
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR RESULT AND GET CURRENT TIMESTAMP  *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-CHKP-RESULT
           MOVE +0  TO LS-CR-RETURN-CODE
           MOVE 'N' TO LS-CR-RESTART-FLAG
      *
      *    GET CURRENT DATE AND TIME
      *
           MOVE FUNCTION CURRENT-DATE
               TO WS-CURRENT-DATE-DATA
                  WS-CURRENT-TIME-DATA
                  WS-DIFF-FROM-GMT
      *
      *    FORMAT DB2 TIMESTAMP
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD   '-'
                  WS-CURR-HH   '.'
                  WS-CURR-MN   '.'
                  WS-CURR-SS   '.000000'
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-TS
           .
      *
      ****************************************************************
      *    2000-INIT-CHECKPOINT - CHECK FOR PENDING RESTART          *
      *    LOOK IN RESTART_CONTROL FOR ABENDED/IN-PROGRESS ROWS     *
      ****************************************************************
       2000-INIT-CHECKPOINT.
      *
           MOVE LS-CF-JOB-NAME TO JOB-NAME
      *
      *    CHECK FOR PRIOR ABENDED RUN
      *
           EXEC SQL
               SELECT JOB_NAME
                    , STEP_NAME
                    , CHECKPOINT_ID
                    , RECORDS_PROCESSED
                    , LAST_KEY_VALUE
                    , RESTART_FLAG
                    , STATUS
                    , STARTED_TS
                    , CHECKPOINT_TS
               INTO  :JOB-NAME
                    , :STEP-NAME
                    , :CHECKPOINT-ID
                    , :RECORDS-PROCESSED
                    , :LAST-KEY-VALUE
                       :WS-NI-LAST-KEY
                    , :RESTART-FLAG
                    , :STATUS
                    , :STARTED-TS
                    , :CHECKPOINT-TS
               FROM   AUTOSALE.RESTART_CONTROL
               WHERE  JOB_NAME = :JOB-NAME
                 AND  STATUS IN ('S', 'P', 'A')
               ORDER BY STARTED_TS DESC
               FETCH FIRST 1 ROW ONLY
               WITH UR
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
      *            FOUND PRIOR RUN - CHECK IF RESTART NEEDED
                   IF STATUS = 'A'
      *                ABENDED RUN - SET RESTART FLAG
                       MOVE 'Y' TO LS-CR-RESTART-FLAG
                       MOVE CHECKPOINT-ID
                           TO LS-CR-CHECKPOINT-ID
                       MOVE RECORDS-PROCESSED
                           TO LS-CR-RECORDS-PROCESSED
                       IF WS-NI-LAST-KEY >= +0
                           MOVE LAST-KEY-VALUE-TX
                               TO LS-CR-LAST-KEY
                       END-IF
                       MOVE 'R' TO STATUS
                       PERFORM 2100-UPDATE-RESTART-STATUS
                       MOVE +4 TO LS-CR-RETURN-CODE
                       MOVE
                       'COMCKPL0: RESTART PENDING - PRIOR RUN ABENDED'
                           TO LS-CR-RETURN-MSG
                   ELSE
      *                IN-PROGRESS - POSSIBLE STILL RUNNING
                       MOVE 'N' TO LS-CR-RESTART-FLAG
                       MOVE +4 TO LS-CR-RETURN-CODE
                       MOVE
                       'COMCKPL0: PRIOR RUN IN PROGRESS - CHECK JOB'
                           TO LS-CR-RETURN-MSG
                   END-IF
               WHEN +100
      *            NO PRIOR RUN - NORMAL START
                   MOVE 'N' TO LS-CR-RESTART-FLAG
                   PERFORM 2200-INSERT-NEW-RUN
                   MOVE +0 TO LS-CR-RETURN-CODE
                   MOVE 'COMCKPL0: CHECKPOINT INITIALIZED - NORMAL RUN'
                       TO LS-CR-RETURN-MSG
               WHEN OTHER
                   MOVE SQLCODE TO LS-CR-SQLCODE
                   MOVE +16 TO LS-CR-RETURN-CODE
                   MOVE 'COMCKPL0: DB2 ERROR ON RESTART_CONTROL READ'
                       TO LS-CR-RETURN-MSG
           END-EVALUATE
           .
      *
      ****************************************************************
      *    2100-UPDATE-RESTART-STATUS - SET STATUS TO RESTARTED      *
      ****************************************************************
       2100-UPDATE-RESTART-STATUS.
      *
           EXEC SQL
               UPDATE AUTOSALE.RESTART_CONTROL
                  SET STATUS       = :STATUS
                    , RESTART_FLAG = 'Y'
               WHERE  JOB_NAME    = :JOB-NAME
                 AND  STARTED_TS  = :STARTED-TS
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO LS-CR-SQLCODE
           END-IF
           .
      *
      ****************************************************************
      *    2200-INSERT-NEW-RUN - INSERT NEW RESTART_CONTROL ROW      *
      ****************************************************************
       2200-INSERT-NEW-RUN.
      *
           MOVE LS-CF-JOB-NAME    TO JOB-NAME
           MOVE LS-CF-STEP-NAME   TO STEP-NAME
           MOVE SPACES             TO CHECKPOINT-ID
           MOVE +0                 TO RECORDS-PROCESSED
           MOVE +0                 TO LAST-KEY-VALUE-LN
           MOVE SPACES             TO LAST-KEY-VALUE-TX
           MOVE 'N'                TO RESTART-FLAG
           MOVE 'S'                TO STATUS
           MOVE WS-FORMATTED-TS   TO STARTED-TS
           MOVE WS-FORMATTED-TS   TO CHECKPOINT-TS
      *
           EXEC SQL
               INSERT INTO AUTOSALE.RESTART_CONTROL
                    ( JOB_NAME
                    , STEP_NAME
                    , CHECKPOINT_ID
                    , RECORDS_PROCESSED
                    , LAST_KEY_VALUE
                    , RESTART_FLAG
                    , STATUS
                    , STARTED_TS
                    , CHECKPOINT_TS
                    )
               VALUES
                    ( :JOB-NAME
                    , :STEP-NAME
                    , :CHECKPOINT-ID
                    , :RECORDS-PROCESSED
                    , :LAST-KEY-VALUE
                    , :RESTART-FLAG
                    , :STATUS
                    , :STARTED-TS
                    , :CHECKPOINT-TS
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO LS-CR-SQLCODE
               MOVE +16 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: DB2 ERROR INSERTING RESTART_CONTROL'
                   TO LS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    3000-ISSUE-CHECKPOINT - ISSUE IMS SYMBOLIC CHECKPOINT     *
      *    CALL CBLTDLI WITH CHKP FUNCTION                          *
      ****************************************************************
       3000-ISSUE-CHECKPOINT.
      *
      *    INCREMENT CHECKPOINT SEQUENCE
      *
           ADD +1 TO WS-CHKP-SEQ-NUM
      *
      *    FORMAT CHECKPOINT ID (PROGRAM + SEQUENCE)
      *
           MOVE WS-CHKP-SEQ-NUM TO WS-CHKP-SEQ-DISP
           STRING LS-CF-PROGRAM-NAME(1:4)
                  WS-CHKP-SEQ-DISP(5:4)
                  DELIMITED BY SIZE
                  INTO WS-CHKP-IO-AREA
      *
      *    POPULATE CHECKPOINT SAVE AREA FROM CALLER DATA
      *
           MOVE LS-CD-EYE-CATCHER      TO WS-CHKP-EYE-CATCHER
           MOVE LS-CD-PROGRAM-ID        TO WS-CHKP-PGM-ID
           MOVE WS-FORMATTED-TS         TO WS-CHKP-TIMESTAMP
           MOVE LS-CD-LAST-KEY          TO WS-CHKP-LAST-KEY
           MOVE LS-CD-RECORDS-PROCESSED TO WS-CHKP-REC-COUNT
      *
      *    ISSUE SYMBOLIC CHECKPOINT TO IMS
      *
           CALL 'CBLTDLI' USING WS-FUNC-CHKP
                                LS-IO-PCB
                                WS-CHKP-IO-AREA
                                WS-CHKP-SAVE-AREA
                                WS-CHKP-AREA-LEN
      *
           MOVE LS-IO-STATUS TO LS-CR-IMS-STATUS
      *
           IF LS-IO-STATUS = '  '
      *
      *        CHECKPOINT SUCCESSFUL - UPDATE DB2 TRACKING
      *
               MOVE 'P'                 TO STATUS
               MOVE WS-CHKP-IO-AREA    TO CHECKPOINT-ID
               MOVE LS-CD-RECORDS-PROCESSED
                                         TO RECORDS-PROCESSED
               MOVE FUNCTION LENGTH(LS-CD-LAST-KEY)
                                         TO LAST-KEY-VALUE-LN
               MOVE LS-CD-LAST-KEY      TO LAST-KEY-VALUE-TX
               MOVE WS-FORMATTED-TS     TO CHECKPOINT-TS
      *
               EXEC SQL
                   UPDATE AUTOSALE.RESTART_CONTROL
                      SET STATUS          = :STATUS
                        , CHECKPOINT_ID   = :CHECKPOINT-ID
                        , RECORDS_PROCESSED
                                          = :RECORDS-PROCESSED
                        , LAST_KEY_VALUE  = :LAST-KEY-VALUE
                        , CHECKPOINT_TS   = :CHECKPOINT-TS
                   WHERE  JOB_NAME        = :JOB-NAME
                     AND  STATUS IN ('S', 'P', 'R')
                     AND  STARTED_TS      = :STARTED-TS
               END-EXEC
      *
               ADD +1 TO LS-CR-CHECKPOINT-COUNT
               MOVE WS-CHKP-IO-AREA   TO LS-CR-CHECKPOINT-ID
               MOVE LS-CD-RECORDS-PROCESSED
                                        TO LS-CR-RECORDS-PROCESSED
               MOVE +0 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: CHECKPOINT ISSUED SUCCESSFULLY'
                   TO LS-CR-RETURN-MSG
           ELSE
      *        CHECKPOINT FAILED
               MOVE +12 TO LS-CR-RETURN-CODE
               STRING 'COMCKPL0: IMS CHKP FAILED - STATUS='
                      LS-IO-STATUS
                      DELIMITED BY SIZE
                      INTO LS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    4000-ISSUE-RESTART - ISSUE IMS EXTENDED RESTART           *
      *    CALL CBLTDLI WITH XRST FUNCTION TO RESTORE DATA          *
      ****************************************************************
       4000-ISSUE-RESTART.
      *
      *    SET UP XRST I/O AREA WITH LAST CHECKPOINT ID
      *
           MOVE LS-CR-CHECKPOINT-ID TO WS-CHKP-IO-AREA
      *
      *    ISSUE EXTENDED RESTART TO IMS
      *
           CALL 'CBLTDLI' USING WS-FUNC-XRST
                                LS-IO-PCB
                                WS-CHKP-IO-AREA
                                WS-CHKP-SAVE-AREA
                                WS-XRST-AREA-LEN
      *
           MOVE LS-IO-STATUS TO LS-CR-IMS-STATUS
      *
           IF LS-IO-STATUS = '  '
      *
      *        RESTART SUCCESSFUL - RETURN CHECKPOINT DATA TO CALLER
      *
               MOVE WS-CHKP-EYE-CATCHER   TO LS-CD-EYE-CATCHER
               MOVE WS-CHKP-PGM-ID        TO LS-CD-PROGRAM-ID
               MOVE WS-CHKP-TIMESTAMP     TO LS-CD-TIMESTAMP
               MOVE WS-CHKP-LAST-KEY      TO LS-CD-LAST-KEY
               MOVE WS-CHKP-REC-COUNT     TO LS-CD-RECORDS-PROCESSED
               MOVE WS-CHKP-REC-COUNT     TO LS-CR-RECORDS-PROCESSED
               MOVE WS-CHKP-LAST-KEY      TO LS-CR-LAST-KEY
               MOVE +0 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: XRST COMPLETED - DATA RESTORED'
                   TO LS-CR-RETURN-MSG
           ELSE
      *        RESTART FAILED
               MOVE +12 TO LS-CR-RETURN-CODE
               STRING 'COMCKPL0: IMS XRST FAILED - STATUS='
                      LS-IO-STATUS
                      DELIMITED BY SIZE
                      INTO LS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    5000-MARK-COMPLETE - UPDATE STATUS TO COMPLETE            *
      ****************************************************************
       5000-MARK-COMPLETE.
      *
           MOVE 'C'               TO STATUS
           MOVE WS-FORMATTED-TS   TO COMPLETED-TS
           MOVE LS-CD-RECORDS-PROCESSED TO RECORDS-PROCESSED
      *
           EXEC SQL
               UPDATE AUTOSALE.RESTART_CONTROL
                  SET STATUS          = :STATUS
                    , COMPLETED_TS    = :COMPLETED-TS
                    , RECORDS_PROCESSED
                                      = :RECORDS-PROCESSED
               WHERE  JOB_NAME        = :JOB-NAME
                 AND  STATUS IN ('S', 'P', 'R')
                 AND  STARTED_TS      = :STARTED-TS
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE +0 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: JOB MARKED COMPLETE'
                   TO LS-CR-RETURN-MSG
           ELSE
               MOVE SQLCODE TO LS-CR-SQLCODE
               MOVE +8 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: ERROR UPDATING COMPLETION STATUS'
                   TO LS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    6000-MARK-FAILED - UPDATE STATUS TO FAILED/ABENDED       *
      ****************************************************************
       6000-MARK-FAILED.
      *
           MOVE 'A'               TO STATUS
           MOVE WS-FORMATTED-TS   TO CHECKPOINT-TS
           MOVE LS-CD-RECORDS-PROCESSED TO RECORDS-PROCESSED
      *
           EXEC SQL
               UPDATE AUTOSALE.RESTART_CONTROL
                  SET STATUS          = :STATUS
                    , CHECKPOINT_TS   = :CHECKPOINT-TS
                    , RECORDS_PROCESSED
                                      = :RECORDS-PROCESSED
               WHERE  JOB_NAME        = :JOB-NAME
                 AND  STATUS IN ('S', 'P', 'R')
                 AND  STARTED_TS      = :STARTED-TS
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE +0 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: JOB MARKED FAILED/ABENDED'
                   TO LS-CR-RETURN-MSG
           ELSE
               MOVE SQLCODE TO LS-CR-SQLCODE
               MOVE +8 TO LS-CR-RETURN-CODE
               MOVE 'COMCKPL0: ERROR UPDATING FAILED STATUS'
                   TO LS-CR-RETURN-MSG
           END-IF
           .
      ****************************************************************
      * END OF COMCKPL0                                               *
      ****************************************************************
