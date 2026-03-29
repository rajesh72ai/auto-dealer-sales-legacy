      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.SALES_APPROVAL)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSLAPV))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSALES-APPROVAL)                            *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.SALES_APPROVAL TABLE
           ( APPROVAL_ID      INTEGER NOT NULL,
             DEAL_NUMBER      CHAR(10) NOT NULL,
             APPROVAL_TYPE    CHAR(2) NOT NULL,
             APPROVER_ID      CHAR(8) NOT NULL,
             APPROVAL_STATUS  CHAR(1) NOT NULL,
             COMMENTS         VARCHAR(200),
             APPROVAL_TS      TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.SALES_APPROVAL          *
      ******************************************************************
       01  DCLSALES-APPROVAL.
           10 APPROVAL-ID       PIC S9(9) COMP.
           10 DEAL-NUMBER       PIC X(10).
           10 APPROVAL-TYPE     PIC X(2).
           10 APPROVER-ID       PIC X(8).
           10 APPROVAL-STATUS   PIC X(1).
           10 COMMENTS-TEXT.
              49 COMMENTS-LN    PIC S9(4) COMP.
              49 COMMENTS-TX    PIC X(200).
           10 APPROVAL-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
