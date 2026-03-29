       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRCRCLB0.
      ****************************************************************
      * PROGRAM:  WRCRCLB0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   WRC - RECALL BATCH (INBOUND MANUFACTURER FEED)     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PROCESSES INBOUND RECALL CAMPAIGN FEED FROM        *
      *           MANUFACTURER. INSERTS RECALL_CAMPAIGN RECORD,      *
      *           THEN FOR EACH VIN IN FEED: CHECKS IF VIN EXISTS    *
      *           IN VEHICLE TABLE, INSERTS RECALL_VEHICLE WITH      *
      *           STATUS OP (OPEN). SKIPS UNMATCHED VINS WITH        *
      *           WARNING. COUNTS: TOTAL IN FEED, MATCHED,           *
      *           UNMATCHED.                                         *
      * IMS:      ONLINE IMS DC TRANSACTION (BATCH TRIGGER)          *
      * TRANS:    WRRB - RECALL BATCH                                *
      * MFS MOD:  ASWRRB00                                           *
      * TABLES:   AUTOSALE.RECALL_CAMPAIGN (INSERT)                  *
      *           AUTOSALE.RECALL_VEHICLE  (INSERT)                  *
      *           AUTOSALE.VEHICLE         (READ)                    *
      * CALLS:    COMVALD0 - VIN VALIDATION                          *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
      *           COMLGEL0 - AUDIT LOGGING                           *
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
                                          VALUE 'WRCRCLB0'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASWRRB00'.
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
      *    CAMPAIGN HEADER + UP TO 50 VINS
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
      *    CAMPAIGN HEADER
           05  WS-IN-CAMPAIGN-ID         PIC X(10).
           05  WS-IN-NHTSA-NUMBER        PIC X(12).
           05  WS-IN-DESCRIPTION         PIC X(60).
           05  WS-IN-SEVERITY            PIC X(08).
           05  WS-IN-AFFECTED-MODELS     PIC X(40).
           05  WS-IN-REMEDY-DESC         PIC X(60).
      *    VIN LIST
           05  WS-IN-VIN-COUNT           PIC S9(04) COMP.
           05  WS-IN-VIN-LIST.
               10  WS-IN-VIN-ENTRY OCCURS 50 TIMES
                                          PIC X(17).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-CAMPAIGN-ID        PIC X(10).
           05  WS-OUT-TOTAL-IN-FEED      PIC Z(4)9.
           05  WS-OUT-MATCHED            PIC Z(4)9.
           05  WS-OUT-UNMATCHED          PIC Z(4)9.
           05  WS-OUT-ERRORS             PIC Z(4)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-VIN-INDEX              PIC S9(04) COMP VALUE +0.
           05  WS-MATCHED-COUNT          PIC S9(04) COMP VALUE +0.
           05  WS-UNMATCHED-COUNT        PIC S9(04) COMP VALUE +0.
           05  WS-ERROR-COUNT            PIC S9(04) COMP VALUE +0.
           05  WS-VEH-EXISTS             PIC S9(04) COMP VALUE +0.
           05  WS-CURRENT-VIN            PIC X(17).
      *
      *    VIN VALIDATION MODULE LINKAGE
      *
       01  WS-VAL-FUNCTION               PIC X(04).
       01  WS-VAL-INPUT                  PIC X(17).
       01  WS-VAL-OUTPUT                 PIC X(40).
       01  WS-VAL-RETURN-CODE            PIC S9(04) COMP.
       01  WS-VAL-ERROR-MSG              PIC X(50).
      *
      *    DB ERROR MODULE LINKAGE
      *
       01  WS-DBE-SQLCODE                PIC S9(09) COMP.
       01  WS-DBE-PROGRAM                PIC X(08).
       01  WS-DBE-PARAGRAPH              PIC X(30).
       01  WS-DBE-TABLE-NAME             PIC X(18).
       01  WS-DBE-RETURN-CODE            PIC S9(04) COMP.
      *
      *    LOG MODULE LINKAGE
      *
       01  WS-LOG-FUNCTION               PIC X(04).
       01  WS-LOG-PROGRAM                PIC X(08).
       01  WS-LOG-TABLE-NAME             PIC X(18).
       01  WS-LOG-ACTION                 PIC X(08).
       01  WS-LOG-KEY-VALUE              PIC X(40).
       01  WS-LOG-DETAILS                PIC X(200).
       01  WS-LOG-RETURN-CODE            PIC S9(04) COMP.
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
               PERFORM 4000-INSERT-CAMPAIGN
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-PROCESS-VINS
           END-IF
      *
           PERFORM 7000-FORMAT-OUTPUT
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
           MOVE 'RECALL BATCH - MANUFACTURER FEED' TO WS-OUT-TITLE
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
               MOVE 'WRCRCLB0: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED CAMPAIGN FIELDS      *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-CAMPAIGN-ID = SPACES
               MOVE 'CAMPAIGN ID IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-DESCRIPTION = SPACES
               MOVE 'CAMPAIGN DESCRIPTION IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-VIN-COUNT <= +0
               MOVE 'AT LEAST ONE VIN REQUIRED IN RECALL FEED'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-INSERT-CAMPAIGN - CREATE RECALL CAMPAIGN RECORD      *
      ****************************************************************
       4000-INSERT-CAMPAIGN.
      *
      *    CHECK IF CAMPAIGN ALREADY EXISTS
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO  :WS-VEH-EXISTS
               FROM  AUTOSALE.RECALL_CAMPAIGN RC
               WHERE RC.CAMPAIGN_ID = :WS-IN-CAMPAIGN-ID
           END-EXEC
      *
           IF WS-VEH-EXISTS > +0
               MOVE 'CAMPAIGN ALREADY EXISTS - USE UPDATE FUNCTION'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           EXEC SQL
               INSERT INTO AUTOSALE.RECALL_CAMPAIGN
               ( CAMPAIGN_ID
               , NHTSA_NUMBER
               , CAMPAIGN_DESCRIPTION
               , SEVERITY_LEVEL
               , AFFECTED_MODELS
               , REMEDY_DESCRIPTION
               , TOTAL_AFFECTED
               , TOTAL_COMPLETED
               , CAMPAIGN_STATUS
               , CREATED_TIMESTAMP
               , CREATED_USER
               )
               VALUES
               ( :WS-IN-CAMPAIGN-ID
               , :WS-IN-NHTSA-NUMBER
               , :WS-IN-DESCRIPTION
               , :WS-IN-SEVERITY
               , :WS-IN-AFFECTED-MODELS
               , :WS-IN-REMEDY-DESC
               , :WS-IN-VIN-COUNT
               , 0
               , 'AC'
               , CURRENT TIMESTAMP
               , :IO-USER
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'WRCRCLB0' TO WS-DBE-PROGRAM
               MOVE '4000-INSERT-CAMPAIGN' TO WS-DBE-PARAGRAPH
               MOVE 'RECALL_CAMPAIGN' TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               MOVE 'WRCRCLB0: DB2 ERROR INSERTING CAMPAIGN'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-IN-CAMPAIGN-ID TO WS-OUT-CAMPAIGN-ID
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-VINS - ITERATE VIN LIST AND INSERT           *
      ****************************************************************
       5000-PROCESS-VINS.
      *
           PERFORM VARYING WS-VIN-INDEX FROM +1 BY +1
               UNTIL WS-VIN-INDEX > WS-IN-VIN-COUNT
                  OR WS-VIN-INDEX > +50
      *
               MOVE WS-IN-VIN-ENTRY(WS-VIN-INDEX)
                   TO WS-CURRENT-VIN
      *
      *        SKIP BLANK VINS
      *
               IF WS-CURRENT-VIN = SPACES
                   ADD +1 TO WS-UNMATCHED-COUNT
                   EXIT PERFORM CYCLE
               END-IF
      *
      *        VALIDATE VIN FORMAT
      *
               MOVE 'VIN ' TO WS-VAL-FUNCTION
               MOVE WS-CURRENT-VIN TO WS-VAL-INPUT
               CALL 'COMVALD0' USING WS-VAL-FUNCTION
                                     WS-VAL-INPUT
                                     WS-VAL-OUTPUT
                                     WS-VAL-RETURN-CODE
                                     WS-VAL-ERROR-MSG
      *
               IF WS-VAL-RETURN-CODE NOT = +0
                   ADD +1 TO WS-UNMATCHED-COUNT
                   EXIT PERFORM CYCLE
               END-IF
      *
      *        CHECK IF VIN EXISTS IN VEHICLE TABLE
      *
               EXEC SQL
                   SELECT COUNT(*)
                   INTO  :WS-VEH-EXISTS
                   FROM  AUTOSALE.VEHICLE V
                   WHERE V.VIN = :WS-CURRENT-VIN
               END-EXEC
      *
               IF WS-VEH-EXISTS = +0
                   ADD +1 TO WS-UNMATCHED-COUNT
                   EXIT PERFORM CYCLE
               END-IF
      *
      *        INSERT RECALL VEHICLE RECORD
      *
               EXEC SQL
                   INSERT INTO AUTOSALE.RECALL_VEHICLE
                   ( CAMPAIGN_ID
                   , VIN
                   , RECALL_STATUS
                   , CREATED_TIMESTAMP
                   , CREATED_USER
                   )
                   VALUES
                   ( :WS-IN-CAMPAIGN-ID
                   , :WS-CURRENT-VIN
                   , 'OP'
                   , CURRENT TIMESTAMP
                   , :IO-USER
                   )
               END-EXEC
      *
               IF SQLCODE = +0
                   ADD +1 TO WS-MATCHED-COUNT
               ELSE
                   ADD +1 TO WS-ERROR-COUNT
                   MOVE 'WRCRCLB0' TO WS-DBE-PROGRAM
                   MOVE '5000-PROCESS-VINS' TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_VEHICLE' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
               END-IF
           END-PERFORM
      *
      *    LOG THE BATCH PROCESSING
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'RECALL_VEHICLE' TO WS-LOG-TABLE-NAME
           MOVE 'BATCH' TO WS-LOG-ACTION
           MOVE WS-IN-CAMPAIGN-ID TO WS-LOG-KEY-VALUE
           STRING 'RECALL BATCH: MATCHED=' WS-MATCHED-COUNT
                  ' UNMATCHED=' WS-UNMATCHED-COUNT
                  ' ERRORS=' WS-ERROR-COUNT
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
           .
      *
      ****************************************************************
      *    7000-FORMAT-OUTPUT - BUILD SUMMARY                        *
      ****************************************************************
       7000-FORMAT-OUTPUT.
      *
           MOVE WS-IN-VIN-COUNT TO WS-OUT-TOTAL-IN-FEED
           MOVE WS-MATCHED-COUNT TO WS-OUT-MATCHED
           MOVE WS-UNMATCHED-COUNT TO WS-OUT-UNMATCHED
           MOVE WS-ERROR-COUNT TO WS-OUT-ERRORS
      *
           IF WS-OUT-MESSAGE = SPACES
               IF WS-ERROR-COUNT > +0
                   MOVE 'RECALL BATCH COMPLETED WITH ERRORS'
                       TO WS-OUT-MESSAGE
               ELSE
                   MOVE 'RECALL BATCH PROCESSED SUCCESSFULLY'
                       TO WS-OUT-MESSAGE
               END-IF
           END-IF
           .
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
      * END OF WRCRCLB0                                              *
      ****************************************************************
