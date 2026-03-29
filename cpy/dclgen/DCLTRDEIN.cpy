      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.TRADE_IN)                             *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLTRDEIN))                  *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLTRADE-IN)                                  *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.TRADE_IN TABLE
           ( TRADE_ID         INTEGER NOT NULL,
             DEAL_NUMBER      CHAR(10) NOT NULL,
             VIN              CHAR(17),
             TRADE_YEAR       SMALLINT NOT NULL,
             TRADE_MAKE       VARCHAR(20) NOT NULL,
             TRADE_MODEL      VARCHAR(30) NOT NULL,
             TRADE_COLOR      VARCHAR(15),
             ODOMETER         INTEGER NOT NULL,
             CONDITION_CODE   CHAR(1) NOT NULL,
             ACV_AMOUNT       DECIMAL(11,2) NOT NULL,
             ALLOWANCE_AMT    DECIMAL(11,2) NOT NULL,
             OVER_ALLOW       DECIMAL(9,2) NOT NULL,
             PAYOFF_AMT       DECIMAL(11,2) NOT NULL,
             PAYOFF_BANK      VARCHAR(40),
             PAYOFF_ACCT      VARCHAR(20),
             APPRAISED_BY     CHAR(8) NOT NULL,
             APPRAISED_TS     TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.TRADE_IN                *
      ******************************************************************
       01  DCLTRADE-IN.
           10 TRADE-ID          PIC S9(9) COMP.
           10 DEAL-NUMBER       PIC X(10).
           10 VIN               PIC X(17).
           10 TRADE-YEAR        PIC S9(4) COMP.
           10 TRADE-MAKE.
              49 TRADE-MAKE-LN  PIC S9(4) COMP.
              49 TRADE-MAKE-TX  PIC X(20).
           10 TRADE-MODEL.
              49 TRADE-MODEL-LN PIC S9(4) COMP.
              49 TRADE-MODEL-TX PIC X(30).
           10 TRADE-COLOR.
              49 TRADE-COLOR-LN PIC S9(4) COMP.
              49 TRADE-COLOR-TX PIC X(15).
           10 ODOMETER          PIC S9(9) COMP.
           10 CONDITION-CODE    PIC X(1).
           10 ACV-AMOUNT        PIC S9(9)V9(2) COMP-3.
           10 ALLOWANCE-AMT     PIC S9(9)V9(2) COMP-3.
           10 OVER-ALLOW        PIC S9(7)V9(2) COMP-3.
           10 PAYOFF-AMT        PIC S9(9)V9(2) COMP-3.
           10 PAYOFF-BANK.
              49 PAYOFF-BANK-LN PIC S9(4) COMP.
              49 PAYOFF-BANK-TX PIC X(40).
           10 PAYOFF-ACCT.
              49 PAYOFF-ACCT-LN PIC S9(4) COMP.
              49 PAYOFF-ACCT-TX PIC X(20).
           10 APPRAISED-BY      PIC X(8).
           10 APPRAISED-TS      PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 17     *
      ******************************************************************
