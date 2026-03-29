      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.RESTART_CONTROL)                      *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLRSTCT))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLRESTART-CONTROL)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.RESTART_CONTROL TABLE
           ( JOB_NAME         CHAR(8) NOT NULL,
             STEP_NAME        CHAR(8) NOT NULL,
             CHECKPOINT_ID    CHAR(20) NOT NULL,
             RECORDS_PROCESSED INTEGER NOT NULL,
             LAST_KEY_VALUE   VARCHAR(50),
             RESTART_FLAG     CHAR(1) NOT NULL,
             STATUS           CHAR(1) NOT NULL,
             STARTED_TS       TIMESTAMP NOT NULL,
             CHECKPOINT_TS    TIMESTAMP NOT NULL,
             COMPLETED_TS     TIMESTAMP
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.RESTART_CONTROL         *
      ******************************************************************
       01  DCLRESTART-CONTROL.
           10 JOB-NAME          PIC X(8).
           10 STEP-NAME         PIC X(8).
           10 CHECKPOINT-ID     PIC X(20).
           10 RECORDS-PROCESSED PIC S9(9) COMP.
           10 LAST-KEY-VALUE.
              49 LAST-KEY-VALUE-LN PIC S9(4) COMP.
              49 LAST-KEY-VALUE-TX PIC X(50).
           10 RESTART-FLAG      PIC X(1).
           10 STATUS            PIC X(1).
           10 STARTED-TS        PIC X(26).
           10 CHECKPOINT-TS     PIC X(26).
           10 COMPLETED-TS      PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10     *
      ******************************************************************
