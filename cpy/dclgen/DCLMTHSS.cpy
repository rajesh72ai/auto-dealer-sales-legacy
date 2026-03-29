      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.MONTHLY_SNAPSHOT)                     *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLMTHSS))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLMONTHLY-SNAPSHOT)                          *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.MONTHLY_SNAPSHOT TABLE
           ( SNAPSHOT_MONTH   CHAR(6) NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             TOTAL_UNITS_SOLD SMALLINT NOT NULL,
             TOTAL_REVENUE    DECIMAL(15,2) NOT NULL,
             TOTAL_GROSS      DECIMAL(13,2) NOT NULL,
             TOTAL_FI_GROSS   DECIMAL(11,2) NOT NULL,
             AVG_DAYS_TO_SELL SMALLINT NOT NULL,
             INVENTORY_TURN   DECIMAL(5,2) NOT NULL,
             FI_PER_DEAL      DECIMAL(9,2) NOT NULL,
             CSI_SCORE        DECIMAL(5,2),
             FROZEN_FLAG      CHAR(1) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.MONTHLY_SNAPSHOT        *
      ******************************************************************
       01  DCLMONTHLY-SNAPSHOT.
           10 SNAPSHOT-MONTH    PIC X(6).
           10 DEALER-CODE       PIC X(5).
           10 TOTAL-UNITS-SOLD  PIC S9(4) COMP.
           10 TOTAL-REVENUE     PIC S9(13)V9(2) COMP-3.
           10 TOTAL-GROSS       PIC S9(11)V9(2) COMP-3.
           10 TOTAL-FI-GROSS    PIC S9(9)V9(2) COMP-3.
           10 AVG-DAYS-TO-SELL  PIC S9(4) COMP.
           10 INVENTORY-TURN    PIC S9(3)V9(2) COMP-3.
           10 FI-PER-DEAL       PIC S9(7)V9(2) COMP-3.
           10 CSI-SCORE         PIC S9(3)V9(2) COMP-3.
           10 FROZEN-FLAG       PIC X(1).
           10 CREATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 12     *
      ******************************************************************
