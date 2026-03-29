       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRCNOTF0.
      ****************************************************************
      * PROGRAM:  WRCNOTF0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   WRC - WARRANTY RECALL NOTIFICATION                 *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  GENERATES RECALL NOTIFICATIONS FOR AFFECTED        *
      *           VEHICLES. GIVEN A RECALL CAMPAIGN NUMBER:          *
      *           1. VALIDATES CAMPAIGN EXISTS AND IS ACTIVE         *
      *           2. OPENS CURSOR ON RECALL_VEHICLE TO FIND ALL      *
      *              AFFECTED VINS FOR THE CAMPAIGN                  *
      *           3. FOR EACH VIN, FINDS CURRENT OWNER VIA          *
      *              SALES_DEAL (LATEST DELIVERED DEAL)              *
      *           4. RETRIEVES CUSTOMER CONTACT INFO                 *
      *           5. CHECKS IF NOTIFICATION ALREADY EXISTS           *
      *           6. IF NOT, INSERTS RECALL_NOTIFICATION RECORD      *
      *           7. RETURNS COUNTS: CREATED, ALREADY-NOTIFIED,      *
      *              NO-OWNER-FOUND                                  *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    WRNF - WARRANTY RECALL NOTIFICATION                *
      * MFS MOD:  ASWRNF00                                           *
      * TABLES:   AUTOSALE.RECALL_CAMPAIGN   (READ)                  *
      *           AUTOSALE.RECALL_VEHICLE    (READ - CURSOR)         *
      *           AUTOSALE.SALES_DEAL        (READ)                  *
      *           AUTOSALE.CUSTOMER          (READ)                  *
      *           AUTOSALE.RECALL_NOTIFICATION (READ/INSERT)         *
      * CALLS:    COMDTEL0 - DATE CALCULATION                        *
      *           COMLGEL0 - AUDIT LOGGING                           *
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
                                          VALUE 'WRCNOTF0'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASWRNF00'.
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
           05  WS-IN-CAMPAIGN-NUM        PIC X(10).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-CAMPAIGN-NUM       PIC X(10).
           05  WS-OUT-CAMPAIGN-DESC      PIC X(60).
           05  WS-OUT-SEVERITY           PIC X(10).
           05  WS-OUT-CAMPAIGN-STATUS    PIC X(10).
           05  WS-OUT-TOTAL-AFFECTED     PIC Z(7)9.
           05  WS-OUT-NOTIF-CREATED      PIC Z(7)9.
           05  WS-OUT-ALREADY-NOTIFIED   PIC Z(7)9.
           05  WS-OUT-NO-OWNER           PIC Z(7)9.
           05  WS-OUT-ERRORS             PIC Z(7)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-NOTIF-CREATED-CT       PIC S9(09) COMP VALUE +0.
           05  WS-ALREADY-NOTIFIED-CT    PIC S9(09) COMP VALUE +0.
           05  WS-NO-OWNER-CT            PIC S9(09) COMP VALUE +0.
           05  WS-ERROR-CT               PIC S9(09) COMP VALUE +0.
           05  WS-FETCH-CT               PIC S9(09) COMP VALUE +0.
           05  WS-EXIST-COUNT            PIC S9(09) COMP VALUE +0.
           05  WS-END-OF-CURSOR          PIC X(01) VALUE 'N'.
               88  WS-CURSOR-DONE                  VALUE 'Y'.
               88  WS-CURSOR-NOT-DONE              VALUE 'N'.
           05  WS-PROCESS-FLAG           PIC X(01) VALUE 'Y'.
               88  WS-PROCESS-OK                   VALUE 'Y'.
               88  WS-PROCESS-ERROR                VALUE 'N'.
      *
      *    DB2 HOST VARIABLES - RECALL CAMPAIGN
      *
       01  WS-HV-CAMPAIGN.
           05  WS-HV-RC-ID               PIC X(10).
           05  WS-HV-RC-NHTSA-NUM        PIC X(12).
           05  WS-HV-RC-DESC             PIC X(200).
           05  WS-HV-RC-SEVERITY         PIC X(01).
           05  WS-HV-RC-AFFECTED-YEARS   PIC X(40).
           05  WS-HV-RC-AFFECTED-MODELS  PIC X(100).
           05  WS-HV-RC-REMEDY-DESC      PIC X(200).
           05  WS-HV-RC-STATUS           PIC X(01).
           05  WS-HV-RC-TOTAL-AFFECTED   PIC S9(09) COMP.
           05  WS-HV-RC-TOTAL-COMPLETED  PIC S9(09) COMP.
      *
      *    DB2 HOST VARIABLES - RECALL VEHICLE (CURSOR FETCH)
      *
       01  WS-HV-RECALL-VEH.
           05  WS-HV-RV-VIN              PIC X(17).
           05  WS-HV-RV-DEALER-CODE      PIC X(05).
           05  WS-HV-RV-STATUS           PIC X(02).
      *
      *    DB2 HOST VARIABLES - SALES DEAL (OWNER LOOKUP)
      *
       01  WS-HV-DEAL.
           05  WS-HV-DL-NUMBER           PIC X(10).
           05  WS-HV-DL-CUSTOMER-ID      PIC S9(09) COMP.
           05  WS-HV-DL-SALE-DATE        PIC X(10).
      *
      *    DB2 HOST VARIABLES - CUSTOMER CONTACT INFO
      *
       01  WS-HV-CUSTOMER.
           05  WS-HV-CU-ID              PIC S9(09) COMP.
           05  WS-HV-CU-FIRST-NAME      PIC X(30).
           05  WS-HV-CU-LAST-NAME       PIC X(30).
           05  WS-HV-CU-ADDR-LINE1      PIC X(50).
           05  WS-HV-CU-ADDR-LINE2      PIC X(50).
           05  WS-HV-CU-CITY            PIC X(30).
           05  WS-HV-CU-STATE           PIC X(02).
           05  WS-HV-CU-ZIP             PIC X(10).
           05  WS-HV-CU-CELL-PHONE      PIC X(10).
           05  WS-HV-CU-EMAIL           PIC X(60).
      *
      *    DB2 HOST VARIABLES - NOTIFICATION INSERT
      *
       01  WS-HV-NOTIFICATION.
           05  WS-HV-NF-CAMPAIGN-NUM     PIC X(10).
           05  WS-HV-NF-VIN              PIC X(17).
           05  WS-HV-NF-CUSTOMER-ID      PIC S9(09) COMP.
           05  WS-HV-NF-NOTIF-TYPE       PIC X(01).
           05  WS-HV-NF-NOTIF-DATE       PIC X(10).
           05  WS-HV-NF-RESPONSE-FLAG    PIC X(01).
      *
      *    DATE CALC MODULE LINKAGE
      *
       01  WS-DTE-FUNCTION               PIC X(04).
       01  WS-DTE-INPUT-DATE             PIC X(10).
       01  WS-DTE-YEARS                  PIC S9(04) COMP.
       01  WS-DTE-MONTHS                 PIC S9(04) COMP.
       01  WS-DTE-DAYS                   PIC S9(04) COMP.
       01  WS-DTE-OUTPUT-DATE            PIC X(10).
       01  WS-DTE-RETURN-CODE            PIC S9(04) COMP.
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
      *    SEVERITY DECODE TABLE
      *
       01  WS-SEVERITY-TABLE.
           05  WS-SEV-CRITICAL           PIC X(10) VALUE 'CRITICAL  '.
           05  WS-SEV-HIGH               PIC X(10) VALUE 'HIGH      '.
           05  WS-SEV-MEDIUM             PIC X(10) VALUE 'MEDIUM    '.
           05  WS-SEV-LOW                PIC X(10) VALUE 'LOW       '.
      *
      *    DISPLAY FIELDS FOR LOG MESSAGE
      *
       01  WS-DISP-CREATED               PIC Z(7)9.
       01  WS-DISP-ALREADY               PIC Z(7)9.
       01  WS-DISP-NOOWNER               PIC Z(7)9.
      *
      *    DECLARE CURSOR FOR AFFECTED VEHICLES
      *
           EXEC SQL
               DECLARE CSR_RECALL_VEH CURSOR FOR
               SELECT RV.VIN
                    , RV.DEALER_CODE
                    , RV.RECALL_STATUS
               FROM  AUTOSALE.RECALL_VEHICLE RV
               WHERE RV.RECALL_ID = :WS-IN-CAMPAIGN-NUM
                 AND RV.RECALL_STATUS = 'OP'
               ORDER BY RV.VIN
           END-EXEC.
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
               PERFORM 4000-LOOKUP-CAMPAIGN
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-PROCESS-VEHICLES
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6000-FORMAT-RESULTS
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
           INITIALIZE WS-HV-CAMPAIGN
           INITIALIZE WS-HV-RECALL-VEH
           INITIALIZE WS-HV-DEAL
           INITIALIZE WS-HV-CUSTOMER
           INITIALIZE WS-HV-NOTIFICATION
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'RECALL NOTIFICATION PROCESSOR' TO WS-OUT-TITLE
           MOVE 'N' TO WS-END-OF-CURSOR
           MOVE 'Y' TO WS-PROCESS-FLAG
      *
      *    GET CURRENT DATE FOR NOTIFICATION RECORDS
      *
           MOVE 'CURR' TO WS-DTE-FUNCTION
           MOVE SPACES TO WS-DTE-INPUT-DATE
           MOVE +0 TO WS-DTE-YEARS
           MOVE +0 TO WS-DTE-MONTHS
           MOVE +0 TO WS-DTE-DAYS
           CALL 'COMDTEL0' USING WS-DTE-FUNCTION
                                 WS-DTE-INPUT-DATE
                                 WS-DTE-YEARS
                                 WS-DTE-MONTHS
                                 WS-DTE-DAYS
                                 WS-DTE-OUTPUT-DATE
                                 WS-DTE-RETURN-CODE
      *
           IF WS-DTE-RETURN-CODE = +0
               MOVE WS-DTE-OUTPUT-DATE TO WS-CURRENT-DATE
           ELSE
               MOVE '2026-03-29' TO WS-CURRENT-DATE
           END-IF
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
               MOVE 'WRCNOTF0: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-CAMPAIGN-NUM = SPACES
               MOVE 'RECALL CAMPAIGN NUMBER IS REQUIRED'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    4000-LOOKUP-CAMPAIGN - VERIFY CAMPAIGN EXISTS AND ACTIVE  *
      ****************************************************************
       4000-LOOKUP-CAMPAIGN.
      *
           EXEC SQL
               SELECT RC.RECALL_ID
                    , RC.NHTSA_NUM
                    , RC.RECALL_DESC
                    , RC.SEVERITY
                    , RC.AFFECTED_YEARS
                    , RC.AFFECTED_MODELS
                    , RC.REMEDY_DESC
                    , RC.CAMPAIGN_STATUS
                    , RC.TOTAL_AFFECTED
                    , RC.TOTAL_COMPLETED
               INTO  :WS-HV-RC-ID
                    , :WS-HV-RC-NHTSA-NUM
                    , :WS-HV-RC-DESC
                    , :WS-HV-RC-SEVERITY
                    , :WS-HV-RC-AFFECTED-YEARS
                    , :WS-HV-RC-AFFECTED-MODELS
                    , :WS-HV-RC-REMEDY-DESC
                    , :WS-HV-RC-STATUS
                    , :WS-HV-RC-TOTAL-AFFECTED
                    , :WS-HV-RC-TOTAL-COMPLETED
               FROM  AUTOSALE.RECALL_CAMPAIGN RC
               WHERE RC.RECALL_ID = :WS-IN-CAMPAIGN-NUM
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE 'RECALL CAMPAIGN NOT FOUND'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
               WHEN OTHER
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '4000-LOOKUP-CAMPAIGN'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_CAMPAIGN'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'WRCNOTF0: DB2 ERROR READING CAMPAIGN'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    VERIFY CAMPAIGN IS ACTIVE
      *
           IF WS-HV-RC-STATUS NOT = 'A'
               MOVE 'CAMPAIGN IS NOT ACTIVE - CANNOT NOTIFY'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    POPULATE OUTPUT HEADER FIELDS
      *
           MOVE WS-IN-CAMPAIGN-NUM TO WS-OUT-CAMPAIGN-NUM
           MOVE WS-HV-RC-DESC(1:60) TO WS-OUT-CAMPAIGN-DESC
      *
           EVALUATE WS-HV-RC-SEVERITY
               WHEN 'C'
                   MOVE WS-SEV-CRITICAL TO WS-OUT-SEVERITY
               WHEN 'H'
                   MOVE WS-SEV-HIGH TO WS-OUT-SEVERITY
               WHEN 'M'
                   MOVE WS-SEV-MEDIUM TO WS-OUT-SEVERITY
               WHEN 'L'
                   MOVE WS-SEV-LOW TO WS-OUT-SEVERITY
               WHEN OTHER
                   MOVE 'UNKNOWN   ' TO WS-OUT-SEVERITY
           END-EVALUATE
      *
           MOVE 'ACTIVE    ' TO WS-OUT-CAMPAIGN-STATUS
           MOVE WS-HV-RC-TOTAL-AFFECTED TO WS-OUT-TOTAL-AFFECTED
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-VEHICLES - CURSOR LOOP OVER AFFECTED VINS    *
      ****************************************************************
       5000-PROCESS-VEHICLES.
      *
      *    OPEN THE RECALL VEHICLE CURSOR
      *
           EXEC SQL
               OPEN CSR_RECALL_VEH
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
               MOVE '5000-PROCESS-VEHICLES'
                   TO WS-DBE-PARAGRAPH
               MOVE 'RECALL_VEHICLE'
                   TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               MOVE 'WRCNOTF0: ERROR OPENING VEHICLE CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
      *    FETCH AND PROCESS EACH AFFECTED VEHICLE
      *
           PERFORM UNTIL WS-CURSOR-DONE
                      OR WS-PROCESS-ERROR
               PERFORM 5100-FETCH-VEHICLE
               IF WS-CURSOR-NOT-DONE
                  AND WS-PROCESS-OK
                   PERFORM 5200-FIND-OWNER
                   IF WS-PROCESS-OK
                       PERFORM 5300-CHECK-EXISTING-NOTIF
                   END-IF
                   IF WS-PROCESS-OK
                       PERFORM 5400-CREATE-NOTIFICATION
                   END-IF
               END-IF
           END-PERFORM
      *
      *    CLOSE THE CURSOR
      *
           EXEC SQL
               CLOSE CSR_RECALL_VEH
           END-EXEC
      *
      *    LOG THE PROCESSING RUN
      *
           MOVE WS-NOTIF-CREATED-CT TO WS-DISP-CREATED
           MOVE WS-ALREADY-NOTIFIED-CT TO WS-DISP-ALREADY
           MOVE WS-NO-OWNER-CT TO WS-DISP-NOOWNER
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'RECALL_NOTIFICATION' TO WS-LOG-TABLE-NAME
           MOVE 'INSERT' TO WS-LOG-ACTION
           MOVE WS-IN-CAMPAIGN-NUM TO WS-LOG-KEY-VALUE
           STRING 'RECALL NOTIF CAMPAIGN='
                  WS-IN-CAMPAIGN-NUM
                  ' CREATED=' WS-DISP-CREATED
                  ' EXISTING=' WS-DISP-ALREADY
                  ' NOOWNER=' WS-DISP-NOOWNER
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
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-VEHICLE - FETCH NEXT VIN FROM CURSOR           *
      ****************************************************************
       5100-FETCH-VEHICLE.
      *
           EXEC SQL
               FETCH CSR_RECALL_VEH
               INTO  :WS-HV-RV-VIN
                    , :WS-HV-RV-DEALER-CODE
                    , :WS-HV-RV-STATUS
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-FETCH-CT
               WHEN +100
                   MOVE 'Y' TO WS-END-OF-CURSOR
               WHEN OTHER
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '5100-FETCH-VEHICLE'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_VEHICLE'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'N' TO WS-PROCESS-FLAG
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5200-FIND-OWNER - FIND CURRENT OWNER VIA SALES_DEAL      *
      *    GETS THE LATEST DELIVERED DEAL FOR THIS VIN               *
      ****************************************************************
       5200-FIND-OWNER.
      *
           INITIALIZE WS-HV-DEAL
           INITIALIZE WS-HV-CUSTOMER
      *
           EXEC SQL
               SELECT D.DEAL_NUMBER
                    , D.CUSTOMER_ID
                    , D.SALE_DATE
               INTO  :WS-HV-DL-NUMBER
                    , :WS-HV-DL-CUSTOMER-ID
                    , :WS-HV-DL-SALE-DATE
               FROM  AUTOSALE.SALES_DEAL D
               WHERE D.VIN = :WS-HV-RV-VIN
                 AND D.DEAL_STATUS = 'DL'
               ORDER BY D.SALE_DATE DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   PERFORM 5210-GET-CUSTOMER
               WHEN +100
                   ADD +1 TO WS-NO-OWNER-CT
               WHEN OTHER
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '5200-FIND-OWNER'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.SALES_DEAL'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   ADD +1 TO WS-ERROR-CT
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5210-GET-CUSTOMER - RETRIEVE CUSTOMER CONTACT INFO        *
      ****************************************************************
       5210-GET-CUSTOMER.
      *
           EXEC SQL
               SELECT C.CUSTOMER_ID
                    , C.FIRST_NAME
                    , C.LAST_NAME
                    , C.ADDRESS_LINE1
                    , C.ADDRESS_LINE2
                    , C.CITY
                    , C.STATE_CODE
                    , C.ZIP_CODE
                    , C.CELL_PHONE
                    , C.EMAIL
               INTO  :WS-HV-CU-ID
                    , :WS-HV-CU-FIRST-NAME
                    , :WS-HV-CU-LAST-NAME
                    , :WS-HV-CU-ADDR-LINE1
                    , :WS-HV-CU-ADDR-LINE2
                    , :WS-HV-CU-CITY
                    , :WS-HV-CU-STATE
                    , :WS-HV-CU-ZIP
                    , :WS-HV-CU-CELL-PHONE
                    , :WS-HV-CU-EMAIL
               FROM  AUTOSALE.CUSTOMER C
               WHERE C.CUSTOMER_ID = :WS-HV-DL-CUSTOMER-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   ADD +1 TO WS-NO-OWNER-CT
                   INITIALIZE WS-HV-CUSTOMER
               WHEN OTHER
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '5210-GET-CUSTOMER'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.CUSTOMER'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   ADD +1 TO WS-ERROR-CT
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5300-CHECK-EXISTING-NOTIF - SKIP IF ALREADY NOTIFIED      *
      ****************************************************************
       5300-CHECK-EXISTING-NOTIF.
      *
      *    IF CUSTOMER NOT FOUND, SKIP NOTIFICATION
      *
           IF WS-HV-CU-ID = +0
               GO TO 5300-EXIT
           END-IF
      *
           MOVE +0 TO WS-EXIST-COUNT
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO  :WS-EXIST-COUNT
               FROM  AUTOSALE.RECALL_NOTIFICATION RN
               WHERE RN.RECALL_ID = :WS-IN-CAMPAIGN-NUM
                 AND RN.VIN       = :WS-HV-RV-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   IF WS-EXIST-COUNT > +0
                       ADD +1 TO WS-ALREADY-NOTIFIED-CT
                       INITIALIZE WS-HV-CUSTOMER
                   END-IF
               WHEN OTHER
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '5300-CHECK-EXISTING-NOTIF'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_NOTIFICATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   ADD +1 TO WS-ERROR-CT
           END-EVALUATE
           .
       5300-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5400-CREATE-NOTIFICATION - INSERT NOTIFICATION RECORD     *
      ****************************************************************
       5400-CREATE-NOTIFICATION.
      *
      *    IF CUSTOMER WAS CLEARED (ALREADY NOTIFIED OR NOT FOUND)
      *    SKIP THE INSERT
      *
           IF WS-HV-CU-ID = +0
               GO TO 5400-EXIT
           END-IF
      *
      *    DETERMINE NOTIFICATION METHOD BASED ON AVAILABLE CONTACT
      *
           IF WS-HV-CU-EMAIL NOT = SPACES
               MOVE 'E' TO WS-HV-NF-NOTIF-TYPE
           ELSE IF WS-HV-CU-CELL-PHONE NOT = SPACES
               MOVE 'P' TO WS-HV-NF-NOTIF-TYPE
           ELSE
               MOVE 'M' TO WS-HV-NF-NOTIF-TYPE
           END-IF
      *
      *    BUILD NOTIFICATION RECORD
      *
           MOVE WS-IN-CAMPAIGN-NUM TO WS-HV-NF-CAMPAIGN-NUM
           MOVE WS-HV-RV-VIN TO WS-HV-NF-VIN
           MOVE WS-HV-CU-ID TO WS-HV-NF-CUSTOMER-ID
           MOVE WS-CURRENT-DATE TO WS-HV-NF-NOTIF-DATE
           MOVE 'N' TO WS-HV-NF-RESPONSE-FLAG
      *
      *    INSERT INTO RECALL_NOTIFICATION
      *    (NOTIF_ID IS GENERATED ALWAYS AS IDENTITY)
      *
           EXEC SQL
               INSERT INTO AUTOSALE.RECALL_NOTIFICATION
               ( RECALL_ID
               , VIN
               , CUSTOMER_ID
               , NOTIF_TYPE
               , NOTIF_DATE
               , RESPONSE_FLAG
               )
               VALUES
               ( :WS-HV-NF-CAMPAIGN-NUM
               , :WS-HV-NF-VIN
               , :WS-HV-NF-CUSTOMER-ID
               , :WS-HV-NF-NOTIF-TYPE
               , :WS-HV-NF-NOTIF-DATE
               , :WS-HV-NF-RESPONSE-FLAG
               )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-NOTIF-CREATED-CT
               WHEN OTHER
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '5400-CREATE-NOTIFICATION'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_NOTIFICATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   ADD +1 TO WS-ERROR-CT
           END-EVALUATE
      *
      *    UPDATE RECALL_VEHICLE NOTIFIED DATE
      *
           IF SQLCODE = +0
               EXEC SQL
                   UPDATE AUTOSALE.RECALL_VEHICLE
                   SET    NOTIFIED_DATE = :WS-CURRENT-DATE
                   WHERE  RECALL_ID = :WS-IN-CAMPAIGN-NUM
                     AND  VIN       = :WS-HV-RV-VIN
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE 'WRCNOTF0' TO WS-DBE-PROGRAM
                   MOVE '5400-CREATE-NOTIFICATION'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'RECALL_VEHICLE'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
               END-IF
           END-IF
           .
       5400-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-FORMAT-RESULTS - BUILD OUTPUT SUMMARY MESSAGE        *
      ****************************************************************
       6000-FORMAT-RESULTS.
      *
           MOVE WS-NOTIF-CREATED-CT TO WS-OUT-NOTIF-CREATED
           MOVE WS-ALREADY-NOTIFIED-CT TO WS-OUT-ALREADY-NOTIFIED
           MOVE WS-NO-OWNER-CT TO WS-OUT-NO-OWNER
           MOVE WS-ERROR-CT TO WS-OUT-ERRORS
      *
           IF WS-NOTIF-CREATED-CT > +0
               MOVE WS-NOTIF-CREATED-CT TO WS-DISP-CREATED
               STRING 'NOTIFICATIONS GENERATED: '
                      WS-DISP-CREATED
                      DELIMITED BY '  '
                   INTO WS-OUT-MESSAGE
               END-STRING
           ELSE IF WS-FETCH-CT = +0
               MOVE 'NO OPEN RECALL VEHICLES FOUND FOR CAMPAIGN'
                   TO WS-OUT-MESSAGE
           ELSE IF WS-ALREADY-NOTIFIED-CT = WS-FETCH-CT
               MOVE 'ALL VEHICLES ALREADY NOTIFIED FOR CAMPAIGN'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE 'NOTIFICATION PROCESSING COMPLETE - SEE COUNTS'
                   TO WS-OUT-MESSAGE
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
      * END OF WRCNOTF0                                              *
      ****************************************************************
