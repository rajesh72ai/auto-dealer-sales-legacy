       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSINQ00.
      ****************************************************************
      * PROGRAM:  CUSINQ00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - SEARCH / INQUIRY                        *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SEARCHES CUSTOMER TABLE BY LAST NAME (LIKE),       *
      *           FIRST NAME, PHONE (EXACT), DRIVER LICENSE (EXACT), *
      *           OR CUSTOMER ID. RESULTS DISPLAYED 10 PER PAGE      *
      *           WITH PF7/PF8 PAGING. SELECT FROM LIST SHOWS FULL   *
      *           CUSTOMER DETAIL.                                    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSIQ - CUSTOMER INQUIRY                            *
      * CALLS:    COMFMTL0 - FORMAT PHONE, SSN MASK                 *
      *           COMMSGL0 - MESSAGE FORMATTING                      *
      * TABLES:   AUTOSALE.CUSTOMER (SELECT)                         *
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
                                          VALUE 'CUSINQ00'.
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
           COPY DCLCUSTM.
      *
      *    INPUT FIELDS
      *
       01  WS-INQ-INPUT.
           05  WS-II-FUNCTION            PIC X(02).
               88  WS-II-SEARCH                      VALUE 'SR'.
               88  WS-II-SELECT                      VALUE 'SL'.
               88  WS-II-NEXT-PAGE                   VALUE 'NX'.
               88  WS-II-PREV-PAGE                   VALUE 'PV'.
           05  WS-II-SEARCH-TYPE         PIC X(02).
               88  WS-II-BY-LAST-NAME                VALUE 'LN'.
               88  WS-II-BY-FIRST-NAME               VALUE 'FN'.
               88  WS-II-BY-PHONE                    VALUE 'PH'.
               88  WS-II-BY-DL                       VALUE 'DL'.
               88  WS-II-BY-CUST-ID                  VALUE 'ID'.
           05  WS-II-SEARCH-VALUE        PIC X(30).
           05  WS-II-SELECT-NUM          PIC 9(02).
           05  WS-II-DEALER-CODE         PIC X(05).
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
               10  FILLER               PIC X(35)
                   VALUE '---- CUSTOMER SEARCH RESULTS ----  '.
               10  FILLER               PIC X(20) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'PAGE: '.
               10  WS-IO-PAGE-NUM       PIC Z9.
               10  FILLER               PIC X(04) VALUE ' OF '.
               10  WS-IO-PAGE-TOT       PIC Z9.
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-IO-COL-HDR.
               10  FILLER               PIC X(04) VALUE 'SEL '.
               10  FILLER               PIC X(10) VALUE 'CUST ID   '.
               10  FILLER               PIC X(22)
                   VALUE 'NAME                  '.
               10  FILLER               PIC X(15)
                   VALUE 'PHONE          '.
               10  FILLER               PIC X(16)
                   VALUE 'CITY/STATE      '.
               10  FILLER               PIC X(02) VALUE 'TY'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  FILLER               PIC X(03) VALUE 'SRC'.
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-IO-SEPARATOR           PIC X(79) VALUE ALL '-'.
           05  WS-IO-LIST-LINES.
               10  WS-IO-LIST-LINE       OCCURS 10 TIMES.
                   15  WS-IO-LL-SEL      PIC X(02).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-IO-LL-ID       PIC Z(08)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-IO-LL-NAME     PIC X(22).
                   15  WS-IO-LL-PHONE    PIC X(14).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-IO-LL-CITY-ST  PIC X(16).
                   15  WS-IO-LL-TYPE     PIC X(01).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-IO-LL-SOURCE   PIC X(03).
                   15  FILLER            PIC X(05) VALUE SPACES.
           05  WS-IO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-IO-TOTAL-LINE.
               10  FILLER               PIC X(16) VALUE
                   'TOTAL MATCHING: '.
               10  WS-IO-TOTAL-COUNT    PIC Z(06)9.
               10  FILLER               PIC X(56) VALUE SPACES.
           05  WS-IO-BLANK-3            PIC X(79) VALUE SPACES.
      *
      *    DETAIL VIEW FIELDS (USED WHEN SELECTING FROM LIST)
      *
           05  WS-IO-DETAIL-HEADER.
               10  FILLER               PIC X(35)
                   VALUE '---- CUSTOMER DETAIL ----          '.
               10  FILLER               PIC X(44) VALUE SPACES.
           05  WS-IO-DET-ID-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'CUSTOMER ID: '.
               10  WS-IO-DET-ID         PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TYPE: '.
               10  WS-IO-DET-TYPE       PIC X(01).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'SOURCE: '.
               10  WS-IO-DET-SOURCE     PIC X(03).
               10  FILLER               PIC X(30) VALUE SPACES.
           05  WS-IO-DET-NAME.
               10  FILLER               PIC X(06) VALUE 'NAME: '.
               10  WS-IO-DET-FULLNAME   PIC X(65).
               10  FILLER               PIC X(08) VALUE SPACES.
           05  WS-IO-DET-ADDR1.
               10  FILLER               PIC X(09)
                   VALUE 'ADDRESS: '.
               10  WS-IO-DET-ADDRESS1   PIC X(50).
               10  FILLER               PIC X(20) VALUE SPACES.
           05  WS-IO-DET-ADDR2.
               10  FILLER               PIC X(09) VALUE SPACES.
               10  WS-IO-DET-ADDRESS2   PIC X(50).
               10  FILLER               PIC X(20) VALUE SPACES.
           05  WS-IO-DET-CITY-LINE.
               10  FILLER               PIC X(09) VALUE SPACES.
               10  WS-IO-DET-CITY       PIC X(30).
               10  FILLER               PIC X(02) VALUE ', '.
               10  WS-IO-DET-STATE      PIC X(02).
               10  FILLER               PIC X(02) VALUE SPACES.
               10  WS-IO-DET-ZIP        PIC X(10).
               10  FILLER               PIC X(24) VALUE SPACES.
           05  WS-IO-DET-PHONE.
               10  FILLER               PIC X(06) VALUE 'HOME: '.
               10  WS-IO-DET-HOME-PH    PIC X(14).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'CELL: '.
               10  WS-IO-DET-CELL-PH    PIC X(14).
               10  FILLER               PIC X(35) VALUE SPACES.
           05  WS-IO-DET-EMAIL-LINE.
               10  FILLER               PIC X(07) VALUE 'EMAIL: '.
               10  WS-IO-DET-EMAIL      PIC X(60).
               10  FILLER               PIC X(12) VALUE SPACES.
           05  WS-IO-DET-EMP-LINE.
               10  FILLER               PIC X(10)
                   VALUE 'EMPLOYER: '.
               10  WS-IO-DET-EMPLOYER   PIC X(40).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(08) VALUE 'INCOME: '.
               10  WS-IO-DET-INCOME     PIC $ZZZ,ZZ9.99.
               10  FILLER               PIC X(04) VALUE SPACES.
           05  WS-IO-DET-DL-LINE.
               10  FILLER               PIC X(04) VALUE 'DL: '.
               10  WS-IO-DET-DL         PIC X(20).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'SSN4: '.
               10  WS-IO-DET-SSN4       PIC X(08).
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(07) VALUE 'SALES: '.
               10  WS-IO-DET-SALES      PIC X(08).
               10  FILLER               PIC X(18) VALUE SPACES.
           05  WS-IO-DET-FILLER         PIC X(200) VALUE SPACES.
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
      *    MSG CALL FIELDS
      *
       01  WS-MSG-REQUEST.
           05  WS-MSG-FUNCTION          PIC X(04).
           05  WS-MSG-CODE              PIC X(08).
       01  WS-MSG-RESULT.
           05  WS-MSG-RC                PIC S9(04) COMP.
           05  WS-MSG-TEXT-OUT          PIC X(70).
      *
      *    WORKING FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-CUST-IDX              PIC S9(04) COMP VALUE +0.
           05  WS-PAGE-NUMBER            PIC S9(04) COMP VALUE +1.
           05  WS-TOTAL-PAGES           PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-COUNT           PIC S9(09) COMP VALUE +0.
           05  WS-ROWS-TO-SKIP          PIC S9(09) COMP VALUE +0.
           05  WS-ROWS-FETCHED          PIC S9(04) COMP VALUE +0.
           05  WS-PAGE-SIZE             PIC S9(04) COMP VALUE +10.
           05  WS-SEARCH-LIKE           PIC X(32)  VALUE SPACES.
           05  WS-SELECT-IDX            PIC S9(04) COMP VALUE +0.
           05  WS-CITY-STATE-WORK       PIC X(16)  VALUE SPACES.
           05  WS-DETAIL-MODE           PIC X(01)  VALUE 'N'.
               88  WS-SHOW-DETAIL                   VALUE 'Y'.
               88  WS-SHOW-LIST                     VALUE 'N'.
      *
      *    CURSOR FETCH FIELDS
      *
       01  WS-FETCH-FIELDS.
           05  WS-CF-CUST-ID            PIC S9(09) COMP.
           05  WS-CF-FIRST-NAME         PIC X(30).
           05  WS-CF-LAST-NAME          PIC X(30).
           05  WS-CF-HOME-PHONE         PIC X(10).
           05  WS-CF-CITY               PIC X(30).
           05  WS-CF-STATE              PIC X(02).
           05  WS-CF-CUST-TYPE          PIC X(01).
           05  WS-CF-SOURCE             PIC X(03).
      *
      *    RESULT SET CACHE (10 CUSTOMER IDS FOR CURRENT PAGE)
      *
       01  WS-PAGE-CACHE.
           05  WS-PC-ENTRY              OCCURS 10 TIMES.
               10  WS-PC-CUST-ID        PIC S9(09) COMP.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-HOME-PHONE         PIC S9(04) COMP VALUE +0.
           05  WS-NI-SOURCE             PIC S9(04) COMP VALUE +0.
           05  WS-NI-ADDR2              PIC S9(04) COMP VALUE +0.
           05  WS-NI-EMAIL              PIC S9(04) COMP VALUE +0.
           05  WS-NI-EMPLOYER           PIC S9(04) COMP VALUE +0.
           05  WS-NI-INCOME             PIC S9(04) COMP VALUE +0.
           05  WS-NI-SSN4               PIC S9(04) COMP VALUE +0.
           05  WS-NI-DL                 PIC S9(04) COMP VALUE +0.
           05  WS-NI-ASSIGNED           PIC S9(04) COMP VALUE +0.
           05  WS-NI-CELL               PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR - SEARCH BY LAST NAME (LIKE)
      *
           EXEC SQL
               DECLARE CSR_CUST_LNAME CURSOR FOR
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
                    , CITY
                    , STATE_CODE
                    , CUSTOMER_TYPE
                    , SOURCE_CODE
               FROM   AUTOSALE.CUSTOMER
               WHERE  LAST_NAME LIKE :WS-SEARCH-LIKE
               ORDER BY LAST_NAME, FIRST_NAME
           END-EXEC.
      *
      *    CURSOR - SEARCH BY PHONE (EXACT)
      *
           EXEC SQL
               DECLARE CSR_CUST_PHONE CURSOR FOR
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
                    , CITY
                    , STATE_CODE
                    , CUSTOMER_TYPE
                    , SOURCE_CODE
               FROM   AUTOSALE.CUSTOMER
               WHERE  HOME_PHONE = :WS-II-SEARCH-VALUE
                  OR  CELL_PHONE = :WS-II-SEARCH-VALUE
               ORDER BY LAST_NAME, FIRST_NAME
           END-EXEC.
      *
      *    CURSOR - SEARCH BY DRIVER LICENSE (EXACT)
      *
           EXEC SQL
               DECLARE CSR_CUST_DL CURSOR FOR
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
                    , CITY
                    , STATE_CODE
                    , CUSTOMER_TYPE
                    , SOURCE_CODE
               FROM   AUTOSALE.CUSTOMER
               WHERE  DRIVERS_LICENSE = :WS-II-SEARCH-VALUE
               ORDER BY LAST_NAME, FIRST_NAME
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
                   WHEN WS-II-SELECT
                       PERFORM 5000-SHOW-CUSTOMER-DETAIL
                   WHEN OTHER
                       PERFORM 4000-SEARCH-CUSTOMERS
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
           INITIALIZE WS-INQ-OUTPUT
           MOVE 'CUSINQ00' TO WS-IO-MSG-ID
           MOVE +1 TO WS-PAGE-NUMBER
           MOVE 'N' TO WS-DETAIL-MODE
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
               MOVE WS-INP-FUNCTION      TO WS-II-FUNCTION
               MOVE WS-INP-BODY(1:2)     TO WS-II-SEARCH-TYPE
               MOVE WS-INP-BODY(3:30)    TO WS-II-SEARCH-VALUE
               MOVE WS-INP-BODY(33:2)    TO WS-II-SELECT-NUM
               MOVE WS-INP-BODY(35:5)    TO WS-II-DEALER-CODE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-II-FUNCTION = SPACES
               MOVE 'SR' TO WS-II-FUNCTION
           END-IF
      *
           IF WS-II-SEARCH
               IF WS-II-SEARCH-TYPE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'SEARCH TYPE REQUIRED (LN/FN/PH/DL/ID)'
                       TO WS-IO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
               IF WS-II-SEARCH-VALUE = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'SEARCH VALUE IS REQUIRED'
                       TO WS-IO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
           IF WS-II-SELECT
               IF WS-II-SELECT-NUM = ZEROS
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'SELECT A LINE NUMBER (01-10)'
                       TO WS-IO-MSG-TEXT
               END-IF
           END-IF
      *
      *    HANDLE PAGE NAVIGATION
      *
           IF WS-II-NEXT-PAGE
               ADD +1 TO WS-PAGE-NUMBER
           END-IF
      *
           IF WS-II-PREV-PAGE
               IF WS-PAGE-NUMBER > 1
                   SUBTRACT +1 FROM WS-PAGE-NUMBER
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-SEARCH-CUSTOMERS                                     *
      ****************************************************************
       4000-SEARCH-CUSTOMERS.
      *
      *    GET TOTAL COUNT FIRST
      *
           PERFORM 4100-GET-TOTAL-COUNT
      *
           IF WS-TOTAL-COUNT = +0
               MOVE 'NO CUSTOMERS FOUND MATCHING CRITERIA'
                   TO WS-IO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    COMPUTE PAGING
      *
           COMPUTE WS-TOTAL-PAGES =
               (WS-TOTAL-COUNT + WS-PAGE-SIZE - 1)
               / WS-PAGE-SIZE
      *
           IF WS-PAGE-NUMBER > WS-TOTAL-PAGES
               MOVE WS-TOTAL-PAGES TO WS-PAGE-NUMBER
           END-IF
      *
           COMPUTE WS-ROWS-TO-SKIP =
               (WS-PAGE-NUMBER - 1) * WS-PAGE-SIZE
      *
           MOVE WS-PAGE-NUMBER TO WS-IO-PAGE-NUM
           MOVE WS-TOTAL-PAGES TO WS-IO-PAGE-TOT
           MOVE WS-TOTAL-COUNT TO WS-IO-TOTAL-COUNT
      *
      *    OPEN APPROPRIATE CURSOR AND FETCH PAGE
      *
           PERFORM 4200-OPEN-CURSOR
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4300-FETCH-PAGE
           END-IF
      *
           PERFORM 4400-CLOSE-CURSOR
      *
           IF WS-ROWS-FETCHED > +0
               STRING 'FOUND ' DELIMITED BY SIZE
                      WS-IO-TOTAL-COUNT DELIMITED BY SIZE
                      ' CUSTOMERS - PF7/PF8 TO PAGE'
                                    DELIMITED BY SIZE
                   INTO WS-IO-MSG-TEXT
               END-STRING
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-GET-TOTAL-COUNT                                      *
      ****************************************************************
       4100-GET-TOTAL-COUNT.
      *
           EVALUATE TRUE
               WHEN WS-II-BY-LAST-NAME
                   STRING WS-II-SEARCH-VALUE DELIMITED BY '  '
                          '%' DELIMITED BY SIZE
                       INTO WS-SEARCH-LIKE
                   END-STRING
                   EXEC SQL
                       SELECT COUNT(*)
                       INTO   :WS-TOTAL-COUNT
                       FROM   AUTOSALE.CUSTOMER
                       WHERE  LAST_NAME LIKE :WS-SEARCH-LIKE
                   END-EXEC
               WHEN WS-II-BY-FIRST-NAME
                   STRING WS-II-SEARCH-VALUE DELIMITED BY '  '
                          '%' DELIMITED BY SIZE
                       INTO WS-SEARCH-LIKE
                   END-STRING
                   EXEC SQL
                       SELECT COUNT(*)
                       INTO   :WS-TOTAL-COUNT
                       FROM   AUTOSALE.CUSTOMER
                       WHERE  FIRST_NAME LIKE :WS-SEARCH-LIKE
                   END-EXEC
               WHEN WS-II-BY-PHONE
                   EXEC SQL
                       SELECT COUNT(*)
                       INTO   :WS-TOTAL-COUNT
                       FROM   AUTOSALE.CUSTOMER
                       WHERE  HOME_PHONE = :WS-II-SEARCH-VALUE
                          OR  CELL_PHONE = :WS-II-SEARCH-VALUE
                   END-EXEC
               WHEN WS-II-BY-DL
                   EXEC SQL
                       SELECT COUNT(*)
                       INTO   :WS-TOTAL-COUNT
                       FROM   AUTOSALE.CUSTOMER
                       WHERE  DRIVERS_LICENSE
                              = :WS-II-SEARCH-VALUE
                   END-EXEC
               WHEN WS-II-BY-CUST-ID
                   EXEC SQL
                       SELECT COUNT(*)
                       INTO   :WS-TOTAL-COUNT
                       FROM   AUTOSALE.CUSTOMER
                       WHERE  CUSTOMER_ID =
                              INTEGER(:WS-II-SEARCH-VALUE)
                   END-EXEC
           END-EVALUATE
      *
           IF SQLCODE NOT = +0
               MOVE +0 TO WS-TOTAL-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    4200-OPEN-CURSOR                                          *
      ****************************************************************
       4200-OPEN-CURSOR.
      *
           EVALUATE TRUE
               WHEN WS-II-BY-LAST-NAME
               WHEN WS-II-BY-FIRST-NAME
               WHEN WS-II-BY-CUST-ID
                   EXEC SQL
                       OPEN CSR_CUST_LNAME
                   END-EXEC
               WHEN WS-II-BY-PHONE
                   EXEC SQL
                       OPEN CSR_CUST_PHONE
                   END-EXEC
               WHEN WS-II-BY-DL
                   EXEC SQL
                       OPEN CSR_CUST_DL
                   END-EXEC
           END-EVALUATE
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'ERROR OPENING SEARCH CURSOR'
                   TO WS-IO-MSG-TEXT
           END-IF
           .
      *
      ****************************************************************
      *    4300-FETCH-PAGE - SKIP TO OFFSET AND FETCH 10 ROWS       *
      ****************************************************************
       4300-FETCH-PAGE.
      *
      *    SKIP ROWS FOR PREVIOUS PAGES
      *
           MOVE +0 TO WS-CUST-IDX
           PERFORM WS-ROWS-TO-SKIP TIMES
               PERFORM 4310-FETCH-ONE-ROW
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
           END-PERFORM
      *
      *    FETCH CURRENT PAGE
      *
           MOVE +0 TO WS-ROWS-FETCHED
      *
           PERFORM UNTIL WS-ROWS-FETCHED >= WS-PAGE-SIZE
               PERFORM 4310-FETCH-ONE-ROW
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               IF SQLCODE NOT = +0
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-ROWS-FETCHED
               MOVE WS-CF-CUST-ID
                   TO WS-PC-CUST-ID(WS-ROWS-FETCHED)
               MOVE WS-CF-CUST-ID
                   TO WS-IO-LL-ID(WS-ROWS-FETCHED)
      *
               STRING WS-CF-LAST-NAME DELIMITED BY '  '
                      ', '             DELIMITED BY SIZE
                      WS-CF-FIRST-NAME DELIMITED BY '  '
                   INTO WS-IO-LL-NAME(WS-ROWS-FETCHED)
               END-STRING
      *
      *        FORMAT PHONE
      *
               IF WS-CF-HOME-PHONE NOT = SPACES
                   MOVE 'FPHN' TO WS-FMT-FUNCTION
                   MOVE WS-CF-HOME-PHONE TO WS-FMT-INPUT
                   CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                          WS-FMT-RESULT
                   MOVE WS-FMT-OUTPUT(1:14) TO
                       WS-IO-LL-PHONE(WS-ROWS-FETCHED)
               END-IF
      *
               STRING WS-CF-CITY DELIMITED BY '  '
                      '/' DELIMITED BY SIZE
                      WS-CF-STATE DELIMITED BY SIZE
                   INTO WS-IO-LL-CITY-ST(WS-ROWS-FETCHED)
               END-STRING
      *
               MOVE WS-CF-CUST-TYPE TO
                   WS-IO-LL-TYPE(WS-ROWS-FETCHED)
               MOVE WS-CF-SOURCE TO
                   WS-IO-LL-SOURCE(WS-ROWS-FETCHED)
      *
      *        SET SELECTION NUMBER
      *
               MOVE WS-ROWS-FETCHED TO
                   WS-IO-LL-SEL(WS-ROWS-FETCHED)
           END-PERFORM
           .
      *
      ****************************************************************
      *    4310-FETCH-ONE-ROW                                        *
      ****************************************************************
       4310-FETCH-ONE-ROW.
      *
           EVALUATE TRUE
               WHEN WS-II-BY-LAST-NAME
               WHEN WS-II-BY-FIRST-NAME
               WHEN WS-II-BY-CUST-ID
                   EXEC SQL
                       FETCH CSR_CUST_LNAME
                       INTO  :WS-CF-CUST-ID
                           , :WS-CF-FIRST-NAME
                           , :WS-CF-LAST-NAME
                           , :WS-CF-HOME-PHONE
                                :WS-NI-HOME-PHONE
                           , :WS-CF-CITY
                           , :WS-CF-STATE
                           , :WS-CF-CUST-TYPE
                           , :WS-CF-SOURCE
                                :WS-NI-SOURCE
                   END-EXEC
               WHEN WS-II-BY-PHONE
                   EXEC SQL
                       FETCH CSR_CUST_PHONE
                       INTO  :WS-CF-CUST-ID
                           , :WS-CF-FIRST-NAME
                           , :WS-CF-LAST-NAME
                           , :WS-CF-HOME-PHONE
                                :WS-NI-HOME-PHONE
                           , :WS-CF-CITY
                           , :WS-CF-STATE
                           , :WS-CF-CUST-TYPE
                           , :WS-CF-SOURCE
                                :WS-NI-SOURCE
                   END-EXEC
               WHEN WS-II-BY-DL
                   EXEC SQL
                       FETCH CSR_CUST_DL
                       INTO  :WS-CF-CUST-ID
                           , :WS-CF-FIRST-NAME
                           , :WS-CF-LAST-NAME
                           , :WS-CF-HOME-PHONE
                                :WS-NI-HOME-PHONE
                           , :WS-CF-CITY
                           , :WS-CF-STATE
                           , :WS-CF-CUST-TYPE
                           , :WS-CF-SOURCE
                                :WS-NI-SOURCE
                   END-EXEC
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4400-CLOSE-CURSOR                                         *
      ****************************************************************
       4400-CLOSE-CURSOR.
      *
           EVALUATE TRUE
               WHEN WS-II-BY-LAST-NAME
               WHEN WS-II-BY-FIRST-NAME
               WHEN WS-II-BY-CUST-ID
                   EXEC SQL CLOSE CSR_CUST_LNAME END-EXEC
               WHEN WS-II-BY-PHONE
                   EXEC SQL CLOSE CSR_CUST_PHONE END-EXEC
               WHEN WS-II-BY-DL
                   EXEC SQL CLOSE CSR_CUST_DL END-EXEC
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-SHOW-CUSTOMER-DETAIL                                 *
      ****************************************************************
       5000-SHOW-CUSTOMER-DETAIL.
      *
           MOVE WS-II-SELECT-NUM TO WS-SELECT-IDX
      *
           IF WS-SELECT-IDX < 1 OR WS-SELECT-IDX > 10
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INVALID SELECTION NUMBER' TO WS-IO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF WS-PC-CUST-ID(WS-SELECT-IDX) = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'NO CUSTOMER AT THAT LINE' TO WS-IO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'Y' TO WS-DETAIL-MODE
      *
           EXEC SQL
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , MIDDLE_INIT
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
                    , SSN_LAST4
                    , DRIVERS_LICENSE
                    , ASSIGNED_SALES
               INTO  :CUSTOMER-ID    OF DCLCUSTOMER
                   , :FIRST-NAME     OF DCLCUSTOMER
                   , :LAST-NAME      OF DCLCUSTOMER
                   , :MIDDLE-INIT    OF DCLCUSTOMER
                   , :ADDRESS-LINE1  OF DCLCUSTOMER
                   , :ADDRESS-LINE2  OF DCLCUSTOMER
                                      :WS-NI-ADDR2
                   , :CITY           OF DCLCUSTOMER
                   , :STATE-CODE     OF DCLCUSTOMER
                   , :ZIP-CODE       OF DCLCUSTOMER
                   , :HOME-PHONE     OF DCLCUSTOMER
                                      :WS-NI-HOME-PHONE
                   , :CELL-PHONE     OF DCLCUSTOMER
                                      :WS-NI-CELL
                   , :EMAIL          OF DCLCUSTOMER
                                      :WS-NI-EMAIL
                   , :EMPLOYER-NAME  OF DCLCUSTOMER
                                      :WS-NI-EMPLOYER
                   , :ANNUAL-INCOME  OF DCLCUSTOMER
                                      :WS-NI-INCOME
                   , :CUSTOMER-TYPE  OF DCLCUSTOMER
                   , :SOURCE-CODE    OF DCLCUSTOMER
                                      :WS-NI-SOURCE
                   , :SSN-LAST4      OF DCLCUSTOMER
                                      :WS-NI-SSN4
                   , :DRIVERS-LICENSE OF DCLCUSTOMER
                                      :WS-NI-DL
                   , :ASSIGNED-SALES OF DCLCUSTOMER
                                      :WS-NI-ASSIGNED
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID =
                      :WS-PC-CUST-ID(WS-SELECT-IDX)
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-IO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON CUSTOMER DETAIL LOOKUP'
                   TO WS-IO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
      *    FORMAT DETAIL OUTPUT
      *
           MOVE CUSTOMER-ID OF DCLCUSTOMER TO WS-IO-DET-ID
           MOVE CUSTOMER-TYPE OF DCLCUSTOMER TO WS-IO-DET-TYPE
           MOVE SOURCE-CODE OF DCLCUSTOMER TO WS-IO-DET-SOURCE
      *
           STRING LAST-NAME-TX OF DCLCUSTOMER DELIMITED BY '  '
                  ', '       DELIMITED BY SIZE
                  FIRST-NAME-TX OF DCLCUSTOMER DELIMITED BY '  '
                  ' '        DELIMITED BY SIZE
                  MIDDLE-INIT OF DCLCUSTOMER DELIMITED BY SIZE
               INTO WS-IO-DET-FULLNAME
           END-STRING
      *
           MOVE ADDRESS-LINE1-TX OF DCLCUSTOMER
               TO WS-IO-DET-ADDRESS1
           IF WS-NI-ADDR2 >= +0
               MOVE ADDRESS-LINE2-TX OF DCLCUSTOMER
                   TO WS-IO-DET-ADDRESS2
           END-IF
           MOVE CITY-TX OF DCLCUSTOMER TO WS-IO-DET-CITY
           MOVE STATE-CODE OF DCLCUSTOMER TO WS-IO-DET-STATE
           MOVE ZIP-CODE OF DCLCUSTOMER TO WS-IO-DET-ZIP
      *
      *    FORMAT PHONES
      *
           IF WS-NI-HOME-PHONE >= +0
               MOVE 'FPHN' TO WS-FMT-FUNCTION
               MOVE HOME-PHONE OF DCLCUSTOMER TO WS-FMT-INPUT
               CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                      WS-FMT-RESULT
               MOVE WS-FMT-OUTPUT(1:14) TO WS-IO-DET-HOME-PH
           END-IF
      *
           IF WS-NI-CELL >= +0
               MOVE 'FPHN' TO WS-FMT-FUNCTION
               MOVE CELL-PHONE OF DCLCUSTOMER TO WS-FMT-INPUT
               CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                      WS-FMT-RESULT
               MOVE WS-FMT-OUTPUT(1:14) TO WS-IO-DET-CELL-PH
           END-IF
      *
           IF WS-NI-EMAIL >= +0
               MOVE EMAIL-TX OF DCLCUSTOMER TO WS-IO-DET-EMAIL
           END-IF
      *
           IF WS-NI-EMPLOYER >= +0
               MOVE EMPLOYER-NAME-TX OF DCLCUSTOMER
                   TO WS-IO-DET-EMPLOYER
           END-IF
      *
           IF WS-NI-INCOME >= +0
               MOVE ANNUAL-INCOME OF DCLCUSTOMER
                   TO WS-IO-DET-INCOME
           END-IF
      *
           IF WS-NI-DL >= +0
               MOVE DRIVERS-LICENSE-TX OF DCLCUSTOMER
                   TO WS-IO-DET-DL
           END-IF
      *
      *    SSN MASK - SHOW AS ***-XX-XXXX
      *
           IF WS-NI-SSN4 >= +0
               MOVE 'MSSN' TO WS-FMT-FUNCTION
               MOVE SSN-LAST4 OF DCLCUSTOMER TO WS-FMT-INPUT
               CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                      WS-FMT-RESULT
               MOVE WS-FMT-OUTPUT(1:8) TO WS-IO-DET-SSN4
           END-IF
      *
           IF WS-NI-ASSIGNED >= +0
               MOVE ASSIGNED-SALES OF DCLCUSTOMER
                   TO WS-IO-DET-SALES
           END-IF
      *
           MOVE 'CUSTOMER DETAIL DISPLAYED'
               TO WS-IO-MSG-TEXT
           .
       5000-EXIT.
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
               MOVE 'CSIQ' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSINQ00                                              *
      ****************************************************************
