       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINDOC00.
      ****************************************************************
      * PROGRAM:  FINDOC00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - FINANCE DOCUMENT GENERATION              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  GENERATES DOCUMENT DATA FOR FINANCE CLOSING:       *
      *             LOAN  = RETAIL INSTALLMENT CONTRACT               *
      *             LEASE = LEASE AGREEMENT                           *
      *             CASH  = CASH RECEIPT                              *
      *           PULLS ALL DEAL INFO: CUSTOMER, VEHICLE, PRICING,   *
      *           TRADE-IN, FINANCE TERMS, F&I PRODUCTS.             *
      *           FORMATS BUYER/SELLER INFO, VEHICLE DESCRIPTION,    *
      *           ITEMIZED PRICING, PAYMENT TERMS.                   *
      *           OUTPUTS MULTI-SEGMENT MESSAGE FOR PRINT.           *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNDC - FINANCE DOCUMENTS                           *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                       *
      *           COMLONL0 - LOAN RECALCULATION (FOR LOAN DOCS)      *
      *           COMLESL0 - LEASE RECALCULATION (FOR LEASE DOCS)    *
      *           COMDBEL0 - DB2 ERROR HANDLER                      *
      * TABLES:   AUTOSALE.SALES_DEAL                                *
      *           AUTOSALE.CUSTOMER                                   *
      *           AUTOSALE.VEHICLE                                    *
      *           AUTOSALE.MODEL_MASTER                               *
      *           AUTOSALE.FINANCE_APP                                *
      *           AUTOSALE.TRADE_IN                                   *
      *           AUTOSALE.LEASE_TERMS                                *
      *           AUTOSALE.FINANCE_PRODUCT                            *
      *           AUTOSALE.DEALER                                     *
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
                                          VALUE 'FINDOC00'.
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
      *    DCLGEN COPIES
      *
           COPY DCLSLDEL.
      *
           COPY DCLFINAP.
      *
           COPY DCLCUSTM.
      *
           COPY DCLVEHCL.
      *
           COPY DCLMODEL.
      *
           COPY DCLTRDEIN.
      *
           COPY DCLLSTRM.
      *
           COPY DCLFINPR.
      *
           COPY DCLDEALR.
      *
      *    INPUT FIELDS
      *
       01  WS-DOC-INPUT.
           05  WS-DI-DEAL-NUMBER         PIC X(10).
      *
      *    OUTPUT MESSAGE LAYOUT - MULTI-SECTION DOCUMENT
      *
       01  WS-DOC-OUTPUT.
           05  WS-DO-STATUS-LINE.
               10  WS-DO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-DO-MSG-TEXT       PIC X(70).
           05  WS-DO-BLANK-1            PIC X(79) VALUE SPACES.
      *    DOCUMENT TITLE
           05  WS-DO-TITLE-LINE.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  WS-DO-DOC-TITLE      PIC X(45).
               10  FILLER               PIC X(29) VALUE SPACES.
           05  WS-DO-TITLE-UND.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(45)
                   VALUE '============================================='.
               10  FILLER               PIC X(29) VALUE SPACES.
      *    SELLER (DEALER) INFO
           05  WS-DO-SELLER-LINE.
               10  FILLER               PIC X(08) VALUE 'SELLER: '.
               10  WS-DO-DEALER-NAME    PIC X(40).
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-DO-SELLER-ADDR.
               10  FILLER               PIC X(08) VALUE '        '.
               10  WS-DO-DEALER-ADDR    PIC X(50).
               10  FILLER               PIC X(21) VALUE SPACES.
      *    BUYER INFO
           05  WS-DO-BUYER-LINE.
               10  FILLER               PIC X(08) VALUE 'BUYER:  '.
               10  WS-DO-BUYER-NAME     PIC X(40).
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-DO-BUYER-ADDR.
               10  FILLER               PIC X(08) VALUE '        '.
               10  WS-DO-BUYER-ADDR-TX  PIC X(50).
               10  FILLER               PIC X(21) VALUE SPACES.
           05  WS-DO-BLANK-2            PIC X(79) VALUE SPACES.
      *    VEHICLE DESCRIPTION
           05  WS-DO-VEH-HDR.
               10  FILLER               PIC X(30)
                   VALUE '---- VEHICLE DESCRIPTION ----'.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-DO-VEH-LINE-1.
               10  WS-DO-VEH-YEAR       PIC 9(04).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-DO-VEH-MAKE       PIC X(03).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-DO-VEH-MODEL-NM   PIC X(35).
               10  FILLER               PIC X(33) VALUE SPACES.
           05  WS-DO-VEH-LINE-2.
               10  FILLER               PIC X(05) VALUE 'VIN: '.
               10  WS-DO-VEH-VIN        PIC X(17).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'STOCK: '.
               10  WS-DO-VEH-STOCK      PIC X(08).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'ODOM: '.
               10  WS-DO-VEH-ODOM       PIC Z(05)9.
               10  FILLER               PIC X(20) VALUE SPACES.
           05  WS-DO-BLANK-3            PIC X(79) VALUE SPACES.
      *    PRICING ITEMIZATION
           05  WS-DO-PRICE-HDR.
               10  FILLER               PIC X(30)
                   VALUE '---- PRICING ----            '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-DO-PRICE-VEH.
               10  FILLER               PIC X(30)
                   VALUE 'VEHICLE PRICE:                '.
               10  WS-DO-PX-VEH-PRICE   PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-PRICE-OPT.
               10  FILLER               PIC X(30)
                   VALUE 'OPTIONS/ACCESSORIES:          '.
               10  WS-DO-PX-OPTIONS     PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-PRICE-DEST.
               10  FILLER               PIC X(30)
                   VALUE 'DESTINATION FEE:              '.
               10  WS-DO-PX-DEST        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-PRICE-DISC.
               10  FILLER               PIC X(30)
                   VALUE 'DISCOUNT/REBATES:             '.
               10  WS-DO-PX-DISC        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(01) VALUE '-'.
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-DO-PRICE-TRADE.
               10  FILLER               PIC X(30)
                   VALUE 'NET TRADE ALLOWANCE:          '.
               10  WS-DO-PX-TRADE       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(01) VALUE '-'.
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-DO-PRICE-TAX.
               10  FILLER               PIC X(30)
                   VALUE 'TAXES (STATE/COUNTY/CITY):    '.
               10  WS-DO-PX-TAXES       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-PRICE-FEES.
               10  FILLER               PIC X(30)
                   VALUE 'FEES (DOC/TITLE/REG):         '.
               10  WS-DO-PX-FEES        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-PRICE-TOTAL.
               10  FILLER               PIC X(30)
                   VALUE 'TOTAL SALE PRICE:             '.
               10  WS-DO-PX-TOTAL       PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-PRICE-DOWN.
               10  FILLER               PIC X(30)
                   VALUE 'DOWN PAYMENT:                 '.
               10  WS-DO-PX-DOWN        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(01) VALUE '-'.
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-DO-PRICE-FINANCED.
               10  FILLER               PIC X(30)
                   VALUE 'AMOUNT FINANCED:              '.
               10  WS-DO-PX-FINANCED    PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-BLANK-4            PIC X(79) VALUE SPACES.
      *    FINANCE TERMS (LOAN)
           05  WS-DO-FIN-HDR.
               10  FILLER               PIC X(30)
                   VALUE '---- FINANCE TERMS ----      '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-DO-FIN-APR.
               10  FILLER               PIC X(30)
                   VALUE 'ANNUAL PERCENTAGE RATE:       '.
               10  WS-DO-FT-APR         PIC ZZ9.999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-DO-FIN-TERM.
               10  FILLER               PIC X(30)
                   VALUE 'TERM:                         '.
               10  WS-DO-FT-TERM        PIC Z(02)9.
               10  FILLER               PIC X(07)
                   VALUE ' MONTHS'.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-FIN-PMT.
               10  FILLER               PIC X(30)
                   VALUE 'MONTHLY PAYMENT:              '.
               10  WS-DO-FT-MONTHLY     PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(36) VALUE SPACES.
           05  WS-DO-FIN-TOTAL.
               10  FILLER               PIC X(30)
                   VALUE 'TOTAL OF PAYMENTS:            '.
               10  WS-DO-FT-TOT-PMT     PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-FIN-CHARGE.
               10  FILLER               PIC X(30)
                   VALUE 'FINANCE CHARGE:               '.
               10  WS-DO-FT-FIN-CHG     PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-DO-BLANK-5            PIC X(79) VALUE SPACES.
      *    F&I PRODUCTS
           05  WS-DO-PROD-HDR.
               10  FILLER               PIC X(30)
                   VALUE '---- F&I PRODUCTS ----       '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-DO-PROD-LINES.
               10  WS-DO-PROD-LINE      OCCURS 5 TIMES.
                   15  FILLER           PIC X(03) VALUE SPACES.
                   15  WS-DO-PR-NAME    PIC X(25).
                   15  FILLER           PIC X(03) VALUE SPACES.
                   15  WS-DO-PR-PRICE   PIC $ZZ,ZZ9.99.
                   15  FILLER           PIC X(35) VALUE SPACES.
           05  WS-DO-FILLER             PIC X(79) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-RETURN-CODE              PIC S9(04) COMP VALUE +0.
       01  WS-FINANCE-TYPE-WORK        PIC X(01) VALUE SPACES.
       01  WS-FINANCE-ID-WORK          PIC X(12) VALUE SPACES.
       01  WS-DEAL-NUM-WORK            PIC X(10) VALUE SPACES.
       01  WS-PROD-COUNT               PIC S9(04) COMP VALUE +0.
       01  WS-TOTAL-TAXES              PIC S9(09)V99 COMP-3
                                                       VALUE +0.
       01  WS-TOTAL-FEES               PIC S9(07)V99 COMP-3
                                                       VALUE +0.
       01  WS-TOTAL-DISC               PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    LOAN CALL FIELDS
      *
       01  WS-LOAN-REQUEST.
           05  WS-LN-FUNCTION           PIC X(04).
           05  WS-LN-PRINCIPAL          PIC S9(09)V99 COMP-3.
           05  WS-LN-APR                PIC S9(03)V9(04) COMP-3.
           05  WS-LN-TERM-MONTHS        PIC S9(04)    COMP.
           05  WS-LN-DEALER-CODE        PIC X(05).
           05  WS-LN-VIN                PIC X(17).
       01  WS-LOAN-RESULT.
           05  WS-LR-RETURN-CODE        PIC S9(04)    COMP.
           05  WS-LR-RETURN-MSG         PIC X(79).
           05  WS-LR-MONTHLY-PMT        PIC S9(07)V99 COMP-3.
           05  WS-LR-TOTAL-PAYMENTS     PIC S9(09)V99 COMP-3.
           05  WS-LR-TOTAL-INTEREST     PIC S9(09)V99 COMP-3.
           05  WS-LR-MONTHLY-RATE       PIC S9(01)V9(08) COMP-3.
           05  WS-LR-AMORT-MONTHS       PIC S9(04)    COMP.
           05  WS-LR-AMORT-TABLE.
               10  WS-LR-AMORT-ENTRY    OCCURS 12 TIMES.
                   15  WS-AM-MONTH-NUM  PIC S9(04)    COMP.
                   15  WS-AM-PAYMENT    PIC S9(07)V99 COMP-3.
                   15  WS-AM-PRINCIPAL  PIC S9(07)V99 COMP-3.
                   15  WS-AM-INTEREST   PIC S9(07)V99 COMP-3.
                   15  WS-AM-CUM-INT    PIC S9(09)V99 COMP-3.
                   15  WS-AM-BALANCE    PIC S9(09)V99 COMP-3.
      *
      *    FORMAT CALL FIELDS
      *
       01  WS-FMT-REQUEST.
           05  WS-FMT-FUNCTION          PIC X(04).
           05  WS-FMT-INPUT             PIC X(30).
       01  WS-FMT-RESULT.
           05  WS-FMT-RC                PIC S9(04) COMP.
           05  WS-FMT-OUTPUT            PIC X(40).
      *
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-PROGRAM-NAME         PIC X(08) VALUE 'FINDOC00'.
       01  WS-DBE-SECTION-NAME         PIC X(30).
       01  WS-DBE-TABLE-NAME           PIC X(18).
       01  WS-DBE-OPERATION            PIC X(08).
       01  WS-DBE-RESULT-AREA.
           05  WS-DBE-RESULT-CODE      PIC S9(04) COMP.
           05  WS-DBE-RESULT-MSG       PIC X(79).
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-SALES-MGR          PIC S9(04) COMP VALUE +0.
           05  WS-NI-DELIVERY           PIC S9(04) COMP VALUE +0.
           05  WS-NI-DEAL-DATE          PIC S9(04) COMP VALUE +0.
           05  WS-NI-TRADE              PIC S9(04) COMP VALUE +0.
           05  WS-NI-ADDR2              PIC S9(04) COMP VALUE +0.
           05  WS-NI-MODEL-NAME         PIC S9(04) COMP VALUE +0.
      *
      *    PRODUCT CURSOR
      *
           EXEC SQL
               DECLARE CSR_FIN_PRODUCTS CURSOR FOR
               SELECT PRODUCT_NAME
                    , RETAIL_PRICE
               FROM   AUTOSALE.FINANCE_PRODUCT
               WHERE  DEAL_NUMBER = :WS-DEAL-NUM-WORK
               ORDER BY PRODUCT_SEQ
           END-EXEC.
      *
      *    PRODUCT FETCH WORK FIELDS
      *
       01  WS-PR-FETCH-NAME.
           49  WS-PR-FETCH-NAME-LN      PIC S9(04) COMP.
           49  WS-PR-FETCH-NAME-TX      PIC X(40).
       01  WS-PR-FETCH-PRICE            PIC S9(07)V99 COMP-3.
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
               PERFORM 4000-FETCH-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4500-FETCH-CUSTOMER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FETCH-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5500-FETCH-FINANCE-APP
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-BUILD-PRICING
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-BUILD-FINANCE-TERMS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 8000-FETCH-PRODUCTS
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
           INITIALIZE WS-DOC-OUTPUT
           INITIALIZE WS-DOC-INPUT
           MOVE 'FINDOC00' TO WS-DO-MSG-ID
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
               MOVE 'IMS GU FAILED - UNABLE TO RECEIVE INPUT'
                   TO WS-DO-MSG-TEXT
           ELSE
               MOVE WS-INP-KEY-DATA(1:10)
                   TO WS-DI-DEAL-NUMBER
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-DI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED'
                   TO WS-DO-MSG-TEXT
           ELSE
               MOVE WS-DI-DEAL-NUMBER TO WS-DEAL-NUM-WORK
           END-IF
           .
      *
      ****************************************************************
      *    4000-FETCH-DEAL - GET ALL DEAL DETAILS                    *
      ****************************************************************
       4000-FETCH-DEAL.
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEALER_CODE
                    , CUSTOMER_ID
                    , VIN
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
                    , DEAL_DATE
               INTO  :DEAL-NUMBER    OF DCLSALES-DEAL
                    , :DEALER-CODE   OF DCLSALES-DEAL
                    , :CUSTOMER-ID   OF DCLSALES-DEAL
                    , :VIN           OF DCLSALES-DEAL
                    , :DEAL-TYPE     OF DCLSALES-DEAL
                    , :DEAL-STATUS   OF DCLSALES-DEAL
                    , :VEHICLE-PRICE OF DCLSALES-DEAL
                    , :TOTAL-OPTIONS OF DCLSALES-DEAL
                    , :DESTINATION-FEE OF DCLSALES-DEAL
                    , :SUBTOTAL      OF DCLSALES-DEAL
                    , :TRADE-ALLOW   OF DCLSALES-DEAL
                    , :TRADE-PAYOFF  OF DCLSALES-DEAL
                    , :NET-TRADE     OF DCLSALES-DEAL
                    , :REBATES-APPLIED OF DCLSALES-DEAL
                    , :DISCOUNT-AMT  OF DCLSALES-DEAL
                    , :DOC-FEE       OF DCLSALES-DEAL
                    , :STATE-TAX     OF DCLSALES-DEAL
                    , :COUNTY-TAX    OF DCLSALES-DEAL
                    , :CITY-TAX      OF DCLSALES-DEAL
                    , :TITLE-FEE     OF DCLSALES-DEAL
                    , :REG-FEE       OF DCLSALES-DEAL
                    , :TOTAL-PRICE   OF DCLSALES-DEAL
                    , :DOWN-PAYMENT  OF DCLSALES-DEAL
                    , :AMOUNT-FINANCED OF DCLSALES-DEAL
                    , :DEAL-DATE     OF DCLSALES-DEAL
                                      :WS-NI-DEAL-DATE
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-DI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NOT FOUND' TO WS-DO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE '4000-FETCH'     TO WS-DBE-SECTION-NAME
               MOVE 'SALES_DEAL'     TO WS-DBE-TABLE-NAME
               MOVE 'SELECT'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON DEAL LOOKUP'
                   TO WS-DO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-FETCH-CUSTOMER - BUYER INFO                          *
      ****************************************************************
       4500-FETCH-CUSTOMER.
      *
           EXEC SQL
               SELECT FIRST_NAME
                    , LAST_NAME
                    , ADDRESS_LINE1
                    , CITY
                    , STATE_CODE
                    , ZIP_CODE
               INTO  :FIRST-NAME    OF DCLCUSTOMER
                    , :LAST-NAME    OF DCLCUSTOMER
                    , :ADDRESS-LINE1 OF DCLCUSTOMER
                    , :CITY         OF DCLCUSTOMER
                    , :STATE-CODE   OF DCLCUSTOMER
                    , :ZIP-CODE     OF DCLCUSTOMER
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :CUSTOMER-ID
                                      OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE = +0
               STRING FIRST-NAME-TX OF DCLCUSTOMER
                      DELIMITED BY '  '
                      ' '
                      DELIMITED BY SIZE
                      LAST-NAME-TX OF DCLCUSTOMER
                      DELIMITED BY '  '
                      INTO WS-DO-BUYER-NAME
      *
               STRING ADDRESS-LINE1-TX OF DCLCUSTOMER
                      DELIMITED BY '  '
                      ', '
                      DELIMITED BY SIZE
                      CITY-TX OF DCLCUSTOMER
                      DELIMITED BY '  '
                      ', '
                      DELIMITED BY SIZE
                      STATE-CODE OF DCLCUSTOMER
                      DELIMITED BY SIZE
                      ' '
                      DELIMITED BY SIZE
                      ZIP-CODE OF DCLCUSTOMER
                      DELIMITED BY '  '
                      INTO WS-DO-BUYER-ADDR-TX
           END-IF
      *
      *    FETCH DEALER INFO FOR SELLER SECTION
      *
           EXEC SQL
               SELECT DEALER_NAME
                    , ADDRESS_LINE1
                    , CITY
                    , STATE_CODE
                    , ZIP_CODE
               INTO  :DEALER-NAME  OF DCLDEALER
                    , :ADDRESS-LINE1 OF DCLDEALER
                    , :CITY        OF DCLDEALER
                    , :STATE-CODE  OF DCLDEALER
                    , :ZIP-CODE    OF DCLDEALER
               FROM   AUTOSALE.DEALER
               WHERE  DEALER_CODE = :DEALER-CODE
                                      OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE DEALER-NAME-TX OF DCLDEALER
                   TO WS-DO-DEALER-NAME
               STRING ADDRESS-LINE1-TX OF DCLDEALER
                      DELIMITED BY '  '
                      ', '
                      DELIMITED BY SIZE
                      CITY-TX OF DCLDEALER
                      DELIMITED BY '  '
                      ', '
                      DELIMITED BY SIZE
                      STATE-CODE OF DCLDEALER
                      DELIMITED BY SIZE
                      ' '
                      DELIMITED BY SIZE
                      ZIP-CODE OF DCLDEALER
                      DELIMITED BY '  '
                      INTO WS-DO-DEALER-ADDR
           END-IF
           .
      *
      ****************************************************************
      *    5000-FETCH-VEHICLE - VEHICLE DESCRIPTION                  *
      ****************************************************************
       5000-FETCH-VEHICLE.
      *
           EXEC SQL
               SELECT V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.STOCK_NUMBER
                    , V.ODOMETER
                    , M.MODEL_NAME
               INTO  :MODEL-YEAR     OF DCLVEHICLE
                    , :MAKE-CODE     OF DCLVEHICLE
                    , :STOCK-NUMBER  OF DCLVEHICLE
                    , :ODOMETER      OF DCLVEHICLE
                    , :MODEL-NAME    OF DCLMODEL-MASTER
               FROM   AUTOSALE.VEHICLE V
                    , AUTOSALE.MODEL_MASTER M
               WHERE  V.VIN = :VIN OF DCLSALES-DEAL
                 AND  M.MODEL_YEAR = V.MODEL_YEAR
                 AND  M.MAKE_CODE  = V.MAKE_CODE
                 AND  M.MODEL_CODE = V.MODEL_CODE
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE MODEL-YEAR OF DCLVEHICLE
                   TO WS-DO-VEH-YEAR
               MOVE MAKE-CODE OF DCLVEHICLE
                   TO WS-DO-VEH-MAKE
               MOVE MODEL-NAME-TX TO WS-DO-VEH-MODEL-NM
               MOVE VIN OF DCLSALES-DEAL
                   TO WS-DO-VEH-VIN
               MOVE STOCK-NUMBER TO WS-DO-VEH-STOCK
               MOVE ODOMETER     TO WS-DO-VEH-ODOM
           END-IF
           .
      *
      ****************************************************************
      *    5500-FETCH-FINANCE-APP - GET FINANCE TYPE AND TERMS       *
      ****************************************************************
       5500-FETCH-FINANCE-APP.
      *
           EXEC SQL
               SELECT FINANCE_ID
                    , FINANCE_TYPE
                    , LENDER_CODE
                    , APP_STATUS
                    , AMOUNT_APPROVED
                    , APR_APPROVED
                    , TERM_MONTHS
                    , MONTHLY_PAYMENT
               INTO  :FINANCE-ID     OF DCLFINANCE-APP
                    , :FINANCE-TYPE  OF DCLFINANCE-APP
                    , :LENDER-CODE   OF DCLFINANCE-APP
                    , :APP-STATUS    OF DCLFINANCE-APP
                    , :AMOUNT-APPROVED OF DCLFINANCE-APP
                    , :APR-APPROVED  OF DCLFINANCE-APP
                    , :TERM-MONTHS   OF DCLFINANCE-APP
                    , :MONTHLY-PAYMENT OF DCLFINANCE-APP
               FROM   AUTOSALE.FINANCE_APP
               WHERE  DEAL_NUMBER = :WS-DI-DEAL-NUMBER
                 AND  APP_STATUS IN ('AP', 'NW')
               ORDER BY CREATED_TS DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE FINANCE-TYPE OF DCLFINANCE-APP
                   TO WS-FINANCE-TYPE-WORK
               MOVE FINANCE-ID OF DCLFINANCE-APP
                   TO WS-FINANCE-ID-WORK
           ELSE
      *        DEFAULT TO CASH IF NO FINANCE APP
               MOVE 'C' TO WS-FINANCE-TYPE-WORK
           END-IF
      *
      *    SET DOCUMENT TITLE
      *
           EVALUATE WS-FINANCE-TYPE-WORK
               WHEN 'L'
                   MOVE 'RETAIL INSTALLMENT CONTRACT'
                       TO WS-DO-DOC-TITLE
               WHEN 'S'
                   MOVE 'MOTOR VEHICLE LEASE AGREEMENT'
                       TO WS-DO-DOC-TITLE
               WHEN 'C'
                   MOVE 'CASH SALE RECEIPT'
                       TO WS-DO-DOC-TITLE
               WHEN OTHER
                   MOVE 'SALES DOCUMENT'
                       TO WS-DO-DOC-TITLE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    6000-BUILD-PRICING - ITEMIZE ALL PRICES                   *
      ****************************************************************
       6000-BUILD-PRICING.
      *
           MOVE VEHICLE-PRICE OF DCLSALES-DEAL
               TO WS-DO-PX-VEH-PRICE
           MOVE TOTAL-OPTIONS  OF DCLSALES-DEAL
               TO WS-DO-PX-OPTIONS
           MOVE DESTINATION-FEE OF DCLSALES-DEAL
               TO WS-DO-PX-DEST
      *
      *    DISCOUNT + REBATES
      *
           COMPUTE WS-TOTAL-DISC =
               DISCOUNT-AMT OF DCLSALES-DEAL
               + REBATES-APPLIED OF DCLSALES-DEAL
           END-COMPUTE
           MOVE WS-TOTAL-DISC TO WS-DO-PX-DISC
      *
      *    NET TRADE
      *
           MOVE NET-TRADE OF DCLSALES-DEAL
               TO WS-DO-PX-TRADE
      *
      *    TAXES
      *
           COMPUTE WS-TOTAL-TAXES =
               STATE-TAX OF DCLSALES-DEAL
               + COUNTY-TAX OF DCLSALES-DEAL
               + CITY-TAX OF DCLSALES-DEAL
           END-COMPUTE
           MOVE WS-TOTAL-TAXES TO WS-DO-PX-TAXES
      *
      *    FEES
      *
           COMPUTE WS-TOTAL-FEES =
               DOC-FEE OF DCLSALES-DEAL
               + TITLE-FEE OF DCLSALES-DEAL
               + REG-FEE OF DCLSALES-DEAL
           END-COMPUTE
           MOVE WS-TOTAL-FEES TO WS-DO-PX-FEES
      *
           MOVE TOTAL-PRICE  OF DCLSALES-DEAL
               TO WS-DO-PX-TOTAL
           MOVE DOWN-PAYMENT  OF DCLSALES-DEAL
               TO WS-DO-PX-DOWN
           MOVE AMOUNT-FINANCED OF DCLSALES-DEAL
               TO WS-DO-PX-FINANCED
           .
      *
      ****************************************************************
      *    7000-BUILD-FINANCE-TERMS - LOAN/LEASE/CASH TERMS          *
      ****************************************************************
       7000-BUILD-FINANCE-TERMS.
      *
           EVALUATE WS-FINANCE-TYPE-WORK
               WHEN 'L'
                   PERFORM 7100-BUILD-LOAN-TERMS
               WHEN 'S'
                   PERFORM 7200-BUILD-LEASE-TERMS
               WHEN 'C'
                   PERFORM 7300-BUILD-CASH-TERMS
           END-EVALUATE
           .
      *
      ****************************************************************
      *    7100-BUILD-LOAN-TERMS                                     *
      ****************************************************************
       7100-BUILD-LOAN-TERMS.
      *
      *    USE APPROVED APR AND TERM TO RECALCULATE
      *
           IF APR-APPROVED OF DCLFINANCE-APP > +0
               MOVE 'CALC' TO WS-LN-FUNCTION
               MOVE AMOUNT-FINANCED OF DCLSALES-DEAL
                   TO WS-LN-PRINCIPAL
               MOVE APR-APPROVED OF DCLFINANCE-APP
                   TO WS-LN-APR
               MOVE TERM-MONTHS OF DCLFINANCE-APP
                   TO WS-LN-TERM-MONTHS
               MOVE SPACES TO WS-LN-DEALER-CODE
               MOVE SPACES TO WS-LN-VIN
      *
               CALL 'COMLONL0' USING WS-LOAN-REQUEST
                                      WS-LOAN-RESULT
      *
               IF WS-LR-RETURN-CODE = +0
                   MOVE APR-APPROVED OF DCLFINANCE-APP
                       TO WS-DO-FT-APR
                   MOVE TERM-MONTHS OF DCLFINANCE-APP
                       TO WS-DO-FT-TERM
                   MOVE WS-LR-MONTHLY-PMT
                       TO WS-DO-FT-MONTHLY
                   MOVE WS-LR-TOTAL-PAYMENTS
                       TO WS-DO-FT-TOT-PMT
                   MOVE WS-LR-TOTAL-INTEREST
                       TO WS-DO-FT-FIN-CHG
               END-IF
           ELSE
      *        USE EXISTING MONTHLY PAYMENT FROM FINANCE APP
               MOVE TERM-MONTHS OF DCLFINANCE-APP
                   TO WS-DO-FT-TERM
               MOVE MONTHLY-PAYMENT OF DCLFINANCE-APP
                   TO WS-DO-FT-MONTHLY
           END-IF
           .
      *
      ****************************************************************
      *    7200-BUILD-LEASE-TERMS                                    *
      ****************************************************************
       7200-BUILD-LEASE-TERMS.
      *
      *    FETCH LEASE TERMS FROM LEASE_TERMS TABLE
      *
           IF WS-FINANCE-ID-WORK NOT = SPACES
               EXEC SQL
                   SELECT RESIDUAL_PCT
                        , RESIDUAL_AMT
                        , MONEY_FACTOR
                        , ADJ_CAP_COST
                        , FINANCE_CHARGE
                        , MONTHLY_TAX
                   INTO  :RESIDUAL-PCT    OF DCLLEASE-TERMS
                        , :RESIDUAL-AMT  OF DCLLEASE-TERMS
                        , :MONEY-FACTOR  OF DCLLEASE-TERMS
                        , :ADJ-CAP-COST  OF DCLLEASE-TERMS
                        , :FINANCE-CHARGE OF DCLLEASE-TERMS
                        , :MONTHLY-TAX   OF DCLLEASE-TERMS
                   FROM   AUTOSALE.LEASE_TERMS
                   WHERE  FINANCE_ID = :WS-FINANCE-ID-WORK
               END-EXEC
      *
               IF SQLCODE = +0
      *            APPROXIMATE APR FROM MONEY FACTOR
                   MOVE TERM-MONTHS OF DCLFINANCE-APP
                       TO WS-DO-FT-TERM
                   MOVE MONTHLY-PAYMENT OF DCLFINANCE-APP
                       TO WS-DO-FT-MONTHLY
                   MOVE FINANCE-CHARGE OF DCLLEASE-TERMS
                       TO WS-DO-FT-FIN-CHG
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    7300-BUILD-CASH-TERMS                                     *
      ****************************************************************
       7300-BUILD-CASH-TERMS.
      *
      *    CASH DEAL - NO FINANCE TERMS TO DISPLAY
      *
           MOVE SPACES TO WS-DO-FIN-HDR
           MOVE 'CASH SALE - NO FINANCING' TO WS-DO-FIN-APR
           MOVE SPACES TO WS-DO-FIN-TERM
           MOVE SPACES TO WS-DO-FIN-PMT
           MOVE SPACES TO WS-DO-FIN-TOTAL
           MOVE SPACES TO WS-DO-FIN-CHARGE
           .
      *
      ****************************************************************
      *    8000-FETCH-PRODUCTS - F&I PRODUCTS FOR DEAL               *
      ****************************************************************
       8000-FETCH-PRODUCTS.
      *
           EXEC SQL
               OPEN CSR_FIN_PRODUCTS
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 8000-EXIT
           END-IF
      *
           MOVE +0 TO WS-PROD-COUNT
      *
           PERFORM UNTIL WS-PROD-COUNT >= +5
               EXEC SQL
                   FETCH CSR_FIN_PRODUCTS
                   INTO  :WS-PR-FETCH-NAME
                       , :WS-PR-FETCH-PRICE
               END-EXEC
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               IF SQLCODE NOT = +0
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-PROD-COUNT
               MOVE WS-PR-FETCH-NAME-TX(1:25)
                   TO WS-DO-PR-NAME(WS-PROD-COUNT)
               MOVE WS-PR-FETCH-PRICE
                   TO WS-DO-PR-PRICE(WS-PROD-COUNT)
      *
           END-PERFORM
      *
           EXEC SQL
               CLOSE CSR_FIN_PRODUCTS
           END-EXEC
      *
           MOVE 'FINANCE DOCUMENTS GENERATED SUCCESSFULLY'
               TO WS-DO-MSG-TEXT
           .
       8000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-DOC-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNDC' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINDOC00                                              *
      ****************************************************************
