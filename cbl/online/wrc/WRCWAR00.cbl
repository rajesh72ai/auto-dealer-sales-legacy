       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRCWAR00.
      ****************************************************************
      * PROGRAM:  WRCWAR00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   WRC - WARRANTY REGISTRATION                        *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  CREATES WARRANTY RECORDS FOR A SOLD VEHICLE.       *
      *           GENERATES STANDARD COVERAGES:                      *
      *             BASIC     (3 YR / 36,000 MI)                     *
      *             POWERTRAIN(5 YR / 60,000 MI)                     *
      *             CORROSION (5 YR / UNLIMITED MI)                  *
      *             EMISSION  (8 YR / 80,000 MI)                     *
      *           START DATE = SALE DATE. CALCULATES EXPIRY DATES.   *
      *           INSERTS 4 WARRANTY RECORDS.                        *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    WRWA - WARRANTY REGISTRATION                       *
      * MFS MOD:  ASWRWA00                                           *
      * TABLES:   AUTOSALE.WARRANTY    (INSERT)                      *
      *           AUTOSALE.SALES_DEAL  (READ)                        *
      *           AUTOSALE.VEHICLE     (READ)                        *
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
                                          VALUE 'WRCWAR00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASWRWA00'.
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
           05  WS-IN-VIN                 PIC X(17).
           05  WS-IN-DEAL-NUMBER         PIC X(10).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-DEAL-NUMBER        PIC X(10).
           05  WS-OUT-SALE-DATE          PIC X(10).
           05  WS-OUT-WARRANTY-CT        PIC 9.
           05  WS-OUT-WARR-DTL OCCURS 4 TIMES.
               10  WS-OUT-WR-TYPE        PIC X(12).
               10  WS-OUT-WR-START       PIC X(10).
               10  WS-OUT-WR-EXPIRY      PIC X(10).
               10  WS-OUT-WR-MILE-LIMIT  PIC Z(6)9.
               10  WS-OUT-WR-DEDUCTIBLE  PIC X(08).
               10  WS-OUT-WR-STATUS      PIC X(06).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-SALE-DATE              PIC X(10).
           05  WS-EXPIRY-DATE            PIC X(10).
           05  WS-WARRANTY-INDEX         PIC S9(04) COMP VALUE +0.
           05  WS-INSERT-COUNT           PIC S9(04) COMP VALUE +0.
           05  WS-WARRANTY-ID-NUM        PIC S9(09) COMP VALUE +0.
           05  WS-WARRANTY-ID            PIC X(12).
      *
      *    WARRANTY TYPE TABLE
      *
       01  WS-WARRANTY-TYPES.
           05  WS-WT-ENTRY OCCURS 4 TIMES.
               10  WS-WT-CODE            PIC X(04).
               10  WS-WT-DESC            PIC X(12).
               10  WS-WT-YEARS           PIC S9(02) COMP.
               10  WS-WT-MILES           PIC S9(06) COMP.
               10  WS-WT-DEDUCTIBLE      PIC S9(05)V99 COMP-3.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-DEAL.
           05  WS-HV-DL-NUMBER           PIC X(10).
           05  WS-HV-DL-VIN              PIC X(17).
           05  WS-HV-DL-SALE-DATE        PIC X(10).
           05  WS-HV-DL-STATUS           PIC X(02).
           05  WS-HV-DL-CUSTOMER-ID      PIC X(10).
      *
       01  WS-HV-WARRANTY.
           05  WS-HV-WR-ID               PIC X(12).
           05  WS-HV-WR-VIN              PIC X(17).
           05  WS-HV-WR-DEAL-NUMBER      PIC X(10).
           05  WS-HV-WR-TYPE             PIC X(04).
           05  WS-HV-WR-START-DATE       PIC X(10).
           05  WS-HV-WR-EXPIRY-DATE      PIC X(10).
           05  WS-HV-WR-MILE-LIMIT       PIC S9(06) COMP.
           05  WS-HV-WR-DEDUCTIBLE       PIC S9(05)V99 COMP-3.
           05  WS-HV-WR-STATUS           PIC X(02).
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
               PERFORM 4000-LOOKUP-DEAL
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-CREATE-WARRANTIES
           END-IF
      *
           PERFORM 8000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR WORK AREAS AND LOAD TYPE TABLE    *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'WARRANTY REGISTRATION' TO WS-OUT-TITLE
      *
      *    LOAD WARRANTY TYPE DEFAULTS
      *    TYPE 1: BASIC - 3YR/36K
      *
           MOVE 'BASC' TO WS-WT-CODE(1)
           MOVE 'BASIC       ' TO WS-WT-DESC(1)
           MOVE +3 TO WS-WT-YEARS(1)
           MOVE +36000 TO WS-WT-MILES(1)
           MOVE +0 TO WS-WT-DEDUCTIBLE(1)
      *
      *    TYPE 2: POWERTRAIN - 5YR/60K
      *
           MOVE 'PWRT' TO WS-WT-CODE(2)
           MOVE 'POWERTRAIN  ' TO WS-WT-DESC(2)
           MOVE +5 TO WS-WT-YEARS(2)
           MOVE +60000 TO WS-WT-MILES(2)
           MOVE +100 TO WS-WT-DEDUCTIBLE(2)
      *
      *    TYPE 3: CORROSION - 5YR/UNLIMITED
      *
           MOVE 'CORR' TO WS-WT-CODE(3)
           MOVE 'CORROSION   ' TO WS-WT-DESC(3)
           MOVE +5 TO WS-WT-YEARS(3)
           MOVE +999999 TO WS-WT-MILES(3)
           MOVE +0 TO WS-WT-DEDUCTIBLE(3)
      *
      *    TYPE 4: EMISSION - 8YR/80K
      *
           MOVE 'EMIS' TO WS-WT-CODE(4)
           MOVE 'EMISSION    ' TO WS-WT-DESC(4)
           MOVE +8 TO WS-WT-YEARS(4)
           MOVE +80000 TO WS-WT-MILES(4)
           MOVE +0 TO WS-WT-DEDUCTIBLE(4)
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
               MOVE 'WRCWAR00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-VIN = SPACES
               MOVE 'VIN IS REQUIRED FOR WARRANTY REGISTRATION'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-DEAL-NUMBER = SPACES
               MOVE 'DEAL NUMBER IS REQUIRED FOR WARRANTY REG'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-DEAL - VERIFY DEAL AND GET SALE DATE          *
      ****************************************************************
       4000-LOOKUP-DEAL.
      *
           EXEC SQL
               SELECT D.DEAL_NUMBER
                    , D.VIN
                    , D.SALE_DATE
                    , D.DEAL_STATUS
                    , D.CUSTOMER_ID
               INTO  :WS-HV-DL-NUMBER
                    , :WS-HV-DL-VIN
                    , :WS-HV-DL-SALE-DATE
                    , :WS-HV-DL-STATUS
                    , :WS-HV-DL-CUSTOMER-ID
               FROM  AUTOSALE.SALES_DEAL D
               WHERE D.DEAL_NUMBER = :WS-IN-DEAL-NUMBER
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE 'DEAL NOT FOUND FOR SPECIFIED DEAL NUMBER'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
               WHEN OTHER
                   MOVE 'WRCWAR00' TO WS-DBE-PROGRAM
                   MOVE '4000-LOOKUP-DEAL' TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.SALES_DEAL' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'WRCWAR00: DB2 ERROR READING DEAL'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    VERIFY DEAL IS DELIVERED
      *
           IF WS-HV-DL-STATUS NOT = 'DL'
           AND WS-HV-DL-STATUS NOT = 'FI'
               MOVE 'DEAL MUST BE DELIVERED OR IN F&I STATUS'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    VERIFY VIN MATCHES
      *
           IF WS-HV-DL-VIN NOT = WS-IN-VIN
               MOVE 'VIN DOES NOT MATCH DEAL VEHICLE'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-HV-DL-SALE-DATE TO WS-SALE-DATE
           MOVE WS-IN-VIN TO WS-OUT-VIN
           MOVE WS-IN-DEAL-NUMBER TO WS-OUT-DEAL-NUMBER
           MOVE WS-SALE-DATE TO WS-OUT-SALE-DATE
      *
      *    CHECK IF WARRANTIES ALREADY EXIST
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO  :WS-INSERT-COUNT
               FROM  AUTOSALE.WARRANTY W
               WHERE W.VIN = :WS-IN-VIN
                 AND W.DEAL_NUMBER = :WS-IN-DEAL-NUMBER
           END-EXEC
      *
           IF WS-INSERT-COUNT > +0
               MOVE 'WARRANTIES ALREADY REGISTERED FOR THIS DEAL'
                   TO WS-OUT-MESSAGE
           END-IF
      *
           MOVE +0 TO WS-INSERT-COUNT
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-CREATE-WARRANTIES - INSERT 4 WARRANTY RECORDS        *
      ****************************************************************
       5000-CREATE-WARRANTIES.
      *
           PERFORM VARYING WS-WARRANTY-INDEX FROM +1 BY +1
               UNTIL WS-WARRANTY-INDEX > +4
                  OR WS-OUT-MESSAGE NOT = SPACES
      *
      *        CALCULATE EXPIRY DATE
      *
               MOVE 'ADD ' TO WS-DTE-FUNCTION
               MOVE WS-SALE-DATE TO WS-DTE-INPUT-DATE
               MOVE WS-WT-YEARS(WS-WARRANTY-INDEX)
                   TO WS-DTE-YEARS
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
               IF WS-DTE-RETURN-CODE NOT = +0
                   MOVE 'WRCWAR00: DATE CALC ERROR ON EXPIRY'
                       TO WS-OUT-MESSAGE
                   EXIT PERFORM
               END-IF
      *
               MOVE WS-DTE-OUTPUT-DATE TO WS-EXPIRY-DATE
      *
      *        GENERATE WARRANTY ID
      *
               EXEC SQL
                   SELECT NEXT VALUE FOR AUTOSALE.WARR_SEQ
                   INTO  :WS-WARRANTY-ID-NUM
                   FROM  SYSIBM.SYSDUMMY1
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE 'WRCWAR00: ERROR GENERATING WARRANTY ID'
                       TO WS-OUT-MESSAGE
                   EXIT PERFORM
               END-IF
      *
               MOVE WS-WARRANTY-ID-NUM TO WS-WARRANTY-ID
      *
      *        BUILD WARRANTY RECORD
      *
               MOVE WS-WARRANTY-ID TO WS-HV-WR-ID
               MOVE WS-IN-VIN TO WS-HV-WR-VIN
               MOVE WS-IN-DEAL-NUMBER TO WS-HV-WR-DEAL-NUMBER
               MOVE WS-WT-CODE(WS-WARRANTY-INDEX)
                   TO WS-HV-WR-TYPE
               MOVE WS-SALE-DATE TO WS-HV-WR-START-DATE
               MOVE WS-EXPIRY-DATE TO WS-HV-WR-EXPIRY-DATE
               MOVE WS-WT-MILES(WS-WARRANTY-INDEX)
                   TO WS-HV-WR-MILE-LIMIT
               MOVE WS-WT-DEDUCTIBLE(WS-WARRANTY-INDEX)
                   TO WS-HV-WR-DEDUCTIBLE
               MOVE 'AC' TO WS-HV-WR-STATUS
      *
      *        INSERT WARRANTY RECORD
      *
               EXEC SQL
                   INSERT INTO AUTOSALE.WARRANTY
                   ( WARRANTY_ID
                   , VIN
                   , DEAL_NUMBER
                   , WARRANTY_TYPE
                   , START_DATE
                   , EXPIRY_DATE
                   , MILEAGE_LIMIT
                   , DEDUCTIBLE_AMT
                   , WARRANTY_STATUS
                   , CREATED_TIMESTAMP
                   , CREATED_USER
                   )
                   VALUES
                   ( :WS-HV-WR-ID
                   , :WS-HV-WR-VIN
                   , :WS-HV-WR-DEAL-NUMBER
                   , :WS-HV-WR-TYPE
                   , :WS-HV-WR-START-DATE
                   , :WS-HV-WR-EXPIRY-DATE
                   , :WS-HV-WR-MILE-LIMIT
                   , :WS-HV-WR-DEDUCTIBLE
                   , :WS-HV-WR-STATUS
                   , CURRENT TIMESTAMP
                   , :IO-USER
                   )
               END-EXEC
      *
               IF SQLCODE NOT = +0
                   MOVE 'WRCWAR00' TO WS-DBE-PROGRAM
                   MOVE '5000-CREATE-WARRANTIES'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.WARRANTY' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'WRCWAR00: DB2 ERROR INSERTING WARRANTY'
                       TO WS-OUT-MESSAGE
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-INSERT-COUNT
      *
      *        POPULATE OUTPUT DETAIL
      *
               MOVE WS-WT-DESC(WS-WARRANTY-INDEX)
                   TO WS-OUT-WR-TYPE(WS-WARRANTY-INDEX)
               MOVE WS-SALE-DATE
                   TO WS-OUT-WR-START(WS-WARRANTY-INDEX)
               MOVE WS-EXPIRY-DATE
                   TO WS-OUT-WR-EXPIRY(WS-WARRANTY-INDEX)
               MOVE WS-WT-MILES(WS-WARRANTY-INDEX)
                   TO WS-OUT-WR-MILE-LIMIT(WS-WARRANTY-INDEX)
               IF WS-WT-DEDUCTIBLE(WS-WARRANTY-INDEX) = +0
                   MOVE 'NONE    '
                       TO WS-OUT-WR-DEDUCTIBLE(WS-WARRANTY-INDEX)
               ELSE
                   MOVE '$100.00 '
                       TO WS-OUT-WR-DEDUCTIBLE(WS-WARRANTY-INDEX)
               END-IF
               MOVE 'ACTIVE'
                   TO WS-OUT-WR-STATUS(WS-WARRANTY-INDEX)
           END-PERFORM
      *
           IF WS-OUT-MESSAGE = SPACES
               MOVE WS-INSERT-COUNT TO WS-OUT-WARRANTY-CT
      *
      *        LOG THE TRANSACTION
      *
               MOVE 'LOG ' TO WS-LOG-FUNCTION
               MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
               MOVE 'WARRANTY' TO WS-LOG-TABLE-NAME
               MOVE 'INSERT' TO WS-LOG-ACTION
               MOVE WS-IN-VIN TO WS-LOG-KEY-VALUE
               STRING 'WARRANTY REG VIN=' WS-IN-VIN
                      ' DEAL=' WS-IN-DEAL-NUMBER
                      ' COUNT=4'
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
               MOVE 'WARRANTY REGISTRATION COMPLETED - 4 COVERAGES'
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
      * END OF WRCWAR00                                              *
      ****************************************************************
