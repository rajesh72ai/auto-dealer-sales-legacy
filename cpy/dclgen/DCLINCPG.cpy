      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.INCENTIVE_PROGRAM)                    *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLINCPG))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLINCENTIVE-PROGRAM)                        *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.INCENTIVE_PROGRAM TABLE
           ( INCENTIVE_ID     CHAR(10) NOT NULL,
             INCENTIVE_NAME   VARCHAR(60) NOT NULL,
             INCENTIVE_TYPE   CHAR(2) NOT NULL,
             MODEL_YEAR       SMALLINT,
             MAKE_CODE        CHAR(3),
             MODEL_CODE       CHAR(6),
             REGION_CODE      CHAR(3),
             AMOUNT           DECIMAL(9,2) NOT NULL,
             RATE_OVERRIDE    DECIMAL(5,3),
             START_DATE       DATE NOT NULL,
             END_DATE         DATE NOT NULL,
             MAX_UNITS        INTEGER,
             UNITS_USED       INTEGER NOT NULL,
             STACKABLE_FLAG   CHAR(1) NOT NULL,
             ACTIVE_FLAG      CHAR(1) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.INCENTIVE_PROGRAM       *
      ******************************************************************
       01  DCLINCENTIVE-PROGRAM.
           10 INCENTIVE-ID     PIC X(10).
           10 INCENTIVE-NAME.
              49 INCENTIVE-NAME-LN
                                PIC S9(4) COMP.
              49 INCENTIVE-NAME-TX
                                PIC X(60).
           10 INCENTIVE-TYPE   PIC X(2).
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 REGION-CODE      PIC X(3).
           10 AMOUNT           PIC S9(7)V9(2) COMP-3.
           10 RATE-OVERRIDE    PIC S9(2)V9(3) COMP-3.
           10 START-DATE       PIC X(10).
           10 END-DATE         PIC X(10).
           10 MAX-UNITS        PIC S9(9) COMP.
           10 UNITS-USED       PIC S9(9) COMP.
           10 STACKABLE-FLAG   PIC X(1).
           10 ACTIVE-FLAG      PIC X(1).
           10 CREATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 16     *
      ******************************************************************
