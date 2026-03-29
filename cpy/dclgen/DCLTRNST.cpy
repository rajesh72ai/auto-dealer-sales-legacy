      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.TRANSIT_STATUS)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLTRNST))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLTRANSIT-STATUS)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.TRANSIT_STATUS TABLE
           ( VIN              CHAR(17) NOT NULL,
             STATUS_SEQ       INTEGER NOT NULL,
             LOCATION_DESC    VARCHAR(60) NOT NULL,
             STATUS_CODE      CHAR(2) NOT NULL,
             EDI_REF_NUM      CHAR(20),
             STATUS_TS        TIMESTAMP NOT NULL,
             RECEIVED_TS      TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.TRANSIT_STATUS          *
      ******************************************************************
       01  DCLTRANSIT-STATUS.
           10 VIN              PIC X(17).
           10 STATUS-SEQ       PIC S9(9) COMP.
           10 LOCATION-DESC.
              49 LOCATION-DESC-LN
                                PIC S9(4) COMP.
              49 LOCATION-DESC-TX
                                PIC X(60).
           10 STATUS-CODE      PIC X(2).
           10 EDI-REF-NUM      PIC X(20).
           10 STATUS-TS        PIC X(26).
           10 RECEIVED-TS      PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
