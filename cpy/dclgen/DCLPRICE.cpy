      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.PRICE_MASTER)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLPRICE))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLPRICE-MASTER)                             *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.PRICE_MASTER TABLE
           ( MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             MSRP             DECIMAL(11,2) NOT NULL,
             INVOICE_PRICE    DECIMAL(11,2) NOT NULL,
             HOLDBACK_AMT     DECIMAL(9,2) NOT NULL,
             HOLDBACK_PCT     DECIMAL(5,3) NOT NULL,
             DESTINATION_FEE  DECIMAL(7,2) NOT NULL,
             ADVERTISING_FEE  DECIMAL(7,2) NOT NULL,
             EFFECTIVE_DATE   DATE NOT NULL,
             EXPIRY_DATE      DATE,
             CREATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.PRICE_MASTER            *
      ******************************************************************
       01  DCLPRICE-MASTER.
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 MSRP             PIC S9(9)V9(2) COMP-3.
           10 INVOICE-PRICE    PIC S9(9)V9(2) COMP-3.
           10 HOLDBACK-AMT     PIC S9(7)V9(2) COMP-3.
           10 HOLDBACK-PCT     PIC S9(2)V9(3) COMP-3.
           10 DESTINATION-FEE  PIC S9(5)V9(2) COMP-3.
           10 ADVERTISING-FEE  PIC S9(5)V9(2) COMP-3.
           10 EFFECTIVE-DATE   PIC X(10).
           10 EXPIRY-DATE      PIC X(10).
           10 CREATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 12     *
      ******************************************************************
