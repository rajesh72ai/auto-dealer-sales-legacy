       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATGLINT.
      ****************************************************************
      * PROGRAM:    BATGLINT                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    GENERAL LEDGER INTERFACE. GENERATES GL POSTING   *
      *             ENTRIES FROM COMPLETED DEALS NOT YET POSTED.     *
      *             CREATES ENTRIES FOR VEHICLE REVENUE, COST OF     *
      *             GOODS SOLD, F&I INCOME, AND TAX COLLECTED.       *
      *             UPDATES GL_POSTED_FLAG ON EACH DEAL.             *
      *                                                              *
      * INPUT:      AUTOSALE.SALES_DEAL (GL_POSTED_FLAG = 'N')      *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL      (READ/UPDATE)          *
      *             AUTOSALE.VEHICLE         (READ)                  *
      *             AUTOSALE.FINANCE_APP     (READ)                  *
      *             AUTOSALE.BATCH_CHECKPOINT(READ/UPDATE)           *
      *                                                              *
      * OUTPUT:     GLFILE DD - FIXED-FORMAT GL POSTING RECORDS      *
      *                                                              *
      * CALLS:      COMCKPL0 - CHECKPOINT/RESTART                    *
      *             COMDBEL0 - DB2 ERROR HANDLER                     *
      *             COMLGEL0 - LOGGING UTILITY                       *
      *                                                              *
      * CHECKPOINT: EVERY 200 DEALS VIA CALL 'COMCKPL0'             *
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
           SELECT GL-FILE
               ASSIGN TO GLFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-GLFILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  GL-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 200 CHARACTERS.
       01  GL-RECORD                     PIC X(200).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                  PIC X(08) VALUE 'BATGLINT'.
      *
       01  WS-GLFILE-STATUS              PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    CHECKPOINT AREA
           COPY WSCKPT00.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-DEAL-COUNT             PIC S9(09) COMP-3 VALUE +0.
           05  WS-GL-REC-COUNT           PIC S9(09) COMP-3 VALUE +0.
           05  WS-ERROR-COUNT            PIC S9(09) COMP-3 VALUE +0.
           05  WS-CHECKPOINT-INTERVAL    PIC S9(07) COMP-3 VALUE +200.
      *
      *    ACCUMULATORS
      *
       01  WS-GL-TOTALS.
           05  WS-TOTAL-REVENUE          PIC S9(13)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-COGS             PIC S9(13)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-FNI              PIC S9(13)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-TAX              PIC S9(13)V99 COMP-3
                                                       VALUE +0.
      *
      *    EOF FLAG
      *
       01  WS-EOF-DEAL                   PIC X(01) VALUE 'N'.
           88  WS-DEALS-DONE                       VALUE 'Y'.
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
      *    GL ACCOUNT CODES
      *
       01  WS-GL-ACCOUNTS.
           05  WS-GL-ACCT-VEH-REV       PIC X(10) VALUE '4010-00-00'.
           05  WS-GL-ACCT-COGS           PIC X(10) VALUE '5010-00-00'.
           05  WS-GL-ACCT-FNI-INC       PIC X(10) VALUE '4020-00-00'.
           05  WS-GL-ACCT-TAX-COLL      PIC X(10) VALUE '2300-00-00'.
           05  WS-GL-ACCT-RECV           PIC X(10) VALUE '1200-00-00'.
           05  WS-GL-ACCT-INVENTORY     PIC X(10) VALUE '1400-00-00'.
      *
      *    HOST VARIABLES - DEAL CURSOR
      *
       01  WS-HV-DEAL.
           05  WS-HV-DEAL-NUMBER         PIC X(10).
           05  WS-HV-DEALER-CODE         PIC X(05).
           05  WS-HV-VIN                 PIC X(17).
           05  WS-HV-DEAL-TYPE           PIC X(02).
           05  WS-HV-TOTAL-PRICE         PIC S9(09)V99 COMP-3.
           05  WS-HV-TAX-AMOUNT          PIC S9(07)V99 COMP-3.
           05  WS-HV-FNI-AMOUNT          PIC S9(07)V99 COMP-3.
           05  WS-HV-DELIVERY-DATE       PIC X(10).
      *
      *    HOST VARIABLES - VEHICLE COST
      *
       01  WS-HV-VEHICLE-COST            PIC S9(09)V99 COMP-3.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-VEHICLE-REVENUE        PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-GL-SEQ                 PIC 9(06)     VALUE 0.
      *
      *    GL OUTPUT RECORD LAYOUT
      *
       01  WS-GL-OUTPUT.
           05  WS-GLO-REC-TYPE           PIC X(02).
           05  WS-GLO-GL-ACCOUNT         PIC X(10).
           05  WS-GLO-DEAL-NUMBER        PIC X(10).
           05  WS-GLO-DEALER-CODE        PIC X(05).
           05  WS-GLO-POST-DATE          PIC X(10).
           05  WS-GLO-DEBIT-AMT          PIC S9(11)V99.
           05  WS-GLO-CREDIT-AMT         PIC S9(11)V99.
           05  WS-GLO-DESCRIPTION        PIC X(40).
           05  WS-GLO-SEQ-NUM            PIC 9(06).
           05  WS-GLO-DEAL-TYPE          PIC X(02).
           05  FILLER                    PIC X(88).
      *
      *    DB2 ERROR FIELDS
      *
       01  WS-DB2-ERROR-INFO.
           05  WS-DB2-PROGRAM            PIC X(08) VALUE 'BATGLINT'.
           05  WS-DB2-PARAGRAPH          PIC X(30) VALUE SPACES.
           05  WS-DB2-SQLCODE            PIC S9(09) COMP VALUE +0.
      *
       01  WS-LOG-MESSAGE                PIC X(120) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_GL_DEALS CURSOR FOR
               SELECT S.DEAL_NUMBER
                    , S.DEALER_CODE
                    , S.VIN
                    , S.DEAL_TYPE
                    , S.TOTAL_PRICE
                    , S.TAX_AMOUNT
                    , S.FNI_TOTAL
                    , S.DELIVERY_DATE
               FROM   AUTOSALE.SALES_DEAL S
               WHERE  S.DEAL_STATUS   = 'DL'
                 AND  S.GL_POSTED_FLAG = 'N'
               ORDER BY S.DEAL_NUMBER
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATGLINT: GL INTERFACE - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-GLFILE-STATUS = '00'
               PERFORM 3000-PROCESS-DEALS
               PERFORM 7800-WRITE-TRAILER
               PERFORM 8000-FINAL-CHECKPOINT
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATGLINT: PROCESSING COMPLETE'
           DISPLAY 'BATGLINT:   DEALS POSTED       = '
                   WS-DEAL-COUNT
           DISPLAY 'BATGLINT:   GL RECORDS WRITTEN  = '
                   WS-GL-REC-COUNT
           DISPLAY 'BATGLINT:   ERRORS              = '
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
           MOVE +200 TO WS-CHECKPOINT-FREQ
      *
           INITIALIZE WS-COUNTERS
           INITIALIZE WS-GL-TOTALS
           MOVE 0 TO WS-GL-SEQ
      *
           DISPLAY 'BATGLINT: POSTING DATE = ' WS-TODAY-DATE
      *
      *    CHECK FOR RESTART
      *
           CALL 'COMCKPL0' USING WS-CHECKPOINT-CONTROL
                                 WS-RESTART-CONTROL
                                 WS-CHECKPOINT-AREA
      *
           IF WS-IS-RESTART
               DISPLAY 'BATGLINT: RESTARTING FROM KEY = '
                       WS-RESTART-KEY
               MOVE WS-CHKP-RECORDS-IN  TO WS-DEAL-COUNT
               MOVE WS-CHKP-RECORDS-OUT TO WS-GL-REC-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT GL-FILE
      *
           IF WS-GLFILE-STATUS NOT = '00'
               DISPLAY 'BATGLINT: ERROR OPENING GLFILE - '
                       WS-GLFILE-STATUS
               MOVE 'OPEN-GLFILE'
                   TO WS-LOG-MESSAGE
               CALL 'COMLGEL0' USING WS-MODULE-ID
                                     WS-LOG-MESSAGE
           END-IF
      *
      *    WRITE FILE HEADER
      *
           IF WS-GLFILE-STATUS = '00'
               INITIALIZE WS-GL-OUTPUT
               MOVE 'HD' TO WS-GLO-REC-TYPE
               MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
               MOVE 'AUTOSALES GL POSTING FILE'
                   TO WS-GLO-DESCRIPTION
               WRITE GL-RECORD FROM WS-GL-OUTPUT
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALS                                        *
      ****************************************************************
       3000-PROCESS-DEALS.
      *
           EXEC SQL OPEN CSR_GL_DEALS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATGLINT: ERROR OPENING DEAL CURSOR - '
                       SQLCODE
               MOVE '3000-OPEN' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEAL
      *
           PERFORM UNTIL WS-DEALS-DONE
               EXEC SQL FETCH CSR_GL_DEALS
                   INTO :WS-HV-DEAL-NUMBER
                      , :WS-HV-DEALER-CODE
                      , :WS-HV-VIN
                      , :WS-HV-DEAL-TYPE
                      , :WS-HV-TOTAL-PRICE
                      , :WS-HV-TAX-AMOUNT
                      , :WS-HV-FNI-AMOUNT
                      , :WS-HV-DELIVERY-DATE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-DEAL-COUNT
                       PERFORM 4000-GET-VEHICLE-COST
                       PERFORM 5000-CREATE-GL-ENTRIES
                       PERFORM 6000-UPDATE-POSTED-FLAG
                       PERFORM 7000-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-DEALS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATGLINT: DB2 ERROR ON DEAL - '
                               SQLCODE
                       SET WS-DEALS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_GL_DEALS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-GET-VEHICLE-COST                                     *
      ****************************************************************
       4000-GET-VEHICLE-COST.
      *
           EXEC SQL
               SELECT INVOICE_PRICE
               INTO   :WS-HV-VEHICLE-COST
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-HV-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +0 TO WS-HV-VEHICLE-COST
               IF SQLCODE NOT = +100
                   MOVE '4000-VEH' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    5000-CREATE-GL-ENTRIES                                    *
      ****************************************************************
       5000-CREATE-GL-ENTRIES.
      *
      *    COMPUTE VEHICLE REVENUE (TOTAL - TAX - FNI)
      *
           COMPUTE WS-VEHICLE-REVENUE =
               WS-HV-TOTAL-PRICE - WS-HV-TAX-AMOUNT
                                 - WS-HV-FNI-AMOUNT
      *
      *    ENTRY 1: DEBIT ACCOUNTS RECEIVABLE / CREDIT VEHICLE REVENUE
      *
           PERFORM 5100-WRITE-REVENUE-ENTRY
      *
      *    ENTRY 2: DEBIT COGS / CREDIT INVENTORY
      *
           PERFORM 5200-WRITE-COGS-ENTRY
      *
      *    ENTRY 3: F&I INCOME (IF ANY)
      *
           IF WS-HV-FNI-AMOUNT > +0
               PERFORM 5300-WRITE-FNI-ENTRY
           END-IF
      *
      *    ENTRY 4: TAX COLLECTED (IF ANY)
      *
           IF WS-HV-TAX-AMOUNT > +0
               PERFORM 5400-WRITE-TAX-ENTRY
           END-IF
      *
      *    ACCUMULATE TOTALS
      *
           ADD WS-VEHICLE-REVENUE TO WS-TOTAL-REVENUE
           ADD WS-HV-VEHICLE-COST TO WS-TOTAL-COGS
           ADD WS-HV-FNI-AMOUNT TO WS-TOTAL-FNI
           ADD WS-HV-TAX-AMOUNT TO WS-TOTAL-TAX
           .
      *
      ****************************************************************
      *    5100-WRITE-REVENUE-ENTRY                                  *
      ****************************************************************
       5100-WRITE-REVENUE-ENTRY.
      *
      *    DEBIT A/R
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'DT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-RECV TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE WS-VEHICLE-REVENUE TO WS-GLO-DEBIT-AMT
           MOVE +0 TO WS-GLO-CREDIT-AMT
           MOVE 'VEHICLE SALE - A/R' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
      *
      *    CREDIT REVENUE
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'CT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-VEH-REV TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE +0 TO WS-GLO-DEBIT-AMT
           MOVE WS-VEHICLE-REVENUE TO WS-GLO-CREDIT-AMT
           MOVE 'VEHICLE SALE - REVENUE' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
           .
      *
      ****************************************************************
      *    5200-WRITE-COGS-ENTRY                                     *
      ****************************************************************
       5200-WRITE-COGS-ENTRY.
      *
      *    DEBIT COGS
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'DT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-COGS TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE WS-HV-VEHICLE-COST TO WS-GLO-DEBIT-AMT
           MOVE +0 TO WS-GLO-CREDIT-AMT
           MOVE 'COST OF GOODS SOLD' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
      *
      *    CREDIT INVENTORY
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'CT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-INVENTORY TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE +0 TO WS-GLO-DEBIT-AMT
           MOVE WS-HV-VEHICLE-COST TO WS-GLO-CREDIT-AMT
           MOVE 'INVENTORY RELIEF' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
           .
      *
      ****************************************************************
      *    5300-WRITE-FNI-ENTRY                                      *
      ****************************************************************
       5300-WRITE-FNI-ENTRY.
      *
      *    DEBIT A/R
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'DT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-RECV TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE WS-HV-FNI-AMOUNT TO WS-GLO-DEBIT-AMT
           MOVE +0 TO WS-GLO-CREDIT-AMT
           MOVE 'F AND I INCOME - A/R' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
      *
      *    CREDIT F&I INCOME
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'CT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-FNI-INC TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE +0 TO WS-GLO-DEBIT-AMT
           MOVE WS-HV-FNI-AMOUNT TO WS-GLO-CREDIT-AMT
           MOVE 'F AND I INCOME' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
           .
      *
      ****************************************************************
      *    5400-WRITE-TAX-ENTRY                                      *
      ****************************************************************
       5400-WRITE-TAX-ENTRY.
      *
      *    DEBIT A/R
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'DT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-RECV TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE WS-HV-TAX-AMOUNT TO WS-GLO-DEBIT-AMT
           MOVE +0 TO WS-GLO-CREDIT-AMT
           MOVE 'SALES TAX - A/R' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
      *
      *    CREDIT TAX PAYABLE
      *
           INITIALIZE WS-GL-OUTPUT
           ADD +1 TO WS-GL-SEQ
           MOVE 'CT' TO WS-GLO-REC-TYPE
           MOVE WS-GL-ACCT-TAX-COLL TO WS-GLO-GL-ACCOUNT
           MOVE WS-HV-DEAL-NUMBER TO WS-GLO-DEAL-NUMBER
           MOVE WS-HV-DEALER-CODE TO WS-GLO-DEALER-CODE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE +0 TO WS-GLO-DEBIT-AMT
           MOVE WS-HV-TAX-AMOUNT TO WS-GLO-CREDIT-AMT
           MOVE 'SALES TAX COLLECTED' TO WS-GLO-DESCRIPTION
           MOVE WS-GL-SEQ TO WS-GLO-SEQ-NUM
           MOVE WS-HV-DEAL-TYPE TO WS-GLO-DEAL-TYPE
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
           .
      *
      ****************************************************************
      *    6000-UPDATE-POSTED-FLAG                                   *
      ****************************************************************
       6000-UPDATE-POSTED-FLAG.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
               SET    GL_POSTED_FLAG = 'Y'
                    , GL_POSTED_DATE = :WS-TODAY-DATE
               WHERE  DEAL_NUMBER = :WS-HV-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               DISPLAY 'BATGLINT: UPDATE ERROR DEAL '
                       WS-HV-DEAL-NUMBER ' - ' SQLCODE
               MOVE '6000-UPDATE' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
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
           MOVE WS-DEAL-COUNT    TO WS-CHKP-RECORDS-IN
           MOVE WS-GL-REC-COUNT  TO WS-CHKP-RECORDS-OUT
           MOVE WS-ERROR-COUNT   TO WS-CHKP-RECORDS-ERR
           MOVE WS-HV-DEAL-NUMBER
                                 TO WS-CHKP-LAST-KEY
           MOVE WS-TOTAL-REVENUE TO WS-CHKP-TOTAL-AMT
           MOVE WS-CURRENT-TIMESTAMP
                                 TO WS-CHKP-TIMESTAMP
      *
           EXEC SQL COMMIT END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATGLINT: COMMIT FAILED - ' SQLCODE
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
           DISPLAY 'BATGLINT: CHECKPOINT #'
                   WS-CHECKPOINT-COUNT
                   ' AT DEAL ' WS-DEAL-COUNT
           .
      *
      ****************************************************************
      *    7800-WRITE-TRAILER                                        *
      ****************************************************************
       7800-WRITE-TRAILER.
      *
           INITIALIZE WS-GL-OUTPUT
           MOVE 'TR' TO WS-GLO-REC-TYPE
           MOVE WS-TODAY-DATE TO WS-GLO-POST-DATE
           MOVE WS-TOTAL-REVENUE TO WS-GLO-DEBIT-AMT
           MOVE WS-TOTAL-COGS TO WS-GLO-CREDIT-AMT
           STRING 'TOTALS: ' WS-DEAL-COUNT ' DEALS'
               DELIMITED BY SIZE
               INTO WS-GLO-DESCRIPTION
           WRITE GL-RECORD FROM WS-GL-OUTPUT
           ADD +1 TO WS-GL-REC-COUNT
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
           CLOSE GL-FILE
      *
           IF WS-GLFILE-STATUS NOT = '00'
               DISPLAY 'BATGLINT: ERROR CLOSING GLFILE - '
                       WS-GLFILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF BATGLINT                                              *
      ****************************************************************
