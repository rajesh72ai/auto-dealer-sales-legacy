      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.CREDIT_CHECK)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLCRDCK))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLCREDIT-CHECK)                              *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.CREDIT_CHECK TABLE
           ( CREDIT_ID        INTEGER NOT NULL,
             CUSTOMER_ID      INTEGER NOT NULL,
             BUREAU_CODE      CHAR(2) NOT NULL,
             CREDIT_SCORE     SMALLINT,
             CREDIT_TIER      CHAR(1),
             REQUEST_TS       TIMESTAMP NOT NULL,
             RESPONSE_TS      TIMESTAMP,
             STATUS           CHAR(2) NOT NULL,
             MONTHLY_DEBT     DECIMAL(9,2),
             MONTHLY_INCOME   DECIMAL(9,2),
             DTI_RATIO        DECIMAL(5,2),
             EXPIRY_DATE      DATE
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.CREDIT_CHECK            *
      ******************************************************************
       01  DCLCREDIT-CHECK.
           10 CREDIT-ID         PIC S9(9) COMP.
           10 CUSTOMER-ID       PIC S9(9) COMP.
           10 BUREAU-CODE       PIC X(2).
           10 CREDIT-SCORE      PIC S9(4) COMP.
           10 CREDIT-TIER       PIC X(1).
           10 REQUEST-TS        PIC X(26).
           10 RESPONSE-TS       PIC X(26).
           10 STATUS            PIC X(2).
           10 MONTHLY-DEBT      PIC S9(7)V9(2) COMP-3.
           10 MONTHLY-INCOME    PIC S9(7)V9(2) COMP-3.
           10 DTI-RATIO         PIC S9(3)V9(2) COMP-3.
           10 EXPIRY-DATE       PIC X(10).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 12     *
      ******************************************************************
