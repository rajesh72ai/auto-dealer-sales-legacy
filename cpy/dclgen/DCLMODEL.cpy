      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.MODEL_MASTER)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLMODEL))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLMODEL-MASTER)                             *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.MODEL_MASTER TABLE
           ( MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             MODEL_NAME       VARCHAR(40) NOT NULL,
             BODY_STYLE       CHAR(2) NOT NULL,
             TRIM_LEVEL       CHAR(3) NOT NULL,
             ENGINE_TYPE      CHAR(3) NOT NULL,
             TRANSMISSION     CHAR(1) NOT NULL,
             DRIVE_TRAIN      CHAR(3) NOT NULL,
             EXTERIOR_COLORS  VARCHAR(200),
             INTERIOR_COLORS  VARCHAR(200),
             CURB_WEIGHT      INTEGER,
             FUEL_ECONOMY_CITY SMALLINT,
             FUEL_ECONOMY_HWY SMALLINT,
             ACTIVE_FLAG      CHAR(1) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.MODEL_MASTER            *
      ******************************************************************
       01  DCLMODEL-MASTER.
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 MODEL-NAME.
              49 MODEL-NAME-LN
                                PIC S9(4) COMP.
              49 MODEL-NAME-TX PIC X(40).
           10 BODY-STYLE       PIC X(2).
           10 TRIM-LEVEL       PIC X(3).
           10 ENGINE-TYPE      PIC X(3).
           10 TRANSMISSION     PIC X(1).
           10 DRIVE-TRAIN      PIC X(3).
           10 EXTERIOR-COLORS.
              49 EXTERIOR-COLORS-LN
                                PIC S9(4) COMP.
              49 EXTERIOR-COLORS-TX
                                PIC X(200).
           10 INTERIOR-COLORS.
              49 INTERIOR-COLORS-LN
                                PIC S9(4) COMP.
              49 INTERIOR-COLORS-TX
                                PIC X(200).
           10 CURB-WEIGHT      PIC S9(9) COMP.
           10 FUEL-ECONOMY-CITY
                                PIC S9(4) COMP.
           10 FUEL-ECONOMY-HWY PIC S9(4) COMP.
           10 ACTIVE-FLAG      PIC X(1).
           10 CREATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 16     *
      ******************************************************************
