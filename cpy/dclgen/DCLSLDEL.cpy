      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.SALES_DEAL)                           *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLSLDEL))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLSALES-DEAL)                                *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.SALES_DEAL TABLE
           ( DEAL_NUMBER      CHAR(10) NOT NULL,
             DEALER_CODE      CHAR(5) NOT NULL,
             CUSTOMER_ID      INTEGER NOT NULL,
             VIN              CHAR(17) NOT NULL,
             SALESPERSON_ID   CHAR(8) NOT NULL,
             SALES_MANAGER_ID CHAR(8),
             DEAL_TYPE        CHAR(1) NOT NULL,
             DEAL_STATUS      CHAR(2) NOT NULL,
             VEHICLE_PRICE    DECIMAL(11,2) NOT NULL,
             TOTAL_OPTIONS    DECIMAL(9,2) NOT NULL,
             DESTINATION_FEE  DECIMAL(7,2) NOT NULL,
             SUBTOTAL         DECIMAL(11,2) NOT NULL,
             TRADE_ALLOW      DECIMAL(11,2) NOT NULL,
             TRADE_PAYOFF     DECIMAL(11,2) NOT NULL,
             NET_TRADE        DECIMAL(11,2) NOT NULL,
             REBATES_APPLIED  DECIMAL(9,2) NOT NULL,
             DISCOUNT_AMT     DECIMAL(9,2) NOT NULL,
             DOC_FEE          DECIMAL(7,2) NOT NULL,
             STATE_TAX        DECIMAL(9,2) NOT NULL,
             COUNTY_TAX       DECIMAL(9,2) NOT NULL,
             CITY_TAX         DECIMAL(9,2) NOT NULL,
             TITLE_FEE        DECIMAL(7,2) NOT NULL,
             REG_FEE          DECIMAL(7,2) NOT NULL,
             TOTAL_PRICE      DECIMAL(11,2) NOT NULL,
             DOWN_PAYMENT     DECIMAL(11,2) NOT NULL,
             AMOUNT_FINANCED  DECIMAL(11,2) NOT NULL,
             FRONT_GROSS      DECIMAL(11,2) NOT NULL,
             BACK_GROSS       DECIMAL(11,2) NOT NULL,
             TOTAL_GROSS      DECIMAL(11,2) NOT NULL,
             DEAL_DATE        DATE,
             DELIVERY_DATE    DATE,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.SALES_DEAL              *
      ******************************************************************
       01  DCLSALES-DEAL.
           10 DEAL-NUMBER       PIC X(10).
           10 DEALER-CODE       PIC X(5).
           10 CUSTOMER-ID       PIC S9(9) COMP.
           10 VIN               PIC X(17).
           10 SALESPERSON-ID    PIC X(8).
           10 SALES-MANAGER-ID  PIC X(8).
           10 DEAL-TYPE         PIC X(1).
           10 DEAL-STATUS       PIC X(2).
           10 VEHICLE-PRICE     PIC S9(9)V9(2) COMP-3.
           10 TOTAL-OPTIONS     PIC S9(7)V9(2) COMP-3.
           10 DESTINATION-FEE   PIC S9(5)V9(2) COMP-3.
           10 SUBTOTAL          PIC S9(9)V9(2) COMP-3.
           10 TRADE-ALLOW       PIC S9(9)V9(2) COMP-3.
           10 TRADE-PAYOFF      PIC S9(9)V9(2) COMP-3.
           10 NET-TRADE         PIC S9(9)V9(2) COMP-3.
           10 REBATES-APPLIED   PIC S9(7)V9(2) COMP-3.
           10 DISCOUNT-AMT      PIC S9(7)V9(2) COMP-3.
           10 DOC-FEE           PIC S9(5)V9(2) COMP-3.
           10 STATE-TAX         PIC S9(7)V9(2) COMP-3.
           10 COUNTY-TAX        PIC S9(7)V9(2) COMP-3.
           10 CITY-TAX          PIC S9(7)V9(2) COMP-3.
           10 TITLE-FEE         PIC S9(5)V9(2) COMP-3.
           10 REG-FEE           PIC S9(5)V9(2) COMP-3.
           10 TOTAL-PRICE       PIC S9(9)V9(2) COMP-3.
           10 DOWN-PAYMENT      PIC S9(9)V9(2) COMP-3.
           10 AMOUNT-FINANCED   PIC S9(9)V9(2) COMP-3.
           10 FRONT-GROSS       PIC S9(9)V9(2) COMP-3.
           10 BACK-GROSS        PIC S9(9)V9(2) COMP-3.
           10 TOTAL-GROSS       PIC S9(9)V9(2) COMP-3.
           10 DEAL-DATE         PIC X(10).
           10 DELIVERY-DATE     PIC X(10).
           10 CREATED-TS        PIC X(26).
           10 UPDATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 33     *
      ******************************************************************
