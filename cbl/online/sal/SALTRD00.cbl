       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALTRD00.
      ****************************************************************
      * PROGRAM:    SALTRD00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALT                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLTD00 (TRADE-IN RESPONSE)                     *
      *                                                              *
      * PURPOSE:    TRADE-IN VEHICLE EVALUATION. CAPTURES TRADE      *
      *             VEHICLE INFO (VIN, YEAR, MAKE, MODEL, COLOR,     *
      *             ODOMETER, CONDITION). IF TRADE VIN PROVIDED,     *
      *             VALIDATES AND DECODES VIA COMVALD0/COMVINL0.     *
      *             CALCULATES ACV BASED ON CONDITION CODE:          *
      *               E=100%, G=85%, F=70%, P=55% OF BASE.           *
      *             ALLOWS OVER-ALLOWANCE. CAPTURES PAYOFF INFO      *
      *             (AMOUNT, BANK, ACCOUNT). INSERTS TRADE_IN,       *
      *             RECALCULATES DEAL NET TRADE AND AMOUNT FINANCED. *
      *                                                              *
      * CALLS:      COMVALD0 - VIN VALIDATION                        *
      *             COMVINL0 - VIN DECODE                            *
      *             COMFMTL0 - CURRENCY FORMATTING                   *
      *             COMLGEL0 - AUDIT LOG ENTRY                       *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *                                                              *
      * TABLES:     AUTOSALE.TRADE_IN      (INSERT)                  *
      *             AUTOSALE.SALES_DEAL    (READ/UPDATE)             *
      *             AUTOSALE.PRICE_MASTER  (READ - BASE VALUE)       *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALTRD00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
           COPY DCLTRDEIN.
           COPY DCLPRICE.
      *
      *    INPUT FIELDS
      *
       01  WS-TRADE-INPUT.
           05  WS-TI-DEAL-NUMBER    PIC X(10).
           05  WS-TI-TRADE-VIN     PIC X(17).
           05  WS-TI-YEAR          PIC X(04).
           05  WS-TI-MAKE          PIC X(20).
           05  WS-TI-MODEL         PIC X(30).
           05  WS-TI-COLOR         PIC X(15).
           05  WS-TI-ODOMETER      PIC X(07).
           05  WS-TI-CONDITION     PIC X(01).
               88  WS-TI-COND-EXCELLENT     VALUE 'E'.
               88  WS-TI-COND-GOOD          VALUE 'G'.
               88  WS-TI-COND-FAIR          VALUE 'F'.
               88  WS-TI-COND-POOR          VALUE 'P'.
           05  WS-TI-OVER-ALLOW    PIC X(10).
           05  WS-TI-PAYOFF-AMT    PIC X(12).
           05  WS-TI-PAYOFF-BANK   PIC X(40).
           05  WS-TI-PAYOFF-ACCT   PIC X(20).
      *
      *    OUTPUT LAYOUT
      *
       01  WS-TRADE-OUTPUT.
           05  WS-TO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- TRADE-IN EVALUATION ------'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-TO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(29) VALUE SPACES.
           05  WS-TO-VEH-LINE.
               10  FILLER           PIC X(07)
                   VALUE 'TRADE: '.
               10  WS-TO-YEAR      PIC 9(04).
               10  FILLER           PIC X(01) VALUE SPACE.
               10  WS-TO-MAKE      PIC X(20).
               10  FILLER           PIC X(01) VALUE SPACE.
               10  WS-TO-MODEL     PIC X(30).
               10  FILLER           PIC X(16) VALUE SPACES.
           05  WS-TO-VIN-LINE.
               10  FILLER           PIC X(06) VALUE 'VIN:  '.
               10  WS-TO-VIN       PIC X(17).
               10  FILLER           PIC X(07) VALUE '  ODO: '.
               10  WS-TO-ODOM      PIC ZZZ,ZZ9.
               10  FILLER           PIC X(07) VALUE '  COND:'.
               10  WS-TO-COND      PIC X(01).
               10  FILLER           PIC X(34) VALUE SPACES.
           05  WS-TO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-TO-BASE-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'BASE VALUE:           '.
               10  WS-TO-BASE-VAL  PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-TO-COND-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'CONDITION ADJUST:     '.
               10  WS-TO-COND-ADJ  PIC ZZ9.
               10  FILLER           PIC X(01) VALUE '%'.
               10  FILLER           PIC X(53) VALUE SPACES.
           05  WS-TO-ACV-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'ACV (ACTUAL CASH VAL):'.
               10  WS-TO-ACV       PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-TO-ALLOW-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'ALLOWANCE:            '.
               10  WS-TO-ALLOWANCE PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-TO-OVER-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'OVER ALLOWANCE:       '.
               10  WS-TO-OVER-AMT  PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-TO-PAYOFF-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'PAYOFF AMOUNT:        '.
               10  WS-TO-PAYOFF    PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-TO-NET-LINE.
               10  FILLER           PIC X(22)
                   VALUE '*** NET TRADE:        '.
               10  WS-TO-NET-TRADE PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(42) VALUE SPACES.
           05  WS-TO-BANK-LINE.
               10  FILLER           PIC X(06) VALUE 'BANK: '.
               10  WS-TO-BANK      PIC X(40).
               10  FILLER           PIC X(06) VALUE ' ACCT:'.
               10  WS-TO-ACCT      PIC X(20).
               10  FILLER           PIC X(07) VALUE SPACES.
           05  WS-TO-FILLER        PIC X(790) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR              VALUE 'Y'.
               88  WS-NO-ERROR               VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-TRADE-YEAR-NUM   PIC S9(04) COMP VALUE +0.
           05  WS-ODOM-NUM         PIC S9(09) COMP VALUE +0.
           05  WS-OVER-ALLOW-NUM   PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-PAYOFF-NUM       PIC S9(09)V99 COMP-3 VALUE +0.
      *
      *    ACV CALCULATION FIELDS
      *
       01  WS-ACV-CALC.
           05  WS-AC-BASE-VALUE    PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-AC-COND-PCT      PIC S9(03) COMP VALUE +0.
           05  WS-AC-ACV           PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-AC-ALLOWANCE     PIC S9(09)V99 COMP-3 VALUE +0.
           05  WS-AC-NET-TRADE     PIC S9(09)V99 COMP-3 VALUE +0.
      *
      *    VIN VALIDATION CALL FIELDS (COMVALD0)
      *
       01  WS-VIN-VALID-INPUT       PIC X(17).
       01  WS-VIN-VALID-RC          PIC S9(04) COMP VALUE +0.
       01  WS-VIN-VALID-MSG         PIC X(50).
       01  WS-VIN-DECODED.
           05  WS-VD-WMI           PIC X(03).
           05  WS-VD-VDS           PIC X(05).
           05  WS-VD-CHECK-DIGIT   PIC X(01).
           05  WS-VD-VIS           PIC X(08).
           05  WS-VD-YEAR-CODE     PIC X(01).
           05  WS-VD-PLANT-CODE    PIC X(01).
           05  WS-VD-SEQ-NUM       PIC X(06).
           05  WS-VD-MANUFACTURER  PIC X(30).
           05  WS-VD-MODEL-YEAR    PIC 9(04).
           05  WS-VD-ASSEMBLY      PIC X(30).
      *
      *    VIN DECODE CALL FIELDS (COMVINL0)
      *
       01  WS-VDEC-INPUT            PIC X(17).
       01  WS-VDEC-OUTPUT.
           05  WS-VDEC-YEAR        PIC S9(04) COMP.
           05  WS-VDEC-MAKE        PIC X(20).
           05  WS-VDEC-MODEL       PIC X(30).
           05  WS-VDEC-BODY        PIC X(20).
           05  WS-VDEC-ENGINE      PIC X(20).
       01  WS-VDEC-RC               PIC S9(04) COMP.
       01  WS-VDEC-MSG              PIC X(50).
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
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-TRADE-VIN        PIC S9(04) COMP VALUE +0.
           05  NI-COLOR            PIC S9(04) COMP VALUE +0.
           05  NI-PAYOFF-BANK      PIC S9(04) COMP VALUE +0.
           05  NI-PAYOFF-ACCT      PIC S9(04) COMP VALUE +0.
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
               PERFORM 3500-VALIDATE-TRADE-INPUT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4000-VALIDATE-TRADE-VIN
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-CALCULATE-ACV
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-INSERT-TRADE-IN
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7000-UPDATE-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 7500-WRITE-AUDIT-LOG
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
           SET WS-NO-ERROR TO TRUE
           INITIALIZE WS-TRADE-OUTPUT
           INITIALIZE WS-ACV-CALC
           MOVE SPACES TO WS-ERROR-MSG
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
               MOVE 'SALTRD00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-TI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:17)  TO WS-TI-TRADE-VIN
               MOVE WS-INP-BODY(18:4)  TO WS-TI-YEAR
               MOVE WS-INP-BODY(22:20) TO WS-TI-MAKE
               MOVE WS-INP-BODY(42:30) TO WS-TI-MODEL
               MOVE WS-INP-BODY(72:15) TO WS-TI-COLOR
               MOVE WS-INP-BODY(87:7)  TO WS-TI-ODOMETER
               MOVE WS-INP-BODY(94:1)  TO WS-TI-CONDITION
               MOVE WS-INP-BODY(95:10) TO WS-TI-OVER-ALLOW
               MOVE WS-INP-BODY(105:12) TO WS-TI-PAYOFF-AMT
               MOVE WS-INP-BODY(117:40) TO WS-TI-PAYOFF-BANK
               MOVE WS-INP-BODY(157:20) TO WS-TI-PAYOFF-ACCT
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-DEAL - VERIFY DEAL EXISTS                   *
      ****************************************************************
       3000-VALIDATE-DEAL.
      *
           IF WS-TI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEAL_STATUS
                    , VEHICLE_PRICE
                    , SUBTOTAL
                    , TRADE_ALLOW
                    , TRADE_PAYOFF
                    , NET_TRADE
                    , TOTAL_PRICE
                    , DOWN_PAYMENT
                    , AMOUNT_FINANCED
               INTO   :DEAL-NUMBER
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :SUBTOTAL
                    , :TRADE-ALLOW
                    , :TRADE-PAYOFF
                    , :NET-TRADE
                    , :TOTAL-PRICE
                    , :DOWN-PAYMENT
                    , :AMOUNT-FINANCED
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-TI-DEAL-NUMBER
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
      *    DEAL MUST BE OPEN (WS, NE, OR PA STATUS)
      *
           IF DEAL-STATUS NOT = 'WS'
           AND DEAL-STATUS NOT = 'NE'
           AND DEAL-STATUS NOT = 'PA'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'DEAL STATUS ' DEAL-STATUS
                      ' - NOT OPEN FOR TRADE-IN'
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-VALIDATE-TRADE-INPUT                                 *
      ****************************************************************
       3500-VALIDATE-TRADE-INPUT.
      *
           IF WS-TI-YEAR = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRADE VEHICLE YEAR IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
           COMPUTE WS-TRADE-YEAR-NUM =
               FUNCTION NUMVAL(WS-TI-YEAR)
      *
           IF WS-TRADE-YEAR-NUM < 1950
           OR WS-TRADE-YEAR-NUM > 2027
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRADE YEAR OUT OF VALID RANGE'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
           IF WS-TI-MAKE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRADE MAKE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
           IF WS-TI-MODEL = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'TRADE MODEL IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
           IF WS-TI-ODOMETER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ODOMETER READING IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
           COMPUTE WS-ODOM-NUM =
               FUNCTION NUMVAL(WS-TI-ODOMETER)
      *
           IF WS-ODOM-NUM < +0 OR WS-ODOM-NUM > +500000
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ODOMETER VALUE OUT OF RANGE'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
      *    VALIDATE CONDITION CODE
      *
           IF NOT WS-TI-COND-EXCELLENT
           AND NOT WS-TI-COND-GOOD
           AND NOT WS-TI-COND-FAIR
           AND NOT WS-TI-COND-POOR
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CONDITION CODE MUST BE E, G, F, OR P'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
      *    PARSE OVER-ALLOWANCE
      *
           IF WS-TI-OVER-ALLOW NOT = SPACES
               COMPUTE WS-OVER-ALLOW-NUM =
                   FUNCTION NUMVAL(WS-TI-OVER-ALLOW)
           ELSE
               MOVE +0 TO WS-OVER-ALLOW-NUM
           END-IF
      *
      *    PARSE PAYOFF AMOUNT
      *
           IF WS-TI-PAYOFF-AMT NOT = SPACES
               COMPUTE WS-PAYOFF-NUM =
                   FUNCTION NUMVAL(WS-TI-PAYOFF-AMT)
           ELSE
               MOVE +0 TO WS-PAYOFF-NUM
           END-IF
           .
       3500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-VALIDATE-TRADE-VIN - VALIDATE/DECODE IF PROVIDED     *
      ****************************************************************
       4000-VALIDATE-TRADE-VIN.
      *
           IF WS-TI-TRADE-VIN = SPACES
               GO TO 4000-EXIT
           END-IF
      *
      *    VALIDATE VIN FORMAT
      *
           MOVE WS-TI-TRADE-VIN TO WS-VIN-VALID-INPUT
           CALL 'COMVALD0' USING WS-VIN-VALID-INPUT
                                 WS-VIN-VALID-RC
                                 WS-VIN-VALID-MSG
                                 WS-VIN-DECODED
      *
           IF WS-VIN-VALID-RC NOT = +0
               MOVE +4 TO WS-RETURN-CODE
               MOVE WS-VIN-VALID-MSG TO WS-ERROR-MSG
               MOVE +0 TO WS-RETURN-CODE
      *        WARNING ONLY - CONTINUE WITH TRADE PROCESSING
           END-IF
      *
      *    DECODE VIN FOR DETAILS
      *
           MOVE WS-TI-TRADE-VIN TO WS-VDEC-INPUT
           CALL 'COMVINL0' USING WS-VDEC-INPUT
                                 WS-VDEC-OUTPUT
                                 WS-VDEC-RC
                                 WS-VDEC-MSG
      *
           IF WS-VDEC-RC = +0
      *        USE DECODED DATA TO SUPPLEMENT/OVERRIDE INPUT
               IF WS-TI-MAKE = SPACES
                   MOVE WS-VDEC-MAKE TO WS-TI-MAKE
               END-IF
               IF WS-TI-MODEL = SPACES
                   MOVE WS-VDEC-MODEL TO WS-TI-MODEL
               END-IF
               IF WS-TRADE-YEAR-NUM = +0
                   MOVE WS-VDEC-YEAR TO WS-TRADE-YEAR-NUM
               END-IF
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-CALCULATE-ACV - ACTUAL CASH VALUE BASED ON CONDITION *
      ****************************************************************
       5000-CALCULATE-ACV.
      *
      *    ATTEMPT TO FIND BASE VALUE FROM PRICE_MASTER
      *    (USE AS ROUGH TRADE-IN GUIDE - 40% OF MSRP AS BASE)
      *
           EXEC SQL
               SELECT MSRP
               INTO   :MSRP
               FROM   AUTOSALE.PRICE_MASTER
               WHERE  MODEL_YEAR = :WS-TRADE-YEAR-NUM
                 AND  EFFECTIVE_DATE <= CURRENT DATE
                 AND  (EXPIRY_DATE IS NULL
                    OR EXPIRY_DATE >= CURRENT DATE)
               FETCH FIRST 1 ROWS ONLY
           END-EXEC
      *
           IF SQLCODE = +0
      *        BASE VALUE = 40% OF ORIGINAL MSRP (ROUGH GUIDE)
               COMPUTE WS-AC-BASE-VALUE = MSRP * 0.40
           ELSE
      *        FALLBACK: USE A FLAT $10,000 BASE IF NO PRICE DATA
               MOVE +10000.00 TO WS-AC-BASE-VALUE
           END-IF
      *
      *    APPLY CONDITION PERCENTAGE
      *
           EVALUATE TRUE
               WHEN WS-TI-COND-EXCELLENT
                   MOVE +100 TO WS-AC-COND-PCT
               WHEN WS-TI-COND-GOOD
                   MOVE +85 TO WS-AC-COND-PCT
               WHEN WS-TI-COND-FAIR
                   MOVE +70 TO WS-AC-COND-PCT
               WHEN WS-TI-COND-POOR
                   MOVE +55 TO WS-AC-COND-PCT
               WHEN OTHER
                   MOVE +70 TO WS-AC-COND-PCT
           END-EVALUATE
      *
      *    ACV = BASE VALUE * CONDITION PERCENTAGE
      *
           COMPUTE WS-AC-ACV =
               WS-AC-BASE-VALUE * WS-AC-COND-PCT / 100
      *
      *    ALLOWANCE = ACV + OVER-ALLOWANCE
      *
           COMPUTE WS-AC-ALLOWANCE =
               WS-AC-ACV + WS-OVER-ALLOW-NUM
      *
      *    NET TRADE = ALLOWANCE - PAYOFF
      *
           COMPUTE WS-AC-NET-TRADE =
               WS-AC-ALLOWANCE - WS-PAYOFF-NUM
           .
      *
      ****************************************************************
      *    6000-INSERT-TRADE-IN - WRITE TRADE_IN RECORD              *
      ****************************************************************
       6000-INSERT-TRADE-IN.
      *
      *    SET NULL INDICATORS
      *
           IF WS-TI-TRADE-VIN = SPACES
               MOVE -1 TO NI-TRADE-VIN
           ELSE
               MOVE +0 TO NI-TRADE-VIN
           END-IF
      *
           IF WS-TI-COLOR = SPACES
               MOVE -1 TO NI-COLOR
           ELSE
               MOVE +0 TO NI-COLOR
           END-IF
      *
           IF WS-TI-PAYOFF-BANK = SPACES
               MOVE -1 TO NI-PAYOFF-BANK
           ELSE
               MOVE +0 TO NI-PAYOFF-BANK
           END-IF
      *
           IF WS-TI-PAYOFF-ACCT = SPACES
               MOVE -1 TO NI-PAYOFF-ACCT
           ELSE
               MOVE +0 TO NI-PAYOFF-ACCT
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.TRADE_IN
               ( TRADE_ID
               , DEAL_NUMBER
               , VIN
               , TRADE_YEAR
               , TRADE_MAKE
               , TRADE_MODEL
               , TRADE_COLOR
               , ODOMETER
               , CONDITION_CODE
               , ACV_AMOUNT
               , ALLOWANCE_AMT
               , OVER_ALLOW
               , PAYOFF_AMT
               , PAYOFF_BANK
               , PAYOFF_ACCT
               , APPRAISED_BY
               , APPRAISED_TS
               )
               VALUES
               ( DEFAULT
               , :WS-TI-DEAL-NUMBER
               , :WS-TI-TRADE-VIN    :NI-TRADE-VIN
               , :WS-TRADE-YEAR-NUM
               , :WS-TI-MAKE
               , :WS-TI-MODEL
               , :WS-TI-COLOR        :NI-COLOR
               , :WS-ODOM-NUM
               , :WS-TI-CONDITION
               , :WS-AC-ACV
               , :WS-AC-ALLOWANCE
               , :WS-OVER-ALLOW-NUM
               , :WS-PAYOFF-NUM
               , :WS-TI-PAYOFF-BANK  :NI-PAYOFF-BANK
               , :WS-TI-PAYOFF-ACCT  :NI-PAYOFF-ACCT
               , :IO-PCB-USER-ID
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '6000-INSERT-TRADE-IN' TO WS-DBE-PARAGRAPH
               MOVE SQLCODE TO WS-DBE-SQLCODE
               MOVE SQLERRMC TO WS-DBE-SQLERRM
               MOVE 'TRADE_IN' TO WS-DBE-TABLE-NAME
               MOVE 'INSERT' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING WS-DBE-REQUEST
                                     WS-DBE-RESULT
               MOVE WS-DBE-RETURN-MSG TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    7000-UPDATE-DEAL - RECALCULATE DEAL WITH TRADE FIGURES    *
      ****************************************************************
       7000-UPDATE-DEAL.
      *
      *    RECALCULATE: NET TRADE = ALLOWANCE - PAYOFF
      *    ADJUST AMOUNT FINANCED
      *
           COMPUTE WS-AC-NET-TRADE =
               WS-AC-ALLOWANCE - WS-PAYOFF-NUM
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET TRADE_ALLOW    = :WS-AC-ALLOWANCE
                    , TRADE_PAYOFF   = :WS-PAYOFF-NUM
                    , NET_TRADE      = :WS-AC-NET-TRADE
                    , TOTAL_PRICE    = SUBTOTAL
                                     - DISCOUNT_AMT
                                     - REBATES_APPLIED
                                     - :WS-AC-NET-TRADE
                                     + STATE_TAX
                                     + COUNTY_TAX
                                     + CITY_TAX
                                     + DOC_FEE
                                     + TITLE_FEE
                                     + REG_FEE
                    , AMOUNT_FINANCED = SUBTOTAL
                                     - DISCOUNT_AMT
                                     - REBATES_APPLIED
                                     - :WS-AC-NET-TRADE
                                     + STATE_TAX
                                     + COUNTY_TAX
                                     + CITY_TAX
                                     + DOC_FEE
                                     + TITLE_FEE
                                     + REG_FEE
                                     - DOWN_PAYMENT
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-TI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING DEAL WITH TRADE'
                   TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    7500-WRITE-AUDIT-LOG                                      *
      ****************************************************************
       7500-WRITE-AUDIT-LOG.
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'TRADE   '         TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID     TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-TI-DEAL-NUMBER  TO WS-LR-ENTITY-KEY
           STRING 'TRADE-IN ADDED: DEAL ' WS-TI-DEAL-NUMBER
                  ' ALLOW=' WS-TI-OVER-ALLOW
                  ' PAYOFF=' WS-TI-PAYOFF-AMT
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
           MOVE 'TRADE-IN EVALUATED AND APPLIED TO DEAL'
               TO WS-OUT-MSG-TEXT
      *
           MOVE WS-TI-DEAL-NUMBER TO WS-TO-DEAL-NUM
           MOVE WS-TRADE-YEAR-NUM TO WS-TO-YEAR
           MOVE WS-TI-MAKE        TO WS-TO-MAKE
           MOVE WS-TI-MODEL       TO WS-TO-MODEL
           MOVE WS-TI-TRADE-VIN   TO WS-TO-VIN
           MOVE WS-ODOM-NUM       TO WS-TO-ODOM
           MOVE WS-TI-CONDITION   TO WS-TO-COND
      *
           MOVE WS-AC-BASE-VALUE  TO WS-TO-BASE-VAL
           MOVE WS-AC-COND-PCT    TO WS-TO-COND-ADJ
           MOVE WS-AC-ACV         TO WS-TO-ACV
           MOVE WS-AC-ALLOWANCE   TO WS-TO-ALLOWANCE
           MOVE WS-OVER-ALLOW-NUM TO WS-TO-OVER-AMT
           MOVE WS-PAYOFF-NUM     TO WS-TO-PAYOFF
           MOVE WS-AC-NET-TRADE   TO WS-TO-NET-TRADE
           MOVE WS-TI-PAYOFF-BANK TO WS-TO-BANK
           MOVE WS-TI-PAYOFF-ACCT TO WS-TO-ACCT
      *
           MOVE WS-TRADE-OUTPUT TO WS-OUT-BODY
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
      * END OF SALTRD00                                              *
      ****************************************************************
