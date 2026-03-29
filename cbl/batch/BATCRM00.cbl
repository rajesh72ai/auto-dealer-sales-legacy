       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCRM00.
      ****************************************************************
      * PROGRAM:    BATCRM00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    CRM FEED EXTRACT. READS NEW/CHANGED CUSTOMERS    *
      *             BASED ON LAST_UPDATED > LAST RUN DATE. INCLUDES  *
      *             PURCHASE HISTORY SUMMARY AND CONTACT PREFS.      *
      *             WRITES PIPE-DELIMITED OUTPUT FOR CRM SYSTEM.     *
      *             UPDATES CRM_SYNC_DATE ON CUSTOMER TABLE.         *
      *                                                              *
      * INPUT:      AUTOSALE.CUSTOMER (CHANGED SINCE LAST RUN)      *
      *                                                              *
      * TABLES:     AUTOSALE.CUSTOMER        (READ/UPDATE)          *
      *             AUTOSALE.SALES_DEAL      (READ)                  *
      *             AUTOSALE.BATCH_CONTROL   (READ/UPDATE)           *
      *             AUTOSALE.BATCH_CHECKPOINT(READ/UPDATE)           *
      *                                                              *
      * OUTPUT:     CRMFILE DD - PIPE-DELIMITED CRM EXTRACT         *
      *                                                              *
      * CALLS:      COMCKPL0 - CHECKPOINT/RESTART                    *
      *             COMDBEL0 - DB2 ERROR HANDLER                     *
      *             COMLGEL0 - LOGGING UTILITY                       *
      *                                                              *
      * CHECKPOINT: EVERY 500 CUSTOMERS VIA CALL 'COMCKPL0'         *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CRM-FILE
               ASSIGN TO CRMFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-CRMFILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  CRM-FILE
           RECORDING MODE IS V
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 20 TO 800 CHARACTERS.
       01  CRM-RECORD                    PIC X(800).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                  PIC X(08) VALUE 'BATCRM00'.
      *
       01  WS-CRMFILE-STATUS             PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    CHECKPOINT AREA
           COPY WSCKPT00.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-CUST-COUNT             PIC S9(09) COMP-3 VALUE +0.
           05  WS-WRITE-COUNT            PIC S9(09) COMP-3 VALUE +0.
           05  WS-ERROR-COUNT            PIC S9(09) COMP-3 VALUE +0.
           05  WS-CHECKPOINT-INTERVAL    PIC S9(07) COMP-3 VALUE +500.
      *
      *    EOF FLAG
      *
       01  WS-EOF-CUST                   PIC X(01) VALUE 'N'.
           88  WS-CUST-DONE                        VALUE 'Y'.
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY              PIC 9(04).
           05  WS-CURR-MM                PIC 9(02).
           05  WS-CURR-DD                PIC 9(02).
           05  FILLER                    PIC X(13).
      *
       01  WS-TODAY-DATE                 PIC X(10) VALUE SPACES.
       01  WS-CURRENT-TIMESTAMP          PIC X(26) VALUE SPACES.
       01  WS-LAST-RUN-DATE              PIC X(10) VALUE SPACES.
      *
      *    HOST VARIABLES - CUSTOMER CURSOR
      *
       01  WS-HV-CUST.
           05  WS-HV-CUSTOMER-ID         PIC S9(09) COMP.
           05  WS-HV-LAST-NAME           PIC X(25).
           05  WS-HV-FIRST-NAME          PIC X(15).
           05  WS-HV-MIDDLE-INIT         PIC X(01).
           05  WS-HV-ADDRESS             PIC X(40).
           05  WS-HV-CITY                PIC X(25).
           05  WS-HV-STATE               PIC X(02).
           05  WS-HV-ZIP                 PIC X(10).
           05  WS-HV-PHONE              PIC X(15).
           05  WS-HV-EMAIL               PIC X(50).
           05  WS-HV-CONTACT-PREF        PIC X(02).
           05  WS-HV-DO-NOT-CALL         PIC X(01).
           05  WS-HV-DO-NOT-EMAIL        PIC X(01).
           05  WS-HV-LAST-UPDATED        PIC X(26).
      *
      *    HOST VARIABLES - PURCHASE HISTORY
      *
       01  WS-HV-HISTORY.
           05  WS-HV-TOTAL-DEALS         PIC S9(05) COMP.
           05  WS-HV-LAST-PURCHASE-DATE  PIC X(10).
           05  WS-HV-TOTAL-SPENT         PIC S9(11)V99 COMP-3.
           05  WS-HV-LAST-DEAL-TYPE      PIC X(02).
      *
      *    CUSTOMER ID AS STRING FOR OUTPUT
      *
       01  WS-CUST-ID-DISPLAY            PIC 9(09).
       01  WS-DEAL-COUNT-DISPLAY         PIC 9(05).
       01  WS-TOTAL-SPENT-DISPLAY        PIC 9(11).99.
      *
      *    OUTPUT BUFFER
      *
       01  WS-OUT-BUFFER                 PIC X(800) VALUE SPACES.
      *
      *    DB2 ERROR FIELDS
      *
       01  WS-DB2-ERROR-INFO.
           05  WS-DB2-PROGRAM            PIC X(08) VALUE 'BATCRM00'.
           05  WS-DB2-PARAGRAPH          PIC X(30) VALUE SPACES.
           05  WS-DB2-SQLCODE            PIC S9(09) COMP VALUE +0.
      *
       01  WS-LOG-MESSAGE                PIC X(120) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_CRM_CUST CURSOR FOR
               SELECT C.CUSTOMER_ID
                    , C.LAST_NAME
                    , C.FIRST_NAME
                    , C.MIDDLE_INITIAL
                    , C.ADDRESS_LINE1
                    , C.CITY
                    , C.STATE
                    , C.ZIP_CODE
                    , C.PHONE
                    , C.EMAIL
                    , C.CONTACT_PREF
                    , C.DO_NOT_CALL
                    , C.DO_NOT_EMAIL
                    , C.LAST_UPDATED
               FROM   AUTOSALE.CUSTOMER C
               WHERE  C.LAST_UPDATED > :WS-LAST-RUN-DATE
               ORDER BY C.CUSTOMER_ID
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATCRM00: CRM FEED EXTRACT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-CRMFILE-STATUS = '00'
               PERFORM 2500-WRITE-HEADER
               PERFORM 3000-PROCESS-CUSTOMERS
               PERFORM 6500-UPDATE-CONTROL-TABLE
               PERFORM 8000-FINAL-CHECKPOINT
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATCRM00: PROCESSING COMPLETE'
           DISPLAY 'BATCRM00:   CUSTOMERS READ     = '
                   WS-CUST-COUNT
           DISPLAY 'BATCRM00:   RECORDS WRITTEN    = '
                   WS-WRITE-COUNT
           DISPLAY 'BATCRM00:   ERRORS             = '
                   WS-ERROR-COUNT
      *
           STOP RUN.
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE FUNCTION CURRENT-DATE(1:8)
               TO WS-CURRENT-DATE-DATA
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-TODAY-DATE
      *
           MOVE WS-TODAY-DATE TO WS-CURRENT-TIMESTAMP
      *
           MOVE WS-MODULE-ID TO WS-CHKP-PROGRAM-ID
           MOVE +500 TO WS-CHECKPOINT-FREQ
      *
           INITIALIZE WS-COUNTERS
      *
      *    GET LAST RUN DATE FROM CONTROL TABLE
      *
           EXEC SQL
               SELECT LAST_RUN_DATE
               INTO   :WS-LAST-RUN-DATE
               FROM   AUTOSALE.BATCH_CONTROL
               WHERE  PROGRAM_ID = :WS-MODULE-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE '1900-01-01' TO WS-LAST-RUN-DATE
               DISPLAY 'BATCRM00: NO PRIOR RUN - FULL EXTRACT'
           ELSE IF SQLCODE NOT = +0
               MOVE '1000-CTRL' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               MOVE '1900-01-01' TO WS-LAST-RUN-DATE
           END-IF
      *
           DISPLAY 'BATCRM00: LAST RUN DATE = ' WS-LAST-RUN-DATE
           DISPLAY 'BATCRM00: EXTRACT DATE  = ' WS-TODAY-DATE
      *
      *    CHECK FOR RESTART
      *
           CALL 'COMCKPL0' USING WS-CHECKPOINT-CONTROL
                                 WS-RESTART-CONTROL
                                 WS-CHECKPOINT-AREA
      *
           IF WS-IS-RESTART
               DISPLAY 'BATCRM00: RESTARTING FROM KEY = '
                       WS-RESTART-KEY
               MOVE WS-CHKP-RECORDS-IN  TO WS-CUST-COUNT
               MOVE WS-CHKP-RECORDS-OUT TO WS-WRITE-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT CRM-FILE
      *
           IF WS-CRMFILE-STATUS NOT = '00'
               DISPLAY 'BATCRM00: ERROR OPENING CRMFILE - '
                       WS-CRMFILE-STATUS
               MOVE 'OPEN-CRMFILE'
                   TO WS-LOG-MESSAGE
               CALL 'COMLGEL0' USING WS-MODULE-ID
                                     WS-LOG-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    2500-WRITE-HEADER                                         *
      ****************************************************************
       2500-WRITE-HEADER.
      *
           INITIALIZE WS-OUT-BUFFER
           STRING
               'CUST_ID|LAST_NAME|FIRST_NAME|MI'
               '|ADDRESS|CITY|STATE|ZIP'
               '|PHONE|EMAIL|CONTACT_PREF'
               '|DNC|DNE'
               '|TOTAL_DEALS|LAST_PURCHASE|TOTAL_SPENT'
               '|LAST_DEAL_TYPE|EXTRACT_DATE'
               DELIMITED BY SIZE
               INTO WS-OUT-BUFFER
      *
           WRITE CRM-RECORD FROM WS-OUT-BUFFER
           .
      *
      ****************************************************************
      *    3000-PROCESS-CUSTOMERS                                    *
      ****************************************************************
       3000-PROCESS-CUSTOMERS.
      *
           EXEC SQL OPEN CSR_CRM_CUST END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATCRM00: ERROR OPENING CUST CURSOR - '
                       SQLCODE
               MOVE '3000-OPEN' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-CUST
      *
           PERFORM UNTIL WS-CUST-DONE
               EXEC SQL FETCH CSR_CRM_CUST
                   INTO :WS-HV-CUSTOMER-ID
                      , :WS-HV-LAST-NAME
                      , :WS-HV-FIRST-NAME
                      , :WS-HV-MIDDLE-INIT
                      , :WS-HV-ADDRESS
                      , :WS-HV-CITY
                      , :WS-HV-STATE
                      , :WS-HV-ZIP
                      , :WS-HV-PHONE
                      , :WS-HV-EMAIL
                      , :WS-HV-CONTACT-PREF
                      , :WS-HV-DO-NOT-CALL
                      , :WS-HV-DO-NOT-EMAIL
                      , :WS-HV-LAST-UPDATED
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-CUST-COUNT
                       PERFORM 4000-GET-PURCHASE-HISTORY
                       PERFORM 5000-WRITE-CRM-RECORD
                       PERFORM 6000-UPDATE-SYNC-DATE
                       PERFORM 7000-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-CUST-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATCRM00: DB2 ERROR ON CUST - '
                               SQLCODE
                       SET WS-CUST-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_CRM_CUST END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-GET-PURCHASE-HISTORY                                 *
      ****************************************************************
       4000-GET-PURCHASE-HISTORY.
      *
           INITIALIZE WS-HV-HISTORY
      *
           EXEC SQL
               SELECT COUNT(*)
                    , MAX(DEAL_DATE)
                    , COALESCE(SUM(TOTAL_PRICE), 0)
               INTO  :WS-HV-TOTAL-DEALS
                   , :WS-HV-LAST-PURCHASE-DATE
                   , :WS-HV-TOTAL-SPENT
               FROM  AUTOSALE.SALES_DEAL
               WHERE CUSTOMER_ID = :WS-HV-CUSTOMER-ID
                 AND DEAL_STATUS IN ('DL', 'CL')
           END-EXEC
      *
           IF SQLCODE NOT = +0
           AND SQLCODE NOT = +100
               MOVE '4000-HIST' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
           END-IF
      *
      *    GET LAST DEAL TYPE
      *
           IF WS-HV-TOTAL-DEALS > 0
               EXEC SQL
                   SELECT DEAL_TYPE
                   INTO   :WS-HV-LAST-DEAL-TYPE
                   FROM   AUTOSALE.SALES_DEAL
                   WHERE  CUSTOMER_ID = :WS-HV-CUSTOMER-ID
                     AND  DEAL_DATE = :WS-HV-LAST-PURCHASE-DATE
                   FETCH FIRST 1 ROW ONLY
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE SPACES TO WS-HV-LAST-DEAL-TYPE
               END-IF
           ELSE
               MOVE SPACES TO WS-HV-LAST-DEAL-TYPE
           END-IF
           .
      *
      ****************************************************************
      *    5000-WRITE-CRM-RECORD                                    *
      ****************************************************************
       5000-WRITE-CRM-RECORD.
      *
           MOVE WS-HV-CUSTOMER-ID TO WS-CUST-ID-DISPLAY
           MOVE WS-HV-TOTAL-DEALS TO WS-DEAL-COUNT-DISPLAY
           MOVE WS-HV-TOTAL-SPENT TO WS-TOTAL-SPENT-DISPLAY
      *
           INITIALIZE WS-OUT-BUFFER
           STRING
               WS-CUST-ID-DISPLAY         '|'
               WS-HV-LAST-NAME            '|'
               WS-HV-FIRST-NAME           '|'
               WS-HV-MIDDLE-INIT          '|'
               WS-HV-ADDRESS              '|'
               WS-HV-CITY                 '|'
               WS-HV-STATE                '|'
               WS-HV-ZIP                  '|'
               WS-HV-PHONE               '|'
               WS-HV-EMAIL                '|'
               WS-HV-CONTACT-PREF         '|'
               WS-HV-DO-NOT-CALL          '|'
               WS-HV-DO-NOT-EMAIL         '|'
               WS-DEAL-COUNT-DISPLAY      '|'
               WS-HV-LAST-PURCHASE-DATE   '|'
               WS-TOTAL-SPENT-DISPLAY     '|'
               WS-HV-LAST-DEAL-TYPE       '|'
               WS-TODAY-DATE
               DELIMITED BY SIZE
               INTO WS-OUT-BUFFER
      *
           WRITE CRM-RECORD FROM WS-OUT-BUFFER
      *
           IF WS-CRMFILE-STATUS = '00'
               ADD +1 TO WS-WRITE-COUNT
           ELSE
               DISPLAY 'BATCRM00: WRITE ERROR - '
                       WS-CRMFILE-STATUS
               ADD +1 TO WS-ERROR-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    6000-UPDATE-SYNC-DATE                                     *
      ****************************************************************
       6000-UPDATE-SYNC-DATE.
      *
           EXEC SQL
               UPDATE AUTOSALE.CUSTOMER
               SET    CRM_SYNC_DATE = :WS-TODAY-DATE
               WHERE  CUSTOMER_ID = :WS-HV-CUSTOMER-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATCRM00: SYNC UPDATE ERROR CUST '
                       WS-HV-CUSTOMER-ID ' - ' SQLCODE
               MOVE '6000-SYNC' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
           END-IF
           .
      *
      ****************************************************************
      *    6500-UPDATE-CONTROL-TABLE                                 *
      ****************************************************************
       6500-UPDATE-CONTROL-TABLE.
      *
           EXEC SQL
               UPDATE AUTOSALE.BATCH_CONTROL
               SET    LAST_RUN_DATE    = :WS-TODAY-DATE
                    , RECORDS_PROCESSED = :WS-CUST-COUNT
               WHERE  PROGRAM_ID = :WS-MODULE-ID
           END-EXEC
      *
           IF SQLCODE = +100
      *        NO ROW EXISTS YET - INSERT ONE
               EXEC SQL
                   INSERT INTO AUTOSALE.BATCH_CONTROL
                   (  PROGRAM_ID
                    , LAST_RUN_DATE
                    , RECORDS_PROCESSED
                   )
                   VALUES
                   (  :WS-MODULE-ID
                    , :WS-TODAY-DATE
                    , :WS-CUST-COUNT
                   )
               END-EXEC
           END-IF
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATCRM00: CONTROL TABLE ERROR - '
                       SQLCODE
           END-IF
           .
      *
      ****************************************************************
      *    7000-CHECK-CHECKPOINT                                     *
      ****************************************************************
       7000-CHECK-CHECKPOINT.
      *
           ADD +1 TO WS-RECORDS-SINCE-CHKP
      *
           IF WS-RECORDS-SINCE-CHKP >= WS-CHECKPOINT-INTERVAL
               PERFORM 7500-TAKE-CHECKPOINT
           END-IF
           .
      *
      ****************************************************************
      *    7500-TAKE-CHECKPOINT                                      *
      ****************************************************************
       7500-TAKE-CHECKPOINT.
      *
           MOVE WS-CUST-COUNT    TO WS-CHKP-RECORDS-IN
           MOVE WS-WRITE-COUNT   TO WS-CHKP-RECORDS-OUT
           MOVE WS-ERROR-COUNT   TO WS-CHKP-RECORDS-ERR
           MOVE WS-HV-CUSTOMER-ID
                                 TO WS-CHKP-LAST-KEY
           MOVE WS-CURRENT-TIMESTAMP
                                 TO WS-CHKP-TIMESTAMP
      *
           EXEC SQL COMMIT END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATCRM00: COMMIT FAILED - ' SQLCODE
               MOVE '7500-COMMIT' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
           END-IF
      *
           CALL 'COMCKPL0' USING WS-CHECKPOINT-CONTROL
                                 WS-RESTART-CONTROL
                                 WS-CHECKPOINT-AREA
      *
           ADD +1 TO WS-CHECKPOINT-COUNT
           MOVE +0 TO WS-RECORDS-SINCE-CHKP
      *
           DISPLAY 'BATCRM00: CHECKPOINT #'
                   WS-CHECKPOINT-COUNT
                   ' AT CUSTOMER ' WS-CUST-COUNT
           .
      *
      ****************************************************************
      *    8000-FINAL-CHECKPOINT                                     *
      ****************************************************************
       8000-FINAL-CHECKPOINT.
      *
           IF WS-RECORDS-SINCE-CHKP > 0
               PERFORM 7500-TAKE-CHECKPOINT
           END-IF
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE CRM-FILE
      *
           IF WS-CRMFILE-STATUS NOT = '00'
               DISPLAY 'BATCRM00: ERROR CLOSING CRMFILE - '
                       WS-CRMFILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF BATCRM00                                              *
      ****************************************************************
