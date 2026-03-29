       IDENTIFICATION DIVISION.
       PROGRAM-ID. REGVAL00.
      ****************************************************************
      * PROGRAM:  REGVAL00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   REG - REGISTRATION VALIDATION                      *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  VALIDATES A REGISTRATION RECORD AGAINST STATE      *
      *           RULES. CHECKS THAT ALL REQUIRED FIELDS ARE         *
      *           PRESENT: CUSTOMER NAME/ADDRESS, VIN, REG STATE,    *
      *           REG TYPE, AND FEES CALCULATED. VERIFIES THE        *
      *           REGISTRATION STATE EXISTS IN TAX_RATE TABLE.       *
      *           IF ALL VALIDATIONS PASS, UPDATES REG_STATUS TO     *
      *           'VL' (VALIDATED). OTHERWISE RETURNS FAILURE         *
      *           MESSAGES AND LEAVES STATUS AS 'PR' (PREPARING).    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    RGVL - REGISTRATION VALIDATION                     *
      * MFS MOD:  ASRGVL00                                           *
      * TABLES:   AUTOSALE.REGISTRATION  (READ/UPDATE)               *
      *           AUTOSALE.CUSTOMER      (READ)                      *
      *           AUTOSALE.TAX_RATE      (READ)                      *
      * CALLS:    COMVALD0 - FIELD VALIDATION                        *
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
                                          VALUE 'REGVAL00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASRGVL00'.
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
           05  WS-OUT-REG-STATE          PIC X(02).
           05  WS-OUT-REG-TYPE           PIC X(02).
           05  WS-OUT-REG-STATUS         PIC X(10).
           05  WS-OUT-VALID-COUNT        PIC 9(02).
           05  WS-OUT-FAIL-COUNT         PIC 9(02).
           05  WS-OUT-FAIL-MSG OCCURS 5 TIMES.
               10  WS-OUT-FAIL-TEXT      PIC X(60).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-VALID-CHECKS           PIC S9(04) COMP VALUE +0.
           05  WS-FAIL-CHECKS            PIC S9(04) COMP VALUE +0.
           05  WS-STATE-EXISTS           PIC S9(04) COMP VALUE +0.
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
           05  WS-HV-RG-LIEN-HOLDER     PIC X(60).
           05  WS-HV-RG-LIEN-ADDR       PIC X(100).
           05  WS-HV-RG-REG-STATUS      PIC X(02).
           05  WS-HV-RG-REG-FEE         PIC S9(05)V99 COMP-3.
           05  WS-HV-RG-TITLE-FEE       PIC S9(05)V99 COMP-3.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  NI-LIEN-HOLDER            PIC S9(04) COMP VALUE +0.
           05  NI-LIEN-ADDR              PIC S9(04) COMP VALUE +0.
      *
      *    DB2 HOST VARIABLES - CUSTOMER
      *
       01  WS-HV-CUSTOMER.
           05  WS-HV-CUST-ID            PIC S9(09) COMP.
           05  WS-HV-CUST-FIRST         PIC X(30).
           05  WS-HV-CUST-LAST          PIC X(30).
           05  WS-HV-CUST-ADDR1         PIC X(50).
           05  WS-HV-CUST-CITY          PIC X(30).
           05  WS-HV-CUST-STATE         PIC X(02).
           05  WS-HV-CUST-ZIP           PIC X(10).
      *
      *    COMMON MODULE LINKAGE - COMVALD0
      *
       01  WS-VAL-FUNCTION               PIC X(04).
       01  WS-VAL-INPUT                  PIC X(17).
       01  WS-VAL-OUTPUT                 PIC X(40).
       01  WS-VAL-RETURN-CODE            PIC S9(04) COMP.
       01  WS-VAL-ERROR-MSG              PIC X(50).
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
               PERFORM 5000-VALIDATE-REGISTRATION
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
           AND WS-FAIL-CHECKS = +0
               PERFORM 6000-UPDATE-STATUS
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
           MOVE 'REGISTRATION VALIDATION' TO WS-OUT-TITLE
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
               MOVE 'REGVAL00: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'REGISTRATION ID IS REQUIRED FOR VALIDATION'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    4000-LOOKUP-REGISTRATION - READ REGISTRATION RECORD       *
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
                    , R.LIEN_HOLDER
                    , R.LIEN_HOLDER_ADDR
                    , R.REG_STATUS
                    , R.REG_FEE_PAID
                    , R.TITLE_FEE_PAID
               INTO  :WS-HV-RG-ID
                    , :WS-HV-RG-DEAL-NUMBER
                    , :WS-HV-RG-VIN
                    , :WS-HV-RG-CUSTOMER-ID
                    , :WS-HV-RG-REG-STATE
                    , :WS-HV-RG-REG-TYPE
                    , :WS-HV-RG-LIEN-HOLDER  :NI-LIEN-HOLDER
                    , :WS-HV-RG-LIEN-ADDR    :NI-LIEN-ADDR
                    , :WS-HV-RG-REG-STATUS
                    , :WS-HV-RG-REG-FEE
                    , :WS-HV-RG-TITLE-FEE
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
                   MOVE 'REGVAL00' TO WS-DBE-PROGRAM
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
                   MOVE 'REGVAL00: DB2 ERROR READING REGISTRATION'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    VERIFY STATUS IS 'PR' (PREPARING) - ONLY PR CAN VALIDATE
      *
           IF WS-HV-RG-REG-STATUS NOT = 'PR'
               MOVE 'REGISTRATION MUST BE IN PREPARING STATUS'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
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
      *    5000-VALIDATE-REGISTRATION - CHECK ALL STATE RULES        *
      ****************************************************************
       5000-VALIDATE-REGISTRATION.
      *
           MOVE +0 TO WS-VALID-CHECKS
           MOVE +0 TO WS-FAIL-CHECKS
      *
      *    CHECK 1: VIN IS PRESENT AND VALID
      *
           IF WS-HV-RG-VIN = SPACES
               ADD +1 TO WS-FAIL-CHECKS
               MOVE 'VIN IS MISSING FROM REGISTRATION RECORD'
                   TO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
           ELSE
               MOVE 'VIN ' TO WS-VAL-FUNCTION
               MOVE WS-HV-RG-VIN TO WS-VAL-INPUT
               CALL 'COMVALD0' USING WS-VAL-FUNCTION
                                     WS-VAL-INPUT
                                     WS-VAL-OUTPUT
                                     WS-VAL-RETURN-CODE
                                     WS-VAL-ERROR-MSG
               IF WS-VAL-RETURN-CODE NOT = +0
                   ADD +1 TO WS-FAIL-CHECKS
                   STRING 'VIN VALIDATION FAILED: '
                          WS-VAL-ERROR-MSG
                          DELIMITED BY '  '
                       INTO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
                   END-STRING
               ELSE
                   ADD +1 TO WS-VALID-CHECKS
               END-IF
           END-IF
      *
      *    CHECK 2: CUSTOMER DATA IS COMPLETE
      *
           EXEC SQL
               SELECT C.CUSTOMER_ID
                    , C.FIRST_NAME
                    , C.LAST_NAME
                    , C.ADDRESS_LINE1
                    , C.CITY
                    , C.STATE_CODE
                    , C.ZIP_CODE
               INTO  :WS-HV-CUST-ID
                    , :WS-HV-CUST-FIRST
                    , :WS-HV-CUST-LAST
                    , :WS-HV-CUST-ADDR1
                    , :WS-HV-CUST-CITY
                    , :WS-HV-CUST-STATE
                    , :WS-HV-CUST-ZIP
               FROM  AUTOSALE.CUSTOMER C
               WHERE C.CUSTOMER_ID = :WS-HV-RG-CUSTOMER-ID
           END-EXEC
      *
           IF SQLCODE NOT = +0
               ADD +1 TO WS-FAIL-CHECKS
               IF WS-FAIL-CHECKS <= +5
                   MOVE 'CUSTOMER RECORD NOT FOUND'
                       TO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
               END-IF
               GO TO 5000-CHECK-STATE
           END-IF
      *
           IF WS-HV-CUST-LAST = SPACES
           OR WS-HV-CUST-ADDR1 = SPACES
           OR WS-HV-CUST-CITY = SPACES
           OR WS-HV-CUST-ZIP = SPACES
               ADD +1 TO WS-FAIL-CHECKS
               IF WS-FAIL-CHECKS <= +5
                   MOVE 'CUSTOMER NAME/ADDRESS IS INCOMPLETE'
                       TO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
               END-IF
           ELSE
               ADD +1 TO WS-VALID-CHECKS
           END-IF
      *
      *    CHECK 3: REGISTRATION STATE EXISTS IN TAX_RATE TABLE
      *
       5000-CHECK-STATE.
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO  :WS-STATE-EXISTS
               FROM  AUTOSALE.TAX_RATE T
               WHERE T.STATE_CODE = :WS-HV-RG-REG-STATE
                 AND T.EXPIRY_DATE IS NULL
           END-EXEC
      *
           IF WS-STATE-EXISTS = +0
               ADD +1 TO WS-FAIL-CHECKS
               IF WS-FAIL-CHECKS <= +5
                   MOVE 'REG STATE NOT FOUND IN TAX RATE TABLE'
                       TO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
               END-IF
           ELSE
               ADD +1 TO WS-VALID-CHECKS
           END-IF
      *
      *    CHECK 4: REG TYPE IS VALID
      *
           IF WS-HV-RG-REG-TYPE NOT = 'NW'
           AND WS-HV-RG-REG-TYPE NOT = 'TF'
           AND WS-HV-RG-REG-TYPE NOT = 'RN'
           AND WS-HV-RG-REG-TYPE NOT = 'DP'
               ADD +1 TO WS-FAIL-CHECKS
               IF WS-FAIL-CHECKS <= +5
                   MOVE 'INVALID REG TYPE CODE ON RECORD'
                       TO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
               END-IF
           ELSE
               ADD +1 TO WS-VALID-CHECKS
           END-IF
      *
      *    CHECK 5: FEES MUST BE CALCULATED
      *
           IF WS-HV-RG-REG-FEE = +0
           AND WS-HV-RG-TITLE-FEE = +0
               ADD +1 TO WS-FAIL-CHECKS
               IF WS-FAIL-CHECKS <= +5
                   MOVE 'REG AND TITLE FEES NOT CALCULATED'
                       TO WS-OUT-FAIL-TEXT(WS-FAIL-CHECKS)
               END-IF
           ELSE
               ADD +1 TO WS-VALID-CHECKS
           END-IF
      *
      *    FORMAT VALIDATION RESULT COUNTS
      *
           MOVE WS-VALID-CHECKS TO WS-OUT-VALID-COUNT
           MOVE WS-FAIL-CHECKS TO WS-OUT-FAIL-COUNT
      *
           IF WS-FAIL-CHECKS > +0
               MOVE 'PREPARING ' TO WS-OUT-REG-STATUS
               MOVE 'VALIDATION FAILED - SEE ERRORS ABOVE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    6000-UPDATE-STATUS - SET STATUS TO VALIDATED              *
      ****************************************************************
       6000-UPDATE-STATUS.
      *
           EXEC SQL
               UPDATE AUTOSALE.REGISTRATION
               SET    REG_STATUS  = 'VL'
                    , UPDATED_TS  = CURRENT TIMESTAMP
               WHERE  REG_ID = :WS-IN-REG-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN OTHER
                   MOVE 'REGVAL00' TO WS-DBE-PROGRAM
                   MOVE '6000-UPDATE-STATUS' TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.REGISTRATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGVAL00: DB2 ERROR UPDATING STATUS'
                       TO WS-OUT-MESSAGE
                   GO TO 6000-EXIT
           END-EVALUATE
      *
           MOVE 'VALIDATED ' TO WS-OUT-REG-STATUS
      *
      *    LOG THE VALIDATION
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'REGISTRATION' TO WS-LOG-TABLE-NAME
           MOVE 'UPDATE' TO WS-LOG-ACTION
           MOVE WS-IN-REG-ID TO WS-LOG-KEY-VALUE
           STRING 'REG VALIDATED ID=' WS-IN-REG-ID
                  ' STATE=' WS-HV-RG-REG-STATE
                  ' CHECKS PASSED=' WS-OUT-VALID-COUNT
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
           MOVE 'REGISTRATION VALIDATED SUCCESSFULLY'
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
      * END OF REGVAL00                                              *
      ****************************************************************
