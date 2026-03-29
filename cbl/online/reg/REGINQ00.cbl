       IDENTIFICATION DIVISION.
       PROGRAM-ID. REGINQ00.
      ****************************************************************
      * PROGRAM:  REGINQ00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   REG - REGISTRATION INQUIRY                         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  INQUIRES ON VEHICLE REGISTRATION STATUS BY REG     *
      *           ID, VIN, OR DEAL NUMBER. JOINS REGISTRATION,       *
      *           VEHICLE, CUSTOMER, AND SALES_DEAL TABLES TO        *
      *           DISPLAY FULL REGISTRATION DETAILS INCLUDING        *
      *           PLATE NUMBER, TITLE NUMBER, FEES, AND STATUS.      *
      *           SUPPORTS PF7/PF8 CURSOR-BASED PAGINATION WHEN     *
      *           MULTIPLE REGISTRATIONS MATCH THE CRITERIA.         *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    RGIN - REGISTRATION INQUIRY                        *
      * MFS MOD:  ASRGIN00                                           *
      * TABLES:   AUTOSALE.REGISTRATION  (READ)                      *
      *           AUTOSALE.VEHICLE       (READ)                      *
      *           AUTOSALE.CUSTOMER      (READ)                      *
      *           AUTOSALE.SALES_DEAL    (READ)                      *
      * CALLS:    COMDBEL0 - DB2 ERROR HANDLER                       *
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
                                          VALUE 'REGINQ00'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASRGIN00'.
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
           05  WS-IN-DEAL-NUMBER         PIC X(10).
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-CUSTOMER-ID         PIC X(10).
           05  WS-IN-PAGE-ACTION         PIC X(01).
               88  WS-PAGE-FORWARD                   VALUE 'F'.
               88  WS-PAGE-BACKWARD                  VALUE 'B'.
               88  WS-PAGE-FIRST                     VALUE ' '.
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
           05  WS-OUT-VEH-DESC           PIC X(20).
           05  WS-OUT-CUST-NAME          PIC X(25).
           05  WS-OUT-REG-STATUS-DESC    PIC X(10).
           05  WS-OUT-REG-STATE          PIC X(02).
           05  WS-OUT-REG-TYPE-DESC      PIC X(10).
           05  WS-OUT-PLATE              PIC X(10).
           05  WS-OUT-TITLE-NUM          PIC X(20).
           05  WS-OUT-LIEN-HOLDER        PIC X(25).
           05  WS-OUT-STATUS-CODE        PIC X(10).
           05  WS-OUT-SUBMIT-DATE        PIC X(10).
           05  WS-OUT-ISSUED-DATE        PIC X(10).
           05  WS-OUT-FEE-DISPLAY        PIC X(12).
           05  WS-OUT-PAGE-INFO          PIC X(20).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ROW-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-SKIP-COUNT             PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-PAGE-NUMBER            PIC S9(04) COMP
                                                     VALUE +1.
           05  WS-ROWS-PER-PAGE          PIC S9(04) COMP
                                                     VALUE +1.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-TOTAL-FEE              PIC S9(07)V99 COMP-3
                                                       VALUE +0.
           05  WS-FEE-EDITED             PIC Z(4)9.99.
           05  WS-CUST-ID-INT            PIC S9(09) COMP
                                                     VALUE +0.
           05  WS-HAS-SEARCH-KEY         PIC X(01)  VALUE 'N'.
               88  WS-SEARCH-KEY-FOUND              VALUE 'Y'.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-REG.
           05  WS-HV-RG-ID              PIC X(12).
           05  WS-HV-RG-DEAL-NUMBER     PIC X(10).
           05  WS-HV-RG-VIN             PIC X(17).
           05  WS-HV-RG-CUSTOMER-ID     PIC S9(09) COMP.
           05  WS-HV-RG-REG-STATE       PIC X(02).
           05  WS-HV-RG-REG-TYPE        PIC X(02).
           05  WS-HV-RG-PLATE-NUMBER    PIC X(10).
           05  WS-HV-RG-TITLE-NUMBER    PIC X(20).
           05  WS-HV-RG-LIEN-HOLDER     PIC X(60).
           05  WS-HV-RG-REG-STATUS      PIC X(02).
           05  WS-HV-RG-SUBMIT-DATE     PIC X(10).
           05  WS-HV-RG-ISSUED-DATE     PIC X(10).
           05  WS-HV-RG-REG-FEE         PIC S9(05)V99 COMP-3.
           05  WS-HV-RG-TITLE-FEE       PIC S9(05)V99 COMP-3.
           05  WS-HV-RG-VEH-DESC        PIC X(20).
           05  WS-HV-RG-CUST-NAME       PIC X(25).
      *
      *    NULL INDICATORS FOR NULLABLE COLUMNS
      *
       01  WS-NULL-INDICATORS.
           05  NI-PLATE-NUMBER           PIC S9(04) COMP VALUE +0.
           05  NI-TITLE-NUMBER           PIC S9(04) COMP VALUE +0.
           05  NI-LIEN-HOLDER            PIC S9(04) COMP VALUE +0.
           05  NI-SUBMIT-DATE            PIC S9(04) COMP VALUE +0.
           05  NI-ISSUED-DATE            PIC S9(04) COMP VALUE +0.
      *
      *    CURSOR FOR REGISTRATION INQUIRY
      *
           EXEC SQL DECLARE CSR_REG_INQ CURSOR FOR
               SELECT R.REG_ID
                    , R.DEAL_NUMBER
                    , R.VIN
                    , R.CUSTOMER_ID
                    , R.REG_STATE
                    , R.REG_TYPE
                    , R.PLATE_NUMBER
                    , R.TITLE_NUMBER
                    , R.LIEN_HOLDER
                    , R.REG_STATUS
                    , CHAR(R.SUBMISSION_DATE, ISO)
                    , CHAR(R.ISSUED_DATE, ISO)
                    , R.REG_FEE_PAID
                    , R.TITLE_FEE_PAID
                    , SUBSTR(
                        STRIP(CHAR(V.MODEL_YEAR)) CONCAT ' '
                        CONCAT V.MAKE_CODE CONCAT ' '
                        CONCAT V.MODEL_CODE, 1, 20)
                    , SUBSTR(
                        STRIP(C.LAST_NAME) CONCAT ', '
                        CONCAT STRIP(C.FIRST_NAME), 1, 25)
               FROM   AUTOSALE.REGISTRATION R
               JOIN   AUTOSALE.VEHICLE V
                 ON   R.VIN = V.VIN
               JOIN   AUTOSALE.CUSTOMER C
                 ON   R.CUSTOMER_ID = C.CUSTOMER_ID
               JOIN   AUTOSALE.SALES_DEAL D
                 ON   R.DEAL_NUMBER = D.DEAL_NUMBER
               WHERE  (R.REG_ID = :WS-IN-REG-ID
                       OR :WS-IN-REG-ID = SPACES)
                 AND  (R.DEAL_NUMBER = :WS-IN-DEAL-NUMBER
                       OR :WS-IN-DEAL-NUMBER = SPACES)
                 AND  (R.VIN = :WS-IN-VIN
                       OR :WS-IN-VIN = SPACES)
                 AND  (R.CUSTOMER_ID = :WS-CUST-ID-INT
                       OR :WS-CUST-ID-INT = 0)
               ORDER BY R.CREATED_TS DESC
           END-EXEC
      *
      *    DB ERROR MODULE LINKAGE
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
               PERFORM 4000-RETRIEVE-REGISTRATION
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
           MOVE 'REGISTRATION INQUIRY' TO WS-OUT-TITLE
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
               MOVE 'REGINQ00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - AT LEAST ONE SEARCH KEY REQUIRED    *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           MOVE 'N' TO WS-HAS-SEARCH-KEY
      *
           IF WS-IN-REG-ID NOT = SPACES
               MOVE 'Y' TO WS-HAS-SEARCH-KEY
           END-IF
      *
           IF WS-IN-DEAL-NUMBER NOT = SPACES
               MOVE 'Y' TO WS-HAS-SEARCH-KEY
           END-IF
      *
           IF WS-IN-VIN NOT = SPACES
               MOVE 'Y' TO WS-HAS-SEARCH-KEY
           END-IF
      *
           IF WS-IN-CUSTOMER-ID NOT = SPACES
               MOVE 'Y' TO WS-HAS-SEARCH-KEY
               COMPUTE WS-CUST-ID-INT =
                   FUNCTION NUMVAL(WS-IN-CUSTOMER-ID)
           END-IF
      *
           IF NOT WS-SEARCH-KEY-FOUND
               MOVE 'ENTER REG ID, VIN, DEAL# OR CUSTOMER ID'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    HANDLE PAGING
      *
           IF WS-PAGE-FORWARD
               ADD +1 TO WS-PAGE-NUMBER
           END-IF
           IF WS-PAGE-BACKWARD
               IF WS-PAGE-NUMBER > +1
                   SUBTRACT +1 FROM WS-PAGE-NUMBER
               END-IF
           END-IF
      *
           COMPUTE WS-SKIP-COUNT =
               (WS-PAGE-NUMBER - 1) * WS-ROWS-PER-PAGE
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-RETRIEVE-REGISTRATION - OPEN CURSOR AND FETCH        *
      ****************************************************************
       4000-RETRIEVE-REGISTRATION.
      *
           EXEC SQL OPEN CSR_REG_INQ END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'REGINQ00: ERROR OPENING REGISTRATION CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
      *    SKIP ROWS FOR PAGING
      *
           PERFORM WS-SKIP-COUNT TIMES
               PERFORM 4100-FETCH-ROW
               IF WS-END-OF-DATA
                   EXIT PERFORM
               END-IF
           END-PERFORM
      *
      *    FETCH CURRENT PAGE ROW
      *
           IF NOT WS-END-OF-DATA
               PERFORM 4100-FETCH-ROW
           END-IF
      *
           EXEC SQL CLOSE CSR_REG_INQ END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO REGISTRATION RECORDS FOUND FOR CRITERIA'
                   TO WS-OUT-MESSAGE
           ELSE
               PERFORM 4200-FORMAT-DETAIL
      *
               STRING 'PAGE ' WS-PAGE-NUMBER
                      DELIMITED BY SIZE
                   INTO WS-OUT-PAGE-INFO
               END-STRING
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-ROW - FETCH ONE ROW FROM CURSOR                *
      ****************************************************************
       4100-FETCH-ROW.
      *
           EXEC SQL FETCH CSR_REG_INQ
               INTO  :WS-HV-RG-ID
                    , :WS-HV-RG-DEAL-NUMBER
                    , :WS-HV-RG-VIN
                    , :WS-HV-RG-CUSTOMER-ID
                    , :WS-HV-RG-REG-STATE
                    , :WS-HV-RG-REG-TYPE
                    , :WS-HV-RG-PLATE-NUMBER :NI-PLATE-NUMBER
                    , :WS-HV-RG-TITLE-NUMBER :NI-TITLE-NUMBER
                    , :WS-HV-RG-LIEN-HOLDER  :NI-LIEN-HOLDER
                    , :WS-HV-RG-REG-STATUS
                    , :WS-HV-RG-SUBMIT-DATE  :NI-SUBMIT-DATE
                    , :WS-HV-RG-ISSUED-DATE  :NI-ISSUED-DATE
                    , :WS-HV-RG-REG-FEE
                    , :WS-HV-RG-TITLE-FEE
                    , :WS-HV-RG-VEH-DESC
                    , :WS-HV-RG-CUST-NAME
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'REGINQ00' TO WS-DBE-PROGRAM
                   MOVE '4100-FETCH-ROW' TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.REGISTRATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGINQ00: DB2 ERROR READING REGISTRATION'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4200-FORMAT-DETAIL - POPULATE OUTPUT FROM FETCHED ROW     *
      ****************************************************************
       4200-FORMAT-DETAIL.
      *
           MOVE WS-HV-RG-ID TO WS-OUT-REG-ID
           MOVE WS-HV-RG-DEAL-NUMBER TO WS-OUT-DEAL-NUMBER
           MOVE WS-HV-RG-VIN TO WS-OUT-VIN
           MOVE WS-HV-RG-VEH-DESC TO WS-OUT-VEH-DESC
           MOVE WS-HV-RG-CUST-NAME TO WS-OUT-CUST-NAME
           MOVE WS-HV-RG-REG-STATE TO WS-OUT-REG-STATE
      *
      *    FORMAT REG TYPE DESCRIPTION
      *
           EVALUATE WS-HV-RG-REG-TYPE
               WHEN 'NW'
                   MOVE 'NEW       ' TO WS-OUT-REG-TYPE-DESC
               WHEN 'TF'
                   MOVE 'TRANSFER  ' TO WS-OUT-REG-TYPE-DESC
               WHEN 'RN'
                   MOVE 'RENEWAL   ' TO WS-OUT-REG-TYPE-DESC
               WHEN 'DP'
                   MOVE 'DUPLICATE ' TO WS-OUT-REG-TYPE-DESC
               WHEN OTHER
                   MOVE WS-HV-RG-REG-TYPE
                       TO WS-OUT-REG-TYPE-DESC
           END-EVALUATE
      *
      *    FORMAT STATUS DESCRIPTION
      *
           EVALUATE WS-HV-RG-REG-STATUS
               WHEN 'PR'
                   MOVE 'PREPARING ' TO WS-OUT-REG-STATUS-DESC
               WHEN 'VL'
                   MOVE 'VALIDATED ' TO WS-OUT-REG-STATUS-DESC
               WHEN 'SB'
                   MOVE 'SUBMITTED ' TO WS-OUT-REG-STATUS-DESC
               WHEN 'PG'
                   MOVE 'PROCESSING' TO WS-OUT-REG-STATUS-DESC
               WHEN 'IS'
                   MOVE 'ISSUED    ' TO WS-OUT-REG-STATUS-DESC
               WHEN 'RJ'
                   MOVE 'REJECTED  ' TO WS-OUT-REG-STATUS-DESC
               WHEN 'ER'
                   MOVE 'ERROR     ' TO WS-OUT-REG-STATUS-DESC
               WHEN OTHER
                   MOVE WS-HV-RG-REG-STATUS
                       TO WS-OUT-REG-STATUS-DESC
           END-EVALUATE
      *
           MOVE WS-HV-RG-REG-STATUS TO WS-OUT-STATUS-CODE
      *
      *    HANDLE NULLABLE FIELDS
      *
           IF NI-PLATE-NUMBER < +0
               MOVE SPACES TO WS-OUT-PLATE
           ELSE
               MOVE WS-HV-RG-PLATE-NUMBER TO WS-OUT-PLATE
           END-IF
      *
           IF NI-TITLE-NUMBER < +0
               MOVE SPACES TO WS-OUT-TITLE-NUM
           ELSE
               MOVE WS-HV-RG-TITLE-NUMBER TO WS-OUT-TITLE-NUM
           END-IF
      *
           IF NI-LIEN-HOLDER < +0
               MOVE SPACES TO WS-OUT-LIEN-HOLDER
           ELSE
               MOVE WS-HV-RG-LIEN-HOLDER(1:25)
                   TO WS-OUT-LIEN-HOLDER
           END-IF
      *
           IF NI-SUBMIT-DATE < +0
               MOVE SPACES TO WS-OUT-SUBMIT-DATE
           ELSE
               MOVE WS-HV-RG-SUBMIT-DATE TO WS-OUT-SUBMIT-DATE
           END-IF
      *
           IF NI-ISSUED-DATE < +0
               MOVE SPACES TO WS-OUT-ISSUED-DATE
           ELSE
               MOVE WS-HV-RG-ISSUED-DATE TO WS-OUT-ISSUED-DATE
           END-IF
      *
      *    FORMAT TOTAL FEES
      *
           COMPUTE WS-TOTAL-FEE =
               WS-HV-RG-REG-FEE + WS-HV-RG-TITLE-FEE
           MOVE WS-TOTAL-FEE TO WS-FEE-EDITED
           MOVE WS-FEE-EDITED TO WS-OUT-FEE-DISPLAY
      *
           MOVE 'REGISTRATION RECORD DISPLAYED'
               TO WS-OUT-MESSAGE
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
      * END OF REGINQ00                                              *
      ****************************************************************
