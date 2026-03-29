       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMSTCK0.
      ****************************************************************
      * PROGRAM:  COMSTCK0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - STOCK COUNT UPDATE MODULE                 *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  UPDATES STOCK POSITION COUNTS AND VEHICLE STATUS   *
      *           FOR ALL INVENTORY MOVEMENTS (RECEIVE, SELL, HOLD,  *
      *           RELEASE, TRANSFER IN/OUT, ALLOCATE). INSERTS       *
      *           VEHICLE_STATUS_HIST FOR AUDIT TRAIL.               *
      * CALLABLE: YES - VIA CALL 'COMSTCK0' USING LS-STK-REQUEST    *
      *                                            LS-STK-RESULT     *
      * FUNCTIONS:                                                   *
      *   RECV - VEHICLE RECEIVED INTO INVENTORY                     *
      *   SOLD - VEHICLE SOLD                                        *
      *   HOLD - PUT VEHICLE ON HOLD                                 *
      *   RLSE - RELEASE VEHICLE FROM HOLD                           *
      *   TRNI - TRANSFER IN (FROM ANOTHER DEALER)                   *
      *   TRNO - TRANSFER OUT (TO ANOTHER DEALER)                    *
      *   ALOC - ALLOCATE VEHICLE TO CUSTOMER                        *
      * TABLES:   AUTOSALE.STOCK_POSITION                            *
      *           AUTOSALE.VEHICLE                                   *
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
                                          VALUE 'COMSTCK0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    COPY IN SQLCA
      *
           COPY WSSQLCA.
      *
      *    COPY IN DCLGEN FOR STOCK_POSITION
      *
           COPY DCLSTKPS.
      *
      *    COPY IN DCLGEN FOR VEHICLE_STATUS_HIST
      *
           COPY DCLVHSTH.
      *
      *    COPY IN DCLGEN FOR VEHICLE
      *
           COPY DCLVEHCL.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-OLD-STATUS             PIC X(02)    VALUE SPACES.
           05  WS-NEW-STATUS             PIC X(02)    VALUE SPACES.
           05  WS-NEXT-SEQ               PIC S9(09)   COMP
                                                       VALUE +0.
           05  WS-MAKE-CODE-WORK         PIC X(03)    VALUE SPACES.
           05  WS-MODEL-CODE-WORK        PIC X(06)    VALUE SPACES.
           05  WS-MODEL-YEAR-WORK        PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-VEH-FOUND-FLAG         PIC X(01)    VALUE 'N'.
               88  WS-VEH-FOUND                       VALUE 'Y'.
               88  WS-VEH-NOT-FOUND                   VALUE 'N'.
      *
      *    DATE/TIME FIELDS
      *
       01  WS-DATETIME-FIELDS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURR-YYYY          PIC 9(04).
               10  WS-CURR-MM            PIC 9(02).
               10  WS-CURR-DD            PIC 9(02).
           05  WS-CURRENT-TIME-DATA.
               10  WS-CURR-HH            PIC 9(02).
               10  WS-CURR-MN            PIC 9(02).
               10  WS-CURR-SS            PIC 9(02).
               10  WS-CURR-HS            PIC 9(02).
           05  WS-DIFF-FROM-GMT          PIC S9(04).
           05  WS-FORMATTED-TS           PIC X(26)    VALUE SPACES.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-CHANGE-REASON       PIC S9(04)   COMP
                                                       VALUE +0.
      *
       LINKAGE SECTION.
      *
      *    STOCK UPDATE REQUEST
      *
       01  LS-STK-REQUEST.
           05  LS-SR-FUNCTION            PIC X(04).
               88  LS-SR-RECEIVE                       VALUE 'RECV'.
               88  LS-SR-SOLD                          VALUE 'SOLD'.
               88  LS-SR-HOLD                          VALUE 'HOLD'.
               88  LS-SR-RELEASE                       VALUE 'RLSE'.
               88  LS-SR-TRANSFER-IN                   VALUE 'TRNI'.
               88  LS-SR-TRANSFER-OUT                  VALUE 'TRNO'.
               88  LS-SR-ALLOCATE                      VALUE 'ALOC'.
           05  LS-SR-DEALER-CODE         PIC X(05).
           05  LS-SR-VIN                 PIC X(17).
           05  LS-SR-USER-ID             PIC X(08).
           05  LS-SR-REASON              PIC X(60).
      *
      *    STOCK UPDATE RESULT
      *
       01  LS-STK-RESULT.
           05  LS-RS-RETURN-CODE         PIC S9(04)   COMP.
           05  LS-RS-RETURN-MSG          PIC X(79).
           05  LS-RS-OLD-STATUS          PIC X(02).
           05  LS-RS-NEW-STATUS          PIC X(02).
           05  LS-RS-ON-HAND             PIC S9(04)   COMP.
           05  LS-RS-IN-TRANSIT          PIC S9(04)   COMP.
           05  LS-RS-ALLOCATED           PIC S9(04)   COMP.
           05  LS-RS-ON-HOLD             PIC S9(04)   COMP.
           05  LS-RS-SOLD-MTD            PIC S9(04)   COMP.
           05  LS-RS-SOLD-YTD            PIC S9(04)   COMP.
           05  LS-RS-SQLCODE             PIC S9(09)   COMP.
      *
       PROCEDURE DIVISION USING LS-STK-REQUEST
                                LS-STK-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-VALIDATE-INPUTS
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 3000-LOOKUP-VEHICLE
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 4000-PROCESS-FUNCTION
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 5000-UPDATE-STOCK-POSITION
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 6000-UPDATE-VEHICLE-STATUS
           END-IF
      *
           IF LS-RS-RETURN-CODE = +0
               PERFORM 7000-INSERT-STATUS-HISTORY
           END-IF
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR RESULT AND GET TIMESTAMP          *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-STK-RESULT
           MOVE +0 TO LS-RS-RETURN-CODE
           MOVE 'N' TO WS-VEH-FOUND-FLAG
      *
           MOVE FUNCTION CURRENT-DATE
               TO WS-CURRENT-DATE-DATA
                  WS-CURRENT-TIME-DATA
                  WS-DIFF-FROM-GMT
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD   '-'
                  WS-CURR-HH   '.'
                  WS-CURR-MN   '.'
                  WS-CURR-SS   '.000000'
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-TS
           .
      *
      ****************************************************************
      *    2000-VALIDATE-INPUTS - VALIDATE REQUEST PARAMETERS        *
      ****************************************************************
       2000-VALIDATE-INPUTS.
      *
           IF  NOT LS-SR-RECEIVE
           AND NOT LS-SR-SOLD
           AND NOT LS-SR-HOLD
           AND NOT LS-SR-RELEASE
           AND NOT LS-SR-TRANSFER-IN
           AND NOT LS-SR-TRANSFER-OUT
           AND NOT LS-SR-ALLOCATE
               MOVE +8 TO LS-RS-RETURN-CODE
               STRING 'COMSTCK0: INVALID FUNCTION: '
                      LS-SR-FUNCTION
                      DELIMITED BY SIZE
                      INTO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-SR-DEALER-CODE = SPACES
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: DEALER CODE IS REQUIRED'
                   TO LS-RS-RETURN-MSG
           END-IF
      *
           IF LS-SR-VIN = SPACES
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: VIN IS REQUIRED'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    3000-LOOKUP-VEHICLE - GET VEHICLE DETAILS FOR STOCK       *
      ****************************************************************
       3000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , MAKE_CODE
                    , MODEL_CODE
                    , MODEL_YEAR
               INTO  :VEHICLE-STATUS
                    , :MAKE-CODE
                    , :MODEL-CODE
                    , :MODEL-YEAR
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :LS-SR-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE 'Y' TO WS-VEH-FOUND-FLAG
                   MOVE VEHICLE-STATUS TO WS-OLD-STATUS
                   MOVE MAKE-CODE      TO WS-MAKE-CODE-WORK
                   MOVE MODEL-CODE     TO WS-MODEL-CODE-WORK
                   MOVE MODEL-YEAR     TO WS-MODEL-YEAR-WORK
                   MOVE VEHICLE-STATUS TO LS-RS-OLD-STATUS
               WHEN +100
                   MOVE +8 TO LS-RS-RETURN-CODE
                   MOVE 'COMSTCK0: VEHICLE NOT FOUND FOR VIN'
                       TO LS-RS-RETURN-MSG
               WHEN OTHER
                   MOVE SQLCODE TO LS-RS-SQLCODE
                   MOVE +16 TO LS-RS-RETURN-CODE
                   MOVE 'COMSTCK0: DB2 ERROR READING VEHICLE'
                       TO LS-RS-RETURN-MSG
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4000-PROCESS-FUNCTION - DETERMINE STATUS TRANSITIONS      *
      ****************************************************************
       4000-PROCESS-FUNCTION.
      *
           EVALUATE TRUE
               WHEN LS-SR-RECEIVE
      *            RECEIVE INTO INVENTORY: SET AVAILABLE
                   MOVE 'AV' TO WS-NEW-STATUS
      *            VALIDATE: SHOULD NOT ALREADY BE AVAILABLE
                   IF WS-OLD-STATUS = 'AV'
                       MOVE +4 TO LS-RS-RETURN-CODE
                       MOVE
                       'COMSTCK0: WARNING - VEHICLE ALREADY AVAILABLE'
                           TO LS-RS-RETURN-MSG
                   END-IF
      *
               WHEN LS-SR-SOLD
      *            SOLD: SET TO SOLD STATUS
                   MOVE 'SD' TO WS-NEW-STATUS
      *            VALIDATE: MUST BE AVAILABLE OR ALLOCATED
                   IF WS-OLD-STATUS NOT = 'AV'
                   AND WS-OLD-STATUS NOT = 'AL'
                       MOVE +8 TO LS-RS-RETURN-CODE
                       MOVE
                       'COMSTCK0: VEHICLE MUST BE AV OR AL TO SELL'
                           TO LS-RS-RETURN-MSG
                   END-IF
      *
               WHEN LS-SR-HOLD
      *            HOLD: SET TO HOLD STATUS
                   MOVE 'HD' TO WS-NEW-STATUS
                   IF WS-OLD-STATUS NOT = 'AV'
                       MOVE +8 TO LS-RS-RETURN-CODE
                       MOVE
                       'COMSTCK0: VEHICLE MUST BE AV TO PUT ON HOLD'
                           TO LS-RS-RETURN-MSG
                   END-IF
      *
               WHEN LS-SR-RELEASE
      *            RELEASE FROM HOLD: SET BACK TO AVAILABLE
                   MOVE 'AV' TO WS-NEW-STATUS
                   IF WS-OLD-STATUS NOT = 'HD'
                       MOVE +8 TO LS-RS-RETURN-CODE
                       MOVE
                       'COMSTCK0: VEHICLE MUST BE HD TO RELEASE'
                           TO LS-RS-RETURN-MSG
                   END-IF
      *
               WHEN LS-SR-TRANSFER-IN
      *            TRANSFER IN: SET TO AVAILABLE
                   MOVE 'AV' TO WS-NEW-STATUS
                   IF WS-OLD-STATUS NOT = 'IT'
                       MOVE +4 TO LS-RS-RETURN-CODE
                       MOVE
                    'COMSTCK0: WARNING - EXPECTED IN-TRANSIT STATUS'
                           TO LS-RS-RETURN-MSG
                   END-IF
      *
               WHEN LS-SR-TRANSFER-OUT
      *            TRANSFER OUT: SET TO IN-TRANSIT
                   MOVE 'IT' TO WS-NEW-STATUS
                   IF WS-OLD-STATUS NOT = 'AV'
                       MOVE +8 TO LS-RS-RETURN-CODE
                       MOVE
                       'COMSTCK0: VEHICLE MUST BE AV TO TRANSFER OUT'
                           TO LS-RS-RETURN-MSG
                   END-IF
      *
               WHEN LS-SR-ALLOCATE
      *            ALLOCATE: SET TO ALLOCATED
                   MOVE 'AL' TO WS-NEW-STATUS
                   IF WS-OLD-STATUS NOT = 'AV'
                       MOVE +8 TO LS-RS-RETURN-CODE
                       MOVE
                       'COMSTCK0: VEHICLE MUST BE AV TO ALLOCATE'
                           TO LS-RS-RETURN-MSG
                   END-IF
           END-EVALUATE
      *
           MOVE WS-NEW-STATUS TO LS-RS-NEW-STATUS
           .
      *
      ****************************************************************
      *    5000-UPDATE-STOCK-POSITION - UPDATE COUNTS IN DB2         *
      ****************************************************************
       5000-UPDATE-STOCK-POSITION.
      *
      *    READ CURRENT STOCK POSITION
      *
           EXEC SQL
               SELECT ON_HAND_COUNT
                    , IN_TRANSIT_COUNT
                    , ALLOCATED_COUNT
                    , ON_HOLD_COUNT
                    , SOLD_MTD
                    , SOLD_YTD
               INTO  :ON-HAND-COUNT
                    , :IN-TRANSIT-COUNT
                    , :ALLOCATED-COUNT
                    , :ON-HOLD-COUNT
                    , :SOLD-MTD
                    , :SOLD-YTD
               FROM   AUTOSALE.STOCK_POSITION
               WHERE  DEALER_CODE = :LS-SR-DEALER-CODE
                 AND  MODEL_YEAR  = :WS-MODEL-YEAR-WORK
                 AND  MAKE_CODE   = :WS-MAKE-CODE-WORK
                 AND  MODEL_CODE  = :WS-MODEL-CODE-WORK
               FOR UPDATE
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO LS-RS-SQLCODE
               MOVE +12 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: STOCK POSITION ROW NOT FOUND'
                   TO LS-RS-RETURN-MSG
               GOBACK
           END-IF
      *
      *    APPLY COUNT CHANGES BASED ON FUNCTION
      *
           EVALUATE TRUE
               WHEN LS-SR-RECEIVE
                   ADD +1 TO ON-HAND-COUNT
      *
               WHEN LS-SR-SOLD
                   SUBTRACT +1 FROM ON-HAND-COUNT
                   ADD +1 TO SOLD-MTD
                   ADD +1 TO SOLD-YTD
      *
               WHEN LS-SR-HOLD
                   SUBTRACT +1 FROM ON-HAND-COUNT
                   ADD +1 TO ON-HOLD-COUNT
      *
               WHEN LS-SR-RELEASE
                   ADD +1 TO ON-HAND-COUNT
                   SUBTRACT +1 FROM ON-HOLD-COUNT
      *
               WHEN LS-SR-TRANSFER-IN
                   ADD +1 TO ON-HAND-COUNT
                   SUBTRACT +1 FROM IN-TRANSIT-COUNT
      *
               WHEN LS-SR-TRANSFER-OUT
                   SUBTRACT +1 FROM ON-HAND-COUNT
      *
               WHEN LS-SR-ALLOCATE
                   ADD +1 TO ALLOCATED-COUNT
           END-EVALUATE
      *
      *    PREVENT NEGATIVE COUNTS
      *
           IF ON-HAND-COUNT < +0
               MOVE +0 TO ON-HAND-COUNT
           END-IF
           IF IN-TRANSIT-COUNT < +0
               MOVE +0 TO IN-TRANSIT-COUNT
           END-IF
           IF ON-HOLD-COUNT < +0
               MOVE +0 TO ON-HOLD-COUNT
           END-IF
      *
      *    UPDATE THE ROW
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_POSITION
                  SET ON_HAND_COUNT    = :ON-HAND-COUNT
                    , IN_TRANSIT_COUNT = :IN-TRANSIT-COUNT
                    , ALLOCATED_COUNT  = :ALLOCATED-COUNT
                    , ON_HOLD_COUNT    = :ON-HOLD-COUNT
                    , SOLD_MTD         = :SOLD-MTD
                    , SOLD_YTD         = :SOLD-YTD
                    , UPDATED_TS       = CURRENT TIMESTAMP
               WHERE  DEALER_CODE      = :LS-SR-DEALER-CODE
                 AND  MODEL_YEAR       = :WS-MODEL-YEAR-WORK
                 AND  MAKE_CODE        = :WS-MAKE-CODE-WORK
                 AND  MODEL_CODE       = :WS-MODEL-CODE-WORK
           END-EXEC
      *
           IF SQLCODE = +0
      *        RETURN UPDATED COUNTS
               MOVE ON-HAND-COUNT    TO LS-RS-ON-HAND
               MOVE IN-TRANSIT-COUNT TO LS-RS-IN-TRANSIT
               MOVE ALLOCATED-COUNT  TO LS-RS-ALLOCATED
               MOVE ON-HOLD-COUNT    TO LS-RS-ON-HOLD
               MOVE SOLD-MTD         TO LS-RS-SOLD-MTD
               MOVE SOLD-YTD         TO LS-RS-SOLD-YTD
           ELSE
               MOVE SQLCODE TO LS-RS-SQLCODE
               MOVE +12 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: ERROR UPDATING STOCK_POSITION'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    6000-UPDATE-VEHICLE-STATUS - UPDATE VEHICLE TABLE         *
      ****************************************************************
       6000-UPDATE-VEHICLE-STATUS.
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = :WS-NEW-STATUS
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN            = :LS-SR-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO LS-RS-SQLCODE
               MOVE +12 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: ERROR UPDATING VEHICLE STATUS'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    7000-INSERT-STATUS-HISTORY - AUDIT TRAIL ROW              *
      ****************************************************************
       7000-INSERT-STATUS-HISTORY.
      *
      *    GET NEXT SEQUENCE NUMBER FOR HIST
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO   :WS-NEXT-SEQ
               FROM   AUTOSALE.VEHICLE_STATUS_HIST
               WHERE  VIN = :LS-SR-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               MOVE SQLCODE TO LS-RS-SQLCODE
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: ERROR GETTING HIST SEQUENCE'
                   TO LS-RS-RETURN-MSG
               GOBACK
           END-IF
      *
      *    SET UP NULL INDICATOR FOR REASON
      *
           IF LS-SR-REASON = SPACES
               MOVE -1 TO WS-NI-CHANGE-REASON
           ELSE
               MOVE +0 TO WS-NI-CHANGE-REASON
           END-IF
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
                    ( :LS-SR-VIN
                    , :WS-NEXT-SEQ
                    , :WS-OLD-STATUS
                    , :WS-NEW-STATUS
                    , :LS-SR-USER-ID
                    , :LS-SR-REASON
                       :WS-NI-CHANGE-REASON
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE +0 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: STOCK UPDATE COMPLETED SUCCESSFULLY'
                   TO LS-RS-RETURN-MSG
           ELSE
               MOVE SQLCODE TO LS-RS-SQLCODE
               MOVE +8 TO LS-RS-RETURN-CODE
               MOVE 'COMSTCK0: ERROR INSERTING STATUS HISTORY'
                   TO LS-RS-RETURN-MSG
           END-IF
           .
      ****************************************************************
      * END OF COMSTCK0                                               *
      ****************************************************************
