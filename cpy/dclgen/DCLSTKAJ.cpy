      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.STOCK_ADJUSTMENT)                     *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSTKAJ))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSTOCK-ADJUSTMENT)                         *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.STOCK_ADJUSTMENT TABLE
           ( ADJUST_ID        INTEGER NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             ADJUST_TYPE      CHAR(2) NOT NULL,
             ADJUST_REASON    VARCHAR(100) NOT NULL,
             OLD_STATUS       CHAR(2) NOT NULL,
             NEW_STATUS       CHAR(2) NOT NULL,
             ADJUSTED_BY      CHAR(8) NOT NULL,
             ADJUSTED_TS      TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.STOCK_ADJUSTMENT        *
      ******************************************************************
       01  DCLSTOCK-ADJUSTMENT.
           10 ADJUST-ID        PIC S9(9) COMP.
           10 DEALER-CODE      PIC X(5).
           10 VIN              PIC X(17).
           10 ADJUST-TYPE      PIC X(2).
           10 ADJUST-REASON.
              49 ADJUST-REASON-LN
                                PIC S9(4) COMP.
              49 ADJUST-REASON-TX
                                PIC X(100).
           10 OLD-STATUS       PIC X(2).
           10 NEW-STATUS       PIC X(2).
           10 ADJUSTED-BY      PIC X(8).
           10 ADJUSTED-TS      PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 9      *
      ******************************************************************
