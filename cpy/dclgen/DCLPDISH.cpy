      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.PDI_SCHEDULE)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLPDISH))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLPDI-SCHEDULE)                             *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.PDI_SCHEDULE TABLE
           ( PDI_ID           INTEGER NOT NULL,
             VIN              CHAR(17) NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             SCHEDULED_DATE   DATE NOT NULL,
             TECHNICIAN_ID    CHAR(8),
             PDI_STATUS       CHAR(2) NOT NULL,
             CHECKLIST_ITEMS  SMALLINT NOT NULL,
             ITEMS_PASSED     SMALLINT NOT NULL,
             ITEMS_FAILED     SMALLINT NOT NULL,
             NOTES            VARCHAR(200),
             COMPLETED_TS     TIMESTAMP
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.PDI_SCHEDULE            *
      ******************************************************************
       01  DCLPDI-SCHEDULE.
           10 PDI-ID           PIC S9(9) COMP.
           10 VIN              PIC X(17).
           10 DEALER-CODE      PIC X(5).
           10 SCHEDULED-DATE   PIC X(10).
           10 TECHNICIAN-ID    PIC X(8).
           10 PDI-STATUS       PIC X(2).
           10 CHECKLIST-ITEMS  PIC S9(4) COMP.
           10 ITEMS-PASSED     PIC S9(4) COMP.
           10 ITEMS-FAILED     PIC S9(4) COMP.
           10 NOTES.
              49 NOTES-LN      PIC S9(4) COMP.
              49 NOTES-TX      PIC X(200).
           10 COMPLETED-TS     PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 11     *
      ******************************************************************
