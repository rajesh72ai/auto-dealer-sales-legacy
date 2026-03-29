      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.LOT_LOCATION)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLLOTLC))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLLOT-LOCATION)                             *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.LOT_LOCATION TABLE
           ( DEALER_CODE      CHAR(5) NOT NULL,
             LOCATION_CODE    CHAR(6) NOT NULL,
             LOCATION_DESC    VARCHAR(30) NOT NULL,
             LOCATION_TYPE    CHAR(1) NOT NULL,
             MAX_CAPACITY     SMALLINT NOT NULL,
             CURRENT_COUNT    SMALLINT NOT NULL,
             ACTIVE_FLAG      CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.LOT_LOCATION            *
      ******************************************************************
       01  DCLLOT-LOCATION.
           10 DEALER-CODE      PIC X(5).
           10 LOCATION-CODE    PIC X(6).
           10 LOCATION-DESC.
              49 LOCATION-DESC-LN
                                PIC S9(4) COMP.
              49 LOCATION-DESC-TX
                                PIC X(30).
           10 LOCATION-TYPE    PIC X(1).
           10 MAX-CAPACITY     PIC S9(4) COMP.
           10 CURRENT-COUNT    PIC S9(4) COMP.
           10 ACTIVE-FLAG      PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
