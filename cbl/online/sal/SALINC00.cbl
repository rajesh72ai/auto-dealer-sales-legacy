       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALINC00.
      ****************************************************************
      * PROGRAM:    SALINC00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALI                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLIC00 (INCENTIVE RESPONSE)                    *
      *                                                              *
      * PURPOSE:    INCENTIVE / REBATE APPLICATION. QUERIES ELIGIBLE  *
      *             INCENTIVES: ACTIVE, DATE RANGE VALID, MODEL       *
      *             MATCHES, REGION MATCHES, UNITS AVAILABLE.         *
      *             DISPLAYS LIST OF APPLICABLE INCENTIVES. ALLOWS    *
      *             SELECTION OF MULTIPLE (IF STACKABLE). VALIDATES   *
      *             NON-STACKABLE CANNOT COMBINE. INSERTS             *
      *             INCENTIVE_APPLIED, INCREMENTS UNITS_USED.         *
      *             RECALCULATES DEAL TOTALS WITH REBATES APPLIED.   *
      *                                                              *
      * CALLS:      COMPRCL0 - VEHICLE PRICING LOOKUP                *
      *             COMTAXL0 - TAX CALCULATION                       *
      *             COMFMTL0 - CURRENCY FORMATTING                   *
      *             COMLGEL0 - AUDIT LOG ENTRY                       *
      *                                                              *
      * TABLES:     AUTOSALE.INCENTIVE_PROGRAM  (READ/UPDATE)        *
      *             AUTOSALE.INCENTIVE_APPLIED   (INSERT)            *
      *             AUTOSALE.SALES_DEAL          (READ/UPDATE)       *
      *             AUTOSALE.VEHICLE             (READ)              *
      *             AUTOSALE.CUSTOMER            (READ)              *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALINC00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
           COPY DCLINCPG.
           COPY DCLINAPP.
           COPY DCLVEHCL.
      *
      *    INPUT FIELDS
      *
       01  WS-INC-INPUT.
           05  WS-II-DEAL-NUMBER    PIC X(10).
           05  WS-II-ACTION         PIC X(02).
               88  WS-II-ACT-LIST              VALUE 'LS'.
               88  WS-II-ACT-APPLY             VALUE 'AP'.
           05  WS-II-INCENTIVE-IDS.
               10  WS-II-INC-ID    PIC X(10) OCCURS 5 TIMES.
      *
      *    OUTPUT LAYOUT
      *
       01  WS-INC-OUTPUT.
           05  WS-IO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- INCENTIVES / REBATES -----'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-IO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(29) VALUE SPACES.
           05  WS-IO-VEH-LINE.
               10  FILLER           PIC X(09) VALUE 'VEHICLE: '.
               10  WS-IO-VEH-YEAR  PIC 9(04).
               10  FILLER           PIC X(01) VALUE SPACE.
               10  WS-IO-VEH-MAKE  PIC X(03).
               10  FILLER           PIC X(01) VALUE SPACE.
               10  WS-IO-VEH-MODEL PIC X(06).
               10  FILLER           PIC X(55) VALUE SPACES.
           05  WS-IO-COL-HDR.
               10  FILLER           PIC X(79)
                   VALUE 'ID         NAME
      -               '                   AMT       STACK'.
           05  WS-IO-DASHES.
               10  FILLER           PIC X(79)
                   VALUE '---------- -------------------------
      -               '----------  --------  -----'.
           05  WS-IO-DETAIL OCCURS 8 TIMES.
               10  WS-IO-DET-ID    PIC X(10).
               10  FILLER           PIC X(01) VALUE SPACE.
               10  WS-IO-DET-NAME  PIC X(25).
               10  FILLER           PIC X(01) VALUE SPACE.
               10  WS-IO-DET-TYPE  PIC X(02).
               10  FILLER           PIC X(08) VALUE SPACES.
               10  WS-IO-DET-AMT   PIC $$,$$$,$$9.99.
               10  FILLER           PIC X(02) VALUE SPACES.
               10  WS-IO-DET-STACK PIC X(01).
               10  FILLER           PIC X(14) VALUE SPACES.
           05  WS-IO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-IO-TOTAL-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'TOTAL REBATES APPLIED:'.
               10  WS-IO-TOTAL-REB PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(43) VALUE SPACES.
           05  WS-IO-FILLER        PIC X(537) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR              VALUE 'Y'.
               88  WS-NO-ERROR               VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-VEH-MODEL-YEAR   PIC S9(04) COMP VALUE +0.
           05  WS-VEH-MAKE-CODE    PIC X(03) VALUE SPACES.
           05  WS-VEH-MODEL-CODE   PIC X(06) VALUE SPACES.
           05  WS-DEALER-REGION    PIC X(03) VALUE SPACES.
           05  WS-ROW-COUNT        PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-REBATE     PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-APPLY-COUNT      PIC S9(04) COMP VALUE +0.
           05  WS-HAS-NON-STACK    PIC X(01) VALUE 'N'.
               88  WS-NON-STACK-FOUND         VALUE 'Y'.
               88  WS-ALL-STACKABLE           VALUE 'N'.
           05  WS-EOF-FLAG         PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA             VALUE 'Y'.
               88  WS-MORE-DATA               VALUE 'N'.
           05  WS-CUST-STATE       PIC X(02) VALUE SPACES.
           05  WS-CUST-COUNTY      PIC X(05) VALUE SPACES.
           05  WS-CUST-CITY        PIC X(05) VALUE SPACES.
           05  WS-INC-IDX          PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR FOR ELIGIBLE INCENTIVES
      *
           EXEC SQL DECLARE CSR_INCENTIVES CURSOR FOR
               SELECT I.INCENTIVE_ID
                    , I.INCENTIVE_NAME
                    , I.INCENTIVE_TYPE
                    , I.AMOUNT
                    , I.STACKABLE_FLAG
                    , I.MAX_UNITS
                    , I.UNITS_USED
               FROM   AUTOSALE.INCENTIVE_PROGRAM I
               WHERE  I.ACTIVE_FLAG = 'Y'
                 AND  CURRENT DATE BETWEEN I.START_DATE
                                       AND I.END_DATE
                 AND  (I.MODEL_YEAR = :WS-VEH-MODEL-YEAR
                    OR I.MODEL_YEAR IS NULL)
                 AND  (I.MAKE_CODE = :WS-VEH-MAKE-CODE
                    OR I.MAKE_CODE IS NULL)
                 AND  (I.MODEL_CODE = :WS-VEH-MODEL-CODE
                    OR I.MODEL_CODE IS NULL)
                 AND  (I.REGION_CODE = :WS-DEALER-REGION
                    OR I.REGION_CODE IS NULL)
                 AND  (I.MAX_UNITS IS NULL
                    OR I.UNITS_USED < I.MAX_UNITS)
               ORDER BY I.AMOUNT DESC
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HV-INCENTIVE.
           05  WS-HV-INC-ID        PIC X(10).
           05  WS-HV-INC-NAME.
               49  WS-HV-INC-NAME-LN PIC S9(04) COMP.
               49  WS-HV-INC-NAME-TX PIC X(60).
           05  WS-HV-INC-TYPE      PIC X(02).
           05  WS-HV-INC-AMOUNT    PIC S9(07)V99 COMP-3.
           05  WS-HV-INC-STACKABLE PIC X(01).
           05  WS-HV-INC-MAX-UNITS PIC S9(09) COMP.
           05  WS-HV-INC-USED      PIC S9(09) COMP.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-MAX-UNITS        PIC S9(04) COMP VALUE +0.
           05  NI-REGION           PIC S9(04) COMP VALUE +0.
           05  NI-CUST-COUNTY      PIC S9(04) COMP VALUE +0.
           05  NI-CUST-CITY        PIC S9(04) COMP VALUE +0.
      *
      *    TAX CALL FIELDS
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
      *    FORMAT CALL FIELDS
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
               PERFORM 3500-GET-VEHICLE-INFO
           END-IF
      *
           IF WS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN WS-II-ACT-LIST
                       PERFORM 4000-LIST-INCENTIVES
                   WHEN WS-II-ACT-APPLY
                       PERFORM 5000-APPLY-INCENTIVES
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID ACTION - USE LS OR AP'
                           TO WS-ERROR-MSG
               END-EVALUATE
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
           INITIALIZE WS-INC-OUTPUT
           MOVE SPACES TO WS-ERROR-MSG
           MOVE +0 TO WS-ROW-COUNT
           MOVE +0 TO WS-TOTAL-REBATE
           SET WS-ALL-STACKABLE TO TRUE
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
               MOVE 'SALINC00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-II-DEAL-NUMBER
               MOVE WS-INP-FUNCTION TO WS-II-ACTION
               MOVE WS-INP-BODY(1:10)  TO WS-II-INC-ID(1)
               MOVE WS-INP-BODY(11:10) TO WS-II-INC-ID(2)
               MOVE WS-INP-BODY(21:10) TO WS-II-INC-ID(3)
               MOVE WS-INP-BODY(31:10) TO WS-II-INC-ID(4)
               MOVE WS-INP-BODY(41:10) TO WS-II-INC-ID(5)
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-DEAL                                        *
      ****************************************************************
       3000-VALIDATE-DEAL.
      *
           IF WS-II-DEAL-NUMBER = SPACES
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
                    , DISCOUNT_AMT
                    , REBATES_APPLIED
                    , NET_TRADE
                    , TOTAL_PRICE
                    , DOWN_PAYMENT
                    , VIN
               INTO   :DEAL-NUMBER
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :SUBTOTAL
                    , :DISCOUNT-AMT
                    , :REBATES-APPLIED
                    , :NET-TRADE
                    , :TOTAL-PRICE
                    , :DOWN-PAYMENT
                    , :VIN OF DCLSALES-DEAL
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-II-DEAL-NUMBER
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
           IF DEAL-STATUS NOT = 'WS'
           AND DEAL-STATUS NOT = 'NE'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'DEAL STATUS ' DEAL-STATUS
                      ' - NOT OPEN FOR INCENTIVES'
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-GET-VEHICLE-INFO - GET MODEL FOR INCENTIVE MATCH     *
      ****************************************************************
       3500-GET-VEHICLE-INFO.
      *
           EXEC SQL
               SELECT MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , DEALER_CODE
               INTO   :WS-VEH-MODEL-YEAR
                    , :WS-VEH-MAKE-CODE
                    , :WS-VEH-MODEL-CODE
                    , :DEALER-CODE OF DCLVEHICLE
               FROM   AUTOSALE.VEHICLE
               WHERE  VIN = :VIN OF DCLSALES-DEAL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND FOR DEAL VIN'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
      *    GET DEALER REGION
      *
           EXEC SQL
               SELECT COALESCE(REGION_CODE, '   ')
               INTO   :WS-DEALER-REGION :NI-REGION
               FROM   AUTOSALE.DEALER
               WHERE  DEALER_CODE
                    = :DEALER-CODE OF DCLVEHICLE
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SPACES TO WS-DEALER-REGION
           END-IF
           .
       3500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LIST-INCENTIVES - QUERY AND DISPLAY ELIGIBLE ONES    *
      ****************************************************************
       4000-LIST-INCENTIVES.
      *
           EXEC SQL OPEN CSR_INCENTIVES END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR OPENING INCENTIVE CURSOR'
                   TO WS-ERROR-MSG
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           SET WS-MORE-DATA TO TRUE
      *
           PERFORM 4100-FETCH-INCENTIVE
               UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +8
      *
           EXEC SQL CLOSE CSR_INCENTIVES END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO ELIGIBLE INCENTIVES FOUND FOR THIS VEHICLE'
                   TO WS-ERROR-MSG
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-INCENTIVE - FETCH ONE ROW AND FORMAT           *
      ****************************************************************
       4100-FETCH-INCENTIVE.
      *
           EXEC SQL FETCH CSR_INCENTIVES
               INTO  :WS-HV-INC-ID
                    , :WS-HV-INC-NAME
                    , :WS-HV-INC-TYPE
                    , :WS-HV-INC-AMOUNT
                    , :WS-HV-INC-STACKABLE
                    , :WS-HV-INC-MAX-UNITS :NI-MAX-UNITS
                    , :WS-HV-INC-USED
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   MOVE WS-HV-INC-ID
                       TO WS-IO-DET-ID(WS-ROW-COUNT)
                   MOVE WS-HV-INC-NAME-TX(1:25)
                       TO WS-IO-DET-NAME(WS-ROW-COUNT)
                   MOVE WS-HV-INC-TYPE
                       TO WS-IO-DET-TYPE(WS-ROW-COUNT)
                   MOVE WS-HV-INC-AMOUNT
                       TO WS-IO-DET-AMT(WS-ROW-COUNT)
                   MOVE WS-HV-INC-STACKABLE
                       TO WS-IO-DET-STACK(WS-ROW-COUNT)
               WHEN +100
                   SET WS-END-OF-DATA TO TRUE
               WHEN OTHER
                   SET WS-END-OF-DATA TO TRUE
                   MOVE 'DB2 ERROR READING INCENTIVES'
                       TO WS-ERROR-MSG
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-APPLY-INCENTIVES - APPLY SELECTED INCENTIVES         *
      ****************************************************************
       5000-APPLY-INCENTIVES.
      *
           MOVE +0 TO WS-APPLY-COUNT
           MOVE +0 TO WS-TOTAL-REBATE
           SET WS-ALL-STACKABLE TO TRUE
      *
      *    PROCESS EACH SELECTED INCENTIVE ID
      *
           PERFORM VARYING WS-INC-IDX FROM +1 BY +1
               UNTIL WS-INC-IDX > +5
               OR WS-RETURN-CODE > +0
      *
               IF WS-II-INC-ID(WS-INC-IDX) NOT = SPACES
                   PERFORM 5100-VALIDATE-ONE-INCENTIVE
               END-IF
           END-PERFORM
      *
           IF WS-RETURN-CODE > +0
               GO TO 5000-EXIT
           END-IF
      *
      *    NOW INSERT AND UPDATE EACH SELECTED INCENTIVE
      *
           PERFORM VARYING WS-INC-IDX FROM +1 BY +1
               UNTIL WS-INC-IDX > +5
               OR WS-RETURN-CODE > +0
      *
               IF WS-II-INC-ID(WS-INC-IDX) NOT = SPACES
                   PERFORM 5200-INSERT-ONE-INCENTIVE
               END-IF
           END-PERFORM
      *
      *    UPDATE DEAL WITH TOTAL REBATES
      *
           IF WS-RETURN-CODE = +0 AND WS-APPLY-COUNT > +0
               PERFORM 6000-UPDATE-DEAL
               PERFORM 6500-WRITE-AUDIT-LOG
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-VALIDATE-ONE-INCENTIVE                               *
      ****************************************************************
       5100-VALIDATE-ONE-INCENTIVE.
      *
      *    READ THE INCENTIVE PROGRAM
      *
           EXEC SQL
               SELECT INCENTIVE_ID
                    , AMOUNT
                    , STACKABLE_FLAG
                    , ACTIVE_FLAG
                    , MAX_UNITS
                    , UNITS_USED
               INTO   :INCENTIVE-ID
                    , :AMOUNT OF DCLINCENTIVE-PROGRAM
                    , :STACKABLE-FLAG
                    , :ACTIVE-FLAG
                    , :MAX-UNITS :NI-MAX-UNITS
                    , :UNITS-USED
               FROM   AUTOSALE.INCENTIVE_PROGRAM
               WHERE  INCENTIVE_ID
                    = :WS-II-INC-ID(WS-INC-IDX)
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               STRING 'INCENTIVE NOT FOUND: '
                      WS-II-INC-ID(WS-INC-IDX)
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
               GO TO 5100-EXIT
           END-IF
      *
      *    VERIFY STILL ACTIVE
      *
           IF ACTIVE-FLAG NOT = 'Y'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'INCENTIVE INACTIVE: '
                      WS-II-INC-ID(WS-INC-IDX)
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
               GO TO 5100-EXIT
           END-IF
      *
      *    CHECK MAX UNITS
      *
           IF NI-MAX-UNITS >= +0 AND MAX-UNITS > +0
               IF UNITS-USED >= MAX-UNITS
                   MOVE +8 TO WS-RETURN-CODE
                   STRING 'INCENTIVE MAX UNITS REACHED: '
                          WS-II-INC-ID(WS-INC-IDX)
                          DELIMITED BY SIZE
                          INTO WS-ERROR-MSG
                   GO TO 5100-EXIT
               END-IF
           END-IF
      *
      *    STACKABLE CHECK
      *
           IF STACKABLE-FLAG = 'N'
               IF WS-NON-STACK-FOUND
      *            TWO NON-STACKABLE PROGRAMS SELECTED
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'CANNOT COMBINE NON-STACKABLE INCENTIVES'
                       TO WS-ERROR-MSG
                   GO TO 5100-EXIT
               END-IF
               SET WS-NON-STACK-FOUND TO TRUE
      *        NON-STACKABLE: ONLY ONE ALLOWED
               IF WS-APPLY-COUNT > +0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'NON-STACKABLE INCENTIVE CANNOT COMBINE'
                       TO WS-ERROR-MSG
                   GO TO 5100-EXIT
               END-IF
           ELSE
      *        STACKABLE BUT CHECK IF A NON-STACKABLE ALREADY PICKED
               IF WS-NON-STACK-FOUND
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'CANNOT ADD TO NON-STACKABLE INCENTIVE'
                       TO WS-ERROR-MSG
                   GO TO 5100-EXIT
               END-IF
           END-IF
      *
           ADD +1 TO WS-APPLY-COUNT
           ADD AMOUNT OF DCLINCENTIVE-PROGRAM TO WS-TOTAL-REBATE
           .
       5100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5200-INSERT-ONE-INCENTIVE                                 *
      ****************************************************************
       5200-INSERT-ONE-INCENTIVE.
      *
      *    RE-READ TO GET AMOUNT
      *
           EXEC SQL
               SELECT AMOUNT
               INTO   :AMOUNT OF DCLINCENTIVE-PROGRAM
               FROM   AUTOSALE.INCENTIVE_PROGRAM
               WHERE  INCENTIVE_ID
                    = :WS-II-INC-ID(WS-INC-IDX)
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 5200-EXIT
           END-IF
      *
      *    INSERT INCENTIVE_APPLIED
      *
           EXEC SQL
               INSERT INTO AUTOSALE.INCENTIVE_APPLIED
               ( DEAL_NUMBER
               , INCENTIVE_ID
               , AMOUNT_APPLIED
               , APPLIED_TS
               )
               VALUES
               ( :WS-II-DEAL-NUMBER
               , :WS-II-INC-ID(WS-INC-IDX)
               , :AMOUNT OF DCLINCENTIVE-PROGRAM
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR INSERTING INCENTIVE_APPLIED'
                   TO WS-ERROR-MSG
               GO TO 5200-EXIT
           END-IF
      *
      *    INCREMENT UNITS_USED
      *
           EXEC SQL
               UPDATE AUTOSALE.INCENTIVE_PROGRAM
                  SET UNITS_USED = UNITS_USED + 1
               WHERE  INCENTIVE_ID
                    = :WS-II-INC-ID(WS-INC-IDX)
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING INCENTIVE UNITS_USED'
                   TO WS-ERROR-MSG
           END-IF
           .
       5200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-UPDATE-DEAL - RECALCULATE WITH REBATES               *
      ****************************************************************
       6000-UPDATE-DEAL.
      *
      *    ADD NEW REBATES TO EXISTING
      *
           COMPUTE WS-TOTAL-REBATE =
               REBATES-APPLIED + WS-TOTAL-REBATE
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET REBATES_APPLIED = :WS-TOTAL-REBATE
                    , TOTAL_PRICE     = SUBTOTAL
                                      - DISCOUNT_AMT
                                      - :WS-TOTAL-REBATE
                                      - NET_TRADE
                                      + STATE_TAX
                                      + COUNTY_TAX
                                      + CITY_TAX
                                      + DOC_FEE
                                      + TITLE_FEE
                                      + REG_FEE
                    , AMOUNT_FINANCED = SUBTOTAL
                                      - DISCOUNT_AMT
                                      - :WS-TOTAL-REBATE
                                      - NET_TRADE
                                      + STATE_TAX
                                      + COUNTY_TAX
                                      + CITY_TAX
                                      + DOC_FEE
                                      + TITLE_FEE
                                      + REG_FEE
                                      - DOWN_PAYMENT
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-II-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING DEAL WITH REBATES'
                   TO WS-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    6500-WRITE-AUDIT-LOG                                      *
      ****************************************************************
       6500-WRITE-AUDIT-LOG.
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'INCENT  '         TO WS-LR-FUNCTION
           MOVE IO-PCB-USER-ID     TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-II-DEAL-NUMBER  TO WS-LR-ENTITY-KEY
           STRING 'INCENTIVES APPLIED: DEAL ' WS-II-DEAL-NUMBER
                  ' COUNT=' WS-APPLY-COUNT
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
           IF WS-II-ACT-LIST
               MOVE 'ELIGIBLE INCENTIVES DISPLAYED'
                   TO WS-OUT-MSG-TEXT
           ELSE
               MOVE 'INCENTIVES APPLIED TO DEAL'
                   TO WS-OUT-MSG-TEXT
           END-IF
      *
           MOVE WS-II-DEAL-NUMBER TO WS-IO-DEAL-NUM
           MOVE WS-VEH-MODEL-YEAR TO WS-IO-VEH-YEAR
           MOVE WS-VEH-MAKE-CODE  TO WS-IO-VEH-MAKE
           MOVE WS-VEH-MODEL-CODE TO WS-IO-VEH-MODEL
           MOVE WS-TOTAL-REBATE   TO WS-IO-TOTAL-REB
      *
           MOVE WS-INC-OUTPUT TO WS-OUT-BODY
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
      * END OF SALINC00                                              *
      ****************************************************************
