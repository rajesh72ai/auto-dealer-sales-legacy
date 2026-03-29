       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSLEAD0.
      ****************************************************************
      * PROGRAM:  CUSLEAD0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - LEAD TRACKING & MANAGEMENT              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  MANAGES CUSTOMER LEADS THROUGH THEIR LIFECYCLE.    *
      *           FUNCTIONS: AD (ADD LEAD), UP (UPDATE STATUS),      *
      *           LS (LIST BY SALESPERSON/STATUS).                    *
      *           LEAD STATUS LIFECYCLE:                              *
      *             NW (NEW) -> CT (CONTACTED) -> AP (APPOINTMENT)   *
      *             -> TS (TEST DRIVE) -> QT (QUOTE)                 *
      *             -> WN (WON) / LS (LOST) / DD (DEAD)             *
      *           ALERTS ON OVERDUE FOLLOW-UPS. WHEN STATUS=WN,      *
      *           LINKS TO DEAL CREATION.                             *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSLD - CUSTOMER LEAD                               *
      * CALLS:    COMLGEL0 - AUDIT LOGGING                          *
      *           COMDBEL0 - DB2 ERROR HANDLING                      *
      *           COMDTEL0 - DATE UTILITIES                          *
      * TABLES:   AUTOSALE.CUSTOMER_LEAD (SELECT, INSERT, UPDATE)    *
      *           AUTOSALE.CUSTOMER (SELECT)                         *
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
                                          VALUE 'CUSLEAD0'.
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
           COPY DCLCSLEAD.
      *
           COPY DCLCUSTM.
      *
      *    INPUT FIELDS
      *
       01  WS-LEAD-INPUT.
           05  WS-LI-FUNCTION            PIC X(02).
               88  WS-LI-ADD                         VALUE 'AD'.
               88  WS-LI-UPDATE                      VALUE 'UP'.
               88  WS-LI-LIST                        VALUE 'LS'.
           05  WS-LI-LEAD-ID             PIC X(09).
           05  WS-LI-CUST-ID             PIC X(09).
           05  WS-LI-DEALER-CODE         PIC X(05).
           05  WS-LI-SOURCE              PIC X(03).
           05  WS-LI-INT-MODEL           PIC X(06).
           05  WS-LI-INT-YEAR            PIC X(04).
           05  WS-LI-STATUS              PIC X(02).
               88  WS-LI-STAT-NEW                    VALUE 'NW'.
               88  WS-LI-STAT-CONTACTED              VALUE 'CT'.
               88  WS-LI-STAT-APPT                   VALUE 'AP'.
               88  WS-LI-STAT-TESTDRIVE              VALUE 'TS'.
               88  WS-LI-STAT-QUOTE                  VALUE 'QT'.
               88  WS-LI-STAT-WON                    VALUE 'WN'.
               88  WS-LI-STAT-LOST                   VALUE 'LS'.
               88  WS-LI-STAT-DEAD                   VALUE 'DD'.
           05  WS-LI-ASSIGNED-SALES      PIC X(08).
           05  WS-LI-FOLLOW-UP-DATE      PIC X(10).
           05  WS-LI-NOTES               PIC X(200).
           05  WS-LI-FILTER-SALES        PIC X(08).
           05  WS-LI-FILTER-STATUS       PIC X(02).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-LEAD-OUTPUT.
           05  WS-LO-STATUS-LINE.
               10  WS-LO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LO-MSG-TEXT       PIC X(70).
           05  WS-LO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-LO-HEADER.
               10  FILLER               PIC X(35)
                   VALUE '---- LEAD MANAGEMENT ----          '.
               10  FILLER               PIC X(44) VALUE SPACES.
      *
      *    ADD/UPDATE CONFIRMATION FIELDS
      *
           05  WS-LO-CONF-LINE1.
               10  FILLER               PIC X(10)
                   VALUE 'LEAD ID:  '.
               10  WS-LO-LEAD-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(13)
                   VALUE 'CUSTOMER ID: '.
               10  WS-LO-CUST-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-LO-STATUS         PIC X(02).
               10  FILLER               PIC X(19) VALUE SPACES.
           05  WS-LO-CONF-LINE2.
               10  FILLER               PIC X(10)
                   VALUE 'CUSTOMER: '.
               10  WS-LO-CUST-NAME      PIC X(40).
               10  FILLER               PIC X(29) VALUE SPACES.
           05  WS-LO-CONF-LINE3.
               10  FILLER               PIC X(10)
                   VALUE 'INTEREST: '.
               10  WS-LO-INT-YEAR       PIC X(04).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LO-INT-MODEL      PIC X(06).
               10  FILLER               PIC X(06) VALUE SPACES.
               10  FILLER               PIC X(12)
                   VALUE 'FOLLOW-UP:  '.
               10  WS-LO-FOLLOW-UP      PIC X(10).
               10  FILLER               PIC X(30) VALUE SPACES.
           05  WS-LO-CONF-LINE4.
               10  FILLER               PIC X(08)
                   VALUE 'SALES:  '.
               10  WS-LO-SALES-ID       PIC X(08).
               10  FILLER               PIC X(06) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'SOURCE: '.
               10  WS-LO-SOURCE         PIC X(03).
               10  FILLER               PIC X(06) VALUE SPACES.
               10  FILLER               PIC X(10)
                   VALUE 'CONTACTS: '.
               10  WS-LO-CONTACTS       PIC Z(03)9.
               10  FILLER               PIC X(26) VALUE SPACES.
           05  WS-LO-BLANK-2            PIC X(79) VALUE SPACES.
      *
      *    LIST VIEW FIELDS
      *
           05  WS-LO-LST-COL-HDR.
               10  FILLER               PIC X(10) VALUE 'LEAD ID   '.
               10  FILLER               PIC X(20)
                   VALUE 'CUSTOMER            '.
               10  FILLER               PIC X(03) VALUE 'ST '.
               10  FILLER               PIC X(09)
                   VALUE 'SALES    '.
               10  FILLER               PIC X(11)
                   VALUE 'FOLLOW-UP  '.
               10  FILLER               PIC X(03) VALUE 'CT '.
               10  FILLER               PIC X(08)
                   VALUE 'OVERDUE '.
               10  FILLER               PIC X(15) VALUE SPACES.
           05  WS-LO-LST-SEP            PIC X(79) VALUE ALL '-'.
           05  WS-LO-LST-LINES.
               10  WS-LO-LST-LINE       OCCURS 10 TIMES.
                   15  WS-LO-LL-LEAD-ID  PIC Z(08)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-NAME     PIC X(19).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-STATUS   PIC X(02).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-SALES    PIC X(08).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-FOLLOWUP PIC X(10).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-CONTACTS PIC Z(02)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-OVERDUE  PIC X(03).
                   15  FILLER            PIC X(18) VALUE SPACES.
           05  WS-LO-ALERT-LINE.
               10  FILLER               PIC X(18)
                   VALUE 'OVERDUE LEADS:    '.
               10  WS-LO-OVERDUE-COUNT  PIC Z(04)9.
               10  FILLER               PIC X(56) VALUE SPACES.
           05  WS-LO-WON-MSG.
               10  FILLER               PIC X(52)
                   VALUE 'LEAD WON - USE TRANSACTION SLNW TO CREAT
      -               'E DEAL        '.
               10  FILLER               PIC X(27) VALUE SPACES.
           05  WS-LO-FILLER             PIC X(100) VALUE SPACES.
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
      *    DATE CALL FIELDS
      *
       01  WS-DTE-REQUEST.
           05  WS-DTE-FUNCTION          PIC X(04).
           05  WS-DTE-INPUT-DATE        PIC X(10).
       01  WS-DTE-RESULT.
           05  WS-DTE-RC                PIC S9(04) COMP.
           05  WS-DTE-OUTPUT            PIC X(20).
      *
      *    WORKING FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-CUST-ID-NUM           PIC S9(09) COMP VALUE +0.
           05  WS-LEAD-ID-NUM           PIC S9(09) COMP VALUE +0.
           05  WS-NEW-LEAD-ID           PIC S9(09) COMP VALUE +0.
           05  WS-INT-YEAR-NUM          PIC S9(04) COMP VALUE +0.
           05  WS-LEAD-IDX              PIC S9(04) COMP VALUE +0.
           05  WS-OVERDUE-COUNT         PIC S9(04) COMP VALUE +0.
           05  WS-OLD-STATUS            PIC X(02)  VALUE SPACES.
           05  WS-CUST-FIRST            PIC X(30)  VALUE SPACES.
           05  WS-CUST-LAST             PIC X(30)  VALUE SPACES.
           05  WS-CURRENT-DATE-W        PIC X(10)  VALUE SPACES.
      *
      *    CURSOR FETCH FIELDS
      *
       01  WS-CF-LEAD.
           05  WS-CF-LEAD-ID            PIC S9(09) COMP.
           05  WS-CF-CUST-ID            PIC S9(09) COMP.
           05  WS-CF-FIRST-NAME         PIC X(30).
           05  WS-CF-LAST-NAME          PIC X(30).
           05  WS-CF-STATUS             PIC X(02).
           05  WS-CF-SALES              PIC X(08).
           05  WS-CF-FOLLOW-UP          PIC X(10).
           05  WS-CF-CONTACT-COUNT      PIC S9(04) COMP.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-INT-MODEL          PIC S9(04) COMP VALUE +0.
           05  WS-NI-INT-YEAR           PIC S9(04) COMP VALUE +0.
           05  WS-NI-FOLLOW-UP          PIC S9(04) COMP VALUE +0.
           05  WS-NI-LAST-CONTACT       PIC S9(04) COMP VALUE +0.
           05  WS-NI-NOTES              PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR - LIST LEADS BY SALESPERSON AND/OR STATUS
      *
           EXEC SQL
               DECLARE CSR_LEADS_ALL CURSOR FOR
               SELECT L.LEAD_ID
                    , L.CUSTOMER_ID
                    , C.FIRST_NAME
                    , C.LAST_NAME
                    , L.LEAD_STATUS
                    , L.ASSIGNED_SALES
                    , L.FOLLOW_UP_DATE
                    , L.CONTACT_COUNT
               FROM   AUTOSALE.CUSTOMER_LEAD L
                    , AUTOSALE.CUSTOMER C
               WHERE  L.CUSTOMER_ID = C.CUSTOMER_ID
                 AND  L.DEALER_CODE = :WS-LI-DEALER-CODE
                 AND  (L.ASSIGNED_SALES = :WS-LI-FILTER-SALES
                       OR :WS-LI-FILTER-SALES = '        ')
                 AND  (L.LEAD_STATUS = :WS-LI-FILTER-STATUS
                       OR :WS-LI-FILTER-STATUS = '  ')
               ORDER BY L.FOLLOW_UP_DATE ASC
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
               EVALUATE TRUE
                   WHEN WS-LI-ADD
                       PERFORM 4000-ADD-LEAD
                   WHEN WS-LI-UPDATE
                       PERFORM 5000-UPDATE-LEAD
                   WHEN WS-LI-LIST
                       PERFORM 6000-LIST-LEADS
               END-EVALUATE
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
           INITIALIZE WS-LEAD-OUTPUT
           MOVE 'CUSLEAD0' TO WS-LO-MSG-ID
           MOVE +0 TO WS-OVERDUE-COUNT
      *
      *    GET CURRENT DATE FOR OVERDUE CHECK
      *
           MOVE 'CURD' TO WS-DTE-FUNCTION
           CALL 'COMDTEL0' USING WS-DTE-REQUEST
                                  WS-DTE-RESULT
           MOVE WS-DTE-OUTPUT(1:10) TO WS-CURRENT-DATE-W
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
                   TO WS-LO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION        TO WS-LI-FUNCTION
               MOVE WS-INP-BODY(1:9)       TO WS-LI-LEAD-ID
               MOVE WS-INP-BODY(10:9)      TO WS-LI-CUST-ID
               MOVE WS-INP-BODY(19:5)      TO WS-LI-DEALER-CODE
               MOVE WS-INP-BODY(24:3)      TO WS-LI-SOURCE
               MOVE WS-INP-BODY(27:6)      TO WS-LI-INT-MODEL
               MOVE WS-INP-BODY(33:4)      TO WS-LI-INT-YEAR
               MOVE WS-INP-BODY(37:2)      TO WS-LI-STATUS
               MOVE WS-INP-BODY(39:8)      TO WS-LI-ASSIGNED-SALES
               MOVE WS-INP-BODY(47:10)     TO WS-LI-FOLLOW-UP-DATE
               MOVE WS-INP-BODY(57:200)    TO WS-LI-NOTES
               MOVE WS-INP-BODY(257:8)     TO WS-LI-FILTER-SALES
               MOVE WS-INP-BODY(265:2)     TO WS-LI-FILTER-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-LI-FUNCTION = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FUNCTION REQUIRED: AD (ADD), UP (UPD), LS (LST)'
                   TO WS-LO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-LI-ADD
               IF WS-LI-CUST-ID = SPACES OR ZEROS
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'CUSTOMER ID IS REQUIRED TO ADD A LEAD'
                       TO WS-LO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-LI-DEALER-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEALER CODE IS REQUIRED'
                       TO WS-LO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-LI-ASSIGNED-SALES = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'ASSIGNED SALESPERSON IS REQUIRED'
                       TO WS-LO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-LI-SOURCE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LEAD SOURCE IS REQUIRED'
                       TO WS-LO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-LI-UPDATE
               IF WS-LI-LEAD-ID = SPACES OR ZEROS
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LEAD ID IS REQUIRED FOR UPDATE'
                       TO WS-LO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-LI-STATUS = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'NEW STATUS IS REQUIRED FOR UPDATE'
                       TO WS-LO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-LI-LIST
               IF WS-LI-DEALER-CODE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'DEALER CODE IS REQUIRED FOR LISTING'
                       TO WS-LO-MSG-TEXT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-ADD-LEAD - CREATE NEW LEAD RECORD                    *
      ****************************************************************
       4000-ADD-LEAD.
      *
           COMPUTE WS-CUST-ID-NUM =
               FUNCTION NUMVAL(WS-LI-CUST-ID)
      *
      *    VERIFY CUSTOMER EXISTS
      *
           EXEC SQL
               SELECT FIRST_NAME
                    , LAST_NAME
               INTO  :WS-CUST-FIRST
                   , :WS-CUST-LAST
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-LO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    SET NULL INDICATORS
      *
           IF WS-LI-INT-MODEL = SPACES
               MOVE -1 TO WS-NI-INT-MODEL
           ELSE
               MOVE +0 TO WS-NI-INT-MODEL
           END-IF
      *
           IF WS-LI-INT-YEAR = SPACES OR ZEROS
               MOVE -1 TO WS-NI-INT-YEAR
               MOVE +0 TO WS-INT-YEAR-NUM
           ELSE
               MOVE +0 TO WS-NI-INT-YEAR
               COMPUTE WS-INT-YEAR-NUM =
                   FUNCTION NUMVAL(WS-LI-INT-YEAR)
           END-IF
      *
           IF WS-LI-FOLLOW-UP-DATE = SPACES
               MOVE -1 TO WS-NI-FOLLOW-UP
           ELSE
               MOVE +0 TO WS-NI-FOLLOW-UP
           END-IF
      *
           IF WS-LI-NOTES = SPACES
               MOVE -1 TO WS-NI-NOTES
           ELSE
               MOVE +0 TO WS-NI-NOTES
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.CUSTOMER_LEAD
               ( CUSTOMER_ID
               , DEALER_CODE
               , LEAD_SOURCE
               , INTEREST_MODEL
               , INTEREST_YEAR
               , LEAD_STATUS
               , ASSIGNED_SALES
               , FOLLOW_UP_DATE
               , LAST_CONTACT_DT
               , CONTACT_COUNT
               , NOTES
               , CREATED_TS
               , UPDATED_TS
               )
               VALUES
               ( :WS-CUST-ID-NUM
               , :WS-LI-DEALER-CODE
               , :WS-LI-SOURCE
               , :WS-LI-INT-MODEL    :WS-NI-INT-MODEL
               , :WS-INT-YEAR-NUM    :WS-NI-INT-YEAR
               , 'NW'
               , :WS-LI-ASSIGNED-SALES
               , :WS-LI-FOLLOW-UP-DATE :WS-NI-FOLLOW-UP
               , CURRENT DATE
               , 1
               , :WS-LI-NOTES        :WS-NI-NOTES
               , CURRENT TIMESTAMP
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSLEAD0'          TO WS-DBERR-PROGRAM
               MOVE 'CUSTOMER_LEAD'     TO WS-DBERR-TABLE
               MOVE 'INSERT'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-LO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    GET AUTO-GENERATED LEAD ID
      *
           EXEC SQL
               SELECT IDENTITY_VAL_LOCAL()
               INTO   :WS-NEW-LEAD-ID
               FROM   SYSIBM.SYSDUMMY1
           END-EXEC
      *
      *    FORMAT CONFIRMATION OUTPUT
      *
           MOVE WS-NEW-LEAD-ID TO WS-LO-LEAD-ID
           MOVE WS-CUST-ID-NUM TO WS-LO-CUST-ID
           MOVE 'NW'           TO WS-LO-STATUS
           STRING WS-CUST-LAST  DELIMITED BY '  '
                  ', '           DELIMITED BY SIZE
                  WS-CUST-FIRST  DELIMITED BY '  '
               INTO WS-LO-CUST-NAME
           END-STRING
           MOVE WS-LI-INT-YEAR       TO WS-LO-INT-YEAR
           MOVE WS-LI-INT-MODEL      TO WS-LO-INT-MODEL
           MOVE WS-LI-FOLLOW-UP-DATE TO WS-LO-FOLLOW-UP
           MOVE WS-LI-ASSIGNED-SALES TO WS-LO-SALES-ID
           MOVE WS-LI-SOURCE         TO WS-LO-SOURCE
           MOVE 1                     TO WS-LO-CONTACTS
      *
      *    AUDIT LOG
      *
           MOVE 'LOGW'       TO WS-LOG-FUNCTION
           MOVE 'CUSLEAD0'   TO WS-LOG-PROGRAM
           MOVE 'CUSTOMER_LEAD' TO WS-LOG-TABLE
           MOVE 'INS'        TO WS-LOG-ACTION
           MOVE WS-NEW-LEAD-ID TO WS-LOG-KEY
           MOVE SPACES          TO WS-LOG-OLD-VAL
           STRING 'LEAD FOR CUST ' DELIMITED BY SIZE
                  WS-LI-CUST-ID    DELIMITED BY '  '
                  ' STATUS=NW'     DELIMITED BY SIZE
               INTO WS-LOG-NEW-VAL
           END-STRING
           MOVE 'LEAD CREATED' TO WS-LOG-DESC
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
                                  WS-LOG-RESULT
      *
           MOVE 'LEAD CREATED SUCCESSFULLY' TO WS-LO-MSG-TEXT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-UPDATE-LEAD - UPDATE STATUS AND CONTACT INFO         *
      ****************************************************************
       5000-UPDATE-LEAD.
      *
           COMPUTE WS-LEAD-ID-NUM =
               FUNCTION NUMVAL(WS-LI-LEAD-ID)
      *
      *    FETCH CURRENT LEAD STATUS
      *
           EXEC SQL
               SELECT L.LEAD_STATUS
                    , L.CUSTOMER_ID
                    , C.FIRST_NAME
                    , C.LAST_NAME
                    , L.CONTACT_COUNT
                    , L.ASSIGNED_SALES
               INTO  :WS-OLD-STATUS
                   , :WS-CUST-ID-NUM
                   , :WS-CUST-FIRST
                   , :WS-CUST-LAST
                   , :WS-CF-CONTACT-COUNT
                   , :WS-CF-SALES
               FROM   AUTOSALE.CUSTOMER_LEAD L
                    , AUTOSALE.CUSTOMER C
               WHERE  L.LEAD_ID = :WS-LEAD-ID-NUM
                 AND  C.CUSTOMER_ID = L.CUSTOMER_ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LEAD NOT FOUND' TO WS-LO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON LEAD LOOKUP'
                   TO WS-LO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    VALIDATE STATUS TRANSITION
      *    NW->CT->AP->TS->QT->WN/LS/DD
      *    (ALLOW BACKWARD TO LS/DD FROM ANY ACTIVE STATE)
      *
           IF WS-OLD-STATUS = 'WN' OR 'LS' OR 'DD'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'LEAD IS CLOSED - CANNOT UPDATE'
                   TO WS-LO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    SET NULL INDICATORS FOR OPTIONAL UPDATE FIELDS
      *
           IF WS-LI-FOLLOW-UP-DATE = SPACES
               MOVE -1 TO WS-NI-FOLLOW-UP
           ELSE
               MOVE +0 TO WS-NI-FOLLOW-UP
           END-IF
      *
           IF WS-LI-NOTES = SPACES
               MOVE -1 TO WS-NI-NOTES
           ELSE
               MOVE +0 TO WS-NI-NOTES
           END-IF
      *
      *    UPDATE THE LEAD
      *
           ADD +1 TO WS-CF-CONTACT-COUNT
      *
           EXEC SQL
               UPDATE AUTOSALE.CUSTOMER_LEAD
               SET    LEAD_STATUS    = :WS-LI-STATUS
                    , FOLLOW_UP_DATE = CASE
                          WHEN :WS-NI-FOLLOW-UP >= 0
                          THEN :WS-LI-FOLLOW-UP-DATE
                          ELSE FOLLOW_UP_DATE END
                    , LAST_CONTACT_DT = CURRENT DATE
                    , CONTACT_COUNT  = :WS-CF-CONTACT-COUNT
                    , NOTES          = CASE
                          WHEN :WS-NI-NOTES >= 0
                          THEN :WS-LI-NOTES
                          ELSE NOTES END
                    , UPDATED_TS     = CURRENT TIMESTAMP
               WHERE  LEAD_ID = :WS-LEAD-ID-NUM
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE SQLCODE TO WS-DBERR-SQLCODE
               MOVE 'CUSLEAD0'          TO WS-DBERR-PROGRAM
               MOVE 'CUSTOMER_LEAD'     TO WS-DBERR-TABLE
               MOVE 'UPDATE'            TO WS-DBERR-OPERATION
               MOVE 'ERRH'              TO WS-DBERR-FUNCTION
               CALL 'COMDBEL0' USING WS-DBERR-REQUEST
                                      WS-DBERR-RESULT
               MOVE +16 TO WS-RETURN-CODE
               MOVE WS-DBERR-MSG TO WS-LO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    FORMAT CONFIRMATION
      *
           MOVE WS-LEAD-ID-NUM   TO WS-LO-LEAD-ID
           MOVE WS-CUST-ID-NUM   TO WS-LO-CUST-ID
           MOVE WS-LI-STATUS     TO WS-LO-STATUS
           STRING WS-CUST-LAST    DELIMITED BY '  '
                  ', '             DELIMITED BY SIZE
                  WS-CUST-FIRST    DELIMITED BY '  '
               INTO WS-LO-CUST-NAME
           END-STRING
           MOVE WS-CF-SALES       TO WS-LO-SALES-ID
           MOVE WS-CF-CONTACT-COUNT TO WS-LO-CONTACTS
      *
      *    AUDIT LOG
      *
           MOVE 'LOGW'       TO WS-LOG-FUNCTION
           MOVE 'CUSLEAD0'   TO WS-LOG-PROGRAM
           MOVE 'CUSTOMER_LEAD' TO WS-LOG-TABLE
           MOVE 'UPD'        TO WS-LOG-ACTION
           MOVE WS-LEAD-ID-NUM TO WS-LOG-KEY
           MOVE WS-OLD-STATUS  TO WS-LOG-OLD-VAL
           MOVE WS-LI-STATUS   TO WS-LOG-NEW-VAL
           STRING 'LEAD STATUS CHANGE ' DELIMITED BY SIZE
                  WS-OLD-STATUS          DELIMITED BY SIZE
                  ' -> '                 DELIMITED BY SIZE
                  WS-LI-STATUS           DELIMITED BY SIZE
               INTO WS-LOG-DESC
           END-STRING
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
                                  WS-LOG-RESULT
      *
      *    IF WON, SHOW DEAL CREATION MESSAGE
      *
           IF WS-LI-STAT-WON
               MOVE 'LEAD WON - PROCEED TO DEAL CREATION (SLNW)'
                   TO WS-LO-MSG-TEXT
           ELSE
               MOVE 'LEAD UPDATED SUCCESSFULLY' TO WS-LO-MSG-TEXT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-LIST-LEADS                                           *
      ****************************************************************
       6000-LIST-LEADS.
      *
           EXEC SQL
               OPEN CSR_LEADS_ALL
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'ERROR OPENING LEAD LIST CURSOR'
                   TO WS-LO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
           MOVE +0 TO WS-LEAD-IDX
           MOVE +0 TO WS-OVERDUE-COUNT
      *
           PERFORM UNTIL WS-LEAD-IDX >= 10
               EXEC SQL
                   FETCH CSR_LEADS_ALL
                   INTO  :WS-CF-LEAD-ID
                       , :WS-CF-CUST-ID
                       , :WS-CF-FIRST-NAME
                       , :WS-CF-LAST-NAME
                       , :WS-CF-STATUS
                       , :WS-CF-SALES
                       , :WS-CF-FOLLOW-UP
                              :WS-NI-FOLLOW-UP
                       , :WS-CF-CONTACT-COUNT
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
               ADD +1 TO WS-LEAD-IDX
      *
               MOVE WS-CF-LEAD-ID TO
                   WS-LO-LL-LEAD-ID(WS-LEAD-IDX)
      *
               STRING WS-CF-LAST-NAME DELIMITED BY '  '
                      ', '             DELIMITED BY SIZE
                      WS-CF-FIRST-NAME DELIMITED BY '  '
                   INTO WS-LO-LL-NAME(WS-LEAD-IDX)
               END-STRING
      *
               MOVE WS-CF-STATUS TO
                   WS-LO-LL-STATUS(WS-LEAD-IDX)
               MOVE WS-CF-SALES TO
                   WS-LO-LL-SALES(WS-LEAD-IDX)
               MOVE WS-CF-CONTACT-COUNT TO
                   WS-LO-LL-CONTACTS(WS-LEAD-IDX)
      *
               IF WS-NI-FOLLOW-UP >= +0
                   MOVE WS-CF-FOLLOW-UP TO
                       WS-LO-LL-FOLLOWUP(WS-LEAD-IDX)
      *
      *            CHECK OVERDUE: FOLLOW-UP < TODAY AND NOT CLOSED
      *
                   IF WS-CF-FOLLOW-UP < WS-CURRENT-DATE-W
                       AND WS-CF-STATUS NOT = 'WN'
                       AND WS-CF-STATUS NOT = 'LS'
                       AND WS-CF-STATUS NOT = 'DD'
                       MOVE 'YES' TO
                           WS-LO-LL-OVERDUE(WS-LEAD-IDX)
                       ADD +1 TO WS-OVERDUE-COUNT
                   ELSE
                       MOVE 'NO ' TO
                           WS-LO-LL-OVERDUE(WS-LEAD-IDX)
                   END-IF
               ELSE
                   MOVE 'N/A' TO
                       WS-LO-LL-FOLLOWUP(WS-LEAD-IDX)
                   MOVE 'N/A' TO
                       WS-LO-LL-OVERDUE(WS-LEAD-IDX)
               END-IF
           END-PERFORM
      *
           EXEC SQL
               CLOSE CSR_LEADS_ALL
           END-EXEC
      *
           MOVE WS-OVERDUE-COUNT TO WS-LO-OVERDUE-COUNT
      *
           IF WS-LEAD-IDX = +0
               MOVE 'NO LEADS FOUND MATCHING CRITERIA'
                   TO WS-LO-MSG-TEXT
           ELSE
               IF WS-OVERDUE-COUNT > +0
                   STRING 'LEADS LISTED - '     DELIMITED BY SIZE
                          WS-LO-OVERDUE-COUNT   DELIMITED BY '  '
                          ' OVERDUE FOLLOW-UPS'  DELIMITED BY SIZE
                       INTO WS-LO-MSG-TEXT
                   END-STRING
               ELSE
                   MOVE 'LEAD LISTING COMPLETE' TO WS-LO-MSG-TEXT
               END-IF
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-LEAD-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'CSLD' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSLEAD0                                              *
      ****************************************************************
