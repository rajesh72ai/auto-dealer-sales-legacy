      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.INCENTIVE_APPLIED)                    *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLINAPP))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLINCENTIVE-APPLIED)                        *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.INCENTIVE_APPLIED TABLE
           ( DEAL_NUMBER      CHAR(10) NOT NULL,
             INCENTIVE_ID     CHAR(10) NOT NULL,
             AMOUNT_APPLIED   DECIMAL(9,2) NOT NULL,
             APPLIED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.INCENTIVE_APPLIED       *
      ******************************************************************
       01  DCLINCENTIVE-APPLIED.
           10 DEAL-NUMBER       PIC X(10).
           10 INCENTIVE-ID      PIC X(10).
           10 AMOUNT-APPLIED    PIC S9(7)V9(2) COMP-3.
           10 APPLIED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 4      *
      ******************************************************************
