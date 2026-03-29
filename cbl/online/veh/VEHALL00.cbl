       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHALL00.
      ****************************************************************
      * PROGRAM:  VEHALL00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - VEHICLE ALLOCATION FROM MANUFACTURER     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  RECEIVES ALLOCATION DATA FROM PRODUCTION SYSTEM    *
      *           (ONLINE ENTRY OR FROM PLIPROD0 BATCH). ASSIGNS     *
      *           PRODUCED VEHICLES TO DEALER ORDERS BASED ON        *
      *           PRIORITY AND REGION. UPDATES PRODUCTION_ORDER      *
      *           ALLOCATED_DEALER AND VEHICLE.DEALER_CODE FIELDS.   *
      *           CHANGES VEHICLE_STATUS FROM PR (PRODUCED) TO       *
      *           AL (ALLOCATED).                                    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHAL - VEHICLE ALLOCATION                          *
      * MFS:     INPUT  - MFSVEHIN (SHARED VEHICLE INPUT)           *
      *          OUTPUT - MFSVEHIN (SHARED VEHICLE OUTPUT)          *
      * CALLS:    COMVALD0 - VIN VALIDATION                          *
      *           COMSTCK0 - STOCK UPDATE (ALOC FUNCTION)            *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.PRODUCTION_ORDER                          *
      *           AUTOSALE.VEHICLE                                   *
      *           AUTOSALE.DEALER                                    *
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
                                          VALUE 'VEHALL00'.
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
      *    COPY IN IMS I/O PCB MASK
      *
           COPY WSIOPCB.
      *
      *    COPY IN MESSAGE FORMAT AREAS
      *
           COPY WSMSGFMT.
      *
      *    COPY IN DCLGEN FOR PRODUCTION_ORDER
      *
           COPY DCLPRORD.
      *
      *    COPY IN DCLGEN FOR VEHICLE
      *
           COPY DCLVEHCL.
      *
      *    COPY IN DCLGEN FOR VEHICLE_STATUS_HIST
      *
           COPY DCLVHSTH.
      *
      *    INPUT MESSAGE FIELDS
      *
       01  WS-ALLOC-INPUT.
           05  WS-AI-FUNCTION            PIC X(02).
               88  WS-AI-ALLOCATE                   VALUE 'AL'.
               88  WS-AI-INQUIRY                    VALUE 'IQ'.
           05  WS-AI-VIN                 PIC X(17).
           05  WS-AI-DEALER-CODE         PIC X(05).
           05  WS-AI-PRODUCTION-ID       PIC X(12).
           05  WS-AI-PRIORITY            PIC X(02).
               88  WS-AI-PRIO-HIGH                  VALUE 'HI'.
               88  WS-AI-PRIO-NORMAL                VALUE 'NR'.
               88  WS-AI-PRIO-LOW                   VALUE 'LO'.
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-ALLOC-OUTPUT.
           05  WS-AO-STATUS-LINE.
               10  WS-AO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-MSG-TEXT       PIC X(70).
           05  WS-AO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-AO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-AO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'PROD ID:  '.
               10  WS-AO-PROD-ID        PIC X(12).
               10  FILLER               PIC X(30) VALUE SPACES.
           05  WS-AO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-AO-YEAR           PIC 9(04).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-AO-MAKE           PIC X(03).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-AO-MODEL          PIC X(06).
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-AO-ALLOC-LINE.
               10  FILLER               PIC X(08) VALUE 'DEALER: '.
               10  WS-AO-DEALER         PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'PRIORITY: '.
               10  WS-AO-PRIORITY       PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-AO-STATUS         PIC X(02).
               10  FILLER               PIC X(36) VALUE SPACES.
           05  WS-AO-STATUS-LINE-2.
               10  FILLER               PIC X(12)
                   VALUE 'OLD STATUS: '.
               10  WS-AO-OLD-STATUS     PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(12)
                   VALUE 'NEW STATUS: '.
               10  WS-AO-NEW-STATUS     PIC X(02).
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-AO-BUILD-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'BUILD DATE: '.
               10  WS-AO-BUILD-DATE     PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'PLANT: '.
               10  WS-AO-PLANT          PIC X(04).
               10  FILLER               PIC X(42) VALUE SPACES.
           05  WS-AO-FILLER             PIC X(1406) VALUE SPACES.
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
           05  WS-DEALER-EXISTS         PIC X(01) VALUE 'N'.
               88  WS-DEALER-VALID                VALUE 'Y'.
               88  WS-DEALER-INVALID              VALUE 'N'.
           05  WS-OLD-VEH-STATUS        PIC X(02) VALUE SPACES.
           05  WS-NEXT-HIST-SEQ         PIC S9(09) COMP VALUE +0.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-ALLOC-DEALER       PIC S9(04) COMP VALUE +0.
           05  WS-NI-ALLOC-DATE         PIC S9(04) COMP VALUE +0.
           05  WS-NI-BUILD-DATE         PIC S9(04) COMP VALUE +0.
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
                   WHEN WS-AI-ALLOCATE
                       PERFORM 4000-PROCESS-ALLOCATION
                   WHEN WS-AI-INQUIRY
                       PERFORM 5000-INQUIRY-MODE
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'VEHALL00'  TO WS-AO-MSG-ID
                       MOVE 'INVALID FUNCTION - USE AL OR IQ'
                           TO WS-AO-MSG-TEXT
               END-EVALUATE
           END-IF
      *
           PERFORM 8000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - SET UP WORKING STORAGE                  *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE +0 TO WS-RETURN-CODE
           INITIALIZE WS-ALLOC-OUTPUT
           MOVE 'VEHALL00' TO WS-AO-MSG-ID
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
               MOVE 'VEHALL00'  TO WS-AO-MSG-ID
               MOVE 'IMS GU FAILED - UNABLE TO RECEIVE INPUT'
                   TO WS-AO-MSG-TEXT
           ELSE
      *        PARSE INPUT DATA INTO ALLOCATION FIELDS
               MOVE WS-INP-FUNCTION   TO WS-AI-FUNCTION
               MOVE WS-INP-BODY(1:17) TO WS-AI-VIN
               MOVE WS-INP-BODY(18:5) TO WS-AI-DEALER-CODE
               MOVE WS-INP-BODY(23:12) TO WS-AI-PRODUCTION-ID
               MOVE WS-INP-BODY(35:2) TO WS-AI-PRIORITY
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - VALIDATE VIN AND DEALER             *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
      *    VALIDATE VIN FORMAT
      *
           IF WS-AI-VIN = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN IS REQUIRED' TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-AI-VIN TO WS-VIN-VALID-INPUT
           CALL 'COMVALD0' USING WS-VIN-VALID-INPUT
                                 WS-VIN-VALID-RC
                                 WS-VIN-VALID-MSG
                                 WS-VIN-DECODED
      *
           IF WS-VIN-VALID-RC NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-VIN-VALID-MSG TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE DEALER CODE EXISTS
      *
           IF WS-AI-FUNCTION = 'AL'
               IF WS-AI-DEALER-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEALER CODE IS REQUIRED FOR ALLOCATION'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
               EXEC SQL
                   SELECT 'Y'
                   INTO   :WS-DEALER-EXISTS
                   FROM   AUTOSALE.DEALER
                   WHERE  DEALER_CODE = :WS-AI-DEALER-CODE
                     AND  ACTIVE_FLAG = 'Y'
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEALER CODE NOT FOUND OR INACTIVE'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    VALIDATE PRIORITY IF SUPPLIED
      *
           IF WS-AI-PRIORITY NOT = SPACES
           AND NOT WS-AI-PRIO-HIGH
           AND NOT WS-AI-PRIO-NORMAL
           AND NOT WS-AI-PRIO-LOW
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INVALID PRIORITY - USE HI, NR, OR LO'
                   TO WS-AO-MSG-TEXT
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PROCESS-ALLOCATION - ALLOCATE VEHICLE TO DEALER      *
      ****************************************************************
       4000-PROCESS-ALLOCATION.
      *
      *    LOOK UP PRODUCTION ORDER
      *
           EXEC SQL
               SELECT PRODUCTION_ID
                    , VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , PLANT_CODE
                    , BUILD_DATE
                    , BUILD_STATUS
                    , ALLOCATED_DEALER
               INTO  :PRODUCTION-ID
                    , :VIN        OF DCLPRODUCTION-ORDER
                    , :MODEL-YEAR OF DCLPRODUCTION-ORDER
                    , :MAKE-CODE  OF DCLPRODUCTION-ORDER
                    , :MODEL-CODE OF DCLPRODUCTION-ORDER
                    , :PLANT-CODE
                    , :BUILD-DATE :WS-NI-BUILD-DATE
                    , :BUILD-STATUS
                    , :ALLOCATED-DEALER :WS-NI-ALLOC-DEALER
               FROM   AUTOSALE.PRODUCTION_ORDER
               WHERE  VIN = :WS-AI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'PRODUCTION ORDER NOT FOUND FOR VIN'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING PRODUCTION ORDER'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY BUILD STATUS IS COMPLETE (PR = PRODUCED)
      *
           IF BUILD-STATUS NOT = 'PR'
           AND BUILD-STATUS NOT = 'CM'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'VEHICLE NOT READY - BUILD STATUS: '
                      BUILD-STATUS
                      DELIMITED BY SIZE
                      INTO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK IF ALREADY ALLOCATED
      *
           IF WS-NI-ALLOC-DEALER = +0
           AND ALLOCATED-DEALER NOT = SPACES
               MOVE +4 TO WS-RETURN-CODE
               STRING 'VEHICLE ALREADY ALLOCATED TO DEALER '
                      ALLOCATED-DEALER
                      DELIMITED BY SIZE
                      INTO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    GET CURRENT VEHICLE STATUS
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
               INTO   :WS-OLD-VEH-STATUS
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-AI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE RECORD NOT FOUND'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    UPDATE PRODUCTION_ORDER WITH ALLOCATED DEALER
      *
           EXEC SQL
               UPDATE AUTOSALE.PRODUCTION_ORDER
                  SET ALLOCATED_DEALER = :WS-AI-DEALER-CODE
                    , ALLOCATION_DATE  = :WS-FORMATTED-DATE
                    , UPDATED_TS       = CURRENT TIMESTAMP
               WHERE  VIN = :WS-AI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING PRODUCTION ORDER'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    UPDATE VEHICLE DEALER_CODE AND STATUS
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET DEALER_CODE    = :WS-AI-DEALER-CODE
                    , VEHICLE_STATUS = 'AL'
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :WS-AI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING VEHICLE RECORD'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    CALL COMSTCK0 TO UPDATE STOCK POSITION
      *
           MOVE 'ALOC'              TO WS-SR-FUNCTION
           MOVE WS-AI-DEALER-CODE   TO WS-SR-DEALER-CODE
           MOVE WS-AI-VIN           TO WS-SR-VIN
           MOVE IO-PCB-USER-ID      TO WS-SR-USER-ID
           STRING 'ALLOCATION FROM PROD ORDER '
                  PRODUCTION-ID
                  DELIMITED BY SIZE
                  INTO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           IF WS-RS-RETURN-CODE > +4
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-RS-RETURN-MSG TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    WRITE AUDIT LOG
      *
           MOVE 'VEHALL00'      TO WS-LR-PROGRAM
           MOVE 'ALLOC   '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-AI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'ALLOCATED VIN ' WS-AI-VIN
                  ' TO DEALER ' WS-AI-DEALER-CODE
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT SUCCESS OUTPUT
      *
           MOVE 'VEHICLE ALLOCATED SUCCESSFULLY'
               TO WS-AO-MSG-TEXT
           MOVE WS-AI-VIN         TO WS-AO-VIN
           MOVE PRODUCTION-ID     TO WS-AO-PROD-ID
           MOVE MODEL-YEAR OF DCLPRODUCTION-ORDER
                                  TO WS-AO-YEAR
           MOVE MAKE-CODE OF DCLPRODUCTION-ORDER
                                  TO WS-AO-MAKE
           MOVE MODEL-CODE OF DCLPRODUCTION-ORDER
                                  TO WS-AO-MODEL
           MOVE WS-AI-DEALER-CODE TO WS-AO-DEALER
           MOVE WS-AI-PRIORITY    TO WS-AO-PRIORITY
           MOVE 'AL'              TO WS-AO-STATUS
           MOVE WS-OLD-VEH-STATUS TO WS-AO-OLD-STATUS
           MOVE 'AL'              TO WS-AO-NEW-STATUS
           MOVE BUILD-DATE        TO WS-AO-BUILD-DATE
           MOVE PLANT-CODE        TO WS-AO-PLANT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-INQUIRY-MODE - DISPLAY ALLOCATION STATUS             *
      ****************************************************************
       5000-INQUIRY-MODE.
      *
           EXEC SQL
               SELECT P.PRODUCTION_ID
                    , P.VIN
                    , P.MODEL_YEAR
                    , P.MAKE_CODE
                    , P.MODEL_CODE
                    , P.PLANT_CODE
                    , P.BUILD_DATE
                    , P.BUILD_STATUS
                    , P.ALLOCATED_DEALER
                    , V.VEHICLE_STATUS
               INTO  :PRODUCTION-ID
                    , :VIN        OF DCLPRODUCTION-ORDER
                    , :MODEL-YEAR OF DCLPRODUCTION-ORDER
                    , :MAKE-CODE  OF DCLPRODUCTION-ORDER
                    , :MODEL-CODE OF DCLPRODUCTION-ORDER
                    , :PLANT-CODE
                    , :BUILD-DATE :WS-NI-BUILD-DATE
                    , :BUILD-STATUS
                    , :ALLOCATED-DEALER :WS-NI-ALLOC-DEALER
                    , :WS-OLD-VEH-STATUS
               FROM   AUTOSALE.PRODUCTION_ORDER P
                    , AUTOSALE.VEHICLE V
               WHERE  P.VIN = :WS-AI-VIN
                 AND  V.VIN = P.VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO PRODUCTION/VEHICLE RECORD FOUND FOR VIN'
                   TO WS-AO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON ALLOCATION INQUIRY'
                   TO WS-AO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    FORMAT INQUIRY OUTPUT
      *
           MOVE 'ALLOCATION INQUIRY COMPLETE'
               TO WS-AO-MSG-TEXT
           MOVE WS-AI-VIN         TO WS-AO-VIN
           MOVE PRODUCTION-ID     TO WS-AO-PROD-ID
           MOVE MODEL-YEAR OF DCLPRODUCTION-ORDER
                                  TO WS-AO-YEAR
           MOVE MAKE-CODE OF DCLPRODUCTION-ORDER
                                  TO WS-AO-MAKE
           MOVE MODEL-CODE OF DCLPRODUCTION-ORDER
                                  TO WS-AO-MODEL
           MOVE ALLOCATED-DEALER  TO WS-AO-DEALER
           MOVE WS-OLD-VEH-STATUS TO WS-AO-STATUS
           MOVE BUILD-DATE        TO WS-AO-BUILD-DATE
           MOVE PLANT-CODE        TO WS-AO-PLANT
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    8000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       8000-SEND-OUTPUT.
      *
      *    FORMAT OUTPUT MESSAGE
      *
           MOVE WS-ALLOC-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHALL00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHALL00                                              *
      ****************************************************************
