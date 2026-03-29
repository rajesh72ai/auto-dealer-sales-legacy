       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKAGIN0.
      ****************************************************************
      * PROGRAM:  STKAGIN0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - STOCK AGING ENGINE              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CALCULATES DAYS ON LOT FOR EVERY VEHICLE AT A      *
      *           DEALER (CURRENT DATE - RECEIVE_DATE). UPDATES      *
      *           VEHICLE.DAYS_IN_STOCK FIELD. BUCKETS VEHICLES      *
      *           INTO AGING RANGES: 0-30, 31-60, 61-90, 91-120,    *
      *           120+ DAYS. PROVIDES SUMMARY BY BUCKET WITH COUNT,  *
      *           TOTAL VALUE, AND AVG VALUE. FLAGS VEHICLES          *
      *           APPROACHING FLOOR PLAN CURTAILMENT.                *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKG00                                           *
      * TABLES:   AUTOSALE.VEHICLE       (READ/UPDATE)               *
      *           AUTOSALE.PRICE_MASTER   (READ)                     *
      * CALLS:    COMDTEL0 - DATE UTILITY (DAYS, AGED)              *
      *           COMFMTL0 - CURRENCY FORMATTING                    *
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
                                          VALUE 'STKAGIN0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKG00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
      *
      *    CURTAILMENT THRESHOLD (DAYS)
      *
       01  WS-CURTAIL-THRESHOLD          PIC S9(04) COMP VALUE +90.
       01  WS-CURTAIL-WARNING            PIC S9(04) COMP VALUE +75.
      *
      *    INPUT MESSAGE AREA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
      *
      *    OUTPUT MESSAGE AREA
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-PROCESSED          PIC Z(5)9.
           05  WS-OUT-UPDATED            PIC Z(5)9.
           05  WS-OUT-BUCKET-LINES OCCURS 5 TIMES.
               10  WS-OUT-BKT-NAME       PIC X(12).
               10  WS-OUT-BKT-COUNT      PIC Z(5)9.
               10  WS-OUT-BKT-TOTAL-VAL  PIC X(16).
               10  WS-OUT-BKT-AVG-VAL    PIC X(14).
           05  WS-OUT-CURTAIL-COUNT      PIC Z(4)9.
           05  WS-OUT-CURTAIL-LABEL      PIC X(30).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    AGING BUCKET TABLE
      *    1=0-30, 2=31-60, 3=61-90, 4=91-120, 5=120+
      *
       01  WS-BUCKET-TABLE.
           05  WS-BKT-ENTRY OCCURS 5 TIMES.
               10  WS-BKT-NAME-W         PIC X(12).
               10  WS-BKT-COUNT-W        PIC S9(05) COMP
                                                     VALUE +0.
               10  WS-BKT-TOTAL-VAL-W    PIC S9(11)V99 COMP-3
                                                     VALUE +0.
               10  WS-BKT-MIN-DAYS       PIC S9(04) COMP.
               10  WS-BKT-MAX-DAYS       PIC S9(04) COMP.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-IDX                    PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
           05  WS-PROCESSED-COUNT        PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-UPDATED-COUNT          PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-CURTAIL-COUNT          PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-DAYS-CALC              PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-BUCKET-IDX             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-AVG-VALUE-WORK         PIC S9(09)V99 COMP-3
                                                     VALUE +0.
      *
      *    CURSOR: ALL ACTIVE VEHICLES FOR DEALER
      *
           EXEC SQL DECLARE CSR_AGE_VEH CURSOR FOR
               SELECT V.VIN
                    , V.RECEIVE_DATE
                    , V.DAYS_IN_STOCK
                    , P.INVOICE_PRICE
               FROM   AUTOSALE.VEHICLE V
               JOIN   AUTOSALE.PRICE_MASTER P
                 ON   V.MODEL_YEAR = P.MODEL_YEAR
                AND   V.MAKE_CODE  = P.MAKE_CODE
                AND   V.MODEL_CODE = P.MODEL_CODE
               WHERE  V.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  V.VEHICLE_STATUS IN ('AV','DM','LN','HD','AL')
                 AND  V.RECEIVE_DATE IS NOT NULL
               ORDER BY V.RECEIVE_DATE
           END-EXEC
      *
      *    HOST VARIABLES
      *
       01  WS-HV-FIELDS.
           05  WS-HV-VIN                PIC X(17).
           05  WS-HV-RECEIVE-DATE       PIC X(10).
           05  WS-HV-DAYS-IN-STOCK      PIC S9(04) COMP.
           05  WS-HV-INVOICE-PRICE      PIC S9(09)V99 COMP-3.
      *
      *    COMDTEL0 LINKAGE
      *
       01  WS-DTU-FUNCTION              PIC X(04).
       01  WS-DTU-INPUT-AREA.
           05  WS-DTU-DATE-1             PIC X(10).
           05  WS-DTU-DATE-2             PIC X(10).
           05  WS-DTU-DAYS              PIC S9(05) COMP.
       01  WS-DTU-OUTPUT-AREA.
           05  WS-DTU-RESULT-DATE        PIC X(10).
           05  WS-DTU-RESULT-DAYS        PIC S9(05) COMP.
           05  WS-DTU-RESULT-TS          PIC X(26).
       01  WS-DTU-RETURN-CODE           PIC S9(04) COMP.
       01  WS-DTU-ERROR-MSG             PIC X(50).
      *
      *    COMFMTL0 LINKAGE
      *
       01  WS-FMT-FUNCTION              PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA       PIC X(40).
           05  WS-FMT-INPUT-NUM         PIC S9(09)V99 COMP-3.
           05  WS-FMT-INPUT-RATE        PIC S9(02)V9(04) COMP-3.
           05  WS-FMT-INPUT-PCT         PIC S9(03)V99 COMP-3.
       01  WS-FMT-OUTPUT                PIC X(40).
       01  WS-FMT-RETURN-CODE           PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG             PIC X(50).
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY             PIC 9(04).
           05  WS-CURR-MM               PIC 9(02).
           05  WS-CURR-DD               PIC 9(02).
       01  WS-CURR-DATE-FMT             PIC X(10) VALUE SPACES.
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
               PERFORM 4000-PROCESS-AGING
           END-IF
      *
           PERFORM 5000-SEND-OUTPUT
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
           MOVE 'STOCK AGING ANALYSIS' TO WS-OUT-TITLE
           MOVE SPACES TO WS-OUT-MESSAGE
      *
      *    GET CURRENT DATE
      *
           MOVE FUNCTION CURRENT-DATE(1:8)
               TO WS-CURRENT-DATE-DATA
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-CURR-DATE-FMT
      *
      *    INITIALIZE AGING BUCKETS
      *
           MOVE '0-30 DAYS   ' TO WS-BKT-NAME-W(1)
           MOVE +0             TO WS-BKT-MIN-DAYS(1)
           MOVE +30            TO WS-BKT-MAX-DAYS(1)
      *
           MOVE '31-60 DAYS  ' TO WS-BKT-NAME-W(2)
           MOVE +31            TO WS-BKT-MIN-DAYS(2)
           MOVE +60            TO WS-BKT-MAX-DAYS(2)
      *
           MOVE '61-90 DAYS  ' TO WS-BKT-NAME-W(3)
           MOVE +61            TO WS-BKT-MIN-DAYS(3)
           MOVE +90            TO WS-BKT-MAX-DAYS(3)
      *
           MOVE '91-120 DAYS ' TO WS-BKT-NAME-W(4)
           MOVE +91            TO WS-BKT-MIN-DAYS(4)
           MOVE +120           TO WS-BKT-MAX-DAYS(4)
      *
           MOVE '120+ DAYS   ' TO WS-BKT-NAME-W(5)
           MOVE +121           TO WS-BKT-MIN-DAYS(5)
           MOVE +9999          TO WS-BKT-MAX-DAYS(5)
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               MOVE +0 TO WS-BKT-COUNT-W(WS-IDX)
               MOVE +0 TO WS-BKT-TOTAL-VAL-W(WS-IDX)
           END-PERFORM
      *
           MOVE +0 TO WS-CURTAIL-COUNT
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
               MOVE 'STKAGIN0: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'DEALER CODE IS REQUIRED FOR AGING ANALYSIS'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           END-IF
           .
      *
      ****************************************************************
      *    4000-PROCESS-AGING - CALC DAYS AND UPDATE VEHICLES        *
      ****************************************************************
       4000-PROCESS-AGING.
      *
           EXEC SQL OPEN CSR_AGE_VEH END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKAGIN0: ERROR OPENING AGING CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
      *
               EXEC SQL FETCH CSR_AGE_VEH
                   INTO  :WS-HV-VIN
                        , :WS-HV-RECEIVE-DATE
                        , :WS-HV-DAYS-IN-STOCK
                        , :WS-HV-INVOICE-PRICE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-PROCESSED-COUNT
                       PERFORM 4100-CALCULATE-DAYS
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 'STKAGIN0: DB2 ERROR IN AGING QUERY'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_AGE_VEH END-EXEC
      *
      *    BUILD OUTPUT
      *
           PERFORM 4300-BUILD-OUTPUT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-CALCULATE-DAYS - COMPUTE DAYS AND ASSIGN BUCKET      *
      ****************************************************************
       4100-CALCULATE-DAYS.
      *
      *    CALL COMDTEL0 TO CALCULATE DAYS BETWEEN DATES
      *
           MOVE 'AGED' TO WS-DTU-FUNCTION
           MOVE WS-HV-RECEIVE-DATE TO WS-DTU-DATE-1
           MOVE WS-CURR-DATE-FMT   TO WS-DTU-DATE-2
           MOVE +0                  TO WS-DTU-DAYS
      *
           CALL 'COMDTEL0' USING WS-DTU-FUNCTION
                                 WS-DTU-INPUT-AREA
                                 WS-DTU-OUTPUT-AREA
                                 WS-DTU-RETURN-CODE
                                 WS-DTU-ERROR-MSG
      *
           IF WS-DTU-RETURN-CODE = +0
               MOVE WS-DTU-RESULT-DAYS TO WS-DAYS-CALC
           ELSE
      *        FALLBACK: USE EXISTING DAYS_IN_STOCK
               MOVE WS-HV-DAYS-IN-STOCK TO WS-DAYS-CALC
           END-IF
      *
      *    UPDATE VEHICLE DAYS_IN_STOCK IF CHANGED
      *
           IF WS-DAYS-CALC NOT = WS-HV-DAYS-IN-STOCK
               PERFORM 4200-UPDATE-DAYS
           END-IF
      *
      *    ASSIGN TO AGING BUCKET
      *
           MOVE +5 TO WS-BUCKET-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               IF WS-DAYS-CALC >= WS-BKT-MIN-DAYS(WS-IDX)
               AND WS-DAYS-CALC <= WS-BKT-MAX-DAYS(WS-IDX)
                   MOVE WS-IDX TO WS-BUCKET-IDX
               END-IF
           END-PERFORM
      *
           ADD +1 TO WS-BKT-COUNT-W(WS-BUCKET-IDX)
           ADD WS-HV-INVOICE-PRICE
               TO WS-BKT-TOTAL-VAL-W(WS-BUCKET-IDX)
      *
      *    CHECK CURTAILMENT RISK
      *
           IF WS-DAYS-CALC >= WS-CURTAIL-WARNING
               ADD +1 TO WS-CURTAIL-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    4200-UPDATE-DAYS - UPDATE DAYS_IN_STOCK ON VEHICLE        *
      ****************************************************************
       4200-UPDATE-DAYS.
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET DAYS_IN_STOCK = :WS-DAYS-CALC
                    , UPDATED_TS    = CURRENT TIMESTAMP
               WHERE  VIN           = :WS-HV-VIN
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-UPDATED-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    4300-BUILD-OUTPUT - FORMAT BUCKET SUMMARY LINES           *
      ****************************************************************
       4300-BUILD-OUTPUT.
      *
           MOVE WS-PROCESSED-COUNT TO WS-OUT-PROCESSED
           MOVE WS-UPDATED-COUNT   TO WS-OUT-UPDATED
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
      *
               MOVE WS-BKT-NAME-W(WS-IDX)
                   TO WS-OUT-BKT-NAME(WS-IDX)
               MOVE WS-BKT-COUNT-W(WS-IDX)
                   TO WS-OUT-BKT-COUNT(WS-IDX)
      *
      *        FORMAT TOTAL VALUE
      *
               MOVE 'CURR' TO WS-FMT-FUNCTION
               MOVE WS-BKT-TOTAL-VAL-W(WS-IDX)
                   TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:16)
                   TO WS-OUT-BKT-TOTAL-VAL(WS-IDX)
      *
      *        AVERAGE VALUE
      *
               IF WS-BKT-COUNT-W(WS-IDX) > +0
                   COMPUTE WS-AVG-VALUE-WORK =
                       WS-BKT-TOTAL-VAL-W(WS-IDX)
                       / WS-BKT-COUNT-W(WS-IDX)
               ELSE
                   MOVE +0 TO WS-AVG-VALUE-WORK
               END-IF
      *
               MOVE WS-AVG-VALUE-WORK TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:14)
                   TO WS-OUT-BKT-AVG-VAL(WS-IDX)
           END-PERFORM
      *
      *    CURTAILMENT WARNING LINE
      *
           MOVE WS-CURTAIL-COUNT TO WS-OUT-CURTAIL-COUNT
           MOVE 'VEHICLES NEAR CURTAILMENT'
               TO WS-OUT-CURTAIL-LABEL
      *
           IF WS-PROCESSED-COUNT = +0
               MOVE 'NO ACTIVE VEHICLES FOUND FOR DEALER'
                   TO WS-OUT-MESSAGE
           ELSE
               STRING WS-PROCESSED-COUNT
                      ' VEHICLES PROCESSED, '
                      WS-UPDATED-COUNT
                      ' UPDATED'
                      DELIMITED BY SIZE
                      INTO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    5000-SEND-OUTPUT                                          *
      ****************************************************************
       5000-SEND-OUTPUT.
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
      * END OF STKAGIN0                                              *
      ****************************************************************
