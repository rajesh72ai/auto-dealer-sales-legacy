       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATDMS00.
      ****************************************************************
      * PROGRAM:    BATDMS00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    DMS (DEALER MANAGEMENT SYSTEM) INTERFACE. SENDS  *
      *             DEAL AND INVENTORY DATA TO EXTERNAL DMS. READS   *
      *             ACTIVE INVENTORY AND RECENT DEALS, FORMATS PER   *
      *             DMS SPECIFICATION WITH HEADER + DETAIL RECORDS,  *
      *             AND TRACKS LAST SYNC VIA CONTROL TABLE.          *
      *                                                              *
      * INPUT:      AUTOSALE.VEHICLE     (ACTIVE INVENTORY)          *
      *             AUTOSALE.SALES_DEAL  (RECENT DEALS)              *
      *                                                              *
      * TABLES:     AUTOSALE.VEHICLE         (READ)                  *
      *             AUTOSALE.SALES_DEAL      (READ)                  *
      *             AUTOSALE.CUSTOMER        (READ)                  *
      *             AUTOSALE.DEALER          (READ)                  *
      *             AUTOSALE.BATCH_CONTROL   (READ/UPDATE)           *
      *             AUTOSALE.BATCH_CHECKPOINT(READ/UPDATE)           *
      *                                                              *
      * OUTPUT:     DMSFILE DD - DMS FORMAT HEADER + DETAIL RECORDS  *
      *                                                              *
      * CALLS:      COMCKPL0 - CHECKPOINT/RESTART                    *
      *             COMDBEL0 - DB2 ERROR HANDLER                     *
      *             COMLGEL0 - LOGGING UTILITY                       *
      *                                                              *
      * CHECKPOINT: EVERY 500 RECORDS VIA CALL 'COMCKPL0'           *
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
           SELECT DMS-FILE
               ASSIGN TO DMSFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-DMSFILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  DMS-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 500 CHARACTERS.
       01  DMS-RECORD                    PIC X(500).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                  PIC X(08) VALUE 'BATDMS00'.
      *
       01  WS-DMSFILE-STATUS             PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    CHECKPOINT AREA
           COPY WSCKPT00.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-INV-COUNT              PIC S9(09) COMP-3 VALUE +0.
           05  WS-DEAL-COUNT             PIC S9(09) COMP-3 VALUE +0.
           05  WS-TOTAL-WRITE            PIC S9(09) COMP-3 VALUE +0.
           05  WS-ERROR-COUNT            PIC S9(09) COMP-3 VALUE +0.
           05  WS-CHECKPOINT-INTERVAL    PIC S9(07) COMP-3 VALUE +500.
      *
      *    EOF FLAGS
      *
       01  WS-EOF-INV                    PIC X(01) VALUE 'N'.
           88  WS-INV-DONE                         VALUE 'Y'.
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
       01  WS-LAST-SYNC-DATE             PIC X(10) VALUE SPACES.
      *
      *    DMS FILE HEADER RECORD
      *
       01  WS-DMS-FILE-HEADER.
           05  WS-FH-REC-TYPE            PIC X(02) VALUE 'FH'.
           05  WS-FH-SYSTEM-ID           PIC X(10) VALUE 'AUTOSALES '.
           05  WS-FH-FILE-DATE           PIC X(10).
           05  WS-FH-FILE-TIME           PIC X(08).
           05  WS-FH-VERSION             PIC X(04) VALUE '0100'.
           05  FILLER                    PIC X(466) VALUE SPACES.
      *
      *    DMS DEALER HEADER RECORD
      *
       01  WS-DMS-DEALER-HDR.
           05  WS-DH-REC-TYPE            PIC X(02) VALUE 'DH'.
           05  WS-DH-DEALER-CODE         PIC X(05).
           05  WS-DH-DEALER-NAME         PIC X(40).
           05  WS-DH-ADDRESS             PIC X(40).
           05  WS-DH-CITY                PIC X(25).
           05  WS-DH-STATE               PIC X(02).
           05  WS-DH-ZIP                 PIC X(10).
           05  WS-DH-PHONE               PIC X(15).
           05  FILLER                    PIC X(361) VALUE SPACES.
      *
      *    DMS INVENTORY DETAIL RECORD
      *
       01  WS-DMS-INV-DETAIL.
           05  WS-ID-REC-TYPE            PIC X(02) VALUE 'IV'.
           05  WS-ID-VIN                 PIC X(17).
           05  WS-ID-MAKE                PIC X(10).
           05  WS-ID-MODEL               PIC X(30).
           05  WS-ID-YEAR                PIC X(04).
           05  WS-ID-TRIM                PIC X(15).
           05  WS-ID-EXT-COLOR           PIC X(15).
           05  WS-ID-INT-COLOR           PIC X(15).
           05  WS-ID-STOCK-STATUS        PIC X(02).
           05  WS-ID-DAYS-IN-STOCK       PIC 9(04).
           05  WS-ID-INVOICE             PIC S9(09)V99.
           05  WS-ID-MSRP                PIC S9(09)V99.
           05  WS-ID-DEALER-CODE         PIC X(05).
           05  FILLER                    PIC X(345) VALUE SPACES.
      *
      *    DMS DEAL DETAIL RECORD
      *
       01  WS-DMS-DEAL-DETAIL.
           05  WS-DD-REC-TYPE            PIC X(02) VALUE 'SD'.
           05  WS-DD-DEAL-NUMBER         PIC X(10).
           05  WS-DD-DEALER-CODE         PIC X(05).
           05  WS-DD-CUSTOMER-ID         PIC 9(09).
           05  WS-DD-CUST-NAME           PIC X(40).
           05  WS-DD-VIN                 PIC X(17).
           05  WS-DD-DEAL-TYPE           PIC X(02).
           05  WS-DD-DEAL-STATUS         PIC X(02).
           05  WS-DD-TOTAL-PRICE         PIC S9(09)V99.
           05  WS-DD-TAX-AMOUNT          PIC S9(07)V99.
           05  WS-DD-DEAL-DATE           PIC X(10).
           05  WS-DD-DELIVERY-DATE       PIC X(10).
           05  FILLER                    PIC X(370) VALUE SPACES.
      *
      *    DMS FILE TRAILER RECORD
      *
       01  WS-DMS-FILE-TRAILER.
           05  WS-FT-REC-TYPE            PIC X(02) VALUE 'FT'.
           05  WS-FT-INV-COUNT           PIC 9(07).
           05  WS-FT-DEAL-COUNT          PIC 9(07).
           05  WS-FT-TOTAL-RECORDS       PIC 9(09).
           05  FILLER                    PIC X(475) VALUE SPACES.
      *
      *    HOST VARIABLES - DEALER
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE            PIC X(05).
           05  WS-HV-DLR-NAME            PIC X(40).
           05  WS-HV-DLR-ADDRESS         PIC X(40).
           05  WS-HV-DLR-CITY            PIC X(25).
           05  WS-HV-DLR-STATE           PIC X(02).
           05  WS-HV-DLR-ZIP             PIC X(10).
           05  WS-HV-DLR-PHONE           PIC X(15).
      *
      *    HOST VARIABLES - INVENTORY CURSOR
      *
       01  WS-HV-INV.
           05  WS-HV-IV-VIN              PIC X(17).
           05  WS-HV-IV-MAKE             PIC X(10).
           05  WS-HV-IV-MODEL            PIC X(30).
           05  WS-HV-IV-YEAR             PIC X(04).
           05  WS-HV-IV-TRIM             PIC X(15).
           05  WS-HV-IV-EXT-COLOR        PIC X(15).
           05  WS-HV-IV-INT-COLOR        PIC X(15).
           05  WS-HV-IV-STATUS           PIC X(02).
           05  WS-HV-IV-DAYS-STOCK       PIC S9(04) COMP.
           05  WS-HV-IV-INVOICE          PIC S9(09)V99 COMP-3.
           05  WS-HV-IV-MSRP             PIC S9(09)V99 COMP-3.
           05  WS-HV-IV-DEALER           PIC X(05).
      *
      *    HOST VARIABLES - DEAL CURSOR
      *
       01  WS-HV-DEAL.
           05  WS-HV-DL-DEAL-NUM         PIC X(10).
           05  WS-HV-DL-DEALER           PIC X(05).
           05  WS-HV-DL-CUST-ID          PIC S9(09) COMP.
           05  WS-HV-DL-CUST-LAST        PIC X(25).
           05  WS-HV-DL-CUST-FIRST       PIC X(15).
           05  WS-HV-DL-VIN              PIC X(17).
           05  WS-HV-DL-DEAL-TYPE        PIC X(02).
           05  WS-HV-DL-DEAL-STATUS      PIC X(02).
           05  WS-HV-DL-TOTAL-PRICE      PIC S9(09)V99 COMP-3.
           05  WS-HV-DL-TAX              PIC S9(07)V99 COMP-3.
           05  WS-HV-DL-DEAL-DATE        PIC X(10).
           05  WS-HV-DL-DELIVERY-DATE    PIC X(10).
      *
      *    WORK FIELDS
      *
       01  WS-CUST-FULL-NAME             PIC X(40) VALUE SPACES.
       01  WS-EOF-DEALER                 PIC X(01) VALUE 'N'.
           88  WS-DEALER-DONE                      VALUE 'Y'.
      *
      *    DB2 ERROR FIELDS
      *
       01  WS-DB2-ERROR-INFO.
           05  WS-DB2-PROGRAM            PIC X(08) VALUE 'BATDMS00'.
           05  WS-DB2-PARAGRAPH          PIC X(30) VALUE SPACES.
           05  WS-DB2-SQLCODE            PIC S9(09) COMP VALUE +0.
      *
       01  WS-LOG-MESSAGE                PIC X(120) VALUE SPACES.
      *
      *    DB2 CURSORS
      *
           EXEC SQL DECLARE CSR_DMS_DEALERS CURSOR FOR
               SELECT DEALER_CODE
                    , DEALER_NAME
                    , ADDRESS_LINE1
                    , CITY
                    , STATE
                    , ZIP_CODE
                    , PHONE
               FROM   AUTOSALE.DEALER
               WHERE  ACTIVE_FLAG = 'Y'
               ORDER BY DEALER_CODE
           END-EXEC
      *
           EXEC SQL DECLARE CSR_DMS_INV CURSOR FOR
               SELECT VIN
                    , MAKE
                    , MODEL_DESC
                    , MODEL_YEAR
                    , TRIM_LEVEL
                    , EXT_COLOR
                    , INT_COLOR
                    , VEHICLE_STATUS
                    , DAYS(CURRENT DATE) - DAYS(ALLOCATION_DATE)
                    , INVOICE_PRICE
                    , MSRP
                    , DEALER_CODE
               FROM   AUTOSALE.VEHICLE
               WHERE  DEALER_CODE = :WS-HV-DLR-CODE
                 AND  VEHICLE_STATUS IN ('AV', 'HD', 'TR')
               ORDER BY VIN
           END-EXEC
      *
           EXEC SQL DECLARE CSR_DMS_DEALS CURSOR FOR
               SELECT S.DEAL_NUMBER
                    , S.DEALER_CODE
                    , S.CUSTOMER_ID
                    , C.LAST_NAME
                    , C.FIRST_NAME
                    , S.VIN
                    , S.DEAL_TYPE
                    , S.DEAL_STATUS
                    , S.TOTAL_PRICE
                    , S.TAX_AMOUNT
                    , S.DEAL_DATE
                    , S.DELIVERY_DATE
               FROM   AUTOSALE.SALES_DEAL S
               INNER JOIN AUTOSALE.CUSTOMER C
                 ON   S.CUSTOMER_ID = C.CUSTOMER_ID
               WHERE  S.DEALER_CODE = :WS-HV-DLR-CODE
                 AND  S.DEAL_DATE > :WS-LAST-SYNC-DATE
               ORDER BY S.DEAL_NUMBER
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATDMS00: DMS INTERFACE - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-DMSFILE-STATUS = '00'
               PERFORM 2500-WRITE-FILE-HEADER
               PERFORM 3000-PROCESS-DEALERS
               PERFORM 7800-WRITE-FILE-TRAILER
               PERFORM 8000-FINAL-CHECKPOINT
               PERFORM 8500-UPDATE-CONTROL-TABLE
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATDMS00: PROCESSING COMPLETE'
           DISPLAY 'BATDMS00:   INVENTORY RECORDS  = '
                   WS-INV-COUNT
           DISPLAY 'BATDMS00:   DEAL RECORDS       = '
                   WS-DEAL-COUNT
           DISPLAY 'BATDMS00:   TOTAL WRITTEN      = '
                   WS-TOTAL-WRITE
           DISPLAY 'BATDMS00:   ERRORS             = '
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
      *    GET LAST SYNC DATE FROM CONTROL TABLE
      *
           EXEC SQL
               SELECT LAST_RUN_DATE
               INTO   :WS-LAST-SYNC-DATE
               FROM   AUTOSALE.BATCH_CONTROL
               WHERE  PROGRAM_ID = :WS-MODULE-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE '1900-01-01' TO WS-LAST-SYNC-DATE
               DISPLAY 'BATDMS00: NO PRIOR SYNC - FULL EXTRACT'
           ELSE IF SQLCODE NOT = +0
               MOVE '1000-CTRL' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               MOVE '1900-01-01' TO WS-LAST-SYNC-DATE
           END-IF
      *
           DISPLAY 'BATDMS00: LAST SYNC = ' WS-LAST-SYNC-DATE
      *
      *    CHECK FOR RESTART
      *
           CALL 'COMCKPL0' USING WS-CHECKPOINT-CONTROL
                                 WS-RESTART-CONTROL
                                 WS-CHECKPOINT-AREA
      *
           IF WS-IS-RESTART
               DISPLAY 'BATDMS00: RESTARTING FROM KEY = '
                       WS-RESTART-KEY
               MOVE WS-CHKP-RECORDS-IN  TO WS-INV-COUNT
               MOVE WS-CHKP-RECORDS-OUT TO WS-DEAL-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT DMS-FILE
      *
           IF WS-DMSFILE-STATUS NOT = '00'
               DISPLAY 'BATDMS00: ERROR OPENING DMSFILE - '
                       WS-DMSFILE-STATUS
               MOVE 'OPEN-DMSFILE'
                   TO WS-LOG-MESSAGE
               CALL 'COMLGEL0' USING WS-MODULE-ID
                                     WS-LOG-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    2500-WRITE-FILE-HEADER                                    *
      ****************************************************************
       2500-WRITE-FILE-HEADER.
      *
           MOVE WS-TODAY-DATE TO WS-FH-FILE-DATE
           STRING WS-CURR-YYYY WS-CURR-MM WS-CURR-DD
               DELIMITED BY SIZE
               INTO WS-FH-FILE-TIME
      *
           WRITE DMS-RECORD FROM WS-DMS-FILE-HEADER
           ADD +1 TO WS-TOTAL-WRITE
           .
      *
      ****************************************************************
      *    3000-PROCESS-DEALERS                                      *
      ****************************************************************
       3000-PROCESS-DEALERS.
      *
           EXEC SQL OPEN CSR_DMS_DEALERS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDMS00: ERROR OPENING DEALER CURSOR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEALER
      *
           PERFORM UNTIL WS-DEALER-DONE
               EXEC SQL FETCH CSR_DMS_DEALERS
                   INTO :WS-HV-DLR-CODE
                      , :WS-HV-DLR-NAME
                      , :WS-HV-DLR-ADDRESS
                      , :WS-HV-DLR-CITY
                      , :WS-HV-DLR-STATE
                      , :WS-HV-DLR-ZIP
                      , :WS-HV-DLR-PHONE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 3500-WRITE-DEALER-HEADER
                       PERFORM 4000-PROCESS-INVENTORY
                       PERFORM 5000-PROCESS-DEALS
                   WHEN +100
                       SET WS-DEALER-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDMS00: DB2 ERROR DEALER - '
                               SQLCODE
                       SET WS-DEALER-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DMS_DEALERS END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-WRITE-DEALER-HEADER                                  *
      ****************************************************************
       3500-WRITE-DEALER-HEADER.
      *
           MOVE WS-HV-DLR-CODE    TO WS-DH-DEALER-CODE
           MOVE WS-HV-DLR-NAME    TO WS-DH-DEALER-NAME
           MOVE WS-HV-DLR-ADDRESS TO WS-DH-ADDRESS
           MOVE WS-HV-DLR-CITY    TO WS-DH-CITY
           MOVE WS-HV-DLR-STATE   TO WS-DH-STATE
           MOVE WS-HV-DLR-ZIP     TO WS-DH-ZIP
           MOVE WS-HV-DLR-PHONE   TO WS-DH-PHONE
      *
           WRITE DMS-RECORD FROM WS-DMS-DEALER-HDR
           ADD +1 TO WS-TOTAL-WRITE
           .
      *
      ****************************************************************
      *    4000-PROCESS-INVENTORY                                    *
      ****************************************************************
       4000-PROCESS-INVENTORY.
      *
           EXEC SQL OPEN CSR_DMS_INV END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDMS00: ERROR OPENING INV CURSOR - '
                       SQLCODE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-INV
      *
           PERFORM UNTIL WS-INV-DONE
               EXEC SQL FETCH CSR_DMS_INV
                   INTO :WS-HV-IV-VIN
                      , :WS-HV-IV-MAKE
                      , :WS-HV-IV-MODEL
                      , :WS-HV-IV-YEAR
                      , :WS-HV-IV-TRIM
                      , :WS-HV-IV-EXT-COLOR
                      , :WS-HV-IV-INT-COLOR
                      , :WS-HV-IV-STATUS
                      , :WS-HV-IV-DAYS-STOCK
                      , :WS-HV-IV-INVOICE
                      , :WS-HV-IV-MSRP
                      , :WS-HV-IV-DEALER
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 4500-WRITE-INV-DETAIL
                       PERFORM 7000-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-INV-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDMS00: DB2 ERROR INV - '
                               SQLCODE
                       SET WS-INV-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DMS_INV END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-WRITE-INV-DETAIL                                     *
      ****************************************************************
       4500-WRITE-INV-DETAIL.
      *
           INITIALIZE WS-DMS-INV-DETAIL
           MOVE 'IV'               TO WS-ID-REC-TYPE
           MOVE WS-HV-IV-VIN      TO WS-ID-VIN
           MOVE WS-HV-IV-MAKE     TO WS-ID-MAKE
           MOVE WS-HV-IV-MODEL    TO WS-ID-MODEL
           MOVE WS-HV-IV-YEAR     TO WS-ID-YEAR
           MOVE WS-HV-IV-TRIM     TO WS-ID-TRIM
           MOVE WS-HV-IV-EXT-COLOR TO WS-ID-EXT-COLOR
           MOVE WS-HV-IV-INT-COLOR TO WS-ID-INT-COLOR
           MOVE WS-HV-IV-STATUS   TO WS-ID-STOCK-STATUS
           MOVE WS-HV-IV-DAYS-STOCK TO WS-ID-DAYS-IN-STOCK
           MOVE WS-HV-IV-INVOICE  TO WS-ID-INVOICE
           MOVE WS-HV-IV-MSRP     TO WS-ID-MSRP
           MOVE WS-HV-IV-DEALER   TO WS-ID-DEALER-CODE
      *
           WRITE DMS-RECORD FROM WS-DMS-INV-DETAIL
      *
           IF WS-DMSFILE-STATUS = '00'
               ADD +1 TO WS-INV-COUNT
               ADD +1 TO WS-TOTAL-WRITE
           ELSE
               DISPLAY 'BATDMS00: INV WRITE ERROR - '
                       WS-DMSFILE-STATUS
               ADD +1 TO WS-ERROR-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    5000-PROCESS-DEALS                                        *
      ****************************************************************
       5000-PROCESS-DEALS.
      *
           EXEC SQL OPEN CSR_DMS_DEALS END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDMS00: ERROR OPENING DEAL CURSOR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DEAL
      *
           PERFORM UNTIL WS-DEALS-DONE
               EXEC SQL FETCH CSR_DMS_DEALS
                   INTO :WS-HV-DL-DEAL-NUM
                      , :WS-HV-DL-DEALER
                      , :WS-HV-DL-CUST-ID
                      , :WS-HV-DL-CUST-LAST
                      , :WS-HV-DL-CUST-FIRST
                      , :WS-HV-DL-VIN
                      , :WS-HV-DL-DEAL-TYPE
                      , :WS-HV-DL-DEAL-STATUS
                      , :WS-HV-DL-TOTAL-PRICE
                      , :WS-HV-DL-TAX
                      , :WS-HV-DL-DEAL-DATE
                      , :WS-HV-DL-DELIVERY-DATE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5500-WRITE-DEAL-DETAIL
                       PERFORM 7000-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-DEALS-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATDMS00: DB2 ERROR DEAL - '
                               SQLCODE
                       SET WS-DEALS-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DMS_DEALS END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5500-WRITE-DEAL-DETAIL                                    *
      ****************************************************************
       5500-WRITE-DEAL-DETAIL.
      *
           INITIALIZE WS-DMS-DEAL-DETAIL
           MOVE 'SD'               TO WS-DD-REC-TYPE
           MOVE WS-HV-DL-DEAL-NUM TO WS-DD-DEAL-NUMBER
           MOVE WS-HV-DL-DEALER   TO WS-DD-DEALER-CODE
           MOVE WS-HV-DL-CUST-ID  TO WS-DD-CUSTOMER-ID
      *
           INITIALIZE WS-CUST-FULL-NAME
           STRING WS-HV-DL-CUST-LAST DELIMITED BY '  '
                  ', ' DELIMITED BY SIZE
                  WS-HV-DL-CUST-FIRST DELIMITED BY '  '
                  INTO WS-CUST-FULL-NAME
           MOVE WS-CUST-FULL-NAME TO WS-DD-CUST-NAME
      *
           MOVE WS-HV-DL-VIN           TO WS-DD-VIN
           MOVE WS-HV-DL-DEAL-TYPE     TO WS-DD-DEAL-TYPE
           MOVE WS-HV-DL-DEAL-STATUS   TO WS-DD-DEAL-STATUS
           MOVE WS-HV-DL-TOTAL-PRICE   TO WS-DD-TOTAL-PRICE
           MOVE WS-HV-DL-TAX           TO WS-DD-TAX-AMOUNT
           MOVE WS-HV-DL-DEAL-DATE     TO WS-DD-DEAL-DATE
           MOVE WS-HV-DL-DELIVERY-DATE TO WS-DD-DELIVERY-DATE
      *
           WRITE DMS-RECORD FROM WS-DMS-DEAL-DETAIL
      *
           IF WS-DMSFILE-STATUS = '00'
               ADD +1 TO WS-DEAL-COUNT
               ADD +1 TO WS-TOTAL-WRITE
           ELSE
               DISPLAY 'BATDMS00: DEAL WRITE ERROR - '
                       WS-DMSFILE-STATUS
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
           MOVE WS-INV-COUNT     TO WS-CHKP-RECORDS-IN
           MOVE WS-DEAL-COUNT    TO WS-CHKP-RECORDS-OUT
           MOVE WS-ERROR-COUNT   TO WS-CHKP-RECORDS-ERR
           MOVE WS-HV-DLR-CODE  TO WS-CHKP-LAST-KEY
           MOVE WS-CURRENT-TIMESTAMP
                                 TO WS-CHKP-TIMESTAMP
      *
           EXEC SQL COMMIT END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDMS00: COMMIT FAILED - ' SQLCODE
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
           DISPLAY 'BATDMS00: CHECKPOINT #'
                   WS-CHECKPOINT-COUNT
                   ' AT RECORD ' WS-TOTAL-WRITE
           .
      *
      ****************************************************************
      *    7800-WRITE-FILE-TRAILER                                   *
      ****************************************************************
       7800-WRITE-FILE-TRAILER.
      *
           MOVE WS-INV-COUNT    TO WS-FT-INV-COUNT
           MOVE WS-DEAL-COUNT   TO WS-FT-DEAL-COUNT
           MOVE WS-TOTAL-WRITE  TO WS-FT-TOTAL-RECORDS
      *
           WRITE DMS-RECORD FROM WS-DMS-FILE-TRAILER
           ADD +1 TO WS-TOTAL-WRITE
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
      *    8500-UPDATE-CONTROL-TABLE                                 *
      ****************************************************************
       8500-UPDATE-CONTROL-TABLE.
      *
           EXEC SQL
               UPDATE AUTOSALE.BATCH_CONTROL
               SET    LAST_RUN_DATE     = :WS-TODAY-DATE
                    , RECORDS_PROCESSED = :WS-TOTAL-WRITE
               WHERE  PROGRAM_ID = :WS-MODULE-ID
           END-EXEC
      *
           IF SQLCODE = +100
               EXEC SQL
                   INSERT INTO AUTOSALE.BATCH_CONTROL
                   (  PROGRAM_ID
                    , LAST_RUN_DATE
                    , RECORDS_PROCESSED
                   )
                   VALUES
                   (  :WS-MODULE-ID
                    , :WS-TODAY-DATE
                    , :WS-TOTAL-WRITE
                   )
               END-EXEC
           END-IF
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATDMS00: CONTROL TABLE ERROR - '
                       SQLCODE
           END-IF
      *
           EXEC SQL COMMIT END-EXEC
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE DMS-FILE
      *
           IF WS-DMSFILE-STATUS NOT = '00'
               DISPLAY 'BATDMS00: ERROR CLOSING DMSFILE - '
                       WS-DMSFILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF BATDMS00                                              *
      ****************************************************************
