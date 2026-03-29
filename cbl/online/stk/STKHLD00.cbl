       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKHLD00.
      ****************************************************************
      * PROGRAM:  STKHLD00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - HOLD/RELEASE VEHICLE            *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PLACES A VEHICLE ON HOLD (CUSTOMER DEPOSIT OR      *
      *           MANAGER HOLD) OR RELEASES A HELD VEHICLE BACK TO   *
      *           AVAILABLE STATUS. VALIDATES STATUS TRANSITIONS AND  *
      *           UPDATES BOTH VEHICLE AND STOCK_POSITION TABLES.    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKH00                                           *
      * TABLES:   AUTOSALE.VEHICLE          (READ/UPDATE)            *
      *           AUTOSALE.STOCK_POSITION    (UPDATE VIA COMSTCK0)   *
      * CALLS:    COMSTCK0 - STOCK COUNT UPDATE (HOLD/RLSE)         *
      *           COMLGEL0 - AUDIT LOGGING                          *
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
                                          VALUE 'STKHLD00'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKH00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
           COPY DCLVEHCL.
      *
      *    INPUT MESSAGE AREA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-FUNCTION            PIC X(04).
               88  WS-IN-HOLD                        VALUE 'HOLD'.
               88  WS-IN-RELEASE                     VALUE 'RLSE'.
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-HOLD-REASON         PIC X(60).
      *
      *    OUTPUT MESSAGE AREA
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-FUNCTION           PIC X(08).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-MAKE-CODE          PIC X(03).
           05  WS-OUT-MODEL-CODE         PIC X(06).
           05  WS-OUT-MODEL-YEAR         PIC X(04).
           05  WS-OUT-STOCK-NUMBER       PIC X(08).
           05  WS-OUT-OLD-STATUS         PIC X(02).
           05  WS-OUT-NEW-STATUS         PIC X(02).
           05  WS-OUT-ON-HAND            PIC Z(4)9.
           05  WS-OUT-ON-HOLD            PIC Z(4)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-VEH-STATUS             PIC X(02) VALUE SPACES.
           05  WS-VEH-DEALER             PIC X(05) VALUE SPACES.
           05  WS-VEH-MAKE              PIC X(03) VALUE SPACES.
           05  WS-VEH-MODEL             PIC X(06) VALUE SPACES.
           05  WS-VEH-YEAR              PIC S9(04) COMP VALUE +0.
           05  WS-VEH-STOCK-NUM         PIC X(08) VALUE SPACES.
      *
      *    COMSTCK0 LINKAGE
      *
       01  WS-STK-REQUEST.
           05  WS-STK-FUNCTION           PIC X(04).
           05  WS-STK-DEALER-CODE        PIC X(05).
           05  WS-STK-VIN               PIC X(17).
           05  WS-STK-USER-ID           PIC X(08).
           05  WS-STK-REASON            PIC X(60).
      *
       01  WS-STK-RESULT.
           05  WS-STK-RETURN-CODE       PIC S9(04) COMP.
           05  WS-STK-RETURN-MSG        PIC X(79).
           05  WS-STK-OLD-STATUS        PIC X(02).
           05  WS-STK-NEW-STATUS        PIC X(02).
           05  WS-STK-ON-HAND           PIC S9(04) COMP.
           05  WS-STK-IN-TRANSIT        PIC S9(04) COMP.
           05  WS-STK-ALLOCATED         PIC S9(04) COMP.
           05  WS-STK-ON-HOLD           PIC S9(04) COMP.
           05  WS-STK-SOLD-MTD          PIC S9(04) COMP.
           05  WS-STK-SOLD-YTD          PIC S9(04) COMP.
           05  WS-STK-SQLCODE           PIC S9(09) COMP.
      *
      *    AUDIT MODULE LINKAGE
      *
       01  WS-AUD-USER-ID               PIC X(08).
       01  WS-AUD-PROGRAM-ID            PIC X(08).
       01  WS-AUD-ACTION-TYPE           PIC X(03).
       01  WS-AUD-TABLE-NAME            PIC X(30).
       01  WS-AUD-KEY-VALUE             PIC X(50).
       01  WS-AUD-OLD-VALUE             PIC X(200).
       01  WS-AUD-NEW-VALUE             PIC X(200).
       01  WS-AUD-RETURN-CODE           PIC S9(04) COMP.
       01  WS-AUD-ERROR-MSG             PIC X(50).
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-STATUS                 PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-USER                   PIC X(08).
      *
       01  DB-PCB-1.
           05  DB-1-DBD-NAME            PIC X(08).
           05  DB-1-SEG-LEVEL           PIC X(02).
           05  DB-1-STATUS              PIC X(02).
           05  FILLER                   PIC X(20).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB, DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF IO-STATUS = '  '
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 4000-LOOKUP-VEHICLE
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-PROCESS-HOLD-RELEASE
           END-IF
      *
           PERFORM 6000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           MOVE 'VEHICLE HOLD / RELEASE' TO WS-OUT-TITLE
           MOVE SPACES TO WS-OUT-MESSAGE
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
           IF IO-STATUS NOT = '  '
               MOVE 'STKHLD00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF NOT WS-IN-HOLD AND NOT WS-IN-RELEASE
               MOVE 'FUNCTION MUST BE HOLD OR RLSE'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-VIN = SPACES
               MOVE 'VIN IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-HOLD AND WS-IN-HOLD-REASON = SPACES
               MOVE 'HOLD REASON IS REQUIRED FOR HOLD FUNCTION'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-HOLD
               MOVE 'HOLD    ' TO WS-OUT-FUNCTION
           ELSE
               MOVE 'RELEASE ' TO WS-OUT-FUNCTION
           END-IF
      *
           MOVE WS-IN-VIN TO WS-OUT-VIN
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-VEHICLE - GET CURRENT STATUS                  *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , DEALER_CODE
                    , MAKE_CODE
                    , MODEL_CODE
                    , MODEL_YEAR
                    , STOCK_NUMBER
               INTO  :WS-VEH-STATUS
                    , :WS-VEH-DEALER
                    , :WS-VEH-MAKE
                    , :WS-VEH-MODEL
                    , :WS-VEH-YEAR
                    , :WS-VEH-STOCK-NUM
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-IN-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE WS-VEH-DEALER    TO WS-OUT-DEALER-CODE
                   MOVE WS-VEH-MAKE      TO WS-OUT-MAKE-CODE
                   MOVE WS-VEH-MODEL     TO WS-OUT-MODEL-CODE
                   MOVE WS-VEH-YEAR      TO WS-OUT-MODEL-YEAR
                   MOVE WS-VEH-STOCK-NUM TO WS-OUT-STOCK-NUMBER
                   MOVE WS-VEH-STATUS    TO WS-OUT-OLD-STATUS
      *
      *            VALIDATE STATUS TRANSITION
      *
                   IF WS-IN-HOLD
                       IF WS-VEH-STATUS NOT = 'AV'
                           MOVE
                           'VEHICLE MUST BE AV (AVAILABLE) TO HOLD'
                               TO WS-OUT-MESSAGE
                       END-IF
                   END-IF
      *
                   IF WS-IN-RELEASE
                       IF WS-VEH-STATUS NOT = 'HD'
                           MOVE
                           'VEHICLE MUST BE HD (ON HOLD) TO RELEASE'
                               TO WS-OUT-MESSAGE
                       END-IF
                   END-IF
      *
               WHEN +100
                   MOVE 'VEHICLE NOT FOUND FOR SPECIFIED VIN'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE 'STKHLD00: DB2 ERROR READING VEHICLE'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-PROCESS-HOLD-RELEASE - CALL COMSTCK0                 *
      ****************************************************************
       5000-PROCESS-HOLD-RELEASE.
      *
      *    SET UP COMSTCK0 REQUEST
      *
           IF WS-IN-HOLD
               MOVE 'HOLD' TO WS-STK-FUNCTION
           ELSE
               MOVE 'RLSE' TO WS-STK-FUNCTION
           END-IF
      *
           MOVE WS-VEH-DEALER   TO WS-STK-DEALER-CODE
           MOVE WS-IN-VIN       TO WS-STK-VIN
           MOVE IO-USER         TO WS-STK-USER-ID
           MOVE WS-IN-HOLD-REASON TO WS-STK-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           IF WS-STK-RETURN-CODE <= +4
      *        SUCCESS OR WARNING
               MOVE WS-STK-NEW-STATUS TO WS-OUT-NEW-STATUS
               MOVE WS-STK-ON-HAND    TO WS-OUT-ON-HAND
               MOVE WS-STK-ON-HOLD    TO WS-OUT-ON-HOLD
      *
               IF WS-IN-HOLD
                   MOVE 'VEHICLE PLACED ON HOLD SUCCESSFULLY'
                       TO WS-OUT-MESSAGE
               ELSE
                   MOVE 'VEHICLE RELEASED FROM HOLD SUCCESSFULLY'
                       TO WS-OUT-MESSAGE
               END-IF
      *
      *        AUDIT LOG
      *
               MOVE IO-USER         TO WS-AUD-USER-ID
               MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
               MOVE 'UPD'           TO WS-AUD-ACTION-TYPE
               MOVE 'VEHICLE'       TO WS-AUD-TABLE-NAME
               MOVE WS-IN-VIN       TO WS-AUD-KEY-VALUE
               STRING 'STATUS=' WS-VEH-STATUS
                      DELIMITED BY SIZE
                      INTO WS-AUD-OLD-VALUE
               STRING 'STATUS=' WS-STK-NEW-STATUS
                      ' REASON=' WS-IN-HOLD-REASON(1:40)
                      DELIMITED BY SIZE
                      INTO WS-AUD-NEW-VALUE
               CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                     WS-AUD-PROGRAM-ID
                                     WS-AUD-ACTION-TYPE
                                     WS-AUD-TABLE-NAME
                                     WS-AUD-KEY-VALUE
                                     WS-AUD-OLD-VALUE
                                     WS-AUD-NEW-VALUE
                                     WS-AUD-RETURN-CODE
                                     WS-AUD-ERROR-MSG
           ELSE
               MOVE WS-STK-RETURN-MSG TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    6000-SEND-OUTPUT                                          *
      ****************************************************************
       6000-SEND-OUTPUT.
      *
           COMPUTE WS-OUT-LL =
               FUNCTION LENGTH(WS-OUTPUT-MSG)
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
           .
      ****************************************************************
      * END OF STKHLD00                                              *
      ****************************************************************
