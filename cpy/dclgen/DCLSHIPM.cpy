      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.SHIPMENT)                             *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSHIPM))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSHIPMENT)                                 *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.SHIPMENT TABLE
           ( SHIPMENT_ID      CHAR(12) NOT NULL,
             CARRIER_CODE     CHAR(5) NOT NULL,
             CARRIER_NAME     VARCHAR(40),
             ORIGIN_PLANT     CHAR(4) NOT NULL,
             DEST_DEALER      CHAR(5) NOT NULL,
             TRANSPORT_MODE   CHAR(2) NOT NULL,
             VEHICLE_COUNT    SMALLINT NOT NULL,
             SHIP_DATE        DATE,
             EST_ARRIVAL_DATE DATE,
             ACT_ARRIVAL_DATE DATE,
             SHIPMENT_STATUS  CHAR(2) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.SHIPMENT                *
      ******************************************************************
       01  DCLSHIPMENT.
           10 SHIPMENT-ID      PIC X(12).
           10 CARRIER-CODE     PIC X(5).
           10 CARRIER-NAME.
              49 CARRIER-NAME-LN
                                PIC S9(4) COMP.
              49 CARRIER-NAME-TX
                                PIC X(40).
           10 ORIGIN-PLANT     PIC X(4).
           10 DEST-DEALER      PIC X(5).
           10 TRANSPORT-MODE   PIC X(2).
           10 VEHICLE-COUNT    PIC S9(4) COMP.
           10 SHIP-DATE        PIC X(10).
           10 EST-ARRIVAL-DATE PIC X(10).
           10 ACT-ARRIVAL-DATE PIC X(10).
           10 SHIPMENT-STATUS  PIC X(2).
           10 CREATED-TS       PIC X(26).
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 13     *
      ******************************************************************
