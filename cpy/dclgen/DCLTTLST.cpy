      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.TITLE_STATUS)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLTTLST))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLTITLE-STATUS)                              *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.TITLE_STATUS TABLE
           ( REG_ID           CHAR(12) NOT NULL,
             STATUS_SEQ       SMALLINT NOT NULL,
             STATUS_CODE      CHAR(2) NOT NULL,
             STATUS_DESC      VARCHAR(60),
             STATUS_TS        TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.TITLE_STATUS            *
      ******************************************************************
       01  DCLTITLE-STATUS.
           10 REG-ID            PIC X(12).
           10 STATUS-SEQ        PIC S9(4) COMP.
           10 STATUS-CODE       PIC X(2).
           10 STATUS-DESC.
              49 STATUS-DESC-LN PIC S9(4) COMP.
              49 STATUS-DESC-TX PIC X(60).
           10 STATUS-TS         PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 5      *
      ******************************************************************
