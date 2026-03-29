       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLIDLVR0.
      ****************************************************************
      * PROGRAM:  PLIDLVR0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - DELIVERY CONFIRMATION     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DEALER CONFIRMS RECEIPT OF VEHICLE FROM SHIPMENT.  *
      *           INPUT: VIN OR SHIPMENT ID, DAMAGE INSPECTION       *
      *           RESULTS, ODOMETER. UPDATES VEHICLE STATUS TO DL,   *
      *           RECEIVE_DATE, ODOMETER. IF ALL VEHICLES IN         *
      *           SHIPMENT DELIVERED: UPDATES SHIPMENT ACT_ARRIVAL,  *
      *           STATUS=DL. TRIGGERS STOCK UPDATE AND PDI SCHED.    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLDL - DELIVERY CONFIRMATION                       *
      * CALLS:    COMSTCK0 - STOCK UPDATE (RECV FUNCTION)            *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      *           COMVALD0 - VIN VALIDATION                          *
      * TABLES:   AUTOSALE.VEHICLE                                    *
      *           AUTOSALE.SHIPMENT                                  *
      *           AUTOSALE.SHIPMENT_VEHICLE                          *
      *           AUTOSALE.PDI_SCHEDULE                               *
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
                                          VALUE 'PLIDLVR0'.
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
      *    INPUT FIELDS - DELIVERY CONFIRMATION
      *
       01  WS-DLVR-INPUT.
           05  WS-DI-FUNCTION            PIC X(02).
               88  WS-DI-CONFIRM                    VALUE 'CF'.
               88  WS-DI-BY-SHIPMENT                VALUE 'SH'.
               88  WS-DI-INQUIRY                    VALUE 'IQ'.
           05  WS-DI-VIN                 PIC X(17).
           05  WS-DI-SHIPMENT-ID         PIC S9(09) COMP.
           05  WS-DI-DEALER-CODE         PIC X(05).
           05  WS-DI-ODOMETER            PIC 9(06).
           05  WS-DI-DAMAGE-FLAG         PIC X(01).
               88  WS-DI-NO-DAMAGE                  VALUE 'N'.
               88  WS-DI-HAS-DAMAGE                 VALUE 'Y'.
           05  WS-DI-DAMAGE-DESC         PIC X(80).
           05  WS-DI-INSPECTION-NOTE     PIC X(60).
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-DLVR-OUTPUT.
           05  WS-DO-STATUS-LINE.
               10  WS-DO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-DO-MSG-TEXT       PIC X(70).
           05  WS-DO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-DO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-DO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'DEALER: '.
               10  WS-DO-DEALER         PIC X(05).
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-DO-SHIP-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'SHIPMENT ID: '.
               10  WS-DO-SHIP-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-DO-STATUS         PIC X(02).
               10  FILLER               PIC X(43) VALUE SPACES.
           05  WS-DO-RECV-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'RECV DATE:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-DO-RECV-DATE      PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'ODOM: '.
               10  WS-DO-ODOMETER       PIC Z(05)9.
               10  FILLER               PIC X(42) VALUE SPACES.
           05  WS-DO-DAMAGE-LINE.
               10  FILLER               PIC X(08)
                   VALUE 'DAMAGE: '.
               10  WS-DO-DAMAGE-FLAG    PIC X(01).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  WS-DO-DAMAGE-DESC    PIC X(66).
           05  WS-DO-SHIP-STATUS.
               10  FILLER               PIC X(14)
                   VALUE 'SHIP COMPLETE:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-DO-DLV-COUNT      PIC Z(03)9.
               10  FILLER               PIC X(04) VALUE ' OF '.
               10  WS-DO-TOTAL-COUNT    PIC Z(03)9.
               10  FILLER               PIC X(11)
                   VALUE ' DELIVERED '.
               10  WS-DO-SHIP-COMPLETE  PIC X(03).
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-DO-PDI-LINE.
               10  FILLER               PIC X(15)
                   VALUE 'PDI SCHEDULED: '.
               10  WS-DO-PDI-DATE       PIC X(10).
               10  FILLER               PIC X(54) VALUE SPACES.
           05  WS-DO-FILLER             PIC X(1090) VALUE SPACES.
      *
      *    VIN VALIDATION CALL FIELDS
      *
       01  WS-VIN-VALID-INPUT            PIC X(17).
       01  WS-VIN-VALID-RC               PIC S9(04) COMP VALUE +0.
       01  WS-VIN-VALID-MSG              PIC X(50).
       01  WS-VIN-DECODED.
           05  WS-VD-WMI                 PIC X(03).
           05  WS-VD-VDS                 PIC X(05).
           05  WS-VD-CHECK-DIGIT         PIC X(01).
           05  WS-VD-VIS                 PIC X(08).
           05  WS-VD-YEAR-CODE           PIC X(01).
           05  WS-VD-PLANT-CODE          PIC X(01).
           05  WS-VD-SEQ-NUM             PIC X(06).
           05  WS-VD-MANUFACTURER        PIC X(30).
           05  WS-VD-MODEL-YEAR          PIC 9(04).
           05  WS-VD-ASSEMBLY            PIC X(30).
      *
      *    STOCK UPDATE CALL FIELDS
      *
       01  WS-STK-REQUEST.
           05  WS-SR-FUNCTION            PIC X(04).
           05  WS-SR-DEALER-CODE         PIC X(05).
           05  WS-SR-VIN                 PIC X(17).
           05  WS-SR-USER-ID             PIC X(08).
           05  WS-SR-REASON              PIC X(60).
       01  WS-STK-RESULT.
           05  WS-RS-RETURN-CODE         PIC S9(04) COMP.
           05  WS-RS-RETURN-MSG          PIC X(79).
           05  WS-RS-OLD-STATUS          PIC X(02).
           05  WS-RS-NEW-STATUS          PIC X(02).
           05  WS-RS-ON-HAND             PIC S9(04) COMP.
           05  WS-RS-IN-TRANSIT          PIC S9(04) COMP.
           05  WS-RS-ALLOCATED           PIC S9(04) COMP.
           05  WS-RS-ON-HOLD             PIC S9(04) COMP.
           05  WS-RS-SOLD-MTD            PIC S9(04) COMP.
           05  WS-RS-SOLD-YTD            PIC S9(04) COMP.
           05  WS-RS-SQLCODE             PIC S9(09) COMP.
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
           05  WS-PDI-SCHED-DATE        PIC X(10) VALUE SPACES.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-VEHICLE-STATUS        PIC X(02) VALUE SPACES.
           05  WS-VEHICLE-DEALER        PIC X(05) VALUE SPACES.
           05  WS-SHIP-STATUS           PIC X(02) VALUE SPACES.
           05  WS-DLV-VEH-COUNT         PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-VEH-COUNT       PIC S9(04) COMP VALUE +0.
           05  WS-ODOMETER-NUM          PIC S9(09) COMP VALUE +0.
           05  WS-PDI-ID-GEN            PIC S9(09) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-DAMAGE-DESC        PIC S9(04) COMP VALUE +0.
           05  WS-NI-INSPECT-NOTE       PIC S9(04) COMP VALUE +0.
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
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN WS-DI-CONFIRM
                       PERFORM 4000-CONFIRM-DELIVERY
                   WHEN WS-DI-BY-SHIPMENT
                       PERFORM 5000-CONFIRM-BY-SHIPMENT
                   WHEN WS-DI-INQUIRY
                       PERFORM 6000-INQUIRY-DELIVERY
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - USE CF, SH, OR IQ'
                           TO WS-DO-MSG-TEXT
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
           INITIALIZE WS-DLVR-OUTPUT
           MOVE 'PLIDLVR0' TO WS-DO-MSG-ID
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
                   TO WS-DO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-DI-FUNCTION
               MOVE WS-INP-BODY(1:17)   TO WS-DI-VIN
               MOVE WS-INP-BODY(18:4)   TO WS-DI-SHIPMENT-ID
               MOVE WS-INP-BODY(22:5)   TO WS-DI-DEALER-CODE
               MOVE WS-INP-BODY(27:6)   TO WS-DI-ODOMETER
               MOVE WS-INP-BODY(33:1)   TO WS-DI-DAMAGE-FLAG
               MOVE WS-INP-BODY(34:80)  TO WS-DI-DAMAGE-DESC
               MOVE WS-INP-BODY(114:60) TO WS-DI-INSPECTION-NOTE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK DELIVERY DATA                  *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-DI-CONFIRM
               IF WS-DI-VIN = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'VIN IS REQUIRED FOR DELIVERY CONFIRMATION'
                       TO WS-DO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
      *        VALIDATE VIN FORMAT
      *
               MOVE WS-DI-VIN TO WS-VIN-VALID-INPUT
               CALL 'COMVALD0' USING WS-VIN-VALID-INPUT
                                     WS-VIN-VALID-RC
                                     WS-VIN-VALID-MSG
                                     WS-VIN-DECODED
      *
               IF WS-VIN-VALID-RC NOT = +0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE WS-VIN-VALID-MSG TO WS-DO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-DI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-DO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-DI-DAMAGE-FLAG = SPACES
               MOVE 'N' TO WS-DI-DAMAGE-FLAG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CONFIRM-DELIVERY - SINGLE VIN DELIVERY                *
      ****************************************************************
       4000-CONFIRM-DELIVERY.
      *
      *    VERIFY VEHICLE EXISTS AND IS IN SHIPPED STATUS
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , DEALER_CODE
               INTO   :WS-VEHICLE-STATUS
                    , :WS-VEHICLE-DEALER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-DI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND'
                   TO WS-DO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-VEHICLE-STATUS NOT = 'SH'
           AND WS-VEHICLE-STATUS NOT = 'AL'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT DELIVER - STATUS IS '
                      WS-VEHICLE-STATUS
                      ' (MUST BE SH OR AL)'
                      DELIMITED BY SIZE
                      INTO WS-DO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    SET NULL INDICATORS
      *
           IF WS-DI-DAMAGE-DESC = SPACES
               MOVE -1 TO WS-NI-DAMAGE-DESC
           ELSE
               MOVE +0 TO WS-NI-DAMAGE-DESC
           END-IF
      *
           MOVE WS-DI-ODOMETER TO WS-ODOMETER-NUM
      *
      *    UPDATE VEHICLE RECORD
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = 'DL'
                    , RECEIVE_DATE   = :WS-FORMATTED-DATE
                    , ODOMETER       = :WS-ODOMETER-NUM
                    , DAMAGE_FLAG    = :WS-DI-DAMAGE-FLAG
                    , DAMAGE_DESC    = :WS-DI-DAMAGE-DESC
                                        :WS-NI-DAMAGE-DESC
                    , DEALER_CODE    = :WS-DI-DEALER-CODE
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :WS-DI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING VEHICLE FOR DELIVERY'
                   TO WS-DO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK IF ALL VEHICLES IN SHIPMENT ARE DELIVERED
      *
           PERFORM 4500-CHECK-SHIPMENT-COMPLETE
      *
      *    TRIGGER STOCK UPDATE VIA COMSTCK0
      *
           MOVE 'RECV'              TO WS-SR-FUNCTION
           MOVE WS-DI-DEALER-CODE   TO WS-SR-DEALER-CODE
           MOVE WS-DI-VIN           TO WS-SR-VIN
           MOVE IO-PCB-USER-ID      TO WS-SR-USER-ID
           MOVE 'VEHICLE DELIVERY CONFIRMED AT DEALER'
                                    TO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
      *    SCHEDULE PDI
      *
           PERFORM 4600-SCHEDULE-PDI
      *
      *    AUDIT LOG
      *
           MOVE 'PLIDLVR0'      TO WS-LR-PROGRAM
           MOVE 'DELIVER '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-DI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'DELIVERY CONFIRMED VIN ' WS-DI-VIN
                  ' AT DEALER ' WS-DI-DEALER-CODE
                  ' ODOM ' WS-DI-ODOMETER
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           IF WS-RETURN-CODE = +0
               MOVE 'DELIVERY CONFIRMED SUCCESSFULLY'
                   TO WS-DO-MSG-TEXT
           END-IF
           MOVE WS-DI-VIN            TO WS-DO-VIN
           MOVE WS-DI-DEALER-CODE    TO WS-DO-DEALER
           MOVE 'DL'                 TO WS-DO-STATUS
           MOVE WS-FORMATTED-DATE    TO WS-DO-RECV-DATE
           MOVE WS-DI-ODOMETER       TO WS-DO-ODOMETER
           MOVE WS-DI-DAMAGE-FLAG    TO WS-DO-DAMAGE-FLAG
           MOVE WS-DI-DAMAGE-DESC    TO WS-DO-DAMAGE-DESC
           MOVE WS-PDI-SCHED-DATE    TO WS-DO-PDI-DATE
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-CHECK-SHIPMENT-COMPLETE - ALL VEHICLES DELIVERED?     *
      ****************************************************************
       4500-CHECK-SHIPMENT-COMPLETE.
      *
      *    FIND SHIPMENT FOR THIS VEHICLE
      *
           EXEC SQL
               SELECT SV.SHIPMENT_ID
               INTO   :WS-DI-SHIPMENT-ID
               FROM   AUTOSALE.SHIPMENT_VEHICLE SV
               WHERE  SV.VIN = :WS-DI-VIN
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4500-EXIT
           END-IF
      *
      *    COUNT DELIVERED VS TOTAL
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-TOTAL-VEH-COUNT
               FROM   AUTOSALE.SHIPMENT_VEHICLE
               WHERE  SHIPMENT_ID = :WS-DI-SHIPMENT-ID
           END-EXEC
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-DLV-VEH-COUNT
               FROM   AUTOSALE.SHIPMENT_VEHICLE SV
               JOIN   AUTOSALE.VEHICLE V
                 ON   V.VIN = SV.VIN
               WHERE  SV.SHIPMENT_ID = :WS-DI-SHIPMENT-ID
                 AND  V.VEHICLE_STATUS = 'DL'
           END-EXEC
      *
           MOVE WS-DLV-VEH-COUNT    TO WS-DO-DLV-COUNT
           MOVE WS-TOTAL-VEH-COUNT  TO WS-DO-TOTAL-COUNT
           MOVE WS-DI-SHIPMENT-ID   TO WS-DO-SHIP-ID
      *
      *    IF ALL DELIVERED, UPDATE SHIPMENT
      *
           IF WS-DLV-VEH-COUNT = WS-TOTAL-VEH-COUNT
               EXEC SQL
                   UPDATE AUTOSALE.SHIPMENT
                      SET SHIPMENT_STATUS  = 'DL'
                        , ACT_ARRIVAL_DATE = :WS-FORMATTED-DATE
                        , UPDATED_TS       = CURRENT TIMESTAMP
                   WHERE  SHIPMENT_ID = :WS-DI-SHIPMENT-ID
               END-EXEC
      *
               MOVE 'YES' TO WS-DO-SHIP-COMPLETE
           ELSE
               MOVE 'NO ' TO WS-DO-SHIP-COMPLETE
           END-IF
           .
       4500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4600-SCHEDULE-PDI - CREATE PDI SCHEDULE FOR DELIVERED VEH  *
      ****************************************************************
       4600-SCHEDULE-PDI.
      *
      *    GENERATE PDI ID (SIMPLE MAX+1)
      *
           EXEC SQL
               SELECT COALESCE(MAX(PDI_ID), 0) + 1
               INTO   :WS-PDI-ID-GEN
               FROM   AUTOSALE.PDI_SCHEDULE
           END-EXEC
      *
      *    PDI SCHEDULED FOR 2 DAYS AFTER DELIVERY
      *
           MOVE WS-FORMATTED-DATE TO WS-PDI-SCHED-DATE
      *
           EXEC SQL
               INSERT INTO AUTOSALE.PDI_SCHEDULE
                    ( PDI_ID
                    , VIN
                    , DEALER_CODE
                    , SCHEDULED_DATE
                    , PDI_STATUS
                    , CHECKLIST_ITEMS
                    , ITEMS_PASSED
                    , ITEMS_FAILED
                    , COMPLETED_TS
                    )
               VALUES
                    ( :WS-PDI-ID-GEN
                    , :WS-DI-VIN
                    , :WS-DI-DEALER-CODE
                    , :WS-PDI-SCHED-DATE
                    , 'SC'
                    , 42
                    , 0
                    , 0
                    , NULL
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: PDI SCHEDULE INSERT FAILED'
                   TO WS-DO-MSG-TEXT
           ELSE
               MOVE WS-PDI-SCHED-DATE TO WS-DO-PDI-DATE
           END-IF
           .
      *
      ****************************************************************
      *    5000-CONFIRM-BY-SHIPMENT - DELIVER ALL IN SHIPMENT         *
      ****************************************************************
       5000-CONFIRM-BY-SHIPMENT.
      *
           IF WS-DI-SHIPMENT-ID = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT ID REQUIRED FOR BULK DELIVERY'
                   TO WS-DO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE ALL VEHICLES IN SHIPMENT TO DELIVERED
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE V
                  SET V.VEHICLE_STATUS = 'DL'
                    , V.RECEIVE_DATE   = :WS-FORMATTED-DATE
                    , V.ODOMETER       = :WS-DI-ODOMETER
                    , V.DEALER_CODE    = :WS-DI-DEALER-CODE
                    , V.UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  V.VIN IN
                   (SELECT SV.VIN
                    FROM   AUTOSALE.SHIPMENT_VEHICLE SV
                    WHERE  SV.SHIPMENT_ID = :WS-DI-SHIPMENT-ID)
                 AND  V.VEHICLE_STATUS IN ('SH', 'AL')
           END-EXEC
      *
           MOVE SQLERRD(3) TO WS-DLV-VEH-COUNT
      *
      *    UPDATE SHIPMENT STATUS
      *
           EXEC SQL
               UPDATE AUTOSALE.SHIPMENT
                  SET SHIPMENT_STATUS  = 'DL'
                    , ACT_ARRIVAL_DATE = :WS-FORMATTED-DATE
                    , UPDATED_TS       = CURRENT TIMESTAMP
               WHERE  SHIPMENT_ID = :WS-DI-SHIPMENT-ID
           END-EXEC
      *
      *    AUDIT LOG
      *
           MOVE 'PLIDLVR0'      TO WS-LR-PROGRAM
           MOVE 'BULKDLVR'      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'SHIPMENT'      TO WS-LR-ENTITY-TYPE
           MOVE WS-DI-SHIPMENT-ID TO WS-LR-ENTITY-KEY
           STRING 'BULK DELIVERY SHIPMENT '
                  WS-DI-SHIPMENT-ID
                  ' VEHICLES: '
                  WS-DLV-VEH-COUNT
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           MOVE 'SHIPMENT DELIVERY CONFIRMED'
               TO WS-DO-MSG-TEXT
           MOVE WS-DI-SHIPMENT-ID    TO WS-DO-SHIP-ID
           MOVE WS-DI-DEALER-CODE    TO WS-DO-DEALER
           MOVE 'DL'                 TO WS-DO-STATUS
           MOVE WS-FORMATTED-DATE    TO WS-DO-RECV-DATE
           MOVE WS-DLV-VEH-COUNT     TO WS-DO-DLV-COUNT
           MOVE WS-DLV-VEH-COUNT     TO WS-DO-TOTAL-COUNT
           MOVE 'YES'                TO WS-DO-SHIP-COMPLETE
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-INQUIRY-DELIVERY - SHOW DELIVERY STATUS               *
      ****************************************************************
       6000-INQUIRY-DELIVERY.
      *
           EXEC SQL
               SELECT V.VEHICLE_STATUS
                    , V.DEALER_CODE
                    , V.RECEIVE_DATE
                    , V.ODOMETER
                    , V.DAMAGE_FLAG
               INTO   :WS-VEHICLE-STATUS
                    , :WS-DO-DEALER
                    , :WS-DO-RECV-DATE
                    , :WS-ODOMETER-NUM
                    , :WS-DO-DAMAGE-FLAG
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VIN = :WS-DI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND'
                   TO WS-DO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-DI-VIN        TO WS-DO-VIN
           MOVE WS-VEHICLE-STATUS TO WS-DO-STATUS
           MOVE WS-ODOMETER-NUM  TO WS-DO-ODOMETER
           MOVE 'DELIVERY STATUS RETRIEVED'
               TO WS-DO-MSG-TEXT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-DLVR-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLIDLVR0' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLIDLVR0                                               *
      ****************************************************************
