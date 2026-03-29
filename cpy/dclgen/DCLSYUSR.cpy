      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.SYSTEM_USER)                          *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSYUSR))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSYSTEM-USER)                              *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.SYSTEM_USER TABLE
           ( USER_ID          CHAR(8) NOT NULL,
             USER_NAME        VARCHAR(40) NOT NULL,
             PASSWORD_HASH    CHAR(64) NOT NULL,
             USER_TYPE        CHAR(1) NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             ACTIVE_FLAG      CHAR(1) NOT NULL,
             LAST_LOGIN_TS    TIMESTAMP,
             FAILED_ATTEMPTS  SMALLINT NOT NULL,
             LOCKED_FLAG      CHAR(1) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.SYSTEM_USER             *
      ******************************************************************
       01  DCLSYSTEM-USER.
           10 USER-ID          PIC X(8).
           10 USER-NAME.
              49 USER-NAME-LN  PIC S9(4) COMP.
              49 USER-NAME-TX  PIC X(40).
           10 PASSWORD-HASH    PIC X(64).
           10 USER-TYPE        PIC X(1).
           10 DEALER-CODE      PIC X(5).
           10 ACTIVE-FLAG      PIC X(1).
           10 LAST-LOGIN-TS    PIC X(26).
           10 FAILED-ATTEMPTS  PIC S9(4) COMP.
           10 LOCKED-FLAG      PIC X(1).
           10 CREATED-TS       PIC X(26).
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 11     *
      ******************************************************************
