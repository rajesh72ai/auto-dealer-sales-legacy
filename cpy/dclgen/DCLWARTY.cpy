      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.WARRANTY)                             *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLWARTY))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLWARRANTY)                                  *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.WARRANTY TABLE
           ( WARRANTY_ID      INTEGER NOT NULL,
             VIN              CHAR(17) NOT NULL,
             DEAL_NUMBER      CHAR(10) NOT NULL,
             WARRANTY_TYPE    CHAR(2) NOT NULL,
             START_DATE       DATE NOT NULL,
             EXPIRY_DATE      DATE NOT NULL,
             MILEAGE_LIMIT    INTEGER NOT NULL,
             DEDUCTIBLE       DECIMAL(7,2) NOT NULL,
             ACTIVE_FLAG      CHAR(1) NOT NULL,
             REGISTERED_TS    TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.WARRANTY                *
      ******************************************************************
       01  DCLWARRANTY.
           10 WARRANTY-ID       PIC S9(9) COMP.
           10 VIN               PIC X(17).
           10 DEAL-NUMBER       PIC X(10).
           10 WARRANTY-TYPE     PIC X(2).
           10 START-DATE        PIC X(10).
           10 EXPIRY-DATE       PIC X(10).
           10 MILEAGE-LIMIT     PIC S9(9) COMP.
           10 DEDUCTIBLE        PIC S9(5)V9(2) COMP-3.
           10 ACTIVE-FLAG       PIC X(1).
           10 REGISTERED-TS     PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10     *
      ******************************************************************
