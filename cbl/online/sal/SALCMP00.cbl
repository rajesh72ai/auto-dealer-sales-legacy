       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALCMP00.
      ****************************************************************
      * PROGRAM:    SALCMP00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALC                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLCP00 (COMPLETION RESPONSE)                   *
      *                                                              *
      * PURPOSE:    SALE COMPLETION / CLOSING. VALIDATES DEAL IS     *
      *             APPROVED (STATUS AP OR FI), ALL CHECKLIST ITEMS   *
      *             COMPLETE. CHECKLIST: TRADE TITLE RECEIVED (IF    *
      *             TRADE), INSURANCE VERIFIED, CREDIT/FINANCE       *
      *             APPROVED (IF NOT CASH), DOWN PAYMENT RECEIVED.   *
      *             UPDATES SALES_DEAL STATUS TO DL (DELIVERED),     *
      *             SETS DELIVERY_DATE AND FINAL AMOUNTS. UPDATES    *
      *             VEHICLE STATUS TO SD (SOLD). UPDATES             *
      *             STOCK_POSITION: DECREMENTS ON_HAND, INCREMENTS   *
      *             SOLD_MTD/SOLD_YTD. TRIGGERS WARRANTY REG AND     *
      *             REGISTRATION DATA ASSEMBLY.                       *
      *                                                              *
      * CALLS:      COMSTCK0 - STOCK UPDATE (SOLD FUNCTION)          *
      *             COMSEQL0 - SEQUENCE NUMBER GENERATOR              *
      *             COMLGEL0 - AUDIT LOG ENTRY                       *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *             COMFMTL0 - CURRENCY FORMATTING                   *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ/UPDATE)            *
      *             AUTOSALE.VEHICLE        (UPDATE)                  *
      *             AUTOSALE.STOCK_POSITION (UPDATE VIA COMSTCK0)    *
      *             AUTOSALE.TRADE_IN       (READ)                   *
      *             AUTOSALE.FINANCE_APP    (READ)                   *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALCMP00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
      *
      *    INPUT FIELDS
      *
       01  WS-CMP-INPUT.
           05  WS-CI-DEAL-NUMBER    PIC X(10).
           05  WS-CI-DELIVERY-DATE PIC X(10).
           05  WS-CI-DOWN-METHOD   PIC X(02).
               88  WS-CI-DOWN-CASH           VALUE 'CA'.
               88  WS-CI-DOWN-CHECK          VALUE 'CK'.
               88  WS-CI-DOWN-CARD           VALUE 'CC'.
               88  WS-CI-DOWN-WIRE           VALUE 'WR'.
           05  WS-CI-DOWN-AMOUNT   PIC X(12).
           05  WS-CI-INSURANCE-OK  PIC X(01).
           05  WS-CI-TRADE-TITLE   PIC X(01).
      *
      *    OUTPUT LAYOUT
      *
       01  WS-CMP-OUTPUT.
           05  WS-CO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- SALE COMPLETION ----------'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-CO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(29) VALUE SPACES.
           05  WS-CO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-CO-CHECKLIST-HDR.
               10  FILLER           PIC X(30)
                   VALUE 'DELIVERY CHECKLIST:           '.
               10  FILLER           PIC X(49) VALUE SPACES.
           05  WS-CO-CHK-1.
               10  WS-CO-CHK1-IND  PIC X(03).
               10  FILLER           PIC X(30)
                   VALUE ' DEAL APPROVED (AP/FI STATUS) '.
               10  FILLER           PIC X(46) VALUE SPACES.
           05  WS-CO-CHK-2.
               10  WS-CO-CHK2-IND  PIC X(03).
               10  FILLER           PIC X(30)
                   VALUE ' INSURANCE VERIFIED           '.
               10  FILLER           PIC X(46) VALUE SPACES.
           05  WS-CO-CHK-3.
               10  WS-CO-CHK3-IND  PIC X(03).
               10  FILLER           PIC X(30)
                   VALUE ' DOWN PAYMENT RECEIVED        '.
               10  FILLER           PIC X(46) VALUE SPACES.
           05  WS-CO-CHK-4.
               10  WS-CO-CHK4-IND  PIC X(03).
               10  FILLER           PIC X(30)
                   VALUE ' CREDIT/FINANCE APPROVED      '.
               10  FILLER           PIC X(46) VALUE SPACES.
           05  WS-CO-CHK-5.
               10  WS-CO-CHK5-IND  PIC X(03).
               10  FILLER           PIC X(30)
                   VALUE ' TRADE TITLE RECEIVED         '.
               10  FILLER           PIC X(46) VALUE SPACES.
           05  WS-CO-BLANK-2       PIC X(79) VALUE SPACES.
           05  WS-CO-DELIVERY-LINE.
               10  FILLER           PIC X(16)
                   VALUE 'DELIVERY DATE:  '.
               10  WS-CO-DEL-DATE  PIC X(10).
               10  FILLER           PIC X(14)
                   VALUE '  DOWN PAID: '.
               10  WS-CO-DOWN-AMT  PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(25) VALUE SPACES.
           05  WS-CO-FINAL-LINE.
               10  FILLER           PIC X(16)
                   VALUE 'FINAL TOTAL:    '.
               10  WS-CO-FINAL-TOT PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(14)
                   VALUE '  FINANCED:  '.
               10  WS-CO-FINANCED  PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(20) VALUE SPACES.
           05  WS-CO-STATUS-LINE.
               10  FILLER           PIC X(16)
                   VALUE 'VEHICLE STATUS: '.
               10  WS-CO-VEH-STAT  PIC X(02).
               10  FILLER           PIC X(06) VALUE ' (SD) '.
               10  FILLER           PIC X(55) VALUE SPACES.
           05  WS-CO-FILLER        PIC X(693) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-DOWN-AMT-NUM     PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-TRADE-EXISTS     PIC X(01) VALUE 'N'.
               88  WS-HAS-TRADE              VALUE 'Y'.
               88  WS-NO-TRADE               VALUE 'N'.
           05  WS-FINANCE-OK       PIC X(01) VALUE 'N'.
           05  WS-CHECKLIST-OK     PIC X(01) VALUE 'Y'.
               88  WS-ALL-CHECKS-PASS         VALUE 'Y'.
               88  WS-CHECKS-FAIL             VALUE 'N'.
      *
      *    STOCK UPDATE CALL FIELDS (COMSTCK0)
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
      *    SEQUENCE GENERATOR
      *
       01  WS-SEQ-REQUEST.
           05  WS-SEQ-FUNCTION     PIC X(04).
           05  WS-SEQ-NAME         PIC X(20).
       01  WS-SEQ-RESULT.
           05  WS-SEQ-NUMBER       PIC S9(09) COMP.
           05  WS-SEQ-FORMATTED    PIC X(10).
           05  WS-SEQ-RETURN-CODE  PIC S9(04) COMP.
           05  WS-SEQ-RETURN-MSG   PIC X(50).
      *
      *    FORMAT CALL
      *
       01  WS-FMT-FUNCTION         PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA  PIC X(40).
           05  WS-FMT-INPUT-NUM    PIC S9(09)V99 COMP-3.
           05  WS-FMT-INPUT-RATE   PIC S9(02)V9(04) COMP-3.
           05  WS-FMT-INPUT-PCT    PIC S9(03)V99 COMP-3.
       01  WS-FMT-OUTPUT           PIC X(40).
       01  WS-FMT-RETURN-CODE      PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG        PIC X(50).
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
               PERFORM 3000-LOAD-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4000-VERIFY-CHECKLIST
           END-IF
      *
           IF WS-RETURN-CODE = +0 AND WS-ALL-CHECKS-PASS
               PERFORM 5000-COMPLETE-SALE
           END-IF
      *
           IF WS-RETURN-CODE = +0 AND WS-ALL-CHECKS-PASS
               PERFORM 6000-UPDATE-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0 AND WS-ALL-CHECKS-PASS
               PERFORM 6500-UPDATE-STOCK
           END-IF
      *
           IF WS-RETURN-CODE = +0 AND WS-ALL-CHECKS-PASS
               PERFORM 7000-TRIGGER-POST-SALE
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
           INITIALIZE WS-CMP-OUTPUT
           MOVE SPACES TO WS-ERROR-MSG
           SET WS-ALL-CHECKS-PASS TO TRUE
           SET WS-NO-TRADE TO TRUE
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
               MOVE 'SALCMP00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-CI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:10)  TO WS-CI-DELIVERY-DATE
               MOVE WS-INP-BODY(11:2)  TO WS-CI-DOWN-METHOD
               MOVE WS-INP-BODY(13:12) TO WS-CI-DOWN-AMOUNT
               MOVE WS-INP-BODY(25:1)  TO WS-CI-INSURANCE-OK
               MOVE WS-INP-BODY(26:1)  TO WS-CI-TRADE-TITLE
           END-IF
           .
      *
      ****************************************************************
      *    3000-LOAD-DEAL                                            *
      ****************************************************************
       3000-LOAD-DEAL.
      *
           IF WS-CI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEALER_CODE
                    , CUSTOMER_ID
                    , VIN
                    , DEAL_TYPE
                    , DEAL_STATUS
                    , VEHICLE_PRICE
                    , TOTAL_PRICE
                    , DOWN_PAYMENT
                    , AMOUNT_FINANCED
                    , TRADE_ALLOW
                    , TRADE_PAYOFF
               INTO   :DEAL-NUMBER
                    , :DEALER-CODE    OF DCLSALES-DEAL
                    , :CUSTOMER-ID    OF DCLSALES-DEAL
                    , :VIN            OF DCLSALES-DEAL
                    , :DEAL-TYPE
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :TOTAL-PRICE
                    , :DOWN-PAYMENT
                    , :AMOUNT-FINANCED
                    , :TRADE-ALLOW
                    , :TRADE-PAYOFF
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
      *    DEAL MUST BE APPROVED OR IN F&I
      *
           IF DEAL-STATUS NOT = 'AP'
           AND DEAL-STATUS NOT = 'FI'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'DEAL STATUS ' DEAL-STATUS
                      ' - MUST BE AP OR FI TO COMPLETE'
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
           END-IF
      *
      *    PARSE DOWN PAYMENT AMOUNT
      *
           IF WS-CI-DOWN-AMOUNT NOT = SPACES
               COMPUTE WS-DOWN-AMT-NUM =
                   FUNCTION NUMVAL(WS-CI-DOWN-AMOUNT)
           ELSE
               MOVE DOWN-PAYMENT TO WS-DOWN-AMT-NUM
           END-IF
      *
      *    CHECK IF TRADE EXISTS
      *
           IF TRADE-ALLOW > +0
               SET WS-HAS-TRADE TO TRUE
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-VERIFY-CHECKLIST                                     *
      ****************************************************************
       4000-VERIFY-CHECKLIST.
      *
      *    CHECK 1: DEAL APPROVED
      *
           IF DEAL-STATUS = 'AP' OR DEAL-STATUS = 'FI'
               MOVE '[X]' TO WS-CO-CHK1-IND
           ELSE
               MOVE '[ ]' TO WS-CO-CHK1-IND
               SET WS-CHECKS-FAIL TO TRUE
           END-IF
      *
      *    CHECK 2: INSURANCE VERIFIED
      *
           IF WS-CI-INSURANCE-OK = 'Y'
               MOVE '[X]' TO WS-CO-CHK2-IND
           ELSE
               MOVE '[ ]' TO WS-CO-CHK2-IND
               SET WS-CHECKS-FAIL TO TRUE
           END-IF
      *
      *    CHECK 3: DOWN PAYMENT RECEIVED
      *
           IF WS-DOWN-AMT-NUM > +0
           OR DEAL-TYPE = 'W'
               MOVE '[X]' TO WS-CO-CHK3-IND
           ELSE
               IF DOWN-PAYMENT = +0
      *            CASH DEAL WITH NO DOWN PAYMENT IS OK
                   MOVE '[X]' TO WS-CO-CHK3-IND
               ELSE
                   MOVE '[ ]' TO WS-CO-CHK3-IND
                   SET WS-CHECKS-FAIL TO TRUE
               END-IF
           END-IF
      *
      *    CHECK 4: CREDIT/FINANCE APPROVED (IF NOT CASH)
      *
           IF AMOUNT-FINANCED > +0
      *        CHECK FOR APPROVED FINANCE APPLICATION
               EXEC SQL
                   SELECT 'Y'
                   INTO   :WS-FINANCE-OK
                   FROM   AUTOSALE.FINANCE_APP
                   WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
                     AND  APP_STATUS = 'AP'
                   FETCH FIRST 1 ROWS ONLY
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE '[X]' TO WS-CO-CHK4-IND
               ELSE
                   MOVE '[ ]' TO WS-CO-CHK4-IND
                   SET WS-CHECKS-FAIL TO TRUE
               END-IF
           ELSE
      *        CASH DEAL - NO FINANCING NEEDED
               MOVE '[X]' TO WS-CO-CHK4-IND
           END-IF
      *
      *    CHECK 5: TRADE TITLE (ONLY IF TRADE EXISTS)
      *
           IF WS-HAS-TRADE
               IF WS-CI-TRADE-TITLE = 'Y'
                   MOVE '[X]' TO WS-CO-CHK5-IND
               ELSE
                   MOVE '[ ]' TO WS-CO-CHK5-IND
                   SET WS-CHECKS-FAIL TO TRUE
               END-IF
           ELSE
               MOVE '[X]' TO WS-CO-CHK5-IND
           END-IF
      *
           IF WS-CHECKS-FAIL
               MOVE 'CHECKLIST INCOMPLETE - CANNOT COMPLETE SALE'
                   TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    5000-COMPLETE-SALE - UPDATE DEAL TO DELIVERED             *
      ****************************************************************
       5000-COMPLETE-SALE.
      *
      *    SET DELIVERY DATE
      *
           IF WS-CI-DELIVERY-DATE = SPACES
               MOVE FUNCTION CURRENT-DATE(1:4) TO
                   WS-CI-DELIVERY-DATE(1:4)
               MOVE '-' TO WS-CI-DELIVERY-DATE(5:1)
               MOVE FUNCTION CURRENT-DATE(5:2) TO
                   WS-CI-DELIVERY-DATE(6:2)
               MOVE '-' TO WS-CI-DELIVERY-DATE(8:1)
               MOVE FUNCTION CURRENT-DATE(7:2) TO
                   WS-CI-DELIVERY-DATE(9:2)
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS    = 'DL'
                    , DELIVERY_DATE  = :WS-CI-DELIVERY-DATE
                    , DOWN_PAYMENT   = :WS-DOWN-AMT-NUM
                    , AMOUNT_FINANCED = TOTAL_PRICE
                                       - :WS-DOWN-AMT-NUM
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-CI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '5000-COMPLETE-SALE' TO WS-DBE-PARAGRAPH
               MOVE SQLCODE TO WS-DBE-SQLCODE
               MOVE SQLERRMC TO WS-DBE-SQLERRM
               MOVE 'SALES_DEAL' TO WS-DBE-TABLE-NAME
               MOVE 'UPDATE' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                     WS-DBE-RESULT
               MOVE WS-DBE-RETURN-MSG TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    6000-UPDATE-VEHICLE - SET STATUS TO SOLD                  *
      ****************************************************************
       6000-UPDATE-VEHICLE.
      *
           EXEC SQL
               UPDATE AUTOSALE.VEHICLE
                  SET VEHICLE_STATUS = 'SD'
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  VIN = :VIN OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING VEHICLE STATUS TO SOLD'
                   TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    6500-UPDATE-STOCK - CALL COMSTCK0 WITH SOLD FUNCTION      *
      ****************************************************************
       6500-UPDATE-STOCK.
      *
           MOVE 'SOLD' TO WS-SR-FUNCTION
           MOVE DEALER-CODE OF DCLSALES-DEAL TO WS-SR-DEALER-CODE
           MOVE VIN OF DCLSALES-DEAL TO WS-SR-VIN
           MOVE IO-PCB-USER-ID TO WS-SR-USER-ID
           STRING 'SALE COMPLETED: DEAL ' WS-CI-DEAL-NUMBER
                  DELIMITED BY SIZE
                  INTO WS-SR-REASON
      *
           CALL 'COMSTCK0' USING WS-STK-REQUEST
                                 WS-STK-RESULT
      *
           IF WS-RS-RETURN-CODE > +4
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-RS-RETURN-MSG TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    7000-TRIGGER-POST-SALE - WARRANTY REG, REG DATA           *
      ****************************************************************
       7000-TRIGGER-POST-SALE.
      *
      *    AUDIT LOG FOR SALE COMPLETION
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'DELIVER '         TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID     TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-CI-DEAL-NUMBER  TO WS-LR-ENTITY-KEY
           STRING 'SALE COMPLETED: DEAL ' WS-CI-DEAL-NUMBER
                  ' VIN=' VIN OF DCLSALES-DEAL
                  ' DEL=' WS-CI-DELIVERY-DATE
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    INSERT WARRANTY REGISTRATION TRIGGER
      *    (PICKED UP BY BATCH WARRANTY REGISTRATION PROCESS)
      *
           EXEC SQL
               INSERT INTO AUTOSALE.COMMISSION_AUDIT
               ( DEAL_NUMBER
               , ENTITY_TYPE
               , DESCRIPTION
               , AUDIT_TS
               )
               VALUES
               ( :WS-CI-DEAL-NUMBER
               , 'WARR_REG'
               , 'WARRANTY REGISTRATION PENDING'
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
      *    INSERT REGISTRATION DATA TRIGGER
      *
           EXEC SQL
               INSERT INTO AUTOSALE.COMMISSION_AUDIT
               ( DEAL_NUMBER
               , ENTITY_TYPE
               , DESCRIPTION
               , AUDIT_TS
               )
               VALUES
               ( :WS-CI-DEAL-NUMBER
               , 'VEH_REG'
               , 'VEHICLE REGISTRATION DATA PENDING'
               , CURRENT TIMESTAMP
               )
           END-EXEC
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
           IF WS-ALL-CHECKS-PASS
               MOVE 'SALE COMPLETED - VEHICLE DELIVERED'
                   TO WS-OUT-MSG-TEXT
           ELSE
               MOVE WS-ERROR-MSG TO WS-OUT-MSG-TEXT
           END-IF
      *
           MOVE WS-CI-DEAL-NUMBER TO WS-CO-DEAL-NUM
           MOVE WS-CI-DELIVERY-DATE TO WS-CO-DEL-DATE
           MOVE WS-DOWN-AMT-NUM TO WS-CO-DOWN-AMT
           MOVE TOTAL-PRICE TO WS-CO-FINAL-TOT
      *
      *    COMPUTE FINANCED AMOUNT
      *
           COMPUTE WS-FMT-INPUT-NUM =
               TOTAL-PRICE - WS-DOWN-AMT-NUM
           MOVE WS-FMT-INPUT-NUM TO WS-CO-FINANCED
      *
           IF WS-ALL-CHECKS-PASS
               MOVE 'SD' TO WS-CO-VEH-STAT
           ELSE
               MOVE DEAL-STATUS TO WS-CO-VEH-STAT
           END-IF
      *
           MOVE WS-CMP-OUTPUT TO WS-OUT-BODY
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
      * END OF SALCMP00                                              *
      ****************************************************************
