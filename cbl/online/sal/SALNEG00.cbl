       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALNEG00.
      ****************************************************************
      * PROGRAM:    SALNEG00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALN                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLNG00 (NEGOTIATION RESPONSE)                  *
      *                                                              *
      * PURPOSE:    PRICE NEGOTIATION. DISPLAYS MSRP, INVOICE        *
      *             (MANAGER ONLY), HOLDBACK (HIDDEN), AND CURRENT   *
      *             OFFER. ALLOWS COUNTER OFFER, DISCOUNT BY AMOUNT  *
      *             OR PERCENTAGE. RECALCULATES ALL DEAL FINANCIALS   *
      *             ON EACH COUNTER. SHOWS GROSS PROFIT AND MARGIN   *
      *             PERCENTAGE (MANAGER VIEW ONLY - CONTROLLED BY    *
      *             USER TYPE). MANAGER CAN ENTER DESK NOTES VISIBLE *
      *             TO SALESPERSON. UPDATES SALES_DEAL WITH NEW       *
      *             PRICING AND STATUS NE (NEGOTIATING).              *
      *                                                              *
      * CALLS:      COMPRCL0 - VEHICLE PRICING LOOKUP                *
      *             COMTAXL0 - TAX CALCULATION                       *
      *             COMFMTL0 - CURRENCY FORMATTING                   *
      *             COMLGEL0 - AUDIT LOG ENTRY                       *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL       (READ/UPDATE)          *
      *             AUTOSALE.SYSTEM_USER       (READ)                *
      *             AUTOSALE.CUSTOMER          (READ)                *
      *             AUTOSALE.TAX_RATE          (READ VIA COMTAXL0)   *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALNEG00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
           COPY DCLSYUSR.
           COPY DCLCUSTM.
      *
      *    INPUT FIELDS
      *
       01  WS-NEG-INPUT.
           05  WS-NI-DEAL-NUMBER    PIC X(10).
           05  WS-NI-COUNTER-OFFER  PIC X(12).
           05  WS-NI-DISCOUNT-AMT   PIC X(12).
           05  WS-NI-DISCOUNT-PCT   PIC X(06).
           05  WS-NI-DESK-NOTE      PIC X(200).
           05  WS-NI-ACTION         PIC X(02).
               88  WS-NI-ACT-VIEW              VALUE 'VW'.
               88  WS-NI-ACT-COUNTER           VALUE 'CO'.
               88  WS-NI-ACT-DISCOUNT          VALUE 'DS'.
      *
      *    OUTPUT LAYOUT
      *
       01  WS-NEG-OUTPUT.
           05  WS-NO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- PRICE NEGOTIATION --------'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-NO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(10)
                   VALUE '  STATUS: '.
               10  WS-NO-STATUS    PIC X(02).
               10  FILLER           PIC X(17) VALUE SPACES.
           05  WS-NO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-NO-MSRP-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'MSRP:                 '.
               10  WS-NO-MSRP      PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-NO-INV-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'INVOICE:              '.
               10  WS-NO-INVOICE   PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(16)
                   VALUE '  ** MGR ONLY **'.
               10  FILLER           PIC X(27) VALUE SPACES.
           05  WS-NO-CURR-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'CURRENT OFFER:        '.
               10  WS-NO-CURRENT   PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-NO-DISC-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'DISCOUNT APPLIED:     '.
               10  WS-NO-DISCOUNT  PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(42) VALUE SPACES.
           05  WS-NO-REBATE-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'REBATES:              '.
               10  WS-NO-REBATES   PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(42) VALUE SPACES.
           05  WS-NO-TRADE-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'NET TRADE-IN:         '.
               10  WS-NO-NET-TRADE PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(42) VALUE SPACES.
           05  WS-NO-TAX-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'TOTAL TAX:            '.
               10  WS-NO-TOTAL-TAX PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-NO-FEES-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'TOTAL FEES:           '.
               10  WS-NO-TOTAL-FEES PIC $$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-NO-TOTAL-LINE.
               10  FILLER           PIC X(22)
                   VALUE '*** TOTAL PRICE:      '.
               10  WS-NO-TOTAL     PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-NO-BLANK-2       PIC X(79) VALUE SPACES.
           05  WS-NO-GROSS-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'FRONT GROSS:          '.
               10  WS-NO-GROSS     PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(10)
                   VALUE '  MARGIN: '.
               10  WS-NO-MARGIN    PIC Z(3)9.99.
               10  FILLER           PIC X(01) VALUE '%'.
               10  FILLER           PIC X(17)
                   VALUE '  ** MGR ONLY **'.
               10  FILLER           PIC X(04) VALUE SPACES.
           05  WS-NO-NOTE-LINE.
               10  FILLER           PIC X(12)
                   VALUE 'DESK NOTES: '.
               10  WS-NO-DESK-NOTE PIC X(67).
           05  WS-NO-FILLER        PIC X(711) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR              VALUE 'Y'.
               88  WS-NO-ERROR               VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-IS-MANAGER       PIC X(01) VALUE 'N'.
               88  WS-USER-IS-MGR            VALUE 'Y'.
               88  WS-USER-NOT-MGR           VALUE 'N'.
           05  WS-COUNTER-NUM      PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DISCOUNT-NUM     PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DISCOUNT-PCT     PIC S9(03)V99 COMP-3 VALUE +0.
           05  WS-CUST-STATE       PIC X(02) VALUE SPACES.
           05  WS-CUST-COUNTY      PIC X(05) VALUE SPACES.
           05  WS-CUST-CITY        PIC X(05) VALUE SPACES.
      *
      *    RECALCULATION FIELDS
      *
       01  WS-RECALC.
           05  WS-RC-NEW-PRICE     PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-RC-TAXABLE       PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-RC-STATE-TAX     PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-RC-COUNTY-TAX    PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-RC-CITY-TAX      PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-RC-TOTAL-TAX     PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-RC-TOTAL-FEES    PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-RC-TOTAL-PRICE   PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-RC-AMT-FINANCED  PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-RC-FRONT-GROSS   PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-RC-MARGIN-PCT    PIC S9(03)V99 COMP-3 VALUE +0.
      *
      *    TAX CALL FIELDS (COMTAXL0)
      *
       01  WS-TAX-REQUEST.
           05  WS-TAX-FUNCTION     PIC X(04).
           05  WS-TAX-STATE        PIC X(02).
           05  WS-TAX-COUNTY       PIC X(05).
           05  WS-TAX-CITY         PIC X(05).
           05  WS-TAX-TAXABLE-AMT  PIC S9(09)V99 COMP-3.
       01  WS-TAX-RESULT.
           05  WS-TAX-STATE-AMT    PIC S9(07)V99 COMP-3.
           05  WS-TAX-COUNTY-AMT   PIC S9(07)V99 COMP-3.
           05  WS-TAX-CITY-AMT     PIC S9(07)V99 COMP-3.
           05  WS-TAX-TOTAL-AMT    PIC S9(07)V99 COMP-3.
           05  WS-TAX-DOC-FEE      PIC S9(05)V99 COMP-3.
           05  WS-TAX-TITLE-FEE    PIC S9(05)V99 COMP-3.
           05  WS-TAX-REG-FEE      PIC S9(05)V99 COMP-3.
           05  WS-TAX-RETURN-CODE  PIC S9(04) COMP.
           05  WS-TAX-RETURN-MSG   PIC X(50).
      *
      *    PRICING CALL FIELDS (COMPRCL0)
      *
       01  WS-PRC-REQUEST.
           05  WS-PRC-FUNCTION     PIC X(04).
           05  WS-PRC-MODEL-YEAR   PIC S9(04) COMP.
           05  WS-PRC-MAKE-CODE    PIC X(03).
           05  WS-PRC-MODEL-CODE   PIC X(06).
       01  WS-PRC-RESULT.
           05  WS-PRC-MSRP         PIC S9(09)V99 COMP-3.
           05  WS-PRC-INVOICE      PIC S9(09)V99 COMP-3.
           05  WS-PRC-HOLDBACK     PIC S9(07)V99 COMP-3.
           05  WS-PRC-HOLDBACK-PCT PIC S9(02)V999 COMP-3.
           05  WS-PRC-DEST-FEE     PIC S9(05)V99 COMP-3.
           05  WS-PRC-ADV-FEE      PIC S9(05)V99 COMP-3.
           05  WS-PRC-RETURN-CODE  PIC S9(04) COMP.
           05  WS-PRC-RETURN-MSG   PIC X(50).
      *
      *    FORMAT CALL FIELDS (COMFMTL0)
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
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  NI-SALES-MGR        PIC S9(04) COMP VALUE +0.
           05  NI-CUST-COUNTY      PIC S9(04) COMP VALUE +0.
           05  NI-CUST-CITY        PIC S9(04) COMP VALUE +0.
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
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3000-VALIDATE-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3500-CHECK-USER-AUTH
           END-IF
      *
           IF WS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN WS-NI-ACT-VIEW
                       PERFORM 4000-VIEW-DEAL
                   WHEN WS-NI-ACT-COUNTER
                       PERFORM 5000-PROCESS-COUNTER
                   WHEN WS-NI-ACT-DISCOUNT
                       PERFORM 5500-PROCESS-DISCOUNT
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID ACTION - USE VW, CO, OR DS'
                           TO WS-ERROR-MSG
               END-EVALUATE
           END-IF
      *
           PERFORM 8000-FORMAT-OUTPUT
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
           SET WS-NO-ERROR TO TRUE
           INITIALIZE WS-NEG-OUTPUT
           INITIALIZE WS-RECALC
           MOVE SPACES TO WS-ERROR-MSG
           SET WS-USER-NOT-MGR TO TRUE
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
               MOVE 'SALNEG00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-NI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:12) TO WS-NI-COUNTER-OFFER
               MOVE WS-INP-BODY(13:12) TO WS-NI-DISCOUNT-AMT
               MOVE WS-INP-BODY(25:6) TO WS-NI-DISCOUNT-PCT
               MOVE WS-INP-BODY(31:200) TO WS-NI-DESK-NOTE
               MOVE WS-INP-FUNCTION TO WS-NI-ACTION
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-DEAL - RETRIEVE AND VALIDATE DEAL           *
      ****************************************************************
       3000-VALIDATE-DEAL.
      *
           IF WS-NI-DEAL-NUMBER = SPACES
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
                    , SALESPERSON_ID
                    , SALES_MANAGER_ID
                    , DEAL_TYPE
                    , DEAL_STATUS
                    , VEHICLE_PRICE
                    , TOTAL_OPTIONS
                    , DESTINATION_FEE
                    , SUBTOTAL
                    , TRADE_ALLOW
                    , TRADE_PAYOFF
                    , NET_TRADE
                    , REBATES_APPLIED
                    , DISCOUNT_AMT
                    , DOC_FEE
                    , STATE_TAX
                    , COUNTY_TAX
                    , CITY_TAX
                    , TITLE_FEE
                    , REG_FEE
                    , TOTAL_PRICE
                    , DOWN_PAYMENT
                    , AMOUNT_FINANCED
                    , FRONT_GROSS
               INTO   :DEAL-NUMBER
                    , :DEALER-CODE   OF DCLSALES-DEAL
                    , :CUSTOMER-ID   OF DCLSALES-DEAL
                    , :VIN           OF DCLSALES-DEAL
                    , :SALESPERSON-ID
                    , :SALES-MANAGER-ID :NI-SALES-MGR
                    , :DEAL-TYPE
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :TOTAL-OPTIONS
                    , :DESTINATION-FEE
                    , :SUBTOTAL
                    , :TRADE-ALLOW
                    , :TRADE-PAYOFF
                    , :NET-TRADE
                    , :REBATES-APPLIED
                    , :DISCOUNT-AMT
                    , :DOC-FEE
                    , :STATE-TAX
                    , :COUNTY-TAX
                    , :CITY-TAX
                    , :TITLE-FEE
                    , :REG-FEE
                    , :TOTAL-PRICE
                    , :DOWN-PAYMENT
                    , :AMOUNT-FINANCED
                    , :FRONT-GROSS
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-NI-DEAL-NUMBER
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
      *    DEAL MUST BE IN WORKSHEET OR NEGOTIATING STATUS
      *
           IF DEAL-STATUS NOT = 'WS'
           AND DEAL-STATUS NOT = 'NE'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'DEAL STATUS ' DEAL-STATUS
                      ' - NOT OPEN FOR NEGOTIATION'
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-CHECK-USER-AUTH - DETERMINE IF MANAGER                *
      ****************************************************************
       3500-CHECK-USER-AUTH.
      *
           EXEC SQL
               SELECT USER_TYPE
               INTO   :USER-TYPE
               FROM   AUTOSALE.SYSTEM_USER
               WHERE  USER_ID = :IO-PCB-USER-ID
                 AND  ACTIVE_FLAG = 'Y'
           END-EXEC
      *
           IF SQLCODE = +0
               IF USER-TYPE = 'M' OR USER-TYPE = 'G'
               OR USER-TYPE = 'A'
                   SET WS-USER-IS-MGR TO TRUE
               ELSE
                   SET WS-USER-NOT-MGR TO TRUE
               END-IF
           ELSE
               SET WS-USER-NOT-MGR TO TRUE
           END-IF
      *
      *    GET CUSTOMER STATE FOR TAX RECALC
      *
           EXEC SQL
               SELECT STATE_CODE
               INTO   :WS-CUST-STATE
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID
                    = :CUSTOMER-ID OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'TX' TO WS-CUST-STATE
           END-IF
      *
      *    GET TAX JURISDICTION
      *
           EXEC SQL
               SELECT COUNTY_CODE
                    , CITY_CODE
               INTO   :WS-CUST-COUNTY :NI-CUST-COUNTY
                    , :WS-CUST-CITY   :NI-CUST-CITY
               FROM   AUTOSALE.TAX_RATE
               WHERE  STATE_CODE = :WS-CUST-STATE
                 AND  EFFECTIVE_DATE <= CURRENT DATE
                 AND  (EXPIRY_DATE IS NULL
                    OR EXPIRY_DATE >= CURRENT DATE)
               FETCH FIRST 1 ROWS ONLY
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '00000' TO WS-CUST-COUNTY
               MOVE '00000' TO WS-CUST-CITY
           END-IF
           .
      *
      ****************************************************************
      *    4000-VIEW-DEAL - DISPLAY CURRENT DEAL PRICING             *
      ****************************************************************
       4000-VIEW-DEAL.
      *
      *    GET INVOICE PRICE FOR GROSS CALC (MANAGERS ONLY)
      *
           PERFORM 4500-GET-PRICING-DATA
      *
      *    RECALCULATE TOTALS FOR DISPLAY
      *
           COMPUTE WS-RC-TOTAL-TAX =
               STATE-TAX + COUNTY-TAX + CITY-TAX
      *
           COMPUTE WS-RC-TOTAL-FEES =
               DOC-FEE + TITLE-FEE + REG-FEE
      *
           MOVE FRONT-GROSS TO WS-RC-FRONT-GROSS
      *
      *    MARGIN = FRONT GROSS / VEHICLE PRICE * 100
      *
           IF VEHICLE-PRICE > +0
               COMPUTE WS-RC-MARGIN-PCT =
                   (FRONT-GROSS / VEHICLE-PRICE) * 100
           END-IF
           .
      *
      ****************************************************************
      *    4500-GET-PRICING-DATA - CALL COMPRCL0                     *
      ****************************************************************
       4500-GET-PRICING-DATA.
      *
      *    DECODE VIN TO GET MODEL YEAR/MAKE/MODEL
      *
           EXEC SQL
               SELECT MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
               INTO   :WS-PRC-MODEL-YEAR
                    , :WS-PRC-MAKE-CODE
                    , :WS-PRC-MODEL-CODE
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :VIN OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 4500-EXIT
           END-IF
      *
           MOVE 'LKUP' TO WS-PRC-FUNCTION
           CALL 'COMPRCL0' USING WS-PRC-REQUEST
                                 WS-PRC-RESULT
           .
       4500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-COUNTER - APPLY COUNTER OFFER PRICE          *
      ****************************************************************
       5000-PROCESS-COUNTER.
      *
           IF WS-NI-COUNTER-OFFER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'COUNTER OFFER AMOUNT IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
           COMPUTE WS-COUNTER-NUM =
               FUNCTION NUMVAL(WS-NI-COUNTER-OFFER)
      *
           IF WS-COUNTER-NUM <= +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'COUNTER OFFER MUST BE GREATER THAN ZERO'
                   TO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
      *    COMPUTE NEW DISCOUNT = MSRP - COUNTER OFFER
      *
           COMPUTE WS-DISCOUNT-NUM =
               VEHICLE-PRICE - WS-COUNTER-NUM
      *
           IF WS-DISCOUNT-NUM < +0
               MOVE +0 TO WS-DISCOUNT-NUM
           END-IF
      *
      *    RECALCULATE DEAL
      *
           PERFORM 6000-RECALCULATE-DEAL
      *
      *    UPDATE DEAL IN DATABASE
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-UPDATE-DEAL
           END-IF
      *
      *    WRITE DESK NOTE IF MANAGER
      *
           IF WS-USER-IS-MGR AND WS-NI-DESK-NOTE NOT = SPACES
               PERFORM 7500-WRITE-DESK-NOTE
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5500-PROCESS-DISCOUNT - APPLY DISCOUNT AMT OR PCT         *
      ****************************************************************
       5500-PROCESS-DISCOUNT.
      *
      *    DISCOUNT BY AMOUNT
      *
           IF WS-NI-DISCOUNT-AMT NOT = SPACES
               COMPUTE WS-DISCOUNT-NUM =
                   FUNCTION NUMVAL(WS-NI-DISCOUNT-AMT)
               ADD DISCOUNT-AMT TO WS-DISCOUNT-NUM
      *
      *    DISCOUNT BY PERCENTAGE
      *
           ELSE IF WS-NI-DISCOUNT-PCT NOT = SPACES
               COMPUTE WS-DISCOUNT-PCT =
                   FUNCTION NUMVAL(WS-NI-DISCOUNT-PCT)
               COMPUTE WS-DISCOUNT-NUM =
                   DISCOUNT-AMT +
                   (VEHICLE-PRICE * WS-DISCOUNT-PCT / 100)
           ELSE
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DISCOUNT AMOUNT OR PERCENTAGE REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 5500-EXIT
           END-IF
           END-IF
      *
      *    RECALCULATE AND UPDATE
      *
           PERFORM 6000-RECALCULATE-DEAL
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-UPDATE-DEAL
           END-IF
      *
           IF WS-USER-IS-MGR AND WS-NI-DESK-NOTE NOT = SPACES
               PERFORM 7500-WRITE-DESK-NOTE
           END-IF
           .
       5500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-RECALCULATE-DEAL - RECOMPUTE ALL FINANCIALS          *
      ****************************************************************
       6000-RECALCULATE-DEAL.
      *
      *    GET INVOICE FOR GROSS CALCULATION
      *
           PERFORM 4500-GET-PRICING-DATA
      *
      *    TAXABLE = SUBTOTAL - DISCOUNT - TRADE ALLOWANCE
      *
           COMPUTE WS-RC-TAXABLE =
               SUBTOTAL
             - WS-DISCOUNT-NUM
             - TRADE-ALLOW
      *
           IF WS-RC-TAXABLE < +0
               MOVE +0 TO WS-RC-TAXABLE
           END-IF
      *
      *    RECALCULATE TAX
      *
           MOVE 'CALC' TO WS-TAX-FUNCTION
           MOVE WS-CUST-STATE  TO WS-TAX-STATE
           MOVE WS-CUST-COUNTY TO WS-TAX-COUNTY
           MOVE WS-CUST-CITY   TO WS-TAX-CITY
           MOVE WS-RC-TAXABLE  TO WS-TAX-TAXABLE-AMT
      *
           CALL 'COMTAXL0' USING WS-TAX-REQUEST
                                 WS-TAX-RESULT
      *
           IF WS-TAX-RETURN-CODE NOT = +0
               MOVE WS-TAX-STATE-AMT  TO WS-RC-STATE-TAX
               MOVE WS-TAX-COUNTY-AMT TO WS-RC-COUNTY-TAX
               MOVE WS-TAX-CITY-AMT   TO WS-RC-CITY-TAX
           ELSE
               MOVE WS-TAX-STATE-AMT  TO WS-RC-STATE-TAX
               MOVE WS-TAX-COUNTY-AMT TO WS-RC-COUNTY-TAX
               MOVE WS-TAX-CITY-AMT   TO WS-RC-CITY-TAX
           END-IF
      *
           COMPUTE WS-RC-TOTAL-TAX =
               WS-RC-STATE-TAX + WS-RC-COUNTY-TAX
             + WS-RC-CITY-TAX
      *
           COMPUTE WS-RC-TOTAL-FEES =
               DOC-FEE + TITLE-FEE + REG-FEE
      *
      *    NEW TOTAL PRICE
      *
           COMPUTE WS-RC-TOTAL-PRICE =
               SUBTOTAL
             - WS-DISCOUNT-NUM
             - REBATES-APPLIED
             - NET-TRADE
             + WS-RC-TOTAL-TAX
             + WS-RC-TOTAL-FEES
      *
      *    AMOUNT FINANCED
      *
           COMPUTE WS-RC-AMT-FINANCED =
               WS-RC-TOTAL-PRICE - DOWN-PAYMENT
      *
           IF WS-RC-AMT-FINANCED < +0
               MOVE +0 TO WS-RC-AMT-FINANCED
           END-IF
      *
      *    FRONT GROSS = SELLING PRICE - INVOICE - HOLDBACK
      *
           IF WS-PRC-RETURN-CODE = +0
               COMPUTE WS-RC-FRONT-GROSS =
                   VEHICLE-PRICE
                 - WS-DISCOUNT-NUM
                 - WS-PRC-INVOICE
                 - WS-PRC-HOLDBACK
           ELSE
               COMPUTE WS-RC-FRONT-GROSS =
                   VEHICLE-PRICE
                 - WS-DISCOUNT-NUM
                 - FRONT-GROSS
           END-IF
      *
      *    MARGIN PERCENTAGE
      *
           IF VEHICLE-PRICE > +0
               COMPUTE WS-RC-MARGIN-PCT =
                   (WS-RC-FRONT-GROSS / VEHICLE-PRICE) * 100
           ELSE
               MOVE +0 TO WS-RC-MARGIN-PCT
           END-IF
           .
      *
      ****************************************************************
      *    7000-UPDATE-DEAL - WRITE CHANGES TO SALES_DEAL            *
      ****************************************************************
       7000-UPDATE-DEAL.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DISCOUNT_AMT    = :WS-DISCOUNT-NUM
                    , STATE_TAX       = :WS-RC-STATE-TAX
                    , COUNTY_TAX      = :WS-RC-COUNTY-TAX
                    , CITY_TAX        = :WS-RC-CITY-TAX
                    , TOTAL_PRICE     = :WS-RC-TOTAL-PRICE
                    , AMOUNT_FINANCED = :WS-RC-AMT-FINANCED
                    , FRONT_GROSS     = :WS-RC-FRONT-GROSS
                    , TOTAL_GROSS     = :WS-RC-FRONT-GROSS
                                      + BACK_GROSS
                    , DEAL_STATUS     = 'NE'
                    , SALES_MANAGER_ID = :IO-PCB-USER-ID
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-NI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING DEAL' TO WS-ERROR-MSG
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'NEGOT   '         TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID     TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-NI-DEAL-NUMBER  TO WS-LR-ENTITY-KEY
           STRING 'NEGOTIATION UPDATE: DEAL ' WS-NI-DEAL-NUMBER
                  ' DISC=' WS-NI-DISCOUNT-AMT
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
      *
      ****************************************************************
      *    7500-WRITE-DESK-NOTE - INSERT MANAGER DESK NOTE           *
      ****************************************************************
       7500-WRITE-DESK-NOTE.
      *
      *    STORE DESK NOTE IN SALES_APPROVAL TABLE AS A NOTE TYPE
      *
           EXEC SQL
               INSERT INTO AUTOSALE.SALES_APPROVAL
               ( APPROVAL_ID
               , DEAL_NUMBER
               , APPROVAL_TYPE
               , APPROVER_ID
               , APPROVAL_STATUS
               , COMMENTS
               , APPROVAL_TS
               )
               VALUES
               ( DEFAULT
               , :WS-NI-DEAL-NUMBER
               , 'DN'
               , :IO-PCB-USER-ID
               , 'N'
               , :WS-NI-DESK-NOTE
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
           EVALUATE TRUE
               WHEN WS-NI-ACT-VIEW
                   MOVE 'DEAL PRICING DISPLAYED'
                       TO WS-OUT-MSG-TEXT
               WHEN OTHER
                   MOVE 'DEAL PRICING UPDATED - NEGOTIATING'
                       TO WS-OUT-MSG-TEXT
           END-EVALUATE
      *
           MOVE WS-NI-DEAL-NUMBER TO WS-NO-DEAL-NUM
           MOVE DEAL-STATUS TO WS-NO-STATUS
           MOVE VEHICLE-PRICE TO WS-NO-MSRP
           MOVE DISCOUNT-AMT TO WS-NO-DISCOUNT
           MOVE REBATES-APPLIED TO WS-NO-REBATES
           MOVE NET-TRADE TO WS-NO-NET-TRADE
      *
      *    SHOW CURRENT OFFER = MSRP - DISCOUNT
      *
           COMPUTE WS-RC-NEW-PRICE =
               VEHICLE-PRICE - WS-DISCOUNT-NUM
           MOVE WS-RC-NEW-PRICE TO WS-NO-CURRENT
      *
      *    IF COUNTER/DISCOUNT WAS PROCESSED USE RECALC VALUES
      *
           IF WS-NI-ACT-COUNTER OR WS-NI-ACT-DISCOUNT
               MOVE WS-DISCOUNT-NUM TO WS-NO-DISCOUNT
               MOVE WS-RC-TOTAL-TAX TO WS-NO-TOTAL-TAX
               MOVE WS-RC-TOTAL-FEES TO WS-NO-TOTAL-FEES
               MOVE WS-RC-TOTAL-PRICE TO WS-NO-TOTAL
           ELSE
               COMPUTE WS-RC-TOTAL-TAX =
                   STATE-TAX + COUNTY-TAX + CITY-TAX
               COMPUTE WS-RC-TOTAL-FEES =
                   DOC-FEE + TITLE-FEE + REG-FEE
               MOVE WS-RC-TOTAL-TAX TO WS-NO-TOTAL-TAX
               MOVE WS-RC-TOTAL-FEES TO WS-NO-TOTAL-FEES
               MOVE TOTAL-PRICE TO WS-NO-TOTAL
           END-IF
      *
      *    MANAGER-ONLY FIELDS - INVOICE AND GROSS
      *
           IF WS-USER-IS-MGR
               IF WS-PRC-RETURN-CODE = +0
                   MOVE WS-PRC-INVOICE TO WS-NO-INVOICE
               END-IF
               MOVE WS-RC-FRONT-GROSS TO WS-NO-GROSS
               MOVE WS-RC-MARGIN-PCT  TO WS-NO-MARGIN
           ELSE
               MOVE SPACES TO WS-NO-INV-LINE
               MOVE 'INVOICE:               *** RESTRICTED ***'
                   TO WS-NO-INV-LINE
               MOVE SPACES TO WS-NO-GROSS-LINE
               MOVE 'GROSS/MARGIN:          *** RESTRICTED ***'
                   TO WS-NO-GROSS-LINE
           END-IF
      *
      *    SHOW LATEST DESK NOTE
      *
           EXEC SQL
               SELECT COMMENTS
               INTO   :WS-NO-DESK-NOTE
               FROM   AUTOSALE.SALES_APPROVAL
               WHERE  DEAL_NUMBER = :WS-NI-DEAL-NUMBER
                 AND  APPROVAL_TYPE = 'DN'
               ORDER BY APPROVAL_TS DESC
               FETCH FIRST 1 ROWS ONLY
           END-EXEC
      *
           MOVE WS-NEG-OUTPUT TO WS-OUT-BODY
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
      * END OF SALNEG00                                              *
      ****************************************************************
