       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMINC00.
      ****************************************************************
      * PROGRAM:    ADMINC00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMI                                             *
      * MFS MID:    MFSADINC (INCENTIVE PROGRAM SCREEN)              *
      * MFS MOD:    ASINCI00 (INCENTIVE INQUIRY RESPONSE)            *
      *                                                              *
      * PURPOSE:    INCENTIVE PROGRAM SETUP. PROVIDES CRUD AND       *
      *             ACTIVATE/DEACTIVATE OPERATIONS ON THE             *
      *             INCENTIVE_PROGRAM TABLE. VALIDATES DATE RANGES,  *
      *             AMOUNTS, MAX UNITS, AND MODEL ELIGIBILITY.       *
      *                                                              *
      * FUNCTIONS:  INQ  - INQUIRY BY INCENTIVE ID                   *
      *             ADD  - ADD NEW INCENTIVE PROGRAM                 *
      *             UPD  - UPDATE EXISTING INCENTIVE                 *
      *             ACT  - ACTIVATE INCENTIVE                        *
      *             DEAC - DEACTIVATE INCENTIVE                      *
      *                                                              *
      * CALLS:      COMLGEL0 - AUDIT LOGGING                        *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *             COMFMTL0 - FORMAT CURRENCY                       *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMINC00'.
      *
      *    IMS FUNCTION CODES
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR INCENTIVE_PROGRAM TABLE
      *
           COPY DCLINCPG.
      *
      *    INPUT MESSAGE LAYOUT
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL             PIC S9(04) COMP.
           05  WS-IN-ZZ             PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE      PIC X(08).
           05  WS-IN-FUNC-CODE      PIC X(04).
               88  WS-FUNC-INQ                VALUE 'INQ '.
               88  WS-FUNC-ADD                VALUE 'ADD '.
               88  WS-FUNC-UPD                VALUE 'UPD '.
               88  WS-FUNC-ACT                VALUE 'ACT '.
               88  WS-FUNC-DEAC               VALUE 'DEAC'.
           05  WS-IN-INCENT-ID      PIC X(10).
           05  WS-IN-INCENT-NAME    PIC X(60).
           05  WS-IN-INCENT-TYPE    PIC X(02).
           05  WS-IN-MODEL-YEAR     PIC X(04).
           05  WS-IN-MAKE-CODE      PIC X(03).
           05  WS-IN-MODEL-CODE     PIC X(06).
           05  WS-IN-REGION-CODE    PIC X(03).
           05  WS-IN-AMOUNT         PIC X(12).
           05  WS-IN-RATE-OVERRIDE  PIC X(06).
           05  WS-IN-START-DATE     PIC X(10).
           05  WS-IN-END-DATE       PIC X(10).
           05  WS-IN-MAX-UNITS      PIC X(08).
           05  WS-IN-STACKABLE      PIC X(01).
           05  WS-IN-USER-ID        PIC X(08).
           05  FILLER               PIC X(50).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL            PIC S9(04) COMP.
           05  WS-OUT-ZZ            PIC S9(04) COMP.
           05  WS-OUT-MOD-NAME      PIC X(08).
           05  WS-OUT-FUNC-CODE     PIC X(04).
           05  WS-OUT-INCENT-ID     PIC X(10).
           05  WS-OUT-INCENT-NAME   PIC X(60).
           05  WS-OUT-INCENT-TYPE   PIC X(02).
           05  WS-OUT-TYPE-DESC     PIC X(20).
           05  WS-OUT-MODEL-YEAR    PIC 9(04).
           05  WS-OUT-MAKE-CODE     PIC X(03).
           05  WS-OUT-MODEL-CODE    PIC X(06).
           05  WS-OUT-REGION-CODE   PIC X(03).
           05  WS-OUT-AMOUNT        PIC $$$,$$$,$$9.99.
           05  WS-OUT-RATE-OVERRIDE PIC Z9.999.
           05  WS-OUT-START-DATE    PIC X(10).
           05  WS-OUT-END-DATE      PIC X(10).
           05  WS-OUT-MAX-UNITS     PIC ZZ,ZZ9.
           05  WS-OUT-UNITS-USED    PIC ZZ,ZZ9.
           05  WS-OUT-UNITS-REMAIN  PIC ZZ,ZZ9.
           05  WS-OUT-STACKABLE     PIC X(01).
           05  WS-OUT-ACTIVE        PIC X(01).
           05  WS-OUT-STATUS-DESC   PIC X(10).
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  FILLER               PIC X(30).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-MODEL-YEAR-NUM   PIC S9(04) COMP VALUE 0.
           05  WS-AMOUNT-NUM       PIC S9(07)V9(02) COMP-3 VALUE 0.
           05  WS-RATE-OVR-NUM     PIC S9(02)V9(03) COMP-3 VALUE 0.
           05  WS-MAX-UNITS-NUM    PIC S9(09) COMP VALUE 0.
           05  WS-UNITS-REMAIN     PIC S9(09) COMP VALUE 0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-MODEL-YEAR        PIC S9(04) COMP VALUE 0.
           05  NI-MAKE-CODE         PIC S9(04) COMP VALUE 0.
           05  NI-MODEL-CODE        PIC S9(04) COMP VALUE 0.
           05  NI-REGION-CODE       PIC S9(04) COMP VALUE 0.
           05  NI-RATE-OVERRIDE     PIC S9(04) COMP VALUE 0.
           05  NI-MAX-UNITS         PIC S9(04) COMP VALUE 0.
      *
      *    VALID INCENTIVE TYPES
      *
       01  WS-INCENT-TYPE-TABLE.
           05  FILLER              PIC X(02) VALUE 'CR'.
           05  FILLER              PIC X(02) VALUE 'RF'.
           05  FILLER              PIC X(02) VALUE 'DL'.
           05  FILLER              PIC X(02) VALUE 'LR'.
           05  FILLER              PIC X(02) VALUE 'LC'.
           05  FILLER              PIC X(02) VALUE 'BD'.
       01  WS-INCENT-TBL-R REDEFINES WS-INCENT-TYPE-TABLE.
           05  WS-INCENT-ENTRY     PIC X(02) OCCURS 6 TIMES.
       01  WS-INCENT-IDX           PIC 9(02) VALUE 0.
       01  WS-INCENT-VALID         PIC X(01) VALUE 'N'.
           88  WS-INCENT-IS-VALID             VALUE 'Y'.
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
           EVALUATE TRUE
               WHEN WS-FUNC-INQ
                   PERFORM 3000-INQUIRY
               WHEN WS-FUNC-ADD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 4000-ADD-INCENTIVE
                   END-IF
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-INCENTIVE
                   END-IF
               WHEN WS-FUNC-ACT
                   PERFORM 6000-ACTIVATE-INCENTIVE
               WHEN WS-FUNC-DEAC
                   PERFORM 7000-DEACTIVATE-INCENTIVE
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INVALID FUNCTION: '
                          WS-IN-FUNC-CODE
                          '. USE INQ/ADD/UPD/ACT/DEAC'
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
      * 1000 - RECEIVE INPUT MESSAGE                                   *
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
      * 2000 - VALIDATE INCENTIVE INPUT FIELDS                         *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
      *    INCENTIVE ID REQUIRED
      *
           IF WS-IN-INCENT-ID = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE ID IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    INCENTIVE NAME REQUIRED
      *
           IF WS-IN-INCENT-NAME = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE NAME IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE INCENTIVE TYPE
      *
           IF WS-IN-INCENT-TYPE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE TYPE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-INCENT-VALID
           PERFORM VARYING WS-INCENT-IDX FROM 1 BY 1
               UNTIL WS-INCENT-IDX > 6 OR WS-INCENT-IS-VALID
               IF WS-IN-INCENT-TYPE =
                  WS-INCENT-ENTRY(WS-INCENT-IDX)
                   MOVE 'Y' TO WS-INCENT-VALID
               END-IF
           END-PERFORM
      *
           IF NOT WS-INCENT-IS-VALID
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'INVALID INCENTIVE TYPE: '
                      WS-IN-INCENT-TYPE
                      '. USE CR/RF/DL/LR/LC/BD'
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE AMOUNT - MUST BE > 0
      *
           IF WS-IN-AMOUNT = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE AMOUNT IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           COMPUTE WS-AMOUNT-NUM =
               FUNCTION NUMVAL(WS-IN-AMOUNT)
      *
           IF WS-AMOUNT-NUM <= 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE AMOUNT MUST BE GREATER THAN ZERO'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE START DATE REQUIRED
      *
           IF WS-IN-START-DATE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'START DATE IS REQUIRED (YYYY-MM-DD)'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    VALIDATE END DATE REQUIRED AND > START DATE
      *
           IF WS-IN-END-DATE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'END DATE IS REQUIRED (YYYY-MM-DD)'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           IF WS-IN-END-DATE <= WS-IN-START-DATE
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'END DATE MUST BE AFTER START DATE'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    MAX UNITS - OPTIONAL BUT IF PROVIDED MUST BE > 0
      *
           IF WS-IN-MAX-UNITS NOT = SPACES
               IF WS-IN-MAX-UNITS NOT NUMERIC
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'MAX UNITS MUST BE NUMERIC'
                       TO WS-ERROR-MSG
                   GO TO 2000-EXIT
               END-IF
               MOVE WS-IN-MAX-UNITS TO WS-MAX-UNITS-NUM
               IF WS-MAX-UNITS-NUM <= 0
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'MAX UNITS MUST BE GREATER THAN ZERO'
                       TO WS-ERROR-MSG
               END-IF
           END-IF
      *
      *    MODEL YEAR - OPTIONAL BUT VALIDATE IF PROVIDED
      *
           IF WS-IN-MODEL-YEAR NOT = SPACES
           AND WS-IN-MODEL-YEAR NOT NUMERIC
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'MODEL YEAR MUST BE NUMERIC IF PROVIDED'
                   TO WS-ERROR-MSG
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INQUIRY BY INCENTIVE ID                                 *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-INCENT-ID = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE ID IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT INCENTIVE_ID, INCENTIVE_NAME,
                      INCENTIVE_TYPE, MODEL_YEAR,
                      MAKE_CODE, MODEL_CODE,
                      REGION_CODE, AMOUNT,
                      RATE_OVERRIDE, START_DATE,
                      END_DATE, MAX_UNITS,
                      UNITS_USED, STACKABLE_FLAG,
                      ACTIVE_FLAG
               INTO   :DCLINCENTIVE-PROGRAM.INCENTIVE-ID,
                      :DCLINCENTIVE-PROGRAM.INCENTIVE-NAME,
                      :DCLINCENTIVE-PROGRAM.INCENTIVE-TYPE,
                      :DCLINCENTIVE-PROGRAM.MODEL-YEAR
                          :NI-MODEL-YEAR,
                      :DCLINCENTIVE-PROGRAM.MAKE-CODE
                          :NI-MAKE-CODE,
                      :DCLINCENTIVE-PROGRAM.MODEL-CODE
                          :NI-MODEL-CODE,
                      :DCLINCENTIVE-PROGRAM.REGION-CODE
                          :NI-REGION-CODE,
                      :DCLINCENTIVE-PROGRAM.AMOUNT,
                      :DCLINCENTIVE-PROGRAM.RATE-OVERRIDE
                          :NI-RATE-OVERRIDE,
                      :DCLINCENTIVE-PROGRAM.START-DATE,
                      :DCLINCENTIVE-PROGRAM.END-DATE,
                      :DCLINCENTIVE-PROGRAM.MAX-UNITS
                          :NI-MAX-UNITS,
                      :DCLINCENTIVE-PROGRAM.UNITS-USED,
                      :DCLINCENTIVE-PROGRAM.STACKABLE-FLAG,
                      :DCLINCENTIVE-PROGRAM.ACTIVE-FLAG
               FROM   AUTOSALE.INCENTIVE_PROGRAM
               WHERE  INCENTIVE_ID = :WS-IN-INCENT-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 3100-FORMAT-INQUIRY-OUTPUT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INCENTIVE NOT FOUND: '
                          WS-IN-INCENT-ID
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-INQUIRY' TO WS-DBE-SECTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-DBE-TABLE
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
      * 3100 - FORMAT INQUIRY OUTPUT                                    *
      *---------------------------------------------------------------*
       3100-FORMAT-INQUIRY-OUTPUT.
      *
           MOVE 600 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASINCI00' TO WS-OUT-MOD-NAME
           MOVE 'INQ ' TO WS-OUT-FUNC-CODE
           MOVE INCENTIVE-ID OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-INCENT-ID
           MOVE INCENTIVE-NAME-TX OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-INCENT-NAME
           MOVE INCENTIVE-TYPE OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-INCENT-TYPE
      *
      *    DECODE INCENTIVE TYPE
      *
           EVALUATE INCENTIVE-TYPE OF DCLINCENTIVE-PROGRAM
               WHEN 'CR' MOVE 'CUSTOMER REBATE'
                   TO WS-OUT-TYPE-DESC
               WHEN 'RF' MOVE 'RATE FINANCE'
                   TO WS-OUT-TYPE-DESC
               WHEN 'DL' MOVE 'DEALER CASH'
                   TO WS-OUT-TYPE-DESC
               WHEN 'LR' MOVE 'LEASE REBATE'
                   TO WS-OUT-TYPE-DESC
               WHEN 'LC' MOVE 'LOYALTY CREDIT'
                   TO WS-OUT-TYPE-DESC
               WHEN 'BD' MOVE 'BONUS/STAIR-STEP'
                   TO WS-OUT-TYPE-DESC
               WHEN OTHER MOVE 'UNKNOWN'
                   TO WS-OUT-TYPE-DESC
           END-EVALUATE
      *
      *    OPTIONAL FIELDS
      *
           IF NI-MODEL-YEAR >= 0
               MOVE MODEL-YEAR OF DCLINCENTIVE-PROGRAM
                   TO WS-OUT-MODEL-YEAR
           ELSE
               MOVE 0 TO WS-OUT-MODEL-YEAR
           END-IF
      *
           IF NI-MAKE-CODE >= 0
               MOVE MAKE-CODE OF DCLINCENTIVE-PROGRAM
                   TO WS-OUT-MAKE-CODE
           ELSE
               MOVE 'ALL' TO WS-OUT-MAKE-CODE
           END-IF
      *
           IF NI-MODEL-CODE >= 0
               MOVE MODEL-CODE OF DCLINCENTIVE-PROGRAM
                   TO WS-OUT-MODEL-CODE
           ELSE
               MOVE 'ALL   ' TO WS-OUT-MODEL-CODE
           END-IF
      *
           IF NI-REGION-CODE >= 0
               MOVE REGION-CODE OF DCLINCENTIVE-PROGRAM
                   TO WS-OUT-REGION-CODE
           ELSE
               MOVE 'ALL' TO WS-OUT-REGION-CODE
           END-IF
      *
           MOVE AMOUNT OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-AMOUNT
      *
           IF NI-RATE-OVERRIDE >= 0
               MOVE RATE-OVERRIDE OF DCLINCENTIVE-PROGRAM
                   TO WS-OUT-RATE-OVERRIDE
           ELSE
               MOVE 0 TO WS-OUT-RATE-OVERRIDE
           END-IF
      *
           MOVE START-DATE OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-START-DATE
           MOVE END-DATE OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-END-DATE
      *
      *    UNITS TRACKING
      *
           IF NI-MAX-UNITS >= 0
               MOVE MAX-UNITS OF DCLINCENTIVE-PROGRAM
                   TO WS-OUT-MAX-UNITS
               COMPUTE WS-UNITS-REMAIN =
                   MAX-UNITS OF DCLINCENTIVE-PROGRAM -
                   UNITS-USED OF DCLINCENTIVE-PROGRAM
               MOVE WS-UNITS-REMAIN TO WS-OUT-UNITS-REMAIN
           ELSE
               MOVE 0 TO WS-OUT-MAX-UNITS
               MOVE 0 TO WS-OUT-UNITS-REMAIN
           END-IF
      *
           MOVE UNITS-USED OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-UNITS-USED
           MOVE STACKABLE-FLAG OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-STACKABLE
           MOVE ACTIVE-FLAG OF DCLINCENTIVE-PROGRAM
               TO WS-OUT-ACTIVE
      *
           IF ACTIVE-FLAG OF DCLINCENTIVE-PROGRAM = 'Y'
               MOVE 'ACTIVE' TO WS-OUT-STATUS-DESC
           ELSE
               MOVE 'INACTIVE' TO WS-OUT-STATUS-DESC
           END-IF
      *
           MOVE 'INCENTIVE RECORD DISPLAYED SUCCESSFULLY'
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
      * 4000 - ADD NEW INCENTIVE PROGRAM                               *
      *---------------------------------------------------------------*
       4000-ADD-INCENTIVE.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               INSERT INTO AUTOSALE.INCENTIVE_PROGRAM
               ( INCENTIVE_ID, INCENTIVE_NAME,
                 INCENTIVE_TYPE, MODEL_YEAR,
                 MAKE_CODE, MODEL_CODE,
                 REGION_CODE, AMOUNT,
                 RATE_OVERRIDE, START_DATE,
                 END_DATE, MAX_UNITS,
                 UNITS_USED, STACKABLE_FLAG,
                 ACTIVE_FLAG, CREATED_TS )
               VALUES
               ( :DCLINCENTIVE-PROGRAM.INCENTIVE-ID,
                 :DCLINCENTIVE-PROGRAM.INCENTIVE-NAME,
                 :DCLINCENTIVE-PROGRAM.INCENTIVE-TYPE,
                 :DCLINCENTIVE-PROGRAM.MODEL-YEAR
                     :NI-MODEL-YEAR,
                 :DCLINCENTIVE-PROGRAM.MAKE-CODE
                     :NI-MAKE-CODE,
                 :DCLINCENTIVE-PROGRAM.MODEL-CODE
                     :NI-MODEL-CODE,
                 :DCLINCENTIVE-PROGRAM.REGION-CODE
                     :NI-REGION-CODE,
                 :DCLINCENTIVE-PROGRAM.AMOUNT,
                 :DCLINCENTIVE-PROGRAM.RATE-OVERRIDE
                     :NI-RATE-OVERRIDE,
                 :DCLINCENTIVE-PROGRAM.START-DATE,
                 :DCLINCENTIVE-PROGRAM.END-DATE,
                 :DCLINCENTIVE-PROGRAM.MAX-UNITS
                     :NI-MAX-UNITS,
                 0,
                 :DCLINCENTIVE-PROGRAM.STACKABLE-FLAG,
                 'Y',
                 CURRENT TIMESTAMP )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 600 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASINCI00' TO WS-OUT-MOD-NAME
                   MOVE 'ADD ' TO WS-OUT-FUNC-CODE
                   STRING 'INCENTIVE ' WS-IN-INCENT-ID
                          ' ADDED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN -803
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INCENTIVE ID '
                          WS-IN-INCENT-ID
                          ' ALREADY EXISTS'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '4000-ADD' TO WS-DBE-SECTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-DBE-TABLE
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
           MOVE WS-IN-INCENT-ID
               TO INCENTIVE-ID OF DCLINCENTIVE-PROGRAM
      *
           MOVE WS-IN-INCENT-NAME
               TO INCENTIVE-NAME-TX OF DCLINCENTIVE-PROGRAM
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-INCENT-NAME TRAILING))
               TO INCENTIVE-NAME-LN OF DCLINCENTIVE-PROGRAM
      *
           MOVE WS-IN-INCENT-TYPE
               TO INCENTIVE-TYPE OF DCLINCENTIVE-PROGRAM
      *
      *    MODEL YEAR (NULLABLE)
      *
           IF WS-IN-MODEL-YEAR NOT = SPACES
           AND WS-IN-MODEL-YEAR NUMERIC
               MOVE 0 TO NI-MODEL-YEAR
               MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-NUM
               MOVE WS-MODEL-YEAR-NUM
                   TO MODEL-YEAR OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE -1 TO NI-MODEL-YEAR
           END-IF
      *
      *    MAKE CODE (NULLABLE)
      *
           IF WS-IN-MAKE-CODE NOT = SPACES
               MOVE 0 TO NI-MAKE-CODE
               MOVE WS-IN-MAKE-CODE
                   TO MAKE-CODE OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE -1 TO NI-MAKE-CODE
           END-IF
      *
      *    MODEL CODE (NULLABLE)
      *
           IF WS-IN-MODEL-CODE NOT = SPACES
               MOVE 0 TO NI-MODEL-CODE
               MOVE WS-IN-MODEL-CODE
                   TO MODEL-CODE OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE -1 TO NI-MODEL-CODE
           END-IF
      *
      *    REGION CODE (NULLABLE)
      *
           IF WS-IN-REGION-CODE NOT = SPACES
               MOVE 0 TO NI-REGION-CODE
               MOVE WS-IN-REGION-CODE
                   TO REGION-CODE OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE -1 TO NI-REGION-CODE
           END-IF
      *
           MOVE WS-AMOUNT-NUM
               TO AMOUNT OF DCLINCENTIVE-PROGRAM
      *
      *    RATE OVERRIDE (NULLABLE)
      *
           IF WS-IN-RATE-OVERRIDE NOT = SPACES
               MOVE 0 TO NI-RATE-OVERRIDE
               COMPUTE WS-RATE-OVR-NUM =
                   FUNCTION NUMVAL(WS-IN-RATE-OVERRIDE)
               MOVE WS-RATE-OVR-NUM
                   TO RATE-OVERRIDE OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE -1 TO NI-RATE-OVERRIDE
           END-IF
      *
           MOVE WS-IN-START-DATE
               TO START-DATE OF DCLINCENTIVE-PROGRAM
           MOVE WS-IN-END-DATE
               TO END-DATE OF DCLINCENTIVE-PROGRAM
      *
      *    MAX UNITS (NULLABLE)
      *
           IF WS-IN-MAX-UNITS NOT = SPACES
           AND WS-IN-MAX-UNITS NUMERIC
               MOVE 0 TO NI-MAX-UNITS
               MOVE WS-IN-MAX-UNITS TO WS-MAX-UNITS-NUM
               MOVE WS-MAX-UNITS-NUM
                   TO MAX-UNITS OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE -1 TO NI-MAX-UNITS
           END-IF
      *
           IF WS-IN-STACKABLE = SPACES
               MOVE 'N' TO STACKABLE-FLAG OF DCLINCENTIVE-PROGRAM
           ELSE
               MOVE WS-IN-STACKABLE
                   TO STACKABLE-FLAG OF DCLINCENTIVE-PROGRAM
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - UPDATE EXISTING INCENTIVE PROGRAM                       *
      *---------------------------------------------------------------*
       5000-UPDATE-INCENTIVE.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           EXEC SQL
               UPDATE AUTOSALE.INCENTIVE_PROGRAM
               SET    INCENTIVE_NAME =
                          :DCLINCENTIVE-PROGRAM.INCENTIVE-NAME,
                      INCENTIVE_TYPE =
                          :DCLINCENTIVE-PROGRAM.INCENTIVE-TYPE,
                      MODEL_YEAR =
                          :DCLINCENTIVE-PROGRAM.MODEL-YEAR
                          :NI-MODEL-YEAR,
                      MAKE_CODE =
                          :DCLINCENTIVE-PROGRAM.MAKE-CODE
                          :NI-MAKE-CODE,
                      MODEL_CODE =
                          :DCLINCENTIVE-PROGRAM.MODEL-CODE
                          :NI-MODEL-CODE,
                      REGION_CODE =
                          :DCLINCENTIVE-PROGRAM.REGION-CODE
                          :NI-REGION-CODE,
                      AMOUNT =
                          :DCLINCENTIVE-PROGRAM.AMOUNT,
                      RATE_OVERRIDE =
                          :DCLINCENTIVE-PROGRAM.RATE-OVERRIDE
                          :NI-RATE-OVERRIDE,
                      START_DATE =
                          :DCLINCENTIVE-PROGRAM.START-DATE,
                      END_DATE =
                          :DCLINCENTIVE-PROGRAM.END-DATE,
                      MAX_UNITS =
                          :DCLINCENTIVE-PROGRAM.MAX-UNITS
                          :NI-MAX-UNITS,
                      STACKABLE_FLAG =
                          :DCLINCENTIVE-PROGRAM.STACKABLE-FLAG
               WHERE  INCENTIVE_ID = :WS-IN-INCENT-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 600 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASINCI00' TO WS-OUT-MOD-NAME
                   MOVE 'UPD ' TO WS-OUT-FUNC-CODE
                   STRING 'INCENTIVE ' WS-IN-INCENT-ID
                          ' UPDATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'INCENTIVE NOT FOUND: '
                          WS-IN-INCENT-ID
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '5000-UPDATE' TO WS-DBE-SECTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-DBE-TABLE
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
      * 6000 - ACTIVATE INCENTIVE PROGRAM                              *
      *---------------------------------------------------------------*
       6000-ACTIVATE-INCENTIVE.
      *
           IF WS-IN-INCENT-ID = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE ID IS REQUIRED FOR ACTIVATE'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.INCENTIVE_PROGRAM
               SET    ACTIVE_FLAG = 'Y'
               WHERE  INCENTIVE_ID = :WS-IN-INCENT-ID
               AND    ACTIVE_FLAG = 'N'
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 600 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASINCI00' TO WS-OUT-MOD-NAME
                   MOVE 'ACT ' TO WS-OUT-FUNC-CODE
                   STRING 'INCENTIVE ' WS-IN-INCENT-ID
                          ' ACTIVATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
      *
                   MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
                   MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
                   MOVE 'UPD' TO WS-AUD-ACTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-AUD-TABLE
                   MOVE WS-IN-INCENT-ID TO WS-AUD-KEY
                   MOVE 'ACTIVE_FLAG=N' TO WS-AUD-OLD-VAL
                   MOVE 'ACTIVE_FLAG=Y' TO WS-AUD-NEW-VAL
                   CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                          WS-AUD-PROGRAM-ID
                                          WS-AUD-ACTION
                                          WS-AUD-TABLE
                                          WS-AUD-KEY
                                          WS-AUD-OLD-VAL
                                          WS-AUD-NEW-VAL
                                          WS-AUD-RC
                                          WS-AUD-MSG
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE
               'INCENTIVE NOT FOUND OR ALREADY ACTIVE'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '6000-ACTIVATE' TO WS-DBE-SECTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-DBE-TABLE
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
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7000 - DEACTIVATE INCENTIVE PROGRAM                            *
      *---------------------------------------------------------------*
       7000-DEACTIVATE-INCENTIVE.
      *
           IF WS-IN-INCENT-ID = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INCENTIVE ID IS REQUIRED FOR DEACTIVATE'
                   TO WS-ERROR-MSG
               GO TO 7000-EXIT
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.INCENTIVE_PROGRAM
               SET    ACTIVE_FLAG = 'N'
               WHERE  INCENTIVE_ID = :WS-IN-INCENT-ID
               AND    ACTIVE_FLAG = 'Y'
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 600 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE 'ASINCI00' TO WS-OUT-MOD-NAME
                   MOVE 'DEAC' TO WS-OUT-FUNC-CODE
                   STRING 'INCENTIVE ' WS-IN-INCENT-ID
                          ' DEACTIVATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
      *
                   MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
                   MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
                   MOVE 'UPD' TO WS-AUD-ACTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-AUD-TABLE
                   MOVE WS-IN-INCENT-ID TO WS-AUD-KEY
                   MOVE 'ACTIVE_FLAG=Y' TO WS-AUD-OLD-VAL
                   MOVE 'ACTIVE_FLAG=N' TO WS-AUD-NEW-VAL
                   CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                          WS-AUD-PROGRAM-ID
                                          WS-AUD-ACTION
                                          WS-AUD-TABLE
                                          WS-AUD-KEY
                                          WS-AUD-OLD-VAL
                                          WS-AUD-NEW-VAL
                                          WS-AUD-RC
                                          WS-AUD-MSG
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE
               'INCENTIVE NOT FOUND OR ALREADY INACTIVE'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '7000-DEACTIVATE' TO WS-DBE-SECTION
                   MOVE 'INCENTIVE_PROGRAM' TO WS-DBE-TABLE
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
       7000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - SEND ERROR RESPONSE                                     *
      *---------------------------------------------------------------*
       8000-SEND-ERROR.
      *
           MOVE 600 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'ASINCI00' TO WS-OUT-MOD-NAME
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
      * 9000 - LOG AUDIT TRAIL                                         *
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
           MOVE 'INCENTIVE_PROGRAM' TO WS-AUD-TABLE
           MOVE WS-IN-INCENT-ID TO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           MOVE WS-IN-INCENT-NAME TO WS-AUD-NEW-VAL
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
      * END OF ADMINC00                                              *
      ****************************************************************
