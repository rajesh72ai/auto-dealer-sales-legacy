       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMSEC00.
      ****************************************************************
      * PROGRAM:    ADMSEC00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     ADM - ADMINISTRATION                             *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   ADMS                                             *
      * MFS MID:    MFSADMMN (SIGN-ON SCREEN)                       *
      * MFS MOD:    ASMNU00  (MAIN MENU ON SUCCESS)                  *
      *             MFSADMMN (SIGN-ON ON FAILURE)                    *
      *                                                              *
      * PURPOSE:    SECURITY / SIGN-ON PROCESSING. RECEIVES USER     *
      *             CREDENTIALS FROM THE SIGN-ON SCREEN, VALIDATES   *
      *             AGAINST THE SYSTEM_USER TABLE, AND EITHER        *
      *             GRANTS ACCESS (RETURNING THE MAIN MENU) OR       *
      *             DENIES ACCESS WITH AN APPROPRIATE ERROR.         *
      *                                                              *
      * PROCESSING: 1. GU TO RECEIVE INPUT MESSAGE                   *
      *             2. PARSE USER ID AND PASSWORD                    *
      *             3. SELECT FROM SYSTEM_USER TABLE                 *
      *             4. VALIDATE ACTIVE FLAG, LOCKED FLAG             *
      *             5. VALIDATE PASSWORD HASH                        *
      *             6. ON SUCCESS: UPDATE LAST_LOGIN_TS, RESET       *
      *                FAILED ATTEMPTS, RETURN MAIN MENU             *
      *             7. ON FAILURE: INCREMENT FAILED ATTEMPTS,        *
      *                LOCK IF >= 5, RETURN ERROR                    *
      *                                                              *
      * CALLS:      COMLGEL0 - AUDIT LOGGING                        *
      *             COMMSGL0 - MESSAGE FORMATTING                    *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'ADMSEC00'.
      *
      *    IMS FUNCTION CODES
      *
           COPY WSIOPCB.
      *
      *    DB2 SQLCA
      *
           COPY WSSQLCA.
      *
      *    DCLGEN FOR SYSTEM_USER TABLE
      *
           COPY DCLSYUSR.
      *
      *    INPUT MESSAGE LAYOUT
      *    FORMAT: LLZZ + TRAN-CODE(8) + FUNCTION(3) + DATA
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL             PIC S9(04) COMP.
           05  WS-IN-ZZ             PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE      PIC X(08).
           05  WS-IN-USER-ID        PIC X(08).
           05  WS-IN-PASSWORD       PIC X(20).
           05  FILLER               PIC X(200).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL            PIC S9(04) COMP.
           05  WS-OUT-ZZ            PIC S9(04) COMP.
           05  WS-OUT-MOD-NAME      PIC X(08).
           05  WS-OUT-USER-ID       PIC X(08).
           05  WS-OUT-USER-NAME     PIC X(40).
           05  WS-OUT-USER-TYPE     PIC X(01).
           05  WS-OUT-DEALER-CODE   PIC X(05).
           05  WS-OUT-MSG-LINE1     PIC X(79).
           05  WS-OUT-MSG-LINE2     PIC X(79).
           05  WS-OUT-STATUS        PIC X(01).
               88  WS-OUT-SUCCESS              VALUE 'S'.
               88  WS-OUT-FAILURE              VALUE 'F'.
           05  FILLER               PIC X(100).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS       PIC X(26).
           05  WS-PASSWORD-HASH    PIC X(64).
           05  WS-FAILED-COUNT     PIC S9(04) COMP VALUE 0.
           05  WS-DB-RC            PIC S9(04) COMP VALUE 0.
           05  WS-ERROR-FLAG       PIC X(01) VALUE 'N'.
               88  WS-HAS-ERROR               VALUE 'Y'.
               88  WS-NO-ERROR                VALUE 'N'.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-MAX-FAILED       PIC S9(04) COMP VALUE 5.
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
      *    MESSAGE FORMATTING FIELDS
      *
       01  WS-MSG-FIELDS.
           05  WS-MSG-TYPE         PIC X(01).
           05  WS-MSG-CODE         PIC X(08).
           05  WS-MSG-DATA1        PIC X(40).
           05  WS-MSG-DATA2        PIC X(40).
           05  WS-MSG-OUTPUT       PIC X(79).
           05  WS-MSG-RC           PIC S9(04) COMP.
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
           COPY WSIOPCB
               REPLACING ==:TAG:== BY ==LK==.
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
      *    INITIALIZE WORK AREAS
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
      *
      *    RECEIVE INPUT MESSAGE FROM TERMINAL
      *
           PERFORM 1000-RECEIVE-INPUT
      *
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR-RESPONSE
               GOBACK
           END-IF
      *
      *    VALIDATE INPUT FIELDS
      *
           PERFORM 2000-VALIDATE-INPUT
      *
           IF WS-HAS-ERROR
               PERFORM 8000-SEND-ERROR-RESPONSE
               GOBACK
           END-IF
      *
      *    LOOK UP USER IN SYSTEM_USER TABLE
      *
           PERFORM 3000-LOOKUP-USER
      *
           IF WS-HAS-ERROR
               PERFORM 9000-LOG-FAILED-ATTEMPT
               PERFORM 8000-SEND-ERROR-RESPONSE
               GOBACK
           END-IF
      *
      *    CHECK IF ACCOUNT IS ACTIVE AND NOT LOCKED
      *
           PERFORM 4000-CHECK-ACCOUNT-STATUS
      *
           IF WS-HAS-ERROR
               PERFORM 9000-LOG-FAILED-ATTEMPT
               PERFORM 8000-SEND-ERROR-RESPONSE
               GOBACK
           END-IF
      *
      *    VALIDATE PASSWORD
      *
           PERFORM 5000-VALIDATE-PASSWORD
      *
           IF WS-HAS-ERROR
               PERFORM 6000-INCREMENT-FAILED-ATTEMPTS
               PERFORM 9000-LOG-FAILED-ATTEMPT
               PERFORM 8000-SEND-ERROR-RESPONSE
               GOBACK
           END-IF
      *
      *    LOGIN SUCCESSFUL - UPDATE USER RECORD
      *
           PERFORM 7000-UPDATE-SUCCESSFUL-LOGIN
      *
      *    LOG SUCCESSFUL LOGIN
      *
           PERFORM 9100-LOG-SUCCESSFUL-LOGIN
      *
      *    SEND SUCCESS RESPONSE (MAIN MENU)
      *
           PERFORM 8500-SEND-SUCCESS-RESPONSE
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
      * 2000 - VALIDATE INPUT FIELDS                                   *
      *---------------------------------------------------------------*
       2000-VALIDATE-INPUT.
      *
           IF WS-IN-USER-ID = SPACES OR LOW-VALUES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'USER ID IS REQUIRED' TO WS-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
           IF WS-IN-PASSWORD = SPACES OR LOW-VALUES
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'PASSWORD IS REQUIRED' TO WS-ERROR-MSG
           END-IF
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - LOOK UP USER IN SYSTEM_USER TABLE                      *
      *---------------------------------------------------------------*
       3000-LOOKUP-USER.
      *
           EXEC SQL
               SELECT USER_ID,
                      USER_NAME,
                      PASSWORD_HASH,
                      USER_TYPE,
                      DEALER_CODE,
                      ACTIVE_FLAG,
                      FAILED_ATTEMPTS,
                      LOCKED_FLAG
               INTO   :DCLSYSTEM-USER.USER-ID,
                      :DCLSYSTEM-USER.USER-NAME,
                      :DCLSYSTEM-USER.PASSWORD-HASH,
                      :DCLSYSTEM-USER.USER-TYPE,
                      :DCLSYSTEM-USER.DEALER-CODE,
                      :DCLSYSTEM-USER.ACTIVE-FLAG,
                      :DCLSYSTEM-USER.FAILED-ATTEMPTS,
                      :DCLSYSTEM-USER.LOCKED-FLAG
               FROM   AUTOSALE.SYSTEM_USER
               WHERE  USER_ID = :WS-IN-USER-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                   CONTINUE
               WHEN +100
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE 'INVALID USER ID OR PASSWORD'
                       TO WS-ERROR-MSG
               WHEN OTHER
                   MOVE 'Y' TO WS-ERROR-FLAG
                   MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
                   MOVE '3000-LOOKUP-USER' TO WS-DBE-SECTION
                   MOVE 'SYSTEM_USER' TO WS-DBE-TABLE
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
      * 4000 - CHECK ACCOUNT STATUS (ACTIVE AND NOT LOCKED)            *
      *---------------------------------------------------------------*
       4000-CHECK-ACCOUNT-STATUS.
      *
      *    CHECK ACTIVE FLAG
      *
           IF ACTIVE-FLAG OF DCLSYSTEM-USER NOT = 'Y'
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'ACCOUNT IS INACTIVE - CONTACT ADMINISTRATOR'
                   TO WS-ERROR-MSG
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK LOCKED FLAG
      *
           IF LOCKED-FLAG OF DCLSYSTEM-USER = 'Y'
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE
               'ACCOUNT IS LOCKED - CONTACT ADMINISTRATOR'
                   TO WS-ERROR-MSG
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - VALIDATE PASSWORD AGAINST STORED HASH                   *
      *        NOTE: IN PRODUCTION, WOULD USE A CRYPTO HASH ROUTINE    *
      *        HERE WE DO A SIMPLE COMPARISON FOR DEMONSTRATION         *
      *---------------------------------------------------------------*
       5000-VALIDATE-PASSWORD.
      *
      *    HASH THE INPUT PASSWORD (SIMPLIFIED)
      *    IN PRODUCTION: CALL EXTERNAL CRYPTO MODULE
      *
           MOVE SPACES TO WS-PASSWORD-HASH
           STRING WS-IN-PASSWORD DELIMITED BY SPACES
               INTO WS-PASSWORD-HASH
      *
      *    COMPARE WITH STORED HASH
      *
           IF WS-PASSWORD-HASH NOT =
              PASSWORD-HASH OF DCLSYSTEM-USER
               MOVE 'Y' TO WS-ERROR-FLAG
               MOVE 'INVALID USER ID OR PASSWORD'
                   TO WS-ERROR-MSG
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - INCREMENT FAILED ATTEMPTS AND LOCK IF >= 5              *
      *---------------------------------------------------------------*
       6000-INCREMENT-FAILED-ATTEMPTS.
      *
           ADD 1 TO FAILED-ATTEMPTS OF DCLSYSTEM-USER
               GIVING WS-FAILED-COUNT
      *
      *    CHECK IF WE NEED TO LOCK THE ACCOUNT
      *
           IF WS-FAILED-COUNT >= WS-MAX-FAILED
      *
      *        LOCK THE ACCOUNT
      *
               EXEC SQL
                   UPDATE AUTOSALE.SYSTEM_USER
                   SET    FAILED_ATTEMPTS = :WS-FAILED-COUNT,
                          LOCKED_FLAG = 'Y',
                          UPDATED_TS = CURRENT TIMESTAMP
                   WHERE  USER_ID = :WS-IN-USER-ID
               END-EXEC
      *
               IF SQLCODE = 0
                   MOVE SPACES TO WS-ERROR-MSG
                   STRING 'ACCOUNT LOCKED AFTER '
                          WS-FAILED-COUNT
                          ' FAILED ATTEMPTS'
                       DELIMITED BY SIZE
                       INTO WS-ERROR-MSG
               END-IF
           ELSE
      *
      *        JUST INCREMENT THE COUNTER
      *
               EXEC SQL
                   UPDATE AUTOSALE.SYSTEM_USER
                   SET    FAILED_ATTEMPTS = :WS-FAILED-COUNT,
                          UPDATED_TS = CURRENT TIMESTAMP
                   WHERE  USER_ID = :WS-IN-USER-ID
               END-EXEC
           END-IF
      *
           IF SQLCODE NOT = 0
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '6000-INCR-FAILED' TO WS-DBE-SECTION
               MOVE 'SYSTEM_USER' TO WS-DBE-TABLE
               MOVE 'UPDATE' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                     WS-DBE-PROGRAM
                                     WS-DBE-SECTION
                                     WS-DBE-TABLE
                                     WS-DBE-OPERATION
                                     WS-DBE-RESULT
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7000 - UPDATE USER RECORD FOR SUCCESSFUL LOGIN                 *
      *        RESET FAILED ATTEMPTS, SET LAST_LOGIN_TS                *
      *---------------------------------------------------------------*
       7000-UPDATE-SUCCESSFUL-LOGIN.
      *
           EXEC SQL
               UPDATE AUTOSALE.SYSTEM_USER
               SET    LAST_LOGIN_TS = CURRENT TIMESTAMP,
                      FAILED_ATTEMPTS = 0,
                      UPDATED_TS = CURRENT TIMESTAMP
               WHERE  USER_ID = :WS-IN-USER-ID
           END-EXEC
      *
           IF SQLCODE NOT = 0
               MOVE WS-MODULE-ID TO WS-DBE-PROGRAM
               MOVE '7000-UPD-LOGIN' TO WS-DBE-SECTION
               MOVE 'SYSTEM_USER' TO WS-DBE-TABLE
               MOVE 'UPDATE' TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                     WS-DBE-PROGRAM
                                     WS-DBE-SECTION
                                     WS-DBE-TABLE
                                     WS-DBE-OPERATION
                                     WS-DBE-RESULT
           END-IF
           .
       7000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - SEND ERROR RESPONSE BACK TO TERMINAL                    *
      *        FORMAT THE SIGN-ON SCREEN WITH ERROR MESSAGE             *
      *---------------------------------------------------------------*
       8000-SEND-ERROR-RESPONSE.
      *
           MOVE 324 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE 'MFSADMMN' TO WS-OUT-MOD-NAME
           MOVE WS-IN-USER-ID TO WS-OUT-USER-ID
           MOVE SPACES TO WS-OUT-USER-NAME
           MOVE SPACES TO WS-OUT-USER-TYPE
           MOVE SPACES TO WS-OUT-DEALER-CODE
           MOVE WS-ERROR-MSG TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
           MOVE 'F' TO WS-OUT-STATUS
      *
      *    FORMAT MESSAGE USING COMMON MODULE
      *
           MOVE 'E' TO WS-MSG-TYPE
           MOVE 'ADMS0001' TO WS-MSG-CODE
           MOVE WS-ERROR-MSG TO WS-MSG-DATA1
           MOVE SPACES TO WS-MSG-DATA2
           CALL 'COMMSGL0' USING WS-MSG-TYPE
                                  WS-MSG-CODE
                                  WS-MSG-DATA1
                                  WS-MSG-DATA2
                                  WS-MSG-OUTPUT
                                  WS-MSG-RC
      *
           IF WS-MSG-RC = 0
               MOVE WS-MSG-OUTPUT TO WS-OUT-MSG-LINE1
           END-IF
      *
      *    SEND OUTPUT MESSAGE VIA IMS ISRT
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
      *
           IF IO-STATUS-CODE NOT = SPACES
               CONTINUE
           END-IF
           .
       8000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8500 - SEND SUCCESS RESPONSE (MAIN MENU)                       *
      *---------------------------------------------------------------*
       8500-SEND-SUCCESS-RESPONSE.
      *
           MOVE 324 TO WS-OUT-LL
           MOVE 0 TO WS-OUT-ZZ
           MOVE WS-MOD-MAIN-MENU TO WS-OUT-MOD-NAME
           MOVE USER-ID OF DCLSYSTEM-USER
               TO WS-OUT-USER-ID
           MOVE USER-NAME-TX OF DCLSYSTEM-USER
               TO WS-OUT-USER-NAME
           MOVE USER-TYPE OF DCLSYSTEM-USER
               TO WS-OUT-USER-TYPE
           MOVE DEALER-CODE OF DCLSYSTEM-USER
               TO WS-OUT-DEALER-CODE
           MOVE 'SIGN-ON SUCCESSFUL. WELCOME TO AUTOSALE.'
               TO WS-OUT-MSG-LINE1
           MOVE SPACES TO WS-OUT-MSG-LINE2
           MOVE 'S' TO WS-OUT-STATUS
      *
      *    FORMAT SUCCESS MESSAGE USING COMMON MODULE
      *
           MOVE 'I' TO WS-MSG-TYPE
           MOVE 'ADMS0002' TO WS-MSG-CODE
           MOVE USER-NAME-TX OF DCLSYSTEM-USER
               TO WS-MSG-DATA1
           MOVE SPACES TO WS-MSG-DATA2
           CALL 'COMMSGL0' USING WS-MSG-TYPE
                                  WS-MSG-CODE
                                  WS-MSG-DATA1
                                  WS-MSG-DATA2
                                  WS-MSG-OUTPUT
                                  WS-MSG-RC
      *
           IF WS-MSG-RC = 0
               MOVE WS-MSG-OUTPUT TO WS-OUT-MSG-LINE1
           END-IF
      *
      *    SEND OUTPUT VIA IMS ISRT
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB-MASK
                                WS-OUTPUT-MSG
      *
           IF IO-STATUS-CODE NOT = SPACES
               CONTINUE
           END-IF
           .
       8500-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 9000 - LOG FAILED LOGIN ATTEMPT VIA AUDIT MODULE               *
      *---------------------------------------------------------------*
       9000-LOG-FAILED-ATTEMPT.
      *
           MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
           MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
           MOVE 'LOF' TO WS-AUD-ACTION
           MOVE 'SYSTEM_USER' TO WS-AUD-TABLE
           MOVE WS-IN-USER-ID TO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           MOVE WS-ERROR-MSG TO WS-AUD-NEW-VAL
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
      *
      *---------------------------------------------------------------*
      * 9100 - LOG SUCCESSFUL LOGIN VIA AUDIT MODULE                   *
      *---------------------------------------------------------------*
       9100-LOG-SUCCESSFUL-LOGIN.
      *
           MOVE WS-IN-USER-ID TO WS-AUD-USER-ID
           MOVE WS-MODULE-ID TO WS-AUD-PROGRAM-ID
           MOVE 'LON' TO WS-AUD-ACTION
           MOVE 'SYSTEM_USER' TO WS-AUD-TABLE
           MOVE WS-IN-USER-ID TO WS-AUD-KEY
           MOVE SPACES TO WS-AUD-OLD-VAL
           MOVE 'LOGIN SUCCESSFUL' TO WS-AUD-NEW-VAL
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
       9100-EXIT.
           EXIT.
      ****************************************************************
      * END OF ADMSEC00                                              *
      ****************************************************************
