       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINPRD00.
      ****************************************************************
      * PROGRAM:  FINPRD00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - F&I PRODUCT SELECTION                    *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DISPLAYS MENU OF AVAILABLE F&I PRODUCTS FOR A      *
      *           DEAL. PRODUCTS INCLUDE EXTENDED WARRANTY, GAP,     *
      *           PAINT PROTECTION, FABRIC GUARD, THEFT DETERRENT,   *
      *           MAINTENANCE, TIRE/WHEEL, DENT REPAIR, KEY          *
      *           REPLACEMENT, AND LOJACK.                           *
      *           ALLOWS MULTI-SELECT. CALCULATES TOTAL F&I GROSS.  *
      *           INSERTS FINANCE_PRODUCT RECORDS FOR EACH SELECTED. *
      *           UPDATES SALES_DEAL.BACK_GROSS WITH F&I PROFIT.     *
      *           RECALCULATES TOTAL_GROSS (FRONT + BACK).           *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNPR - F&I PRODUCTS                                *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                       *
      *           COMLGEL0 - AUDIT LOGGING                          *
      *           COMDBEL0 - DB2 ERROR HANDLER                      *
      * TABLES:   AUTOSALE.SALES_DEAL                                *
      *           AUTOSALE.FINANCE_PRODUCT                            *
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
                                          VALUE 'FINPRD00'.
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
           COPY DCLFINPR.
      *
      *    INPUT FIELDS
      *
       01  WS-PRD-INPUT.
           05  WS-PI-DEAL-NUMBER         PIC X(10).
           05  WS-PI-SELECTIONS          PIC X(30).
      *
      *    F&I PRODUCT CATALOG (HARD-CODED FOR IMS/COBOL DEMO)
      *    EACH ENTRY: CODE(3) + NAME(25) + TERM(3) + MILES(6)
      *                + RETAIL(9.99) + COST(9.99) + PROFIT(9.99)
      *
       01  WS-PRODUCT-CATALOG.
           05  FILLER PIC X(72) VALUE
               'EXWExtended Warranty         036012000001995.00000895.00001100.00'.
           05  FILLER PIC X(72) VALUE
               'GAPGAP Insurance             036000000000895.00000325.00000570.00'.
           05  FILLER PIC X(72) VALUE
               'PPTPaint Protection          060000000000599.00000125.00000474.00'.
           05  FILLER PIC X(72) VALUE
               'FBRFabric Protection         060000000000399.00000075.00000324.00'.
           05  FILLER PIC X(72) VALUE
               'THFTheft Deterrent           060000000000695.00000195.00000500.00'.
           05  FILLER PIC X(72) VALUE
               'MNTMaintenance Plan          036050000000799.00000375.00000424.00'.
           05  FILLER PIC X(72) VALUE
               'TIRTire and Wheel            036050000000599.00000185.00000414.00'.
           05  FILLER PIC X(72) VALUE
               'DNTDent Repair               036000000000399.00000095.00000304.00'.
           05  FILLER PIC X(72) VALUE
               'KEYKey Replacement           060000000000299.00000045.00000254.00'.
           05  FILLER PIC X(72) VALUE
               'LOJLoJack GPS Tracking       048000000000995.00000450.00000545.00'.
       01  WS-PRODUCT-TABLE REDEFINES WS-PRODUCT-CATALOG.
           05  WS-PROD-ENTRY             OCCURS 10 TIMES.
               10  WS-PE-CODE            PIC X(03).
               10  WS-PE-NAME            PIC X(25).
               10  WS-PE-TERM            PIC 9(03).
               10  WS-PE-MILES           PIC 9(06).
               10  WS-PE-RETAIL          PIC 9(07)V99.
               10  WS-PE-COST            PIC 9(07)V99.
               10  WS-PE-PROFIT          PIC 9(07)V99.
      *
      *    SELECTION FLAGS
      *
       01  WS-SELECTION-FLAGS.
           05  WS-SF-ENTRY               OCCURS 10 TIMES.
               10  WS-SF-SELECTED        PIC X(01) VALUE 'N'.
                   88  WS-SF-IS-SELECTED              VALUE 'Y'.
      *
      *    TOTALS
      *
       01  WS-TOTALS.
           05  WS-TOT-RETAIL             PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOT-COST              PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-TOT-PROFIT            PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-PRODUCTS-SELECTED     PIC S9(04)    COMP
                                                       VALUE +0.
           05  WS-NEXT-SEQ              PIC S9(04)    COMP
                                                       VALUE +0.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-PRD-OUTPUT.
           05  WS-PO-STATUS-LINE.
               10  WS-PO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-PO-MSG-TEXT       PIC X(70).
           05  WS-PO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-PO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- F&I PRODUCT SELECTION ----       '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-PO-DEAL-LINE.
               10  FILLER               PIC X(06) VALUE 'DEAL: '.
               10  WS-PO-DEAL-NUM       PIC X(10).
               10  FILLER               PIC X(63) VALUE SPACES.
           05  WS-PO-COL-HDR.
               10  FILLER               PIC X(03) VALUE 'SEL'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  FILLER               PIC X(03) VALUE 'COD'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  FILLER               PIC X(25)
                   VALUE 'PRODUCT NAME             '.
               10  FILLER               PIC X(05) VALUE 'TERM '.
               10  FILLER               PIC X(08) VALUE 'MILES   '.
               10  FILLER               PIC X(11)
                   VALUE 'RETAIL     '.
               10  FILLER               PIC X(11)
                   VALUE 'COST       '.
               10  FILLER               PIC X(11)
                   VALUE 'PROFIT     '.
           05  WS-PO-PRODUCT-LINES.
               10  WS-PO-PROD-LINE      OCCURS 10 TIMES.
                   15  WS-PO-PL-SEL     PIC X(01).
                   15  FILLER           PIC X(03) VALUE SPACES.
                   15  WS-PO-PL-CODE    PIC X(03).
                   15  FILLER           PIC X(01) VALUE SPACE.
                   15  WS-PO-PL-NAME    PIC X(25).
                   15  WS-PO-PL-TERM    PIC Z(02)9.
                   15  FILLER           PIC X(01) VALUE SPACE.
                   15  WS-PO-PL-MILES   PIC Z(05)9.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-PO-PL-RETAIL  PIC $Z,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-PO-PL-COST    PIC $Z,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
                   15  WS-PO-PL-PROFIT  PIC $Z,ZZ9.99.
                   15  FILLER           PIC X(02) VALUE SPACES.
           05  WS-PO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-PO-TOTAL-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'PRODUCTS:   '.
               10  WS-PO-NUM-SELECTED   PIC Z(02)9.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(16)
                   VALUE 'TOTAL RETAIL:   '.
               10  WS-PO-TOT-RETAIL     PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(28) VALUE SPACES.
           05  WS-PO-PROFIT-LINE.
               10  FILLER               PIC X(16)
                   VALUE 'TOTAL F&I COST: '.
               10  WS-PO-TOT-COST       PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(18)
                   VALUE 'TOTAL F&I PROFIT: '.
               10  WS-PO-TOT-PROFIT     PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(12) VALUE SPACES.
           05  WS-PO-FILLER             PIC X(79) VALUE SPACES.
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
      *    AUDIT LOG CALL FIELDS
      *
       01  WS-AUD-USER-ID              PIC X(08).
       01  WS-AUD-PROGRAM-ID           PIC X(08) VALUE 'FINPRD00'.
       01  WS-AUD-ACTION-TYPE          PIC X(08).
       01  WS-AUD-TABLE-NAME           PIC X(18).
       01  WS-AUD-KEY-VALUE            PIC X(30).
       01  WS-AUD-OLD-VALUE            PIC X(100).
       01  WS-AUD-NEW-VALUE            PIC X(100).
       01  WS-AUD-RETURN-CODE          PIC S9(04) COMP.
       01  WS-AUD-ERROR-MSG            PIC X(79).
      *
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-PROGRAM-NAME         PIC X(08) VALUE 'FINPRD00'.
       01  WS-DBE-SECTION-NAME         PIC X(30).
       01  WS-DBE-TABLE-NAME           PIC X(18).
       01  WS-DBE-OPERATION            PIC X(08).
       01  WS-DBE-RESULT-AREA.
           05  WS-DBE-RESULT-CODE      PIC S9(04) COMP.
           05  WS-DBE-RESULT-MSG       PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-RETURN-CODE              PIC S9(04) COMP VALUE +0.
       01  WS-IDX                      PIC S9(04) COMP VALUE +0.
       01  WS-SEL-IDX                  PIC S9(04) COMP VALUE +0.
       01  WS-SEL-CODE                 PIC X(03) VALUE SPACES.
       01  WS-FRONT-GROSS-WORK         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
       01  WS-TOTAL-GROSS-WORK         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
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
               PERFORM 4000-VALIDATE-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-BUILD-PRODUCT-DISPLAY
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-PARSE-SELECTIONS
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-PRODUCTS-SELECTED > +0
               PERFORM 7000-INSERT-PRODUCTS
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-PRODUCTS-SELECTED > +0
               PERFORM 8000-UPDATE-DEAL-GROSS
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
           INITIALIZE WS-PRD-OUTPUT
           INITIALIZE WS-PRD-INPUT
           INITIALIZE WS-TOTALS
           INITIALIZE WS-SELECTION-FLAGS
           MOVE 'FINPRD00' TO WS-PO-MSG-ID
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
                   TO WS-PO-MSG-TEXT
           ELSE
               MOVE WS-INP-KEY-DATA(1:10)
                   TO WS-PI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:30)
                   TO WS-PI-SELECTIONS
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-PI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED'
                   TO WS-PO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    4000-VALIDATE-DEAL                                        *
      ****************************************************************
       4000-VALIDATE-DEAL.
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEAL_STATUS
                    , FRONT_GROSS
                    , BACK_GROSS
                    , TOTAL_GROSS
               INTO  :DEAL-NUMBER    OF DCLSALES-DEAL
                    , :DEAL-STATUS   OF DCLSALES-DEAL
                    , :FRONT-GROSS   OF DCLSALES-DEAL
                    , :BACK-GROSS    OF DCLSALES-DEAL
                    , :TOTAL-GROSS   OF DCLSALES-DEAL
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-PI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NOT FOUND' TO WS-PO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE '4000-VALIDATE'  TO WS-DBE-SECTION-NAME
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
                   TO WS-PO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-PI-DEAL-NUMBER TO WS-PO-DEAL-NUM
           MOVE FRONT-GROSS OF DCLSALES-DEAL
               TO WS-FRONT-GROSS-WORK
      *
      *    GET NEXT PRODUCT SEQUENCE
      *
           EXEC SQL
               SELECT COALESCE(MAX(PRODUCT_SEQ), 0) + 1
               INTO   :WS-NEXT-SEQ
               FROM   AUTOSALE.FINANCE_PRODUCT
               WHERE  DEAL_NUMBER = :WS-PI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0 AND SQLCODE NOT = +100
               MOVE +0 TO WS-NEXT-SEQ
           END-IF
           IF WS-NEXT-SEQ = +0
               MOVE +1 TO WS-NEXT-SEQ
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-BUILD-PRODUCT-DISPLAY                                *
      ****************************************************************
       5000-BUILD-PRODUCT-DISPLAY.
      *
           PERFORM VARYING WS-IDX
               FROM +1 BY +1
               UNTIL WS-IDX > +10
      *
               MOVE SPACE TO WS-PO-PL-SEL(WS-IDX)
               MOVE WS-PE-CODE(WS-IDX)
                   TO WS-PO-PL-CODE(WS-IDX)
               MOVE WS-PE-NAME(WS-IDX)
                   TO WS-PO-PL-NAME(WS-IDX)
               MOVE WS-PE-TERM(WS-IDX)
                   TO WS-PO-PL-TERM(WS-IDX)
               MOVE WS-PE-MILES(WS-IDX)
                   TO WS-PO-PL-MILES(WS-IDX)
               MOVE WS-PE-RETAIL(WS-IDX)
                   TO WS-PO-PL-RETAIL(WS-IDX)
               MOVE WS-PE-COST(WS-IDX)
                   TO WS-PO-PL-COST(WS-IDX)
               MOVE WS-PE-PROFIT(WS-IDX)
                   TO WS-PO-PL-PROFIT(WS-IDX)
      *
           END-PERFORM
           .
      *
      ****************************************************************
      *    6000-PARSE-SELECTIONS - PARSE 3-CHAR PRODUCT CODES        *
      *    INPUT FORMAT: "EXW GAP PPT" (SPACE-SEPARATED CODES)       *
      ****************************************************************
       6000-PARSE-SELECTIONS.
      *
           IF WS-PI-SELECTIONS = SPACES
               MOVE 'NO PRODUCTS SELECTED - SHOWING CATALOG ONLY'
                   TO WS-PO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    SCAN THROUGH SELECTION STRING FOR EACH CATALOG PRODUCT
      *
           MOVE +0 TO WS-PRODUCTS-SELECTED
           MOVE +0 TO WS-TOT-RETAIL
           MOVE +0 TO WS-TOT-COST
           MOVE +0 TO WS-TOT-PROFIT
      *
           PERFORM VARYING WS-IDX
               FROM +1 BY +1
               UNTIL WS-IDX > +10
      *
               MOVE WS-PE-CODE(WS-IDX) TO WS-SEL-CODE
      *
      *        SEARCH FOR THIS CODE IN SELECTION STRING
      *
               INSPECT WS-PI-SELECTIONS
                   TALLYING WS-SEL-IDX
                   FOR ALL WS-SEL-CODE
      *
               IF WS-SEL-IDX > +0
                   MOVE 'Y' TO WS-SF-SELECTED(WS-IDX)
                   MOVE '*' TO WS-PO-PL-SEL(WS-IDX)
                   ADD +1 TO WS-PRODUCTS-SELECTED
                   ADD WS-PE-RETAIL(WS-IDX) TO WS-TOT-RETAIL
                   ADD WS-PE-COST(WS-IDX)   TO WS-TOT-COST
                   ADD WS-PE-PROFIT(WS-IDX) TO WS-TOT-PROFIT
               END-IF
      *
               MOVE +0 TO WS-SEL-IDX
      *
           END-PERFORM
      *
      *    FORMAT TOTALS
      *
           MOVE WS-PRODUCTS-SELECTED TO WS-PO-NUM-SELECTED
           MOVE WS-TOT-RETAIL        TO WS-PO-TOT-RETAIL
           MOVE WS-TOT-COST          TO WS-PO-TOT-COST
           MOVE WS-TOT-PROFIT        TO WS-PO-TOT-PROFIT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-INSERT-PRODUCTS - INSERT SELECTED PRODUCTS           *
      ****************************************************************
       7000-INSERT-PRODUCTS.
      *
           PERFORM VARYING WS-IDX
               FROM +1 BY +1
               UNTIL WS-IDX > +10
      *
               IF WS-SF-IS-SELECTED(WS-IDX)
      *
                   MOVE WS-PI-DEAL-NUMBER
                       TO DEAL-NUMBER OF DCLFINANCE-PRODUCT
                   MOVE WS-NEXT-SEQ
                       TO PRODUCT-SEQ
                   MOVE WS-PE-CODE(WS-IDX)
                       TO PRODUCT-TYPE
                   MOVE FUNCTION LENGTH(WS-PE-NAME(WS-IDX))
                       TO PRODUCT-NAME-LN
                   MOVE WS-PE-NAME(WS-IDX)
                       TO PRODUCT-NAME-TX
                   MOVE +0 TO PROVIDER-LN
                   MOVE SPACES TO PROVIDER-TX
                   MOVE WS-PE-TERM(WS-IDX)
                       TO TERM-MONTHS OF DCLFINANCE-PRODUCT
                   MOVE WS-PE-MILES(WS-IDX)
                       TO MILEAGE-LIMIT
                   MOVE WS-PE-RETAIL(WS-IDX)
                       TO RETAIL-PRICE
                   MOVE WS-PE-COST(WS-IDX)
                       TO DEALER-COST
                   MOVE WS-PE-PROFIT(WS-IDX)
                       TO GROSS-PROFIT
      *
                   EXEC SQL
                       INSERT INTO AUTOSALE.FINANCE_PRODUCT
                       ( DEAL_NUMBER
                       , PRODUCT_SEQ
                       , PRODUCT_TYPE
                       , PRODUCT_NAME
                       , PROVIDER
                       , TERM_MONTHS
                       , MILEAGE_LIMIT
                       , RETAIL_PRICE
                       , DEALER_COST
                       , GROSS_PROFIT
                       )
                       VALUES
                       ( :DEAL-NUMBER  OF DCLFINANCE-PRODUCT
                       , :PRODUCT-SEQ
                       , :PRODUCT-TYPE
                       , :PRODUCT-NAME
                       , :PROVIDER
                       , :TERM-MONTHS  OF DCLFINANCE-PRODUCT
                       , :MILEAGE-LIMIT
                       , :RETAIL-PRICE
                       , :DEALER-COST
                       , :GROSS-PROFIT
                       )
                   END-EXEC
      *
                   IF SQLCODE NOT = +0
                       MOVE '7000-INSERT'    TO WS-DBE-SECTION-NAME
                       MOVE 'FINANCE_PRODUCT' TO WS-DBE-TABLE-NAME
                       MOVE 'INSERT'         TO WS-DBE-OPERATION
                       CALL 'COMDBEL0' USING SQLCA
                                              WS-DBE-PROGRAM-NAME
                                              WS-DBE-SECTION-NAME
                                              WS-DBE-TABLE-NAME
                                              WS-DBE-OPERATION
                                              WS-DBE-RESULT-AREA
                       MOVE +16 TO WS-RETURN-CODE
                       MOVE 'DB2 ERROR ON FINANCE_PRODUCT INSERT'
                           TO WS-PO-MSG-TEXT
                       EXIT PERFORM
                   END-IF
      *
                   ADD +1 TO WS-NEXT-SEQ
      *
               END-IF
      *
           END-PERFORM
      *
           IF WS-RETURN-CODE = +0
      *        AUDIT LOG
               MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
               MOVE 'INSERT'       TO WS-AUD-ACTION-TYPE
               MOVE 'FINANCE_PRODUCT' TO WS-AUD-TABLE-NAME
               MOVE WS-PI-DEAL-NUMBER TO WS-AUD-KEY-VALUE
               MOVE SPACES         TO WS-AUD-OLD-VALUE
               STRING 'F&I PRODUCTS ADDED: '
                      WS-PO-NUM-SELECTED
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
               MOVE 'F&I PRODUCTS ADDED SUCCESSFULLY'
                   TO WS-PO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    8000-UPDATE-DEAL-GROSS - UPDATE BACK GROSS AND TOTAL      *
      ****************************************************************
       8000-UPDATE-DEAL-GROSS.
      *
      *    CALCULATE NEW TOTAL GROSS (FRONT + BACK)
      *
           COMPUTE WS-TOTAL-GROSS-WORK =
               WS-FRONT-GROSS-WORK + WS-TOT-PROFIT
           END-COMPUTE
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET BACK_GROSS  = :WS-TOT-PROFIT
                    , TOTAL_GROSS = :WS-TOTAL-GROSS-WORK
                    , UPDATED_TS  = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-PI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '8000-UPDATE'    TO WS-DBE-SECTION-NAME
               MOVE 'SALES_DEAL'     TO WS-DBE-TABLE-NAME
               MOVE 'UPDATE'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING DEAL GROSS'
                   TO WS-PO-MSG-TEXT
           ELSE
               MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
               MOVE 'UPDATE'       TO WS-AUD-ACTION-TYPE
               MOVE 'SALES_DEAL'   TO WS-AUD-TABLE-NAME
               MOVE WS-PI-DEAL-NUMBER TO WS-AUD-KEY-VALUE
               MOVE SPACES         TO WS-AUD-OLD-VALUE
               STRING 'BACK_GROSS=' WS-PO-TOT-PROFIT
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
           END-IF
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-PRD-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNPR' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINPRD00                                              *
      ****************************************************************
