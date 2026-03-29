       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSLST00.
      ****************************************************************
      * PROGRAM:  CUSLST00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - LISTING / BROWSE ALL CUSTOMERS          *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  BROWSE ALL CUSTOMERS FOR A DEALER WITH SORT        *
      *           OPTIONS (NAME, DATE, TYPE). DISPLAYS 15 PER PAGE   *
      *           WITH PF7/PF8 PAGING. SHOWS TOTAL COUNT AT BOTTOM.  *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSLS - CUSTOMER LIST                               *
      * CALLS:    COMFMTL0 - FORMAT PHONE                           *
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
                                          VALUE 'CUSLST00'.
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
       01  WS-LST-INPUT.
           05  WS-LI-FUNCTION            PIC X(02).
               88  WS-LI-LIST                        VALUE 'LS'.
               88  WS-LI-NEXT-PAGE                   VALUE 'NX'.
               88  WS-LI-PREV-PAGE                   VALUE 'PV'.
           05  WS-LI-DEALER-CODE         PIC X(05).
           05  WS-LI-SORT-BY             PIC X(02).
               88  WS-LI-SORT-NAME                   VALUE 'NM'.
               88  WS-LI-SORT-DATE                   VALUE 'DT'.
               88  WS-LI-SORT-TYPE                   VALUE 'TY'.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-LST-OUTPUT.
           05  WS-LO-STATUS-LINE.
               10  WS-LO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-LO-MSG-TEXT       PIC X(70).
           05  WS-LO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-LO-HEADER.
               10  FILLER               PIC X(33)
                   VALUE '---- CUSTOMER LISTING ----       '.
               10  FILLER               PIC X(10) VALUE 'DEALER:   '.
               10  WS-LO-DEALER         PIC X(05).
               10  FILLER               PIC X(07) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'PAGE: '.
               10  WS-LO-PAGE-NUM       PIC Z9.
               10  FILLER               PIC X(04) VALUE ' OF '.
               10  WS-LO-PAGE-TOT       PIC Z9.
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-LO-COL-HDR.
               10  FILLER               PIC X(10) VALUE 'CUST ID   '.
               10  FILLER               PIC X(22)
                   VALUE 'NAME                  '.
               10  FILLER               PIC X(15)
                   VALUE 'PHONE          '.
               10  FILLER               PIC X(02) VALUE 'TY'.
               10  FILLER               PIC X(01) VALUE SPACE.
               10  FILLER               PIC X(04) VALUE 'SRC '.
               10  FILLER               PIC X(12)
                   VALUE 'CREATED     '.
               10  FILLER               PIC X(13) VALUE SPACES.
           05  WS-LO-SEPARATOR           PIC X(79) VALUE ALL '-'.
           05  WS-LO-LIST-LINES.
               10  WS-LO-LIST-LINE       OCCURS 15 TIMES.
                   15  WS-LO-LL-ID       PIC Z(08)9.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-NAME     PIC X(22).
                   15  WS-LO-LL-PHONE    PIC X(14).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-TYPE     PIC X(01).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-LO-LL-SOURCE   PIC X(03).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-LO-LL-CREATED  PIC X(10).
                   15  FILLER            PIC X(14) VALUE SPACES.
           05  WS-LO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-LO-TOTAL-LINE.
               10  FILLER               PIC X(20) VALUE
                   'TOTAL CUSTOMERS:    '.
               10  WS-LO-TOTAL-COUNT    PIC Z(06)9.
               10  FILLER               PIC X(06) VALUE SPACES.
               10  FILLER               PIC X(09) VALUE
                   'SORT BY: '.
               10  WS-LO-SORT-DESC      PIC X(10).
               10  FILLER               PIC X(27) VALUE SPACES.
           05  WS-LO-NAV-LINE.
               10  FILLER               PIC X(50)
                   VALUE 'PF7=PREV PAGE  PF8=NEXT PAGE  PF3=EXIT
      -               '         '.
               10  FILLER               PIC X(29) VALUE SPACES.
           05  WS-LO-FILLER             PIC X(200) VALUE SPACES.
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
           05  WS-PAGE-SIZE             PIC S9(04) COMP VALUE +15.
      *
      *    CURSOR FETCH FIELDS
      *
       01  WS-FETCH-FIELDS.
           05  WS-CF-CUST-ID            PIC S9(09) COMP.
           05  WS-CF-FIRST-NAME         PIC X(30).
           05  WS-CF-LAST-NAME          PIC X(30).
           05  WS-CF-HOME-PHONE         PIC X(10).
           05  WS-CF-CUST-TYPE          PIC X(01).
           05  WS-CF-SOURCE             PIC X(03).
           05  WS-CF-CREATED-TS         PIC X(26).
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-HOME-PHONE         PIC S9(04) COMP VALUE +0.
           05  WS-NI-SOURCE             PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR - ORDER BY NAME
      *
           EXEC SQL
               DECLARE CSR_CUST_BY_NAME CURSOR FOR
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
                    , CUSTOMER_TYPE
                    , SOURCE_CODE
                    , CREATED_TS
               FROM   AUTOSALE.CUSTOMER
               WHERE  DEALER_CODE = :WS-LI-DEALER-CODE
               ORDER BY LAST_NAME, FIRST_NAME
           END-EXEC.
      *
      *    CURSOR - ORDER BY DATE
      *
           EXEC SQL
               DECLARE CSR_CUST_BY_DATE CURSOR FOR
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
                    , CUSTOMER_TYPE
                    , SOURCE_CODE
                    , CREATED_TS
               FROM   AUTOSALE.CUSTOMER
               WHERE  DEALER_CODE = :WS-LI-DEALER-CODE
               ORDER BY CREATED_TS DESC
           END-EXEC.
      *
      *    CURSOR - ORDER BY TYPE
      *
           EXEC SQL
               DECLARE CSR_CUST_BY_TYPE CURSOR FOR
               SELECT CUSTOMER_ID
                    , FIRST_NAME
                    , LAST_NAME
                    , HOME_PHONE
                    , CUSTOMER_TYPE
                    , SOURCE_CODE
                    , CREATED_TS
               FROM   AUTOSALE.CUSTOMER
               WHERE  DEALER_CODE = :WS-LI-DEALER-CODE
               ORDER BY CUSTOMER_TYPE, LAST_NAME
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
               PERFORM 4000-LIST-CUSTOMERS
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
           INITIALIZE WS-LST-OUTPUT
           MOVE 'CUSLST00' TO WS-LO-MSG-ID
           MOVE +1 TO WS-PAGE-NUMBER
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
               MOVE WS-INP-FUNCTION      TO WS-LI-FUNCTION
               MOVE WS-INP-BODY(1:5)     TO WS-LI-DEALER-CODE
               MOVE WS-INP-BODY(6:2)     TO WS-LI-SORT-BY
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-LI-FUNCTION = SPACES
               MOVE 'LS' TO WS-LI-FUNCTION
           END-IF
      *
           IF WS-LI-DEALER-CODE = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEALER CODE IS REQUIRED'
                   TO WS-LO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    DEFAULT SORT TO NAME
      *
           IF WS-LI-SORT-BY = SPACES
               MOVE 'NM' TO WS-LI-SORT-BY
           END-IF
      *
      *    HANDLE PAGING
      *
           IF WS-LI-NEXT-PAGE
               ADD +1 TO WS-PAGE-NUMBER
           END-IF
      *
           IF WS-LI-PREV-PAGE
               IF WS-PAGE-NUMBER > 1
                   SUBTRACT +1 FROM WS-PAGE-NUMBER
               END-IF
           END-IF
      *
           MOVE WS-LI-DEALER-CODE TO WS-LO-DEALER
      *
           EVALUATE TRUE
               WHEN WS-LI-SORT-NAME
                   MOVE 'BY NAME   ' TO WS-LO-SORT-DESC
               WHEN WS-LI-SORT-DATE
                   MOVE 'BY DATE   ' TO WS-LO-SORT-DESC
               WHEN WS-LI-SORT-TYPE
                   MOVE 'BY TYPE   ' TO WS-LO-SORT-DESC
               WHEN OTHER
                   MOVE 'NM' TO WS-LI-SORT-BY
                   MOVE 'BY NAME   ' TO WS-LO-SORT-DESC
           END-EVALUATE
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LIST-CUSTOMERS                                       *
      ****************************************************************
       4000-LIST-CUSTOMERS.
      *
      *    GET TOTAL COUNT
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO   :WS-TOTAL-COUNT
               FROM   AUTOSALE.CUSTOMER
               WHERE  DEALER_CODE = :WS-LI-DEALER-CODE
           END-EXEC
      *
           IF WS-TOTAL-COUNT = +0
               MOVE 'NO CUSTOMERS FOUND FOR THIS DEALER'
                   TO WS-LO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
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
           MOVE WS-PAGE-NUMBER TO WS-LO-PAGE-NUM
           MOVE WS-TOTAL-PAGES TO WS-LO-PAGE-TOT
           MOVE WS-TOTAL-COUNT TO WS-LO-TOTAL-COUNT
      *
      *    OPEN CURSOR BASED ON SORT
      *
           EVALUATE TRUE
               WHEN WS-LI-SORT-NAME
                   EXEC SQL OPEN CSR_CUST_BY_NAME END-EXEC
               WHEN WS-LI-SORT-DATE
                   EXEC SQL OPEN CSR_CUST_BY_DATE END-EXEC
               WHEN WS-LI-SORT-TYPE
                   EXEC SQL OPEN CSR_CUST_BY_TYPE END-EXEC
           END-EVALUATE
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'ERROR OPENING CUSTOMER LIST CURSOR'
                   TO WS-LO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    SKIP TO CURRENT PAGE OFFSET
      *
           PERFORM WS-ROWS-TO-SKIP TIMES
               PERFORM 4100-FETCH-ONE-ROW
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
           END-PERFORM
      *
      *    FETCH CURRENT PAGE OF 15 ROWS
      *
           MOVE +0 TO WS-ROWS-FETCHED
      *
           PERFORM UNTIL WS-ROWS-FETCHED >= WS-PAGE-SIZE
               PERFORM 4100-FETCH-ONE-ROW
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
      *
               MOVE WS-CF-CUST-ID TO
                   WS-LO-LL-ID(WS-ROWS-FETCHED)
      *
               STRING WS-CF-LAST-NAME DELIMITED BY '  '
                      ', '             DELIMITED BY SIZE
                      WS-CF-FIRST-NAME DELIMITED BY '  '
                   INTO WS-LO-LL-NAME(WS-ROWS-FETCHED)
               END-STRING
      *
               IF WS-NI-HOME-PHONE >= +0
                   MOVE 'FPHN' TO WS-FMT-FUNCTION
                   MOVE WS-CF-HOME-PHONE TO WS-FMT-INPUT
                   CALL 'COMFMTL0' USING WS-FMT-REQUEST
                                          WS-FMT-RESULT
                   MOVE WS-FMT-OUTPUT(1:14) TO
                       WS-LO-LL-PHONE(WS-ROWS-FETCHED)
               END-IF
      *
               MOVE WS-CF-CUST-TYPE TO
                   WS-LO-LL-TYPE(WS-ROWS-FETCHED)
               MOVE WS-CF-SOURCE TO
                   WS-LO-LL-SOURCE(WS-ROWS-FETCHED)
               MOVE WS-CF-CREATED-TS(1:10) TO
                   WS-LO-LL-CREATED(WS-ROWS-FETCHED)
           END-PERFORM
      *
      *    CLOSE CURSOR
      *
           EVALUATE TRUE
               WHEN WS-LI-SORT-NAME
                   EXEC SQL CLOSE CSR_CUST_BY_NAME END-EXEC
               WHEN WS-LI-SORT-DATE
                   EXEC SQL CLOSE CSR_CUST_BY_DATE END-EXEC
               WHEN WS-LI-SORT-TYPE
                   EXEC SQL CLOSE CSR_CUST_BY_TYPE END-EXEC
           END-EVALUATE
      *
           MOVE 'CUSTOMER LISTING COMPLETE' TO WS-LO-MSG-TEXT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-ONE-ROW                                        *
      ****************************************************************
       4100-FETCH-ONE-ROW.
      *
           EVALUATE TRUE
               WHEN WS-LI-SORT-NAME
                   EXEC SQL
                       FETCH CSR_CUST_BY_NAME
                       INTO  :WS-CF-CUST-ID
                           , :WS-CF-FIRST-NAME
                           , :WS-CF-LAST-NAME
                           , :WS-CF-HOME-PHONE
                                :WS-NI-HOME-PHONE
                           , :WS-CF-CUST-TYPE
                           , :WS-CF-SOURCE
                                :WS-NI-SOURCE
                           , :WS-CF-CREATED-TS
                   END-EXEC
               WHEN WS-LI-SORT-DATE
                   EXEC SQL
                       FETCH CSR_CUST_BY_DATE
                       INTO  :WS-CF-CUST-ID
                           , :WS-CF-FIRST-NAME
                           , :WS-CF-LAST-NAME
                           , :WS-CF-HOME-PHONE
                                :WS-NI-HOME-PHONE
                           , :WS-CF-CUST-TYPE
                           , :WS-CF-SOURCE
                                :WS-NI-SOURCE
                           , :WS-CF-CREATED-TS
                   END-EXEC
               WHEN WS-LI-SORT-TYPE
                   EXEC SQL
                       FETCH CSR_CUST_BY_TYPE
                       INTO  :WS-CF-CUST-ID
                           , :WS-CF-FIRST-NAME
                           , :WS-CF-LAST-NAME
                           , :WS-CF-HOME-PHONE
                                :WS-NI-HOME-PHONE
                           , :WS-CF-CUST-TYPE
                           , :WS-CF-SOURCE
                                :WS-NI-SOURCE
                           , :WS-CF-CREATED-TS
                   END-EXEC
           END-EVALUATE
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-LST-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'CSLS' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSLST00                                              *
      ****************************************************************
