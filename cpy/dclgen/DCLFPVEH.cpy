      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.FLOOR_PLAN_VEHICLE)                   *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLFPVEH))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLFLOOR-PLAN-VEHICLE)                       *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.FLOOR_PLAN_VEHICLE TABLE
           ( FLOOR_PLAN_ID    INTEGER NOT NULL,
             VIN              CHAR(17) NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             LENDER_ID        CHAR(5) NOT NULL,
             INVOICE_AMOUNT   DECIMAL(11,2) NOT NULL,
             CURRENT_BALANCE  DECIMAL(11,2) NOT NULL,
             INTEREST_ACCRUED DECIMAL(9,2) NOT NULL,
             FLOOR_DATE       DATE NOT NULL,
             CURTAILMENT_DATE DATE,
             PAYOFF_DATE      DATE,
             FP_STATUS        CHAR(2) NOT NULL,
             DAYS_ON_FLOOR    SMALLINT NOT NULL,
             LAST_INTEREST_DT DATE
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.FLOOR_PLAN_VEHICLE      *
      ******************************************************************
       01  DCLFLOOR-PLAN-VEHICLE.
           10 FLOOR-PLAN-ID     PIC S9(9) COMP.
           10 VIN               PIC X(17).
           10 DEALER-CODE       PIC X(5).
           10 LENDER-ID         PIC X(5).
           10 INVOICE-AMOUNT    PIC S9(9)V9(2) COMP-3.
           10 CURRENT-BALANCE   PIC S9(9)V9(2) COMP-3.
           10 INTEREST-ACCRUED  PIC S9(7)V9(2) COMP-3.
           10 FLOOR-DATE        PIC X(10).
           10 CURTAILMENT-DATE  PIC X(10).
           10 PAYOFF-DATE       PIC X(10).
           10 FP-STATUS         PIC X(2).
           10 DAYS-ON-FLOOR     PIC S9(4) COMP.
           10 LAST-INTEREST-DT  PIC X(10).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 13     *
      ******************************************************************
