      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.AUDIT_LOG)                            *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLAUDIT))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLAUDIT-LOG)                                 *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.AUDIT_LOG TABLE
           ( AUDIT_ID         INTEGER NOT NULL,
             USER_ID          CHAR(8) NOT NULL,
             PROGRAM_ID       CHAR(8) NOT NULL,
             ACTION_TYPE      CHAR(3) NOT NULL,
             TABLE_NAME       VARCHAR(30),
             KEY_VALUE        VARCHAR(50),
             OLD_VALUE        VARCHAR(200),
             NEW_VALUE        VARCHAR(200),
             AUDIT_TS         TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.AUDIT_LOG               *
      ******************************************************************
       01  DCLAUDIT-LOG.
           10 AUDIT-ID          PIC S9(9) COMP.
           10 USER-ID           PIC X(8).
           10 PROGRAM-ID        PIC X(8).
           10 ACTION-TYPE       PIC X(3).
           10 TABLE-NAME.
              49 TABLE-NAME-LN  PIC S9(4) COMP.
              49 TABLE-NAME-TX  PIC X(30).
           10 KEY-VALUE.
              49 KEY-VALUE-LN   PIC S9(4) COMP.
              49 KEY-VALUE-TX   PIC X(50).
           10 OLD-VALUE.
              49 OLD-VALUE-LN   PIC S9(4) COMP.
              49 OLD-VALUE-TX   PIC X(200).
           10 NEW-VALUE.
              49 NEW-VALUE-LN   PIC S9(4) COMP.
              49 NEW-VALUE-TX   PIC X(200).
           10 AUDIT-TS          PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 9      *
      ******************************************************************
