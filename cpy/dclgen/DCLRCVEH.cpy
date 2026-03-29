      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.RECALL_VEHICLE)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLRCVEH))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLRECALL-VEHICLE)                            *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.RECALL_VEHICLE TABLE
           ( RECALL_ID        CHAR(10) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             DEALER_CODE      CHAR(5),
             RECALL_STATUS    CHAR(2) NOT NULL,
             NOTIFIED_DATE    DATE,
             SCHEDULED_DATE   DATE,
             COMPLETED_DATE   DATE,
             TECHNICIAN_ID    CHAR(8),
             PARTS_ORDERED    CHAR(1) NOT NULL,
             PARTS_AVAIL      CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.RECALL_VEHICLE          *
      ******************************************************************
       01  DCLRECALL-VEHICLE.
           10 RECALL-ID         PIC X(10).
           10 VIN               PIC X(17).
           10 DEALER-CODE       PIC X(5).
           10 RECALL-STATUS     PIC X(2).
           10 NOTIFIED-DATE     PIC X(10).
           10 SCHEDULED-DATE    PIC X(10).
           10 COMPLETED-DATE    PIC X(10).
           10 TECHNICIAN-ID     PIC X(8).
           10 PARTS-ORDERED     PIC X(1).
           10 PARTS-AVAIL       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10     *
      ******************************************************************
