       IDENTIFICATION DIVISION.
       PROGRAM-ID. REGSUB00.
      ****************************************************************
      * PROGRAM:  REGSUB00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   REG - REGISTRATION SUBMISSION TO STATE             *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  SUBMITS A VALIDATED REGISTRATION TO THE STATE      *
      *           DMV FOR PROCESSING. VERIFIES REGISTRATION IS IN    *
      *           'VL' (VALIDATED) STATUS BEFORE PROCEEDING.         *
      *           GENERATES A UNIQUE TRACKING NUMBER FOR THE         *
      *           SUBMISSION. UPDATES STATUS TO 'SB' (SUBMITTED)     *
      *           AND RECORDS THE SUBMISSION DATE. INSERTS A         *
      *           STATUS HISTORY RECORD INTO TITLE_STATUS TABLE.     *
      *           LOGS ALL ACTIVITY VIA COMLGEL0.                    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    RGSB - REGISTRATION SUBMISSION                     *
      * MFS MOD:  ASRGSB00                                           *
      * TABLES:   AUTOSALE.REGISTRATION  (READ/UPDATE)               *
      *           AUTOSALE.TITLE_STATUS  (INSERT)                    *
      *           AUTOSALE.VEHICLE       (READ)                      *
      *           AUTOSALE.CUSTOMER      (READ)                      *
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
                                          VALUE 'REGSUB00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASRGSB00'.
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
           05  WS-OUT-CUST-NAME          PIC X(25).
           05  WS-OUT-VEH-DESC           PIC X(20).
           05  WS-OUT-REG-STATE          PIC X(02).
           05  WS-OUT-REG-TYPE           PIC X(02).
           05  WS-OUT-REG-STATUS         PIC X(10).
           05  WS-OUT-SUBMIT-DATE        PIC X(10).
           05  WS-OUT-TRACKING-NUM       PIC X(15).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-TRACKING-NUMBER        PIC X(15).
           05  WS-TRACKING-SEQ           PIC S9(09) COMP VALUE +0.
           05  WS-TRACKING-SEQ-DISP      PIC 9(09).
           05  WS-STATUS-SEQ             PIC S9(04) COMP VALUE +0.
      *
      *    DB2 HOST VARIABLES - REGISTRATION
      *
       01  WS-HV-REG.
           05  WS-HV-RG-ID              PIC X(12).
           05  WS-HV-RG-DEAL-NUMBER     PIC X(10).
           05  WS-HV-RG-VIN             PIC X(17).
           05  WS-HV-RG-CUSTOMER-ID     PIC S9(09) COMP.
           05  WS-HV-RG-REG-STATE       PIC X(02).
           05  WS-HV-RG-REG-TYPE        PIC X(02).
           05  WS-HV-RG-REG-STATUS      PIC X(02).
      *
      *    DB2 HOST VARIABLES - VEHICLE DESC
      *
       01  WS-HV-VEH-DESC               PIC X(20).
      *
      *    DB2 HOST VARIABLES - CUSTOMER NAME
      *
       01  WS-HV-CUST-NAME              PIC X(25).
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
               PERFORM 5000-GENERATE-TRACKING
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6000-SUBMIT-REGISTRATION
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
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'REGISTRATION SUBMISSION' TO WS-OUT-TITLE
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
               MOVE 'REGSUB00: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'REGISTRATION ID IS REQUIRED FOR SUBMISSION'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    4000-LOOKUP-REGISTRATION - READ AND VERIFY STATUS         *
      ****************************************************************
       4000-LOOKUP-REGISTRATION.
      *
           EXEC SQL
               SELECT R.REG_ID
                    , R.DEAL_NUMBER
                    , R.VIN
                    , R.CUSTOMER_ID
                    , R.REG_STATE
                    , R.REG_TYPE
                    , R.REG_STATUS
               INTO  :WS-HV-RG-ID
                    , :WS-HV-RG-DEAL-NUMBER
                    , :WS-HV-RG-VIN
                    , :WS-HV-RG-CUSTOMER-ID
                    , :WS-HV-RG-REG-STATE
                    , :WS-HV-RG-REG-TYPE
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
                   MOVE 'REGSUB00' TO WS-DBE-PROGRAM
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
                   MOVE 'REGSUB00: DB2 ERROR READING REGISTRATION'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    VERIFY STATUS IS 'VL' (VALIDATED)
      *
           IF WS-HV-RG-REG-STATUS NOT = 'VL'
               MOVE 'REGISTRATION MUST BE VALIDATED BEFORE SUBMIT'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    LOOK UP VEHICLE DESCRIPTION
      *
           EXEC SQL
               SELECT SUBSTR(
                   STRIP(CHAR(V.MODEL_YEAR)) CONCAT ' '
                   CONCAT V.MAKE_CODE CONCAT ' '
                   CONCAT V.MODEL_CODE, 1, 20)
               INTO  :WS-HV-VEH-DESC
               FROM  AUTOSALE.VEHICLE V
               WHERE V.VIN = :WS-HV-RG-VIN
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE WS-HV-VEH-DESC TO WS-OUT-VEH-DESC
           END-IF
      *
      *    LOOK UP CUSTOMER NAME
      *
           EXEC SQL
               SELECT SUBSTR(
                   STRIP(C.LAST_NAME) CONCAT ', '
                   CONCAT STRIP(C.FIRST_NAME), 1, 25)
               INTO  :WS-HV-CUST-NAME
               FROM  AUTOSALE.CUSTOMER C
               WHERE C.CUSTOMER_ID = :WS-HV-RG-CUSTOMER-ID
           END-EXEC
      *
           IF SQLCODE = +0
               MOVE WS-HV-CUST-NAME TO WS-OUT-CUST-NAME
           END-IF
      *
      *    POPULATE OUTPUT FIELDS
      *
           MOVE WS-HV-RG-ID TO WS-OUT-REG-ID
           MOVE WS-HV-RG-DEAL-NUMBER TO WS-OUT-DEAL-NUMBER
           MOVE WS-HV-RG-VIN TO WS-OUT-VIN
           MOVE WS-HV-RG-REG-STATE TO WS-OUT-REG-STATE
           MOVE WS-HV-RG-REG-TYPE TO WS-OUT-REG-TYPE
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-GENERATE-TRACKING - CREATE UNIQUE TRACKING NUMBER    *
      ****************************************************************
       5000-GENERATE-TRACKING.
      *
      *    TRACKING FORMAT: REG + STATE + YYMMDD + SEQ (9 DIGITS)
      *    EXAMPLE: RGTX260329000000001
      *
           EXEC SQL
               SELECT NEXT VALUE FOR AUTOSALE.REG_TRACK_SEQ
               INTO  :WS-TRACKING-SEQ
               FROM  SYSIBM.SYSDUMMY1
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'REGSUB00: ERROR GENERATING TRACKING NUMBER'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE WS-TRACKING-SEQ TO WS-TRACKING-SEQ-DISP
      *
           MOVE SPACES TO WS-TRACKING-NUMBER
           STRING 'RG'
                  WS-HV-RG-REG-STATE
                  WS-CURRENT-DATE(3:2)
                  WS-CURRENT-DATE(6:2)
                  WS-CURRENT-DATE(9:2)
                  WS-TRACKING-SEQ-DISP(5:5)
                  DELIMITED BY SIZE
               INTO WS-TRACKING-NUMBER
           END-STRING
      *
           MOVE WS-TRACKING-NUMBER TO WS-OUT-TRACKING-NUM
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-SUBMIT-REGISTRATION - UPDATE TO SUBMITTED STATUS     *
      ****************************************************************
       6000-SUBMIT-REGISTRATION.
      *
           EXEC SQL
               UPDATE AUTOSALE.REGISTRATION
               SET    REG_STATUS      = 'SB'
                    , SUBMISSION_DATE = CURRENT DATE
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  REG_ID = :WS-IN-REG-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN OTHER
                   MOVE 'REGSUB00' TO WS-DBE-PROGRAM
                   MOVE '6000-SUBMIT-REGISTRATION'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.REGISTRATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGSUB00: DB2 ERROR UPDATING REGISTRATION'
                       TO WS-OUT-MESSAGE
                   GO TO 6000-EXIT
           END-EVALUATE
      *
           MOVE 'SUBMITTED ' TO WS-OUT-REG-STATUS
           MOVE WS-CURRENT-DATE TO WS-OUT-SUBMIT-DATE
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
               , 'SB'
               , 'SUBMITTED TO STATE DMV'
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'REGSUB00' TO WS-DBE-PROGRAM
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
               MOVE 'REGSUB00: DB2 ERROR ON STATUS HISTORY'
                   TO WS-OUT-MESSAGE
               GO TO 6500-EXIT
           END-IF
      *
      *    LOG THE SUBMISSION
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'REGISTRATION' TO WS-LOG-TABLE-NAME
           MOVE 'SUBMIT' TO WS-LOG-ACTION
           MOVE WS-IN-REG-ID TO WS-LOG-KEY-VALUE
           STRING 'REG SUBMITTED ID=' WS-IN-REG-ID
                  ' TRACK=' WS-TRACKING-NUMBER
                  ' STATE=' WS-HV-RG-REG-STATE
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
           MOVE 'REGISTRATION SUBMITTED TO STATE SUCCESSFULLY'
               TO WS-OUT-MESSAGE
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
      * END OF REGSUB00                                              *
      ****************************************************************
