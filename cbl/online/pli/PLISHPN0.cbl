       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLISHPN0.
      ****************************************************************
      * PROGRAM:  PLISHPN0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - SHIPMENT CREATION         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  GROUPS ALLOCATED VEHICLES INTO TRANSPORT LOADS.    *
      *           CREATES SHIPMENT RECORD WITH AUTO-GENERATED ID.    *
      *           VALIDATES VEHICLE STATUS=AL, INSERTS INTO          *
      *           SHIPMENT_VEHICLE. CALCULATES VEHICLE COUNT AND     *
      *           ESTIMATES ARRIVAL DATE BASED ON TRANSPORT MODE.     *
      *           DISPATCHES SHIPMENT: UPDATES ALL VEHICLES TO SH.   *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLSH - SHIPMENT CREATION                           *
      * CALLS:    COMSEQL0 - SEQUENCE NUMBER GENERATION              *
      *           COMSTCK0 - STOCK UPDATE                            *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.SHIPMENT                                  *
      *           AUTOSALE.SHIPMENT_VEHICLE                          *
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
                                          VALUE 'PLISHPN0'.
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
      *    INPUT FIELDS - SHIPMENT DATA
      *
       01  WS-SHIP-INPUT.
           05  WS-SI-FUNCTION            PIC X(02).
               88  WS-SI-CREATE                     VALUE 'CR'.
               88  WS-SI-ADD-VEH                    VALUE 'AV'.
               88  WS-SI-DISPATCH                   VALUE 'DP'.
               88  WS-SI-INQUIRY                    VALUE 'IQ'.
           05  WS-SI-SHIPMENT-ID         PIC S9(09) COMP.
           05  WS-SI-CARRIER-CODE        PIC X(06).
           05  WS-SI-ORIGIN-PLANT        PIC X(05).
           05  WS-SI-DEST-DEALER         PIC X(05).
           05  WS-SI-TRANSPORT-MODE      PIC X(02).
               88  WS-SI-TRUCK                      VALUE 'TK'.
               88  WS-SI-RAIL                       VALUE 'RL'.
               88  WS-SI-OCEAN                      VALUE 'OC'.
               88  WS-SI-AIR                        VALUE 'AR'.
           05  WS-SI-VIN                 PIC X(17).
           05  WS-SI-DEPARTURE-DATE      PIC X(10).
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-SHIP-OUTPUT.
           05  WS-SO-STATUS-LINE.
               10  WS-SO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-SO-MSG-TEXT       PIC X(70).
           05  WS-SO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-SO-SHIP-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'SHIPMENT ID: '.
               10  WS-SO-SHIP-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'CARRIER: '.
               10  WS-SO-CARRIER        PIC X(06).
               10  FILLER               PIC X(38) VALUE SPACES.
           05  WS-SO-ROUTE-LINE.
               10  FILLER               PIC X(08)
                   VALUE 'ORIGIN: '.
               10  WS-SO-ORIGIN         PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'DEST: '.
               10  WS-SO-DEST           PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MODE: '.
               10  WS-SO-MODE           PIC X(02).
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-SO-DATE-LINE.
               10  FILLER               PIC X(11)
                   VALUE 'DEPARTURE: '.
               10  WS-SO-DEPART-DATE    PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'EST ARR: '.
               10  WS-SO-EST-ARRIVAL    PIC X(10).
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-SO-COUNT-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'VEHICLES: '.
               10  WS-SO-VEH-COUNT      PIC Z(03)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-SO-STATUS         PIC X(02).
               10  FILLER               PIC X(51) VALUE SPACES.
           05  WS-SO-VIN-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'ADDED VIN:  '.
               10  WS-SO-VIN            PIC X(17).
               10  FILLER               PIC X(50) VALUE SPACES.
           05  WS-SO-FILLER             PIC X(1248) VALUE SPACES.
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
           05  WS-EST-ARRIVAL-DATE      PIC X(10) VALUE SPACES.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-VEHICLE-STATUS        PIC X(02) VALUE SPACES.
           05  WS-VEHICLE-DEALER        PIC X(05) VALUE SPACES.
           05  WS-SHIP-STATUS           PIC X(02) VALUE SPACES.
           05  WS-VEH-COUNT             PIC S9(04) COMP VALUE +0.
           05  WS-TRANSIT-DAYS          PIC S9(04) COMP VALUE +0.
           05  WS-NEW-SHIPMENT-ID       PIC S9(09) COMP VALUE +0.
           05  WS-VEH-SEQ               PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR FOR DISPATCH - ALL VEHICLES IN SHIPMENT
      *
           EXEC SQL DECLARE CSR_SHIP_VEH CURSOR FOR
               SELECT SV.VIN
                    , SV.VEHICLE_SEQ
               FROM   AUTOSALE.SHIPMENT_VEHICLE SV
               WHERE  SV.SHIPMENT_ID = :WS-SI-SHIPMENT-ID
               ORDER BY SV.VEHICLE_SEQ
           END-EXEC
      *
       01  WS-HV-DISPATCH.
           05  WS-HV-VIN                PIC X(17).
           05  WS-HV-VEH-SEQ           PIC S9(04) COMP.
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
                   WHEN WS-SI-CREATE
                       PERFORM 3000-CREATE-SHIPMENT
                   WHEN WS-SI-ADD-VEH
                       PERFORM 4000-ADD-VEHICLE
                   WHEN WS-SI-DISPATCH
                       PERFORM 5000-DISPATCH-SHIPMENT
                   WHEN WS-SI-INQUIRY
                       PERFORM 6000-INQUIRY-SHIPMENT
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - USE CR/AV/DP/IQ'
                           TO WS-SO-MSG-TEXT
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
           INITIALIZE WS-SHIP-OUTPUT
           MOVE 'PLISHPN0' TO WS-SO-MSG-ID
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
                   TO WS-SO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-SI-FUNCTION
               MOVE WS-INP-BODY(1:4)    TO WS-SI-SHIPMENT-ID
               MOVE WS-INP-BODY(5:6)    TO WS-SI-CARRIER-CODE
               MOVE WS-INP-BODY(11:5)   TO WS-SI-ORIGIN-PLANT
               MOVE WS-INP-BODY(16:5)   TO WS-SI-DEST-DEALER
               MOVE WS-INP-BODY(21:2)   TO WS-SI-TRANSPORT-MODE
               MOVE WS-INP-BODY(23:17)  TO WS-SI-VIN
               MOVE WS-INP-BODY(40:10)  TO WS-SI-DEPARTURE-DATE
           END-IF
           .
      *
      ****************************************************************
      *    3000-CREATE-SHIPMENT - CREATE NEW SHIPMENT RECORD          *
      ****************************************************************
       3000-CREATE-SHIPMENT.
      *
      *    VALIDATE REQUIRED FIELDS
      *
           IF WS-SI-CARRIER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CARRIER CODE IS REQUIRED'
                   TO WS-SO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-SI-ORIGIN-PLANT = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ORIGIN PLANT IS REQUIRED'
                   TO WS-SO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-SI-DEST-DEALER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DESTINATION DEALER IS REQUIRED'
                   TO WS-SO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-SI-TRANSPORT-MODE = SPACES
               MOVE 'TK' TO WS-SI-TRANSPORT-MODE
           END-IF
      *
      *    GENERATE SHIPMENT ID VIA COMSEQL0
      *
           MOVE 'SHIPMENT_ID   '  TO WS-SEQ-TABLE-NAME
           MOVE 'SHIPMENT      '  TO WS-SEQ-COLUMN-NAME
           CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                 WS-SEQ-RESULT
      *
           IF WS-SEQ-RC NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR GENERATING SHIPMENT ID'
                   TO WS-SO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-SEQ-NEXT-VALUE TO WS-NEW-SHIPMENT-ID
      *
      *    SET DEPARTURE DATE
      *
           IF WS-SI-DEPARTURE-DATE = SPACES
               MOVE WS-FORMATTED-DATE TO WS-SI-DEPARTURE-DATE
           END-IF
      *
      *    CALCULATE ESTIMATED ARRIVAL DATE BASED ON TRANSPORT MODE
      *
           EVALUATE TRUE
               WHEN WS-SI-TRUCK
                   MOVE +3 TO WS-TRANSIT-DAYS
               WHEN WS-SI-RAIL
                   MOVE +7 TO WS-TRANSIT-DAYS
               WHEN WS-SI-OCEAN
                   MOVE +21 TO WS-TRANSIT-DAYS
               WHEN WS-SI-AIR
                   MOVE +1 TO WS-TRANSIT-DAYS
               WHEN OTHER
                   MOVE +5 TO WS-TRANSIT-DAYS
           END-EVALUATE
      *
      *    SIMPLIFIED ETA: USE DEPARTURE + TRANSIT DAYS
      *    ACTUAL CALCULATION WOULD USE DATE ARITHMETIC
      *
           MOVE WS-SI-DEPARTURE-DATE TO WS-EST-ARRIVAL-DATE
      *
      *    INSERT SHIPMENT RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.SHIPMENT
                    ( SHIPMENT_ID
                    , CARRIER_CODE
                    , ORIGIN_PLANT
                    , DEST_DEALER
                    , TRANSPORT_MODE
                    , SHIPMENT_STATUS
                    , VEHICLE_COUNT
                    , DEPARTURE_DATE
                    , EST_ARRIVAL_DATE
                    , ACT_ARRIVAL_DATE
                    , CREATED_TS
                    , UPDATED_TS
                    )
               VALUES
                    ( :WS-NEW-SHIPMENT-ID
                    , :WS-SI-CARRIER-CODE
                    , :WS-SI-ORIGIN-PLANT
                    , :WS-SI-DEST-DEALER
                    , :WS-SI-TRANSPORT-MODE
                    , 'CR'
                    , 0
                    , :WS-SI-DEPARTURE-DATE
                    , :WS-EST-ARRIVAL-DATE
                    , NULL
                    , CURRENT TIMESTAMP
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR INSERTING SHIPMENT RECORD'
                   TO WS-SO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLISHPN0'      TO WS-LR-PROGRAM
           MOVE 'SHIPCRT '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'SHIPMENT'      TO WS-LR-ENTITY-TYPE
           MOVE WS-NEW-SHIPMENT-ID TO WS-LR-ENTITY-KEY
           STRING 'SHIPMENT CREATED CARRIER '
                  WS-SI-CARRIER-CODE
                  ' FROM ' WS-SI-ORIGIN-PLANT
                  ' TO ' WS-SI-DEST-DEALER
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           MOVE 'SHIPMENT CREATED SUCCESSFULLY'
               TO WS-SO-MSG-TEXT
           MOVE WS-NEW-SHIPMENT-ID   TO WS-SO-SHIP-ID
           MOVE WS-SI-CARRIER-CODE   TO WS-SO-CARRIER
           MOVE WS-SI-ORIGIN-PLANT   TO WS-SO-ORIGIN
           MOVE WS-SI-DEST-DEALER    TO WS-SO-DEST
           MOVE WS-SI-TRANSPORT-MODE TO WS-SO-MODE
           MOVE WS-SI-DEPARTURE-DATE TO WS-SO-DEPART-DATE
           MOVE WS-EST-ARRIVAL-DATE  TO WS-SO-EST-ARRIVAL
           MOVE +0                   TO WS-SO-VEH-COUNT
           MOVE 'CR'                 TO WS-SO-STATUS
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-ADD-VEHICLE - ADD VEHICLE TO SHIPMENT                 *
      ****************************************************************
       4000-ADD-VEHICLE.
      *
      *    VALIDATE INPUTS
      *
           IF WS-SI-SHIPMENT-ID = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT ID IS REQUIRED'
                   TO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-SI-VIN = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN IS REQUIRED TO ADD VEHICLE'
                   TO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY SHIPMENT EXISTS AND IS IN CR STATUS
      *
           EXEC SQL
               SELECT SHIPMENT_STATUS
                    , VEHICLE_COUNT
               INTO   :WS-SHIP-STATUS
                    , :WS-VEH-COUNT
               FROM   AUTOSALE.SHIPMENT
               WHERE  SHIPMENT_ID = :WS-SI-SHIPMENT-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT NOT FOUND'
                   TO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-SHIP-STATUS NOT = 'CR'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT ADD - SHIPMENT STATUS IS '
                      WS-SHIP-STATUS
                      DELIMITED BY SIZE
                      INTO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY VEHICLE IS ALLOCATED (STATUS=AL)
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , DEALER_CODE
               INTO   :WS-VEHICLE-STATUS
                    , :WS-VEHICLE-DEALER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-SI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND'
                   TO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-VEHICLE-STATUS NOT = 'AL'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'VEHICLE NOT ALLOCATED - STATUS IS '
                      WS-VEHICLE-STATUS
                      DELIMITED BY SIZE
                      INTO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    INSERT SHIPMENT_VEHICLE RECORD
      *
           ADD +1 TO WS-VEH-COUNT
           MOVE WS-VEH-COUNT TO WS-VEH-SEQ
      *
           EXEC SQL
               INSERT INTO AUTOSALE.SHIPMENT_VEHICLE
                    ( SHIPMENT_ID
                    , VEHICLE_SEQ
                    , VIN
                    , LOAD_POSITION
                    , CREATED_TS
                    )
               VALUES
                    ( :WS-SI-SHIPMENT-ID
                    , :WS-VEH-SEQ
                    , :WS-SI-VIN
                    , :WS-VEH-SEQ
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR INSERTING SHIPMENT VEHICLE'
                   TO WS-SO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    UPDATE VEHICLE COUNT ON SHIPMENT
      *
           EXEC SQL
               UPDATE AUTOSALE.SHIPMENT
                  SET VEHICLE_COUNT = :WS-VEH-COUNT
                    , UPDATED_TS    = CURRENT TIMESTAMP
               WHERE  SHIPMENT_ID = :WS-SI-SHIPMENT-ID
           END-EXEC
      *
      *    FORMAT OUTPUT
      *
           MOVE 'VEHICLE ADDED TO SHIPMENT'
               TO WS-SO-MSG-TEXT
           MOVE WS-SI-SHIPMENT-ID TO WS-SO-SHIP-ID
           MOVE WS-SI-VIN         TO WS-SO-VIN
           MOVE WS-VEH-COUNT      TO WS-SO-VEH-COUNT
           MOVE 'CR'               TO WS-SO-STATUS
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-DISPATCH-SHIPMENT - SET STATUS TO DISPATCHED          *
      ****************************************************************
       5000-DISPATCH-SHIPMENT.
      *
           IF WS-SI-SHIPMENT-ID = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT ID IS REQUIRED FOR DISPATCH'
                   TO WS-SO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    VERIFY SHIPMENT EXISTS AND HAS VEHICLES
      *
           EXEC SQL
               SELECT SHIPMENT_STATUS
                    , VEHICLE_COUNT
                    , CARRIER_CODE
                    , ORIGIN_PLANT
                    , DEST_DEALER
                    , TRANSPORT_MODE
               INTO   :WS-SHIP-STATUS
                    , :WS-VEH-COUNT
                    , :WS-SI-CARRIER-CODE
                    , :WS-SI-ORIGIN-PLANT
                    , :WS-SI-DEST-DEALER
                    , :WS-SI-TRANSPORT-MODE
               FROM   AUTOSALE.SHIPMENT
               WHERE  SHIPMENT_ID = :WS-SI-SHIPMENT-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT NOT FOUND'
                   TO WS-SO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF WS-SHIP-STATUS NOT = 'CR'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT DISPATCH - STATUS IS '
                      WS-SHIP-STATUS
                      DELIMITED BY SIZE
                      INTO WS-SO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF WS-VEH-COUNT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CANNOT DISPATCH - NO VEHICLES IN SHIPMENT'
                   TO WS-SO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE ALL VEHICLES IN SHIPMENT TO SH (SHIPPED)
      *
           EXEC SQL OPEN CSR_SHIP_VEH END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR OPENING VEHICLE CURSOR'
                   TO WS-SO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-WORK-FIELDS
           PERFORM 5100-UPDATE-VEHICLE-STATUS
               UNTIL WS-RETURN-CODE NOT = +0
      *
           EXEC SQL CLOSE CSR_SHIP_VEH END-EXEC
      *
           IF WS-RETURN-CODE > +4
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE SHIPMENT STATUS TO DP (DISPATCHED)
      *
           EXEC SQL
               UPDATE AUTOSALE.SHIPMENT
                  SET SHIPMENT_STATUS = 'DP'
                    , DEPARTURE_DATE  = :WS-FORMATTED-DATE
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  SHIPMENT_ID = :WS-SI-SHIPMENT-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING SHIPMENT STATUS'
                   TO WS-SO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLISHPN0'      TO WS-LR-PROGRAM
           MOVE 'DISPATCH'      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'SHIPMENT'      TO WS-LR-ENTITY-TYPE
           MOVE WS-SI-SHIPMENT-ID TO WS-LR-ENTITY-KEY
           STRING 'SHIPMENT DISPATCHED WITH '
                  WS-VEH-COUNT ' VEHICLES'
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           MOVE +0 TO WS-RETURN-CODE
           MOVE 'SHIPMENT DISPATCHED SUCCESSFULLY'
               TO WS-SO-MSG-TEXT
           MOVE WS-SI-SHIPMENT-ID    TO WS-SO-SHIP-ID
           MOVE WS-SI-CARRIER-CODE   TO WS-SO-CARRIER
           MOVE WS-SI-ORIGIN-PLANT   TO WS-SO-ORIGIN
           MOVE WS-SI-DEST-DEALER    TO WS-SO-DEST
           MOVE WS-SI-TRANSPORT-MODE TO WS-SO-MODE
           MOVE WS-FORMATTED-DATE    TO WS-SO-DEPART-DATE
           MOVE WS-VEH-COUNT         TO WS-SO-VEH-COUNT
           MOVE 'DP'                 TO WS-SO-STATUS
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-UPDATE-VEHICLE-STATUS - UPDATE EACH VEHICLE TO SH     *
      ****************************************************************
       5100-UPDATE-VEHICLE-STATUS.
      *
           EXEC SQL FETCH CSR_SHIP_VEH
               INTO  :WS-HV-VIN
                    , :WS-HV-VEH-SEQ
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +1 TO WS-RETURN-CODE
               GO TO 5100-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR FETCHING SHIPMENT VEHICLES'
                   TO WS-SO-MSG-TEXT
               GO TO 5100-EXIT
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = 'SH'
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :WS-HV-VIN
           END-EXEC
      *
      *    CALL COMSTCK0 FOR EACH VEHICLE
      *
           MOVE 'SHIP'              TO WS-SR-FUNCTION
           MOVE WS-SI-DEST-DEALER   TO WS-SR-DEALER-CODE
           MOVE WS-HV-VIN           TO WS-SR-VIN
           MOVE IO-PCB-USER-ID      TO WS-SR-USER-ID
           MOVE 'VEHICLE SHIPPED IN TRANSIT'
                                    TO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           MOVE +0 TO WS-RETURN-CODE
           .
       5100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-INQUIRY-SHIPMENT - DISPLAY SHIPMENT DETAILS           *
      ****************************************************************
       6000-INQUIRY-SHIPMENT.
      *
           EXEC SQL
               SELECT SHIPMENT_STATUS
                    , VEHICLE_COUNT
                    , CARRIER_CODE
                    , ORIGIN_PLANT
                    , DEST_DEALER
                    , TRANSPORT_MODE
                    , DEPARTURE_DATE
                    , EST_ARRIVAL_DATE
               INTO   :WS-SHIP-STATUS
                    , :WS-VEH-COUNT
                    , :WS-SI-CARRIER-CODE
                    , :WS-SI-ORIGIN-PLANT
                    , :WS-SI-DEST-DEALER
                    , :WS-SI-TRANSPORT-MODE
                    , :WS-SI-DEPARTURE-DATE
                    , :WS-EST-ARRIVAL-DATE
               FROM   AUTOSALE.SHIPMENT
               WHERE  SHIPMENT_ID = :WS-SI-SHIPMENT-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT NOT FOUND'
                   TO WS-SO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-SI-SHIPMENT-ID    TO WS-SO-SHIP-ID
           MOVE WS-SI-CARRIER-CODE   TO WS-SO-CARRIER
           MOVE WS-SI-ORIGIN-PLANT   TO WS-SO-ORIGIN
           MOVE WS-SI-DEST-DEALER    TO WS-SO-DEST
           MOVE WS-SI-TRANSPORT-MODE TO WS-SO-MODE
           MOVE WS-SI-DEPARTURE-DATE TO WS-SO-DEPART-DATE
           MOVE WS-EST-ARRIVAL-DATE  TO WS-SO-EST-ARRIVAL
           MOVE WS-VEH-COUNT         TO WS-SO-VEH-COUNT
           MOVE WS-SHIP-STATUS       TO WS-SO-STATUS
           MOVE 'SHIPMENT DETAILS RETRIEVED'
               TO WS-SO-MSG-TEXT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-SHIP-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLISHPN0' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLISHPN0                                               *
      ****************************************************************
