       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMLGEL0.
      ****************************************************************
      * PROGRAM:   COMLGEL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   AUDIT LOGGING MODULE. INSERTS AUDIT TRAIL         *
      *            RECORDS INTO THE AUDIT_LOG DB2 TABLE FOR ALL      *
      *            DATA CHANGES ACROSS THE AUTOSALES SYSTEM.          *
      *            AUDIT FAILURES DO NOT ABEND THE CALLER.            *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMLGEL0' USING LK-AUD-USER-ID                      *
      *                         LK-AUD-PROGRAM-ID                    *
      *                         LK-AUD-ACTION-TYPE                   *
      *                         LK-AUD-TABLE-NAME                    *
      *                         LK-AUD-KEY-VALUE                     *
      *                         LK-AUD-OLD-VALUE                     *
      *                         LK-AUD-NEW-VALUE                     *
      *                         LK-AUD-RETURN-CODE                   *
      *                         LK-AUD-ERROR-MSG                     *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - AUDIT RECORD WRITTEN SUCCESSFULLY                     *
      *   04 - WARNING: AUDIT WRITE FAILED (NON-FATAL)              *
      *                                                              *
      * DESIGN NOTE:                                                 *
      *   AUDIT FAILURE MUST NEVER CAUSE THE CALLING TRANSACTION     *
      *   TO ABEND. THIS MODULE TRAPS ALL ERRORS AND RETURNS A      *
      *   WARNING CODE. THE CALLER CAN CHOOSE TO LOG THE WARNING    *
      *   OR PROCEED WITHOUT THE AUDIT RECORD.                       *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMLGEL0'.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR AUDIT_LOG TABLE
      *
           COPY DCLAUDIT.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-SAVED-SQLCODE    PIC S9(09) COMP VALUE 0.
           05  WS-SAVED-SQLSTATE   PIC X(05)  VALUE SPACES.
           05  WS-SAVED-SQLERRMC   PIC X(70)  VALUE SPACES.
           05  WS-INSERT-ATTEMPTS  PIC 9(02)  VALUE 0.
           05  WS-MAX-ATTEMPTS     PIC 9(02)  VALUE 3.
           05  WS-RETRY-FLAG       PIC X(01)  VALUE 'N'.
               88  WS-SHOULD-RETRY          VALUE 'Y'.
               88  WS-NO-RETRY              VALUE 'N'.
      *
      *    CURRENT TIMESTAMP WORK FIELDS
      *
       01  WS-TIMESTAMP-WORK.
           05  WS-TS-DATE-TIME.
               10  WS-TS-YYYY     PIC 9(04).
               10  WS-TS-MM       PIC 9(02).
               10  WS-TS-DD       PIC 9(02).
               10  WS-TS-HH       PIC 9(02).
               10  WS-TS-MN       PIC 9(02).
               10  WS-TS-SS       PIC 9(02).
               10  WS-TS-HS       PIC 9(02).
           05  WS-TS-FORMATTED    PIC X(26)  VALUE SPACES.
      *
      *    NULL INDICATORS FOR NULLABLE COLUMNS
      *
       01  WS-NULL-INDICATORS.
           05  NI-TABLE-NAME      PIC S9(04) COMP VALUE 0.
           05  NI-KEY-VALUE       PIC S9(04) COMP VALUE 0.
           05  NI-OLD-VALUE       PIC S9(04) COMP VALUE 0.
           05  NI-NEW-VALUE       PIC S9(04) COMP VALUE 0.
      *
      *    VALID ACTION TYPES
      *
       01  WS-VALID-ACTIONS.
           05  WS-ACTION-TABLE.
               10  FILLER         PIC X(03) VALUE 'INS'.
               10  FILLER         PIC X(03) VALUE 'UPD'.
               10  FILLER         PIC X(03) VALUE 'DEL'.
               10  FILLER         PIC X(03) VALUE 'INQ'.
               10  FILLER         PIC X(03) VALUE 'APR'.
               10  FILLER         PIC X(03) VALUE 'REJ'.
               10  FILLER         PIC X(03) VALUE 'PRT'.
               10  FILLER         PIC X(03) VALUE 'LON'.
               10  FILLER         PIC X(03) VALUE 'LOF'.
               10  FILLER         PIC X(03) VALUE 'XFR'.
               10  FILLER         PIC X(03) VALUE 'CAN'.
               10  FILLER         PIC X(03) VALUE 'SUB'.
           05  WS-ACTION-TBL-R REDEFINES WS-ACTION-TABLE.
               10  WS-ACTION-ENTRY PIC X(03) OCCURS 12 TIMES.
           05  WS-ACTION-IDX      PIC 9(02) VALUE 0.
           05  WS-ACTION-VALID    PIC X(01) VALUE 'N'.
               88  WS-IS-VALID-ACTION      VALUE 'Y'.
               88  WS-NOT-VALID-ACTION     VALUE 'N'.
      *
       LINKAGE SECTION.
      *
       01  LK-AUD-USER-ID         PIC X(08).
       01  LK-AUD-PROGRAM-ID      PIC X(08).
       01  LK-AUD-ACTION-TYPE     PIC X(03).
       01  LK-AUD-TABLE-NAME      PIC X(30).
       01  LK-AUD-KEY-VALUE       PIC X(50).
       01  LK-AUD-OLD-VALUE       PIC X(200).
       01  LK-AUD-NEW-VALUE       PIC X(200).
       01  LK-AUD-RETURN-CODE     PIC S9(04) COMP.
       01  LK-AUD-ERROR-MSG       PIC X(50).
      *
       PROCEDURE DIVISION USING LK-AUD-USER-ID
                                LK-AUD-PROGRAM-ID
                                LK-AUD-ACTION-TYPE
                                LK-AUD-TABLE-NAME
                                LK-AUD-KEY-VALUE
                                LK-AUD-OLD-VALUE
                                LK-AUD-NEW-VALUE
                                LK-AUD-RETURN-CODE
                                LK-AUD-ERROR-MSG.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-AUD-RETURN-CODE
           MOVE SPACES TO LK-AUD-ERROR-MSG
      *
           PERFORM 1000-VALIDATE-INPUT
           IF LK-AUD-RETURN-CODE NOT = ZEROS
               GO TO 0000-EXIT
           END-IF
      *
           PERFORM 2000-BUILD-AUDIT-RECORD
      *
           PERFORM 3000-INSERT-AUDIT-LOG
      *
       0000-EXIT.
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - VALIDATE INPUT PARAMETERS                               *
      *        MINIMUM REQUIRED: USER-ID, PROGRAM-ID, ACTION-TYPE      *
      *---------------------------------------------------------------*
       1000-VALIDATE-INPUT.
      *
      *    USER ID IS REQUIRED
      *
           IF LK-AUD-USER-ID = SPACES OR LOW-VALUES
               MOVE +4 TO LK-AUD-RETURN-CODE
               MOVE 'AUDIT: USER ID IS REQUIRED'
                   TO LK-AUD-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
      *    PROGRAM ID IS REQUIRED
      *
           IF LK-AUD-PROGRAM-ID = SPACES OR LOW-VALUES
               MOVE +4 TO LK-AUD-RETURN-CODE
               MOVE 'AUDIT: PROGRAM ID IS REQUIRED'
                   TO LK-AUD-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
      *    VALIDATE ACTION TYPE AGAINST KNOWN VALUES
      *
           MOVE 'N' TO WS-ACTION-VALID
           PERFORM VARYING WS-ACTION-IDX FROM 1 BY 1
               UNTIL WS-ACTION-IDX > 12
               OR WS-IS-VALID-ACTION
               IF LK-AUD-ACTION-TYPE =
                  WS-ACTION-ENTRY(WS-ACTION-IDX)
                   MOVE 'Y' TO WS-ACTION-VALID
               END-IF
           END-PERFORM
      *
           IF WS-NOT-VALID-ACTION
               MOVE +4 TO LK-AUD-RETURN-CODE
               STRING 'AUDIT: INVALID ACTION TYPE: '
                      LK-AUD-ACTION-TYPE
                      DELIMITED BY SIZE
                   INTO LK-AUD-ERROR-MSG
           END-IF
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - BUILD THE AUDIT LOG RECORD FROM INPUT PARAMETERS        *
      *        SET UP HOST VARIABLES AND NULL INDICATORS                *
      *---------------------------------------------------------------*
       2000-BUILD-AUDIT-RECORD.
      *
      *    SET HOST VARIABLES FOR INSERT
      *
           MOVE LK-AUD-USER-ID    TO USER-ID     OF DCLAUDIT-LOG
           MOVE LK-AUD-PROGRAM-ID TO PROGRAM-ID  OF DCLAUDIT-LOG
           MOVE LK-AUD-ACTION-TYPE TO ACTION-TYPE OF DCLAUDIT-LOG
      *
      *    TABLE NAME (VARCHAR)
      *
           IF LK-AUD-TABLE-NAME NOT = SPACES
               MOVE LK-AUD-TABLE-NAME TO TABLE-NAME-TX
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(LK-AUD-TABLE-NAME TRAILING))
                   TO TABLE-NAME-LN
               MOVE 0 TO NI-TABLE-NAME
           ELSE
               MOVE 0 TO TABLE-NAME-LN
               MOVE -1 TO NI-TABLE-NAME
           END-IF
      *
      *    KEY VALUE (VARCHAR)
      *
           IF LK-AUD-KEY-VALUE NOT = SPACES
               MOVE LK-AUD-KEY-VALUE TO KEY-VALUE-TX
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(LK-AUD-KEY-VALUE TRAILING))
                   TO KEY-VALUE-LN
               MOVE 0 TO NI-KEY-VALUE
           ELSE
               MOVE 0 TO KEY-VALUE-LN
               MOVE -1 TO NI-KEY-VALUE
           END-IF
      *
      *    OLD VALUE (VARCHAR) - SET NULL IF BLANK
      *
           IF LK-AUD-OLD-VALUE NOT = SPACES
               MOVE LK-AUD-OLD-VALUE TO OLD-VALUE-TX
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(LK-AUD-OLD-VALUE TRAILING))
                   TO OLD-VALUE-LN
               MOVE 0 TO NI-OLD-VALUE
           ELSE
               MOVE 0 TO OLD-VALUE-LN
               MOVE -1 TO NI-OLD-VALUE
           END-IF
      *
      *    NEW VALUE (VARCHAR) - SET NULL IF BLANK
      *
           IF LK-AUD-NEW-VALUE NOT = SPACES
               MOVE LK-AUD-NEW-VALUE TO NEW-VALUE-TX
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(LK-AUD-NEW-VALUE TRAILING))
                   TO NEW-VALUE-LN
               MOVE 0 TO NI-NEW-VALUE
           ELSE
               MOVE 0 TO NEW-VALUE-LN
               MOVE -1 TO NI-NEW-VALUE
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - INSERT AUDIT LOG RECORD INTO DB2                        *
      *        RETRIES ON DEADLOCK/TIMEOUT (UP TO 3 ATTEMPTS)          *
      *        NEVER ABENDS - SETS WARNING CODE ON FAILURE             *
      *---------------------------------------------------------------*
       3000-INSERT-AUDIT-LOG.
      *
           MOVE 0 TO WS-INSERT-ATTEMPTS
           MOVE 'Y' TO WS-RETRY-FLAG
      *
           PERFORM UNTIL WS-NO-RETRY
               OR WS-INSERT-ATTEMPTS >= WS-MAX-ATTEMPTS
      *
               ADD 1 TO WS-INSERT-ATTEMPTS
               MOVE 'N' TO WS-RETRY-FLAG
      *
               EXEC SQL
                   INSERT INTO AUTOSALE.AUDIT_LOG
                   ( USER_ID,
                     PROGRAM_ID,
                     ACTION_TYPE,
                     TABLE_NAME,
                     KEY_VALUE,
                     OLD_VALUE,
                     NEW_VALUE,
                     AUDIT_TS
                   )
                   VALUES
                   ( :USER-ID     OF DCLAUDIT-LOG,
                     :PROGRAM-ID  OF DCLAUDIT-LOG,
                     :ACTION-TYPE OF DCLAUDIT-LOG,
                     :TABLE-NAME  :NI-TABLE-NAME,
                     :KEY-VALUE   :NI-KEY-VALUE,
                     :OLD-VALUE   :NI-OLD-VALUE,
                     :NEW-VALUE   :NI-NEW-VALUE,
                     CURRENT TIMESTAMP
                   )
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
      *                SUCCESS
                       MOVE 'N' TO WS-RETRY-FLAG
                   WHEN -911
                   WHEN -913
      *                DEADLOCK OR TIMEOUT - RETRY
                       MOVE 'Y' TO WS-RETRY-FLAG
                       MOVE SQLCODE  TO WS-SAVED-SQLCODE
                       MOVE SQLSTATE TO WS-SAVED-SQLSTATE
                   WHEN OTHER
      *                ANY OTHER ERROR - DO NOT RETRY
                       MOVE 'N' TO WS-RETRY-FLAG
                       MOVE SQLCODE  TO WS-SAVED-SQLCODE
                       MOVE SQLSTATE TO WS-SAVED-SQLSTATE
                       MOVE SQLERRMC TO WS-SAVED-SQLERRMC
               END-EVALUATE
      *
           END-PERFORM
      *
      *    CHECK FINAL STATUS
      *
           IF SQLCODE NOT = 0
               MOVE +4 TO LK-AUD-RETURN-CODE
               PERFORM 3100-FORMAT-ERROR-MSG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3100 - FORMAT ERROR MESSAGE FOR AUDIT INSERT FAILURE           *
      *        IMPORTANT: NEVER ABEND - JUST REPORT THE WARNING        *
      *---------------------------------------------------------------*
       3100-FORMAT-ERROR-MSG.
      *
           EVALUATE WS-SAVED-SQLCODE
               WHEN -803
                   MOVE 'AUDIT: DUPLICATE KEY ON INSERT'
                       TO LK-AUD-ERROR-MSG
               WHEN -904
                   MOVE 'AUDIT: TABLE UNAVAILABLE'
                       TO LK-AUD-ERROR-MSG
               WHEN -911
               WHEN -913
                   MOVE 'AUDIT: DEADLOCK/TIMEOUT AFTER RETRIES'
                       TO LK-AUD-ERROR-MSG
               WHEN OTHER
                   STRING 'AUDIT: SQL ERROR '
                          WS-SAVED-SQLCODE
                          ' STATE='
                          WS-SAVED-SQLSTATE
                          DELIMITED BY SIZE
                       INTO LK-AUD-ERROR-MSG
           END-EVALUATE
           .
       3100-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMLGEL0                                              *
      ****************************************************************
