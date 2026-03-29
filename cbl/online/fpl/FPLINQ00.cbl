       IDENTIFICATION DIVISION.
       PROGRAM-ID. FPLINQ00.
      ****************************************************************
      * PROGRAM:  FPLINQ00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FPL - FLOOR PLAN INQUIRY                           *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DISPLAYS FLOOR PLAN VEHICLES FOR A DEALER WITH     *
      *           OPTIONAL FILTERS BY VIN, STATUS, OR LENDER.        *
      *           SHOWS VIN, MODEL DESC, FLOOR DATE, DAYS ON FLOOR,  *
      *           BALANCE, INTEREST ACCRUED, AND STATUS.             *
      *           CALCULATES TOTALS FOR BALANCE AND INTEREST.        *
      *           SUPPORTS PF7/PF8 FORWARD/BACKWARD PAGING.         *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FPLI - FLOOR PLAN INQUIRY                          *
      * MFS MOD:  ASFPLI00                                           *
      * TABLES:   AUTOSALE.FLOOR_PLAN_VEHICLE (READ)                 *
      *           AUTOSALE.VEHICLE            (READ)                  *
      *           AUTOSALE.MODEL_MASTER       (READ)                  *
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
                                          VALUE 'FPLINQ00'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASFPLI00'.
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
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-STATUS-FILTER       PIC X(02).
           05  WS-IN-LENDER-FILTER       PIC X(05).
           05  WS-IN-PAGE-ACTION         PIC X(01).
               88  WS-PAGE-FORWARD                   VALUE 'F'.
               88  WS-PAGE-BACKWARD                  VALUE 'B'.
               88  WS-PAGE-FIRST                     VALUE ' '.
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-DETAIL-COUNT       PIC S9(04) COMP.
           05  WS-OUT-DETAIL OCCURS 12 TIMES.
               10  WS-OUT-VIN            PIC X(17).
               10  WS-OUT-MODEL-DESC     PIC X(20).
               10  WS-OUT-FLOOR-DATE     PIC X(10).
               10  WS-OUT-DAYS-ON-FLR    PIC Z(3)9.
               10  WS-OUT-BALANCE        PIC X(13).
               10  WS-OUT-INTEREST       PIC X(11).
               10  WS-OUT-STATUS         PIC X(02).
           05  WS-OUT-TOT-BALANCE        PIC X(15).
           05  WS-OUT-TOT-INTEREST       PIC X(15).
           05  WS-OUT-PAGE-INFO          PIC X(20).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ROW-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-SKIP-COUNT             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-PAGE-NUMBER            PIC S9(04) COMP
                                                     VALUE +1.
           05  WS-ROWS-PER-PAGE          PIC S9(04) COMP
                                                     VALUE +12.
           05  WS-TOTAL-ROWS             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-DAYS-ON-FLOOR          PIC S9(04) COMP VALUE +0.
           05  WS-SUM-BALANCE            PIC S9(11)V99 COMP-3
                                                       VALUE +0.
           05  WS-SUM-INTEREST           PIC S9(11)V99 COMP-3
                                                       VALUE +0.
           05  WS-CALC-INTEREST          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-FPL.
           05  WS-HV-FP-VIN             PIC X(17).
           05  WS-HV-FP-FLOOR-DATE      PIC X(10).
           05  WS-HV-FP-BALANCE         PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-INTEREST        PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-STATUS          PIC X(02).
           05  WS-HV-FP-LENDER-ID       PIC X(05).
           05  WS-HV-FP-CURTAIL-DATE    PIC X(10).
           05  WS-HV-MODEL-DESC         PIC X(20).
           05  WS-HV-FP-RATE            PIC S9(03)V9(04) COMP-3.
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
      *    CURSOR FOR FLOOR PLAN INQUIRY
      *
           EXEC SQL DECLARE CSR_FPL_INQ CURSOR FOR
               SELECT FP.VIN
                    , FP.FLOOR_DATE
                    , FP.CURRENT_BALANCE
                    , FP.INTEREST_ACCRUED
                    , FP.FLOOR_STATUS
                    , FP.LENDER_ID
                    , FP.CURTAILMENT_DATE
                    , SUBSTR(M.MODEL_NAME, 1, 20)
                    , FP.INTEREST_RATE
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE FP
               JOIN   AUTOSALE.VEHICLE V
                 ON   FP.VIN = V.VIN
               JOIN   AUTOSALE.MODEL_MASTER M
                 ON   V.MODEL_YEAR = M.MODEL_YEAR
                AND   V.MAKE_CODE  = M.MAKE_CODE
                AND   V.MODEL_CODE = M.MODEL_CODE
               WHERE  FP.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  (FP.VIN = :WS-IN-VIN
                       OR :WS-IN-VIN = SPACES)
                 AND  (FP.FLOOR_STATUS = :WS-IN-STATUS-FILTER
                       OR :WS-IN-STATUS-FILTER = '  ')
                 AND  (FP.LENDER_ID = :WS-IN-LENDER-FILTER
                       OR :WS-IN-LENDER-FILTER = '     ')
               ORDER BY FP.FLOOR_DATE DESC
                      , FP.VIN
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
               PERFORM 4000-RETRIEVE-FLOOR-PLAN
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
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'FLOOR PLAN INQUIRY' TO WS-OUT-TITLE
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
               MOVE 'FPLINQ00: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'DEALER CODE IS REQUIRED FOR FLOOR PLAN INQ'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
      *
      *    HANDLE PAGING
      *
           IF WS-PAGE-FORWARD
               ADD +1 TO WS-PAGE-NUMBER
           END-IF
           IF WS-PAGE-BACKWARD
               IF WS-PAGE-NUMBER > +1
                   SUBTRACT +1 FROM WS-PAGE-NUMBER
               END-IF
           END-IF
      *
           COMPUTE WS-SKIP-COUNT =
               (WS-PAGE-NUMBER - 1) * WS-ROWS-PER-PAGE
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-RETRIEVE-FLOOR-PLAN - OPEN CURSOR AND FETCH          *
      ****************************************************************
       4000-RETRIEVE-FLOOR-PLAN.
      *
           EXEC SQL OPEN CSR_FPL_INQ END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLINQ00: ERROR OPENING FLOOR PLAN CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE +0 TO WS-TOTAL-ROWS
           MOVE +0 TO WS-SUM-BALANCE
           MOVE +0 TO WS-SUM-INTEREST
           MOVE 'N' TO WS-EOF-FLAG
      *
      *    SKIP ROWS FOR PAGING
      *
           PERFORM WS-SKIP-COUNT TIMES
               PERFORM 4100-FETCH-ROW
               IF WS-END-OF-DATA
                   EXIT PERFORM
               END-IF
               ADD +1 TO WS-TOTAL-ROWS
           END-PERFORM
      *
      *    FETCH CURRENT PAGE ROWS
      *
           IF NOT WS-END-OF-DATA
               PERFORM 4100-FETCH-ROW
                   UNTIL WS-END-OF-DATA
                   OR WS-ROW-COUNT >= WS-ROWS-PER-PAGE
           END-IF
      *
           EXEC SQL CLOSE CSR_FPL_INQ END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO FLOOR PLAN RECORDS FOUND FOR CRITERIA'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-ROW-COUNT TO WS-OUT-DETAIL-COUNT
      *
      *        FORMAT TOTALS
      *
               MOVE 'CUR ' TO WS-FMT-FUNCTION
               MOVE WS-SUM-BALANCE TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-TOT-BALANCE
      *
               MOVE WS-SUM-INTEREST TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-TOT-INTEREST
      *
               STRING 'PAGE ' WS-PAGE-NUMBER
                      DELIMITED BY SIZE
                   INTO WS-OUT-PAGE-INFO
               END-STRING
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-ROW - FETCH ONE ROW FROM CURSOR                *
      ****************************************************************
       4100-FETCH-ROW.
      *
           EXEC SQL FETCH CSR_FPL_INQ
               INTO  :WS-HV-FP-VIN
                    , :WS-HV-FP-FLOOR-DATE
                    , :WS-HV-FP-BALANCE
                    , :WS-HV-FP-INTEREST
                    , :WS-HV-FP-STATUS
                    , :WS-HV-FP-LENDER-ID
                    , :WS-HV-FP-CURTAIL-DATE
                    , :WS-HV-MODEL-DESC
                    , :WS-HV-FP-RATE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   PERFORM 4200-FORMAT-DETAIL-LINE
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'FPLINQ00: DB2 ERROR READING FLOOR PLAN'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4200-FORMAT-DETAIL-LINE - POPULATE OUTPUT DETAIL ROW      *
      ****************************************************************
       4200-FORMAT-DETAIL-LINE.
      *
           MOVE WS-HV-FP-VIN
               TO WS-OUT-VIN(WS-ROW-COUNT)
           MOVE WS-HV-MODEL-DESC
               TO WS-OUT-MODEL-DESC(WS-ROW-COUNT)
           MOVE WS-HV-FP-FLOOR-DATE
               TO WS-OUT-FLOOR-DATE(WS-ROW-COUNT)
           MOVE WS-HV-FP-STATUS
               TO WS-OUT-STATUS(WS-ROW-COUNT)
      *
      *    CALCULATE DAYS ON FLOOR
      *
           EXEC SQL
               SET :WS-DAYS-ON-FLOOR =
                   DAYS(CURRENT DATE)
                   - DAYS(:WS-HV-FP-FLOOR-DATE)
           END-EXEC
           MOVE WS-DAYS-ON-FLOOR
               TO WS-OUT-DAYS-ON-FLR(WS-ROW-COUNT)
      *
      *    CALCULATE CURRENT INTEREST VIA COMINTL0
      *
           MOVE 'CALC' TO WS-INT-FUNCTION
           MOVE WS-HV-FP-BALANCE TO WS-INT-BALANCE
           MOVE WS-HV-FP-RATE TO WS-INT-RATE
           MOVE WS-HV-FP-FLOOR-DATE TO WS-INT-FROM-DATE
           MOVE WS-CURRENT-DATE TO WS-INT-TO-DATE
           CALL 'COMINTL0' USING WS-INT-FUNCTION
                                 WS-INT-BALANCE
                                 WS-INT-RATE
                                 WS-INT-FROM-DATE
                                 WS-INT-TO-DATE
                                 WS-INT-RESULT
                                 WS-INT-RETURN-CODE
           MOVE WS-INT-RESULT TO WS-CALC-INTEREST
      *
      *    FORMAT BALANCE
      *
           MOVE 'CUR ' TO WS-FMT-FUNCTION
           MOVE WS-HV-FP-BALANCE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:13)
               TO WS-OUT-BALANCE(WS-ROW-COUNT)
      *
      *    FORMAT INTEREST
      *
           MOVE WS-CALC-INTEREST TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:11)
               TO WS-OUT-INTEREST(WS-ROW-COUNT)
      *
      *    ACCUMULATE TOTALS
      *
           ADD WS-HV-FP-BALANCE TO WS-SUM-BALANCE
           ADD WS-CALC-INTEREST TO WS-SUM-INTEREST
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
      * END OF FPLINQ00                                              *
      ****************************************************************
