       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMMFG00.
      ****************************************************************
      * PROGRAM:    ADMMFG00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMM                                             *
      * MFS MID:    MFSADMFG (MODEL MASTER SCREEN)                   *
      * MFS MOD:    ASMDLI00 (MODEL INQUIRY/LIST RESPONSE)           *
      *                                                              *
      * PURPOSE:    MANUFACTURER / MAKE / MODEL MASTER MAINTENANCE.  *
      *             PROVIDES CRUD OPERATIONS ON THE MODEL_MASTER     *
      *             TABLE INCLUDING INQUIRY, ADD, UPDATE, AND LIST   *
      *             BY MAKE CODE AND MODEL YEAR.                     *
      *                                                              *
      * FUNCTIONS:  INQ - INQUIRY BY YEAR/MAKE/MODEL                 *
      *             ADD - ADD NEW MODEL RECORD                       *
      *             UPD - UPDATE EXISTING MODEL                      *
      *             LST - LIST BY MAKE CODE AND YEAR                 *
      *                                                              *
      * CALLS:      COMMSGL0 - MESSAGE FORMATTING                   *
      *             COMLGEL0 - AUDIT LOGGING                         *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMMFG00'.
      *
      *    IMS FUNCTION CODES
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR MODEL_MASTER TABLE
      *
           COPY DCLMODEL.
      *
      *    INPUT MESSAGE LAYOUT
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL             PIC S9(04) COMP.
           05  WS-IN-ZZ             PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE      PIC X(08).
           05  WS-IN-FUNC-CODE      PIC X(03).
               88  WS-FUNC-INQ                VALUE 'INQ'.
               88  WS-FUNC-ADD                VALUE 'ADD'.
               88  WS-FUNC-UPD                VALUE 'UPD'.
               88  WS-FUNC-LST                VALUE 'LST'.
           05  WS-IN-MODEL-YEAR     PIC X(04).
           05  WS-IN-MAKE-CODE      PIC X(03).
           05  WS-IN-MODEL-CODE     PIC X(06).
           05  WS-IN-MODEL-NAME     PIC X(40).
           05  WS-IN-BODY-STYLE     PIC X(02).
           05  WS-IN-TRIM-LEVEL     PIC X(03).
           05  WS-IN-ENGINE-TYPE    PIC X(03).
           05  WS-IN-TRANSMISSION   PIC X(01).
           05  WS-IN-DRIVE-TRAIN    PIC X(03).
           05  WS-IN-EXT-COLORS     PIC X(200).
           05  WS-IN-INT-COLORS     PIC X(200).
           05  WS-IN-CURB-WEIGHT    PIC X(06).
           05  WS-IN-MPG-CITY       PIC X(03).
           05  WS-IN-MPG-HWY        PIC X(03).
           05  WS-IN-ACTIVE         PIC X(01).
           05  WS-IN-USER-ID        PIC X(08).
           05  FILLER               PIC X(50).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL            PIC S9(04) COMP.
           05  WS-OUT-ZZ            PIC S9(04) COMP.
           05  WS-OUT-MOD-NAME      PIC X(08).
           05  WS-OUT-FUNC-CODE     PIC X(03).
           05  WS-OUT-MODEL-YEAR    PIC 9(04).
           05  WS-OUT-MAKE-CODE     PIC X(03).
           05  WS-OUT-MODEL-CODE    PIC X(06).
           05  WS-OUT-MODEL-NAME    PIC X(40).
           05  WS-OUT-BODY-STYLE    PIC X(02).
           05  WS-OUT-BODY-DESC     PIC X(15).
           05  WS-OUT-TRIM-LEVEL    PIC X(03).
           05  WS-OUT-ENGINE-TYPE   PIC X(03).
           05  WS-OUT-ENGINE-DESC   PIC X(15).
           05  WS-OUT-TRANSMISSION  PIC X(01).
           05  WS-OUT-TRANS-DESC    PIC X(12).
           05  WS-OUT-DRIVE-TRAIN   PIC X(03).
           05  WS-OUT-CURB-WEIGHT   PIC Z(5)9.
           05  WS-OUT-MPG-CITY      PIC Z(2)9.
           05  WS-OUT-MPG-HWY       PIC Z(2)9.
           05  WS-OUT-ACTIVE        PIC X(01).
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  FILLER               PIC X(50).
      *
      *    LIST OUTPUT - UP TO 15 MODELS PER SCREEN
      *
       01  WS-LIST-OUTPUT.
           05  WS-LST-LL            PIC S9(04) COMP.
           05  WS-LST-ZZ            PIC S9(04) COMP.
           05  WS-LST-MOD-NAME      PIC X(08).
           05  WS-LST-MAKE-CODE     PIC X(03).
           05  WS-LST-YEAR          PIC 9(04).
           05  WS-LST-COUNT         PIC 9(03).
           05  WS-LST-MSG           PIC X(79).
           05  WS-LST-ENTRY OCCURS 15 TIMES.
               10  WS-LST-MDL-YEAR PIC 9(04).
               10  WS-LST-MDL-MAKE PIC X(03).
               10  WS-LST-MDL-CODE PIC X(06).
               10  WS-LST-MDL-NAME PIC X(30).
               10  WS-LST-MDL-BODY PIC X(02).
               10  WS-LST-MDL-ENG  PIC X(03).
               10  WS-LST-MDL-TRN  PIC X(01).
               10  WS-LST-MDL-ACT  PIC X(01).
           05  FILLER               PIC X(50).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-MODEL-YEAR-NUM   PIC S9(04) COMP VALUE 0.
           05  WS-WEIGHT-NUM       PIC S9(09) COMP VALUE 0.
           05  WS-MPG-CITY-NUM     PIC S9(04) COMP VALUE 0.
           05  WS-MPG-HWY-NUM      PIC S9(04) COMP VALUE 0.
           05  WS-LIST-IDX         PIC 9(03) VALUE 0.
           05  WS-ROWS-FETCHED     PIC 9(03) VALUE 0.
           05  WS-MIN-YEAR         PIC S9(04) COMP VALUE 1990.
           05  WS-MAX-YEAR         PIC S9(04) COMP VALUE 2030.
      *
      *    VALID BODY STYLE CODES
      *
       01  WS-BODY-STYLE-TABLE.
           05  FILLER              PIC X(02) VALUE 'SD'.
           05  FILLER              PIC X(02) VALUE 'CP'.
           05  FILLER              PIC X(02) VALUE 'HB'.
           05  FILLER              PIC X(02) VALUE 'WG'.
           05  FILLER              PIC X(02) VALUE 'CV'.
           05  FILLER              PIC X(02) VALUE 'SU'.
           05  FILLER              PIC X(02) VALUE 'PU'.
           05  FILLER              PIC X(02) VALUE 'VN'.
           05  FILLER              PIC X(02) VALUE 'XT'.
       01  WS-BODY-TBL-R REDEFINES WS-BODY-STYLE-TABLE.
           05  WS-BODY-ENTRY       PIC X(02) OCCURS 9 TIMES.
      *
      *    VALID ENGINE TYPE CODES
      *
       01  WS-ENGINE-TYPE-TABLE.
           05  FILLER              PIC X(03) VALUE 'I4 '.
           05  FILLER              PIC X(03) VALUE 'I6 '.
           05  FILLER              PIC X(03) VALUE 'V6 '.
           05  FILLER              PIC X(03) VALUE 'V8 '.
           05  FILLER              PIC X(03) VALUE 'V10'.
           05  FILLER              PIC X(03) VALUE 'V12'.
           05  FILLER              PIC X(03) VALUE 'EV '.
           05  FILLER              PIC X(03) VALUE 'HYB'.
           05  FILLER              PIC X(03) VALUE 'PHV'.
           05  FILLER              PIC X(03) VALUE 'DSL'.
       01  WS-ENGINE-TBL-R REDEFINES WS-ENGINE-TYPE-TABLE.
           05  WS-ENGINE-ENTRY     PIC X(03) OCCURS 10 TIMES.
      *
      *    VALID TRANSMISSION CODES
      *
       01  WS-TRANS-TABLE.
           05  FILLER              PIC X(01) VALUE 'A'.
           05  FILLER              PIC X(01) VALUE 'M'.
           05  FILLER              PIC X(01) VALUE 'C'.
           05  FILLER              PIC X(01) VALUE 'D'.
       01  WS-TRANS-TBL-R REDEFINES WS-TRANS-TABLE.
           05  WS-TRANS-ENTRY      PIC X(01) OCCURS 4 TIMES.
      *
      *    TABLE SEARCH INDEX
      *
       01  WS-TBL-IDX             PIC 9(03) VALUE 0.
       01  WS-TBL-FOUND           PIC X(01) VALUE 'N'.
           88  WS-TBL-IS-FOUND               VALUE 'Y'.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-EXT-COLORS       PIC S9(04) COMP VALUE 0.
           05  NI-INT-COLORS       PIC S9(04) COMP VALUE 0.
           05  NI-CURB-WEIGHT      PIC S9(04) COMP VALUE 0.
           05  NI-MPG-CITY         PIC S9(04) COMP VALUE 0.
           05  NI-MPG-HWY          PIC S9(04) COMP VALUE 0.
      *
      *    AUDIT LOGGING FIELDS
      *
       01  WS-AUDIT-FIELDS.
           05  WS-AUD-USER-ID      PIC X(08).
           05  WS-AUD-PROGRAM-ID   PIC X(08).
           05  WS-AUD-ACTION       PIC X(03).
           05  WS-AUD-TABLE        PIC X(30).
           05  WS-AUD-KEY          PIC X(50).
           05  WS-AUD-OLD-VAL      PIC X(200).
           05  WS-AUD-NEW-VAL      PIC X(200).
           05  WS-AUD-RC           PIC S9(04) COMP.
           05  WS-AUD-MSG          PIC X(50).
      *
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-FIELDS.
           05  WS-DBE-PROGRAM      PIC X(08).
           05  WS-DBE-SECTION      PIC X(30).
           05  WS-DBE-TABLE        PIC X(18).
           05  WS-DBE-OPERATION    PIC X(10).
           05  WS-DBE-RESULT.
               10  WS-DBE-RC      PIC S9(04) COMP.
               10  WS-DBE-RETRY   PIC X(01).
               10  WS-DBE-MSG     PIC X(120).
               10  WS-DBE-SQLCD   PIC X(10).
               10  WS-DBE-SQLST   PIC X(05).
               10  WS-DBE-CATEG   PIC X(20).
               10  WS-DBE-SEVER   PIC X(01).
               10  WS-DBE-ROWS    PIC S9(09) COMP.
      *
      *    CURSOR FOR MODEL LIST BY MAKE/YEAR
      *
           EXEC SQL
               DECLARE MODEL_LIST_CSR CURSOR FOR
               SELECT MODEL_YEAR,
                      MAKE_CODE,
                      MODEL_CODE,
                      MODEL_NAME,
                      BODY_STYLE,
                      ENGINE_TYPE,
                      TRANSMISSION,
                      ACTIVE_FLAG
               FROM   AUTOSALE.MODEL_MASTER
               WHERE  MAKE_CODE = :WS-IN-MAKE-CODE
               AND    (MODEL_YEAR = :WS-MODEL-YEAR-NUM
                       OR :WS-MODEL-YEAR-NUM = 0)
               ORDER BY MODEL_YEAR DESC, MODEL_CODE
               FETCH FIRST 15 ROWS ONLY
           END-EXEC.
      *
       LINKAGE SECTION.
      *
       01  LK-IO-PCB.
           05  LK-IO-LTERM         PIC X(08).
           05  FILLER              PIC X(02).
           05  LK-IO-STATUS        PIC X(02).
           05  LK-IO-DATE          PIC S9(07) COMP-3.
           05  LK-IO-TIME          PIC S9(07) COMP-3.
           05  LK-IO-SEQ           PIC S9(09) COMP.
           05  LK-IO-MOD           PIC X(08).
           05  LK-IO-USER          PIC X(08).
           05  LK-IO-GROUP         PIC X(08).
      *
       01  LK-DB-PCB-1.
           05  LK-DB1-DBD-NAME     PIC X(08).
           05  LK-DB1-SEG-LEVEL    PIC X(02).
           05  LK-DB1-STATUS       PIC X(02).
           05  LK-DB1-PROC-OPT     PIC X(04).
           05  FILLER              PIC S9(05) COMP.
           05  LK-DB1-SEG-NAME     PIC X(08).
           05  LK-DB1-KEY-LEN      PIC S9(05) COMP.
           05  LK-DB1-NSENS-SEGS   PIC S9(05) COMP.
           05  LK-DB1-KEY-FB       PIC X(50).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB-MASK
                              LK-DB-PCB-1.
      *
       0000-MAIN-PROCESS.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
      *
           PERFORM 1000-RECEIVE-INPUT
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR
               GOBACK
           END-IF
      *
      *    ROUTE BY FUNCTION
      *
           EVALUATE TRUE
               WHEN WS-FUNC-INQ
                   PERFORM 3000-INQUIRY
               WHEN WS-FUNC-ADD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 4000-ADD-MODEL
                   END-IF
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-MODEL
                   END-IF
               WHEN WS-FUNC-LST
                   PERFORM 6000-LIST-MODELS
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INVALID FUNCTION: '
                          WS-IN-FUNC-CODE
                          '. USE INQ/ADD/UPD/LST'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
           END-EVALUATE
      *
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR
           END-IF
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - RECEIVE INPUT MESSAGE VIA IMS GU CALL                   *
      *---------------------------------------------------------------*
       1000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-IO-GU
                                IO-PCB-MASK
                                WS-INPUT-MSG
      *
           IF IO-STATUS-CODE NOT = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'IMS GU FAILED - STATUS: '
                      IO-STATUS-CODE
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
           END-IF
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - VALIDATE INPUT FIELDS FOR ADD/UPDATE                    *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
      *    MODEL YEAR - MUST BE NUMERIC AND IN RANGE
      *
           IF WS-IN-MODEL-YEAR NOT NUMERIC
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL YEAR MUST BE NUMERIC (YYYY)'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-NUM
           IF WS-MODEL-YEAR-NUM < WS-MIN-YEAR
           OR WS-MODEL-YEAR-NUM > WS-MAX-YEAR
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL YEAR MUST BE BETWEEN 1990 AND 2030'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    MAKE CODE REQUIRED
      *
           IF WS-IN-MAKE-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MAKE CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    MODEL CODE REQUIRED
      *
           IF WS-IN-MODEL-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    MODEL NAME REQUIRED
      *
           IF WS-IN-MODEL-NAME = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL NAME IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE BODY STYLE
      *
           IF WS-IN-BODY-STYLE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'BODY STYLE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-TBL-FOUND
           PERFORM VARYING WS-TBL-IDX FROM 1 BY 1
               UNTIL WS-TBL-IDX > 9 OR WS-TBL-IS-FOUND
               IF WS-IN-BODY-STYLE = WS-BODY-ENTRY(WS-TBL-IDX)
                   MOVE 'Y' TO WS-TBL-FOUND
               END-IF
           END-PERFORM
      *
           IF NOT WS-TBL-IS-FOUND
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'INVALID BODY STYLE: '
                      WS-IN-BODY-STYLE
                      '. USE SD/CP/HB/WG/CV/SU/PU/VN/XT'
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE ENGINE TYPE
      *
           IF WS-IN-ENGINE-TYPE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ENGINE TYPE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-TBL-FOUND
           PERFORM VARYING WS-TBL-IDX FROM 1 BY 1
               UNTIL WS-TBL-IDX > 10 OR WS-TBL-IS-FOUND
               IF WS-IN-ENGINE-TYPE = WS-ENGINE-ENTRY(WS-TBL-IDX)
                   MOVE 'Y' TO WS-TBL-FOUND
               END-IF
           END-PERFORM
      *
           IF NOT WS-TBL-IS-FOUND
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'INVALID ENGINE TYPE: '
                      WS-IN-ENGINE-TYPE
                      '. USE I4/I6/V6/V8/V10/V12/EV/HYB/PHV/DSL'
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE TRANSMISSION CODE
      *
           IF WS-IN-TRANSMISSION = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'TRANSMISSION CODE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-TBL-FOUND
           PERFORM VARYING WS-TBL-IDX FROM 1 BY 1
               UNTIL WS-TBL-IDX > 4 OR WS-TBL-IS-FOUND
               IF WS-IN-TRANSMISSION = WS-TRANS-ENTRY(WS-TBL-IDX)
                   MOVE 'Y' TO WS-TBL-FOUND
               END-IF
           END-PERFORM
      *
           IF NOT WS-TBL-IS-FOUND
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'INVALID TRANSMISSION: '
                      WS-IN-TRANSMISSION
                      '. USE A(AUTO)/M(MANUAL)/C(CVT)/D(DCT)'
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INQUIRY BY YEAR/MAKE/MODEL                              *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-MODEL-YEAR NOT NUMERIC
           OR WS-IN-MAKE-CODE = SPACES
           OR WS-IN-MODEL-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'YEAR, MAKE, AND MODEL REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-NUM
      *
           EXEC SQL
               SELECT MODEL_YEAR, MAKE_CODE, MODEL_CODE,
                      MODEL_NAME, BODY_STYLE, TRIM_LEVEL,
                      ENGINE_TYPE, TRANSMISSION, DRIVE_TRAIN,
                      EXTERIOR_COLORS, INTERIOR_COLORS,
                      CURB_WEIGHT, FUEL_ECONOMY_CITY,
                      FUEL_ECONOMY_HWY, ACTIVE_FLAG
               INTO   :DCLMODEL-MASTER.MODEL-YEAR,
                      :DCLMODEL-MASTER.MAKE-CODE,
                      :DCLMODEL-MASTER.MODEL-CODE,
                      :DCLMODEL-MASTER.MODEL-NAME,
                      :DCLMODEL-MASTER.BODY-STYLE,
                      :DCLMODEL-MASTER.TRIM-LEVEL,
                      :DCLMODEL-MASTER.ENGINE-TYPE,
                      :DCLMODEL-MASTER.TRANSMISSION,
                      :DCLMODEL-MASTER.DRIVE-TRAIN,
                      :DCLMODEL-MASTER.EXTERIOR-COLORS
                          :NI-EXT-COLORS,
                      :DCLMODEL-MASTER.INTERIOR-COLORS
                          :NI-INT-COLORS,
                      :DCLMODEL-MASTER.CURB-WEIGHT
                          :NI-CURB-WEIGHT,
                      :DCLMODEL-MASTER.FUEL-ECONOMY-CITY
                          :NI-MPG-CITY,
                      :DCLMODEL-MASTER.FUEL-ECONOMY-HWY
                          :NI-MPG-HWY,
                      :DCLMODEL-MASTER.ACTIVE-FLAG
               FROM   AUTOSALE.MODEL_MASTER
               WHERE  MODEL_YEAR = :WS-MODEL-YEAR-NUM
               AND    MAKE_CODE  = :WS-IN-MAKE-CODE
               AND    MODEL_CODE = :WS-IN-MODEL-CODE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 3100-FORMAT-INQUIRY-OUTPUT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'MODEL NOT FOUND: '
                          WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-INQUIRY' TO WS-DBE-SECTION
                   MOVE 'MODEL_MASTER' TO WS-DBE-TABLE
                   MOVE 'SELECT' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM
                                         WS-DBE-SECTION
                                         WS-DBE-TABLE
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT
                   MOVE WS-DBE-MSG(1:79) TO WS-ERROR-MSG
           END-EVALUATE
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3100 - FORMAT INQUIRY OUTPUT WITH DECODED DESCRIPTIONS         *
      *---------------------------------------------------------------*
       3100-FORMAT-INQUIRY-OUTPUT.
      *
           MOVE 450 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASMDLI00' TO WS-OUT-MOD-NAME
           MOVE 'INQ' TO WS-OUT-FUNC-CODE
           MOVE MODEL-YEAR OF DCLMODEL-MASTER
               TO WS-OUT-MODEL-YEAR
           MOVE MAKE-CODE OF DCLMODEL-MASTER
               TO WS-OUT-MAKE-CODE
           MOVE MODEL-CODE OF DCLMODEL-MASTER
               TO WS-OUT-MODEL-CODE
           MOVE MODEL-NAME-TX OF DCLMODEL-MASTER
               TO WS-OUT-MODEL-NAME
           MOVE BODY-STYLE OF DCLMODEL-MASTER
               TO WS-OUT-BODY-STYLE
      *
      *    DECODE BODY STYLE
      *
           EVALUATE BODY-STYLE OF DCLMODEL-MASTER
               WHEN 'SD' MOVE 'SEDAN' TO WS-OUT-BODY-DESC
               WHEN 'CP' MOVE 'COUPE' TO WS-OUT-BODY-DESC
               WHEN 'HB' MOVE 'HATCHBACK' TO WS-OUT-BODY-DESC
               WHEN 'WG' MOVE 'WAGON' TO WS-OUT-BODY-DESC
               WHEN 'CV' MOVE 'CONVERTIBLE' TO WS-OUT-BODY-DESC
               WHEN 'SU' MOVE 'SUV' TO WS-OUT-BODY-DESC
               WHEN 'PU' MOVE 'PICKUP' TO WS-OUT-BODY-DESC
               WHEN 'VN' MOVE 'VAN' TO WS-OUT-BODY-DESC
               WHEN 'XT' MOVE 'CROSSOVER' TO WS-OUT-BODY-DESC
               WHEN OTHER MOVE 'UNKNOWN' TO WS-OUT-BODY-DESC
           END-EVALUATE
      *
           MOVE TRIM-LEVEL OF DCLMODEL-MASTER
               TO WS-OUT-TRIM-LEVEL
           MOVE ENGINE-TYPE OF DCLMODEL-MASTER
               TO WS-OUT-ENGINE-TYPE
      *
      *    DECODE ENGINE TYPE
      *
           EVALUATE ENGINE-TYPE OF DCLMODEL-MASTER
               WHEN 'I4 ' MOVE 'INLINE-4' TO WS-OUT-ENGINE-DESC
               WHEN 'I6 ' MOVE 'INLINE-6' TO WS-OUT-ENGINE-DESC
               WHEN 'V6 ' MOVE 'V6' TO WS-OUT-ENGINE-DESC
               WHEN 'V8 ' MOVE 'V8' TO WS-OUT-ENGINE-DESC
               WHEN 'V10' MOVE 'V10' TO WS-OUT-ENGINE-DESC
               WHEN 'V12' MOVE 'V12' TO WS-OUT-ENGINE-DESC
               WHEN 'EV ' MOVE 'ELECTRIC' TO WS-OUT-ENGINE-DESC
               WHEN 'HYB' MOVE 'HYBRID' TO WS-OUT-ENGINE-DESC
               WHEN 'PHV' MOVE 'PLUG-IN HYBRID'
                   TO WS-OUT-ENGINE-DESC
               WHEN 'DSL' MOVE 'DIESEL' TO WS-OUT-ENGINE-DESC
               WHEN OTHER MOVE 'UNKNOWN' TO WS-OUT-ENGINE-DESC
           END-EVALUATE
      *
           MOVE TRANSMISSION OF DCLMODEL-MASTER
               TO WS-OUT-TRANSMISSION
      *
           EVALUATE TRANSMISSION OF DCLMODEL-MASTER
               WHEN 'A' MOVE 'AUTOMATIC' TO WS-OUT-TRANS-DESC
               WHEN 'M' MOVE 'MANUAL' TO WS-OUT-TRANS-DESC
               WHEN 'C' MOVE 'CVT' TO WS-OUT-TRANS-DESC
               WHEN 'D' MOVE 'DCT' TO WS-OUT-TRANS-DESC
               WHEN OTHER MOVE 'UNKNOWN' TO WS-OUT-TRANS-DESC
           END-EVALUATE
      *
           MOVE DRIVE-TRAIN OF DCLMODEL-MASTER
               TO WS-OUT-DRIVE-TRAIN
      *
           IF NI-CURB-WEIGHT >= 0
               MOVE CURB-WEIGHT OF DCLMODEL-MASTER
                   TO WS-OUT-CURB-WEIGHT
           ELSE
               MOVE 0 TO WS-OUT-CURB-WEIGHT
           END-IF
      *
           IF NI-MPG-CITY >= 0
               MOVE FUEL-ECONOMY-CITY OF DCLMODEL-MASTER
                   TO WS-OUT-MPG-CITY
           ELSE
               MOVE 0 TO WS-OUT-MPG-CITY
           END-IF
      *
           IF NI-MPG-HWY >= 0
               MOVE FUEL-ECONOMY-HWY OF DCLMODEL-MASTER
                   TO WS-OUT-MPG-HWY
           ELSE
               MOVE 0 TO WS-OUT-MPG-HWY
           END-IF
      *
           MOVE ACTIVE-FLAG OF DCLMODEL-MASTER TO WS-OUT-ACTIVE
           MOVE 'MODEL RECORD DISPLAYED SUCCESSFULLY'
               TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       3100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - ADD NEW MODEL RECORD                                    *
      *---------------------------------------------------------------*
       4000-ADD-MODEL.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               INSERT INTO AUTOSALE.MODEL_MASTER
               ( MODEL_YEAR, MAKE_CODE, MODEL_CODE,
                 MODEL_NAME, BODY_STYLE, TRIM_LEVEL,
                 ENGINE_TYPE, TRANSMISSION, DRIVE_TRAIN,
                 EXTERIOR_COLORS, INTERIOR_COLORS,
                 CURB_WEIGHT, FUEL_ECONOMY_CITY,
                 FUEL_ECONOMY_HWY, ACTIVE_FLAG, CREATED_TS )
               VALUES
               ( :DCLMODEL-MASTER.MODEL-YEAR,
                 :DCLMODEL-MASTER.MAKE-CODE,
                 :DCLMODEL-MASTER.MODEL-CODE,
                 :DCLMODEL-MASTER.MODEL-NAME,
                 :DCLMODEL-MASTER.BODY-STYLE,
                 :DCLMODEL-MASTER.TRIM-LEVEL,
                 :DCLMODEL-MASTER.ENGINE-TYPE,
                 :DCLMODEL-MASTER.TRANSMISSION,
                 :DCLMODEL-MASTER.DRIVE-TRAIN,
                 :DCLMODEL-MASTER.EXTERIOR-COLORS
                     :NI-EXT-COLORS,
                 :DCLMODEL-MASTER.INTERIOR-COLORS
                     :NI-INT-COLORS,
                 :DCLMODEL-MASTER.CURB-WEIGHT
                     :NI-CURB-WEIGHT,
                 :DCLMODEL-MASTER.FUEL-ECONOMY-CITY
                     :NI-MPG-CITY,
                 :DCLMODEL-MASTER.FUEL-ECONOMY-HWY
                     :NI-MPG-HWY,
                 :DCLMODEL-MASTER.ACTIVE-FLAG,
                 CURRENT TIMESTAMP )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 450 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASMDLI00' TO WS-OUT-MOD-NAME
                   MOVE 'ADD' TO WS-OUT-FUNC-CODE
                   STRING 'MODEL ' WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                          ' ADDED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN -803
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'MODEL ALREADY EXISTS: '
                          WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '4000-ADD-MODEL' TO WS-DBE-SECTION
                   MOVE 'MODEL_MASTER' TO WS-DBE-TABLE
                   MOVE 'INSERT' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM
                                         WS-DBE-SECTION
                                         WS-DBE-TABLE
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT
                   MOVE WS-DBE-MSG(1:79) TO WS-ERROR-MSG
           END-EVALUATE
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4100 - POPULATE DCLGEN FROM INPUT FIELDS                       *
      *---------------------------------------------------------------*
       4100-POPULATE-DCLGEN.
      *
           MOVE WS-MODEL-YEAR-NUM TO MODEL-YEAR OF DCLMODEL-MASTER
           MOVE WS-IN-MAKE-CODE TO MAKE-CODE OF DCLMODEL-MASTER
           MOVE WS-IN-MODEL-CODE TO MODEL-CODE OF DCLMODEL-MASTER
      *
           MOVE WS-IN-MODEL-NAME TO MODEL-NAME-TX OF DCLMODEL-MASTER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-MODEL-NAME TRAILING))
               TO MODEL-NAME-LN OF DCLMODEL-MASTER
      *
           MOVE WS-IN-BODY-STYLE TO BODY-STYLE OF DCLMODEL-MASTER
           MOVE WS-IN-TRIM-LEVEL TO TRIM-LEVEL OF DCLMODEL-MASTER
           MOVE WS-IN-ENGINE-TYPE TO ENGINE-TYPE OF DCLMODEL-MASTER
           MOVE WS-IN-TRANSMISSION
               TO TRANSMISSION OF DCLMODEL-MASTER
           MOVE WS-IN-DRIVE-TRAIN
               TO DRIVE-TRAIN OF DCLMODEL-MASTER
      *
      *    EXTERIOR COLORS (NULLABLE)
      *
           IF WS-IN-EXT-COLORS = SPACES
               MOVE -1 TO NI-EXT-COLORS
           ELSE
               MOVE 0 TO NI-EXT-COLORS
               MOVE WS-IN-EXT-COLORS
                   TO EXTERIOR-COLORS-TX OF DCLMODEL-MASTER
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(WS-IN-EXT-COLORS TRAILING))
                   TO EXTERIOR-COLORS-LN OF DCLMODEL-MASTER
           END-IF
      *
      *    INTERIOR COLORS (NULLABLE)
      *
           IF WS-IN-INT-COLORS = SPACES
               MOVE -1 TO NI-INT-COLORS
           ELSE
               MOVE 0 TO NI-INT-COLORS
               MOVE WS-IN-INT-COLORS
                   TO INTERIOR-COLORS-TX OF DCLMODEL-MASTER
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(WS-IN-INT-COLORS TRAILING))
                   TO INTERIOR-COLORS-LN OF DCLMODEL-MASTER
           END-IF
      *
      *    CURB WEIGHT (NULLABLE)
      *
           IF WS-IN-CURB-WEIGHT = SPACES
           OR WS-IN-CURB-WEIGHT NOT NUMERIC
               MOVE -1 TO NI-CURB-WEIGHT
           ELSE
               MOVE 0 TO NI-CURB-WEIGHT
               MOVE WS-IN-CURB-WEIGHT TO WS-WEIGHT-NUM
               MOVE WS-WEIGHT-NUM
                   TO CURB-WEIGHT OF DCLMODEL-MASTER
           END-IF
      *
      *    FUEL ECONOMY CITY (NULLABLE)
      *
           IF WS-IN-MPG-CITY = SPACES
           OR WS-IN-MPG-CITY NOT NUMERIC
               MOVE -1 TO NI-MPG-CITY
           ELSE
               MOVE 0 TO NI-MPG-CITY
               MOVE WS-IN-MPG-CITY TO WS-MPG-CITY-NUM
               MOVE WS-MPG-CITY-NUM
                   TO FUEL-ECONOMY-CITY OF DCLMODEL-MASTER
           END-IF
      *
      *    FUEL ECONOMY HWY (NULLABLE)
      *
           IF WS-IN-MPG-HWY = SPACES
           OR WS-IN-MPG-HWY NOT NUMERIC
               MOVE -1 TO NI-MPG-HWY
           ELSE
               MOVE 0 TO NI-MPG-HWY
               MOVE WS-IN-MPG-HWY TO WS-MPG-HWY-NUM
               MOVE WS-MPG-HWY-NUM
                   TO FUEL-ECONOMY-HWY OF DCLMODEL-MASTER
           END-IF
      *
           IF WS-IN-ACTIVE = SPACES
               MOVE 'Y' TO ACTIVE-FLAG OF DCLMODEL-MASTER
           ELSE
               MOVE WS-IN-ACTIVE TO
                   ACTIVE-FLAG OF DCLMODEL-MASTER
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - UPDATE EXISTING MODEL RECORD                            *
      *---------------------------------------------------------------*
       5000-UPDATE-MODEL.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               UPDATE AUTOSALE.MODEL_MASTER
               SET    MODEL_NAME = :DCLMODEL-MASTER.MODEL-NAME,
                      BODY_STYLE = :DCLMODEL-MASTER.BODY-STYLE,
                      TRIM_LEVEL = :DCLMODEL-MASTER.TRIM-LEVEL,
                      ENGINE_TYPE = :DCLMODEL-MASTER.ENGINE-TYPE,
                      TRANSMISSION =
                          :DCLMODEL-MASTER.TRANSMISSION,
                      DRIVE_TRAIN = :DCLMODEL-MASTER.DRIVE-TRAIN,
                      EXTERIOR_COLORS =
                          :DCLMODEL-MASTER.EXTERIOR-COLORS
                          :NI-EXT-COLORS,
                      INTERIOR_COLORS =
                          :DCLMODEL-MASTER.INTERIOR-COLORS
                          :NI-INT-COLORS,
                      CURB_WEIGHT = :DCLMODEL-MASTER.CURB-WEIGHT
                          :NI-CURB-WEIGHT,
                      FUEL_ECONOMY_CITY =
                          :DCLMODEL-MASTER.FUEL-ECONOMY-CITY
                          :NI-MPG-CITY,
                      FUEL_ECONOMY_HWY =
                          :DCLMODEL-MASTER.FUEL-ECONOMY-HWY
                          :NI-MPG-HWY,
                      ACTIVE_FLAG = :DCLMODEL-MASTER.ACTIVE-FLAG
               WHERE  MODEL_YEAR = :WS-MODEL-YEAR-NUM
               AND    MAKE_CODE  = :WS-IN-MAKE-CODE
               AND    MODEL_CODE = :WS-IN-MODEL-CODE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 450 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASMDLI00' TO WS-OUT-MOD-NAME
                   MOVE 'UPD' TO WS-OUT-FUNC-CODE
                   STRING 'MODEL ' WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                          ' UPDATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'MODEL NOT FOUND: '
                          WS-IN-MODEL-YEAR ' '
                          WS-IN-MAKE-CODE ' '
                          WS-IN-MODEL-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '5000-UPDATE' TO WS-DBE-SECTION
                   MOVE 'MODEL_MASTER' TO WS-DBE-TABLE
                   MOVE 'UPDATE' TO WS-DBE-OPERATION
                   CALL 'COMDBEL0' USING SQLCA
                                         WS-DBE-PROGRAM
                                         WS-DBE-SECTION
                                         WS-DBE-TABLE
                                         WS-DBE-OPERATION
                                         WS-DBE-RESULT
                   MOVE WS-DBE-MSG(1:79) TO WS-ERROR-MSG
           END-EVALUATE
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - LIST MODELS BY MAKE AND OPTIONAL YEAR                   *
      *---------------------------------------------------------------*
       6000-LIST-MODELS.
      *
           IF WS-IN-MAKE-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MAKE CODE IS REQUIRED FOR LIST'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
      *    YEAR IS OPTIONAL - SET TO 0 TO SKIP FILTER
      *
           IF WS-IN-MODEL-YEAR NUMERIC
               MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-NUM
           ELSE
               MOVE 0 TO WS-MODEL-YEAR-NUM
           END-IF
      *
           INITIALIZE WS-LIST-OUTPUT
           MOVE 0 TO WS-LIST-IDX
           MOVE 0 TO WS-ROWS-FETCHED
      *
           EXEC SQL
               OPEN MODEL_LIST_CSR
           END-EXEC
      *
           IF SQLCODE NOT = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ERROR OPENING MODEL LIST CURSOR'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           PERFORM 6100-FETCH-MODEL
               UNTIL SQLCODE NOT = 0
               OR WS-LIST-IDX >= 15
      *
           EXEC SQL
               CLOSE MODEL_LIST_CSR
           END-EXEC
      *
           IF WS-ROWS-FETCHED = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'NO MODELS FOUND FOR MAKE: '
                      WS-IN-MAKE-CODE
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           MOVE 900 TO WS-LST-LL
           MOVE 0 TO WS-LST-ZZ
           MOVE 'ASMDLI00' TO WS-LST-MOD-NAME
           MOVE WS-IN-MAKE-CODE TO WS-LST-MAKE-CODE
           MOVE WS-MODEL-YEAR-NUM TO WS-LST-YEAR
           MOVE WS-ROWS-FETCHED TO WS-LST-COUNT
           STRING 'DISPLAYING ' WS-ROWS-FETCHED
                  ' MODEL(S) FOR MAKE ' WS-IN-MAKE-CODE
               DELIMITED BY SIZE
               INTO WS-LST-MSG
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-LIST-OUTPUT
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6100 - FETCH NEXT MODEL ROW FROM CURSOR                       *
      *---------------------------------------------------------------*
       6100-FETCH-MODEL.
      *
           EXEC SQL
               FETCH MODEL_LIST_CSR
               INTO  :DCLMODEL-MASTER.MODEL-YEAR,
                     :DCLMODEL-MASTER.MAKE-CODE,
                     :DCLMODEL-MASTER.MODEL-CODE,
                     :DCLMODEL-MASTER.MODEL-NAME,
                     :DCLMODEL-MASTER.BODY-STYLE,
                     :DCLMODEL-MASTER.ENGINE-TYPE,
                     :DCLMODEL-MASTER.TRANSMISSION,
                     :DCLMODEL-MASTER.ACTIVE-FLAG
           END-EXEC
      *
           IF SQLCODE = 0
               ADD 1 TO WS-LIST-IDX
               ADD 1 TO WS-ROWS-FETCHED
               MOVE MODEL-YEAR OF DCLMODEL-MASTER
                   TO WS-LST-MDL-YEAR(WS-LIST-IDX)
               MOVE MAKE-CODE OF DCLMODEL-MASTER
                   TO WS-LST-MDL-MAKE(WS-LIST-IDX)
               MOVE MODEL-CODE OF DCLMODEL-MASTER
                   TO WS-LST-MDL-CODE(WS-LIST-IDX)
               MOVE MODEL-NAME-TX OF DCLMODEL-MASTER
                   TO WS-LST-MDL-NAME(WS-LIST-IDX)
               MOVE BODY-STYLE OF DCLMODEL-MASTER
                   TO WS-LST-MDL-BODY(WS-LIST-IDX)
               MOVE ENGINE-TYPE OF DCLMODEL-MASTER
                   TO WS-LST-MDL-ENG(WS-LIST-IDX)
               MOVE TRANSMISSION OF DCLMODEL-MASTER
                   TO WS-LST-MDL-TRN(WS-LIST-IDX)
               MOVE ACTIVE-FLAG OF DCLMODEL-MASTER
                   TO WS-LST-MDL-ACT(WS-LIST-IDX)
           END-IF
           .
       6100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - SEND ERROR RESPONSE                                     *
      *---------------------------------------------------------------*
       8000-SEND-ERROR.
      *
           MOVE 450 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASMDLI00' TO WS-OUT-MOD-NAME
           MOVE WS-IN-FUNC-CODE TO WS-OUT-FUNC-CODE
           MOVE WS-ERROR-MSG TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       8000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 9000 - LOG AUDIT TRAIL FOR DATA CHANGES                        *
      *---------------------------------------------------------------*
       9000-LOG-AUDIT.
      *
           MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
           MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
      *
           EVALUATE TRUE
               WHEN WS-FUNC-ADD
                   MOVE 'INS' TO WS-AUD-ACTION
               WHEN WS-FUNC-UPD
                   MOVE 'UPD' TO WS-AUD-ACTION
               WHEN OTHER
                   MOVE 'INQ' TO WS-AUD-ACTION
           END-EVALUATE
      *
           MOVE 'MODEL_MASTER' TO WS-AUD-TABLE
           STRING WS-IN-MODEL-YEAR ' '
                  WS-IN-MAKE-CODE ' '
                  WS-IN-MODEL-CODE
               DELIMITED BY SIZE
               INTO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           MOVE WS-IN-MODEL-NAME TO WS-AUD-NEW-VAL
      *
           CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                  WS-AUD-PROGRAM-ID
                                  WS-AUD-ACTION
                                  WS-AUD-TABLE
                                  WS-AUD-KEY
                                  WS-AUD-OLD-VAL
                                  WS-AUD-NEW-VAL
                                  WS-AUD-RC
                                  WS-AUD-MSG
           .
       9000-EXIT.
           EXIT.
      ****************************************************************
      * END OF ADMMFG00                                              *
      ****************************************************************
