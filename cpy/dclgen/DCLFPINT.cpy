      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.FLOOR_PLAN_INTEREST)                  *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLFPINT))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLFLOOR-PLAN-INTEREST)                      *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.FLOOR_PLAN_INTEREST TABLE
           ( INTEREST_ID      INTEGER NOT NULL,
             FLOOR_PLAN_ID    INTEGER NOT NULL,
             CALC_DATE        DATE NOT NULL,
             PRINCIPAL_BAL    DECIMAL(11,2) NOT NULL,
             RATE_APPLIED     DECIMAL(5,3) NOT NULL,
             DAILY_INTEREST   DECIMAL(9,4) NOT NULL,
             CUMULATIVE_INT   DECIMAL(9,2) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.FLOOR_PLAN_INTEREST     *
      ******************************************************************
       01  DCLFLOOR-PLAN-INTEREST.
           10 INTEREST-ID       PIC S9(9) COMP.
           10 FLOOR-PLAN-ID     PIC S9(9) COMP.
           10 CALC-DATE         PIC X(10).
           10 PRINCIPAL-BAL     PIC S9(9)V9(2) COMP-3.
           10 RATE-APPLIED      PIC S9(2)V9(3) COMP-3.
           10 DAILY-INTEREST    PIC S9(5)V9(4) COMP-3.
           10 CUMULATIVE-INT    PIC S9(7)V9(2) COMP-3.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
