       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSUPD00.
      ****************************************************************
      * PROGRAM:  CUSUPD00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - UPDATE CUSTOMER PROFILE                 *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  UPDATES AN EXISTING CUSTOMER RECORD. FETCHES THE   *
      *           CURRENT RECORD, COMPARES FIELD BY FIELD, AND       *
      *           APPLIES ONLY CHANGED FIELDS. VALIDATES ALL INPUT   *
      *           (STATE CODE, ZIP, PHONE, EMAIL). LOGS OLD/NEW      *
      *           VALUES VIA AUDIT.                                   *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSUP - CUSTOMER UPDATE                             *
      * CALLS:    COMFMTL0 - FORMAT PHONE                           *
      *           COMLGEL0 - AUDIT LOGGING (OLD/NEW VALUES)          *
      *           COMDBEL0 - DB2 ERROR HANDLING                      *
      * TABLES:   AUTOSALE.CUSTOMER (SELECT, UPDATE)                 *
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
                                          VALUE 'CUSUPD00'.
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
      *    INPUT FIELDS
      *
       01  WS-UPD-INPUT.
           05  WS-UI-FUNCTION            PIC X(02).
               88  WS-UI-UPDATE                      VALUE 'UP'.
           05  WS-UI-CUST-ID             PIC X(09).
           05  WS-UI-FIRST-NAME          PIC X(30).
           05  WS-UI-LAST-NAME           PIC X(30).
           05  WS-UI-MIDDLE-INIT         PIC X(01).
           05  WS-UI-DOB                 PIC X(10).
           05  WS-UI-SSN-LAST4           PIC X(04).
           05  WS-UI-DL-NUMBER           PIC X(20).
           05  WS-UI-DL-STATE            PIC X(02).
           05  WS-UI-ADDRESS1            PIC X(50).
           05  WS-UI-ADDRESS2            PIC X(50).
           05  WS-UI-CITY                PIC X(30).
           05  WS-UI-STATE               PIC X(02).
           05  WS-UI-ZIP                 PIC X(10).
           05  WS-UI-HOME-PHONE          PIC X(10).
           05  WS-UI-CELL-PHONE          PIC X(10).
           05  WS-UI-EMAIL               PIC X(60).
           05  WS-UI-EMPLOYER            PIC X(40).
           05  WS-UI-INCOME              PIC X(11).
           05  WS-UI-CUST-TYPE           PIC X(01).
           05  WS-UI-SOURCE              PIC X(03).
           05  WS-UI-ASSIGNED-SALES      PIC X(08).
      *
      *    SAVED OLD VALUES FOR AUDIT
      *
       01  WS-OLD-RECORD.
           05  WS-OLD-FIRST-NAME         PIC X(30).
           05  WS-OLD-LAST-NAME          PIC X(30).
           05  WS-OLD-ADDRESS1           PIC X(50).
           05  WS-OLD-CITY               PIC X(30).
           05  WS-OLD-STATE              PIC X(02).
           05  WS-OLD-ZIP                PIC X(10).
           05  WS-OLD-HOME-PHONE         PIC X(10).
           05  WS-OLD-CELL-PHONE         PIC X(10).
           05  WS-OLD-EMAIL              PIC X(60).
           05  WS-OLD-EMPLOYER           PIC X(40).
           05  WS-OLD-INCOME             PIC S9(09)V9(2) COMP-3.
           05  WS-OLD-CUST-TYPE          PIC X(01).
           05  WS-OLD-SOURCE             PIC X(03).
           05  WS-OLD-ASSIGNED           PIC X(08).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-UPD-OUTPUT.
           05  WS-UO-STATUS-LINE.
               10  WS-UO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-UO-MSG-TEXT       PIC X(70).
           05  WS-UO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-UO-HEADER.
               10  FILLER               PIC X(38)
                   VALUE '---- CUSTOMER UPDATE CONFIRMATION ----'.
               10  FILLER               PIC X(41) VALUE SPACES.
           05  WS-UO-ID-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'CUSTOMER ID: '.
               10  WS-UO-CUST-ID        PIC Z(08)9.
               10  FILLER               PIC X(57) VALUE SPACES.
           05  WS-UO-NAME-LINE.
               10  FILLER               PIC X(06) VALUE 'NAME: '.
               10  WS-UO-FULL-NAME      PIC X(62).
               10  FILLER               PIC X(11) VALUE SPACES.
           05  WS-UO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-UO-CHG-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- CHANGES APPLIED ----     '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-UO-CHG-COL-HDR.
               10  FILLER               PIC X(16) VALUE
                   'FIELD           '.
               10  FILLER               PIC X(30) VALUE
                   'OLD VALUE                     '.
               10  FILLER               PIC X(30) VALUE
                   'NEW VALUE                     '.
               10  FILLER               PIC X(03) VALUE SPACES.
           05  WS-UO-CHG-LINES.
               10  WS-UO-CHG-LINE       OCCURS 10 TIMES.
                   15  WS-UO-CL-FIELD   PIC X(15).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-UO-CL-OLD     PIC X(30).
                   15  WS-UO-CL-NEW     PIC X(30).
                   15  FILLER            PIC X(03) VALUE SPACES.
           05  WS-UO-BLANK-3            PIC X(79) VALUE SPACES.
           05  WS-UO-COUNT-LINE.
               10  FILLER               PIC X(18) VALUE
                   'FIELDS CHANGED:   '.
               10  WS-UO-CHG-COUNT      PIC Z9.
               10  FILLER               PIC X(59) VALUE SPACES.
           05  WS-UO-FILLER             PIC X(200) VALUE SPACES.
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
           05  WS-CUST-ID-NUM           PIC S9(09) COMP VALUE +0.
           05  WS-CHANGE-COUNT          PIC S9(04) COMP VALUE +0.
           05  WS-CHG-IDX               PIC S9(04) COMP VALUE +0.
           05  WS-INCOME-NUM            PIC S9(09)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-IDX                   PIC S9(04) COMP VALUE +0.
           05  WS-AT-SIGN-CNT           PIC S9(04) COMP VALUE +0.
           05  WS-DOT-CNT               PIC S9(04) COMP VALUE +0.
           05  WS-ZIP-DIGIT             PIC X(01)  VALUE SPACES.
      *
      *    STATE VALIDATION TABLE
      *
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
               PERFORM 4000-FETCH-CURRENT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-COMPARE-AND-UPDATE
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-AUDIT-LOG
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
           INITIALIZE WS-UPD-OUTPUT
           MOVE 'CUSUPD00' TO WS-UO-MSG-ID
           MOVE +0 TO WS-CHANGE-COUNT
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
                   TO WS-UO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION         TO WS-UI-FUNCTION
               MOVE WS-INP-KEY-DATA(1:9)    TO WS-UI-CUST-ID
               MOVE WS-INP-BODY(1:30)       TO WS-UI-FIRST-NAME
               MOVE WS-INP-BODY(31:30)      TO WS-UI-LAST-NAME
               MOVE WS-INP-BODY(61:1)       TO WS-UI-MIDDLE-INIT
               MOVE WS-INP-BODY(62:10)      TO WS-UI-DOB
               MOVE WS-INP-BODY(72:4)       TO WS-UI-SSN-LAST4
               MOVE WS-INP-BODY(76:20)      TO WS-UI-DL-NUMBER
               MOVE WS-INP-BODY(96:2)       TO WS-UI-DL-STATE
               MOVE WS-INP-BODY(98:50)      TO WS-UI-ADDRESS1
               MOVE WS-INP-BODY(148:50)     TO WS-UI-ADDRESS2
               MOVE WS-INP-BODY(198:30)     TO WS-UI-CITY
               MOVE WS-INP-BODY(228:2)      TO WS-UI-STATE
               MOVE WS-INP-BODY(230:10)     TO WS-UI-ZIP
               MOVE WS-INP-BODY(240:10)     TO WS-UI-HOME-PHONE
               MOVE WS-INP-BODY(250:10)     TO WS-UI-CELL-PHONE
               MOVE WS-INP-BODY(260:60)     TO WS-UI-EMAIL
               MOVE WS-INP-BODY(320:40)     TO WS-UI-EMPLOYER
               MOVE WS-INP-BODY(360:11)     TO WS-UI-INCOME
               MOVE WS-INP-BODY(371:1)      TO WS-UI-CUST-TYPE
               MOVE WS-INP-BODY(372:3)      TO WS-UI-SOURCE
               MOVE WS-INP-BODY(375:8)      TO WS-UI-ASSIGNED-SALES
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF NOT WS-UI-UPDATE
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FUNCTION MUST BE UP (UPDATE)'
                   TO WS-UO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-UI-CUST-ID = SPACES OR ZEROS
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER ID IS REQUIRED FOR UPDATE'
                   TO WS-UO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           COMPUTE WS-CUST-ID-NUM =
               FUNCTION NUMVAL(WS-UI-CUST-ID)
      *
      *    VALIDATE STATE IF PROVIDED
      *
           IF WS-UI-STATE NOT = SPACES
               PERFORM 3100-VALIDATE-STATE
               IF WS-RETURN-CODE NOT = +0
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    VALIDATE ZIP IF PROVIDED
      *
           IF WS-UI-ZIP NOT = SPACES
               PERFORM 3200-VALIDATE-ZIP
               IF WS-RETURN-CODE NOT = +0
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    VALIDATE PHONE IF PROVIDED
      *
           IF WS-UI-HOME-PHONE NOT = SPACES
               IF WS-UI-HOME-PHONE NOT NUMERIC
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'HOME PHONE MUST BE 10 DIGITS'
                       TO WS-UO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-UI-CELL-PHONE NOT = SPACES
               IF WS-UI-CELL-PHONE NOT NUMERIC
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'CELL PHONE MUST BE 10 DIGITS'
                       TO WS-UO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    VALIDATE EMAIL IF PROVIDED
      *
           IF WS-UI-EMAIL NOT = SPACES
               MOVE +0 TO WS-AT-SIGN-CNT
               INSPECT WS-UI-EMAIL TALLYING WS-AT-SIGN-CNT
                   FOR ALL '@'
               IF WS-AT-SIGN-CNT = +0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'EMAIL MUST CONTAIN @ SYMBOL'
                       TO WS-UO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
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
           MOVE 'N' TO WS-ZIP-DIGIT
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 52
               IF WS-STATE-ENTRY(WS-IDX) = WS-UI-STATE
                   MOVE 'Y' TO WS-ZIP-DIGIT
                   EXIT PERFORM
               END-IF
           END-PERFORM
      *
           IF WS-ZIP-DIGIT = 'N'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INVALID STATE CODE' TO WS-UO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    3200-VALIDATE-ZIP                                         *
      ****************************************************************
       3200-VALIDATE-ZIP.
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > 5
               MOVE WS-UI-ZIP(WS-IDX:1) TO WS-ZIP-DIGIT
               IF WS-ZIP-DIGIT NOT NUMERIC
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'ZIP CODE MUST BE 5 DIGITS'
                       TO WS-UO-MSG-TEXT
                   EXIT PERFORM
               END-IF
           END-PERFORM
           .
      *
      ****************************************************************
      *    4000-FETCH-CURRENT - GET EXISTING CUSTOMER RECORD         *
      ****************************************************************
       4000-FETCH-CURRENT.
      *
           EXEC SQL
               SELECT FIRST_NAME
                    , LAST_NAME
                    , ADDRESS_LINE1
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
                    , ASSIGNED_SALES
               INTO  :WS-OLD-FIRST-NAME
                   , :WS-OLD-LAST-NAME
                   , :WS-OLD-ADDRESS1
                   , :WS-OLD-CITY
                   , :WS-OLD-STATE
                   , :WS-OLD-ZIP
                   , :WS-OLD-HOME-PHONE
                              :WS-NI-HOME-PHONE
                   , :WS-OLD-CELL-PHONE
                              :WS-NI-CELL-PHONE
                   , :WS-OLD-EMAIL
                              :WS-NI-EMAIL
                   , :WS-OLD-EMPLOYER
                              :WS-NI-EMPLOYER
                   , :WS-OLD-INCOME
                              :WS-NI-INCOME
                   , :WS-OLD-CUST-TYPE
                   , :WS-OLD-SOURCE
                              :WS-NI-SOURCE
                   , :WS-OLD-ASSIGNED
                              :WS-NI-ASSIGNED
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-UO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSUPD00'          TO WS-DBERR-PROGRAM
               MOVE 'CUSTOMER'          TO WS-DBERR-TABLE
               MOVE 'SELECT'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-UO-MSG-TEXT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-COMPARE-AND-UPDATE - SELECTIVE FIELD UPDATE           *
      ****************************************************************
       5000-COMPARE-AND-UPDATE.
      *
           MOVE +0 TO WS-CHANGE-COUNT
           MOVE +0 TO WS-CHG-IDX
      *
      *    COMPARE EACH FIELD - ONLY UPDATE IF CHANGED
      *
           IF WS-UI-FIRST-NAME NOT = SPACES
               AND WS-UI-FIRST-NAME NOT = WS-OLD-FIRST-NAME
               ADD +1 TO WS-CHG-IDX
               IF WS-CHG-IDX <= 10
                   MOVE 'FIRST NAME'     TO
                       WS-UO-CL-FIELD(WS-CHG-IDX)
                   MOVE WS-OLD-FIRST-NAME TO
                       WS-UO-CL-OLD(WS-CHG-IDX)
                   MOVE WS-UI-FIRST-NAME  TO
                       WS-UO-CL-NEW(WS-CHG-IDX)
               END-IF
               ADD +1 TO WS-CHANGE-COUNT
           END-IF
      *
           IF WS-UI-LAST-NAME NOT = SPACES
               AND WS-UI-LAST-NAME NOT = WS-OLD-LAST-NAME
               ADD +1 TO WS-CHG-IDX
               IF WS-CHG-IDX <= 10
                   MOVE 'LAST NAME'      TO
                       WS-UO-CL-FIELD(WS-CHG-IDX)
                   MOVE WS-OLD-LAST-NAME  TO
                       WS-UO-CL-OLD(WS-CHG-IDX)
                   MOVE WS-UI-LAST-NAME   TO
                       WS-UO-CL-NEW(WS-CHG-IDX)
               END-IF
               ADD +1 TO WS-CHANGE-COUNT
           END-IF
      *
           IF WS-UI-ADDRESS1 NOT = SPACES
               AND WS-UI-ADDRESS1 NOT = WS-OLD-ADDRESS1
               ADD +1 TO WS-CHG-IDX
               IF WS-CHG-IDX <= 10
                   MOVE 'ADDRESS'        TO
                       WS-UO-CL-FIELD(WS-CHG-IDX)
                   MOVE WS-OLD-ADDRESS1   TO
                       WS-UO-CL-OLD(WS-CHG-IDX)
                   MOVE WS-UI-ADDRESS1    TO
                       WS-UO-CL-NEW(WS-CHG-IDX)
               END-IF
               ADD +1 TO WS-CHANGE-COUNT
           END-IF
      *
           IF WS-UI-STATE NOT = SPACES
               AND WS-UI-STATE NOT = WS-OLD-STATE
               ADD +1 TO WS-CHG-IDX
               IF WS-CHG-IDX <= 10
                   MOVE 'STATE'          TO
                       WS-UO-CL-FIELD(WS-CHG-IDX)
                   MOVE WS-OLD-STATE      TO
                       WS-UO-CL-OLD(WS-CHG-IDX)
                   MOVE WS-UI-STATE       TO
                       WS-UO-CL-NEW(WS-CHG-IDX)
               END-IF
               ADD +1 TO WS-CHANGE-COUNT
           END-IF
      *
           IF WS-UI-HOME-PHONE NOT = SPACES
               AND WS-UI-HOME-PHONE NOT = WS-OLD-HOME-PHONE
               ADD +1 TO WS-CHG-IDX
               IF WS-CHG-IDX <= 10
                   MOVE 'HOME PHONE'     TO
                       WS-UO-CL-FIELD(WS-CHG-IDX)
                   MOVE WS-OLD-HOME-PHONE TO
                       WS-UO-CL-OLD(WS-CHG-IDX)
                   MOVE WS-UI-HOME-PHONE  TO
                       WS-UO-CL-NEW(WS-CHG-IDX)
               END-IF
               ADD +1 TO WS-CHANGE-COUNT
           END-IF
      *
           IF WS-UI-CUST-TYPE NOT = SPACES
               AND WS-UI-CUST-TYPE NOT = WS-OLD-CUST-TYPE
               ADD +1 TO WS-CHG-IDX
               IF WS-CHG-IDX <= 10
                   MOVE 'CUST TYPE'      TO
                       WS-UO-CL-FIELD(WS-CHG-IDX)
                   MOVE WS-OLD-CUST-TYPE  TO
                       WS-UO-CL-OLD(WS-CHG-IDX)
                   MOVE WS-UI-CUST-TYPE   TO
                       WS-UO-CL-NEW(WS-CHG-IDX)
               END-IF
               ADD +1 TO WS-CHANGE-COUNT
           END-IF
      *
           IF WS-CHANGE-COUNT = +0
               MOVE 'NO CHANGES DETECTED' TO WS-UO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    APPLY THE UPDATE
      *
           EXEC SQL
               UPDATE AUTOSALE.CUSTOMER
               SET    FIRST_NAME = CASE
                          WHEN :WS-UI-FIRST-NAME <> ' '
                          THEN :WS-UI-FIRST-NAME
                          ELSE FIRST_NAME END
                    , LAST_NAME = CASE
                          WHEN :WS-UI-LAST-NAME <> ' '
                          THEN :WS-UI-LAST-NAME
                          ELSE LAST_NAME END
                    , ADDRESS_LINE1 = CASE
                          WHEN :WS-UI-ADDRESS1 <> ' '
                          THEN :WS-UI-ADDRESS1
                          ELSE ADDRESS_LINE1 END
                    , CITY = CASE
                          WHEN :WS-UI-CITY <> ' '
                          THEN :WS-UI-CITY
                          ELSE CITY END
                    , STATE_CODE = CASE
                          WHEN :WS-UI-STATE <> ' '
                          THEN :WS-UI-STATE
                          ELSE STATE_CODE END
                    , ZIP_CODE = CASE
                          WHEN :WS-UI-ZIP <> ' '
                          THEN :WS-UI-ZIP
                          ELSE ZIP_CODE END
                    , HOME_PHONE = CASE
                          WHEN :WS-UI-HOME-PHONE <> ' '
                          THEN :WS-UI-HOME-PHONE
                          ELSE HOME_PHONE END
                    , CELL_PHONE = CASE
                          WHEN :WS-UI-CELL-PHONE <> ' '
                          THEN :WS-UI-CELL-PHONE
                          ELSE CELL_PHONE END
                    , EMAIL = CASE
                          WHEN :WS-UI-EMAIL <> ' '
                          THEN :WS-UI-EMAIL
                          ELSE EMAIL END
                    , EMPLOYER_NAME = CASE
                          WHEN :WS-UI-EMPLOYER <> ' '
                          THEN :WS-UI-EMPLOYER
                          ELSE EMPLOYER_NAME END
                    , CUSTOMER_TYPE = CASE
                          WHEN :WS-UI-CUST-TYPE <> ' '
                          THEN :WS-UI-CUST-TYPE
                          ELSE CUSTOMER_TYPE END
                    , SOURCE_CODE = CASE
                          WHEN :WS-UI-SOURCE <> ' '
                          THEN :WS-UI-SOURCE
                          ELSE SOURCE_CODE END
                    , ASSIGNED_SALES = CASE
                          WHEN :WS-UI-ASSIGNED-SALES <> ' '
                          THEN :WS-UI-ASSIGNED-SALES
                          ELSE ASSIGNED_SALES END
                    , UPDATED_TS = CURRENT TIMESTAMP
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSUPD00'          TO WS-DBERR-PROGRAM
               MOVE 'CUSTOMER'          TO WS-DBERR-TABLE
               MOVE 'UPDATE'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-UO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    FORMAT SUCCESS OUTPUT
      *
           MOVE WS-CUST-ID-NUM TO WS-UO-CUST-ID
           STRING WS-UI-LAST-NAME DELIMITED BY '  '
                  ', '             DELIMITED BY SIZE
                  WS-UI-FIRST-NAME DELIMITED BY '  '
               INTO WS-UO-FULL-NAME
           END-STRING
           MOVE WS-CHG-IDX TO WS-UO-CHG-COUNT
      *
           MOVE 'CUSTOMER UPDATED SUCCESSFULLY'
               TO WS-UO-MSG-TEXT
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-AUDIT-LOG                                            *
      ****************************************************************
       6000-AUDIT-LOG.
      *
           MOVE 'LOGW'      TO WS-LOG-FUNCTION
           MOVE 'CUSUPD00'  TO WS-LOG-PROGRAM
           MOVE 'CUSTOMER'  TO WS-LOG-TABLE
           MOVE 'UPD'       TO WS-LOG-ACTION
           MOVE WS-CUST-ID-NUM TO WS-LOG-KEY
      *
           STRING WS-OLD-LAST-NAME DELIMITED BY '  '
                  ', '              DELIMITED BY SIZE
                  WS-OLD-FIRST-NAME DELIMITED BY '  '
               INTO WS-LOG-OLD-VAL
           END-STRING
      *
           STRING WS-UI-LAST-NAME DELIMITED BY '  '
                  ', '             DELIMITED BY SIZE
                  WS-UI-FIRST-NAME DELIMITED BY '  '
               INTO WS-LOG-NEW-VAL
           END-STRING
      *
           STRING 'CUSTOMER UPDATE - '  DELIMITED BY SIZE
                  WS-UO-CHG-COUNT       DELIMITED BY SIZE
                  ' FIELDS CHANGED'     DELIMITED BY SIZE
               INTO WS-LOG-DESC
           END-STRING
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
                                  WS-LOG-RESULT
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-UPD-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'CSUP' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSUPD00                                              *
      ****************************************************************
