       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMDBEL0.
      ****************************************************************
      * PROGRAM:   COMDBEL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   DB2 ERROR HANDLER MODULE. CENTRALIZES ALL DB2     *
      *            SQLCODE EVALUATION, ERROR MESSAGE FORMATTING,      *
      *            AND RECOVERY ACTIONS ACROSS THE AUTOSALES SYSTEM. *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMDBEL0' USING LK-SQLCA-AREA                       *
      *                         LK-DBE-PROGRAM-NAME                  *
      *                         LK-DBE-SECTION-NAME                  *
      *                         LK-DBE-TABLE-NAME                    *
      *                         LK-DBE-OPERATION                     *
      *                         LK-DBE-RESULT-AREA                   *
      *                                                              *
      * RETURN CODES (IN LK-DBE-RESULT-CODE):                       *
      *   00 - OK (SQLCODE = 0)                                      *
      *   04 - NOT FOUND (SQLCODE = +100)                            *
      *   08 - ERROR (RECOVERABLE)                                   *
      *   12 - FATAL ERROR (REQUIRES ROLLBACK/ABEND)                *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMDBEL0'.
      *
      *    SQLCODE DISPLAY WORK FIELD
      *
       01  WS-SQLCODE-DISP         PIC -(09)9.
      *
      *    ERROR MESSAGE BUILD AREA
      *
       01  WS-ERROR-BUILD.
           05  WS-ERR-PREFIX       PIC X(08) VALUE SPACES.
           05  WS-ERR-SEPARATOR    PIC X(02) VALUE ': '.
           05  WS-ERR-BODY         PIC X(120) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-SAVED-SQLCODE    PIC S9(09) COMP VALUE 0.
           05  WS-SAVED-SQLSTATE   PIC X(05) VALUE SPACES.
           05  WS-SAVED-SQLERRMC   PIC X(70) VALUE SPACES.
           05  WS-SAVED-SQLERRD3   PIC S9(09) COMP VALUE 0.
           05  WS-SQLERRD3-DISP    PIC -(09)9.
           05  WS-SEVERITY         PIC X(01) VALUE SPACES.
               88  WS-SEV-OK               VALUE 'O'.
               88  WS-SEV-INFO             VALUE 'I'.
               88  WS-SEV-WARNING          VALUE 'W'.
               88  WS-SEV-ERROR            VALUE 'E'.
               88  WS-SEV-FATAL            VALUE 'F'.
      *
      *    IMS DC ROLL CALL FIELDS
      *
       01  WS-IMS-FIELDS.
           05  WS-IMS-FUNCTION     PIC X(04) VALUE SPACES.
           05  WS-IMS-STATUS       PIC X(02) VALUE SPACES.
           05  WS-IMS-IO-AREA      PIC X(10) VALUE SPACES.
      *
      *    DB2 ERROR CATEGORY TABLE
      *    MAPS RANGES OF SQLCODES TO CATEGORIES
      *
       01  WS-SQLCODE-CATEGORIES.
           05  WS-CAT-SUCCESS      PIC X(20)
               VALUE 'SUCCESSFUL EXECUTION'.
           05  WS-CAT-NOT-FOUND    PIC X(20)
               VALUE 'ROW NOT FOUND       '.
           05  WS-CAT-DUP-KEY      PIC X(20)
               VALUE 'DUPLICATE KEY VALUE '.
           05  WS-CAT-MULT-ROWS    PIC X(20)
               VALUE 'MULTIPLE ROWS FOUND '.
           05  WS-CAT-UNAVAILABLE  PIC X(20)
               VALUE 'RESOURCE UNAVAILABLE'.
           05  WS-CAT-DEADLOCK     PIC X(20)
               VALUE 'DEADLOCK DETECTED   '.
           05  WS-CAT-TIMEOUT      PIC X(20)
               VALUE 'TIMEOUT ON LOCK     '.
           05  WS-CAT-AUTH-FAIL    PIC X(20)
               VALUE 'AUTHORIZATION ERROR '.
           05  WS-CAT-DATA-ERR     PIC X(20)
               VALUE 'DATA EXCEPTION      '.
           05  WS-CAT-CONSTRAINT   PIC X(20)
               VALUE 'CONSTRAINT VIOLATION'.
           05  WS-CAT-PLAN-ERR     PIC X(20)
               VALUE 'PLAN/PACKAGE ERROR  '.
           05  WS-CAT-UNKNOWN      PIC X(20)
               VALUE 'UNKNOWN SQL ERROR   '.
      *
       LINKAGE SECTION.
      *
      *    SQLCA PASSED BY CALLER (STANDARD IBM SQLCA LAYOUT)
      *
       01  LK-SQLCA-AREA.
           05  LK-SQLCAID          PIC X(08).
           05  LK-SQLCABC          PIC S9(09) COMP.
           05  LK-SQLCODE          PIC S9(09) COMP.
           05  LK-SQLERRM.
               49  LK-SQLERRML    PIC S9(04) COMP.
               49  LK-SQLERRMC    PIC X(70).
           05  LK-SQLERRP          PIC X(08).
           05  LK-SQLERRD          PIC S9(09) COMP
                                    OCCURS 6 TIMES.
           05  LK-SQLWARN.
               10  LK-SQLWARN0    PIC X(01).
               10  LK-SQLWARN1    PIC X(01).
               10  LK-SQLWARN2    PIC X(01).
               10  LK-SQLWARN3    PIC X(01).
               10  LK-SQLWARN4    PIC X(01).
               10  LK-SQLWARN5    PIC X(01).
               10  LK-SQLWARN6    PIC X(01).
               10  LK-SQLWARN7    PIC X(01).
               10  LK-SQLWARN8    PIC X(01).
               10  LK-SQLWARN9    PIC X(01).
               10  LK-SQLWARNA   PIC X(01).
           05  LK-SQLSTATE         PIC X(05).
      *
       01  LK-DBE-PROGRAM-NAME    PIC X(08).
       01  LK-DBE-SECTION-NAME    PIC X(30).
       01  LK-DBE-TABLE-NAME      PIC X(18).
       01  LK-DBE-OPERATION       PIC X(10).
      *
       01  LK-DBE-RESULT-AREA.
           05  LK-DBE-RESULT-CODE PIC S9(04) COMP.
           05  LK-DBE-RETRY-FLAG  PIC X(01).
               88  LK-DBE-SHOULD-RETRY     VALUE 'Y'.
               88  LK-DBE-NO-RETRY         VALUE 'N'.
           05  LK-DBE-ERROR-MSG   PIC X(120).
           05  LK-DBE-SQLCODE-DISP PIC X(10).
           05  LK-DBE-SQLSTATE    PIC X(05).
           05  LK-DBE-CATEGORY    PIC X(20).
           05  LK-DBE-SEVERITY    PIC X(01).
           05  LK-DBE-ROWS-AFFECTED PIC S9(09) COMP.
      *
       PROCEDURE DIVISION USING LK-SQLCA-AREA
                                LK-DBE-PROGRAM-NAME
                                LK-DBE-SECTION-NAME
                                LK-DBE-TABLE-NAME
                                LK-DBE-OPERATION
                                LK-DBE-RESULT-AREA.
      *
       0000-MAIN-ENTRY.
      *
           INITIALIZE LK-DBE-RESULT-AREA
           MOVE 'N' TO LK-DBE-RETRY-FLAG
           MOVE ZEROS TO LK-DBE-RESULT-CODE
      *
      *    SAVE SQLCA FIELDS FOR PROCESSING
      *
           MOVE LK-SQLCODE   TO WS-SAVED-SQLCODE
           MOVE LK-SQLSTATE  TO WS-SAVED-SQLSTATE
           MOVE LK-SQLERRMC  TO WS-SAVED-SQLERRMC
           MOVE LK-SQLERRD(3) TO WS-SAVED-SQLERRD3
      *
      *    COPY SQLSTATE AND ROWS AFFECTED TO RESULT
      *
           MOVE WS-SAVED-SQLSTATE TO LK-DBE-SQLSTATE
           MOVE WS-SAVED-SQLERRD3 TO LK-DBE-ROWS-AFFECTED
      *
      *    FORMAT SQLCODE FOR DISPLAY
      *
           MOVE WS-SAVED-SQLCODE TO WS-SQLCODE-DISP
           MOVE WS-SQLCODE-DISP TO LK-DBE-SQLCODE-DISP
      *
      *    EVALUATE SQLCODE AND SET RESULT
      *
           PERFORM 1000-EVALUATE-SQLCODE
      *
      *    BUILD FORMATTED ERROR MESSAGE
      *
           PERFORM 2000-BUILD-ERROR-MESSAGE
      *
      *    FOR FATAL ERRORS, ISSUE IMS ROLL
      *
           IF LK-DBE-RESULT-CODE = +12
               PERFORM 3000-ISSUE-IMS-ROLL
           END-IF
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - EVALUATE SQLCODE AND SET RESULT CODE, CATEGORY,         *
      *        SEVERITY, AND RETRY FLAG                                 *
      *---------------------------------------------------------------*
       1000-EVALUATE-SQLCODE.
      *
           EVALUATE TRUE
      *
      *        SUCCESSFUL EXECUTION
      *
               WHEN WS-SAVED-SQLCODE = 0
                   MOVE +0 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-SUCCESS TO LK-DBE-CATEGORY
                   MOVE 'O' TO LK-DBE-SEVERITY
      *
      *        ROW NOT FOUND
      *
               WHEN WS-SAVED-SQLCODE = +100
                   MOVE +4 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-NOT-FOUND TO LK-DBE-CATEGORY
                   MOVE 'I' TO LK-DBE-SEVERITY
      *
      *        POSITIVE WARNINGS (1-99)
      *
               WHEN WS-SAVED-SQLCODE > 0
                AND WS-SAVED-SQLCODE < 100
                   MOVE +0 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-SUCCESS TO LK-DBE-CATEGORY
                   MOVE 'W' TO LK-DBE-SEVERITY
      *
      *        DUPLICATE KEY ON INSERT (-803)
      *
               WHEN WS-SAVED-SQLCODE = -803
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-DUP-KEY TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
      *
      *        MULTIPLE ROWS ON SINGLETON SELECT (-811)
      *
               WHEN WS-SAVED-SQLCODE = -811
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-MULT-ROWS TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
      *
      *        CHECK CONSTRAINT VIOLATION (-545)
      *
               WHEN WS-SAVED-SQLCODE = -545
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-CONSTRAINT TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
      *
      *        REFERENTIAL CONSTRAINT (-530, -531, -532)
      *
               WHEN WS-SAVED-SQLCODE = -530
               WHEN WS-SAVED-SQLCODE = -531
               WHEN WS-SAVED-SQLCODE = -532
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-CONSTRAINT TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
      *
      *        RESOURCE UNAVAILABLE (-904)
      *
               WHEN WS-SAVED-SQLCODE = -904
                   MOVE +12 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-UNAVAILABLE TO LK-DBE-CATEGORY
                   MOVE 'F' TO LK-DBE-SEVERITY
      *
      *        DEADLOCK (-911) - SET RETRY FLAG
      *
               WHEN WS-SAVED-SQLCODE = -911
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-DEADLOCK TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
                   MOVE 'Y' TO LK-DBE-RETRY-FLAG
      *
      *        TIMEOUT (-913) - SET RETRY FLAG
      *
               WHEN WS-SAVED-SQLCODE = -913
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-TIMEOUT TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
                   MOVE 'Y' TO LK-DBE-RETRY-FLAG
      *
      *        PLAN/PACKAGE MISMATCH (-818)
      *
               WHEN WS-SAVED-SQLCODE = -818
                   MOVE +12 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-PLAN-ERR TO LK-DBE-CATEGORY
                   MOVE 'F' TO LK-DBE-SEVERITY
      *
      *        AUTHORIZATION FAILURE (-551, -552)
      *
               WHEN WS-SAVED-SQLCODE = -551
               WHEN WS-SAVED-SQLCODE = -552
                   MOVE +12 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-AUTH-FAIL TO LK-DBE-CATEGORY
                   MOVE 'F' TO LK-DBE-SEVERITY
      *
      *        DATA EXCEPTION (-302, -303, -304, -305)
      *
               WHEN WS-SAVED-SQLCODE = -302
               WHEN WS-SAVED-SQLCODE = -303
               WHEN WS-SAVED-SQLCODE = -304
               WHEN WS-SAVED-SQLCODE = -305
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-DATA-ERR TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
      *
      *        NEGATIVE NOT FOUND (-100)
      *
               WHEN WS-SAVED-SQLCODE = -100
                   MOVE +4 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-NOT-FOUND TO LK-DBE-CATEGORY
                   MOVE 'I' TO LK-DBE-SEVERITY
      *
      *        SEVERE ERRORS (-900 THROUGH -999)
      *
               WHEN WS-SAVED-SQLCODE <= -900
                AND WS-SAVED-SQLCODE >= -999
                   MOVE +12 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-UNKNOWN TO LK-DBE-CATEGORY
                   MOVE 'F' TO LK-DBE-SEVERITY
      *
      *        ALL OTHER NEGATIVE SQLCODES
      *
               WHEN WS-SAVED-SQLCODE < 0
                   MOVE +8 TO LK-DBE-RESULT-CODE
                   MOVE WS-CAT-UNKNOWN TO LK-DBE-CATEGORY
                   MOVE 'E' TO LK-DBE-SEVERITY
      *
           END-EVALUATE
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - BUILD FORMATTED ERROR MESSAGE WITH ALL CONTEXT          *
      *---------------------------------------------------------------*
       2000-BUILD-ERROR-MESSAGE.
      *
      *    SKIP MESSAGE BUILDING FOR SUCCESS
      *
           IF LK-DBE-RESULT-CODE = 0
               MOVE SPACES TO LK-DBE-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    BUILD DETAILED ERROR MESSAGE
      *
           EVALUATE WS-SAVED-SQLCODE
               WHEN +100
                   PERFORM 2100-MSG-NOT-FOUND
               WHEN -803
                   PERFORM 2200-MSG-DUPLICATE
               WHEN -811
                   PERFORM 2300-MSG-MULTIPLE-ROWS
               WHEN -904
                   PERFORM 2400-MSG-UNAVAILABLE
               WHEN -911
                   PERFORM 2500-MSG-DEADLOCK
               WHEN -913
                   PERFORM 2600-MSG-TIMEOUT
               WHEN -818
                   PERFORM 2700-MSG-PLAN-MISMATCH
               WHEN OTHER
                   PERFORM 2800-MSG-GENERIC
           END-EVALUATE
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2100 - NOT FOUND MESSAGE                                       *
      *---------------------------------------------------------------*
       2100-MSG-NOT-FOUND.
      *
           STRING 'NO ROW FOUND IN '
                  LK-DBE-TABLE-NAME
                  ' FOR '
                  LK-DBE-OPERATION
                  ' IN '
                  LK-DBE-SECTION-NAME
                  ' ('
                  LK-DBE-PROGRAM-NAME
                  ')'
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2200 - DUPLICATE KEY MESSAGE                                   *
      *---------------------------------------------------------------*
       2200-MSG-DUPLICATE.
      *
           STRING 'DUPLICATE KEY ON '
                  LK-DBE-OPERATION
                  ' TO '
                  LK-DBE-TABLE-NAME
                  ' - SQLCODE=-803 IN '
                  LK-DBE-SECTION-NAME
                  ' ('
                  LK-DBE-PROGRAM-NAME
                  ')'
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2200-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2300 - MULTIPLE ROWS MESSAGE                                   *
      *---------------------------------------------------------------*
       2300-MSG-MULTIPLE-ROWS.
      *
           STRING 'MULTIPLE ROWS ON '
                  LK-DBE-OPERATION
                  ' FROM '
                  LK-DBE-TABLE-NAME
                  ' - SQLCODE=-811 IN '
                  LK-DBE-SECTION-NAME
                  ' ('
                  LK-DBE-PROGRAM-NAME
                  ')'
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2300-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2400 - RESOURCE UNAVAILABLE MESSAGE                            *
      *---------------------------------------------------------------*
       2400-MSG-UNAVAILABLE.
      *
           STRING 'TABLE '
                  LK-DBE-TABLE-NAME
                  ' UNAVAILABLE - SQLCODE=-904'
                  ' REASON='
                  WS-SAVED-SQLERRMC(1:30)
                  ' IN '
                  LK-DBE-PROGRAM-NAME
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2400-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2500 - DEADLOCK MESSAGE (WITH RETRY RECOMMENDATION)            *
      *---------------------------------------------------------------*
       2500-MSG-DEADLOCK.
      *
           STRING 'DEADLOCK ON '
                  LK-DBE-OPERATION
                  ' TO '
                  LK-DBE-TABLE-NAME
                  ' - SQLCODE=-911 RETRY RECOMMENDED'
                  ' IN '
                  LK-DBE-SECTION-NAME
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2500-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2600 - TIMEOUT MESSAGE (WITH RETRY RECOMMENDATION)             *
      *---------------------------------------------------------------*
       2600-MSG-TIMEOUT.
      *
           STRING 'LOCK TIMEOUT ON '
                  LK-DBE-OPERATION
                  ' TO '
                  LK-DBE-TABLE-NAME
                  ' - SQLCODE=-913 RETRY RECOMMENDED'
                  ' IN '
                  LK-DBE-SECTION-NAME
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2600-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2700 - PLAN/PACKAGE MISMATCH                                   *
      *---------------------------------------------------------------*
       2700-MSG-PLAN-MISMATCH.
      *
           STRING 'PLAN MISMATCH FOR '
                  LK-DBE-PROGRAM-NAME
                  ' - SQLCODE=-818 REBIND REQUIRED'
                  ' SQLSTATE='
                  WS-SAVED-SQLSTATE
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2700-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2800 - GENERIC ERROR MESSAGE                                   *
      *---------------------------------------------------------------*
       2800-MSG-GENERIC.
      *
           MOVE WS-SAVED-SQLCODE TO WS-SQLCODE-DISP
           MOVE WS-SAVED-SQLERRD3 TO WS-SQLERRD3-DISP
      *
           STRING 'SQL ERROR '
                  WS-SQLCODE-DISP
                  ' STATE='
                  WS-SAVED-SQLSTATE
                  ' ON '
                  LK-DBE-OPERATION
                  ' '
                  LK-DBE-TABLE-NAME
                  ' IN '
                  LK-DBE-SECTION-NAME
                  ' ('
                  LK-DBE-PROGRAM-NAME
                  ') ERRD3='
                  WS-SQLERRD3-DISP
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       2800-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - ISSUE IMS DC ROLL CALL TO ROLLBACK TRANSACTION          *
      *        CALLED ONLY FOR FATAL ERRORS (RC=12)                    *
      *        ROLL CALL BACKS OUT ALL DB2 AND DL/I CHANGES            *
      *---------------------------------------------------------------*
       3000-ISSUE-IMS-ROLL.
      *
      *    IMS ROLL CALL - BACKS OUT CHANGES AND RESTARTS MPP
      *    THE ROLL CALL DOES NOT RETURN TO THE CALLER
      *    IMS WILL RE-QUEUE THE INPUT MESSAGE
      *
           CALL 'CBLTDLI' USING WS-IMS-FUNCTION
                                WS-IMS-IO-AREA
      *
      *    NOTE: IF WE REACH HERE, THE ROLL FAILED
      *    (POSSIBLY RUNNING IN BATCH MODE WHERE ROLL IS N/A)
      *    SET SEVERITY TO INDICATE ROLLBACK WAS NOT DONE
      *
           STRING LK-DBE-ERROR-MSG(1:80)
                  ' *** ROLL FAILED ***'
               DELIMITED BY SIZE
               INTO LK-DBE-ERROR-MSG
           .
       3000-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMDBEL0                                              *
      ****************************************************************
