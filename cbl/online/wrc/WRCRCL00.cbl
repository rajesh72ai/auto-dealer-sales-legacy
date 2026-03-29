       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRCRCL00.
      ****************************************************************
      * PROGRAM:  WRCRCL00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   WRC - RECALL MANAGEMENT ONLINE                     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ONLINE RECALL MANAGEMENT WITH THREE FUNCTIONS:     *
      *           INQ - RECALL CAMPAIGN DETAIL                       *
      *           VEH - LIST AFFECTED VEHICLES FOR A CAMPAIGN        *
      *           UPD - UPDATE VEHICLE RECALL STATUS                 *
      *             SC=SCHEDULED, IP=IN-PROGRESS, CM=COMPLETE,       *
      *             NA=NOT-APPLICABLE                                *
      *           ON COMPLETE: INCREMENTS TOTAL_COMPLETED COUNT.     *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    WRCR - RECALL MANAGEMENT                           *
      * MFS MOD:  ASWRCR00                                           *
      * TABLES:   AUTOSALE.RECALL_CAMPAIGN (READ/UPDATE)             *
      *           AUTOSALE.RECALL_VEHICLE  (READ/UPDATE)             *
      *           AUTOSALE.VEHICLE         (READ)                    *
      * CALLS:    COMLGEL0 - AUDIT LOGGING                           *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
      *           COMFMTL0 - FIELD FORMATTING                        *
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
                                          VALUE 'WRCRCL00'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASWRCR00'.
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
           05  WS-IN-FUNCTION            PIC X(03).
               88  WS-IN-FN-INQ                      VALUE 'INQ'.
               88  WS-IN-FN-VEH                      VALUE 'VEH'.
               88  WS-IN-FN-UPD                      VALUE 'UPD'.
           05  WS-IN-CAMPAIGN-ID         PIC X(10).
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-NEW-STATUS          PIC X(02).
           05  WS-IN-STATUS-FILTER       PIC X(02).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
      *    CAMPAIGN DETAIL (INQ FUNCTION)
           05  WS-OUT-CAMPAIGN-ID        PIC X(10).
           05  WS-OUT-NHTSA-NUMBER       PIC X(12).
           05  WS-OUT-CAMPAIGN-DESC      PIC X(60).
           05  WS-OUT-SEVERITY           PIC X(08).
           05  WS-OUT-AFFECTED-MODELS    PIC X(40).
           05  WS-OUT-REMEDY-DESC        PIC X(60).
           05  WS-OUT-TOTAL-AFFECTED     PIC Z(5)9.
           05  WS-OUT-TOTAL-COMPLETED    PIC Z(5)9.
      *    VEHICLE LIST (VEH FUNCTION)
           05  WS-OUT-VEH-COUNT          PIC S9(04) COMP.
           05  WS-OUT-VEH-DTL OCCURS 10 TIMES.
               10  WS-OUT-VEH-VIN        PIC X(17).
               10  WS-OUT-VEH-DESC       PIC X(25).
               10  WS-OUT-VEH-STATUS     PIC X(02).
               10  WS-OUT-VEH-SCHED-DT   PIC X(10).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-ROW-COUNT              PIC S9(04) COMP VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-OLD-STATUS             PIC X(02).
      *
      *    DB2 HOST VARIABLES - CAMPAIGN
      *
       01  WS-HV-CAMPAIGN.
           05  WS-HV-RC-ID              PIC X(10).
           05  WS-HV-RC-NHTSA           PIC X(12).
           05  WS-HV-RC-DESC            PIC X(60).
           05  WS-HV-RC-SEVERITY        PIC X(08).
           05  WS-HV-RC-MODELS          PIC X(40).
           05  WS-HV-RC-REMEDY          PIC X(60).
           05  WS-HV-RC-TOTAL-AFF       PIC S9(06) COMP.
           05  WS-HV-RC-TOTAL-CMP       PIC S9(06) COMP.
      *
      *    DB2 HOST VARIABLES - VEHICLE RECALL
      *
       01  WS-HV-RV.
           05  WS-HV-RV-VIN             PIC X(17).
           05  WS-HV-RV-STATUS          PIC X(02).
           05  WS-HV-RV-SCHED-DATE      PIC X(10).
           05  WS-HV-RV-VEH-DESC        PIC X(25).
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
      *    DB ERROR MODULE LINKAGE
      *
       01  WS-DBE-SQLCODE                PIC S9(09) COMP.
       01  WS-DBE-PROGRAM                PIC X(08).
       01  WS-DBE-PARAGRAPH              PIC X(30).
       01  WS-DBE-TABLE-NAME             PIC X(18).
       01  WS-DBE-RETURN-CODE            PIC S9(04) COMP.
      *
      *    FORMAT MODULE LINKAGE
      *
       01  WS-FMT-FUNCTION               PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA        PIC X(40).
           05  WS-FMT-INPUT-NUM          PIC S9(09)V99 COMP-3.
       01  WS-FMT-OUTPUT                 PIC X(40).
       01  WS-FMT-RETURN-CODE            PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG              PIC X(50).
      *
      *    CURSOR FOR AFFECTED VEHICLES
      *
           EXEC SQL DECLARE CSR_RCL_VEH CURSOR FOR
               SELECT RV.VIN
                    , RV.RECALL_STATUS
                    , RV.SCHEDULED_DATE
                    , SUBSTR(M.MODEL_NAME, 1, 25)
               FROM   AUTOSALE.RECALL_VEHICLE RV
               JOIN   AUTOSALE.VEHICLE V
                 ON   RV.VIN = V.VIN
               JOIN   AUTOSALE.MODEL_MASTER M
                 ON   V.MODEL_YEAR = M.MODEL_YEAR
                AND   V.MAKE_CODE  = M.MAKE_CODE
                AND   V.MODEL_CODE = M.MODEL_CODE
               WHERE  RV.CAMPAIGN_ID = :WS-IN-CAMPAIGN-ID
                 AND  (RV.RECALL_STATUS = :WS-IN-STATUS-FILTER
                       OR :WS-IN-STATUS-FILTER = '  ')
               ORDER BY RV.VIN
           END-EXEC
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
               EVALUATE TRUE
                   WHEN WS-IN-FN-INQ
                       PERFORM 4000-CAMPAIGN-INQUIRY
                   WHEN WS-IN-FN-VEH
                       PERFORM 5000-VEHICLE-LIST
                   WHEN WS-IN-FN-UPD
                       PERFORM 6000-UPDATE-STATUS
                   WHEN OTHER
                       MOVE 'INVALID FUNCTION - USE INQ, VEH, OR UPD'
                           TO WS-OUT-MESSAGE
               END-EVALUATE
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
           MOVE 'RECALL MANAGEMENT' TO WS-OUT-TITLE
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
               MOVE 'WRCRCL00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-CAMPAIGN-ID = SPACES
               MOVE 'CAMPAIGN ID IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-FN-UPD
               IF WS-IN-VIN = SPACES
                   MOVE 'VIN IS REQUIRED FOR STATUS UPDATE'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
               IF WS-IN-NEW-STATUS NOT = 'SC'
               AND WS-IN-NEW-STATUS NOT = 'IP'
               AND WS-IN-NEW-STATUS NOT = 'CM'
               AND WS-IN-NEW-STATUS NOT = 'NA'
                   MOVE 'INVALID STATUS - USE SC, IP, CM, OR NA'
                       TO WS-OUT-MESSAGE
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CAMPAIGN-INQUIRY - DISPLAY CAMPAIGN DETAIL           *
      ****************************************************************
       4000-CAMPAIGN-INQUIRY.
      *
           EXEC SQL
               SELECT RC.CAMPAIGN_ID
                    , RC.NHTSA_NUMBER
                    , RC.CAMPAIGN_DESCRIPTION
                    , RC.SEVERITY_LEVEL
                    , RC.AFFECTED_MODELS
                    , RC.REMEDY_DESCRIPTION
                    , RC.TOTAL_AFFECTED
                    , RC.TOTAL_COMPLETED
               INTO  :WS-HV-RC-ID
                    , :WS-HV-RC-NHTSA
                    , :WS-HV-RC-DESC
                    , :WS-HV-RC-SEVERITY
                    , :WS-HV-RC-MODELS
                    , :WS-HV-RC-REMEDY
                    , :WS-HV-RC-TOTAL-AFF
                    , :WS-HV-RC-TOTAL-CMP
               FROM  AUTOSALE.RECALL_CAMPAIGN RC
               WHERE RC.CAMPAIGN_ID = :WS-IN-CAMPAIGN-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE WS-HV-RC-ID TO WS-OUT-CAMPAIGN-ID
                   MOVE WS-HV-RC-NHTSA TO WS-OUT-NHTSA-NUMBER
                   MOVE WS-HV-RC-DESC TO WS-OUT-CAMPAIGN-DESC
                   MOVE WS-HV-RC-SEVERITY TO WS-OUT-SEVERITY
                   MOVE WS-HV-RC-MODELS TO WS-OUT-AFFECTED-MODELS
                   MOVE WS-HV-RC-REMEDY TO WS-OUT-REMEDY-DESC
                   MOVE WS-HV-RC-TOTAL-AFF TO WS-OUT-TOTAL-AFFECTED
                   MOVE WS-HV-RC-TOTAL-CMP TO WS-OUT-TOTAL-COMPLETED
                   MOVE 'RECALL CAMPAIGN DETAILS DISPLAYED'
                       TO WS-OUT-MESSAGE
               WHEN +100
                   MOVE 'RECALL CAMPAIGN NOT FOUND'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE 'WRCRCL00: DB2 ERROR READING CAMPAIGN'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-VEHICLE-LIST - LIST AFFECTED VEHICLES                *
      ****************************************************************
       5000-VEHICLE-LIST.
      *
           EXEC SQL OPEN CSR_RCL_VEH END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'WRCRCL00: ERROR OPENING VEHICLE CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 5100-FETCH-VEHICLE
               UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +10
      *
           EXEC SQL CLOSE CSR_RCL_VEH END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO AFFECTED VEHICLES FOUND FOR CAMPAIGN'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-ROW-COUNT TO WS-OUT-VEH-COUNT
               MOVE 'AFFECTED VEHICLES DISPLAYED'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-VEHICLE - FETCH ONE VEHICLE ROW                *
      ****************************************************************
       5100-FETCH-VEHICLE.
      *
           EXEC SQL FETCH CSR_RCL_VEH
               INTO  :WS-HV-RV-VIN
                    , :WS-HV-RV-STATUS
                    , :WS-HV-RV-SCHED-DATE
                    , :WS-HV-RV-VEH-DESC
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   MOVE WS-HV-RV-VIN
                       TO WS-OUT-VEH-VIN(WS-ROW-COUNT)
                   MOVE WS-HV-RV-VEH-DESC
                       TO WS-OUT-VEH-DESC(WS-ROW-COUNT)
                   MOVE WS-HV-RV-STATUS
                       TO WS-OUT-VEH-STATUS(WS-ROW-COUNT)
                   MOVE WS-HV-RV-SCHED-DATE
                       TO WS-OUT-VEH-SCHED-DT(WS-ROW-COUNT)
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'WRCRCL00: DB2 ERROR READING VEHICLES'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    6000-UPDATE-STATUS - UPDATE VEHICLE RECALL STATUS         *
      ****************************************************************
       6000-UPDATE-STATUS.
      *
      *    READ CURRENT STATUS
      *
           EXEC SQL
               SELECT RV.RECALL_STATUS
               INTO  :WS-OLD-STATUS
               FROM  AUTOSALE.RECALL_VEHICLE RV
               WHERE RV.CAMPAIGN_ID = :WS-IN-CAMPAIGN-ID
                 AND RV.VIN         = :WS-IN-VIN
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE 'VEHICLE NOT FOUND IN THIS RECALL CAMPAIGN'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
           IF SQLCODE NOT = +0
               MOVE 'WRCRCL00: DB2 ERROR READING RECALL VEHICLE'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
      *
      *    UPDATE RECALL VEHICLE STATUS
      *
           EXEC SQL
               UPDATE AUTOSALE.RECALL_VEHICLE
               SET    RECALL_STATUS     = :WS-IN-NEW-STATUS
                    , UPDATED_TIMESTAMP = CURRENT TIMESTAMP
                    , UPDATED_USER     = :IO-USER
               WHERE  CAMPAIGN_ID = :WS-IN-CAMPAIGN-ID
                 AND  VIN         = :WS-IN-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'WRCRCL00' TO WS-DBE-PROGRAM
               MOVE '6000-UPDATE-STATUS' TO WS-DBE-PARAGRAPH
               MOVE 'RECALL_VEHICLE' TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               MOVE 'WRCRCL00: DB2 ERROR UPDATING RECALL STATUS'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
      *
      *    IF COMPLETED, INCREMENT CAMPAIGN TOTAL
      *
           IF WS-IN-NEW-STATUS = 'CM'
           AND WS-OLD-STATUS NOT = 'CM'
               EXEC SQL
                   UPDATE AUTOSALE.RECALL_CAMPAIGN
                   SET    TOTAL_COMPLETED = TOTAL_COMPLETED + 1
                        , UPDATED_TIMESTAMP = CURRENT TIMESTAMP
                   WHERE  CAMPAIGN_ID = :WS-IN-CAMPAIGN-ID
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE 'WRCRCL00' TO WS-DBE-PROGRAM
                   MOVE '6000-UPDATE-STATUS' TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_CAMPAIGN' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
               END-IF
           END-IF
      *
      *    LOG THE UPDATE
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'RECALL_VEHICLE' TO WS-LOG-TABLE-NAME
           MOVE 'UPDATE' TO WS-LOG-ACTION
           STRING WS-IN-CAMPAIGN-ID '/' WS-IN-VIN
                  DELIMITED BY SIZE
               INTO WS-LOG-KEY-VALUE
           END-STRING
           STRING 'RECALL STATUS ' WS-OLD-STATUS
                  ' -> ' WS-IN-NEW-STATUS
                  DELIMITED BY SIZE
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
           MOVE 'RECALL STATUS UPDATED SUCCESSFULLY'
               TO WS-OUT-MESSAGE
           .
       6000-EXIT.
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
      * END OF WRCRCL00                                              *
      ****************************************************************
