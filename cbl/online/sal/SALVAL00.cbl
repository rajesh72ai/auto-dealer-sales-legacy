       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALVAL00.
      ****************************************************************
      * PROGRAM:    SALVAL00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALV                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLVL00 (VALIDATION RESPONSE)                   *
      *                                                              *
      * PURPOSE:    DEAL VALIDATION. COMPREHENSIVE VALIDATION BEFORE *
      *             APPROVAL. CHECKS:                                *
      *             - CUSTOMER VALID AND CREDIT CHECKED              *
      *             - VEHICLE STILL AVAILABLE (NOT SOLD/TRANSFERRED) *
      *             - PRICING WITHIN DEALER GUIDELINES (MIN MARGIN)  *
      *             - ALL REQUIRED DEAL COMPONENTS PRESENT            *
      *             - TAX CALCULATED                                  *
      *             - TRADE-IN PAYOFF VERIFIED IF APPLICABLE         *
      *             - INCENTIVE ELIGIBILITY STILL VALID              *
      *             RETURNS LIST OF ERRORS OR "DEAL VALID" STATUS.   *
      *             UPDATES SALES_DEAL STATUS TO PA (PENDING APPR).  *
      *                                                              *
      * CALLS:      COMDBEL0 - DB2 ERROR HANDLING                    *
      *             COMMSGL0 - MESSAGE BUILDER                       *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL         (READ/UPDATE)       *
      *             AUTOSALE.CUSTOMER            (READ)              *
      *             AUTOSALE.CREDIT_CHECK        (READ)              *
      *             AUTOSALE.VEHICLE             (READ)              *
      *             AUTOSALE.SYSTEM_USER         (READ)              *
      *             AUTOSALE.SYSTEM_CONFIG       (READ)              *
      *             AUTOSALE.TRADE_IN            (READ)              *
      *             AUTOSALE.INCENTIVE_APPLIED   (READ)              *
      *             AUTOSALE.INCENTIVE_PROGRAM   (READ)              *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALVAL00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
           COPY DCLCRDCK.
           COPY DCLSYSCF.
      *
      *    INPUT FIELDS
      *
       01  WS-VAL-INPUT.
           05  WS-VI-DEAL-NUMBER    PIC X(10).
      *
      *    OUTPUT LAYOUT
      *
       01  WS-VAL-OUTPUT.
           05  WS-VO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- DEAL VALIDATION ----------'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-VO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(29) VALUE SPACES.
           05  WS-VO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-VO-RESULT-LINE.
               10  FILLER           PIC X(08)
                   VALUE 'RESULT: '.
               10  WS-VO-RESULT    PIC X(20).
               10  FILLER           PIC X(51) VALUE SPACES.
           05  WS-VO-BLANK-2       PIC X(79) VALUE SPACES.
           05  WS-VO-ERR-HDR.
               10  FILLER           PIC X(40)
                   VALUE 'VALIDATION ERRORS:
      -               '                        '.
               10  FILLER           PIC X(39) VALUE SPACES.
           05  WS-VO-ERR-DETAIL OCCURS 10 TIMES.
               10  WS-VO-ERR-NUM   PIC Z9.
               10  FILLER           PIC X(02) VALUE '. '.
               10  WS-VO-ERR-MSG   PIC X(72).
               10  FILLER           PIC X(03) VALUE SPACES.
           05  WS-VO-FILLER        PIC X(501) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-VAL-ERROR-COUNT  PIC S9(04) COMP VALUE +0.
           05  WS-DEAL-VALID       PIC X(01) VALUE 'Y'.
               88  WS-IS-VALID               VALUE 'Y'.
               88  WS-NOT-VALID              VALUE 'N'.
           05  WS-CUST-EXISTS      PIC X(01) VALUE 'N'.
           05  WS-VEH-STATUS       PIC X(02) VALUE SPACES.
           05  WS-CREDIT-STATUS    PIC X(02) VALUE SPACES.
           05  WS-CREDIT-SCORE     PIC S9(04) COMP VALUE +0.
           05  WS-SALESPERSON-OK   PIC X(01) VALUE 'N'.
           05  WS-MIN-MARGIN       PIC S9(05)V99 COMP-3 VALUE +0.
           05  WS-MARGIN-PCT       PIC S9(03)V99 COMP-3 VALUE +0.
           05  WS-TRADE-PAYOFF-OK  PIC X(01) VALUE 'N'.
           05  WS-TRADE-COUNT      PIC S9(04) COMP VALUE +0.
           05  WS-INC-INVALID-CT   PIC S9(04) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-CREDIT-SCORE     PIC S9(04) COMP VALUE +0.
           05  NI-MIN-MARGIN       PIC S9(04) COMP VALUE +0.
           05  NI-TRADE-PAYOFF     PIC S9(04) COMP VALUE +0.
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
      *    MESSAGE BUILDER
      *
       01  WS-MSG-FUNCTION         PIC X(04).
       01  WS-MSG-TEXT             PIC X(79).
       01  WS-MSG-SEVERITY        PIC X(04).
       01  WS-MSG-PROGRAM-ID      PIC X(08).
       01  WS-MSG-OUTPUT-AREA     PIC X(256).
       01  WS-MSG-RETURN-CODE     PIC S9(04) COMP.
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
               PERFORM 4000-VALIDATE-CUSTOMER
               PERFORM 4100-VALIDATE-CREDIT
               PERFORM 4200-VALIDATE-VEHICLE
               PERFORM 4300-VALIDATE-SALESPERSON
               PERFORM 4400-VALIDATE-PRICING
               PERFORM 4500-VALIDATE-TAX
               PERFORM 4600-VALIDATE-TRADE
               PERFORM 4700-VALIDATE-INCENTIVES
               PERFORM 4800-VALIDATE-COMPONENTS
           END-IF
      *
      *    IF ALL VALID, UPDATE STATUS TO PA
      *
           IF WS-RETURN-CODE = +0 AND WS-IS-VALID
               PERFORM 5000-UPDATE-STATUS
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
           INITIALIZE WS-VAL-OUTPUT
           MOVE SPACES TO WS-ERROR-MSG
           MOVE +0 TO WS-VAL-ERROR-COUNT
           SET WS-IS-VALID TO TRUE
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
               MOVE 'SALVAL00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-VI-DEAL-NUMBER
           END-IF
           .
      *
      ****************************************************************
      *    3000-LOAD-DEAL                                            *
      ****************************************************************
       3000-LOAD-DEAL.
      *
           IF WS-VI-DEAL-NUMBER = SPACES
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
                    , DEAL_TYPE
                    , DEAL_STATUS
                    , VEHICLE_PRICE
                    , SUBTOTAL
                    , TRADE_ALLOW
                    , TRADE_PAYOFF
                    , NET_TRADE
                    , DISCOUNT_AMT
                    , STATE_TAX
                    , COUNTY_TAX
                    , CITY_TAX
                    , TOTAL_PRICE
                    , FRONT_GROSS
               INTO   :DEAL-NUMBER
                    , :DEALER-CODE   OF DCLSALES-DEAL
                    , :CUSTOMER-ID   OF DCLSALES-DEAL
                    , :VIN           OF DCLSALES-DEAL
                    , :SALESPERSON-ID
                    , :DEAL-TYPE
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :SUBTOTAL
                    , :TRADE-ALLOW
                    , :TRADE-PAYOFF
                    , :NET-TRADE
                    , :DISCOUNT-AMT
                    , :STATE-TAX
                    , :COUNTY-TAX
                    , :CITY-TAX
                    , :TOTAL-PRICE
                    , :FRONT-GROSS
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-VI-DEAL-NUMBER
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
      *    CHECK DEAL STATUS IS ELIGIBLE FOR VALIDATION
      *
           IF DEAL-STATUS NOT = 'WS'
           AND DEAL-STATUS NOT = 'NE'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'DEAL STATUS ' DEAL-STATUS
                      ' - NOT ELIGIBLE FOR VALIDATION'
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-VALIDATE-CUSTOMER                                    *
      ****************************************************************
       4000-VALIDATE-CUSTOMER.
      *
           EXEC SQL
               SELECT 'Y'
               INTO   :WS-CUST-EXISTS
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID
                    = :CUSTOMER-ID OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               PERFORM 4900-ADD-ERROR-CUST
           END-IF
           .
       4900-ADD-ERROR-CUST.
           ADD +1 TO WS-VAL-ERROR-COUNT
           SET WS-NOT-VALID TO TRUE
           IF WS-VAL-ERROR-COUNT <= +10
               MOVE WS-VAL-ERROR-COUNT
                   TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
               MOVE 'CUSTOMER NOT FOUND OR INVALID'
                   TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
           END-IF
           .
      *
      ****************************************************************
      *    4100-VALIDATE-CREDIT                                      *
      ****************************************************************
       4100-VALIDATE-CREDIT.
      *
      *    CHECK IF DEAL TYPE REQUIRES CREDIT (NOT CASH/WHOLESALE)
      *
           IF DEAL-TYPE = 'W'
               GO TO 4100-EXIT
           END-IF
      *
           EXEC SQL
               SELECT STATUS
                    , CREDIT_SCORE
               INTO   :WS-CREDIT-STATUS
                    , :WS-CREDIT-SCORE :NI-CREDIT-SCORE
               FROM   AUTOSALE.CREDIT_CHECK
               WHERE  CUSTOMER_ID
                    = :CUSTOMER-ID OF DCLSALES-DEAL
                 AND  STATUS = 'AP'
                 AND  EXPIRY_DATE >= CURRENT DATE
               ORDER BY REQUEST_TS DESC
               FETCH FIRST 1 ROWS ONLY
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'NO APPROVED CREDIT CHECK ON FILE'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4200-VALIDATE-VEHICLE                                     *
      ****************************************************************
       4200-VALIDATE-VEHICLE.
      *
           EXEC SQL
               SELECT VEHICLE_STATUS
               INTO   :WS-VEH-STATUS
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :VIN OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'VEHICLE NOT FOUND'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
               GO TO 4200-EXIT
           END-IF
      *
      *    VEHICLE MUST STILL BE AVAILABLE
      *
           IF WS-VEH-STATUS NOT = 'AV'
           AND WS-VEH-STATUS NOT = 'HD'
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   STRING 'VEHICLE STATUS IS ' WS-VEH-STATUS
                          ' - NOT AVAILABLE FOR SALE'
                          DELIMITED BY SIZE
                          INTO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
       4200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4300-VALIDATE-SALESPERSON                                 *
      ****************************************************************
       4300-VALIDATE-SALESPERSON.
      *
           EXEC SQL
               SELECT 'Y'
               INTO   :WS-SALESPERSON-OK
               FROM   AUTOSALE.SYSTEM_USER
               WHERE  USER_ID = :SALESPERSON-ID
                 AND  ACTIVE_FLAG = 'Y'
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'SALESPERSON NOT FOUND OR INACTIVE'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4400-VALIDATE-PRICING - CHECK MIN MARGIN FROM CONFIG      *
      ****************************************************************
       4400-VALIDATE-PRICING.
      *
      *    GET MIN MARGIN THRESHOLD FROM SYSTEM_CONFIG
      *
           EXEC SQL
               SELECT CONFIG_VALUE
               INTO   :CONFIG-VALUE
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_KEY = 'MIN_FRONT_GROSS'
           END-EXEC
      *
           IF SQLCODE = +0
               COMPUTE WS-MIN-MARGIN =
                   FUNCTION NUMVAL(CONFIG-VALUE-TX(
                       1:CONFIG-VALUE-LN))
           ELSE
               MOVE -500.00 TO WS-MIN-MARGIN
           END-IF
      *
      *    CHECK FRONT GROSS AGAINST MINIMUM
      *
           IF FRONT-GROSS < WS-MIN-MARGIN
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'FRONT GROSS BELOW MINIMUM DEALER GUIDELINE'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
      *
      *    CHECK TOTAL PRICE IS POSITIVE
      *
           IF TOTAL-PRICE <= +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'TOTAL PRICE MUST BE GREATER THAN ZERO'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4500-VALIDATE-TAX                                         *
      ****************************************************************
       4500-VALIDATE-TAX.
      *
      *    ENSURE TAX HAS BEEN CALCULATED
      *
           IF STATE-TAX = +0 AND COUNTY-TAX = +0
           AND CITY-TAX = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'TAX HAS NOT BEEN CALCULATED FOR THIS DEAL'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4600-VALIDATE-TRADE - VERIFY TRADE IF PRESENT             *
      ****************************************************************
       4600-VALIDATE-TRADE.
      *
      *    ONLY VALIDATE IF DEAL HAS TRADE FIGURES
      *
           IF TRADE-ALLOW = +0
               GO TO 4600-EXIT
           END-IF
      *
      *    CHECK TRADE_IN RECORD EXISTS
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-TRADE-COUNT
               FROM   AUTOSALE.TRADE_IN
               WHERE  DEAL_NUMBER = :WS-VI-DEAL-NUMBER
           END-EXEC
      *
           IF WS-TRADE-COUNT = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'TRADE ALLOWANCE SET BUT NO TRADE RECORD'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
      *
      *    IF PAYOFF EXISTS, VERIFY IT MATCHES DEAL
      *
           IF TRADE-PAYOFF > +0
               EXEC SQL
                   SELECT 'Y'
                   INTO   :WS-TRADE-PAYOFF-OK
                   FROM   AUTOSALE.TRADE_IN
                   WHERE  DEAL_NUMBER = :WS-VI-DEAL-NUMBER
                     AND  PAYOFF_AMT = :TRADE-PAYOFF
                   FETCH FIRST 1 ROWS ONLY
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   ADD +1 TO WS-VAL-ERROR-COUNT
                   SET WS-NOT-VALID TO TRUE
                   IF WS-VAL-ERROR-COUNT <= +10
                       MOVE WS-VAL-ERROR-COUNT
                         TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                       MOVE 'TRADE PAYOFF DOES NOT MATCH RECORD'
                         TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
                   END-IF
               END-IF
           END-IF
           .
       4600-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4700-VALIDATE-INCENTIVES                                  *
      ****************************************************************
       4700-VALIDATE-INCENTIVES.
      *
      *    CHECK THAT ALL APPLIED INCENTIVES ARE STILL VALID
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-INC-INVALID-CT
               FROM   AUTOSALE.INCENTIVE_APPLIED A
               JOIN   AUTOSALE.INCENTIVE_PROGRAM P
                 ON   A.INCENTIVE_ID = P.INCENTIVE_ID
               WHERE  A.DEAL_NUMBER = :WS-VI-DEAL-NUMBER
                 AND  (P.ACTIVE_FLAG = 'N'
                    OR CURRENT DATE NOT BETWEEN
                       P.START_DATE AND P.END_DATE)
           END-EXEC
      *
           IF WS-INC-INVALID-CT > +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'ONE OR MORE APPLIED INCENTIVES NO LONGER '
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4800-VALIDATE-COMPONENTS - ALL REQUIRED FIELDS            *
      ****************************************************************
       4800-VALIDATE-COMPONENTS.
      *
           IF VIN OF DCLSALES-DEAL = SPACES
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'VEHICLE VIN IS MISSING FROM DEAL'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
      *
           IF CUSTOMER-ID OF DCLSALES-DEAL = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'CUSTOMER ID IS MISSING FROM DEAL'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
      *
           IF SALESPERSON-ID = SPACES
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'SALESPERSON ID IS MISSING FROM DEAL'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
      *
           IF VEHICLE-PRICE = +0
               ADD +1 TO WS-VAL-ERROR-COUNT
               SET WS-NOT-VALID TO TRUE
               IF WS-VAL-ERROR-COUNT <= +10
                   MOVE WS-VAL-ERROR-COUNT
                       TO WS-VO-ERR-NUM(WS-VAL-ERROR-COUNT)
                   MOVE 'VEHICLE PRICE IS ZERO'
                       TO WS-VO-ERR-MSG(WS-VAL-ERROR-COUNT)
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    5000-UPDATE-STATUS - SET DEAL TO PENDING APPROVAL         *
      ****************************************************************
       5000-UPDATE-STATUS.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS = 'PA'
                    , UPDATED_TS  = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-VI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '5000-UPDATE-STATUS' TO WS-DBE-PARAGRAPH
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
      *    8000-FORMAT-OUTPUT                                        *
      ****************************************************************
       8000-FORMAT-OUTPUT.
      *
           IF WS-RETURN-CODE > +4
               MOVE WS-MODULE-ID TO WS-OUT-MSG-ID
               MOVE WS-ERROR-MSG TO WS-OUT-MSG-TEXT
               GO TO 8000-EXIT
           END-IF
      *
           MOVE WS-MODULE-ID TO WS-OUT-MSG-ID
           MOVE WS-VI-DEAL-NUMBER TO WS-VO-DEAL-NUM
      *
           IF WS-IS-VALID
               MOVE 'DEAL VALID - STATUS SET TO PENDING APPROVAL'
                   TO WS-OUT-MSG-TEXT
               MOVE 'DEAL VALID' TO WS-VO-RESULT
           ELSE
               STRING 'VALIDATION FAILED - '
                      WS-VAL-ERROR-COUNT ' ERROR(S) FOUND'
                      DELIMITED BY SIZE
                      INTO WS-OUT-MSG-TEXT
               MOVE 'VALIDATION FAILED' TO WS-VO-RESULT
           END-IF
      *
           MOVE WS-VAL-OUTPUT TO WS-OUT-BODY
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
      * END OF SALVAL00                                              *
      ****************************************************************
