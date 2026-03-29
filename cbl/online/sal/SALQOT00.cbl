       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALQOT00.
      ****************************************************************
      * PROGRAM:    SALQOT00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALQ                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLDL00 (DEAL WORKSHEET RESPONSE)               *
      *                                                              *
      * PURPOSE:    DEAL WORKSHEET / QUOTE GENERATION. RECEIVES      *
      *             CUSTOMER ID, VIN, SALESPERSON ID, AND DEAL TYPE  *
      *             (R=RETAIL, L=LEASE, F=FLEET, W=WHOLESALE).       *
      *             VALIDATES ALL ENTITIES, BUILDS COMPLETE DEAL     *
      *             WORKSHEET WITH VEHICLE PRICE, OPTIONS, DEST FEE, *
      *             TRADE-IN, INCENTIVES, TAX (STATE/COUNTY/CITY),   *
      *             DOC FEE, TITLE FEE, REG FEE. CALCULATES TOTAL   *
      *             PRICE, DOWN PAYMENT, AMOUNT FINANCED, AND FRONT  *
      *             GROSS. GENERATES DEAL NUMBER VIA COMSEQL0 AND    *
      *             INSERTS SALES_DEAL (STATUS WS) AND LINE ITEMS.   *
      *                                                              *
      * CALLS:      COMPRCL0 - VEHICLE PRICING LOOKUP                *
      *             COMTAXL0 - TAX CALCULATION                       *
      *             COMSEQL0 - SEQUENCE NUMBER GENERATOR              *
      *             COMFMTL0 - CURRENCY FORMATTING                   *
      *             COMLGEL0 - AUDIT LOG ENTRY                       *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL       (INSERT)               *
      *             AUTOSALE.DEAL_LINE_ITEM   (INSERT)               *
      *             AUTOSALE.CUSTOMER          (READ)                *
      *             AUTOSALE.VEHICLE           (READ)                *
      *             AUTOSALE.SYSTEM_USER       (READ)                *
      *             AUTOSALE.PRICE_MASTER      (READ VIA COMPRCL0)   *
      *             AUTOSALE.VEHICLE_OPTION    (READ)                *
      *             AUTOSALE.TAX_RATE          (READ VIA COMTAXL0)   *
      *             AUTOSALE.TRADE_IN          (READ)                *
      *             AUTOSALE.INCENTIVE_APPLIED (READ)                *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALQOT00'.
      *
      *    IMS FUNCTION CODES AND I/O PCB MASK
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    MFS MESSAGE FORMAT AREAS
      *
           COPY WSMSGFMT.
      *
      *    DCLGEN COPYBOOKS
      *
           COPY DCLSLDEL.
           COPY DCLDLITM.
           COPY DCLCUSTM.
           COPY DCLVEHCL.
           COPY DCLPRICE.
           COPY DCLVHOPT.
           COPY DCLTRDEIN.
           COPY DCLSYUSR.
      *
      *    INPUT FIELDS (PARSED FROM MFS MESSAGE)
      *
       01  WS-QUOTE-INPUT.
           05  WS-QI-CUSTOMER-ID     PIC X(09).
           05  WS-QI-VIN             PIC X(17).
           05  WS-QI-SALESPERSON-ID  PIC X(08).
           05  WS-QI-DEAL-TYPE       PIC X(01).
               88  WS-QI-RETAIL                 VALUE 'R'.
               88  WS-QI-LEASE                  VALUE 'L'.
               88  WS-QI-FLEET                  VALUE 'F'.
               88  WS-QI-WHOLESALE              VALUE 'W'.
           05  WS-QI-DEALER-CODE     PIC X(05).
           05  WS-QI-DOWN-PMT        PIC X(12).
      *
      *    OUTPUT LAYOUT - DEAL WORKSHEET
      *
       01  WS-QUOTE-OUTPUT.
           05  WS-QO-HEADER-LINE.
               10  FILLER            PIC X(30)
                   VALUE '--- DEAL WORKSHEET ----------'.
               10  FILLER            PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-QO-DEAL-NUM   PIC X(10).
               10  FILLER            PIC X(29) VALUE SPACES.
           05  WS-QO-CUST-LINE.
               10  FILLER            PIC X(10)
                   VALUE 'CUSTOMER: '.
               10  WS-QO-CUST-NAME  PIC X(40).
               10  FILLER            PIC X(06) VALUE '  ID: '.
               10  WS-QO-CUST-ID    PIC Z(8)9.
               10  FILLER            PIC X(14) VALUE SPACES.
           05  WS-QO-VEH-LINE.
               10  FILLER            PIC X(09)
                   VALUE 'VEHICLE: '.
               10  WS-QO-VEH-YEAR   PIC 9(04).
               10  FILLER            PIC X(01) VALUE SPACE.
               10  WS-QO-VEH-MAKE   PIC X(03).
               10  FILLER            PIC X(01) VALUE SPACE.
               10  WS-QO-VEH-MODEL  PIC X(06).
               10  FILLER            PIC X(06) VALUE ' VIN: '.
               10  WS-QO-VEH-VIN    PIC X(17).
               10  FILLER            PIC X(32) VALUE SPACES.
           05  WS-QO-PRICE-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'VEHICLE PRICE (MSRP): '.
               10  WS-QO-VEH-PRICE  PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-OPTS-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'OPTIONS TOTAL:        '.
               10  WS-QO-OPTIONS    PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-DEST-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'DESTINATION FEE:      '.
               10  WS-QO-DEST-FEE   PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-SUB-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'SUBTOTAL:             '.
               10  WS-QO-SUBTOTAL   PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-DISC-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'DISCOUNT:             '.
               10  WS-QO-DISCOUNT   PIC $$$,$$$,$$9.99-.
               10  FILLER            PIC X(42) VALUE SPACES.
           05  WS-QO-REBATE-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'REBATES/INCENTIVES:   '.
               10  WS-QO-REBATES    PIC $$$,$$$,$$9.99-.
               10  FILLER            PIC X(42) VALUE SPACES.
           05  WS-QO-TRADE-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'NET TRADE-IN:         '.
               10  WS-QO-NET-TRADE  PIC $$$,$$$,$$9.99-.
               10  FILLER            PIC X(42) VALUE SPACES.
           05  WS-QO-TAX-LINE.
               10  FILLER            PIC X(08)
                   VALUE 'TAX: ST='.
               10  WS-QO-STATE-TAX  PIC $$,$$9.99.
               10  FILLER            PIC X(05) VALUE ' CTY='.
               10  WS-QO-COUNTY-TAX PIC $$,$$9.99.
               10  FILLER            PIC X(06) VALUE ' CITY='.
               10  WS-QO-CITY-TAX   PIC $$,$$9.99.
               10  FILLER            PIC X(31) VALUE SPACES.
           05  WS-QO-FEES-LINE.
               10  FILLER            PIC X(05)
                   VALUE 'DOC: '.
               10  WS-QO-DOC-FEE    PIC $$$9.99.
               10  FILLER            PIC X(07) VALUE ' TITLE:'.
               10  WS-QO-TITLE-FEE  PIC $$$9.99.
               10  FILLER            PIC X(05) VALUE ' REG:'.
               10  WS-QO-REG-FEE    PIC $$$9.99.
               10  FILLER            PIC X(41) VALUE SPACES.
           05  WS-QO-TOTAL-LINE.
               10  FILLER            PIC X(22)
                   VALUE '*** TOTAL PRICE:      '.
               10  WS-QO-TOTAL      PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-DOWN-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'DOWN PAYMENT:         '.
               10  WS-QO-DOWN-PMT   PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-FIN-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'AMOUNT FINANCED:      '.
               10  WS-QO-AMT-FIN    PIC $$$,$$$,$$9.99.
               10  FILLER            PIC X(43) VALUE SPACES.
           05  WS-QO-GROSS-LINE.
               10  FILLER            PIC X(22)
                   VALUE 'FRONT GROSS:          '.
               10  WS-QO-FRONT-GRSS PIC $$$,$$$,$$9.99-.
               10  FILLER            PIC X(42) VALUE SPACES.
           05  WS-QO-FILLER         PIC X(633) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG        PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG         PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE       PIC S9(04) COMP VALUE +0.
           05  WS-CUST-ID-NUM       PIC S9(09) COMP VALUE +0.
           05  WS-DOWN-PMT-NUM      PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-CUST-STATE        PIC X(02) VALUE SPACES.
           05  WS-CUST-COUNTY       PIC X(05) VALUE SPACES.
           05  WS-CUST-CITY         PIC X(05) VALUE SPACES.
           05  WS-DEALER-CODE       PIC X(05) VALUE SPACES.
      *
      *    DEAL CALCULATION FIELDS
      *
       01  WS-DEAL-CALC.
           05  WS-DC-VEHICLE-PRICE  PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-INVOICE-PRICE  PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-HOLDBACK-AMT   PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-OPTIONS-TOTAL  PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-DEST-FEE       PIC S9(05)V99 COMP-3 VALUE +0.
           05  WS-DC-SUBTOTAL       PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-TRADE-ALLOW    PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-TRADE-PAYOFF   PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-NET-TRADE      PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-REBATES        PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-DISCOUNT       PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-STATE-TAX      PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-COUNTY-TAX     PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-CITY-TAX       PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-DC-DOC-FEE        PIC S9(05)V99 COMP-3 VALUE +0.
           05  WS-DC-TITLE-FEE      PIC S9(05)V99 COMP-3 VALUE +0.
           05  WS-DC-REG-FEE        PIC S9(05)V99 COMP-3 VALUE +0.
           05  WS-DC-TOTAL-PRICE    PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-DOWN-PAYMENT   PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-AMT-FINANCED   PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-FRONT-GROSS    PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-DC-TAXABLE-AMT    PIC S9(09)V99 COMP-3 VALUE +0.
      *
      *    DEAL LINE ITEM COUNTER
      *
       01  WS-LINE-SEQ              PIC S9(04) COMP VALUE +0.
      *
      *    GENERATED DEAL NUMBER
      *
       01  WS-DEAL-NUMBER           PIC X(10) VALUE SPACES.
      *
      *    PRICING CALL FIELDS (COMPRCL0)
      *
       01  WS-PRC-REQUEST.
           05  WS-PRC-FUNCTION      PIC X(04).
           05  WS-PRC-MODEL-YEAR    PIC S9(04) COMP.
           05  WS-PRC-MAKE-CODE     PIC X(03).
           05  WS-PRC-MODEL-CODE    PIC X(06).
       01  WS-PRC-RESULT.
           05  WS-PRC-MSRP          PIC S9(09)V99 COMP-3.
           05  WS-PRC-INVOICE       PIC S9(09)V99 COMP-3.
           05  WS-PRC-HOLDBACK      PIC S9(07)V99 COMP-3.
           05  WS-PRC-HOLDBACK-PCT  PIC S9(02)V999 COMP-3.
           05  WS-PRC-DEST-FEE      PIC S9(05)V99 COMP-3.
           05  WS-PRC-ADV-FEE       PIC S9(05)V99 COMP-3.
           05  WS-PRC-RETURN-CODE   PIC S9(04) COMP.
           05  WS-PRC-RETURN-MSG    PIC X(50).
      *
      *    TAX CALL FIELDS (COMTAXL0)
      *
       01  WS-TAX-REQUEST.
           05  WS-TAX-FUNCTION      PIC X(04).
           05  WS-TAX-STATE         PIC X(02).
           05  WS-TAX-COUNTY        PIC X(05).
           05  WS-TAX-CITY          PIC X(05).
           05  WS-TAX-TAXABLE-AMT   PIC S9(09)V99 COMP-3.
       01  WS-TAX-RESULT.
           05  WS-TAX-STATE-AMT     PIC S9(07)V99 COMP-3.
           05  WS-TAX-COUNTY-AMT    PIC S9(07)V99 COMP-3.
           05  WS-TAX-CITY-AMT      PIC S9(07)V99 COMP-3.
           05  WS-TAX-TOTAL-AMT     PIC S9(07)V99 COMP-3.
           05  WS-TAX-DOC-FEE       PIC S9(05)V99 COMP-3.
           05  WS-TAX-TITLE-FEE     PIC S9(05)V99 COMP-3.
           05  WS-TAX-REG-FEE       PIC S9(05)V99 COMP-3.
           05  WS-TAX-RETURN-CODE   PIC S9(04) COMP.
           05  WS-TAX-RETURN-MSG    PIC X(50).
      *
      *    SEQUENCE GENERATOR CALL FIELDS (COMSEQL0)
      *
       01  WS-SEQ-REQUEST.
           05  WS-SEQ-FUNCTION      PIC X(04).
           05  WS-SEQ-NAME          PIC X(20).
       01  WS-SEQ-RESULT.
           05  WS-SEQ-NUMBER        PIC S9(09) COMP.
           05  WS-SEQ-FORMATTED     PIC X(10).
           05  WS-SEQ-RETURN-CODE   PIC S9(04) COMP.
           05  WS-SEQ-RETURN-MSG    PIC X(50).
      *
      *    FORMAT CALL FIELDS (COMFMTL0)
      *
       01  WS-FMT-FUNCTION          PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA   PIC X(40).
           05  WS-FMT-INPUT-NUM     PIC S9(09)V99 COMP-3.
           05  WS-FMT-INPUT-RATE    PIC S9(02)V9(04) COMP-3.
           05  WS-FMT-INPUT-PCT     PIC S9(03)V99 COMP-3.
       01  WS-FMT-OUTPUT            PIC X(40).
       01  WS-FMT-RETURN-CODE       PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG         PIC X(50).
      *
      *    AUDIT LOG CALL FIELDS (COMLGEL0)
      *
       01  WS-LOG-REQUEST.
           05  WS-LR-PROGRAM        PIC X(08).
           05  WS-LR-FUNCTION       PIC X(08).
           05  WS-LR-USER-ID        PIC X(08).
           05  WS-LR-ENTITY-TYPE    PIC X(08).
           05  WS-LR-ENTITY-KEY     PIC X(30).
           05  WS-LR-DESCRIPTION    PIC X(80).
           05  WS-LR-RETURN-CODE    PIC S9(04) COMP.
      *
      *    DB2 ERROR HANDLER FIELDS (COMDBEL0)
      *
       01  WS-DBE-REQUEST.
           05  WS-DBE-PROGRAM       PIC X(08).
           05  WS-DBE-PARAGRAPH     PIC X(30).
           05  WS-DBE-SQLCODE       PIC S9(09) COMP.
           05  WS-DBE-SQLERRM       PIC X(70).
           05  WS-DBE-TABLE-NAME    PIC X(30).
           05  WS-DBE-OPERATION     PIC X(10).
       01  WS-DBE-RESULT.
           05  WS-DBE-RETURN-CODE   PIC S9(04) COMP.
           05  WS-DBE-RETURN-MSG    PIC X(79).
      *
      *    DATE/TIME FIELDS
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-DATE.
               10  WS-CURR-YYYY     PIC 9(04).
               10  WS-CURR-MM       PIC 9(02).
               10  WS-CURR-DD       PIC 9(02).
           05  WS-CURR-TIME.
               10  WS-CURR-HH       PIC 9(02).
               10  WS-CURR-MN       PIC 9(02).
               10  WS-CURR-SS       PIC 9(02).
               10  WS-CURR-HS       PIC 9(02).
           05  WS-DIFF-FROM-GMT     PIC S9(04).
       01  WS-FORMATTED-DATE        PIC X(10) VALUE SPACES.
      *
      *    OPTIONS TOTAL CURSOR
      *
           EXEC SQL DECLARE CSR_OPTIONS CURSOR FOR
               SELECT SUM(OPTION_PRICE)
               FROM   AUTOSALE.VEHICLE_OPTION
               WHERE  VIN = :WS-QI-VIN
                 AND  INSTALLED_FLAG = 'Y'
           END-EXEC
      *
      *    EXISTING TRADE-IN CURSOR
      *
           EXEC SQL DECLARE CSR_TRADE CURSOR FOR
               SELECT ALLOWANCE_AMT
                    , PAYOFF_AMT
               FROM   AUTOSALE.TRADE_IN
               WHERE  DEAL_NUMBER = :WS-DEAL-NUMBER
           END-EXEC
      *
      *    EXISTING REBATES CURSOR
      *
           EXEC SQL DECLARE CSR_REBATES CURSOR FOR
               SELECT SUM(AMOUNT_APPLIED)
               FROM   AUTOSALE.INCENTIVE_APPLIED
               WHERE  DEAL_NUMBER = :WS-DEAL-NUMBER
           END-EXEC
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-OPTIONS-TOTAL      PIC S9(04) COMP VALUE +0.
           05  NI-TRADE-ALLOW        PIC S9(04) COMP VALUE +0.
           05  NI-TRADE-PAYOFF       PIC S9(04) COMP VALUE +0.
           05  NI-REBATES            PIC S9(04) COMP VALUE +0.
           05  NI-CUST-COUNTY        PIC S9(04) COMP VALUE +0.
           05  NI-CUST-CITY          PIC S9(04) COMP VALUE +0.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                PIC X(10).
           05  IO-PCB-STATUS         PIC X(02).
           05  FILLER                PIC X(20).
           05  IO-PCB-MOD-NAME       PIC X(08).
           05  IO-PCB-USER-ID        PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER                PIC X(22).
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
               PERFORM 4000-GET-PRICING
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-CALCULATE-TAXES
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-GENERATE-DEAL-NUMBER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-CALCULATE-TOTALS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7500-INSERT-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7600-INSERT-LINE-ITEMS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7700-WRITE-AUDIT-LOG
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
      *    1000-INITIALIZE - SET UP WORK AREAS                       *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE +0 TO WS-RETURN-CODE
           SET WS-NO-ERROR TO TRUE
           INITIALIZE WS-QUOTE-OUTPUT
           INITIALIZE WS-DEAL-CALC
           MOVE SPACES TO WS-ERROR-MSG
           MOVE +0 TO WS-LINE-SEQ
      *
           MOVE FUNCTION CURRENT-DATE TO
               WS-CURRENT-DATE-DATA
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-DATE
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT - GU CALL ON IO-PCB                    *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-IO-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'SALQOT00: IMS GU FAILED - UNABLE TO RECEIVE'
                   TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-BODY(1:9)  TO WS-QI-CUSTOMER-ID
               MOVE WS-INP-BODY(10:17) TO WS-QI-VIN
               MOVE WS-INP-BODY(27:8) TO WS-QI-SALESPERSON-ID
               MOVE WS-INP-BODY(35:1) TO WS-QI-DEAL-TYPE
               MOVE WS-INP-BODY(36:5) TO WS-QI-DEALER-CODE
               MOVE WS-INP-BODY(41:12) TO WS-QI-DOWN-PMT
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - VALIDATE CUSTOMER, VEHICLE, USER    *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
      *    VALIDATE CUSTOMER ID
      *
           IF WS-QI-CUSTOMER-ID = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER ID IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           COMPUTE WS-CUST-ID-NUM =
               FUNCTION NUMVAL(WS-QI-CUSTOMER-ID)
      *
           EXEC SQL
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , STATE_CODE
                    , DEALER_CODE
               INTO   :CUSTOMER-ID
                    , :FIRST-NAME
                    , :LAST-NAME
                    , :STATE-CODE OF DCLCUSTOMER
                    , :DEALER-CODE OF DCLCUSTOMER
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               PERFORM 3900-DB2-ERROR
               GO TO 3000-EXIT
           END-IF
      *
           MOVE STATE-CODE OF DCLCUSTOMER TO WS-CUST-STATE
           MOVE DEALER-CODE OF DCLCUSTOMER TO WS-DEALER-CODE
      *
      *    VALIDATE VIN
      *
           IF WS-QI-VIN = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VIN IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , VEHICLE_STATUS
                    , DEALER_CODE
               INTO   :VIN            OF DCLVEHICLE
                    , :MODEL-YEAR     OF DCLVEHICLE
                    , :MAKE-CODE      OF DCLVEHICLE
                    , :MODEL-CODE     OF DCLVEHICLE
                    , :VEHICLE-STATUS
                    , :DEALER-CODE    OF DCLVEHICLE
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :WS-QI-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               PERFORM 3900-DB2-ERROR
               GO TO 3000-EXIT
           END-IF
      *
           IF VEHICLE-STATUS NOT = 'AV'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'VEHICLE NOT AVAILABLE - STATUS: '
                      VEHICLE-STATUS
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE SALESPERSON
      *
           IF WS-QI-SALESPERSON-ID = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SALESPERSON ID IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT USER_ID
                    , USER_TYPE
                    , ACTIVE_FLAG
               INTO   :USER-ID
                    , :USER-TYPE
                    , :ACTIVE-FLAG
               FROM   AUTOSALE.SYSTEM_USER
               WHERE  USER_ID = :WS-QI-SALESPERSON-ID
                 AND  ACTIVE_FLAG = 'Y'
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'SALESPERSON NOT FOUND OR INACTIVE'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               PERFORM 3900-DB2-ERROR
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE DEAL TYPE
      *
           IF NOT WS-QI-RETAIL AND NOT WS-QI-LEASE
           AND NOT WS-QI-FLEET AND NOT WS-QI-WHOLESALE
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INVALID DEAL TYPE - USE R, L, F, OR W'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
      *    PARSE DOWN PAYMENT IF PROVIDED
      *
           IF WS-QI-DOWN-PMT NOT = SPACES
               COMPUTE WS-DOWN-PMT-NUM =
                   FUNCTION NUMVAL(WS-QI-DOWN-PMT)
           ELSE
               MOVE +0 TO WS-DOWN-PMT-NUM
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3900-DB2-ERROR - HANDLE DB2 ERROR VIA COMDBEL0            *
      ****************************************************************
       3900-DB2-ERROR.
      *
           MOVE +12 TO WS-RETURN-CODE
           MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
           MOVE '3000-VALIDATE-INPUT' TO WS-DBE-PARAGRAPH
           MOVE SQLCODE TO WS-DBE-SQLCODE
           MOVE SQLERRMC TO WS-DBE-SQLERRM
           MOVE 'VALIDATION' TO WS-DBE-TABLE-NAME
           MOVE 'SELECT' TO WS-DBE-OPERATION
      *
           CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                 WS-DBE-RESULT
      *
           MOVE WS-DBE-RETURN-MSG TO WS-ERROR-MSG
           .
      *
      ****************************************************************
      *    4000-GET-PRICING - CALL COMPRCL0 AND GET OPTIONS TOTAL    *
      ****************************************************************
       4000-GET-PRICING.
      *
      *    CALL PRICING MODULE FOR VEHICLE MSRP/INVOICE/HOLDBACK
      *
           MOVE 'LKUP' TO WS-PRC-FUNCTION
           MOVE MODEL-YEAR OF DCLVEHICLE TO WS-PRC-MODEL-YEAR
           MOVE MAKE-CODE OF DCLVEHICLE TO WS-PRC-MAKE-CODE
           MOVE MODEL-CODE OF DCLVEHICLE TO WS-PRC-MODEL-CODE
      *
           CALL 'COMPRCL0' USING WS-PRC-REQUEST
                                 WS-PRC-RESULT
      *
           IF WS-PRC-RETURN-CODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-PRC-RETURN-MSG TO WS-ERROR-MSG
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-PRC-MSRP     TO WS-DC-VEHICLE-PRICE
           MOVE WS-PRC-INVOICE  TO WS-DC-INVOICE-PRICE
           MOVE WS-PRC-HOLDBACK TO WS-DC-HOLDBACK-AMT
           MOVE WS-PRC-DEST-FEE TO WS-DC-DEST-FEE
      *
      *    GET OPTIONS TOTAL FROM VEHICLE_OPTION
      *
           EXEC SQL
               SELECT COALESCE(SUM(OPTION_PRICE), 0)
               INTO   :WS-DC-OPTIONS-TOTAL
                       :NI-OPTIONS-TOTAL
               FROM   AUTOSALE.VEHICLE_OPTION
               WHERE  VIN = :WS-QI-VIN
                 AND  INSTALLED_FLAG = 'Y'
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ERROR READING VEHICLE OPTIONS'
                   TO WS-ERROR-MSG
               GO TO 4000-EXIT
           END-IF
      *
           IF NI-OPTIONS-TOTAL < +0
               MOVE +0 TO WS-DC-OPTIONS-TOTAL
           END-IF
      *
      *    CALCULATE SUBTOTAL
      *
           COMPUTE WS-DC-SUBTOTAL =
               WS-DC-VEHICLE-PRICE
             + WS-DC-OPTIONS-TOTAL
             + WS-DC-DEST-FEE
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-CALCULATE-TAXES - CALL COMTAXL0                      *
      ****************************************************************
       5000-CALCULATE-TAXES.
      *
      *    LOOK UP CUSTOMER COUNTY/CITY CODES FROM DEALER STATE
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
           IF SQLCODE = +100
               MOVE '00000' TO WS-CUST-COUNTY
               MOVE '00000' TO WS-CUST-CITY
           END-IF
      *
      *    TAXABLE AMOUNT = SUBTOTAL - TRADE ALLOWANCE (IF ANY)
      *
           COMPUTE WS-DC-TAXABLE-AMT =
               WS-DC-SUBTOTAL - WS-DC-TRADE-ALLOW
      *
           IF WS-DC-TAXABLE-AMT < +0
               MOVE +0 TO WS-DC-TAXABLE-AMT
           END-IF
      *
           MOVE 'CALC' TO WS-TAX-FUNCTION
           MOVE WS-CUST-STATE  TO WS-TAX-STATE
           MOVE WS-CUST-COUNTY TO WS-TAX-COUNTY
           MOVE WS-CUST-CITY   TO WS-TAX-CITY
           MOVE WS-DC-TAXABLE-AMT TO WS-TAX-TAXABLE-AMT
      *
           CALL 'COMTAXL0' USING WS-TAX-REQUEST
                                 WS-TAX-RESULT
      *
           IF WS-TAX-RETURN-CODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE WS-TAX-RETURN-MSG TO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
           MOVE WS-TAX-STATE-AMT  TO WS-DC-STATE-TAX
           MOVE WS-TAX-COUNTY-AMT TO WS-DC-COUNTY-TAX
           MOVE WS-TAX-CITY-AMT   TO WS-DC-CITY-TAX
           MOVE WS-TAX-DOC-FEE    TO WS-DC-DOC-FEE
           MOVE WS-TAX-TITLE-FEE  TO WS-DC-TITLE-FEE
           MOVE WS-TAX-REG-FEE    TO WS-DC-REG-FEE
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-GENERATE-DEAL-NUMBER - CALL COMSEQL0                 *
      ****************************************************************
       6000-GENERATE-DEAL-NUMBER.
      *
           MOVE 'NEXT' TO WS-SEQ-FUNCTION
           MOVE 'DEAL_NUMBER' TO WS-SEQ-NAME
      *
           CALL 'COMSEQL0' USING WS-SEQ-REQUEST
                                 WS-SEQ-RESULT
      *
           IF WS-SEQ-RETURN-CODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-SEQ-RETURN-MSG TO WS-ERROR-MSG
           ELSE
               MOVE WS-SEQ-FORMATTED TO WS-DEAL-NUMBER
           END-IF
           .
      *
      ****************************************************************
      *    7000-CALCULATE-TOTALS - COMPUTE FINAL DEAL FIGURES        *
      ****************************************************************
       7000-CALCULATE-TOTALS.
      *
      *    TOTAL PRICE = SUBTOTAL - DISCOUNT - REBATES - NET TRADE
      *                  + TAXES + FEES
      *
           COMPUTE WS-DC-TOTAL-PRICE =
               WS-DC-SUBTOTAL
             - WS-DC-DISCOUNT
             - WS-DC-REBATES
             - WS-DC-NET-TRADE
             + WS-DC-STATE-TAX
             + WS-DC-COUNTY-TAX
             + WS-DC-CITY-TAX
             + WS-DC-DOC-FEE
             + WS-DC-TITLE-FEE
             + WS-DC-REG-FEE
      *
      *    DOWN PAYMENT AND AMOUNT FINANCED
      *
           MOVE WS-DOWN-PMT-NUM TO WS-DC-DOWN-PAYMENT
      *
           COMPUTE WS-DC-AMT-FINANCED =
               WS-DC-TOTAL-PRICE - WS-DC-DOWN-PAYMENT
      *
           IF WS-DC-AMT-FINANCED < +0
               MOVE +0 TO WS-DC-AMT-FINANCED
           END-IF
      *
      *    FRONT GROSS = SELLING PRICE - INVOICE - HOLDBACK
      *
           COMPUTE WS-DC-FRONT-GROSS =
               WS-DC-VEHICLE-PRICE
             - WS-DC-INVOICE-PRICE
             - WS-DC-HOLDBACK-AMT
             - WS-DC-DISCOUNT
           .
      *
      ****************************************************************
      *    7500-INSERT-DEAL - INSERT SALES_DEAL RECORD               *
      ****************************************************************
       7500-INSERT-DEAL.
      *
           EXEC SQL
               INSERT INTO AUTOSALE.SALES_DEAL
               ( DEAL_NUMBER
               , DEALER_CODE
               , CUSTOMER_ID
               , VIN
               , SALESPERSON_ID
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
               , BACK_GROSS
               , TOTAL_GROSS
               , DEAL_DATE
               , CREATED_TS
               , UPDATED_TS
               )
               VALUES
               ( :WS-DEAL-NUMBER
               , :WS-DEALER-CODE
               , :WS-CUST-ID-NUM
               , :WS-QI-VIN
               , :WS-QI-SALESPERSON-ID
               , :WS-QI-DEAL-TYPE
               , 'WS'
               , :WS-DC-VEHICLE-PRICE
               , :WS-DC-OPTIONS-TOTAL
               , :WS-DC-DEST-FEE
               , :WS-DC-SUBTOTAL
               , :WS-DC-TRADE-ALLOW
               , :WS-DC-TRADE-PAYOFF
               , :WS-DC-NET-TRADE
               , :WS-DC-REBATES
               , :WS-DC-DISCOUNT
               , :WS-DC-DOC-FEE
               , :WS-DC-STATE-TAX
               , :WS-DC-COUNTY-TAX
               , :WS-DC-CITY-TAX
               , :WS-DC-TITLE-FEE
               , :WS-DC-REG-FEE
               , :WS-DC-TOTAL-PRICE
               , :WS-DC-DOWN-PAYMENT
               , :WS-DC-AMT-FINANCED
               , :WS-DC-FRONT-GROSS
               , 0
               , :WS-DC-FRONT-GROSS
               , CURRENT DATE
               , CURRENT TIMESTAMP
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '7500-INSERT-DEAL' TO WS-DBE-PARAGRAPH
               MOVE SQLCODE TO WS-DBE-SQLCODE
               MOVE SQLERRMC TO WS-DBE-SQLERRM
               MOVE 'SALES_DEAL' TO WS-DBE-TABLE-NAME
               MOVE 'INSERT' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                     WS-DBE-RESULT
               MOVE WS-DBE-RETURN-MSG TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    7600-INSERT-LINE-ITEMS - INSERT DEAL_LINE_ITEM ROWS       *
      ****************************************************************
       7600-INSERT-LINE-ITEMS.
      *
           MOVE +0 TO WS-LINE-SEQ
      *
      *    LINE 1: VEHICLE PRICE
      *
           ADD +1 TO WS-LINE-SEQ
           PERFORM 7610-INSERT-ONE-LINE-VP
      *
      *    LINE 2: OPTIONS
      *
           IF WS-DC-OPTIONS-TOTAL > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7620-INSERT-ONE-LINE-OPT
           END-IF
      *
      *    LINE 3: DESTINATION FEE
      *
           IF WS-DC-DEST-FEE > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7630-INSERT-ONE-LINE-DST
           END-IF
      *
      *    LINE 4: DOC FEE
      *
           IF WS-DC-DOC-FEE > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7640-INSERT-ONE-LINE-DOC
           END-IF
      *
      *    LINE 5: STATE TAX
      *
           IF WS-DC-STATE-TAX > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7650-INSERT-ONE-LINE-STX
           END-IF
      *
      *    LINE 6: COUNTY TAX
      *
           IF WS-DC-COUNTY-TAX > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7660-INSERT-ONE-LINE-CTX
           END-IF
      *
      *    LINE 7: CITY TAX
      *
           IF WS-DC-CITY-TAX > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7670-INSERT-ONE-LINE-CIX
           END-IF
      *
      *    LINE 8: TITLE FEE
      *
           IF WS-DC-TITLE-FEE > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7680-INSERT-ONE-LINE-TTL
           END-IF
      *
      *    LINE 9: REGISTRATION FEE
      *
           IF WS-DC-REG-FEE > +0
               ADD +1 TO WS-LINE-SEQ
               PERFORM 7690-INSERT-ONE-LINE-REG
           END-IF
           .
      *
       7610-INSERT-ONE-LINE-VP.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'VP',
                'VEHICLE PRICE (MSRP)', :WS-DC-VEHICLE-PRICE,
                :WS-DC-INVOICE-PRICE, 'Y')
           END-EXEC
           .
       7620-INSERT-ONE-LINE-OPT.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'OP',
                'VEHICLE OPTIONS TOTAL', :WS-DC-OPTIONS-TOTAL,
                :WS-DC-OPTIONS-TOTAL, 'Y')
           END-EXEC
           .
       7630-INSERT-ONE-LINE-DST.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'DF',
                'DESTINATION/DELIVERY FEE', :WS-DC-DEST-FEE,
                :WS-DC-DEST-FEE, 'N')
           END-EXEC
           .
       7640-INSERT-ONE-LINE-DOC.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'DC',
                'DOCUMENTARY FEE', :WS-DC-DOC-FEE,
                0, 'N')
           END-EXEC
           .
       7650-INSERT-ONE-LINE-STX.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'TX',
                'STATE TAX', :WS-DC-STATE-TAX,
                0, 'N')
           END-EXEC
           .
       7660-INSERT-ONE-LINE-CTX.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'TX',
                'COUNTY TAX', :WS-DC-COUNTY-TAX,
                0, 'N')
           END-EXEC
           .
       7670-INSERT-ONE-LINE-CIX.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'TX',
                'CITY TAX', :WS-DC-CITY-TAX,
                0, 'N')
           END-EXEC
           .
       7680-INSERT-ONE-LINE-TTL.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'TF',
                'TITLE FEE', :WS-DC-TITLE-FEE,
                0, 'N')
           END-EXEC
           .
       7690-INSERT-ONE-LINE-REG.
           EXEC SQL
               INSERT INTO AUTOSALE.DEAL_LINE_ITEM
               (DEAL_NUMBER, LINE_SEQ, LINE_TYPE,
                DESCRIPTION, AMOUNT, COST, TAXABLE_FLAG)
               VALUES
               (:WS-DEAL-NUMBER, :WS-LINE-SEQ, 'RF',
                'REGISTRATION FEE', :WS-DC-REG-FEE,
                0, 'N')
           END-EXEC
           .
      *
      ****************************************************************
      *    7700-WRITE-AUDIT-LOG - LOG DEAL CREATION                  *
      ****************************************************************
       7700-WRITE-AUDIT-LOG.
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'QUOTE   '         TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID     TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-DEAL-NUMBER     TO WS-LR-ENTITY-KEY
           STRING 'DEAL WORKSHEET CREATED: ' WS-DEAL-NUMBER
                  ' VIN=' WS-QI-VIN
                  ' CUST=' WS-QI-CUSTOMER-ID
                  DELIMITED BY SIZE
                  INTO WS-LR-DESCRIPTION
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
           .
      *
      ****************************************************************
      *    8000-FORMAT-OUTPUT - BUILD DISPLAY WORKSHEET               *
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
           MOVE 'DEAL WORKSHEET CREATED SUCCESSFULLY'
               TO WS-OUT-MSG-TEXT
      *
           MOVE WS-DEAL-NUMBER TO WS-QO-DEAL-NUM
      *
      *    CUSTOMER INFO
      *
           STRING FIRST-NAME-TX(1:FIRST-NAME-LN)
                  ' '
                  LAST-NAME-TX(1:LAST-NAME-LN)
                  DELIMITED BY SIZE
                  INTO WS-QO-CUST-NAME
           MOVE WS-CUST-ID-NUM TO WS-QO-CUST-ID
      *
      *    VEHICLE INFO
      *
           MOVE MODEL-YEAR OF DCLVEHICLE TO WS-QO-VEH-YEAR
           MOVE MAKE-CODE OF DCLVEHICLE TO WS-QO-VEH-MAKE
           MOVE MODEL-CODE OF DCLVEHICLE TO WS-QO-VEH-MODEL
           MOVE WS-QI-VIN TO WS-QO-VEH-VIN
      *
      *    FINANCIAL DETAILS
      *
           MOVE WS-DC-VEHICLE-PRICE TO WS-QO-VEH-PRICE
           MOVE WS-DC-OPTIONS-TOTAL TO WS-QO-OPTIONS
           MOVE WS-DC-DEST-FEE      TO WS-QO-DEST-FEE
           MOVE WS-DC-SUBTOTAL      TO WS-QO-SUBTOTAL
           MOVE WS-DC-DISCOUNT      TO WS-QO-DISCOUNT
           MOVE WS-DC-REBATES       TO WS-QO-REBATES
           MOVE WS-DC-NET-TRADE     TO WS-QO-NET-TRADE
           MOVE WS-DC-STATE-TAX     TO WS-QO-STATE-TAX
           MOVE WS-DC-COUNTY-TAX    TO WS-QO-COUNTY-TAX
           MOVE WS-DC-CITY-TAX      TO WS-QO-CITY-TAX
           MOVE WS-DC-DOC-FEE       TO WS-QO-DOC-FEE
           MOVE WS-DC-TITLE-FEE     TO WS-QO-TITLE-FEE
           MOVE WS-DC-REG-FEE       TO WS-QO-REG-FEE
           MOVE WS-DC-TOTAL-PRICE   TO WS-QO-TOTAL
           MOVE WS-DC-DOWN-PAYMENT  TO WS-QO-DOWN-PMT
           MOVE WS-DC-AMT-FINANCED  TO WS-QO-AMT-FIN
           MOVE WS-DC-FRONT-GROSS   TO WS-QO-FRONT-GRSS
      *
           MOVE WS-QUOTE-OUTPUT TO WS-OUT-BODY
           .
       8000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
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
      * END OF SALQOT00                                              *
      ****************************************************************
