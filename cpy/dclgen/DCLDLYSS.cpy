      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.DAILY_SALES_SUMMARY)                  *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLDLYSS))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLDAILY-SALES-SUMMARY)                      *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.DAILY_SALES_SUMMARY TABLE
           ( SUMMARY_DATE     DATE NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             UNITS_SOLD       SMALLINT NOT NULL,
             TOTAL_REVENUE    DECIMAL(13,2) NOT NULL,
             TOTAL_GROSS      DECIMAL(11,2) NOT NULL,
             FRONT_GROSS      DECIMAL(11,2) NOT NULL,
             BACK_GROSS       DECIMAL(11,2) NOT NULL,
             AVG_SELLING_PRICE DECIMAL(11,2) NOT NULL,
             AVG_GROSS_PER_UNIT DECIMAL(9,2) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.DAILY_SALES_SUMMARY     *
      ******************************************************************
       01  DCLDAILY-SALES-SUMMARY.
           10 SUMMARY-DATE      PIC X(10).
           10 DEALER-CODE       PIC X(5).
           10 MODEL-YEAR        PIC S9(4) COMP.
           10 MAKE-CODE         PIC X(3).
           10 MODEL-CODE        PIC X(6).
           10 UNITS-SOLD        PIC S9(4) COMP.
           10 TOTAL-REVENUE     PIC S9(11)V9(2) COMP-3.
           10 TOTAL-GROSS       PIC S9(9)V9(2) COMP-3.
           10 FRONT-GROSS       PIC S9(9)V9(2) COMP-3.
           10 BACK-GROSS        PIC S9(9)V9(2) COMP-3.
           10 AVG-SELLING-PRICE PIC S9(9)V9(2) COMP-3.
           10 AVG-GROSS-PER-UNIT PIC S9(7)V9(2) COMP-3.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 12     *
      ******************************************************************
