      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.CUSTOMER_LEAD)                        *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLCSLEAD))                  *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLCUSTOMER-LEAD)                             *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.CUSTOMER_LEAD TABLE
           ( LEAD_ID          INTEGER NOT NULL,
             CUSTOMER_ID      INTEGER NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             LEAD_SOURCE      CHAR(3) NOT NULL,
             INTEREST_MODEL   CHAR(6),
             INTEREST_YEAR    SMALLINT,
             LEAD_STATUS      CHAR(2) NOT NULL,
             ASSIGNED_SALES   CHAR(8) NOT NULL,
             FOLLOW_UP_DATE   DATE,
             LAST_CONTACT_DT  DATE,
             CONTACT_COUNT    SMALLINT NOT NULL,
             NOTES            VARCHAR(200),
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.CUSTOMER_LEAD           *
      ******************************************************************
       01  DCLCUSTOMER-LEAD.
           10 LEAD-ID           PIC S9(9) COMP.
           10 CUSTOMER-ID       PIC S9(9) COMP.
           10 DEALER-CODE       PIC X(5).
           10 LEAD-SOURCE       PIC X(3).
           10 INTEREST-MODEL    PIC X(6).
           10 INTEREST-YEAR     PIC S9(4) COMP.
           10 LEAD-STATUS       PIC X(2).
           10 ASSIGNED-SALES    PIC X(8).
           10 FOLLOW-UP-DATE    PIC X(10).
           10 LAST-CONTACT-DT   PIC X(10).
           10 CONTACT-COUNT     PIC S9(4) COMP.
           10 NOTES-TEXT.
              49 NOTES-LN       PIC S9(4) COMP.
              49 NOTES-TX       PIC X(200).
           10 CREATED-TS        PIC X(26).
           10 UPDATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 14     *
      ******************************************************************
