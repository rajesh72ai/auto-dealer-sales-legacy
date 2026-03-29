       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLIALLO0.
      ****************************************************************
      * PROGRAM:  PLIALLO0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - ALLOCATION ENGINE         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ASSIGNS PRODUCED VEHICLES TO DEALER ORDERS BASED   *
      *           ON PRIORITY. INPUT: VIN OR AUTO-ALLOCATE BY MODEL. *
      *           CHECKS DEALER ALLOCATION PRIORITY (SYSTEM_CONFIG), *
      *           REGION MATCHING, CURRENT INVENTORY VS MAX.         *
      *           UPDATES PRODUCTION_ORDER.ALLOCATED_DEALER AND      *
      *           VEHICLE.DEALER_CODE. SETS STATUS TO AL (ALLOCATED).*
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLAL - ALLOCATION ENGINE                           *
      * CALLS:    COMSTCK0 - STOCK UPDATE (ALOC FUNCTION)            *
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      * TABLES:   AUTOSALE.PRODUCTION_ORDER                          *
      *           AUTOSALE.VEHICLE                                    *
      *           AUTOSALE.SYSTEM_CONFIG                              *
      *           AUTOSALE.DEALER                                     *
      *           AUTOSALE.STOCK_POSITION                             *
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
                                          VALUE 'PLIALLO0'.
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
      *    INPUT FIELDS - ALLOCATION REQUEST
      *
       01  WS-ALLOC-INPUT.
           05  WS-AI-FUNCTION            PIC X(02).
               88  WS-AI-MANUAL                     VALUE 'MA'.
               88  WS-AI-AUTO                       VALUE 'AU'.
               88  WS-AI-INQUIRY                    VALUE 'IQ'.
           05  WS-AI-VIN                 PIC X(17).
           05  WS-AI-DEALER-CODE         PIC X(05).
           05  WS-AI-MODEL-YEAR          PIC 9(04).
           05  WS-AI-MAKE-CODE           PIC X(03).
           05  WS-AI-MODEL-CODE          PIC X(06).
           05  WS-AI-REGION-CODE         PIC X(04).
           05  WS-AI-PRIORITY-OVRD       PIC X(01).
               88  WS-AI-USE-PRIORITY                VALUE 'Y'.
               88  WS-AI-NO-PRIORITY                 VALUE 'N'.
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
               10  FILLER               PIC X(08)
                   VALUE 'DEALER: '.
               10  WS-AO-DEALER         PIC X(05).
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-AO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-AO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-AO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-AO-MODEL          PIC X(06).
               10  FILLER               PIC X(43) VALUE SPACES.
           05  WS-AO-ALLOC-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'PRIORITY: '.
               10  WS-AO-PRIORITY       PIC Z(04)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'REGION: '.
               10  WS-AO-REGION         PIC X(04).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(09)
                   VALUE 'ON HAND: '.
               10  WS-AO-ON-HAND        PIC Z(04)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'MAX: '.
               10  WS-AO-MAX-INV        PIC Z(04)9.
               10  FILLER               PIC X(16) VALUE SPACES.
           05  WS-AO-STATUS-LINE-2.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-AO-OLD-STATUS     PIC X(02).
               10  FILLER               PIC X(04) VALUE ' -> '.
               10  WS-AO-NEW-STATUS     PIC X(02).
               10  FILLER               PIC X(63) VALUE SPACES.
           05  WS-AO-AUTO-LINE.
               10  FILLER               PIC X(16)
                   VALUE 'AUTO-ALLOCATED: '.
               10  WS-AO-AUTO-COUNT     PIC Z(03)9.
               10  FILLER               PIC X(10)
                   VALUE ' VEHICLES '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-AO-FILLER             PIC X(1248) VALUE SPACES.
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
           05  WS-RS-SOLD-YTD           PIC S9(04) COMP.
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
           05  WS-VEHICLE-STATUS        PIC X(02) VALUE SPACES.
           05  WS-VEHICLE-YEAR          PIC S9(04) COMP VALUE +0.
           05  WS-VEHICLE-MAKE          PIC X(03) VALUE SPACES.
           05  WS-VEHICLE-MODEL         PIC X(06) VALUE SPACES.
           05  WS-DEALER-REGION         PIC X(04) VALUE SPACES.
           05  WS-DEALER-PRIORITY       PIC S9(04) COMP VALUE +0.
           05  WS-DEALER-ON-HAND        PIC S9(04) COMP VALUE +0.
           05  WS-DEALER-MAX-INV        PIC S9(04) COMP VALUE +0.
           05  WS-AUTO-ALLOC-COUNT      PIC S9(04) COMP VALUE +0.
           05  WS-BEST-DEALER           PIC X(05) VALUE SPACES.
           05  WS-BEST-PRIORITY         PIC S9(04) COMP VALUE +9999.
           05  WS-EOF-FLAG              PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA                  VALUE 'Y'.
               88  WS-MORE-DATA                    VALUE 'N'.
      *
      *    CURSOR FOR AUTO-ALLOCATION CANDIDATE DEALERS
      *
           EXEC SQL DECLARE CSR_ALLOC_DLR CURSOR FOR
               SELECT D.DEALER_CODE
                    , D.REGION_CODE
                    , COALESCE(C.CONFIG_VALUE_NUM, 999) AS PRIORITY
                    , COALESCE(S.ON_HAND_COUNT, 0) AS ON_HAND
                    , COALESCE(C2.CONFIG_VALUE_NUM, 100)
                          AS MAX_INVENTORY
               FROM   AUTOSALE.DEALER D
               LEFT JOIN AUTOSALE.SYSTEM_CONFIG C
                 ON   C.CONFIG_KEY = 'ALLOC_PRIORITY'
                AND   C.CONFIG_SCOPE = D.DEALER_CODE
               LEFT JOIN AUTOSALE.STOCK_POSITION S
                 ON   S.DEALER_CODE = D.DEALER_CODE
                AND   S.MODEL_YEAR  = :WS-AI-MODEL-YEAR
                AND   S.MAKE_CODE   = :WS-AI-MAKE-CODE
                AND   S.MODEL_CODE  = :WS-AI-MODEL-CODE
               LEFT JOIN AUTOSALE.SYSTEM_CONFIG C2
                 ON   C2.CONFIG_KEY = 'MAX_INVENTORY'
                AND   C2.CONFIG_SCOPE = D.DEALER_CODE
               WHERE  D.DEALER_STATUS = 'A'
                 AND  (D.REGION_CODE = :WS-AI-REGION-CODE
                       OR :WS-AI-REGION-CODE = '    ')
               ORDER BY PRIORITY ASC
                      , ON_HAND ASC
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HV-ALLOC.
           05  WS-HV-DEALER-CODE        PIC X(05).
           05  WS-HV-REGION             PIC X(04).
           05  WS-HV-PRIORITY           PIC S9(04) COMP.
           05  WS-HV-ON-HAND            PIC S9(04) COMP.
           05  WS-HV-MAX-INV            PIC S9(04) COMP.
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
                   WHEN WS-AI-MANUAL
                       PERFORM 4000-MANUAL-ALLOCATE
                   WHEN WS-AI-AUTO
                       PERFORM 5000-AUTO-ALLOCATE
                   WHEN WS-AI-INQUIRY
                       PERFORM 6000-INQUIRY-ALLOC
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - USE MA, AU, OR IQ'
                           TO WS-AO-MSG-TEXT
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
           INITIALIZE WS-ALLOC-OUTPUT
           MOVE 'PLIALLO0' TO WS-AO-MSG-ID
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
                   TO WS-AO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-AI-FUNCTION
               MOVE WS-INP-BODY(1:17)   TO WS-AI-VIN
               MOVE WS-INP-BODY(18:5)   TO WS-AI-DEALER-CODE
               MOVE WS-INP-BODY(23:4)   TO WS-AI-MODEL-YEAR
               MOVE WS-INP-BODY(27:3)   TO WS-AI-MAKE-CODE
               MOVE WS-INP-BODY(30:6)   TO WS-AI-MODEL-CODE
               MOVE WS-INP-BODY(36:4)   TO WS-AI-REGION-CODE
               MOVE WS-INP-BODY(40:1)   TO WS-AI-PRIORITY-OVRD
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK ALLOCATION PREREQUISITES       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-AI-MANUAL
               IF WS-AI-VIN = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'VIN IS REQUIRED FOR MANUAL ALLOCATION'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-AI-DEALER-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEALER CODE REQUIRED FOR MANUAL ALLOCATION'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-AI-AUTO
               IF WS-AI-MODEL-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'MODEL CODE REQUIRED FOR AUTO-ALLOCATION'
                       TO WS-AO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-MANUAL-ALLOCATE - ASSIGN VIN TO SPECIFIC DEALER       *
      ****************************************************************
       4000-MANUAL-ALLOCATE.
      *
      *    VERIFY VEHICLE EXISTS AND IS IN PR STATUS
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
               INTO   :WS-VEHICLE-STATUS
                    , :WS-VEHICLE-YEAR
                    , :WS-VEHICLE-MAKE
                    , :WS-VEHICLE-MODEL
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-AI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND IN SYSTEM'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING VEHICLE TABLE'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-VEHICLE-STATUS NOT = 'PR'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT ALLOCATE - STATUS IS '
                      WS-VEHICLE-STATUS
                      ' (MUST BE PR)'
                      DELIMITED BY SIZE
                      INTO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK DEALER INVENTORY CAPACITY
      *
           EXEC SQL
               SELECT COALESCE(S.ON_HAND_COUNT, 0)
                    , COALESCE(C.CONFIG_VALUE_NUM, 100)
               INTO   :WS-DEALER-ON-HAND
                    , :WS-DEALER-MAX-INV
               FROM   AUTOSALE.DEALER D
               LEFT JOIN AUTOSALE.STOCK_POSITION S
                 ON   S.DEALER_CODE = D.DEALER_CODE
                AND   S.MODEL_YEAR  = :WS-VEHICLE-YEAR
                AND   S.MAKE_CODE   = :WS-VEHICLE-MAKE
                AND   S.MODEL_CODE  = :WS-VEHICLE-MODEL
               LEFT JOIN AUTOSALE.SYSTEM_CONFIG C
                 ON   C.CONFIG_KEY = 'MAX_INVENTORY'
                AND   C.CONFIG_SCOPE = D.DEALER_CODE
               WHERE  D.DEALER_CODE = :WS-AI-DEALER-CODE
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER NOT FOUND IN SYSTEM'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-DEALER-ON-HAND >= WS-DEALER-MAX-INV
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: DEALER AT OR OVER MAX INVENTORY'
                   TO WS-AO-MSG-TEXT
           END-IF
      *
      *    UPDATE PRODUCTION ORDER
      *
           EXEC SQL
               UPDATE AUTOSALE.PRODUCTION_ORDER
                  SET ALLOCATED_DEALER = :WS-AI-DEALER-CODE
                    , PROD_STATUS      = 'AL'
                    , UPDATED_TS       = CURRENT TIMESTAMP
               WHERE  VIN = :WS-AI-VIN
                 AND  PROD_STATUS = 'PR'
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING PRODUCTION ORDER'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    UPDATE VEHICLE RECORD
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
               MOVE 'DB2 ERROR UPDATING VEHICLE ALLOCATION'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    CALL COMSTCK0 TO UPDATE STOCK COUNTS
      *
           MOVE 'ALOC'              TO WS-SR-FUNCTION
           MOVE WS-AI-DEALER-CODE   TO WS-SR-DEALER-CODE
           MOVE WS-AI-VIN           TO WS-SR-VIN
           MOVE IO-PCB-USER-ID      TO WS-SR-USER-ID
           MOVE 'VEHICLE ALLOCATED TO DEALER'
                                    TO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
      *    WRITE AUDIT LOG
      *
           MOVE 'PLIALLO0'      TO WS-LR-PROGRAM
           MOVE 'ALLOCATE'      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-AI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'VIN ' WS-AI-VIN
                  ' ALLOCATED TO DEALER ' WS-AI-DEALER-CODE
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           IF WS-RETURN-CODE = +0
               MOVE 'VEHICLE ALLOCATED SUCCESSFULLY'
                   TO WS-AO-MSG-TEXT
           END-IF
           MOVE WS-AI-VIN            TO WS-AO-VIN
           MOVE WS-AI-DEALER-CODE    TO WS-AO-DEALER
           MOVE WS-VEHICLE-YEAR      TO WS-AO-YEAR
           MOVE WS-VEHICLE-MAKE      TO WS-AO-MAKE
           MOVE WS-VEHICLE-MODEL     TO WS-AO-MODEL
           MOVE WS-DEALER-ON-HAND    TO WS-AO-ON-HAND
           MOVE WS-DEALER-MAX-INV    TO WS-AO-MAX-INV
           MOVE 'PR'                 TO WS-AO-OLD-STATUS
           MOVE 'AL'                 TO WS-AO-NEW-STATUS
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-AUTO-ALLOCATE - AUTO-ASSIGN BY MODEL TO BEST DEALER   *
      ****************************************************************
       5000-AUTO-ALLOCATE.
      *
           MOVE +0 TO WS-AUTO-ALLOC-COUNT
      *
           EXEC SQL OPEN CSR_ALLOC_DLR END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR OPENING ALLOCATION CURSOR'
                   TO WS-AO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    FIND BEST CANDIDATE DEALER (FIRST ROW = HIGHEST PRIORITY)
      *
           EXEC SQL FETCH CSR_ALLOC_DLR
               INTO  :WS-HV-DEALER-CODE
                    , :WS-HV-REGION
                    , :WS-HV-PRIORITY
                    , :WS-HV-ON-HAND
                    , :WS-HV-MAX-INV
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO ELIGIBLE DEALERS FOUND FOR ALLOCATION'
                   TO WS-AO-MSG-TEXT
               EXEC SQL CLOSE CSR_ALLOC_DLR END-EXEC
               GO TO 5000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR FETCHING ALLOCATION CANDIDATES'
                   TO WS-AO-MSG-TEXT
               EXEC SQL CLOSE CSR_ALLOC_DLR END-EXEC
               GO TO 5000-EXIT
           END-IF
      *
      *    CHECK CAPACITY BEFORE ALLOCATING
      *
           IF WS-HV-ON-HAND >= WS-HV-MAX-INV
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ALL ELIGIBLE DEALERS AT MAX INVENTORY'
                   TO WS-AO-MSG-TEXT
               EXEC SQL CLOSE CSR_ALLOC_DLR END-EXEC
               GO TO 5000-EXIT
           END-IF
      *
           EXEC SQL CLOSE CSR_ALLOC_DLR END-EXEC
      *
      *    USE BEST DEALER FOR MANUAL ALLOCATION
      *
           MOVE WS-HV-DEALER-CODE TO WS-AI-DEALER-CODE
           MOVE WS-HV-PRIORITY    TO WS-AO-PRIORITY
           MOVE WS-HV-REGION      TO WS-AO-REGION
           MOVE WS-HV-ON-HAND     TO WS-AO-ON-HAND
           MOVE WS-HV-MAX-INV     TO WS-AO-MAX-INV
      *
      *    ALLOCATE ALL UNALLOCATED VEHICLES OF THIS MODEL
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET DEALER_CODE    = :WS-HV-DEALER-CODE
                    , VEHICLE_STATUS = 'AL'
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VEHICLE_STATUS = 'PR'
                 AND  MODEL_YEAR     = :WS-AI-MODEL-YEAR
                 AND  MAKE_CODE      = :WS-AI-MAKE-CODE
                 AND  MODEL_CODE     = :WS-AI-MODEL-CODE
                 AND  DEALER_CODE    IS NULL
           END-EXEC
      *
           MOVE SQLERRD(3) TO WS-AUTO-ALLOC-COUNT
      *
           IF WS-AUTO-ALLOC-COUNT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO UNALLOCATED VEHICLES FOUND FOR MODEL'
                   TO WS-AO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE PRODUCTION ORDERS TO MATCH
      *
           EXEC SQL
               UPDATE AUTOSALE.PRODUCTION_ORDER
                  SET ALLOCATED_DEALER = :WS-HV-DEALER-CODE
                    , PROD_STATUS      = 'AL'
                    , UPDATED_TS       = CURRENT TIMESTAMP
               WHERE  PROD_STATUS = 'PR'
                 AND  MODEL_YEAR  = :WS-AI-MODEL-YEAR
                 AND  MAKE_CODE   = :WS-AI-MAKE-CODE
                 AND  MODEL_CODE  = :WS-AI-MODEL-CODE
                 AND  ALLOCATED_DEALER IS NULL
           END-EXEC
      *
      *    AUDIT LOG
      *
           MOVE 'PLIALLO0'      TO WS-LR-PROGRAM
           MOVE 'AUTOALOC'      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'VEHICLE '      TO WS-LR-ENTITY-TYPE
           MOVE WS-AI-MODEL-CODE TO WS-LR-ENTITY-KEY
           STRING 'AUTO-ALLOCATED '
                  WS-AUTO-ALLOC-COUNT
                  ' VEHICLES TO DEALER '
                  WS-HV-DEALER-CODE
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
           MOVE WS-AUTO-ALLOC-COUNT TO WS-AO-AUTO-COUNT
           MOVE WS-HV-DEALER-CODE   TO WS-AO-DEALER
           STRING 'AUTO-ALLOCATED '
                  WS-AUTO-ALLOC-COUNT
                  ' VEHICLES TO DEALER '
                  WS-HV-DEALER-CODE
                  DELIMITED BY SIZE
                  INTO WS-AO-MSG-TEXT
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-INQUIRY-ALLOC - SHOW ALLOCATION STATUS                *
      ****************************************************************
       6000-INQUIRY-ALLOC.
      *
           EXEC SQL
               SELECT V.VEHICLE_STATUS
                    , V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.MODEL_CODE
                    , V.DEALER_CODE
               INTO   :WS-VEHICLE-STATUS
                    , :WS-VEHICLE-YEAR
                    , :WS-VEHICLE-MAKE
                    , :WS-VEHICLE-MODEL
                    , :WS-AO-DEALER
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VIN = :WS-AI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND'
                   TO WS-AO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-AI-VIN        TO WS-AO-VIN
           MOVE WS-VEHICLE-YEAR  TO WS-AO-YEAR
           MOVE WS-VEHICLE-MAKE  TO WS-AO-MAKE
           MOVE WS-VEHICLE-MODEL TO WS-AO-MODEL
           MOVE WS-VEHICLE-STATUS TO WS-AO-OLD-STATUS
           MOVE WS-VEHICLE-STATUS TO WS-AO-NEW-STATUS
           MOVE 'ALLOCATION STATUS RETRIEVED'
               TO WS-AO-MSG-TEXT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
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
               MOVE 'PLIALLO0' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLIALLO0                                               *
      ****************************************************************
