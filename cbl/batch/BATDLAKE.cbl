       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATDLAKE.
      ****************************************************************
      * PROGRAM:    BATDLAKE                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    DATA LAKE EXTRACT. READS AUDIT_LOG FOR TODAY'S   *
      *             CHANGES, EXTRACTS FULL CURRENT RECORDS FROM      *
      *             EACH CHANGED TABLE, AND WRITES JSON-LIKE         *
      *             DELIMITED OUTPUT FOR DATA LAKE INGESTION.        *
      *                                                              *
      * INPUT:      AUTOSALE.AUDIT_LOG (TODAY'S CHANGES)             *
      *                                                              *
      * TABLES:     AUTOSALE.AUDIT_LOG       (READ)                  *
      *             AUTOSALE.SALES_DEAL      (READ)                  *
      *             AUTOSALE.VEHICLE         (READ)                  *
      *             AUTOSALE.CUSTOMER        (READ)                  *
      *             AUTOSALE.FINANCE_APP     (READ)                  *
      *             AUTOSALE.REGISTRATION    (READ)                  *
      *             AUTOSALE.BATCH_CHECKPOINT(READ/UPDATE)           *
      *                                                              *
      * OUTPUT:     OUTFILE DD - JSON-LIKE DELIMITED EXTRACT         *
      *                                                              *
      * CALLS:      COMCKPL0 - CHECKPOINT/RESTART                    *
      *             COMDBEL0 - DB2 ERROR HANDLER                     *
      *             COMLGEL0 - LOGGING UTILITY                       *
      *                                                              *
      * CHECKPOINT: EVERY 1000 RECORDS VIA CALL 'COMCKPL0'          *
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
           SELECT OUTPUT-FILE
               ASSIGN TO OUTFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-OUTFILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  OUTPUT-FILE
           RECORDING MODE IS V
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 20 TO 2000 CHARACTERS.
       01  OUTPUT-RECORD                 PIC X(2000).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                  PIC X(08) VALUE 'BATDLAKE'.
      *
       01  WS-OUTFILE-STATUS             PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    CHECKPOINT AREA
           COPY WSCKPT00.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-AUDIT-COUNT            PIC S9(09) COMP-3 VALUE +0.
           05  WS-EXTRACT-COUNT          PIC S9(09) COMP-3 VALUE +0.
           05  WS-ERROR-COUNT            PIC S9(09) COMP-3 VALUE +0.
           05  WS-CHECKPOINT-INTERVAL    PIC S9(07) COMP-3 VALUE +1000.
      *
      *    EOF FLAGS
      *
       01  WS-EOF-AUDIT                  PIC X(01) VALUE 'N'.
           88  WS-AUDIT-DONE                       VALUE 'Y'.
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
      *
      *    HOST VARIABLES - AUDIT LOG CURSOR
      *
       01  WS-HV-AUDIT.
           05  WS-HV-AUD-TABLE-NAME     PIC X(30).
           05  WS-HV-AUD-PRIMARY-KEY    PIC X(30).
           05  WS-HV-AUD-ACTION         PIC X(01).
           05  WS-HV-AUD-TIMESTAMP      PIC X(26).
           05  WS-HV-AUD-USER-ID        PIC X(08).
      *
      *    HOST VARIABLES - SALES DEAL
      *
       01  WS-HV-DEAL.
           05  WS-HV-DL-DEAL-NUMBER     PIC X(10).
           05  WS-HV-DL-DEALER-CODE     PIC X(05).
           05  WS-HV-DL-CUSTOMER-ID     PIC S9(09) COMP.
           05  WS-HV-DL-VIN             PIC X(17).
           05  WS-HV-DL-DEAL-TYPE       PIC X(02).
           05  WS-HV-DL-DEAL-STATUS     PIC X(02).
           05  WS-HV-DL-TOTAL-PRICE     PIC S9(09)V99 COMP-3.
           05  WS-HV-DL-DEAL-DATE       PIC X(10).
      *
      *    HOST VARIABLES - VEHICLE
      *
       01  WS-HV-VEH.
           05  WS-HV-VH-VIN             PIC X(17).
           05  WS-HV-VH-MAKE            PIC X(10).
           05  WS-HV-VH-MODEL-DESC      PIC X(30).
           05  WS-HV-VH-MODEL-YEAR      PIC X(04).
           05  WS-HV-VH-STATUS          PIC X(02).
           05  WS-HV-VH-DEALER-CODE     PIC X(05).
           05  WS-HV-VH-INVOICE         PIC S9(07)V99 COMP-3.
           05  WS-HV-VH-MSRP            PIC S9(07)V99 COMP-3.
      *
      *    HOST VARIABLES - CUSTOMER
      *
       01  WS-HV-CUST.
           05  WS-HV-CU-CUSTOMER-ID     PIC S9(09) COMP.
           05  WS-HV-CU-LAST-NAME       PIC X(25).
           05  WS-HV-CU-FIRST-NAME      PIC X(15).
           05  WS-HV-CU-PHONE           PIC X(15).
           05  WS-HV-CU-EMAIL           PIC X(50).
           05  WS-HV-CU-ADDRESS         PIC X(40).
           05  WS-HV-CU-CITY            PIC X(25).
           05  WS-HV-CU-STATE           PIC X(02).
           05  WS-HV-CU-ZIP             PIC X(10).
      *
      *    HOST VARIABLES - FINANCE APP
      *
       01  WS-HV-FIN.
           05  WS-HV-FN-APP-ID          PIC S9(09) COMP.
           05  WS-HV-FN-DEAL-NUMBER     PIC X(10).
           05  WS-HV-FN-LENDER-CODE     PIC X(05).
           05  WS-HV-FN-APP-STATUS      PIC X(02).
           05  WS-HV-FN-AMOUNT          PIC S9(09)V99 COMP-3.
           05  WS-HV-FN-RATE            PIC S9(03)V99 COMP-3.
           05  WS-HV-FN-TERM            PIC S9(03) COMP-3.
      *
      *    HOST VARIABLES - REGISTRATION
      *
       01  WS-HV-REG.
           05  WS-HV-RG-REG-ID          PIC S9(09) COMP.
           05  WS-HV-RG-VIN             PIC X(17).
           05  WS-HV-RG-PLATE-NUM       PIC X(10).
           05  WS-HV-RG-STATE           PIC X(02).
           05  WS-HV-RG-REG-DATE        PIC X(10).
           05  WS-HV-RG-EXP-DATE        PIC X(10).
           05  WS-HV-RG-STATUS          PIC X(02).
      *
      *    OUTPUT BUFFER
      *
       01  WS-OUT-BUFFER                 PIC X(2000) VALUE SPACES.
       01  WS-OUT-LENGTH                 PIC S9(04) COMP VALUE +0.
      *
      *    DB2 ERROR FIELDS
      *
       01  WS-DB2-ERROR-INFO.
           05  WS-DB2-PROGRAM            PIC X(08) VALUE 'BATDLAKE'.
           05  WS-DB2-PARAGRAPH          PIC X(30) VALUE SPACES.
           05  WS-DB2-SQLCODE            PIC S9(09) COMP VALUE +0.
      *
       01  WS-LOG-MESSAGE                PIC X(120) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_AUDIT CURSOR FOR
               SELECT TABLE_NAME
                    , PRIMARY_KEY
                    , AUDIT_ACTION
                    , AUDIT_TIMESTAMP
                    , USER_ID
               FROM   AUTOSALE.AUDIT_LOG
               WHERE  DATE(AUDIT_TIMESTAMP) = :WS-TODAY-DATE
               ORDER BY AUDIT_TIMESTAMP
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATDLAKE: DATA LAKE EXTRACT - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-OUTFILE-STATUS = '00'
               PERFORM 3000-PROCESS-AUDIT-LOG
               PERFORM 8000-FINAL-CHECKPOINT
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATDLAKE: PROCESSING COMPLETE'
           DISPLAY 'BATDLAKE:   AUDIT RECORDS     = '
                   WS-AUDIT-COUNT
           DISPLAY 'BATDLAKE:   RECORDS EXTRACTED  = '
                   WS-EXTRACT-COUNT
           DISPLAY 'BATDLAKE:   ERRORS             = '
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
           MOVE +1000 TO WS-CHECKPOINT-FREQ
      *
           INITIALIZE WS-COUNTERS
      *
           DISPLAY 'BATDLAKE: EXTRACT DATE = ' WS-TODAY-DATE
      *
      *    CHECK FOR RESTART
      *
           CALL 'COMCKPL0' USING WS-CHECKPOINT-CONTROL
                                 WS-RESTART-CONTROL
                                 WS-CHECKPOINT-AREA
      *
           IF WS-IS-RESTART
               DISPLAY 'BATDLAKE: RESTARTING FROM KEY = '
                       WS-RESTART-KEY
               MOVE WS-CHKP-RECORDS-IN  TO WS-AUDIT-COUNT
               MOVE WS-CHKP-RECORDS-OUT TO WS-EXTRACT-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT OUTPUT-FILE
      *
           IF WS-OUTFILE-STATUS NOT = '00'
               DISPLAY 'BATDLAKE: ERROR OPENING OUTFILE - '
                       WS-OUTFILE-STATUS
               MOVE 'OPEN-OUTFILE'
                   TO WS-LOG-MESSAGE
               CALL 'COMLGEL0' USING WS-MODULE-ID
                                     WS-LOG-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-AUDIT-LOG                                    *
      ****************************************************************
       3000-PROCESS-AUDIT-LOG.
      *
           EXEC SQL OPEN CSR_AUDIT END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDLAKE: ERROR OPENING AUDIT CURSOR - '
                       SQLCODE
               MOVE '3000-OPEN' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-AUDIT
      *
           PERFORM UNTIL WS-AUDIT-DONE
               EXEC SQL FETCH CSR_AUDIT
                   INTO :WS-HV-AUD-TABLE-NAME
                      , :WS-HV-AUD-PRIMARY-KEY
                      , :WS-HV-AUD-ACTION
                      , :WS-HV-AUD-TIMESTAMP
                      , :WS-HV-AUD-USER-ID
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-AUDIT-COUNT
                       PERFORM 4000-EXTRACT-RECORD
                       PERFORM 7000-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-AUDIT-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDLAKE: DB2 ERROR ON AUDIT - '
                               SQLCODE
                       SET WS-AUDIT-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_AUDIT END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-EXTRACT-RECORD - EXTRACT BASED ON TABLE NAME         *
      ****************************************************************
       4000-EXTRACT-RECORD.
      *
           EVALUATE WS-HV-AUD-TABLE-NAME
               WHEN 'SALES_DEAL'
                   PERFORM 4100-EXTRACT-DEAL
               WHEN 'VEHICLE'
                   PERFORM 4200-EXTRACT-VEHICLE
               WHEN 'CUSTOMER'
                   PERFORM 4300-EXTRACT-CUSTOMER
               WHEN 'FINANCE_APP'
                   PERFORM 4400-EXTRACT-FINANCE
               WHEN 'REGISTRATION'
                   PERFORM 4500-EXTRACT-REGISTRATION
               WHEN OTHER
                   DISPLAY 'BATDLAKE: UNKNOWN TABLE - '
                           WS-HV-AUD-TABLE-NAME
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4100-EXTRACT-DEAL                                         *
      ****************************************************************
       4100-EXTRACT-DEAL.
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEALER_CODE
                    , CUSTOMER_ID
                    , VIN
                    , DEAL_TYPE
                    , DEAL_STATUS
                    , TOTAL_PRICE
                    , DEAL_DATE
               INTO  :WS-HV-DL-DEAL-NUMBER
                   , :WS-HV-DL-DEALER-CODE
                   , :WS-HV-DL-CUSTOMER-ID
                   , :WS-HV-DL-VIN
                   , :WS-HV-DL-DEAL-TYPE
                   , :WS-HV-DL-DEAL-STATUS
                   , :WS-HV-DL-TOTAL-PRICE
                   , :WS-HV-DL-DEAL-DATE
               FROM  AUTOSALE.SALES_DEAL
               WHERE DEAL_NUMBER = :WS-HV-AUD-PRIMARY-KEY
           END-EXEC
      *
           IF SQLCODE = +0
               INITIALIZE WS-OUT-BUFFER
               STRING
                 '{"table":"SALES_DEAL"'
                 ',"key":"' WS-HV-DL-DEAL-NUMBER '"'
                 ',"dealer":"' WS-HV-DL-DEALER-CODE '"'
                 ',"vin":"' WS-HV-DL-VIN '"'
                 ',"type":"' WS-HV-DL-DEAL-TYPE '"'
                 ',"status":"' WS-HV-DL-DEAL-STATUS '"'
                 ',"date":"' WS-HV-DL-DEAL-DATE '"'
                 ',"action":"' WS-HV-AUD-ACTION '"'
                 ',"ts":"' WS-HV-AUD-TIMESTAMP '"}'
                 DELIMITED BY SIZE
                 INTO WS-OUT-BUFFER
               PERFORM 6000-WRITE-OUTPUT
           ELSE
               IF SQLCODE NOT = +100
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE '4100-DEAL' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4200-EXTRACT-VEHICLE                                      *
      ****************************************************************
       4200-EXTRACT-VEHICLE.
      *
           EXEC SQL
               SELECT VIN
                    , MAKE
                    , MODEL_DESC
                    , MODEL_YEAR
                    , VEHICLE_STATUS
                    , DEALER_CODE
                    , INVOICE_PRICE
                    , MSRP
               INTO  :WS-HV-VH-VIN
                   , :WS-HV-VH-MAKE
                   , :WS-HV-VH-MODEL-DESC
                   , :WS-HV-VH-MODEL-YEAR
                   , :WS-HV-VH-STATUS
                   , :WS-HV-VH-DEALER-CODE
                   , :WS-HV-VH-INVOICE
                   , :WS-HV-VH-MSRP
               FROM  AUTOSALE.VEHICLE
               WHERE VIN = :WS-HV-AUD-PRIMARY-KEY
           END-EXEC
      *
           IF SQLCODE = +0
               INITIALIZE WS-OUT-BUFFER
               STRING
                 '{"table":"VEHICLE"'
                 ',"key":"' WS-HV-VH-VIN '"'
                 ',"make":"' WS-HV-VH-MAKE '"'
                 ',"model":"' WS-HV-VH-MODEL-DESC '"'
                 ',"year":"' WS-HV-VH-MODEL-YEAR '"'
                 ',"status":"' WS-HV-VH-STATUS '"'
                 ',"dealer":"' WS-HV-VH-DEALER-CODE '"'
                 ',"action":"' WS-HV-AUD-ACTION '"'
                 ',"ts":"' WS-HV-AUD-TIMESTAMP '"}'
                 DELIMITED BY SIZE
                 INTO WS-OUT-BUFFER
               PERFORM 6000-WRITE-OUTPUT
           ELSE
               IF SQLCODE NOT = +100
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE '4200-VEH' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4300-EXTRACT-CUSTOMER                                     *
      ****************************************************************
       4300-EXTRACT-CUSTOMER.
      *
           EXEC SQL
               SELECT CUSTOMER_ID
                    , LAST_NAME
                    , FIRST_NAME
                    , PHONE
                    , EMAIL
                    , ADDRESS_LINE1
                    , CITY
                    , STATE
                    , ZIP_CODE
               INTO  :WS-HV-CU-CUSTOMER-ID
                   , :WS-HV-CU-LAST-NAME
                   , :WS-HV-CU-FIRST-NAME
                   , :WS-HV-CU-PHONE
                   , :WS-HV-CU-EMAIL
                   , :WS-HV-CU-ADDRESS
                   , :WS-HV-CU-CITY
                   , :WS-HV-CU-STATE
                   , :WS-HV-CU-ZIP
               FROM  AUTOSALE.CUSTOMER
               WHERE CUSTOMER_ID = :WS-HV-AUD-PRIMARY-KEY
           END-EXEC
      *
           IF SQLCODE = +0
               INITIALIZE WS-OUT-BUFFER
               STRING
                 '{"table":"CUSTOMER"'
                 ',"key":"' WS-HV-AUD-PRIMARY-KEY '"'
                 ',"last":"' WS-HV-CU-LAST-NAME '"'
                 ',"first":"' WS-HV-CU-FIRST-NAME '"'
                 ',"phone":"' WS-HV-CU-PHONE '"'
                 ',"email":"' WS-HV-CU-EMAIL '"'
                 ',"city":"' WS-HV-CU-CITY '"'
                 ',"state":"' WS-HV-CU-STATE '"'
                 ',"action":"' WS-HV-AUD-ACTION '"'
                 ',"ts":"' WS-HV-AUD-TIMESTAMP '"}'
                 DELIMITED BY SIZE
                 INTO WS-OUT-BUFFER
               PERFORM 6000-WRITE-OUTPUT
           ELSE
               IF SQLCODE NOT = +100
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE '4300-CUST' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4400-EXTRACT-FINANCE                                      *
      ****************************************************************
       4400-EXTRACT-FINANCE.
      *
           EXEC SQL
               SELECT APP_ID
                    , DEAL_NUMBER
                    , LENDER_CODE
                    , APP_STATUS
                    , FINANCE_AMOUNT
                    , INTEREST_RATE
                    , TERM_MONTHS
               INTO  :WS-HV-FN-APP-ID
                   , :WS-HV-FN-DEAL-NUMBER
                   , :WS-HV-FN-LENDER-CODE
                   , :WS-HV-FN-APP-STATUS
                   , :WS-HV-FN-AMOUNT
                   , :WS-HV-FN-RATE
                   , :WS-HV-FN-TERM
               FROM  AUTOSALE.FINANCE_APP
               WHERE APP_ID = :WS-HV-AUD-PRIMARY-KEY
           END-EXEC
      *
           IF SQLCODE = +0
               INITIALIZE WS-OUT-BUFFER
               STRING
                 '{"table":"FINANCE_APP"'
                 ',"key":"' WS-HV-AUD-PRIMARY-KEY '"'
                 ',"deal":"' WS-HV-FN-DEAL-NUMBER '"'
                 ',"lender":"' WS-HV-FN-LENDER-CODE '"'
                 ',"status":"' WS-HV-FN-APP-STATUS '"'
                 ',"action":"' WS-HV-AUD-ACTION '"'
                 ',"ts":"' WS-HV-AUD-TIMESTAMP '"}'
                 DELIMITED BY SIZE
                 INTO WS-OUT-BUFFER
               PERFORM 6000-WRITE-OUTPUT
           ELSE
               IF SQLCODE NOT = +100
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE '4400-FIN' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4500-EXTRACT-REGISTRATION                                 *
      ****************************************************************
       4500-EXTRACT-REGISTRATION.
      *
           EXEC SQL
               SELECT REG_ID
                    , VIN
                    , PLATE_NUMBER
                    , STATE
                    , REG_DATE
                    , EXPIRY_DATE
                    , REG_STATUS
               INTO  :WS-HV-RG-REG-ID
                   , :WS-HV-RG-VIN
                   , :WS-HV-RG-PLATE-NUM
                   , :WS-HV-RG-STATE
                   , :WS-HV-RG-REG-DATE
                   , :WS-HV-RG-EXP-DATE
                   , :WS-HV-RG-STATUS
               FROM  AUTOSALE.REGISTRATION
               WHERE REG_ID = :WS-HV-AUD-PRIMARY-KEY
           END-EXEC
      *
           IF SQLCODE = +0
               INITIALIZE WS-OUT-BUFFER
               STRING
                 '{"table":"REGISTRATION"'
                 ',"key":"' WS-HV-AUD-PRIMARY-KEY '"'
                 ',"vin":"' WS-HV-RG-VIN '"'
                 ',"plate":"' WS-HV-RG-PLATE-NUM '"'
                 ',"state":"' WS-HV-RG-STATE '"'
                 ',"regDate":"' WS-HV-RG-REG-DATE '"'
                 ',"status":"' WS-HV-RG-STATUS '"'
                 ',"action":"' WS-HV-AUD-ACTION '"'
                 ',"ts":"' WS-HV-AUD-TIMESTAMP '"}'
                 DELIMITED BY SIZE
                 INTO WS-OUT-BUFFER
               PERFORM 6000-WRITE-OUTPUT
           ELSE
               IF SQLCODE NOT = +100
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE '4500-REG' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    6000-WRITE-OUTPUT                                         *
      ****************************************************************
       6000-WRITE-OUTPUT.
      *
           WRITE OUTPUT-RECORD FROM WS-OUT-BUFFER
      *
           IF WS-OUTFILE-STATUS = '00'
               ADD +1 TO WS-EXTRACT-COUNT
           ELSE
               DISPLAY 'BATDLAKE: WRITE ERROR - '
                       WS-OUTFILE-STATUS
               ADD +1 TO WS-ERROR-COUNT
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
           MOVE WS-AUDIT-COUNT   TO WS-CHKP-RECORDS-IN
           MOVE WS-EXTRACT-COUNT TO WS-CHKP-RECORDS-OUT
           MOVE WS-ERROR-COUNT   TO WS-CHKP-RECORDS-ERR
           MOVE WS-HV-AUD-PRIMARY-KEY
                                 TO WS-CHKP-LAST-KEY
           MOVE WS-CURRENT-TIMESTAMP
                                 TO WS-CHKP-TIMESTAMP
      *
           EXEC SQL COMMIT END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDLAKE: COMMIT FAILED - ' SQLCODE
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
           DISPLAY 'BATDLAKE: CHECKPOINT #'
                   WS-CHECKPOINT-COUNT
                   ' AT RECORD ' WS-AUDIT-COUNT
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
           CLOSE OUTPUT-FILE
      *
           IF WS-OUTFILE-STATUS NOT = '00'
               DISPLAY 'BATDLAKE: ERROR CLOSING OUTFILE - '
                       WS-OUTFILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF BATDLAKE                                              *
      ****************************************************************
