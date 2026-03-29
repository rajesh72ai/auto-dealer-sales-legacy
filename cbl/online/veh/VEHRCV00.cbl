       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHRCV00.
      ****************************************************************
      * PROGRAM:  VEHRCV00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - VEHICLE RECEIVING / CHECK-IN             *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DEALER RECEIVES VEHICLE AT DOCK. SCAN VIN,        *
      *           INSPECT VEHICLE, CAPTURE STOCK NUMBER (AUTO OR     *
      *           MANUAL), LOT LOCATION, ODOMETER, DAMAGE INFO,     *
      *           KEY NUMBER. VALIDATES VIN AND VERIFIES VEHICLE     *
      *           IS EXPECTED AT THIS DEALER. UPDATES STATUS TO      *
      *           DL (DELIVERED) THEN AV (AVAILABLE). TRIGGERS       *
      *           PDI SCHEDULING VIA INSERT INTO PDI_SCHEDULE.       *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHRC - VEHICLE RECEIVING                           *
      * CALLS:    COMVALD0 - VIN VALIDATION                          *
      *           COMVINL0 - VIN DECODE/LOOKUP                       *
      *           COMSTCK0 - STOCK UPDATE (RECV FUNCTION)            *
      *           COMSEQL0 - SEQUENCE NUMBER GENERATION              *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.VEHICLE                                   *
      *           AUTOSALE.PDI_SCHEDULE                               *
      *           AUTOSALE.VEHICLE_STATUS_HIST                       *
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
                                          VALUE 'VEHRCV00'.
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
      *    COPY IN SQLCA AND COMMON FIELDS
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
           COPY WSMSGFMT.
      *
      *    COPY IN DCLGEN LAYOUTS
      *
           COPY DCLVEHCL.
      *
           COPY DCLVHSTH.
      *
           COPY DCLPDISH.
      *
      *    INPUT FIELDS - RECEIVING DATA
      *
       01  WS-RECV-INPUT.
           05  WS-RI-FUNCTION            PIC X(02).
               88  WS-RI-RECEIVE                    VALUE 'RC'.
               88  WS-RI-INQUIRY                    VALUE 'IQ'.
           05  WS-RI-VIN                 PIC X(17).
           05  WS-RI-DEALER-CODE         PIC X(05).
           05  WS-RI-STOCK-NUM           PIC X(08).
           05  WS-RI-STOCK-MODE          PIC X(01).
               88  WS-RI-AUTO-STOCK                 VALUE 'A'.
               88  WS-RI-MANUAL-STOCK               VALUE 'M'.
           05  WS-RI-LOT-LOCATION        PIC X(06).
           05  WS-RI-ODOMETER            PIC 9(06).
           05  WS-RI-DAMAGE-FLAG         PIC X(01).
               88  WS-RI-NO-DAMAGE                  VALUE 'N'.
               88  WS-RI-HAS-DAMAGE                 VALUE 'Y'.
           05  WS-RI-DAMAGE-DESC         PIC X(80).
           05  WS-RI-KEY-NUMBER          PIC X(06).
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-RECV-OUTPUT.
           05  WS-RO-STATUS-LINE.
               10  WS-RO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-MSG-TEXT       PIC X(70).
           05  WS-RO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-RO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-RO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'STOCK NO: '.
               10  WS-RO-STOCK-NUM      PIC X(08).
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-RO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-RO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-RO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-RO-MODEL          PIC X(06).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'COLOR: '.
               10  WS-RO-COLOR          PIC X(03).
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-RO-RECV-LINE.
               10  FILLER               PIC X(08) VALUE 'DEALER: '.
               10  WS-RO-DEALER         PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'LOT: '.
               10  WS-RO-LOT            PIC X(06).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'ODOM: '.
               10  WS-RO-ODOMETER       PIC Z(05)9.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-RO-STATUS-LINE-2.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-RO-STATUS         PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'KEY: '.
               10  WS-RO-KEY-NUMBER     PIC X(06).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'DAMAGE: '.
               10  WS-RO-DAMAGE-FLAG    PIC X(01).
               10  FILLER               PIC X(41) VALUE SPACES.
           05  WS-RO-DAMAGE-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'DAMAGE DESC:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-DAMAGE-DESC    PIC X(66).
           05  WS-RO-PDI-LINE.
               10  FILLER               PIC X(15)
                   VALUE 'PDI SCHEDULED: '.
               10  WS-RO-PDI-DATE       PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'PDI ID:  '.
               10  WS-RO-PDI-ID         PIC Z(08)9.
               10  FILLER               PIC X(32) VALUE SPACES.
           05  WS-RO-FILLER             PIC X(1248) VALUE SPACES.
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
      *    VIN LOOKUP CALL FIELDS
      *
       01  WS-VINL-REQUEST.
           05  WS-VINL-FUNCTION          PIC X(04).
           05  WS-VINL-VIN               PIC X(17).
       01  WS-VINL-RESULT.
           05  WS-VINL-RC                PIC S9(04) COMP.
           05  WS-VINL-MSG               PIC X(50).
           05  WS-VINL-MAKE-NAME         PIC X(20).
           05  WS-VINL-MODEL-NAME        PIC X(30).
           05  WS-VINL-YEAR              PIC 9(04).
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
      *    SEQUENCE NUMBER CALL FIELDS
      *
       01  WS-SEQ-REQUEST.
           05  WS-SEQ-TABLE-NAME         PIC X(18).
           05  WS-SEQ-COLUMN-NAME        PIC X(18).
       01  WS-SEQ-RESULT.
           05  WS-SEQ-NEXT-VALUE         PIC S9(09) COMP.
           05  WS-SEQ-RC                 PIC S9(04) COMP.
           05  WS-SEQ-MSG                PIC X(50).
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
           05  WS-GENERATED-STOCK       PIC X(08) VALUE SPACES.
           05  WS-PDI-ID-GEN            PIC S9(09) COMP VALUE +0.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-ODOMETER-NUM          PIC S9(09) COMP VALUE +0.
           05  WS-HIST-SEQ              PIC S9(09) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-DAMAGE-DESC        PIC S9(04) COMP VALUE +0.
           05  WS-NI-LOT-LOCATION       PIC S9(04) COMP VALUE +0.
           05  WS-NI-KEY-NUMBER         PIC S9(04) COMP VALUE +0.
           05  WS-NI-TECH-ID            PIC S9(04) COMP VALUE -1.
           05  WS-NI-NOTES              PIC S9(04) COMP VALUE -1.
           05  WS-NI-COMPLETED          PIC S9(04) COMP VALUE -1.
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
               PERFORM 4000-LOOKUP-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-PROCESS-RECEIVING
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-SCHEDULE-PDI
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-UPDATE-STOCK
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
           INITIALIZE WS-RECV-OUTPUT
           MOVE 'VEHRCV00' TO WS-RO-MSG-ID
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
                   TO WS-RO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION    TO WS-RI-FUNCTION
               MOVE WS-INP-BODY(1:17)  TO WS-RI-VIN
               MOVE WS-INP-BODY(18:5)  TO WS-RI-DEALER-CODE
               MOVE WS-INP-BODY(23:8)  TO WS-RI-STOCK-NUM
               MOVE WS-INP-BODY(31:1)  TO WS-RI-STOCK-MODE
               MOVE WS-INP-BODY(32:6)  TO WS-RI-LOT-LOCATION
               MOVE WS-INP-BODY(38:6)  TO WS-RI-ODOMETER
               MOVE WS-INP-BODY(44:1)  TO WS-RI-DAMAGE-FLAG
               MOVE WS-INP-BODY(45:80) TO WS-RI-DAMAGE-DESC
               MOVE WS-INP-BODY(125:6) TO WS-RI-KEY-NUMBER
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - VALIDATE VIN AND RECEIVING DATA     *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-RI-VIN = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN IS REQUIRED FOR RECEIVING'
                   TO WS-RO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE VIN FORMAT
      *
           MOVE WS-RI-VIN TO WS-VIN-VALID-INPUT
           CALL 'COMVALD0' USING WS-VIN-VALID-INPUT
                                 WS-VIN-VALID-RC
                                 WS-VIN-VALID-MSG
                                 WS-VIN-DECODED
      *
           IF WS-VIN-VALID-RC NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-VIN-VALID-MSG TO WS-RO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    CALL COMVINL0 TO DECODE VIN DETAILS
      *
           MOVE 'LOOK'        TO WS-VINL-FUNCTION
           MOVE WS-RI-VIN     TO WS-VINL-VIN
           CALL 'COMVINL0' USING WS-VINL-REQUEST
                                 WS-VINL-RESULT
      *
      *    VALIDATE DEALER CODE
      *
           IF WS-RI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED FOR RECEIVING'
                   TO WS-RO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE DAMAGE FLAG
      *
           IF WS-RI-DAMAGE-FLAG NOT = 'Y'
           AND WS-RI-DAMAGE-FLAG NOT = 'N'
           AND WS-RI-DAMAGE-FLAG NOT = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DAMAGE FLAG MUST BE Y OR N'
                   TO WS-RO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-RI-DAMAGE-FLAG = SPACES
               MOVE 'N' TO WS-RI-DAMAGE-FLAG
           END-IF
      *
      *    VALIDATE ODOMETER
      *
           IF WS-RI-ODOMETER IS NOT NUMERIC
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ODOMETER MUST BE NUMERIC'
                   TO WS-RO-MSG-TEXT
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-VEHICLE - VERIFY VEHICLE EXISTS IN DB2        *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , EXTERIOR_COLOR
                    , VEHICLE_STATUS
                    , DEALER_CODE
                    , STOCK_NUMBER
               INTO  :VIN            OF DCLVEHICLE
                    , :MODEL-YEAR    OF DCLVEHICLE
                    , :MAKE-CODE     OF DCLVEHICLE
                    , :MODEL-CODE    OF DCLVEHICLE
                    , :EXTERIOR-COLOR
                    , :VEHICLE-STATUS
                    , :DEALER-CODE   OF DCLVEHICLE
                    , :STOCK-NUMBER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-RI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND IN SYSTEM - CHECK VIN'
                   TO WS-RO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING VEHICLE TABLE'
                   TO WS-RO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY VEHICLE IS EXPECTED AT THIS DEALER
      *
           IF DEALER-CODE OF DCLVEHICLE NOT = SPACES
           AND DEALER-CODE OF DCLVEHICLE NOT = WS-RI-DEALER-CODE
               MOVE +4 TO WS-RETURN-CODE
               STRING 'WARNING: VEHICLE ASSIGNED TO DEALER '
                      DEALER-CODE OF DCLVEHICLE
                      ' NOT '
                      WS-RI-DEALER-CODE
                      DELIMITED BY SIZE
                      INTO WS-RO-MSG-TEXT
           END-IF
      *
      *    VERIFY STATUS ALLOWS RECEIVING (AL=ALLOCATED OR IT=TRANSIT)
      *
           IF VEHICLE-STATUS NOT = 'AL'
           AND VEHICLE-STATUS NOT = 'IT'
           AND VEHICLE-STATUS NOT = 'PR'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT RECEIVE - CURRENT STATUS IS '
                      VEHICLE-STATUS
                      DELIMITED BY SIZE
                      INTO WS-RO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-RECEIVING - UPDATE VEHICLE RECORD             *
      ****************************************************************
       5000-PROCESS-RECEIVING.
      *
      *    AUTO-GENERATE STOCK NUMBER IF REQUESTED
      *
           IF WS-RI-STOCK-MODE = 'A' OR WS-RI-STOCK-NUM = SPACES
               MOVE 'STOCK_NUMBER'  TO WS-SEQ-TABLE-NAME
               MOVE 'VEHICLE     '  TO WS-SEQ-COLUMN-NAME
               CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                     WS-SEQ-RESULT
      *
               IF WS-SEQ-RC NOT = +0
                   MOVE +12 TO WS-RETURN-CODE
                   MOVE 'ERROR GENERATING STOCK NUMBER'
                       TO WS-RO-MSG-TEXT
                   GO TO 5000-EXIT
               END-IF
      *
               MOVE WS-SEQ-NEXT-VALUE TO WS-GENERATED-STOCK
               MOVE WS-GENERATED-STOCK TO WS-RI-STOCK-NUM
           END-IF
      *
      *    SET ODOMETER VALUE
      *
           MOVE WS-RI-ODOMETER TO WS-ODOMETER-NUM
      *
      *    SET NULL INDICATORS
      *
           IF WS-RI-DAMAGE-DESC = SPACES
               MOVE -1 TO WS-NI-DAMAGE-DESC
           ELSE
               MOVE +0 TO WS-NI-DAMAGE-DESC
           END-IF
      *
           IF WS-RI-LOT-LOCATION = SPACES
               MOVE -1 TO WS-NI-LOT-LOCATION
           ELSE
               MOVE +0 TO WS-NI-LOT-LOCATION
           END-IF
      *
           IF WS-RI-KEY-NUMBER = SPACES
               MOVE -1 TO WS-NI-KEY-NUMBER
           ELSE
               MOVE +0 TO WS-NI-KEY-NUMBER
           END-IF
      *
      *    UPDATE VEHICLE RECORD WITH RECEIVING DATA
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = 'AV'
                    , DEALER_CODE    = :WS-RI-DEALER-CODE
                    , LOT_LOCATION   = :WS-RI-LOT-LOCATION
                                        :WS-NI-LOT-LOCATION
                    , STOCK_NUMBER   = :WS-RI-STOCK-NUM
                    , RECEIVE_DATE   = :WS-FORMATTED-DATE
                    , ODOMETER       = :WS-ODOMETER-NUM
                    , KEY_NUMBER     = :WS-RI-KEY-NUMBER
                                        :WS-NI-KEY-NUMBER
                    , DAMAGE_FLAG    = :WS-RI-DAMAGE-FLAG
                    , DAMAGE_DESC    = :WS-RI-DAMAGE-DESC
                                        :WS-NI-DAMAGE-DESC
                    , DAYS_IN_STOCK  = 0
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :WS-RI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING VEHICLE FOR RECEIVE'
                   TO WS-RO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    INSERT STATUS HISTORY RECORD
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO   :WS-HIST-SEQ
               FROM   AUTOSALE.VEHICLE_STATUS_HIST
               WHERE  VIN = :WS-RI-VIN
           END-EXEC
      *
           EXEC SQL
               INSERT INTO AUTOSALE.VEHICLE_STATUS_HIST
                    ( VIN, STATUS_SEQ, OLD_STATUS, NEW_STATUS,
                      CHANGED_BY, CHANGE_REASON, CHANGED_TS )
               VALUES
                    ( :WS-RI-VIN
                    , :WS-HIST-SEQ
                    , :VEHICLE-STATUS
                    , 'AV'
                    , :IO-PCB-USER-ID
                    , 'VEHICLE RECEIVED AT DEALER DOCK'
                    , CURRENT TIMESTAMP )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: STATUS HISTORY INSERT FAILED'
                   TO WS-RO-MSG-TEXT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-SCHEDULE-PDI - INSERT PDI SCHEDULE RECORD            *
      ****************************************************************
       6000-SCHEDULE-PDI.
      *
      *    GENERATE PDI ID
      *
           MOVE 'PDI_ID      '   TO WS-SEQ-TABLE-NAME
           MOVE 'PDI_SCHEDULE'   TO WS-SEQ-COLUMN-NAME
           CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                 WS-SEQ-RESULT
      *
           IF WS-SEQ-RC NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: COULD NOT GENERATE PDI ID'
                   TO WS-RO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-SEQ-NEXT-VALUE TO WS-PDI-ID-GEN
      *
      *    CALCULATE PDI SCHEDULE DATE (NEXT BUSINESS DAY + 1)
      *    SIMPLIFIED: ADD 2 DAYS TO RECEIVE DATE
      *
           MOVE WS-FORMATTED-DATE TO WS-PDI-SCHED-DATE
      *
           EXEC SQL
               INSERT INTO AUTOSALE.PDI_SCHEDULE
                    ( PDI_ID
                    , VIN
                    , DEALER_CODE
                    , SCHEDULED_DATE
                    , TECHNICIAN_ID
                    , PDI_STATUS
                    , CHECKLIST_ITEMS
                    , ITEMS_PASSED
                    , ITEMS_FAILED
                    , NOTES
                    , COMPLETED_TS
                    )
               VALUES
                    ( :WS-PDI-ID-GEN
                    , :WS-RI-VIN
                    , :WS-RI-DEALER-CODE
                    , :WS-PDI-SCHED-DATE
                    , NULL
                    , 'SC'
                    , 42
                    , 0
                    , 0
                    , NULL
                    , NULL
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: PDI SCHEDULE INSERT FAILED'
                   TO WS-RO-MSG-TEXT
           ELSE
               MOVE WS-PDI-SCHED-DATE TO WS-RO-PDI-DATE
               MOVE WS-PDI-ID-GEN     TO WS-RO-PDI-ID
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-UPDATE-STOCK - CALL COMSTCK0 WITH RECV FUNCTION      *
      ****************************************************************
       7000-UPDATE-STOCK.
      *
           MOVE 'RECV'              TO WS-SR-FUNCTION
           MOVE WS-RI-DEALER-CODE   TO WS-SR-DEALER-CODE
           MOVE WS-RI-VIN           TO WS-SR-VIN
           MOVE IO-PCB-USER-ID      TO WS-SR-USER-ID
           MOVE 'VEHICLE RECEIVED AT DEALER DOCK'
                                    TO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           IF WS-RS-RETURN-CODE > +4
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: STOCK UPDATE MAY HAVE FAILED'
                   TO WS-RO-MSG-TEXT
           END-IF
      *
      *    WRITE AUDIT LOG
      *
           MOVE 'VEHRCV00'      TO WS-LR-PROGRAM
           MOVE 'RECEIVE '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-RI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'VIN ' WS-RI-VIN
                  ' RECEIVED AT DEALER ' WS-RI-DEALER-CODE
                  ' STOCK#' WS-RI-STOCK-NUM
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT SUCCESS OUTPUT
      *
           IF WS-RETURN-CODE = +0
               MOVE 'VEHICLE RECEIVED SUCCESSFULLY - PDI SCHEDULED'
                   TO WS-RO-MSG-TEXT
           END-IF
      *
           MOVE WS-RI-VIN           TO WS-RO-VIN
           MOVE WS-RI-STOCK-NUM     TO WS-RO-STOCK-NUM
           MOVE MODEL-YEAR OF DCLVEHICLE TO WS-RO-YEAR
           MOVE MAKE-CODE OF DCLVEHICLE  TO WS-RO-MAKE
           MOVE MODEL-CODE OF DCLVEHICLE TO WS-RO-MODEL
           MOVE EXTERIOR-COLOR       TO WS-RO-COLOR
           MOVE WS-RI-DEALER-CODE    TO WS-RO-DEALER
           MOVE WS-RI-LOT-LOCATION   TO WS-RO-LOT
           MOVE WS-RI-ODOMETER       TO WS-RO-ODOMETER
           MOVE 'AV'                 TO WS-RO-STATUS
           MOVE WS-RI-KEY-NUMBER     TO WS-RO-KEY-NUMBER
           MOVE WS-RI-DAMAGE-FLAG    TO WS-RO-DAMAGE-FLAG
           MOVE WS-RI-DAMAGE-DESC    TO WS-RO-DAMAGE-DESC
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-RECV-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHRCV00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHRCV00                                              *
      ****************************************************************
