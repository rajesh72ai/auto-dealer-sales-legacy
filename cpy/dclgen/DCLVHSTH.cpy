      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.VEHICLE_STATUS_HIST)                  *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLVHSTH))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLVEHICLE-STATUS-HIST)                      *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.VEHICLE_STATUS_HIST TABLE
           ( VIN              CHAR(17) NOT NULL,
             STATUS_SEQ       INTEGER NOT NULL,
             OLD_STATUS       CHAR(2) NOT NULL,
             NEW_STATUS       CHAR(2) NOT NULL,
             CHANGED_BY       CHAR(8) NOT NULL,
             CHANGE_REASON    VARCHAR(60),
             CHANGED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.VEHICLE_STATUS_HIST     *
      ******************************************************************
       01  DCLVEHICLE-STATUS-HIST.
           10 VIN              PIC X(17).
           10 STATUS-SEQ       PIC S9(9) COMP.
           10 OLD-STATUS       PIC X(2).
           10 NEW-STATUS       PIC X(2).
           10 CHANGED-BY       PIC X(8).
           10 CHANGE-REASON.
              49 CHANGE-REASON-LN
                                PIC S9(4) COMP.
              49 CHANGE-REASON-TX
                                PIC X(60).
           10 CHANGED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
