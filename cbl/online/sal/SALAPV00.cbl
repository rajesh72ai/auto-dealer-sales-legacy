       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALAPV00.
      ****************************************************************
      * PROGRAM:    SALAPV00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     SAL - SALES PROCESS                              *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * IMS TRAN:   SALA                                             *
      * MFS MID:    MFSSLINP (SALES INPUT SCREEN)                    *
      * MFS MOD:    ASSLAP00 (APPROVAL RESPONSE)                     *
      *                                                              *
      * PURPOSE:    SALES APPROVAL WORKFLOW. VALIDATES APPROVER HAS  *
      *             AUTHORITY (USER TYPE M=MANAGER OR ABOVE).         *
      *             DEALS BELOW $500 FRONT GROSS: AUTO-APPROVE IF    *
      *             MANAGER. DEALS BELOW $0 GROSS (LOSER DEAL):      *
      *             REQUIRES GM (GENERAL MANAGER). INSERTS           *
      *             SALES_APPROVAL RECORD. ON APPROVE: STATUS TO AP, *
      *             ADVANCES TO F&I. ON REJECT: STATUS BACK TO NE    *
      *             WITH REJECTION COMMENTS.                         *
      *                                                              *
      * CALLS:      COMLGEL0 - AUDIT LOG ENTRY                      *
      *             COMDBEL0 - DB2 ERROR HANDLING                    *
      *             COMMSGL0 - MESSAGE BUILDER                       *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL     (READ/UPDATE)            *
      *             AUTOSALE.SALES_APPROVAL  (INSERT)                *
      *             AUTOSALE.SYSTEM_USER     (READ)                  *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'SALAPV00'.
      *
           COPY WSIOPCB.
           COPY WSSQLCA.
           COPY WSMSGFMT.
      *
           COPY DCLSLDEL.
           COPY DCLSLAPV.
           COPY DCLSYUSR.
      *
      *    INPUT FIELDS
      *
       01  WS-APV-INPUT.
           05  WS-AI-DEAL-NUMBER    PIC X(10).
           05  WS-AI-APPROVER-ID   PIC X(08).
           05  WS-AI-ACTION        PIC X(02).
               88  WS-AI-ACT-APPROVE         VALUE 'AP'.
               88  WS-AI-ACT-REJECT          VALUE 'RJ'.
           05  WS-AI-COMMENTS      PIC X(200).
      *
      *    OUTPUT LAYOUT
      *
       01  WS-APV-OUTPUT.
           05  WS-AO-HEADER.
               10  FILLER           PIC X(30)
                   VALUE '--- SALES APPROVAL -----------'.
               10  FILLER           PIC X(10)
                   VALUE '  DEAL #: '.
               10  WS-AO-DEAL-NUM  PIC X(10).
               10  FILLER           PIC X(29) VALUE SPACES.
           05  WS-AO-DEAL-LINE.
               10  FILLER           PIC X(14)
                   VALUE 'VEHICLE PRICE:'.
               10  WS-AO-VEH-PRICE PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(14)
                   VALUE '  FRONT GROSS:'.
               10  WS-AO-GROSS     PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(22) VALUE SPACES.
           05  WS-AO-GROSS-LINE.
               10  FILLER           PIC X(14)
                   VALUE 'TOTAL PRICE:  '.
               10  WS-AO-TOTAL     PIC $$$,$$$,$$9.99.
               10  FILLER           PIC X(14)
                   VALUE '  TOTAL GROSS:'.
               10  WS-AO-TOT-GROSS PIC $$$,$$$,$$9.99-.
               10  FILLER           PIC X(22) VALUE SPACES.
           05  WS-AO-BLANK-1       PIC X(79) VALUE SPACES.
           05  WS-AO-AUTH-LINE.
               10  FILLER           PIC X(10)
                   VALUE 'APPROVER: '.
               10  WS-AO-APPRVR-ID PIC X(08).
               10  FILLER           PIC X(08)
                   VALUE '  TYPE: '.
               10  WS-AO-APPRVR-TY PIC X(01).
               10  FILLER           PIC X(10)
                   VALUE '  ACTION: '.
               10  WS-AO-ACTION    PIC X(10).
               10  FILLER           PIC X(32) VALUE SPACES.
           05  WS-AO-STATUS-LINE.
               10  FILLER           PIC X(12)
                   VALUE 'OLD STATUS: '.
               10  WS-AO-OLD-STAT  PIC X(02).
               10  FILLER           PIC X(14)
                   VALUE '  NEW STATUS: '.
               10  WS-AO-NEW-STAT  PIC X(02).
               10  FILLER           PIC X(49) VALUE SPACES.
           05  WS-AO-BLANK-2       PIC X(79) VALUE SPACES.
           05  WS-AO-THRESH-LINE.
               10  FILLER           PIC X(22)
                   VALUE 'APPROVAL THRESHOLD:   '.
               10  WS-AO-THRESH    PIC X(30).
               10  FILLER           PIC X(27) VALUE SPACES.
           05  WS-AO-COMMENT-LINE.
               10  FILLER           PIC X(10)
                   VALUE 'COMMENTS: '.
               10  WS-AO-COMMENTS  PIC X(69).
           05  WS-AO-FILLER        PIC X(950) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ERROR-MSG        PIC X(79) VALUE SPACES.
           05  WS-RETURN-CODE      PIC S9(04) COMP VALUE +0.
           05  WS-APPROVER-TYPE    PIC X(01) VALUE SPACES.
           05  WS-OLD-STATUS       PIC X(02) VALUE SPACES.
           05  WS-NEW-STATUS       PIC X(02) VALUE SPACES.
           05  WS-THRESHOLD-MSG    PIC X(30) VALUE SPACES.
           05  WS-GROSS-THRESHOLD  PIC S9(05)V99 COMP-3
                                              VALUE +500.00.
      *
      *    AUDIT LOG
      *
       01  WS-LOG-REQUEST.
           05  WS-LR-PROGRAM       PIC X(08).
           05  WS-LR-FUNCTION      PIC X(08).
           05  WS-LR-USER-ID       PIC X(08).
           05  WS-LR-ENTITY-TYPE   PIC X(08).
           05  WS-LR-ENTITY-KEY    PIC X(30).
           05  WS-LR-DESCRIPTION   PIC X(80).
           05  WS-LR-RETURN-CODE   PIC S9(04) COMP.
      *
      *    DB2 ERROR HANDLER
      *
       01  WS-DBE-REQUEST.
           05  WS-DBE-PROGRAM      PIC X(08).
           05  WS-DBE-PARAGRAPH    PIC X(30).
           05  WS-DBE-SQLCODE      PIC S9(09) COMP.
           05  WS-DBE-SQLERRM      PIC X(70).
           05  WS-DBE-TABLE-NAME   PIC X(30).
           05  WS-DBE-OPERATION    PIC X(10).
       01  WS-DBE-RESULT.
           05  WS-DBE-RETURN-CODE  PIC S9(04) COMP.
           05  WS-DBE-RETURN-MSG   PIC X(79).
      *
      *    MESSAGE BUILDER
      *
       01  WS-MSG-FUNCTION         PIC X(04).
       01  WS-MSG-TEXT             PIC X(79).
       01  WS-MSG-SEVERITY        PIC X(04).
       01  WS-MSG-PROGRAM-ID      PIC X(08).
       01  WS-MSG-OUTPUT-AREA     PIC X(256).
       01  WS-MSG-RETURN-CODE     PIC S9(04) COMP.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-IND.
           05  NI-COMMENTS         PIC S9(04) COMP VALUE +0.
           05  NI-SALES-MGR        PIC S9(04) COMP VALUE +0.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER              PIC X(10).
           05  IO-PCB-STATUS       PIC X(02).
           05  FILLER              PIC X(20).
           05  IO-PCB-MOD-NAME     PIC X(08).
           05  IO-PCB-USER-ID      PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER              PIC X(22).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3000-VALIDATE-DEAL
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3500-VALIDATE-APPROVER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4000-CHECK-AUTHORITY
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-PROCESS-APPROVAL
           END-IF
      *
           PERFORM 8000-FORMAT-OUTPUT
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
           INITIALIZE WS-APV-OUTPUT
           MOVE SPACES TO WS-ERROR-MSG
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT                                        *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-IO-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'SALAPV00: IMS GU FAILED' TO WS-ERROR-MSG
           ELSE
               MOVE WS-INP-KEY-DATA(1:10) TO WS-AI-DEAL-NUMBER
               MOVE WS-INP-BODY(1:8)   TO WS-AI-APPROVER-ID
               MOVE WS-INP-FUNCTION     TO WS-AI-ACTION
               MOVE WS-INP-BODY(9:200) TO WS-AI-COMMENTS
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-DEAL                                        *
      ****************************************************************
       3000-VALIDATE-DEAL.
      *
           IF WS-AI-DEAL-NUMBER = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NUMBER IS REQUIRED' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           EXEC SQL
               SELECT DEAL_NUMBER
                    , DEAL_STATUS
                    , VEHICLE_PRICE
                    , TOTAL_PRICE
                    , FRONT_GROSS
                    , TOTAL_GROSS
               INTO   :DEAL-NUMBER
                    , :DEAL-STATUS
                    , :VEHICLE-PRICE
                    , :TOTAL-PRICE
                    , :FRONT-GROSS
                    , :TOTAL-GROSS
               FROM   AUTOSALE.SALES_DEAL
               WHERE  DEAL_NUMBER = :WS-AI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'DEAL NOT FOUND' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR READING DEAL' TO WS-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
           MOVE DEAL-STATUS TO WS-OLD-STATUS
      *
      *    DEAL MUST BE PENDING APPROVAL
      *
           IF DEAL-STATUS NOT = 'PA'
           AND DEAL-STATUS NOT = 'NE'
           AND DEAL-STATUS NOT = 'WS'
               MOVE +8 TO WS-RETURN-CODE
               STRING 'DEAL STATUS ' DEAL-STATUS
                      ' - NOT PENDING APPROVAL'
                      DELIMITED BY SIZE
                      INTO WS-ERROR-MSG
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    3500-VALIDATE-APPROVER                                    *
      ****************************************************************
       3500-VALIDATE-APPROVER.
      *
           IF WS-AI-APPROVER-ID = SPACES
               MOVE IO-PCB-USER-ID TO WS-AI-APPROVER-ID
           END-IF
      *
           EXEC SQL
               SELECT USER_TYPE
               INTO   :WS-APPROVER-TYPE
               FROM   AUTOSALE.SYSTEM_USER
               WHERE  USER_ID = :WS-AI-APPROVER-ID
                 AND  ACTIVE_FLAG = 'Y'
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'APPROVER NOT FOUND OR INACTIVE'
                   TO WS-ERROR-MSG
               GO TO 3500-EXIT
           END-IF
      *
      *    MUST BE MANAGER (M), GENERAL MANAGER (G), OR ADMIN (A)
      *
           IF WS-APPROVER-TYPE NOT = 'M'
           AND WS-APPROVER-TYPE NOT = 'G'
           AND WS-APPROVER-TYPE NOT = 'A'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INSUFFICIENT AUTHORITY - MANAGER REQUIRED'
                   TO WS-ERROR-MSG
           END-IF
           .
       3500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CHECK-AUTHORITY - VERIFY APPROVAL LEVEL              *
      ****************************************************************
       4000-CHECK-AUTHORITY.
      *
      *    VALIDATE ACTION
      *
           IF NOT WS-AI-ACT-APPROVE AND NOT WS-AI-ACT-REJECT
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'INVALID ACTION - USE AP OR RJ'
                   TO WS-ERROR-MSG
               GO TO 4000-EXIT
           END-IF
      *
      *    FOR REJECTION - ANY MANAGER CAN REJECT
      *
           IF WS-AI-ACT-REJECT
               MOVE 'STANDARD - ANY MANAGER' TO WS-THRESHOLD-MSG
               GO TO 4000-EXIT
           END-IF
      *
      *    FOR APPROVAL - CHECK GROSS PROFIT THRESHOLDS
      *
      *    LOSER DEAL (FRONT GROSS < 0): REQUIRES GM
      *
           IF FRONT-GROSS < +0
               IF WS-APPROVER-TYPE NOT = 'G'
               AND WS-APPROVER-TYPE NOT = 'A'
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'LOSER DEAL - GM APPROVAL REQUIRED'
                       TO WS-ERROR-MSG
                   GO TO 4000-EXIT
               END-IF
               MOVE 'GM REQUIRED - NEGATIVE GROSS' TO
                   WS-THRESHOLD-MSG
               GO TO 4000-EXIT
           END-IF
      *
      *    LOW GROSS (FRONT GROSS < $500): MANAGER APPROVAL OK
      *
           IF FRONT-GROSS < WS-GROSS-THRESHOLD
               MOVE 'STANDARD MGR - LOW GROSS' TO
                   WS-THRESHOLD-MSG
           ELSE
               MOVE 'STANDARD MGR APPROVAL' TO WS-THRESHOLD-MSG
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-APPROVAL                                     *
      ****************************************************************
       5000-PROCESS-APPROVAL.
      *
      *    SET NULL INDICATOR FOR COMMENTS
      *
           IF WS-AI-COMMENTS = SPACES
               MOVE -1 TO NI-COMMENTS
           ELSE
               MOVE +0 TO NI-COMMENTS
           END-IF
      *
      *    INSERT APPROVAL RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.SALES_APPROVAL
               ( APPROVAL_ID
               , DEAL_NUMBER
               , APPROVAL_TYPE
               , APPROVER_ID
               , APPROVAL_STATUS
               , COMMENTS
               , APPROVAL_TS
               )
               VALUES
               ( DEFAULT
               , :WS-AI-DEAL-NUMBER
               , 'SA'
               , :WS-AI-APPROVER-ID
               , :WS-AI-ACTION
               , :WS-AI-COMMENTS :NI-COMMENTS
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR INSERTING APPROVAL RECORD'
                   TO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
      *    UPDATE DEAL STATUS BASED ON ACTION
      *
           IF WS-AI-ACT-APPROVE
               MOVE 'AP' TO WS-NEW-STATUS
           ELSE
               MOVE 'NE' TO WS-NEW-STATUS
           END-IF
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET DEAL_STATUS     = :WS-NEW-STATUS
                    , SALES_MANAGER_ID = :WS-AI-APPROVER-ID
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER = :WS-AI-DEAL-NUMBER
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +12 TO WS-RETURN-CODE
               MOVE 'ERROR UPDATING DEAL STATUS'
                   TO WS-ERROR-MSG
               GO TO 5000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE WS-MODULE-ID       TO WS-LR-PROGRAM
           MOVE 'APPROVE '         TO WS-LR-FUNCTION
           MOVE WS-AI-APPROVER-ID  TO WS-LR-USER-ID
           MOVE 'DEAL    '         TO WS-LR-ENTITY-TYPE
           MOVE WS-AI-DEAL-NUMBER  TO WS-LR-ENTITY-KEY
      *
           IF WS-AI-ACT-APPROVE
               STRING 'DEAL APPROVED: ' WS-AI-DEAL-NUMBER
                      ' BY ' WS-AI-APPROVER-ID
                      DELIMITED BY SIZE
                      INTO WS-LR-DESCRIPTION
           ELSE
               STRING 'DEAL REJECTED: ' WS-AI-DEAL-NUMBER
                      ' BY ' WS-AI-APPROVER-ID
                      DELIMITED BY SIZE
                      INTO WS-LR-DESCRIPTION
           END-IF
      *
           CALL 'COMLGEL0' USING WS-LOG-REQUEST
      *
      *    SEND MESSAGE NOTIFICATION
      *
           IF WS-AI-ACT-APPROVE
               MOVE 'APPR' TO WS-MSG-FUNCTION
               MOVE 'DEAL APPROVED - READY FOR F&I'
                   TO WS-MSG-TEXT
           ELSE
               MOVE 'REJT' TO WS-MSG-FUNCTION
               MOVE 'DEAL REJECTED - RETURNED TO NEGOTIATION'
                   TO WS-MSG-TEXT
           END-IF
           MOVE 'I' TO WS-MSG-SEVERITY
           MOVE WS-MODULE-ID TO WS-MSG-PROGRAM-ID
           CALL 'COMMSGL0' USING WS-MSG-FUNCTION
                                 WS-MSG-TEXT
                                 WS-MSG-SEVERITY
                                 WS-MSG-PROGRAM-ID
                                 WS-MSG-OUTPUT-AREA
                                 WS-MSG-RETURN-CODE
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    8000-FORMAT-OUTPUT                                        *
      ****************************************************************
       8000-FORMAT-OUTPUT.
      *
           IF WS-RETURN-CODE > +0
               MOVE WS-MODULE-ID TO WS-OUT-MSG-ID
               MOVE WS-ERROR-MSG TO WS-OUT-MSG-TEXT
               GO TO 8000-EXIT
           END-IF
      *
           MOVE WS-MODULE-ID TO WS-OUT-MSG-ID
      *
           IF WS-AI-ACT-APPROVE
               MOVE 'DEAL APPROVED SUCCESSFULLY'
                   TO WS-OUT-MSG-TEXT
           ELSE
               MOVE 'DEAL REJECTED - RETURNED TO NEGOTIATION'
                   TO WS-OUT-MSG-TEXT
           END-IF
      *
           MOVE WS-AI-DEAL-NUMBER TO WS-AO-DEAL-NUM
           MOVE VEHICLE-PRICE     TO WS-AO-VEH-PRICE
           MOVE FRONT-GROSS       TO WS-AO-GROSS
           MOVE TOTAL-PRICE       TO WS-AO-TOTAL
           MOVE TOTAL-GROSS       TO WS-AO-TOT-GROSS
           MOVE WS-AI-APPROVER-ID TO WS-AO-APPRVR-ID
           MOVE WS-APPROVER-TYPE  TO WS-AO-APPRVR-TY
      *
           IF WS-AI-ACT-APPROVE
               MOVE 'APPROVED' TO WS-AO-ACTION
           ELSE
               MOVE 'REJECTED' TO WS-AO-ACTION
           END-IF
      *
           MOVE WS-OLD-STATUS TO WS-AO-OLD-STAT
           MOVE WS-NEW-STATUS TO WS-AO-NEW-STAT
           MOVE WS-THRESHOLD-MSG TO WS-AO-THRESH
           MOVE WS-AI-COMMENTS(1:69) TO WS-AO-COMMENTS
      *
           MOVE WS-APV-OUTPUT TO WS-OUT-BODY
           .
       8000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-IO-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               CONTINUE
           END-IF
           .
      ****************************************************************
      * END OF SALAPV00                                              *
      ****************************************************************
