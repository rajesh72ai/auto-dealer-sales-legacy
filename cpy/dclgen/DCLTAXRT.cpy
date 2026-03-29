      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.TAX_RATE)                             *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLTAXRT))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLTAX-RATE)                                 *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.TAX_RATE TABLE
           ( STATE_CODE       CHAR(2) NOT NULL,
             COUNTY_CODE      CHAR(5) NOT NULL,
             CITY_CODE        CHAR(5) NOT NULL,
             STATE_RATE       DECIMAL(5,4) NOT NULL,
             COUNTY_RATE      DECIMAL(5,4) NOT NULL,
             CITY_RATE        DECIMAL(5,4) NOT NULL,
             DOC_FEE_MAX      DECIMAL(7,2) NOT NULL,
             TITLE_FEE        DECIMAL(7,2) NOT NULL,
             REG_FEE          DECIMAL(7,2) NOT NULL,
             EFFECTIVE_DATE   DATE NOT NULL,
             EXPIRY_DATE      DATE
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.TAX_RATE                *
      ******************************************************************
       01  DCLTAX-RATE.
           10 STATE-CODE       PIC X(2).
           10 COUNTY-CODE      PIC X(5).
           10 CITY-CODE        PIC X(5).
           10 STATE-RATE       PIC S9(1)V9(4) COMP-3.
           10 COUNTY-RATE      PIC S9(1)V9(4) COMP-3.
           10 CITY-RATE        PIC S9(1)V9(4) COMP-3.
           10 DOC-FEE-MAX      PIC S9(5)V9(2) COMP-3.
           10 TITLE-FEE        PIC S9(5)V9(2) COMP-3.
           10 REG-FEE          PIC S9(5)V9(2) COMP-3.
           10 EFFECTIVE-DATE   PIC X(10).
           10 EXPIRY-DATE      PIC X(10).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 11     *
      ******************************************************************
