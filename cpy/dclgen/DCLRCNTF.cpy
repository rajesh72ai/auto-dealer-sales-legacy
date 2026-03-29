      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.RECALL_NOTIFICATION)                  *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLRCNTF))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLRECALL-NOTIFICATION)                      *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.RECALL_NOTIFICATION TABLE
           ( NOTIF_ID         INTEGER NOT NULL,
             RECALL_ID        CHAR(10) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             CUSTOMER_ID      INTEGER,
             NOTIF_TYPE       CHAR(1) NOT NULL,
             NOTIF_DATE       DATE NOT NULL,
             RESPONSE_FLAG    CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.RECALL_NOTIFICATION     *
      ******************************************************************
       01  DCLRECALL-NOTIFICATION.
           10 NOTIF-ID          PIC S9(9) COMP.
           10 RECALL-ID         PIC X(10).
           10 VIN               PIC X(17).
           10 CUSTOMER-ID       PIC S9(9) COMP.
           10 NOTIF-TYPE        PIC X(1).
           10 NOTIF-DATE        PIC X(10).
           10 RESPONSE-FLAG     PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
