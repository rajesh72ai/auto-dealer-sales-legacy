       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLIETA00.
      ****************************************************************
      * PROGRAM:  PLIETA00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - ETA TRACKING SCREEN       *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ETA TRACKING DISPLAY. SEARCH BY VIN, DEALER CODE,  *
      *           OR SHIPMENT ID. DISPLAYS VEHICLE/SHIPMENT DETAILS  *
      *           WITH FULL TRANSIT HISTORY TIMELINE. LISTS STATUS,  *
      *           LOCATION, TIMESTAMP FOR EACH TRANSIT EVENT.        *
      *           CALCULATES DAYS IN TRANSIT AND ESTIMATED DAYS      *
      *           REMAINING. DISPLAY ONLY - NO UPDATES.              *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLET - ETA TRACKING                                *
      * CALLS:    COMDTEL0 - DATE CALCULATION (DAYS FUNCTION)        *
      *           COMFMTL0 - FORMATTING UTILITY                      *
      * TABLES:   AUTOSALE.SHIPMENT        (READ)                    *
      *           AUTOSALE.SHIPMENT_VEHICLE (READ)                   *
      *           AUTOSALE.VEHICLE          (READ)                    *
      *           AUTOSALE.TRANSIT_STATUS   (READ)                   *
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
                                          VALUE 'PLIETA00'.
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
      *    INPUT FIELDS - ETA SEARCH
      *
       01  WS-ETA-INPUT.
           05  WS-EI-FUNCTION            PIC X(02).
               88  WS-EI-BY-VIN                     VALUE 'VN'.
               88  WS-EI-BY-DEALER                  VALUE 'DL'.
               88  WS-EI-BY-SHIPMENT                VALUE 'SH'.
           05  WS-EI-VIN                 PIC X(17).
           05  WS-EI-DEALER-CODE         PIC X(05).
           05  WS-EI-SHIPMENT-ID         PIC S9(09) COMP.
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-ETA-OUTPUT.
           05  WS-EO-STATUS-LINE.
               10  WS-EO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-MSG-TEXT       PIC X(70).
           05  WS-EO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-EO-SHIP-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'SHIPMENT ID: '.
               10  WS-EO-SHIP-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'CARRIER: '.
               10  WS-EO-CARRIER        PIC X(06).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-EO-SHIP-STATUS    PIC X(02).
               10  FILLER               PIC X(24) VALUE SPACES.
           05  WS-EO-ROUTE-LINE.
               10  FILLER               PIC X(08)
                   VALUE 'ORIGIN: '.
               10  WS-EO-ORIGIN         PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'DEST: '.
               10  WS-EO-DEST           PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MODE: '.
               10  WS-EO-MODE           PIC X(02).
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-EO-DATE-LINE.
               10  FILLER               PIC X(11)
                   VALUE 'DEPARTURE: '.
               10  WS-EO-DEPART-DATE    PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'EST ARR: '.
               10  WS-EO-EST-ARRIVAL    PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'ACT ARR: '.
               10  WS-EO-ACT-ARRIVAL    PIC X(10).
               10  FILLER               PIC X(12) VALUE SPACES.
           05  WS-EO-VEH-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-EO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-EO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-EO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-EO-MODEL          PIC X(06).
               10  FILLER               PIC X(16) VALUE SPACES.
           05  WS-EO-TRANSIT-LINE.
               10  FILLER               PIC X(16)
                   VALUE 'DAYS IN TRANSIT:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-DAYS-TRANSIT   PIC Z(03)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(15)
                   VALUE 'EST REMAINING: '.
               10  WS-EO-DAYS-REMAIN    PIC Z(03)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'VEHICLES: '.
               10  WS-EO-VEH-COUNT      PIC Z(03)9.
               10  FILLER               PIC X(15) VALUE SPACES.
           05  WS-EO-HIST-HEADER.
               10  FILLER               PIC X(79)
                   VALUE '--- TRANSIT HISTORY ----------------------
      -           '----------------------------------'.
           05  WS-EO-HIST-DETAIL OCCURS 10 TIMES.
               10  WS-EO-HD-SEQ         PIC Z(02)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-HD-STATUS      PIC X(02).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-HD-DESC        PIC X(12).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-HD-LOCATION    PIC X(10).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-HD-DATE        PIC X(10).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-HD-TIME        PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-EO-HD-CARRIER-REF PIC X(20).
               10  FILLER               PIC X(08) VALUE SPACES.
           05  WS-EO-FILLER             PIC X(538) VALUE SPACES.
      *
      *    DATE CALCULATION CALL FIELDS
      *
       01  WS-DTE-FUNCTION               PIC X(04).
       01  WS-DTE-DATE-1                 PIC X(10).
       01  WS-DTE-DATE-2                 PIC X(10).
       01  WS-DTE-RESULT                 PIC S9(09) COMP.
       01  WS-DTE-RETURN-CODE            PIC S9(04) COMP.
       01  WS-DTE-ERROR-MSG              PIC X(50).
      *
      *    FORMAT UTILITY CALL FIELDS
      *
       01  WS-FMT-FUNCTION               PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA        PIC X(40).
           05  WS-FMT-INPUT-NUM          PIC S9(09)V99 COMP-3.
       01  WS-FMT-OUTPUT                 PIC X(40).
       01  WS-FMT-RETURN-CODE            PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG              PIC X(50).
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
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-ROW-COUNT             PIC S9(04) COMP VALUE +0.
           05  WS-DAYS-TRANSIT          PIC S9(04) COMP VALUE +0.
           05  WS-DAYS-REMAINING        PIC S9(04) COMP VALUE +0.
           05  WS-VEH-COUNT             PIC S9(04) COMP VALUE +0.
           05  WS-EOF-FLAG              PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA                  VALUE 'Y'.
               88  WS-MORE-DATA                    VALUE 'N'.
      *
      *    SHIPMENT LOOKUP HOST VARIABLES
      *
       01  WS-HV-SHIP.
           05  WS-HV-SHIP-ID            PIC S9(09) COMP.
           05  WS-HV-CARRIER            PIC X(06).
           05  WS-HV-ORIGIN             PIC X(05).
           05  WS-HV-DEST               PIC X(05).
           05  WS-HV-MODE               PIC X(02).
           05  WS-HV-STATUS             PIC X(02).
           05  WS-HV-VEH-COUNT          PIC S9(04) COMP.
           05  WS-HV-DEPART-DATE        PIC X(10).
           05  WS-HV-EST-ARR            PIC X(10).
           05  WS-HV-ACT-ARR            PIC X(10).
      *
      *    VEHICLE LOOKUP HOST VARIABLES
      *
       01  WS-HV-VEH.
           05  WS-HV-VIN                PIC X(17).
           05  WS-HV-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-HV-MAKE-CODE          PIC X(03).
           05  WS-HV-MODEL-CODE         PIC X(06).
      *
      *    NULL INDICATORS FOR NULLABLE COLUMNS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-ACT-ARR            PIC S9(04) COMP VALUE +0.
           05  WS-NI-CARRIER-REF        PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR FOR TRANSIT HISTORY
      *
           EXEC SQL DECLARE CSR_TRANSIT CURSOR FOR
               SELECT T.STATUS_SEQ
                    , T.STATUS_CODE
                    , T.STATUS_DESC
                    , T.LOCATION_CODE
                    , T.STATUS_DATE
                    , T.STATUS_TIME
                    , T.CARRIER_REF
               FROM   AUTOSALE.TRANSIT_STATUS T
               WHERE  T.SHIPMENT_ID = :WS-EI-SHIPMENT-ID
               ORDER BY T.STATUS_TS ASC
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HV-TRANSIT.
           05  WS-HV-TR-SEQ             PIC S9(09) COMP.
           05  WS-HV-TR-STATUS          PIC X(02).
           05  WS-HV-TR-DESC.
               49  WS-HV-TR-DESC-LN     PIC S9(04) COMP.
               49  WS-HV-TR-DESC-TX     PIC X(20).
           05  WS-HV-TR-LOCATION        PIC X(10).
           05  WS-HV-TR-DATE            PIC X(10).
           05  WS-HV-TR-TIME            PIC X(08).
           05  WS-HV-TR-CARRIER-REF     PIC X(20).
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
                   WHEN WS-EI-BY-VIN
                       PERFORM 4000-LOOKUP-BY-VIN
                   WHEN WS-EI-BY-DEALER
                       PERFORM 4100-LOOKUP-BY-DEALER
                   WHEN WS-EI-BY-SHIPMENT
                       PERFORM 4200-LOOKUP-BY-SHIPMENT
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - USE VN, DL, OR SH'
                           TO WS-EO-MSG-TEXT
               END-EVALUATE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-LOAD-TRANSIT-HISTORY
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-CALCULATE-ETA
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
           INITIALIZE WS-ETA-OUTPUT
           MOVE 'PLIETA00' TO WS-EO-MSG-ID
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
                   TO WS-EO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-EI-FUNCTION
               MOVE WS-INP-BODY(1:17)   TO WS-EI-VIN
               MOVE WS-INP-BODY(18:5)   TO WS-EI-DEALER-CODE
               MOVE WS-INP-BODY(23:4)   TO WS-EI-SHIPMENT-ID
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK SEARCH CRITERIA                *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-EI-BY-VIN
               IF WS-EI-VIN = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'VIN IS REQUIRED FOR VIN SEARCH'
                       TO WS-EO-MSG-TEXT
               END-IF
           END-IF
      *
           IF WS-EI-BY-DEALER
               IF WS-EI-DEALER-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEALER CODE REQUIRED FOR DEALER SEARCH'
                       TO WS-EO-MSG-TEXT
               END-IF
           END-IF
      *
           IF WS-EI-BY-SHIPMENT
               IF WS-EI-SHIPMENT-ID = +0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'SHIPMENT ID REQUIRED FOR SHIPMENT SEARCH'
                       TO WS-EO-MSG-TEXT
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4000-LOOKUP-BY-VIN - FIND SHIPMENT FOR VIN                 *
      ****************************************************************
       4000-LOOKUP-BY-VIN.
      *
      *    GET VEHICLE DETAILS
      *
           EXEC SQL
               SELECT V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.MODEL_CODE
               INTO   :WS-HV-MODEL-YEAR
                    , :WS-HV-MAKE-CODE
                    , :WS-HV-MODEL-CODE
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VIN = :WS-EI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND'
                   TO WS-EO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-EI-VIN       TO WS-EO-VIN
           MOVE WS-HV-MODEL-YEAR TO WS-EO-YEAR
           MOVE WS-HV-MAKE-CODE TO WS-EO-MAKE
           MOVE WS-HV-MODEL-CODE TO WS-EO-MODEL
      *
      *    FIND SHIPMENT FOR THIS VIN
      *
           EXEC SQL
               SELECT S.SHIPMENT_ID
                    , S.CARRIER_CODE
                    , S.ORIGIN_PLANT
                    , S.DEST_DEALER
                    , S.TRANSPORT_MODE
                    , S.SHIPMENT_STATUS
                    , S.VEHICLE_COUNT
                    , S.DEPARTURE_DATE
                    , S.EST_ARRIVAL_DATE
                    , S.ACT_ARRIVAL_DATE
               INTO   :WS-HV-SHIP-ID
                    , :WS-HV-CARRIER
                    , :WS-HV-ORIGIN
                    , :WS-HV-DEST
                    , :WS-HV-MODE
                    , :WS-HV-STATUS
                    , :WS-HV-VEH-COUNT
                    , :WS-HV-DEPART-DATE
                    , :WS-HV-EST-ARR
                    , :WS-HV-ACT-ARR :WS-NI-ACT-ARR
               FROM   AUTOSALE.SHIPMENT S
               JOIN   AUTOSALE.SHIPMENT_VEHICLE SV
                 ON   SV.SHIPMENT_ID = S.SHIPMENT_ID
               WHERE  SV.VIN = :WS-EI-VIN
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO SHIPMENT FOUND FOR THIS VIN'
                   TO WS-EO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-HV-SHIP-ID   TO WS-EI-SHIPMENT-ID
           PERFORM 4300-FORMAT-SHIPMENT-OUTPUT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-LOOKUP-BY-DEALER - FIND LATEST SHIPMENT FOR DEALER    *
      ****************************************************************
       4100-LOOKUP-BY-DEALER.
      *
           EXEC SQL
               SELECT S.SHIPMENT_ID
                    , S.CARRIER_CODE
                    , S.ORIGIN_PLANT
                    , S.DEST_DEALER
                    , S.TRANSPORT_MODE
                    , S.SHIPMENT_STATUS
                    , S.VEHICLE_COUNT
                    , S.DEPARTURE_DATE
                    , S.EST_ARRIVAL_DATE
                    , S.ACT_ARRIVAL_DATE
               INTO   :WS-HV-SHIP-ID
                    , :WS-HV-CARRIER
                    , :WS-HV-ORIGIN
                    , :WS-HV-DEST
                    , :WS-HV-MODE
                    , :WS-HV-STATUS
                    , :WS-HV-VEH-COUNT
                    , :WS-HV-DEPART-DATE
                    , :WS-HV-EST-ARR
                    , :WS-HV-ACT-ARR :WS-NI-ACT-ARR
               FROM   AUTOSALE.SHIPMENT S
               WHERE  S.DEST_DEALER = :WS-EI-DEALER-CODE
                 AND  S.SHIPMENT_STATUS NOT = 'DL'
               ORDER BY S.CREATED_TS DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO ACTIVE SHIPMENTS FOUND FOR DEALER'
                   TO WS-EO-MSG-TEXT
               GO TO 4100-EXIT
           END-IF
      *
           MOVE WS-HV-SHIP-ID TO WS-EI-SHIPMENT-ID
           PERFORM 4300-FORMAT-SHIPMENT-OUTPUT
           .
       4100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4200-LOOKUP-BY-SHIPMENT - DIRECT SHIPMENT LOOKUP           *
      ****************************************************************
       4200-LOOKUP-BY-SHIPMENT.
      *
           EXEC SQL
               SELECT S.SHIPMENT_ID
                    , S.CARRIER_CODE
                    , S.ORIGIN_PLANT
                    , S.DEST_DEALER
                    , S.TRANSPORT_MODE
                    , S.SHIPMENT_STATUS
                    , S.VEHICLE_COUNT
                    , S.DEPARTURE_DATE
                    , S.EST_ARRIVAL_DATE
                    , S.ACT_ARRIVAL_DATE
               INTO   :WS-HV-SHIP-ID
                    , :WS-HV-CARRIER
                    , :WS-HV-ORIGIN
                    , :WS-HV-DEST
                    , :WS-HV-MODE
                    , :WS-HV-STATUS
                    , :WS-HV-VEH-COUNT
                    , :WS-HV-DEPART-DATE
                    , :WS-HV-EST-ARR
                    , :WS-HV-ACT-ARR :WS-NI-ACT-ARR
               FROM   AUTOSALE.SHIPMENT S
               WHERE  S.SHIPMENT_ID = :WS-EI-SHIPMENT-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SHIPMENT NOT FOUND'
                   TO WS-EO-MSG-TEXT
               GO TO 4200-EXIT
           END-IF
      *
           PERFORM 4300-FORMAT-SHIPMENT-OUTPUT
           .
       4200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4300-FORMAT-SHIPMENT-OUTPUT - POPULATE SHIPMENT FIELDS      *
      ****************************************************************
       4300-FORMAT-SHIPMENT-OUTPUT.
      *
           MOVE WS-HV-SHIP-ID       TO WS-EO-SHIP-ID
           MOVE WS-HV-CARRIER       TO WS-EO-CARRIER
           MOVE WS-HV-STATUS        TO WS-EO-SHIP-STATUS
           MOVE WS-HV-ORIGIN        TO WS-EO-ORIGIN
           MOVE WS-HV-DEST          TO WS-EO-DEST
           MOVE WS-HV-MODE          TO WS-EO-MODE
           MOVE WS-HV-DEPART-DATE   TO WS-EO-DEPART-DATE
           MOVE WS-HV-EST-ARR       TO WS-EO-EST-ARRIVAL
           MOVE WS-HV-VEH-COUNT     TO WS-EO-VEH-COUNT
      *
           IF WS-NI-ACT-ARR = +0
               MOVE WS-HV-ACT-ARR   TO WS-EO-ACT-ARRIVAL
           ELSE
               MOVE 'N/A       '    TO WS-EO-ACT-ARRIVAL
           END-IF
           .
      *
      ****************************************************************
      *    5000-LOAD-TRANSIT-HISTORY - CURSOR ON TRANSIT_STATUS       *
      ****************************************************************
       5000-LOAD-TRANSIT-HISTORY.
      *
           EXEC SQL OPEN CSR_TRANSIT END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: COULD NOT LOAD TRANSIT HISTORY'
                   TO WS-EO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 5100-FETCH-TRANSIT-ROW
               UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +10
      *
           EXEC SQL CLOSE CSR_TRANSIT END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'ETA INFO RETRIEVED - NO TRANSIT EVENTS YET'
                   TO WS-EO-MSG-TEXT
           ELSE
               MOVE 'ETA TRACKING INFORMATION RETRIEVED'
                   TO WS-EO-MSG-TEXT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-TRANSIT-ROW - FETCH AND FORMAT HISTORY ROW      *
      ****************************************************************
       5100-FETCH-TRANSIT-ROW.
      *
           EXEC SQL FETCH CSR_TRANSIT
               INTO  :WS-HV-TR-SEQ
                    , :WS-HV-TR-STATUS
                    , :WS-HV-TR-DESC
                    , :WS-HV-TR-LOCATION
                    , :WS-HV-TR-DATE
                    , :WS-HV-TR-TIME
                    , :WS-HV-TR-CARRIER-REF
                                           :WS-NI-CARRIER-REF
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   MOVE WS-HV-TR-SEQ
                       TO WS-EO-HD-SEQ(WS-ROW-COUNT)
                   MOVE WS-HV-TR-STATUS
                       TO WS-EO-HD-STATUS(WS-ROW-COUNT)
                   MOVE WS-HV-TR-DESC-TX
                       TO WS-EO-HD-DESC(WS-ROW-COUNT)
                   MOVE WS-HV-TR-LOCATION
                       TO WS-EO-HD-LOCATION(WS-ROW-COUNT)
                   MOVE WS-HV-TR-DATE
                       TO WS-EO-HD-DATE(WS-ROW-COUNT)
                   MOVE WS-HV-TR-TIME
                       TO WS-EO-HD-TIME(WS-ROW-COUNT)
                   IF WS-NI-CARRIER-REF = +0
                       MOVE WS-HV-TR-CARRIER-REF
                           TO WS-EO-HD-CARRIER-REF(WS-ROW-COUNT)
                   END-IF
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
           END-EVALUATE
           .
      *
      ****************************************************************
      *    6000-CALCULATE-ETA - DAYS IN TRANSIT AND REMAINING         *
      ****************************************************************
       6000-CALCULATE-ETA.
      *
      *    CALCULATE DAYS IN TRANSIT
      *
           MOVE 'DAYS'              TO WS-DTE-FUNCTION
           MOVE WS-HV-DEPART-DATE   TO WS-DTE-DATE-1
           MOVE WS-FORMATTED-DATE    TO WS-DTE-DATE-2
      *
           CALL 'COMDTEL0' USING WS-DTE-FUNCTION
                                 WS-DTE-DATE-1
                                 WS-DTE-DATE-2
                                 WS-DTE-RESULT
                                 WS-DTE-RETURN-CODE
                                 WS-DTE-ERROR-MSG
      *
           IF WS-DTE-RETURN-CODE = +0
               MOVE WS-DTE-RESULT TO WS-DAYS-TRANSIT
               MOVE WS-DAYS-TRANSIT TO WS-EO-DAYS-TRANSIT
           ELSE
               MOVE +0 TO WS-EO-DAYS-TRANSIT
           END-IF
      *
      *    CALCULATE ESTIMATED REMAINING DAYS
      *
           IF WS-HV-STATUS NOT = 'DL'
               MOVE 'DAYS'              TO WS-DTE-FUNCTION
               MOVE WS-FORMATTED-DATE    TO WS-DTE-DATE-1
               MOVE WS-HV-EST-ARR        TO WS-DTE-DATE-2
      *
               CALL 'COMDTEL0' USING WS-DTE-FUNCTION
                                     WS-DTE-DATE-1
                                     WS-DTE-DATE-2
                                     WS-DTE-RESULT
                                     WS-DTE-RETURN-CODE
                                     WS-DTE-ERROR-MSG
      *
               IF WS-DTE-RETURN-CODE = +0
                   IF WS-DTE-RESULT > +0
                       MOVE WS-DTE-RESULT TO WS-DAYS-REMAINING
                   ELSE
                       MOVE +0 TO WS-DAYS-REMAINING
                   END-IF
                   MOVE WS-DAYS-REMAINING TO WS-EO-DAYS-REMAIN
               ELSE
                   MOVE +0 TO WS-EO-DAYS-REMAIN
               END-IF
           ELSE
               MOVE +0 TO WS-EO-DAYS-REMAIN
           END-IF
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-ETA-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLIETA00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLIETA00                                               *
      ****************************************************************
