       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHAGE00.
      ****************************************************************
      * PROGRAM:  VEHAGE00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - INVENTORY AGING DISPLAY                  *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SHOWS AGING BUCKETS FOR A DEALER:                  *
      *           0-30 DAYS, 31-60, 61-90, 90+ DAYS.                *
      *           CALCULATES FROM VEHICLE.RECEIVE_DATE TO CURRENT.   *
      *           SUMMARY: COUNT AND TOTAL VALUE PER BUCKET.         *
      *           DETAIL: LIST VEHICLES IN SELECTED BUCKET.          *
      *           HIGHLIGHTS VEHICLES OVER 90 DAYS (AGED STOCK).     *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHAG - VEHICLE AGING                               *
      * CALLS:    COMDTEL0 - DATE CALC (AGED FUNCTION)               *
      *           COMFMTL0 - FORMAT CURRENCY                         *
      *           COMPRCL0 - GET INVOICE FOR VALUE                   *
      * TABLES:   AUTOSALE.VEHICLE                                   *
      *           AUTOSALE.PRICE_SCHEDULE                             *
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
                                          VALUE 'VEHAGE00'.
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
      *    INPUT FIELDS
      *
       01  WS-AGE-INPUT.
           05  WS-AI-FUNCTION            PIC X(02).
               88  WS-AI-SUMMARY                    VALUE 'SM'.
               88  WS-AI-DETAIL                     VALUE 'DT'.
           05  WS-AI-DEALER-CODE         PIC X(05).
           05  WS-AI-BUCKET              PIC X(01).
               88  WS-AI-BUCKET-30                  VALUE '1'.
               88  WS-AI-BUCKET-60                  VALUE '2'.
               88  WS-AI-BUCKET-90                  VALUE '3'.
               88  WS-AI-BUCKET-OVER                VALUE '4'.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-AGE-OUTPUT.
           05  WS-AO-STATUS-LINE.
               10  WS-AO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-MSG-TEXT       PIC X(70).
           05  WS-AO-TITLE-LINE.
               10  FILLER               PIC X(40)
                   VALUE '==== INVENTORY AGING REPORT ====        '.
               10  FILLER               PIC X(08)
                   VALUE 'DEALER: '.
               10  WS-AO-DEALER-HDR     PIC X(05).
               10  FILLER               PIC X(26) VALUE SPACES.
           05  WS-AO-BLANK-1            PIC X(79) VALUE SPACES.
      *
      *    SUMMARY SECTION
      *
           05  WS-AO-SUM-HEADER.
               10  FILLER               PIC X(20)
                   VALUE 'AGING BUCKET        '.
               10  FILLER               PIC X(10)
                   VALUE 'COUNT     '.
               10  FILLER               PIC X(15)
                   VALUE 'TOTAL VALUE    '.
               10  FILLER               PIC X(10)
                   VALUE 'AVG DAYS  '.
               10  FILLER               PIC X(07)
                   VALUE 'PCT    '.
               10  FILLER               PIC X(17) VALUE SPACES.
           05  WS-AO-SUM-SEP            PIC X(79) VALUE ALL '-'.
           05  WS-AO-BUCKET-1.
               10  FILLER               PIC X(20)
                   VALUE '0-30 DAYS           '.
               10  WS-AO-B1-COUNT       PIC Z(08)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B1-VALUE       PIC $(11)9.99.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B1-AVG-DAYS    PIC Z(06)9.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  WS-AO-B1-PCT         PIC ZZ9.9.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-AO-BUCKET-2.
               10  FILLER               PIC X(20)
                   VALUE '31-60 DAYS          '.
               10  WS-AO-B2-COUNT       PIC Z(08)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B2-VALUE       PIC $(11)9.99.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B2-AVG-DAYS    PIC Z(06)9.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  WS-AO-B2-PCT         PIC ZZ9.9.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-AO-BUCKET-3.
               10  FILLER               PIC X(20)
                   VALUE '61-90 DAYS          '.
               10  WS-AO-B3-COUNT       PIC Z(08)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B3-VALUE       PIC $(11)9.99.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B3-AVG-DAYS    PIC Z(06)9.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  WS-AO-B3-PCT         PIC ZZ9.9.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-AO-BUCKET-4.
               10  FILLER               PIC X(20)
                   VALUE '90+ DAYS  ** AGED **'.
               10  WS-AO-B4-COUNT       PIC Z(08)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B4-VALUE       PIC $(11)9.99.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-B4-AVG-DAYS    PIC Z(06)9.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  WS-AO-B4-PCT         PIC ZZ9.9.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(10) VALUE SPACES.
           05  WS-AO-SUM-SEP-2          PIC X(79) VALUE ALL '-'.
           05  WS-AO-TOTAL-LINE.
               10  FILLER               PIC X(20)
                   VALUE 'TOTAL               '.
               10  WS-AO-TOT-COUNT      PIC Z(08)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-TOT-VALUE      PIC $(11)9.99.
               10  FILLER               PIC X(32) VALUE SPACES.
           05  WS-AO-BLANK-2            PIC X(79) VALUE SPACES.
      *
      *    DETAIL SECTION (FOR SELECTED BUCKET)
      *
           05  WS-AO-DTL-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- DETAIL FOR BUCKET ----   '.
               10  WS-AO-DTL-BUCKET     PIC X(12).
               10  FILLER               PIC X(37) VALUE SPACES.
           05  WS-AO-DTL-COL-HDR.
               10  FILLER               PIC X(18)
                   VALUE 'VIN              '.
               10  FILLER               PIC X(05) VALUE 'YEAR '.
               10  FILLER               PIC X(07) VALUE 'MODEL '.
               10  FILLER               PIC X(04) VALUE 'CLR '.
               10  FILLER               PIC X(06) VALUE 'DAYS  '.
               10  FILLER               PIC X(14)
                   VALUE 'INVOICE       '.
               10  FILLER               PIC X(05) VALUE 'ALERT'.
               10  FILLER               PIC X(20) VALUE SPACES.
           05  WS-AO-DTL-LINES.
               10  WS-AO-DTL-LINE       OCCURS 8 TIMES.
                   15  WS-AO-DT-VIN     PIC X(17).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-AO-DT-YEAR    PIC 9(04).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-AO-DT-MODEL   PIC X(06).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-AO-DT-COLOR   PIC X(03).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-AO-DT-DAYS    PIC Z(04)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-AO-DT-INVOICE PIC $(10)9.99.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-AO-DT-ALERT   PIC X(05).
                   15  FILLER            PIC X(14) VALUE SPACES.
           05  WS-AO-FILLER             PIC X(2) VALUE SPACES.
      *
      *    DATE CALC CALL FIELDS
      *
       01  WS-DTE-REQUEST.
           05  WS-DTE-FUNCTION           PIC X(04).
           05  WS-DTE-DATE-1             PIC X(10).
           05  WS-DTE-DATE-2             PIC X(10).
       01  WS-DTE-RESULT.
           05  WS-DTE-RC                 PIC S9(04) COMP.
           05  WS-DTE-DAYS              PIC S9(09) COMP.
           05  WS-DTE-MSG               PIC X(40).
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
      *    PRICE CALL FIELDS
      *
       01  WS-PRC-REQUEST.
           05  WS-PRC-FUNCTION           PIC X(04).
           05  WS-PRC-YEAR               PIC S9(04) COMP.
           05  WS-PRC-MAKE               PIC X(03).
           05  WS-PRC-MODEL              PIC X(06).
       01  WS-PRC-RESULT.
           05  WS-PRC-RC                 PIC S9(04) COMP.
           05  WS-PRC-INVOICE            PIC S9(7)V99 COMP-3.
           05  WS-PRC-MSRP               PIC S9(7)V99 COMP-3.
           05  WS-PRC-MSG                PIC X(40).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-CURRENT-DATE.
               10  WS-CURR-YYYY         PIC 9(04).
               10  WS-CURR-MM           PIC 9(02).
               10  WS-CURR-DD           PIC 9(02).
           05  WS-CURRENT-TIME.
               10  WS-CURR-HH           PIC 9(02).
               10  WS-CURR-MN           PIC 9(02).
               10  WS-CURR-SS           PIC 9(02).
               10  WS-CURR-HS           PIC 9(02).
           05  WS-DIFF-FROM-GMT         PIC S9(04).
           05  WS-FORMATTED-DATE        PIC X(10) VALUE SPACES.
      *
      *    AGING BUCKET ACCUMULATORS
      *
       01  WS-BUCKET-ACCUM.
           05  WS-BUCKET-DATA           OCCURS 4 TIMES.
               10  WS-BK-COUNT          PIC S9(09) COMP VALUE +0.
               10  WS-BK-VALUE          PIC S9(11)V99 COMP-3
                                                       VALUE +0.
               10  WS-BK-TOTAL-DAYS     PIC S9(09) COMP VALUE +0.
               10  WS-BK-AVG-DAYS       PIC S9(09) COMP VALUE +0.
               10  WS-BK-PERCENT        PIC S9(3)V9 COMP-3 VALUE +0.
      *
       01  WS-TOTAL-COUNT               PIC S9(09) COMP VALUE +0.
       01  WS-TOTAL-VALUE               PIC S9(11)V99 COMP-3
                                                       VALUE +0.
      *
      *    CURSOR FETCH WORK AREA
      *
       01  WS-AGE-ROW.
           05  WS-AR-VIN                PIC X(17).
           05  WS-AR-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-AR-MAKE-CODE          PIC X(03).
           05  WS-AR-MODEL-CODE         PIC X(06).
           05  WS-AR-EXT-COLOR          PIC X(03).
           05  WS-AR-DAYS-IN-STOCK      PIC S9(04) COMP.
           05  WS-AR-RECEIVE-DATE       PIC X(10).
      *
       01  WS-BUCKET-IDX               PIC S9(04) COMP VALUE +0.
       01  WS-DTL-IDX                   PIC S9(04) COMP VALUE +0.
       01  WS-INVOICE-AMT              PIC S9(7)V99 COMP-3 VALUE +0.
       01  WS-AGE-DAYS                  PIC S9(09) COMP VALUE +0.
       01  WS-MIN-DAYS                  PIC S9(09) COMP VALUE +0.
       01  WS-MAX-DAYS                  PIC S9(09) COMP VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-RECV-DATE          PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR - ALL VEHICLES FOR AGING
      *
           EXEC SQL
               DECLARE CSR_VEH_AGING CURSOR FOR
               SELECT VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , EXTERIOR_COLOR
                    , DAYS_IN_STOCK
                    , RECEIVE_DATE
               FROM   AUTOSALE.VEHICLE
               WHERE  DEALER_CODE = :WS-AI-DEALER-CODE
                 AND  VEHICLE_STATUS IN ('AV', 'HD', 'AL')
                 AND  RECEIVE_DATE IS NOT NULL
               ORDER BY DAYS_IN_STOCK DESC
           END-EXEC.
      *
      *    CURSOR - DETAIL FOR SPECIFIC BUCKET
      *
           EXEC SQL
               DECLARE CSR_VEH_AGED_DTL CURSOR FOR
               SELECT VIN
                    , MODEL_YEAR
                    , MAKE_CODE
                    , MODEL_CODE
                    , EXTERIOR_COLOR
                    , DAYS_IN_STOCK
                    , RECEIVE_DATE
               FROM   AUTOSALE.VEHICLE
               WHERE  DEALER_CODE = :WS-AI-DEALER-CODE
                 AND  VEHICLE_STATUS IN ('AV', 'HD', 'AL')
                 AND  RECEIVE_DATE IS NOT NULL
                 AND  DAYS_IN_STOCK >= :WS-MIN-DAYS
                 AND  (DAYS_IN_STOCK <= :WS-MAX-DAYS
                       OR :WS-MAX-DAYS = 9999)
               ORDER BY DAYS_IN_STOCK DESC
           END-EXEC.
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
               PERFORM 4000-CALCULATE-AGING-SUMMARY
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FORMAT-SUMMARY
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-AI-DETAIL
               PERFORM 6000-FETCH-BUCKET-DETAIL
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
           INITIALIZE WS-AGE-OUTPUT
           INITIALIZE WS-BUCKET-ACCUM
           MOVE 'VEHAGE00' TO WS-AO-MSG-ID
           MOVE +0 TO WS-TOTAL-COUNT
           MOVE +0 TO WS-TOTAL-VALUE
      *
           MOVE FUNCTION CURRENT-DATE TO
               WS-CURRENT-DATE
               WS-CURRENT-TIME
               WS-DIFF-FROM-GMT
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-DATE
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
               MOVE 'IMS GU FAILED' TO WS-AO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION    TO WS-AI-FUNCTION
               MOVE WS-INP-BODY(1:5)   TO WS-AI-DEALER-CODE
               MOVE WS-INP-BODY(6:1)   TO WS-AI-BUCKET
      *        DEFAULT TO SUMMARY
               IF WS-AI-FUNCTION = SPACES
                   MOVE 'SM' TO WS-AI-FUNCTION
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-AI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-AI-DEALER-CODE TO WS-AO-DEALER-HDR
      *
           IF WS-AI-DETAIL
               IF WS-AI-BUCKET = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'BUCKET IS REQUIRED: 1=0-30 2=31-60 3=61-9'
                     &  '0 4=90+'
                       TO WS-AO-MSG-TEXT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CALCULATE-AGING-SUMMARY - SCAN ALL VEHICLES          *
      ****************************************************************
       4000-CALCULATE-AGING-SUMMARY.
      *
           EXEC SQL
               OPEN CSR_VEH_AGING
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR OPENING AGING CURSOR'
                   TO WS-AO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           PERFORM UNTIL SQLCODE = +100
               EXEC SQL
                   FETCH CSR_VEH_AGING
                   INTO  :WS-AR-VIN
                       , :WS-AR-MODEL-YEAR
                       , :WS-AR-MAKE-CODE
                       , :WS-AR-MODEL-CODE
                       , :WS-AR-EXT-COLOR
                       , :WS-AR-DAYS-IN-STOCK
                       , :WS-AR-RECEIVE-DATE :WS-NI-RECV-DATE
               END-EXEC
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               IF SQLCODE NOT = +0
                   MOVE +12 TO WS-RETURN-CODE
                   MOVE 'DB2 ERROR FETCHING AGING DATA'
                       TO WS-AO-MSG-TEXT
                   EXIT PERFORM
               END-IF
      *
      *        CALL COMDTEL0 TO CALCULATE ACTUAL DAYS AGED
      *
               MOVE 'AGED' TO WS-DTE-FUNCTION
               MOVE WS-AR-RECEIVE-DATE TO WS-DTE-DATE-1
               MOVE WS-FORMATTED-DATE  TO WS-DTE-DATE-2
               CALL 'COMDTEL0' USING WS-DTE-REQUEST
                                     WS-DTE-RESULT
      *
               IF WS-DTE-RC = +0
                   MOVE WS-DTE-DAYS TO WS-AGE-DAYS
               ELSE
                   MOVE WS-AR-DAYS-IN-STOCK TO WS-AGE-DAYS
               END-IF
      *
      *        CALL COMPRCL0 TO GET INVOICE PRICE
      *
               MOVE 'INVC' TO WS-PRC-FUNCTION
               MOVE WS-AR-MODEL-YEAR TO WS-PRC-YEAR
               MOVE WS-AR-MAKE-CODE  TO WS-PRC-MAKE
               MOVE WS-AR-MODEL-CODE TO WS-PRC-MODEL
               CALL 'COMPRCL0' USING WS-PRC-REQUEST
                                     WS-PRC-RESULT
      *
               IF WS-PRC-RC = +0
                   MOVE WS-PRC-INVOICE TO WS-INVOICE-AMT
               ELSE
                   MOVE +0 TO WS-INVOICE-AMT
               END-IF
      *
      *        DETERMINE BUCKET
      *
               EVALUATE TRUE
                   WHEN WS-AGE-DAYS >= 0 AND WS-AGE-DAYS <= 30
                       MOVE 1 TO WS-BUCKET-IDX
                   WHEN WS-AGE-DAYS >= 31 AND WS-AGE-DAYS <= 60
                       MOVE 2 TO WS-BUCKET-IDX
                   WHEN WS-AGE-DAYS >= 61 AND WS-AGE-DAYS <= 90
                       MOVE 3 TO WS-BUCKET-IDX
                   WHEN WS-AGE-DAYS > 90
                       MOVE 4 TO WS-BUCKET-IDX
                   WHEN OTHER
                       MOVE 1 TO WS-BUCKET-IDX
               END-EVALUATE
      *
      *        ACCUMULATE
      *
               ADD +1 TO WS-BK-COUNT(WS-BUCKET-IDX)
               ADD WS-INVOICE-AMT TO WS-BK-VALUE(WS-BUCKET-IDX)
               ADD WS-AGE-DAYS TO WS-BK-TOTAL-DAYS(WS-BUCKET-IDX)
      *
               ADD +1 TO WS-TOTAL-COUNT
               ADD WS-INVOICE-AMT TO WS-TOTAL-VALUE
      *
           END-PERFORM
      *
           EXEC SQL
               CLOSE CSR_VEH_AGING
           END-EXEC
      *
      *    CALCULATE AVERAGES AND PERCENTAGES
      *
           PERFORM VARYING WS-BUCKET-IDX FROM 1 BY 1
               UNTIL WS-BUCKET-IDX > 4
      *
               IF WS-BK-COUNT(WS-BUCKET-IDX) > +0
                   COMPUTE WS-BK-AVG-DAYS(WS-BUCKET-IDX) =
                       WS-BK-TOTAL-DAYS(WS-BUCKET-IDX) /
                       WS-BK-COUNT(WS-BUCKET-IDX)
               END-IF
      *
               IF WS-TOTAL-COUNT > +0
                   COMPUTE WS-BK-PERCENT(WS-BUCKET-IDX) =
                       (WS-BK-COUNT(WS-BUCKET-IDX) * 100.0) /
                       WS-TOTAL-COUNT
               END-IF
      *
           END-PERFORM
      *
           IF WS-TOTAL-COUNT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO VEHICLES WITH RECEIVE DATE IN INVENTORY'
                   TO WS-AO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-FORMAT-SUMMARY - MOVE ACCUMULATORS TO OUTPUT         *
      ****************************************************************
       5000-FORMAT-SUMMARY.
      *
      *    BUCKET 1: 0-30 DAYS
      *
           MOVE WS-BK-COUNT(1)      TO WS-AO-B1-COUNT
           MOVE WS-BK-VALUE(1)      TO WS-AO-B1-VALUE
           MOVE WS-BK-AVG-DAYS(1)   TO WS-AO-B1-AVG-DAYS
           MOVE WS-BK-PERCENT(1)    TO WS-AO-B1-PCT
      *
      *    BUCKET 2: 31-60 DAYS
      *
           MOVE WS-BK-COUNT(2)      TO WS-AO-B2-COUNT
           MOVE WS-BK-VALUE(2)      TO WS-AO-B2-VALUE
           MOVE WS-BK-AVG-DAYS(2)   TO WS-AO-B2-AVG-DAYS
           MOVE WS-BK-PERCENT(2)    TO WS-AO-B2-PCT
      *
      *    BUCKET 3: 61-90 DAYS
      *
           MOVE WS-BK-COUNT(3)      TO WS-AO-B3-COUNT
           MOVE WS-BK-VALUE(3)      TO WS-AO-B3-VALUE
           MOVE WS-BK-AVG-DAYS(3)   TO WS-AO-B3-AVG-DAYS
           MOVE WS-BK-PERCENT(3)    TO WS-AO-B3-PCT
      *
      *    BUCKET 4: 90+ DAYS (AGED)
      *
           MOVE WS-BK-COUNT(4)      TO WS-AO-B4-COUNT
           MOVE WS-BK-VALUE(4)      TO WS-AO-B4-VALUE
           MOVE WS-BK-AVG-DAYS(4)   TO WS-AO-B4-AVG-DAYS
           MOVE WS-BK-PERCENT(4)    TO WS-AO-B4-PCT
      *
      *    TOTALS
      *
           MOVE WS-TOTAL-COUNT      TO WS-AO-TOT-COUNT
           MOVE WS-TOTAL-VALUE      TO WS-AO-TOT-VALUE
      *
      *    CALL COMFMTL0 FOR CURRENCY FORMATTING
      *
           MOVE 'CURR' TO WS-FMT-FUNCTION
           CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                  WS-FMT-RESULT
      *
           IF WS-BK-COUNT(4) > +0
               STRING 'AGING SUMMARY - WARNING: '
                      WS-BK-COUNT(4)
                      ' VEHICLES OVER 90 DAYS!'
                      DELIMITED BY SIZE
                      INTO WS-AO-MSG-TEXT
           ELSE
               MOVE 'INVENTORY AGING SUMMARY COMPLETE'
                   TO WS-AO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    6000-FETCH-BUCKET-DETAIL - LIST VEHICLES IN BUCKET        *
      ****************************************************************
       6000-FETCH-BUCKET-DETAIL.
      *
      *    DETERMINE DAY RANGE FOR SELECTED BUCKET
      *
           EVALUATE WS-AI-BUCKET
               WHEN '1'
                   MOVE +0    TO WS-MIN-DAYS
                   MOVE +30   TO WS-MAX-DAYS
                   MOVE '0-30 DAYS   ' TO WS-AO-DTL-BUCKET
               WHEN '2'
                   MOVE +31   TO WS-MIN-DAYS
                   MOVE +60   TO WS-MAX-DAYS
                   MOVE '31-60 DAYS  ' TO WS-AO-DTL-BUCKET
               WHEN '3'
                   MOVE +61   TO WS-MIN-DAYS
                   MOVE +90   TO WS-MAX-DAYS
                   MOVE '61-90 DAYS  ' TO WS-AO-DTL-BUCKET
               WHEN '4'
                   MOVE +91   TO WS-MIN-DAYS
                   MOVE +9999 TO WS-MAX-DAYS
                   MOVE '90+ DAYS    ' TO WS-AO-DTL-BUCKET
           END-EVALUATE
      *
           EXEC SQL
               OPEN CSR_VEH_AGED_DTL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 6000-EXIT
           END-IF
      *
           MOVE +0 TO WS-DTL-IDX
      *
           PERFORM UNTIL WS-DTL-IDX >= 8
               EXEC SQL
                   FETCH CSR_VEH_AGED_DTL
                   INTO  :WS-AR-VIN
                       , :WS-AR-MODEL-YEAR
                       , :WS-AR-MAKE-CODE
                       , :WS-AR-MODEL-CODE
                       , :WS-AR-EXT-COLOR
                       , :WS-AR-DAYS-IN-STOCK
                       , :WS-AR-RECEIVE-DATE :WS-NI-RECV-DATE
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
               ADD +1 TO WS-DTL-IDX
      *
               MOVE WS-AR-VIN        TO
                   WS-AO-DT-VIN(WS-DTL-IDX)
               MOVE WS-AR-MODEL-YEAR TO
                   WS-AO-DT-YEAR(WS-DTL-IDX)
               MOVE WS-AR-MODEL-CODE TO
                   WS-AO-DT-MODEL(WS-DTL-IDX)
               MOVE WS-AR-EXT-COLOR  TO
                   WS-AO-DT-COLOR(WS-DTL-IDX)
               MOVE WS-AR-DAYS-IN-STOCK TO
                   WS-AO-DT-DAYS(WS-DTL-IDX)
      *
      *        GET INVOICE PRICE FOR EACH VEHICLE
      *
               MOVE 'INVC' TO WS-PRC-FUNCTION
               MOVE WS-AR-MODEL-YEAR TO WS-PRC-YEAR
               MOVE WS-AR-MAKE-CODE  TO WS-PRC-MAKE
               MOVE WS-AR-MODEL-CODE TO WS-PRC-MODEL
               CALL 'COMPRCL0' USING WS-PRC-REQUEST
                                     WS-PRC-RESULT
      *
               IF WS-PRC-RC = +0
                   MOVE WS-PRC-INVOICE TO
                       WS-AO-DT-INVOICE(WS-DTL-IDX)
               END-IF
      *
      *        FLAG AGED VEHICLES (90+ DAYS)
      *
               IF WS-AR-DAYS-IN-STOCK > 90
                   MOVE '**AG*' TO
                       WS-AO-DT-ALERT(WS-DTL-IDX)
               ELSE
                   MOVE SPACES TO
                       WS-AO-DT-ALERT(WS-DTL-IDX)
               END-IF
      *
           END-PERFORM
      *
           EXEC SQL
               CLOSE CSR_VEH_AGED_DTL
           END-EXEC
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-AGE-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHAGE00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHAGE00                                              *
      ****************************************************************
