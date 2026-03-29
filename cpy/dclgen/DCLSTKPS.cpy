      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.STOCK_POSITION)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSTKPS))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSTOCK-POSITION)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.STOCK_POSITION TABLE
           ( DEALER_CODE      CHAR(5) NOT NULL,
             MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             ON_HAND_COUNT    SMALLINT NOT NULL,
             IN_TRANSIT_COUNT SMALLINT NOT NULL,
             ALLOCATED_COUNT  SMALLINT NOT NULL,
             ON_HOLD_COUNT    SMALLINT NOT NULL,
             SOLD_MTD         SMALLINT NOT NULL,
             SOLD_YTD         SMALLINT NOT NULL,
             REORDER_POINT    SMALLINT NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.STOCK_POSITION          *
      ******************************************************************
       01  DCLSTOCK-POSITION.
           10 DEALER-CODE      PIC X(5).
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 ON-HAND-COUNT    PIC S9(4) COMP.
           10 IN-TRANSIT-COUNT PIC S9(4) COMP.
           10 ALLOCATED-COUNT  PIC S9(4) COMP.
           10 ON-HOLD-COUNT    PIC S9(4) COMP.
           10 SOLD-MTD         PIC S9(4) COMP.
           10 SOLD-YTD         PIC S9(4) COMP.
           10 REORDER-POINT    PIC S9(4) COMP.
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 12     *
      ******************************************************************
