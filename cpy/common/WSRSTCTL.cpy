      ****************************************************************
      * COPYBOOK: WSRSTCTL                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  RESTART CONTROL TABLE HOST VARIABLES AND          *
      *           WORKING STORAGE FOR DB2 RESTART TRACKING          *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    THE RESTART_CONTROL TABLE TRACKS BATCH JOB        *
      *           PROGRESS SO THAT JOBS CAN BE RESTARTED FROM      *
      *           THE LAST SUCCESSFUL CHECKPOINT IF ABENDED.        *
      *           TABLE: AUTOSALE.RESTART_CONTROL                   *
      ****************************************************************
      *
      *    HOST VARIABLES FOR RESTART_CONTROL TABLE
      *
       01  WS-RST-HOST-VARS.
           05  HV-RST-PROGRAM-ID      PIC X(08).
           05  HV-RST-JOB-NAME        PIC X(08).
           05  HV-RST-STEP-NAME       PIC X(08).
           05  HV-RST-RUN-DATE        PIC X(10).
           05  HV-RST-RUN-TIME        PIC X(08).
           05  HV-RST-STATUS          PIC X(01).
               88  HV-RST-STARTED                  VALUE 'S'.
               88  HV-RST-IN-PROGRESS              VALUE 'P'.
               88  HV-RST-COMPLETED                VALUE 'C'.
               88  HV-RST-ABENDED                  VALUE 'A'.
               88  HV-RST-RESTARTED                VALUE 'R'.
           05  HV-RST-CHECKPOINT-ID   PIC X(08).
           05  HV-RST-LAST-KEY        PIC X(30).
           05  HV-RST-RECORDS-IN      PIC S9(09)   COMP.
           05  HV-RST-RECORDS-OUT     PIC S9(09)   COMP.
           05  HV-RST-RECORDS-ERR     PIC S9(09)   COMP.
           05  HV-RST-TOTAL-AMT       PIC S9(13)V99 COMP-3.
           05  HV-RST-CHKP-TIMESTAMP  PIC X(26).
           05  HV-RST-START-TIMESTAMP PIC X(26).
           05  HV-RST-END-TIMESTAMP   PIC X(26).
           05  HV-RST-RESTART-COUNT   PIC S9(04)   COMP.
           05  HV-RST-USER-DATA       PIC X(100).
      *
      *    NULL INDICATORS FOR RESTART_CONTROL
      *
       01  WS-RST-NULL-IND.
           05  NI-RST-PROGRAM-ID      PIC S9(04)   COMP
                                                    VALUE +0.
           05  NI-RST-JOB-NAME        PIC S9(04)   COMP
                                                    VALUE +0.
           05  NI-RST-STEP-NAME       PIC S9(04)   COMP
                                                    VALUE +0.
           05  NI-RST-END-TIMESTAMP   PIC S9(04)   COMP
                                                    VALUE -1.
           05  NI-RST-USER-DATA       PIC S9(04)   COMP
                                                    VALUE -1.
      *
      *    SQL STATEMENTS FOR RESTART CONTROL
      *
      *    READ RESTART CONTROL ROW
      *
           EXEC SQL
               SELECT PROGRAM_ID
                    , JOB_NAME
                    , STEP_NAME
                    , RUN_DATE
                    , RUN_TIME
                    , STATUS
                    , CHECKPOINT_ID
                    , LAST_KEY_VALUE
                    , RECORDS_IN
                    , RECORDS_OUT
                    , RECORDS_ERR
                    , TOTAL_AMOUNT
                    , CHKP_TIMESTAMP
                    , START_TIMESTAMP
                    , END_TIMESTAMP
                    , RESTART_COUNT
                    , USER_DATA
               INTO  :HV-RST-PROGRAM-ID
                    , :HV-RST-JOB-NAME
                    , :HV-RST-STEP-NAME
                    , :HV-RST-RUN-DATE
                    , :HV-RST-RUN-TIME
                    , :HV-RST-STATUS
                    , :HV-RST-CHECKPOINT-ID
                    , :HV-RST-LAST-KEY
                    , :HV-RST-RECORDS-IN
                    , :HV-RST-RECORDS-OUT
                    , :HV-RST-RECORDS-ERR
                    , :HV-RST-TOTAL-AMT
                    , :HV-RST-CHKP-TIMESTAMP
                    , :HV-RST-START-TIMESTAMP
                    , :HV-RST-END-TIMESTAMP
                       :NI-RST-END-TIMESTAMP
                    , :HV-RST-RESTART-COUNT
                    , :HV-RST-USER-DATA
                       :NI-RST-USER-DATA
               FROM  AUTOSALE.RESTART_CONTROL
               WHERE PROGRAM_ID = :HV-RST-PROGRAM-ID
                 AND JOB_NAME   = :HV-RST-JOB-NAME
                 AND STATUS IN ('S', 'P', 'A')
               ORDER BY START_TIMESTAMP DESC
               FETCH FIRST 1 ROW ONLY
               WITH UR
           END-EXEC.
      *
      *    INSERT NEW RESTART CONTROL ROW
      *
           EXEC SQL
               INSERT INTO AUTOSALE.RESTART_CONTROL
                    ( PROGRAM_ID
                    , JOB_NAME
                    , STEP_NAME
                    , RUN_DATE
                    , RUN_TIME
                    , STATUS
                    , CHECKPOINT_ID
                    , LAST_KEY_VALUE
                    , RECORDS_IN
                    , RECORDS_OUT
                    , RECORDS_ERR
                    , TOTAL_AMOUNT
                    , CHKP_TIMESTAMP
                    , START_TIMESTAMP
                    , RESTART_COUNT
                    )
               VALUES
                    ( :HV-RST-PROGRAM-ID
                    , :HV-RST-JOB-NAME
                    , :HV-RST-STEP-NAME
                    , :HV-RST-RUN-DATE
                    , :HV-RST-RUN-TIME
                    , :HV-RST-STATUS
                    , :HV-RST-CHECKPOINT-ID
                    , :HV-RST-LAST-KEY
                    , :HV-RST-RECORDS-IN
                    , :HV-RST-RECORDS-OUT
                    , :HV-RST-RECORDS-ERR
                    , :HV-RST-TOTAL-AMT
                    , :HV-RST-CHKP-TIMESTAMP
                    , :HV-RST-START-TIMESTAMP
                    , :HV-RST-RESTART-COUNT
                    )
           END-EXEC.
      *
      *    UPDATE RESTART CONTROL ROW (CHECKPOINT UPDATE)
      *
           EXEC SQL
               UPDATE AUTOSALE.RESTART_CONTROL
                  SET STATUS          = :HV-RST-STATUS
                    , CHECKPOINT_ID   = :HV-RST-CHECKPOINT-ID
                    , LAST_KEY_VALUE  = :HV-RST-LAST-KEY
                    , RECORDS_IN      = :HV-RST-RECORDS-IN
                    , RECORDS_OUT     = :HV-RST-RECORDS-OUT
                    , RECORDS_ERR     = :HV-RST-RECORDS-ERR
                    , TOTAL_AMOUNT    = :HV-RST-TOTAL-AMT
                    , CHKP_TIMESTAMP  = :HV-RST-CHKP-TIMESTAMP
                    , RESTART_COUNT   = :HV-RST-RESTART-COUNT
               WHERE PROGRAM_ID      = :HV-RST-PROGRAM-ID
                 AND JOB_NAME        = :HV-RST-JOB-NAME
                 AND START_TIMESTAMP = :HV-RST-START-TIMESTAMP
           END-EXEC.
      *
      *    UPDATE RESTART CONTROL ROW (JOB COMPLETION)
      *
           EXEC SQL
               UPDATE AUTOSALE.RESTART_CONTROL
                  SET STATUS          = :HV-RST-STATUS
                    , END_TIMESTAMP   = :HV-RST-END-TIMESTAMP
                    , RECORDS_IN      = :HV-RST-RECORDS-IN
                    , RECORDS_OUT     = :HV-RST-RECORDS-OUT
                    , RECORDS_ERR     = :HV-RST-RECORDS-ERR
                    , TOTAL_AMOUNT    = :HV-RST-TOTAL-AMT
               WHERE PROGRAM_ID      = :HV-RST-PROGRAM-ID
                 AND JOB_NAME        = :HV-RST-JOB-NAME
                 AND START_TIMESTAMP = :HV-RST-START-TIMESTAMP
           END-EXEC.
      *
      *    WORKING STORAGE FOR RESTART LOGIC
      *
       01  WS-RST-WORK-FIELDS.
           05  WS-RST-SAVE-SQLCODE    PIC S9(09)   COMP
                                                    VALUE +0.
           05  WS-RST-FOUND-FLAG      PIC X(01)    VALUE 'N'.
               88  WS-RST-ROW-FOUND                VALUE 'Y'.
               88  WS-RST-ROW-NOT-FOUND            VALUE 'N'.
      ****************************************************************
      * END OF WSRSTCTL                                              *
      ****************************************************************
