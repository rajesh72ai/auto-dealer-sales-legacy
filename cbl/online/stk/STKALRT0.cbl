       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKALRT0.
      ****************************************************************
      * PROGRAM:  STKALRT0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - LOW STOCK ALERT PROCESSOR       *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  BATCH-STYLE ONLINE QUERY (DISPLAY ONLY). SCANS     *
      *           STOCK_POSITION FOR ALL MODELS WHERE ON_HAND_COUNT  *
      *           IS BELOW REORDER_POINT. GROUPS BY DEALER AND       *
      *           SHOWS MODEL, ON HAND, REORDER POINT, DEFICIT,      *
      *           AND SUGGESTED ORDER QUANTITY.                       *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKL00                                           *
      * TABLES:   AUTOSALE.STOCK_POSITION (READ)                     *
      *           AUTOSALE.MODEL_MASTER   (READ)                     *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                       *
      *           COMMSGL0 - MESSAGE BUILDER                         *
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
                                          VALUE 'STKALRT0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKL00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
      *
      *    SAFETY STOCK CONSTANT (UNITS ABOVE REORDER POINT)
      *
       01  WS-SAFETY-STOCK              PIC S9(04) COMP VALUE +2.
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
           05  WS-OUT-FILTER-DEALER      PIC X(05).
           05  WS-OUT-ALERT-COUNT        PIC Z(4)9.
           05  WS-OUT-LINE-COUNT         PIC S9(04) COMP.
           05  WS-OUT-DETAIL OCCURS 18 TIMES.
               10  WS-OUT-DEALER         PIC X(05).
               10  WS-OUT-MODEL-YR       PIC X(04).
               10  WS-OUT-MAKE           PIC X(03).
               10  WS-OUT-MODEL          PIC X(06).
               10  WS-OUT-MODEL-DESC     PIC X(25).
               10  WS-OUT-ON-HAND        PIC Z(4)9.
               10  WS-OUT-REORDER-PT     PIC Z(4)9.
               10  WS-OUT-DEFICIT        PIC Z(4)9.
               10  WS-OUT-SUGGEST-QTY    PIC Z(4)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ROW-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-TOTAL-ALERTS           PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
           05  WS-DEFICIT-WORK           PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-SUGGEST-QTY-WORK       PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-ALL-DEALERS            PIC X(01)  VALUE 'N'.
               88  WS-QUERY-ALL-DEALERS              VALUE 'Y'.
      *
      *    CURSOR: LOW STOCK ALERTS (ALL DEALERS OR SINGLE)
      *
           EXEC SQL DECLARE CSR_LOW_STK CURSOR FOR
               SELECT S.DEALER_CODE
                    , S.MODEL_YEAR
                    , S.MAKE_CODE
                    , S.MODEL_CODE
                    , S.ON_HAND_COUNT
                    , S.REORDER_POINT
                    , M.MODEL_NAME
               FROM   AUTOSALE.STOCK_POSITION S
               JOIN   AUTOSALE.MODEL_MASTER   M
                 ON   S.MODEL_YEAR = M.MODEL_YEAR
                AND   S.MAKE_CODE  = M.MAKE_CODE
                AND   S.MODEL_CODE = M.MODEL_CODE
               WHERE  S.ON_HAND_COUNT < S.REORDER_POINT
                 AND  (S.DEALER_CODE = :WS-IN-DEALER-CODE
                       OR :WS-IN-DEALER-CODE = '     ')
               ORDER BY S.DEALER_CODE
                      , S.MAKE_CODE
                      , S.MODEL_CODE
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR
      *
       01  WS-HV-FIELDS.
           05  WS-HV-DEALER-CODE        PIC X(05).
           05  WS-HV-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-HV-MAKE-CODE          PIC X(03).
           05  WS-HV-MODEL-CODE         PIC X(06).
           05  WS-HV-ON-HAND            PIC S9(04) COMP.
           05  WS-HV-REORDER-PT         PIC S9(04) COMP.
           05  WS-HV-MODEL-NAME.
               49  WS-HV-MODEL-NAME-LN  PIC S9(04) COMP.
               49  WS-HV-MODEL-NAME-TX  PIC X(40).
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
      *    COMMSGL0 LINKAGE
      *
       01  WS-MSG-FUNCTION              PIC X(04).
       01  WS-MSG-TEXT                   PIC X(79).
       01  WS-MSG-SEVERITY              PIC X(04).
       01  WS-MSG-PROGRAM-ID            PIC X(08).
       01  WS-MSG-OUTPUT-AREA           PIC X(256).
       01  WS-MSG-RETURN-CODE           PIC S9(04) COMP.
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
               PERFORM 3000-SCAN-LOW-STOCK
           END-IF
      *
           PERFORM 4000-SEND-OUTPUT
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
           MOVE 'LOW STOCK ALERT REPORT' TO WS-OUT-TITLE
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
               MOVE 'STKALRT0: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           ELSE
      *        DEALER CODE IS OPTIONAL - BLANK MEANS ALL DEALERS
               IF WS-IN-DEALER-CODE NOT = SPACES
                   MOVE WS-IN-DEALER-CODE TO WS-OUT-FILTER-DEALER
                   MOVE 'N' TO WS-ALL-DEALERS
               ELSE
                   MOVE 'ALL  ' TO WS-OUT-FILTER-DEALER
                   MOVE 'Y' TO WS-ALL-DEALERS
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    3000-SCAN-LOW-STOCK - OPEN CURSOR AND DISPLAY ALERTS      *
      ****************************************************************
       3000-SCAN-LOW-STOCK.
      *
           EXEC SQL OPEN CSR_LOW_STK END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKALRT0: ERROR OPENING LOW STOCK CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE +0 TO WS-TOTAL-ALERTS
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +18
      *
               EXEC SQL FETCH CSR_LOW_STK
                   INTO  :WS-HV-DEALER-CODE
                        , :WS-HV-MODEL-YEAR
                        , :WS-HV-MAKE-CODE
                        , :WS-HV-MODEL-CODE
                        , :WS-HV-ON-HAND
                        , :WS-HV-REORDER-PT
                        , :WS-HV-MODEL-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-ROW-COUNT
                       ADD +1 TO WS-TOTAL-ALERTS
                       PERFORM 3100-FORMAT-ALERT-LINE
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 'STKALRT0: DB2 ERROR SCANNING STOCK'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_LOW_STK END-EXEC
      *
           MOVE WS-ROW-COUNT TO WS-OUT-LINE-COUNT
           MOVE WS-TOTAL-ALERTS TO WS-OUT-ALERT-COUNT
      *
           IF WS-TOTAL-ALERTS = +0
               MOVE 'NO LOW STOCK ALERTS - ALL MODELS ABOVE REORDER'
                   TO WS-OUT-MESSAGE
           ELSE
      *        BUILD INFO MESSAGE VIA COMMSGL0
               MOVE 'INFO' TO WS-MSG-FUNCTION
               STRING WS-TOTAL-ALERTS
                      ' MODEL(S) BELOW REORDER POINT'
                      DELIMITED BY SIZE
                      INTO WS-MSG-TEXT
               MOVE 'W' TO WS-MSG-SEVERITY
               MOVE WS-PROGRAM-NAME TO WS-MSG-PROGRAM-ID
               CALL 'COMMSGL0' USING WS-MSG-FUNCTION
                                     WS-MSG-TEXT
                                     WS-MSG-SEVERITY
                                     WS-MSG-PROGRAM-ID
                                     WS-MSG-OUTPUT-AREA
                                     WS-MSG-RETURN-CODE
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3100-FORMAT-ALERT-LINE                                    *
      ****************************************************************
       3100-FORMAT-ALERT-LINE.
      *
           MOVE WS-HV-DEALER-CODE TO WS-OUT-DEALER(WS-ROW-COUNT)
           MOVE WS-HV-MODEL-YEAR  TO WS-OUT-MODEL-YR(WS-ROW-COUNT)
           MOVE WS-HV-MAKE-CODE   TO WS-OUT-MAKE(WS-ROW-COUNT)
           MOVE WS-HV-MODEL-CODE  TO WS-OUT-MODEL(WS-ROW-COUNT)
           MOVE WS-HV-MODEL-NAME-TX(1:25)
                                   TO WS-OUT-MODEL-DESC(WS-ROW-COUNT)
           MOVE WS-HV-ON-HAND     TO WS-OUT-ON-HAND(WS-ROW-COUNT)
           MOVE WS-HV-REORDER-PT  TO WS-OUT-REORDER-PT(WS-ROW-COUNT)
      *
      *    DEFICIT = REORDER_POINT - ON_HAND
      *
           COMPUTE WS-DEFICIT-WORK =
               WS-HV-REORDER-PT - WS-HV-ON-HAND
           MOVE WS-DEFICIT-WORK TO WS-OUT-DEFICIT(WS-ROW-COUNT)
      *
      *    SUGGESTED ORDER = REORDER_POINT - ON_HAND + SAFETY_STOCK
      *
           COMPUTE WS-SUGGEST-QTY-WORK =
               WS-DEFICIT-WORK + WS-SAFETY-STOCK
           IF WS-SUGGEST-QTY-WORK < +1
               MOVE +1 TO WS-SUGGEST-QTY-WORK
           END-IF
           MOVE WS-SUGGEST-QTY-WORK
               TO WS-OUT-SUGGEST-QTY(WS-ROW-COUNT)
           .
      *
      ****************************************************************
      *    4000-SEND-OUTPUT                                          *
      ****************************************************************
       4000-SEND-OUTPUT.
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
      * END OF STKALRT0                                              *
      ****************************************************************
