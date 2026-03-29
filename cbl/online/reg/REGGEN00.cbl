       IDENTIFICATION DIVISION.
       PROGRAM-ID. REGGEN00.
      ****************************************************************
      * PROGRAM:  REGGEN00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   REG - REGISTRATION DOCUMENT GENERATION             *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ASSEMBLES A VEHICLE REGISTRATION PACKET FROM       *
      *           DEAL, VEHICLE, AND CUSTOMER DATA. CALCULATES       *
      *           STATE REGISTRATION AND TITLE FEES VIA COMTAXL0.    *
      *           INSERTS A NEW REGISTRATION RECORD WITH STATUS      *
      *           'PR' (PREPARING). VALIDATES DEAL IS DELIVERED      *
      *           OR IN F&I STATUS BEFORE PROCEEDING.                *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    RGGE - REGISTRATION DOCUMENT GENERATION            *
      * MFS MOD:  ASRGGE00                                           *
      * TABLES:   AUTOSALE.REGISTRATION  (INSERT)                    *
      *           AUTOSALE.SALES_DEAL    (READ)                      *
      *           AUTOSALE.VEHICLE       (READ)                      *
      *           AUTOSALE.CUSTOMER      (READ)                      *
      *           AUTOSALE.TAX_RATE      (READ - VIA COMTAXL0)       *
      * CALLS:    COMVALD0 - VIN VALIDATION                          *
      *           COMTAXL0 - TAX/FEE CALCULATION                     *
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
                                          VALUE 'REGGEN00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASRGGE00'.
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
           05  WS-IN-DEAL-NUMBER         PIC X(10).
           05  WS-IN-REG-STATE           PIC X(02).
           05  WS-IN-REG-TYPE            PIC X(02).
           05  WS-IN-LIEN-HOLDER-NAME    PIC X(25).
           05  WS-IN-LIEN-HOLDER-ADDR    PIC X(30).
           05  WS-IN-LIEN-HOLDER-CITY    PIC X(15).
           05  WS-IN-LIEN-HOLDER-ST      PIC X(02).
           05  WS-IN-LIEN-HOLDER-ZIP     PIC X(10).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-DEAL-NUMBER        PIC X(10).
           05  WS-OUT-CUSTOMER-ID        PIC X(10).
           05  WS-OUT-CUST-NAME          PIC X(25).
           05  WS-OUT-CUST-ADDR          PIC X(30).
           05  WS-OUT-CUST-CITY          PIC X(15).
           05  WS-OUT-CUST-STATE         PIC X(02).
           05  WS-OUT-CUST-ZIP           PIC X(10).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-VEH-DESC           PIC X(20).
           05  WS-OUT-REG-STATE          PIC X(02).
           05  WS-OUT-REG-TYPE           PIC X(10).
           05  WS-OUT-LIEN-NAME          PIC X(25).
           05  WS-OUT-LIEN-ADDR          PIC X(30).
           05  WS-OUT-LIEN-CITY          PIC X(15).
           05  WS-OUT-LIEN-ST            PIC X(02).
           05  WS-OUT-LIEN-ZIP           PIC X(10).
           05  WS-OUT-VALID-STATUS       PIC X(10).
           05  WS-OUT-REG-STATUS         PIC X(10).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-REG-ID-NUM             PIC S9(09) COMP VALUE +0.
           05  WS-REG-ID                 PIC X(12).
           05  WS-LIEN-HOLDER-FULL       PIC X(60).
           05  WS-LIEN-ADDR-FULL         PIC X(100).
           05  WS-CUST-ID-DISPLAY        PIC Z(9)9.
           05  WS-REG-FEE               PIC S9(05)V99 COMP-3
                                                       VALUE +0.
           05  WS-TITLE-FEE             PIC S9(05)V99 COMP-3
                                                       VALUE +0.
           05  WS-REG-TYPE-DESC          PIC X(10).
      *
      *    DB2 HOST VARIABLES - DEAL
      *
       01  WS-HV-DEAL.
           05  WS-HV-DL-NUMBER           PIC X(10).
           05  WS-HV-DL-VIN              PIC X(17).
           05  WS-HV-DL-CUSTOMER-ID      PIC S9(09) COMP.
           05  WS-HV-DL-STATUS           PIC X(02).
           05  WS-HV-DL-DEALER-CODE      PIC X(05).
           05  WS-HV-DL-DEAL-DATE        PIC X(10).
           05  WS-HV-DL-VEHICLE-PRICE    PIC S9(09)V99 COMP-3.
           05  WS-HV-DL-TRADE-ALLOW      PIC S9(09)V99 COMP-3.
           05  WS-HV-DL-STATE-CODE       PIC X(02).
      *
      *    DB2 HOST VARIABLES - VEHICLE
      *
       01  WS-HV-VEHICLE.
           05  WS-HV-VEH-VIN            PIC X(17).
           05  WS-HV-VEH-MODEL-YEAR     PIC S9(04) COMP.
           05  WS-HV-VEH-MAKE           PIC X(03).
           05  WS-HV-VEH-MODEL          PIC X(06).
           05  WS-HV-VEH-STATUS         PIC X(02).
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
           05  WS-HV-CUST-COUNTY        PIC X(05).
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
      *    COMMON MODULE LINKAGE - COMVALD0
      *
       01  WS-VAL-FUNCTION               PIC X(04).
       01  WS-VAL-INPUT                  PIC X(17).
       01  WS-VAL-OUTPUT                 PIC X(40).
       01  WS-VAL-RETURN-CODE            PIC S9(04) COMP.
       01  WS-VAL-ERROR-MSG              PIC X(50).
      *
      *    COMMON MODULE LINKAGE - COMTAXL0
      *
       01  WS-TAX-STATE-CODE             PIC X(02).
       01  WS-TAX-COUNTY-CODE            PIC X(05).
       01  WS-TAX-CITY-CODE              PIC X(05).
       01  WS-TAX-INPUT-AREA.
           05  WS-TAX-TAXABLE-AMT        PIC S9(09)V99 COMP-3.
           05  WS-TAX-TRADE-ALLOW        PIC S9(09)V99 COMP-3.
           05  WS-TAX-DOC-FEE-REQ        PIC S9(05)V99 COMP-3.
           05  WS-TAX-VEHICLE-TYPE        PIC X(02).
           05  WS-TAX-SALE-DATE           PIC X(10).
       01  WS-TAX-RESULT-AREA.
           05  WS-TAX-STATE-RATE         PIC S9(01)V9(04) COMP-3.
           05  WS-TAX-STATE-AMT          PIC S9(09)V99 COMP-3.
           05  WS-TAX-COUNTY-RATE        PIC S9(01)V9(04) COMP-3.
           05  WS-TAX-COUNTY-AMT         PIC S9(09)V99 COMP-3.
           05  WS-TAX-CITY-RATE          PIC S9(01)V9(04) COMP-3.
           05  WS-TAX-CITY-AMT           PIC S9(09)V99 COMP-3.
           05  WS-TAX-TOTAL-TAX          PIC S9(09)V99 COMP-3.
           05  WS-TAX-NET-TAXABLE        PIC S9(09)V99 COMP-3.
           05  WS-TAX-DOC-FEE            PIC S9(05)V99 COMP-3.
           05  WS-TAX-TITLE-FEE          PIC S9(05)V99 COMP-3.
           05  WS-TAX-REG-FEE            PIC S9(05)V99 COMP-3.
           05  WS-TAX-TOTAL-FEES         PIC S9(07)V99 COMP-3.
           05  WS-TAX-GRAND-TOTAL        PIC S9(09)V99 COMP-3.
       01  WS-TAX-RETURN-CODE            PIC S9(04) COMP.
       01  WS-TAX-ERROR-MSG              PIC X(50).
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
               PERFORM 4000-LOOKUP-DEAL
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 4500-LOOKUP-CUSTOMER
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-CALCULATE-FEES
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6000-INSERT-REGISTRATION
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
      *
           EXEC SQL
               SET :WS-CURRENT-TS = CURRENT TIMESTAMP
           END-EXEC
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
               MOVE 'REGGEN00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-DEAL-NUMBER = SPACES
               MOVE 'DEAL NUMBER IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-REG-STATE = SPACES
               MOVE 'REGISTRATION STATE IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-REG-TYPE = SPACES
               MOVE 'REGISTRATION TYPE IS REQUIRED'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE REG TYPE (NW, TF, RN, DP)
      *
           IF WS-IN-REG-TYPE NOT = 'NW'
           AND WS-IN-REG-TYPE NOT = 'TF'
           AND WS-IN-REG-TYPE NOT = 'RN'
           AND WS-IN-REG-TYPE NOT = 'DP'
               MOVE 'INVALID REG TYPE - USE NW/TF/RN/DP'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE STATE CODE VIA COMVALD0
      *
           MOVE 'STAT' TO WS-VAL-FUNCTION
           MOVE WS-IN-REG-STATE TO WS-VAL-INPUT
           CALL 'COMVALD0' USING WS-VAL-FUNCTION
                                 WS-VAL-INPUT
                                 WS-VAL-OUTPUT
                                 WS-VAL-RETURN-CODE
                                 WS-VAL-ERROR-MSG
      *
           IF WS-VAL-RETURN-CODE NOT = +0
               STRING 'INVALID STATE: '
                      WS-VAL-ERROR-MSG
                      DELIMITED BY '  '
                   INTO WS-OUT-MESSAGE
               END-STRING
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-LOOKUP-DEAL - READ DEAL AND VEHICLE DATA             *
      ****************************************************************
       4000-LOOKUP-DEAL.
      *
           EXEC SQL
               SELECT D.DEAL_NUMBER
                    , D.VIN
                    , D.CUSTOMER_ID
                    , D.DEAL_STATUS
                    , D.DEALER_CODE
                    , CHAR(D.DEAL_DATE, ISO)
                    , D.VEHICLE_PRICE
                    , D.TRADE_ALLOW
               INTO  :WS-HV-DL-NUMBER
                    , :WS-HV-DL-VIN
                    , :WS-HV-DL-CUSTOMER-ID
                    , :WS-HV-DL-STATUS
                    , :WS-HV-DL-DEALER-CODE
                    , :WS-HV-DL-DEAL-DATE
                    , :WS-HV-DL-VEHICLE-PRICE
                    , :WS-HV-DL-TRADE-ALLOW
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
                   MOVE 'REGGEN00' TO WS-DBE-PROGRAM
                   MOVE '4000-LOOKUP-DEAL' TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.SALES_DEAL' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGGEN00: DB2 ERROR READING DEAL'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    VERIFY DEAL IS DELIVERED OR IN F&I
      *
           IF WS-HV-DL-STATUS NOT = 'DL'
           AND WS-HV-DL-STATUS NOT = 'FI'
           AND WS-HV-DL-STATUS NOT = 'CT'
               MOVE 'DEAL MUST BE CONTRACTED/F&I/DELIVERED'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    CHECK IF REGISTRATION ALREADY EXISTS FOR THIS DEAL
      *
           EXEC SQL
               SELECT COUNT(*)
               INTO  :WS-REG-ID-NUM
               FROM  AUTOSALE.REGISTRATION R
               WHERE R.DEAL_NUMBER = :WS-IN-DEAL-NUMBER
           END-EXEC
      *
           IF WS-REG-ID-NUM > +0
               MOVE 'REGISTRATION ALREADY EXISTS FOR THIS DEAL'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    LOOK UP VEHICLE DESCRIPTION
      *
           EXEC SQL
               SELECT V.VIN
                    , V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.MODEL_CODE
                    , V.VEHICLE_STATUS
               INTO  :WS-HV-VEH-VIN
                    , :WS-HV-VEH-MODEL-YEAR
                    , :WS-HV-VEH-MAKE
                    , :WS-HV-VEH-MODEL
                    , :WS-HV-VEH-STATUS
               FROM  AUTOSALE.VEHICLE V
               WHERE V.VIN = :WS-HV-DL-VIN
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'VEHICLE NOT FOUND FOR DEAL VIN'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
      *    POPULATE VEHICLE OUTPUT FIELDS
      *
           MOVE WS-HV-DL-VIN TO WS-OUT-VIN
           STRING WS-HV-VEH-MODEL-YEAR ' '
                  WS-HV-VEH-MAKE       ' '
                  WS-HV-VEH-MODEL
                  DELIMITED BY SIZE
               INTO WS-OUT-VEH-DESC
           END-STRING
      *
           MOVE WS-IN-DEAL-NUMBER TO WS-OUT-DEAL-NUMBER
           MOVE WS-IN-REG-STATE TO WS-OUT-REG-STATE
      *
      *    FORMAT REG TYPE DESCRIPTION
      *
           EVALUATE WS-IN-REG-TYPE
               WHEN 'NW'
                   MOVE 'NEW       ' TO WS-OUT-REG-TYPE
               WHEN 'TF'
                   MOVE 'TRANSFER  ' TO WS-OUT-REG-TYPE
               WHEN 'RN'
                   MOVE 'RENEWAL   ' TO WS-OUT-REG-TYPE
               WHEN 'DP'
                   MOVE 'DUPLICATE ' TO WS-OUT-REG-TYPE
           END-EVALUATE
      *
      *    POPULATE LIEN HOLDER OUTPUT
      *
           MOVE WS-IN-LIEN-HOLDER-NAME TO WS-OUT-LIEN-NAME
           MOVE WS-IN-LIEN-HOLDER-ADDR TO WS-OUT-LIEN-ADDR
           MOVE WS-IN-LIEN-HOLDER-CITY TO WS-OUT-LIEN-CITY
           MOVE WS-IN-LIEN-HOLDER-ST TO WS-OUT-LIEN-ST
           MOVE WS-IN-LIEN-HOLDER-ZIP TO WS-OUT-LIEN-ZIP
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-LOOKUP-CUSTOMER - READ CUSTOMER FOR REGISTRATION     *
      ****************************************************************
       4500-LOOKUP-CUSTOMER.
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
               WHERE C.CUSTOMER_ID = :WS-HV-DL-CUSTOMER-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE 'CUSTOMER NOT FOUND FOR DEAL'
                       TO WS-OUT-MESSAGE
                   GO TO 4500-EXIT
               WHEN OTHER
                   MOVE 'REGGEN00' TO WS-DBE-PROGRAM
                   MOVE '4500-LOOKUP-CUSTOMER'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.CUSTOMER' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGGEN00: DB2 ERROR READING CUSTOMER'
                       TO WS-OUT-MESSAGE
                   GO TO 4500-EXIT
           END-EVALUATE
      *
      *    FORMAT CUSTOMER OUTPUT
      *
           MOVE WS-HV-CUST-ID TO WS-CUST-ID-DISPLAY
           MOVE WS-CUST-ID-DISPLAY TO WS-OUT-CUSTOMER-ID
           STRING WS-HV-CUST-LAST DELIMITED BY '  '
                  ', ' DELIMITED BY SIZE
                  WS-HV-CUST-FIRST DELIMITED BY '  '
               INTO WS-OUT-CUST-NAME
           END-STRING
           MOVE WS-HV-CUST-ADDR1(1:30) TO WS-OUT-CUST-ADDR
           MOVE WS-HV-CUST-CITY(1:15) TO WS-OUT-CUST-CITY
           MOVE WS-HV-CUST-STATE TO WS-OUT-CUST-STATE
           MOVE WS-HV-CUST-ZIP TO WS-OUT-CUST-ZIP
           .
       4500-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-CALCULATE-FEES - GET REG/TITLE FEES VIA COMTAXL0     *
      ****************************************************************
       5000-CALCULATE-FEES.
      *
           MOVE WS-IN-REG-STATE TO WS-TAX-STATE-CODE
           MOVE '00000' TO WS-TAX-COUNTY-CODE
           MOVE '00000' TO WS-TAX-CITY-CODE
           MOVE WS-HV-DL-VEHICLE-PRICE TO WS-TAX-TAXABLE-AMT
           MOVE WS-HV-DL-TRADE-ALLOW TO WS-TAX-TRADE-ALLOW
           MOVE +0 TO WS-TAX-DOC-FEE-REQ
           MOVE 'NW' TO WS-TAX-VEHICLE-TYPE
           MOVE WS-HV-DL-DEAL-DATE TO WS-TAX-SALE-DATE
      *
           CALL 'COMTAXL0' USING WS-TAX-STATE-CODE
                                 WS-TAX-COUNTY-CODE
                                 WS-TAX-CITY-CODE
                                 WS-TAX-INPUT-AREA
                                 WS-TAX-RESULT-AREA
                                 WS-TAX-RETURN-CODE
                                 WS-TAX-ERROR-MSG
      *
           IF WS-TAX-RETURN-CODE NOT = +0
               STRING 'FEE CALC ERROR: '
                      WS-TAX-ERROR-MSG
                      DELIMITED BY '  '
                   INTO WS-OUT-MESSAGE
               END-STRING
               GO TO 5000-EXIT
           END-IF
      *
           MOVE WS-TAX-REG-FEE TO WS-REG-FEE
           MOVE WS-TAX-TITLE-FEE TO WS-TITLE-FEE
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-INSERT-REGISTRATION - CREATE REGISTRATION RECORD     *
      ****************************************************************
       6000-INSERT-REGISTRATION.
      *
      *    GENERATE REGISTRATION ID
      *
           EXEC SQL
               SELECT NEXT VALUE FOR AUTOSALE.REG_SEQ
               INTO  :WS-REG-ID-NUM
               FROM  SYSIBM.SYSDUMMY1
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'REGGEN00: ERROR GENERATING REGISTRATION ID'
                   TO WS-OUT-MESSAGE
               GO TO 6000-EXIT
           END-IF
      *
           MOVE WS-REG-ID-NUM TO WS-REG-ID
      *
      *    BUILD LIEN HOLDER FULL NAME AND ADDRESS
      *
           MOVE SPACES TO WS-LIEN-HOLDER-FULL
           MOVE WS-IN-LIEN-HOLDER-NAME TO WS-LIEN-HOLDER-FULL
           MOVE SPACES TO WS-LIEN-ADDR-FULL
           IF WS-IN-LIEN-HOLDER-ADDR NOT = SPACES
               STRING WS-IN-LIEN-HOLDER-ADDR DELIMITED BY '  '
                      ', ' DELIMITED BY SIZE
                      WS-IN-LIEN-HOLDER-CITY DELIMITED BY '  '
                      ', ' DELIMITED BY SIZE
                      WS-IN-LIEN-HOLDER-ST DELIMITED BY SIZE
                      ' ' DELIMITED BY SIZE
                      WS-IN-LIEN-HOLDER-ZIP DELIMITED BY '  '
                   INTO WS-LIEN-ADDR-FULL
               END-STRING
           END-IF
      *
      *    BUILD HOST VARIABLES
      *
           MOVE WS-REG-ID TO WS-HV-RG-ID
           MOVE WS-IN-DEAL-NUMBER TO WS-HV-RG-DEAL-NUMBER
           MOVE WS-HV-DL-VIN TO WS-HV-RG-VIN
           MOVE WS-HV-DL-CUSTOMER-ID TO WS-HV-RG-CUSTOMER-ID
           MOVE WS-IN-REG-STATE TO WS-HV-RG-REG-STATE
           MOVE WS-IN-REG-TYPE TO WS-HV-RG-REG-TYPE
           MOVE WS-LIEN-HOLDER-FULL TO WS-HV-RG-LIEN-HOLDER
           MOVE WS-LIEN-ADDR-FULL TO WS-HV-RG-LIEN-ADDR
           MOVE 'PR' TO WS-HV-RG-REG-STATUS
           MOVE WS-REG-FEE TO WS-HV-RG-REG-FEE
           MOVE WS-TITLE-FEE TO WS-HV-RG-TITLE-FEE
      *
      *    INSERT REGISTRATION RECORD
      *
           EXEC SQL
               INSERT INTO AUTOSALE.REGISTRATION
               ( REG_ID
               , DEAL_NUMBER
               , VIN
               , CUSTOMER_ID
               , REG_STATE
               , REG_TYPE
               , LIEN_HOLDER
               , LIEN_HOLDER_ADDR
               , REG_STATUS
               , REG_FEE_PAID
               , TITLE_FEE_PAID
               , CREATED_TS
               , UPDATED_TS
               )
               VALUES
               ( :WS-HV-RG-ID
               , :WS-HV-RG-DEAL-NUMBER
               , :WS-HV-RG-VIN
               , :WS-HV-RG-CUSTOMER-ID
               , :WS-HV-RG-REG-STATE
               , :WS-HV-RG-REG-TYPE
               , :WS-HV-RG-LIEN-HOLDER
               , :WS-HV-RG-LIEN-ADDR
               , :WS-HV-RG-REG-STATUS
               , :WS-HV-RG-REG-FEE
               , :WS-HV-RG-TITLE-FEE
               , CURRENT TIMESTAMP
               , CURRENT TIMESTAMP
               )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN OTHER
                   MOVE 'REGGEN00' TO WS-DBE-PROGRAM
                   MOVE '6000-INSERT-REGISTRATION'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.REGISTRATION'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'REGGEN00: DB2 ERROR INSERTING REGISTRATION'
                       TO WS-OUT-MESSAGE
                   GO TO 6000-EXIT
           END-EVALUATE
      *
      *    POPULATE OUTPUT STATUS FIELDS
      *
           MOVE 'PREPARING ' TO WS-OUT-REG-STATUS
           MOVE 'PENDING   ' TO WS-OUT-VALID-STATUS
      *
      *    LOG THE TRANSACTION
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'REGISTRATION' TO WS-LOG-TABLE-NAME
           MOVE 'INSERT' TO WS-LOG-ACTION
           MOVE WS-REG-ID TO WS-LOG-KEY-VALUE
           STRING 'REG GENERATED DEAL=' WS-IN-DEAL-NUMBER
                  ' VIN=' WS-HV-DL-VIN
                  ' STATE=' WS-IN-REG-STATE
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
           MOVE 'REGISTRATION PACKET ASSEMBLED SUCCESSFULLY'
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
      * END OF REGGEN00                                              *
      ****************************************************************
