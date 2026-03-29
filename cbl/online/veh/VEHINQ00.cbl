       IDENTIFICATION DIVISION.
       PROGRAM-ID. VEHINQ00.
      ****************************************************************
      * PROGRAM:  VEHINQ00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   VEHICLE - VEHICLE INQUIRY BY VIN OR STOCK NUMBER   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SEARCH BY VIN (EXACT) OR STOCK NUMBER. DISPLAYS    *
      *           FULL VEHICLE DETAILS, OPTIONS, STATUS HISTORY,     *
      *           AND CURRENT LOCATION. USES EXEC SQL SELECT WITH    *
      *           JOIN TO MODEL_MASTER FOR DESCRIPTION. SUB-QUERY    *
      *           FOR OPTIONS VIA CURSOR ON VEHICLE_OPTION.          *
      *           SUB-QUERY FOR STATUS HISTORY VIA CURSOR ON         *
      *           VEHICLE_STATUS_HIST. DISPLAY ONLY - NO UPDATES.    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    VHIQ - VEHICLE INQUIRY                             *
      * CALLS:    COMFMTL0 - FORMAT VIN, CURRENCY                   *
      *           COMVINL0 - DECODE VIN                              *
      * TABLES:   AUTOSALE.VEHICLE (JOIN MODEL_MASTER)               *
      *           AUTOSALE.VEHICLE_OPTION                             *
      *           AUTOSALE.VEHICLE_STATUS_HIST                       *
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
                                          VALUE 'VEHINQ00'.
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
           COPY DCLVEHCL.
      *
           COPY DCLVHOPT.
      *
           COPY DCLVHSTH.
      *
           COPY DCLMODEL.
      *
      *    INPUT FIELDS
      *
       01  WS-INQ-INPUT.
           05  WS-II-FUNCTION            PIC X(02).
               88  WS-II-BY-VIN                     VALUE 'VN'.
               88  WS-II-BY-STOCK                   VALUE 'ST'.
           05  WS-II-VIN                 PIC X(17).
           05  WS-II-STOCK-NUM           PIC X(08).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-INQ-OUTPUT.
           05  WS-IO-STATUS-LINE.
               10  WS-IO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-IO-MSG-TEXT       PIC X(70).
           05  WS-IO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-IO-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- VEHICLE DETAIL ----     '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-IO-VIN-LINE.
               10  FILLER               PIC X(06) VALUE 'VIN:  '.
               10  WS-IO-VIN            PIC X(17).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'STOCK NO: '.
               10  WS-IO-STOCK-NUM      PIC X(08).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'STATUS: '.
               10  WS-IO-STATUS         PIC X(02).
               10  FILLER               PIC X(20) VALUE SPACES.
           05  WS-IO-VEHICLE-LINE.
               10  FILLER               PIC X(06) VALUE 'YEAR: '.
               10  WS-IO-YEAR           PIC 9(04).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'MAKE: '.
               10  WS-IO-MAKE           PIC X(03).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'MODEL: '.
               10  WS-IO-MODEL          PIC X(06).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'NAME: '.
               10  WS-IO-MODEL-NAME     PIC X(35).
           05  WS-IO-COLOR-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'EXT COLOR:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-IO-EXT-COLOR      PIC X(03).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'INT COLOR:'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-IO-INT-COLOR      PIC X(03).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'BODY: '.
               10  WS-IO-BODY-STYLE     PIC X(02).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TRIM: '.
               10  WS-IO-TRIM           PIC X(03).
               10  FILLER               PIC X(22) VALUE SPACES.
           05  WS-IO-DEALER-LINE.
               10  FILLER               PIC X(08) VALUE 'DEALER: '.
               10  WS-IO-DEALER         PIC X(05).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'LOT: '.
               10  WS-IO-LOT            PIC X(06).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'ODOM: '.
               10  WS-IO-ODOMETER       PIC Z(05)9.
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-IO-DATE-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'RECEIVED: '.
               10  WS-IO-RECV-DATE      PIC X(10).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(12)
                   VALUE 'DAYS STOCK: '.
               10  WS-IO-DAYS           PIC Z(04)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'PDI: '.
               10  WS-IO-PDI            PIC X(01).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'DMG: '.
               10  WS-IO-DMG-FLAG       PIC X(01).
               10  FILLER               PIC X(14) VALUE SPACES.
           05  WS-IO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-IO-OPT-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- INSTALLED OPTIONS ----   '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-IO-OPT-LINES.
               10  WS-IO-OPT-LINE       OCCURS 8 TIMES.
                   15  WS-IO-OPT-CODE   PIC X(06).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-IO-OPT-DESC   PIC X(40).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-IO-OPT-PRICE  PIC Z(06)9.99.
                   15  FILLER            PIC X(18) VALUE SPACES.
           05  WS-IO-BLANK-3            PIC X(79) VALUE SPACES.
           05  WS-IO-HIST-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- STATUS HISTORY ----      '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-IO-HIST-COL-HDR.
               10  FILLER               PIC X(05) VALUE 'SEQ  '.
               10  FILLER               PIC X(05) VALUE 'FROM '.
               10  FILLER               PIC X(05) VALUE 'TO   '.
               10  FILLER               PIC X(10) VALUE 'BY       '.
               10  FILLER               PIC X(21) VALUE
                   'TIMESTAMP            '.
               10  FILLER               PIC X(33) VALUE 'REASON'.
           05  WS-IO-HIST-LINES.
               10  WS-IO-HIST-LINE      OCCURS 6 TIMES.
                   15  WS-IO-HIST-SEQ   PIC Z(03)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-IO-HIST-FROM  PIC X(02).
                   15  FILLER            PIC X(03) VALUE SPACES.
                   15  WS-IO-HIST-TO    PIC X(02).
                   15  FILLER            PIC X(03) VALUE SPACES.
                   15  WS-IO-HIST-BY    PIC X(08).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-IO-HIST-TS    PIC X(19).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-IO-HIST-REASON PIC X(33).
           05  WS-IO-FILLER             PIC X(82) VALUE SPACES.
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
      *    VIN LOOKUP CALL FIELDS
      *
       01  WS-VINL-REQUEST.
           05  WS-VINL-FUNCTION          PIC X(04).
           05  WS-VINL-VIN               PIC X(17).
       01  WS-VINL-RESULT.
           05  WS-VINL-RC                PIC S9(04) COMP.
           05  WS-VINL-MSG               PIC X(50).
           05  WS-VINL-MAKE-NAME         PIC X(20).
           05  WS-VINL-MODEL-NAME        PIC X(30).
           05  WS-VINL-YEAR              PIC 9(04).
      *
      *    CURSOR STATUS FIELDS
      *
       01  WS-OPT-COUNT                 PIC S9(04) COMP VALUE +0.
       01  WS-HIST-COUNT                PIC S9(04) COMP VALUE +0.
       01  WS-OPT-IDX                   PIC S9(04) COMP VALUE +0.
       01  WS-HIST-IDX                  PIC S9(04) COMP VALUE +0.
       01  WS-RETURN-CODE               PIC S9(04) COMP VALUE +0.
       01  WS-LOOKUP-VIN                PIC X(17) VALUE SPACES.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-RECV-DATE          PIC S9(04) COMP VALUE +0.
           05  WS-NI-LOT-LOC            PIC S9(04) COMP VALUE +0.
           05  WS-NI-STOCK-NUM          PIC S9(04) COMP VALUE +0.
           05  WS-NI-DEALER-CODE        PIC S9(04) COMP VALUE +0.
           05  WS-NI-CHANGE-REASON      PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR FOR VEHICLE OPTIONS
      *
           EXEC SQL
               DECLARE CSR_VEH_OPTIONS CURSOR FOR
               SELECT OPTION_CODE
                    , OPTION_DESC
                    , OPTION_PRICE
                    , INSTALLED_FLAG
               FROM   AUTOSALE.VEHICLE_OPTION
               WHERE  VIN = :WS-LOOKUP-VIN
                 AND  INSTALLED_FLAG = 'Y'
               ORDER BY OPTION_CODE
           END-EXEC.
      *
      *    CURSOR FOR STATUS HISTORY
      *
           EXEC SQL
               DECLARE CSR_VEH_HISTORY CURSOR FOR
               SELECT STATUS_SEQ
                    , OLD_STATUS
                    , NEW_STATUS
                    , CHANGED_BY
                    , CHANGED_TS
                    , CHANGE_REASON
               FROM   AUTOSALE.VEHICLE_STATUS_HIST
               WHERE  VIN = :WS-LOOKUP-VIN
               ORDER BY STATUS_SEQ DESC
           END-EXEC.
      *
      *    HISTORY WORK FIELDS
      *
       01  WS-HIST-WORK.
           05  WS-HW-SEQ                PIC S9(09) COMP.
           05  WS-HW-OLD-STATUS         PIC X(02).
           05  WS-HW-NEW-STATUS         PIC X(02).
           05  WS-HW-CHANGED-BY         PIC X(08).
           05  WS-HW-CHANGED-TS         PIC X(26).
           05  WS-HW-REASON.
               49  WS-HW-REASON-LN      PIC S9(04) COMP.
               49  WS-HW-REASON-TX      PIC X(60).
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
               PERFORM 4000-LOOKUP-VEHICLE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FETCH-OPTIONS
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-FETCH-HISTORY
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
           INITIALIZE WS-INQ-OUTPUT
           MOVE 'VEHINQ00' TO WS-IO-MSG-ID
           MOVE +0 TO WS-OPT-COUNT
           MOVE +0 TO WS-HIST-COUNT
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
                   TO WS-IO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION    TO WS-II-FUNCTION
               MOVE WS-INP-BODY(1:17)  TO WS-II-VIN
               MOVE WS-INP-BODY(18:8)  TO WS-II-STOCK-NUM
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-II-FUNCTION = SPACES
               MOVE 'VN' TO WS-II-FUNCTION
           END-IF
      *
           IF WS-II-BY-VIN
               IF WS-II-VIN = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'VIN IS REQUIRED FOR VIN INQUIRY'
                       TO WS-IO-MSG-TEXT
               END-IF
           ELSE
               IF WS-II-BY-STOCK
                   IF WS-II-STOCK-NUM = SPACES
                       MOVE +8 TO WS-RETURN-CODE
                       MOVE 'STOCK NUMBER IS REQUIRED'
                           TO WS-IO-MSG-TEXT
                   END-IF
               ELSE
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'FUNCTION MUST BE VN (VIN) OR ST (STOCK)'
                       TO WS-IO-MSG-TEXT
               END-IF
           END-IF
           .
      *
      ****************************************************************
      *    4000-LOOKUP-VEHICLE - JOIN VEHICLE AND MODEL_MASTER       *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           IF WS-II-BY-VIN
               EXEC SQL
                   SELECT V.VIN
                        , V.MODEL_YEAR
                        , V.MAKE_CODE
                        , V.MODEL_CODE
                        , V.EXTERIOR_COLOR
                        , V.INTERIOR_COLOR
                        , V.VEHICLE_STATUS
                        , V.DEALER_CODE
                        , V.LOT_LOCATION
                        , V.STOCK_NUMBER
                        , V.DAYS_IN_STOCK
                        , V.RECEIVE_DATE
                        , V.PDI_COMPLETE
                        , V.DAMAGE_FLAG
                        , V.ODOMETER
                        , M.MODEL_NAME
                        , M.BODY_STYLE
                        , M.TRIM_LEVEL
                   INTO  :VIN             OF DCLVEHICLE
                        , :MODEL-YEAR     OF DCLVEHICLE
                        , :MAKE-CODE      OF DCLVEHICLE
                        , :MODEL-CODE     OF DCLVEHICLE
                        , :EXTERIOR-COLOR OF DCLVEHICLE
                        , :INTERIOR-COLOR OF DCLVEHICLE
                        , :VEHICLE-STATUS OF DCLVEHICLE
                        , :DEALER-CODE    OF DCLVEHICLE
                                           :WS-NI-DEALER-CODE
                        , :LOT-LOCATION   OF DCLVEHICLE
                                           :WS-NI-LOT-LOC
                        , :STOCK-NUMBER   OF DCLVEHICLE
                                           :WS-NI-STOCK-NUM
                        , :DAYS-IN-STOCK  OF DCLVEHICLE
                        , :RECEIVE-DATE   OF DCLVEHICLE
                                           :WS-NI-RECV-DATE
                        , :PDI-COMPLETE   OF DCLVEHICLE
                        , :DAMAGE-FLAG    OF DCLVEHICLE
                        , :ODOMETER       OF DCLVEHICLE
                        , :MODEL-NAME     OF DCLMODEL-MASTER
                        , :BODY-STYLE     OF DCLMODEL-MASTER
                        , :TRIM-LEVEL     OF DCLMODEL-MASTER
                   FROM   AUTOSALE.VEHICLE V
                        , AUTOSALE.MODEL_MASTER M
                   WHERE  V.VIN = :WS-II-VIN
                     AND  M.MODEL_YEAR = V.MODEL_YEAR
                     AND  M.MAKE_CODE  = V.MAKE_CODE
                     AND  M.MODEL_CODE = V.MODEL_CODE
               END-EXEC
           ELSE
               EXEC SQL
                   SELECT V.VIN
                        , V.MODEL_YEAR
                        , V.MAKE_CODE
                        , V.MODEL_CODE
                        , V.EXTERIOR_COLOR
                        , V.INTERIOR_COLOR
                        , V.VEHICLE_STATUS
                        , V.DEALER_CODE
                        , V.LOT_LOCATION
                        , V.STOCK_NUMBER
                        , V.DAYS_IN_STOCK
                        , V.RECEIVE_DATE
                        , V.PDI_COMPLETE
                        , V.DAMAGE_FLAG
                        , V.ODOMETER
                        , M.MODEL_NAME
                        , M.BODY_STYLE
                        , M.TRIM_LEVEL
                   INTO  :VIN             OF DCLVEHICLE
                        , :MODEL-YEAR     OF DCLVEHICLE
                        , :MAKE-CODE      OF DCLVEHICLE
                        , :MODEL-CODE     OF DCLVEHICLE
                        , :EXTERIOR-COLOR OF DCLVEHICLE
                        , :INTERIOR-COLOR OF DCLVEHICLE
                        , :VEHICLE-STATUS OF DCLVEHICLE
                        , :DEALER-CODE    OF DCLVEHICLE
                                           :WS-NI-DEALER-CODE
                        , :LOT-LOCATION   OF DCLVEHICLE
                                           :WS-NI-LOT-LOC
                        , :STOCK-NUMBER   OF DCLVEHICLE
                                           :WS-NI-STOCK-NUM
                        , :DAYS-IN-STOCK  OF DCLVEHICLE
                        , :RECEIVE-DATE   OF DCLVEHICLE
                                           :WS-NI-RECV-DATE
                        , :PDI-COMPLETE   OF DCLVEHICLE
                        , :DAMAGE-FLAG    OF DCLVEHICLE
                        , :ODOMETER       OF DCLVEHICLE
                        , :MODEL-NAME     OF DCLMODEL-MASTER
                        , :BODY-STYLE     OF DCLMODEL-MASTER
                        , :TRIM-LEVEL     OF DCLMODEL-MASTER
                   FROM   AUTOSALE.VEHICLE V
                        , AUTOSALE.MODEL_MASTER M
                   WHERE  V.STOCK_NUMBER = :WS-II-STOCK-NUM
                     AND  M.MODEL_YEAR   = V.MODEL_YEAR
                     AND  M.MAKE_CODE    = V.MAKE_CODE
                     AND  M.MODEL_CODE   = V.MODEL_CODE
               END-EXEC
           END-IF
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'VEHICLE NOT FOUND' TO WS-IO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON VEHICLE LOOKUP'
                   TO WS-IO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    SAVE VIN FOR CURSOR QUERIES
      *
           MOVE VIN OF DCLVEHICLE TO WS-LOOKUP-VIN
      *
      *    CALL COMVINL0 TO DECODE VIN
      *
           MOVE 'DECO'        TO WS-VINL-FUNCTION
           MOVE WS-LOOKUP-VIN TO WS-VINL-VIN
           CALL 'COMVINL0' USING WS-VINL-REQUEST
                                 WS-VINL-RESULT
      *
      *    CALL COMFMTL0 TO FORMAT VIN DISPLAY
      *
           MOVE 'FVIN' TO WS-FMT-FUNCTION
           MOVE WS-LOOKUP-VIN TO WS-FMT-INPUT
           CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                  WS-FMT-RESULT
      *
      *    FORMAT OUTPUT DETAIL LINES
      *
           MOVE VIN OF DCLVEHICLE          TO WS-IO-VIN
           MOVE STOCK-NUMBER               TO WS-IO-STOCK-NUM
           MOVE VEHICLE-STATUS             TO WS-IO-STATUS
           MOVE MODEL-YEAR OF DCLVEHICLE   TO WS-IO-YEAR
           MOVE MAKE-CODE OF DCLVEHICLE    TO WS-IO-MAKE
           MOVE MODEL-CODE OF DCLVEHICLE   TO WS-IO-MODEL
           MOVE MODEL-NAME-TX             TO WS-IO-MODEL-NAME
           MOVE EXTERIOR-COLOR             TO WS-IO-EXT-COLOR
           MOVE INTERIOR-COLOR             TO WS-IO-INT-COLOR
           MOVE BODY-STYLE                 TO WS-IO-BODY-STYLE
           MOVE TRIM-LEVEL                 TO WS-IO-TRIM
           MOVE DEALER-CODE OF DCLVEHICLE  TO WS-IO-DEALER
           MOVE LOT-LOCATION               TO WS-IO-LOT
           MOVE ODOMETER                   TO WS-IO-ODOMETER
           MOVE RECEIVE-DATE               TO WS-IO-RECV-DATE
           MOVE DAYS-IN-STOCK              TO WS-IO-DAYS
           MOVE PDI-COMPLETE               TO WS-IO-PDI
           MOVE DAMAGE-FLAG                TO WS-IO-DMG-FLAG
      *
           MOVE 'VEHICLE INQUIRY COMPLETE'
               TO WS-IO-MSG-TEXT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-FETCH-OPTIONS - CURSOR FETCH FOR VEHICLE OPTIONS     *
      ****************************************************************
       5000-FETCH-OPTIONS.
      *
           EXEC SQL
               OPEN CSR_VEH_OPTIONS
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-OPT-IDX
      *
           PERFORM UNTIL WS-OPT-IDX >= 8
               EXEC SQL
                   FETCH CSR_VEH_OPTIONS
                   INTO  :OPTION-CODE    OF DCLVEHICLE-OPTION
                       , :OPTION-DESC    OF DCLVEHICLE-OPTION
                       , :OPTION-PRICE   OF DCLVEHICLE-OPTION
                       , :INSTALLED-FLAG OF DCLVEHICLE-OPTION
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
               ADD +1 TO WS-OPT-IDX
               MOVE OPTION-CODE TO
                   WS-IO-OPT-CODE(WS-OPT-IDX)
               MOVE OPTION-DESC-TX TO
                   WS-IO-OPT-DESC(WS-OPT-IDX)
               MOVE OPTION-PRICE TO
                   WS-IO-OPT-PRICE(WS-OPT-IDX)
           END-PERFORM
      *
           MOVE WS-OPT-IDX TO WS-OPT-COUNT
      *
           EXEC SQL
               CLOSE CSR_VEH_OPTIONS
           END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-FETCH-HISTORY - CURSOR FETCH FOR STATUS HISTORY      *
      ****************************************************************
       6000-FETCH-HISTORY.
      *
           EXEC SQL
               OPEN CSR_VEH_HISTORY
           END-EXEC
      *
           IF SQLCODE NOT = +0
               GO TO 6000-EXIT
           END-IF
      *
           MOVE +0 TO WS-HIST-IDX
      *
           PERFORM UNTIL WS-HIST-IDX >= 6
               EXEC SQL
                   FETCH CSR_VEH_HISTORY
                   INTO  :WS-HW-SEQ
                       , :WS-HW-OLD-STATUS
                       , :WS-HW-NEW-STATUS
                       , :WS-HW-CHANGED-BY
                       , :WS-HW-CHANGED-TS
                       , :WS-HW-REASON
                          :WS-NI-CHANGE-REASON
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
               ADD +1 TO WS-HIST-IDX
               MOVE WS-HW-SEQ        TO
                   WS-IO-HIST-SEQ(WS-HIST-IDX)
               MOVE WS-HW-OLD-STATUS  TO
                   WS-IO-HIST-FROM(WS-HIST-IDX)
               MOVE WS-HW-NEW-STATUS  TO
                   WS-IO-HIST-TO(WS-HIST-IDX)
               MOVE WS-HW-CHANGED-BY  TO
                   WS-IO-HIST-BY(WS-HIST-IDX)
               MOVE WS-HW-CHANGED-TS(1:19)  TO
                   WS-IO-HIST-TS(WS-HIST-IDX)
               IF WS-NI-CHANGE-REASON >= +0
                   MOVE WS-HW-REASON-TX(1:33) TO
                       WS-IO-HIST-REASON(WS-HIST-IDX)
               ELSE
                   MOVE SPACES TO
                       WS-IO-HIST-REASON(WS-HIST-IDX)
               END-IF
           END-PERFORM
      *
           MOVE WS-HIST-IDX TO WS-HIST-COUNT
      *
           EXEC SQL
               CLOSE CSR_VEH_HISTORY
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
           MOVE WS-INQ-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'VEHINQ00' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF VEHINQ00                                              *
      ****************************************************************
