      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.PRODUCTION_ORDER)                     *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLPRORD))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLPRODUCTION-ORDER)                         *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.PRODUCTION_ORDER TABLE
           ( PRODUCTION_ID    CHAR(12) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             PLANT_CODE       CHAR(4) NOT NULL,
             BUILD_DATE       DATE,
             BUILD_STATUS     CHAR(2) NOT NULL,
             ALLOCATED_DEALER CHAR(5),
             ALLOCATION_DATE  DATE,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.PRODUCTION_ORDER        *
      ******************************************************************
       01  DCLPRODUCTION-ORDER.
           10 PRODUCTION-ID    PIC X(12).
           10 VIN              PIC X(17).
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 PLANT-CODE       PIC X(4).
           10 BUILD-DATE       PIC X(10).
           10 BUILD-STATUS     PIC X(2).
           10 ALLOCATED-DEALER PIC X(5).
           10 ALLOCATION-DATE  PIC X(10).
           10 CREATED-TS       PIC X(26).
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 12     *
      ******************************************************************
