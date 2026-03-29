       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALCAN00.
      ****************************************************************
      * PROGRAM:    SALCAN00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALX                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLCN00 (CANCELLATION RESPONSE)                 *
      *                                                              *
      * PURPOSE:    SALE CANCELLATION / UNWIND. VALIDATES DEAL       *
      *             EXISTS AND NOT ALREADY CANCELLED. IF VEHICLE WAS *
      *             MARKED SOLD: REVERSES STATUS TO AV. IF STOCK WAS *
      *             DECREMENTED: REVERSES VIA COMSTCK0 (RECV).       *
      *             IF INCENTIVES WERE APPLIED: DECREMENTS           *
      *             UNITS_USED. IF FLOOR PLAN WAS PAID OFF:          *
      *             REVERSES PAYOFF. UPDATES SALES_DEAL STATUS TO    *
      *             CA (CANCELLED) OR UW (UNWOUND). INSERTS          *
      *             COMPREHENSIVE AUDIT TRAIL FOR ALL REVERSALS.     *
      *                                                              *
      * CALLS:      COMSTCK0 - STOCK UPDATE (RECV TO REVERSE SOLD)   *
      *             COMLGEL0 - AUDIT LOG ENTRY                       *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL        (READ/UPDATE)        *
      *             AUTOSALE.VEHICLE            (READ/UPDATE)        *
      *             AUTOSALE.STOCK_POSITION     (UPDATE VIA COMSTCK0)*
      *             AUTOSALE.INCENTIVE_APPLIED  (READ/DELETE)        *
      *             AUTOSALE.INCENTIVE_PROGRAM  (UPDATE)             *
      *             AUTOSALE.FLOOR_PLAN_VEHICLE (READ/UPDATE)        *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALCAN00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
           COPY DCLINAPP.
      *
      *    INPUT FIELDS
      *
       01  WS-CAN-INPUT.
           05  WS-CI-DEAL-NUMBER    PIC X(10).
           05  WS-CI-CANCEL-REASON PIC X(200).
      *
      *    OUTPUT LAYOUT
      *
       01  WS-CAN-OUTPUT.
           05  WS-CO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- SALE CANCELLATION --------'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-CO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(29) VALUE SPACES.
           05  WS-CO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-CO-STATUS-LINE.
               10  FILLER           PIC X(16)
                   VALUE 'PREVIOUS STATUS:'.
               10  WS-CO-OLD-STAT  PIC X(02).
               10  FILLER           PIC X(16)
                   VALUE '   NEW STATUS:  '.
               10  WS-CO-NEW-STAT  PIC X(02).
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-CO-BLANK-2       PIC X(79) VALUE SPACES.
           05  WS-CO-REVERSAL-HDR.
               10  FILLER           PIC X(30)
                   VALUE 'REVERSALS PERFORMED:          '.
               10  FILLER           PIC X(49) VALUE SPACES.
           05  WS-CO-REV OCCURS 8 TIMES.
               10  WS-CO-REV-NUM   PIC Z9.
               10  FILLER           PIC X(02) VALUE '. '.
               10  WS-CO-REV-DESC  PIC X(72).
               10  FILLER           PIC X(03) VALUE SPACES.
           05  WS-CO-BLANK-3       PIC X(79) VALUE SPACES.
           05  WS-CO-REASON-LINE.
               10  FILLER           PIC X(08)
                   VALUE 'REASON: '.
               10  WS-CO-REASON    PIC X(71).
           05  WS-CO-FILLER        PIC X(495) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-OLD-STATUS       PIC X(02) VALUE SPACES.
           05  WS-NEW-STATUS       PIC X(02) VALUE SPACES.
           05  WS-VEH-STATUS       PIC X(02) VALUE SPACES.
           05  WS-REV-COUNT        PIC S9(04) COMP VALUE +0.
           05  WS-WAS-DELIVERED    PIC X(01) VALUE 'N'.
               88  WS-DEAL-DELIVERED          VALUE 'Y'.
               88  WS-DEAL-NOT-DELIVERED      VALUE 'N'.
           05  WS-INC-COUNT        PIC S9(04) COMP VALUE +0.
           05  WS-FP-EXISTS        PIC X(01) VALUE 'N'.
               88  WS-HAS-FLOOR-PLAN          VALUE 'Y'.
               88  WS-NO-FLOOR-PLAN           VALUE 'N'.
      *
      *    INCENTIVE REVERSAL CURSOR
      *
           EXEC SQL DECLARE CSR_INC_REVERSE CURSOR FOR
               SELECT INCENTIVE_ID
               FROM   AUTOSALE.INCENTIVE_APPLIED
               WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
           END-EXEC
      *
      *    HOST VARIABLES
      *
       01  WS-HV-INC-ID            PIC X(10).
       01  WS-EOF-FLAG             PIC X(01) VALUE 'N'.
           88  WS-END-OF-DATA                VALUE 'Y'.
           88  WS-MORE-DATA                  VALUE 'N'.
      *
      *    STOCK UPDATE CALL FIELDS
      *
       01  WS-STK-REQUEST.
           05  WS-SR-FUNCTION      PIC X(04).
           05  WS-SR-DEALER-CODE   PIC X(05).
           05  WS-SR-VIN           PIC X(17).
           05  WS-SR-USER-ID       PIC X(08).
           05  WS-SR-REASON        PIC X(60).
       01  WS-STK-RESULT.
           05  WS-RS-RETURN-CODE   PIC S9(04) COMP.
           05  WS-RS-RETURN-MSG    PIC X(79).
           05  WS-RS-OLD-STATUS    PIC X(02).
           05  WS-RS-NEW-STATUS    PIC X(02).
           05  WS-RS-ON-HAND       PIC S9(04) COMP.
           05  WS-RS-IN-TRANSIT    PIC S9(04) COMP.
           05  WS-RS-ALLOCATED     PIC S9(04) COMP.
           05  WS-RS-ON-HOLD       PIC S9(04) COMP.
           05  WS-RS-SOLD-MTD      PIC S9(04) COMP.
           05  WS-RS-SOLD-YTD      PIC S9(04) COMP.
           05  WS-RS-SQLCODE       PIC S9(09) COMP.
      *
      *    AUDIT LOG
      *
       01  WS-LOG-REQUEST.
           05  WS-LR-PROGRAM       PIC X(08).
           05  WS-LR-FUNCTION      PIC X(08).
           05  WS-LR-USER-ID       PIC X(08).
           05  WS-LR-ENTITY-TYPE   PIC X(08).
           05  WS-LR-ENTITY-KEY    PIC X(30).
           05  WS-LR-DESCRIPTION   PIC X(80).
           05  WS-LR-RETURN-CODE   PIC S9(04) COMP.
      *
      *    DB2 ERROR HANDLER
      *
       01  WS-DBE-REQUEST.
           05  WS-DBE-PROGRAM      PIC X(08).
           05  WS-DBE-PARAGRAPH    PIC X(30).
           05  WS-DBE-SQLCODE      PIC S9(09) COMP.
           05  WS-DBE-SQLERRM      PIC X(70).
           05  WS-DBE-TABLE-NAME   PIC X(30).
           05  WS-DBE-OPERATION    PIC X(10).
       01  WS-DBE-RESULT.
           05  WS-DBE-RETURN-CODE  PIC S9(04) COMP.
           05  WS-DBE-RETURN-MSG   PIC X(79).
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER              PIC X(10).
           05  IO-PCB-STATUS       PIC X(02).
           05  FILLER              PIC X(20).
           05  IO-PCB-MOD-NAME     PIC X(08).
           05  IO-PCB-USER-ID      PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER              PIC X(22).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3000-VALIDATE-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4000-REVERSE-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4500-REVERSE-STOCK
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-REVERSE-INCENTIVES
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5500-REVERSE-FLOOR-PLAN
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-CANCEL-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-WRITE-AUDIT-TRAIL
           END-IF
      *
           PERFORM 8000-FORMAT-OUTPUT
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
           INITIALIZE WS-CAN-OUTPUT
           MOVE SPACES TO WS-ERROR-MSG
           MOVE +0 TO WS-REV-COUNT
           SET WS-DEAL-NOT-DELIVERED TO TRUE
           SET WS-NO-FLOOR-PLAN TO TRUE
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT                                        *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-IO-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'SALCAN00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-CI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:200) TO WS-CI-CANCEL-REASON
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-DEAL                                        *
      ****************************************************************
       3000-VALIDATE-DEAL.
      *
           IF WS-CI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-CI-CANCEL-REASON = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CANCELLATION REASON IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEALER_CODE
                    , VIN
                    , DEAL_STATUS
                    , VEHICLE_PRICE
                    , TOTAL_PRICE
                    , TRADE_ALLOW
                    , REBATES_APPLIED
               INTO   :DEAL-NUMBER
                    , :DEALER-CODE OF DCLSALES-DEAL
                    , :VIN         OF DCLSALES-DEAL
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :TOTAL-PRICE
                    , :TRADE-ALLOW
                    , :REBATES-APPLIED
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NOT FOUND' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING DEAL' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           MOVE DEAL-STATUS TO WS-OLD-STATUS
      *
      *    CANNOT CANCEL IF ALREADY CANCELLED
      *
           IF DEAL-STATUS = 'CA' OR DEAL-STATUS = 'UW'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL IS ALREADY CANCELLED/UNWOUND'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
      *    DETERMINE IF THIS IS A CANCELLATION OR UNWIND
      *    (UNWIND = DEAL WAS DELIVERED, CANCEL = NOT YET DELIVERED)
      *
           IF DEAL-STATUS = 'DL'
               SET WS-DEAL-DELIVERED TO TRUE
               MOVE 'UW' TO WS-NEW-STATUS
           ELSE
               SET WS-DEAL-NOT-DELIVERED TO TRUE
               MOVE 'CA' TO WS-NEW-STATUS
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-REVERSE-VEHICLE - RESTORE VEHICLE TO AVAILABLE       *
      ****************************************************************
       4000-REVERSE-VEHICLE.
      *
      *    GET CURRENT VEHICLE STATUS
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
               INTO   :WS-VEH-STATUS
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :VIN OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4000-EXIT
           END-IF
      *
      *    IF VEHICLE WAS SOLD, REVERSE TO AVAILABLE
      *
           IF WS-VEH-STATUS = 'SD'
               EXEC SQL
                   UPDATE AUTOSALE.VEHICLE
                      SET VEHICLE_STATUS = 'AV'
                        , UPDATED_TS     = CURRENT TIMESTAMP
                   WHERE  VIN = :VIN OF DCLSALES-DEAL
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE +12 TO WS-RETURN-CODE
                   MOVE 'ERROR REVERSING VEHICLE STATUS'
                       TO WS-ERROR-MSG
                   GO TO 4000-EXIT
               END-IF
      *
               ADD +1 TO WS-REV-COUNT
               IF WS-REV-COUNT <= +8
                   MOVE WS-REV-COUNT
                       TO WS-CO-REV-NUM(WS-REV-COUNT)
                   MOVE 'VEHICLE STATUS REVERSED: SD -> AV'
                       TO WS-CO-REV-DESC(WS-REV-COUNT)
               END-IF
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-REVERSE-STOCK - CALL COMSTCK0 RECV TO UNDO SOLD     *
      ****************************************************************
       4500-REVERSE-STOCK.
      *
      *    ONLY REVERSE STOCK IF VEHICLE WAS DELIVERED/SOLD
      *
           IF NOT WS-DEAL-DELIVERED
           AND WS-VEH-STATUS NOT = 'SD'
               GO TO 4500-EXIT
           END-IF
      *
           MOVE 'RECV' TO WS-SR-FUNCTION
           MOVE DEALER-CODE OF DCLSALES-DEAL TO WS-SR-DEALER-CODE
           MOVE VIN OF DCLSALES-DEAL TO WS-SR-VIN
           MOVE IO-PCB-USER-ID TO WS-SR-USER-ID
           STRING 'CANCEL/UNWIND: DEAL ' WS-CI-DEAL-NUMBER
                  DELIMITED BY SIZE
                  INTO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           IF WS-RS-RETURN-CODE > +4
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-RS-RETURN-MSG TO WS-ERROR-MSG
               GO TO 4500-EXIT
           END-IF
      *
           ADD +1 TO WS-REV-COUNT
           IF WS-REV-COUNT <= +8
               MOVE WS-REV-COUNT
                   TO WS-CO-REV-NUM(WS-REV-COUNT)
               MOVE 'STOCK POSITION REVERSED: SOLD -> ON HAND'
                   TO WS-CO-REV-DESC(WS-REV-COUNT)
           END-IF
           .
       4500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-REVERSE-INCENTIVES - DECREMENT UNITS_USED            *
      ****************************************************************
       5000-REVERSE-INCENTIVES.
      *
      *    CHECK IF ANY INCENTIVES WERE APPLIED
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-INC-COUNT
               FROM   AUTOSALE.INCENTIVE_APPLIED
               WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
           END-EXEC
      *
           IF WS-INC-COUNT = +0
               GO TO 5000-EXIT
           END-IF
      *
      *    REVERSE EACH INCENTIVE
      *
           EXEC SQL OPEN CSR_INC_REVERSE END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 5000-EXIT
           END-IF
      *
           SET WS-MORE-DATA TO TRUE
      *
           PERFORM 5100-FETCH-REVERSE-INC
               UNTIL WS-END-OF-DATA
      *
           EXEC SQL CLOSE CSR_INC_REVERSE END-EXEC
      *
      *    DELETE INCENTIVE_APPLIED RECORDS
      *
           EXEC SQL
               DELETE FROM AUTOSALE.INCENTIVE_APPLIED
               WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
           END-EXEC
      *
           ADD +1 TO WS-REV-COUNT
           IF WS-REV-COUNT <= +8
               MOVE WS-REV-COUNT
                   TO WS-CO-REV-NUM(WS-REV-COUNT)
               STRING 'INCENTIVES REVERSED: '
                      WS-INC-COUNT ' PROGRAM(S)'
                      DELIMITED BY SIZE
                      INTO WS-CO-REV-DESC(WS-REV-COUNT)
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-REVERSE-INC - FETCH AND DECREMENT EACH         *
      ****************************************************************
       5100-FETCH-REVERSE-INC.
      *
           EXEC SQL FETCH CSR_INC_REVERSE
               INTO :WS-HV-INC-ID
           END-EXEC
      *
           IF SQLCODE = +100
               SET WS-END-OF-DATA TO TRUE
               GO TO 5100-EXIT
           END-IF
           IF SQLCODE NOT = +0
               SET WS-END-OF-DATA TO TRUE
               GO TO 5100-EXIT
           END-IF
      *
      *    DECREMENT UNITS_USED
      *
           EXEC SQL
               UPDATE AUTOSALE.INCENTIVE_PROGRAM
                  SET UNITS_USED = UNITS_USED - 1
               WHERE  INCENTIVE_ID = :WS-HV-INC-ID
                 AND  UNITS_USED > 0
           END-EXEC
           .
       5100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5500-REVERSE-FLOOR-PLAN - UNDO PAYOFF IF APPLICABLE      *
      ****************************************************************
       5500-REVERSE-FLOOR-PLAN.
      *
      *    CHECK IF FLOOR PLAN WAS PAID OFF FOR THIS VIN
      *
           EXEC SQL
               SELECT 'Y'
               INTO   :WS-FP-EXISTS
               FROM   AUTOSALE.FLOOR_PLAN_VEHICLE
               WHERE  VIN = :VIN OF DCLSALES-DEAL
                 AND  FP_STATUS = 'PD'
               FETCH FIRST 1 ROWS ONLY
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 5500-EXIT
           END-IF
      *
      *    REVERSE PAYOFF STATUS BACK TO ACTIVE
      *
           EXEC SQL
               UPDATE AUTOSALE.FLOOR_PLAN_VEHICLE
                  SET FP_STATUS  = 'AC'
                    , PAYOFF_DATE = NULL
                    , UPDATED_TS = CURRENT TIMESTAMP
               WHERE  VIN = :VIN OF DCLSALES-DEAL
                 AND  FP_STATUS = 'PD'
           END-EXEC
      *
           IF SQLCODE = +0
               ADD +1 TO WS-REV-COUNT
               IF WS-REV-COUNT <= +8
                   MOVE WS-REV-COUNT
                       TO WS-CO-REV-NUM(WS-REV-COUNT)
                   MOVE 'FLOOR PLAN PAYOFF REVERSED: PD -> AC'
                       TO WS-CO-REV-DESC(WS-REV-COUNT)
               END-IF
           END-IF
           .
       5500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-CANCEL-DEAL - UPDATE SALES_DEAL STATUS               *
      ****************************************************************
       6000-CANCEL-DEAL.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS = :WS-NEW-STATUS
                    , UPDATED_TS  = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '6000-CANCEL-DEAL' TO WS-DBE-PARAGRAPH
               MOVE SQLCODE TO WS-DBE-SQLCODE
               MOVE SQLERRMC TO WS-DBE-SQLERRM
               MOVE 'SALES_DEAL' TO WS-DBE-TABLE-NAME
               MOVE 'UPDATE' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                     WS-DBE-RESULT
               MOVE WS-DBE-RETURN-MSG TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           ADD +1 TO WS-REV-COUNT
           IF WS-REV-COUNT <= +8
               MOVE WS-REV-COUNT
                   TO WS-CO-REV-NUM(WS-REV-COUNT)
               STRING 'DEAL STATUS CHANGED: '
                      WS-OLD-STATUS ' -> ' WS-NEW-STATUS
                      DELIMITED BY SIZE
                      INTO WS-CO-REV-DESC(WS-REV-COUNT)
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-WRITE-AUDIT-TRAIL - COMPREHENSIVE AUDIT LOG          *
      ****************************************************************
       7000-WRITE-AUDIT-TRAIL.
      *
      *    MAIN CANCELLATION LOG ENTRY
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'CANCEL  '         TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID     TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-CI-DEAL-NUMBER  TO WS-LR-ENTITY-KEY
      *
           IF WS-DEAL-DELIVERED
               STRING 'DEAL UNWOUND: ' WS-CI-DEAL-NUMBER
                      ' VIN=' VIN OF DCLSALES-DEAL
                      ' PREV=' WS-OLD-STATUS
                      DELIMITED BY SIZE
                      INTO WS-LR-DESCRIPTION
           ELSE
               STRING 'DEAL CANCELLED: ' WS-CI-DEAL-NUMBER
                      ' VIN=' VIN OF DCLSALES-DEAL
                      ' PREV=' WS-OLD-STATUS
                      DELIMITED BY SIZE
                      INTO WS-LR-DESCRIPTION
           END-IF
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    REASON LOG ENTRY
      *
           MOVE 'REASON  '         TO WS-LR-FUNCTION
           STRING 'REASON: '
                  WS-CI-CANCEL-REASON(1:72)
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    REVERSAL DETAIL LOG
      *
           MOVE 'REVERSAL'         TO WS-LR-FUNCTION
           STRING 'TOTAL REVERSALS PERFORMED: '
                  WS-REV-COUNT
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
      *
      ****************************************************************
      *    8000-FORMAT-OUTPUT                                        *
      ****************************************************************
       8000-FORMAT-OUTPUT.
      *
           IF WS-RETURN-CODE > +0
               MOVE WS-MODULE-ID TO WS-OUT-MSG-ID
               MOVE WS-ERROR-MSG TO WS-OUT-MSG-TEXT
               GO TO 8000-EXIT
           END-IF
      *
           MOVE WS-MODULE-ID TO WS-OUT-MSG-ID
      *
           IF WS-DEAL-DELIVERED
               MOVE 'DEAL UNWOUND SUCCESSFULLY'
                   TO WS-OUT-MSG-TEXT
           ELSE
               MOVE 'DEAL CANCELLED SUCCESSFULLY'
                   TO WS-OUT-MSG-TEXT
           END-IF
      *
           MOVE WS-CI-DEAL-NUMBER TO WS-CO-DEAL-NUM
           MOVE WS-OLD-STATUS TO WS-CO-OLD-STAT
           MOVE WS-NEW-STATUS TO WS-CO-NEW-STAT
           MOVE WS-CI-CANCEL-REASON(1:71) TO WS-CO-REASON
      *
           MOVE WS-CAN-OUTPUT TO WS-OUT-BODY
           .
       8000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               CONTINUE
           END-IF
           .
      ****************************************************************
      * END OF SALCAN00                                              *
      ****************************************************************
