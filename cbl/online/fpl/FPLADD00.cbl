       IDENTIFICATION DIVISION.
       PROGRAM-ID. FPLADD00.
      ****************************************************************
      * PROGRAM:  FPLADD00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FPL - FLOOR PLAN VEHICLE ADD                       *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  NOTIFIES LENDER OF NEW VEHICLE ADDED TO FLOOR      *
      *           PLAN. LOOKS UP INVOICE PRICE AND DEALER INFO.      *
      *           INSERTS FLOOR_PLAN_VEHICLE WITH INVOICE AS          *
      *           BALANCE, FLOOR DATE = CURRENT DATE.                *
      *           CALCULATES CURTAILMENT DATE (FLOOR DATE +           *
      *           LENDER CURTAILMENT DAYS). STATUS = AC (ACTIVE).    *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FPLA - FLOOR PLAN ADD                              *
      * MFS MOD:  ASFPLA00                                           *
      * TABLES:   AUTOSALE.FLOOR_PLAN_VEHICLE (INSERT)               *
      *           AUTOSALE.VEHICLE            (READ)                  *
      *           AUTOSALE.DEALER             (READ)                  *
      *           AUTOSALE.LENDER             (READ)                  *
      * CALLS:    COMVALD0 - VIN VALIDATION                          *
      *           COMFMTL0 - FIELD FORMATTING                        *
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
                                          VALUE 'FPLADD00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASFPLA00'.
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
           05  WS-IN-LENDER-ID           PIC X(05).
           05  WS-IN-DEALER-CODE         PIC X(05).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-VEHICLE-DESC       PIC X(40).
           05  WS-OUT-INVOICE-PRICE      PIC X(13).
           05  WS-OUT-LENDER-NAME        PIC X(30).
           05  WS-OUT-FLOOR-DATE         PIC X(10).
           05  WS-OUT-CURTAIL-DATE       PIC X(10).
           05  WS-OUT-STATUS             PIC X(02).
           05  WS-OUT-FPL-ID             PIC X(12).
           05  WS-OUT-DEALER-NAME        PIC X(30).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-CURTAIL-DAYS           PIC S9(04) COMP VALUE +0.
           05  WS-CURTAIL-DATE           PIC X(10).
           05  WS-INVOICE-AMT            PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-FPL-ID-NUM             PIC S9(09) COMP VALUE +0.
           05  WS-FPL-ID                 PIC X(12).
           05  WS-FLOOR-DATE-INT         PIC S9(08) COMP VALUE +0.
           05  WS-CURTAIL-DATE-INT       PIC S9(08) COMP VALUE +0.
           05  WS-VALID-VIN-FLAG         PIC X(01) VALUE 'N'.
               88  WS-VIN-VALID                    VALUE 'Y'.
               88  WS-VIN-INVALID                  VALUE 'N'.
      *
      *    DB2 HOST VARIABLES
      *
       01  WS-HV-VEHICLE.
           05  WS-HV-VEH-VIN            PIC X(17).
           05  WS-HV-VEH-MODEL-YEAR     PIC S9(04) COMP.
           05  WS-HV-VEH-MAKE           PIC X(03).
           05  WS-HV-VEH-MODEL          PIC X(06).
           05  WS-HV-VEH-INVOICE-PRICE  PIC S9(09)V99 COMP-3.
           05  WS-HV-VEH-STATUS         PIC X(02).
           05  WS-HV-VEH-DEALER-CODE    PIC X(05).
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-NAME           PIC X(30).
           05  WS-HV-DLR-CODE           PIC X(05).
      *
       01  WS-HV-LENDER.
           05  WS-HV-LND-ID             PIC X(05).
           05  WS-HV-LND-NAME           PIC X(30).
           05  WS-HV-LND-CURTAIL-DAYS   PIC S9(04) COMP.
      *
       01  WS-HV-FLOOR-PLAN.
           05  WS-HV-FP-ID              PIC X(12).
           05  WS-HV-FP-VIN             PIC X(17).
           05  WS-HV-FP-DEALER-CODE     PIC X(05).
           05  WS-HV-FP-LENDER-ID       PIC X(05).
           05  WS-HV-FP-FLOOR-DATE      PIC X(10).
           05  WS-HV-FP-CURTAIL-DATE    PIC X(10).
           05  WS-HV-FP-INVOICE-AMT     PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-BALANCE         PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-INTEREST-ACC    PIC S9(09)V99 COMP-3.
           05  WS-HV-FP-STATUS          PIC X(02).
           05  WS-HV-FP-PAYOFF-DATE     PIC X(10).
      *
      *    COMMON MODULE LINKAGE AREAS
      *
       01  WS-VAL-FUNCTION               PIC X(04).
       01  WS-VAL-INPUT                  PIC X(17).
       01  WS-VAL-OUTPUT                 PIC X(40).
       01  WS-VAL-RETURN-CODE            PIC S9(04) COMP.
       01  WS-VAL-ERROR-MSG              PIC X(50).
      *
       01  WS-FMT-FUNCTION               PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA        PIC X(40).
           05  WS-FMT-INPUT-NUM          PIC S9(09)V99 COMP-3.
       01  WS-FMT-OUTPUT                 PIC X(40).
       01  WS-FMT-RETURN-CODE            PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG              PIC X(50).
      *
       01  WS-LOG-FUNCTION               PIC X(04).
       01  WS-LOG-PROGRAM                PIC X(08).
       01  WS-LOG-TABLE-NAME             PIC X(18).
       01  WS-LOG-ACTION                 PIC X(08).
       01  WS-LOG-KEY-VALUE              PIC X(40).
       01  WS-LOG-DETAILS                PIC X(200).
       01  WS-LOG-RETURN-CODE            PIC S9(04) COMP.
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
               PERFORM 4000-LOOKUP-VEHICLE
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 4500-LOOKUP-LENDER
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-INSERT-FLOOR-PLAN
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
           MOVE 'FLOOR PLAN - ADD VEHICLE' TO WS-OUT-TITLE
      *
      *    GET CURRENT DATE
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
               MOVE 'FPLADD00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - VIN AND LENDER VALIDATION           *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-VIN = SPACES
               MOVE 'VIN IS REQUIRED FOR FLOOR PLAN ADD'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           IF WS-IN-LENDER-ID = SPACES
               MOVE 'LENDER ID IS REQUIRED FOR FLOOR PLAN ADD'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE VIN FORMAT USING COMMON MODULE
      *
           MOVE 'VIN ' TO WS-VAL-FUNCTION
           MOVE WS-IN-VIN TO WS-VAL-INPUT
           CALL 'COMVALD0' USING WS-VAL-FUNCTION
                                 WS-VAL-INPUT
                                 WS-VAL-OUTPUT
                                 WS-VAL-RETURN-CODE
                                 WS-VAL-ERROR-MSG
      *
           IF WS-VAL-RETURN-CODE NOT = +0
               STRING 'INVALID VIN: '
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
      *    4000-LOOKUP-VEHICLE - READ VEHICLE AND INVOICE PRICE      *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT V.VIN
                    , V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.MODEL_CODE
                    , V.INVOICE_PRICE
                    , V.VEHICLE_STATUS
                    , V.DEALER_CODE
               INTO  :WS-HV-VEH-VIN
                    , :WS-HV-VEH-MODEL-YEAR
                    , :WS-HV-VEH-MAKE
                    , :WS-HV-VEH-MODEL
                    , :WS-HV-VEH-INVOICE-PRICE
                    , :WS-HV-VEH-STATUS
                    , :WS-HV-VEH-DEALER-CODE
               FROM  AUTOSALE.VEHICLE V
               WHERE V.VIN = :WS-IN-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   CONTINUE
               WHEN +100
                   MOVE 'VEHICLE NOT FOUND FOR SPECIFIED VIN'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
               WHEN OTHER
                   MOVE 'FPLADD00' TO WS-DBE-PROGRAM
                   MOVE '4000-LOOKUP-VEHICLE' TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.VEHICLE' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'FPLADD00: DB2 ERROR READING VEHICLE'
                       TO WS-OUT-MESSAGE
                   GO TO 4000-EXIT
           END-EVALUATE
      *
      *    VEHICLE MUST BE IN STOCK (AV OR IT STATUS)
      *
           IF WS-HV-VEH-STATUS NOT = 'AV'
           AND WS-HV-VEH-STATUS NOT = 'IT'
               MOVE 'VEHICLE NOT IN AVAILABLE/IN-TRANSIT STATUS'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-HV-VEH-INVOICE-PRICE TO WS-INVOICE-AMT
           MOVE WS-HV-VEH-DEALER-CODE TO WS-IN-DEALER-CODE
      *
      *    LOOK UP DEALER NAME
      *
           EXEC SQL
               SELECT D.DEALER_NAME
                    , D.DEALER_CODE
               INTO  :WS-HV-DLR-NAME
                    , :WS-HV-DLR-CODE
               FROM  AUTOSALE.DEALER D
               WHERE D.DEALER_CODE = :WS-IN-DEALER-CODE
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'DEALER NOT FOUND FOR VEHICLE'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-HV-DLR-NAME TO WS-OUT-DEALER-NAME
           END-IF
      *
      *    FORMAT VEHICLE DESCRIPTION
      *
           STRING WS-HV-VEH-MODEL-YEAR ' '
                  WS-HV-VEH-MAKE       ' '
                  WS-HV-VEH-MODEL
                  DELIMITED BY SIZE
               INTO WS-OUT-VEHICLE-DESC
           END-STRING
      *
      *    FORMAT INVOICE PRICE
      *
           MOVE 'CUR ' TO WS-FMT-FUNCTION
           MOVE WS-INVOICE-AMT TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
           MOVE WS-FMT-OUTPUT(1:13) TO WS-OUT-INVOICE-PRICE
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4500-LOOKUP-LENDER - GET LENDER AND CURTAILMENT DAYS      *
      ****************************************************************
       4500-LOOKUP-LENDER.
      *
           EXEC SQL
               SELECT L.LENDER_ID
                    , L.LENDER_NAME
                    , L.CURTAILMENT_DAYS
               INTO  :WS-HV-LND-ID
                    , :WS-HV-LND-NAME
                    , :WS-HV-LND-CURTAIL-DAYS
               FROM  AUTOSALE.LENDER L
               WHERE L.LENDER_ID = :WS-IN-LENDER-ID
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE WS-HV-LND-NAME TO WS-OUT-LENDER-NAME
                   MOVE WS-HV-LND-CURTAIL-DAYS TO WS-CURTAIL-DAYS
               WHEN +100
                   MOVE 'LENDER NOT FOUND FOR SPECIFIED ID'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE 'FPLADD00' TO WS-DBE-PROGRAM
                   MOVE '4500-LOOKUP-LENDER' TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.LENDER' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'FPLADD00: DB2 ERROR READING LENDER'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
      *
      *    CALCULATE CURTAILMENT DATE
      *
           IF WS-OUT-MESSAGE = SPACES
               EXEC SQL
                   SET :WS-CURTAIL-DATE =
                       CHAR(CURRENT DATE
                            + :WS-CURTAIL-DAYS DAYS, ISO)
               END-EXEC
               MOVE WS-CURTAIL-DATE TO WS-OUT-CURTAIL-DATE
           END-IF
           .
      *
      ****************************************************************
      *    5000-INSERT-FLOOR-PLAN - CREATE FLOOR PLAN RECORD         *
      ****************************************************************
       5000-INSERT-FLOOR-PLAN.
      *
      *    BUILD FLOOR PLAN RECORD
      *
           MOVE WS-IN-VIN TO WS-HV-FP-VIN
           MOVE WS-IN-DEALER-CODE TO WS-HV-FP-DEALER-CODE
           MOVE WS-IN-LENDER-ID TO WS-HV-FP-LENDER-ID
           MOVE WS-CURRENT-DATE TO WS-HV-FP-FLOOR-DATE
           MOVE WS-CURTAIL-DATE TO WS-HV-FP-CURTAIL-DATE
           MOVE WS-INVOICE-AMT TO WS-HV-FP-INVOICE-AMT
           MOVE WS-INVOICE-AMT TO WS-HV-FP-BALANCE
           MOVE +0 TO WS-HV-FP-INTEREST-ACC
           MOVE 'AC' TO WS-HV-FP-STATUS
           MOVE SPACES TO WS-HV-FP-PAYOFF-DATE
      *
      *    GENERATE FLOOR PLAN ID
      *
           EXEC SQL
               SELECT NEXT VALUE FOR AUTOSALE.FPL_SEQ
               INTO  :WS-FPL-ID-NUM
               FROM  SYSIBM.SYSDUMMY1
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLADD00: ERROR GENERATING FLOOR PLAN ID'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE WS-FPL-ID-NUM TO WS-FPL-ID
           MOVE WS-FPL-ID TO WS-HV-FP-ID
      *
      *    INSERT FLOOR PLAN VEHICLE
      *
           EXEC SQL
               INSERT INTO AUTOSALE.FLOOR_PLAN_VEHICLE
               ( FLOOR_PLAN_ID
               , VIN
               , DEALER_CODE
               , LENDER_ID
               , FLOOR_DATE
               , CURTAILMENT_DATE
               , INVOICE_AMOUNT
               , CURRENT_BALANCE
               , INTEREST_ACCRUED
               , FLOOR_STATUS
               , PAYOFF_DATE
               , CREATED_TIMESTAMP
               , CREATED_USER
               )
               VALUES
               ( :WS-HV-FP-ID
               , :WS-HV-FP-VIN
               , :WS-HV-FP-DEALER-CODE
               , :WS-HV-FP-LENDER-ID
               , :WS-HV-FP-FLOOR-DATE
               , :WS-HV-FP-CURTAIL-DATE
               , :WS-HV-FP-INVOICE-AMT
               , :WS-HV-FP-BALANCE
               , :WS-HV-FP-INTEREST-ACC
               , :WS-HV-FP-STATUS
               , NULL
               , CURRENT TIMESTAMP
               , :IO-USER
               )
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'FPLADD00' TO WS-DBE-PROGRAM
               MOVE '5000-INSERT-FLOOR-PLAN' TO WS-DBE-PARAGRAPH
               MOVE 'AUTOSALE.FLOOR_PLAN_VEHICLE'
                   TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               MOVE 'FPLADD00: DB2 ERROR INSERTING FLOOR PLAN'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
      *    POPULATE OUTPUT FIELDS
      *
           MOVE WS-FPL-ID TO WS-OUT-FPL-ID
           MOVE WS-IN-VIN TO WS-OUT-VIN
           MOVE WS-CURRENT-DATE TO WS-OUT-FLOOR-DATE
           MOVE 'AC' TO WS-OUT-STATUS
      *
      *    LOG THE TRANSACTION
      *
           MOVE 'LOG ' TO WS-LOG-FUNCTION
           MOVE WS-PROGRAM-NAME TO WS-LOG-PROGRAM
           MOVE 'FLOOR_PLAN_VEHICLE' TO WS-LOG-TABLE-NAME
           MOVE 'INSERT' TO WS-LOG-ACTION
           MOVE WS-FPL-ID TO WS-LOG-KEY-VALUE
           STRING 'FLOOR PLAN ADDED VIN=' WS-IN-VIN
                  ' LENDER=' WS-IN-LENDER-ID
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
           MOVE 'FLOOR PLAN VEHICLE ADDED SUCCESSFULLY'
               TO WS-OUT-MESSAGE
           .
       5000-EXIT.
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
      * END OF FPLADD00                                              *
      ****************************************************************
