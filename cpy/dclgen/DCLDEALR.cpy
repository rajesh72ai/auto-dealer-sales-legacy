      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.DEALER)                               *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLDEALR))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLDEALER)                                   *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.DEALER TABLE
           ( DEALER_CODE      CHAR(5) NOT NULL,
             DEALER_NAME      VARCHAR(60) NOT NULL,
             ADDRESS_LINE1    VARCHAR(50) NOT NULL,
             ADDRESS_LINE2    VARCHAR(50),
             CITY             VARCHAR(30) NOT NULL,
             STATE_CODE       CHAR(2) NOT NULL,
             ZIP_CODE         CHAR(10) NOT NULL,
             PHONE_NUMBER     CHAR(10) NOT NULL,
             FAX_NUMBER       CHAR(10),
             DEALER_PRINCIPAL VARCHAR(40) NOT NULL,
             REGION_CODE      CHAR(3) NOT NULL,
             ZONE_CODE        CHAR(2) NOT NULL,
             OEM_DEALER_NUM   CHAR(10) NOT NULL,
             FLOOR_PLAN_LENDER_ID CHAR(5),
             MAX_INVENTORY    SMALLINT NOT NULL,
             ACTIVE_FLAG      CHAR(1) NOT NULL,
             OPENED_DATE      DATE NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.DEALER                  *
      ******************************************************************
       01  DCLDEALER.
           10 DEALER-CODE      PIC X(5).
           10 DEALER-NAME.
              49 DEALER-NAME-LN
                                PIC S9(4) COMP.
              49 DEALER-NAME-TX
                                PIC X(60).
           10 ADDRESS-LINE1.
              49 ADDRESS-LINE1-LN
                                PIC S9(4) COMP.
              49 ADDRESS-LINE1-TX
                                PIC X(50).
           10 ADDRESS-LINE2.
              49 ADDRESS-LINE2-LN
                                PIC S9(4) COMP.
              49 ADDRESS-LINE2-TX
                                PIC X(50).
           10 CITY.
              49 CITY-LN       PIC S9(4) COMP.
              49 CITY-TX       PIC X(30).
           10 STATE-CODE       PIC X(2).
           10 ZIP-CODE         PIC X(10).
           10 PHONE-NUMBER     PIC X(10).
           10 FAX-NUMBER       PIC X(10).
           10 DEALER-PRINCIPAL.
              49 DEALER-PRINCIPAL-LN
                                PIC S9(4) COMP.
              49 DEALER-PRINCIPAL-TX
                                PIC X(40).
           10 REGION-CODE      PIC X(3).
           10 ZONE-CODE        PIC X(2).
           10 OEM-DEALER-NUM   PIC X(10).
           10 FLOOR-PLAN-LENDER-ID
                                PIC X(5).
           10 MAX-INVENTORY    PIC S9(4) COMP.
           10 ACTIVE-FLAG      PIC X(1).
           10 OPENED-DATE      PIC X(10).
           10 CREATED-TS       PIC X(26).
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 19     *
      ******************************************************************
