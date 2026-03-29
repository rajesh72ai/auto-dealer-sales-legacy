       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLITRNS0.
      ****************************************************************
      * PROGRAM:  PLITRNS0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - TRANSIT STATUS UPDATE     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  RECEIVES CARRIER STATUS UPDATES (EDI 214 FEED).   *
      *           ONLINE ENTRY OR FROM EDI BATCH PROCESSING.         *
      *           LOOKS UP SHIPMENT AND VEHICLE, VALIDATES SEQUENCE. *
      *           INSERTS TRANSIT_STATUS RECORD WITH LOCATION/STATUS.*
      *           UPDATES SHIPMENT.SHIPMENT_STATUS. WHEN STATUS=DL  *
      *           (DELIVERED): TRIGGERS DELIVERY CONFIRMATION.       *
      *           HANDLES: DP=DEPARTED, AR=ARRIVED, TF=TRANSFERRED,  *
      *           DL=DELIVERED, DY=DELAYED.                          *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLTR - TRANSIT STATUS UPDATE                       *
      * CALLS:    COMEDIL0 - EDI FORMAT PARSER (IF EDI FORMAT)       *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.SHIPMENT                                  *
      *           AUTOSALE.TRANSIT_STATUS                             *
      *           AUTOSALE.VEHICLE                                    *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-3090.
       OBJECT-COMPUTER. IBM-3090.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       01  WS-PROGRAM-FIELDS.
           05  WS-PROGRAM-NAME           PIC X(08)
                                          VALUE 'PLITRNS0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-ABEND-CODE             PIC X(04)
                                          VALUE SPACES.
      *
      *    IMS FUNCTION CODES
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
           COPY WSMSGFMT.
      *
      *    INPUT FIELDS - TRANSIT STATUS
      *
       01  WS-TRNS-INPUT.
           05  WS-TI-FUNCTION            PIC X(02).
               88  WS-TI-ONLINE                     VALUE 'OL'.
               88  WS-TI-EDI-FEED                   VALUE 'ED'.
               88  WS-TI-INQUIRY                    VALUE 'IQ'.
           05  WS-TI-SHIPMENT-ID         PIC S9(09) COMP.
           05  WS-TI-VIN                 PIC X(17).
           05  WS-TI-STATUS-CODE         PIC X(02).
               88  WS-TI-DEPARTED                   VALUE 'DP'.
               88  WS-TI-ARRIVED                    VALUE 'AR'.
               88  WS-TI-TRANSFERRED                VALUE 'TF'.
               88  WS-TI-DELIVERED                  VALUE 'DL'.
               88  WS-TI-DELAYED                    VALUE 'DY'.
           05  WS-TI-LOCATION-CODE       PIC X(10).
           05  WS-TI-LOCATION-DESC       PIC X(40).
           05  WS-TI-STATUS-DATE         PIC X(10).
           05  WS-TI-STATUS-TIME         PIC X(08).
           05  WS-TI-CARRIER-REF         PIC X(20).
           05  WS-TI-NOTES               PIC X(60).
           05  WS-TI-EDI-RAW-DATA        PIC X(256).
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-TRNS-OUTPUT.
           05  WS-TO-STATUS-LINE.
               10  WS-TO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-TO-MSG-TEXT       PIC X(70).
           05  WS-TO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-TO-SHIP-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'SHIPMENT ID: '.
               10  WS-TO-SHIP-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-TO-VIN            PIC X(17).
               10  FILLER               PIC X(30) VALUE SPACES.
           05  WS-TO-STATUS-UPDATE.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-TO-OLD-STATUS     PIC X(02).
               10  FILLER               PIC X(04) VALUE ' -> '.
               10  WS-TO-NEW-STATUS     PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'DESC: '.
               10  WS-TO-STATUS-DESC    PIC X(20).
               10  FILLER               PIC X(33) VALUE SPACES.
           05  WS-TO-LOCATION-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'LOCATION: '.
               10  WS-TO-LOCATION       PIC X(10).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  WS-TO-LOC-DESC       PIC X(40).
               10  FILLER               PIC X(17) VALUE SPACES.
           05  WS-TO-DATE-LINE.
               10  FILLER               PIC X(06) VALUE 'DATE: '.
               10  WS-TO-STATUS-DATE    PIC X(10).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TIME: '.
               10  WS-TO-STATUS-TIME    PIC X(08).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'REF: '.
               10  WS-TO-CARRIER-REF    PIC X(20).
               10  FILLER               PIC X(18) VALUE SPACES.
           05  WS-TO-NOTES-LINE.
               10  FILLER               PIC X(07) VALUE 'NOTES: '.
               10  WS-TO-NOTES          PIC X(60).
               10  FILLER               PIC X(12) VALUE SPACES.
           05  WS-TO-SEQ-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'STATUS SEQ: '.
               10  WS-TO-SEQ-NUM        PIC Z(04)9.
               10  FILLER               PIC X(62) VALUE SPACES.
           05  WS-TO-FILLER             PIC X(1090) VALUE SPACES.
      *
      *    EDI PARSER CALL FIELDS
      *
       01  WS-EDI-REQUEST.
           05  WS-EDI-FUNCTION           PIC X(04).
           05  WS-EDI-RAW-DATA           PIC X(256).
       01  WS-EDI-RESULT.
           05  WS-EDI-RC                 PIC S9(04) COMP.
           05  WS-EDI-MSG                PIC X(50).
           05  WS-EDI-SHIPMENT-ID        PIC S9(09) COMP.
           05  WS-EDI-VIN                PIC X(17).
           05  WS-EDI-STATUS-CODE        PIC X(02).
           05  WS-EDI-LOCATION           PIC X(10).
           05  WS-EDI-LOC-DESC           PIC X(40).
           05  WS-EDI-DATE               PIC X(10).
           05  WS-EDI-TIME               PIC X(08).
           05  WS-EDI-CARRIER-REF        PIC X(20).
      *
      *    DB2 ERROR HANDLER CALL FIELDS
      *
       01  WS-DBE-REQUEST.
           05  WS-DBE-PROGRAM            PIC X(08).
           05  WS-DBE-PARAGRAPH          PIC X(30).
           05  WS-DBE-SQLCODE            PIC S9(09) COMP.
           05  WS-DBE-SQLERRM            PIC X(70).
       01  WS-DBE-RESULT.
           05  WS-DBE-RETURN-CODE        PIC S9(04) COMP.
           05  WS-DBE-RETURN-MSG         PIC X(79).
      *
      *    AUDIT LOG CALL FIELDS
      *
       01  WS-LOG-REQUEST.
           05  WS-LR-PROGRAM            PIC X(08).
           05  WS-LR-FUNCTION           PIC X(08).
           05  WS-LR-USER-ID            PIC X(08).
           05  WS-LR-ENTITY-TYPE        PIC X(08).
           05  WS-LR-ENTITY-KEY         PIC X(30).
           05  WS-LR-DESCRIPTION        PIC X(80).
           05  WS-LR-RETURN-CODE        PIC S9(04) COMP.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE.
               10  WS-CURR-YYYY         PIC 9(04).
               10  WS-CURR-MM           PIC 9(02).
               10  WS-CURR-DD           PIC 9(02).
           05  WS-CURRENT-TIME.
               10  WS-CURR-HH           PIC 9(02).
               10  WS-CURR-MN           PIC 9(02).
               10  WS-CURR-SS           PIC 9(02).
               10  WS-CURR-HS           PIC 9(02).
           05  WS-DIFF-FROM-GMT         PIC S9(04).
           05  WS-FORMATTED-DATE        PIC X(10) VALUE SPACES.
           05  WS-FORMATTED-TIME        PIC X(08) VALUE SPACES.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-SHIP-STATUS           PIC X(02) VALUE SPACES.
           05  WS-SHIP-DEST-DLR         PIC X(05) VALUE SPACES.
           05  WS-TRANSIT-SEQ           PIC S9(09) COMP VALUE +0.
           05  WS-MAX-SEQ               PIC S9(09) COMP VALUE +0.
           05  WS-LAST-STATUS           PIC X(02) VALUE SPACES.
           05  WS-DLV-VEH-COUNT         PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-VEH-COUNT       PIC S9(04) COMP VALUE +0.
           05  WS-STATUS-DESC-WORK      PIC X(20) VALUE SPACES.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-PCB-STATUS             PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-PCB-MOD-NAME           PIC X(08).
           05  IO-PCB-USER-ID            PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER                    PIC X(22).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN WS-TI-ONLINE
                       PERFORM 3000-VALIDATE-INPUT
                       IF WS-RETURN-CODE = +0
                           PERFORM 4000-PROCESS-STATUS-UPDATE
                       END-IF
                   WHEN WS-TI-EDI-FEED
                       PERFORM 3500-PARSE-EDI-INPUT
                       IF WS-RETURN-CODE = +0
                           PERFORM 4000-PROCESS-STATUS-UPDATE
                       END-IF
                   WHEN WS-TI-INQUIRY
                       PERFORM 6000-INQUIRY-TRANSIT
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - USE OL, ED, OR IQ'
                           TO WS-TO-MSG-TEXT
               END-EVALUATE
           END-IF
      *
           PERFORM 9000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE +0 TO WS-RETURN-CODE
           INITIALIZE WS-TRNS-OUTPUT
           MOVE 'PLITRNS0' TO WS-TO-MSG-ID
      *
           MOVE FUNCTION CURRENT-DATE TO
               WS-CURRENT-DATE
               WS-CURRENT-TIME
               WS-DIFF-FROM-GMT
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-DATE
      *
           STRING WS-CURR-HH ':'
                  WS-CURR-MN ':'
                  WS-CURR-SS
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-TIME
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT - GU CALL ON IO-PCB                    *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'IMS GU FAILED - UNABLE TO RECEIVE INPUT'
                   TO WS-TO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-TI-FUNCTION
               MOVE WS-INP-BODY(1:4)    TO WS-TI-SHIPMENT-ID
               MOVE WS-INP-BODY(5:17)   TO WS-TI-VIN
               MOVE WS-INP-BODY(22:2)   TO WS-TI-STATUS-CODE
               MOVE WS-INP-BODY(24:10)  TO WS-TI-LOCATION-CODE
               MOVE WS-INP-BODY(34:40)  TO WS-TI-LOCATION-DESC
               MOVE WS-INP-BODY(74:10)  TO WS-TI-STATUS-DATE
               MOVE WS-INP-BODY(84:8)   TO WS-TI-STATUS-TIME
               MOVE WS-INP-BODY(92:20)  TO WS-TI-CARRIER-REF
               MOVE WS-INP-BODY(112:60) TO WS-TI-NOTES
               MOVE WS-INP-BODY(172:256) TO WS-TI-EDI-RAW-DATA
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - VALIDATE ONLINE TRANSIT INPUT        *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-TI-SHIPMENT-ID = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT ID IS REQUIRED'
                   TO WS-TO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-TI-STATUS-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'STATUS CODE IS REQUIRED'
                   TO WS-TO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE STATUS CODE
      *
           IF NOT WS-TI-DEPARTED
           AND NOT WS-TI-ARRIVED
           AND NOT WS-TI-TRANSFERRED
           AND NOT WS-TI-DELIVERED
           AND NOT WS-TI-DELAYED
               MOVE +8 TO WS-RETURN-CODE
               STRING 'INVALID STATUS CODE: '
                      WS-TI-STATUS-CODE
                      ' (USE DP/AR/TF/DL/DY)'
                      DELIMITED BY SIZE
                      INTO WS-TO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    DEFAULT DATE AND TIME IF NOT PROVIDED
      *
           IF WS-TI-STATUS-DATE = SPACES
               MOVE WS-FORMATTED-DATE TO WS-TI-STATUS-DATE
           END-IF
      *
           IF WS-TI-STATUS-TIME = SPACES
               MOVE WS-FORMATTED-TIME TO WS-TI-STATUS-TIME
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-PARSE-EDI-INPUT - CALL COMEDIL0 FOR EDI 214           *
      ****************************************************************
       3500-PARSE-EDI-INPUT.
      *
           MOVE '214 '              TO WS-EDI-FUNCTION
           MOVE WS-TI-EDI-RAW-DATA TO WS-EDI-RAW-DATA
      *
           CALL 'COMEDIL0' USING WS-EDI-REQUEST
                                 WS-EDI-RESULT
      *
           IF WS-EDI-RC NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-EDI-MSG TO WS-TO-MSG-TEXT
               GO TO 3500-EXIT
           END-IF
      *
      *    MAP EDI PARSED FIELDS TO INPUT FIELDS
      *
           MOVE WS-EDI-SHIPMENT-ID  TO WS-TI-SHIPMENT-ID
           MOVE WS-EDI-VIN          TO WS-TI-VIN
           MOVE WS-EDI-STATUS-CODE  TO WS-TI-STATUS-CODE
           MOVE WS-EDI-LOCATION     TO WS-TI-LOCATION-CODE
           MOVE WS-EDI-LOC-DESC     TO WS-TI-LOCATION-DESC
           MOVE WS-EDI-DATE         TO WS-TI-STATUS-DATE
           MOVE WS-EDI-TIME         TO WS-TI-STATUS-TIME
           MOVE WS-EDI-CARRIER-REF  TO WS-TI-CARRIER-REF
      *
      *    VALIDATE PARSED DATA
      *
           PERFORM 3000-VALIDATE-INPUT
           .
       3500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PROCESS-STATUS-UPDATE - MAIN UPDATE LOGIC              *
      ****************************************************************
       4000-PROCESS-STATUS-UPDATE.
      *
      *    VERIFY SHIPMENT EXISTS
      *
           EXEC SQL
               SELECT SHIPMENT_STATUS
                    , DEST_DEALER
                    , VEHICLE_COUNT
               INTO   :WS-SHIP-STATUS
                    , :WS-SHIP-DEST-DLR
                    , :WS-TOTAL-VEH-COUNT
               FROM   AUTOSALE.SHIPMENT
               WHERE  SHIPMENT_ID = :WS-TI-SHIPMENT-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT NOT FOUND'
                   TO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING SHIPMENT'
                   TO WS-TO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 4000-EXIT
           END-IF
      *
      *    GET NEXT SEQUENCE NUMBER FOR THIS SHIPMENT
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO   :WS-TRANSIT-SEQ
               FROM   AUTOSALE.TRANSIT_STATUS
               WHERE  SHIPMENT_ID = :WS-TI-SHIPMENT-ID
           END-EXEC
      *
      *    GET LAST STATUS TO VALIDATE SEQUENCE
      *
           IF WS-TRANSIT-SEQ > 1
               EXEC SQL
                   SELECT STATUS_CODE
                   INTO   :WS-LAST-STATUS
                   FROM   AUTOSALE.TRANSIT_STATUS
                   WHERE  SHIPMENT_ID = :WS-TI-SHIPMENT-ID
                     AND  STATUS_SEQ  = :WS-TRANSIT-SEQ - 1
               END-EXEC
      *
      *        VALIDATE STATUS TRANSITION
      *
               IF WS-LAST-STATUS = 'DL'
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'SHIPMENT ALREADY DELIVERED - NO UPDATES'
                       TO WS-TO-MSG-TEXT
                   GO TO 4000-EXIT
               END-IF
           END-IF
      *
      *    RESOLVE STATUS DESCRIPTION
      *
           EVALUATE WS-TI-STATUS-CODE
               WHEN 'DP'
                   MOVE 'DEPARTED'    TO WS-STATUS-DESC-WORK
               WHEN 'AR'
                   MOVE 'ARRIVED'     TO WS-STATUS-DESC-WORK
               WHEN 'TF'
                   MOVE 'TRANSFERRED' TO WS-STATUS-DESC-WORK
               WHEN 'DL'
                   MOVE 'DELIVERED'   TO WS-STATUS-DESC-WORK
               WHEN 'DY'
                   MOVE 'DELAYED'     TO WS-STATUS-DESC-WORK
               WHEN OTHER
                   MOVE 'UNKNOWN'     TO WS-STATUS-DESC-WORK
           END-EVALUATE
      *
      *    INSERT TRANSIT_STATUS RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.TRANSIT_STATUS
                    ( SHIPMENT_ID
                    , STATUS_SEQ
                    , VIN
                    , STATUS_CODE
                    , STATUS_DESC
                    , LOCATION_CODE
                    , LOCATION_DESC
                    , STATUS_DATE
                    , STATUS_TIME
                    , CARRIER_REF
                    , NOTES
                    , STATUS_TS
                    )
               VALUES
                    ( :WS-TI-SHIPMENT-ID
                    , :WS-TRANSIT-SEQ
                    , :WS-TI-VIN
                    , :WS-TI-STATUS-CODE
                    , :WS-STATUS-DESC-WORK
                    , :WS-TI-LOCATION-CODE
                    , :WS-TI-LOCATION-DESC
                    , :WS-TI-STATUS-DATE
                    , :WS-TI-STATUS-TIME
                    , :WS-TI-CARRIER-REF
                    , :WS-TI-NOTES
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR INSERTING TRANSIT STATUS'
                   TO WS-TO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 4000-EXIT
           END-IF
      *
      *    UPDATE SHIPMENT STATUS
      *
           EXEC SQL
               UPDATE AUTOSALE.SHIPMENT
                  SET SHIPMENT_STATUS = :WS-TI-STATUS-CODE
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  SHIPMENT_ID = :WS-TI-SHIPMENT-ID
           END-EXEC
      *
      *    IF DELIVERED, TRIGGER DELIVERY WORKFLOW
      *
           IF WS-TI-DELIVERED
               PERFORM 5000-HANDLE-DELIVERY
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLITRNS0'      TO WS-LR-PROGRAM
           MOVE 'TRNSTAT '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'SHIPMENT'      TO WS-LR-ENTITY-TYPE
           MOVE WS-TI-SHIPMENT-ID TO WS-LR-ENTITY-KEY
           STRING 'TRANSIT STATUS ' WS-TI-STATUS-CODE
                  ' AT ' WS-TI-LOCATION-CODE
                  ' VIN ' WS-TI-VIN
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           MOVE 'TRANSIT STATUS UPDATED SUCCESSFULLY'
               TO WS-TO-MSG-TEXT
           MOVE WS-TI-SHIPMENT-ID    TO WS-TO-SHIP-ID
           MOVE WS-TI-VIN            TO WS-TO-VIN
           MOVE WS-SHIP-STATUS       TO WS-TO-OLD-STATUS
           MOVE WS-TI-STATUS-CODE    TO WS-TO-NEW-STATUS
           MOVE WS-STATUS-DESC-WORK  TO WS-TO-STATUS-DESC
           MOVE WS-TI-LOCATION-CODE  TO WS-TO-LOCATION
           MOVE WS-TI-LOCATION-DESC  TO WS-TO-LOC-DESC
           MOVE WS-TI-STATUS-DATE    TO WS-TO-STATUS-DATE
           MOVE WS-TI-STATUS-TIME    TO WS-TO-STATUS-TIME
           MOVE WS-TI-CARRIER-REF    TO WS-TO-CARRIER-REF
           MOVE WS-TI-NOTES          TO WS-TO-NOTES
           MOVE WS-TRANSIT-SEQ       TO WS-TO-SEQ-NUM
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-HANDLE-DB2-ERROR - CALL COMDBEL0                      *
      ****************************************************************
       4500-HANDLE-DB2-ERROR.
      *
           MOVE WS-PROGRAM-NAME   TO WS-DBE-PROGRAM
           MOVE 'TRANSIT-UPDATE'   TO WS-DBE-PARAGRAPH
           MOVE SQLCODE            TO WS-DBE-SQLCODE
           MOVE SQLERRMC           TO WS-DBE-SQLERRM
      *
           CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                 WS-DBE-RESULT
           .
      *
      ****************************************************************
      *    5000-HANDLE-DELIVERY - DELIVERED STATUS WORKFLOW            *
      ****************************************************************
       5000-HANDLE-DELIVERY.
      *
      *    UPDATE VEHICLE STATUS TO DL IF VIN PROVIDED
      *
           IF WS-TI-VIN NOT = SPACES
               EXEC SQL
                   UPDATE AUTOSALE.VEHICLE
                      SET VEHICLE_STATUS = 'DL'
                        , UPDATED_TS     = CURRENT TIMESTAMP
                   WHERE  VIN = :WS-TI-VIN
               END-EXEC
           END-IF
      *
      *    UPDATE SHIPMENT ARRIVAL DATE
      *
           EXEC SQL
               UPDATE AUTOSALE.SHIPMENT
                  SET ACT_ARRIVAL_DATE = :WS-TI-STATUS-DATE
                    , UPDATED_TS       = CURRENT TIMESTAMP
               WHERE  SHIPMENT_ID = :WS-TI-SHIPMENT-ID
           END-EXEC
      *
           MOVE 'DELIVERY CONFIRMED - VEHICLE DL STATUS SET'
               TO WS-TO-MSG-TEXT
           .
      *
      ****************************************************************
      *    6000-INQUIRY-TRANSIT - SHOW LATEST STATUS                  *
      ****************************************************************
       6000-INQUIRY-TRANSIT.
      *
           IF WS-TI-SHIPMENT-ID = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT ID REQUIRED FOR INQUIRY'
                   TO WS-TO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT T.STATUS_SEQ
                    , T.STATUS_CODE
                    , T.STATUS_DESC
                    , T.LOCATION_CODE
                    , T.STATUS_DATE
                    , T.STATUS_TIME
               INTO   :WS-TRANSIT-SEQ
                    , :WS-TO-NEW-STATUS
                    , :WS-STATUS-DESC-WORK
                    , :WS-TO-LOCATION
                    , :WS-TO-STATUS-DATE
                    , :WS-TO-STATUS-TIME
               FROM   AUTOSALE.TRANSIT_STATUS T
               WHERE  T.SHIPMENT_ID = :WS-TI-SHIPMENT-ID
               ORDER BY T.STATUS_SEQ DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO TRANSIT STATUS RECORDS FOUND'
                   TO WS-TO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-TI-SHIPMENT-ID    TO WS-TO-SHIP-ID
           MOVE WS-STATUS-DESC-WORK  TO WS-TO-STATUS-DESC
           MOVE WS-TRANSIT-SEQ       TO WS-TO-SEQ-NUM
           MOVE 'LATEST TRANSIT STATUS RETRIEVED'
               TO WS-TO-MSG-TEXT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-TRNS-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLITRNS0' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLITRNS0                                               *
      ****************************************************************
