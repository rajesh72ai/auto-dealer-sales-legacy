      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.CUSTOMER)                             *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLCUSTM))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLCUSTOMER)                                 *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.CUSTOMER TABLE
           ( CUSTOMER_ID      INTEGER NOT NULL,
             FIRST_NAME       VARCHAR(30) NOT NULL,
             LAST_NAME        VARCHAR(30) NOT NULL,
             MIDDLE_INIT      CHAR(1),
             DATE_OF_BIRTH    DATE,
             SSN_LAST4        CHAR(4),
             DRIVERS_LICENSE   VARCHAR(20),
             DL_STATE         CHAR(2),
             ADDRESS_LINE1    VARCHAR(50) NOT NULL,
             ADDRESS_LINE2    VARCHAR(50),
             CITY             VARCHAR(30) NOT NULL,
             STATE_CODE       CHAR(2) NOT NULL,
             ZIP_CODE         CHAR(10) NOT NULL,
             HOME_PHONE       CHAR(10),
             CELL_PHONE       CHAR(10),
             EMAIL            VARCHAR(60),
             EMPLOYER_NAME    VARCHAR(40),
             ANNUAL_INCOME    DECIMAL(11,2),
             CUSTOMER_TYPE    CHAR(1) NOT NULL,
             SOURCE_CODE      CHAR(3),
             DEALER_CODE      CHAR(5) NOT NULL,
             ASSIGNED_SALES   CHAR(8),
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.CUSTOMER                *
      ******************************************************************
       01  DCLCUSTOMER.
           10 CUSTOMER-ID      PIC S9(9) COMP.
           10 FIRST-NAME.
              49 FIRST-NAME-LN
                                PIC S9(4) COMP.
              49 FIRST-NAME-TX PIC X(30).
           10 LAST-NAME.
              49 LAST-NAME-LN PIC S9(4) COMP.
              49 LAST-NAME-TX  PIC X(30).
           10 MIDDLE-INIT      PIC X(1).
           10 DATE-OF-BIRTH    PIC X(10).
           10 SSN-LAST4        PIC X(4).
           10 DRIVERS-LICENSE.
              49 DRIVERS-LICENSE-LN
                                PIC S9(4) COMP.
              49 DRIVERS-LICENSE-TX
                                PIC X(20).
           10 DL-STATE         PIC X(2).
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
           10 HOME-PHONE       PIC X(10).
           10 CELL-PHONE       PIC X(10).
           10 EMAIL.
              49 EMAIL-LN      PIC S9(4) COMP.
              49 EMAIL-TX      PIC X(60).
           10 EMPLOYER-NAME.
              49 EMPLOYER-NAME-LN
                                PIC S9(4) COMP.
              49 EMPLOYER-NAME-TX
                                PIC X(40).
           10 ANNUAL-INCOME    PIC S9(9)V9(2) COMP-3.
           10 CUSTOMER-TYPE    PIC X(1).
           10 SOURCE-CODE      PIC X(3).
           10 DEALER-CODE      PIC X(5).
           10 ASSIGNED-SALES   PIC X(8).
           10 CREATED-TS       PIC X(26).
           10 UPDATED-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 24     *
      ******************************************************************
