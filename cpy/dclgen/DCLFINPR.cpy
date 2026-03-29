      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.FINANCE_PRODUCT)                      *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLFINPR))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLFINANCE-PRODUCT)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.FINANCE_PRODUCT TABLE
           ( DEAL_NUMBER      CHAR(10) NOT NULL,
             PRODUCT_SEQ      SMALLINT NOT NULL,
             PRODUCT_TYPE     CHAR(3) NOT NULL,
             PRODUCT_NAME     VARCHAR(40) NOT NULL,
             PROVIDER         VARCHAR(40),
             TERM_MONTHS      SMALLINT,
             MILEAGE_LIMIT    INTEGER,
             RETAIL_PRICE     DECIMAL(9,2) NOT NULL,
             DEALER_COST      DECIMAL(9,2) NOT NULL,
             GROSS_PROFIT     DECIMAL(9,2) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.FINANCE_PRODUCT         *
      ******************************************************************
       01  DCLFINANCE-PRODUCT.
           10 DEAL-NUMBER       PIC X(10).
           10 PRODUCT-SEQ       PIC S9(4) COMP.
           10 PRODUCT-TYPE      PIC X(3).
           10 PRODUCT-NAME.
              49 PRODUCT-NAME-LN PIC S9(4) COMP.
              49 PRODUCT-NAME-TX PIC X(40).
           10 PROVIDER.
              49 PROVIDER-LN    PIC S9(4) COMP.
              49 PROVIDER-TX    PIC X(40).
           10 TERM-MONTHS       PIC S9(4) COMP.
           10 MILEAGE-LIMIT     PIC S9(9) COMP.
           10 RETAIL-PRICE      PIC S9(7)V9(2) COMP-3.
           10 DEALER-COST       PIC S9(7)V9(2) COMP-3.
           10 GROSS-PROFIT      PIC S9(7)V9(2) COMP-3.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10     *
      ******************************************************************
