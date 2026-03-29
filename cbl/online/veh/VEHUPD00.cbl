       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHUPD00.
      ****************************************************************
      * PROGRAM:  VEHUPD00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - VEHICLE STATUS UPDATE                    *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ALLOWS MANUAL STATUS CHANGE WITH REASON CODE.      *
      *           VALIDATES STATUS TRANSITIONS (E.G., CAN'T GO       *
      *           FROM SD BACK TO AV WITHOUT UNWIND). INSERTS        *
      *           VEHICLE_STATUS_HIST RECORD FOR AUDIT TRAIL.        *
      *           NOTIFIES STOCK MODULE OF STATUS CHANGE.            *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHUP - VEHICLE STATUS UPDATE                       *
      * STATUS CODES:                                                *
      *   PR = PRODUCED   AL = ALLOCATED  IT = IN TRANSIT            *
      *   DL = DELIVERED  AV = AVAILABLE  HD = ON HOLD               *
      *   SD = SOLD       TR = TRANSFER   SV = SERVICE               *
      *   WO = WRITE-OFF  RJ = REJECTED                              *
      * CALLS:    COMSTCK0 - STOCK UPDATE (APPROPRIATE FUNCTION)     *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.VEHICLE                                   *
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
                                          VALUE 'VEHUPD00'.
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
           COPY DCLVEHCL.
      *
           COPY DCLVHSTH.
      *
      *    INPUT FIELDS
      *
       01  WS-UPD-INPUT.
           05  WS-UI-FUNCTION            PIC X(02).
               88  WS-UI-UPDATE                     VALUE 'UP'.
               88  WS-UI-INQUIRY                    VALUE 'IQ'.
           05  WS-UI-VIN                 PIC X(17).
           05  WS-UI-NEW-STATUS          PIC X(02).
           05  WS-UI-REASON              PIC X(60).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-UPD-OUTPUT.
           05  WS-UO-STATUS-LINE.
               10  WS-UO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-UO-MSG-TEXT       PIC X(70).
           05  WS-UO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-UO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-UO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'STOCK NO: '.
               10  WS-UO-STOCK-NUM      PIC X(08).
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-UO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-UO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-UO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-UO-MODEL          PIC X(06).
               10  FILLER               PIC X(43) VALUE SPACES.
           05  WS-UO-STATUS-CHANGE.
               10  FILLER               PIC X(12)
                   VALUE 'OLD STATUS: '.
               10  WS-UO-OLD-STATUS     PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(03) VALUE '>> '.
               10  FILLER               PIC X(12)
                   VALUE 'NEW STATUS: '.
               10  WS-UO-NEW-STATUS     PIC X(02).
               10  FILLER               PIC X(44) VALUE SPACES.
           05  WS-UO-REASON-LINE.
               10  FILLER               PIC X(08) VALUE 'REASON: '.
               10  WS-UO-REASON         PIC X(60).
               10  FILLER               PIC X(11) VALUE SPACES.
           05  WS-UO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-UO-TRANS-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- VALID STATUS TRANSITIONS ----      '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-UO-TRANS-LINES.
               10  FILLER               PIC X(79)
                   VALUE 'PR >> AL IT     AL >> DL AV IT    IT '
                        & '>> DL AV                                '.
               10  FILLER               PIC X(79)
                   VALUE 'DL >> AV        AV >> HD SD TR SV  HD '
                        & '>> AV                                   '.
               10  FILLER               PIC X(79)
                   VALUE 'SD >> (UNWIND)  TR >> AV           SV '
                        & '>> AV                                   '.
               10  FILLER               PIC X(79)
                   VALUE 'ANY >> WO RJ (MANAGER OVERRIDE)        '
                        & '                                        '.
           05  WS-UO-FILLER             PIC X(1024) VALUE SPACES.
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
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-OLD-STATUS            PIC X(02) VALUE SPACES.
           05  WS-TRANSITION-VALID      PIC X(01) VALUE 'N'.
               88  WS-TRANS-OK                     VALUE 'Y'.
               88  WS-TRANS-INVALID                VALUE 'N'.
           05  WS-STK-FUNCTION          PIC X(04) VALUE SPACES.
           05  WS-HIST-SEQ              PIC S9(09) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-REASON             PIC S9(04) COMP VALUE +0.
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
           AND WS-UI-UPDATE
               PERFORM 5000-VALIDATE-TRANSITION
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-UI-UPDATE
               PERFORM 6000-APPLY-STATUS-CHANGE
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-UI-UPDATE
               PERFORM 7000-UPDATE-STOCK-MODULE
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
           INITIALIZE WS-UPD-OUTPUT
           MOVE 'VEHUPD00' TO WS-UO-MSG-ID
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
               MOVE 'IMS GU FAILED' TO WS-UO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION    TO WS-UI-FUNCTION
               MOVE WS-INP-BODY(1:17)  TO WS-UI-VIN
               MOVE WS-INP-BODY(18:2)  TO WS-UI-NEW-STATUS
               MOVE WS-INP-BODY(20:60) TO WS-UI-REASON
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-UI-VIN = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN IS REQUIRED' TO WS-UO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-UI-UPDATE
               IF WS-UI-NEW-STATUS = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'NEW STATUS CODE IS REQUIRED FOR UPDATE'
                       TO WS-UO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
               IF WS-UI-REASON = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'REASON IS REQUIRED FOR STATUS CHANGE'
                       TO WS-UO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
      *        VALIDATE STATUS CODE IS RECOGNIZED
      *
               IF WS-UI-NEW-STATUS NOT = 'PR'
               AND WS-UI-NEW-STATUS NOT = 'AL'
               AND WS-UI-NEW-STATUS NOT = 'IT'
               AND WS-UI-NEW-STATUS NOT = 'DL'
               AND WS-UI-NEW-STATUS NOT = 'AV'
               AND WS-UI-NEW-STATUS NOT = 'HD'
               AND WS-UI-NEW-STATUS NOT = 'SD'
               AND WS-UI-NEW-STATUS NOT = 'TR'
               AND WS-UI-NEW-STATUS NOT = 'SV'
               AND WS-UI-NEW-STATUS NOT = 'WO'
               AND WS-UI-NEW-STATUS NOT = 'RJ'
                   MOVE +8 TO WS-RETURN-CODE
                   STRING 'INVALID STATUS CODE: '
                          WS-UI-NEW-STATUS
                          DELIMITED BY SIZE
                          INTO WS-UO-MSG-TEXT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-VEHICLE - GET CURRENT VEHICLE DATA            *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , VEHICLE_STATUS
                    , DEALER_CODE
                    , STOCK_NUMBER
               INTO  :VIN            OF DCLVEHICLE
                    , :MODEL-YEAR    OF DCLVEHICLE
                    , :MAKE-CODE     OF DCLVEHICLE
                    , :MODEL-CODE    OF DCLVEHICLE
                    , :VEHICLE-STATUS
                    , :DEALER-CODE   OF DCLVEHICLE
                    , :STOCK-NUMBER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-UI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND' TO WS-UO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING VEHICLE'
                   TO WS-UO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE VEHICLE-STATUS TO WS-OLD-STATUS
      *
      *    POPULATE OUTPUT FIELDS
      *
           MOVE VIN OF DCLVEHICLE         TO WS-UO-VIN
           MOVE STOCK-NUMBER              TO WS-UO-STOCK-NUM
           MOVE MODEL-YEAR OF DCLVEHICLE  TO WS-UO-YEAR
           MOVE MAKE-CODE OF DCLVEHICLE   TO WS-UO-MAKE
           MOVE MODEL-CODE OF DCLVEHICLE  TO WS-UO-MODEL
           MOVE WS-OLD-STATUS             TO WS-UO-OLD-STATUS
      *
           IF WS-UI-INQUIRY
               MOVE 'VEHICLE STATUS INQUIRY COMPLETE'
                   TO WS-UO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-VALIDATE-TRANSITION - CHECK ALLOWED TRANSITIONS      *
      ****************************************************************
       5000-VALIDATE-TRANSITION.
      *
           MOVE 'N' TO WS-TRANSITION-VALID
           MOVE SPACES TO WS-STK-FUNCTION
      *
      *    EVALUATE CURRENT STATUS AND ALLOWED NEXT STATES
      *
           EVALUATE WS-OLD-STATUS
               WHEN 'PR'
      *            PRODUCED: CAN GO TO ALLOCATED OR IN-TRANSIT
                   IF WS-UI-NEW-STATUS = 'AL'
                   OR WS-UI-NEW-STATUS = 'IT'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       IF WS-UI-NEW-STATUS = 'AL'
                           MOVE 'ALOC' TO WS-STK-FUNCTION
                       END-IF
                   END-IF
      *
               WHEN 'AL'
      *            ALLOCATED: CAN GO TO DELIVERED, AVAILABLE, TRANSIT
                   IF WS-UI-NEW-STATUS = 'DL'
                   OR WS-UI-NEW-STATUS = 'AV'
                   OR WS-UI-NEW-STATUS = 'IT'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       IF WS-UI-NEW-STATUS = 'AV'
                           MOVE 'RECV' TO WS-STK-FUNCTION
                       END-IF
                   END-IF
      *
               WHEN 'IT'
      *            IN TRANSIT: CAN GO TO DELIVERED OR AVAILABLE
                   IF WS-UI-NEW-STATUS = 'DL'
                   OR WS-UI-NEW-STATUS = 'AV'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       MOVE 'RECV' TO WS-STK-FUNCTION
                   END-IF
      *
               WHEN 'DL'
      *            DELIVERED: CAN GO TO AVAILABLE
                   IF WS-UI-NEW-STATUS = 'AV'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       MOVE 'RECV' TO WS-STK-FUNCTION
                   END-IF
      *
               WHEN 'AV'
      *            AVAILABLE: CAN GO TO HOLD, SOLD, TRANSFER, SERVICE
                   IF WS-UI-NEW-STATUS = 'HD'
                   OR WS-UI-NEW-STATUS = 'SD'
                   OR WS-UI-NEW-STATUS = 'TR'
                   OR WS-UI-NEW-STATUS = 'SV'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       EVALUATE WS-UI-NEW-STATUS
                           WHEN 'HD'  MOVE 'HOLD' TO WS-STK-FUNCTION
                           WHEN 'SD'  MOVE 'SOLD' TO WS-STK-FUNCTION
                           WHEN 'TR'  MOVE 'TRNO' TO WS-STK-FUNCTION
                       END-EVALUATE
                   END-IF
      *
               WHEN 'HD'
      *            ON HOLD: CAN GO BACK TO AVAILABLE
                   IF WS-UI-NEW-STATUS = 'AV'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       MOVE 'RLSE' TO WS-STK-FUNCTION
                   END-IF
      *
               WHEN 'TR'
      *            TRANSFER: CAN GO TO AVAILABLE (AT NEW DEALER)
                   IF WS-UI-NEW-STATUS = 'AV'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                       MOVE 'TRNI' TO WS-STK-FUNCTION
                   END-IF
      *
               WHEN 'SV'
      *            IN SERVICE: CAN GO BACK TO AVAILABLE
                   IF WS-UI-NEW-STATUS = 'AV'
                       MOVE 'Y' TO WS-TRANSITION-VALID
                   END-IF
      *
               WHEN 'SD'
      *            SOLD: CANNOT GO BACK WITHOUT UNWIND PROCESS
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'SOLD STATUS REQUIRES DEAL UNWIND PROCESS'
                       TO WS-UO-MSG-TEXT
                   GO TO 5000-EXIT
           END-EVALUATE
      *
      *    MANAGER OVERRIDE: WO AND RJ ALLOWED FROM ANY STATUS
      *
           IF WS-UI-NEW-STATUS = 'WO'
           OR WS-UI-NEW-STATUS = 'RJ'
               MOVE 'Y' TO WS-TRANSITION-VALID
           END-IF
      *
           IF WS-TRANS-INVALID
               MOVE +8 TO WS-RETURN-CODE
               STRING 'INVALID TRANSITION FROM '
                      WS-OLD-STATUS
                      ' TO '
                      WS-UI-NEW-STATUS
                      DELIMITED BY SIZE
                      INTO WS-UO-MSG-TEXT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-APPLY-STATUS-CHANGE - UPDATE VEHICLE AND HISTORY     *
      ****************************************************************
       6000-APPLY-STATUS-CHANGE.
      *
      *    UPDATE VEHICLE STATUS
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = :WS-UI-NEW-STATUS
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :WS-UI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING VEHICLE STATUS'
                   TO WS-UO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    GET NEXT HISTORY SEQUENCE
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO   :WS-HIST-SEQ
               FROM   AUTOSALE.VEHICLE_STATUS_HIST
               WHERE  VIN = :WS-UI-VIN
           END-EXEC
      *
      *    SET NULL INDICATOR FOR REASON
      *
           IF WS-UI-REASON = SPACES
               MOVE -1 TO WS-NI-REASON
           ELSE
               MOVE +0 TO WS-NI-REASON
           END-IF
      *
      *    INSERT STATUS HISTORY
      *
           EXEC SQL
               INSERT INTO AUTOSALE.VEHICLE_STATUS_HIST
                    ( VIN
                    , STATUS_SEQ
                    , OLD_STATUS
                    , NEW_STATUS
                    , CHANGED_BY
                    , CHANGE_REASON
                    , CHANGED_TS
                    )
               VALUES
                    ( :WS-UI-VIN
                    , :WS-HIST-SEQ
                    , :WS-OLD-STATUS
                    , :WS-UI-NEW-STATUS
                    , :IO-PCB-USER-ID
                    , :WS-UI-REASON :WS-NI-REASON
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: STATUS HISTORY INSERT FAILED'
                   TO WS-UO-MSG-TEXT
           END-IF
      *
      *    FORMAT SUCCESS OUTPUT
      *
           MOVE WS-UI-NEW-STATUS TO WS-UO-NEW-STATUS
           MOVE WS-UI-REASON     TO WS-UO-REASON
      *
           IF WS-RETURN-CODE = +0
               STRING 'STATUS CHANGED FROM ' WS-OLD-STATUS
                      ' TO ' WS-UI-NEW-STATUS ' SUCCESSFULLY'
                      DELIMITED BY SIZE
                      INTO WS-UO-MSG-TEXT
           END-IF
      *
      *    WRITE AUDIT LOG
      *
           MOVE 'VEHUPD00'      TO WS-LR-PROGRAM
           MOVE 'STSCHNG '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-UI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'STATUS ' WS-OLD-STATUS ' >> '
                  WS-UI-NEW-STATUS ': '
                  WS-UI-REASON
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-UPDATE-STOCK-MODULE - NOTIFY COMSTCK0                *
      ****************************************************************
       7000-UPDATE-STOCK-MODULE.
      *
           IF WS-STK-FUNCTION = SPACES
               GO TO 7000-EXIT
           END-IF
      *
           MOVE WS-STK-FUNCTION     TO WS-SR-FUNCTION
           MOVE DEALER-CODE OF DCLVEHICLE
                                    TO WS-SR-DEALER-CODE
           MOVE WS-UI-VIN           TO WS-SR-VIN
           MOVE IO-PCB-USER-ID      TO WS-SR-USER-ID
           STRING 'MANUAL STATUS CHANGE: ' WS-UI-REASON
                  DELIMITED BY SIZE
                  INTO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           IF WS-RS-RETURN-CODE > +4
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'STATUS CHANGED BUT STOCK UPDATE WARNING'
                   TO WS-UO-MSG-TEXT
           END-IF
           .
       7000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-UPD-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHUPD00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHUPD00                                              *
      ****************************************************************
