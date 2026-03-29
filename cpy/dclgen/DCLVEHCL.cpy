      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.VEHICLE)                              *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLVEHCL))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLVEHICLE)                                  *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.VEHICLE TABLE
           ( VIN              CHAR(17) NOT NULL,
             MODEL_YEAR       SMALLINT NOT NULL,
             MAKE_CODE        CHAR(3) NOT NULL,
             MODEL_CODE       CHAR(6) NOT NULL,
             EXTERIOR_COLOR   CHAR(3) NOT NULL,
             INTERIOR_COLOR   CHAR(3) NOT NULL,
             ENGINE_NUM       VARCHAR(20),
             PRODUCTION_DATE  DATE,
             SHIP_DATE        DATE,
             RECEIVE_DATE     DATE,
             VEHICLE_STATUS   CHAR(2) NOT NULL,
             DEALER_CODE      CHAR(5),
             LOT_LOCATION     CHAR(6),
             STOCK_NUMBER     CHAR(8),
             DAYS_IN_STOCK    SMALLINT NOT NULL,
             PDI_COMPLETE     CHAR(1) NOT NULL,
             PDI_DATE         DATE,
             DAMAGE_FLAG      CHAR(1) NOT NULL,
             DAMAGE_DESC      VARCHAR(200),
             ODOMETER         INTEGER NOT NULL,
             KEY_NUMBER       CHAR(6),
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.VEHICLE                 *
      ******************************************************************
       01  DCLVEHICLE.
           10 VIN              PIC X(17).
           10 MODEL-YEAR       PIC S9(4) COMP.
           10 MAKE-CODE        PIC X(3).
           10 MODEL-CODE       PIC X(6).
           10 EXTERIOR-COLOR   PIC X(3).
           10 INTERIOR-COLOR   PIC X(3).
           10 ENGINE-NUM.
              49 ENGINE-NUM-LN PIC S9(4) COMP.
              49 ENGINE-NUM-TX PIC X(20).
           10 PRODUCTION-DATE  PIC X(10).
           10 SHIP-DATE        PIC X(10).
           10 RECEIVE-DATE     PIC X(10).
           10 VEHICLE-STATUS   PIC X(2).
           10 DEALER-CODE      PIC X(5).
           10 LOT-LOCATION     PIC X(6).
           10 STOCK-NUMBER     PIC X(8).
           10 DAYS-IN-STOCK    PIC S9(4) COMP.
           10 PDI-COMPLETE     PIC X(1).
           10 PDI-DATE         PIC X(10).
           10 DAMAGE-FLAG      PIC X(1).
           10 DAMAGE-DESC.
              49 DAMAGE-DESC-LN
                                PIC S9(4) COMP.
              49 DAMAGE-DESC-TX
                                PIC X(200).
           10 ODOMETER         PIC S9(9) COMP.
           10 KEY-NUMBER       PIC X(6).
           10 CREATED-TS       PIC X(26).
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 23     *
      ******************************************************************
