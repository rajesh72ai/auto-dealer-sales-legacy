       IDENTIFICATION DIVISION.
       PROGRAM-ID. FPLINT00.
      ****************************************************************
      * PROGRAM:  FPLINT00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FPL - FLOOR PLAN INTEREST CALCULATION              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CALCULATES DAILY INTEREST ACCRUAL FOR FLOOR PLAN   *
      *           VEHICLES. SUPPORTS SINGLE VIN (ONLINE TRIGGER)     *
      *           OR BATCH MODE (ALL ACTIVE VEHICLES). UPDATES       *
      *           FLOOR_PLAN_VEHICLE.INTEREST_ACCRUED AND INSERTS    *
      *           FLOOR_PLAN_INTEREST DAILY DETAIL RECORDS.          *
      *           FLAGS CURTAILMENT APPROACHING (WITHIN 15 DAYS).    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FPLN - FLOOR PLAN INTEREST                         *
      * MFS MOD:  ASFPLN00                                           *
      * TABLES:   AUTOSALE.FLOOR_PLAN_VEHICLE  (READ/UPDATE)         *
      *           AUTOSALE.FLOOR_PLAN_INTEREST (INSERT)              *
      * CALLS:    COMINTL0 - INTEREST CALCULATION                    *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
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
                                          VALUE 'FPLINT00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASFPLN00'.
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
           05  WS-IN-MODE                PIC X(01).
               88  WS-IN-SINGLE                      VALUE 'S'.
               88  WS-IN-BATCH                       VALUE 'B'.
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-DEALER-CODE         PIC X(05).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-MODE               PIC X(10).
           05  WS-OUT-PROCESSED          PIC Z(4)9.
           05  WS-OUT-UPDATED            PIC Z(4)9.
           05  WS-OUT-CURTAIL-WARN       PIC Z(4)9.
           05  WS-OUT-ERRORS             PIC Z(4)9.
           05  WS-OUT-TOTAL-INTEREST     PIC X(15).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-PROCESSED-COUNT        PIC S9(04) COMP VALUE +0.
           05  WS-UPDATED-COUNT          PIC S9(04) COMP VALUE +0.
           05  WS-CURTAIL-WARN-CT        PIC S9(04) COMP VALUE +0.
           05  WS-ERROR-COUNT            PIC S9(04) COMP VALUE +0.
           05  WS-DAILY-INTEREST         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NEW-ACCRUED            PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-INTEREST         PIC S9(11)V99 COMP-3
                                                       VALUE +0.
           05  WS-DAYS-TO-CURTAIL        PIC S9(04) COMP VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-CURTAIL-THRESHOLD      PIC S9(04) COMP VALUE +15.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-FPL.
           05  WS-HV-FP-ID              PIC X(12).
           05  WS-HV-FP-VIN             PIC X(17).
           05  WS-HV-FP-DEALER-CODE     PIC X(05).
           05  WS-HV-FP-LENDER-ID       PIC X(05).
           05  WS-HV-FP-FLOOR-DATE      PIC X(10).
           05  WS-HV-FP-CURTAIL-DATE    PIC X(10).
           05  WS-HV-FP-BALANCE         PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-INTEREST-ACC    PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-STATUS          PIC X(02).
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
      *    DB ERROR MODULE LINKAGE
      *
       01  WS-DBE-SQLCODE                PIC S9(09) COMP.
       01  WS-DBE-PROGRAM                PIC X(08).
       01  WS-DBE-PARAGRAPH              PIC X(30).
       01  WS-DBE-TABLE-NAME             PIC X(18).
       01  WS-DBE-RETURN-CODE            PIC S9(04) COMP.
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
      *    CURSOR FOR BATCH PROCESSING
      *
           EXEC SQL DECLARE CSR_FPL_ACTIVE CURSOR FOR
               SELECT FP.FLOOR_PLAN_ID
                    , FP.VIN
                    , FP.DEALER_CODE
                    , FP.LENDER_ID
                    , FP.FLOOR_DATE
                    , FP.CURTAILMENT_DATE
                    , FP.CURRENT_BALANCE
                    , FP.INTEREST_ACCRUED
                    , FP.FLOOR_STATUS
                    , FP.INTEREST_RATE
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE FP
               WHERE  FP.FLOOR_STATUS = 'AC'
                 AND  (FP.DEALER_CODE = :WS-IN-DEALER-CODE
                       OR :WS-IN-DEALER-CODE = '     ')
               ORDER BY FP.DEALER_CODE
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
               EVALUATE TRUE
                   WHEN WS-IN-SINGLE
                       PERFORM 4000-PROCESS-SINGLE
                   WHEN WS-IN-BATCH
                       PERFORM 5000-PROCESS-BATCH
                   WHEN OTHER
                       PERFORM 5000-PROCESS-BATCH
               END-EVALUATE
           END-IF
      *
           PERFORM 7000-FORMAT-OUTPUT
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
           MOVE 'FLOOR PLAN - INTEREST CALCULATION' TO WS-OUT-TITLE
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
               MOVE 'FPLINT00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK MODE AND REQUIRED FIELDS      *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-SINGLE
               IF WS-IN-VIN = SPACES
                   MOVE 'VIN REQUIRED FOR SINGLE VEHICLE MODE'
                       TO WS-OUT-MESSAGE
               END-IF
               MOVE 'SINGLE' TO WS-OUT-MODE
           ELSE
               MOVE 'BATCH' TO WS-OUT-MODE
           END-IF
           .
      *
      ****************************************************************
      *    4000-PROCESS-SINGLE - CALCULATE INTEREST FOR ONE VIN      *
      ****************************************************************
       4000-PROCESS-SINGLE.
      *
           EXEC SQL
               SELECT FP.FLOOR_PLAN_ID
                    , FP.VIN
                    , FP.DEALER_CODE
                    , FP.LENDER_ID
                    , FP.FLOOR_DATE
                    , FP.CURTAILMENT_DATE
                    , FP.CURRENT_BALANCE
                    , FP.INTEREST_ACCRUED
                    , FP.FLOOR_STATUS
                    , FP.INTEREST_RATE
               INTO  :WS-HV-FP-ID
                    , :WS-HV-FP-VIN
                    , :WS-HV-FP-DEALER-CODE
                    , :WS-HV-FP-LENDER-ID
                    , :WS-HV-FP-FLOOR-DATE
                    , :WS-HV-FP-CURTAIL-DATE
                    , :WS-HV-FP-BALANCE
                    , :WS-HV-FP-INTEREST-ACC
                    , :WS-HV-FP-STATUS
                    , :WS-HV-FP-RATE
               FROM  AUTOSALE.FLOOR_PLAN_VEHICLE FP
               WHERE FP.VIN = :WS-IN-VIN
                 AND FP.FLOOR_STATUS = 'AC'
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE 'NO ACTIVE FLOOR PLAN FOUND FOR THIS VIN'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               MOVE 'FPLINT00: DB2 ERROR READING FLOOR PLAN'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           PERFORM 6000-CALC-AND-UPDATE
      *
           ADD +1 TO WS-PROCESSED-COUNT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-BATCH - ITERATE ALL ACTIVE FLOOR PLANS       *
      ****************************************************************
       5000-PROCESS-BATCH.
      *
           EXEC SQL OPEN CSR_FPL_ACTIVE END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLINT00: ERROR OPENING ACTIVE FPL CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 5100-FETCH-ACTIVE
               UNTIL WS-END-OF-DATA
      *
           EXEC SQL CLOSE CSR_FPL_ACTIVE END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-ACTIVE - FETCH NEXT ACTIVE FLOOR PLAN          *
      ****************************************************************
       5100-FETCH-ACTIVE.
      *
           EXEC SQL FETCH CSR_FPL_ACTIVE
               INTO  :WS-HV-FP-ID
                    , :WS-HV-FP-VIN
                    , :WS-HV-FP-DEALER-CODE
                    , :WS-HV-FP-LENDER-ID
                    , :WS-HV-FP-FLOOR-DATE
                    , :WS-HV-FP-CURTAIL-DATE
                    , :WS-HV-FP-BALANCE
                    , :WS-HV-FP-INTEREST-ACC
                    , :WS-HV-FP-STATUS
                    , :WS-HV-FP-RATE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-PROCESSED-COUNT
                   PERFORM 6000-CALC-AND-UPDATE
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   ADD +1 TO WS-ERROR-COUNT
           END-EVALUATE
           .
      *
      ****************************************************************
      *    6000-CALC-AND-UPDATE - CALCULATE AND RECORD INTEREST      *
      ****************************************************************
       6000-CALC-AND-UPDATE.
      *
      *    CALCULATE DAILY INTEREST VIA COMINTL0
      *
           MOVE 'DAY ' TO WS-INT-FUNCTION
           MOVE WS-HV-FP-BALANCE TO WS-INT-BALANCE
           MOVE WS-HV-FP-RATE TO WS-INT-RATE
           MOVE WS-CURRENT-DATE TO WS-INT-FROM-DATE
           MOVE WS-CURRENT-DATE TO WS-INT-TO-DATE
      *
           CALL 'COMINTL0' USING WS-INT-FUNCTION
                                 WS-INT-BALANCE
                                 WS-INT-RATE
                                 WS-INT-FROM-DATE
                                 WS-INT-TO-DATE
                                 WS-INT-RESULT
                                 WS-INT-RETURN-CODE
      *
           IF WS-INT-RETURN-CODE NOT = +0
               ADD +1 TO WS-ERROR-COUNT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-INT-RESULT TO WS-DAILY-INTEREST
           COMPUTE WS-NEW-ACCRUED =
               WS-HV-FP-INTEREST-ACC + WS-DAILY-INTEREST
           ADD WS-DAILY-INTEREST TO WS-TOTAL-INTEREST
      *
      *    UPDATE FLOOR PLAN VEHICLE INTEREST ACCRUED
      *
           EXEC SQL
               UPDATE AUTOSALE.FLOOR_PLAN_VEHICLE
               SET    INTEREST_ACCRUED  = :WS-NEW-ACCRUED
                    , UPDATED_TIMESTAMP = CURRENT TIMESTAMP
                    , UPDATED_USER     = :IO-USER
               WHERE  FLOOR_PLAN_ID    = :WS-HV-FP-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLINT00' TO WS-DBE-PROGRAM
               MOVE '6000-CALC-AND-UPDATE' TO WS-DBE-PARAGRAPH
               MOVE 'FLOOR_PLAN_VEHICLE' TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               ADD +1 TO WS-ERROR-COUNT
               GO TO 6000-EXIT
           END-IF
      *
      *    INSERT DAILY INTEREST DETAIL RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.FLOOR_PLAN_INTEREST
               ( FLOOR_PLAN_ID
               , INTEREST_DATE
               , DAILY_BALANCE
               , DAILY_RATE
               , DAILY_INTEREST
               , CUMULATIVE_INTEREST
               , CREATED_TIMESTAMP
               )
               VALUES
               ( :WS-HV-FP-ID
               , :WS-CURRENT-DATE
               , :WS-HV-FP-BALANCE
               , :WS-HV-FP-RATE
               , :WS-DAILY-INTEREST
               , :WS-NEW-ACCRUED
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLINT00' TO WS-DBE-PROGRAM
               MOVE '6000-CALC-AND-UPDATE' TO WS-DBE-PARAGRAPH
               MOVE 'FLOOR_PLAN_INTEREST' TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               ADD +1 TO WS-ERROR-COUNT
               GO TO 6000-EXIT
           END-IF
      *
           ADD +1 TO WS-UPDATED-COUNT
      *
      *    CHECK CURTAILMENT APPROACHING
      *
           EXEC SQL
               SET :WS-DAYS-TO-CURTAIL =
                   DAYS(:WS-HV-FP-CURTAIL-DATE)
                   - DAYS(CURRENT DATE)
           END-EXEC
      *
           IF WS-DAYS-TO-CURTAIL >= +0
           AND WS-DAYS-TO-CURTAIL <= WS-CURTAIL-THRESHOLD
               ADD +1 TO WS-CURTAIL-WARN-CT
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-FORMAT-OUTPUT - BUILD SUMMARY OUTPUT                  *
      ****************************************************************
       7000-FORMAT-OUTPUT.
      *
           MOVE WS-PROCESSED-COUNT TO WS-OUT-PROCESSED
           MOVE WS-UPDATED-COUNT TO WS-OUT-UPDATED
           MOVE WS-CURTAIL-WARN-CT TO WS-OUT-CURTAIL-WARN
           MOVE WS-ERROR-COUNT TO WS-OUT-ERRORS
      *
      *    FORMAT TOTAL INTEREST
      *
           MOVE 'CUR ' TO WS-FMT-FUNCTION
           MOVE WS-TOTAL-INTEREST TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-TOTAL-INTEREST
      *
           IF WS-OUT-MESSAGE = SPACES
               IF WS-ERROR-COUNT > +0
                   MOVE 'INTEREST CALC COMPLETE WITH ERRORS'
                       TO WS-OUT-MESSAGE
               ELSE
                   MOVE 'INTEREST CALCULATION COMPLETED SUCCESSFULLY'
                       TO WS-OUT-MESSAGE
               END-IF
           END-IF
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
      * END OF FPLINT00                                              *
      ****************************************************************
