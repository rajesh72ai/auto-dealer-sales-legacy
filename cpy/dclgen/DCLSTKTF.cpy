      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.STOCK_TRANSFER)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSTKTF))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSTOCK-TRANSFER)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.STOCK_TRANSFER TABLE
           ( TRANSFER_ID      INTEGER NOT NULL,
             FROM_DEALER      CHAR(5) NOT NULL,
             TO_DEALER        CHAR(5) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             TRANSFER_STATUS  CHAR(2) NOT NULL,
             REQUESTED_BY     CHAR(8) NOT NULL,
             APPROVED_BY      CHAR(8),
             REQUESTED_TS     TIMESTAMP NOT NULL,
             APPROVED_TS      TIMESTAMP,
             COMPLETED_TS     TIMESTAMP
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.STOCK_TRANSFER          *
      ******************************************************************
       01  DCLSTOCK-TRANSFER.
           10 TRANSFER-ID      PIC S9(9) COMP.
           10 FROM-DEALER      PIC X(5).
           10 TO-DEALER        PIC X(5).
           10 VIN              PIC X(17).
           10 TRANSFER-STATUS  PIC X(2).
           10 REQUESTED-BY     PIC X(8).
           10 APPROVED-BY      PIC X(8).
           10 REQUESTED-TS     PIC X(26).
           10 APPROVED-TS      PIC X(26).
           10 COMPLETED-TS     PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10     *
      ******************************************************************
