       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATVAL00.
      ****************************************************************
      * PROGRAM:    BATVAL00                                         *
      * SYSTEM:     AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * MODULE:     BAT - BATCH PROCESSING                           *
      * AUTHOR:     AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:       2026-03-29                                       *
      * REGION:     BMP (BATCH MESSAGE PROCESSING)                   *
      *                                                              *
      * PURPOSE:    DATA VALIDATION/INTEGRITY BATCH. RUNS WEEKLY TO: *
      *             1. CHECK ORPHANED RECORDS:                        *
      *                - DEALS WITHOUT VALID CUSTOMERS                *
      *                - VEHICLES WITHOUT VALID DEALERS               *
      *             2. VALIDATE VIN CHECKSUMS ON ALL VEHICLES USING  *
      *                COMVINL0 VIN DECODER MODULE                    *
      *             3. CHECK FOR DUPLICATE CUSTOMER RECORDS           *
      *                (SAME LAST NAME, FIRST NAME, DOB, DEALER)     *
      *             4. WRITE ALL EXCEPTIONS TO SYSPRINT REPORT       *
      *                                                              *
      * CHECKPOINT: EVERY 500 RECORDS PROCESSED VIA COMCKPL0        *
      *                                                              *
      * OUTPUT:     SYSPRINT DD - EXCEPTION REPORT (132 CHARS)       *
      *                                                              *
      * TABLES:     AUTOSALE.SALES_DEAL   (READ)                     *
      *             AUTOSALE.CUSTOMER     (READ)                     *
      *             AUTOSALE.VEHICLE      (READ/UPDATE)              *
      *             AUTOSALE.DEALER       (READ)                     *
      *             AUTOSALE.RESTART_CONTROL (READ/UPDATE)           *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REPORT-FILE
               ASSIGN TO SYSPRINT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
      *
       DATA DIVISION.
      *
       FILE SECTION.
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  REPORT-RECORD               PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID                PIC X(08) VALUE 'BATVAL00'.
      *
       01  WS-FILE-STATUS              PIC X(02) VALUE SPACES.
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    COPY CHECKPOINT/RESTART AREAS
      *
           COPY WSCKPT00.
           COPY WSRSTCTL.
      *
      *    PROCESSING COUNTERS
      *
       01  WS-COUNTERS.
           05  WS-ORPHAN-DEAL-CT       PIC S9(09) COMP VALUE +0.
           05  WS-ORPHAN-VEH-CT        PIC S9(09) COMP VALUE +0.
           05  WS-VIN-INVALID-CT       PIC S9(09) COMP VALUE +0.
           05  WS-VIN-CHECKED-CT       PIC S9(09) COMP VALUE +0.
           05  WS-DUP-CUSTOMER-CT      PIC S9(09) COMP VALUE +0.
           05  WS-TOTAL-EXCEPTIONS     PIC S9(09) COMP VALUE +0.
           05  WS-TOTAL-PROCESSED      PIC S9(09) COMP VALUE +0.
           05  WS-ERROR-COUNT          PIC S9(09) COMP VALUE +0.
      *
      *    CURRENT DATE FIELDS
      *
       01  WS-DATE-FIELDS.
           05  WS-CURRENT-DATE-DATA.
               10  WS-CURR-YYYY        PIC 9(04).
               10  WS-CURR-MM          PIC 9(02).
               10  WS-CURR-DD          PIC 9(02).
               10  FILLER              PIC X(13).
           05  WS-CURRENT-DATE         PIC X(10) VALUE SPACES.
      *
      *    REPORT CONTROL
      *
       01  WS-REPORT-CONTROLS.
           05  WS-PAGE-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-LINE-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-LINES-PER-PAGE       PIC S9(04) COMP VALUE +56.
      *
      *    REPORT LINES
      *
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(40)
               VALUE 'AUTOSALES DEALER MANAGEMENT SYSTEM      '.
           05  FILLER                  PIC X(30)
               VALUE ' DATA INTEGRITY EXCEPTION RPT '.
           05  FILLER                  PIC X(07) VALUE 'DATE: '.
           05  WS-RH1-DATE            PIC X(10).
           05  FILLER                  PIC X(06) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'PAGE: '.
           05  WS-RH1-PAGE            PIC Z(4)9.
           05  FILLER                  PIC X(27) VALUE SPACES.
      *
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(131) VALUE ALL '-'.
      *
       01  WS-SECTION-HEADER.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-SH-SECTION-NAME     PIC X(60).
           05  FILLER                  PIC X(71) VALUE SPACES.
      *
       01  WS-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-TYPE             PIC X(06).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-KEY              PIC X(20).
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-DL-DESC             PIC X(80).
           05  FILLER                  PIC X(23) VALUE SPACES.
      *
       01  WS-SUMMARY-LINE.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  WS-SM-LABEL            PIC X(40).
           05  WS-SM-COUNT            PIC Z(7)9.
           05  FILLER                  PIC X(83) VALUE SPACES.
      *
      *    CHECKPOINT CALL FIELDS
      *
       01  WS-CHKP-FUNCTION.
           05  WS-CF-FUNC-CODE        PIC X(04).
           05  WS-CF-PROGRAM-NAME     PIC X(08).
           05  WS-CF-JOB-NAME         PIC X(08).
           05  WS-CF-STEP-NAME        PIC X(08).
           05  WS-CF-CHECKPOINT-FREQ  PIC S9(07) COMP-3.
      *
       01  WS-CHKP-DATA.
           05  WS-CD-EYE-CATCHER     PIC X(08).
           05  WS-CD-PROGRAM-ID       PIC X(08).
           05  WS-CD-TIMESTAMP        PIC X(26).
           05  WS-CD-LAST-KEY         PIC X(50).
           05  WS-CD-RECORDS-PROC     PIC S9(09) COMP.
           05  WS-CD-USER-DATA        PIC X(139).
      *
       01  WS-CHKP-RESULT.
           05  WS-CR-RETURN-CODE      PIC S9(04) COMP.
           05  WS-CR-RETURN-MSG       PIC X(79).
           05  WS-CR-RESTART-FLAG     PIC X(01).
           05  WS-CR-CHECKPOINT-ID    PIC X(20).
           05  WS-CR-RECORDS-PROC     PIC S9(09) COMP.
           05  WS-CR-LAST-KEY         PIC X(50).
           05  WS-CR-IMS-STATUS       PIC X(02).
           05  WS-CR-SQLCODE          PIC S9(09) COMP.
           05  WS-CR-CHKP-COUNT       PIC S9(07) COMP-3.
      *
      *    VIN VALIDATION CALL FIELDS
      *
       01  WS-VIN-REQUEST.
           05  WS-VR-VIN              PIC X(17).
           05  WS-VR-FUNCTION         PIC X(04) VALUE 'VALD'.
      *
       01  WS-VIN-RESULT.
           05  WS-VR-RETURN-CODE      PIC S9(04) COMP.
           05  WS-VR-RETURN-MSG       PIC X(79).
           05  WS-VR-VALID-FLAG       PIC X(01).
               88  WS-VIN-VALID                  VALUE 'Y'.
               88  WS-VIN-NOT-VALID              VALUE 'N'.
           05  WS-VR-COUNTRY          PIC X(20).
           05  WS-VR-MANUFACTURER     PIC X(20).
           05  WS-VR-MODEL-YEAR       PIC X(04).
           05  WS-VR-PLANT            PIC X(01).
           05  WS-VR-SEQ-NUM          PIC X(06).
      *
      *    HOST VARIABLES - ORPHANED DEALS
      *
       01  WS-HV-ORPHAN-DEAL.
           05  WS-HV-OD-DEAL-NUMBER   PIC X(10).
           05  WS-HV-OD-CUSTOMER-ID   PIC S9(09) COMP.
           05  WS-HV-OD-DEALER-CODE   PIC X(05).
      *
      *    HOST VARIABLES - ORPHANED VEHICLES
      *
       01  WS-HV-ORPHAN-VEH.
           05  WS-HV-OV-VIN           PIC X(17).
           05  WS-HV-OV-DEALER-CODE   PIC X(05).
           05  WS-HV-OV-STATUS        PIC X(02).
      *
      *    HOST VARIABLES - VIN CHECK
      *
       01  WS-HV-VIN-CHECK.
           05  WS-HV-VC-VIN           PIC X(17).
           05  WS-HV-VC-DEALER-CODE   PIC X(05).
      *
      *    HOST VARIABLES - DUPLICATE CUSTOMERS
      *
       01  WS-HV-DUP-CUST.
           05  WS-HV-DC-CUST-ID-1     PIC S9(09) COMP.
           05  WS-HV-DC-CUST-ID-2     PIC S9(09) COMP.
           05  WS-HV-DC-LAST-NAME     PIC X(30).
           05  WS-HV-DC-FIRST-NAME    PIC X(30).
           05  WS-HV-DC-DEALER-CODE   PIC X(05).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CUST-ID-DISP        PIC Z(8)9.
           05  WS-CUST-ID2-DISP       PIC Z(8)9.
           05  WS-DESC-WORK           PIC X(80) VALUE SPACES.
      *
      *    EOF FLAGS
      *
       01  WS-EOF-FLAGS.
           05  WS-EOF-ORPHAN-DEAL     PIC X(01) VALUE 'N'.
               88  WS-ORPHAN-DEAL-DONE           VALUE 'Y'.
           05  WS-EOF-ORPHAN-VEH      PIC X(01) VALUE 'N'.
               88  WS-ORPHAN-VEH-DONE            VALUE 'Y'.
           05  WS-EOF-VIN-CHECK       PIC X(01) VALUE 'N'.
               88  WS-VIN-CHECK-DONE             VALUE 'Y'.
           05  WS-EOF-DUP-CUST        PIC X(01) VALUE 'N'.
               88  WS-DUP-CUST-DONE              VALUE 'Y'.
      *
      *    DB2 CURSORS
      *
      *    CURSOR: DEALS WITH NO MATCHING CUSTOMER
      *
           EXEC SQL DECLARE CSR_ORPHAN_DEAL CURSOR FOR
               SELECT SD.DEAL_NUMBER
                    , SD.CUSTOMER_ID
                    , SD.DEALER_CODE
               FROM   AUTOSALE.SALES_DEAL SD
               WHERE  NOT EXISTS (
                          SELECT 1
                          FROM   AUTOSALE.CUSTOMER C
                          WHERE  C.CUSTOMER_ID = SD.CUSTOMER_ID
                      )
                 AND  SD.DEAL_STATUS NOT IN ('CA', 'UW')
               ORDER BY SD.DEAL_NUMBER
           END-EXEC
      *
      *    CURSOR: VEHICLES WITH INVALID DEALER CODE
      *
           EXEC SQL DECLARE CSR_ORPHAN_VEH CURSOR FOR
               SELECT V.VIN
                    , V.DEALER_CODE
                    , V.VEHICLE_STATUS
               FROM   AUTOSALE.VEHICLE V
               WHERE  V.DEALER_CODE IS NOT NULL
                 AND  V.DEALER_CODE <> SPACES
                 AND  NOT EXISTS (
                          SELECT 1
                          FROM   AUTOSALE.DEALER D
                          WHERE  D.DEALER_CODE = V.DEALER_CODE
                      )
               ORDER BY V.VIN
           END-EXEC
      *
      *    CURSOR: ALL VEHICLES FOR VIN CHECKSUM VALIDATION
      *
           EXEC SQL DECLARE CSR_VIN_CHECK CURSOR FOR
               SELECT V.VIN
                    , V.DEALER_CODE
               FROM   AUTOSALE.VEHICLE V
               ORDER BY V.VIN
           END-EXEC
      *
      *    CURSOR: POTENTIAL DUPLICATE CUSTOMERS
      *
           EXEC SQL DECLARE CSR_DUP_CUST CURSOR FOR
               SELECT C1.CUSTOMER_ID
                    , C2.CUSTOMER_ID
                    , C1.LAST_NAME
                    , C1.FIRST_NAME
                    , C1.DEALER_CODE
               FROM   AUTOSALE.CUSTOMER C1
               INNER JOIN AUTOSALE.CUSTOMER C2
                 ON   C1.LAST_NAME    = C2.LAST_NAME
                 AND  C1.FIRST_NAME   = C2.FIRST_NAME
                 AND  C1.DATE_OF_BIRTH = C2.DATE_OF_BIRTH
                 AND  C1.DEALER_CODE  = C2.DEALER_CODE
                 AND  C1.CUSTOMER_ID  < C2.CUSTOMER_ID
               ORDER BY C1.LAST_NAME, C1.FIRST_NAME
           END-EXEC
      *
       PROCEDURE DIVISION.
      *
       0000-MAIN-CONTROL.
      *
           DISPLAY 'BATVAL00: DATA VALIDATION BATCH - START'
      *
           PERFORM 1000-INITIALIZE
           PERFORM 2000-OPEN-FILES
      *
           IF WS-FILE-STATUS = '00'
               PERFORM 2500-INIT-CHECKPOINT
               PERFORM 3000-CHECK-ORPHAN-DEALS
               PERFORM 4000-CHECK-ORPHAN-VEHICLES
               PERFORM 5000-VALIDATE-VINS
               PERFORM 6000-CHECK-DUPLICATE-CUSTS
               PERFORM 7000-PRINT-SUMMARY
           END-IF
      *
           PERFORM 8000-MARK-COMPLETE
           PERFORM 9000-CLOSE-FILES
      *
           DISPLAY 'BATVAL00: DATA VALIDATION BATCH - END'
      *
           STOP RUN.
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE FUNCTION CURRENT-DATE(1:8)
               TO WS-CURRENT-DATE-DATA
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
                  DELIMITED BY SIZE
                  INTO WS-CURRENT-DATE
      *
           DISPLAY 'BATVAL00: PROCESSING DATE = ' WS-CURRENT-DATE
      *
           INITIALIZE WS-COUNTERS
           .
      *
      ****************************************************************
      *    2000-OPEN-FILES                                           *
      ****************************************************************
       2000-OPEN-FILES.
      *
           OPEN OUTPUT REPORT-FILE
      *
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'BATVAL00: ERROR OPENING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
           .
      *
      ****************************************************************
      *    2500-INIT-CHECKPOINT                                      *
      ****************************************************************
       2500-INIT-CHECKPOINT.
      *
           MOVE 'INIT'     TO WS-CF-FUNC-CODE
           MOVE 'BATVAL00' TO WS-CF-PROGRAM-NAME
           MOVE 'BATVAL00' TO WS-CF-JOB-NAME
           MOVE 'VALIDAT ' TO WS-CF-STEP-NAME
           MOVE +500       TO WS-CF-CHECKPOINT-FREQ
      *
           INITIALIZE WS-CHKP-DATA
           MOVE 'ASCHKP00' TO WS-CD-EYE-CATCHER
           MOVE 'BATVAL00' TO WS-CD-PROGRAM-ID
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE > +4
               DISPLAY 'BATVAL00: CHECKPOINT INIT FAILED - '
                       WS-CR-RETURN-MSG
               MOVE +16 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           DISPLAY 'BATVAL00: ' WS-CR-RETURN-MSG
      *
           MOVE +500 TO WS-CHECKPOINT-FREQ
           .
      *
      ****************************************************************
      *    2700-PRINT-PAGE-HEADER                                    *
      ****************************************************************
       2700-PRINT-PAGE-HEADER.
      *
           ADD +1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO WS-RH1-PAGE
           MOVE WS-CURRENT-DATE TO WS-RH1-DATE
      *
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
               AFTER ADVANCING PAGE
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
               AFTER ADVANCING 1
      *
           MOVE 4 TO WS-LINE-COUNT
           .
      *
      ****************************************************************
      *    2800-WRITE-DETAIL - WRITE A DETAIL LINE WITH OVERFLOW CHK *
      ****************************************************************
       2800-WRITE-DETAIL.
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 2700-PRINT-PAGE-HEADER
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE
               AFTER ADVANCING 1
      *
           ADD +1 TO WS-LINE-COUNT
           ADD +1 TO WS-TOTAL-EXCEPTIONS
           .
      *
      ****************************************************************
      *    2900-CHECK-CHECKPOINT                                     *
      ****************************************************************
       2900-CHECK-CHECKPOINT.
      *
           ADD +1 TO WS-RECORDS-SINCE-CHKP
      *
           IF WS-RECORDS-SINCE-CHKP >= WS-CHECKPOINT-FREQ
               PERFORM 2950-ISSUE-CHECKPOINT
           END-IF
           .
      *
      ****************************************************************
      *    2950-ISSUE-CHECKPOINT                                     *
      ****************************************************************
       2950-ISSUE-CHECKPOINT.
      *
           MOVE 'CHKP' TO WS-CF-FUNC-CODE
           MOVE WS-TOTAL-PROCESSED TO WS-CD-RECORDS-PROC
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           IF WS-CR-RETURN-CODE = +0
               EXEC SQL COMMIT END-EXEC
               MOVE +0 TO WS-RECORDS-SINCE-CHKP
               ADD +1 TO WS-CHECKPOINT-COUNT
               DISPLAY 'BATVAL00: CHECKPOINT #'
                       WS-CHECKPOINT-COUNT
                       ' AT RECORD ' WS-TOTAL-PROCESSED
           ELSE
               DISPLAY 'BATVAL00: CHECKPOINT FAILED - '
                       WS-CR-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    3000-CHECK-ORPHAN-DEALS - DEALS WITHOUT CUSTOMERS         *
      ****************************************************************
       3000-CHECK-ORPHAN-DEALS.
      *
           DISPLAY 'BATVAL00: PHASE 1 - ORPHANED DEAL CHECK'
      *
           PERFORM 2700-PRINT-PAGE-HEADER
      *
           MOVE SPACES TO WS-SH-SECTION-NAME
           STRING '*** SECTION 1: ORPHANED DEALS '
                  '(DEALS WITHOUT VALID CUSTOMERS) ***'
                  DELIMITED BY SIZE
                  INTO WS-SH-SECTION-NAME
      *
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           ADD +2 TO WS-LINE-COUNT
      *
           EXEC SQL OPEN CSR_ORPHAN_DEAL END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATVAL00: ERROR OPENING ORPHAN DEAL CSR - '
                       SQLCODE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-ORPHAN-DEAL
      *
           PERFORM UNTIL WS-ORPHAN-DEAL-DONE
               EXEC SQL FETCH CSR_ORPHAN_DEAL
                   INTO :WS-HV-OD-DEAL-NUMBER
                      , :WS-HV-OD-CUSTOMER-ID
                      , :WS-HV-OD-DEALER-CODE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-ORPHAN-DEAL-CT
                       ADD +1 TO WS-TOTAL-PROCESSED
                       INITIALIZE WS-DETAIL-LINE
                       MOVE 'DEAL  ' TO WS-DL-TYPE
                       MOVE WS-HV-OD-DEAL-NUMBER TO WS-DL-KEY
                       MOVE WS-HV-OD-CUSTOMER-ID TO WS-CUST-ID-DISP
                       STRING 'CUSTOMER_ID='
                              WS-CUST-ID-DISP
                              ' NOT FOUND IN CUSTOMER TABLE'
                              ' DEALER=' WS-HV-OD-DEALER-CODE
                              DELIMITED BY SIZE
                              INTO WS-DL-DESC
                       PERFORM 2800-WRITE-DETAIL
                       PERFORM 2900-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-ORPHAN-DEAL-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATVAL00: DB2 ERROR ORPHAN DEAL - '
                               SQLCODE
                       SET WS-ORPHAN-DEAL-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_ORPHAN_DEAL END-EXEC
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-CHECK-ORPHAN-VEHICLES - VEHICLES WITHOUT DEALERS     *
      ****************************************************************
       4000-CHECK-ORPHAN-VEHICLES.
      *
           DISPLAY 'BATVAL00: PHASE 2 - ORPHANED VEHICLE CHECK'
      *
           MOVE SPACES TO WS-SH-SECTION-NAME
           STRING '*** SECTION 2: ORPHANED VEHICLES '
                  '(VEHICLES WITH INVALID DEALER) ***'
                  DELIMITED BY SIZE
                  INTO WS-SH-SECTION-NAME
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 2700-PRINT-PAGE-HEADER
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           ADD +2 TO WS-LINE-COUNT
      *
           EXEC SQL OPEN CSR_ORPHAN_VEH END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATVAL00: ERROR OPENING ORPHAN VEH CSR - '
                       SQLCODE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-ORPHAN-VEH
      *
           PERFORM UNTIL WS-ORPHAN-VEH-DONE
               EXEC SQL FETCH CSR_ORPHAN_VEH
                   INTO :WS-HV-OV-VIN
                      , :WS-HV-OV-DEALER-CODE
                      , :WS-HV-OV-STATUS
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-ORPHAN-VEH-CT
                       ADD +1 TO WS-TOTAL-PROCESSED
                       INITIALIZE WS-DETAIL-LINE
                       MOVE 'VEH   ' TO WS-DL-TYPE
                       MOVE WS-HV-OV-VIN TO WS-DL-KEY
                       STRING 'DEALER_CODE='
                              WS-HV-OV-DEALER-CODE
                              ' NOT FOUND IN DEALER TABLE'
                              ' STATUS=' WS-HV-OV-STATUS
                              DELIMITED BY SIZE
                              INTO WS-DL-DESC
                       PERFORM 2800-WRITE-DETAIL
                       PERFORM 2900-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-ORPHAN-VEH-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATVAL00: DB2 ERROR ORPHAN VEH - '
                               SQLCODE
                       SET WS-ORPHAN-VEH-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_ORPHAN_VEH END-EXEC
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-VALIDATE-VINS - CHECK VIN CHECKSUMS                  *
      ****************************************************************
       5000-VALIDATE-VINS.
      *
           DISPLAY 'BATVAL00: PHASE 3 - VIN CHECKSUM VALIDATION'
      *
           MOVE SPACES TO WS-SH-SECTION-NAME
           STRING '*** SECTION 3: VIN CHECKSUM VALIDATION '
                  'FAILURES ***'
                  DELIMITED BY SIZE
                  INTO WS-SH-SECTION-NAME
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 2700-PRINT-PAGE-HEADER
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           ADD +2 TO WS-LINE-COUNT
      *
           EXEC SQL OPEN CSR_VIN_CHECK END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATVAL00: ERROR OPENING VIN CHECK CSR - '
                       SQLCODE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-VIN-CHECK
      *
           PERFORM UNTIL WS-VIN-CHECK-DONE
               EXEC SQL FETCH CSR_VIN_CHECK
                   INTO :WS-HV-VC-VIN
                      , :WS-HV-VC-DEALER-CODE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       PERFORM 5100-VALIDATE-ONE-VIN
                   WHEN +100
                       SET WS-VIN-CHECK-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATVAL00: DB2 ERROR VIN CHECK - '
                               SQLCODE
                       SET WS-VIN-CHECK-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_VIN_CHECK END-EXEC
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-VALIDATE-ONE-VIN - CALL COMVINL0 FOR VIN CHECK       *
      ****************************************************************
       5100-VALIDATE-ONE-VIN.
      *
           ADD +1 TO WS-VIN-CHECKED-CT
           ADD +1 TO WS-TOTAL-PROCESSED
      *
           MOVE WS-HV-VC-VIN TO WS-VR-VIN
           MOVE 'VALD'        TO WS-VR-FUNCTION
      *
           INITIALIZE WS-VIN-RESULT
      *
           CALL 'COMVINL0' USING WS-VIN-REQUEST
                                 WS-VIN-RESULT
      *
           IF WS-VIN-NOT-VALID
               ADD +1 TO WS-VIN-INVALID-CT
               INITIALIZE WS-DETAIL-LINE
               MOVE 'VIN   ' TO WS-DL-TYPE
               MOVE WS-HV-VC-VIN TO WS-DL-KEY
               STRING 'CHECKSUM INVALID - '
                      WS-VR-RETURN-MSG(1:40)
                      ' DEALER=' WS-HV-VC-DEALER-CODE
                      DELIMITED BY SIZE
                      INTO WS-DL-DESC
               PERFORM 2800-WRITE-DETAIL
      *
      *        FLAG THE VEHICLE WITH DAMAGE_FLAG FOR REVIEW
      *
               EXEC SQL
                   UPDATE AUTOSALE.VEHICLE
                      SET DAMAGE_FLAG = 'Y'
                        , DAMAGE_DESC = 'VIN CHECKSUM FAILED'
                        , UPDATED_TS  = CURRENT TIMESTAMP
                   WHERE  VIN = :WS-HV-VC-VIN
                     AND  DAMAGE_FLAG = 'N'
               END-EXEC
           END-IF
      *
           PERFORM 2900-CHECK-CHECKPOINT
           .
      *
      ****************************************************************
      *    6000-CHECK-DUPLICATE-CUSTS - DUPLICATE CUSTOMER RECORDS   *
      ****************************************************************
       6000-CHECK-DUPLICATE-CUSTS.
      *
           DISPLAY 'BATVAL00: PHASE 4 - DUPLICATE CUSTOMER CHECK'
      *
           MOVE SPACES TO WS-SH-SECTION-NAME
           STRING '*** SECTION 4: POTENTIAL DUPLICATE '
                  'CUSTOMER RECORDS ***'
                  DELIMITED BY SIZE
                  INTO WS-SH-SECTION-NAME
      *
           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM 2700-PRINT-PAGE-HEADER
           END-IF
      *
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
           ADD +2 TO WS-LINE-COUNT
      *
           EXEC SQL OPEN CSR_DUP_CUST END-EXEC
      *
           IF SQLCODE NOT = +0
               DISPLAY 'BATVAL00: ERROR OPENING DUP CUST CSR - '
                       SQLCODE
               GO TO 6000-EXIT
           END-IF
      *
           MOVE 'N' TO WS-EOF-DUP-CUST
      *
           PERFORM UNTIL WS-DUP-CUST-DONE
               EXEC SQL FETCH CSR_DUP_CUST
                   INTO :WS-HV-DC-CUST-ID-1
                      , :WS-HV-DC-CUST-ID-2
                      , :WS-HV-DC-LAST-NAME
                      , :WS-HV-DC-FIRST-NAME
                      , :WS-HV-DC-DEALER-CODE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN +0
                       ADD +1 TO WS-DUP-CUSTOMER-CT
                       ADD +1 TO WS-TOTAL-PROCESSED
                       INITIALIZE WS-DETAIL-LINE
                       MOVE 'CUST  ' TO WS-DL-TYPE
                       MOVE WS-HV-DC-CUST-ID-1 TO WS-CUST-ID-DISP
                       MOVE WS-CUST-ID-DISP TO WS-DL-KEY
                       MOVE WS-HV-DC-CUST-ID-2 TO WS-CUST-ID2-DISP
                       STRING WS-HV-DC-LAST-NAME(1:15)
                              ', '
                              WS-HV-DC-FIRST-NAME(1:10)
                              ' DUP OF ID='
                              WS-CUST-ID2-DISP
                              ' DLR=' WS-HV-DC-DEALER-CODE
                              DELIMITED BY SIZE
                              INTO WS-DL-DESC
                       PERFORM 2800-WRITE-DETAIL
                       PERFORM 2900-CHECK-CHECKPOINT
                   WHEN +100
                       SET WS-DUP-CUST-DONE TO TRUE
                   WHEN OTHER
                       DISPLAY 'BATVAL00: DB2 ERROR DUP CUST - '
                               SQLCODE
                       SET WS-DUP-CUST-DONE TO TRUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CSR_DUP_CUST END-EXEC
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-PRINT-SUMMARY - EXCEPTION SUMMARY AT END OF REPORT   *
      ****************************************************************
       7000-PRINT-SUMMARY.
      *
           PERFORM 2700-PRINT-PAGE-HEADER
      *
           MOVE SPACES TO WS-SH-SECTION-NAME
           MOVE '*** VALIDATION SUMMARY ***' TO WS-SH-SECTION-NAME
           WRITE REPORT-RECORD FROM WS-SECTION-HEADER
               AFTER ADVANCING 2
      *
           MOVE SPACES TO WS-REPORT-HEADER-2
           MOVE SPACES TO REPORT-RECORD
           WRITE REPORT-RECORD AFTER ADVANCING 1
      *
           MOVE 'ORPHANED DEALS (NO CUSTOMER):  '
               TO WS-SM-LABEL
           MOVE WS-ORPHAN-DEAL-CT TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 1
      *
           MOVE 'ORPHANED VEHICLES (NO DEALER): '
               TO WS-SM-LABEL
           MOVE WS-ORPHAN-VEH-CT TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 1
      *
           MOVE 'VINS CHECKED:                  '
               TO WS-SM-LABEL
           MOVE WS-VIN-CHECKED-CT TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 1
      *
           MOVE 'VIN CHECKSUM FAILURES:         '
               TO WS-SM-LABEL
           MOVE WS-VIN-INVALID-CT TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 1
      *
           MOVE 'DUPLICATE CUSTOMER PAIRS:      '
               TO WS-SM-LABEL
           MOVE WS-DUP-CUSTOMER-CT TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 1
      *
           MOVE 'TOTAL EXCEPTIONS:              '
               TO WS-SM-LABEL
           MOVE WS-TOTAL-EXCEPTIONS TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 2
      *
           MOVE 'TOTAL RECORDS PROCESSED:       '
               TO WS-SM-LABEL
           MOVE WS-TOTAL-PROCESSED TO WS-SM-COUNT
           WRITE REPORT-RECORD FROM WS-SUMMARY-LINE
               AFTER ADVANCING 1
           .
      *
      ****************************************************************
      *    8000-MARK-COMPLETE                                        *
      ****************************************************************
       8000-MARK-COMPLETE.
      *
           EXEC SQL COMMIT END-EXEC
      *
           MOVE 'DONE' TO WS-CF-FUNC-CODE
           MOVE WS-TOTAL-PROCESSED TO WS-CD-RECORDS-PROC
      *
           CALL 'COMCKPL0' USING WS-CHKP-FUNCTION
                                 WS-CHKP-DATA
                                 WS-CHKP-RESULT
      *
           DISPLAY 'BATVAL00: ' WS-CR-RETURN-MSG
           .
      *
      ****************************************************************
      *    9000-CLOSE-FILES                                          *
      ****************************************************************
       9000-CLOSE-FILES.
      *
           CLOSE REPORT-FILE
      *
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'BATVAL00: ERROR CLOSING REPORT FILE - '
                       WS-FILE-STATUS
           END-IF
      *
           DISPLAY 'BATVAL00: ================================='
           DISPLAY 'BATVAL00: DATA VALIDATION STATISTICS'
           DISPLAY 'BATVAL00: ================================='
           DISPLAY 'BATVAL00: ORPHANED DEALS       = '
                   WS-ORPHAN-DEAL-CT
           DISPLAY 'BATVAL00: ORPHANED VEHICLES     = '
                   WS-ORPHAN-VEH-CT
           DISPLAY 'BATVAL00: VINS CHECKED          = '
                   WS-VIN-CHECKED-CT
           DISPLAY 'BATVAL00: VIN FAILURES          = '
                   WS-VIN-INVALID-CT
           DISPLAY 'BATVAL00: DUPLICATE CUSTOMERS   = '
                   WS-DUP-CUSTOMER-CT
           DISPLAY 'BATVAL00: TOTAL EXCEPTIONS      = '
                   WS-TOTAL-EXCEPTIONS
           DISPLAY 'BATVAL00: TOTAL PROCESSED       = '
                   WS-TOTAL-PROCESSED
           DISPLAY 'BATVAL00: CHECKPOINTS TAKEN     = '
                   WS-CHECKPOINT-COUNT
           DISPLAY 'BATVAL00: ================================='
           .
      ****************************************************************
      * END OF BATVAL00                                              *
      ****************************************************************
