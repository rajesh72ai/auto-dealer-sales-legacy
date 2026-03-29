       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHTRN00.
      ****************************************************************
      * PROGRAM:  VEHTRN00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - DEALER-TO-DEALER TRADE/TRANSFER          *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  MANAGES INTER-DEALER VEHICLE TRANSFERS.            *
      *           REQUEST: SALESPERSON AT FROM-DEALER INITIATES,     *
      *           SELECTS VIN. VALIDATES VEHICLE IS AVAILABLE,       *
      *           NOT ON HOLD, NOT IN A DEAL. CREATES STOCK_TRANSFER *
      *           RECORD WITH STATUS RQ (REQUESTED).                 *
      *           APPROVE: MANAGER AT TO-DEALER APPROVES/REJECTS.    *
      *           ON APPROVE: UPDATES VEHICLE DEALER_CODE, STATUS    *
      *           TO TR (TRANSFER), CREATES STATUS HISTORY.          *
      *           COMPLETE (ARRIVAL): STATUS TO AV AT NEW DEALER,    *
      *           UPDATE STOCK COUNTS AT BOTH DEALERS.               *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHTR - VEHICLE TRANSFER                            *
      * CALLS:    COMSTCK0 - STOCK UPDATE (TRNO AT FROM, TRNI AT TO)*
      *           COMLGEL0 - AUDIT LOG ENTRY                         *
      *           COMSEQL0 - SEQUENCE NUMBER GENERATION              *
      * TABLES:   AUTOSALE.VEHICLE                                   *
      *           AUTOSALE.STOCK_TRANSFER                             *
      *           AUTOSALE.VEHICLE_STATUS_HIST                       *
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
                                          VALUE 'VEHTRN00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
           COPY WSMSGFMT.
      *
           COPY DCLVEHCL.
      *
           COPY DCLSTKTF.
      *
           COPY DCLVHSTH.
      *
      *    INPUT FIELDS
      *
       01  WS-TRN-INPUT.
           05  WS-TI-FUNCTION            PIC X(02).
               88  WS-TI-REQUEST                    VALUE 'RQ'.
               88  WS-TI-APPROVE                    VALUE 'AP'.
               88  WS-TI-REJECT                     VALUE 'RJ'.
               88  WS-TI-COMPLETE                   VALUE 'CM'.
               88  WS-TI-INQUIRY                    VALUE 'IQ'.
           05  WS-TI-VIN                 PIC X(17).
           05  WS-TI-FROM-DEALER         PIC X(05).
           05  WS-TI-TO-DEALER           PIC X(05).
           05  WS-TI-TRANSFER-ID         PIC S9(09) COMP.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-TRN-OUTPUT.
           05  WS-TO-STATUS-LINE.
               10  WS-TO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-TO-MSG-TEXT       PIC X(70).
           05  WS-TO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-TO-TRANSFER-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'TRANSFER ID: '.
               10  WS-TO-TRANSFER-ID    PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-TO-TRN-STATUS     PIC X(02).
               10  FILLER               PIC X(43) VALUE SPACES.
           05  WS-TO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-TO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'STOCK NO: '.
               10  WS-TO-STOCK-NUM      PIC X(08).
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-TO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-TO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-TO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-TO-MODEL          PIC X(06).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'COLOR: '.
               10  WS-TO-COLOR          PIC X(03).
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-TO-DEALER-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'FROM DEALER: '.
               10  WS-TO-FROM-DEALER    PIC X(05).
               10  FILLER               PIC X(08) VALUE SPACES.
               10  FILLER               PIC X(11)
                   VALUE 'TO DEALER: '.
               10  WS-TO-TO-DEALER      PIC X(05).
               10  FILLER               PIC X(37) VALUE SPACES.
           05  WS-TO-REQUESTED-LINE.
               10  FILLER               PIC X(14)
                   VALUE 'REQUESTED BY: '.
               10  WS-TO-REQUESTED-BY   PIC X(08).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(04) VALUE 'ON: '.
               10  WS-TO-REQUESTED-TS   PIC X(19).
               10  FILLER               PIC X(30) VALUE SPACES.
           05  WS-TO-APPROVED-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'APPROVED BY: '.
               10  WS-TO-APPROVED-BY    PIC X(08).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(04) VALUE 'ON: '.
               10  WS-TO-APPROVED-TS    PIC X(19).
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-TO-FILLER             PIC X(1172) VALUE SPACES.
      *
      *    STOCK UPDATE CALL FIELDS
      *
       01  WS-STK-REQUEST.
           05  WS-SR-FUNCTION            PIC X(04).
           05  WS-SR-DEALER-CODE         PIC X(05).
           05  WS-SR-VIN                 PIC X(17).
           05  WS-SR-USER-ID             PIC X(08).
           05  WS-SR-REASON              PIC X(60).
       01  WS-STK-RESULT.
           05  WS-RS-RETURN-CODE         PIC S9(04) COMP.
           05  WS-RS-RETURN-MSG          PIC X(79).
           05  WS-RS-OLD-STATUS          PIC X(02).
           05  WS-RS-NEW-STATUS          PIC X(02).
           05  WS-RS-ON-HAND             PIC S9(04) COMP.
           05  WS-RS-IN-TRANSIT          PIC S9(04) COMP.
           05  WS-RS-ALLOCATED           PIC S9(04) COMP.
           05  WS-RS-ON-HOLD             PIC S9(04) COMP.
           05  WS-RS-SOLD-MTD            PIC S9(04) COMP.
           05  WS-RS-SOLD-YTD            PIC S9(04) COMP.
           05  WS-RS-SQLCODE             PIC S9(09) COMP.
      *
      *    SEQUENCE NUMBER CALL FIELDS
      *
       01  WS-SEQ-REQUEST.
           05  WS-SEQ-TABLE-NAME         PIC X(18).
           05  WS-SEQ-COLUMN-NAME        PIC X(18).
       01  WS-SEQ-RESULT.
           05  WS-SEQ-NEXT-VALUE         PIC S9(09) COMP.
           05  WS-SEQ-RC                 PIC S9(04) COMP.
           05  WS-SEQ-MSG                PIC X(50).
      *
      *    AUDIT LOG CALL FIELDS
      *
       01  WS-LOG-REQUEST.
           05  WS-LR-PROGRAM            PIC X(08).
           05  WS-LR-FUNCTION           PIC X(08).
           05  WS-LR-USER-ID            PIC X(08).
           05  WS-LR-ENTITY-TYPE        PIC X(08).
           05  WS-LR-ENTITY-KEY         PIC X(30).
           05  WS-LR-DESCRIPTION        PIC X(80).
           05  WS-LR-RETURN-CODE        PIC S9(04) COMP.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-GEN-TRANSFER-ID       PIC S9(09) COMP VALUE +0.
           05  WS-HIST-SEQ              PIC S9(09) COMP VALUE +0.
           05  WS-DEAL-COUNT            PIC S9(09) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-APPROVED-BY        PIC S9(04) COMP VALUE -1.
           05  WS-NI-APPROVED-TS        PIC S9(04) COMP VALUE -1.
           05  WS-NI-COMPLETED-TS       PIC S9(04) COMP VALUE -1.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-PCB-STATUS             PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-PCB-MOD-NAME           PIC X(08).
           05  IO-PCB-USER-ID            PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER                    PIC X(22).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN WS-TI-REQUEST
                       PERFORM 4000-PROCESS-REQUEST
                   WHEN WS-TI-APPROVE
                       PERFORM 5000-PROCESS-APPROVE
                   WHEN WS-TI-REJECT
                       PERFORM 6000-PROCESS-REJECT
                   WHEN WS-TI-COMPLETE
                       PERFORM 7000-PROCESS-COMPLETE
                   WHEN WS-TI-INQUIRY
                       PERFORM 8000-PROCESS-INQUIRY
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION: USE RQ AP RJ CM IQ'
                           TO WS-TO-MSG-TEXT
               END-EVALUATE
           END-IF
      *
           PERFORM 9000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE +0 TO WS-RETURN-CODE
           INITIALIZE WS-TRN-OUTPUT
           MOVE 'VEHTRN00' TO WS-TO-MSG-ID
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
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'IMS GU FAILED' TO WS-TO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION    TO WS-TI-FUNCTION
               MOVE WS-INP-BODY(1:17)  TO WS-TI-VIN
               MOVE WS-INP-BODY(18:5)  TO WS-TI-FROM-DEALER
               MOVE WS-INP-BODY(23:5)  TO WS-TI-TO-DEALER
      *        TRANSFER ID FOR APPROVE/REJECT/COMPLETE
               IF WS-INP-BODY(28:9) IS NUMERIC
                   MOVE WS-INP-BODY(28:9) TO WS-TI-TRANSFER-ID
               ELSE
                   MOVE +0 TO WS-TI-TRANSFER-ID
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-TI-REQUEST
               IF WS-TI-VIN = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'VIN IS REQUIRED FOR TRANSFER REQUEST'
                       TO WS-TO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-TI-FROM-DEALER = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'FROM DEALER CODE IS REQUIRED'
                       TO WS-TO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-TI-TO-DEALER = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'TO DEALER CODE IS REQUIRED'
                       TO WS-TO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-TI-FROM-DEALER = WS-TI-TO-DEALER
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'FROM AND TO DEALER CANNOT BE THE SAME'
                       TO WS-TO-MSG-TEXT
               END-IF
           ELSE
               IF WS-TI-TRANSFER-ID = +0
               AND NOT WS-TI-INQUIRY
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'TRANSFER ID IS REQUIRED'
                       TO WS-TO-MSG-TEXT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-PROCESS-REQUEST - CREATE TRANSFER REQUEST            *
      ****************************************************************
       4000-PROCESS-REQUEST.
      *
      *    VALIDATE VEHICLE EXISTS AND IS AVAILABLE
      *
           EXEC SQL
               SELECT VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , EXTERIOR_COLOR
                    , VEHICLE_STATUS
                    , DEALER_CODE
                    , STOCK_NUMBER
               INTO  :VIN            OF DCLVEHICLE
                    , :MODEL-YEAR    OF DCLVEHICLE
                    , :MAKE-CODE     OF DCLVEHICLE
                    , :MODEL-CODE    OF DCLVEHICLE
                    , :EXTERIOR-COLOR
                    , :VEHICLE-STATUS
                    , :DEALER-CODE   OF DCLVEHICLE
                    , :STOCK-NUMBER
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-TI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND' TO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING VEHICLE'
                   TO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY VEHICLE IS AT FROM-DEALER
      *
           IF DEALER-CODE OF DCLVEHICLE NOT = WS-TI-FROM-DEALER
               MOVE +8 TO WS-RETURN-CODE
               STRING 'VEHICLE NOT AT DEALER '
                      WS-TI-FROM-DEALER
                      DELIMITED BY SIZE
                      INTO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY VEHICLE IS AVAILABLE
      *
           IF VEHICLE-STATUS NOT = 'AV'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'VEHICLE NOT AVAILABLE - STATUS IS '
                      VEHICLE-STATUS
                      DELIMITED BY SIZE
                      INTO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK VEHICLE IS NOT IN A PENDING DEAL
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-DEAL-COUNT
               FROM   AUTOSALE.SALES_DEAL
               WHERE  VIN = :WS-TI-VIN
                 AND  DEAL_STATUS IN ('PD', 'AP', 'FN')
           END-EXEC
      *
           IF WS-DEAL-COUNT > +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE IS IN AN ACTIVE DEAL - CANNOT TRANSFER'
                   TO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    GENERATE TRANSFER ID
      *
           MOVE 'TRANSFER_ID   ' TO WS-SEQ-TABLE-NAME
           MOVE 'STOCK_TRANSFER' TO WS-SEQ-COLUMN-NAME
           CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                 WS-SEQ-RESULT
      *
           IF WS-SEQ-RC NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR GENERATING TRANSFER ID'
                   TO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-SEQ-NEXT-VALUE TO WS-GEN-TRANSFER-ID
      *
      *    INSERT STOCK_TRANSFER RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.STOCK_TRANSFER
                    ( TRANSFER_ID
                    , FROM_DEALER
                    , TO_DEALER
                    , VIN
                    , TRANSFER_STATUS
                    , REQUESTED_BY
                    , APPROVED_BY
                    , REQUESTED_TS
                    , APPROVED_TS
                    , COMPLETED_TS
                    )
               VALUES
                    ( :WS-GEN-TRANSFER-ID
                    , :WS-TI-FROM-DEALER
                    , :WS-TI-TO-DEALER
                    , :WS-TI-VIN
                    , 'RQ'
                    , :IO-PCB-USER-ID
                    , NULL
                    , CURRENT TIMESTAMP
                    , NULL
                    , NULL
                    )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR CREATING TRANSFER REQUEST'
                   TO WS-TO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    FORMAT SUCCESS OUTPUT
      *
           MOVE 'TRANSFER REQUEST CREATED SUCCESSFULLY'
               TO WS-TO-MSG-TEXT
           MOVE WS-GEN-TRANSFER-ID TO WS-TO-TRANSFER-ID
           MOVE 'RQ'               TO WS-TO-TRN-STATUS
           MOVE WS-TI-VIN          TO WS-TO-VIN
           MOVE STOCK-NUMBER       TO WS-TO-STOCK-NUM
           MOVE MODEL-YEAR OF DCLVEHICLE TO WS-TO-YEAR
           MOVE MAKE-CODE OF DCLVEHICLE  TO WS-TO-MAKE
           MOVE MODEL-CODE OF DCLVEHICLE TO WS-TO-MODEL
           MOVE EXTERIOR-COLOR     TO WS-TO-COLOR
           MOVE WS-TI-FROM-DEALER  TO WS-TO-FROM-DEALER
           MOVE WS-TI-TO-DEALER    TO WS-TO-TO-DEALER
           MOVE IO-PCB-USER-ID     TO WS-TO-REQUESTED-BY
      *
      *    AUDIT LOG
      *
           MOVE 'VEHTRN00'      TO WS-LR-PROGRAM
           MOVE 'TRNREQ  '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'TRANSFER'      TO WS-LR-ENTITY-TYPE
           MOVE WS-TI-VIN       TO WS-LR-ENTITY-KEY
           STRING 'TRANSFER REQUESTED: '
                  WS-TI-FROM-DEALER ' >> '
                  WS-TI-TO-DEALER
                  ' VIN ' WS-TI-VIN
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-APPROVE - APPROVE TRANSFER REQUEST           *
      ****************************************************************
       5000-PROCESS-APPROVE.
      *
      *    LOOK UP THE TRANSFER REQUEST
      *
           EXEC SQL
               SELECT TRANSFER_ID
                    , FROM_DEALER
                    , TO_DEALER
                    , VIN
                    , TRANSFER_STATUS
                    , REQUESTED_BY
                    , REQUESTED_TS
               INTO  :TRANSFER-ID
                    , :FROM-DEALER
                    , :TO-DEALER
                    , :VIN OF DCLSTOCK-TRANSFER
                    , :TRANSFER-STATUS
                    , :REQUESTED-BY
                    , :REQUESTED-TS
               FROM   AUTOSALE.STOCK_TRANSFER
               WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRANSFER REQUEST NOT FOUND'
                   TO WS-TO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING TRANSFER REQUEST'
                   TO WS-TO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    VERIFY STATUS IS RQ (REQUESTED)
      *
           IF TRANSFER-STATUS NOT = 'RQ'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'TRANSFER IS NOT IN REQUEST STATUS - IS '
                      TRANSFER-STATUS
                      DELIMITED BY SIZE
                      INTO WS-TO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE TRANSFER TO APPROVED
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_TRANSFER
                  SET TRANSFER_STATUS = 'AP'
                    , APPROVED_BY     = :IO-PCB-USER-ID
                    , APPROVED_TS     = CURRENT TIMESTAMP
               WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING TRANSFER TO APPROVED'
                   TO WS-TO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE VEHICLE STATUS TO TR (TRANSFER)
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = 'TR'
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :VIN OF DCLSTOCK-TRANSFER
           END-EXEC
      *
      *    CALL COMSTCK0 - TRANSFER OUT FROM SENDING DEALER
      *
           MOVE 'TRNO'             TO WS-SR-FUNCTION
           MOVE FROM-DEALER        TO WS-SR-DEALER-CODE
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-SR-VIN
           MOVE IO-PCB-USER-ID     TO WS-SR-USER-ID
           STRING 'TRANSFER APPROVED TO DEALER '
                  TO-DEALER
                  DELIMITED BY SIZE
                  INTO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
      *    INSERT STATUS HISTORY
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO   :WS-HIST-SEQ
               FROM   AUTOSALE.VEHICLE_STATUS_HIST
               WHERE  VIN = :VIN OF DCLSTOCK-TRANSFER
           END-EXEC
      *
           EXEC SQL
               INSERT INTO AUTOSALE.VEHICLE_STATUS_HIST
                    ( VIN, STATUS_SEQ, OLD_STATUS, NEW_STATUS,
                      CHANGED_BY, CHANGE_REASON, CHANGED_TS )
               VALUES
                    ( :VIN OF DCLSTOCK-TRANSFER
                    , :WS-HIST-SEQ
                    , 'AV'
                    , 'TR'
                    , :IO-PCB-USER-ID
                    , 'DEALER TRANSFER APPROVED'
                    , CURRENT TIMESTAMP )
           END-EXEC
      *
      *    FORMAT OUTPUT
      *
           MOVE 'TRANSFER APPROVED - VEHICLE IN TRANSIT'
               TO WS-TO-MSG-TEXT
           MOVE TRANSFER-ID    TO WS-TO-TRANSFER-ID
           MOVE 'AP'           TO WS-TO-TRN-STATUS
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-TO-VIN
           MOVE FROM-DEALER    TO WS-TO-FROM-DEALER
           MOVE TO-DEALER      TO WS-TO-TO-DEALER
           MOVE REQUESTED-BY   TO WS-TO-REQUESTED-BY
           MOVE REQUESTED-TS(1:19) TO WS-TO-REQUESTED-TS
           MOVE IO-PCB-USER-ID TO WS-TO-APPROVED-BY
      *
      *    AUDIT LOG
      *
           MOVE 'VEHTRN00'      TO WS-LR-PROGRAM
           MOVE 'TRNAPPR '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'TRANSFER'      TO WS-LR-ENTITY-TYPE
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-LR-ENTITY-KEY
           STRING 'TRANSFER APPROVED: '
                  FROM-DEALER ' >> ' TO-DEALER
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-PROCESS-REJECT - REJECT TRANSFER REQUEST             *
      ****************************************************************
       6000-PROCESS-REJECT.
      *
      *    LOOK UP THE TRANSFER REQUEST
      *
           EXEC SQL
               SELECT TRANSFER_ID
                    , FROM_DEALER
                    , TO_DEALER
                    , VIN
                    , TRANSFER_STATUS
                    , REQUESTED_BY
               INTO  :TRANSFER-ID
                    , :FROM-DEALER
                    , :TO-DEALER
                    , :VIN OF DCLSTOCK-TRANSFER
                    , :TRANSFER-STATUS
                    , :REQUESTED-BY
               FROM   AUTOSALE.STOCK_TRANSFER
               WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRANSFER REQUEST NOT FOUND'
                   TO WS-TO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           IF TRANSFER-STATUS NOT = 'RQ'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CAN ONLY REJECT REQUESTS IN RQ STATUS'
                   TO WS-TO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    UPDATE TRANSFER TO REJECTED
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_TRANSFER
                  SET TRANSFER_STATUS = 'RJ'
                    , APPROVED_BY     = :IO-PCB-USER-ID
                    , APPROVED_TS     = CURRENT TIMESTAMP
               WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR REJECTING TRANSFER'
                   TO WS-TO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE 'TRANSFER REQUEST REJECTED'
               TO WS-TO-MSG-TEXT
           MOVE TRANSFER-ID  TO WS-TO-TRANSFER-ID
           MOVE 'RJ'         TO WS-TO-TRN-STATUS
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-TO-VIN
           MOVE FROM-DEALER  TO WS-TO-FROM-DEALER
           MOVE TO-DEALER    TO WS-TO-TO-DEALER
      *
      *    AUDIT LOG
      *
           MOVE 'VEHTRN00'      TO WS-LR-PROGRAM
           MOVE 'TRNREJT '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'TRANSFER'      TO WS-LR-ENTITY-TYPE
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-LR-ENTITY-KEY
           STRING 'TRANSFER REJECTED: ID='
                  WS-TI-TRANSFER-ID
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-PROCESS-COMPLETE - VEHICLE ARRIVED AT TO-DEALER      *
      ****************************************************************
       7000-PROCESS-COMPLETE.
      *
      *    LOOK UP THE TRANSFER
      *
           EXEC SQL
               SELECT TRANSFER_ID
                    , FROM_DEALER
                    , TO_DEALER
                    , VIN
                    , TRANSFER_STATUS
                    , REQUESTED_BY
                    , APPROVED_BY
                    , REQUESTED_TS
                    , APPROVED_TS
               INTO  :TRANSFER-ID
                    , :FROM-DEALER
                    , :TO-DEALER
                    , :VIN OF DCLSTOCK-TRANSFER
                    , :TRANSFER-STATUS
                    , :REQUESTED-BY
                    , :APPROVED-BY :WS-NI-APPROVED-BY
                    , :REQUESTED-TS
                    , :APPROVED-TS :WS-NI-APPROVED-TS
               FROM   AUTOSALE.STOCK_TRANSFER
               WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRANSFER NOT FOUND' TO WS-TO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
           IF TRANSFER-STATUS NOT = 'AP'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRANSFER MUST BE APPROVED TO COMPLETE'
                   TO WS-TO-MSG-TEXT
               GO TO 7000-EXIT
           END-IF
      *
      *    UPDATE TRANSFER TO COMPLETED
      *
           EXEC SQL
               UPDATE AUTOSALE.STOCK_TRANSFER
                  SET TRANSFER_STATUS = 'CM'
                    , COMPLETED_TS    = CURRENT TIMESTAMP
               WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
           END-EXEC
      *
      *    UPDATE VEHICLE: NEW DEALER, STATUS AVAILABLE
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET DEALER_CODE    = :TO-DEALER
                    , VEHICLE_STATUS = 'AV'
                    , DAYS_IN_STOCK  = 0
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :VIN OF DCLSTOCK-TRANSFER
           END-EXEC
      *
      *    CALL COMSTCK0 - TRANSFER IN AT RECEIVING DEALER
      *
           MOVE 'TRNI'             TO WS-SR-FUNCTION
           MOVE TO-DEALER          TO WS-SR-DEALER-CODE
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-SR-VIN
           MOVE IO-PCB-USER-ID     TO WS-SR-USER-ID
           STRING 'TRANSFER RECEIVED FROM DEALER '
                  FROM-DEALER
                  DELIMITED BY SIZE
                  INTO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
      *    INSERT STATUS HISTORY - TR TO AV
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO   :WS-HIST-SEQ
               FROM   AUTOSALE.VEHICLE_STATUS_HIST
               WHERE  VIN = :VIN OF DCLSTOCK-TRANSFER
           END-EXEC
      *
           EXEC SQL
               INSERT INTO AUTOSALE.VEHICLE_STATUS_HIST
                    ( VIN, STATUS_SEQ, OLD_STATUS, NEW_STATUS,
                      CHANGED_BY, CHANGE_REASON, CHANGED_TS )
               VALUES
                    ( :VIN OF DCLSTOCK-TRANSFER
                    , :WS-HIST-SEQ
                    , 'TR'
                    , 'AV'
                    , :IO-PCB-USER-ID
                    , 'TRANSFER COMPLETE - RECEIVED AT NEW DEALER'
                    , CURRENT TIMESTAMP )
           END-EXEC
      *
      *    FORMAT OUTPUT
      *
           MOVE 'TRANSFER COMPLETED - VEHICLE AT NEW DEALER'
               TO WS-TO-MSG-TEXT
           MOVE TRANSFER-ID   TO WS-TO-TRANSFER-ID
           MOVE 'CM'          TO WS-TO-TRN-STATUS
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-TO-VIN
           MOVE FROM-DEALER   TO WS-TO-FROM-DEALER
           MOVE TO-DEALER     TO WS-TO-TO-DEALER
           MOVE REQUESTED-BY  TO WS-TO-REQUESTED-BY
           MOVE REQUESTED-TS(1:19) TO WS-TO-REQUESTED-TS
           IF WS-NI-APPROVED-BY >= +0
               MOVE APPROVED-BY TO WS-TO-APPROVED-BY
           END-IF
           IF WS-NI-APPROVED-TS >= +0
               MOVE APPROVED-TS(1:19) TO WS-TO-APPROVED-TS
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE 'VEHTRN00'      TO WS-LR-PROGRAM
           MOVE 'TRNCMPL '      TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID  TO WS-LR-USER-ID
           MOVE 'TRANSFER'      TO WS-LR-ENTITY-TYPE
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-LR-ENTITY-KEY
           STRING 'TRANSFER COMPLETE: '
                  FROM-DEALER ' >> ' TO-DEALER
                  ' VIN RECEIVED'
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
       7000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    8000-PROCESS-INQUIRY - DISPLAY TRANSFER DETAILS           *
      ****************************************************************
       8000-PROCESS-INQUIRY.
      *
      *    INQUIRY BY VIN (LATEST TRANSFER) OR TRANSFER ID
      *
           IF WS-TI-TRANSFER-ID > +0
               EXEC SQL
                   SELECT TRANSFER_ID
                        , FROM_DEALER
                        , TO_DEALER
                        , VIN
                        , TRANSFER_STATUS
                        , REQUESTED_BY
                        , APPROVED_BY
                        , REQUESTED_TS
                        , APPROVED_TS
                   INTO  :TRANSFER-ID
                        , :FROM-DEALER
                        , :TO-DEALER
                        , :VIN OF DCLSTOCK-TRANSFER
                        , :TRANSFER-STATUS
                        , :REQUESTED-BY
                        , :APPROVED-BY  :WS-NI-APPROVED-BY
                        , :REQUESTED-TS
                        , :APPROVED-TS  :WS-NI-APPROVED-TS
                   FROM   AUTOSALE.STOCK_TRANSFER
                   WHERE  TRANSFER_ID = :WS-TI-TRANSFER-ID
               END-EXEC
           ELSE
               EXEC SQL
                   SELECT TRANSFER_ID
                        , FROM_DEALER
                        , TO_DEALER
                        , VIN
                        , TRANSFER_STATUS
                        , REQUESTED_BY
                        , APPROVED_BY
                        , REQUESTED_TS
                        , APPROVED_TS
                   INTO  :TRANSFER-ID
                        , :FROM-DEALER
                        , :TO-DEALER
                        , :VIN OF DCLSTOCK-TRANSFER
                        , :TRANSFER-STATUS
                        , :REQUESTED-BY
                        , :APPROVED-BY  :WS-NI-APPROVED-BY
                        , :REQUESTED-TS
                        , :APPROVED-TS  :WS-NI-APPROVED-TS
                   FROM   AUTOSALE.STOCK_TRANSFER
                   WHERE  VIN = :WS-TI-VIN
                   ORDER BY REQUESTED_TS DESC
                   FETCH FIRST 1 ROW ONLY
               END-EXEC
           END-IF
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO TRANSFER FOUND' TO WS-TO-MSG-TEXT
               GO TO 8000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON TRANSFER INQUIRY'
                   TO WS-TO-MSG-TEXT
               GO TO 8000-EXIT
           END-IF
      *
           MOVE 'TRANSFER INQUIRY COMPLETE'
               TO WS-TO-MSG-TEXT
           MOVE TRANSFER-ID    TO WS-TO-TRANSFER-ID
           MOVE TRANSFER-STATUS TO WS-TO-TRN-STATUS
           MOVE VIN OF DCLSTOCK-TRANSFER TO WS-TO-VIN
           MOVE FROM-DEALER    TO WS-TO-FROM-DEALER
           MOVE TO-DEALER      TO WS-TO-TO-DEALER
           MOVE REQUESTED-BY   TO WS-TO-REQUESTED-BY
           MOVE REQUESTED-TS(1:19) TO WS-TO-REQUESTED-TS
           IF WS-NI-APPROVED-BY >= +0
               MOVE APPROVED-BY TO WS-TO-APPROVED-BY
           END-IF
           IF WS-NI-APPROVED-TS >= +0
               MOVE APPROVED-TS(1:19) TO WS-TO-APPROVED-TS
           END-IF
           .
       8000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-TRN-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHTRN00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHTRN00                                              *
      ****************************************************************
