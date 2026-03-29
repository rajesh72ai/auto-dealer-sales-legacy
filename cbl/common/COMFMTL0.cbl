       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMFMTL0.
      ****************************************************************
      * PROGRAM:   COMFMTL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   FIELD FORMATTING MODULE. PROVIDES CONSISTENT      *
      *            FORMATTING OF CURRENCY, PHONE NUMBERS, SSN,       *
      *            VIN, PERCENTAGES, RATES AND NAMES FOR DISPLAY.    *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMFMTL0' USING LK-FMT-FUNCTION                     *
      *                         LK-FMT-INPUT                         *
      *                         LK-FMT-OUTPUT                        *
      *                         LK-FMT-RETURN-CODE                   *
      *                         LK-FMT-ERROR-MSG                     *
      *                                                              *
      * FUNCTIONS:                                                   *
      *   CURR - FORMAT CURRENCY ($999,999.99)                       *
      *   PHON - FORMAT PHONE (999-999-9999)                         *
      *   SSNM - MASK SSN (XXX-XX-1234)                              *
      *   VINF - FORMAT VIN WITH SPACES (WMI VDS CHK VIS)            *
      *   PCTF - FORMAT PERCENTAGE (99.99%)                          *
      *   RATF - FORMAT RATE (9.9999)                                *
      *   NAME - FORMAT NAME PROPER CASE                             *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - SUCCESS                                               *
      *   04 - INVALID INPUT                                         *
      *   08 - INVALID FUNCTION CODE                                 *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMFMTL0'.
      *
      *    CURRENCY FORMATTING WORK FIELDS
      *
       01  WS-CURR-WORK.
           05  WS-CURR-INPUT-NUM   PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-CURR-NEGATIVE    PIC X(01) VALUE 'N'.
               88  WS-CURR-IS-NEG          VALUE 'Y'.
               88  WS-CURR-IS-POS          VALUE 'N'.
           05  WS-CURR-ABS-AMT    PIC S9(09)V99 COMP-3 VALUE 0.
           05  WS-CURR-EDITED     PIC $$$,$$$,$$9.99.
           05  WS-CURR-NEG-EDIT   PIC -$$$,$$$,$$9.99.
           05  WS-CURR-OUTPUT     PIC X(20) VALUE SPACES.
      *
      *    PHONE FORMATTING WORK FIELDS
      *
       01  WS-PHONE-WORK.
           05  WS-PHONE-DIGITS    PIC X(10) VALUE SPACES.
           05  WS-PHONE-DIGIT-R REDEFINES WS-PHONE-DIGITS.
               10  WS-PH-AREA     PIC X(03).
               10  WS-PH-EXCH     PIC X(03).
               10  WS-PH-LINE     PIC X(04).
           05  WS-PHONE-CLEAN     PIC X(10) VALUE SPACES.
           05  WS-PHONE-IDX       PIC 9(02) VALUE 0.
           05  WS-PHONE-OUT-IDX   PIC 9(02) VALUE 0.
           05  WS-PHONE-CHAR      PIC X(01) VALUE SPACES.
      *
      *    SSN FORMATTING WORK FIELDS
      *
       01  WS-SSN-WORK.
           05  WS-SSN-DIGITS      PIC X(09) VALUE SPACES.
           05  WS-SSN-DIGIT-R REDEFINES WS-SSN-DIGITS.
               10  WS-SSN-AREA    PIC X(03).
               10  WS-SSN-GRP     PIC X(02).
               10  WS-SSN-SER     PIC X(04).
           05  WS-SSN-CLEAN       PIC X(09) VALUE SPACES.
           05  WS-SSN-IDX         PIC 9(02) VALUE 0.
           05  WS-SSN-OUT-IDX     PIC 9(02) VALUE 0.
           05  WS-SSN-CHAR        PIC X(01) VALUE SPACES.
      *
      *    VIN FORMATTING WORK FIELDS
      *
       01  WS-VIN-WORK.
           05  WS-VIN-INPUT-W     PIC X(17) VALUE SPACES.
           05  WS-VIN-INPUT-R REDEFINES WS-VIN-INPUT-W.
               10  WS-VIN-W-WMI   PIC X(03).
               10  WS-VIN-W-VDS   PIC X(05).
               10  WS-VIN-W-CHK   PIC X(01).
               10  WS-VIN-W-VIS   PIC X(08).
      *
      *    PERCENTAGE FORMATTING WORK FIELDS
      *
       01  WS-PCT-WORK.
           05  WS-PCT-INPUT-NUM   PIC S9(03)V99 COMP-3 VALUE 0.
           05  WS-PCT-EDITED      PIC ZZ9.99.
      *
      *    RATE FORMATTING WORK FIELDS
      *
       01  WS-RATE-WORK.
           05  WS-RATE-INPUT-NUM  PIC S9(02)V9(04) COMP-3 VALUE 0.
           05  WS-RATE-EDITED     PIC Z9.9999.
      *
      *    NAME FORMATTING WORK FIELDS
      *
       01  WS-NAME-WORK.
           05  WS-NAME-INPUT-W    PIC X(40) VALUE SPACES.
           05  WS-NAME-OUTPUT-W   PIC X(40) VALUE SPACES.
           05  WS-NAME-IDX        PIC 9(02) VALUE 0.
           05  WS-NAME-CHAR       PIC X(01) VALUE SPACES.
           05  WS-NAME-PREV-CHAR  PIC X(01) VALUE SPACES.
           05  WS-NAME-AFTER-SEP  PIC X(01) VALUE 'Y'.
               88  WS-AFTER-SEPARATOR      VALUE 'Y'.
               88  WS-IN-WORD              VALUE 'N'.
           05  WS-NAME-LENGTH     PIC 9(02) VALUE 0.
      *
       LINKAGE SECTION.
      *
       01  LK-FMT-FUNCTION        PIC X(04).
      *
       01  LK-FMT-INPUT.
           05  LK-FMT-INPUT-ALPHA PIC X(40).
           05  LK-FMT-INPUT-NUM   PIC S9(09)V99 COMP-3.
           05  LK-FMT-INPUT-RATE  PIC S9(02)V9(04) COMP-3.
           05  LK-FMT-INPUT-PCT   PIC S9(03)V99 COMP-3.
      *
       01  LK-FMT-OUTPUT          PIC X(40).
      *
       01  LK-FMT-RETURN-CODE     PIC S9(04) COMP.
      *
       01  LK-FMT-ERROR-MSG       PIC X(50).
      *
       PROCEDURE DIVISION USING LK-FMT-FUNCTION
                                LK-FMT-INPUT
                                LK-FMT-OUTPUT
                                LK-FMT-RETURN-CODE
                                LK-FMT-ERROR-MSG.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-FMT-RETURN-CODE
           MOVE SPACES TO LK-FMT-ERROR-MSG
           MOVE SPACES TO LK-FMT-OUTPUT
      *
           EVALUATE LK-FMT-FUNCTION
               WHEN 'CURR'
                   PERFORM 1000-FORMAT-CURRENCY
               WHEN 'PHON'
                   PERFORM 2000-FORMAT-PHONE
               WHEN 'SSNM'
                   PERFORM 3000-MASK-SSN
               WHEN 'VINF'
                   PERFORM 4000-FORMAT-VIN
               WHEN 'PCTF'
                   PERFORM 5000-FORMAT-PERCENTAGE
               WHEN 'RATF'
                   PERFORM 6000-FORMAT-RATE
               WHEN 'NAME'
                   PERFORM 7000-FORMAT-NAME
               WHEN OTHER
                   MOVE +8 TO LK-FMT-RETURN-CODE
                   STRING 'INVALID FORMAT FUNCTION: '
                          LK-FMT-FUNCTION
                          DELIMITED BY SIZE
                       INTO LK-FMT-ERROR-MSG
           END-EVALUATE
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - FORMAT CURRENCY WITH DOLLAR SIGN AND COMMAS             *
      *        INPUT: LK-FMT-INPUT-NUM (S9(09)V99 COMP-3)             *
      *        OUTPUT: $999,999,999.99 OR ($999,999,999.99)            *
      *---------------------------------------------------------------*
       1000-FORMAT-CURRENCY.
      *
           MOVE LK-FMT-INPUT-NUM TO WS-CURR-INPUT-NUM
      *
           IF WS-CURR-INPUT-NUM < 0
               MOVE 'Y' TO WS-CURR-NEGATIVE
               MULTIPLY -1 BY WS-CURR-INPUT-NUM
                   GIVING WS-CURR-ABS-AMT
           ELSE
               MOVE 'N' TO WS-CURR-NEGATIVE
               MOVE WS-CURR-INPUT-NUM TO WS-CURR-ABS-AMT
           END-IF
      *
           IF WS-CURR-IS-NEG
               MOVE WS-CURR-INPUT-NUM TO WS-CURR-NEG-EDIT
               MOVE WS-CURR-NEG-EDIT  TO WS-CURR-OUTPUT
           ELSE
               MOVE WS-CURR-ABS-AMT TO WS-CURR-EDITED
               MOVE WS-CURR-EDITED  TO WS-CURR-OUTPUT
           END-IF
      *
      *    LEFT-JUSTIFY THE RESULT
      *
           MOVE SPACES TO LK-FMT-OUTPUT
           MOVE WS-CURR-OUTPUT TO LK-FMT-OUTPUT
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - FORMAT PHONE NUMBER AS 999-999-9999                     *
      *        INPUT: LK-FMT-INPUT-ALPHA (10 DIGIT STRING)            *
      *        STRIPS NON-DIGIT CHARACTERS FIRST                       *
      *---------------------------------------------------------------*
       2000-FORMAT-PHONE.
      *
      *    EXTRACT ONLY DIGITS FROM INPUT
      *
           MOVE SPACES TO WS-PHONE-CLEAN
           MOVE 0 TO WS-PHONE-OUT-IDX
      *
           PERFORM VARYING WS-PHONE-IDX FROM 1 BY 1
               UNTIL WS-PHONE-IDX > 40
               OR WS-PHONE-OUT-IDX >= 10
      *
               MOVE LK-FMT-INPUT-ALPHA(WS-PHONE-IDX:1)
                   TO WS-PHONE-CHAR
      *
               IF WS-PHONE-CHAR >= '0' AND <= '9'
                   ADD 1 TO WS-PHONE-OUT-IDX
                   MOVE WS-PHONE-CHAR
                       TO WS-PHONE-CLEAN(WS-PHONE-OUT-IDX:1)
               END-IF
           END-PERFORM
      *
      *    VALIDATE WE HAVE 10 DIGITS
      *
           IF WS-PHONE-OUT-IDX NOT = 10
               MOVE +4 TO LK-FMT-RETURN-CODE
               MOVE 'PHONE NUMBER MUST HAVE 10 DIGITS'
                   TO LK-FMT-ERROR-MSG
               GO TO 2000-EXIT
           END-IF
      *
      *    FORMAT AS 999-999-9999
      *
           MOVE WS-PHONE-CLEAN TO WS-PHONE-DIGITS
           STRING WS-PH-AREA '-'
                  WS-PH-EXCH '-'
                  WS-PH-LINE
               DELIMITED BY SIZE
               INTO LK-FMT-OUTPUT
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - MASK SSN: SHOW ONLY LAST 4 DIGITS                      *
      *        INPUT: LK-FMT-INPUT-ALPHA (9 DIGIT SSN)                *
      *        OUTPUT: XXX-XX-1234                                     *
      *---------------------------------------------------------------*
       3000-MASK-SSN.
      *
      *    EXTRACT ONLY DIGITS FROM INPUT
      *
           MOVE SPACES TO WS-SSN-CLEAN
           MOVE 0 TO WS-SSN-OUT-IDX
      *
           PERFORM VARYING WS-SSN-IDX FROM 1 BY 1
               UNTIL WS-SSN-IDX > 40
               OR WS-SSN-OUT-IDX >= 9
      *
               MOVE LK-FMT-INPUT-ALPHA(WS-SSN-IDX:1)
                   TO WS-SSN-CHAR
      *
               IF WS-SSN-CHAR >= '0' AND <= '9'
                   ADD 1 TO WS-SSN-OUT-IDX
                   MOVE WS-SSN-CHAR
                       TO WS-SSN-CLEAN(WS-SSN-OUT-IDX:1)
               END-IF
           END-PERFORM
      *
           IF WS-SSN-OUT-IDX NOT = 9
               MOVE +4 TO LK-FMT-RETURN-CODE
               MOVE 'SSN MUST HAVE 9 DIGITS'
                   TO LK-FMT-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
      *    VALIDATE SSN RANGES (NOT ALL ZEROS IN ANY GROUP)
      *
           MOVE WS-SSN-CLEAN TO WS-SSN-DIGITS
           IF WS-SSN-AREA = '000' OR
              WS-SSN-GRP  = '00'  OR
              WS-SSN-SER  = '0000'
               MOVE +4 TO LK-FMT-RETURN-CODE
               MOVE 'SSN CONTAINS INVALID ZERO GROUP'
                   TO LK-FMT-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
      *    ALSO REJECT KNOWN INVALID SSNS
      *
           IF WS-SSN-AREA = '666' OR
              WS-SSN-AREA >= '900'
               MOVE +4 TO LK-FMT-RETURN-CODE
               MOVE 'SSN AREA NUMBER IS INVALID'
                   TO LK-FMT-ERROR-MSG
               GO TO 3000-EXIT
           END-IF
      *
      *    MASK FIRST 5 DIGITS, KEEP LAST 4
      *
           STRING 'XXX-XX-'
                  WS-SSN-SER
               DELIMITED BY SIZE
               INTO LK-FMT-OUTPUT
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - FORMAT VIN WITH SPACES BETWEEN SECTIONS                 *
      *        INPUT: LK-FMT-INPUT-ALPHA (17 CHAR VIN)                *
      *        OUTPUT: WMI VDS CHK VIS (WMI VDS C YYSSSSSS)           *
      *---------------------------------------------------------------*
       4000-FORMAT-VIN.
      *
           MOVE LK-FMT-INPUT-ALPHA(1:17) TO WS-VIN-INPUT-W
      *
      *    VALIDATE NOT BLANK
      *
           IF WS-VIN-INPUT-W = SPACES
               MOVE +4 TO LK-FMT-RETURN-CODE
               MOVE 'VIN IS BLANK'
                   TO LK-FMT-ERROR-MSG
               GO TO 4000-EXIT
           END-IF
      *
      *    FORMAT: WMI-VDS-C-YYSSSSSS
      *    (3 DASH 5 DASH 1 DASH 8 = 20 CHARS WITH DASHES)
      *
           STRING WS-VIN-W-WMI '-'
                  WS-VIN-W-VDS '-'
                  WS-VIN-W-CHK '-'
                  WS-VIN-W-VIS
               DELIMITED BY SIZE
               INTO LK-FMT-OUTPUT
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - FORMAT PERCENTAGE WITH PERCENT SIGN                     *
      *        INPUT: LK-FMT-INPUT-PCT (S9(03)V99 COMP-3)             *
      *        OUTPUT: ZZ9.99%                                         *
      *---------------------------------------------------------------*
       5000-FORMAT-PERCENTAGE.
      *
           MOVE LK-FMT-INPUT-PCT TO WS-PCT-INPUT-NUM
           MOVE WS-PCT-INPUT-NUM TO WS-PCT-EDITED
      *
           STRING WS-PCT-EDITED '%'
               DELIMITED BY SIZE
               INTO LK-FMT-OUTPUT
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - FORMAT RATE WITH 4 DECIMAL PLACES                      *
      *        INPUT: LK-FMT-INPUT-RATE (S9(02)V9(04) COMP-3)        *
      *        OUTPUT: Z9.9999                                         *
      *---------------------------------------------------------------*
       6000-FORMAT-RATE.
      *
           MOVE LK-FMT-INPUT-RATE TO WS-RATE-INPUT-NUM
           MOVE WS-RATE-INPUT-NUM TO WS-RATE-EDITED
           MOVE WS-RATE-EDITED TO LK-FMT-OUTPUT
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7000 - FORMAT NAME IN PROPER CASE (FIRST LETTER UPPERCASE,    *
      *        REST LOWERCASE). HANDLES SPACES, HYPHENS, APOSTROPHES. *
      *        INPUT: LK-FMT-INPUT-ALPHA (UP TO 40 CHARS)             *
      *        OUTPUT: PROPERLY CASED NAME                             *
      *---------------------------------------------------------------*
       7000-FORMAT-NAME.
      *
           MOVE LK-FMT-INPUT-ALPHA TO WS-NAME-INPUT-W
           MOVE SPACES TO WS-NAME-OUTPUT-W
           MOVE 'Y' TO WS-NAME-AFTER-SEP
      *
      *    DETERMINE ACTUAL LENGTH
      *
           MOVE 40 TO WS-NAME-LENGTH
           INSPECT FUNCTION REVERSE(WS-NAME-INPUT-W)
               TALLYING WS-NAME-LENGTH
               FOR LEADING SPACES
           COMPUTE WS-NAME-LENGTH = 40 - WS-NAME-LENGTH
      *
           IF WS-NAME-LENGTH = 0
               MOVE +4 TO LK-FMT-RETURN-CODE
               MOVE 'NAME IS BLANK'
                   TO LK-FMT-ERROR-MSG
               GO TO 7000-EXIT
           END-IF
      *
           PERFORM VARYING WS-NAME-IDX FROM 1 BY 1
               UNTIL WS-NAME-IDX > WS-NAME-LENGTH
      *
               MOVE WS-NAME-INPUT-W(WS-NAME-IDX:1)
                   TO WS-NAME-CHAR
      *
      *        CHECK FOR WORD SEPARATOR
      *
               IF WS-NAME-CHAR = SPACE OR '-' OR ''''
                   MOVE WS-NAME-CHAR
                       TO WS-NAME-OUTPUT-W(WS-NAME-IDX:1)
                   MOVE 'Y' TO WS-NAME-AFTER-SEP
               ELSE
      *
      *            CAPITALIZE FIRST LETTER OF EACH WORD
      *
                   IF WS-AFTER-SEPARATOR
                       PERFORM 7100-TO-UPPER
                       MOVE 'N' TO WS-NAME-AFTER-SEP
                   ELSE
                       PERFORM 7200-TO-LOWER
                   END-IF
      *
                   MOVE WS-NAME-CHAR
                       TO WS-NAME-OUTPUT-W(WS-NAME-IDX:1)
               END-IF
      *
           END-PERFORM
      *
      *    HANDLE SPECIAL CASES: MC, MAC, O'
      *
           PERFORM 7300-HANDLE-SPECIAL-PREFIXES
      *
           MOVE WS-NAME-OUTPUT-W TO LK-FMT-OUTPUT
           .
       7000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7100 - CONVERT WS-NAME-CHAR TO UPPERCASE                      *
      *---------------------------------------------------------------*
       7100-TO-UPPER.
      *
           INSPECT WS-NAME-CHAR
               CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                       TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
           .
       7100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7200 - CONVERT WS-NAME-CHAR TO LOWERCASE                      *
      *---------------------------------------------------------------*
       7200-TO-LOWER.
      *
           INSPECT WS-NAME-CHAR
               CONVERTING 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                       TO 'abcdefghijklmnopqrstuvwxyz'
           .
       7200-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7300 - HANDLE SPECIAL NAME PREFIXES                            *
      *        MC -> CAPITALIZE NEXT LETTER (MCDONALD -> MCDONALD)     *
      *        MAC -> CAPITALIZE NEXT LETTER (MACDONALD)               *
      *---------------------------------------------------------------*
       7300-HANDLE-SPECIAL-PREFIXES.
      *
      *    CHECK FOR MC PREFIX (E.G., MCDONALD -> MCDONALD)
      *
           IF WS-NAME-OUTPUT-W(1:2) = 'Mc' AND
              WS-NAME-LENGTH > 2
               MOVE WS-NAME-OUTPUT-W(3:1) TO WS-NAME-CHAR
               PERFORM 7100-TO-UPPER
               MOVE WS-NAME-CHAR
                   TO WS-NAME-OUTPUT-W(3:1)
           END-IF
      *
      *    CHECK FOR MAC PREFIX (E.G., MACDONALD)
      *    BUT NOT SHORT NAMES LIKE MACK OR MACE
      *
           IF WS-NAME-OUTPUT-W(1:3) = 'Mac' AND
              WS-NAME-LENGTH > 4
               MOVE WS-NAME-OUTPUT-W(4:1) TO WS-NAME-CHAR
               PERFORM 7100-TO-UPPER
               MOVE WS-NAME-CHAR
                   TO WS-NAME-OUTPUT-W(4:1)
           END-IF
      *
      *    SCAN FOR MC AFTER SPACE OR HYPHEN
      *
           PERFORM VARYING WS-NAME-IDX FROM 2 BY 1
               UNTIL WS-NAME-IDX > WS-NAME-LENGTH - 2
               IF (WS-NAME-OUTPUT-W(WS-NAME-IDX - 1:1)
                   = SPACE OR '-')
                  AND
                  WS-NAME-OUTPUT-W(WS-NAME-IDX:2) = 'Mc'
                   ADD 2 TO WS-NAME-IDX
                   IF WS-NAME-IDX <= WS-NAME-LENGTH
                       MOVE WS-NAME-OUTPUT-W(
                           WS-NAME-IDX:1)
                           TO WS-NAME-CHAR
                       PERFORM 7100-TO-UPPER
                       MOVE WS-NAME-CHAR
                           TO WS-NAME-OUTPUT-W(
                               WS-NAME-IDX:1)
                   END-IF
                   SUBTRACT 2 FROM WS-NAME-IDX
               END-IF
           END-PERFORM
           .
       7300-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMFMTL0                                              *
      ****************************************************************
