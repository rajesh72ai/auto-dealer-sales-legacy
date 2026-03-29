       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATINB00.
      ****************************************************************
      * PROGRAM:    BATINB00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    INBOUND DATA FEED PROCESSING. READS VEHICLE      *
      *             ALLOCATION FEEDS FROM MANUFACTURER, VALIDATES    *
      *             AND TRANSFORMS RECORDS, INSERTS NEW VEHICLES     *
      *             INTO AUTOSALE.VEHICLE, AND UPDATES MODEL_MASTER  *
      *             FOR NEW MODELS. REJECTS WRITTEN TO REJFILE DD    *
      *             WITH REASON CODES.                               *
      *                                                              *
      * INPUT:      INFILE  DD - FIXED-LENGTH ALLOCATION RECORDS     *
      *                                                              *
      * TABLES:     AUTOSALE.VEHICLE         (INSERT)                *
      *             AUTOSALE.MODEL_MASTER    (READ/UPDATE)           *
      *             AUTOSALE.BATCH_CHECKPOINT(READ/UPDATE)           *
      *                                                              *
      * OUTPUT:     REJFILE DD - REJECTED RECORDS WITH REASON CODES  *
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
           SELECT INBOUND-FILE
               ASSIGN TO INFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-INFILE-STATUS.
      *
           SELECT REJECT-FILE
               ASSIGN TO REJFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-REJFILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  INBOUND-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 400 CHARACTERS.
       01  INBOUND-RECORD                PIC X(400).
      *
       FD  REJECT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 410 CHARACTERS.
       01  REJECT-RECORD                 PIC X(410).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                  PIC X(08) VALUE 'BATINB00'.
      *
       01  WS-INFILE-STATUS              PIC X(02) VALUE SPACES.
       01  WS-REJFILE-STATUS             PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    CHECKPOINT AREA
           COPY WSCKPT00.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-READ-COUNT             PIC S9(09) COMP-3 VALUE +0.
           05  WS-INSERT-COUNT           PIC S9(09) COMP-3 VALUE +0.
           05  WS-REJECT-COUNT           PIC S9(09) COMP-3 VALUE +0.
           05  WS-UPDATE-COUNT           PIC S9(09) COMP-3 VALUE +0.
           05  WS-CHECKPOINT-INTERVAL    PIC S9(07) COMP-3 VALUE +500.
      *
      *    EOF FLAG
      *
       01  WS-EOF-FLAG                   PIC X(01) VALUE 'N'.
           88  WS-END-OF-FILE                      VALUE 'Y'.
      *
      *    INBOUND RECORD LAYOUT
      *
       01  WS-INB-RECORD.
           05  WS-INB-REC-TYPE           PIC X(02).
               88  WS-INB-IS-VEHICLE               VALUE 'VH'.
               88  WS-INB-IS-ALLOC                 VALUE 'AL'.
           05  WS-INB-VIN                PIC X(17).
           05  WS-INB-MAKE               PIC X(10).
           05  WS-INB-MODEL-CODE         PIC X(10).
           05  WS-INB-MODEL-DESC         PIC X(30).
           05  WS-INB-MODEL-YEAR         PIC 9(04).
           05  WS-INB-TRIM               PIC X(15).
           05  WS-INB-EXT-COLOR          PIC X(15).
           05  WS-INB-INT-COLOR          PIC X(15).
           05  WS-INB-ENGINE             PIC X(10).
           05  WS-INB-TRANS              PIC X(10).
           05  WS-INB-INVOICE-AMT        PIC 9(07)V99.
           05  WS-INB-MSRP               PIC 9(07)V99.
           05  WS-INB-DEALER-CODE        PIC X(05).
           05  WS-INB-ALLOC-DATE         PIC X(10).
           05  WS-INB-ORDER-NUM          PIC X(12).
           05  WS-INB-OPTIONS            PIC X(100).
           05  FILLER                    PIC X(130).
      *
      *    REJECT RECORD LAYOUT
      *
       01  WS-REJ-RECORD.
           05  WS-REJ-DATA              PIC X(400).
           05  WS-REJ-REASON            PIC X(10).
      *
      *    VALIDATION FLAGS
      *
       01  WS-VALIDATION.
           05  WS-VALID-FLAG             PIC X(01) VALUE 'Y'.
               88  WS-RECORD-VALID                 VALUE 'Y'.
               88  WS-RECORD-INVALID               VALUE 'N'.
           05  WS-REJECT-REASON          PIC X(10) VALUE SPACES.
      *
      *    HOST VARIABLES
      *
       01  WS-HV-VEHICLE.
           05  WS-HV-VIN                PIC X(17).
           05  WS-HV-MAKE               PIC X(10).
           05  WS-HV-MODEL-CODE         PIC X(10).
           05  WS-HV-MODEL-DESC         PIC X(30).
           05  WS-HV-MODEL-YEAR         PIC X(04).
           05  WS-HV-TRIM               PIC X(15).
           05  WS-HV-EXT-COLOR          PIC X(15).
           05  WS-HV-INT-COLOR          PIC X(15).
           05  WS-HV-ENGINE             PIC X(10).
           05  WS-HV-TRANS              PIC X(10).
           05  WS-HV-INVOICE-AMT        PIC S9(07)V99 COMP-3.
           05  WS-HV-MSRP               PIC S9(07)V99 COMP-3.
           05  WS-HV-DEALER-CODE        PIC X(05).
           05  WS-HV-ALLOC-DATE         PIC X(10).
           05  WS-HV-STATUS             PIC X(02).
           05  WS-HV-ORDER-NUM          PIC X(12).
      *
       01  WS-HV-MODEL-EXISTS           PIC S9(09) COMP.
      *
      *    CURRENT DATE WORK FIELDS
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY              PIC 9(04).
           05  WS-CURR-MM                PIC 9(02).
           05  WS-CURR-DD                PIC 9(02).
           05  FILLER                    PIC X(13).
      *
       01  WS-CURRENT-TIMESTAMP          PIC X(26) VALUE SPACES.
      *
      *    DB2 ERROR FIELDS
      *
       01  WS-DB2-ERROR-INFO.
           05  WS-DB2-PROGRAM            PIC X(08) VALUE 'BATINB00'.
           05  WS-DB2-PARAGRAPH          PIC X(30) VALUE SPACES.
           05  WS-DB2-SQLCODE            PIC S9(09) COMP VALUE +0.
      *
      *    LOG MESSAGE AREA
      *
       01  WS-LOG-MESSAGE                PIC X(120) VALUE SPACES.
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATINB00: INBOUND FEED PROCESSING - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF  WS-INFILE-STATUS = '00'
           AND WS-REJFILE-STATUS = '00'
               PERFORM 3000-PROCESS-INBOUND
                   UNTIL WS-END-OF-FILE
               PERFORM 8000-FINAL-CHECKPOINT
           END-IF
      *
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATINB00: PROCESSING COMPLETE'
           DISPLAY 'BATINB00:   RECORDS READ     = '
                   WS-READ-COUNT
           DISPLAY 'BATINB00:   RECORDS INSERTED  = '
                   WS-INSERT-COUNT
           DISPLAY 'BATINB00:   RECORDS REJECTED  = '
                   WS-REJECT-COUNT
           DISPLAY 'BATINB00:   MODELS UPDATED    = '
                   WS-UPDATE-COUNT
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
                  INTO WS-CURRENT-TIMESTAMP
      *
           MOVE WS-MODULE-ID TO WS-CHKP-PROGRAM-ID
           MOVE +500 TO WS-CHECKPOINT-FREQ
      *
           INITIALIZE WS-COUNTERS
      *
           DISPLAY 'BATINB00: CHECKPOINT FREQ = '
                   WS-CHECKPOINT-INTERVAL
      *
      *    CHECK FOR RESTART
      *
           CALL 'COMCKPL0' USING WS-CHECKPOINT-CONTROL
                                 WS-RESTART-CONTROL
                                 WS-CHECKPOINT-AREA
      *
           IF WS-IS-RESTART
               DISPLAY 'BATINB00: RESTARTING FROM KEY = '
                       WS-RESTART-KEY
               MOVE WS-CHKP-RECORDS-IN  TO WS-READ-COUNT
               MOVE WS-CHKP-RECORDS-OUT TO WS-INSERT-COUNT
               MOVE WS-CHKP-RECORDS-ERR TO WS-REJECT-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN INPUT INBOUND-FILE
      *
           IF WS-INFILE-STATUS NOT = '00'
               DISPLAY 'BATINB00: ERROR OPENING INFILE - '
                       WS-INFILE-STATUS
               MOVE 'OPEN-INFILE'
                   TO WS-LOG-MESSAGE
               CALL 'COMLGEL0' USING WS-MODULE-ID
                                     WS-LOG-MESSAGE
           END-IF
      *
           OPEN OUTPUT REJECT-FILE
      *
           IF WS-REJFILE-STATUS NOT = '00'
               DISPLAY 'BATINB00: ERROR OPENING REJFILE - '
                       WS-REJFILE-STATUS
               MOVE 'OPEN-REJFILE'
                   TO WS-LOG-MESSAGE
               CALL 'COMLGEL0' USING WS-MODULE-ID
                                     WS-LOG-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-PROCESS-INBOUND - READ AND PROCESS EACH RECORD      *
      ****************************************************************
       3000-PROCESS-INBOUND.
      *
           READ INBOUND-FILE INTO WS-INB-RECORD
      *
           EVALUATE WS-INFILE-STATUS
               WHEN '00'
                   ADD +1 TO WS-READ-COUNT
                   PERFORM 4000-VALIDATE-RECORD
                   IF WS-RECORD-VALID
                       PERFORM 5000-INSERT-VEHICLE
                       PERFORM 5500-CHECK-MODEL-MASTER
                   ELSE
                       PERFORM 6000-WRITE-REJECT
                   END-IF
                   PERFORM 7000-CHECK-CHECKPOINT
               WHEN '10'
                   SET WS-END-OF-FILE TO TRUE
               WHEN OTHER
                   DISPLAY 'BATINB00: READ ERROR - '
                           WS-INFILE-STATUS
                   SET WS-END-OF-FILE TO TRUE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4000-VALIDATE-RECORD                                      *
      ****************************************************************
       4000-VALIDATE-RECORD.
      *
           MOVE 'Y' TO WS-VALID-FLAG
           MOVE SPACES TO WS-REJECT-REASON
      *
      *    CHECK RECORD TYPE
      *
           IF NOT WS-INB-IS-VEHICLE
           AND NOT WS-INB-IS-ALLOC
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'BAD-RECTYP' TO WS-REJECT-REASON
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK VIN IS PRESENT AND CORRECT LENGTH
      *
           IF WS-INB-VIN = SPACES
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'NO-VIN    ' TO WS-REJECT-REASON
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK MAKE IS PRESENT
      *
           IF WS-INB-MAKE = SPACES
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'NO-MAKE   ' TO WS-REJECT-REASON
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK MODEL YEAR IS VALID
      *
           IF WS-INB-MODEL-YEAR < 2000
           OR WS-INB-MODEL-YEAR > 2030
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'BAD-YEAR  ' TO WS-REJECT-REASON
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK DEALER CODE
      *
           IF WS-INB-DEALER-CODE = SPACES
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'NO-DEALER ' TO WS-REJECT-REASON
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK INVOICE AMOUNT
      *
           IF WS-INB-INVOICE-AMT NOT > 0
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'BAD-INVOIC' TO WS-REJECT-REASON
               GO TO 4000-EXIT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-INSERT-VEHICLE - INSERT INTO AUTOSALE.VEHICLE        *
      ****************************************************************
       5000-INSERT-VEHICLE.
      *
      *    CHECK FOR DUPLICATE VIN
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-HV-MODEL-EXISTS
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-INB-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '5000-DUP-CHK' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               GO TO 5000-EXIT
           END-IF
      *
           IF WS-HV-MODEL-EXISTS > 0
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'DUP-VIN   ' TO WS-REJECT-REASON
               PERFORM 6000-WRITE-REJECT
               GO TO 5000-EXIT
           END-IF
      *
      *    PREPARE HOST VARIABLES
      *
           MOVE WS-INB-VIN          TO WS-HV-VIN
           MOVE WS-INB-MAKE         TO WS-HV-MAKE
           MOVE WS-INB-MODEL-CODE   TO WS-HV-MODEL-CODE
           MOVE WS-INB-MODEL-DESC   TO WS-HV-MODEL-DESC
           MOVE WS-INB-MODEL-YEAR   TO WS-HV-MODEL-YEAR
           MOVE WS-INB-TRIM         TO WS-HV-TRIM
           MOVE WS-INB-EXT-COLOR    TO WS-HV-EXT-COLOR
           MOVE WS-INB-INT-COLOR    TO WS-HV-INT-COLOR
           MOVE WS-INB-ENGINE       TO WS-HV-ENGINE
           MOVE WS-INB-TRANS        TO WS-HV-TRANS
           MOVE WS-INB-INVOICE-AMT  TO WS-HV-INVOICE-AMT
           MOVE WS-INB-MSRP         TO WS-HV-MSRP
           MOVE WS-INB-DEALER-CODE  TO WS-HV-DEALER-CODE
           MOVE WS-INB-ALLOC-DATE   TO WS-HV-ALLOC-DATE
           MOVE 'AV'                TO WS-HV-STATUS
           MOVE WS-INB-ORDER-NUM    TO WS-HV-ORDER-NUM
      *
           EXEC SQL
               INSERT INTO AUTOSALE.VEHICLE
               (  VIN
                , MAKE
                , MODEL_CODE
                , MODEL_DESC
                , MODEL_YEAR
                , TRIM_LEVEL
                , EXT_COLOR
                , INT_COLOR
                , ENGINE_TYPE
                , TRANSMISSION
                , INVOICE_PRICE
                , MSRP
                , DEALER_CODE
                , ALLOCATION_DATE
                , VEHICLE_STATUS
                , ORDER_NUMBER
               )
               VALUES
               (  :WS-HV-VIN
                , :WS-HV-MAKE
                , :WS-HV-MODEL-CODE
                , :WS-HV-MODEL-DESC
                , :WS-HV-MODEL-YEAR
                , :WS-HV-TRIM
                , :WS-HV-EXT-COLOR
                , :WS-HV-INT-COLOR
                , :WS-HV-ENGINE
                , :WS-HV-TRANS
                , :WS-HV-INVOICE-AMT
                , :WS-HV-MSRP
                , :WS-HV-DEALER-CODE
                , :WS-HV-ALLOC-DATE
                , :WS-HV-STATUS
                , :WS-HV-ORDER-NUM
               )
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-INSERT-COUNT
           ELSE
               MOVE '5000-INSERT' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               MOVE 'N' TO WS-VALID-FLAG
               MOVE 'INS-FAILED' TO WS-REJECT-REASON
               PERFORM 6000-WRITE-REJECT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5500-CHECK-MODEL-MASTER - ADD NEW MODEL IF NOT EXISTS     *
      ****************************************************************
       5500-CHECK-MODEL-MASTER.
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-HV-MODEL-EXISTS
               FROM   AUTOSALE.MODEL_MASTER
               WHERE  MODEL_CODE = :WS-INB-MODEL-CODE
                 AND  MODEL_YEAR = :WS-INB-MODEL-YEAR
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '5500-MDLCHK' TO WS-DB2-PARAGRAPH
               MOVE SQLCODE TO WS-DB2-SQLCODE
               CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                     SQLCA
               GO TO 5500-EXIT
           END-IF
      *
           IF WS-HV-MODEL-EXISTS = 0
               EXEC SQL
                   INSERT INTO AUTOSALE.MODEL_MASTER
                   (  MODEL_CODE
                    , MODEL_YEAR
                    , MODEL_DESC
                    , MAKE
                    , INVOICE_BASE
                    , MSRP_BASE
                    , ACTIVE_FLAG
                   )
                   VALUES
                   (  :WS-INB-MODEL-CODE
                    , :WS-INB-MODEL-YEAR
                    , :WS-INB-MODEL-DESC
                    , :WS-INB-MAKE
                    , :WS-HV-INVOICE-AMT
                    , :WS-HV-MSRP
                    , 'Y'
                   )
               END-EXEC
      *
               IF SQLCODE = +0
                   ADD +1 TO WS-UPDATE-COUNT
                   DISPLAY 'BATINB00: NEW MODEL ADDED - '
                           WS-INB-MODEL-CODE ' '
                           WS-INB-MODEL-YEAR
               ELSE
                   MOVE '5500-MDLINS' TO WS-DB2-PARAGRAPH
                   MOVE SQLCODE TO WS-DB2-SQLCODE
                   CALL 'COMDBEL0' USING WS-DB2-ERROR-INFO
                                         SQLCA
               END-IF
           END-IF
           .
       5500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-WRITE-REJECT - WRITE REJECTED RECORD                 *
      ****************************************************************
       6000-WRITE-REJECT.
      *
           MOVE WS-INB-RECORD    TO WS-REJ-DATA
           MOVE WS-REJECT-REASON TO WS-REJ-REASON
      *
           WRITE REJECT-RECORD FROM WS-REJ-RECORD
      *
           IF WS-REJFILE-STATUS = '00'
               ADD +1 TO WS-REJECT-COUNT
           ELSE
               DISPLAY 'BATINB00: REJECT WRITE ERROR - '
                       WS-REJFILE-STATUS
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
           MOVE WS-READ-COUNT    TO WS-CHKP-RECORDS-IN
           MOVE WS-INSERT-COUNT  TO WS-CHKP-RECORDS-OUT
           MOVE WS-REJECT-COUNT  TO WS-CHKP-RECORDS-ERR
           MOVE WS-INB-VIN       TO WS-CHKP-LAST-KEY
           MOVE WS-CURRENT-TIMESTAMP
                                 TO WS-CHKP-TIMESTAMP
      *
           EXEC SQL COMMIT END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATINB00: COMMIT FAILED - ' SQLCODE
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
           DISPLAY 'BATINB00: CHECKPOINT #'
                   WS-CHECKPOINT-COUNT
                   ' AT RECORD ' WS-READ-COUNT
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
           CLOSE INBOUND-FILE
      *
           IF WS-INFILE-STATUS NOT = '00'
               DISPLAY 'BATINB00: ERROR CLOSING INFILE - '
                       WS-INFILE-STATUS
           END-IF
      *
           CLOSE REJECT-FILE
      *
           IF WS-REJFILE-STATUS NOT = '00'
               DISPLAY 'BATINB00: ERROR CLOSING REJFILE - '
                       WS-REJFILE-STATUS
           END-IF
           .
      ****************************************************************
      * END OF BATINB00                                              *
      ****************************************************************
