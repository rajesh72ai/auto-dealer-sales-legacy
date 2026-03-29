       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLIPROD0.
      ****************************************************************
      * PROGRAM:  PLIPROD0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - PRODUCTION COMPLETION     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  RECEIVES PRODUCTION COMPLETION FEED FROM PLANT.    *
      *           PROCESSES PRODUCTION RECORDS: VIN, MODEL YEAR,     *
      *           MAKE, MODEL, PLANT CODE, BUILD DATE, OPTIONS.      *
      *           VALIDATES VIN, CHECKS FOR DUPLICATES, INSERTS      *
      *           INTO PRODUCTION_ORDER AND VEHICLE TABLES.           *
      *           INSERTS VEHICLE_OPTION RECORDS. SETS INITIAL       *
      *           STATUS TO PR (PRODUCED). HANDLES BOTH SINGLE       *
      *           ONLINE ENTRY AND BATCH MODE PROCESSING.            *
      * IMS:      ONLINE IMS DC TRANSACTION (BATCH-CALLABLE)         *
      * TRANS:    PLPR - PRODUCTION COMPLETION                       *
      * CALLS:    COMVALD0 - VIN VALIDATION                          *
      *           COMVINL0 - VIN DECODE/LOOKUP                       *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.PRODUCTION_ORDER                          *
      *           AUTOSALE.VEHICLE                                    *
      *           AUTOSALE.VEHICLE_OPTION                             *
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
                                          VALUE 'PLIPROD0'.
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
      *    INPUT FIELDS - PRODUCTION RECORD
      *
       01  WS-PROD-INPUT.
           05  WS-PI-FUNCTION            PIC X(02).
               88  WS-PI-SINGLE                     VALUE 'SG'.
               88  WS-PI-BATCH                      VALUE 'BT'.
               88  WS-PI-INQUIRY                    VALUE 'IQ'.
           05  WS-PI-VIN                 PIC X(17).
           05  WS-PI-MODEL-YEAR          PIC 9(04).
           05  WS-PI-MAKE-CODE           PIC X(03).
           05  WS-PI-MODEL-CODE          PIC X(06).
           05  WS-PI-PLANT-CODE          PIC X(05).
           05  WS-PI-BUILD-DATE          PIC X(10).
           05  WS-PI-EXT-COLOR           PIC X(03).
           05  WS-PI-INT-COLOR           PIC X(03).
           05  WS-PI-ENGINE-CODE         PIC X(04).
           05  WS-PI-TRANS-CODE          PIC X(04).
           05  WS-PI-OPTION-COUNT        PIC 9(02).
           05  WS-PI-OPTIONS.
               10  WS-PI-OPTION-ENTRY    OCCURS 20 TIMES.
                   15  WS-PI-OPT-CODE    PIC X(06).
                   15  WS-PI-OPT-DESC    PIC X(30).
           05  WS-PI-BATCH-COUNT         PIC 9(04).
           05  WS-PI-MSRP               PIC S9(07)V99 COMP-3.
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-PROD-OUTPUT.
           05  WS-PO-STATUS-LINE.
               10  WS-PO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-PO-MSG-TEXT       PIC X(70).
           05  WS-PO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-PO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-PO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(07)
                   VALUE 'PLANT: '.
               10  WS-PO-PLANT          PIC X(05).
               10  FILLER               PIC X(40) VALUE SPACES.
           05  WS-PO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-PO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-PO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-PO-MODEL          PIC X(06).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'BUILD: '.
               10  WS-PO-BUILD-DATE     PIC X(10).
               10  FILLER               PIC X(24) VALUE SPACES.
           05  WS-PO-COLOR-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'EXT COLOR:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-PO-EXT-COLOR      PIC X(03).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'INT COLOR:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-PO-INT-COLOR      PIC X(03).
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-PO-STATUS-LINE-2.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-PO-STATUS         PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'OPTIONS: '.
               10  WS-PO-OPT-COUNT      PIC Z9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MSRP: '.
               10  WS-PO-MSRP           PIC $$$,$$$,$$9.99.
               10  FILLER               PIC X(27) VALUE SPACES.
           05  WS-PO-BATCH-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'BATCH PROC: '.
               10  WS-PO-BATCH-TOTAL    PIC Z(03)9.
               10  FILLER               PIC X(10)
                   VALUE ' RECEIVED '.
               10  WS-PO-BATCH-OK       PIC Z(03)9.
               10  FILLER               PIC X(04)
                   VALUE ' OK '.
               10  WS-PO-BATCH-ERR      PIC Z(03)9.
               10  FILLER               PIC X(08)
                   VALUE ' ERRORS '.
               10  FILLER               PIC X(27) VALUE SPACES.
           05  WS-PO-FILLER             PIC X(1090) VALUE SPACES.
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
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-DUP-COUNT             PIC S9(09) COMP VALUE +0.
           05  WS-OPTION-IDX            PIC S9(04) COMP VALUE +0.
           05  WS-BATCH-TOTAL           PIC S9(04) COMP VALUE +0.
           05  WS-BATCH-OK              PIC S9(04) COMP VALUE +0.
           05  WS-BATCH-ERR             PIC S9(04) COMP VALUE +0.
           05  WS-PROD-ORDER-ID         PIC S9(09) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-ALLOC-DEALER       PIC S9(04) COMP VALUE -1.
           05  WS-NI-ENGINE             PIC S9(04) COMP VALUE +0.
           05  WS-NI-TRANS              PIC S9(04) COMP VALUE +0.
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
                   WHEN WS-PI-SINGLE
                       PERFORM 4000-PROCESS-SINGLE
                   WHEN WS-PI-BATCH
                       PERFORM 5000-PROCESS-BATCH
                   WHEN WS-PI-INQUIRY
                       PERFORM 6000-INQUIRY-PROD
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION CODE'
                           TO WS-PO-MSG-TEXT
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
           INITIALIZE WS-PROD-OUTPUT
           MOVE 'PLIPROD0' TO WS-PO-MSG-ID
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
                   TO WS-PO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-PI-FUNCTION
               MOVE WS-INP-BODY(1:17)   TO WS-PI-VIN
               MOVE WS-INP-BODY(18:4)   TO WS-PI-MODEL-YEAR
               MOVE WS-INP-BODY(22:3)   TO WS-PI-MAKE-CODE
               MOVE WS-INP-BODY(25:6)   TO WS-PI-MODEL-CODE
               MOVE WS-INP-BODY(31:5)   TO WS-PI-PLANT-CODE
               MOVE WS-INP-BODY(36:10)  TO WS-PI-BUILD-DATE
               MOVE WS-INP-BODY(46:3)   TO WS-PI-EXT-COLOR
               MOVE WS-INP-BODY(49:3)   TO WS-PI-INT-COLOR
               MOVE WS-INP-BODY(52:4)   TO WS-PI-ENGINE-CODE
               MOVE WS-INP-BODY(56:4)   TO WS-PI-TRANS-CODE
               MOVE WS-INP-BODY(60:2)   TO WS-PI-OPTION-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - VIN AND PRODUCTION DATA              *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-PI-VIN = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN IS REQUIRED FOR PRODUCTION ENTRY'
                   TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE VIN FORMAT VIA COMVALD0
      *
           MOVE WS-PI-VIN TO WS-VIN-VALID-INPUT
           CALL 'COMVALD0' USING WS-VIN-VALID-INPUT
                                 WS-VIN-VALID-RC
                                 WS-VIN-VALID-MSG
                                 WS-VIN-DECODED
      *
           IF WS-VIN-VALID-RC NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-VIN-VALID-MSG TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    DECODE VIN DETAILS VIA COMVINL0
      *
           MOVE 'LOOK'        TO WS-VINL-FUNCTION
           MOVE WS-PI-VIN     TO WS-VINL-VIN
           CALL 'COMVINL0' USING WS-VINL-REQUEST
                                 WS-VINL-RESULT
      *
      *    CHECK FOR DUPLICATE VIN IN VEHICLE TABLE
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-DUP-COUNT
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-PI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR CHECKING VIN DUPLICATE'
                   TO WS-PO-MSG-TEXT
               PERFORM 3500-HANDLE-DB2-ERROR
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-DUP-COUNT > +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN ALREADY EXISTS IN VEHICLE TABLE'
                   TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE REQUIRED FIELDS
      *
           IF WS-PI-MODEL-YEAR < 1990
           OR WS-PI-MODEL-YEAR > 2030
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'MODEL YEAR OUT OF VALID RANGE (1990-2030)'
                   TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-PI-MAKE-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'MAKE CODE IS REQUIRED'
                   TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-PI-MODEL-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'MODEL CODE IS REQUIRED'
                   TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-PI-PLANT-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'PLANT CODE IS REQUIRED'
                   TO WS-PO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-PI-BUILD-DATE = SPACES
               MOVE WS-FORMATTED-DATE TO WS-PI-BUILD-DATE
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-HANDLE-DB2-ERROR - CALL COMDBEL0                      *
      ****************************************************************
       3500-HANDLE-DB2-ERROR.
      *
           MOVE WS-PROGRAM-NAME  TO WS-DBE-PROGRAM
           MOVE 'PRODUCTION-FEED' TO WS-DBE-PARAGRAPH
           MOVE SQLCODE           TO WS-DBE-SQLCODE
           MOVE SQLERRMC          TO WS-DBE-SQLERRM
      *
           CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                 WS-DBE-RESULT
           .
      *
      ****************************************************************
      *    4000-PROCESS-SINGLE - INSERT SINGLE PRODUCTION RECORD      *
      ****************************************************************
       4000-PROCESS-SINGLE.
      *
           PERFORM 4100-INSERT-PROD-ORDER
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4200-INSERT-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4300-INSERT-OPTIONS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4400-LOG-AND-FORMAT
           END-IF
           .
      *
      ****************************************************************
      *    4100-INSERT-PROD-ORDER - INSERT PRODUCTION_ORDER            *
      ****************************************************************
       4100-INSERT-PROD-ORDER.
      *
           EXEC SQL
               SELECT COALESCE(MAX(PROD_ORDER_ID), 0) + 1
               INTO   :WS-PROD-ORDER-ID
               FROM   AUTOSALE.PRODUCTION_ORDER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR GENERATING PROD ORDER ID'
                   TO WS-PO-MSG-TEXT
               PERFORM 3500-HANDLE-DB2-ERROR
               GO TO 4100-EXIT
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.PRODUCTION_ORDER
                    ( PROD_ORDER_ID
                    , VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , PLANT_CODE
                    , BUILD_DATE
                    , PROD_STATUS
                    , ALLOCATED_DEALER
                    , CREATED_TS
                    , UPDATED_TS
                    )
               VALUES
                    ( :WS-PROD-ORDER-ID
                    , :WS-PI-VIN
                    , :WS-PI-MODEL-YEAR
                    , :WS-PI-MAKE-CODE
                    , :WS-PI-MODEL-CODE
                    , :WS-PI-PLANT-CODE
                    , :WS-PI-BUILD-DATE
                    , 'PR'
                    , NULL
                    , CURRENT TIMESTAMP
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR INSERTING PRODUCTION ORDER'
                   TO WS-PO-MSG-TEXT
               PERFORM 3500-HANDLE-DB2-ERROR
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4200-INSERT-VEHICLE - INSERT INTO VEHICLE TABLE             *
      ****************************************************************
       4200-INSERT-VEHICLE.
      *
           EXEC SQL
               INSERT INTO AUTOSALE.VEHICLE
                    ( VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , EXTERIOR_COLOR
                    , INTERIOR_COLOR
                    , ENGINE_CODE
                    , TRANSMISSION_CODE
                    , VEHICLE_STATUS
                    , PLANT_CODE
                    , BUILD_DATE
                    , MSRP
                    , DEALER_CODE
                    , CREATED_TS
                    , UPDATED_TS
                    )
               VALUES
                    ( :WS-PI-VIN
                    , :WS-PI-MODEL-YEAR
                    , :WS-PI-MAKE-CODE
                    , :WS-PI-MODEL-CODE
                    , :WS-PI-EXT-COLOR
                    , :WS-PI-INT-COLOR
                    , :WS-PI-ENGINE-CODE
                    , :WS-PI-TRANS-CODE
                    , 'PR'
                    , :WS-PI-PLANT-CODE
                    , :WS-PI-BUILD-DATE
                    , :WS-PI-MSRP
                    , NULL
                    , CURRENT TIMESTAMP
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR INSERTING VEHICLE RECORD'
                   TO WS-PO-MSG-TEXT
               PERFORM 3500-HANDLE-DB2-ERROR
           END-IF
           .
      *
      ****************************************************************
      *    4300-INSERT-OPTIONS - INSERT VEHICLE_OPTION RECORDS         *
      ****************************************************************
       4300-INSERT-OPTIONS.
      *
           IF WS-PI-OPTION-COUNT = 0
               GO TO 4300-EXIT
           END-IF
      *
           PERFORM VARYING WS-OPTION-IDX FROM +1 BY +1
               UNTIL WS-OPTION-IDX > WS-PI-OPTION-COUNT
               OR WS-OPTION-IDX > 20
      *
               IF WS-PI-OPT-CODE(WS-OPTION-IDX) NOT = SPACES
                   EXEC SQL
                       INSERT INTO AUTOSALE.VEHICLE_OPTION
                            ( VIN
                            , OPTION_SEQ
                            , OPTION_CODE
                            , OPTION_DESC
                            , INSTALLED_DATE
                            , CREATED_TS
                            )
                       VALUES
                            ( :WS-PI-VIN
                            , :WS-OPTION-IDX
                            , :WS-PI-OPT-CODE(WS-OPTION-IDX)
                            , :WS-PI-OPT-DESC(WS-OPTION-IDX)
                            , :WS-PI-BUILD-DATE
                            , CURRENT TIMESTAMP
                            )
                   END-EXEC
      *
                   IF SQLCODE NOT = +0
                       MOVE +4 TO WS-RETURN-CODE
                       MOVE 'WARNING: OPTION INSERT FAILED'
                           TO WS-PO-MSG-TEXT
                   END-IF
               END-IF
           END-PERFORM
           .
       4300-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4400-LOG-AND-FORMAT - AUDIT LOG AND FORMAT OUTPUT           *
      ****************************************************************
       4400-LOG-AND-FORMAT.
      *
           MOVE 'PLIPROD0'      TO WS-LR-PROGRAM
           MOVE 'PRODRCV '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-PI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'PRODUCTION RECEIVED VIN ' WS-PI-VIN
                  ' PLANT ' WS-PI-PLANT-CODE
                  ' BUILD ' WS-PI-BUILD-DATE
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT SUCCESS OUTPUT
      *
           MOVE 'PRODUCTION RECORD CREATED SUCCESSFULLY'
               TO WS-PO-MSG-TEXT
           MOVE WS-PI-VIN            TO WS-PO-VIN
           MOVE WS-PI-PLANT-CODE     TO WS-PO-PLANT
           MOVE WS-PI-MODEL-YEAR     TO WS-PO-YEAR
           MOVE WS-PI-MAKE-CODE      TO WS-PO-MAKE
           MOVE WS-PI-MODEL-CODE     TO WS-PO-MODEL
           MOVE WS-PI-BUILD-DATE     TO WS-PO-BUILD-DATE
           MOVE WS-PI-EXT-COLOR      TO WS-PO-EXT-COLOR
           MOVE WS-PI-INT-COLOR      TO WS-PO-INT-COLOR
           MOVE 'PR'                 TO WS-PO-STATUS
           MOVE WS-PI-OPTION-COUNT   TO WS-PO-OPT-COUNT
           MOVE WS-PI-MSRP           TO WS-PO-MSRP
           .
      *
      ****************************************************************
      *    5000-PROCESS-BATCH - BATCH MODE COUNTER-BASED              *
      ****************************************************************
       5000-PROCESS-BATCH.
      *
           MOVE +0 TO WS-BATCH-TOTAL
           MOVE +0 TO WS-BATCH-OK
           MOVE +0 TO WS-BATCH-ERR
      *
      *    IN BATCH MODE THE INPUT CONTAINS A COUNT OF RECORDS
      *    EACH RECORD IS PROCESSED VIA THE SAME SINGLE LOGIC
      *    FOR ONLINE SIMULATION WE PROCESS THE SINGLE RECORD
      *    AND REPORT BATCH COUNTERS
      *
           ADD +1 TO WS-BATCH-TOTAL
      *
           PERFORM 4100-INSERT-PROD-ORDER
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4200-INSERT-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4300-INSERT-OPTIONS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               ADD +1 TO WS-BATCH-OK
               PERFORM 4400-LOG-AND-FORMAT
           ELSE
               ADD +1 TO WS-BATCH-ERR
               MOVE +0 TO WS-RETURN-CODE
           END-IF
      *
      *    FORMAT BATCH SUMMARY
      *
           MOVE 'BATCH PROCESSING COMPLETE'
               TO WS-PO-MSG-TEXT
           MOVE WS-BATCH-TOTAL   TO WS-PO-BATCH-TOTAL
           MOVE WS-BATCH-OK      TO WS-PO-BATCH-OK
           MOVE WS-BATCH-ERR     TO WS-PO-BATCH-ERR
           .
      *
      ****************************************************************
      *    6000-INQUIRY-PROD - DISPLAY PRODUCTION ORDER STATUS        *
      ****************************************************************
       6000-INQUIRY-PROD.
      *
           EXEC SQL
               SELECT PROD_ORDER_ID
                    , PROD_STATUS
                    , PLANT_CODE
                    , BUILD_DATE
                    , ALLOCATED_DEALER
               INTO   :WS-PROD-ORDER-ID
                    , :WS-PO-STATUS
                    , :WS-PO-PLANT
                    , :WS-PO-BUILD-DATE
                    , :WS-NI-ALLOC-DEALER
               FROM   AUTOSALE.PRODUCTION_ORDER
               WHERE  VIN = :WS-PI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'PRODUCTION ORDER NOT FOUND FOR THIS VIN'
                   TO WS-PO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING PRODUCTION ORDER'
                   TO WS-PO-MSG-TEXT
               PERFORM 3500-HANDLE-DB2-ERROR
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-PI-VIN        TO WS-PO-VIN
           MOVE WS-PI-MODEL-YEAR TO WS-PO-YEAR
           MOVE WS-PI-MAKE-CODE  TO WS-PO-MAKE
           MOVE WS-PI-MODEL-CODE TO WS-PO-MODEL
           MOVE 'PRODUCTION ORDER FOUND'
               TO WS-PO-MSG-TEXT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-PROD-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLIPROD0' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLIPROD0                                               *
      ****************************************************************
