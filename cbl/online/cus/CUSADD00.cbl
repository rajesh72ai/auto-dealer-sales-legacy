       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSADD00.
      ****************************************************************
      * PROGRAM:  CUSADD00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - ADD / CREATE CUSTOMER PROFILE           *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CREATES A NEW CUSTOMER RECORD IN THE CUSTOMER      *
      *           TABLE. VALIDATES ALL REQUIRED FIELDS, STATE CODE,  *
      *           ZIP FORMAT, PHONE FORMAT, AND EMAIL FORMAT.         *
      *           CHECKS FOR POTENTIAL DUPLICATE (SAME LAST NAME +   *
      *           PHONE OR LAST NAME + ADDRESS). IF DUPLICATE FOUND  *
      *           SHOWS WARNING AND ALLOWS FORCE-ADD VIA FA FUNC.    *
      *           INSERTS INTO CUSTOMER TABLE WITH AUTO-GEN ID.      *
      *           ASSIGNS SALESPERSON VIA ROUND-ROBIN IF NOT GIVEN.  *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSAD - CUSTOMER ADD                                *
      * CALLS:    COMFMTL0 - FORMAT PHONE, NAME                     *
      *           COMLGEL0 - AUDIT LOGGING                           *
      *           COMDBEL0 - DB2 ERROR HANDLING                      *
      * TABLES:   AUTOSALE.CUSTOMER (INSERT)                         *
      *           AUTOSALE.SYSTEM_USER (SELECT FOR ROUND-ROBIN)      *
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
                                          VALUE 'CUSADD00'.
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
           COPY WSAUDIT.
      *
      *    DCLGEN COPIES
      *
           COPY DCLCUSTM.
      *
           COPY DCLSYUSR.
      *
      *    INPUT FIELDS
      *
       01  WS-ADD-INPUT.
           05  WS-AI-FUNCTION            PIC X(02).
               88  WS-AI-ADD                         VALUE 'AD'.
               88  WS-AI-FORCE-ADD                   VALUE 'FA'.
           05  WS-AI-DEALER-CODE         PIC X(05).
           05  WS-AI-FIRST-NAME          PIC X(30).
           05  WS-AI-LAST-NAME           PIC X(30).
           05  WS-AI-MIDDLE-INIT         PIC X(01).
           05  WS-AI-DOB                 PIC X(10).
           05  WS-AI-SSN-LAST4           PIC X(04).
           05  WS-AI-DL-NUMBER           PIC X(20).
           05  WS-AI-DL-STATE            PIC X(02).
           05  WS-AI-ADDRESS1            PIC X(50).
           05  WS-AI-ADDRESS2            PIC X(50).
           05  WS-AI-CITY                PIC X(30).
           05  WS-AI-STATE               PIC X(02).
           05  WS-AI-ZIP                 PIC X(10).
           05  WS-AI-HOME-PHONE          PIC X(10).
           05  WS-AI-CELL-PHONE          PIC X(10).
           05  WS-AI-EMAIL               PIC X(60).
           05  WS-AI-EMPLOYER            PIC X(40).
           05  WS-AI-INCOME              PIC X(11).
           05  WS-AI-CUST-TYPE           PIC X(01).
           05  WS-AI-SOURCE              PIC X(03).
           05  WS-AI-ASSIGNED-SALES      PIC X(08).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-ADD-OUTPUT.
           05  WS-AO-STATUS-LINE.
               10  WS-AO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-AO-MSG-TEXT       PIC X(70).
           05  WS-AO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-AO-HEADER.
               10  FILLER               PIC X(35)
                   VALUE '---- CUSTOMER ADD CONFIRMATION ----'.
               10  FILLER               PIC X(44) VALUE SPACES.
           05  WS-AO-ID-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'CUSTOMER ID: '.
               10  WS-AO-CUST-ID        PIC Z(08)9.
               10  FILLER               PIC X(57) VALUE SPACES.
           05  WS-AO-NAME-LINE.
               10  FILLER               PIC X(06) VALUE 'NAME: '.
               10  WS-AO-FULL-NAME      PIC X(62).
               10  FILLER               PIC X(11) VALUE SPACES.
           05  WS-AO-ADDR-LINE.
               10  FILLER               PIC X(09)
                   VALUE 'ADDRESS: '.
               10  WS-AO-ADDRESS1       PIC X(50).
               10  FILLER               PIC X(20) VALUE SPACES.
           05  WS-AO-CITY-LINE.
               10  FILLER               PIC X(09) VALUE SPACES.
               10  WS-AO-CITY           PIC X(30).
               10  FILLER               PIC X(02) VALUE ', '.
               10  WS-AO-STATE          PIC X(02).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  WS-AO-ZIP            PIC X(10).
               10  FILLER               PIC X(24) VALUE SPACES.
           05  WS-AO-PHONE-LINE.
               10  FILLER               PIC X(06) VALUE 'HOME: '.
               10  WS-AO-HOME-PHONE     PIC X(14).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'CELL: '.
               10  WS-AO-CELL-PHONE     PIC X(14).
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-AO-SALES-LINE.
               10  FILLER               PIC X(14)
                   VALUE 'SALESPERSON:  '.
               10  WS-AO-SALES-ID       PIC X(08).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TYPE: '.
               10  WS-AO-CUST-TYPE      PIC X(01).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'SOURCE: '.
               10  WS-AO-SOURCE         PIC X(03).
               10  FILLER               PIC X(31) VALUE SPACES.
           05  WS-AO-DUP-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- POTENTIAL DUPLICATE FOUND ----     '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-AO-DUP-LINE.
               10  FILLER               PIC X(04) VALUE 'ID: '.
               10  WS-AO-DUP-ID         PIC Z(08)9.
               10  FILLER               PIC X(02) VALUE SPACES.
               10  WS-AO-DUP-NAME       PIC X(40).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  WS-AO-DUP-PHONE      PIC X(14).
               10  FILLER               PIC X(07) VALUE SPACES.
           05  WS-AO-DUP-MSG.
               10  FILLER               PIC X(55)
                   VALUE 'USE FUNCTION FA TO FORCE ADD IF THIS IS
      -               ' NOT A DUPLICATE'.
               10  FILLER               PIC X(24) VALUE SPACES.
           05  WS-AO-FILLER             PIC X(400) VALUE SPACES.
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
      *    LOG CALL FIELDS
      *
       01  WS-LOG-REQUEST.
           05  WS-LOG-FUNCTION          PIC X(04).
           05  WS-LOG-PROGRAM           PIC X(08).
           05  WS-LOG-TABLE             PIC X(18).
           05  WS-LOG-ACTION            PIC X(03).
           05  WS-LOG-KEY               PIC X(40).
           05  WS-LOG-OLD-VAL           PIC X(200).
           05  WS-LOG-NEW-VAL           PIC X(200).
           05  WS-LOG-DESC              PIC X(80).
       01  WS-LOG-RESULT.
           05  WS-LOG-RC                PIC S9(04) COMP.
      *
      *    DB ERROR CALL FIELDS
      *
       01  WS-DBERR-REQUEST.
           05  WS-DBERR-FUNCTION        PIC X(04).
           05  WS-DBERR-PROGRAM         PIC X(08).
           05  WS-DBERR-SQLCODE         PIC S9(09) COMP.
           05  WS-DBERR-TABLE           PIC X(18).
           05  WS-DBERR-OPERATION       PIC X(10).
       01  WS-DBERR-RESULT.
           05  WS-DBERR-RC              PIC S9(04) COMP.
           05  WS-DBERR-MSG             PIC X(70).
      *
      *    WORKING FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-DUP-FOUND             PIC X(01)  VALUE 'N'.
               88  WS-IS-DUPLICATE                  VALUE 'Y'.
               88  WS-NOT-DUPLICATE                 VALUE 'N'.
           05  WS-INCOME-NUM            PIC S9(09)V9(2)  COMP-3
                                                     VALUE +0.
           05  WS-NEW-CUST-ID           PIC S9(09) COMP VALUE +0.
           05  WS-DUP-CUST-ID           PIC S9(09) COMP VALUE +0.
           05  WS-DUP-FIRST             PIC X(30)  VALUE SPACES.
           05  WS-DUP-LAST              PIC X(30)  VALUE SPACES.
           05  WS-DUP-PHONE             PIC X(10)  VALUE SPACES.
           05  WS-RR-SALES-ID           PIC X(08)  VALUE SPACES.
           05  WS-AT-SIGN-POS           PIC S9(04) COMP VALUE +0.
           05  WS-DOT-POS               PIC S9(04) COMP VALUE +0.
           05  WS-IDX                   PIC S9(04) COMP VALUE +0.
           05  WS-ZIP-DIGIT             PIC X(01)  VALUE SPACES.
      *
      *    STATE CODE VALIDATION TABLE
      *
       01  WS-STATE-TABLE.
           05  FILLER PIC X(100)
               VALUE 'ALAKAZABORACABORCOBORCTBORDEBORFLBORGABOR'
             & 'HIBORIDBORIDBORIDBORIDBORKSBORKYBOR'.
           05  FILLER PIC X(100)
               VALUE 'LABORMABORMDBORMEBORMIBORMNBORMSBORMOBOR'
             & 'MTBORNEBORNEBORNEVBORNHBORNJBORNMBOR'.
           05  FILLER PIC X(100)
               VALUE 'NYBORNYBORNDBORDABOROHBORORBORORBORBORBPA'
             & 'BORRIBORSYBORSDBORTNBORTXBORUTBOR'.
           05  FILLER PIC X(50)
               VALUE 'VTBORVABORWAYWBORWVBORWIBORDCBORPRBOR'.
       01  WS-VALID-STATES.
           05  FILLER PIC X(02) VALUE 'AL'.
           05  FILLER PIC X(02) VALUE 'AK'.
           05  FILLER PIC X(02) VALUE 'AZ'.
           05  FILLER PIC X(02) VALUE 'AR'.
           05  FILLER PIC X(02) VALUE 'CA'.
           05  FILLER PIC X(02) VALUE 'CO'.
           05  FILLER PIC X(02) VALUE 'CT'.
           05  FILLER PIC X(02) VALUE 'DE'.
           05  FILLER PIC X(02) VALUE 'FL'.
           05  FILLER PIC X(02) VALUE 'GA'.
           05  FILLER PIC X(02) VALUE 'HI'.
           05  FILLER PIC X(02) VALUE 'ID'.
           05  FILLER PIC X(02) VALUE 'IL'.
           05  FILLER PIC X(02) VALUE 'IN'.
           05  FILLER PIC X(02) VALUE 'IA'.
           05  FILLER PIC X(02) VALUE 'KS'.
           05  FILLER PIC X(02) VALUE 'KY'.
           05  FILLER PIC X(02) VALUE 'LA'.
           05  FILLER PIC X(02) VALUE 'ME'.
           05  FILLER PIC X(02) VALUE 'MD'.
           05  FILLER PIC X(02) VALUE 'MA'.
           05  FILLER PIC X(02) VALUE 'MI'.
           05  FILLER PIC X(02) VALUE 'MN'.
           05  FILLER PIC X(02) VALUE 'MS'.
           05  FILLER PIC X(02) VALUE 'MO'.
           05  FILLER PIC X(02) VALUE 'MT'.
           05  FILLER PIC X(02) VALUE 'NE'.
           05  FILLER PIC X(02) VALUE 'NV'.
           05  FILLER PIC X(02) VALUE 'NH'.
           05  FILLER PIC X(02) VALUE 'NJ'.
           05  FILLER PIC X(02) VALUE 'NM'.
           05  FILLER PIC X(02) VALUE 'NY'.
           05  FILLER PIC X(02) VALUE 'NC'.
           05  FILLER PIC X(02) VALUE 'ND'.
           05  FILLER PIC X(02) VALUE 'OH'.
           05  FILLER PIC X(02) VALUE 'OK'.
           05  FILLER PIC X(02) VALUE 'OR'.
           05  FILLER PIC X(02) VALUE 'PA'.
           05  FILLER PIC X(02) VALUE 'RI'.
           05  FILLER PIC X(02) VALUE 'SC'.
           05  FILLER PIC X(02) VALUE 'SD'.
           05  FILLER PIC X(02) VALUE 'TN'.
           05  FILLER PIC X(02) VALUE 'TX'.
           05  FILLER PIC X(02) VALUE 'UT'.
           05  FILLER PIC X(02) VALUE 'VT'.
           05  FILLER PIC X(02) VALUE 'VA'.
           05  FILLER PIC X(02) VALUE 'WA'.
           05  FILLER PIC X(02) VALUE 'WV'.
           05  FILLER PIC X(02) VALUE 'WI'.
           05  FILLER PIC X(02) VALUE 'WY'.
           05  FILLER PIC X(02) VALUE 'DC'.
           05  FILLER PIC X(02) VALUE 'PR'.
       01  WS-STATE-ARRAY REDEFINES WS-VALID-STATES.
           05  WS-STATE-ENTRY            PIC X(02)
                                          OCCURS 52 TIMES.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-MIDDLE-INIT        PIC S9(04) COMP VALUE +0.
           05  WS-NI-DOB                PIC S9(04) COMP VALUE +0.
           05  WS-NI-SSN-LAST4          PIC S9(04) COMP VALUE +0.
           05  WS-NI-DL                 PIC S9(04) COMP VALUE +0.
           05  WS-NI-DL-STATE           PIC S9(04) COMP VALUE +0.
           05  WS-NI-ADDR2              PIC S9(04) COMP VALUE +0.
           05  WS-NI-HOME-PHONE         PIC S9(04) COMP VALUE +0.
           05  WS-NI-CELL-PHONE         PIC S9(04) COMP VALUE +0.
           05  WS-NI-EMAIL              PIC S9(04) COMP VALUE +0.
           05  WS-NI-EMPLOYER           PIC S9(04) COMP VALUE +0.
           05  WS-NI-INCOME             PIC S9(04) COMP VALUE +0.
           05  WS-NI-SOURCE             PIC S9(04) COMP VALUE +0.
           05  WS-NI-ASSIGNED           PIC S9(04) COMP VALUE +0.
      *
      *    ROUND-ROBIN CURSOR FOR SALES ASSIGNMENT
      *
           EXEC SQL
               DECLARE CSR_ROUND_ROBIN CURSOR FOR
               SELECT USER_ID
               FROM   AUTOSALE.SYSTEM_USER
               WHERE  USER_TYPE    = 'S'
                 AND  ACTIVE_FLAG  = 'Y'
                 AND  LOCKED_FLAG  = 'N'
                 AND  DEALER_CODE  = :WS-AI-DEALER-CODE
               ORDER BY LAST_LOGIN_TS ASC
               FETCH FIRST 1 ROW ONLY
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
               IF WS-AI-ADD
                   PERFORM 4000-CHECK-DUPLICATE
               END-IF
           END-IF
      *
           IF WS-RETURN-CODE = +0
               AND WS-NOT-DUPLICATE
               PERFORM 5000-ASSIGN-SALESPERSON
           END-IF
      *
           IF WS-RETURN-CODE = +0
               AND WS-NOT-DUPLICATE
               PERFORM 6000-INSERT-CUSTOMER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               AND WS-NOT-DUPLICATE
               PERFORM 7000-FORMAT-OUTPUT
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
           INITIALIZE WS-ADD-OUTPUT
           MOVE 'CUSADD00' TO WS-AO-MSG-ID
           MOVE 'N' TO WS-DUP-FOUND
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
                   TO WS-AO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION         TO WS-AI-FUNCTION
               MOVE WS-INP-BODY(1:5)        TO WS-AI-DEALER-CODE
               MOVE WS-INP-BODY(6:30)       TO WS-AI-FIRST-NAME
               MOVE WS-INP-BODY(36:30)      TO WS-AI-LAST-NAME
               MOVE WS-INP-BODY(66:1)       TO WS-AI-MIDDLE-INIT
               MOVE WS-INP-BODY(67:10)      TO WS-AI-DOB
               MOVE WS-INP-BODY(77:4)       TO WS-AI-SSN-LAST4
               MOVE WS-INP-BODY(81:20)      TO WS-AI-DL-NUMBER
               MOVE WS-INP-BODY(101:2)      TO WS-AI-DL-STATE
               MOVE WS-INP-BODY(103:50)     TO WS-AI-ADDRESS1
               MOVE WS-INP-BODY(153:50)     TO WS-AI-ADDRESS2
               MOVE WS-INP-BODY(203:30)     TO WS-AI-CITY
               MOVE WS-INP-BODY(233:2)      TO WS-AI-STATE
               MOVE WS-INP-BODY(235:10)     TO WS-AI-ZIP
               MOVE WS-INP-BODY(245:10)     TO WS-AI-HOME-PHONE
               MOVE WS-INP-BODY(255:10)     TO WS-AI-CELL-PHONE
               MOVE WS-INP-BODY(265:60)     TO WS-AI-EMAIL
               MOVE WS-INP-BODY(325:40)     TO WS-AI-EMPLOYER
               MOVE WS-INP-BODY(365:11)     TO WS-AI-INCOME
               MOVE WS-INP-BODY(376:1)      TO WS-AI-CUST-TYPE
               MOVE WS-INP-BODY(377:3)      TO WS-AI-SOURCE
               MOVE WS-INP-BODY(380:8)      TO WS-AI-ASSIGNED-SALES
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
      *    VALIDATE FUNCTION CODE
      *
           IF NOT WS-AI-ADD AND NOT WS-AI-FORCE-ADD
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FUNCTION MUST BE AD (ADD) OR FA (FORCE ADD)'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE REQUIRED FIELDS
      *
           IF WS-AI-FIRST-NAME = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FIRST NAME IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-AI-LAST-NAME = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LAST NAME IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-AI-ADDRESS1 = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ADDRESS LINE 1 IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-AI-CITY = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CITY IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-AI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-AI-CUST-TYPE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER TYPE IS REQUIRED (R=RETAIL B=BIZ)'
                   TO WS-AO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE STATE CODE
      *
           PERFORM 3100-VALIDATE-STATE
      *
           IF WS-RETURN-CODE NOT = +0
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE ZIP FORMAT (5 DIGITS OR 5+4)
      *
           PERFORM 3200-VALIDATE-ZIP
      *
           IF WS-RETURN-CODE NOT = +0
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE PHONE FORMAT (10 DIGITS)
      *
           IF WS-AI-HOME-PHONE NOT = SPACES
               PERFORM 3300-VALIDATE-HOME-PHONE
               IF WS-RETURN-CODE NOT = +0
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-AI-CELL-PHONE NOT = SPACES
               PERFORM 3400-VALIDATE-CELL-PHONE
               IF WS-RETURN-CODE NOT = +0
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    VALIDATE EMAIL FORMAT (CONTAINS @ AND .)
      *
           IF WS-AI-EMAIL NOT = SPACES
               PERFORM 3500-VALIDATE-EMAIL
               IF WS-RETURN-CODE NOT = +0
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    CONVERT INCOME TO NUMERIC
      *
           IF WS-AI-INCOME NOT = SPACES
               COMPUTE WS-INCOME-NUM =
                   FUNCTION NUMVAL(WS-AI-INCOME)
           ELSE
               MOVE +0 TO WS-INCOME-NUM
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3100-VALIDATE-STATE                                       *
      ****************************************************************
       3100-VALIDATE-STATE.
      *
           IF WS-AI-STATE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'STATE CODE IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3100-EXIT
           END-IF
      *
           MOVE 'N' TO WS-DUP-FOUND
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 52
               IF WS-STATE-ENTRY(WS-IDX) = WS-AI-STATE
                   MOVE 'Y' TO WS-DUP-FOUND
                   EXIT PERFORM
               END-IF
           END-PERFORM
      *
           IF WS-DUP-FOUND = 'N'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INVALID STATE CODE' TO WS-AO-MSG-TEXT
           END-IF
      *
           MOVE 'N' TO WS-DUP-FOUND
           .
       3100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3200-VALIDATE-ZIP                                         *
      ****************************************************************
       3200-VALIDATE-ZIP.
      *
           IF WS-AI-ZIP = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ZIP CODE IS REQUIRED'
                   TO WS-AO-MSG-TEXT
               GO TO 3200-EXIT
           END-IF
      *
      *    CHECK FIRST 5 CHARS ARE DIGITS
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               MOVE WS-AI-ZIP(WS-IDX:1) TO WS-ZIP-DIGIT
               IF WS-ZIP-DIGIT NOT NUMERIC
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'ZIP CODE MUST BE 5 DIGITS (OR 5+4 FORMAT)'
                       TO WS-AO-MSG-TEXT
                   GO TO 3200-EXIT
               END-IF
           END-PERFORM
           .
       3200-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3300-VALIDATE-HOME-PHONE                                  *
      ****************************************************************
       3300-VALIDATE-HOME-PHONE.
      *
           IF WS-AI-HOME-PHONE NOT NUMERIC
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'HOME PHONE MUST BE 10 DIGITS (NO DASHES)'
                   TO WS-AO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    3400-VALIDATE-CELL-PHONE                                  *
      ****************************************************************
       3400-VALIDATE-CELL-PHONE.
      *
           IF WS-AI-CELL-PHONE NOT NUMERIC
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CELL PHONE MUST BE 10 DIGITS (NO DASHES)'
                   TO WS-AO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    3500-VALIDATE-EMAIL                                       *
      ****************************************************************
       3500-VALIDATE-EMAIL.
      *
           MOVE +0 TO WS-AT-SIGN-POS
           MOVE +0 TO WS-DOT-POS
      *
           INSPECT WS-AI-EMAIL TALLYING WS-AT-SIGN-POS
               FOR ALL '@'
      *
           IF WS-AT-SIGN-POS = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'EMAIL MUST CONTAIN @ SYMBOL'
                   TO WS-AO-MSG-TEXT
               GO TO 3500-EXIT
           END-IF
      *
           INSPECT WS-AI-EMAIL TALLYING WS-DOT-POS
               FOR ALL '.'
      *
           IF WS-DOT-POS = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'EMAIL MUST CONTAIN A PERIOD IN DOMAIN'
                   TO WS-AO-MSG-TEXT
           END-IF
           .
       3500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CHECK-DUPLICATE                                      *
      ****************************************************************
       4000-CHECK-DUPLICATE.
      *
      *    CHECK FOR SAME LAST NAME + HOME PHONE
      *
           IF WS-AI-HOME-PHONE NOT = SPACES
               EXEC SQL
                   SELECT CUSTOMER_ID
                        , FIRST_NAME
                        , LAST_NAME
                        , HOME_PHONE
                   INTO  :WS-DUP-CUST-ID
                       , :WS-DUP-FIRST
                       , :WS-DUP-LAST
                       , :WS-DUP-PHONE
                   FROM   AUTOSALE.CUSTOMER
                   WHERE  LAST_NAME = :WS-AI-LAST-NAME
                     AND  HOME_PHONE = :WS-AI-HOME-PHONE
                   FETCH FIRST 1 ROW ONLY
               END-EXEC
      *
               IF SQLCODE = +0
                   MOVE 'Y' TO WS-DUP-FOUND
                   PERFORM 4500-SHOW-DUPLICATE
                   GO TO 4000-EXIT
               END-IF
           END-IF
      *
      *    CHECK FOR SAME LAST NAME + ADDRESS
      *
           EXEC SQL
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
               INTO  :WS-DUP-CUST-ID
                   , :WS-DUP-FIRST
                   , :WS-DUP-LAST
                   , :WS-DUP-PHONE
                        :WS-NI-HOME-PHONE
               FROM   AUTOSALE.CUSTOMER
               WHERE  LAST_NAME = :WS-AI-LAST-NAME
                 AND  ADDRESS_LINE1 = :WS-AI-ADDRESS1
                 AND  ZIP_CODE = :WS-AI-ZIP
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE 'Y' TO WS-DUP-FOUND
               PERFORM 4500-SHOW-DUPLICATE
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-SHOW-DUPLICATE - FORMAT DUPLICATE WARNING OUTPUT     *
      ****************************************************************
       4500-SHOW-DUPLICATE.
      *
           MOVE WS-DUP-CUST-ID TO WS-AO-DUP-ID
           STRING WS-DUP-LAST DELIMITED BY '  '
                  ', '         DELIMITED BY SIZE
                  WS-DUP-FIRST DELIMITED BY '  '
               INTO WS-AO-DUP-NAME
           END-STRING
      *
      *    FORMAT DUPLICATE PHONE FOR DISPLAY
      *
           IF WS-DUP-PHONE NOT = SPACES
               MOVE 'FPHN' TO WS-FMT-FUNCTION
               MOVE WS-DUP-PHONE TO WS-FMT-INPUT
               CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                      WS-FMT-RESULT
               MOVE WS-FMT-OUTPUT(1:14) TO WS-AO-DUP-PHONE
           ELSE
               MOVE 'N/A' TO WS-AO-DUP-PHONE
           END-IF
      *
           MOVE 'POTENTIAL DUPLICATE FOUND - SEE BELOW'
               TO WS-AO-MSG-TEXT
           .
      *
      ****************************************************************
      *    5000-ASSIGN-SALESPERSON (ROUND-ROBIN IF NOT PROVIDED)     *
      ****************************************************************
       5000-ASSIGN-SALESPERSON.
      *
           IF WS-AI-ASSIGNED-SALES NOT = SPACES
               GO TO 5000-EXIT
           END-IF
      *
           EXEC SQL
               OPEN CSR_ROUND_ROBIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SPACES TO WS-AI-ASSIGNED-SALES
               GO TO 5000-EXIT
           END-IF
      *
           EXEC SQL
               FETCH CSR_ROUND_ROBIN
               INTO  :WS-RR-SALES-ID
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE WS-RR-SALES-ID TO WS-AI-ASSIGNED-SALES
           ELSE
               MOVE SPACES TO WS-AI-ASSIGNED-SALES
           END-IF
      *
           EXEC SQL
               CLOSE CSR_ROUND_ROBIN
           END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-INSERT-CUSTOMER                                      *
      ****************************************************************
       6000-INSERT-CUSTOMER.
      *
      *    SET NULL INDICATORS FOR OPTIONAL FIELDS
      *
           IF WS-AI-MIDDLE-INIT = SPACES
               MOVE -1 TO WS-NI-MIDDLE-INIT
           ELSE
               MOVE +0 TO WS-NI-MIDDLE-INIT
           END-IF
      *
           IF WS-AI-DOB = SPACES
               MOVE -1 TO WS-NI-DOB
           ELSE
               MOVE +0 TO WS-NI-DOB
           END-IF
      *
           IF WS-AI-SSN-LAST4 = SPACES
               MOVE -1 TO WS-NI-SSN-LAST4
           ELSE
               MOVE +0 TO WS-NI-SSN-LAST4
           END-IF
      *
           IF WS-AI-DL-NUMBER = SPACES
               MOVE -1 TO WS-NI-DL
           ELSE
               MOVE +0 TO WS-NI-DL
           END-IF
      *
           IF WS-AI-DL-STATE = SPACES
               MOVE -1 TO WS-NI-DL-STATE
           ELSE
               MOVE +0 TO WS-NI-DL-STATE
           END-IF
      *
           IF WS-AI-ADDRESS2 = SPACES
               MOVE -1 TO WS-NI-ADDR2
           ELSE
               MOVE +0 TO WS-NI-ADDR2
           END-IF
      *
           IF WS-AI-HOME-PHONE = SPACES
               MOVE -1 TO WS-NI-HOME-PHONE
           ELSE
               MOVE +0 TO WS-NI-HOME-PHONE
           END-IF
      *
           IF WS-AI-CELL-PHONE = SPACES
               MOVE -1 TO WS-NI-CELL-PHONE
           ELSE
               MOVE +0 TO WS-NI-CELL-PHONE
           END-IF
      *
           IF WS-AI-EMAIL = SPACES
               MOVE -1 TO WS-NI-EMAIL
           ELSE
               MOVE +0 TO WS-NI-EMAIL
           END-IF
      *
           IF WS-AI-EMPLOYER = SPACES
               MOVE -1 TO WS-NI-EMPLOYER
           ELSE
               MOVE +0 TO WS-NI-EMPLOYER
           END-IF
      *
           IF WS-INCOME-NUM = +0
               MOVE -1 TO WS-NI-INCOME
           ELSE
               MOVE +0 TO WS-NI-INCOME
           END-IF
      *
           IF WS-AI-SOURCE = SPACES
               MOVE -1 TO WS-NI-SOURCE
           ELSE
               MOVE +0 TO WS-NI-SOURCE
           END-IF
      *
           IF WS-AI-ASSIGNED-SALES = SPACES
               MOVE -1 TO WS-NI-ASSIGNED
           ELSE
               MOVE +0 TO WS-NI-ASSIGNED
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.CUSTOMER
               ( FIRST_NAME
               , LAST_NAME
               , MIDDLE_INIT
               , DATE_OF_BIRTH
               , SSN_LAST4
               , DRIVERS_LICENSE
               , DL_STATE
               , ADDRESS_LINE1
               , ADDRESS_LINE2
               , CITY
               , STATE_CODE
               , ZIP_CODE
               , HOME_PHONE
               , CELL_PHONE
               , EMAIL
               , EMPLOYER_NAME
               , ANNUAL_INCOME
               , CUSTOMER_TYPE
               , SOURCE_CODE
               , DEALER_CODE
               , ASSIGNED_SALES
               , CREATED_TS
               , UPDATED_TS
               )
               VALUES
               ( :WS-AI-FIRST-NAME
               , :WS-AI-LAST-NAME
               , :WS-AI-MIDDLE-INIT     :WS-NI-MIDDLE-INIT
               , :WS-AI-DOB             :WS-NI-DOB
               , :WS-AI-SSN-LAST4       :WS-NI-SSN-LAST4
               , :WS-AI-DL-NUMBER       :WS-NI-DL
               , :WS-AI-DL-STATE        :WS-NI-DL-STATE
               , :WS-AI-ADDRESS1
               , :WS-AI-ADDRESS2        :WS-NI-ADDR2
               , :WS-AI-CITY
               , :WS-AI-STATE
               , :WS-AI-ZIP
               , :WS-AI-HOME-PHONE      :WS-NI-HOME-PHONE
               , :WS-AI-CELL-PHONE      :WS-NI-CELL-PHONE
               , :WS-AI-EMAIL           :WS-NI-EMAIL
               , :WS-AI-EMPLOYER        :WS-NI-EMPLOYER
               , :WS-INCOME-NUM         :WS-NI-INCOME
               , :WS-AI-CUST-TYPE
               , :WS-AI-SOURCE          :WS-NI-SOURCE
               , :WS-AI-DEALER-CODE
               , :WS-AI-ASSIGNED-SALES  :WS-NI-ASSIGNED
               , CURRENT TIMESTAMP
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSADD00'          TO WS-DBERR-PROGRAM
               MOVE 'CUSTOMER'          TO WS-DBERR-TABLE
               MOVE 'INSERT'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-AO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    GET AUTO-GENERATED CUSTOMER ID
      *
           EXEC SQL
               SELECT IDENTITY_VAL_LOCAL()
               INTO   :WS-NEW-CUST-ID
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    AUDIT LOG THE INSERT
      *
           MOVE 'LOGW' TO WS-LOG-FUNCTION
           MOVE 'CUSADD00'   TO WS-LOG-PROGRAM
           MOVE 'CUSTOMER'   TO WS-LOG-TABLE
           MOVE 'INS'        TO WS-LOG-ACTION
           MOVE WS-NEW-CUST-ID TO WS-LOG-KEY
           MOVE SPACES          TO WS-LOG-OLD-VAL
           STRING WS-AI-LAST-NAME DELIMITED BY '  '
                  ', '             DELIMITED BY SIZE
                  WS-AI-FIRST-NAME DELIMITED BY '  '
               INTO WS-LOG-NEW-VAL
           END-STRING
           MOVE 'CUSTOMER PROFILE CREATED' TO WS-LOG-DESC
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
                                  WS-LOG-RESULT
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-FORMAT-OUTPUT                                        *
      ****************************************************************
       7000-FORMAT-OUTPUT.
      *
           MOVE WS-NEW-CUST-ID TO WS-AO-CUST-ID
      *
           STRING WS-AI-LAST-NAME DELIMITED BY '  '
                  ', '             DELIMITED BY SIZE
                  WS-AI-FIRST-NAME DELIMITED BY '  '
                  ' '              DELIMITED BY SIZE
                  WS-AI-MIDDLE-INIT DELIMITED BY SIZE
               INTO WS-AO-FULL-NAME
           END-STRING
      *
           MOVE WS-AI-ADDRESS1    TO WS-AO-ADDRESS1
           MOVE WS-AI-CITY        TO WS-AO-CITY
           MOVE WS-AI-STATE       TO WS-AO-STATE
           MOVE WS-AI-ZIP         TO WS-AO-ZIP
      *
      *    FORMAT PHONES FOR DISPLAY
      *
           IF WS-AI-HOME-PHONE NOT = SPACES
               MOVE 'FPHN' TO WS-FMT-FUNCTION
               MOVE WS-AI-HOME-PHONE TO WS-FMT-INPUT
               CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                      WS-FMT-RESULT
               MOVE WS-FMT-OUTPUT(1:14) TO WS-AO-HOME-PHONE
           END-IF
      *
           IF WS-AI-CELL-PHONE NOT = SPACES
               MOVE 'FPHN' TO WS-FMT-FUNCTION
               MOVE WS-AI-CELL-PHONE TO WS-FMT-INPUT
               CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                      WS-FMT-RESULT
               MOVE WS-FMT-OUTPUT(1:14) TO WS-AO-CELL-PHONE
           END-IF
      *
           MOVE WS-AI-ASSIGNED-SALES TO WS-AO-SALES-ID
           MOVE WS-AI-CUST-TYPE      TO WS-AO-CUST-TYPE
           MOVE WS-AI-SOURCE         TO WS-AO-SOURCE
      *
           MOVE 'CUSTOMER ADDED SUCCESSFULLY'
               TO WS-AO-MSG-TEXT
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-ADD-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'CSAD' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSADD00                                              *
      ****************************************************************
