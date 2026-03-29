      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.COMMISSION)                           *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLCOMMS))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLCOMMISSION)                                *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.COMMISSION TABLE
           ( COMMISSION_ID    INTEGER NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             SALESPERSON_ID   CHAR(8) NOT NULL,
             DEAL_NUMBER      CHAR(10) NOT NULL,
             COMM_TYPE        CHAR(2) NOT NULL,
             GROSS_AMOUNT     DECIMAL(11,2) NOT NULL,
             COMM_RATE        DECIMAL(5,4) NOT NULL,
             COMM_AMOUNT      DECIMAL(9,2) NOT NULL,
             PAY_PERIOD       CHAR(6) NOT NULL,
             PAID_FLAG        CHAR(1) NOT NULL,
             CALC_TS          TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.COMMISSION              *
      ******************************************************************
       01  DCLCOMMISSION.
           10 COMMISSION-ID     PIC S9(9) COMP.
           10 DEALER-CODE       PIC X(5).
           10 SALESPERSON-ID    PIC X(8).
           10 DEAL-NUMBER       PIC X(10).
           10 COMM-TYPE         PIC X(2).
           10 GROSS-AMOUNT      PIC S9(9)V9(2) COMP-3.
           10 COMM-RATE         PIC S9(1)V9(4) COMP-3.
           10 COMM-AMOUNT       PIC S9(7)V9(2) COMP-3.
           10 PAY-PERIOD        PIC X(6).
           10 PAID-FLAG         PIC X(1).
           10 CALC-TS           PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 11     *
      ******************************************************************
