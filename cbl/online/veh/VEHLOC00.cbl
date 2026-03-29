       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHLOC00.
      ****************************************************************
      * PROGRAM:  VEHLOC00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - LOT LOCATION MANAGEMENT                  *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  MANAGES LOT LOCATIONS FOR DEALER VEHICLE STORAGE.  *
      *           FUNCTIONS:                                         *
      *           INQ - LIST LOCATIONS FOR DEALER                    *
      *           ADD - ADD NEW LOT LOCATION                         *
      *           UPD - UPDATE LOCATION DETAILS                      *
      *           ASGN - ASSIGN VEHICLE TO LOCATION                  *
      *           CRUD ON LOT_LOCATION TABLE. WHEN ASSIGNING:        *
      *           UPDATE VEHICLE.LOT_LOCATION, CHECK CAPACITY.       *
      *           SHOWS: LOCATION DESC, TYPE, CAPACITY, COUNT.       *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHLC - LOT LOCATION                                *
      * CALLS:    COMLGEL0 - AUDIT LOG ENTRY                         *
      *           COMDBEL0 - DB ERROR HANDLING                       *
      * TABLES:   AUTOSALE.LOT_LOCATION                               *
      *           AUTOSALE.VEHICLE                                   *
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
                                          VALUE 'VEHLOC00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
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
           COPY DCLLOTLC.
      *
           COPY DCLVEHCL.
      *
      *    INPUT FIELDS
      *
       01  WS-LOC-INPUT.
           05  WS-LCI-FUNCTION           PIC X(02).
               88  WS-LCI-INQUIRY                   VALUE 'IQ'.
               88  WS-LCI-ADD                       VALUE 'AD'.
               88  WS-LCI-UPDATE                    VALUE 'UP'.
               88  WS-LCI-ASSIGN                    VALUE 'AS'.
           05  WS-LCI-DEALER-CODE        PIC X(05).
           05  WS-LCI-LOCATION-CODE      PIC X(06).
           05  WS-LCI-LOCATION-DESC      PIC X(30).
           05  WS-LCI-LOCATION-TYPE      PIC X(01).
               88  WS-LCI-TYPE-LOT                  VALUE 'L'.
               88  WS-LCI-TYPE-SHOWROOM             VALUE 'S'.
               88  WS-LCI-TYPE-SERVICE              VALUE 'V'.
               88  WS-LCI-TYPE-OVERFLOW             VALUE 'O'.
           05  WS-LCI-MAX-CAPACITY       PIC 9(04).
           05  WS-LCI-ACTIVE-FLAG        PIC X(01).
           05  WS-LCI-VIN                PIC X(17).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-LOC-OUTPUT.
           05  WS-LCO-STATUS-LINE.
               10  WS-LCO-MSG-ID        PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LCO-MSG-TEXT      PIC X(70).
           05  WS-LCO-TITLE-LINE.
               10  FILLER               PIC X(30)
                   VALUE 'LOT LOCATION MANAGEMENT       '.
               10  FILLER               PIC X(08)
                   VALUE 'DEALER: '.
               10  WS-LCO-DEALER-HDR    PIC X(05).
               10  FILLER               PIC X(36) VALUE SPACES.
           05  WS-LCO-BLANK-1           PIC X(79) VALUE SPACES.
           05  WS-LCO-COL-HEADER.
               10  FILLER               PIC X(07) VALUE 'LOC CD '.
               10  FILLER               PIC X(31)
                   VALUE 'DESCRIPTION                    '.
               10  FILLER               PIC X(06) VALUE 'TYPE  '.
               10  FILLER               PIC X(06) VALUE 'CAP   '.
               10  FILLER               PIC X(06) VALUE 'COUNT '.
               10  FILLER               PIC X(06) VALUE 'AVAIL '.
               10  FILLER               PIC X(04) VALUE 'ACT '.
               10  FILLER               PIC X(13) VALUE SPACES.
           05  WS-LCO-SEP-LINE          PIC X(79) VALUE ALL '-'.
           05  WS-LCO-DETAIL-LINES.
               10  WS-LCO-DETAIL        OCCURS 10 TIMES.
                   15  WS-LCO-DT-LOC    PIC X(06).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LCO-DT-DESC   PIC X(30).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LCO-DT-TYPE   PIC X(01).
                   15  FILLER            PIC X(04) VALUE SPACES.
                   15  WS-LCO-DT-CAP    PIC Z(04)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LCO-DT-COUNT  PIC Z(04)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LCO-DT-AVAIL  PIC Z(04)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LCO-DT-ACTIVE PIC X(01).
                   15  FILLER            PIC X(16) VALUE SPACES.
           05  WS-LCO-BLANK-2           PIC X(79) VALUE SPACES.
           05  WS-LCO-ASSIGN-LINE.
               10  FILLER               PIC X(21)
                   VALUE 'VEHICLE ASSIGNED TO: '.
               10  WS-LCO-ASGN-LOC      PIC X(06).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'VIN: '.
               10  WS-LCO-ASGN-VIN      PIC X(17).
               10  FILLER               PIC X(26) VALUE SPACES.
           05  WS-LCO-FILLER            PIC X(372) VALUE SPACES.
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
      *    DB ERROR CALL FIELDS
      *
       01  WS-DBE-REQUEST.
           05  WS-DBE-PROGRAM           PIC X(08).
           05  WS-DBE-SQLCODE           PIC S9(09) COMP.
           05  WS-DBE-TABLE             PIC X(18).
           05  WS-DBE-OPERATION         PIC X(10).
       01  WS-DBE-RESULT.
           05  WS-DBE-RC                PIC S9(04) COMP.
           05  WS-DBE-MSG               PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-ROW-IDX               PIC S9(04) COMP VALUE +0.
           05  WS-CAPACITY-NUM          PIC S9(04) COMP VALUE +0.
           05  WS-CURRENT-NUM           PIC S9(04) COMP VALUE +0.
           05  WS-AVAIL-NUM             PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR - LIST LOCATIONS FOR DEALER
      *
           EXEC SQL
               DECLARE CSR_LOT_LOCS CURSOR FOR
               SELECT LOCATION_CODE
                    , LOCATION_DESC
                    , LOCATION_TYPE
                    , MAX_CAPACITY
                    , CURRENT_COUNT
                    , ACTIVE_FLAG
               FROM   AUTOSALE.LOT_LOCATION
               WHERE  DEALER_CODE = :WS-LCI-DEALER-CODE
               ORDER BY LOCATION_CODE
           END-EXEC.
      *
      *    CURSOR FETCH WORK AREA
      *
       01  WS-LOC-ROW.
           05  WS-LR-LOC-CODE           PIC X(06).
           05  WS-LR-LOC-DESC.
               49  WS-LR-LOC-DESC-LN    PIC S9(04) COMP.
               49  WS-LR-LOC-DESC-TX    PIC X(30).
           05  WS-LR-LOC-TYPE           PIC X(01).
           05  WS-LR-MAX-CAP            PIC S9(04) COMP.
           05  WS-LR-CURR-COUNT         PIC S9(04) COMP.
           05  WS-LR-ACTIVE             PIC X(01).
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
                   WHEN WS-LCI-INQUIRY
                       PERFORM 4000-LIST-LOCATIONS
                   WHEN WS-LCI-ADD
                       PERFORM 5000-ADD-LOCATION
                   WHEN WS-LCI-UPDATE
                       PERFORM 6000-UPDATE-LOCATION
                   WHEN WS-LCI-ASSIGN
                       PERFORM 7000-ASSIGN-VEHICLE
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION: USE IQ AD UP AS'
                           TO WS-LCO-MSG-TEXT
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
           INITIALIZE WS-LOC-OUTPUT
           MOVE 'VEHLOC00' TO WS-LCO-MSG-ID
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT                                        *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'IMS GU FAILED' TO WS-LCO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-LCI-FUNCTION
               MOVE WS-INP-BODY(1:5)    TO WS-LCI-DEALER-CODE
               MOVE WS-INP-BODY(6:6)    TO WS-LCI-LOCATION-CODE
               MOVE WS-INP-BODY(12:30)  TO WS-LCI-LOCATION-DESC
               MOVE WS-INP-BODY(42:1)   TO WS-LCI-LOCATION-TYPE
               IF WS-INP-BODY(43:4) IS NUMERIC
                   MOVE WS-INP-BODY(43:4) TO WS-LCI-MAX-CAPACITY
               ELSE
                   MOVE 0 TO WS-LCI-MAX-CAPACITY
               END-IF
               MOVE WS-INP-BODY(47:1)   TO WS-LCI-ACTIVE-FLAG
               MOVE WS-INP-BODY(48:17)  TO WS-LCI-VIN
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-LCI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-LCO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-LCI-DEALER-CODE TO WS-LCO-DEALER-HDR
      *
      *    FOR ADD/UPDATE/ASSIGN - LOCATION CODE REQUIRED
      *
           IF NOT WS-LCI-INQUIRY
               IF WS-LCI-LOCATION-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOCATION CODE IS REQUIRED'
                       TO WS-LCO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    FOR ADD - VALIDATE TYPE AND CAPACITY
      *
           IF WS-LCI-ADD
               IF NOT WS-LCI-TYPE-LOT
               AND NOT WS-LCI-TYPE-SHOWROOM
               AND NOT WS-LCI-TYPE-SERVICE
               AND NOT WS-LCI-TYPE-OVERFLOW
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOCATION TYPE: L=LOT S=SHOW V=SVC O=OFLOW'
                       TO WS-LCO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
               IF WS-LCI-MAX-CAPACITY = 0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'MAX CAPACITY MUST BE GREATER THAN ZERO'
                       TO WS-LCO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
               IF WS-LCI-LOCATION-DESC = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOCATION DESCRIPTION IS REQUIRED'
                       TO WS-LCO-MSG-TEXT
               END-IF
           END-IF
      *
      *    FOR ASSIGN - VIN REQUIRED
      *
           IF WS-LCI-ASSIGN
               IF WS-LCI-VIN = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'VIN IS REQUIRED FOR LOCATION ASSIGNMENT'
                       TO WS-LCO-MSG-TEXT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LIST-LOCATIONS - DISPLAY ALL LOCATIONS FOR DEALER    *
      ****************************************************************
       4000-LIST-LOCATIONS.
      *
           EXEC SQL
               OPEN CSR_LOT_LOCS
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'VEHLOC00' TO WS-DBE-PROGRAM
               MOVE SQLCODE     TO WS-DBE-SQLCODE
               MOVE 'LOT_LOCATION'  TO WS-DBE-TABLE
               MOVE 'OPEN CURSOR'   TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                     WS-DBE-RESULT
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-DBE-MSG TO WS-LCO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-IDX
      *
           PERFORM UNTIL WS-ROW-IDX >= 10
               EXEC SQL
                   FETCH CSR_LOT_LOCS
                   INTO  :WS-LR-LOC-CODE
                       , :WS-LR-LOC-DESC
                       , :WS-LR-LOC-TYPE
                       , :WS-LR-MAX-CAP
                       , :WS-LR-CURR-COUNT
                       , :WS-LR-ACTIVE
               END-EXEC
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               IF SQLCODE NOT = +0
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-ROW-IDX
      *
               MOVE WS-LR-LOC-CODE     TO
                   WS-LCO-DT-LOC(WS-ROW-IDX)
               MOVE WS-LR-LOC-DESC-TX  TO
                   WS-LCO-DT-DESC(WS-ROW-IDX)
               MOVE WS-LR-LOC-TYPE     TO
                   WS-LCO-DT-TYPE(WS-ROW-IDX)
               MOVE WS-LR-MAX-CAP      TO
                   WS-LCO-DT-CAP(WS-ROW-IDX)
               MOVE WS-LR-CURR-COUNT   TO
                   WS-LCO-DT-COUNT(WS-ROW-IDX)
      *
               COMPUTE WS-AVAIL-NUM =
                   WS-LR-MAX-CAP - WS-LR-CURR-COUNT
               IF WS-AVAIL-NUM < +0
                   MOVE +0 TO WS-AVAIL-NUM
               END-IF
               MOVE WS-AVAIL-NUM       TO
                   WS-LCO-DT-AVAIL(WS-ROW-IDX)
               MOVE WS-LR-ACTIVE       TO
                   WS-LCO-DT-ACTIVE(WS-ROW-IDX)
           END-PERFORM
      *
           EXEC SQL
               CLOSE CSR_LOT_LOCS
           END-EXEC
      *
           IF WS-ROW-IDX = +0
               MOVE 'NO LOT LOCATIONS FOUND FOR THIS DEALER'
                   TO WS-LCO-MSG-TEXT
           ELSE
               STRING 'FOUND ' WS-ROW-IDX ' LOCATION(S)'
                      DELIMITED BY SIZE
                      INTO WS-LCO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-ADD-LOCATION - INSERT NEW LOT LOCATION               *
      ****************************************************************
       5000-ADD-LOCATION.
      *
           IF WS-LCI-ACTIVE-FLAG = SPACES
               MOVE 'Y' TO WS-LCI-ACTIVE-FLAG
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.LOT_LOCATION
                    ( DEALER_CODE
                    , LOCATION_CODE
                    , LOCATION_DESC
                    , LOCATION_TYPE
                    , MAX_CAPACITY
                    , CURRENT_COUNT
                    , ACTIVE_FLAG
                    )
               VALUES
                    ( :WS-LCI-DEALER-CODE
                    , :WS-LCI-LOCATION-CODE
                    , :WS-LCI-LOCATION-DESC
                    , :WS-LCI-LOCATION-TYPE
                    , :WS-LCI-MAX-CAPACITY
                    , 0
                    , :WS-LCI-ACTIVE-FLAG
                    )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE 'LOT LOCATION ADDED SUCCESSFULLY'
                       TO WS-LCO-MSG-TEXT
      *
      *            AUDIT LOG
      *
                   MOVE 'VEHLOC00'      TO WS-LR-PROGRAM
                   MOVE 'ADD LOC '      TO WS-LR-FUNCTION
                   MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
                   MOVE 'LOT_LOC '      TO WS-LR-ENTITY-TYPE
                   STRING WS-LCI-DEALER-CODE '/'
                          WS-LCI-LOCATION-CODE
                          DELIMITED BY SIZE
                          INTO WS-LR-ENTITY-KEY
                   STRING 'ADDED LOT LOCATION '
                          WS-LCI-LOCATION-CODE
                          ' AT DEALER ' WS-LCI-DEALER-CODE
                          DELIMITED BY SIZE
                          INTO WS-LR-DESCRIPTION
                   CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
               WHEN -803
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOCATION CODE ALREADY EXISTS AT THIS DEALER'
                       TO WS-LCO-MSG-TEXT
      *
               WHEN OTHER
                   MOVE +12 TO WS-RETURN-CODE
                   MOVE 'DB2 ERROR INSERTING LOT LOCATION'
                       TO WS-LCO-MSG-TEXT
           END-EVALUATE
           .
      *
      ****************************************************************
      *    6000-UPDATE-LOCATION - UPDATE EXISTING LOT LOCATION       *
      ****************************************************************
       6000-UPDATE-LOCATION.
      *
      *    BUILD DYNAMIC UPDATE - ONLY UPDATE NON-BLANK FIELDS
      *
           EXEC SQL
               SELECT LOCATION_DESC
                    , LOCATION_TYPE
                    , MAX_CAPACITY
                    , CURRENT_COUNT
                    , ACTIVE_FLAG
               INTO  :LOCATION-DESC OF DCLLOT-LOCATION
                    , :LOCATION-TYPE OF DCLLOT-LOCATION
                    , :MAX-CAPACITY  OF DCLLOT-LOCATION
                    , :CURRENT-COUNT OF DCLLOT-LOCATION
                    , :ACTIVE-FLAG   OF DCLLOT-LOCATION
               FROM   AUTOSALE.LOT_LOCATION
               WHERE  DEALER_CODE   = :WS-LCI-DEALER-CODE
                 AND  LOCATION_CODE = :WS-LCI-LOCATION-CODE
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LOCATION NOT FOUND' TO WS-LCO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING LOT LOCATION'
                   TO WS-LCO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    APPLY UPDATES FROM INPUT (NON-BLANK FIELDS ONLY)
      *
           IF WS-LCI-LOCATION-DESC NOT = SPACES
               MOVE WS-LCI-LOCATION-DESC TO LOCATION-DESC-TX
                   OF DCLLOT-LOCATION
               MOVE 30 TO LOCATION-DESC-LN OF DCLLOT-LOCATION
           END-IF
      *
           IF WS-LCI-LOCATION-TYPE NOT = SPACES
               MOVE WS-LCI-LOCATION-TYPE TO LOCATION-TYPE
                   OF DCLLOT-LOCATION
           END-IF
      *
           IF WS-LCI-MAX-CAPACITY > 0
               MOVE WS-LCI-MAX-CAPACITY TO MAX-CAPACITY
                   OF DCLLOT-LOCATION
           END-IF
      *
           IF WS-LCI-ACTIVE-FLAG NOT = SPACES
               MOVE WS-LCI-ACTIVE-FLAG TO ACTIVE-FLAG
                   OF DCLLOT-LOCATION
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.LOT_LOCATION
                  SET LOCATION_DESC = :LOCATION-DESC
                                       OF DCLLOT-LOCATION
                    , LOCATION_TYPE = :LOCATION-TYPE
                                       OF DCLLOT-LOCATION
                    , MAX_CAPACITY  = :MAX-CAPACITY
                                       OF DCLLOT-LOCATION
                    , ACTIVE_FLAG   = :ACTIVE-FLAG
                                       OF DCLLOT-LOCATION
               WHERE  DEALER_CODE   = :WS-LCI-DEALER-CODE
                 AND  LOCATION_CODE = :WS-LCI-LOCATION-CODE
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE 'LOT LOCATION UPDATED SUCCESSFULLY'
                   TO WS-LCO-MSG-TEXT
      *
               MOVE 'VEHLOC00'      TO WS-LR-PROGRAM
               MOVE 'UPD LOC '      TO WS-LR-FUNCTION
               MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
               MOVE 'LOT_LOC '      TO WS-LR-ENTITY-TYPE
               STRING WS-LCI-DEALER-CODE '/'
                      WS-LCI-LOCATION-CODE
                      DELIMITED BY SIZE
                      INTO WS-LR-ENTITY-KEY
               STRING 'UPDATED LOT LOCATION '
                      WS-LCI-LOCATION-CODE
                      DELIMITED BY SIZE
                      INTO WS-LR-DESCRIPTION
               CALL 'COMLGEL0' USING WS-LOG-REQUEST
           ELSE
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING LOT LOCATION'
                   TO WS-LCO-MSG-TEXT
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-ASSIGN-VEHICLE - ASSIGN VEHICLE TO LOT LOCATION      *
      ****************************************************************
       7000-ASSIGN-VEHICLE.
      *
      *    VERIFY VEHICLE EXISTS AND IS AT THIS DEALER
      *
           EXEC SQL
               SELECT VIN
                    , DEALER_CODE
                    , LOT_LOCATION
                    , VEHICLE_STATUS
               INTO  :VIN          OF DCLVEHICLE
                    , :DEALER-CODE OF DCLVEHICLE
                    , :LOT-LOCATION OF DCLVEHICLE
                    , :VEHICLE-STATUS OF DCLVEHICLE
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-LCI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND' TO WS-LCO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
           IF DEALER-CODE OF DCLVEHICLE NOT = WS-LCI-DEALER-CODE
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT AT THIS DEALER'
                   TO WS-LCO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
      *    CHECK LOT LOCATION EXISTS AND HAS CAPACITY
      *
           EXEC SQL
               SELECT MAX_CAPACITY
                    , CURRENT_COUNT
                    , ACTIVE_FLAG
               INTO  :WS-CAPACITY-NUM
                    , :WS-CURRENT-NUM
                    , :ACTIVE-FLAG OF DCLLOT-LOCATION
               FROM   AUTOSALE.LOT_LOCATION
               WHERE  DEALER_CODE   = :WS-LCI-DEALER-CODE
                 AND  LOCATION_CODE = :WS-LCI-LOCATION-CODE
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LOT LOCATION NOT FOUND'
                   TO WS-LCO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
           IF ACTIVE-FLAG OF DCLLOT-LOCATION NOT = 'Y'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LOT LOCATION IS NOT ACTIVE'
                   TO WS-LCO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
           IF WS-CURRENT-NUM >= WS-CAPACITY-NUM
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LOT LOCATION IS AT FULL CAPACITY'
                   TO WS-LCO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
      *    DECREMENT OLD LOCATION COUNT IF VEHICLE HAD ONE
      *
           IF LOT-LOCATION OF DCLVEHICLE NOT = SPACES
               EXEC SQL
                   UPDATE AUTOSALE.LOT_LOCATION
                      SET CURRENT_COUNT = CURRENT_COUNT - 1
                   WHERE  DEALER_CODE   = :WS-LCI-DEALER-CODE
                     AND  LOCATION_CODE = :LOT-LOCATION
                                           OF DCLVEHICLE
                     AND  CURRENT_COUNT > 0
               END-EXEC
           END-IF
      *
      *    UPDATE VEHICLE WITH NEW LOCATION
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET LOT_LOCATION = :WS-LCI-LOCATION-CODE
                    , UPDATED_TS   = CURRENT TIMESTAMP
               WHERE  VIN = :WS-LCI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING VEHICLE LOCATION'
                   TO WS-LCO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
      *    INCREMENT NEW LOCATION COUNT
      *
           EXEC SQL
               UPDATE AUTOSALE.LOT_LOCATION
                  SET CURRENT_COUNT = CURRENT_COUNT + 1
               WHERE  DEALER_CODE   = :WS-LCI-DEALER-CODE
                 AND  LOCATION_CODE = :WS-LCI-LOCATION-CODE
           END-EXEC
      *
      *    FORMAT OUTPUT
      *
           MOVE 'VEHICLE ASSIGNED TO LOT LOCATION SUCCESSFULLY'
               TO WS-LCO-MSG-TEXT
           MOVE WS-LCI-LOCATION-CODE TO WS-LCO-ASGN-LOC
           MOVE WS-LCI-VIN           TO WS-LCO-ASGN-VIN
      *
      *    AUDIT LOG
      *
           MOVE 'VEHLOC00'      TO WS-LR-PROGRAM
           MOVE 'ASSIGN  '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-LCI-VIN      TO WS-LR-ENTITY-KEY
           STRING 'ASSIGNED TO LOT '
                  WS-LCI-LOCATION-CODE
                  ' AT DEALER ' WS-LCI-DEALER-CODE
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
       7000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-LOC-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHLOC00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHLOC00                                              *
      ****************************************************************
