       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKSNAP0.
      ****************************************************************
      * PROGRAM:  STKSNAP0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - DAILY STOCK SNAPSHOT            *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CAPTURES POINT-IN-TIME STOCK POSITION FOR          *
      *           HISTORICAL TRACKING. READS ALL STOCK_POSITION      *
      *           RECORDS FOR EACH DEALER, CALCULATES AVERAGE DAYS   *
      *           IN STOCK PER MODEL (FROM VEHICLE TABLE) AND TOTAL  *
      *           VALUE PER MODEL (COUNT * INVOICE PRICE). INSERTS   *
      *           INTO STOCK_SNAPSHOT WITH CURRENT DATE.              *
      *           USUALLY RUN END-OF-DAY BUT AVAILABLE ONLINE.       *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKN00                                           *
      * TABLES:   AUTOSALE.STOCK_POSITION   (READ)                  *
      *           AUTOSALE.VEHICLE           (READ)                  *
      *           AUTOSALE.PRICE_MASTER      (READ)                  *
      *           AUTOSALE.STOCK_SNAPSHOT    (INSERT/DELETE)          *
      * CALLS:    COMDBEL0 - DB2 ERROR HANDLER                     *
      *           COMLGEL0 - AUDIT LOGGING                          *
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
                                          VALUE 'STKSNAP0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKN00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
           COPY DCLSTKSS.
      *
      *    INPUT MESSAGE AREA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
           05  WS-IN-SNAP-DATE           PIC X(10).
      *
      *    OUTPUT MESSAGE AREA
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-SNAP-DATE          PIC X(10).
           05  WS-OUT-RECORDS-READ       PIC Z(5)9.
           05  WS-OUT-RECORDS-INSERT     PIC Z(5)9.
           05  WS-OUT-RECORDS-DELETE     PIC Z(5)9.
           05  WS-OUT-TOTAL-ON-HAND      PIC Z(6)9.
           05  WS-OUT-TOTAL-IN-TRANSIT   PIC Z(6)9.
           05  WS-OUT-TOTAL-ON-HOLD      PIC Z(6)9.
           05  WS-OUT-TOTAL-VALUE        PIC X(16).
           05  WS-OUT-STATUS-MSG         PIC X(30).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
           05  WS-RECORDS-READ           PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-RECORDS-INSERT         PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-RECORDS-DELETE         PIC S9(05) COMP
                                                     VALUE +0.
           05  WS-TOTAL-ON-HAND          PIC S9(07) COMP
                                                     VALUE +0.
           05  WS-TOTAL-IN-TRANSIT       PIC S9(07) COMP
                                                     VALUE +0.
           05  WS-TOTAL-ON-HOLD          PIC S9(07) COMP
                                                     VALUE +0.
           05  WS-TOTAL-VALUE            PIC S9(11)V99 COMP-3
                                                     VALUE +0.
           05  WS-SNAP-DATE-WORK         PIC X(10) VALUE SPACES.
           05  WS-ALL-DEALERS            PIC X(01)  VALUE 'N'.
               88  WS-PROCESS-ALL                    VALUE 'Y'.
      *
      *    CURRENT DATE
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY             PIC 9(04).
           05  WS-CURR-MM               PIC 9(02).
           05  WS-CURR-DD               PIC 9(02).
       01  WS-CURR-DATE-FMT             PIC X(10) VALUE SPACES.
      *
      *    CURSOR: STOCK POSITION WITH AVG DAYS AND VALUE
      *
           EXEC SQL DECLARE CSR_SNAP CURSOR FOR
               SELECT S.DEALER_CODE
                    , S.MODEL_YEAR
                    , S.MAKE_CODE
                    , S.MODEL_CODE
                    , S.ON_HAND_COUNT
                    , S.IN_TRANSIT_COUNT
                    , S.ON_HOLD_COUNT
                    , COALESCE(AVG(V.DAYS_IN_STOCK), 0)
                    , S.ON_HAND_COUNT * P.INVOICE_PRICE
               FROM   AUTOSALE.STOCK_POSITION S
               JOIN   AUTOSALE.PRICE_MASTER   P
                 ON   S.MODEL_YEAR = P.MODEL_YEAR
                AND   S.MAKE_CODE  = P.MAKE_CODE
                AND   S.MODEL_CODE = P.MODEL_CODE
               LEFT JOIN AUTOSALE.VEHICLE V
                 ON   V.DEALER_CODE = S.DEALER_CODE
                AND   V.MODEL_YEAR  = S.MODEL_YEAR
                AND   V.MAKE_CODE   = S.MAKE_CODE
                AND   V.MODEL_CODE  = S.MODEL_CODE
                AND   V.VEHICLE_STATUS IN ('AV','DM','LN','HD')
               WHERE  (S.DEALER_CODE = :WS-IN-DEALER-CODE
                       OR :WS-IN-DEALER-CODE = '     ')
               GROUP BY S.DEALER_CODE
                      , S.MODEL_YEAR
                      , S.MAKE_CODE
                      , S.MODEL_CODE
                      , S.ON_HAND_COUNT
                      , S.IN_TRANSIT_COUNT
                      , S.ON_HOLD_COUNT
                      , P.INVOICE_PRICE
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
           05  WS-HV-IN-TRANSIT         PIC S9(04) COMP.
           05  WS-HV-ON-HOLD            PIC S9(04) COMP.
           05  WS-HV-AVG-DAYS           PIC S9(04) COMP.
           05  WS-HV-TOTAL-VALUE        PIC S9(11)V99 COMP-3.
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
      *    COMFMTL0 LINKAGE (FOR VALUE FORMATTING)
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
               PERFORM 4000-DELETE-EXISTING-SNAPSHOT
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-CREATE-SNAPSHOT
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
           MOVE 'DAILY STOCK SNAPSHOT' TO WS-OUT-TITLE
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
               MOVE 'STKSNAP0: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
      *    DEALER CODE IS OPTIONAL (BLANK = ALL DEALERS)
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'Y' TO WS-ALL-DEALERS
               MOVE 'ALL  ' TO WS-OUT-DEALER-CODE
           ELSE
               MOVE 'N' TO WS-ALL-DEALERS
               MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           END-IF
      *
      *    SNAPSHOT DATE DEFAULTS TO TODAY IF NOT PROVIDED
      *
           IF WS-IN-SNAP-DATE NOT = SPACES
               MOVE WS-IN-SNAP-DATE TO WS-SNAP-DATE-WORK
           ELSE
               MOVE WS-CURR-DATE-FMT TO WS-SNAP-DATE-WORK
           END-IF
      *
           MOVE WS-SNAP-DATE-WORK TO WS-OUT-SNAP-DATE
           .
      *
      ****************************************************************
      *    4000-DELETE-EXISTING-SNAPSHOT - REMOVE EXISTING FOR DATE   *
      ****************************************************************
       4000-DELETE-EXISTING-SNAPSHOT.
      *
           EXEC SQL
               DELETE FROM AUTOSALE.STOCK_SNAPSHOT
               WHERE  SNAPSHOT_DATE = :WS-SNAP-DATE-WORK
                 AND  (DEALER_CODE = :WS-IN-DEALER-CODE
                       OR :WS-IN-DEALER-CODE = '     ')
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE SQLERRD(3) TO WS-RECORDS-DELETE
               WHEN +100
                   MOVE +0 TO WS-RECORDS-DELETE
               WHEN OTHER
                   MOVE WS-PROGRAM-NAME TO WS-DBE-PROGRAM-NAME
                   MOVE '4000-DELETE' TO WS-DBE-SECTION-NAME
                   MOVE 'STOCK_SNAPSHOT' TO WS-DBE-TABLE-NAME
                   MOVE 'DELETE' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM-NAME
                                         WS-DBE-SECTION-NAME
                                         WS-DBE-TABLE-NAME
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT-AREA
                   MOVE WS-DBE-RESULT-MSG TO WS-OUT-MESSAGE
           END-EVALUATE
      *
           MOVE WS-RECORDS-DELETE TO WS-OUT-RECORDS-DELETE
           .
      *
      ****************************************************************
      *    5000-CREATE-SNAPSHOT - READ STOCK AND INSERT SNAPSHOT      *
      ****************************************************************
       5000-CREATE-SNAPSHOT.
      *
           EXEC SQL OPEN CSR_SNAP END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKSNAP0: ERROR OPENING SNAPSHOT CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
      *
               EXEC SQL FETCH CSR_SNAP
                   INTO  :WS-HV-DEALER-CODE
                        , :WS-HV-MODEL-YEAR
                        , :WS-HV-MAKE-CODE
                        , :WS-HV-MODEL-CODE
                        , :WS-HV-ON-HAND
                        , :WS-HV-IN-TRANSIT
                        , :WS-HV-ON-HOLD
                        , :WS-HV-AVG-DAYS
                        , :WS-HV-TOTAL-VALUE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-RECORDS-READ
                       PERFORM 5100-INSERT-SNAPSHOT-ROW
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 'STKSNAP0: DB2 ERROR FETCHING STOCK DATA'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_SNAP END-EXEC
      *
      *    BUILD OUTPUT SUMMARY
      *
           MOVE WS-RECORDS-READ   TO WS-OUT-RECORDS-READ
           MOVE WS-RECORDS-INSERT TO WS-OUT-RECORDS-INSERT
           MOVE WS-TOTAL-ON-HAND  TO WS-OUT-TOTAL-ON-HAND
           MOVE WS-TOTAL-IN-TRANSIT TO WS-OUT-TOTAL-IN-TRANSIT
           MOVE WS-TOTAL-ON-HOLD  TO WS-OUT-TOTAL-ON-HOLD
      *
      *    FORMAT TOTAL VALUE
      *
           MOVE 'CURR' TO WS-FMT-FUNCTION
           MOVE WS-TOTAL-VALUE TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:16) TO WS-OUT-TOTAL-VALUE
      *
      *    AUDIT LOG
      *
           MOVE IO-USER         TO WS-AUD-USER-ID
           MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
           MOVE 'INS'           TO WS-AUD-ACTION-TYPE
           MOVE 'STOCK_SNAPSHOT' TO WS-AUD-TABLE-NAME
           MOVE WS-SNAP-DATE-WORK TO WS-AUD-KEY-VALUE
           MOVE SPACES          TO WS-AUD-OLD-VALUE
           STRING 'RECORDS=' WS-RECORDS-INSERT
                  ' DEALER=' WS-OUT-DEALER-CODE
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
               MOVE 'SNAPSHOT COMPLETED SUCCESSFULLY'
                   TO WS-OUT-STATUS-MSG
               STRING 'SNAPSHOT: '
                      WS-RECORDS-INSERT ' ROWS INSERTED FOR '
                      WS-SNAP-DATE-WORK
                      DELIMITED BY SIZE
                      INTO WS-OUT-MESSAGE
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-INSERT-SNAPSHOT-ROW                                  *
      ****************************************************************
       5100-INSERT-SNAPSHOT-ROW.
      *
           EXEC SQL
               INSERT INTO AUTOSALE.STOCK_SNAPSHOT
                    ( SNAPSHOT_DATE
                    , DEALER_CODE
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , ON_HAND_COUNT
                    , IN_TRANSIT_COUNT
                    , ON_HOLD_COUNT
                    , TOTAL_VALUE
                    , AVG_DAYS_IN_STOCK
                    )
               VALUES
                    ( :WS-SNAP-DATE-WORK
                    , :WS-HV-DEALER-CODE
                    , :WS-HV-MODEL-YEAR
                    , :WS-HV-MAKE-CODE
                    , :WS-HV-MODEL-CODE
                    , :WS-HV-ON-HAND
                    , :WS-HV-IN-TRANSIT
                    , :WS-HV-ON-HOLD
                    , :WS-HV-TOTAL-VALUE
                    , :WS-HV-AVG-DAYS
                    )
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-RECORDS-INSERT
      *
      *        ACCUMULATE TOTALS FOR DISPLAY
      *
               ADD WS-HV-ON-HAND    TO WS-TOTAL-ON-HAND
               ADD WS-HV-IN-TRANSIT TO WS-TOTAL-IN-TRANSIT
               ADD WS-HV-ON-HOLD    TO WS-TOTAL-ON-HOLD
               ADD WS-HV-TOTAL-VALUE TO WS-TOTAL-VALUE
           ELSE
               MOVE WS-PROGRAM-NAME TO WS-DBE-PROGRAM-NAME
               MOVE '5100-INSERT' TO WS-DBE-SECTION-NAME
               MOVE 'STOCK_SNAPSHOT' TO WS-DBE-TABLE-NAME
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
      * END OF STKSNAP0                                              *
      ****************************************************************
