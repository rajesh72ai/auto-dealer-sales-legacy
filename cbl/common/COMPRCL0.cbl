       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMPRCL0.
      ****************************************************************
      * PROGRAM:   COMPRCL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   VEHICLE PRICING ENGINE MODULE. LOOKS UP BASE      *
      *            PRICING FROM THE PRICE_MASTER DB2 TABLE AND       *
      *            CALCULATES ALL PRICING COMPONENTS FOR A VEHICLE   *
      *            INCLUDING MSRP, INVOICE, HOLDBACK, GROSS PROFIT   *
      *            AND COMPLETE DEAL PRICING WITH TAX.                *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMPRCL0' USING LK-PRC-INPUT-AREA                   *
      *                         LK-PRC-RESULT-AREA                   *
      *                         LK-PRC-RETURN-CODE                   *
      *                         LK-PRC-ERROR-MSG                     *
      *                                                              *
      * FUNCTIONS:                                                   *
      *   MSRP - GET MANUFACTURER SUGGESTED RETAIL PRICE             *
      *   INVP - GET INVOICE PRICE                                   *
      *   GROS - CALCULATE GROSS PROFIT AT A GIVEN SELLING PRICE    *
      *   MRGN - CALCULATE MARGIN PERCENTAGE                        *
      *   DEAL - BUILD COMPLETE DEAL PRICING WITH ALL COMPONENTS    *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - SUCCESS                                               *
      *   04 - PRICING NOT FOUND FOR VEHICLE                        *
      *   08 - INVALID INPUT                                         *
      *   12 - DB2 ERROR                                             *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMPRCL0'.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR PRICE_MASTER TABLE
      *
           COPY DCLPRICE.
      *
      *    DCLGEN FOR VEHICLE TABLE (FOR VIN LOOKUP)
      *
           COPY DCLVEHCL.
      *
      *    DATE FIELDS FOR EFFECTIVE PRICING LOOKUP
      *
       01  WS-DATE-FIELDS.
           05  WS-CURRENT-DATE.
               10  WS-CURR-YYYY   PIC 9(04).
               10  WS-CURR-MM     PIC 9(02).
               10  WS-CURR-DD     PIC 9(02).
           05  WS-CURRENT-DATE-X REDEFINES WS-CURRENT-DATE
                                   PIC X(08).
           05  WS-CURRENT-DATE-DB2 PIC X(10) VALUE SPACES.
      *
      *    PRICING CALCULATION WORK FIELDS
      *
       01  WS-PRICING-WORK.
           05  WS-BASE-MSRP       PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-BASE-INVOICE    PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-HOLDBACK-AMT    PIC S9(07)V99 COMP-3 VALUE 0.
           05  WS-HOLDBACK-PCT    PIC S9(02)V9(03) COMP-3 VALUE 0.
           05  WS-DEST-FEE        PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-ADV-FEE         PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TOTAL-MSRP      PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TOTAL-INVOICE   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-DEALER-COST     PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-SELLING-PRICE   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-GROSS-PROFIT    PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-FRONT-GROSS     PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-BACK-GROSS      PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-MARGIN-PCT      PIC S9(03)V99 COMP-3 VALUE 0.
           05  WS-CALC-HOLDBACK   PIC S9(07)V99 COMP-3 VALUE 0.
      *
      *    VEHICLE LOOKUP WORK FIELDS
      *
       01  WS-VEHICLE-WORK.
           05  WS-VEH-MODEL-YEAR  PIC S9(04) COMP VALUE 0.
           05  WS-VEH-MAKE-CODE   PIC X(03) VALUE SPACES.
           05  WS-VEH-MODEL-CODE  PIC X(06) VALUE SPACES.
           05  WS-VEH-FOUND-FLAG  PIC X(01) VALUE 'N'.
               88  WS-VEH-FOUND            VALUE 'Y'.
               88  WS-VEH-NOT-FOUND        VALUE 'N'.
      *
      *    TAX CALCULATION CALL PARAMETERS
      *    (FOR DEAL FUNCTION - CALLS COMTAXL0)
      *
       01  WS-TAX-CALL-STATE      PIC X(02) VALUE SPACES.
       01  WS-TAX-CALL-COUNTY     PIC X(05) VALUE SPACES.
       01  WS-TAX-CALL-CITY       PIC X(05) VALUE SPACES.
       01  WS-TAX-CALL-INPUT.
           05  WS-TC-TAXABLE-AMT  PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-TRADE-ALLOW  PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-DOC-FEE-REQ  PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TC-VEHICLE-TYPE PIC X(02) VALUE 'NW'.
           05  WS-TC-SALE-DATE    PIC X(10) VALUE SPACES.
       01  WS-TAX-CALL-RESULT.
           05  WS-TC-STATE-RATE   PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-TC-STATE-AMT    PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-COUNTY-RATE  PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-TC-COUNTY-AMT   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-CITY-RATE    PIC S9(01)V9(04) COMP-3 VALUE 0.
           05  WS-TC-CITY-AMT     PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-TOTAL-TAX    PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-NET-TAXABLE  PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TC-DOC-FEE      PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TC-TITLE-FEE    PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TC-REG-FEE      PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TC-TOTAL-FEES   PIC S9(07)V99 COMP-3 VALUE 0.
           05  WS-TC-GRAND-TOTAL  PIC S9(09)V99 COMP-3 VALUE 0.
       01  WS-TAX-CALL-RC         PIC S9(04) COMP VALUE 0.
       01  WS-TAX-CALL-MSG        PIC X(50) VALUE SPACES.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  NI-EXPIRY-DATE     PIC S9(04) COMP VALUE 0.
           05  NI-VEH-ENGINE-NUM  PIC S9(04) COMP VALUE 0.
           05  NI-VEH-PROD-DATE   PIC S9(04) COMP VALUE 0.
           05  NI-VEH-SHIP-DATE   PIC S9(04) COMP VALUE 0.
           05  NI-VEH-RECV-DATE   PIC S9(04) COMP VALUE 0.
           05  NI-VEH-DEALER      PIC S9(04) COMP VALUE 0.
           05  NI-VEH-LOT         PIC S9(04) COMP VALUE 0.
           05  NI-VEH-STOCK       PIC S9(04) COMP VALUE 0.
           05  NI-VEH-PDI-DATE    PIC S9(04) COMP VALUE 0.
           05  NI-VEH-DAMAGE-DESC PIC S9(04) COMP VALUE 0.
           05  NI-VEH-KEY-NUM     PIC S9(04) COMP VALUE 0.
      *
       LINKAGE SECTION.
      *
       01  LK-PRC-INPUT-AREA.
           05  LK-PRC-FUNCTION    PIC X(04).
               88  LK-FUNC-MSRP               VALUE 'MSRP'.
               88  LK-FUNC-INVOICE            VALUE 'INVP'.
               88  LK-FUNC-GROSS              VALUE 'GROS'.
               88  LK-FUNC-MARGIN             VALUE 'MRGN'.
               88  LK-FUNC-DEAL               VALUE 'DEAL'.
           05  LK-PRC-VIN         PIC X(17).
           05  LK-PRC-MODEL-YEAR  PIC S9(04) COMP.
           05  LK-PRC-MAKE-CODE   PIC X(03).
           05  LK-PRC-MODEL-CODE  PIC X(06).
           05  LK-PRC-SELL-PRICE  PIC S9(09)V99 COMP-3.
           05  LK-PRC-TRADE-AMT   PIC S9(09)V99 COMP-3.
           05  LK-PRC-DOC-FEE-REQ PIC S9(05)V99 COMP-3.
           05  LK-PRC-STATE-CODE  PIC X(02).
           05  LK-PRC-COUNTY-CODE PIC X(05).
           05  LK-PRC-CITY-CODE   PIC X(05).
      *
       01  LK-PRC-RESULT-AREA.
           05  LK-RES-MODEL-YEAR  PIC S9(04) COMP.
           05  LK-RES-MAKE-CODE   PIC X(03).
           05  LK-RES-MODEL-CODE  PIC X(06).
           05  LK-RES-BASE-MSRP   PIC S9(09)V99 COMP-3.
           05  LK-RES-DEST-FEE    PIC S9(05)V99 COMP-3.
           05  LK-RES-ADV-FEE     PIC S9(05)V99 COMP-3.
           05  LK-RES-TOTAL-MSRP  PIC S9(09)V99 COMP-3.
           05  LK-RES-INVOICE     PIC S9(09)V99 COMP-3.
           05  LK-RES-HOLDBACK-AMT PIC S9(07)V99 COMP-3.
           05  LK-RES-HOLDBACK-PCT PIC S9(02)V9(03) COMP-3.
           05  LK-RES-DEALER-COST PIC S9(09)V99 COMP-3.
           05  LK-RES-SELL-PRICE  PIC S9(09)V99 COMP-3.
           05  LK-RES-FRONT-GROSS PIC S9(09)V99 COMP-3.
           05  LK-RES-BACK-GROSS  PIC S9(09)V99 COMP-3.
           05  LK-RES-TOTAL-GROSS PIC S9(09)V99 COMP-3.
           05  LK-RES-MARGIN-PCT  PIC S9(03)V99 COMP-3.
           05  LK-RES-TAX-AMT     PIC S9(09)V99 COMP-3.
           05  LK-RES-FEES-AMT    PIC S9(07)V99 COMP-3.
           05  LK-RES-DEAL-TOTAL  PIC S9(09)V99 COMP-3.
      *
       01  LK-PRC-RETURN-CODE     PIC S9(04) COMP.
      *
       01  LK-PRC-ERROR-MSG       PIC X(50).
      *
       PROCEDURE DIVISION USING LK-PRC-INPUT-AREA
                                LK-PRC-RESULT-AREA
                                LK-PRC-RETURN-CODE
                                LK-PRC-ERROR-MSG.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-PRC-RETURN-CODE
           MOVE SPACES TO LK-PRC-ERROR-MSG
           INITIALIZE LK-PRC-RESULT-AREA
           INITIALIZE WS-PRICING-WORK
      *
           PERFORM 1000-VALIDATE-INPUT
           IF LK-PRC-RETURN-CODE NOT = ZEROS
               GO TO 0000-EXIT
           END-IF
      *
      *    RESOLVE VEHICLE KEY FIELDS
      *
           PERFORM 2000-RESOLVE-VEHICLE-KEY
           IF LK-PRC-RETURN-CODE NOT = ZEROS
               GO TO 0000-EXIT
           END-IF
      *
      *    GET CURRENT DATE FOR EFFECTIVE PRICING
      *
           PERFORM 2500-GET-CURRENT-DATE
      *
      *    LOOKUP BASE PRICING FROM PRICE_MASTER
      *
           PERFORM 3000-LOOKUP-PRICING
           IF LK-PRC-RETURN-CODE NOT = ZEROS
               GO TO 0000-EXIT
           END-IF
      *
      *    EXTRACT PRICING COMPONENTS
      *
           PERFORM 4000-EXTRACT-PRICING
      *
      *    EXECUTE REQUESTED FUNCTION
      *
           EVALUATE LK-PRC-FUNCTION
               WHEN 'MSRP'
                   PERFORM 5000-CALCULATE-MSRP
               WHEN 'INVP'
                   PERFORM 5100-CALCULATE-INVOICE
               WHEN 'GROS'
                   PERFORM 5200-CALCULATE-GROSS
               WHEN 'MRGN'
                   PERFORM 5300-CALCULATE-MARGIN
               WHEN 'DEAL'
                   PERFORM 5400-CALCULATE-DEAL
           END-EVALUATE
      *
       0000-EXIT.
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - VALIDATE INPUT PARAMETERS                               *
      *---------------------------------------------------------------*
       1000-VALIDATE-INPUT.
      *
           IF NOT (LK-FUNC-MSRP OR LK-FUNC-INVOICE
               OR LK-FUNC-GROSS OR LK-FUNC-MARGIN
               OR LK-FUNC-DEAL)
               MOVE +8 TO LK-PRC-RETURN-CODE
               STRING 'INVALID PRICING FUNCTION: '
                      LK-PRC-FUNCTION
                      DELIMITED BY SIZE
                   INTO LK-PRC-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
      *    MUST HAVE VIN OR MODEL YEAR/MAKE/MODEL
      *
           IF LK-PRC-VIN = SPACES
               IF LK-PRC-MODEL-YEAR = 0 OR
                  LK-PRC-MAKE-CODE = SPACES OR
                  LK-PRC-MODEL-CODE = SPACES
                   MOVE +8 TO LK-PRC-RETURN-CODE
                   MOVE 'VIN OR YEAR/MAKE/MODEL REQUIRED'
                       TO LK-PRC-ERROR-MSG
                   GO TO 1000-EXIT
               END-IF
           END-IF
      *
      *    FOR GROSS/MARGIN, SELLING PRICE IS REQUIRED
      *
           IF (LK-FUNC-GROSS OR LK-FUNC-MARGIN)
              AND LK-PRC-SELL-PRICE <= 0
               MOVE +8 TO LK-PRC-RETURN-CODE
               MOVE 'SELLING PRICE REQUIRED FOR GROSS/MARGIN'
                   TO LK-PRC-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
      *    FOR DEAL, SELLING PRICE AND STATE CODE REQUIRED
      *
           IF LK-FUNC-DEAL
               IF LK-PRC-SELL-PRICE <= 0
                   MOVE +8 TO LK-PRC-RETURN-CODE
                   MOVE 'SELLING PRICE REQUIRED FOR DEAL'
                       TO LK-PRC-ERROR-MSG
                   GO TO 1000-EXIT
               END-IF
               IF LK-PRC-STATE-CODE = SPACES
                   MOVE +8 TO LK-PRC-RETURN-CODE
                   MOVE 'STATE CODE REQUIRED FOR DEAL PRICING'
                       TO LK-PRC-ERROR-MSG
               END-IF
           END-IF
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - RESOLVE VEHICLE KEY: IF VIN PROVIDED, LOOK UP VEHICLE   *
      *        TABLE TO GET MODEL YEAR, MAKE AND MODEL CODES            *
      *---------------------------------------------------------------*
       2000-RESOLVE-VEHICLE-KEY.
      *
           IF LK-PRC-VIN NOT = SPACES
      *        LOOK UP VEHICLE BY VIN
               PERFORM 2100-LOOKUP-VEHICLE-BY-VIN
               IF LK-PRC-RETURN-CODE NOT = ZEROS
                   GO TO 2000-EXIT
               END-IF
           ELSE
      *        USE DIRECT MODEL YEAR/MAKE/MODEL FROM INPUT
               MOVE LK-PRC-MODEL-YEAR TO WS-VEH-MODEL-YEAR
               MOVE LK-PRC-MAKE-CODE  TO WS-VEH-MAKE-CODE
               MOVE LK-PRC-MODEL-CODE TO WS-VEH-MODEL-CODE
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2100 - LOOKUP VEHICLE TABLE BY VIN TO GET YEAR/MAKE/MODEL     *
      *---------------------------------------------------------------*
       2100-LOOKUP-VEHICLE-BY-VIN.
      *
           EXEC SQL
               SELECT MODEL_YEAR,
                      MAKE_CODE,
                      MODEL_CODE
                 INTO :WS-VEH-MODEL-YEAR,
                      :WS-VEH-MAKE-CODE,
                      :WS-VEH-MODEL-CODE
                 FROM AUTOSALE.VEHICLE
                WHERE VIN = :LK-PRC-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE 'Y' TO WS-VEH-FOUND-FLAG
               WHEN +100
                   MOVE +4 TO LK-PRC-RETURN-CODE
                   STRING 'VEHICLE NOT FOUND FOR VIN '
                          LK-PRC-VIN
                          DELIMITED BY SIZE
                       INTO LK-PRC-ERROR-MSG
               WHEN OTHER
                   MOVE +12 TO LK-PRC-RETURN-CODE
                   MOVE 'DB2 ERROR ON VEHICLE LOOKUP'
                       TO LK-PRC-ERROR-MSG
           END-EVALUATE
           .
       2100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2500 - GET CURRENT DATE FOR EFFECTIVE PRICING LOOKUP           *
      *---------------------------------------------------------------*
       2500-GET-CURRENT-DATE.
      *
           MOVE FUNCTION CURRENT-DATE(1:8)
               TO WS-CURRENT-DATE-X
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
               DELIMITED BY SIZE
               INTO WS-CURRENT-DATE-DB2
           .
       2500-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - LOOKUP PRICING FROM PRICE_MASTER TABLE                  *
      *        FINDS EFFECTIVE PRICING FOR THE VEHICLE                 *
      *---------------------------------------------------------------*
       3000-LOOKUP-PRICING.
      *
           EXEC SQL
               SELECT MSRP,
                      INVOICE_PRICE,
                      HOLDBACK_AMT,
                      HOLDBACK_PCT,
                      DESTINATION_FEE,
                      ADVERTISING_FEE,
                      EFFECTIVE_DATE,
                      EXPIRY_DATE
                 INTO :MSRP             OF DCLPRICE-MASTER,
                      :INVOICE-PRICE    OF DCLPRICE-MASTER,
                      :HOLDBACK-AMT     OF DCLPRICE-MASTER,
                      :HOLDBACK-PCT     OF DCLPRICE-MASTER,
                      :DESTINATION-FEE  OF DCLPRICE-MASTER,
                      :ADVERTISING-FEE  OF DCLPRICE-MASTER,
                      :EFFECTIVE-DATE   OF DCLPRICE-MASTER,
                      :EXPIRY-DATE      OF DCLPRICE-MASTER
                                        :NI-EXPIRY-DATE
                 FROM AUTOSALE.PRICE_MASTER
                WHERE MODEL_YEAR = :WS-VEH-MODEL-YEAR
                  AND MAKE_CODE  = :WS-VEH-MAKE-CODE
                  AND MODEL_CODE = :WS-VEH-MODEL-CODE
                  AND EFFECTIVE_DATE <= :WS-CURRENT-DATE-DB2
                  AND (EXPIRY_DATE IS NULL
                       OR EXPIRY_DATE >= :WS-CURRENT-DATE-DB2)
                ORDER BY EFFECTIVE_DATE DESC
                FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE +4 TO LK-PRC-RETURN-CODE
                   MOVE 'NO PRICING FOUND FOR YEAR/MAKE/MODEL'
                       TO LK-PRC-ERROR-MSG
               WHEN OTHER
                   MOVE +12 TO LK-PRC-RETURN-CODE
                   MOVE 'DB2 ERROR ON PRICE_MASTER LOOKUP'
                       TO LK-PRC-ERROR-MSG
           END-EVALUATE
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - EXTRACT PRICING COMPONENTS FROM DB2 ROW                 *
      *---------------------------------------------------------------*
       4000-EXTRACT-PRICING.
      *
           MOVE MSRP            OF DCLPRICE-MASTER
               TO WS-BASE-MSRP
           MOVE INVOICE-PRICE   OF DCLPRICE-MASTER
               TO WS-BASE-INVOICE
           MOVE HOLDBACK-AMT    OF DCLPRICE-MASTER
               TO WS-HOLDBACK-AMT
           MOVE HOLDBACK-PCT    OF DCLPRICE-MASTER
               TO WS-HOLDBACK-PCT
           MOVE DESTINATION-FEE OF DCLPRICE-MASTER
               TO WS-DEST-FEE
           MOVE ADVERTISING-FEE OF DCLPRICE-MASTER
               TO WS-ADV-FEE
      *
      *    CALCULATE TOTAL MSRP (BASE + DESTINATION)
      *
           COMPUTE WS-TOTAL-MSRP =
               WS-BASE-MSRP + WS-DEST-FEE
      *
      *    CALCULATE TOTAL INVOICE (BASE INVOICE + DEST + ADV)
      *
           COMPUTE WS-TOTAL-INVOICE =
               WS-BASE-INVOICE + WS-DEST-FEE + WS-ADV-FEE
      *
      *    CALCULATE EFFECTIVE HOLDBACK
      *    USE FIXED AMOUNT IF > 0, ELSE CALCULATE FROM PCT
      *
           IF WS-HOLDBACK-AMT > 0
               MOVE WS-HOLDBACK-AMT TO WS-CALC-HOLDBACK
           ELSE
               COMPUTE WS-CALC-HOLDBACK ROUNDED =
                   WS-BASE-INVOICE * WS-HOLDBACK-PCT
           END-IF
      *
      *    DEALER COST = INVOICE - HOLDBACK
      *
           COMPUTE WS-DEALER-COST =
               WS-TOTAL-INVOICE - WS-CALC-HOLDBACK
      *
      *    POPULATE RESULT FIELDS COMMON TO ALL FUNCTIONS
      *
           MOVE WS-VEH-MODEL-YEAR TO LK-RES-MODEL-YEAR
           MOVE WS-VEH-MAKE-CODE  TO LK-RES-MAKE-CODE
           MOVE WS-VEH-MODEL-CODE TO LK-RES-MODEL-CODE
           MOVE WS-BASE-MSRP      TO LK-RES-BASE-MSRP
           MOVE WS-DEST-FEE       TO LK-RES-DEST-FEE
           MOVE WS-ADV-FEE        TO LK-RES-ADV-FEE
           MOVE WS-TOTAL-MSRP     TO LK-RES-TOTAL-MSRP
           MOVE WS-TOTAL-INVOICE  TO LK-RES-INVOICE
           MOVE WS-HOLDBACK-AMT   TO LK-RES-HOLDBACK-AMT
           MOVE WS-HOLDBACK-PCT   TO LK-RES-HOLDBACK-PCT
           MOVE WS-DEALER-COST    TO LK-RES-DEALER-COST
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - MSRP: RETURN TOTAL STICKER PRICE                       *
      *---------------------------------------------------------------*
       5000-CALCULATE-MSRP.
      *
      *    ALL BASE PRICING ALREADY POPULATED IN 4000
      *    MSRP FUNCTION JUST RETURNS THE BASE PRICING DATA
      *
           CONTINUE
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5100 - INVP: RETURN INVOICE PRICING                           *
      *---------------------------------------------------------------*
       5100-CALCULATE-INVOICE.
      *
      *    ALL INVOICE PRICING ALREADY POPULATED IN 4000
      *
           CONTINUE
           .
       5100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5200 - GROS: CALCULATE GROSS PROFIT AT SELLING PRICE          *
      *        FRONT GROSS = SELLING PRICE - INVOICE                   *
      *        BACK GROSS  = HOLDBACK AMOUNT                           *
      *        TOTAL GROSS = FRONT + BACK                              *
      *---------------------------------------------------------------*
       5200-CALCULATE-GROSS.
      *
           MOVE LK-PRC-SELL-PRICE TO WS-SELLING-PRICE
      *
      *    FRONT-END GROSS (WHAT THE CUSTOMER SEES)
      *
           COMPUTE WS-FRONT-GROSS =
               WS-SELLING-PRICE - WS-TOTAL-INVOICE
      *
      *    BACK-END GROSS (HOLDBACK - NOT VISIBLE TO CUSTOMER)
      *
           MOVE WS-CALC-HOLDBACK TO WS-BACK-GROSS
      *
      *    TOTAL GROSS PROFIT
      *
           COMPUTE WS-GROSS-PROFIT =
               WS-FRONT-GROSS + WS-BACK-GROSS
      *
           MOVE WS-SELLING-PRICE TO LK-RES-SELL-PRICE
           MOVE WS-FRONT-GROSS   TO LK-RES-FRONT-GROSS
           MOVE WS-BACK-GROSS    TO LK-RES-BACK-GROSS
           MOVE WS-GROSS-PROFIT  TO LK-RES-TOTAL-GROSS
           .
       5200-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5300 - MRGN: CALCULATE MARGIN PERCENTAGE                      *
      *        MARGIN% = (SELLING PRICE - DEALER COST) / SELLING      *
      *---------------------------------------------------------------*
       5300-CALCULATE-MARGIN.
      *
           MOVE LK-PRC-SELL-PRICE TO WS-SELLING-PRICE
      *
      *    CALCULATE GROSS FIRST
      *
           PERFORM 5200-CALCULATE-GROSS
      *
      *    MARGIN PERCENTAGE = TOTAL GROSS / SELLING PRICE * 100
      *
           IF WS-SELLING-PRICE > 0
               COMPUTE WS-MARGIN-PCT ROUNDED =
                   (WS-GROSS-PROFIT / WS-SELLING-PRICE) * 100
           ELSE
               MOVE ZEROS TO WS-MARGIN-PCT
           END-IF
      *
           MOVE WS-MARGIN-PCT TO LK-RES-MARGIN-PCT
           .
       5300-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5400 - DEAL: BUILD COMPLETE DEAL PRICING                      *
      *        INCLUDES PRICING + TAX + FEES                           *
      *        CALLS COMTAXL0 FOR TAX CALCULATION                     *
      *---------------------------------------------------------------*
       5400-CALCULATE-DEAL.
      *
      *    FIRST CALCULATE GROSS/MARGIN
      *
           PERFORM 5300-CALCULATE-MARGIN
      *
      *    NOW CALCULATE TAX BY CALLING COMTAXL0
      *
           MOVE LK-PRC-STATE-CODE  TO WS-TAX-CALL-STATE
           MOVE LK-PRC-COUNTY-CODE TO WS-TAX-CALL-COUNTY
           MOVE LK-PRC-CITY-CODE   TO WS-TAX-CALL-CITY
      *
           MOVE LK-PRC-SELL-PRICE  TO WS-TC-TAXABLE-AMT
           MOVE LK-PRC-TRADE-AMT   TO WS-TC-TRADE-ALLOW
           MOVE LK-PRC-DOC-FEE-REQ TO WS-TC-DOC-FEE-REQ
           MOVE 'NW'               TO WS-TC-VEHICLE-TYPE
           MOVE SPACES             TO WS-TC-SALE-DATE
      *
           INITIALIZE WS-TAX-CALL-RESULT
      *
           CALL 'COMTAXL0' USING WS-TAX-CALL-STATE
                                 WS-TAX-CALL-COUNTY
                                 WS-TAX-CALL-CITY
                                 WS-TAX-CALL-INPUT
                                 WS-TAX-CALL-RESULT
                                 WS-TAX-CALL-RC
                                 WS-TAX-CALL-MSG
      *
      *    CHECK TAX CALCULATION RESULT
      *
           IF WS-TAX-CALL-RC = 0
               MOVE WS-TC-TOTAL-TAX  TO LK-RES-TAX-AMT
               MOVE WS-TC-TOTAL-FEES TO LK-RES-FEES-AMT
           ELSE
      *        TAX CALC FAILED - SET TAX FIELDS TO ZERO
      *        BUT CONTINUE WITH THE DEAL (DON'T FAIL)
               MOVE ZEROS TO LK-RES-TAX-AMT
               MOVE ZEROS TO LK-RES-FEES-AMT
           END-IF
      *
      *    DEAL TOTAL = SELLING PRICE + TAX + FEES - TRADE
      *
           COMPUTE LK-RES-DEAL-TOTAL =
               WS-SELLING-PRICE
               + LK-RES-TAX-AMT
               + LK-RES-FEES-AMT
               - LK-PRC-TRADE-AMT
           .
       5400-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMPRCL0                                              *
      ****************************************************************
