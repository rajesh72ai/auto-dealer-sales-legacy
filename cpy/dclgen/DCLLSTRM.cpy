      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.LEASE_TERMS)                          *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLLSTRM))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLLEASE-TERMS)                               *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.LEASE_TERMS TABLE
           ( FINANCE_ID       CHAR(12) NOT NULL,
             RESIDUAL_PCT     DECIMAL(5,2) NOT NULL,
             RESIDUAL_AMT     DECIMAL(11,2) NOT NULL,
             MONEY_FACTOR     DECIMAL(7,6) NOT NULL,
             CAPITALIZED_COST DECIMAL(11,2) NOT NULL,
             CAP_COST_REDUCE  DECIMAL(11,2) NOT NULL,
             ADJ_CAP_COST     DECIMAL(11,2) NOT NULL,
             DEPRECIATION_AMT DECIMAL(11,2) NOT NULL,
             FINANCE_CHARGE   DECIMAL(9,2) NOT NULL,
             MONTHLY_TAX      DECIMAL(7,2) NOT NULL,
             MILES_PER_YEAR   INTEGER NOT NULL,
             EXCESS_MILE_CHG  DECIMAL(5,3) NOT NULL,
             DISPOSITION_FEE  DECIMAL(7,2) NOT NULL,
             ACQ_FEE          DECIMAL(7,2) NOT NULL,
             SECURITY_DEPOSIT DECIMAL(7,2) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.LEASE_TERMS             *
      ******************************************************************
       01  DCLLEASE-TERMS.
           10 FINANCE-ID        PIC X(12).
           10 RESIDUAL-PCT      PIC S9(3)V9(2) COMP-3.
           10 RESIDUAL-AMT      PIC S9(9)V9(2) COMP-3.
           10 MONEY-FACTOR      PIC S9(1)V9(6) COMP-3.
           10 CAPITALIZED-COST  PIC S9(9)V9(2) COMP-3.
           10 CAP-COST-REDUCE   PIC S9(9)V9(2) COMP-3.
           10 ADJ-CAP-COST      PIC S9(9)V9(2) COMP-3.
           10 DEPRECIATION-AMT  PIC S9(9)V9(2) COMP-3.
           10 FINANCE-CHARGE    PIC S9(7)V9(2) COMP-3.
           10 MONTHLY-TAX       PIC S9(5)V9(2) COMP-3.
           10 MILES-PER-YEAR    PIC S9(9) COMP.
           10 EXCESS-MILE-CHG   PIC S9(2)V9(3) COMP-3.
           10 DISPOSITION-FEE   PIC S9(5)V9(2) COMP-3.
           10 ACQ-FEE           PIC S9(5)V9(2) COMP-3.
           10 SECURITY-DEPOSIT  PIC S9(5)V9(2) COMP-3.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 15     *
      ******************************************************************
