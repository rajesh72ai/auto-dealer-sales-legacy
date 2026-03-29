      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.FLOOR_PLAN_LENDER)                    *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLFPLND))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLFLOOR-PLAN-LENDER)                        *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.FLOOR_PLAN_LENDER TABLE
           ( LENDER_ID        CHAR(5) NOT NULL,
             LENDER_NAME      VARCHAR(40) NOT NULL,
             CONTACT_NAME     VARCHAR(40),
             PHONE            CHAR(10),
             BASE_RATE        DECIMAL(5,3) NOT NULL,
             SPREAD           DECIMAL(5,3) NOT NULL,
             CURTAILMENT_DAYS INTEGER NOT NULL,
             FREE_FLOOR_DAYS  INTEGER NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.FLOOR_PLAN_LENDER       *
      ******************************************************************
       01  DCLFLOOR-PLAN-LENDER.
           10 LENDER-ID         PIC X(5).
           10 LENDER-NAME.
              49 LENDER-NAME-LN PIC S9(4) COMP.
              49 LENDER-NAME-TX PIC X(40).
           10 CONTACT-NAME.
              49 CONTACT-NAME-LN PIC S9(4) COMP.
              49 CONTACT-NAME-TX PIC X(40).
           10 PHONE             PIC X(10).
           10 BASE-RATE         PIC S9(2)V9(3) COMP-3.
           10 SPREAD            PIC S9(2)V9(3) COMP-3.
           10 CURTAILMENT-DAYS  PIC S9(9) COMP.
           10 FREE-FLOOR-DAYS   PIC S9(9) COMP.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 8      *
      ******************************************************************
