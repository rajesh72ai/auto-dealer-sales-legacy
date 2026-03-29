      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.SHIPMENT_VEHICLE)                     *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSHPVH))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSHIPMENT-VEHICLE)                         *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.SHIPMENT_VEHICLE TABLE
           ( SHIPMENT_ID      CHAR(12) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             LOAD_SEQUENCE    SMALLINT NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.SHIPMENT_VEHICLE        *
      ******************************************************************
       01  DCLSHIPMENT-VEHICLE.
           10 SHIPMENT-ID      PIC X(12).
           10 VIN              PIC X(17).
           10 LOAD-SEQUENCE    PIC S9(4) COMP.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 3      *
      ******************************************************************
