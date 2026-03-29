      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.STOCK_SNAPSHOT)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSTKSS))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSTOCK-SNAPSHOT)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.STOCK_SNAPSHOT TABLE
           ( SNAPSHOT_DATE    DATE NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             ON_HAND_COUNT    SMALLINT NOT NULL,
             IN_TRANSIT_COUNT SMALLINT NOT NULL,
             ON_HOLD_COUNT    SMALLINT NOT NULL,
             TOTAL_VALUE      DECIMAL(13,2) NOT NULL,
             AVG_DAYS_IN_STOCK SMALLINT NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.STOCK_SNAPSHOT          *
      ******************************************************************
       01  DCLSTOCK-SNAPSHOT.
           10 SNAPSHOT-DATE    PIC X(10).
           10 DEALER-CODE      PIC X(5).
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 ON-HAND-COUNT    PIC S9(4) COMP.
           10 IN-TRANSIT-COUNT PIC S9(4) COMP.
           10 ON-HOLD-COUNT    PIC S9(4) COMP.
           10 TOTAL-VALUE      PIC S9(11)V9(2) COMP-3.
           10 AVG-DAYS-IN-STOCK
                                PIC S9(4) COMP.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10     *
      ******************************************************************
