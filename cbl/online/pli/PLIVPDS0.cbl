       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLIVPDS0.
      ****************************************************************
      * PROGRAM:  PLIVPDS0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - PDI SCHEDULING            *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SCHEDULES PRE-DELIVERY INSPECTION (PDI) FOR        *
      *           RECEIVED VEHICLES. INPUT: VIN, SCHEDULED DATE,     *
      *           TECHNICIAN ID. CREATES/UPDATES PDI_SCHEDULE.       *
      *           FUNCTIONS: SCHEDULE NEW, UPDATE STATUS (IP/CM/FL), *
      *           RECORD CHECKLIST RESULTS. ON COMPLETE: UPDATES     *
      *           VEHICLE.PDI_COMPLETE=Y, PDI_DATE. ON FAIL: SETS    *
      *           STATUS=FL WITH NOTES, REQUIRES RESCHEDULE.         *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLPD - PDI SCHEDULING                              *
      * CALLS:    COMLGEL0 - AUDIT LOG ENTRY                         *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
      * TABLES:   AUTOSALE.PDI_SCHEDULE                               *
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
                                          VALUE 'PLIVPDS0'.
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
      *    INPUT FIELDS - PDI SCHEDULING
      *
       01  WS-PDI-INPUT.
           05  WS-PI-FUNCTION            PIC X(02).
               88  WS-PI-SCHEDULE                   VALUE 'SC'.
               88  WS-PI-START                      VALUE 'IP'.
               88  WS-PI-COMPLETE                   VALUE 'CM'.
               88  WS-PI-FAIL                       VALUE 'FL'.
               88  WS-PI-INQUIRY                    VALUE 'IQ'.
           05  WS-PI-VIN                 PIC X(17).
           05  WS-PI-PDI-ID             PIC S9(09) COMP.
           05  WS-PI-DEALER-CODE         PIC X(05).
           05  WS-PI-SCHED-DATE          PIC X(10).
           05  WS-PI-TECHNICIAN-ID       PIC X(08).
           05  WS-PI-ITEMS-PASSED        PIC 9(03).
           05  WS-PI-ITEMS-FAILED        PIC 9(03).
           05  WS-PI-NOTES               PIC X(200).
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-PDI-OUTPUT.
           05  WS-PO-STATUS-LINE.
               10  WS-PO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-PO-MSG-TEXT       PIC X(70).
           05  WS-PO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-PO-PDI-LINE.
               10  FILLER               PIC X(08) VALUE 'PDI ID: '.
               10  WS-PO-PDI-ID         PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-PO-PDI-STATUS     PIC X(02).
               10  FILLER               PIC X(48) VALUE SPACES.
           05  WS-PO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-PO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'DEALER: '.
               10  WS-PO-DEALER         PIC X(05).
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-PO-SCHED-LINE.
               10  FILLER               PIC X(11)
                   VALUE 'SCHEDULED: '.
               10  WS-PO-SCHED-DATE     PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TECH: '.
               10  WS-PO-TECHNICIAN     PIC X(08).
               10  FILLER               PIC X(40) VALUE SPACES.
           05  WS-PO-CHECK-LINE.
               10  FILLER               PIC X(11)
                   VALUE 'CHECKLIST: '.
               10  WS-PO-TOTAL-ITEMS    PIC Z(02)9.
               10  FILLER               PIC X(09)
                   VALUE ' TOTAL   '.
               10  WS-PO-PASSED         PIC Z(02)9.
               10  FILLER               PIC X(09)
                   VALUE ' PASSED  '.
               10  WS-PO-FAILED         PIC Z(02)9.
               10  FILLER               PIC X(09)
                   VALUE ' FAILED  '.
               10  FILLER               PIC X(23) VALUE SPACES.
           05  WS-PO-NOTES-LINE.
               10  FILLER               PIC X(07) VALUE 'NOTES: '.
               10  WS-PO-NOTES          PIC X(72).
           05  WS-PO-VEH-STATUS.
               10  FILLER               PIC X(16)
                   VALUE 'VEHICLE STATUS: '.
               10  WS-PO-VEH-STAT       PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(14)
                   VALUE 'PDI COMPLETE: '.
               10  WS-PO-PDI-COMP       PIC X(01).
               10  FILLER               PIC X(42) VALUE SPACES.
           05  WS-PO-FILLER             PIC X(1090) VALUE SPACES.
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
           05  WS-PDI-STATUS            PIC X(02) VALUE SPACES.
           05  WS-PDI-ITEMS-TOTAL       PIC S9(04) COMP VALUE +0.
           05  WS-PDI-ITEMS-PASS        PIC S9(04) COMP VALUE +0.
           05  WS-PDI-ITEMS-FAIL        PIC S9(04) COMP VALUE +0.
           05  WS-PDI-VIN               PIC X(17) VALUE SPACES.
           05  WS-PDI-DEALER            PIC X(05) VALUE SPACES.
           05  WS-PDI-SCHED-DT          PIC X(10) VALUE SPACES.
           05  WS-PDI-TECH-ID           PIC X(08) VALUE SPACES.
           05  WS-PDI-ID-GEN            PIC S9(09) COMP VALUE +0.
           05  WS-VEHICLE-STATUS        PIC X(02) VALUE SPACES.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
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
               EVALUATE TRUE
                   WHEN WS-PI-SCHEDULE
                       PERFORM 4000-SCHEDULE-PDI
                   WHEN WS-PI-START
                       PERFORM 5000-START-PDI
                   WHEN WS-PI-COMPLETE
                       PERFORM 6000-COMPLETE-PDI
                   WHEN WS-PI-FAIL
                       PERFORM 7000-FAIL-PDI
                   WHEN WS-PI-INQUIRY
                       PERFORM 8000-INQUIRY-PDI
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - SC/IP/CM/FL/IQ'
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
           INITIALIZE WS-PDI-OUTPUT
           MOVE 'PLIVPDS0' TO WS-PO-MSG-ID
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
               MOVE WS-INP-BODY(18:4)   TO WS-PI-PDI-ID
               MOVE WS-INP-BODY(22:5)   TO WS-PI-DEALER-CODE
               MOVE WS-INP-BODY(27:10)  TO WS-PI-SCHED-DATE
               MOVE WS-INP-BODY(37:8)   TO WS-PI-TECHNICIAN-ID
               MOVE WS-INP-BODY(45:3)   TO WS-PI-ITEMS-PASSED
               MOVE WS-INP-BODY(48:3)   TO WS-PI-ITEMS-FAILED
               MOVE WS-INP-BODY(51:200) TO WS-PI-NOTES
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK PDI DATA                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-PI-VIN = SPACES AND WS-PI-PDI-ID = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN OR PDI ID IS REQUIRED'
                   TO WS-PO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    4000-SCHEDULE-PDI - CREATE NEW PDI SCHEDULE                 *
      ****************************************************************
       4000-SCHEDULE-PDI.
      *
      *    VERIFY VEHICLE EXISTS AND IS DELIVERED
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , DEALER_CODE
               INTO   :WS-VEHICLE-STATUS
                    , :WS-PDI-DEALER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-PI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND'
                   TO WS-PO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    GENERATE PDI ID
      *
           EXEC SQL
               SELECT COALESCE(MAX(PDI_ID), 0) + 1
               INTO   :WS-PDI-ID-GEN
               FROM   AUTOSALE.PDI_SCHEDULE
           END-EXEC
      *
      *    SET SCHEDULE DATE
      *
           IF WS-PI-SCHED-DATE = SPACES
               MOVE WS-FORMATTED-DATE TO WS-PI-SCHED-DATE
           END-IF
      *
      *    SET DEALER FROM INPUT OR VEHICLE RECORD
      *
           IF WS-PI-DEALER-CODE = SPACES
               MOVE WS-PDI-DEALER TO WS-PI-DEALER-CODE
           END-IF
      *
      *    SET NULL INDICATORS
      *
           IF WS-PI-TECHNICIAN-ID = SPACES
               MOVE -1 TO WS-NI-TECH-ID
           ELSE
               MOVE +0 TO WS-NI-TECH-ID
           END-IF
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
                    , :WS-PI-VIN
                    , :WS-PI-DEALER-CODE
                    , :WS-PI-SCHED-DATE
                    , :WS-PI-TECHNICIAN-ID
                                          :WS-NI-TECH-ID
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
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR INSERTING PDI SCHEDULE'
                   TO WS-PO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 4000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLIVPDS0'      TO WS-LR-PROGRAM
           MOVE 'PDISCHED'      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'PDI     '      TO WS-LR-ENTITY-TYPE
           MOVE WS-PI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'PDI SCHEDULED VIN ' WS-PI-VIN
                  ' DATE ' WS-PI-SCHED-DATE
                  ' TECH ' WS-PI-TECHNICIAN-ID
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    FORMAT OUTPUT
      *
           MOVE 'PDI SCHEDULED SUCCESSFULLY'
               TO WS-PO-MSG-TEXT
           MOVE WS-PDI-ID-GEN        TO WS-PO-PDI-ID
           MOVE 'SC'                  TO WS-PO-PDI-STATUS
           MOVE WS-PI-VIN            TO WS-PO-VIN
           MOVE WS-PI-DEALER-CODE    TO WS-PO-DEALER
           MOVE WS-PI-SCHED-DATE     TO WS-PO-SCHED-DATE
           MOVE WS-PI-TECHNICIAN-ID  TO WS-PO-TECHNICIAN
           MOVE +42                  TO WS-PO-TOTAL-ITEMS
           MOVE +0                   TO WS-PO-PASSED
           MOVE +0                   TO WS-PO-FAILED
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-HANDLE-DB2-ERROR - CALL COMDBEL0                      *
      ****************************************************************
       4500-HANDLE-DB2-ERROR.
      *
           MOVE WS-PROGRAM-NAME   TO WS-DBE-PROGRAM
           MOVE 'PDI-SCHEDULE'     TO WS-DBE-PARAGRAPH
           MOVE SQLCODE            TO WS-DBE-SQLCODE
           MOVE SQLERRMC           TO WS-DBE-SQLERRM
      *
           CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                 WS-DBE-RESULT
           .
      *
      ****************************************************************
      *    5000-START-PDI - UPDATE STATUS TO IP (IN PROGRESS)          *
      ****************************************************************
       5000-START-PDI.
      *
      *    LOOKUP PDI RECORD
      *
           PERFORM 8500-LOOKUP-PDI
      *
           IF WS-RETURN-CODE NOT = +0
               GO TO 5000-EXIT
           END-IF
      *
      *    VERIFY STATUS IS SC
      *
           IF WS-PDI-STATUS NOT = 'SC'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT START - PDI STATUS IS '
                      WS-PDI-STATUS
                      DELIMITED BY SIZE
                      INTO WS-PO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    SET TECHNICIAN IF PROVIDED
      *
           IF WS-PI-TECHNICIAN-ID NOT = SPACES
               MOVE +0 TO WS-NI-TECH-ID
           ELSE
               MOVE -1 TO WS-NI-TECH-ID
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.PDI_SCHEDULE
                  SET PDI_STATUS    = 'IP'
                    , TECHNICIAN_ID = :WS-PI-TECHNICIAN-ID
                                       :WS-NI-TECH-ID
               WHERE  PDI_ID = :WS-PI-PDI-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING PDI TO IN PROGRESS'
                   TO WS-PO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 5000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLIVPDS0'      TO WS-LR-PROGRAM
           MOVE 'PDISTART'      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'PDI     '      TO WS-LR-ENTITY-TYPE
           MOVE WS-PDI-VIN      TO WS-LR-ENTITY-KEY
           STRING 'PDI STARTED ID ' WS-PI-PDI-ID
                  ' VIN ' WS-PDI-VIN
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
           MOVE 'PDI STARTED - IN PROGRESS'
               TO WS-PO-MSG-TEXT
           MOVE 'IP' TO WS-PO-PDI-STATUS
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-COMPLETE-PDI - MARK AS COMPLETED                       *
      ****************************************************************
       6000-COMPLETE-PDI.
      *
           PERFORM 8500-LOOKUP-PDI
      *
           IF WS-RETURN-CODE NOT = +0
               GO TO 6000-EXIT
           END-IF
      *
           IF WS-PDI-STATUS NOT = 'IP'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT COMPLETE - PDI STATUS IS '
                      WS-PDI-STATUS
                      DELIMITED BY SIZE
                      INTO WS-PO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    UPDATE PDI TO COMPLETED
      *
           IF WS-PI-NOTES NOT = SPACES
               MOVE +0 TO WS-NI-NOTES
           ELSE
               MOVE -1 TO WS-NI-NOTES
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.PDI_SCHEDULE
                  SET PDI_STATUS    = 'CM'
                    , ITEMS_PASSED  = :WS-PI-ITEMS-PASSED
                    , ITEMS_FAILED  = :WS-PI-ITEMS-FAILED
                    , NOTES         = :WS-PI-NOTES
                                       :WS-NI-NOTES
                    , COMPLETED_TS  = CURRENT TIMESTAMP
               WHERE  PDI_ID = :WS-PI-PDI-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR COMPLETING PDI'
                   TO WS-PO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 6000-EXIT
           END-IF
      *
      *    UPDATE VEHICLE PDI_COMPLETE FLAG
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET PDI_COMPLETE = 'Y'
                    , PDI_DATE     = :WS-FORMATTED-DATE
                    , VEHICLE_STATUS = 'AV'
                    , UPDATED_TS   = CURRENT TIMESTAMP
               WHERE  VIN = :WS-PDI-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE 'WARNING: VEHICLE PDI FLAG UPDATE FAILED'
                   TO WS-PO-MSG-TEXT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLIVPDS0'      TO WS-LR-PROGRAM
           MOVE 'PDICMPL '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'PDI     '      TO WS-LR-ENTITY-TYPE
           MOVE WS-PDI-VIN      TO WS-LR-ENTITY-KEY
           STRING 'PDI COMPLETED ID ' WS-PI-PDI-ID
                  ' VIN ' WS-PDI-VIN
                  ' PASSED ' WS-PI-ITEMS-PASSED
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
           IF WS-RETURN-CODE = +0
               MOVE 'PDI COMPLETED - VEHICLE AVAILABLE FOR SALE'
                   TO WS-PO-MSG-TEXT
           END-IF
           MOVE 'CM'  TO WS-PO-PDI-STATUS
           MOVE 'AV'  TO WS-PO-VEH-STAT
           MOVE 'Y'   TO WS-PO-PDI-COMP
           MOVE WS-PI-ITEMS-PASSED TO WS-PO-PASSED
           MOVE WS-PI-ITEMS-FAILED TO WS-PO-FAILED
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-FAIL-PDI - MARK AS FAILED, REQUIRES RESCHEDULE        *
      ****************************************************************
       7000-FAIL-PDI.
      *
           PERFORM 8500-LOOKUP-PDI
      *
           IF WS-RETURN-CODE NOT = +0
               GO TO 7000-EXIT
           END-IF
      *
           IF WS-PDI-STATUS NOT = 'IP'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'CANNOT FAIL - PDI STATUS IS '
                      WS-PDI-STATUS
                      DELIMITED BY SIZE
                      INTO WS-PO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
      *    UPDATE PDI TO FAILED
      *
           IF WS-PI-NOTES NOT = SPACES
               MOVE +0 TO WS-NI-NOTES
           ELSE
               MOVE -1 TO WS-NI-NOTES
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.PDI_SCHEDULE
                  SET PDI_STATUS    = 'FL'
                    , ITEMS_PASSED  = :WS-PI-ITEMS-PASSED
                    , ITEMS_FAILED  = :WS-PI-ITEMS-FAILED
                    , NOTES         = :WS-PI-NOTES
                                       :WS-NI-NOTES
               WHERE  PDI_ID = :WS-PI-PDI-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING PDI TO FAILED'
                   TO WS-PO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 7000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'PLIVPDS0'      TO WS-LR-PROGRAM
           MOVE 'PDIFAIL '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'PDI     '      TO WS-LR-ENTITY-TYPE
           MOVE WS-PDI-VIN      TO WS-LR-ENTITY-KEY
           STRING 'PDI FAILED ID ' WS-PI-PDI-ID
                  ' VIN ' WS-PDI-VIN
                  ' NEEDS RESCHEDULE'
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
           MOVE 'PDI FAILED - RESCHEDULE REQUIRED'
               TO WS-PO-MSG-TEXT
           MOVE 'FL'  TO WS-PO-PDI-STATUS
           MOVE WS-PI-ITEMS-PASSED TO WS-PO-PASSED
           MOVE WS-PI-ITEMS-FAILED TO WS-PO-FAILED
           MOVE WS-PI-NOTES(1:72)  TO WS-PO-NOTES
           .
       7000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    8000-INQUIRY-PDI - DISPLAY PDI STATUS                       *
      ****************************************************************
       8000-INQUIRY-PDI.
      *
           PERFORM 8500-LOOKUP-PDI
      *
           IF WS-RETURN-CODE = +0
               MOVE 'PDI RECORD RETRIEVED'
                   TO WS-PO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    8500-LOOKUP-PDI - READ PDI RECORD BY ID OR VIN              *
      ****************************************************************
       8500-LOOKUP-PDI.
      *
           IF WS-PI-PDI-ID NOT = +0
               EXEC SQL
                   SELECT PDI_ID
                        , VIN
                        , DEALER_CODE
                        , SCHEDULED_DATE
                        , TECHNICIAN_ID
                        , PDI_STATUS
                        , CHECKLIST_ITEMS
                        , ITEMS_PASSED
                        , ITEMS_FAILED
                   INTO   :WS-PI-PDI-ID
                        , :WS-PDI-VIN
                        , :WS-PDI-DEALER
                        , :WS-PDI-SCHED-DT
                        , :WS-PDI-TECH-ID
                                          :WS-NI-TECH-ID
                        , :WS-PDI-STATUS
                        , :WS-PDI-ITEMS-TOTAL
                        , :WS-PDI-ITEMS-PASS
                        , :WS-PDI-ITEMS-FAIL
                   FROM   AUTOSALE.PDI_SCHEDULE
                   WHERE  PDI_ID = :WS-PI-PDI-ID
               END-EXEC
           ELSE
               EXEC SQL
                   SELECT PDI_ID
                        , VIN
                        , DEALER_CODE
                        , SCHEDULED_DATE
                        , TECHNICIAN_ID
                        , PDI_STATUS
                        , CHECKLIST_ITEMS
                        , ITEMS_PASSED
                        , ITEMS_FAILED
                   INTO   :WS-PI-PDI-ID
                        , :WS-PDI-VIN
                        , :WS-PDI-DEALER
                        , :WS-PDI-SCHED-DT
                        , :WS-PDI-TECH-ID
                                          :WS-NI-TECH-ID
                        , :WS-PDI-STATUS
                        , :WS-PDI-ITEMS-TOTAL
                        , :WS-PDI-ITEMS-PASS
                        , :WS-PDI-ITEMS-FAIL
                   FROM   AUTOSALE.PDI_SCHEDULE
                   WHERE  VIN = :WS-PI-VIN
                   ORDER BY PDI_ID DESC
                   FETCH FIRST 1 ROW ONLY
               END-EXEC
           END-IF
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'PDI RECORD NOT FOUND'
                   TO WS-PO-MSG-TEXT
               GO TO 8500-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING PDI SCHEDULE'
                   TO WS-PO-MSG-TEXT
               PERFORM 4500-HANDLE-DB2-ERROR
               GO TO 8500-EXIT
           END-IF
      *
      *    FORMAT COMMON OUTPUT FIELDS
      *
           MOVE WS-PI-PDI-ID         TO WS-PO-PDI-ID
           MOVE WS-PDI-STATUS        TO WS-PO-PDI-STATUS
           MOVE WS-PDI-VIN           TO WS-PO-VIN
           MOVE WS-PDI-DEALER        TO WS-PO-DEALER
           MOVE WS-PDI-SCHED-DT      TO WS-PO-SCHED-DATE
           IF WS-NI-TECH-ID = +0
               MOVE WS-PDI-TECH-ID   TO WS-PO-TECHNICIAN
           END-IF
           MOVE WS-PDI-ITEMS-TOTAL   TO WS-PO-TOTAL-ITEMS
           MOVE WS-PDI-ITEMS-PASS    TO WS-PO-PASSED
           MOVE WS-PDI-ITEMS-FAIL    TO WS-PO-FAILED
           .
       8500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-PDI-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLIVPDS0' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLIVPDS0                                               *
      ****************************************************************
