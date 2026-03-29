       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKTRN00.
      ****************************************************************
      * PROGRAM:  STKTRN00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - INTER-DEALER STOCK TRANSFER     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DUAL-PURPOSE SCREEN FOR STOCK TRANSFERS:           *
      *           1. CREATE TRANSFER REQUEST (VIN + DEST DEALER)     *
      *           2. LIST PENDING TRANSFERS FOR THIS DEALER           *
      *           3. APPROVE/REJECT PENDING TRANSFERS                 *
      *           ON APPROVAL, TRIGGERS VEHICLE TRANSFER PROCESS.    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKT00                                           *
      * TABLES:   AUTOSALE.STOCK_TRANSFER    (READ/INSERT/UPDATE)    *
      *           AUTOSALE.VEHICLE           (READ)                  *
      *           AUTOSALE.DEALER            (READ - VALIDATE)       *
      * CALLS:    COMSTCK0 - STOCK COUNT UPDATE (TRNO)              *
      *           COMSEQL0 - SEQUENCE NUMBER GENERATOR              *
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
                                          VALUE 'STKTRN00'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKT00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
           COPY WSIOPCB.
           COPY DCLSTKTF.
           COPY DCLVEHCL.
      *
      *    INPUT MESSAGE AREA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-ACTION              PIC X(04).
               88  WS-IN-REQUEST                     VALUE 'RQST'.
               88  WS-IN-LIST                        VALUE 'LIST'.
               88  WS-IN-APPROVE                     VALUE 'APRV'.
               88  WS-IN-REJECT                      VALUE 'REJT'.
           05  WS-IN-DEALER-CODE         PIC X(05).
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-DEST-DEALER         PIC X(05).
           05  WS-IN-TRANSFER-ID         PIC X(09).
      *
      *    OUTPUT MESSAGE AREA
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-ACTION-DESC        PIC X(20).
           05  WS-OUT-LINE-COUNT         PIC S9(04) COMP.
           05  WS-OUT-DETAIL OCCURS 12 TIMES.
               10  WS-OUT-TRAN-ID        PIC Z(8)9.
               10  WS-OUT-FROM-DLR       PIC X(05).
               10  WS-OUT-TO-DLR         PIC X(05).
               10  WS-OUT-TRAN-VIN       PIC X(17).
               10  WS-OUT-TRAN-STATUS    PIC X(02).
               10  WS-OUT-REQ-BY         PIC X(08).
               10  WS-OUT-REQ-DATE       PIC X(10).
           05  WS-OUT-NEW-TRAN-ID        PIC Z(8)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ROW-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
           05  WS-NEXT-TRAN-ID           PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-TRAN-ID-NUM            PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-VEH-STATUS             PIC X(02)  VALUE SPACES.
           05  WS-VEH-DEALER             PIC X(05)  VALUE SPACES.
           05  WS-DEST-VALID             PIC X(01)  VALUE 'N'.
               88  WS-DEST-IS-VALID                 VALUE 'Y'.
           05  WS-DEST-DEALER-NAME       PIC X(40)  VALUE SPACES.
      *
      *    CURSOR FOR PENDING TRANSFERS
      *
           EXEC SQL DECLARE CSR_PENDING CURSOR FOR
               SELECT TRANSFER_ID
                    , FROM_DEALER
                    , TO_DEALER
                    , VIN
                    , TRANSFER_STATUS
                    , REQUESTED_BY
                    , REQUESTED_TS
               FROM   AUTOSALE.STOCK_TRANSFER
               WHERE  (FROM_DEALER = :WS-IN-DEALER-CODE
                       OR TO_DEALER = :WS-IN-DEALER-CODE)
                 AND  TRANSFER_STATUS = 'RQ'
               ORDER BY REQUESTED_TS DESC
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HV-FIELDS.
           05  WS-HV-TRAN-ID            PIC S9(09) COMP.
           05  WS-HV-FROM-DEALER        PIC X(05).
           05  WS-HV-TO-DEALER          PIC X(05).
           05  WS-HV-VIN                PIC X(17).
           05  WS-HV-STATUS             PIC X(02).
           05  WS-HV-REQ-BY             PIC X(08).
           05  WS-HV-REQ-TS             PIC X(26).
      *
      *    COMSEQL0 LINKAGE
      *
       01  WS-SEQ-REQUEST.
           05  WS-SEQ-TYPE              PIC X(04).
           05  WS-SEQ-DEALER-CODE       PIC X(05).
       01  WS-SEQ-RESULT.
           05  WS-SEQ-RETURN-CODE       PIC S9(04) COMP.
           05  WS-SEQ-RETURN-MSG        PIC X(79).
           05  WS-SEQ-FORMATTED-NUM     PIC X(10).
           05  WS-SEQ-RAW-NUM           PIC S9(09) COMP.
      *
      *    COMSTCK0 LINKAGE
      *
       01  WS-STK-REQUEST.
           05  WS-STK-FUNCTION           PIC X(04).
           05  WS-STK-DEALER-CODE        PIC X(05).
           05  WS-STK-VIN               PIC X(17).
           05  WS-STK-USER-ID           PIC X(08).
           05  WS-STK-REASON            PIC X(60).
      *
       01  WS-STK-RESULT.
           05  WS-STK-RETURN-CODE       PIC S9(04) COMP.
           05  WS-STK-RETURN-MSG        PIC X(79).
           05  WS-STK-OLD-STATUS        PIC X(02).
           05  WS-STK-NEW-STATUS        PIC X(02).
           05  WS-STK-ON-HAND           PIC S9(04) COMP.
           05  WS-STK-IN-TRANSIT        PIC S9(04) COMP.
           05  WS-STK-ALLOCATED         PIC S9(04) COMP.
           05  WS-STK-ON-HOLD           PIC S9(04) COMP.
           05  WS-STK-SOLD-MTD          PIC S9(04) COMP.
           05  WS-STK-SOLD-YTD          PIC S9(04) COMP.
           05  WS-STK-SQLCODE           PIC S9(09) COMP.
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
                   WHEN WS-IN-REQUEST
                       PERFORM 4000-CREATE-TRANSFER-REQUEST
                   WHEN WS-IN-LIST
                       PERFORM 5000-LIST-PENDING-TRANSFERS
                   WHEN WS-IN-APPROVE
                       PERFORM 6000-APPROVE-TRANSFER
                   WHEN WS-IN-REJECT
                       PERFORM 7000-REJECT-TRANSFER
               END-EVALUATE
           END-IF
      *
           PERFORM 8000-SEND-OUTPUT
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
           MOVE 'INTER-DEALER STOCK TRANSFER' TO WS-OUT-TITLE
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
               MOVE 'STKTRN00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF NOT WS-IN-REQUEST AND NOT WS-IN-LIST
           AND NOT WS-IN-APPROVE AND NOT WS-IN-REJECT
               MOVE
               'INVALID ACTION (RQST/LIST/APRV/REJT)'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
      *
      *    REQUEST REQUIRES VIN AND DESTINATION DEALER
      *
           IF WS-IN-REQUEST
               IF WS-IN-VIN = SPACES
                   MOVE 'VIN IS REQUIRED FOR TRANSFER REQUEST'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
               IF WS-IN-DEST-DEALER = SPACES
                   MOVE 'DESTINATION DEALER IS REQUIRED'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
               IF WS-IN-DEST-DEALER = WS-IN-DEALER-CODE
                   MOVE 'CANNOT TRANSFER TO SAME DEALER'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
               MOVE 'TRANSFER REQUEST' TO WS-OUT-ACTION-DESC
           END-IF
      *
      *    APPROVE/REJECT REQUIRES TRANSFER ID
      *
           IF WS-IN-APPROVE OR WS-IN-REJECT
               IF WS-IN-TRANSFER-ID = SPACES
                   MOVE 'TRANSFER ID IS REQUIRED'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
               IF WS-IN-APPROVE
                   MOVE 'APPROVE TRANSFER' TO WS-OUT-ACTION-DESC
               ELSE
                   MOVE 'REJECT TRANSFER' TO WS-OUT-ACTION-DESC
               END-IF
           END-IF
      *
           IF WS-IN-LIST
               MOVE 'PENDING TRANSFERS' TO WS-OUT-ACTION-DESC
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CREATE-TRANSFER-REQUEST                              *
      ****************************************************************
       4000-CREATE-TRANSFER-REQUEST.
      *
      *    VALIDATE VEHICLE EXISTS AND IS AVAILABLE
      *
           EXEC SQL
               SELECT VEHICLE_STATUS, DEALER_CODE
               INTO  :WS-VEH-STATUS, :WS-VEH-DEALER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-IN-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE 'VEHICLE NOT FOUND FOR SPECIFIED VIN'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE 'STKTRN00: DB2 ERROR READING VEHICLE'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-VEH-STATUS NOT = 'AV'
               MOVE 'VEHICLE MUST BE AVAILABLE (AV) FOR TRANSFER'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           IF WS-VEH-DEALER NOT = WS-IN-DEALER-CODE
               MOVE 'VEHICLE NOT ASSIGNED TO REQUESTING DEALER'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    VALIDATE DESTINATION DEALER EXISTS
      *
           EXEC SQL
               SELECT DEALER_NAME
               INTO   :WS-DEST-DEALER-NAME
               FROM   AUTOSALE.DEALER
               WHERE  DEALER_CODE = :WS-IN-DEST-DEALER
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE 'DESTINATION DEALER CODE NOT FOUND'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    GENERATE TRANSFER SEQUENCE NUMBER
      *
           MOVE 'TRAN' TO WS-SEQ-TYPE
           MOVE WS-IN-DEALER-CODE TO WS-SEQ-DEALER-CODE
           CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                 WS-SEQ-RESULT
      *
           IF WS-SEQ-RETURN-CODE NOT = +0
               MOVE WS-SEQ-RETURN-MSG TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-SEQ-RAW-NUM TO WS-NEXT-TRAN-ID
      *
      *    INSERT TRANSFER REQUEST
      *
           EXEC SQL
               INSERT INTO AUTOSALE.STOCK_TRANSFER
                    ( TRANSFER_ID
                    , FROM_DEALER
                    , TO_DEALER
                    , VIN
                    , TRANSFER_STATUS
                    , REQUESTED_BY
                    , REQUESTED_TS
                    )
               VALUES
                    ( :WS-NEXT-TRAN-ID
                    , :WS-IN-DEALER-CODE
                    , :WS-IN-DEST-DEALER
                    , :WS-IN-VIN
                    , 'RQ'
                    , :IO-USER
                    , CURRENT TIMESTAMP
                    )
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE WS-NEXT-TRAN-ID TO WS-OUT-NEW-TRAN-ID
               STRING 'TRANSFER REQUEST '
                      WS-SEQ-FORMATTED-NUM
                      ' CREATED SUCCESSFULLY'
                      DELIMITED BY SIZE
                      INTO WS-OUT-MESSAGE
      *
      *        AUDIT LOG
      *
               MOVE IO-USER         TO WS-AUD-USER-ID
               MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
               MOVE 'INS'           TO WS-AUD-ACTION-TYPE
               MOVE 'STOCK_TRANSFER' TO WS-AUD-TABLE-NAME
               MOVE WS-IN-VIN       TO WS-AUD-KEY-VALUE
               MOVE SPACES          TO WS-AUD-OLD-VALUE
               STRING 'FROM=' WS-IN-DEALER-CODE
                      ' TO=' WS-IN-DEST-DEALER
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
               MOVE 'STKTRN00: ERROR CREATING TRANSFER REQUEST'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-LIST-PENDING-TRANSFERS                               *
      ****************************************************************
       5000-LIST-PENDING-TRANSFERS.
      *
           EXEC SQL OPEN CSR_PENDING END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKTRN00: ERROR OPENING PENDING CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +12
      *
               EXEC SQL FETCH CSR_PENDING
                   INTO  :WS-HV-TRAN-ID
                        , :WS-HV-FROM-DEALER
                        , :WS-HV-TO-DEALER
                        , :WS-HV-VIN
                        , :WS-HV-STATUS
                        , :WS-HV-REQ-BY
                        , :WS-HV-REQ-TS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-ROW-COUNT
                       MOVE WS-HV-TRAN-ID
                           TO WS-OUT-TRAN-ID(WS-ROW-COUNT)
                       MOVE WS-HV-FROM-DEALER
                           TO WS-OUT-FROM-DLR(WS-ROW-COUNT)
                       MOVE WS-HV-TO-DEALER
                           TO WS-OUT-TO-DLR(WS-ROW-COUNT)
                       MOVE WS-HV-VIN
                           TO WS-OUT-TRAN-VIN(WS-ROW-COUNT)
                       MOVE WS-HV-STATUS
                           TO WS-OUT-TRAN-STATUS(WS-ROW-COUNT)
                       MOVE WS-HV-REQ-BY
                           TO WS-OUT-REQ-BY(WS-ROW-COUNT)
                       MOVE WS-HV-REQ-TS(1:10)
                           TO WS-OUT-REQ-DATE(WS-ROW-COUNT)
                   WHEN +100
                       MOVE 'Y' TO WS-EOF-FLAG
                   WHEN OTHER
                       MOVE 'Y' TO WS-EOF-FLAG
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_PENDING END-EXEC
      *
           MOVE WS-ROW-COUNT TO WS-OUT-LINE-COUNT
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO PENDING TRANSFER REQUESTS FOUND'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-APPROVE-TRANSFER                                     *
      ****************************************************************
       6000-APPROVE-TRANSFER.
      *
           COMPUTE WS-TRAN-ID-NUM =
               FUNCTION NUMVAL(WS-IN-TRANSFER-ID)
      *
      *    VERIFY TRANSFER EXISTS AND IS PENDING
      *
           EXEC SQL
               SELECT TRANSFER_ID, FROM_DEALER, VIN
               INTO  :WS-HV-TRAN-ID
                    , :WS-HV-FROM-DEALER
                    , :WS-HV-VIN
               FROM   AUTOSALE.STOCK_TRANSFER
               WHERE  TRANSFER_ID     = :WS-TRAN-ID-NUM
                 AND  TRANSFER_STATUS  = 'RQ'
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE 'TRANSFER NOT FOUND OR NOT IN RQ STATUS'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE 'STKTRN00: DB2 ERROR READING TRANSFER'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
      *
      *    UPDATE TRANSFER STATUS TO APPROVED
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_TRANSFER
                  SET TRANSFER_STATUS = 'AP'
                    , APPROVED_BY     = :IO-USER
                    , APPROVED_TS     = CURRENT TIMESTAMP
               WHERE  TRANSFER_ID    = :WS-TRAN-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +0
      *
      *        TRIGGER TRANSFER-OUT ON SOURCE DEALER VIA COMSTCK0
      *
               MOVE 'TRNO' TO WS-STK-FUNCTION
               MOVE WS-HV-FROM-DEALER TO WS-STK-DEALER-CODE
               MOVE WS-HV-VIN         TO WS-STK-VIN
               MOVE IO-USER           TO WS-STK-USER-ID
               STRING 'APPROVED TRANSFER '
                      WS-IN-TRANSFER-ID
                      DELIMITED BY SIZE
                      INTO WS-STK-REASON
               CALL 'COMSTCK0' USING WS-STK-REQUEST
                                     WS-STK-RESULT
      *
               STRING 'TRANSFER '
                      WS-IN-TRANSFER-ID
                      ' APPROVED - VEHICLE SET TO IN-TRANSIT'
                      DELIMITED BY SIZE
                      INTO WS-OUT-MESSAGE
      *
      *        AUDIT LOG
      *
               MOVE IO-USER         TO WS-AUD-USER-ID
               MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
               MOVE 'APR'           TO WS-AUD-ACTION-TYPE
               MOVE 'STOCK_TRANSFER' TO WS-AUD-TABLE-NAME
               MOVE WS-IN-TRANSFER-ID TO WS-AUD-KEY-VALUE
               MOVE 'STATUS=RQ' TO WS-AUD-OLD-VALUE
               MOVE 'STATUS=AP' TO WS-AUD-NEW-VALUE
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
               MOVE 'STKTRN00: ERROR UPDATING TRANSFER STATUS'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-REJECT-TRANSFER                                      *
      ****************************************************************
       7000-REJECT-TRANSFER.
      *
           COMPUTE WS-TRAN-ID-NUM =
               FUNCTION NUMVAL(WS-IN-TRANSFER-ID)
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_TRANSFER
                  SET TRANSFER_STATUS = 'RJ'
                    , APPROVED_BY     = :IO-USER
                    , APPROVED_TS     = CURRENT TIMESTAMP
               WHERE  TRANSFER_ID    = :WS-TRAN-ID-NUM
                 AND  TRANSFER_STATUS = 'RQ'
           END-EXEC
      *
           IF SQLCODE = +0
               STRING 'TRANSFER '
                      WS-IN-TRANSFER-ID
                      ' REJECTED'
                      DELIMITED BY SIZE
                      INTO WS-OUT-MESSAGE
      *
      *        AUDIT LOG
      *
               MOVE IO-USER         TO WS-AUD-USER-ID
               MOVE WS-PROGRAM-NAME TO WS-AUD-PROGRAM-ID
               MOVE 'REJ'           TO WS-AUD-ACTION-TYPE
               MOVE 'STOCK_TRANSFER' TO WS-AUD-TABLE-NAME
               MOVE WS-IN-TRANSFER-ID TO WS-AUD-KEY-VALUE
               MOVE 'STATUS=RQ' TO WS-AUD-OLD-VALUE
               MOVE 'STATUS=RJ' TO WS-AUD-NEW-VALUE
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
               IF SQLCODE = +100
                   MOVE 'TRANSFER NOT FOUND OR NOT PENDING'
                       TO WS-OUT-MESSAGE
               ELSE
                   MOVE 'STKTRN00: ERROR REJECTING TRANSFER'
                       TO WS-OUT-MESSAGE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    8000-SEND-OUTPUT                                          *
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
           .
      ****************************************************************
      * END OF STKTRN00                                              *
      ****************************************************************
