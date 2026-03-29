       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHLST00.
      ****************************************************************
      * PROGRAM:  VEHLST00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - INVENTORY LISTING BY DEALER/MODEL/STATUS *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SCROLLABLE LIST OF VEHICLES WITH FILTERS.          *
      *           INPUT: DEALER CODE (REQUIRED), OPTIONAL MODEL      *
      *           YEAR, MAKE, MODEL, STATUS, COLOR. DECLARE CURSOR   *
      *           WITH DYNAMIC WHERE CLAUSE BUILDING. DISPLAYS 12    *
      *           VEHICLES PER PAGE: VIN, STOCK#, YEAR, MODEL,       *
      *           COLOR, STATUS, DAYS, LOCATION. PF7/PF8 PAGING.    *
      *           SHOWS COUNT: "SHOWING 1-12 OF 47".                 *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHLS - VEHICLE LISTING                             *
      * CALLS:    COMFMTL0 - FORMAT DISPLAY FIELDS                  *
      *           COMMSGL0 - MESSAGE FORMATTING                      *
      * TABLES:   AUTOSALE.VEHICLE                                   *
      *           AUTOSALE.MODEL_MASTER                               *
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
                                          VALUE 'VEHLST00'.
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
      *    INPUT FIELDS - FILTER CRITERIA
      *
       01  WS-LIST-INPUT.
           05  WS-LI-FUNCTION            PIC X(02).
               88  WS-LI-SEARCH                     VALUE 'SR'.
               88  WS-LI-NEXT-PAGE                  VALUE 'NX'.
               88  WS-LI-PREV-PAGE                  VALUE 'PV'.
           05  WS-LI-DEALER-CODE         PIC X(05).
           05  WS-LI-MODEL-YEAR          PIC 9(04).
           05  WS-LI-MAKE-CODE           PIC X(03).
           05  WS-LI-MODEL-CODE          PIC X(06).
           05  WS-LI-STATUS              PIC X(02).
           05  WS-LI-COLOR               PIC X(03).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-LIST-OUTPUT.
           05  WS-LO-STATUS-LINE.
               10  WS-LO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LO-MSG-TEXT       PIC X(70).
           05  WS-LO-TITLE-LINE.
               10  FILLER               PIC X(30)
                   VALUE 'VEHICLE INVENTORY LISTING     '.
               10  FILLER               PIC X(10)
                   VALUE 'DEALER:   '.
               10  WS-LO-DEALER-HDR     PIC X(05).
               10  FILLER               PIC X(34) VALUE SPACES.
           05  WS-LO-FILTER-LINE.
               10  FILLER               PIC X(09) VALUE 'FILTERS: '.
               10  WS-LO-FILTER-DESC    PIC X(70).
           05  WS-LO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-LO-COL-HEADER.
               10  FILLER               PIC X(18)
                   VALUE 'VIN              '.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  FILLER               PIC X(09)
                   VALUE 'STOCK#  '.
               10  FILLER               PIC X(05)
                   VALUE 'YEAR '.
               10  FILLER               PIC X(07)
                   VALUE 'MODEL '.
               10  FILLER               PIC X(04)
                   VALUE 'CLR '.
               10  FILLER               PIC X(04)
                   VALUE 'ST '.
               10  FILLER               PIC X(06)
                   VALUE 'DAYS '.
               10  FILLER               PIC X(07)
                   VALUE 'LOT   '.
               10  FILLER               PIC X(18) VALUE SPACES.
           05  WS-LO-SEP-LINE           PIC X(79) VALUE ALL '-'.
           05  WS-LO-DETAIL-LINES.
               10  WS-LO-DETAIL         OCCURS 12 TIMES.
                   15  WS-LO-DT-VIN     PIC X(17).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-STOCK   PIC X(08).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-YEAR    PIC 9(04).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-MODEL   PIC X(06).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-COLOR   PIC X(03).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-STATUS  PIC X(02).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-DAYS    PIC Z(04)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-DT-LOT     PIC X(06).
                   15  FILLER            PIC X(19) VALUE SPACES.
           05  WS-LO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-LO-COUNT-LINE.
               10  FILLER               PIC X(08) VALUE 'SHOWING '.
               10  WS-LO-SHOW-FROM      PIC Z(04)9.
               10  FILLER               PIC X(01) VALUE '-'.
               10  WS-LO-SHOW-TO        PIC Z(04)9.
               10  FILLER               PIC X(04) VALUE ' OF '.
               10  WS-LO-TOTAL-COUNT    PIC Z(04)9.
               10  FILLER               PIC X(08) VALUE SPACES.
               10  FILLER               PIC X(36)
                   VALUE 'PF7=PREV  PF8=NEXT  PF3=EXIT       '.
           05  WS-LO-FILLER             PIC X(372) VALUE SPACES.
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
      *    MESSAGE CALL FIELDS
      *
       01  WS-MSGL-REQUEST.
           05  WS-MSGL-CODE             PIC X(08).
           05  WS-MSGL-DATA             PIC X(40).
       01  WS-MSGL-RESULT.
           05  WS-MSGL-RC               PIC S9(04) COMP.
           05  WS-MSGL-TEXT             PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-ROWS            PIC S9(09) COMP VALUE +0.
           05  WS-PAGE-SIZE             PIC S9(04) COMP VALUE +12.
           05  WS-CURRENT-PAGE          PIC S9(04) COMP VALUE +1.
           05  WS-OFFSET                PIC S9(09) COMP VALUE +0.
           05  WS-ROW-IDX              PIC S9(04) COMP VALUE +0.
           05  WS-FETCH-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-SHOW-FROM             PIC S9(09) COMP VALUE +0.
           05  WS-SHOW-TO               PIC S9(09) COMP VALUE +0.
           05  WS-SKIP-COUNT            PIC S9(09) COMP VALUE +0.
           05  WS-FILTER-TEXT           PIC X(70) VALUE SPACES.
           05  WS-FILTER-POS            PIC S9(04) COMP VALUE +1.
      *
      *    CURSOR FETCH WORK AREA
      *
       01  WS-VEH-ROW.
           05  WS-VR-VIN                PIC X(17).
           05  WS-VR-STOCK-NUM          PIC X(08).
           05  WS-VR-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-VR-MODEL-CODE         PIC X(06).
           05  WS-VR-EXT-COLOR          PIC X(03).
           05  WS-VR-STATUS             PIC X(02).
           05  WS-VR-DAYS               PIC S9(04) COMP.
           05  WS-VR-LOT-LOC            PIC X(06).
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-STOCK-NUM          PIC S9(04) COMP VALUE +0.
           05  WS-NI-LOT-LOC            PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR DECLARATIONS
      *    BASE CURSOR - FILTERED BY DEALER AND OPTIONAL CRITERIA
      *    USES PARAMETER MARKERS WITH COALESCE FOR OPTIONAL FILTERS
      *
           EXEC SQL
               DECLARE CSR_VEH_LIST CURSOR FOR
               SELECT V.VIN
                    , V.STOCK_NUMBER
                    , V.MODEL_YEAR
                    , V.MODEL_CODE
                    , V.EXTERIOR_COLOR
                    , V.VEHICLE_STATUS
                    , V.DAYS_IN_STOCK
                    , V.LOT_LOCATION
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.DEALER_CODE = :WS-LI-DEALER-CODE
                 AND  (V.MODEL_YEAR = :WS-LI-MODEL-YEAR
                       OR :WS-LI-MODEL-YEAR = 0)
                 AND  (V.MAKE_CODE = :WS-LI-MAKE-CODE
                       OR :WS-LI-MAKE-CODE = '   ')
                 AND  (V.MODEL_CODE = :WS-LI-MODEL-CODE
                       OR :WS-LI-MODEL-CODE = '      ')
                 AND  (V.VEHICLE_STATUS = :WS-LI-STATUS
                       OR :WS-LI-STATUS = '  ')
                 AND  (V.EXTERIOR_COLOR = :WS-LI-COLOR
                       OR :WS-LI-COLOR = '   ')
               ORDER BY V.DAYS_IN_STOCK DESC
                      , V.VIN
           END-EXEC.
      *
      *    COUNT CURSOR
      *
           EXEC SQL
               DECLARE CSR_VEH_COUNT CURSOR FOR
               SELECT COUNT(*)
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.DEALER_CODE = :WS-LI-DEALER-CODE
                 AND  (V.MODEL_YEAR = :WS-LI-MODEL-YEAR
                       OR :WS-LI-MODEL-YEAR = 0)
                 AND  (V.MAKE_CODE = :WS-LI-MAKE-CODE
                       OR :WS-LI-MAKE-CODE = '   ')
                 AND  (V.MODEL_CODE = :WS-LI-MODEL-CODE
                       OR :WS-LI-MODEL-CODE = '      ')
                 AND  (V.VEHICLE_STATUS = :WS-LI-STATUS
                       OR :WS-LI-STATUS = '  ')
                 AND  (V.EXTERIOR_COLOR = :WS-LI-COLOR
                       OR :WS-LI-COLOR = '   ')
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
               PERFORM 4000-GET-TOTAL-COUNT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FETCH-PAGE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-FORMAT-COUNTS
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
           INITIALIZE WS-LIST-OUTPUT
           MOVE 'VEHLST00' TO WS-LO-MSG-ID
           MOVE +0          TO WS-LI-MODEL-YEAR
           MOVE SPACES       TO WS-LI-MAKE-CODE
           MOVE SPACES       TO WS-LI-MODEL-CODE
           MOVE SPACES       TO WS-LI-STATUS
           MOVE SPACES       TO WS-LI-COLOR
           MOVE +1           TO WS-CURRENT-PAGE
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
               MOVE 'IMS GU FAILED' TO WS-LO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION     TO WS-LI-FUNCTION
               MOVE WS-INP-BODY(1:5)    TO WS-LI-DEALER-CODE
               IF WS-INP-BODY(6:4) IS NUMERIC
               AND WS-INP-BODY(6:4) NOT = '0000'
                   MOVE WS-INP-BODY(6:4)  TO WS-LI-MODEL-YEAR
               END-IF
               MOVE WS-INP-BODY(10:3)   TO WS-LI-MAKE-CODE
               MOVE WS-INP-BODY(13:6)   TO WS-LI-MODEL-CODE
               MOVE WS-INP-BODY(19:2)   TO WS-LI-STATUS
               MOVE WS-INP-BODY(21:3)   TO WS-LI-COLOR
      *
      *        HANDLE PAGING - RETRIEVE PAGE NUMBER FROM INPUT
      *
               IF WS-LI-NEXT-PAGE
                   IF WS-INP-BODY(24:4) IS NUMERIC
                       MOVE WS-INP-BODY(24:4) TO WS-CURRENT-PAGE
                       ADD +1 TO WS-CURRENT-PAGE
                   ELSE
                       MOVE +2 TO WS-CURRENT-PAGE
                   END-IF
               END-IF
      *
               IF WS-LI-PREV-PAGE
                   IF WS-INP-BODY(24:4) IS NUMERIC
                       MOVE WS-INP-BODY(24:4) TO WS-CURRENT-PAGE
                       SUBTRACT +1 FROM WS-CURRENT-PAGE
                   ELSE
                       MOVE +1 TO WS-CURRENT-PAGE
                   END-IF
               END-IF
      *
               IF WS-CURRENT-PAGE < +1
                   MOVE +1 TO WS-CURRENT-PAGE
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-LI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-LO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    DEFAULT FUNCTION TO SEARCH
      *
           IF WS-LI-FUNCTION = SPACES
               MOVE 'SR' TO WS-LI-FUNCTION
           END-IF
      *
      *    BUILD FILTER DESCRIPTION
      *
           MOVE SPACES TO WS-FILTER-TEXT
           MOVE +1 TO WS-FILTER-POS
      *
           IF WS-LI-MODEL-YEAR > 0
               STRING 'YR=' WS-LI-MODEL-YEAR ' '
                   DELIMITED BY SIZE
                   INTO WS-FILTER-TEXT
                   WITH POINTER WS-FILTER-POS
           END-IF
      *
           IF WS-LI-MAKE-CODE NOT = SPACES
               STRING 'MAKE=' WS-LI-MAKE-CODE ' '
                   DELIMITED BY SIZE
                   INTO WS-FILTER-TEXT
                   WITH POINTER WS-FILTER-POS
           END-IF
      *
           IF WS-LI-MODEL-CODE NOT = SPACES
               STRING 'MODEL=' WS-LI-MODEL-CODE ' '
                   DELIMITED BY SIZE
                   INTO WS-FILTER-TEXT
                   WITH POINTER WS-FILTER-POS
           END-IF
      *
           IF WS-LI-STATUS NOT = SPACES
               STRING 'STATUS=' WS-LI-STATUS ' '
                   DELIMITED BY SIZE
                   INTO WS-FILTER-TEXT
                   WITH POINTER WS-FILTER-POS
           END-IF
      *
           IF WS-LI-COLOR NOT = SPACES
               STRING 'COLOR=' WS-LI-COLOR ' '
                   DELIMITED BY SIZE
                   INTO WS-FILTER-TEXT
                   WITH POINTER WS-FILTER-POS
           END-IF
      *
           IF WS-FILTER-POS = +1
               MOVE '(NO FILTERS - ALL VEHICLES)'
                   TO WS-FILTER-TEXT
           END-IF
      *
           MOVE WS-FILTER-TEXT TO WS-LO-FILTER-DESC
           MOVE WS-LI-DEALER-CODE TO WS-LO-DEALER-HDR
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-GET-TOTAL-COUNT - COUNT MATCHING VEHICLES            *
      ****************************************************************
       4000-GET-TOTAL-COUNT.
      *
           EXEC SQL
               OPEN CSR_VEH_COUNT
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR OPENING COUNT CURSOR'
                   TO WS-LO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           EXEC SQL
               FETCH CSR_VEH_COUNT
               INTO  :WS-TOTAL-ROWS
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +0 TO WS-TOTAL-ROWS
           END-IF
      *
           EXEC SQL
               CLOSE CSR_VEH_COUNT
           END-EXEC
      *
           IF WS-TOTAL-ROWS = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO VEHICLES FOUND MATCHING CRITERIA'
                   TO WS-LO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-FETCH-PAGE - FETCH 12 ROWS FOR CURRENT PAGE         *
      ****************************************************************
       5000-FETCH-PAGE.
      *
      *    CALCULATE OFFSET FOR CURRENT PAGE
      *
           COMPUTE WS-OFFSET =
               (WS-CURRENT-PAGE - 1) * WS-PAGE-SIZE
      *
           EXEC SQL
               OPEN CSR_VEH_LIST
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR OPENING VEHICLE LIST CURSOR'
                   TO WS-LO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    SKIP ROWS TO REACH CURRENT PAGE
      *
           MOVE +0 TO WS-SKIP-COUNT
      *
           PERFORM UNTIL WS-SKIP-COUNT >= WS-OFFSET
               EXEC SQL
                   FETCH CSR_VEH_LIST
                   INTO  :WS-VR-VIN
                       , :WS-VR-STOCK-NUM :WS-NI-STOCK-NUM
                       , :WS-VR-MODEL-YEAR
                       , :WS-VR-MODEL-CODE
                       , :WS-VR-EXT-COLOR
                       , :WS-VR-STATUS
                       , :WS-VR-DAYS
                       , :WS-VR-LOT-LOC   :WS-NI-LOT-LOC
               END-EXEC
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-SKIP-COUNT
           END-PERFORM
      *
      *    FETCH UP TO 12 DETAIL ROWS
      *
           MOVE +0 TO WS-ROW-IDX
      *
           PERFORM UNTIL WS-ROW-IDX >= WS-PAGE-SIZE
               EXEC SQL
                   FETCH CSR_VEH_LIST
                   INTO  :WS-VR-VIN
                       , :WS-VR-STOCK-NUM :WS-NI-STOCK-NUM
                       , :WS-VR-MODEL-YEAR
                       , :WS-VR-MODEL-CODE
                       , :WS-VR-EXT-COLOR
                       , :WS-VR-STATUS
                       , :WS-VR-DAYS
                       , :WS-VR-LOT-LOC   :WS-NI-LOT-LOC
               END-EXEC
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               IF SQLCODE NOT = +0
                   MOVE +12 TO WS-RETURN-CODE
                   MOVE 'DB2 ERROR FETCHING VEHICLE LIST'
                       TO WS-LO-MSG-TEXT
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-ROW-IDX
               MOVE WS-VR-VIN        TO WS-LO-DT-VIN(WS-ROW-IDX)
               MOVE WS-VR-STOCK-NUM  TO WS-LO-DT-STOCK(WS-ROW-IDX)
               MOVE WS-VR-MODEL-YEAR TO WS-LO-DT-YEAR(WS-ROW-IDX)
               MOVE WS-VR-MODEL-CODE TO WS-LO-DT-MODEL(WS-ROW-IDX)
               MOVE WS-VR-EXT-COLOR  TO WS-LO-DT-COLOR(WS-ROW-IDX)
               MOVE WS-VR-STATUS     TO WS-LO-DT-STATUS(WS-ROW-IDX)
               MOVE WS-VR-DAYS       TO WS-LO-DT-DAYS(WS-ROW-IDX)
               MOVE WS-VR-LOT-LOC    TO WS-LO-DT-LOT(WS-ROW-IDX)
           END-PERFORM
      *
           MOVE WS-ROW-IDX TO WS-FETCH-COUNT
      *
           EXEC SQL
               CLOSE CSR_VEH_LIST
           END-EXEC
      *
           IF WS-FETCH-COUNT = +0
               MOVE 'NO MORE VEHICLES ON THIS PAGE'
                   TO WS-LO-MSG-TEXT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-FORMAT-COUNTS - SHOWING X-Y OF Z                     *
      ****************************************************************
       6000-FORMAT-COUNTS.
      *
           COMPUTE WS-SHOW-FROM = WS-OFFSET + 1
           COMPUTE WS-SHOW-TO   = WS-OFFSET + WS-FETCH-COUNT
      *
           MOVE WS-SHOW-FROM    TO WS-LO-SHOW-FROM
           MOVE WS-SHOW-TO      TO WS-LO-SHOW-TO
           MOVE WS-TOTAL-ROWS   TO WS-LO-TOTAL-COUNT
      *
           IF WS-RETURN-CODE = +0
               STRING 'INVENTORY LISTING - PAGE '
                      WS-CURRENT-PAGE
                      DELIMITED BY SIZE
                      INTO WS-LO-MSG-TEXT
           END-IF
      *
      *    CALL COMFMTL0 FOR DISPLAY FORMATTING
      *
           MOVE 'PAGE' TO WS-FMT-FUNCTION
           CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                  WS-FMT-RESULT
      *
      *    CALL COMMSGL0 FOR MESSAGE FORMATTING
      *
           MOVE 'VEHLST00' TO WS-MSGL-CODE
           CALL 'COMMSGL0' USING WS-MSGL-REQUEST
                                 WS-MSGL-RESULT
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-LIST-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHLST00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHLST00                                              *
      ****************************************************************
