       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMVALD0.
      ****************************************************************
      * PROGRAM:   COMVALD0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   VIN (VEHICLE IDENTIFICATION NUMBER) VALIDATION    *
      *            MODULE. VALIDATES 17-CHARACTER VIN PER NHTSA      *
      *            STANDARDS INCLUDING CHECK DIGIT CALCULATION.       *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMVALD0' USING LK-VIN-INPUT                        *
      *                         LK-VIN-RETURN-CODE                   *
      *                         LK-VIN-ERROR-MSG                     *
      *                         LK-VIN-DECODED                       *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - VIN IS VALID                                          *
      *   04 - INVALID FORMAT (LENGTH, ILLEGAL CHARS)                *
      *   08 - BAD CHECK DIGIT                                       *
      *   12 - INVALID POSITION DATA (WMI, YEAR CODE)               *
      *                                                              *
      * CHANGE LOG:                                                  *
      *   2026-03-29  INITIAL CREATION                               *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMVALD0'.
      *
      *    VIN POSITION WEIGHTS FOR CHECK DIGIT ALGORITHM
      *    POSITIONS 1-17: 8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2
      *
       01  WS-VIN-WEIGHTS.
           05  FILLER              PIC 9(02) VALUE 08.
           05  FILLER              PIC 9(02) VALUE 07.
           05  FILLER              PIC 9(02) VALUE 06.
           05  FILLER              PIC 9(02) VALUE 05.
           05  FILLER              PIC 9(02) VALUE 04.
           05  FILLER              PIC 9(02) VALUE 03.
           05  FILLER              PIC 9(02) VALUE 02.
           05  FILLER              PIC 9(02) VALUE 10.
           05  FILLER              PIC 9(02) VALUE 00.
           05  FILLER              PIC 9(02) VALUE 09.
           05  FILLER              PIC 9(02) VALUE 08.
           05  FILLER              PIC 9(02) VALUE 07.
           05  FILLER              PIC 9(02) VALUE 06.
           05  FILLER              PIC 9(02) VALUE 05.
           05  FILLER              PIC 9(02) VALUE 04.
           05  FILLER              PIC 9(02) VALUE 03.
           05  FILLER              PIC 9(02) VALUE 02.
       01  WS-VIN-WEIGHT-TABLE REDEFINES WS-VIN-WEIGHTS.
           05  WS-WEIGHT-ENTRY     PIC 9(02)
                                   OCCURS 17 TIMES.
      *
      *    TRANSLITERATION TABLE: A-Z MAPPED TO NUMERIC VALUES
      *    A=1, B=2, C=3, D=4, E=5, F=6, G=7, H=8
      *    J=1, K=2, L=3, M=4, N=5, P=7, R=9
      *    S=2, T=3, U=4, V=5, W=6, X=7, Y=8, Z=9
      *    I, O, Q ARE INVALID IN VIN
      *
       01  WS-TRANSLIT-TABLE.
           05  WS-TRANSLIT-ALPHA  PIC X(26)
               VALUE 'ABCDEFGHJKLMNPRSTVWXYZ    '.
           05  WS-TRANSLIT-VALUE  PIC X(26)
               VALUE '12345678123457923456789    '.
      *
      *    VALID MODEL YEAR CODES (POSITION 10)
      *    A=2010, B=2011, ... H=2017, J=2018, K=2019
      *    L=2020, M=2021, N=2022, P=2023, R=2024
      *    S=2025, T=2026, V=2027, W=2028, X=2029, Y=2030
      *    1=2001, 2=2002, ... 9=2009
      *
       01  WS-VALID-YEAR-CODES    PIC X(30)
           VALUE 'ABCDEFGHJKLMNPRSTUVWXY12345679'.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-VIN-POS          PIC 9(02) VALUE 0.
           05  WS-VIN-CHAR        PIC X(01) VALUE SPACES.
           05  WS-CHAR-VALUE      PIC 9(02) VALUE 0.
           05  WS-WEIGHTED-SUM    PIC 9(06) VALUE 0.
           05  WS-PRODUCT         PIC 9(04) VALUE 0.
           05  WS-REMAINDER       PIC 9(02) VALUE 0.
           05  WS-EXPECTED-CHECK  PIC X(01) VALUE SPACES.
           05  WS-ACTUAL-CHECK    PIC X(01) VALUE SPACES.
           05  WS-SEARCH-IDX      PIC 9(02) VALUE 0.
           05  WS-FOUND-FLAG      PIC X(01) VALUE 'N'.
               88  WS-CHAR-FOUND           VALUE 'Y'.
               88  WS-CHAR-NOT-FOUND       VALUE 'N'.
           05  WS-VIN-LENGTH      PIC 9(02) VALUE 0.
           05  WS-QUOTIENT        PIC 9(04) VALUE 0.
           05  WS-YEAR-OFFSET     PIC 9(02) VALUE 0.
      *
      *    VIN BROKEN INTO INDIVIDUAL CHARACTERS
      *
       01  WS-VIN-CHARS.
           05  WS-VC              PIC X(01)
                                  OCCURS 17 TIMES.
      *
       LINKAGE SECTION.
      *
       01  LK-VIN-INPUT            PIC X(17).
      *
       01  LK-VIN-RETURN-CODE      PIC S9(04) COMP.
      *
       01  LK-VIN-ERROR-MSG        PIC X(50).
      *
       01  LK-VIN-DECODED.
           05  LK-VIN-WMI         PIC X(03).
           05  LK-VIN-VDS         PIC X(05).
           05  LK-VIN-CHECK-DIGIT PIC X(01).
           05  LK-VIN-VIS         PIC X(08).
           05  LK-VIN-YEAR-CODE   PIC X(01).
           05  LK-VIN-PLANT-CODE  PIC X(01).
           05  LK-VIN-SEQ-NUM     PIC X(06).
           05  LK-VIN-MANUFACTURER PIC X(30).
           05  LK-VIN-MODEL-YEAR  PIC 9(04).
           05  LK-VIN-ASSEMBLY    PIC X(30).
      *
       PROCEDURE DIVISION USING LK-VIN-INPUT
                                LK-VIN-RETURN-CODE
                                LK-VIN-ERROR-MSG
                                LK-VIN-DECODED.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-VIN-RETURN-CODE
           MOVE SPACES TO LK-VIN-ERROR-MSG
           INITIALIZE LK-VIN-DECODED
      *
           PERFORM 1000-VALIDATE-LENGTH
           IF LK-VIN-RETURN-CODE = ZEROS
               PERFORM 2000-VALIDATE-CHARACTERS
           END-IF
      *
           IF LK-VIN-RETURN-CODE = ZEROS
               PERFORM 3000-VALIDATE-WMI
           END-IF
      *
           IF LK-VIN-RETURN-CODE = ZEROS
               PERFORM 4000-VALIDATE-CHECK-DIGIT
           END-IF
      *
           IF LK-VIN-RETURN-CODE = ZEROS
               PERFORM 5000-VALIDATE-YEAR-CODE
           END-IF
      *
           IF LK-VIN-RETURN-CODE = ZEROS
               PERFORM 6000-DECODE-VIN
           END-IF
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - VALIDATE VIN LENGTH IS EXACTLY 17 CHARACTERS           *
      *---------------------------------------------------------------*
       1000-VALIDATE-LENGTH.
      *
           IF LK-VIN-INPUT = SPACES OR LOW-VALUES
               MOVE +4 TO LK-VIN-RETURN-CODE
               MOVE 'VIN IS BLANK OR MISSING'
                   TO LK-VIN-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
           MOVE ZERO TO WS-VIN-LENGTH
           INSPECT LK-VIN-INPUT TALLYING WS-VIN-LENGTH
               FOR CHARACTERS BEFORE INITIAL SPACE
      *
           IF WS-VIN-LENGTH NOT = 17
               MOVE +4 TO LK-VIN-RETURN-CODE
               STRING 'VIN LENGTH MUST BE 17, GOT '
                      WS-VIN-LENGTH
                      DELIMITED BY SIZE
                   INTO LK-VIN-ERROR-MSG
           ELSE
               MOVE LK-VIN-INPUT TO WS-VIN-CHARS
           END-IF
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - VALIDATE VIN CONTAINS ONLY LEGAL CHARACTERS            *
      *        VIN CANNOT CONTAIN I, O, OR Q                           *
      *        MUST BE A-Z (EXCEPT I,O,Q) OR 0-9                      *
      *---------------------------------------------------------------*
       2000-VALIDATE-CHARACTERS.
      *
           PERFORM VARYING WS-VIN-POS FROM 1 BY 1
               UNTIL WS-VIN-POS > 17
               OR LK-VIN-RETURN-CODE NOT = ZEROS
      *
               MOVE WS-VC(WS-VIN-POS) TO WS-VIN-CHAR
      *
      *        CHECK FOR ILLEGAL CHARACTERS I, O, Q
      *
               IF WS-VIN-CHAR = 'I' OR 'O' OR 'Q'
                   MOVE +4 TO LK-VIN-RETURN-CODE
                   STRING 'ILLEGAL CHAR '
                          WS-VIN-CHAR
                          ' AT POSITION '
                          WS-VIN-POS
                          DELIMITED BY SIZE
                       INTO LK-VIN-ERROR-MSG
               END-IF
      *
      *        CHECK FOR VALID ALPHANUMERIC
      *
               IF LK-VIN-RETURN-CODE = ZEROS
                   IF (WS-VIN-CHAR >= 'A' AND <= 'Z')
                   OR (WS-VIN-CHAR >= '0' AND <= '9')
                       CONTINUE
                   ELSE
                       MOVE +4 TO LK-VIN-RETURN-CODE
                       STRING 'INVALID CHAR '
                              WS-VIN-CHAR
                              ' AT POSITION '
                              WS-VIN-POS
                              DELIMITED BY SIZE
                           INTO LK-VIN-ERROR-MSG
                   END-IF
               END-IF
      *
           END-PERFORM
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - VALIDATE WMI (WORLD MANUFACTURER IDENTIFIER)           *
      *        POSITIONS 1-3 IDENTIFY THE MANUFACTURER                 *
      *        POSITION 1 = COUNTRY OF ORIGIN                          *
      *        POSITION 3 = VEHICLE TYPE (IF WMI POS 3 = '9' THEN     *
      *        POSITIONS 12-14 ALSO IDENTIFY MANUFACTURER)             *
      *---------------------------------------------------------------*
       3000-VALIDATE-WMI.
      *
      *    POSITION 1 MUST BE A VALID REGION CODE
      *    1-5 = NORTH AMERICA, A-H = AFRICA, J-R = ASIA
      *    S-Z = EUROPE, 6-7 = OCEANIA, 8-9 = SOUTH AMERICA
      *
           MOVE WS-VC(1) TO WS-VIN-CHAR
      *
           EVALUATE TRUE
               WHEN WS-VIN-CHAR >= '1' AND <= '5'
                   CONTINUE
               WHEN WS-VIN-CHAR >= 'A' AND <= 'H'
                   CONTINUE
               WHEN WS-VIN-CHAR >= 'J' AND <= 'R'
                   CONTINUE
               WHEN WS-VIN-CHAR >= 'S' AND <= 'Z'
                   CONTINUE
               WHEN WS-VIN-CHAR >= '6' AND <= '7'
                   CONTINUE
               WHEN WS-VIN-CHAR >= '8' AND <= '9'
                   CONTINUE
               WHEN OTHER
                   MOVE +12 TO LK-VIN-RETURN-CODE
                   STRING 'INVALID WMI REGION CODE: '
                          WS-VIN-CHAR
                          DELIMITED BY SIZE
                       INTO LK-VIN-ERROR-MSG
           END-EVALUATE
      *
      *    POSITION 2 MUST BE ALPHANUMERIC (ALREADY CHECKED)
      *    BUT VERIFY WMI IS NOT ALL ZEROS
      *
           IF LK-VIN-RETURN-CODE = ZEROS
               IF WS-VC(1) = '0' AND
                  WS-VC(2) = '0' AND
                  WS-VC(3) = '0'
                   MOVE +12 TO LK-VIN-RETURN-CODE
                   MOVE 'WMI CANNOT BE ALL ZEROS'
                       TO LK-VIN-ERROR-MSG
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - VALIDATE CHECK DIGIT (POSITION 9)                      *
      *        USES NHTSA CHECK DIGIT ALGORITHM:                       *
      *        1. TRANSLITERATE ALPHA CHARS TO NUMERIC VALUES          *
      *        2. MULTIPLY EACH POSITION BY ITS WEIGHT                 *
      *        3. SUM ALL PRODUCTS                                     *
      *        4. DIVIDE BY 11, REMAINDER IS CHECK DIGIT               *
      *        5. IF REMAINDER = 10, CHECK DIGIT IS 'X'                *
      *---------------------------------------------------------------*
       4000-VALIDATE-CHECK-DIGIT.
      *
           MOVE ZERO TO WS-WEIGHTED-SUM
      *
           PERFORM VARYING WS-VIN-POS FROM 1 BY 1
               UNTIL WS-VIN-POS > 17
      *
               MOVE WS-VC(WS-VIN-POS) TO WS-VIN-CHAR
      *
      *        TRANSLITERATE CHARACTER TO NUMERIC VALUE
      *
               PERFORM 4100-TRANSLITERATE-CHAR
      *
      *        MULTIPLY BY POSITION WEIGHT AND ACCUMULATE
      *
               MULTIPLY WS-CHAR-VALUE BY
                   WS-WEIGHT-ENTRY(WS-VIN-POS)
                   GIVING WS-PRODUCT
               ADD WS-PRODUCT TO WS-WEIGHTED-SUM
      *
           END-PERFORM
      *
      *    CALCULATE REMAINDER (MOD 11)
      *
           DIVIDE WS-WEIGHTED-SUM BY 11
               GIVING WS-QUOTIENT
               REMAINDER WS-REMAINDER
      *
      *    DETERMINE EXPECTED CHECK DIGIT
      *
           IF WS-REMAINDER = 10
               MOVE 'X' TO WS-EXPECTED-CHECK
           ELSE
               MOVE WS-REMAINDER TO WS-EXPECTED-CHECK
      *        CONVERT NUMERIC REMAINDER TO CHARACTER
               EVALUATE WS-REMAINDER
                   WHEN 0  MOVE '0' TO WS-EXPECTED-CHECK
                   WHEN 1  MOVE '1' TO WS-EXPECTED-CHECK
                   WHEN 2  MOVE '2' TO WS-EXPECTED-CHECK
                   WHEN 3  MOVE '3' TO WS-EXPECTED-CHECK
                   WHEN 4  MOVE '4' TO WS-EXPECTED-CHECK
                   WHEN 5  MOVE '5' TO WS-EXPECTED-CHECK
                   WHEN 6  MOVE '6' TO WS-EXPECTED-CHECK
                   WHEN 7  MOVE '7' TO WS-EXPECTED-CHECK
                   WHEN 8  MOVE '8' TO WS-EXPECTED-CHECK
                   WHEN 9  MOVE '9' TO WS-EXPECTED-CHECK
               END-EVALUATE
           END-IF
      *
      *    COMPARE WITH ACTUAL CHECK DIGIT AT POSITION 9
      *
           MOVE WS-VC(9) TO WS-ACTUAL-CHECK
      *
           IF WS-ACTUAL-CHECK NOT = WS-EXPECTED-CHECK
               MOVE +8 TO LK-VIN-RETURN-CODE
               STRING 'CHECK DIGIT MISMATCH: GOT '
                      WS-ACTUAL-CHECK
                      ' EXPECTED '
                      WS-EXPECTED-CHECK
                      DELIMITED BY SIZE
                   INTO LK-VIN-ERROR-MSG
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4100 - TRANSLITERATE A SINGLE VIN CHARACTER TO ITS NUMERIC    *
      *        VALUE. DIGITS MAP TO THEMSELVES, LETTERS MAP PER       *
      *        NHTSA TRANSLITERATION TABLE.                            *
      *---------------------------------------------------------------*
       4100-TRANSLITERATE-CHAR.
      *
           IF WS-VIN-CHAR >= '0' AND <= '9'
      *        NUMERIC: VALUE IS THE DIGIT ITSELF
               EVALUATE WS-VIN-CHAR
                   WHEN '0'  MOVE 0  TO WS-CHAR-VALUE
                   WHEN '1'  MOVE 1  TO WS-CHAR-VALUE
                   WHEN '2'  MOVE 2  TO WS-CHAR-VALUE
                   WHEN '3'  MOVE 3  TO WS-CHAR-VALUE
                   WHEN '4'  MOVE 4  TO WS-CHAR-VALUE
                   WHEN '5'  MOVE 5  TO WS-CHAR-VALUE
                   WHEN '6'  MOVE 6  TO WS-CHAR-VALUE
                   WHEN '7'  MOVE 7  TO WS-CHAR-VALUE
                   WHEN '8'  MOVE 8  TO WS-CHAR-VALUE
                   WHEN '9'  MOVE 9  TO WS-CHAR-VALUE
               END-EVALUATE
           ELSE
      *        ALPHA: LOOK UP IN TRANSLITERATION TABLE
               EVALUATE WS-VIN-CHAR
                   WHEN 'A'  MOVE 1  TO WS-CHAR-VALUE
                   WHEN 'B'  MOVE 2  TO WS-CHAR-VALUE
                   WHEN 'C'  MOVE 3  TO WS-CHAR-VALUE
                   WHEN 'D'  MOVE 4  TO WS-CHAR-VALUE
                   WHEN 'E'  MOVE 5  TO WS-CHAR-VALUE
                   WHEN 'F'  MOVE 6  TO WS-CHAR-VALUE
                   WHEN 'G'  MOVE 7  TO WS-CHAR-VALUE
                   WHEN 'H'  MOVE 8  TO WS-CHAR-VALUE
                   WHEN 'J'  MOVE 1  TO WS-CHAR-VALUE
                   WHEN 'K'  MOVE 2  TO WS-CHAR-VALUE
                   WHEN 'L'  MOVE 3  TO WS-CHAR-VALUE
                   WHEN 'M'  MOVE 4  TO WS-CHAR-VALUE
                   WHEN 'N'  MOVE 5  TO WS-CHAR-VALUE
                   WHEN 'P'  MOVE 7  TO WS-CHAR-VALUE
                   WHEN 'R'  MOVE 9  TO WS-CHAR-VALUE
                   WHEN 'S'  MOVE 2  TO WS-CHAR-VALUE
                   WHEN 'T'  MOVE 3  TO WS-CHAR-VALUE
                   WHEN 'U'  MOVE 4  TO WS-CHAR-VALUE
                   WHEN 'V'  MOVE 5  TO WS-CHAR-VALUE
                   WHEN 'W'  MOVE 6  TO WS-CHAR-VALUE
                   WHEN 'X'  MOVE 7  TO WS-CHAR-VALUE
                   WHEN 'Y'  MOVE 8  TO WS-CHAR-VALUE
                   WHEN 'Z'  MOVE 9  TO WS-CHAR-VALUE
                   WHEN OTHER MOVE 0 TO WS-CHAR-VALUE
               END-EVALUATE
           END-IF
           .
       4100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - VALIDATE MODEL YEAR CODE (POSITION 10)                 *
      *        DECODES YEAR CODE TO 4-DIGIT YEAR                       *
      *---------------------------------------------------------------*
       5000-VALIDATE-YEAR-CODE.
      *
           MOVE WS-VC(10) TO WS-VIN-CHAR
      *
           MOVE 'N' TO WS-FOUND-FLAG
           INSPECT WS-VALID-YEAR-CODES TALLYING WS-YEAR-OFFSET
               FOR CHARACTERS BEFORE INITIAL WS-VIN-CHAR
      *
      *    DECODE MODEL YEAR FROM POSITION 10
      *
           EVALUATE WS-VIN-CHAR
               WHEN '1'  MOVE 2001 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '2'  MOVE 2002 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '3'  MOVE 2003 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '4'  MOVE 2004 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '5'  MOVE 2005 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '6'  MOVE 2006 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '7'  MOVE 2007 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '8'  MOVE 2008 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN '9'  MOVE 2009 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'A'  MOVE 2010 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'B'  MOVE 2011 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'C'  MOVE 2012 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'D'  MOVE 2013 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'E'  MOVE 2014 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'F'  MOVE 2015 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'G'  MOVE 2016 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'H'  MOVE 2017 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'J'  MOVE 2018 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'K'  MOVE 2019 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'L'  MOVE 2020 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'M'  MOVE 2021 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'N'  MOVE 2022 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'P'  MOVE 2023 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'R'  MOVE 2024 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'S'  MOVE 2025 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'T'  MOVE 2026 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'V'  MOVE 2027 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'W'  MOVE 2028 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'X'  MOVE 2029 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN 'Y'  MOVE 2030 TO LK-VIN-MODEL-YEAR
                          MOVE 'Y'  TO WS-FOUND-FLAG
               WHEN OTHER
                   MOVE +12 TO LK-VIN-RETURN-CODE
                   STRING 'INVALID MODEL YEAR CODE: '
                          WS-VIN-CHAR
                          DELIMITED BY SIZE
                       INTO LK-VIN-ERROR-MSG
           END-EVALUATE
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - DECODE VIN INTO COMPONENT PARTS                        *
      *        WMI (1-3), VDS (4-8), CHECK (9), VIS (10-17)           *
      *---------------------------------------------------------------*
       6000-DECODE-VIN.
      *
      *    WORLD MANUFACTURER IDENTIFIER (POSITIONS 1-3)
      *
           MOVE WS-VC(1) TO LK-VIN-WMI(1:1)
           MOVE WS-VC(2) TO LK-VIN-WMI(2:1)
           MOVE WS-VC(3) TO LK-VIN-WMI(3:1)
      *
      *    VEHICLE DESCRIPTOR SECTION (POSITIONS 4-8)
      *
           MOVE WS-VC(4) TO LK-VIN-VDS(1:1)
           MOVE WS-VC(5) TO LK-VIN-VDS(2:1)
           MOVE WS-VC(6) TO LK-VIN-VDS(3:1)
           MOVE WS-VC(7) TO LK-VIN-VDS(4:1)
           MOVE WS-VC(8) TO LK-VIN-VDS(5:1)
      *
      *    CHECK DIGIT (POSITION 9)
      *
           MOVE WS-VC(9) TO LK-VIN-CHECK-DIGIT
      *
      *    VEHICLE IDENTIFIER SECTION (POSITIONS 10-17)
      *
           STRING WS-VC(10) WS-VC(11) WS-VC(12) WS-VC(13)
                  WS-VC(14) WS-VC(15) WS-VC(16) WS-VC(17)
               DELIMITED BY SIZE INTO LK-VIN-VIS
      *
      *    YEAR CODE (POSITION 10) - ALREADY DECODED IN 5000
      *
           MOVE WS-VC(10) TO LK-VIN-YEAR-CODE
      *
      *    ASSEMBLY PLANT (POSITION 11)
      *
           MOVE WS-VC(11) TO LK-VIN-PLANT-CODE
      *
      *    SEQUENTIAL NUMBER (POSITIONS 12-17)
      *
           STRING WS-VC(12) WS-VC(13) WS-VC(14)
                  WS-VC(15) WS-VC(16) WS-VC(17)
               DELIMITED BY SIZE INTO LK-VIN-SEQ-NUM
      *
      *    DECODE MANUFACTURER FROM WMI
      *
           PERFORM 6100-DECODE-MANUFACTURER
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6100 - DECODE MANUFACTURER NAME FROM WMI CODE                 *
      *        COMMON US/JAPAN/GERMAN MANUFACTURER CODES               *
      *---------------------------------------------------------------*
       6100-DECODE-MANUFACTURER.
      *
           EVALUATE LK-VIN-WMI(1:2)
               WHEN '1G'
                   MOVE 'GENERAL MOTORS USA'
                       TO LK-VIN-MANUFACTURER
               WHEN '1F'
                   MOVE 'FORD MOTOR COMPANY'
                       TO LK-VIN-MANUFACTURER
               WHEN '1C'
                   MOVE 'CHRYSLER / STELLANTIS'
                       TO LK-VIN-MANUFACTURER
               WHEN '2T'
                   MOVE 'TOYOTA CANADA'
                       TO LK-VIN-MANUFACTURER
               WHEN '3G'
                   MOVE 'GENERAL MOTORS MEXICO'
                       TO LK-VIN-MANUFACTURER
               WHEN '4T'
                   MOVE 'TOYOTA USA'
                       TO LK-VIN-MANUFACTURER
               WHEN '5T'
                   MOVE 'HYUNDAI / KIA USA'
                       TO LK-VIN-MANUFACTURER
               WHEN 'JT'
                   MOVE 'TOYOTA JAPAN'
                       TO LK-VIN-MANUFACTURER
               WHEN 'JH'
                   MOVE 'HONDA JAPAN'
                       TO LK-VIN-MANUFACTURER
               WHEN 'JN'
                   MOVE 'NISSAN JAPAN'
                       TO LK-VIN-MANUFACTURER
               WHEN 'WA'
                   MOVE 'AUDI GERMANY'
                       TO LK-VIN-MANUFACTURER
               WHEN 'WB'
                   MOVE 'BMW GERMANY'
                       TO LK-VIN-MANUFACTURER
               WHEN 'WD'
                   MOVE 'MERCEDES-BENZ GERMANY'
                       TO LK-VIN-MANUFACTURER
               WHEN 'WV'
                   MOVE 'VOLKSWAGEN GERMANY'
                       TO LK-VIN-MANUFACTURER
               WHEN 'WP'
                   MOVE 'PORSCHE GERMANY'
                       TO LK-VIN-MANUFACTURER
               WHEN OTHER
                   MOVE 'UNKNOWN MANUFACTURER'
                       TO LK-VIN-MANUFACTURER
           END-EVALUATE
           .
       6100-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMVALD0                                              *
      ****************************************************************
