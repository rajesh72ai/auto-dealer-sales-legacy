       IDENTIFICATION DIVISION.
       PROGRAM-ID. FPLRPT00.
      ****************************************************************
      * PROGRAM:  FPLRPT00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FPL - FLOOR PLAN EXPOSURE REPORT                   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SUMMARIZES FLOOR PLAN LIABILITY FOR A DEALER:      *
      *           TOTAL BALANCE, TOTAL INTEREST, GROUPED BY LENDER.  *
      *           GROUPS BY NEW/USED, LENDER, AND AGE BUCKET.        *
      *           CALCULATES WEIGHTED AVG INTEREST RATE AND          *
      *           AVERAGE DAYS ON FLOOR.                             *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FPLR - FLOOR PLAN REPORT                           *
      * MFS MOD:  ASFPLR00                                           *
      * TABLES:   AUTOSALE.FLOOR_PLAN_VEHICLE (READ)                 *
      *           AUTOSALE.VEHICLE            (READ)                  *
      *           AUTOSALE.LENDER             (READ)                  *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                        *
      *           COMINTL0 - INTEREST CALCULATION                    *
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
                                          VALUE 'FPLRPT00'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASFPLR00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
      *    INPUT MESSAGE AREA (FROM MFS)
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
      *    LENDER SUMMARY (UP TO 8 LENDERS)
           05  WS-OUT-LENDER-COUNT       PIC S9(04) COMP.
           05  WS-OUT-LENDER-DTL OCCURS 8 TIMES.
               10  WS-OUT-LND-ID         PIC X(05).
               10  WS-OUT-LND-NAME       PIC X(20).
               10  WS-OUT-LND-VEH-CT     PIC Z(3)9.
               10  WS-OUT-LND-BALANCE    PIC X(15).
               10  WS-OUT-LND-INTEREST   PIC X(13).
               10  WS-OUT-LND-AVG-RATE   PIC X(08).
               10  WS-OUT-LND-AVG-DAYS   PIC Z(3)9.
      *    AGE BUCKET SUMMARY
           05  WS-OUT-AGE-0-30           PIC Z(3)9.
           05  WS-OUT-AGE-31-60          PIC Z(3)9.
           05  WS-OUT-AGE-61-90          PIC Z(3)9.
           05  WS-OUT-AGE-91-PLUS        PIC Z(3)9.
      *    NEW/USED SPLIT
           05  WS-OUT-NEW-COUNT          PIC Z(3)9.
           05  WS-OUT-NEW-BALANCE        PIC X(15).
           05  WS-OUT-USED-COUNT         PIC Z(3)9.
           05  WS-OUT-USED-BALANCE       PIC X(15).
      *    GRAND TOTALS
           05  WS-OUT-GRAND-VEHICLES     PIC Z(4)9.
           05  WS-OUT-GRAND-BALANCE      PIC X(15).
           05  WS-OUT-GRAND-INTEREST     PIC X(15).
           05  WS-OUT-WAVG-RATE          PIC X(08).
           05  WS-OUT-AVG-DAYS           PIC Z(3)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-ROW-COUNT              PIC S9(04) COMP VALUE +0.
           05  WS-LENDER-IDX            PIC S9(04) COMP VALUE +0.
           05  WS-FOUND-FLAG            PIC X(01)  VALUE 'N'.
           05  WS-DAYS-ON-FLOOR         PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-DAYS            PIC S9(08) COMP VALUE +0.
           05  WS-TOTAL-VEHICLES        PIC S9(04) COMP VALUE +0.
           05  WS-GRAND-BALANCE         PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-GRAND-INTEREST        PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-WAVG-NUMERATOR        PIC S9(13)V9(04) COMP-3
                                                      VALUE +0.
           05  WS-WAVG-RATE             PIC S9(03)V9(04) COMP-3
                                                      VALUE +0.
           05  WS-AVG-DAYS              PIC S9(04) COMP VALUE +0.
      *    NEW/USED COUNTERS
           05  WS-NEW-COUNT             PIC S9(04) COMP VALUE +0.
           05  WS-NEW-BALANCE           PIC S9(11)V99 COMP-3
                                                      VALUE +0.
           05  WS-USED-COUNT            PIC S9(04) COMP VALUE +0.
           05  WS-USED-BALANCE          PIC S9(11)V99 COMP-3
                                                      VALUE +0.
      *    AGE BUCKET COUNTERS
           05  WS-AGE-0-30              PIC S9(04) COMP VALUE +0.
           05  WS-AGE-31-60             PIC S9(04) COMP VALUE +0.
           05  WS-AGE-61-90             PIC S9(04) COMP VALUE +0.
           05  WS-AGE-91-PLUS           PIC S9(04) COMP VALUE +0.
      *    LENDER ACCUMULATOR TABLE
       01  WS-LND-ACCUM-TABLE.
           05  WS-LND-ACCUM OCCURS 8 TIMES.
               10  WS-LA-ID              PIC X(05).
               10  WS-LA-NAME            PIC X(20).
               10  WS-LA-VEH-CT          PIC S9(04) COMP.
               10  WS-LA-BALANCE         PIC S9(11)V99 COMP-3.
               10  WS-LA-INTEREST        PIC S9(11)V99 COMP-3.
               10  WS-LA-RATE-NUM        PIC S9(13)V9(04) COMP-3.
               10  WS-LA-TOTAL-DAYS      PIC S9(08) COMP.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-FPL.
           05  WS-HV-FP-VIN             PIC X(17).
           05  WS-HV-FP-LENDER-ID       PIC X(05).
           05  WS-HV-FP-FLOOR-DATE      PIC X(10).
           05  WS-HV-FP-BALANCE         PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-INTEREST        PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-RATE            PIC S9(03)V9(04) COMP-3.
           05  WS-HV-LND-NAME           PIC X(20).
           05  WS-HV-VEH-CONDITION      PIC X(01).
      *
      *    FORMAT MODULE LINKAGE
      *
       01  WS-FMT-FUNCTION               PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA        PIC X(40).
           05  WS-FMT-INPUT-NUM          PIC S9(09)V99 COMP-3.
       01  WS-FMT-OUTPUT                 PIC X(40).
       01  WS-FMT-RETURN-CODE            PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG              PIC X(50).
      *
      *    INTEREST CALC MODULE LINKAGE
      *
       01  WS-INT-FUNCTION               PIC X(04).
       01  WS-INT-BALANCE                PIC S9(09)V99 COMP-3.
       01  WS-INT-RATE                   PIC S9(03)V9(04) COMP-3.
       01  WS-INT-FROM-DATE              PIC X(10).
       01  WS-INT-TO-DATE                PIC X(10).
       01  WS-INT-RESULT                 PIC S9(09)V99 COMP-3.
       01  WS-INT-RETURN-CODE            PIC S9(04) COMP.
      *
      *    CURSOR FOR EXPOSURE REPORT
      *
           EXEC SQL DECLARE CSR_FPL_EXPOSURE CURSOR FOR
               SELECT FP.VIN
                    , FP.LENDER_ID
                    , FP.FLOOR_DATE
                    , FP.CURRENT_BALANCE
                    , FP.INTEREST_ACCRUED
                    , FP.INTEREST_RATE
                    , SUBSTR(L.LENDER_NAME, 1, 20)
                    , V.VEHICLE_CONDITION
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE FP
               JOIN   AUTOSALE.VEHICLE V
                 ON   FP.VIN = V.VIN
               JOIN   AUTOSALE.LENDER L
                 ON   FP.LENDER_ID = L.LENDER_ID
               WHERE  FP.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  FP.FLOOR_STATUS = 'AC'
               ORDER BY FP.LENDER_ID
                      , FP.FLOOR_DATE
           END-EXEC
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
               PERFORM 4000-BUILD-REPORT
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-FORMAT-OUTPUT
           END-IF
      *
           PERFORM 8000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR WORK AREAS                        *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
           INITIALIZE WS-LND-ACCUM-TABLE
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'FLOOR PLAN EXPOSURE REPORT' TO WS-OUT-TITLE
      *
           EXEC SQL
               SET :WS-CURRENT-TS = CURRENT TIMESTAMP
           END-EXEC
           MOVE WS-CURRENT-TS(1:10) TO WS-CURRENT-DATE
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
           IF IO-STATUS NOT = '  '
               MOVE 'FPLRPT00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'DEALER CODE IS REQUIRED FOR EXPOSURE REPORT'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           END-IF
           .
      *
      ****************************************************************
      *    4000-BUILD-REPORT - ACCUMULATE DATA FROM CURSOR           *
      ****************************************************************
       4000-BUILD-REPORT.
      *
           EXEC SQL OPEN CSR_FPL_EXPOSURE END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLRPT00: ERROR OPENING EXPOSURE CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-OUT-LENDER-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 4100-FETCH-ROW
               UNTIL WS-END-OF-DATA
      *
           EXEC SQL CLOSE CSR_FPL_EXPOSURE END-EXEC
      *
           IF WS-TOTAL-VEHICLES = +0
               MOVE 'NO ACTIVE FLOOR PLAN VEHICLES FOR DEALER'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-ROW - FETCH AND ACCUMULATE                     *
      ****************************************************************
       4100-FETCH-ROW.
      *
           EXEC SQL FETCH CSR_FPL_EXPOSURE
               INTO  :WS-HV-FP-VIN
                    , :WS-HV-FP-LENDER-ID
                    , :WS-HV-FP-FLOOR-DATE
                    , :WS-HV-FP-BALANCE
                    , :WS-HV-FP-INTEREST
                    , :WS-HV-FP-RATE
                    , :WS-HV-LND-NAME
                    , :WS-HV-VEH-CONDITION
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   PERFORM 4200-ACCUMULATE-DATA
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'FPLRPT00: DB2 ERROR READING EXPOSURE DATA'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4200-ACCUMULATE-DATA - ADD TO ACCUMULATORS                *
      ****************************************************************
       4200-ACCUMULATE-DATA.
      *
           ADD +1 TO WS-TOTAL-VEHICLES
           ADD WS-HV-FP-BALANCE TO WS-GRAND-BALANCE
           ADD WS-HV-FP-INTEREST TO WS-GRAND-INTEREST
      *
      *    WEIGHTED AVG RATE NUMERATOR
      *
           COMPUTE WS-WAVG-NUMERATOR =
               WS-WAVG-NUMERATOR
               + (WS-HV-FP-BALANCE * WS-HV-FP-RATE)
      *
      *    CALCULATE DAYS ON FLOOR
      *
           EXEC SQL
               SET :WS-DAYS-ON-FLOOR =
                   DAYS(CURRENT DATE)
                   - DAYS(:WS-HV-FP-FLOOR-DATE)
           END-EXEC
           ADD WS-DAYS-ON-FLOOR TO WS-TOTAL-DAYS
      *
      *    NEW/USED SPLIT
      *
           IF WS-HV-VEH-CONDITION = 'N'
               ADD +1 TO WS-NEW-COUNT
               ADD WS-HV-FP-BALANCE TO WS-NEW-BALANCE
           ELSE
               ADD +1 TO WS-USED-COUNT
               ADD WS-HV-FP-BALANCE TO WS-USED-BALANCE
           END-IF
      *
      *    AGE BUCKET
      *
           EVALUATE TRUE
               WHEN WS-DAYS-ON-FLOOR <= +30
                   ADD +1 TO WS-AGE-0-30
               WHEN WS-DAYS-ON-FLOOR <= +60
                   ADD +1 TO WS-AGE-31-60
               WHEN WS-DAYS-ON-FLOOR <= +90
                   ADD +1 TO WS-AGE-61-90
               WHEN OTHER
                   ADD +1 TO WS-AGE-91-PLUS
           END-EVALUATE
      *
      *    ACCUMULATE BY LENDER
      *
           MOVE 'N' TO WS-FOUND-FLAG
           PERFORM VARYING WS-LENDER-IDX FROM +1 BY +1
               UNTIL WS-LENDER-IDX > WS-OUT-LENDER-COUNT
                  OR WS-FOUND-FLAG = 'Y'
               IF WS-LA-ID(WS-LENDER-IDX)
                   = WS-HV-FP-LENDER-ID
                   MOVE 'Y' TO WS-FOUND-FLAG
               END-IF
           END-PERFORM
      *
           IF WS-FOUND-FLAG = 'Y'
               SUBTRACT +1 FROM WS-LENDER-IDX
           ELSE
               IF WS-OUT-LENDER-COUNT < +8
                   ADD +1 TO WS-OUT-LENDER-COUNT
                   MOVE WS-OUT-LENDER-COUNT TO WS-LENDER-IDX
                   MOVE WS-HV-FP-LENDER-ID
                       TO WS-LA-ID(WS-LENDER-IDX)
                   MOVE WS-HV-LND-NAME
                       TO WS-LA-NAME(WS-LENDER-IDX)
                   MOVE +0 TO WS-LA-VEH-CT(WS-LENDER-IDX)
                   MOVE +0 TO WS-LA-BALANCE(WS-LENDER-IDX)
                   MOVE +0 TO WS-LA-INTEREST(WS-LENDER-IDX)
                   MOVE +0 TO WS-LA-RATE-NUM(WS-LENDER-IDX)
                   MOVE +0 TO WS-LA-TOTAL-DAYS(WS-LENDER-IDX)
               ELSE
                   GO TO 4200-EXIT
               END-IF
           END-IF
      *
           ADD +1 TO WS-LA-VEH-CT(WS-LENDER-IDX)
           ADD WS-HV-FP-BALANCE
               TO WS-LA-BALANCE(WS-LENDER-IDX)
           ADD WS-HV-FP-INTEREST
               TO WS-LA-INTEREST(WS-LENDER-IDX)
           COMPUTE WS-LA-RATE-NUM(WS-LENDER-IDX) =
               WS-LA-RATE-NUM(WS-LENDER-IDX)
               + (WS-HV-FP-BALANCE * WS-HV-FP-RATE)
           ADD WS-DAYS-ON-FLOOR
               TO WS-LA-TOTAL-DAYS(WS-LENDER-IDX)
           .
       4200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-FORMAT-OUTPUT - FORMAT ALL SUMMARY FIELDS             *
      ****************************************************************
       5000-FORMAT-OUTPUT.
      *
      *    CALCULATE WEIGHTED AVG RATE
      *
           IF WS-GRAND-BALANCE > +0
               COMPUTE WS-WAVG-RATE =
                   WS-WAVG-NUMERATOR / WS-GRAND-BALANCE
           END-IF
      *
      *    CALCULATE AVERAGE DAYS
      *
           IF WS-TOTAL-VEHICLES > +0
               COMPUTE WS-AVG-DAYS =
                   WS-TOTAL-DAYS / WS-TOTAL-VEHICLES
           END-IF
      *
      *    FORMAT LENDER DETAILS
      *
           MOVE 'CUR ' TO WS-FMT-FUNCTION
           PERFORM VARYING WS-LENDER-IDX FROM +1 BY +1
               UNTIL WS-LENDER-IDX > WS-OUT-LENDER-COUNT
      *
               MOVE WS-LA-ID(WS-LENDER-IDX)
                   TO WS-OUT-LND-ID(WS-LENDER-IDX)
               MOVE WS-LA-NAME(WS-LENDER-IDX)
                   TO WS-OUT-LND-NAME(WS-LENDER-IDX)
               MOVE WS-LA-VEH-CT(WS-LENDER-IDX)
                   TO WS-OUT-LND-VEH-CT(WS-LENDER-IDX)
      *
               MOVE WS-LA-BALANCE(WS-LENDER-IDX)
                   TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:15)
                   TO WS-OUT-LND-BALANCE(WS-LENDER-IDX)
      *
               MOVE WS-LA-INTEREST(WS-LENDER-IDX)
                   TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:13)
                   TO WS-OUT-LND-INTEREST(WS-LENDER-IDX)
      *
      *        LENDER AVG RATE
      *
               IF WS-LA-BALANCE(WS-LENDER-IDX) > +0
                   COMPUTE WS-WAVG-RATE =
                       WS-LA-RATE-NUM(WS-LENDER-IDX)
                       / WS-LA-BALANCE(WS-LENDER-IDX)
                   MOVE 'PCT ' TO WS-FMT-FUNCTION
                   MOVE WS-WAVG-RATE TO WS-FMT-INPUT-NUM
                   CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                         WS-FMT-INPUT
                                         WS-FMT-OUTPUT
                                         WS-FMT-RETURN-CODE
                                         WS-FMT-ERROR-MSG
                   MOVE WS-FMT-OUTPUT(1:8)
                       TO WS-OUT-LND-AVG-RATE(WS-LENDER-IDX)
               END-IF
      *
      *        LENDER AVG DAYS
      *
               IF WS-LA-VEH-CT(WS-LENDER-IDX) > +0
                   COMPUTE WS-AVG-DAYS =
                       WS-LA-TOTAL-DAYS(WS-LENDER-IDX)
                       / WS-LA-VEH-CT(WS-LENDER-IDX)
                   MOVE WS-AVG-DAYS
                       TO WS-OUT-LND-AVG-DAYS(WS-LENDER-IDX)
               END-IF
           END-PERFORM
      *
      *    FORMAT AGE BUCKETS
      *
           MOVE WS-AGE-0-30 TO WS-OUT-AGE-0-30
           MOVE WS-AGE-31-60 TO WS-OUT-AGE-31-60
           MOVE WS-AGE-61-90 TO WS-OUT-AGE-61-90
           MOVE WS-AGE-91-PLUS TO WS-OUT-AGE-91-PLUS
      *
      *    FORMAT NEW/USED
      *
           MOVE WS-NEW-COUNT TO WS-OUT-NEW-COUNT
           MOVE WS-USED-COUNT TO WS-OUT-USED-COUNT
      *
           MOVE 'CUR ' TO WS-FMT-FUNCTION
           MOVE WS-NEW-BALANCE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-NEW-BALANCE
      *
           MOVE WS-USED-BALANCE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-USED-BALANCE
      *
      *    FORMAT GRAND TOTALS
      *
           MOVE WS-TOTAL-VEHICLES TO WS-OUT-GRAND-VEHICLES
      *
           MOVE WS-GRAND-BALANCE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-GRAND-BALANCE
      *
           MOVE WS-GRAND-INTEREST TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-GRAND-INTEREST
      *
      *    WEIGHTED AVERAGE RATE
      *
           IF WS-GRAND-BALANCE > +0
               COMPUTE WS-WAVG-RATE =
                   WS-WAVG-NUMERATOR / WS-GRAND-BALANCE
               MOVE 'PCT ' TO WS-FMT-FUNCTION
               MOVE WS-WAVG-RATE TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:8) TO WS-OUT-WAVG-RATE
           END-IF
      *
           MOVE WS-AVG-DAYS TO WS-OUT-AVG-DAYS
      *
           MOVE 'FLOOR PLAN EXPOSURE REPORT GENERATED'
               TO WS-OUT-MESSAGE
           .
      *
      ****************************************************************
      *    8000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       8000-SEND-OUTPUT.
      *
           COMPUTE WS-OUT-LL =
               FUNCTION LENGTH(WS-OUTPUT-MSG)
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-STATUS NOT = '  '
               CONTINUE
           END-IF
           .
      ****************************************************************
      * END OF FPLRPT00                                              *
      ****************************************************************
