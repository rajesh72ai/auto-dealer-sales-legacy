       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKRCN00.
      ****************************************************************
      * PROGRAM:  STKRCN00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - STOCK RECONCILIATION            *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  LISTS EACH MODEL WITH SYSTEM COUNT (FROM           *
      *           STOCK_POSITION) VS PHYSICAL COUNT (USER ENTERED).  *
      *           CALCULATES VARIANCE PER MODEL AND TOTAL.           *
      *           PF5=ACCEPT CREATES STOCK_ADJUSTMENT RECORDS.       *
      *           PF6=PRINT FORMATS RECONCILIATION REPORT.           *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKR00                                           *
      * TABLES:   AUTOSALE.STOCK_POSITION   (READ/UPDATE)            *
      *           AUTOSALE.MODEL_MASTER      (READ)                  *
      *           AUTOSALE.STOCK_ADJUSTMENT  (INSERT)                *
      * CALLS:    COMLGEL0 - AUDIT LOGGING                          *
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
                                          VALUE 'STKRCN00'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKR00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
           COPY DCLSTKPS.
           COPY DCLSTKAJ.
           COPY DCLMODEL.
      *
      *    INPUT MESSAGE AREA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
           05  WS-IN-RECON-DATE          PIC X(10).
           05  WS-IN-PF-KEY              PIC X(02).
           05  WS-IN-PHYSICAL-COUNTS OCCURS 20 TIMES.
               10  WS-IN-PHY-MODEL-YR    PIC X(04).
               10  WS-IN-PHY-MAKE        PIC X(03).
               10  WS-IN-PHY-MODEL       PIC X(06).
               10  WS-IN-PHY-COUNT       PIC X(05).
      *
      *    OUTPUT MESSAGE AREA
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-RECON-DATE         PIC X(10).
           05  WS-OUT-LINE-COUNT         PIC S9(04) COMP.
           05  WS-OUT-DETAIL OCCURS 20 TIMES.
               10  WS-OUT-MODEL-YR       PIC X(04).
               10  WS-OUT-MAKE           PIC X(03).
               10  WS-OUT-MODEL          PIC X(06).
               10  WS-OUT-MODEL-DESC     PIC X(25).
               10  WS-OUT-SYS-COUNT      PIC Z(4)9.
               10  WS-OUT-PHY-COUNT      PIC Z(4)9.
               10  WS-OUT-VARIANCE       PIC -(4)9.
               10  WS-OUT-VAR-FLAG       PIC X(03).
           05  WS-OUT-TOTAL-VARIANCE     PIC -(6)9.
           05  WS-OUT-STATUS-MSG         PIC X(30).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ROW-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
           05  WS-TOTAL-VARIANCE         PIC S9(07) COMP
                                                     VALUE +0.
           05  WS-ADJ-IDX                PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-VARIANCE-WORK          PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-PHY-COUNT-NUM          PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-NEXT-ADJUST-ID         PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-ADJ-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
      *
      *    CURSOR FOR STOCK POSITION WITH MODEL DESC
      *
           EXEC SQL DECLARE CSR_STK_RCN CURSOR FOR
               SELECT S.MODEL_YEAR
                    , S.MAKE_CODE
                    , S.MODEL_CODE
                    , S.ON_HAND_COUNT
                    , M.MODEL_NAME
               FROM   AUTOSALE.STOCK_POSITION S
               JOIN   AUTOSALE.MODEL_MASTER   M
                 ON   S.MODEL_YEAR = M.MODEL_YEAR
                AND   S.MAKE_CODE  = M.MAKE_CODE
                AND   S.MODEL_CODE = M.MODEL_CODE
               WHERE  S.DEALER_CODE = :WS-IN-DEALER-CODE
               ORDER BY S.MAKE_CODE
                      , S.MODEL_CODE
                      , S.MODEL_YEAR
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR
      *
       01  WS-HV-FIELDS.
           05  WS-HV-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-HV-MAKE-CODE          PIC X(03).
           05  WS-HV-MODEL-CODE         PIC X(06).
           05  WS-HV-ON-HAND            PIC S9(04) COMP.
           05  WS-HV-MODEL-NAME.
               49  WS-HV-MODEL-NAME-LN  PIC S9(04) COMP.
               49  WS-HV-MODEL-NAME-TX  PIC X(40).
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
               EVALUATE WS-IN-PF-KEY
                   WHEN '05'
                       PERFORM 5000-ACCEPT-RECONCILIATION
                   WHEN '06'
                       PERFORM 6000-FORMAT-PRINT-REPORT
                   WHEN OTHER
                       PERFORM 4000-DISPLAY-RECONCILIATION
               END-EVALUATE
           END-IF
      *
           PERFORM 7000-SEND-OUTPUT
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
           MOVE 'STOCK RECONCILIATION' TO WS-OUT-TITLE
           MOVE SPACES TO WS-OUT-MESSAGE
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
               MOVE 'STKRCN00: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'DEALER CODE IS REQUIRED FOR RECONCILIATION'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-RECON-DATE = SPACES
               MOVE 'RECONCILIATION DATE IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           MOVE WS-IN-RECON-DATE  TO WS-OUT-RECON-DATE
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-DISPLAY-RECONCILIATION - LOAD SYSTEM COUNTS          *
      ****************************************************************
       4000-DISPLAY-RECONCILIATION.
      *
           EXEC SQL OPEN CSR_STK_RCN END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKRCN00: ERROR OPENING RECON CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +20
      *
               EXEC SQL FETCH CSR_STK_RCN
                   INTO  :WS-HV-MODEL-YEAR
                        , :WS-HV-MAKE-CODE
                        , :WS-HV-MODEL-CODE
                        , :WS-HV-ON-HAND
                        , :WS-HV-MODEL-NAME
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-ROW-COUNT
                       MOVE WS-HV-MODEL-YEAR
                           TO WS-OUT-MODEL-YR(WS-ROW-COUNT)
                       MOVE WS-HV-MAKE-CODE
                           TO WS-OUT-MAKE(WS-ROW-COUNT)
                       MOVE WS-HV-MODEL-CODE
                           TO WS-OUT-MODEL(WS-ROW-COUNT)
                       MOVE WS-HV-MODEL-NAME-TX(1:25)
                           TO WS-OUT-MODEL-DESC(WS-ROW-COUNT)
                       MOVE WS-HV-ON-HAND
                           TO WS-OUT-SYS-COUNT(WS-ROW-COUNT)
                       MOVE +0
                           TO WS-OUT-PHY-COUNT(WS-ROW-COUNT)
                       MOVE +0
                           TO WS-OUT-VARIANCE(WS-ROW-COUNT)
                       MOVE SPACES
                           TO WS-OUT-VAR-FLAG(WS-ROW-COUNT)
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 'STKRCN00: DB2 ERROR FETCHING RECON DATA'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_STK_RCN END-EXEC
      *
           MOVE WS-ROW-COUNT TO WS-OUT-LINE-COUNT
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO STOCK POSITION RECORDS FOUND'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE 'ENTER PHYSICAL COUNTS. PF5=ACCEPT PF6=PRINT'
                   TO WS-OUT-STATUS-MSG
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-ACCEPT-RECONCILIATION - PROCESS VARIANCES            *
      ****************************************************************
       5000-ACCEPT-RECONCILIATION.
      *
      *    FIRST DISPLAY CURRENT SYSTEM COUNTS
      *
           PERFORM 4000-DISPLAY-RECONCILIATION
      *
           IF WS-OUT-MESSAGE NOT = SPACES
               GO TO 5000-EXIT
           END-IF
      *
      *    GET NEXT ADJUSTMENT ID
      *
           EXEC SQL
               SELECT COALESCE(MAX(ADJUST_ID), 0) + 1
               INTO   :WS-NEXT-ADJUST-ID
               FROM   AUTOSALE.STOCK_ADJUSTMENT
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               MOVE 'STKRCN00: ERROR GETTING NEXT ADJUST ID'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-TOTAL-VARIANCE
           MOVE +0 TO WS-ADJ-COUNT
      *
      *    PROCESS EACH LINE WITH PHYSICAL COUNTS
      *
           PERFORM VARYING WS-ADJ-IDX FROM 1 BY 1
               UNTIL WS-ADJ-IDX > WS-OUT-LINE-COUNT
      *
               IF WS-IN-PHY-COUNT(WS-ADJ-IDX) NOT = SPACES
               AND WS-IN-PHY-COUNT(WS-ADJ-IDX) NOT = '00000'
      *
                   COMPUTE WS-PHY-COUNT-NUM =
                       FUNCTION NUMVAL(
                           WS-IN-PHY-COUNT(WS-ADJ-IDX))
      *
                   MOVE WS-PHY-COUNT-NUM
                       TO WS-OUT-PHY-COUNT(WS-ADJ-IDX)
      *
      *            CALCULATE VARIANCE (PHYSICAL - SYSTEM)
      *
                   COMPUTE WS-VARIANCE-WORK =
                       WS-PHY-COUNT-NUM - WS-HV-ON-HAND
      *
                   MOVE WS-VARIANCE-WORK
                       TO WS-OUT-VARIANCE(WS-ADJ-IDX)
                   ADD WS-VARIANCE-WORK TO WS-TOTAL-VARIANCE
      *
                   IF WS-VARIANCE-WORK NOT = +0
                       MOVE 'ADJ' TO WS-OUT-VAR-FLAG(WS-ADJ-IDX)
                       PERFORM 5100-INSERT-ADJUSTMENT
                   END-IF
               END-IF
           END-PERFORM
      *
           MOVE WS-TOTAL-VARIANCE TO WS-OUT-TOTAL-VARIANCE
      *
           IF WS-ADJ-COUNT > +0
               STRING 'RECONCILIATION ACCEPTED: '
                      WS-ADJ-COUNT
                      ' ADJUSTMENTS CREATED'
                      DELIMITED BY SIZE
                      INTO WS-OUT-STATUS-MSG
      *
      *        AUDIT LOG THE RECONCILIATION
      *
               MOVE IO-USER TO WS-AUD-USER-ID
               MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
               MOVE 'UPD' TO WS-AUD-ACTION-TYPE
               MOVE 'STOCK_POSITION' TO WS-AUD-TABLE-NAME
               MOVE WS-IN-DEALER-CODE TO WS-AUD-KEY-VALUE
               MOVE SPACES TO WS-AUD-OLD-VALUE
               STRING 'RECONCILIATION: '
                      WS-ADJ-COUNT ' ADJUSTMENTS'
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
               MOVE 'NO VARIANCES FOUND - NO ADJUSTMENTS NEEDED'
                   TO WS-OUT-STATUS-MSG
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-INSERT-ADJUSTMENT - CREATE STOCK_ADJUSTMENT RECORD   *
      ****************************************************************
       5100-INSERT-ADJUSTMENT.
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
                    , 'RECONCILIATION  '
                    , 'PH'
                    , 'PHYSICAL COUNT RECONCILIATION'
                    , 'AV'
                    , 'AV'
                    , :IO-USER
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-NEXT-ADJUST-ID
               ADD +1 TO WS-ADJ-COUNT
      *
      *        UPDATE STOCK_POSITION ON_HAND_COUNT
      *
               EXEC SQL
                   UPDATE AUTOSALE.STOCK_POSITION
                      SET ON_HAND_COUNT = :WS-PHY-COUNT-NUM
                        , UPDATED_TS    = CURRENT TIMESTAMP
                   WHERE  DEALER_CODE = :WS-IN-DEALER-CODE
                     AND  MODEL_YEAR  = :WS-HV-MODEL-YEAR
                     AND  MAKE_CODE   = :WS-HV-MAKE-CODE
                     AND  MODEL_CODE  = :WS-HV-MODEL-CODE
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE WS-PROGRAM-NAME TO WS-DBE-PROGRAM-NAME
                   MOVE '5100-INSERT-ADJ' TO WS-DBE-SECTION-NAME
                   MOVE 'STOCK_POSITION' TO WS-DBE-TABLE-NAME
                   MOVE 'UPDATE' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM-NAME
                                         WS-DBE-SECTION-NAME
                                         WS-DBE-TABLE-NAME
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT-AREA
               END-IF
           ELSE
               MOVE WS-PROGRAM-NAME TO WS-DBE-PROGRAM-NAME
               MOVE '5100-INSERT-ADJ' TO WS-DBE-SECTION-NAME
               MOVE 'STOCK_ADJUSTMENT' TO WS-DBE-TABLE-NAME
               MOVE 'INSERT' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                     WS-DBE-PROGRAM-NAME
                                     WS-DBE-SECTION-NAME
                                     WS-DBE-TABLE-NAME
                                     WS-DBE-OPERATION
                                     WS-DBE-RESULT-AREA
           END-IF
           .
      *
      ****************************************************************
      *    6000-FORMAT-PRINT-REPORT - BUILD PRINT OUTPUT             *
      ****************************************************************
       6000-FORMAT-PRINT-REPORT.
      *
      *    LOAD CURRENT RECONCILIATION DATA FIRST
      *
           PERFORM 4000-DISPLAY-RECONCILIATION
      *
           MOVE 'RECONCILIATION REPORT FORMATTED FOR PRINTING'
               TO WS-OUT-STATUS-MSG
           .
      *
      ****************************************************************
      *    7000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       7000-SEND-OUTPUT.
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
      * END OF STKRCN00                                              *
      ****************************************************************
