       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKVALS0.
      ****************************************************************
      * PROGRAM:  STKVALS0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - STOCK VALUATION                 *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CALCULATES TOTAL FLOOR PLAN EXPOSURE FOR A DEALER. *
      *           GROUPS INVENTORY BY CATEGORY (NEW, DEMO, LOANER).  *
      *           SHOWS COUNT, TOTAL INVOICE VALUE, TOTAL MSRP,      *
      *           AVG AGE, AND ESTIMATED HOLDING COST. JOINS VEHICLE *
      *           + PRICE_MASTER + FLOOR_PLAN_VEHICLE FOR INTEREST.  *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKV00                                           *
      * TABLES:   AUTOSALE.VEHICLE            (READ)                 *
      *           AUTOSALE.PRICE_MASTER        (READ)                *
      *           AUTOSALE.FLOOR_PLAN_VEHICLE  (READ)                *
      * CALLS:    COMPRCL0 - VEHICLE PRICING ENGINE                 *
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
                                          VALUE 'STKVALS0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKV00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
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
           05  WS-OUT-CATEGORY-LINES OCCURS 5 TIMES.
               10  WS-OUT-CAT-NAME       PIC X(10).
               10  WS-OUT-CAT-COUNT      PIC Z(5)9.
               10  WS-OUT-CAT-INVOICE    PIC X(16).
               10  WS-OUT-CAT-MSRP       PIC X(16).
               10  WS-OUT-CAT-AVG-AGE    PIC Z(4)9.
               10  WS-OUT-CAT-HOLD-COST  PIC X(14).
           05  WS-OUT-TOTALS.
               10  WS-OUT-TOT-LABEL      PIC X(10).
               10  WS-OUT-TOT-COUNT      PIC Z(5)9.
               10  WS-OUT-TOT-INVOICE    PIC X(16).
               10  WS-OUT-TOT-MSRP       PIC X(16).
               10  WS-OUT-TOT-AVG-AGE    PIC Z(4)9.
               10  WS-OUT-TOT-HOLD-COST  PIC X(14).
           05  WS-OUT-FP-INTEREST        PIC X(16).
           05  WS-OUT-FP-LABEL           PIC X(25).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    CATEGORY WORK TABLE (NEW, DEMO, LOANER, HOLD, OTHER)
      *
       01  WS-CATEGORY-TABLE.
           05  WS-CAT-ENTRY OCCURS 5 TIMES.
               10  WS-CAT-STATUS-CODE    PIC X(02).
               10  WS-CAT-NAME-W         PIC X(10).
               10  WS-CAT-COUNT-W        PIC S9(05) COMP
                                                     VALUE +0.
               10  WS-CAT-INVOICE-W      PIC S9(11)V99 COMP-3
                                                     VALUE +0.
               10  WS-CAT-MSRP-W         PIC S9(11)V99 COMP-3
                                                     VALUE +0.
               10  WS-CAT-TOTAL-DAYS-W   PIC S9(09) COMP
                                                     VALUE +0.
               10  WS-CAT-HOLD-COST-W    PIC S9(09)V99 COMP-3
                                                     VALUE +0.
      *
       01  WS-CAT-INIT-DATA.
           05  FILLER                    PIC X(12)
                                          VALUE 'AVNEW       '.
           05  FILLER                    PIC X(12)
                                          VALUE 'DMDEMO      '.
           05  FILLER                    PIC X(12)
                                          VALUE 'LNLOANER    '.
           05  FILLER                    PIC X(12)
                                          VALUE 'HDON HOLD   '.
           05  FILLER                    PIC X(12)
                                          VALUE 'OTOTHER     '.
       01  WS-CAT-INIT-R REDEFINES WS-CAT-INIT-DATA.
           05  WS-CAT-INIT-ENTRY OCCURS 5 TIMES.
               10  WS-CAT-INIT-STATUS    PIC X(02).
               10  WS-CAT-INIT-NAME      PIC X(10).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-IDX                    PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-FOUND-IDX             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG              PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
           05  WS-GRAND-COUNT           PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-GRAND-INVOICE        PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-GRAND-MSRP           PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-GRAND-DAYS           PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-GRAND-HOLD-COST      PIC S9(09)V99 COMP-3
                                                     VALUE +0.
           05  WS-AVG-AGE              PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-TOTAL-FP-INTEREST    PIC S9(09)V99 COMP-3
                                                     VALUE +0.
      *
      *    CURSOR: VEHICLE VALUATION WITH PRICING
      *
           EXEC SQL DECLARE CSR_STK_VAL CURSOR FOR
               SELECT V.VEHICLE_STATUS
                    , V.DAYS_IN_STOCK
                    , P.INVOICE_PRICE
                    , P.MSRP
                    , COALESCE(F.INTEREST_ACCRUED, 0)
               FROM   AUTOSALE.VEHICLE V
               JOIN   AUTOSALE.PRICE_MASTER P
                 ON   V.MODEL_YEAR = P.MODEL_YEAR
                AND   V.MAKE_CODE  = P.MAKE_CODE
                AND   V.MODEL_CODE = P.MODEL_CODE
               LEFT JOIN AUTOSALE.FLOOR_PLAN_VEHICLE F
                 ON   V.VIN = F.VIN
                AND   F.FP_STATUS = 'AC'
               WHERE  V.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  V.VEHICLE_STATUS IN ('AV','DM','LN','HD','AL')
               ORDER BY V.VEHICLE_STATUS
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR
      *
       01  WS-HV-FIELDS.
           05  WS-HV-VEH-STATUS         PIC X(02).
           05  WS-HV-DAYS-IN-STOCK      PIC S9(04) COMP.
           05  WS-HV-INVOICE-PRICE      PIC S9(09)V99 COMP-3.
           05  WS-HV-MSRP               PIC S9(09)V99 COMP-3.
           05  WS-HV-INTEREST-ACCRUED   PIC S9(07)V99 COMP-3.
      *
      *    DAILY HOLDING COST (ESTIMATED FLOOR PLAN RATE)
      *
       01  WS-DAILY-HOLD-RATE           PIC S9(03)V9(06) COMP-3
                                          VALUE +0.000164.
      *
      *    COMPRCL0 LINKAGE
      *
       01  WS-PRC-INPUT-AREA.
           05  WS-PRC-FUNCTION           PIC X(04).
           05  WS-PRC-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-PRC-MAKE-CODE          PIC X(03).
           05  WS-PRC-MODEL-CODE         PIC X(06).
           05  WS-PRC-SELL-PRICE         PIC S9(09)V99 COMP-3.
       01  WS-PRC-RESULT-AREA.
           05  WS-PRC-MSRP              PIC S9(09)V99 COMP-3.
           05  WS-PRC-INVOICE           PIC S9(09)V99 COMP-3.
           05  WS-PRC-HOLDBACK          PIC S9(07)V99 COMP-3.
           05  WS-PRC-GROSS-PROFIT      PIC S9(09)V99 COMP-3.
           05  WS-PRC-MARGIN-PCT        PIC S9(03)V99 COMP-3.
       01  WS-PRC-RETURN-CODE           PIC S9(04) COMP.
       01  WS-PRC-ERROR-MSG             PIC X(50).
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
               PERFORM 4000-CALCULATE-VALUATION
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
           MOVE 'STOCK VALUATION REPORT' TO WS-OUT-TITLE
           MOVE SPACES TO WS-OUT-MESSAGE
      *
      *    INITIALIZE CATEGORY TABLE
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               MOVE WS-CAT-INIT-STATUS(WS-IDX)
                   TO WS-CAT-STATUS-CODE(WS-IDX)
               MOVE WS-CAT-INIT-NAME(WS-IDX)
                   TO WS-CAT-NAME-W(WS-IDX)
               MOVE +0 TO WS-CAT-COUNT-W(WS-IDX)
               MOVE +0 TO WS-CAT-INVOICE-W(WS-IDX)
               MOVE +0 TO WS-CAT-MSRP-W(WS-IDX)
               MOVE +0 TO WS-CAT-TOTAL-DAYS-W(WS-IDX)
               MOVE +0 TO WS-CAT-HOLD-COST-W(WS-IDX)
           END-PERFORM
      *
           MOVE +0 TO WS-GRAND-COUNT
           MOVE +0 TO WS-GRAND-INVOICE
           MOVE +0 TO WS-GRAND-MSRP
           MOVE +0 TO WS-GRAND-DAYS
           MOVE +0 TO WS-GRAND-HOLD-COST
           MOVE +0 TO WS-TOTAL-FP-INTEREST
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
               MOVE 'STKVALS0: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'DEALER CODE IS REQUIRED FOR VALUATION'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           END-IF
           .
      *
      ****************************************************************
      *    4000-CALCULATE-VALUATION                                  *
      ****************************************************************
       4000-CALCULATE-VALUATION.
      *
           EXEC SQL OPEN CSR_STK_VAL END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKVALS0: ERROR OPENING VALUATION CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
      *
               EXEC SQL FETCH CSR_STK_VAL
                   INTO  :WS-HV-VEH-STATUS
                        , :WS-HV-DAYS-IN-STOCK
                        , :WS-HV-INVOICE-PRICE
                        , :WS-HV-MSRP
                        , :WS-HV-INTEREST-ACCRUED
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 4100-ACCUMULATE-CATEGORY
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 'STKVALS0: DB2 ERROR IN VALUATION QUERY'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_STK_VAL END-EXEC
      *
      *    GET TOTAL FLOOR PLAN INTEREST
      *
           EXEC SQL
               SELECT COALESCE(SUM(INTEREST_ACCRUED), 0)
               INTO   :WS-TOTAL-FP-INTEREST
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE
               WHERE  DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  FP_STATUS = 'AC'
           END-EXEC
      *
      *    BUILD OUTPUT LINES
      *
           PERFORM 4200-BUILD-OUTPUT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-ACCUMULATE-CATEGORY - MAP TO CATEGORY BUCKET         *
      ****************************************************************
       4100-ACCUMULATE-CATEGORY.
      *
      *    FIND MATCHING CATEGORY (DEFAULT TO OTHER = INDEX 5)
      *
           MOVE +5 TO WS-FOUND-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 4
               IF WS-CAT-STATUS-CODE(WS-IDX) = WS-HV-VEH-STATUS
                   MOVE WS-IDX TO WS-FOUND-IDX
               END-IF
           END-PERFORM
      *
           ADD +1 TO WS-CAT-COUNT-W(WS-FOUND-IDX)
           ADD WS-HV-INVOICE-PRICE
               TO WS-CAT-INVOICE-W(WS-FOUND-IDX)
           ADD WS-HV-MSRP
               TO WS-CAT-MSRP-W(WS-FOUND-IDX)
           ADD WS-HV-DAYS-IN-STOCK
               TO WS-CAT-TOTAL-DAYS-W(WS-FOUND-IDX)
      *
      *    ESTIMATED HOLDING COST = INVOICE * DAILY RATE * DAYS
      *
           COMPUTE WS-CAT-HOLD-COST-W(WS-FOUND-IDX) =
               WS-CAT-HOLD-COST-W(WS-FOUND-IDX)
               + (WS-HV-INVOICE-PRICE * WS-DAILY-HOLD-RATE
                  * WS-HV-DAYS-IN-STOCK)
      *
      *    ACCUMULATE GRAND TOTALS
      *
           ADD +1                  TO WS-GRAND-COUNT
           ADD WS-HV-INVOICE-PRICE TO WS-GRAND-INVOICE
           ADD WS-HV-MSRP          TO WS-GRAND-MSRP
           ADD WS-HV-DAYS-IN-STOCK TO WS-GRAND-DAYS
           .
      *
      ****************************************************************
      *    4200-BUILD-OUTPUT - FORMAT CATEGORY AND TOTAL LINES       *
      ****************************************************************
       4200-BUILD-OUTPUT.
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
      *
               MOVE WS-CAT-NAME-W(WS-IDX)
                   TO WS-OUT-CAT-NAME(WS-IDX)
               MOVE WS-CAT-COUNT-W(WS-IDX)
                   TO WS-OUT-CAT-COUNT(WS-IDX)
      *
      *        FORMAT INVOICE TOTAL
      *
               MOVE 'CURR' TO WS-FMT-FUNCTION
               MOVE WS-CAT-INVOICE-W(WS-IDX)
                   TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:16)
                   TO WS-OUT-CAT-INVOICE(WS-IDX)
      *
      *        FORMAT MSRP TOTAL
      *
               MOVE WS-CAT-MSRP-W(WS-IDX) TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:16)
                   TO WS-OUT-CAT-MSRP(WS-IDX)
      *
      *        AVERAGE AGE
      *
               IF WS-CAT-COUNT-W(WS-IDX) > +0
                   COMPUTE WS-AVG-AGE =
                       WS-CAT-TOTAL-DAYS-W(WS-IDX)
                       / WS-CAT-COUNT-W(WS-IDX)
               ELSE
                   MOVE +0 TO WS-AVG-AGE
               END-IF
               MOVE WS-AVG-AGE TO WS-OUT-CAT-AVG-AGE(WS-IDX)
      *
      *        FORMAT HOLDING COST
      *
               MOVE WS-CAT-HOLD-COST-W(WS-IDX)
                   TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:14)
                   TO WS-OUT-CAT-HOLD-COST(WS-IDX)
           END-PERFORM
      *
      *    TOTALS LINE
      *
           MOVE 'TOTAL' TO WS-OUT-TOT-LABEL
           MOVE WS-GRAND-COUNT TO WS-OUT-TOT-COUNT
      *
           MOVE WS-GRAND-INVOICE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:16) TO WS-OUT-TOT-INVOICE
      *
           MOVE WS-GRAND-MSRP TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:16) TO WS-OUT-TOT-MSRP
      *
           IF WS-GRAND-COUNT > +0
               COMPUTE WS-AVG-AGE =
                   WS-GRAND-DAYS / WS-GRAND-COUNT
           ELSE
               MOVE +0 TO WS-AVG-AGE
           END-IF
           MOVE WS-AVG-AGE TO WS-OUT-TOT-AVG-AGE
      *
      *    COMPUTE GRAND HOLDING COST
      *
           MOVE +0 TO WS-GRAND-HOLD-COST
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               ADD WS-CAT-HOLD-COST-W(WS-IDX)
                   TO WS-GRAND-HOLD-COST
           END-PERFORM
      *
           MOVE WS-GRAND-HOLD-COST TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:14) TO WS-OUT-TOT-HOLD-COST
      *
      *    FLOOR PLAN INTEREST LINE
      *
           MOVE 'TOTAL FP INTEREST ACCRUED'
               TO WS-OUT-FP-LABEL
           MOVE WS-TOTAL-FP-INTEREST TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:16) TO WS-OUT-FP-INTEREST
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
      * END OF STKVALS0                                              *
      ****************************************************************
