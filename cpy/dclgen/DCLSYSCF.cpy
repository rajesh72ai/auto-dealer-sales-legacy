      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.SYSTEM_CONFIG)                        *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSYSCF))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSYSTEM-CONFIG)                             *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.SYSTEM_CONFIG TABLE
           ( CONFIG_KEY       VARCHAR(30) NOT NULL,
             CONFIG_VALUE     VARCHAR(100) NOT NULL,
             CONFIG_DESC      VARCHAR(60),
             UPDATED_BY       CHAR(8),
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.SYSTEM_CONFIG           *
      ******************************************************************
       01  DCLSYSTEM-CONFIG.
           10 CONFIG-KEY.
              49 CONFIG-KEY-LN  PIC S9(4) COMP.
              49 CONFIG-KEY-TX  PIC X(30).
           10 CONFIG-VALUE.
              49 CONFIG-VALUE-LN PIC S9(4) COMP.
              49 CONFIG-VALUE-TX PIC X(100).
           10 CONFIG-DESC.
              49 CONFIG-DESC-LN PIC S9(4) COMP.
              49 CONFIG-DESC-TX PIC X(60).
           10 UPDATED-BY        PIC X(8).
           10 UPDATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 5      *
      ******************************************************************
