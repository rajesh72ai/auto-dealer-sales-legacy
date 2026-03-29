       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKSUM00.
      ****************************************************************
      * PROGRAM:  STKSUM00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - STOCK SUMMARY DASHBOARD         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  AGGREGATES STOCK POSITION BY BODY STYLE FOR A      *
      *           GIVEN DEALER. SHOWS COUNTS FOR SEDANS, SUVS,       *
      *           TRUCKS, COUPES, ETC. CALCULATES TOTAL INVENTORY    *
      *           COUNT, TOTAL ESTIMATED VALUE (INVOICE), AND         *
      *           AVERAGE DAYS IN STOCK.                              *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKS00                                           *
      * TABLES:   AUTOSALE.STOCK_POSITION (READ)                     *
      *           AUTOSALE.MODEL_MASTER   (READ)                     *
      *           AUTOSALE.PRICE_MASTER   (READ)                     *
      *           AUTOSALE.VEHICLE        (READ)                     *
      * CALLS:    COMFMTL0 - CURRENCY FORMATTING                    *
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
                                          VALUE 'STKSUM00'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKS00'.
      *
      *    IMS FUNCTION CODES
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
      *    COPY IN SQLCA
      *
           COPY WSSQLCA.
      *
      *    COPY IN IMS I/O PCB MASK
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
           05  WS-OUT-BODY-LINES OCCURS 10 TIMES.
               10  WS-OUT-BODY-DESC      PIC X(12).
               10  WS-OUT-BODY-COUNT     PIC Z(5)9.
               10  WS-OUT-BODY-VALUE     PIC X(20).
           05  WS-OUT-TOTALS.
               10  WS-OUT-TOTAL-LABEL    PIC X(12).
               10  WS-OUT-TOTAL-COUNT    PIC Z(5)9.
               10  WS-OUT-TOTAL-VALUE    PIC X(20).
               10  WS-OUT-AVG-DAYS       PIC Z(4)9.
           05  WS-OUT-LINE-COUNT         PIC S9(04) COMP.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    BODY STYLE AGGREGATION TABLE
      *
       01  WS-BODY-STYLE-TABLE.
           05  WS-BS-ENTRY OCCURS 10 TIMES.
               10  WS-BS-CODE            PIC X(02).
               10  WS-BS-DESC            PIC X(12).
               10  WS-BS-COUNT           PIC S9(07) COMP-3
                                                     VALUE +0.
               10  WS-BS-TOTAL-VALUE     PIC S9(11)V99 COMP-3
                                                     VALUE +0.
               10  WS-BS-TOTAL-DAYS      PIC S9(09) COMP
                                                     VALUE +0.
      *
       01  WS-BODY-STYLE-INIT.
           05  FILLER                    PIC X(14)
                                          VALUE 'SDSEDANS      '.
           05  FILLER                    PIC X(14)
                                          VALUE 'SVSUV/CROSSOVR'.
           05  FILLER                    PIC X(14)
                                          VALUE 'TKTRUCKS      '.
           05  FILLER                    PIC X(14)
                                          VALUE 'CPCOUPES      '.
           05  FILLER                    PIC X(14)
                                          VALUE 'CVCONVERTIBLES'.
           05  FILLER                    PIC X(14)
                                          VALUE 'VNVANS/MINIVAN'.
           05  FILLER                    PIC X(14)
                                          VALUE 'WGWAGONS      '.
           05  FILLER                    PIC X(14)
                                          VALUE 'HBHATCHBACKS  '.
           05  FILLER                    PIC X(14)
                                          VALUE 'EVEVEHICLES   '.
           05  FILLER                    PIC X(14)
                                          VALUE 'OTOTHER       '.
       01  WS-BS-INIT-R REDEFINES WS-BODY-STYLE-INIT.
           05  WS-BS-INIT-ENTRY OCCURS 10 TIMES.
               10  WS-BS-INIT-CODE       PIC X(02).
               10  WS-BS-INIT-DESC       PIC X(12).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-IDX                    PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-FOUND-IDX             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-GRAND-TOTAL-COUNT     PIC S9(07) COMP-3
                                                     VALUE +0.
           05  WS-GRAND-TOTAL-VALUE     PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-GRAND-TOTAL-DAYS      PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-AVG-DAYS              PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-LINE-IDX             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG              PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
      *
      *    CURSOR: AGGREGATE BY BODY STYLE
      *
           EXEC SQL DECLARE CSR_STK_SUM CURSOR FOR
               SELECT M.BODY_STYLE
                    , SUM(S.ON_HAND_COUNT)
                    , SUM(S.ON_HAND_COUNT * P.INVOICE_PRICE)
                    , COALESCE(AVG(V.DAYS_IN_STOCK), 0)
               FROM   AUTOSALE.STOCK_POSITION S
               JOIN   AUTOSALE.MODEL_MASTER   M
                 ON   S.MODEL_YEAR = M.MODEL_YEAR
                AND   S.MAKE_CODE  = M.MAKE_CODE
                AND   S.MODEL_CODE = M.MODEL_CODE
               JOIN   AUTOSALE.PRICE_MASTER   P
                 ON   S.MODEL_YEAR = P.MODEL_YEAR
                AND   S.MAKE_CODE  = P.MAKE_CODE
                AND   S.MODEL_CODE = P.MODEL_CODE
               LEFT JOIN AUTOSALE.VEHICLE V
                 ON   V.DEALER_CODE = S.DEALER_CODE
                AND   V.MODEL_YEAR  = S.MODEL_YEAR
                AND   V.MAKE_CODE   = S.MAKE_CODE
                AND   V.MODEL_CODE  = S.MODEL_CODE
                AND   V.VEHICLE_STATUS = 'AV'
               WHERE  S.DEALER_CODE = :WS-IN-DEALER-CODE
               GROUP BY M.BODY_STYLE
               ORDER BY M.BODY_STYLE
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HV-FIELDS.
           05  WS-HV-BODY-STYLE         PIC X(02).
           05  WS-HV-SUM-COUNT          PIC S9(07) COMP-3.
           05  WS-HV-SUM-VALUE          PIC S9(11)V99 COMP-3.
           05  WS-HV-AVG-DAYS           PIC S9(05) COMP.
      *
      *    COMFMTL0 LINKAGE AREAS
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
               PERFORM 4000-AGGREGATE-STOCK
           END-IF
      *
           PERFORM 5000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - SET UP BODY STYLE TABLE                 *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           MOVE 'STOCK SUMMARY DASHBOARD' TO WS-OUT-TITLE
           MOVE SPACES TO WS-OUT-MESSAGE
      *
      *    INITIALIZE BODY STYLE LOOKUP TABLE
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 10
               MOVE WS-BS-INIT-CODE(WS-IDX)
                   TO WS-BS-CODE(WS-IDX)
               MOVE WS-BS-INIT-DESC(WS-IDX)
                   TO WS-BS-DESC(WS-IDX)
               MOVE +0 TO WS-BS-COUNT(WS-IDX)
               MOVE +0 TO WS-BS-TOTAL-VALUE(WS-IDX)
               MOVE +0 TO WS-BS-TOTAL-DAYS(WS-IDX)
           END-PERFORM
      *
           MOVE +0 TO WS-GRAND-TOTAL-COUNT
           MOVE +0 TO WS-GRAND-TOTAL-VALUE
           MOVE +0 TO WS-GRAND-TOTAL-DAYS
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
               MOVE 'STKSUM00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK DEALER CODE                   *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'DEALER CODE IS REQUIRED FOR STOCK SUMMARY'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           END-IF
           .
      *
      ****************************************************************
      *    4000-AGGREGATE-STOCK - OPEN CURSOR AND SUM BY BODY STYLE  *
      ****************************************************************
       4000-AGGREGATE-STOCK.
      *
           EXEC SQL OPEN CSR_STK_SUM END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKSUM00: ERROR OPENING SUMMARY CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               EXEC SQL FETCH CSR_STK_SUM
                   INTO  :WS-HV-BODY-STYLE
                        , :WS-HV-SUM-COUNT
                        , :WS-HV-SUM-VALUE
                        , :WS-HV-AVG-DAYS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 4100-MAP-BODY-STYLE
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 'STKSUM00: DB2 ERROR IN SUMMARY QUERY'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_STK_SUM END-EXEC
      *
      *    BUILD OUTPUT LINES
      *
           PERFORM 4200-BUILD-OUTPUT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-MAP-BODY-STYLE - MAP RESULT TO BODY STYLE TABLE      *
      ****************************************************************
       4100-MAP-BODY-STYLE.
      *
           MOVE +10 TO WS-FOUND-IDX
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 9
               IF WS-BS-CODE(WS-IDX) = WS-HV-BODY-STYLE
                   MOVE WS-IDX TO WS-FOUND-IDX
               END-IF
           END-PERFORM
      *
           ADD WS-HV-SUM-COUNT
               TO WS-BS-COUNT(WS-FOUND-IDX)
           ADD WS-HV-SUM-VALUE
               TO WS-BS-TOTAL-VALUE(WS-FOUND-IDX)
      *
           ADD WS-HV-SUM-COUNT  TO WS-GRAND-TOTAL-COUNT
           ADD WS-HV-SUM-VALUE  TO WS-GRAND-TOTAL-VALUE
           .
      *
      ****************************************************************
      *    4200-BUILD-OUTPUT - FORMAT OUTPUT LINES WITH CURRENCY     *
      ****************************************************************
       4200-BUILD-OUTPUT.
      *
           MOVE +0 TO WS-LINE-IDX
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 10
               IF WS-BS-COUNT(WS-IDX) > +0
                   ADD +1 TO WS-LINE-IDX
      *
                   MOVE WS-BS-DESC(WS-IDX)
                       TO WS-OUT-BODY-DESC(WS-LINE-IDX)
                   MOVE WS-BS-COUNT(WS-IDX)
                       TO WS-OUT-BODY-COUNT(WS-LINE-IDX)
      *
      *            FORMAT CURRENCY VALUE VIA COMFMTL0
      *
                   MOVE 'CURR' TO WS-FMT-FUNCTION
                   MOVE WS-BS-TOTAL-VALUE(WS-IDX)
                       TO WS-FMT-INPUT-NUM
                   CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                         WS-FMT-INPUT
                                         WS-FMT-OUTPUT
                                         WS-FMT-RETURN-CODE
                                         WS-FMT-ERROR-MSG
                   MOVE WS-FMT-OUTPUT(1:20)
                       TO WS-OUT-BODY-VALUE(WS-LINE-IDX)
               END-IF
           END-PERFORM
      *
      *    TOTALS LINE
      *
           MOVE 'TOTAL' TO WS-OUT-TOTAL-LABEL
           MOVE WS-GRAND-TOTAL-COUNT TO WS-OUT-TOTAL-COUNT
      *
           MOVE 'CURR' TO WS-FMT-FUNCTION
           MOVE WS-GRAND-TOTAL-VALUE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:20) TO WS-OUT-TOTAL-VALUE
      *
      *    AVERAGE DAYS IN STOCK
      *
           IF WS-GRAND-TOTAL-COUNT > +0
               COMPUTE WS-AVG-DAYS =
                   WS-GRAND-TOTAL-DAYS / WS-GRAND-TOTAL-COUNT
               MOVE WS-AVG-DAYS TO WS-OUT-AVG-DAYS
           ELSE
               MOVE +0 TO WS-OUT-AVG-DAYS
           END-IF
      *
           MOVE WS-LINE-IDX TO WS-OUT-LINE-COUNT
           .
      *
      ****************************************************************
      *    5000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
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
      * END OF STKSUM00                                              *
      ****************************************************************
