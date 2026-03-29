      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.VEHICLE_OPTION)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLVHOPT))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLVEHICLE-OPTION)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.VEHICLE_OPTION TABLE
           ( VIN              CHAR(17) NOT NULL,
             OPTION_CODE      CHAR(6) NOT NULL,
             OPTION_DESC      VARCHAR(40) NOT NULL,
             OPTION_PRICE     DECIMAL(9,2) NOT NULL,
             INSTALLED_FLAG   CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.VEHICLE_OPTION          *
      ******************************************************************
       01  DCLVEHICLE-OPTION.
           10 VIN              PIC X(17).
           10 OPTION-CODE      PIC X(6).
           10 OPTION-DESC.
              49 OPTION-DESC-LN
                                PIC S9(4) COMP.
              49 OPTION-DESC-TX
                                PIC X(40).
           10 OPTION-PRICE     PIC S9(7)V9(2) COMP-3.
           10 INSTALLED-FLAG   PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 5      *
      ******************************************************************
