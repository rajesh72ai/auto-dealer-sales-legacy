       IDENTIFICATION DIVISION.
       PROGRAM-ID. REGSTS00.
      ****************************************************************
      * PROGRAM:  REGSTS00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   REG - REGISTRATION STATUS UPDATE                   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  UPDATES A REGISTRATION RECORD WITH STATE DMV       *
      *           RESPONSE. HANDLES BOTH APPROVAL AND REJECTION:     *
      *           - IF APPROVED (STATUS 'IS'): RECORDS PLATE NUMBER, *
      *             TITLE NUMBER, AND ISSUED DATE.                   *
      *           - IF REJECTED (STATUS 'RJ'): RECORDS REJECTION     *
      *             REASON IN TITLE_STATUS HISTORY.                  *
      *           - IF PROCESSING (STATUS 'PG'): MARKS IN-PROGRESS. *
      *           VALIDATES THAT CURRENT STATUS ALLOWS UPDATE        *
      *           (MUST BE SB OR PG). INSERTS AUDIT TRAIL INTO      *
      *           TITLE_STATUS TABLE. LOGS VIA COMLGEL0.             *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    RGST - REGISTRATION STATUS UPDATE                  *
      * MFS MOD:  ASRGST00                                           *
      * TABLES:   AUTOSALE.REGISTRATION  (READ/UPDATE)               *
      *           AUTOSALE.TITLE_STATUS  (INSERT)                    *
      * CALLS:    COMLGEL0 - AUDIT LOGGING                           *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
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
                                          VALUE 'REGSTS00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASRGST00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
      *    INPUT MESSAGE AREA (FROM MFS)
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-REG-ID              PIC X(12).
           05  WS-IN-NEW-STATUS          PIC X(02).
           05  WS-IN-PLATE-NUMBER        PIC X(10).
           05  WS-IN-TITLE-NUMBER        PIC X(20).
           05  WS-IN-REJECT-REASON       PIC X(60).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-REG-ID             PIC X(12).
           05  WS-OUT-DEAL-NUMBER        PIC X(10).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-OLD-STATUS         PIC X(10).
           05  WS-OUT-NEW-STATUS         PIC X(10).
           05  WS-OUT-PLATE              PIC X(10).
           05  WS-OUT-TITLE-NUM          PIC X(20).
           05  WS-OUT-ISSUED-DATE        PIC X(10).
           05  WS-OUT-REJECT-REASON      PIC X(60).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-STATUS-SEQ             PIC S9(04) COMP VALUE +0.
           05  WS-STATUS-DESC            PIC X(60).
      *
      *    DB2 HOST VARIABLES - REGISTRATION
      *
       01  WS-HV-REG.
           05  WS-HV-RG-ID              PIC X(12).
           05  WS-HV-RG-DEAL-NUMBER     PIC X(10).
           05  WS-HV-RG-VIN             PIC X(17).
           05  WS-HV-RG-REG-STATE       PIC X(02).
           05  WS-HV-RG-REG-STATUS      PIC X(02).
      *
      *    NULL INDICATORS FOR UPDATE
      *
       01  WS-NULL-INDICATORS.
           05  NI-PLATE-NUMBER           PIC S9(04) COMP VALUE +0.
           05  NI-TITLE-NUMBER           PIC S9(04) COMP VALUE +0.
           05  NI-ISSUED-DATE            PIC S9(04) COMP VALUE +0.
      *
      *    COMMON MODULE LINKAGE - COMLGEL0
      *
       01  WS-LOG-FUNCTION               PIC X(04).
       01  WS-LOG-PROGRAM                PIC X(08).
       01  WS-LOG-TABLE-NAME             PIC X(18).
       01  WS-LOG-ACTION                 PIC X(08).
       01  WS-LOG-KEY-VALUE              PIC X(40).
       01  WS-LOG-DETAILS                PIC X(200).
       01  WS-LOG-RETURN-CODE            PIC S9(04) COMP.
      *
      *    COMMON MODULE LINKAGE - COMDBEL0
      *
       01  WS-DBE-SQLCODE                PIC S9(09) COMP.
       01  WS-DBE-PROGRAM                PIC X(08).
       01  WS-DBE-PARAGRAPH              PIC X(30).
       01  WS-DBE-TABLE-NAME             PIC X(18).
       01  WS-DBE-RETURN-CODE            PIC S9(04) COMP.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-STATUS                 PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-USER                   PIC X(08).
      *
       01  DB-PCB-1.
           05  DB-1-DBD-NAME            PIC X(08).
           05  DB-1-SEG-LEVEL           PIC X(02).
           05  DB-1-STATUS              PIC X(02).
           05  FILLER                   PIC X(20).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB, DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF IO-STATUS = '  '
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 4000-LOOKUP-REGISTRATION
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-VALIDATE-TRANSITION
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6000-UPDATE-REGISTRATION
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6500-INSERT-STATUS-HISTORY
           END-IF
      *
           PERFORM 8000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR WORK AREAS                        *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
           INITIALIZE WS-NULL-INDICATORS
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'REGISTRATION STATUS UPDATE' TO WS-OUT-TITLE
      *
           EXEC SQL
               SET :WS-CURRENT-TS = CURRENT TIMESTAMP
           END-EXEC
           MOVE WS-CURRENT-TS(1:10) TO WS-CURRENT-DATE
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT - GU CALL ON IO-PCB                    *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-STATUS NOT = '  '
               MOVE 'REGSTS00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-REG-ID = SPACES
               MOVE 'REGISTRATION ID IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-NEW-STATUS = SPACES
               MOVE 'NEW STATUS CODE IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE NEW STATUS IS A VALID CODE
      *
           IF WS-IN-NEW-STATUS NOT = 'PG'
           AND WS-IN-NEW-STATUS NOT = 'IS'
           AND WS-IN-NEW-STATUS NOT = 'RJ'
           AND WS-IN-NEW-STATUS NOT = 'ER'
               MOVE 'INVALID STATUS - USE PG/IS/RJ/ER'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    IF APPROVED, PLATE AND TITLE ARE REQUIRED
      *
           IF WS-IN-NEW-STATUS = 'IS'
               IF WS-IN-PLATE-NUMBER = SPACES
                   MOVE 'PLATE NUMBER IS REQUIRED FOR ISSUANCE'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
               IF WS-IN-TITLE-NUMBER = SPACES
                   MOVE 'TITLE NUMBER IS REQUIRED FOR ISSUANCE'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
           END-IF
      *
      *    IF REJECTED, REASON IS REQUIRED
      *
           IF WS-IN-NEW-STATUS = 'RJ'
               IF WS-IN-REJECT-REASON = SPACES
                   MOVE 'REJECTION REASON IS REQUIRED'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-REGISTRATION - READ CURRENT REGISTRATION      *
      ****************************************************************
       4000-LOOKUP-REGISTRATION.
      *
           EXEC SQL
               SELECT R.REG_ID
                    , R.DEAL_NUMBER
                    , R.VIN
                    , R.REG_STATE
                    , R.REG_STATUS
               INTO  :WS-HV-RG-ID
                    , :WS-HV-RG-DEAL-NUMBER
                    , :WS-HV-RG-VIN
                    , :WS-HV-RG-REG-STATE
                    , :WS-HV-RG-REG-STATUS
               FROM  AUTOSALE.REGISTRATION R
               WHERE R.REG_ID = :WS-IN-REG-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE 'REGISTRATION NOT FOUND FOR SPECIFIED ID'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
               WHEN OTHER
                   MOVE 'REGSTS00' TO WS-DBE-PROGRAM
                   MOVE '4000-LOOKUP-REGISTRATION'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.REGISTRATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGSTS00: DB2 ERROR READING REGISTRATION'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    POPULATE OUTPUT WITH CURRENT DATA
      *
           MOVE WS-HV-RG-ID TO WS-OUT-REG-ID
           MOVE WS-HV-RG-DEAL-NUMBER TO WS-OUT-DEAL-NUMBER
           MOVE WS-HV-RG-VIN TO WS-OUT-VIN
      *
      *    FORMAT OLD STATUS DESCRIPTION
      *
           EVALUATE WS-HV-RG-REG-STATUS
               WHEN 'PR'
                   MOVE 'PREPARING ' TO WS-OUT-OLD-STATUS
               WHEN 'VL'
                   MOVE 'VALIDATED ' TO WS-OUT-OLD-STATUS
               WHEN 'SB'
                   MOVE 'SUBMITTED ' TO WS-OUT-OLD-STATUS
               WHEN 'PG'
                   MOVE 'PROCESSING' TO WS-OUT-OLD-STATUS
               WHEN 'IS'
                   MOVE 'ISSUED    ' TO WS-OUT-OLD-STATUS
               WHEN 'RJ'
                   MOVE 'REJECTED  ' TO WS-OUT-OLD-STATUS
               WHEN 'ER'
                   MOVE 'ERROR     ' TO WS-OUT-OLD-STATUS
               WHEN OTHER
                   MOVE WS-HV-RG-REG-STATUS
                       TO WS-OUT-OLD-STATUS
           END-EVALUATE
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-VALIDATE-TRANSITION - CHECK STATUS TRANSITION RULES  *
      ****************************************************************
       5000-VALIDATE-TRANSITION.
      *
      *    VALID TRANSITIONS:
      *      SB -> PG (PROCESSING BY STATE)
      *      SB -> IS (DIRECT ISSUANCE)
      *      SB -> RJ (REJECTED)
      *      SB -> ER (ERROR)
      *      PG -> IS (ISSUED)
      *      PG -> RJ (REJECTED)
      *      PG -> ER (ERROR)
      *
           IF WS-HV-RG-REG-STATUS NOT = 'SB'
           AND WS-HV-RG-REG-STATUS NOT = 'PG'
               MOVE 'STATUS MUST BE SUBMITTED OR PROCESSING'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
      *    CANNOT GO BACKWARDS FROM PG TO SB
      *
           IF WS-HV-RG-REG-STATUS = 'PG'
           AND WS-IN-NEW-STATUS = 'PG'
               MOVE 'REGISTRATION IS ALREADY IN PROCESSING'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-UPDATE-REGISTRATION - APPLY STATUS AND DATA UPDATE   *
      ****************************************************************
       6000-UPDATE-REGISTRATION.
      *
      *    BUILD STATUS-SPECIFIC UPDATE
      *
           EVALUATE WS-IN-NEW-STATUS
      *
      *        ISSUED - UPDATE WITH PLATE, TITLE, AND DATE
      *
               WHEN 'IS'
                   EXEC SQL
                       UPDATE AUTOSALE.REGISTRATION
                       SET    REG_STATUS   = 'IS'
                            , PLATE_NUMBER = :WS-IN-PLATE-NUMBER
                            , TITLE_NUMBER = :WS-IN-TITLE-NUMBER
                            , ISSUED_DATE  = CURRENT DATE
                            , UPDATED_TS   = CURRENT TIMESTAMP
                       WHERE  REG_ID = :WS-IN-REG-ID
                   END-EXEC
      *
                   IF SQLCODE NOT = +0
                       MOVE 'REGSTS00' TO WS-DBE-PROGRAM
                       MOVE '6000-UPDATE-REGISTRATION'
                           TO WS-DBE-PARAGRAPH
                       MOVE 'AUTOSALE.REGISTRATION'
                           TO WS-DBE-TABLE-NAME
                       MOVE SQLCODE TO WS-DBE-SQLCODE
                       CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                            WS-DBE-PROGRAM
                                            WS-DBE-PARAGRAPH
                                            WS-DBE-TABLE-NAME
                                            WS-DBE-RETURN-CODE
                       MOVE 'REGSTS00: DB2 ERROR UPDATING REG'
                           TO WS-OUT-MESSAGE
                       GO TO 6000-EXIT
                   END-IF
      *
                   MOVE 'ISSUED    ' TO WS-OUT-NEW-STATUS
                   MOVE WS-IN-PLATE-NUMBER TO WS-OUT-PLATE
                   MOVE WS-IN-TITLE-NUMBER TO WS-OUT-TITLE-NUM
                   MOVE WS-CURRENT-DATE TO WS-OUT-ISSUED-DATE
                   STRING 'REGISTRATION ISSUED - PLATE='
                          WS-IN-PLATE-NUMBER
                          DELIMITED BY '  '
                       INTO WS-STATUS-DESC
                   END-STRING
      *
      *        REJECTED - RECORD REASON
      *
               WHEN 'RJ'
                   EXEC SQL
                       UPDATE AUTOSALE.REGISTRATION
                       SET    REG_STATUS = 'RJ'
                            , UPDATED_TS = CURRENT TIMESTAMP
                       WHERE  REG_ID = :WS-IN-REG-ID
                   END-EXEC
      *
                   IF SQLCODE NOT = +0
                       MOVE 'REGSTS00' TO WS-DBE-PROGRAM
                       MOVE '6000-UPDATE-REGISTRATION'
                           TO WS-DBE-PARAGRAPH
                       MOVE 'AUTOSALE.REGISTRATION'
                           TO WS-DBE-TABLE-NAME
                       MOVE SQLCODE TO WS-DBE-SQLCODE
                       CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                            WS-DBE-PROGRAM
                                            WS-DBE-PARAGRAPH
                                            WS-DBE-TABLE-NAME
                                            WS-DBE-RETURN-CODE
                       MOVE 'REGSTS00: DB2 ERROR UPDATING REG'
                           TO WS-OUT-MESSAGE
                       GO TO 6000-EXIT
                   END-IF
      *
                   MOVE 'REJECTED  ' TO WS-OUT-NEW-STATUS
                   MOVE WS-IN-REJECT-REASON TO WS-OUT-REJECT-REASON
                   MOVE WS-IN-REJECT-REASON TO WS-STATUS-DESC
      *
      *        PROCESSING - MARK IN PROGRESS
      *
               WHEN 'PG'
                   EXEC SQL
                       UPDATE AUTOSALE.REGISTRATION
                       SET    REG_STATUS = 'PG'
                            , UPDATED_TS = CURRENT TIMESTAMP
                       WHERE  REG_ID = :WS-IN-REG-ID
                   END-EXEC
      *
                   IF SQLCODE NOT = +0
                       MOVE 'REGSTS00' TO WS-DBE-PROGRAM
                       MOVE '6000-UPDATE-REGISTRATION'
                           TO WS-DBE-PARAGRAPH
                       MOVE 'AUTOSALE.REGISTRATION'
                           TO WS-DBE-TABLE-NAME
                       MOVE SQLCODE TO WS-DBE-SQLCODE
                       CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                            WS-DBE-PROGRAM
                                            WS-DBE-PARAGRAPH
                                            WS-DBE-TABLE-NAME
                                            WS-DBE-RETURN-CODE
                       MOVE 'REGSTS00: DB2 ERROR UPDATING REG'
                           TO WS-OUT-MESSAGE
                       GO TO 6000-EXIT
                   END-IF
      *
                   MOVE 'PROCESSING' TO WS-OUT-NEW-STATUS
                   MOVE 'STATE IS PROCESSING REGISTRATION'
                       TO WS-STATUS-DESC
      *
      *        ERROR - MARK ERROR STATUS
      *
               WHEN 'ER'
                   EXEC SQL
                       UPDATE AUTOSALE.REGISTRATION
                       SET    REG_STATUS = 'ER'
                            , UPDATED_TS = CURRENT TIMESTAMP
                       WHERE  REG_ID = :WS-IN-REG-ID
                   END-EXEC
      *
                   IF SQLCODE NOT = +0
                       MOVE 'REGSTS00' TO WS-DBE-PROGRAM
                       MOVE '6000-UPDATE-REGISTRATION'
                           TO WS-DBE-PARAGRAPH
                       MOVE 'AUTOSALE.REGISTRATION'
                           TO WS-DBE-TABLE-NAME
                       MOVE SQLCODE TO WS-DBE-SQLCODE
                       CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                            WS-DBE-PROGRAM
                                            WS-DBE-PARAGRAPH
                                            WS-DBE-TABLE-NAME
                                            WS-DBE-RETURN-CODE
                       MOVE 'REGSTS00: DB2 ERROR UPDATING REG'
                           TO WS-OUT-MESSAGE
                       GO TO 6000-EXIT
                   END-IF
      *
                   MOVE 'ERROR     ' TO WS-OUT-NEW-STATUS
                   IF WS-IN-REJECT-REASON NOT = SPACES
                       MOVE WS-IN-REJECT-REASON TO WS-STATUS-DESC
                   ELSE
                       MOVE 'REGISTRATION ERROR FROM STATE'
                           TO WS-STATUS-DESC
                   END-IF
           END-EVALUATE
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6500-INSERT-STATUS-HISTORY - ADD TITLE_STATUS RECORD      *
      ****************************************************************
       6500-INSERT-STATUS-HISTORY.
      *
      *    GET NEXT STATUS SEQUENCE FOR THIS REG
      *
           EXEC SQL
               SELECT COALESCE(MAX(STATUS_SEQ), 0) + 1
               INTO  :WS-STATUS-SEQ
               FROM  AUTOSALE.TITLE_STATUS
               WHERE REG_ID = :WS-IN-REG-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +1 TO WS-STATUS-SEQ
           END-IF
      *
      *    INSERT STATUS HISTORY RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.TITLE_STATUS
               ( REG_ID
               , STATUS_SEQ
               , STATUS_CODE
               , STATUS_DESC
               , STATUS_TS
               )
               VALUES
               ( :WS-IN-REG-ID
               , :WS-STATUS-SEQ
               , :WS-IN-NEW-STATUS
               , :WS-STATUS-DESC
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'REGSTS00' TO WS-DBE-PROGRAM
               MOVE '6500-INSERT-STATUS-HISTORY'
                   TO WS-DBE-PARAGRAPH
               MOVE 'AUTOSALE.TITLE_STATUS'
                   TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               MOVE 'REGSTS00: DB2 ERROR ON STATUS HISTORY'
                   TO WS-OUT-MESSAGE
               GO TO 6500-EXIT
           END-IF
      *
      *    LOG THE STATUS UPDATE
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'REGISTRATION' TO WS-LOG-TABLE-NAME
           MOVE 'STATUS' TO WS-LOG-ACTION
           MOVE WS-IN-REG-ID TO WS-LOG-KEY-VALUE
           STRING 'STATUS UPDATE ID=' WS-IN-REG-ID
                  ' FROM=' WS-HV-RG-REG-STATUS
                  ' TO=' WS-IN-NEW-STATUS
                  DELIMITED BY '  '
               INTO WS-LOG-DETAILS
           END-STRING
           CALL 'COMLGEL0' USING WS-LOG-FUNCTION
                                 WS-LOG-PROGRAM
                                 WS-LOG-TABLE-NAME
                                 WS-LOG-ACTION
                                 WS-LOG-KEY-VALUE
                                 WS-LOG-DETAILS
                                 WS-LOG-RETURN-CODE
      *
           STRING 'REGISTRATION STATUS UPDATED TO '
                  WS-OUT-NEW-STATUS
                  DELIMITED BY '  '
               INTO WS-OUT-MESSAGE
           END-STRING
           .
       6500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    8000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       8000-SEND-OUTPUT.
      *
           COMPUTE WS-OUT-LL =
               FUNCTION LENGTH(WS-OUTPUT-MSG)
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-STATUS NOT = '  '
               CONTINUE
           END-IF
           .
      ****************************************************************
      * END OF REGSTS00                                              *
      ****************************************************************
