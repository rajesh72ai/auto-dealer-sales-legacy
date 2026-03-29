       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKADJT0.
      ****************************************************************
      * PROGRAM:  STKADJT0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - STOCK ADJUSTMENT                *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ALLOWS MANUAL STOCK ADJUSTMENTS FOR A VEHICLE.     *
      *           ADJUSTMENT TYPES: DM=DAMAGE, WO=WRITE-OFF,         *
      *           RC=RECLASSIFY, PH=PHYSICAL COUNT, OT=OTHER.        *
      *           UPDATES VEHICLE STATUS, INSERTS STOCK_ADJUSTMENT,  *
      *           AND UPDATES STOCK_POSITION COUNTS.                 *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKA00                                           *
      * TABLES:   AUTOSALE.VEHICLE          (READ/UPDATE)            *
      *           AUTOSALE.STOCK_ADJUSTMENT  (INSERT)                *
      *           AUTOSALE.STOCK_POSITION    (UPDATE)                *
      * CALLS:    COMSTCK0 - STOCK COUNT UPDATE                     *
      *           COMLGEL0 - AUDIT LOGGING                          *
      *           COMDBEL0 - DB2 ERROR HANDLER                      *
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
                                          VALUE 'STKADJT0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKA00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
           COPY DCLVEHCL.
           COPY DCLSTKAJ.
      *
      *    VALID ADJUSTMENT TYPES
      *
       01  WS-VALID-ADJ-TYPES.
           05  FILLER                    PIC X(02) VALUE 'DM'.
           05  FILLER                    PIC X(02) VALUE 'WO'.
           05  FILLER                    PIC X(02) VALUE 'RC'.
           05  FILLER                    PIC X(02) VALUE 'PH'.
           05  FILLER                    PIC X(02) VALUE 'OT'.
       01  WS-VALID-ADJ-R REDEFINES WS-VALID-ADJ-TYPES.
           05  WS-VAL-ADJ-ENTRY          PIC X(02) OCCURS 5 TIMES.
      *
      *    ADJUSTMENT TYPE DESCRIPTIONS
      *
       01  WS-ADJ-TYPE-DESCS.
           05  FILLER                    PIC X(20) VALUE 'DAMAGE              '.
           05  FILLER                    PIC X(20) VALUE 'WRITE-OFF           '.
           05  FILLER                    PIC X(20) VALUE 'RECLASSIFY          '.
           05  FILLER                    PIC X(20) VALUE 'PHYSICAL COUNT CORR.'.
           05  FILLER                    PIC X(20) VALUE 'OTHER               '.
       01  WS-ADJ-DESC-R REDEFINES WS-ADJ-TYPE-DESCS.
           05  WS-ADJ-DESC-ENTRY         PIC X(20) OCCURS 5 TIMES.
      *
      *    INPUT MESSAGE AREA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-ADJ-TYPE            PIC X(02).
           05  WS-IN-ADJ-REASON          PIC X(100).
      *
      *    OUTPUT MESSAGE AREA
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-VEH-STATUS         PIC X(02).
           05  WS-OUT-MAKE-CODE          PIC X(03).
           05  WS-OUT-MODEL-CODE         PIC X(06).
           05  WS-OUT-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-OUT-ADJ-TYPE-DESC      PIC X(20).
           05  WS-OUT-OLD-STATUS         PIC X(02).
           05  WS-OUT-NEW-STATUS         PIC X(02).
           05  WS-OUT-ADJUST-ID          PIC Z(8)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ADJ-TYPE-VALID         PIC X(01) VALUE 'N'.
               88  WS-IS-VALID-ADJ                 VALUE 'Y'.
               88  WS-NOT-VALID-ADJ                VALUE 'N'.
           05  WS-ADJ-IDX                PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-NEW-STATUS             PIC X(02) VALUE SPACES.
           05  WS-NEXT-ADJUST-ID         PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-VEH-MAKE              PIC X(03)  VALUE SPACES.
           05  WS-VEH-MODEL             PIC X(06)  VALUE SPACES.
           05  WS-VEH-YEAR              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-VEH-OLD-STATUS        PIC X(02)  VALUE SPACES.
      *
      *    COMSTCK0 LINKAGE AREAS
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
      *    DB2 ERROR HANDLER LINKAGE
      *
       01  WS-DBE-PROGRAM-NAME          PIC X(08).
       01  WS-DBE-SECTION-NAME          PIC X(20).
       01  WS-DBE-TABLE-NAME            PIC X(30).
       01  WS-DBE-OPERATION             PIC X(10).
       01  WS-DBE-RESULT-AREA.
           05  WS-DBE-RESULT-CODE       PIC S9(04) COMP.
           05  WS-DBE-RESULT-MSG        PIC X(79).
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
               PERFORM 5000-PROCESS-ADJUSTMENT
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
           INITIALIZE WS-WORK-FIELDS
           MOVE 'STOCK ADJUSTMENT ENTRY' TO WS-OUT-TITLE
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
               MOVE 'STKADJT0: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-VIN = SPACES
               MOVE 'VIN IS REQUIRED FOR STOCK ADJUSTMENT'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE ADJUSTMENT TYPE
      *
           MOVE 'N' TO WS-ADJ-TYPE-VALID
           PERFORM VARYING WS-ADJ-IDX FROM 1 BY 1
               UNTIL WS-ADJ-IDX > 5
               OR WS-IS-VALID-ADJ
               IF WS-IN-ADJ-TYPE = WS-VAL-ADJ-ENTRY(WS-ADJ-IDX)
                   MOVE 'Y' TO WS-ADJ-TYPE-VALID
                   MOVE WS-ADJ-DESC-ENTRY(WS-ADJ-IDX)
                       TO WS-OUT-ADJ-TYPE-DESC
               END-IF
           END-PERFORM
      *
           IF WS-NOT-VALID-ADJ
               MOVE
               'INVALID ADJUSTMENT TYPE (DM/WO/RC/PH/OT)'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    REQUIRE REASON TEXT
      *
           IF WS-IN-ADJ-REASON = SPACES
               MOVE 'ADJUSTMENT REASON IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           MOVE WS-IN-VIN         TO WS-OUT-VIN
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-VEHICLE - VERIFY VEHICLE EXISTS               *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
                    , MAKE_CODE
                    , MODEL_CODE
                    , MODEL_YEAR
               INTO  :WS-VEH-OLD-STATUS
                    , :WS-VEH-MAKE
                    , :WS-VEH-MODEL
                    , :WS-VEH-YEAR
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-IN-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE WS-VEH-OLD-STATUS TO WS-OUT-VEH-STATUS
                   MOVE WS-VEH-MAKE       TO WS-OUT-MAKE-CODE
                   MOVE WS-VEH-MODEL      TO WS-OUT-MODEL-CODE
                   MOVE WS-VEH-YEAR       TO WS-OUT-MODEL-YEAR
                   MOVE WS-VEH-OLD-STATUS TO WS-OUT-OLD-STATUS
               WHEN +100
                   MOVE 'VEHICLE NOT FOUND FOR SPECIFIED VIN'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE WS-PROGRAM-NAME TO WS-DBE-PROGRAM-NAME
                   MOVE '4000-LOOKUP' TO WS-DBE-SECTION-NAME
                   MOVE 'VEHICLE' TO WS-DBE-TABLE-NAME
                   MOVE 'SELECT' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM-NAME
                                         WS-DBE-SECTION-NAME
                                         WS-DBE-TABLE-NAME
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT-AREA
                   MOVE WS-DBE-RESULT-MSG TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-PROCESS-ADJUSTMENT - CREATE ADJUSTMENT AND UPDATE    *
      ****************************************************************
       5000-PROCESS-ADJUSTMENT.
      *
      *    DETERMINE NEW STATUS BASED ON ADJUSTMENT TYPE
      *
           EVALUATE WS-IN-ADJ-TYPE
               WHEN 'DM'
                   MOVE 'DG' TO WS-NEW-STATUS
               WHEN 'WO'
                   MOVE 'WO' TO WS-NEW-STATUS
               WHEN 'RC'
                   MOVE 'AV' TO WS-NEW-STATUS
               WHEN 'PH'
                   MOVE WS-VEH-OLD-STATUS TO WS-NEW-STATUS
               WHEN 'OT'
                   MOVE WS-VEH-OLD-STATUS TO WS-NEW-STATUS
           END-EVALUATE
      *
           MOVE WS-NEW-STATUS TO WS-OUT-NEW-STATUS
      *
      *    GET NEXT ADJUSTMENT ID
      *
           EXEC SQL
               SELECT COALESCE(MAX(ADJUST_ID), 0) + 1
               INTO   :WS-NEXT-ADJUST-ID
               FROM   AUTOSALE.STOCK_ADJUSTMENT
           END-EXEC
      *
      *    INSERT STOCK_ADJUSTMENT RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.STOCK_ADJUSTMENT
                    ( ADJUST_ID
                    , DEALER_CODE
                    , VIN
                    , ADJUST_TYPE
                    , ADJUST_REASON
                    , OLD_STATUS
                    , NEW_STATUS
                    , ADJUSTED_BY
                    , ADJUSTED_TS
                    )
               VALUES
                    ( :WS-NEXT-ADJUST-ID
                    , :WS-IN-DEALER-CODE
                    , :WS-IN-VIN
                    , :WS-IN-ADJ-TYPE
                    , :WS-IN-ADJ-REASON
                    , :WS-VEH-OLD-STATUS
                    , :WS-NEW-STATUS
                    , :IO-USER
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE WS-PROGRAM-NAME TO WS-DBE-PROGRAM-NAME
               MOVE '5000-INSERT' TO WS-DBE-SECTION-NAME
               MOVE 'STOCK_ADJUSTMENT' TO WS-DBE-TABLE-NAME
               MOVE 'INSERT' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                     WS-DBE-PROGRAM-NAME
                                     WS-DBE-SECTION-NAME
                                     WS-DBE-TABLE-NAME
                                     WS-DBE-OPERATION
                                     WS-DBE-RESULT-AREA
               MOVE WS-DBE-RESULT-MSG TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE WS-NEXT-ADJUST-ID TO WS-OUT-ADJUST-ID
      *
      *    UPDATE VEHICLE STATUS IF CHANGED
      *
           IF WS-NEW-STATUS NOT = WS-VEH-OLD-STATUS
               EXEC SQL
                   UPDATE AUTOSALE.VEHICLE
                      SET VEHICLE_STATUS = :WS-NEW-STATUS
                        , UPDATED_TS     = CURRENT TIMESTAMP
                   WHERE  VIN            = :WS-IN-VIN
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE 'STKADJT0: WARNING - VEHICLE STATUS NOT '
                       TO WS-OUT-MESSAGE
               END-IF
           END-IF
      *
      *    CALL COMSTCK0 FOR DAMAGE/WRITE-OFF TO DECREMENT COUNTS
      *
           IF WS-IN-ADJ-TYPE = 'DM' OR WS-IN-ADJ-TYPE = 'WO'
               MOVE 'SOLD' TO WS-STK-FUNCTION
               MOVE WS-IN-DEALER-CODE TO WS-STK-DEALER-CODE
               MOVE WS-IN-VIN         TO WS-STK-VIN
               MOVE IO-USER           TO WS-STK-USER-ID
               MOVE WS-IN-ADJ-REASON(1:60) TO WS-STK-REASON
               CALL 'COMSTCK0' USING WS-STK-REQUEST
                                     WS-STK-RESULT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE IO-USER TO WS-AUD-USER-ID
           MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
           MOVE 'INS' TO WS-AUD-ACTION-TYPE
           MOVE 'STOCK_ADJUSTMENT' TO WS-AUD-TABLE-NAME
           MOVE WS-IN-VIN TO WS-AUD-KEY-VALUE
           STRING 'STATUS=' WS-VEH-OLD-STATUS
                  DELIMITED BY SIZE
                  INTO WS-AUD-OLD-VALUE
           STRING 'TYPE=' WS-IN-ADJ-TYPE
                  ' STATUS=' WS-NEW-STATUS
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
      *
           IF WS-OUT-MESSAGE = SPACES
               MOVE 'STOCK ADJUSTMENT PROCESSED SUCCESSFULLY'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       5000-EXIT.
           EXIT.
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
      * END OF STKADJT0                                              *
      ****************************************************************
