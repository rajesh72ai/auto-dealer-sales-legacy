       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRCINQ00.
      ****************************************************************
      * PROGRAM:  WRCINQ00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   WRC - WARRANTY INQUIRY / COVERAGE LOOKUP           *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DISPLAYS WARRANTY COVERAGE FOR A VEHICLE.          *
      *           SHOWS VEHICLE INFO (JOIN VEHICLE + MODEL_MASTER),  *
      *           CURRENT OWNER (FROM LATEST SALES_DEAL), AND ALL    *
      *           WARRANTY COVERAGES WITH TYPE, START, EXPIRY,       *
      *           MILEAGE LIMIT, DEDUCTIBLE, AND ACTIVE/EXPIRED.     *
      *           CALCULATES REMAINING COVERAGE IN DAYS.             *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    WRCI - WARRANTY INQUIRY                            *
      * MFS MOD:  ASWRCI00                                           *
      * TABLES:   AUTOSALE.WARRANTY    (READ)                        *
      *           AUTOSALE.VEHICLE     (READ)                        *
      *           AUTOSALE.MODEL_MASTER(READ)                        *
      *           AUTOSALE.SALES_DEAL  (READ)                        *
      *           AUTOSALE.CUSTOMER    (READ)                        *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                        *
      *           COMDTEL0 - DATE CALCULATION                        *
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
                                          VALUE 'WRCINQ00'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASWRCI00'.
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
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
      *    VEHICLE INFO
           05  WS-OUT-VIN                PIC X(17).
           05  WS-OUT-VEHICLE-DESC       PIC X(40).
           05  WS-OUT-VEHICLE-COLOR      PIC X(15).
           05  WS-OUT-SALE-DATE          PIC X(10).
      *    OWNER INFO
           05  WS-OUT-OWNER-NAME         PIC X(30).
           05  WS-OUT-OWNER-PHONE        PIC X(14).
      *    WARRANTY COVERAGES
           05  WS-OUT-WARR-COUNT         PIC S9(04) COMP.
           05  WS-OUT-WARR-DTL OCCURS 6 TIMES.
               10  WS-OUT-WR-TYPE        PIC X(12).
               10  WS-OUT-WR-START       PIC X(10).
               10  WS-OUT-WR-EXPIRY      PIC X(10).
               10  WS-OUT-WR-MILE-LIMIT  PIC Z(6)9.
               10  WS-OUT-WR-DEDUCTIBLE  PIC X(08).
               10  WS-OUT-WR-STATUS-DSP  PIC X(07).
               10  WS-OUT-WR-REMAIN-DAYS PIC Z(4)9.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-ROW-COUNT              PIC S9(04) COMP VALUE +0.
           05  WS-REMAINING-DAYS         PIC S9(04) COMP VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
      *
      *    DB2 HOST VARIABLES - VEHICLE
      *
       01  WS-HV-VEH.
           05  WS-HV-VEH-VIN            PIC X(17).
           05  WS-HV-VEH-MODEL-YEAR     PIC S9(04) COMP.
           05  WS-HV-VEH-MAKE           PIC X(03).
           05  WS-HV-VEH-MODEL          PIC X(06).
           05  WS-HV-VEH-MODEL-NAME     PIC X(30).
           05  WS-HV-VEH-EXT-COLOR      PIC X(15).
      *
      *    DB2 HOST VARIABLES - OWNER
      *
       01  WS-HV-OWNER.
           05  WS-HV-OWN-FIRST-NAME     PIC X(20).
           05  WS-HV-OWN-LAST-NAME      PIC X(25).
           05  WS-HV-OWN-PHONE          PIC X(14).
           05  WS-HV-OWN-SALE-DATE      PIC X(10).
      *
      *    DB2 HOST VARIABLES - WARRANTY CURSOR FETCH
      *
       01  WS-HV-WARR.
           05  WS-HV-WR-TYPE            PIC X(04).
           05  WS-HV-WR-START-DATE      PIC X(10).
           05  WS-HV-WR-EXPIRY-DATE     PIC X(10).
           05  WS-HV-WR-MILE-LIMIT      PIC S9(06) COMP.
           05  WS-HV-WR-DEDUCTIBLE      PIC S9(05)V99 COMP-3.
           05  WS-HV-WR-STATUS          PIC X(02).
      *
      *    TYPE DESCRIPTION LOOKUP
      *
       01  WS-TYPE-DESC-TABLE.
           05  FILLER PIC X(16) VALUE 'BASCBASIC       '.
           05  FILLER PIC X(16) VALUE 'PWRTPOWERTRAIN  '.
           05  FILLER PIC X(16) VALUE 'CORRCORROSION   '.
           05  FILLER PIC X(16) VALUE 'EMISEMISSION    '.
       01  WS-TYPE-DESC-REDEF REDEFINES WS-TYPE-DESC-TABLE.
           05  WS-TD-ENTRY OCCURS 4 TIMES.
               10  WS-TD-CODE            PIC X(04).
               10  WS-TD-DESC            PIC X(12).
      *
       01  WS-TYPE-INDEX                 PIC S9(04) COMP VALUE +0.
       01  WS-TYPE-FOUND                 PIC X(12) VALUE SPACES.
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
      *    CURSOR FOR WARRANTY COVERAGES
      *
           EXEC SQL DECLARE CSR_WARR_INQ CURSOR FOR
               SELECT W.WARRANTY_TYPE
                    , W.START_DATE
                    , W.EXPIRY_DATE
                    , W.MILEAGE_LIMIT
                    , W.DEDUCTIBLE_AMT
                    , W.WARRANTY_STATUS
               FROM   AUTOSALE.WARRANTY W
               WHERE  W.VIN = :WS-IN-VIN
               ORDER BY W.EXPIRY_DATE
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
               PERFORM 4000-LOOKUP-VEHICLE
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 4500-LOOKUP-OWNER
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-RETRIEVE-WARRANTIES
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
           MOVE 'WARRANTY COVERAGE INQUIRY' TO WS-OUT-TITLE
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
               MOVE 'WRCINQ00: ERROR RECEIVING INPUT MESSAGE'
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
               MOVE 'VIN IS REQUIRED FOR WARRANTY INQUIRY'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    4000-LOOKUP-VEHICLE - GET VEHICLE AND MODEL INFO          *
      ****************************************************************
       4000-LOOKUP-VEHICLE.
      *
           EXEC SQL
               SELECT V.VIN
                    , V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.MODEL_CODE
                    , M.MODEL_NAME
                    , V.EXTERIOR_COLOR
               INTO  :WS-HV-VEH-VIN
                    , :WS-HV-VEH-MODEL-YEAR
                    , :WS-HV-VEH-MAKE
                    , :WS-HV-VEH-MODEL
                    , :WS-HV-VEH-MODEL-NAME
                    , :WS-HV-VEH-EXT-COLOR
               FROM  AUTOSALE.VEHICLE V
               JOIN  AUTOSALE.MODEL_MASTER M
                 ON  V.MODEL_YEAR = M.MODEL_YEAR
                AND  V.MAKE_CODE  = M.MAKE_CODE
                AND  V.MODEL_CODE = M.MODEL_CODE
               WHERE V.VIN = :WS-IN-VIN
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE WS-IN-VIN TO WS-OUT-VIN
                   STRING WS-HV-VEH-MODEL-YEAR ' '
                          WS-HV-VEH-MAKE ' '
                          WS-HV-VEH-MODEL-NAME
                          DELIMITED BY SIZE
                       INTO WS-OUT-VEHICLE-DESC
                   END-STRING
                   MOVE WS-HV-VEH-EXT-COLOR TO WS-OUT-VEHICLE-COLOR
               WHEN +100
                   MOVE 'VEHICLE NOT FOUND FOR SPECIFIED VIN'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE 'WRCINQ00: DB2 ERROR READING VEHICLE'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4500-LOOKUP-OWNER - GET CURRENT OWNER FROM LATEST DEAL    *
      ****************************************************************
       4500-LOOKUP-OWNER.
      *
           EXEC SQL
               SELECT C.FIRST_NAME
                    , C.LAST_NAME
                    , C.PHONE_NUMBER
                    , D.SALE_DATE
               INTO  :WS-HV-OWN-FIRST-NAME
                    , :WS-HV-OWN-LAST-NAME
                    , :WS-HV-OWN-PHONE
                    , :WS-HV-OWN-SALE-DATE
               FROM  AUTOSALE.SALES_DEAL D
               JOIN  AUTOSALE.CUSTOMER C
                 ON  D.CUSTOMER_ID = C.CUSTOMER_ID
               WHERE D.VIN = :WS-IN-VIN
                 AND D.DEAL_STATUS = 'DL'
               ORDER BY D.SALE_DATE DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
      *
           IF SQLCODE = +0
               STRING WS-HV-OWN-FIRST-NAME ' '
                      WS-HV-OWN-LAST-NAME
                      DELIMITED BY '  '
                   INTO WS-OUT-OWNER-NAME
               END-STRING
               MOVE WS-HV-OWN-PHONE TO WS-OUT-OWNER-PHONE
               MOVE WS-HV-OWN-SALE-DATE TO WS-OUT-SALE-DATE
           ELSE
               MOVE 'OWNER UNKNOWN' TO WS-OUT-OWNER-NAME
           END-IF
           .
      *
      ****************************************************************
      *    5000-RETRIEVE-WARRANTIES - OPEN CURSOR AND FETCH          *
      ****************************************************************
       5000-RETRIEVE-WARRANTIES.
      *
           EXEC SQL OPEN CSR_WARR_INQ END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'WRCINQ00: ERROR OPENING WARRANTY CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 5100-FETCH-WARRANTY
               UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +6
      *
           EXEC SQL CLOSE CSR_WARR_INQ END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO WARRANTY RECORDS FOUND FOR THIS VIN'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-ROW-COUNT TO WS-OUT-WARR-COUNT
               MOVE 'WARRANTY COVERAGE DISPLAYED SUCCESSFULLY'
                   TO WS-OUT-MESSAGE
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-WARRANTY - FETCH ONE WARRANTY ROW              *
      ****************************************************************
       5100-FETCH-WARRANTY.
      *
           EXEC SQL FETCH CSR_WARR_INQ
               INTO  :WS-HV-WR-TYPE
                    , :WS-HV-WR-START-DATE
                    , :WS-HV-WR-EXPIRY-DATE
                    , :WS-HV-WR-MILE-LIMIT
                    , :WS-HV-WR-DEDUCTIBLE
                    , :WS-HV-WR-STATUS
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   PERFORM 5200-FORMAT-WARRANTY-LINE
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'WRCINQ00: DB2 ERROR READING WARRANTIES'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5200-FORMAT-WARRANTY-LINE - FORMAT DETAIL ROW             *
      ****************************************************************
       5200-FORMAT-WARRANTY-LINE.
      *
      *    LOOKUP TYPE DESCRIPTION
      *
           MOVE SPACES TO WS-TYPE-FOUND
           PERFORM VARYING WS-TYPE-INDEX FROM +1 BY +1
               UNTIL WS-TYPE-INDEX > +4
               IF WS-TD-CODE(WS-TYPE-INDEX) = WS-HV-WR-TYPE
                   MOVE WS-TD-DESC(WS-TYPE-INDEX) TO WS-TYPE-FOUND
               END-IF
           END-PERFORM
           IF WS-TYPE-FOUND = SPACES
               MOVE WS-HV-WR-TYPE TO WS-TYPE-FOUND
           END-IF
      *
           MOVE WS-TYPE-FOUND
               TO WS-OUT-WR-TYPE(WS-ROW-COUNT)
           MOVE WS-HV-WR-START-DATE
               TO WS-OUT-WR-START(WS-ROW-COUNT)
           MOVE WS-HV-WR-EXPIRY-DATE
               TO WS-OUT-WR-EXPIRY(WS-ROW-COUNT)
           MOVE WS-HV-WR-MILE-LIMIT
               TO WS-OUT-WR-MILE-LIMIT(WS-ROW-COUNT)
      *
           IF WS-HV-WR-DEDUCTIBLE = +0
               MOVE 'NONE    '
                   TO WS-OUT-WR-DEDUCTIBLE(WS-ROW-COUNT)
           ELSE
               MOVE 'CUR ' TO WS-FMT-FUNCTION
               MOVE WS-HV-WR-DEDUCTIBLE TO WS-FMT-INPUT-NUM
               CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                     WS-FMT-INPUT
                                     WS-FMT-OUTPUT
                                     WS-FMT-RETURN-CODE
                                     WS-FMT-ERROR-MSG
               MOVE WS-FMT-OUTPUT(1:8)
                   TO WS-OUT-WR-DEDUCTIBLE(WS-ROW-COUNT)
           END-IF
      *
      *    DETERMINE ACTIVE/EXPIRED AND REMAINING DAYS
      *
           EXEC SQL
               SET :WS-REMAINING-DAYS =
                   DAYS(:WS-HV-WR-EXPIRY-DATE)
                   - DAYS(CURRENT DATE)
           END-EXEC
      *
           IF WS-HV-WR-STATUS = 'AC'
           AND WS-REMAINING-DAYS > +0
               MOVE 'ACTIVE '
                   TO WS-OUT-WR-STATUS-DSP(WS-ROW-COUNT)
               MOVE WS-REMAINING-DAYS
                   TO WS-OUT-WR-REMAIN-DAYS(WS-ROW-COUNT)
           ELSE
               MOVE 'EXPIRED'
                   TO WS-OUT-WR-STATUS-DSP(WS-ROW-COUNT)
               MOVE +0
                   TO WS-OUT-WR-REMAIN-DAYS(WS-ROW-COUNT)
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
      * END OF WRCINQ00                                              *
      ****************************************************************
