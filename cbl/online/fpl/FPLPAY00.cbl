       IDENTIFICATION DIVISION.
       PROGRAM-ID. FPLPAY00.
      ****************************************************************
      * PROGRAM:  FPLPAY00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FPL - FLOOR PLAN PAYOFF                            *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PROCESSES FLOOR PLAN PAYOFF WHEN A VEHICLE IS      *
      *           SOLD OR TRANSFERRED. CALCULATES FINAL INTEREST     *
      *           UP TO PAYOFF DATE. UPDATES FLOOR_PLAN_VEHICLE:     *
      *           STATUS=PD (PAID), PAYOFF_DATE, FINAL BALANCE.      *
      *           UPDATES CUMULATIVE INTEREST FIELDS.                *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FPLP - FLOOR PLAN PAYOFF                           *
      * MFS MOD:  ASFPLP00                                           *
      * TABLES:   AUTOSALE.FLOOR_PLAN_VEHICLE (READ/UPDATE)          *
      * CALLS:    COMINTL0 - INTEREST CALCULATION                    *
      *           COMFMTL0 - FIELD FORMATTING                        *
      *           COMLGEL0 - AUDIT LOGGING                           *
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
                                          VALUE 'FPLPAY00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASFPLP00'.
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
           05  WS-IN-VIN                 PIC X(17).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-FLOOR-DATE         PIC X(10).
           05  WS-OUT-PAYOFF-DATE        PIC X(10).
           05  WS-OUT-ORIG-BALANCE       PIC X(13).
           05  WS-OUT-FINAL-INTEREST     PIC X(11).
           05  WS-OUT-TOTAL-PAYOFF       PIC X(15).
           05  WS-OUT-LENDER-ID          PIC X(05).
           05  WS-OUT-STATUS             PIC X(02).
           05  WS-OUT-DAYS-ON-FLOOR      PIC Z(3)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-FINAL-INTEREST         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOTAL-PAYOFF           PIC S9(11)V99 COMP-3
                                                       VALUE +0.
           05  WS-DAYS-ON-FLOOR          PIC S9(04) COMP VALUE +0.
           05  WS-CUMUL-INTEREST         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-FPL.
           05  WS-HV-FP-ID              PIC X(12).
           05  WS-HV-FP-VIN             PIC X(17).
           05  WS-HV-FP-DEALER-CODE     PIC X(05).
           05  WS-HV-FP-LENDER-ID       PIC X(05).
           05  WS-HV-FP-FLOOR-DATE      PIC X(10).
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
      *    LOG MODULE LINKAGE
      *
       01  WS-LOG-FUNCTION               PIC X(04).
       01  WS-LOG-PROGRAM                PIC X(08).
       01  WS-LOG-TABLE-NAME             PIC X(18).
       01  WS-LOG-ACTION                 PIC X(08).
       01  WS-LOG-KEY-VALUE              PIC X(40).
       01  WS-LOG-DETAILS                PIC X(200).
       01  WS-LOG-RETURN-CODE            PIC S9(04) COMP.
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
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-CALCULATE-INTEREST
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6000-UPDATE-PAYOFF
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
           MOVE 'FLOOR PLAN - PAYOFF' TO WS-OUT-TITLE
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
               MOVE 'FPLPAY00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-VIN = SPACES
               MOVE 'VIN IS REQUIRED FOR FLOOR PLAN PAYOFF'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    4000-RETRIEVE-FLOOR-PLAN - READ ACTIVE FLOOR PLAN         *
      ****************************************************************
       4000-RETRIEVE-FLOOR-PLAN.
      *
           EXEC SQL
               SELECT FP.FLOOR_PLAN_ID
                    , FP.VIN
                    , FP.DEALER_CODE
                    , FP.LENDER_ID
                    , FP.FLOOR_DATE
                    , FP.CURRENT_BALANCE
                    , FP.INTEREST_ACCRUED
                    , FP.FLOOR_STATUS
                    , FP.INTEREST_RATE
               INTO  :WS-HV-FP-ID
                    , :WS-HV-FP-VIN
                    , :WS-HV-FP-DEALER-CODE
                    , :WS-HV-FP-LENDER-ID
                    , :WS-HV-FP-FLOOR-DATE
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
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE 'NO ACTIVE FLOOR PLAN FOUND FOR THIS VIN'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE 'FPLPAY00: DB2 ERROR READING FLOOR PLAN'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
      *
           IF WS-OUT-MESSAGE = SPACES
               MOVE WS-HV-FP-VIN TO WS-OUT-VIN
               MOVE WS-HV-FP-FLOOR-DATE TO WS-OUT-FLOOR-DATE
               MOVE WS-HV-FP-LENDER-ID TO WS-OUT-LENDER-ID
      *
      *        CALCULATE DAYS ON FLOOR
      *
               EXEC SQL
                   SET :WS-DAYS-ON-FLOOR =
                       DAYS(CURRENT DATE)
                       - DAYS(:WS-HV-FP-FLOOR-DATE)
               END-EXEC
               MOVE WS-DAYS-ON-FLOOR TO WS-OUT-DAYS-ON-FLOOR
           END-IF
           .
      *
      ****************************************************************
      *    5000-CALCULATE-INTEREST - FINAL INTEREST TO PAYOFF DATE   *
      ****************************************************************
       5000-CALCULATE-INTEREST.
      *
           MOVE 'CALC' TO WS-INT-FUNCTION
           MOVE WS-HV-FP-BALANCE TO WS-INT-BALANCE
           MOVE WS-HV-FP-RATE TO WS-INT-RATE
           MOVE WS-HV-FP-FLOOR-DATE TO WS-INT-FROM-DATE
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
           IF WS-INT-RETURN-CODE = +0
               MOVE WS-INT-RESULT TO WS-FINAL-INTEREST
               COMPUTE WS-TOTAL-PAYOFF =
                   WS-HV-FP-BALANCE + WS-FINAL-INTEREST
               COMPUTE WS-CUMUL-INTEREST =
                   WS-HV-FP-INTEREST-ACC + WS-FINAL-INTEREST
           ELSE
               MOVE 'FPLPAY00: ERROR CALCULATING INTEREST'
                   TO WS-OUT-MESSAGE
           END-IF
      *
      *    FORMAT OUTPUT AMOUNTS
      *
           IF WS-OUT-MESSAGE = SPACES
               MOVE 'CUR ' TO WS-FMT-FUNCTION
      *
               MOVE WS-HV-FP-BALANCE TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:13) TO WS-OUT-ORIG-BALANCE
      *
               MOVE WS-FINAL-INTEREST TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:11) TO WS-OUT-FINAL-INTEREST
      *
               MOVE WS-TOTAL-PAYOFF TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:15) TO WS-OUT-TOTAL-PAYOFF
           END-IF
           .
      *
      ****************************************************************
      *    6000-UPDATE-PAYOFF - SET STATUS TO PD AND RECORD PAYOFF   *
      ****************************************************************
       6000-UPDATE-PAYOFF.
      *
           EXEC SQL
               UPDATE AUTOSALE.FLOOR_PLAN_VEHICLE
               SET    FLOOR_STATUS     = 'PD'
                    , PAYOFF_DATE      = :WS-CURRENT-DATE
                    , CURRENT_BALANCE  = 0
                    , INTEREST_ACCRUED = :WS-CUMUL-INTEREST
                    , UPDATED_TIMESTAMP = CURRENT TIMESTAMP
                    , UPDATED_USER     = :IO-USER
               WHERE  FLOOR_PLAN_ID   = :WS-HV-FP-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLPAY00: DB2 ERROR UPDATING FLOOR PLAN'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-CURRENT-DATE TO WS-OUT-PAYOFF-DATE
           MOVE 'PD' TO WS-OUT-STATUS
      *
      *    LOG THE PAYOFF
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'FLOOR_PLAN_VEHICLE' TO WS-LOG-TABLE-NAME
           MOVE 'UPDATE' TO WS-LOG-ACTION
           MOVE WS-HV-FP-ID TO WS-LOG-KEY-VALUE
           STRING 'FLOOR PLAN PAYOFF VIN=' WS-IN-VIN
                  ' TOTAL=' WS-TOTAL-PAYOFF
                  DELIMITED BY '  '
               INTO WS-LOG-DETAILS
           END-STRING
           CALL 'COMLGEL0' USING WS-LOG-FUNCTION
                                 WS-LOG-PROGRAM
                                 WS-LOG-TABLE-NAME
                                 WS-LOG-ACTION
                                 WS-LOG-KEY-VALUE
                                 WS-LOG-DETAILS
                                 WS-LOG-RETURN-CODE
      *
           MOVE 'FLOOR PLAN PAYOFF COMPLETED SUCCESSFULLY'
               TO WS-OUT-MESSAGE
           .
       6000-EXIT.
           EXIT.
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
      * END OF FPLPAY00                                              *
      ****************************************************************
