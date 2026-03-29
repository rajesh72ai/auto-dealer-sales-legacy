       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMTAXL0.
      ****************************************************************
      * PROGRAM:   COMTAXL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   TAX CALCULATION MODULE. LOOKS UP STATE, COUNTY    *
      *            AND CITY TAX RATES FROM THE TAX_RATE DB2 TABLE    *
      *            AND CALCULATES ALL TAX COMPONENTS FOR A VEHICLE   *
      *            SALE, INCLUDING DOC FEES, TITLE AND REGISTRATION. *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMTAXL0' USING LK-TAX-STATE-CODE                   *
      *                         LK-TAX-COUNTY-CODE                   *
      *                         LK-TAX-CITY-CODE                     *
      *                         LK-TAX-INPUT-AREA                    *
      *                         LK-TAX-RESULT-AREA                   *
      *                         LK-TAX-RETURN-CODE                   *
      *                         LK-TAX-ERROR-MSG                     *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - SUCCESS                                               *
      *   04 - TAX RATE NOT FOUND FOR JURISDICTION                   *
      *   08 - INVALID INPUT (BLANK STATE, NEGATIVE AMOUNT)          *
      *   12 - DB2 ERROR DURING TAX RATE LOOKUP                      *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMTAXL0'.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR TAX_RATE TABLE
      *
           COPY DCLTAXRT.
      *
      *    WORK FIELDS FOR TAX CALCULATION
      *
       01  WS-TAX-WORK-FIELDS.
           05  WS-TAXABLE-AMOUNT   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TRADE-ALLOWANCE  PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-NET-TAXABLE      PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-STATE-TAX-AMT   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-COUNTY-TAX-AMT  PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-CITY-TAX-AMT    PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-TOTAL-TAX-AMT   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-DOC-FEE-AMT     PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TITLE-FEE-AMT   PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-REG-FEE-AMT     PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-TOTAL-FEES-AMT  PIC S9(07)V99 COMP-3 VALUE 0.
           05  WS-GRAND-TOTAL     PIC S9(09)V99 COMP-3 VALUE 0.
      *
      *    DATE FIELDS FOR EFFECTIVE DATE LOOKUP
      *
       01  WS-DATE-FIELDS.
           05  WS-CURRENT-DATE.
               10  WS-CURR-YYYY   PIC 9(04).
               10  WS-CURR-MM     PIC 9(02).
               10  WS-CURR-DD     PIC 9(02).
           05  WS-CURRENT-DATE-X REDEFINES WS-CURRENT-DATE
                                   PIC X(08).
           05  WS-EFFECTIVE-DATE-W PIC X(10) VALUE SPACES.
           05  WS-CURRENT-DATE-DB2 PIC X(10) VALUE SPACES.
      *
      *    ROUNDING WORK AREA
      *
       01  WS-ROUND-WORK.
           05  WS-ROUND-AMT       PIC S9(11)V9(06) COMP-3 VALUE 0.
      *
      *    STATE-SPECIFIC DOC FEE CAPS
      *    SOME STATES CAP DEALER DOC FEES
      *
       01  WS-DOC-FEE-WORK.
           05  WS-REQUESTED-DOC-FEE PIC S9(05)V99 COMP-3 VALUE 0.
           05  WS-MAX-DOC-FEE     PIC S9(05)V99 COMP-3 VALUE 0.
      *
      *    NULL INDICATORS FOR DB2 NULLABLE COLUMNS
      *
       01  WS-NULL-INDICATORS.
           05  NI-EXPIRY-DATE     PIC S9(04) COMP VALUE 0.
      *
       LINKAGE SECTION.
      *
       01  LK-TAX-STATE-CODE      PIC X(02).
       01  LK-TAX-COUNTY-CODE     PIC X(05).
       01  LK-TAX-CITY-CODE       PIC X(05).
      *
       01  LK-TAX-INPUT-AREA.
           05  LK-TAX-TAXABLE-AMT PIC S9(09)V99 COMP-3.
           05  LK-TAX-TRADE-ALLOW PIC S9(09)V99 COMP-3.
           05  LK-TAX-DOC-FEE-REQ PIC S9(05)V99 COMP-3.
           05  LK-TAX-VEHICLE-TYPE PIC X(02).
               88  LK-TAX-NEW-VEH             VALUE 'NW'.
               88  LK-TAX-USED-VEH            VALUE 'US'.
               88  LK-TAX-DEMO-VEH            VALUE 'DM'.
           05  LK-TAX-SALE-DATE   PIC X(10).
      *
       01  LK-TAX-RESULT-AREA.
           05  LK-TAX-STATE-RATE  PIC S9(01)V9(04) COMP-3.
           05  LK-TAX-STATE-AMT   PIC S9(09)V99 COMP-3.
           05  LK-TAX-COUNTY-RATE PIC S9(01)V9(04) COMP-3.
           05  LK-TAX-COUNTY-AMT  PIC S9(09)V99 COMP-3.
           05  LK-TAX-CITY-RATE   PIC S9(01)V9(04) COMP-3.
           05  LK-TAX-CITY-AMT    PIC S9(09)V99 COMP-3.
           05  LK-TAX-TOTAL-TAX   PIC S9(09)V99 COMP-3.
           05  LK-TAX-NET-TAXABLE PIC S9(09)V99 COMP-3.
           05  LK-TAX-DOC-FEE     PIC S9(05)V99 COMP-3.
           05  LK-TAX-TITLE-FEE   PIC S9(05)V99 COMP-3.
           05  LK-TAX-REG-FEE     PIC S9(05)V99 COMP-3.
           05  LK-TAX-TOTAL-FEES  PIC S9(07)V99 COMP-3.
           05  LK-TAX-GRAND-TOTAL PIC S9(09)V99 COMP-3.
      *
       01  LK-TAX-RETURN-CODE     PIC S9(04) COMP.
      *
       01  LK-TAX-ERROR-MSG       PIC X(50).
      *
       PROCEDURE DIVISION USING LK-TAX-STATE-CODE
                                LK-TAX-COUNTY-CODE
                                LK-TAX-CITY-CODE
                                LK-TAX-INPUT-AREA
                                LK-TAX-RESULT-AREA
                                LK-TAX-RETURN-CODE
                                LK-TAX-ERROR-MSG.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-TAX-RETURN-CODE
           MOVE SPACES TO LK-TAX-ERROR-MSG
           INITIALIZE LK-TAX-RESULT-AREA
           INITIALIZE WS-TAX-WORK-FIELDS
      *
           PERFORM 1000-VALIDATE-INPUT
           IF LK-TAX-RETURN-CODE NOT = ZEROS
               GO TO 0000-EXIT
           END-IF
      *
           PERFORM 2000-GET-CURRENT-DATE
      *
           PERFORM 3000-LOOKUP-TAX-RATES
           IF LK-TAX-RETURN-CODE NOT = ZEROS
               GO TO 0000-EXIT
           END-IF
      *
           PERFORM 4000-CALCULATE-NET-TAXABLE
      *
           PERFORM 5000-CALCULATE-TAXES
      *
           PERFORM 6000-CALCULATE-FEES
      *
           PERFORM 7000-BUILD-RESULTS
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
           IF LK-TAX-STATE-CODE = SPACES OR LOW-VALUES
               MOVE +8 TO LK-TAX-RETURN-CODE
               MOVE 'STATE CODE IS REQUIRED'
                   TO LK-TAX-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
           IF LK-TAX-TAXABLE-AMT < 0
               MOVE +8 TO LK-TAX-RETURN-CODE
               MOVE 'TAXABLE AMOUNT CANNOT BE NEGATIVE'
                   TO LK-TAX-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
           IF LK-TAX-TAXABLE-AMT = 0
               MOVE +8 TO LK-TAX-RETURN-CODE
               MOVE 'TAXABLE AMOUNT IS ZERO'
                   TO LK-TAX-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
           IF LK-TAX-TRADE-ALLOW < 0
               MOVE +8 TO LK-TAX-RETURN-CODE
               MOVE 'TRADE ALLOWANCE CANNOT BE NEGATIVE'
                   TO LK-TAX-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
      *    VALIDATE VEHICLE TYPE
      *
           IF NOT (LK-TAX-NEW-VEH OR
                   LK-TAX-USED-VEH OR
                   LK-TAX-DEMO-VEH)
               MOVE +8 TO LK-TAX-RETURN-CODE
               MOVE 'INVALID VEHICLE TYPE CODE'
                   TO LK-TAX-ERROR-MSG
           END-IF
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - GET CURRENT DATE FOR TAX RATE EFFECTIVE DATE LOOKUP     *
      *---------------------------------------------------------------*
       2000-GET-CURRENT-DATE.
      *
      *    USE SALE DATE IF PROVIDED, ELSE CURRENT DATE
      *
           IF LK-TAX-SALE-DATE NOT = SPACES
               MOVE LK-TAX-SALE-DATE TO WS-CURRENT-DATE-DB2
           ELSE
               MOVE FUNCTION CURRENT-DATE(1:8)
                   TO WS-CURRENT-DATE-X
               STRING WS-CURR-YYYY '-'
                      WS-CURR-MM   '-'
                      WS-CURR-DD
                   DELIMITED BY SIZE
                   INTO WS-CURRENT-DATE-DB2
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - LOOKUP TAX RATES FROM DB2 TAX_RATE TABLE                *
      *        FINDS RATE EFFECTIVE FOR THE CURRENT/SALE DATE          *
      *---------------------------------------------------------------*
       3000-LOOKUP-TAX-RATES.
      *
           EXEC SQL
               SELECT STATE_RATE,
                      COUNTY_RATE,
                      CITY_RATE,
                      DOC_FEE_MAX,
                      TITLE_FEE,
                      REG_FEE,
                      EFFECTIVE_DATE,
                      EXPIRY_DATE
                 INTO :STATE-RATE,
                      :COUNTY-RATE,
                      :CITY-RATE,
                      :DOC-FEE-MAX,
                      :TITLE-FEE,
                      :REG-FEE,
                      :EFFECTIVE-DATE,
                      :EXPIRY-DATE :NI-EXPIRY-DATE
                 FROM AUTOSALE.TAX_RATE
                WHERE STATE_CODE  = :LK-TAX-STATE-CODE
                  AND COUNTY_CODE = :LK-TAX-COUNTY-CODE
                  AND CITY_CODE   = :LK-TAX-CITY-CODE
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
      *            NOT FOUND - TRY JUST STATE + COUNTY
                   PERFORM 3100-LOOKUP-STATE-COUNTY
               WHEN OTHER
                   MOVE +12 TO LK-TAX-RETURN-CODE
                   STRING 'DB2 ERROR ON TAX_RATE LOOKUP: '
                          SQLCODE
                          DELIMITED BY SIZE
                       INTO LK-TAX-ERROR-MSG
           END-EVALUATE
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3100 - FALLBACK: LOOKUP BY STATE AND COUNTY ONLY               *
      *        CITY CODE SET TO '00000' FOR DEFAULT RATE               *
      *---------------------------------------------------------------*
       3100-LOOKUP-STATE-COUNTY.
      *
           EXEC SQL
               SELECT STATE_RATE,
                      COUNTY_RATE,
                      CITY_RATE,
                      DOC_FEE_MAX,
                      TITLE_FEE,
                      REG_FEE,
                      EFFECTIVE_DATE,
                      EXPIRY_DATE
                 INTO :STATE-RATE,
                      :COUNTY-RATE,
                      :CITY-RATE,
                      :DOC-FEE-MAX,
                      :TITLE-FEE,
                      :REG-FEE,
                      :EFFECTIVE-DATE,
                      :EXPIRY-DATE :NI-EXPIRY-DATE
                 FROM AUTOSALE.TAX_RATE
                WHERE STATE_CODE  = :LK-TAX-STATE-CODE
                  AND COUNTY_CODE = :LK-TAX-COUNTY-CODE
                  AND CITY_CODE   = '00000'
                  AND EFFECTIVE_DATE <= :WS-CURRENT-DATE-DB2
                  AND (EXPIRY_DATE IS NULL
                       OR EXPIRY_DATE >= :WS-CURRENT-DATE-DB2)
                ORDER BY EFFECTIVE_DATE DESC
                FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE ZEROS TO CITY-RATE
               WHEN +100
                   PERFORM 3200-LOOKUP-STATE-ONLY
               WHEN OTHER
                   MOVE +12 TO LK-TAX-RETURN-CODE
                   STRING 'DB2 ERROR ON TAX_RATE FALLBACK: '
                          SQLCODE
                          DELIMITED BY SIZE
                       INTO LK-TAX-ERROR-MSG
           END-EVALUATE
           .
       3100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3200 - FALLBACK: LOOKUP BY STATE ONLY                          *
      *        COUNTY AND CITY DEFAULT CODES                           *
      *---------------------------------------------------------------*
       3200-LOOKUP-STATE-ONLY.
      *
           EXEC SQL
               SELECT STATE_RATE,
                      COUNTY_RATE,
                      CITY_RATE,
                      DOC_FEE_MAX,
                      TITLE_FEE,
                      REG_FEE,
                      EFFECTIVE_DATE,
                      EXPIRY_DATE
                 INTO :STATE-RATE,
                      :COUNTY-RATE,
                      :CITY-RATE,
                      :DOC-FEE-MAX,
                      :TITLE-FEE,
                      :REG-FEE,
                      :EFFECTIVE-DATE,
                      :EXPIRY-DATE :NI-EXPIRY-DATE
                 FROM AUTOSALE.TAX_RATE
                WHERE STATE_CODE  = :LK-TAX-STATE-CODE
                  AND COUNTY_CODE = '00000'
                  AND CITY_CODE   = '00000'
                  AND EFFECTIVE_DATE <= :WS-CURRENT-DATE-DB2
                  AND (EXPIRY_DATE IS NULL
                       OR EXPIRY_DATE >= :WS-CURRENT-DATE-DB2)
                ORDER BY EFFECTIVE_DATE DESC
                FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE ZEROS TO COUNTY-RATE
                   MOVE ZEROS TO CITY-RATE
               WHEN +100
                   MOVE +4 TO LK-TAX-RETURN-CODE
                   STRING 'NO TAX RATE FOUND FOR STATE '
                          LK-TAX-STATE-CODE
                          DELIMITED BY SIZE
                       INTO LK-TAX-ERROR-MSG
               WHEN OTHER
                   MOVE +12 TO LK-TAX-RETURN-CODE
                   STRING 'DB2 ERROR ON STATE LOOKUP: '
                          SQLCODE
                          DELIMITED BY SIZE
                       INTO LK-TAX-ERROR-MSG
           END-EVALUATE
           .
       3200-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - CALCULATE NET TAXABLE AMOUNT                            *
      *        IN SOME STATES, TRADE-IN REDUCES TAXABLE AMOUNT         *
      *---------------------------------------------------------------*
       4000-CALCULATE-NET-TAXABLE.
      *
           MOVE LK-TAX-TAXABLE-AMT TO WS-TAXABLE-AMOUNT
           MOVE LK-TAX-TRADE-ALLOW TO WS-TRADE-ALLOWANCE
      *
      *    NET TAXABLE = SELLING PRICE - TRADE ALLOWANCE
      *    (MOST STATES ALLOW TRADE-IN TAX CREDIT)
      *
           COMPUTE WS-NET-TAXABLE =
               WS-TAXABLE-AMOUNT - WS-TRADE-ALLOWANCE
      *
      *    CANNOT BE NEGATIVE
      *
           IF WS-NET-TAXABLE < 0
               MOVE ZEROS TO WS-NET-TAXABLE
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - CALCULATE STATE, COUNTY AND CITY TAXES                  *
      *        ROUND EACH TO NEAREST CENT                              *
      *---------------------------------------------------------------*
       5000-CALCULATE-TAXES.
      *
      *    STATE TAX
      *
           COMPUTE WS-ROUND-AMT =
               WS-NET-TAXABLE * STATE-RATE
           COMPUTE WS-STATE-TAX-AMT ROUNDED =
               WS-ROUND-AMT
      *
      *    COUNTY TAX
      *
           COMPUTE WS-ROUND-AMT =
               WS-NET-TAXABLE * COUNTY-RATE
           COMPUTE WS-COUNTY-TAX-AMT ROUNDED =
               WS-ROUND-AMT
      *
      *    CITY TAX
      *
           COMPUTE WS-ROUND-AMT =
               WS-NET-TAXABLE * CITY-RATE
           COMPUTE WS-CITY-TAX-AMT ROUNDED =
               WS-ROUND-AMT
      *
      *    TOTAL TAX
      *
           COMPUTE WS-TOTAL-TAX-AMT =
               WS-STATE-TAX-AMT +
               WS-COUNTY-TAX-AMT +
               WS-CITY-TAX-AMT
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - CALCULATE FEES (DOC FEE, TITLE, REGISTRATION)          *
      *        DOC FEE IS CAPPED PER STATE LAW                         *
      *---------------------------------------------------------------*
       6000-CALCULATE-FEES.
      *
      *    DOC FEE: USE REQUESTED AMOUNT BUT CAP AT STATE MAX
      *
           MOVE LK-TAX-DOC-FEE-REQ TO WS-REQUESTED-DOC-FEE
           MOVE DOC-FEE-MAX TO WS-MAX-DOC-FEE
      *
           IF WS-REQUESTED-DOC-FEE > WS-MAX-DOC-FEE
               MOVE WS-MAX-DOC-FEE TO WS-DOC-FEE-AMT
           ELSE
               MOVE WS-REQUESTED-DOC-FEE TO WS-DOC-FEE-AMT
           END-IF
      *
      *    TITLE FEE: FLAT FEE FROM TAX_RATE TABLE
      *
           MOVE TITLE-FEE TO WS-TITLE-FEE-AMT
      *
      *    REGISTRATION FEE: FROM TAX_RATE TABLE
      *    NEW VEHICLES MAY HAVE HIGHER REG FEES
      *
           IF LK-TAX-NEW-VEH
               MOVE REG-FEE TO WS-REG-FEE-AMT
           ELSE
      *        USED VEHICLES GET STANDARD REG FEE
               MOVE REG-FEE TO WS-REG-FEE-AMT
           END-IF
      *
      *    TOTAL FEES
      *
           COMPUTE WS-TOTAL-FEES-AMT =
               WS-DOC-FEE-AMT +
               WS-TITLE-FEE-AMT +
               WS-REG-FEE-AMT
      *
      *    GRAND TOTAL (TAX + FEES)
      *
           COMPUTE WS-GRAND-TOTAL =
               WS-TOTAL-TAX-AMT +
               WS-TOTAL-FEES-AMT
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7000 - BUILD RESULT AREA FOR CALLER                            *
      *---------------------------------------------------------------*
       7000-BUILD-RESULTS.
      *
           MOVE STATE-RATE         TO LK-TAX-STATE-RATE
           MOVE WS-STATE-TAX-AMT  TO LK-TAX-STATE-AMT
           MOVE COUNTY-RATE        TO LK-TAX-COUNTY-RATE
           MOVE WS-COUNTY-TAX-AMT TO LK-TAX-COUNTY-AMT
           MOVE CITY-RATE          TO LK-TAX-CITY-RATE
           MOVE WS-CITY-TAX-AMT   TO LK-TAX-CITY-AMT
           MOVE WS-TOTAL-TAX-AMT  TO LK-TAX-TOTAL-TAX
           MOVE WS-NET-TAXABLE    TO LK-TAX-NET-TAXABLE
           MOVE WS-DOC-FEE-AMT    TO LK-TAX-DOC-FEE
           MOVE WS-TITLE-FEE-AMT  TO LK-TAX-TITLE-FEE
           MOVE WS-REG-FEE-AMT    TO LK-TAX-REG-FEE
           MOVE WS-TOTAL-FEES-AMT TO LK-TAX-TOTAL-FEES
           MOVE WS-GRAND-TOTAL    TO LK-TAX-GRAND-TOTAL
           .
       7000-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMTAXL0                                              *
      ****************************************************************
