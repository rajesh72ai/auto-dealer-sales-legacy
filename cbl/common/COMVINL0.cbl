       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMVINL0.
      ****************************************************************
      * PROGRAM:  COMVINL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - VIN DECODER MODULE                        *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DECODES A 17-CHARACTER VIN (VEHICLE IDENTIFICATION *
      *           NUMBER) PER NHTSA/ISO 3779 STANDARD.               *
      *           VALIDATES CHECK DIGIT (POSITION 9).                *
      *           EXTRACTS: COUNTRY, MANUFACTURER, MODEL YEAR,       *
      *           ASSEMBLY PLANT, PRODUCTION SEQUENCE NUMBER.         *
      * CALLABLE: YES - VIA CALL 'COMVINL0' USING LS-VIN-REQUEST    *
      *                                            LS-VIN-RESULT     *
      * VIN POSITIONS:                                               *
      *   1-3:  WMI (WORLD MANUFACTURER IDENTIFIER)                  *
      *   4-8:  VDS (VEHICLE DESCRIPTOR SECTION)                     *
      *   9:    CHECK DIGIT                                          *
      *   10:   MODEL YEAR                                           *
      *   11:   ASSEMBLY PLANT                                       *
      *   12-17: SEQUENTIAL PRODUCTION NUMBER                        *
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
                                          VALUE 'COMVINL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    VIN DECOMPOSITION WORK AREA
      *
       01  WS-VIN-DECOMP.
           05  WS-VIN-FULL               PIC X(17)    VALUE SPACES.
           05  WS-VIN-CHARS.
               10  WS-VIN-CHAR           PIC X(01)
                                          OCCURS 17 TIMES.
           05  WS-VIN-WMI                PIC X(03)    VALUE SPACES.
           05  WS-VIN-VDS                PIC X(05)    VALUE SPACES.
           05  WS-VIN-CHECK              PIC X(01)    VALUE SPACES.
           05  WS-VIN-YEAR-CODE          PIC X(01)    VALUE SPACES.
           05  WS-VIN-PLANT-CODE         PIC X(01)    VALUE SPACES.
           05  WS-VIN-SEQ-NUM            PIC X(06)    VALUE SPACES.
      *
      *    CHECK DIGIT CALCULATION
      *
       01  WS-CHECK-DIGIT-FIELDS.
           05  WS-TRANSLITERATION.
               10  WS-TRANS-VALUE        PIC 9(02)
                                          OCCURS 17 TIMES
                                          VALUE ZEROS.
           05  WS-POSITION-WEIGHT.
               10  FILLER                PIC 9(01) VALUE 8.
               10  FILLER                PIC 9(01) VALUE 7.
               10  FILLER                PIC 9(01) VALUE 6.
               10  FILLER                PIC 9(01) VALUE 5.
               10  FILLER                PIC 9(01) VALUE 4.
               10  FILLER                PIC 9(01) VALUE 3.
               10  FILLER                PIC 9(01) VALUE 2.
               10  FILLER                PIC 9(01) VALUE 0.
               10  FILLER                PIC 9(01) VALUE 0.
               10  FILLER                PIC 9(01) VALUE 9.
               10  FILLER                PIC 9(01) VALUE 8.
               10  FILLER                PIC 9(01) VALUE 7.
               10  FILLER                PIC 9(01) VALUE 6.
               10  FILLER                PIC 9(01) VALUE 5.
               10  FILLER                PIC 9(01) VALUE 4.
               10  FILLER                PIC 9(01) VALUE 3.
               10  FILLER                PIC 9(01) VALUE 2.
           05  WS-WEIGHTS REDEFINES WS-POSITION-WEIGHT.
               10  WS-WEIGHT             PIC 9(01)
                                          OCCURS 17 TIMES.
           05  WS-WEIGHTED-SUM           PIC S9(09)   COMP
                                                       VALUE +0.
           05  WS-CHECK-REMAINDER        PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-CALCULATED-CHECK       PIC X(01)    VALUE SPACES.
           05  WS-PRODUCT                PIC S9(05)   COMP
                                                       VALUE +0.
      *
      *    CHARACTER TRANSLITERATION TABLE
      *    A=1 B=2 C=3 D=4 E=5 F=6 G=7 H=8 (NO I,O,Q)
      *    J=1 K=2 L=3 M=4 N=5 P=7 R=9 S=2 T=3 U=4 V=5
      *    W=6 X=7 Y=8 Z=9
      *
       01  WS-TRANS-TABLE-DATA.
           05  FILLER PIC X(02) VALUE 'A1'.
           05  FILLER PIC X(02) VALUE 'B2'.
           05  FILLER PIC X(02) VALUE 'C3'.
           05  FILLER PIC X(02) VALUE 'D4'.
           05  FILLER PIC X(02) VALUE 'E5'.
           05  FILLER PIC X(02) VALUE 'F6'.
           05  FILLER PIC X(02) VALUE 'G7'.
           05  FILLER PIC X(02) VALUE 'H8'.
           05  FILLER PIC X(02) VALUE 'J1'.
           05  FILLER PIC X(02) VALUE 'K2'.
           05  FILLER PIC X(02) VALUE 'L3'.
           05  FILLER PIC X(02) VALUE 'M4'.
           05  FILLER PIC X(02) VALUE 'N5'.
           05  FILLER PIC X(02) VALUE 'P7'.
           05  FILLER PIC X(02) VALUE 'R9'.
           05  FILLER PIC X(02) VALUE 'S2'.
           05  FILLER PIC X(02) VALUE 'T3'.
           05  FILLER PIC X(02) VALUE 'U4'.
           05  FILLER PIC X(02) VALUE 'V5'.
           05  FILLER PIC X(02) VALUE 'W6'.
           05  FILLER PIC X(02) VALUE 'X7'.
           05  FILLER PIC X(02) VALUE 'Y8'.
           05  FILLER PIC X(02) VALUE 'Z9'.
       01  WS-TRANS-TABLE REDEFINES WS-TRANS-TABLE-DATA.
           05  WS-TRANS-ENTRY            OCCURS 23 TIMES.
               10  WS-TRANS-CHAR         PIC X(01).
               10  WS-TRANS-VAL          PIC 9(01).
      *
      *    LOOP COUNTERS
      *
       01  WS-LOOP-FIELDS.
           05  WS-POS-INDEX              PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-TRANS-INDEX            PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-FOUND-FLAG             PIC X(01)    VALUE 'N'.
               88  WS-FOUND                           VALUE 'Y'.
               88  WS-NOT-FOUND                       VALUE 'N'.
      *
      *    DECODED FIELDS
      *
       01  WS-DECODED-FIELDS.
           05  WS-COUNTRY                PIC X(20)    VALUE SPACES.
           05  WS-MANUFACTURER           PIC X(30)    VALUE SPACES.
           05  WS-MODEL-YEAR             PIC 9(04)    VALUE ZEROS.
           05  WS-ASSEMBLY-PLANT         PIC X(30)    VALUE SPACES.
           05  WS-BODY-TYPE              PIC X(20)    VALUE SPACES.
           05  WS-ENGINE-TYPE            PIC X(20)    VALUE SPACES.
           05  WS-RESTRAINT              PIC X(20)    VALUE SPACES.
      *
      *    VALIDATION FLAGS
      *
       01  WS-VALID-FLAGS.
           05  WS-LENGTH-VALID           PIC X(01)    VALUE 'N'.
           05  WS-CHARS-VALID            PIC X(01)    VALUE 'Y'.
           05  WS-CHECK-VALID            PIC X(01)    VALUE 'N'.
      *
       LINKAGE SECTION.
      *
      *    VIN DECODE REQUEST
      *
       01  LS-VIN-REQUEST.
           05  LS-VR-VIN                 PIC X(17).
           05  LS-VR-FUNCTION            PIC X(04).
               88  LS-VR-DECODE                        VALUE 'DECD'.
               88  LS-VR-VALIDATE                      VALUE 'VALD'.
               88  LS-VR-FULL                          VALUE 'FULL'.
      *
      *    VIN DECODE RESULT
      *
       01  LS-VIN-RESULT.
           05  LS-VD-RETURN-CODE         PIC S9(04)   COMP.
           05  LS-VD-RETURN-MSG          PIC X(79).
           05  LS-VD-VALID-FLAG          PIC X(01).
               88  LS-VD-IS-VALID                      VALUE 'Y'.
               88  LS-VD-IS-INVALID                    VALUE 'N'.
           05  LS-VD-CHECK-DIGIT-OK      PIC X(01).
               88  LS-VD-CHECK-PASS                    VALUE 'Y'.
               88  LS-VD-CHECK-FAIL                    VALUE 'N'.
           05  LS-VD-COUNTRY             PIC X(20).
           05  LS-VD-MANUFACTURER        PIC X(30).
           05  LS-VD-MODEL-YEAR          PIC 9(04).
           05  LS-VD-ASSEMBLY-PLANT      PIC X(30).
           05  LS-VD-BODY-TYPE           PIC X(20).
           05  LS-VD-ENGINE-TYPE         PIC X(20).
           05  LS-VD-RESTRAINT           PIC X(20).
           05  LS-VD-SEQ-NUMBER          PIC X(06).
           05  LS-VD-WMI                 PIC X(03).
           05  LS-VD-VDS                 PIC X(05).
           05  LS-VD-YEAR-CODE           PIC X(01).
           05  LS-VD-PLANT-CODE          PIC X(01).
      *
       PROCEDURE DIVISION USING LS-VIN-REQUEST
                                LS-VIN-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-VALIDATE-LENGTH
      *
           IF WS-LENGTH-VALID = 'Y'
               PERFORM 2100-VALIDATE-CHARACTERS
           END-IF
      *
           IF WS-CHARS-VALID = 'Y'
           AND WS-LENGTH-VALID = 'Y'
               PERFORM 3000-DECOMPOSE-VIN
               PERFORM 4000-VALIDATE-CHECK-DIGIT
               PERFORM 5000-DECODE-WMI
               PERFORM 6000-DECODE-YEAR
               PERFORM 7000-DECODE-PLANT
               PERFORM 8000-DECODE-ATTRIBUTES
               PERFORM 9000-SET-RESULTS
           END-IF
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-VIN-RESULT
           INITIALIZE WS-VIN-DECOMP
           INITIALIZE WS-DECODED-FIELDS
           MOVE +0  TO LS-VD-RETURN-CODE
           MOVE 'N' TO LS-VD-VALID-FLAG
           MOVE 'N' TO LS-VD-CHECK-DIGIT-OK
           MOVE 'N' TO WS-LENGTH-VALID
           MOVE 'Y' TO WS-CHARS-VALID
           MOVE 'N' TO WS-CHECK-VALID
      *
           IF  NOT LS-VR-DECODE
           AND NOT LS-VR-VALIDATE
           AND NOT LS-VR-FULL
               MOVE 'DECD' TO LS-VR-FUNCTION
           END-IF
           .
      *
      ****************************************************************
      *    2000-VALIDATE-LENGTH - VIN MUST BE EXACTLY 17 CHARS       *
      ****************************************************************
       2000-VALIDATE-LENGTH.
      *
           IF FUNCTION LENGTH(FUNCTION TRIM(LS-VR-VIN))
               NOT = 17
               MOVE +8 TO LS-VD-RETURN-CODE
               MOVE 'COMVINL0: VIN MUST BE EXACTLY 17 CHARACTERS'
                   TO LS-VD-RETURN-MSG
               MOVE 'N' TO LS-VD-VALID-FLAG
               MOVE 'N' TO WS-LENGTH-VALID
           ELSE
               MOVE 'Y' TO WS-LENGTH-VALID
               MOVE LS-VR-VIN TO WS-VIN-FULL
           END-IF
           .
      *
      ****************************************************************
      *    2100-VALIDATE-CHARACTERS - NO I, O, Q ALLOWED             *
      ****************************************************************
       2100-VALIDATE-CHARACTERS.
      *
           MOVE WS-VIN-FULL TO WS-VIN-CHARS
      *
           PERFORM VARYING WS-POS-INDEX
               FROM +1 BY +1
               UNTIL WS-POS-INDEX > +17
      *
      *        CHECK FOR INVALID CHARACTERS (I, O, Q)
      *
               IF WS-VIN-CHAR(WS-POS-INDEX) = 'I'
               OR WS-VIN-CHAR(WS-POS-INDEX) = 'O'
               OR WS-VIN-CHAR(WS-POS-INDEX) = 'Q'
                   MOVE 'N' TO WS-CHARS-VALID
                   MOVE +8 TO LS-VD-RETURN-CODE
                   MOVE
                   'COMVINL0: VIN CONTAINS INVALID CHAR (I, O, OR Q)'
                       TO LS-VD-RETURN-MSG
                   MOVE 'N' TO LS-VD-VALID-FLAG
               END-IF
      *
      *        CHECK FOR VALID ALPHANUMERIC
      *
               IF  WS-VIN-CHAR(WS-POS-INDEX) NOT ALPHABETIC-UPPER
               AND WS-VIN-CHAR(WS-POS-INDEX) NOT NUMERIC
                   MOVE 'N' TO WS-CHARS-VALID
                   MOVE +8 TO LS-VD-RETURN-CODE
                   MOVE
                 'COMVINL0: VIN CONTAINS NON-ALPHANUMERIC CHARACTER'
                       TO LS-VD-RETURN-MSG
                   MOVE 'N' TO LS-VD-VALID-FLAG
               END-IF
      *
           END-PERFORM
           .
      *
      ****************************************************************
      *    3000-DECOMPOSE-VIN - SPLIT VIN INTO SECTIONS              *
      ****************************************************************
       3000-DECOMPOSE-VIN.
      *
           MOVE WS-VIN-FULL(1:3)   TO WS-VIN-WMI
           MOVE WS-VIN-FULL(4:5)   TO WS-VIN-VDS
           MOVE WS-VIN-FULL(9:1)   TO WS-VIN-CHECK
           MOVE WS-VIN-FULL(10:1)  TO WS-VIN-YEAR-CODE
           MOVE WS-VIN-FULL(11:1)  TO WS-VIN-PLANT-CODE
           MOVE WS-VIN-FULL(12:6)  TO WS-VIN-SEQ-NUM
      *
           MOVE WS-VIN-WMI         TO LS-VD-WMI
           MOVE WS-VIN-VDS         TO LS-VD-VDS
           MOVE WS-VIN-YEAR-CODE   TO LS-VD-YEAR-CODE
           MOVE WS-VIN-PLANT-CODE  TO LS-VD-PLANT-CODE
           MOVE WS-VIN-SEQ-NUM     TO LS-VD-SEQ-NUMBER
           .
      *
      ****************************************************************
      *    4000-VALIDATE-CHECK-DIGIT - POSITION 9 CHECK DIGIT       *
      *    TRANSLITERATE LETTERS TO NUMBERS, MULTIPLY BY POSITION   *
      *    WEIGHTS, SUM, MOD 11 = CHECK DIGIT (0-9 OR X)            *
      ****************************************************************
       4000-VALIDATE-CHECK-DIGIT.
      *
           MOVE +0 TO WS-WEIGHTED-SUM
      *
      *    TRANSLITERATE EACH VIN CHARACTER TO NUMERIC VALUE
      *
           PERFORM VARYING WS-POS-INDEX
               FROM +1 BY +1
               UNTIL WS-POS-INDEX > +17
      *
      *        SKIP POSITION 9 (CHECK DIGIT ITSELF)
      *        WEIGHT IS 0 SO IT DOESN'T AFFECT SUM ANYWAY
      *
               IF WS-VIN-CHAR(WS-POS-INDEX) IS NUMERIC
      *            NUMERIC - USE AS-IS
                   COMPUTE WS-TRANS-VALUE(WS-POS-INDEX) =
                       FUNCTION ORD(WS-VIN-CHAR(WS-POS-INDEX))
                       - FUNCTION ORD('0')
                   END-COMPUTE
               ELSE
      *            ALPHA - LOOK UP IN TRANSLITERATION TABLE
                   MOVE 'N' TO WS-FOUND-FLAG
                   PERFORM VARYING WS-TRANS-INDEX
                       FROM +1 BY +1
                       UNTIL WS-TRANS-INDEX > +23
                       OR WS-FOUND
      *
                       IF WS-VIN-CHAR(WS-POS-INDEX) =
                           WS-TRANS-CHAR(WS-TRANS-INDEX)
                           MOVE WS-TRANS-VAL(WS-TRANS-INDEX)
                               TO WS-TRANS-VALUE(WS-POS-INDEX)
                           MOVE 'Y' TO WS-FOUND-FLAG
                       END-IF
      *
                   END-PERFORM
      *
                   IF WS-NOT-FOUND
                       MOVE +0 TO WS-TRANS-VALUE(WS-POS-INDEX)
                   END-IF
               END-IF
      *
      *        MULTIPLY BY POSITION WEIGHT AND ADD TO SUM
      *
               COMPUTE WS-PRODUCT =
                   WS-TRANS-VALUE(WS-POS-INDEX)
                   * WS-WEIGHT(WS-POS-INDEX)
               END-COMPUTE
      *
               ADD WS-PRODUCT TO WS-WEIGHTED-SUM
      *
           END-PERFORM
      *
      *    MOD 11 TO GET CHECK DIGIT
      *
           DIVIDE WS-WEIGHTED-SUM BY 11
               GIVING WS-WEIGHTED-SUM
               REMAINDER WS-CHECK-REMAINDER
      *
           IF WS-CHECK-REMAINDER = +10
               MOVE 'X' TO WS-CALCULATED-CHECK
           ELSE
               MOVE WS-CHECK-REMAINDER TO WS-CALCULATED-CHECK
           END-IF
      *
      *    COMPARE TO ACTUAL CHECK DIGIT
      *
           IF WS-VIN-CHECK = WS-CALCULATED-CHECK
               MOVE 'Y' TO WS-CHECK-VALID
               MOVE 'Y' TO LS-VD-CHECK-DIGIT-OK
           ELSE
               MOVE 'N' TO WS-CHECK-VALID
               MOVE 'N' TO LS-VD-CHECK-DIGIT-OK
               MOVE +4 TO LS-VD-RETURN-CODE
               MOVE 'COMVINL0: CHECK DIGIT VALIDATION FAILED'
                   TO LS-VD-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    5000-DECODE-WMI - WORLD MANUFACTURER IDENTIFIER           *
      *    POSITION 1: COUNTRY/REGION                                *
      *    POSITIONS 1-3: MANUFACTURER                               *
      ****************************************************************
       5000-DECODE-WMI.
      *
      *    DECODE COUNTRY OF ORIGIN (POSITION 1)
      *
           EVALUATE WS-VIN-WMI(1:1)
               WHEN '1' WHEN '4' WHEN '5'
                   MOVE 'UNITED STATES'    TO WS-COUNTRY
               WHEN '2'
                   MOVE 'CANADA'           TO WS-COUNTRY
               WHEN '3'
                   MOVE 'MEXICO'           TO WS-COUNTRY
               WHEN 'J'
                   MOVE 'JAPAN'            TO WS-COUNTRY
               WHEN 'K'
                   MOVE 'SOUTH KOREA'      TO WS-COUNTRY
               WHEN 'L'
                   MOVE 'CHINA'            TO WS-COUNTRY
               WHEN 'S'
                   MOVE 'UNITED KINGDOM'   TO WS-COUNTRY
               WHEN 'V'
                   MOVE 'FRANCE'           TO WS-COUNTRY
               WHEN 'W'
                   MOVE 'GERMANY'          TO WS-COUNTRY
               WHEN 'Z'
                   MOVE 'ITALY'            TO WS-COUNTRY
               WHEN '9'
                   MOVE 'BRAZIL'           TO WS-COUNTRY
               WHEN OTHER
                   MOVE 'OTHER/UNKNOWN'    TO WS-COUNTRY
           END-EVALUATE
      *
      *    DECODE MANUFACTURER (POSITIONS 1-3 WMI)
      *
           EVALUATE WS-VIN-WMI
      *        GENERAL MOTORS
               WHEN '1G1'
                   MOVE 'CHEVROLET (USA)'   TO WS-MANUFACTURER
               WHEN '1G2'
                   MOVE 'PONTIAC (USA)'     TO WS-MANUFACTURER
               WHEN '1GC'
                   MOVE 'CHEVROLET TRUCK'   TO WS-MANUFACTURER
               WHEN '1GT'
                   MOVE 'GMC TRUCK (USA)'   TO WS-MANUFACTURER
               WHEN '1GY'
                   MOVE 'CADILLAC (USA)'    TO WS-MANUFACTURER
               WHEN '2G1'
                   MOVE 'CHEVROLET (CAN)'   TO WS-MANUFACTURER
               WHEN '3G1'
                   MOVE 'CHEVROLET (MEX)'   TO WS-MANUFACTURER
      *        FORD
               WHEN '1FA'
                   MOVE 'FORD CAR (USA)'    TO WS-MANUFACTURER
               WHEN '1FB' WHEN '1FC' WHEN '1FD'
                   MOVE 'FORD TRUCK (USA)'  TO WS-MANUFACTURER
               WHEN '1FM'
                   MOVE 'FORD SUV (USA)'    TO WS-MANUFACTURER
               WHEN '1FT'
                   MOVE 'FORD TRUCK (USA)'  TO WS-MANUFACTURER
               WHEN '2FA'
                   MOVE 'FORD (CANADA)'     TO WS-MANUFACTURER
               WHEN '3FA'
                   MOVE 'FORD (MEXICO)'     TO WS-MANUFACTURER
      *        CHRYSLER / STELLANTIS
               WHEN '1C3'
                   MOVE 'CHRYSLER (USA)'    TO WS-MANUFACTURER
               WHEN '1C4'
                   MOVE 'CHRYSLER/JEEP'     TO WS-MANUFACTURER
               WHEN '1C6'
                   MOVE 'RAM TRUCK (USA)'   TO WS-MANUFACTURER
               WHEN '2C3'
                   MOVE 'CHRYSLER (CAN)'    TO WS-MANUFACTURER
               WHEN '3C4'
                   MOVE 'CHRYSLER (MEX)'    TO WS-MANUFACTURER
      *        TOYOTA
               WHEN 'JTD'
                   MOVE 'TOYOTA (JAPAN)'    TO WS-MANUFACTURER
               WHEN 'JTE'
                   MOVE 'TOYOTA SUV (JPN)'  TO WS-MANUFACTURER
               WHEN 'JTN'
                   MOVE 'TOYOTA (JAPAN)'    TO WS-MANUFACTURER
               WHEN '4T1'
                   MOVE 'TOYOTA (USA)'      TO WS-MANUFACTURER
               WHEN '5TD'
                   MOVE 'TOYOTA TRUCK(USA)' TO WS-MANUFACTURER
               WHEN '2T1'
                   MOVE 'TOYOTA (CAN)'      TO WS-MANUFACTURER
      *        HONDA
               WHEN 'JHM'
                   MOVE 'HONDA (JAPAN)'     TO WS-MANUFACTURER
               WHEN '1HG'
                   MOVE 'HONDA CAR (USA)'   TO WS-MANUFACTURER
               WHEN '5FN'
                   MOVE 'HONDA SUV (USA)'   TO WS-MANUFACTURER
               WHEN '2HG'
                   MOVE 'HONDA (CANADA)'    TO WS-MANUFACTURER
      *        NISSAN
               WHEN 'JN1'
                   MOVE 'NISSAN (JAPAN)'    TO WS-MANUFACTURER
               WHEN '1N4'
                   MOVE 'NISSAN CAR (USA)'  TO WS-MANUFACTURER
               WHEN '1N6'
                   MOVE 'NISSAN TRUCK(USA)' TO WS-MANUFACTURER
               WHEN '5N1'
                   MOVE 'NISSAN SUV (USA)'  TO WS-MANUFACTURER
      *        BMW
               WHEN 'WBA'
                   MOVE 'BMW CAR (GER)'     TO WS-MANUFACTURER
               WHEN 'WBS'
                   MOVE 'BMW M SERIES'      TO WS-MANUFACTURER
               WHEN 'WBY'
                   MOVE 'BMW EV (GER)'      TO WS-MANUFACTURER
               WHEN '5UX'
                   MOVE 'BMW SUV (USA)'     TO WS-MANUFACTURER
      *        MERCEDES-BENZ
               WHEN 'WDB'
                   MOVE 'MERCEDES-BENZ'     TO WS-MANUFACTURER
               WHEN 'WDC'
                   MOVE 'MERCEDES SUV'      TO WS-MANUFACTURER
               WHEN 'WDD'
                   MOVE 'MERCEDES-BENZ'     TO WS-MANUFACTURER
               WHEN '4JG'
                   MOVE 'MERCEDES SUV(USA)' TO WS-MANUFACTURER
      *        HYUNDAI / KIA
               WHEN 'KMH'
                   MOVE 'HYUNDAI (KOREA)'   TO WS-MANUFACTURER
               WHEN '5NP'
                   MOVE 'HYUNDAI (USA)'     TO WS-MANUFACTURER
               WHEN 'KNA'
                   MOVE 'KIA (KOREA)'       TO WS-MANUFACTURER
               WHEN '5XY'
                   MOVE 'KIA (USA)'         TO WS-MANUFACTURER
      *        TESLA
               WHEN '5YJ'
                   MOVE 'TESLA (USA)'       TO WS-MANUFACTURER
               WHEN '7SA'
                   MOVE 'TESLA (USA)'       TO WS-MANUFACTURER
      *        SUBARU
               WHEN 'JF1' WHEN 'JF2'
                   MOVE 'SUBARU (JAPAN)'    TO WS-MANUFACTURER
               WHEN '4S3' WHEN '4S4'
                   MOVE 'SUBARU (USA)'      TO WS-MANUFACTURER
      *        VOLKSWAGEN
               WHEN 'WVW'
                   MOVE 'VOLKSWAGEN (GER)'  TO WS-MANUFACTURER
               WHEN '3VW'
                   MOVE 'VOLKSWAGEN (MEX)'  TO WS-MANUFACTURER
      *
               WHEN OTHER
                   STRING 'UNKNOWN (WMI='
                          WS-VIN-WMI
                          ')'
                          DELIMITED BY SIZE
                          INTO WS-MANUFACTURER
           END-EVALUATE
      *
           MOVE WS-COUNTRY      TO LS-VD-COUNTRY
           MOVE WS-MANUFACTURER TO LS-VD-MANUFACTURER
           .
      *
      ****************************************************************
      *    6000-DECODE-YEAR - MODEL YEAR FROM POSITION 10            *
      *    LETTER CODES CYCLE: A=2010..H=2017, J=2018, K=2019,     *
      *    L=2020, M=2021, N=2022, P=2023, R=2024, S=2025,         *
      *    V=2026, W=2027, X=2028, Y=2029, 1=2031..9=2039          *
      ****************************************************************
       6000-DECODE-YEAR.
      *
           EVALUATE WS-VIN-YEAR-CODE
               WHEN 'A'    MOVE 2010 TO WS-MODEL-YEAR
               WHEN 'B'    MOVE 2011 TO WS-MODEL-YEAR
               WHEN 'C'    MOVE 2012 TO WS-MODEL-YEAR
               WHEN 'D'    MOVE 2013 TO WS-MODEL-YEAR
               WHEN 'E'    MOVE 2014 TO WS-MODEL-YEAR
               WHEN 'F'    MOVE 2015 TO WS-MODEL-YEAR
               WHEN 'G'    MOVE 2016 TO WS-MODEL-YEAR
               WHEN 'H'    MOVE 2017 TO WS-MODEL-YEAR
               WHEN 'J'    MOVE 2018 TO WS-MODEL-YEAR
               WHEN 'K'    MOVE 2019 TO WS-MODEL-YEAR
               WHEN 'L'    MOVE 2020 TO WS-MODEL-YEAR
               WHEN 'M'    MOVE 2021 TO WS-MODEL-YEAR
               WHEN 'N'    MOVE 2022 TO WS-MODEL-YEAR
               WHEN 'P'    MOVE 2023 TO WS-MODEL-YEAR
               WHEN 'R'    MOVE 2024 TO WS-MODEL-YEAR
               WHEN 'S'    MOVE 2025 TO WS-MODEL-YEAR
               WHEN 'T'    MOVE 2026 TO WS-MODEL-YEAR
               WHEN 'V'    MOVE 2027 TO WS-MODEL-YEAR
               WHEN 'W'    MOVE 2028 TO WS-MODEL-YEAR
               WHEN 'X'    MOVE 2029 TO WS-MODEL-YEAR
               WHEN 'Y'    MOVE 2030 TO WS-MODEL-YEAR
               WHEN '1'    MOVE 2031 TO WS-MODEL-YEAR
               WHEN '2'    MOVE 2032 TO WS-MODEL-YEAR
               WHEN '3'    MOVE 2033 TO WS-MODEL-YEAR
               WHEN '4'    MOVE 2034 TO WS-MODEL-YEAR
               WHEN '5'    MOVE 2035 TO WS-MODEL-YEAR
               WHEN '6'    MOVE 2036 TO WS-MODEL-YEAR
               WHEN '7'    MOVE 2037 TO WS-MODEL-YEAR
               WHEN '8'    MOVE 2038 TO WS-MODEL-YEAR
               WHEN '9'    MOVE 2039 TO WS-MODEL-YEAR
               WHEN OTHER  MOVE 0    TO WS-MODEL-YEAR
           END-EVALUATE
      *
           MOVE WS-MODEL-YEAR TO LS-VD-MODEL-YEAR
           .
      *
      ****************************************************************
      *    7000-DECODE-PLANT - ASSEMBLY PLANT FROM POSITION 11       *
      *    PLANT CODES ARE MANUFACTURER-SPECIFIC. BELOW ARE          *
      *    COMMON GM/FORD PLANT CODES FOR ILLUSTRATION.              *
      ****************************************************************
       7000-DECODE-PLANT.
      *
      *    GM PLANTS (IF GM MANUFACTURER)
      *
           IF WS-VIN-WMI(1:2) = '1G'
            OR WS-VIN-WMI(1:2) = '2G'
            OR WS-VIN-WMI(1:2) = '3G'
               EVALUATE WS-VIN-PLANT-CODE
                   WHEN '1'
                       MOVE 'WENTZVILLE, MO'   TO WS-ASSEMBLY-PLANT
                   WHEN '2'
                       MOVE 'ST. CATHARINES,ON' TO WS-ASSEMBLY-PLANT
                   WHEN '4'
                       MOVE 'ORION, MI'         TO WS-ASSEMBLY-PLANT
                   WHEN 'A'
                       MOVE 'INGERSOLL, ON'     TO WS-ASSEMBLY-PLANT
                   WHEN 'B'
                       MOVE 'BOWLING GREEN, KY' TO WS-ASSEMBLY-PLANT
                   WHEN 'C'
                       MOVE 'LORDSTOWN, OH'     TO WS-ASSEMBLY-PLANT
                   WHEN 'F'
                       MOVE 'FLINT, MI'         TO WS-ASSEMBLY-PLANT
                   WHEN 'G'
                       MOVE 'SILAO, MEXICO'     TO WS-ASSEMBLY-PLANT
                   WHEN 'K'
                       MOVE 'FAIRFAX, KS'       TO WS-ASSEMBLY-PLANT
                   WHEN 'L'
                       MOVE 'LANSING, MI'       TO WS-ASSEMBLY-PLANT
                   WHEN 'R'
                       MOVE 'ARLINGTON, TX'     TO WS-ASSEMBLY-PLANT
                   WHEN 'S'
                       MOVE 'RAMOS ARIZPE, MX'  TO WS-ASSEMBLY-PLANT
                   WHEN 'T'
                       MOVE 'SPRING HILL, TN'   TO WS-ASSEMBLY-PLANT
                   WHEN 'U'
                       MOVE 'HAMTRAMCK, MI'     TO WS-ASSEMBLY-PLANT
                   WHEN OTHER
                       STRING 'GM PLANT CODE ' WS-VIN-PLANT-CODE
                              DELIMITED BY SIZE
                              INTO WS-ASSEMBLY-PLANT
               END-EVALUATE
      *
      *    FORD PLANTS
      *
           ELSE IF WS-VIN-WMI(1:2) = '1F'
            OR WS-VIN-WMI(1:2) = '2F'
            OR WS-VIN-WMI(1:2) = '3F'
               EVALUATE WS-VIN-PLANT-CODE
                   WHEN 'A'
                       MOVE 'ATLANTA, GA'       TO WS-ASSEMBLY-PLANT
                   WHEN 'B'
                       MOVE 'OAKVILLE, ON'      TO WS-ASSEMBLY-PLANT
                   WHEN 'C'
                       MOVE 'OHIO ASSEMBLY'     TO WS-ASSEMBLY-PLANT
                   WHEN 'D'
                       MOVE 'DEARBORN, MI'      TO WS-ASSEMBLY-PLANT
                   WHEN 'E'
                       MOVE 'LORAIN, OH'        TO WS-ASSEMBLY-PLANT
                   WHEN 'F'
                       MOVE 'FLAT ROCK, MI'     TO WS-ASSEMBLY-PLANT
                   WHEN 'K'
                       MOVE 'KANSAS CITY, MO'   TO WS-ASSEMBLY-PLANT
                   WHEN 'L'
                       MOVE 'MICHIGAN ASSEMBLY' TO WS-ASSEMBLY-PLANT
                   WHEN 'P'
                       MOVE 'ST. PAUL, MN'      TO WS-ASSEMBLY-PLANT
                   WHEN 'R'
                       MOVE 'HERMOSILLO, MX'    TO WS-ASSEMBLY-PLANT
                   WHEN 'T'
                       MOVE 'EDISON, NJ'        TO WS-ASSEMBLY-PLANT
                   WHEN 'X'
                       MOVE 'CLAYCOMO, MO'      TO WS-ASSEMBLY-PLANT
                   WHEN OTHER
                       STRING 'FORD PLANT CODE ' WS-VIN-PLANT-CODE
                              DELIMITED BY SIZE
                              INTO WS-ASSEMBLY-PLANT
               END-EVALUATE
      *
      *    TOYOTA PLANTS
      *
           ELSE IF WS-VIN-WMI(1:1) = 'J'
            OR WS-VIN-WMI(1:2) = '4T'
            OR WS-VIN-WMI(1:2) = '5T'
            OR WS-VIN-WMI(1:2) = '2T'
               EVALUATE WS-VIN-PLANT-CODE
                   WHEN 'A'
                       MOVE 'AICHI, JAPAN'      TO WS-ASSEMBLY-PLANT
                   WHEN 'B'
                       MOVE 'GEORGETOWN, KY'    TO WS-ASSEMBLY-PLANT
                   WHEN 'C'
                       MOVE 'CAMBRIDGE, ON'     TO WS-ASSEMBLY-PLANT
                   WHEN 'D'
                       MOVE 'TOYOTA, JAPAN'     TO WS-ASSEMBLY-PLANT
                   WHEN 'K'
                       MOVE 'TAHARA, JAPAN'     TO WS-ASSEMBLY-PLANT
                   WHEN 'U'
                       MOVE 'PRINCETON, IN'     TO WS-ASSEMBLY-PLANT
                   WHEN OTHER
                       STRING 'TOYOTA PLANT ' WS-VIN-PLANT-CODE
                              DELIMITED BY SIZE
                              INTO WS-ASSEMBLY-PLANT
               END-EVALUATE
      *
           ELSE
      *        GENERIC - JUST REPORT THE CODE
               STRING 'PLANT CODE: ' WS-VIN-PLANT-CODE
                      DELIMITED BY SIZE
                      INTO WS-ASSEMBLY-PLANT
           END-IF
           END-IF
           END-IF
      *
           MOVE WS-ASSEMBLY-PLANT TO LS-VD-ASSEMBLY-PLANT
           .
      *
      ****************************************************************
      *    8000-DECODE-ATTRIBUTES - POSITIONS 4-8 (VDS)              *
      *    BODY TYPE, ENGINE, RESTRAINT SYSTEM                       *
      *    (MANUFACTURER-SPECIFIC, USING GENERIC EXAMPLES)           *
      ****************************************************************
       8000-DECODE-ATTRIBUTES.
      *
      *    POSITION 4: RESTRAINT SYSTEM (GENERIC)
      *
           EVALUATE WS-VIN-VDS(1:1)
               WHEN '1' WHEN 'A'
                   MOVE 'MANUAL BELTS'      TO WS-RESTRAINT
               WHEN '2' WHEN 'B'
                   MOVE 'FRONT AIRBAGS'     TO WS-RESTRAINT
               WHEN '3' WHEN 'C'
                   MOVE 'FRONT+SIDE AIRBAGS'TO WS-RESTRAINT
               WHEN '4' WHEN 'D'
                   MOVE 'FRONT+SIDE+CURTAIN'TO WS-RESTRAINT
               WHEN OTHER
                   MOVE 'STANDARD AIRBAGS'  TO WS-RESTRAINT
           END-EVALUATE
      *
      *    POSITION 5: BODY TYPE (GENERIC)
      *
           EVALUATE WS-VIN-VDS(2:1)
               WHEN '1'
                   MOVE 'SEDAN 2-DOOR'      TO WS-BODY-TYPE
               WHEN '2'
                   MOVE 'SEDAN 4-DOOR'      TO WS-BODY-TYPE
               WHEN '3'
                   MOVE 'CONVERTIBLE'       TO WS-BODY-TYPE
               WHEN '4'
                   MOVE 'WAGON/HATCHBACK'   TO WS-BODY-TYPE
               WHEN '5'
                   MOVE 'SUV/CROSSOVER'     TO WS-BODY-TYPE
               WHEN '6'
                   MOVE 'PICKUP TRUCK'      TO WS-BODY-TYPE
               WHEN '7'
                   MOVE 'VAN/MINIVAN'       TO WS-BODY-TYPE
               WHEN '8'
                   MOVE 'COUPE'             TO WS-BODY-TYPE
               WHEN OTHER
                   MOVE 'UNKNOWN BODY TYPE' TO WS-BODY-TYPE
           END-EVALUATE
      *
      *    POSITION 8: ENGINE (GENERIC DECODE)
      *
           EVALUATE WS-VIN-VDS(5:1)
               WHEN '1' WHEN 'A'
                   MOVE '4-CYL GASOLINE'    TO WS-ENGINE-TYPE
               WHEN '2' WHEN 'B'
                   MOVE '4-CYL TURBO'       TO WS-ENGINE-TYPE
               WHEN '3' WHEN 'C'
                   MOVE 'V6 GASOLINE'       TO WS-ENGINE-TYPE
               WHEN '4' WHEN 'D'
                   MOVE 'V6 TURBO'          TO WS-ENGINE-TYPE
               WHEN '5' WHEN 'E'
                   MOVE 'V8 GASOLINE'       TO WS-ENGINE-TYPE
               WHEN '6' WHEN 'F'
                   MOVE 'V8 SUPERCHARGED'   TO WS-ENGINE-TYPE
               WHEN '7' WHEN 'G'
                   MOVE 'HYBRID'            TO WS-ENGINE-TYPE
               WHEN '8' WHEN 'H'
                   MOVE 'PLUG-IN HYBRID'    TO WS-ENGINE-TYPE
               WHEN '9' WHEN 'J'
                   MOVE 'ELECTRIC (BEV)'    TO WS-ENGINE-TYPE
               WHEN 'K'
                   MOVE 'DIESEL'            TO WS-ENGINE-TYPE
               WHEN OTHER
                   MOVE 'UNKNOWN ENGINE'    TO WS-ENGINE-TYPE
           END-EVALUATE
      *
           MOVE WS-BODY-TYPE    TO LS-VD-BODY-TYPE
           MOVE WS-ENGINE-TYPE  TO LS-VD-ENGINE-TYPE
           MOVE WS-RESTRAINT    TO LS-VD-RESTRAINT
           .
      *
      ****************************************************************
      *    9000-SET-RESULTS - FINALIZE RETURN STATUS                 *
      ****************************************************************
       9000-SET-RESULTS.
      *
           IF WS-CHECK-VALID = 'Y'
               MOVE 'Y' TO LS-VD-VALID-FLAG
               MOVE +0  TO LS-VD-RETURN-CODE
               MOVE 'COMVINL0: VIN DECODED SUCCESSFULLY'
                   TO LS-VD-RETURN-MSG
           ELSE
      *        CHECK DIGIT FAILED BUT DECODE STILL RETURNED
               MOVE 'N' TO LS-VD-VALID-FLAG
               IF LS-VD-RETURN-CODE = +0
                   MOVE +4 TO LS-VD-RETURN-CODE
               END-IF
               MOVE 'COMVINL0: VIN DECODED - CHECK DIGIT INVALID'
                   TO LS-VD-RETURN-MSG
           END-IF
           .
      ****************************************************************
      * END OF COMVINL0                                               *
      ****************************************************************
