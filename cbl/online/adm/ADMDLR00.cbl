       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMDLR00.
      ****************************************************************
      * PROGRAM:    ADMDLR00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMD                                             *
      * MFS MID:    MFSADLR0 (DEALER MAINTENANCE SCREEN)             *
      * MFS MOD:    ASDLRI00 (DEALER INQUIRY RESPONSE)               *
      *                                                              *
      * PURPOSE:    DEALER MASTER MAINTENANCE. PROVIDES FULL CRUD    *
      *             OPERATIONS ON THE DEALER TABLE INCLUDING          *
      *             INQUIRY, ADD, UPDATE, AND LIST BY REGION.         *
      *                                                              *
      * FUNCTIONS:  INQ - INQUIRY BY DEALER CODE                     *
      *             ADD - ADD NEW DEALER RECORD                      *
      *             UPD - UPDATE EXISTING DEALER                     *
      *             LST - LIST DEALERS BY REGION                     *
      *                                                              *
      * CALLS:      COMFMTL0 - FORMAT PHONE NUMBERS                 *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMDLR00'.
      *
      *    IMS FUNCTION CODES AND PCB FIELDS
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR DEALER TABLE
      *
           COPY DCLDEALR.
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
           05  WS-IN-DEALER-CODE    PIC X(05).
           05  WS-IN-DEALER-NAME    PIC X(60).
           05  WS-IN-ADDRESS1       PIC X(50).
           05  WS-IN-ADDRESS2       PIC X(50).
           05  WS-IN-CITY           PIC X(30).
           05  WS-IN-STATE          PIC X(02).
           05  WS-IN-ZIP            PIC X(10).
           05  WS-IN-PHONE          PIC X(10).
           05  WS-IN-FAX            PIC X(10).
           05  WS-IN-PRINCIPAL      PIC X(40).
           05  WS-IN-REGION         PIC X(03).
           05  WS-IN-ZONE           PIC X(02).
           05  WS-IN-OEM-NUM        PIC X(10).
           05  WS-IN-FPL-ID         PIC X(05).
           05  WS-IN-MAX-INV        PIC X(05).
           05  WS-IN-ACTIVE         PIC X(01).
           05  WS-IN-OPEN-DATE      PIC X(10).
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
           05  WS-OUT-DEALER-CODE   PIC X(05).
           05  WS-OUT-DEALER-NAME   PIC X(60).
           05  WS-OUT-ADDRESS1      PIC X(50).
           05  WS-OUT-ADDRESS2      PIC X(50).
           05  WS-OUT-CITY          PIC X(30).
           05  WS-OUT-STATE         PIC X(02).
           05  WS-OUT-ZIP           PIC X(10).
           05  WS-OUT-PHONE-FMT    PIC X(14).
           05  WS-OUT-FAX-FMT      PIC X(14).
           05  WS-OUT-PRINCIPAL     PIC X(40).
           05  WS-OUT-REGION        PIC X(03).
           05  WS-OUT-ZONE          PIC X(02).
           05  WS-OUT-OEM-NUM       PIC X(10).
           05  WS-OUT-FPL-ID        PIC X(05).
           05  WS-OUT-MAX-INV       PIC X(05).
           05  WS-OUT-ACTIVE        PIC X(01).
           05  WS-OUT-OPEN-DATE     PIC X(10).
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  FILLER               PIC X(20).
      *
      *    LIST OUTPUT - UP TO 15 DEALERS PER SCREEN
      *
       01  WS-LIST-OUTPUT.
           05  WS-LST-LL            PIC S9(04) COMP.
           05  WS-LST-ZZ            PIC S9(04) COMP.
           05  WS-LST-MOD-NAME      PIC X(08).
           05  WS-LST-REGION        PIC X(03).
           05  WS-LST-COUNT         PIC 9(03).
           05  WS-LST-MSG           PIC X(79).
           05  WS-LST-ENTRY OCCURS 15 TIMES.
               10  WS-LST-DLR-CODE PIC X(05).
               10  WS-LST-DLR-NAME PIC X(40).
               10  WS-LST-DLR-CITY PIC X(20).
               10  WS-LST-DLR-ST   PIC X(02).
               10  WS-LST-DLR-ACT  PIC X(01).
           05  FILLER               PIC X(50).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-MAX-INV-NUM      PIC S9(04) COMP VALUE 0.
           05  WS-LIST-IDX         PIC 9(03) VALUE 0.
           05  WS-ROWS-FETCHED     PIC 9(03) VALUE 0.
           05  WS-STATE-VALID      PIC X(01) VALUE 'N'.
           05  WS-PHONE-WORK       PIC X(10).
           05  WS-PHONE-FMT        PIC X(14).
           05  WS-FMT-RC           PIC S9(04) COMP.
      *
      *    NULL INDICATORS FOR NULLABLE COLUMNS
      *
       01  WS-NULL-IND.
           05  NI-ADDRESS2          PIC S9(04) COMP VALUE 0.
           05  NI-FAX               PIC S9(04) COMP VALUE 0.
           05  NI-FPL-ID            PIC S9(04) COMP VALUE 0.
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
      *    CURSOR FOR DEALER LIST BY REGION
      *
           EXEC SQL
               DECLARE DEALER_LIST_CSR CURSOR FOR
               SELECT DEALER_CODE,
                      DEALER_NAME,
                      CITY,
                      STATE_CODE,
                      ACTIVE_FLAG
               FROM   AUTOSALE.DEALER
               WHERE  REGION_CODE = :WS-IN-REGION
               ORDER BY DEALER_NAME
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
      *    RECEIVE INPUT MESSAGE
      *
           PERFORM 1000-RECEIVE-INPUT
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR
               GOBACK
           END-IF
      *
      *    ROUTE BASED ON FUNCTION CODE
      *
           EVALUATE TRUE
               WHEN WS-FUNC-INQ
                   PERFORM 3000-INQUIRY
               WHEN WS-FUNC-ADD
                   PERFORM 2000-VALIDATE-DEALER-INPUT
                   IF WS-NO-ERROR
                       PERFORM 4000-ADD-DEALER
                   END-IF
               WHEN WS-FUNC-UPD
                   PERFORM 2000-VALIDATE-DEALER-INPUT
                   IF WS-NO-ERROR
                       PERFORM 5000-UPDATE-DEALER
                   END-IF
               WHEN WS-FUNC-LST
                   PERFORM 6000-LIST-BY-REGION
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
      * 2000 - VALIDATE DEALER INPUT FIELDS FOR ADD/UPDATE             *
      *---------------------------------------------------------------*
       2000-VALIDATE-DEALER-INPUT.
      *
      *    DEALER CODE REQUIRED
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    DEALER NAME REQUIRED
      *
           IF WS-IN-DEALER-NAME = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'DEALER NAME IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    ADDRESS LINE 1 REQUIRED
      *
           IF WS-IN-ADDRESS1 = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ADDRESS LINE 1 IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    CITY REQUIRED
      *
           IF WS-IN-CITY = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'CITY IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    STATE CODE - MUST BE 2 ALPHA CHARS
      *
           IF WS-IN-STATE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'STATE CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           INSPECT WS-IN-STATE TALLYING WS-MAX-INV-NUM
               FOR ALL 'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I'
                       'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R'
                       'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z'
           IF WS-MAX-INV-NUM < 2
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'STATE CODE MUST BE 2 ALPHA CHARACTERS'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    ZIP CODE REQUIRED
      *
           IF WS-IN-ZIP = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ZIP CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    PHONE NUMBER - MUST BE 10 DIGITS
      *
           IF WS-IN-PHONE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'PHONE NUMBER IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           IF WS-IN-PHONE NOT NUMERIC
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'PHONE MUST BE 10 DIGITS (NO DASHES)'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    REGION CODE REQUIRED
      *
           IF WS-IN-REGION = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'REGION CODE IS REQUIRED'
                   TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    ZONE CODE REQUIRED
      *
           IF WS-IN-ZONE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ZONE CODE IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    MAX INVENTORY - MUST BE NUMERIC IF PROVIDED
      *
           IF WS-IN-MAX-INV NOT = SPACES
               IF WS-IN-MAX-INV NOT NUMERIC
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'MAX INVENTORY MUST BE NUMERIC'
                       TO WS-ERROR-MSG
               END-IF
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INQUIRY - SELECT DEALER BY DEALER CODE                  *
      *---------------------------------------------------------------*
       3000-INQUIRY.
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'DEALER CODE IS REQUIRED FOR INQUIRY'
                   TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT DEALER_CODE,
                      DEALER_NAME,
                      ADDRESS_LINE1,
                      ADDRESS_LINE2,
                      CITY,
                      STATE_CODE,
                      ZIP_CODE,
                      PHONE_NUMBER,
                      FAX_NUMBER,
                      DEALER_PRINCIPAL,
                      REGION_CODE,
                      ZONE_CODE,
                      OEM_DEALER_NUM,
                      FLOOR_PLAN_LENDER_ID,
                      MAX_INVENTORY,
                      ACTIVE_FLAG,
                      OPENED_DATE
               INTO   :DCLDEALER.DEALER-CODE,
                      :DCLDEALER.DEALER-NAME,
                      :DCLDEALER.ADDRESS-LINE1,
                      :DCLDEALER.ADDRESS-LINE2
                          :NI-ADDRESS2,
                      :DCLDEALER.CITY,
                      :DCLDEALER.STATE-CODE,
                      :DCLDEALER.ZIP-CODE,
                      :DCLDEALER.PHONE-NUMBER,
                      :DCLDEALER.FAX-NUMBER
                          :NI-FAX,
                      :DCLDEALER.DEALER-PRINCIPAL,
                      :DCLDEALER.REGION-CODE,
                      :DCLDEALER.ZONE-CODE,
                      :DCLDEALER.OEM-DEALER-NUM,
                      :DCLDEALER.FLOOR-PLAN-LENDER-ID
                          :NI-FPL-ID,
                      :DCLDEALER.MAX-INVENTORY,
                      :DCLDEALER.ACTIVE-FLAG,
                      :DCLDEALER.OPENED-DATE
               FROM   AUTOSALE.DEALER
               WHERE  DEALER_CODE = :WS-IN-DEALER-CODE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 3100-FORMAT-INQUIRY-OUTPUT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'DEALER NOT FOUND: '
                          WS-IN-DEALER-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-INQUIRY' TO WS-DBE-SECTION
                   MOVE 'DEALER' TO WS-DBE-TABLE
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
      * 3100 - FORMAT INQUIRY OUTPUT MESSAGE                           *
      *---------------------------------------------------------------*
       3100-FORMAT-INQUIRY-OUTPUT.
      *
           MOVE 550 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE WS-MOD-DEALER-INQ TO WS-OUT-MOD-NAME
           MOVE 'INQ' TO WS-OUT-FUNC-CODE
           MOVE DEALER-CODE OF DCLDEALER
               TO WS-OUT-DEALER-CODE
           MOVE DEALER-NAME-TX OF DCLDEALER
               TO WS-OUT-DEALER-NAME
           MOVE ADDRESS-LINE1-TX OF DCLDEALER
               TO WS-OUT-ADDRESS1
      *
           IF NI-ADDRESS2 >= 0
               MOVE ADDRESS-LINE2-TX OF DCLDEALER
                   TO WS-OUT-ADDRESS2
           ELSE
               MOVE SPACES TO WS-OUT-ADDRESS2
           END-IF
      *
           MOVE CITY-TX OF DCLDEALER TO WS-OUT-CITY
           MOVE STATE-CODE OF DCLDEALER TO WS-OUT-STATE
           MOVE ZIP-CODE OF DCLDEALER TO WS-OUT-ZIP
      *
      *    FORMAT PHONE NUMBER VIA COMMON MODULE
      *
           MOVE PHONE-NUMBER OF DCLDEALER TO WS-PHONE-WORK
           CALL 'COMFMTL0' USING WS-PHONE-WORK
                                  WS-PHONE-FMT
                                  WS-FMT-RC
           IF WS-FMT-RC = 0
               MOVE WS-PHONE-FMT TO WS-OUT-PHONE-FMT
           ELSE
               MOVE PHONE-NUMBER OF DCLDEALER
                   TO WS-OUT-PHONE-FMT
           END-IF
      *
      *    FORMAT FAX NUMBER IF PRESENT
      *
           IF NI-FAX >= 0
               MOVE FAX-NUMBER OF DCLDEALER TO WS-PHONE-WORK
               CALL 'COMFMTL0' USING WS-PHONE-WORK
                                      WS-PHONE-FMT
                                      WS-FMT-RC
               IF WS-FMT-RC = 0
                   MOVE WS-PHONE-FMT TO WS-OUT-FAX-FMT
               ELSE
                   MOVE FAX-NUMBER OF DCLDEALER
                       TO WS-OUT-FAX-FMT
               END-IF
           ELSE
               MOVE SPACES TO WS-OUT-FAX-FMT
           END-IF
      *
           MOVE DEALER-PRINCIPAL-TX OF DCLDEALER
               TO WS-OUT-PRINCIPAL
           MOVE REGION-CODE OF DCLDEALER TO WS-OUT-REGION
           MOVE ZONE-CODE OF DCLDEALER TO WS-OUT-ZONE
           MOVE OEM-DEALER-NUM OF DCLDEALER TO WS-OUT-OEM-NUM
      *
           IF NI-FPL-ID >= 0
               MOVE FLOOR-PLAN-LENDER-ID OF DCLDEALER
                   TO WS-OUT-FPL-ID
           ELSE
               MOVE SPACES TO WS-OUT-FPL-ID
           END-IF
      *
           MOVE MAX-INVENTORY OF DCLDEALER TO WS-OUT-MAX-INV
           MOVE ACTIVE-FLAG OF DCLDEALER TO WS-OUT-ACTIVE
           MOVE OPENED-DATE OF DCLDEALER TO WS-OUT-OPEN-DATE
           MOVE 'DEALER RECORD DISPLAYED SUCCESSFULLY'
               TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
      *
      *    SEND OUTPUT
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
           .
       3100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - ADD NEW DEALER RECORD                                   *
      *---------------------------------------------------------------*
       4000-ADD-DEALER.
      *
      *    SET UP DCLGEN FIELDS
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
      *    SET NULL INDICATORS
      *
           IF WS-IN-ADDRESS2 = SPACES
               MOVE -1 TO NI-ADDRESS2
           ELSE
               MOVE 0 TO NI-ADDRESS2
           END-IF
      *
           IF WS-IN-FAX = SPACES
               MOVE -1 TO NI-FAX
           ELSE
               MOVE 0 TO NI-FAX
           END-IF
      *
           IF WS-IN-FPL-ID = SPACES
               MOVE -1 TO NI-FPL-ID
           ELSE
               MOVE 0 TO NI-FPL-ID
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.DEALER
               ( DEALER_CODE, DEALER_NAME,
                 ADDRESS_LINE1, ADDRESS_LINE2,
                 CITY, STATE_CODE, ZIP_CODE,
                 PHONE_NUMBER, FAX_NUMBER,
                 DEALER_PRINCIPAL, REGION_CODE,
                 ZONE_CODE, OEM_DEALER_NUM,
                 FLOOR_PLAN_LENDER_ID, MAX_INVENTORY,
                 ACTIVE_FLAG, OPENED_DATE,
                 CREATED_TS, UPDATED_TS )
               VALUES
               ( :DCLDEALER.DEALER-CODE,
                 :DCLDEALER.DEALER-NAME,
                 :DCLDEALER.ADDRESS-LINE1,
                 :DCLDEALER.ADDRESS-LINE2
                     :NI-ADDRESS2,
                 :DCLDEALER.CITY,
                 :DCLDEALER.STATE-CODE,
                 :DCLDEALER.ZIP-CODE,
                 :DCLDEALER.PHONE-NUMBER,
                 :DCLDEALER.FAX-NUMBER
                     :NI-FAX,
                 :DCLDEALER.DEALER-PRINCIPAL,
                 :DCLDEALER.REGION-CODE,
                 :DCLDEALER.ZONE-CODE,
                 :DCLDEALER.OEM-DEALER-NUM,
                 :DCLDEALER.FLOOR-PLAN-LENDER-ID
                     :NI-FPL-ID,
                 :DCLDEALER.MAX-INVENTORY,
                 :DCLDEALER.ACTIVE-FLAG,
                 :DCLDEALER.OPENED-DATE,
                 CURRENT TIMESTAMP,
                 CURRENT TIMESTAMP )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 550 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE WS-MOD-DEALER-INQ TO WS-OUT-MOD-NAME
                   MOVE 'ADD' TO WS-OUT-FUNC-CODE
                   MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
                   STRING 'DEALER ' WS-IN-DEALER-CODE
                          ' ADDED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN -803
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'DEALER CODE ' WS-IN-DEALER-CODE
                          ' ALREADY EXISTS'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '4000-ADD-DEALER' TO WS-DBE-SECTION
                   MOVE 'DEALER' TO WS-DBE-TABLE
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
      * 4100 - POPULATE DCLGEN FIELDS FROM INPUT                       *
      *---------------------------------------------------------------*
       4100-POPULATE-DCLGEN.
      *
           MOVE WS-IN-DEALER-CODE TO DEALER-CODE OF DCLDEALER
      *
           MOVE WS-IN-DEALER-NAME TO DEALER-NAME-TX OF DCLDEALER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-DEALER-NAME TRAILING))
               TO DEALER-NAME-LN OF DCLDEALER
      *
           MOVE WS-IN-ADDRESS1 TO ADDRESS-LINE1-TX OF DCLDEALER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-ADDRESS1 TRAILING))
               TO ADDRESS-LINE1-LN OF DCLDEALER
      *
           MOVE WS-IN-ADDRESS2 TO ADDRESS-LINE2-TX OF DCLDEALER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-ADDRESS2 TRAILING))
               TO ADDRESS-LINE2-LN OF DCLDEALER
      *
           MOVE WS-IN-CITY TO CITY-TX OF DCLDEALER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-CITY TRAILING))
               TO CITY-LN OF DCLDEALER
      *
           MOVE WS-IN-STATE TO STATE-CODE OF DCLDEALER
           MOVE WS-IN-ZIP TO ZIP-CODE OF DCLDEALER
           MOVE WS-IN-PHONE TO PHONE-NUMBER OF DCLDEALER
           MOVE WS-IN-FAX TO FAX-NUMBER OF DCLDEALER
      *
           MOVE WS-IN-PRINCIPAL TO
               DEALER-PRINCIPAL-TX OF DCLDEALER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-IN-PRINCIPAL TRAILING))
               TO DEALER-PRINCIPAL-LN OF DCLDEALER
      *
           MOVE WS-IN-REGION TO REGION-CODE OF DCLDEALER
           MOVE WS-IN-ZONE TO ZONE-CODE OF DCLDEALER
           MOVE WS-IN-OEM-NUM TO OEM-DEALER-NUM OF DCLDEALER
           MOVE WS-IN-FPL-ID TO
               FLOOR-PLAN-LENDER-ID OF DCLDEALER
      *
           IF WS-IN-MAX-INV NUMERIC
               MOVE WS-IN-MAX-INV TO WS-MAX-INV-NUM
               MOVE WS-MAX-INV-NUM TO MAX-INVENTORY OF DCLDEALER
           ELSE
               MOVE 100 TO MAX-INVENTORY OF DCLDEALER
           END-IF
      *
           IF WS-IN-ACTIVE = SPACES
               MOVE 'Y' TO ACTIVE-FLAG OF DCLDEALER
           ELSE
               MOVE WS-IN-ACTIVE TO ACTIVE-FLAG OF DCLDEALER
           END-IF
      *
           MOVE WS-IN-OPEN-DATE TO OPENED-DATE OF DCLDEALER
           .
       4100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - UPDATE EXISTING DEALER RECORD                           *
      *---------------------------------------------------------------*
       5000-UPDATE-DEALER.
      *
           PERFORM 4100-POPULATE-DCLGEN
      *
           IF WS-IN-ADDRESS2 = SPACES
               MOVE -1 TO NI-ADDRESS2
           ELSE
               MOVE 0 TO NI-ADDRESS2
           END-IF
      *
           IF WS-IN-FAX = SPACES
               MOVE -1 TO NI-FAX
           ELSE
               MOVE 0 TO NI-FAX
           END-IF
      *
           IF WS-IN-FPL-ID = SPACES
               MOVE -1 TO NI-FPL-ID
           ELSE
               MOVE 0 TO NI-FPL-ID
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.DEALER
               SET    DEALER_NAME = :DCLDEALER.DEALER-NAME,
                      ADDRESS_LINE1 = :DCLDEALER.ADDRESS-LINE1,
                      ADDRESS_LINE2 = :DCLDEALER.ADDRESS-LINE2
                          :NI-ADDRESS2,
                      CITY = :DCLDEALER.CITY,
                      STATE_CODE = :DCLDEALER.STATE-CODE,
                      ZIP_CODE = :DCLDEALER.ZIP-CODE,
                      PHONE_NUMBER = :DCLDEALER.PHONE-NUMBER,
                      FAX_NUMBER = :DCLDEALER.FAX-NUMBER
                          :NI-FAX,
                      DEALER_PRINCIPAL =
                          :DCLDEALER.DEALER-PRINCIPAL,
                      REGION_CODE = :DCLDEALER.REGION-CODE,
                      ZONE_CODE = :DCLDEALER.ZONE-CODE,
                      OEM_DEALER_NUM = :DCLDEALER.OEM-DEALER-NUM,
                      FLOOR_PLAN_LENDER_ID =
                          :DCLDEALER.FLOOR-PLAN-LENDER-ID
                          :NI-FPL-ID,
                      MAX_INVENTORY = :DCLDEALER.MAX-INVENTORY,
                      ACTIVE_FLAG = :DCLDEALER.ACTIVE-FLAG,
                      UPDATED_TS = CURRENT TIMESTAMP
               WHERE  DEALER_CODE = :WS-IN-DEALER-CODE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   MOVE 550 TO WS-OUT-LL
                   MOVE 0 TO WS-OUT-ZZ
                   MOVE WS-MOD-DEALER-INQ TO WS-OUT-MOD-NAME
                   MOVE 'UPD' TO WS-OUT-FUNC-CODE
                   MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
                   STRING 'DEALER ' WS-IN-DEALER-CODE
                          ' UPDATED SUCCESSFULLY'
                       DELIMITED BY SIZE
                       INTO WS-OUT-MSG-LINE1
                   CALL 'CBLTDLI' USING WS-IO-ISRT
                                        IO-PCB-MASK
                                        WS-OUTPUT-MSG
                   PERFORM 9000-LOG-AUDIT
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   STRING 'DEALER NOT FOUND: '
                          WS-IN-DEALER-CODE
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '5000-UPDATE' TO WS-DBE-SECTION
                   MOVE 'DEALER' TO WS-DBE-TABLE
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
      * 6000 - LIST DEALERS BY REGION USING CURSOR                     *
      *---------------------------------------------------------------*
       6000-LIST-BY-REGION.
      *
           IF WS-IN-REGION = SPACES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'REGION CODE IS REQUIRED FOR LIST'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           INITIALIZE WS-LIST-OUTPUT
           MOVE 0 TO WS-LIST-IDX
           MOVE 0 TO WS-ROWS-FETCHED
      *
           EXEC SQL
               OPEN DEALER_LIST_CSR
           END-EXEC
      *
           IF SQLCODE NOT = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ERROR OPENING DEALER LIST CURSOR'
                   TO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
           PERFORM 6100-FETCH-DEALER
               UNTIL SQLCODE NOT = 0
               OR WS-LIST-IDX >= 15
      *
           EXEC SQL
               CLOSE DEALER_LIST_CSR
           END-EXEC
      *
           IF WS-ROWS-FETCHED = 0
               MOVE 'Y' TO WS-ERROR-FLAG
               STRING 'NO DEALERS FOUND FOR REGION: '
                      WS-IN-REGION
                   DELIMITED BY SIZE
                   INTO WS-ERROR-MSG
               GO TO 6000-EXIT
           END-IF
      *
      *    SEND LIST OUTPUT
      *
           MOVE 1200 TO WS-LST-LL
           MOVE 0 TO WS-LST-ZZ
           MOVE WS-MOD-DEALER-INQ TO WS-LST-MOD-NAME
           MOVE WS-IN-REGION TO WS-LST-REGION
           MOVE WS-ROWS-FETCHED TO WS-LST-COUNT
           STRING 'DISPLAYING ' WS-ROWS-FETCHED
                  ' DEALER(S) FOR REGION ' WS-IN-REGION
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
      * 6100 - FETCH NEXT DEALER ROW FROM CURSOR                      *
      *---------------------------------------------------------------*
       6100-FETCH-DEALER.
      *
           EXEC SQL
               FETCH DEALER_LIST_CSR
               INTO  :DCLDEALER.DEALER-CODE,
                     :DCLDEALER.DEALER-NAME,
                     :DCLDEALER.CITY,
                     :DCLDEALER.STATE-CODE,
                     :DCLDEALER.ACTIVE-FLAG
           END-EXEC
      *
           IF SQLCODE = 0
               ADD 1 TO WS-LIST-IDX
               ADD 1 TO WS-ROWS-FETCHED
               MOVE DEALER-CODE OF DCLDEALER
                   TO WS-LST-DLR-CODE(WS-LIST-IDX)
               MOVE DEALER-NAME-TX OF DCLDEALER
                   TO WS-LST-DLR-NAME(WS-LIST-IDX)
               MOVE CITY-TX OF DCLDEALER
                   TO WS-LST-DLR-CITY(WS-LIST-IDX)
               MOVE STATE-CODE OF DCLDEALER
                   TO WS-LST-DLR-ST(WS-LIST-IDX)
               MOVE ACTIVE-FLAG OF DCLDEALER
                   TO WS-LST-DLR-ACT(WS-LIST-IDX)
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
           MOVE 550 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE WS-MOD-DEALER-INQ TO WS-OUT-MOD-NAME
           MOVE WS-IN-FUNC-CODE TO WS-OUT-FUNC-CODE
           MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
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
           MOVE 'DEALER' TO WS-AUD-TABLE
           MOVE WS-IN-DEALER-CODE TO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           MOVE WS-IN-DEALER-NAME TO WS-AUD-NEW-VAL
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
      * END OF ADMDLR00                                              *
      ****************************************************************
