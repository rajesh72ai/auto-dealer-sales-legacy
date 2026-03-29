       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMSEQL0.
      ****************************************************************
      * PROGRAM:  COMSEQL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - SEQUENCE NUMBER GENERATOR MODULE          *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  GENERATES UNIQUE FORMATTED SEQUENCE NUMBERS FOR    *
      *           DEALS, REGISTRATIONS, FINANCE APPS, TRANSFERS,     *
      *           AND SHIPMENTS. USES DB2 SELECT FOR UPDATE TO       *
      *           HANDLE CONCURRENT ACCESS.                          *
      * CALLABLE: YES - VIA CALL 'COMSEQL0' USING LS-SEQ-REQUEST    *
      *                                            LS-SEQ-RESULT     *
      * TABLES:   AUTOSALE.SYSTEM_CONFIG                             *
      *           CONFIG_KEY VALUES:                                  *
      *           - NEXT_DEAL_NUM    (DEALS)                         *
      *           - NEXT_REG_NUM     (REGISTRATIONS)                 *
      *           - NEXT_FIN_NUM     (FINANCE APPLICATIONS)          *
      *           - NEXT_TRAN_NUM    (TRANSFERS)                     *
      *           - NEXT_SHIP_NUM    (SHIPMENTS)                     *
      * FORMAT:   D-XXXXX, R-XXXXX, F-XXXXX, T-XXXXX, S-XXXXX      *
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
                                          VALUE 'COMSEQL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    COPY IN SQLCA FOR DB2 OPERATIONS
      *
           COPY WSSQLCA.
      *
      *    COPY IN SYSTEM_CONFIG DCLGEN
      *
           COPY DCLSYSCF.
      *
      *    SEQUENCE TYPE TABLE
      *
       01  WS-SEQ-TYPE-TABLE.
           05  FILLER PIC X(44) VALUE
               'DEAL NEXT_DEAL_NUM                    D-'.
           05  FILLER PIC X(44) VALUE
               'REG  NEXT_REG_NUM                     R-'.
           05  FILLER PIC X(44) VALUE
               'FIN  NEXT_FIN_NUM                     F-'.
           05  FILLER PIC X(44) VALUE
               'TRAN NEXT_TRAN_NUM                    T-'.
           05  FILLER PIC X(44) VALUE
               'SHIP NEXT_SHIP_NUM                    S-'.
       01  WS-SEQ-TYPE-ENTRIES REDEFINES WS-SEQ-TYPE-TABLE.
           05  WS-SEQ-TYPE-ENTRY         OCCURS 5 TIMES.
               10  WS-SEQ-TYPE-CODE      PIC X(04).
               10  FILLER                PIC X(01).
               10  WS-SEQ-CONFIG-KEY     PIC X(30).
               10  FILLER                PIC X(07).
               10  WS-SEQ-PREFIX         PIC X(02).
      *
      *    WORK FIELDS
      *
       01  WS-SEQ-WORK-FIELDS.
           05  WS-FOUND-INDEX            PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-SEARCH-INDEX           PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-CURRENT-VALUE          PIC S9(09)   COMP
                                                       VALUE +0.
           05  WS-NEXT-VALUE             PIC S9(09)   COMP
                                                       VALUE +0.
           05  WS-SEQ-NUMBER-DISP        PIC 9(05)    VALUE ZEROS.
           05  WS-FORMATTED-NUMBER       PIC X(07)    VALUE SPACES.
           05  WS-CONFIG-KEY-WORK        PIC X(30)    VALUE SPACES.
           05  WS-CONFIG-VALUE-WORK      PIC X(100)   VALUE SPACES.
           05  WS-RETRY-COUNT            PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-MAX-RETRIES            PIC S9(04)   COMP
                                                       VALUE +3.
      *
      *    DATE/TIME FOR UPDATED_TS
      *
       01  WS-DATETIME-FIELDS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURR-YYYY          PIC 9(04).
               10  WS-CURR-MM            PIC 9(02).
               10  WS-CURR-DD            PIC 9(02).
           05  WS-CURRENT-TIME-DATA.
               10  WS-CURR-HH            PIC 9(02).
               10  WS-CURR-MN            PIC 9(02).
               10  WS-CURR-SS            PIC 9(02).
               10  WS-CURR-HS            PIC 9(02).
           05  WS-DIFF-FROM-GMT          PIC S9(04).
           05  WS-FORMATTED-TS           PIC X(26)    VALUE SPACES.
      *
       LINKAGE SECTION.
      *
      *    SEQUENCE NUMBER REQUEST
      *
       01  LS-SEQ-REQUEST.
           05  LS-SR-SEQ-TYPE            PIC X(04).
               88  LS-SR-TYPE-DEAL                     VALUE 'DEAL'.
               88  LS-SR-TYPE-REG                      VALUE 'REG '.
               88  LS-SR-TYPE-FIN                      VALUE 'FIN '.
               88  LS-SR-TYPE-TRAN                     VALUE 'TRAN'.
               88  LS-SR-TYPE-SHIP                     VALUE 'SHIP'.
           05  LS-SR-DEALER-CODE         PIC X(05).
           05  LS-SR-USER-ID             PIC X(08).
      *
      *    SEQUENCE NUMBER RESULT
      *
       01  LS-SEQ-RESULT.
           05  LS-SQ-RETURN-CODE         PIC S9(04)   COMP.
           05  LS-SQ-RETURN-MSG          PIC X(79).
           05  LS-SQ-RAW-NUMBER          PIC S9(09)   COMP.
           05  LS-SQ-FORMATTED-NUM       PIC X(07).
           05  LS-SQ-SQLCODE             PIC S9(09)   COMP.
      *
       PROCEDURE DIVISION USING LS-SEQ-REQUEST
                                LS-SEQ-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-VALIDATE-INPUTS
      *
           IF LS-SQ-RETURN-CODE = +0
               PERFORM 3000-LOOKUP-SEQ-TYPE
           END-IF
      *
           IF LS-SQ-RETURN-CODE = +0
               PERFORM 4000-GET-NEXT-SEQUENCE
           END-IF
      *
           IF LS-SQ-RETURN-CODE = +0
               PERFORM 5000-FORMAT-NUMBER
           END-IF
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR RESULT AND GET TIMESTAMP          *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-SEQ-RESULT
           MOVE +0 TO LS-SQ-RETURN-CODE
           MOVE +0 TO WS-FOUND-INDEX
           MOVE +0 TO WS-RETRY-COUNT
      *
      *    GET CURRENT TIMESTAMP
      *
           MOVE FUNCTION CURRENT-DATE
               TO WS-CURRENT-DATE-DATA
                  WS-CURRENT-TIME-DATA
                  WS-DIFF-FROM-GMT
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD   '-'
                  WS-CURR-HH   '.'
                  WS-CURR-MN   '.'
                  WS-CURR-SS   '.000000'
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-TS
           .
      *
      ****************************************************************
      *    2000-VALIDATE-INPUTS - VALIDATE SEQUENCE TYPE             *
      ****************************************************************
       2000-VALIDATE-INPUTS.
      *
           IF  NOT LS-SR-TYPE-DEAL
           AND NOT LS-SR-TYPE-REG
           AND NOT LS-SR-TYPE-FIN
           AND NOT LS-SR-TYPE-TRAN
           AND NOT LS-SR-TYPE-SHIP
               MOVE +8 TO LS-SQ-RETURN-CODE
               STRING 'COMSEQL0: INVALID SEQUENCE TYPE: '
                      LS-SR-SEQ-TYPE
                      DELIMITED BY SIZE
                      INTO LS-SQ-RETURN-MSG
           END-IF
      *
           IF LS-SR-DEALER-CODE = SPACES
               MOVE +8 TO LS-SQ-RETURN-CODE
               MOVE 'COMSEQL0: DEALER CODE IS REQUIRED'
                   TO LS-SQ-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    3000-LOOKUP-SEQ-TYPE - FIND CONFIG KEY FOR SEQ TYPE       *
      ****************************************************************
       3000-LOOKUP-SEQ-TYPE.
      *
           MOVE +0 TO WS-FOUND-INDEX
      *
           PERFORM VARYING WS-SEARCH-INDEX
               FROM +1 BY +1
               UNTIL WS-SEARCH-INDEX > +5
               OR    WS-FOUND-INDEX > +0
      *
               IF WS-SEQ-TYPE-CODE(WS-SEARCH-INDEX)
                   = LS-SR-SEQ-TYPE
                   MOVE WS-SEARCH-INDEX TO WS-FOUND-INDEX
               END-IF
      *
           END-PERFORM
      *
           IF WS-FOUND-INDEX = +0
               MOVE +8 TO LS-SQ-RETURN-CODE
               MOVE 'COMSEQL0: SEQUENCE TYPE NOT IN LOOKUP TABLE'
                   TO LS-SQ-RETURN-MSG
           ELSE
               MOVE WS-SEQ-CONFIG-KEY(WS-FOUND-INDEX)
                   TO WS-CONFIG-KEY-WORK
           END-IF
           .
      *
      ****************************************************************
      *    4000-GET-NEXT-SEQUENCE - READ AND INCREMENT IN DB2        *
      *    USES SELECT FOR UPDATE TO SERIALIZE CONCURRENT ACCESS     *
      ****************************************************************
       4000-GET-NEXT-SEQUENCE.
      *
           MOVE +0 TO WS-RETRY-COUNT
      *
           PERFORM 4100-FETCH-AND-UPDATE
      *
      *    RETRY LOGIC FOR DEADLOCK/TIMEOUT (-911, -913)
      *
           PERFORM UNTIL WS-RETRY-COUNT >= WS-MAX-RETRIES
               OR LS-SQ-RETURN-CODE = +0
               OR (LS-SQ-SQLCODE NOT = -911
                   AND LS-SQ-SQLCODE NOT = -913)
      *
               ADD +1 TO WS-RETRY-COUNT
               PERFORM 4100-FETCH-AND-UPDATE
      *
           END-PERFORM
           .
      *
      ****************************************************************
      *    4100-FETCH-AND-UPDATE - SINGLE ATTEMPT TO GET SEQUENCE    *
      ****************************************************************
       4100-FETCH-AND-UPDATE.
      *
      *    SELECT FOR UPDATE TO LOCK THE ROW
      *
           MOVE FUNCTION LENGTH(WS-CONFIG-KEY-WORK)
               TO CONFIG-KEY-LN
           MOVE WS-CONFIG-KEY-WORK TO CONFIG-KEY-TX
      *
           EXEC SQL
               SELECT CONFIG_VALUE
               INTO   :CONFIG-VALUE
               FROM   AUTOSALE.SYSTEM_CONFIG
               WHERE  CONFIG_KEY = :CONFIG-KEY
               FOR UPDATE OF CONFIG_VALUE
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
      *            ROW FOUND - PARSE CURRENT VALUE
                   MOVE CONFIG-VALUE-TX(1:CONFIG-VALUE-LN)
                       TO WS-CONFIG-VALUE-WORK
      *
      *            CONVERT TO NUMERIC
      *
                   COMPUTE WS-CURRENT-VALUE =
                       FUNCTION NUMVAL(WS-CONFIG-VALUE-WORK)
                   END-COMPUTE
      *
      *            INCREMENT
      *
                   ADD +1 TO WS-CURRENT-VALUE
                       GIVING WS-NEXT-VALUE
      *
      *            CHECK FOR OVERFLOW (MAX 99999)
      *
                   IF WS-NEXT-VALUE > +99999
                       MOVE +12 TO LS-SQ-RETURN-CODE
                       MOVE
                       'COMSEQL0: SEQUENCE OVERFLOW - MAX 99999'
                           TO LS-SQ-RETURN-MSG
                   ELSE
      *                UPDATE WITH NEW VALUE
                       MOVE WS-NEXT-VALUE TO WS-SEQ-NUMBER-DISP
                       MOVE WS-SEQ-NUMBER-DISP
                           TO CONFIG-VALUE-TX
                       MOVE +5 TO CONFIG-VALUE-LN
      *
                       MOVE +8 TO UPDATED-BY(1:8)
                       IF LS-SR-USER-ID NOT = SPACES
                           MOVE LS-SR-USER-ID TO UPDATED-BY
                       ELSE
                           MOVE 'COMSEQL0' TO UPDATED-BY
                       END-IF
      *
                       MOVE WS-FORMATTED-TS TO UPDATED-TS
      *
                       EXEC SQL
                           UPDATE AUTOSALE.SYSTEM_CONFIG
                              SET CONFIG_VALUE = :CONFIG-VALUE
                                , UPDATED_BY   = :UPDATED-BY
                                , UPDATED_TS   = :UPDATED-TS
                           WHERE  CONFIG_KEY   = :CONFIG-KEY
                       END-EXEC
      *
                       IF SQLCODE = +0
                           MOVE WS-NEXT-VALUE
                               TO LS-SQ-RAW-NUMBER
                           MOVE +0 TO LS-SQ-RETURN-CODE
                       ELSE
                           MOVE SQLCODE TO LS-SQ-SQLCODE
                           MOVE +12 TO LS-SQ-RETURN-CODE
                           MOVE
                          'COMSEQL0: DB2 ERROR ON UPDATE'
                               TO LS-SQ-RETURN-MSG
                       END-IF
                   END-IF
      *
               WHEN +100
      *            CONFIG KEY NOT FOUND
                   MOVE +8 TO LS-SQ-RETURN-CODE
                   STRING 'COMSEQL0: CONFIG KEY NOT FOUND: '
                          WS-CONFIG-KEY-WORK
                          DELIMITED BY SIZE
                          INTO LS-SQ-RETURN-MSG
      *
               WHEN -911
               WHEN -913
      *            DEADLOCK OR TIMEOUT - CALLER WILL RETRY
                   MOVE SQLCODE TO LS-SQ-SQLCODE
                   MOVE +4 TO LS-SQ-RETURN-CODE
                   MOVE 'COMSEQL0: DEADLOCK/TIMEOUT - RETRYING'
                       TO LS-SQ-RETURN-MSG
      *
               WHEN OTHER
                   MOVE SQLCODE TO LS-SQ-SQLCODE
                   MOVE +16 TO LS-SQ-RETURN-CODE
                   MOVE 'COMSEQL0: DB2 ERROR ON SELECT FOR UPDATE'
                       TO LS-SQ-RETURN-MSG
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-FORMAT-NUMBER - FORMAT WITH PREFIX                   *
      *    D-XXXXX, R-XXXXX, F-XXXXX, T-XXXXX, S-XXXXX             *
      ****************************************************************
       5000-FORMAT-NUMBER.
      *
           MOVE LS-SQ-RAW-NUMBER TO WS-SEQ-NUMBER-DISP
      *
           STRING WS-SEQ-PREFIX(WS-FOUND-INDEX)
                  WS-SEQ-NUMBER-DISP
                  DELIMITED BY SIZE
                  INTO WS-FORMATTED-NUMBER
      *
           MOVE WS-FORMATTED-NUMBER TO LS-SQ-FORMATTED-NUM
      *
           MOVE +0 TO LS-SQ-RETURN-CODE
           MOVE 'COMSEQL0: SEQUENCE NUMBER GENERATED SUCCESSFULLY'
               TO LS-SQ-RETURN-MSG
           .
      ****************************************************************
      * END OF COMSEQL0                                               *
      ****************************************************************
