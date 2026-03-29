      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.FINANCE_APP)                          *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLFINAP))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLFINANCE-APP)                               *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.FINANCE_APP TABLE
           ( FINANCE_ID       CHAR(12) NOT NULL,
             DEAL_NUMBER      CHAR(10) NOT NULL,
             CUSTOMER_ID      INTEGER NOT NULL,
             FINANCE_TYPE     CHAR(1) NOT NULL,
             LENDER_CODE      CHAR(5),
             LENDER_NAME      VARCHAR(40),
             APP_STATUS       CHAR(2) NOT NULL,
             AMOUNT_REQUESTED DECIMAL(11,2) NOT NULL,
             AMOUNT_APPROVED  DECIMAL(11,2),
             APR_REQUESTED    DECIMAL(5,3),
             APR_APPROVED     DECIMAL(5,3),
             TERM_MONTHS      SMALLINT,
             MONTHLY_PAYMENT  DECIMAL(9,2),
             DOWN_PAYMENT     DECIMAL(11,2) NOT NULL,
             CREDIT_TIER      CHAR(1),
             STIPULATIONS     VARCHAR(200),
             SUBMITTED_TS     TIMESTAMP,
             DECISION_TS      TIMESTAMP,
             FUNDED_TS        TIMESTAMP,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.FINANCE_APP             *
      ******************************************************************
       01  DCLFINANCE-APP.
           10 FINANCE-ID        PIC X(12).
           10 DEAL-NUMBER       PIC X(10).
           10 CUSTOMER-ID       PIC S9(9) COMP.
           10 FINANCE-TYPE      PIC X(1).
           10 LENDER-CODE       PIC X(5).
           10 LENDER-NAME.
              49 LENDER-NAME-LN PIC S9(4) COMP.
              49 LENDER-NAME-TX PIC X(40).
           10 APP-STATUS        PIC X(2).
           10 AMOUNT-REQUESTED  PIC S9(9)V9(2) COMP-3.
           10 AMOUNT-APPROVED   PIC S9(9)V9(2) COMP-3.
           10 APR-REQUESTED     PIC S9(2)V9(3) COMP-3.
           10 APR-APPROVED      PIC S9(2)V9(3) COMP-3.
           10 TERM-MONTHS       PIC S9(4) COMP.
           10 MONTHLY-PAYMENT   PIC S9(7)V9(2) COMP-3.
           10 DOWN-PAYMENT      PIC S9(9)V9(2) COMP-3.
           10 CREDIT-TIER       PIC X(1).
           10 STIPULATIONS.
              49 STIPULATIONS-LN PIC S9(4) COMP.
              49 STIPULATIONS-TX PIC X(200).
           10 SUBMITTED-TS      PIC X(26).
           10 DECISION-TS       PIC X(26).
           10 FUNDED-TS         PIC X(26).
           10 CREATED-TS        PIC X(26).
           10 UPDATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 21     *
      ******************************************************************
