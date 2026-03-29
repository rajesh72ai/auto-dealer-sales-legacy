       IDENTIFICATION DIVISION.
       PROGRAM-ID. PLIRECON.
      ****************************************************************
      * PROGRAM:  PLIRECON                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   PRODUCTION & LOGISTICS - PROD-TO-STOCK RECONCILE   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  COMPARES PRODUCTION_ORDER VS VEHICLE TABLES TO     *
      *           FIND DISCREPANCIES. IDENTIFIES: PRODUCED BUT NOT   *
      *           IN VEHICLE TABLE, ALLOCATED BUT NOT SHIPPED,       *
      *           SHIPPED BUT NOT DELIVERED. USES MULTI-TABLE JOIN   *
      *           WITH STATUS CHECKS. SHOWS EXCEPTION LIST WITH      *
      *           REASON CODES. SUMMARY: TOTAL PRODUCED, ALLOCATED,  *
      *           SHIPPED, DELIVERED, EXCEPTIONS. DISPLAY-ONLY.      *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    PLRC - PRODUCTION RECONCILIATION                   *
      * CALLS:    COMDTEL0 - DATE CALCULATIONS                       *
      *           COMFMTL0 - FORMATTING UTILITY                      *
      *           COMMSGL0 - MESSAGE BUILDER                         *
      * TABLES:   AUTOSALE.PRODUCTION_ORDER (READ)                   *
      *           AUTOSALE.VEHICLE          (READ)                    *
      *           AUTOSALE.SHIPMENT         (READ)                   *
      *           AUTOSALE.SHIPMENT_VEHICLE (READ)                   *
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
                                          VALUE 'PLIRECON'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-ABEND-CODE             PIC X(04)
                                          VALUE SPACES.
      *
      *    IMS FUNCTION CODES
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
      *    INPUT FIELDS - RECONCILIATION FILTER
      *
       01  WS-RECON-INPUT.
           05  WS-RI-FUNCTION            PIC X(02).
               88  WS-RI-SUMMARY                    VALUE 'SM'.
               88  WS-RI-EXCEPTIONS                 VALUE 'EX'.
               88  WS-RI-FULL                       VALUE 'FL'.
           05  WS-RI-PLANT-CODE          PIC X(05).
           05  WS-RI-MODEL-YEAR          PIC 9(04).
           05  WS-RI-MAKE-CODE           PIC X(03).
           05  WS-RI-DATE-FROM           PIC X(10).
           05  WS-RI-DATE-TO             PIC X(10).
      *
      *    OUTPUT MESSAGE FIELDS
      *
       01  WS-RECON-OUTPUT.
           05  WS-RO-STATUS-LINE.
               10  WS-RO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-MSG-TEXT       PIC X(70).
           05  WS-RO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-RO-TITLE-LINE.
               10  FILLER               PIC X(42)
                   VALUE 'PRODUCTION-TO-STOCK RECONCILIATION REPORT'.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'DATE: '.
               10  WS-RO-RPT-DATE       PIC X(10).
               10  FILLER               PIC X(17) VALUE SPACES.
           05  WS-RO-FILTER-LINE.
               10  FILLER               PIC X(08)
                   VALUE 'FILTER: '.
               10  FILLER               PIC X(07) VALUE 'PLANT: '.
               10  WS-RO-PLANT          PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-RO-YEAR           PIC 9(04).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-RO-MAKE           PIC X(03).
               10  FILLER               PIC X(32) VALUE SPACES.
           05  WS-RO-SUMM-HEADER.
               10  FILLER               PIC X(79)
                   VALUE '--- SUMMARY COUNTS -------------------
      -           '---------------------------------------'.
           05  WS-RO-SUMM-PRODUCED.
               10  FILLER               PIC X(25)
                   VALUE 'TOTAL PRODUCED:          '.
               10  WS-RO-CNT-PRODUCED   PIC Z(06)9.
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-RO-SUMM-ALLOCATED.
               10  FILLER               PIC X(25)
                   VALUE 'TOTAL ALLOCATED:         '.
               10  WS-RO-CNT-ALLOCATED  PIC Z(06)9.
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-RO-SUMM-SHIPPED.
               10  FILLER               PIC X(25)
                   VALUE 'TOTAL SHIPPED:           '.
               10  WS-RO-CNT-SHIPPED    PIC Z(06)9.
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-RO-SUMM-DELIVERED.
               10  FILLER               PIC X(25)
                   VALUE 'TOTAL DELIVERED:         '.
               10  WS-RO-CNT-DELIVERED  PIC Z(06)9.
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-RO-SUMM-EXCEPTIONS.
               10  FILLER               PIC X(25)
                   VALUE 'TOTAL EXCEPTIONS:        '.
               10  WS-RO-CNT-EXCEPTIONS PIC Z(06)9.
               10  FILLER               PIC X(47) VALUE SPACES.
           05  WS-RO-EXC-HEADER.
               10  FILLER               PIC X(79)
                   VALUE '--- EXCEPTION DETAILS ----------------
      -           '---------------------------------------'.
           05  WS-RO-EXC-DETAIL OCCURS 10 TIMES.
               10  WS-RO-ED-VIN         PIC X(17).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-ED-PROD-STAT   PIC X(02).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-ED-VEH-STAT    PIC X(02).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-ED-REASON      PIC X(02).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-ED-REASON-DESC PIC X(35).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-ED-DAYS        PIC Z(03)9.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-RO-ED-PLANT       PIC X(05).
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-RO-FILLER             PIC X(538) VALUE SPACES.
      *
      *    DATE CALCULATION CALL FIELDS
      *
       01  WS-DTE-FUNCTION               PIC X(04).
       01  WS-DTE-DATE-1                 PIC X(10).
       01  WS-DTE-DATE-2                 PIC X(10).
       01  WS-DTE-RESULT                 PIC S9(09) COMP.
       01  WS-DTE-RETURN-CODE            PIC S9(04) COMP.
       01  WS-DTE-ERROR-MSG              PIC X(50).
      *
      *    FORMAT UTILITY CALL FIELDS
      *
       01  WS-FMT-FUNCTION               PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA        PIC X(40).
           05  WS-FMT-INPUT-NUM          PIC S9(09)V99 COMP-3.
       01  WS-FMT-OUTPUT                 PIC X(40).
       01  WS-FMT-RETURN-CODE            PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG              PIC X(50).
      *
      *    MESSAGE BUILDER CALL FIELDS
      *
       01  WS-MSG-FUNCTION               PIC X(04).
       01  WS-MSG-TEXT                    PIC X(79).
       01  WS-MSG-SEVERITY               PIC X(04).
       01  WS-MSG-PROGRAM-ID             PIC X(08).
       01  WS-MSG-OUTPUT-AREA            PIC X(256).
       01  WS-MSG-RETURN-CODE            PIC S9(04) COMP.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
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
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-CNT-PRODUCED          PIC S9(07) COMP VALUE +0.
           05  WS-CNT-ALLOCATED         PIC S9(07) COMP VALUE +0.
           05  WS-CNT-SHIPPED           PIC S9(07) COMP VALUE +0.
           05  WS-CNT-DELIVERED         PIC S9(07) COMP VALUE +0.
           05  WS-CNT-EXCEPTIONS        PIC S9(07) COMP VALUE +0.
           05  WS-EXC-ROW-COUNT         PIC S9(04) COMP VALUE +0.
           05  WS-EOF-FLAG              PIC X(01) VALUE 'N'.
               88  WS-END-OF-DATA                  VALUE 'Y'.
               88  WS-MORE-DATA                    VALUE 'N'.
           05  WS-FILTER-YEAR           PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR FOR EXCEPTION DETAILS
      *    REASON CODES:
      *      NV = PRODUCED BUT NO VEHICLE RECORD
      *      NS = ALLOCATED BUT NOT SHIPPED (> 14 DAYS)
      *      ND = SHIPPED BUT NOT DELIVERED (> 21 DAYS)
      *      SM = STATUS MISMATCH (PROD VS VEHICLE)
      *
           EXEC SQL DECLARE CSR_EXCEPTIONS CURSOR FOR
               SELECT P.VIN
                    , P.PROD_STATUS
                    , COALESCE(V.VEHICLE_STATUS, '--')
                    , CASE
                        WHEN V.VIN IS NULL
                            THEN 'NV'
                        WHEN P.PROD_STATUS = 'AL'
                         AND V.VEHICLE_STATUS = 'AL'
                         AND DAYS(CURRENT DATE) - DAYS(P.UPDATED_TS)
                             > 14
                            THEN 'NS'
                        WHEN V.VEHICLE_STATUS = 'SH'
                         AND DAYS(CURRENT DATE) - DAYS(V.UPDATED_TS)
                             > 21
                            THEN 'ND'
                        WHEN P.PROD_STATUS <> V.VEHICLE_STATUS
                         AND P.PROD_STATUS <> 'PR'
                            THEN 'SM'
                        ELSE 'OK'
                      END AS REASON_CODE
                    , P.PLANT_CODE
                    , P.BUILD_DATE
               FROM   AUTOSALE.PRODUCTION_ORDER P
               LEFT JOIN AUTOSALE.VEHICLE V
                 ON   V.VIN = P.VIN
               WHERE  (P.PLANT_CODE = :WS-RI-PLANT-CODE
                       OR :WS-RI-PLANT-CODE = '     ')
                 AND  (P.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (P.MAKE_CODE   = :WS-RI-MAKE-CODE
                       OR :WS-RI-MAKE-CODE = '   ')
                 AND  CASE
                        WHEN V.VIN IS NULL THEN 'NV'
                        WHEN P.PROD_STATUS = 'AL'
                         AND V.VEHICLE_STATUS = 'AL'
                         AND DAYS(CURRENT DATE) - DAYS(P.UPDATED_TS)
                             > 14 THEN 'NS'
                        WHEN V.VEHICLE_STATUS = 'SH'
                         AND DAYS(CURRENT DATE) - DAYS(V.UPDATED_TS)
                             > 21 THEN 'ND'
                        WHEN P.PROD_STATUS <> V.VEHICLE_STATUS
                         AND P.PROD_STATUS <> 'PR' THEN 'SM'
                        ELSE 'OK'
                      END <> 'OK'
               ORDER BY P.PLANT_CODE, P.BUILD_DATE
           END-EXEC
      *
      *    HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HV-EXC.
           05  WS-HV-VIN                PIC X(17).
           05  WS-HV-PROD-STAT          PIC X(02).
           05  WS-HV-VEH-STAT           PIC X(02).
           05  WS-HV-REASON             PIC X(02).
           05  WS-HV-PLANT              PIC X(05).
           05  WS-HV-BUILD-DATE         PIC X(10).
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
               PERFORM 3000-LOAD-SUMMARY-COUNTS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN WS-RI-SUMMARY
                       CONTINUE
                   WHEN WS-RI-EXCEPTIONS
                       PERFORM 4000-LOAD-EXCEPTIONS
                   WHEN WS-RI-FULL
                       PERFORM 4000-LOAD-EXCEPTIONS
                   WHEN OTHER
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'INVALID FUNCTION - USE SM, EX, OR FL'
                           TO WS-RO-MSG-TEXT
               END-EVALUATE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FORMAT-REPORT
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
           INITIALIZE WS-RECON-OUTPUT
           MOVE 'PLIRECON' TO WS-RO-MSG-ID
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
      *    2000-RECEIVE-INPUT - GU CALL ON IO-PCB                    *
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
                   TO WS-RO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-RI-FUNCTION
               MOVE WS-INP-BODY(1:5)    TO WS-RI-PLANT-CODE
               MOVE WS-INP-BODY(6:4)    TO WS-RI-MODEL-YEAR
               MOVE WS-INP-BODY(10:3)   TO WS-RI-MAKE-CODE
               MOVE WS-INP-BODY(13:10)  TO WS-RI-DATE-FROM
               MOVE WS-INP-BODY(23:10)  TO WS-RI-DATE-TO
           END-IF
      *
      *    CONVERT MODEL YEAR FOR FILTER
      *
           IF WS-RI-MODEL-YEAR > 0
               MOVE WS-RI-MODEL-YEAR TO WS-FILTER-YEAR
           ELSE
               MOVE +0 TO WS-FILTER-YEAR
           END-IF
           .
      *
      ****************************************************************
      *    3000-LOAD-SUMMARY-COUNTS - GET STATUS TOTALS               *
      ****************************************************************
       3000-LOAD-SUMMARY-COUNTS.
      *
      *    COUNT TOTAL PRODUCED
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-CNT-PRODUCED
               FROM   AUTOSALE.PRODUCTION_ORDER P
               WHERE  (P.PLANT_CODE = :WS-RI-PLANT-CODE
                       OR :WS-RI-PLANT-CODE = '     ')
                 AND  (P.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (P.MAKE_CODE   = :WS-RI-MAKE-CODE
                       OR :WS-RI-MAKE-CODE = '   ')
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR COUNTING PRODUCTION ORDERS'
                   TO WS-RO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    COUNT ALLOCATED
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-CNT-ALLOCATED
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VEHICLE_STATUS IN ('AL', 'SH', 'DL', 'AV')
                 AND  (V.PLANT_CODE = :WS-RI-PLANT-CODE
                       OR :WS-RI-PLANT-CODE = '     ')
                 AND  (V.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (V.MAKE_CODE   = :WS-RI-MAKE-CODE
                       OR :WS-RI-MAKE-CODE = '   ')
           END-EXEC
      *
      *    COUNT SHIPPED
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-CNT-SHIPPED
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VEHICLE_STATUS IN ('SH', 'DL', 'AV')
                 AND  (V.PLANT_CODE = :WS-RI-PLANT-CODE
                       OR :WS-RI-PLANT-CODE = '     ')
                 AND  (V.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (V.MAKE_CODE   = :WS-RI-MAKE-CODE
                       OR :WS-RI-MAKE-CODE = '   ')
           END-EXEC
      *
      *    COUNT DELIVERED
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-CNT-DELIVERED
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.VEHICLE_STATUS IN ('DL', 'AV')
                 AND  (V.PLANT_CODE = :WS-RI-PLANT-CODE
                       OR :WS-RI-PLANT-CODE = '     ')
                 AND  (V.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (V.MAKE_CODE   = :WS-RI-MAKE-CODE
                       OR :WS-RI-MAKE-CODE = '   ')
           END-EXEC
      *
      *    COUNT EXCEPTIONS (PRODUCED WITH NO VEHICLE RECORD +
      *    ALLOCATED > 14 DAYS + SHIPPED > 21 DAYS + MISMATCHES)
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-CNT-EXCEPTIONS
               FROM   AUTOSALE.PRODUCTION_ORDER P
               LEFT JOIN AUTOSALE.VEHICLE V
                 ON   V.VIN = P.VIN
               WHERE  (P.PLANT_CODE = :WS-RI-PLANT-CODE
                       OR :WS-RI-PLANT-CODE = '     ')
                 AND  (P.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (P.MAKE_CODE   = :WS-RI-MAKE-CODE
                       OR :WS-RI-MAKE-CODE = '   ')
                 AND  (V.VIN IS NULL
                    OR (P.PROD_STATUS = 'AL'
                        AND V.VEHICLE_STATUS = 'AL'
                        AND DAYS(CURRENT DATE)
                            - DAYS(P.UPDATED_TS) > 14)
                    OR (V.VEHICLE_STATUS = 'SH'
                        AND DAYS(CURRENT DATE)
                            - DAYS(V.UPDATED_TS) > 21)
                    OR (P.PROD_STATUS <> V.VEHICLE_STATUS
                        AND P.PROD_STATUS <> 'PR'))
           END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOAD-EXCEPTIONS - CURSOR FOR EXCEPTION DETAIL          *
      ****************************************************************
       4000-LOAD-EXCEPTIONS.
      *
           EXEC SQL OPEN CSR_EXCEPTIONS END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR OPENING EXCEPTION CURSOR'
                   TO WS-RO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-EXC-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 4100-FETCH-EXCEPTION
               UNTIL WS-END-OF-DATA
               OR WS-EXC-ROW-COUNT >= +10
      *
           EXEC SQL CLOSE CSR_EXCEPTIONS END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-EXCEPTION - FETCH AND FORMAT EXCEPTION ROW       *
      ****************************************************************
       4100-FETCH-EXCEPTION.
      *
           EXEC SQL FETCH CSR_EXCEPTIONS
               INTO  :WS-HV-VIN
                    , :WS-HV-PROD-STAT
                    , :WS-HV-VEH-STAT
                    , :WS-HV-REASON
                    , :WS-HV-PLANT
                    , :WS-HV-BUILD-DATE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-EXC-ROW-COUNT
                   PERFORM 4200-FORMAT-EXCEPTION-ROW
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'DB2 ERROR FETCHING EXCEPTIONS'
                       TO WS-RO-MSG-TEXT
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4200-FORMAT-EXCEPTION-ROW - POPULATE DETAIL LINE            *
      ****************************************************************
       4200-FORMAT-EXCEPTION-ROW.
      *
           MOVE WS-HV-VIN
               TO WS-RO-ED-VIN(WS-EXC-ROW-COUNT)
           MOVE WS-HV-PROD-STAT
               TO WS-RO-ED-PROD-STAT(WS-EXC-ROW-COUNT)
           MOVE WS-HV-VEH-STAT
               TO WS-RO-ED-VEH-STAT(WS-EXC-ROW-COUNT)
           MOVE WS-HV-REASON
               TO WS-RO-ED-REASON(WS-EXC-ROW-COUNT)
           MOVE WS-HV-PLANT
               TO WS-RO-ED-PLANT(WS-EXC-ROW-COUNT)
      *
      *    RESOLVE REASON DESCRIPTION
      *
           EVALUATE WS-HV-REASON
               WHEN 'NV'
                   MOVE 'PRODUCED - NO VEHICLE RECORD'
                       TO WS-RO-ED-REASON-DESC(WS-EXC-ROW-COUNT)
               WHEN 'NS'
                   MOVE 'ALLOCATED > 14 DAYS - NOT SHIPPED'
                       TO WS-RO-ED-REASON-DESC(WS-EXC-ROW-COUNT)
               WHEN 'ND'
                   MOVE 'SHIPPED > 21 DAYS - NOT DELIVERED'
                       TO WS-RO-ED-REASON-DESC(WS-EXC-ROW-COUNT)
               WHEN 'SM'
                   MOVE 'STATUS MISMATCH PROD VS VEHICLE'
                       TO WS-RO-ED-REASON-DESC(WS-EXC-ROW-COUNT)
               WHEN OTHER
                   MOVE 'UNKNOWN EXCEPTION'
                       TO WS-RO-ED-REASON-DESC(WS-EXC-ROW-COUNT)
           END-EVALUATE
      *
      *    CALCULATE DAYS SINCE BUILD
      *
           MOVE 'DAYS' TO WS-DTE-FUNCTION
           MOVE WS-HV-BUILD-DATE TO WS-DTE-DATE-1
           MOVE WS-FORMATTED-DATE TO WS-DTE-DATE-2
      *
           CALL 'COMDTEL0' USING WS-DTE-FUNCTION
                                 WS-DTE-DATE-1
                                 WS-DTE-DATE-2
                                 WS-DTE-RESULT
                                 WS-DTE-RETURN-CODE
                                 WS-DTE-ERROR-MSG
      *
           IF WS-DTE-RETURN-CODE = +0
               MOVE WS-DTE-RESULT
                   TO WS-RO-ED-DAYS(WS-EXC-ROW-COUNT)
           ELSE
               MOVE +0
                   TO WS-RO-ED-DAYS(WS-EXC-ROW-COUNT)
           END-IF
           .
      *
      ****************************************************************
      *    5000-FORMAT-REPORT - ASSEMBLE FINAL OUTPUT                  *
      ****************************************************************
       5000-FORMAT-REPORT.
      *
           MOVE WS-FORMATTED-DATE    TO WS-RO-RPT-DATE
           MOVE WS-RI-PLANT-CODE     TO WS-RO-PLANT
           MOVE WS-RI-MODEL-YEAR     TO WS-RO-YEAR
           MOVE WS-RI-MAKE-CODE      TO WS-RO-MAKE
      *
           MOVE WS-CNT-PRODUCED      TO WS-RO-CNT-PRODUCED
           MOVE WS-CNT-ALLOCATED     TO WS-RO-CNT-ALLOCATED
           MOVE WS-CNT-SHIPPED       TO WS-RO-CNT-SHIPPED
           MOVE WS-CNT-DELIVERED     TO WS-RO-CNT-DELIVERED
           MOVE WS-CNT-EXCEPTIONS    TO WS-RO-CNT-EXCEPTIONS
      *
      *    FORMAT SUMMARY MESSAGE
      *
           IF WS-CNT-EXCEPTIONS = +0
               MOVE 'RECONCILIATION COMPLETE - NO EXCEPTIONS'
                   TO WS-RO-MSG-TEXT
           ELSE
               STRING 'RECONCILIATION COMPLETE - '
                      WS-CNT-EXCEPTIONS
                      ' EXCEPTIONS FOUND'
                      DELIMITED BY SIZE
                      INTO WS-RO-MSG-TEXT
           END-IF
      *
      *    CALL MESSAGE BUILDER FOR FORMATTING
      *
           MOVE 'INFO' TO WS-MSG-FUNCTION
           MOVE WS-RO-MSG-TEXT TO WS-MSG-TEXT
           MOVE 'I   ' TO WS-MSG-SEVERITY
           MOVE WS-PROGRAM-NAME TO WS-MSG-PROGRAM-ID
      *
           CALL 'COMMSGL0' USING WS-MSG-FUNCTION
                                 WS-MSG-TEXT
                                 WS-MSG-SEVERITY
                                 WS-MSG-PROGRAM-ID
                                 WS-MSG-OUTPUT-AREA
                                 WS-MSG-RETURN-CODE
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-RECON-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'PLIRECON' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF PLIRECON                                               *
      ****************************************************************
