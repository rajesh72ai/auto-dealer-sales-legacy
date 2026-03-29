       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMDTEL0.
      ****************************************************************
      * PROGRAM:   COMDTEL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   DATE/TIME UTILITY MODULE. PROVIDES COMMON DATE    *
      *            FUNCTIONS USED ACROSS ALL AUTOSALES PROGRAMS.      *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMDTEL0' USING LK-DTU-FUNCTION                     *
      *                         LK-DTU-INPUT-AREA                    *
      *                         LK-DTU-OUTPUT-AREA                   *
      *                         LK-DTU-RETURN-CODE                   *
      *                         LK-DTU-ERROR-MSG                     *
      *                                                              *
      * FUNCTIONS:                                                   *
      *   JULG - JULIAN TO GREGORIAN CONVERSION                      *
      *   GJUL - GREGORIAN TO JULIAN CONVERSION                      *
      *   DAYS - CALCULATE DAYS BETWEEN TWO DATES                    *
      *   BDAY - ADD BUSINESS DAYS TO A DATE                         *
      *   AGED - CALCULATE AGE/DAYS FROM A DATE TO TODAY             *
      *   CURR - GET CURRENT DATE/TIME/TIMESTAMP                     *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - SUCCESS                                               *
      *   04 - INVALID DATE                                          *
      *   08 - INVALID FUNCTION CODE                                 *
      *   12 - CALCULATION ERROR                                     *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMDTEL0'.
      *
      *    INTRINSIC FUNCTION DATE FIELDS
      *
       01  WS-CURRENT-DATE-DATA.
           05  WS-CURR-YYYY        PIC 9(04).
           05  WS-CURR-MM          PIC 9(02).
           05  WS-CURR-DD          PIC 9(02).
           05  WS-CURR-HH          PIC 9(02).
           05  WS-CURR-MN          PIC 9(02).
           05  WS-CURR-SS          PIC 9(02).
           05  WS-CURR-HS          PIC 9(02).
           05  WS-CURR-GMT-SIGN    PIC X(01).
           05  WS-CURR-GMT-HH      PIC 9(02).
           05  WS-CURR-GMT-MN      PIC 9(02).
      *
      *    DAYS-IN-MONTH TABLE
      *
       01  WS-DAYS-IN-MONTH-TBL.
           05  FILLER              PIC 9(02) VALUE 31.
           05  FILLER              PIC 9(02) VALUE 28.
           05  FILLER              PIC 9(02) VALUE 31.
           05  FILLER              PIC 9(02) VALUE 30.
           05  FILLER              PIC 9(02) VALUE 31.
           05  FILLER              PIC 9(02) VALUE 30.
           05  FILLER              PIC 9(02) VALUE 31.
           05  FILLER              PIC 9(02) VALUE 31.
           05  FILLER              PIC 9(02) VALUE 30.
           05  FILLER              PIC 9(02) VALUE 31.
           05  FILLER              PIC 9(02) VALUE 30.
           05  FILLER              PIC 9(02) VALUE 31.
       01  WS-DAYS-MONTH-REDEF REDEFINES WS-DAYS-IN-MONTH-TBL.
           05  WS-MONTH-DAYS      PIC 9(02)
                                   OCCURS 12 TIMES.
      *
      *    WORK FIELDS FOR DATE CALCULATIONS
      *
       01  WS-DATE-WORK-FIELDS.
           05  WS-WORK-YYYY        PIC 9(04) VALUE 0.
           05  WS-WORK-MM          PIC 9(02) VALUE 0.
           05  WS-WORK-DD          PIC 9(02) VALUE 0.
           05  WS-WORK-CCYYMMDD    PIC 9(08) VALUE 0.
           05  WS-WORK-JULIAN.
               10  WS-JUL-YYYY    PIC 9(04) VALUE 0.
               10  WS-JUL-DDD     PIC 9(03) VALUE 0.
           05  WS-WORK-JULIAN-N REDEFINES WS-WORK-JULIAN
                                   PIC 9(07).
           05  WS-LEAP-YEAR-FLAG   PIC X(01) VALUE 'N'.
               88  WS-IS-LEAP-YEAR         VALUE 'Y'.
               88  WS-NOT-LEAP-YEAR        VALUE 'N'.
           05  WS-WORK-DAYS        PIC S9(09) COMP VALUE 0.
           05  WS-DAY-ACCUM        PIC 9(03) VALUE 0.
           05  WS-MONTH-IDX        PIC 9(02) VALUE 0.
           05  WS-MAX-DAYS         PIC 9(02) VALUE 0.
           05  WS-BDAY-COUNT       PIC S9(07) COMP-3 VALUE 0.
           05  WS-BDAY-DIR         PIC S9(01) VALUE +1.
           05  WS-DOW              PIC 9(01) VALUE 0.
      *
      *    INTEGER DATE WORK FIELDS (FOR DAYS-BETWEEN)
      *
       01  WS-INT-DATE-FIELDS.
           05  WS-INT-DATE-1       PIC 9(09) VALUE 0.
           05  WS-INT-DATE-2       PIC 9(09) VALUE 0.
           05  WS-GREG-DATE-1.
               10  WS-GD1-YYYY    PIC 9(04).
               10  WS-GD1-MM      PIC 9(02).
               10  WS-GD1-DD      PIC 9(02).
           05  WS-GREG-DATE-2.
               10  WS-GD2-YYYY    PIC 9(04).
               10  WS-GD2-MM      PIC 9(02).
               10  WS-GD2-DD      PIC 9(02).
      *
      *    WORK AREAS FOR GREGORIAN PARSING
      *
       01  WS-PARSE-AREA.
           05  WS-PARSE-CCYYMMDD.
               10  WS-PARSE-YYYY  PIC 9(04).
               10  WS-PARSE-MM    PIC 9(02).
               10  WS-PARSE-DD    PIC 9(02).
           05  WS-PARSE-CCYYMMDD-X REDEFINES WS-PARSE-CCYYMMDD
                                   PIC X(08).
           05  WS-PARSE-DASH1     PIC X(10).
      *
       01  WS-REMAINDER-4         PIC 9(04) VALUE 0.
       01  WS-REMAINDER-100       PIC 9(04) VALUE 0.
       01  WS-REMAINDER-400       PIC 9(04) VALUE 0.
       01  WS-QUOTIENT-WORK       PIC 9(09) VALUE 0.
      *
       LINKAGE SECTION.
      *
       01  LK-DTU-FUNCTION         PIC X(04).
      *
       01  LK-DTU-INPUT-AREA.
           05  LK-DTU-INPUT-DATE-1 PIC X(10).
           05  LK-DTU-INPUT-DATE-2 PIC X(10).
           05  LK-DTU-INPUT-JULIAN PIC 9(07).
           05  LK-DTU-INPUT-DAYS  PIC S9(07) COMP-3.
           05  LK-DTU-INPUT-FORMAT PIC X(04).
      *
       01  LK-DTU-OUTPUT-AREA.
           05  LK-DTU-OUT-GREG    PIC X(10).
           05  LK-DTU-OUT-CCYYMMDD PIC X(08).
           05  LK-DTU-OUT-MMDDYYYY PIC X(10).
           05  LK-DTU-OUT-JULIAN  PIC 9(07).
           05  LK-DTU-OUT-DAYS    PIC S9(07) COMP-3.
           05  LK-DTU-OUT-DOW     PIC 9(01).
           05  LK-DTU-OUT-DOW-NAME PIC X(09).
           05  LK-DTU-OUT-TIMESTAMP PIC X(26).
           05  LK-DTU-OUT-TIME    PIC X(08).
           05  LK-DTU-OUT-YEARS   PIC 9(03).
           05  LK-DTU-OUT-MONTHS  PIC 9(02).
           05  LK-DTU-OUT-REMDAYS PIC 9(02).
      *
       01  LK-DTU-RETURN-CODE     PIC S9(04) COMP.
      *
       01  LK-DTU-ERROR-MSG       PIC X(50).
      *
       PROCEDURE DIVISION USING LK-DTU-FUNCTION
                                LK-DTU-INPUT-AREA
                                LK-DTU-OUTPUT-AREA
                                LK-DTU-RETURN-CODE
                                LK-DTU-ERROR-MSG.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-DTU-RETURN-CODE
           MOVE SPACES TO LK-DTU-ERROR-MSG
      *
           EVALUATE LK-DTU-FUNCTION
               WHEN 'JULG'
                   PERFORM 1000-JULIAN-TO-GREGORIAN
               WHEN 'GJUL'
                   PERFORM 2000-GREGORIAN-TO-JULIAN
               WHEN 'DAYS'
                   PERFORM 3000-DAYS-BETWEEN
               WHEN 'BDAY'
                   PERFORM 4000-ADD-BUSINESS-DAYS
               WHEN 'AGED'
                   PERFORM 5000-CALCULATE-AGE
               WHEN 'CURR'
                   PERFORM 6000-GET-CURRENT-DATETIME
               WHEN OTHER
                   MOVE +8 TO LK-DTU-RETURN-CODE
                   STRING 'INVALID FUNCTION CODE: '
                          LK-DTU-FUNCTION
                          DELIMITED BY SIZE
                       INTO LK-DTU-ERROR-MSG
           END-EVALUATE
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - CONVERT JULIAN DATE (YYYYDDD) TO GREGORIAN              *
      *        INPUT: LK-DTU-INPUT-JULIAN (9(07))                      *
      *        OUTPUT: LK-DTU-OUT-GREG (YYYY-MM-DD)                    *
      *---------------------------------------------------------------*
       1000-JULIAN-TO-GREGORIAN.
      *
           MOVE LK-DTU-INPUT-JULIAN TO WS-WORK-JULIAN-N
           MOVE WS-JUL-YYYY TO WS-WORK-YYYY
           MOVE WS-JUL-DDD  TO WS-DAY-ACCUM
      *
      *    VALIDATE YEAR
      *
           IF WS-WORK-YYYY < 1900 OR > 2099
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'JULIAN YEAR OUT OF RANGE (1900-2099)'
                   TO LK-DTU-ERROR-MSG
               GO TO 1000-EXIT
           END-IF
      *
      *    CHECK LEAP YEAR
      *
           PERFORM 8000-CHECK-LEAP-YEAR
      *
      *    VALIDATE DAY-OF-YEAR
      *
           IF WS-IS-LEAP-YEAR
               IF WS-DAY-ACCUM < 1 OR > 366
                   MOVE +4 TO LK-DTU-RETURN-CODE
                   MOVE 'JULIAN DAY OUT OF RANGE FOR LEAP YEAR'
                       TO LK-DTU-ERROR-MSG
                   GO TO 1000-EXIT
               END-IF
           ELSE
               IF WS-DAY-ACCUM < 1 OR > 365
                   MOVE +4 TO LK-DTU-RETURN-CODE
                   MOVE 'JULIAN DAY OUT OF RANGE'
                       TO LK-DTU-ERROR-MSG
                   GO TO 1000-EXIT
               END-IF
           END-IF
      *
      *    CONVERT DAY-OF-YEAR TO MONTH AND DAY
      *
           MOVE 1 TO WS-MONTH-IDX
           PERFORM UNTIL WS-MONTH-IDX > 12
               MOVE WS-MONTH-DAYS(WS-MONTH-IDX)
                   TO WS-MAX-DAYS
      *        ADJUST FEBRUARY FOR LEAP YEAR
               IF WS-MONTH-IDX = 2 AND WS-IS-LEAP-YEAR
                   ADD 1 TO WS-MAX-DAYS
               END-IF
               IF WS-DAY-ACCUM <= WS-MAX-DAYS
                   MOVE WS-MONTH-IDX TO WS-WORK-MM
                   MOVE WS-DAY-ACCUM TO WS-WORK-DD
                   MOVE 13 TO WS-MONTH-IDX
               ELSE
                   SUBTRACT WS-MAX-DAYS FROM WS-DAY-ACCUM
                   ADD 1 TO WS-MONTH-IDX
               END-IF
           END-PERFORM
      *
      *    FORMAT OUTPUT DATE AS YYYY-MM-DD
      *
           STRING WS-WORK-YYYY '-'
                  WS-WORK-MM   '-'
                  WS-WORK-DD
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-GREG
      *
      *    ALSO PROVIDE CCYYMMDD FORMAT
      *
           STRING WS-WORK-YYYY
                  WS-WORK-MM
                  WS-WORK-DD
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-CCYYMMDD
      *
      *    AND MM/DD/YYYY FORMAT
      *
           STRING WS-WORK-MM   '/'
                  WS-WORK-DD   '/'
                  WS-WORK-YYYY
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-MMDDYYYY
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - CONVERT GREGORIAN DATE TO JULIAN (YYYYDDD)              *
      *        INPUT: LK-DTU-INPUT-DATE-1 (YYYY-MM-DD)                *
      *        OUTPUT: LK-DTU-OUT-JULIAN (9(07))                       *
      *---------------------------------------------------------------*
       2000-GREGORIAN-TO-JULIAN.
      *
           PERFORM 7000-PARSE-DATE-1
      *
           IF LK-DTU-RETURN-CODE NOT = ZEROS
               GO TO 2000-EXIT
           END-IF
      *
           MOVE WS-PARSE-YYYY TO WS-WORK-YYYY
           MOVE WS-PARSE-MM   TO WS-WORK-MM
           MOVE WS-PARSE-DD   TO WS-WORK-DD
      *
           PERFORM 8000-CHECK-LEAP-YEAR
      *
      *    ACCUMULATE DAYS THROUGH PRECEDING MONTHS
      *
           MOVE ZERO TO WS-DAY-ACCUM
           PERFORM VARYING WS-MONTH-IDX FROM 1 BY 1
               UNTIL WS-MONTH-IDX >= WS-WORK-MM
               MOVE WS-MONTH-DAYS(WS-MONTH-IDX)
                   TO WS-MAX-DAYS
               IF WS-MONTH-IDX = 2 AND WS-IS-LEAP-YEAR
                   ADD 1 TO WS-MAX-DAYS
               END-IF
               ADD WS-MAX-DAYS TO WS-DAY-ACCUM
           END-PERFORM
      *
      *    ADD CURRENT DAY
      *
           ADD WS-WORK-DD TO WS-DAY-ACCUM
      *
           MOVE WS-WORK-YYYY TO WS-JUL-YYYY
           MOVE WS-DAY-ACCUM TO WS-JUL-DDD
           MOVE WS-WORK-JULIAN-N TO LK-DTU-OUT-JULIAN
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - CALCULATE DAYS BETWEEN TWO GREGORIAN DATES              *
      *        INPUT: LK-DTU-INPUT-DATE-1 AND DATE-2 (YYYY-MM-DD)     *
      *        OUTPUT: LK-DTU-OUT-DAYS (SIGNED, DATE2 - DATE1)         *
      *---------------------------------------------------------------*
       3000-DAYS-BETWEEN.
      *
           PERFORM 7000-PARSE-DATE-1
           IF LK-DTU-RETURN-CODE NOT = ZEROS
               GO TO 3000-EXIT
           END-IF
           MOVE WS-PARSE-YYYY TO WS-GD1-YYYY
           MOVE WS-PARSE-MM   TO WS-GD1-MM
           MOVE WS-PARSE-DD   TO WS-GD1-DD
      *
           PERFORM 7100-PARSE-DATE-2
           IF LK-DTU-RETURN-CODE NOT = ZEROS
               GO TO 3000-EXIT
           END-IF
           MOVE WS-PARSE-YYYY TO WS-GD2-YYYY
           MOVE WS-PARSE-MM   TO WS-GD2-MM
           MOVE WS-PARSE-DD   TO WS-GD2-DD
      *
      *    CONVERT BOTH DATES TO INTEGER DATE FORMAT
      *    USING COBOL INTRINSIC FUNCTION
      *
           COMPUTE WS-INT-DATE-1 =
               FUNCTION INTEGER-OF-DATE(
                   WS-GD1-YYYY * 10000 +
                   WS-GD1-MM   * 100   +
                   WS-GD1-DD)
      *
           COMPUTE WS-INT-DATE-2 =
               FUNCTION INTEGER-OF-DATE(
                   WS-GD2-YYYY * 10000 +
                   WS-GD2-MM   * 100   +
                   WS-GD2-DD)
      *
           COMPUTE LK-DTU-OUT-DAYS =
               WS-INT-DATE-2 - WS-INT-DATE-1
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - ADD BUSINESS DAYS TO A DATE                             *
      *        INPUT: LK-DTU-INPUT-DATE-1, LK-DTU-INPUT-DAYS          *
      *        OUTPUT: LK-DTU-OUT-GREG (RESULTING DATE)                *
      *        SKIPS SATURDAYS AND SUNDAYS                             *
      *---------------------------------------------------------------*
       4000-ADD-BUSINESS-DAYS.
      *
           PERFORM 7000-PARSE-DATE-1
           IF LK-DTU-RETURN-CODE NOT = ZEROS
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-PARSE-YYYY TO WS-WORK-YYYY
           MOVE WS-PARSE-MM   TO WS-WORK-MM
           MOVE WS-PARSE-DD   TO WS-WORK-DD
      *
           MOVE LK-DTU-INPUT-DAYS TO WS-BDAY-COUNT
      *
      *    DETERMINE DIRECTION (POSITIVE = FORWARD)
      *
           IF WS-BDAY-COUNT < 0
               MOVE -1 TO WS-BDAY-DIR
               MULTIPLY -1 BY WS-BDAY-COUNT
           ELSE
               MOVE +1 TO WS-BDAY-DIR
           END-IF
      *
      *    CONVERT START DATE TO INTEGER FOR ARITHMETIC
      *
           COMPUTE WS-INT-DATE-1 =
               FUNCTION INTEGER-OF-DATE(
                   WS-WORK-YYYY * 10000 +
                   WS-WORK-MM   * 100   +
                   WS-WORK-DD)
      *
      *    ADD BUSINESS DAYS ONE AT A TIME
      *
           PERFORM UNTIL WS-BDAY-COUNT = 0
               ADD WS-BDAY-DIR TO WS-INT-DATE-1
      *
      *        CONVERT BACK TO GET DAY OF WEEK
      *
               COMPUTE WS-WORK-CCYYMMDD =
                   FUNCTION DATE-OF-INTEGER(WS-INT-DATE-1)
               COMPUTE WS-DOW =
                   FUNCTION MOD(WS-INT-DATE-1, 7) + 1
      *
      *        DOW: 1=MON, 2=TUE, ... 6=SAT, 7=SUN
      *        SKIP WEEKENDS
      *
               IF WS-DOW NOT = 6 AND WS-DOW NOT = 7
                   SUBTRACT 1 FROM WS-BDAY-COUNT
               END-IF
           END-PERFORM
      *
      *    FORMAT RESULT DATE
      *
           COMPUTE WS-WORK-CCYYMMDD =
               FUNCTION DATE-OF-INTEGER(WS-INT-DATE-1)
      *
           MOVE WS-WORK-CCYYMMDD TO WS-PARSE-CCYYMMDD
      *
           STRING WS-PARSE-YYYY '-'
                  WS-PARSE-MM   '-'
                  WS-PARSE-DD
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-GREG
      *
           STRING WS-PARSE-YYYY
                  WS-PARSE-MM
                  WS-PARSE-DD
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-CCYYMMDD
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - CALCULATE AGE FROM A DATE TO TODAY                      *
      *        INPUT: LK-DTU-INPUT-DATE-1 (YYYY-MM-DD)                *
      *        OUTPUT: LK-DTU-OUT-YEARS, MONTHS, REMDAYS, DAYS         *
      *---------------------------------------------------------------*
       5000-CALCULATE-AGE.
      *
           PERFORM 7000-PARSE-DATE-1
           IF LK-DTU-RETURN-CODE NOT = ZEROS
               GO TO 5000-EXIT
           END-IF
      *
           MOVE WS-PARSE-YYYY TO WS-GD1-YYYY
           MOVE WS-PARSE-MM   TO WS-GD1-MM
           MOVE WS-PARSE-DD   TO WS-GD1-DD
      *
      *    GET TODAY'S DATE
      *
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           MOVE WS-CURR-YYYY TO WS-GD2-YYYY
           MOVE WS-CURR-MM   TO WS-GD2-MM
           MOVE WS-CURR-DD   TO WS-GD2-DD
      *
      *    CALCULATE TOTAL DAYS BETWEEN
      *
           COMPUTE WS-INT-DATE-1 =
               FUNCTION INTEGER-OF-DATE(
                   WS-GD1-YYYY * 10000 +
                   WS-GD1-MM   * 100   +
                   WS-GD1-DD)
      *
           COMPUTE WS-INT-DATE-2 =
               FUNCTION INTEGER-OF-DATE(
                   WS-GD2-YYYY * 10000 +
                   WS-GD2-MM   * 100   +
                   WS-GD2-DD)
      *
           COMPUTE LK-DTU-OUT-DAYS =
               WS-INT-DATE-2 - WS-INT-DATE-1
      *
      *    CALCULATE YEARS, MONTHS, REMAINING DAYS
      *
           COMPUTE LK-DTU-OUT-YEARS =
               WS-GD2-YYYY - WS-GD1-YYYY
           COMPUTE LK-DTU-OUT-MONTHS =
               WS-GD2-MM - WS-GD1-MM
           COMPUTE LK-DTU-OUT-REMDAYS =
               WS-GD2-DD - WS-GD1-DD
      *
      *    ADJUST FOR NEGATIVE DAYS
      *
           IF LK-DTU-OUT-REMDAYS < 0
               SUBTRACT 1 FROM LK-DTU-OUT-MONTHS
               ADD 30 TO LK-DTU-OUT-REMDAYS
           END-IF
      *
      *    ADJUST FOR NEGATIVE MONTHS
      *
           IF LK-DTU-OUT-MONTHS < 0
               SUBTRACT 1 FROM LK-DTU-OUT-YEARS
               ADD 12 TO LK-DTU-OUT-MONTHS
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - GET CURRENT DATE, TIME AND DB2 TIMESTAMP                *
      *        OUTPUT: ALL FORMAT FIELDS POPULATED                     *
      *---------------------------------------------------------------*
       6000-GET-CURRENT-DATETIME.
      *
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
      *
      *    FORMAT YYYY-MM-DD
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-GREG
      *
      *    FORMAT CCYYMMDD
      *
           STRING WS-CURR-YYYY
                  WS-CURR-MM
                  WS-CURR-DD
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-CCYYMMDD
      *
      *    FORMAT MM/DD/YYYY
      *
           STRING WS-CURR-MM   '/'
                  WS-CURR-DD   '/'
                  WS-CURR-YYYY
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-MMDDYYYY
      *
      *    FORMAT HH:MM:SS
      *
           STRING WS-CURR-HH ':'
                  WS-CURR-MN ':'
                  WS-CURR-SS
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-TIME
      *
      *    FORMAT DB2 TIMESTAMP YYYY-MM-DD-HH.MM.SS.FFFFFF
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD   '-'
                  WS-CURR-HH   '.'
                  WS-CURR-MN   '.'
                  WS-CURR-SS   '.'
                  WS-CURR-HS   '0000'
               DELIMITED BY SIZE
               INTO LK-DTU-OUT-TIMESTAMP
      *
      *    COMPUTE JULIAN DATE
      *
           MOVE WS-CURR-YYYY TO WS-WORK-YYYY
           MOVE WS-CURR-MM   TO WS-WORK-MM
           MOVE WS-CURR-DD   TO WS-WORK-DD
           PERFORM 8000-CHECK-LEAP-YEAR
      *
           MOVE ZERO TO WS-DAY-ACCUM
           PERFORM VARYING WS-MONTH-IDX FROM 1 BY 1
               UNTIL WS-MONTH-IDX >= WS-WORK-MM
               MOVE WS-MONTH-DAYS(WS-MONTH-IDX)
                   TO WS-MAX-DAYS
               IF WS-MONTH-IDX = 2 AND WS-IS-LEAP-YEAR
                   ADD 1 TO WS-MAX-DAYS
               END-IF
               ADD WS-MAX-DAYS TO WS-DAY-ACCUM
           END-PERFORM
           ADD WS-WORK-DD TO WS-DAY-ACCUM
      *
           MOVE WS-WORK-YYYY TO WS-JUL-YYYY
           MOVE WS-DAY-ACCUM TO WS-JUL-DDD
           MOVE WS-WORK-JULIAN-N TO LK-DTU-OUT-JULIAN
      *
      *    DAY OF WEEK
      *
           COMPUTE WS-INT-DATE-1 =
               FUNCTION INTEGER-OF-DATE(
                   WS-CURR-YYYY * 10000 +
                   WS-CURR-MM   * 100   +
                   WS-CURR-DD)
           COMPUTE LK-DTU-OUT-DOW =
               FUNCTION MOD(WS-INT-DATE-1, 7) + 1
      *
           EVALUATE LK-DTU-OUT-DOW
               WHEN 1  MOVE 'MONDAY   ' TO LK-DTU-OUT-DOW-NAME
               WHEN 2  MOVE 'TUESDAY  ' TO LK-DTU-OUT-DOW-NAME
               WHEN 3  MOVE 'WEDNESDAY' TO LK-DTU-OUT-DOW-NAME
               WHEN 4  MOVE 'THURSDAY ' TO LK-DTU-OUT-DOW-NAME
               WHEN 5  MOVE 'FRIDAY   ' TO LK-DTU-OUT-DOW-NAME
               WHEN 6  MOVE 'SATURDAY ' TO LK-DTU-OUT-DOW-NAME
               WHEN 7  MOVE 'SUNDAY   ' TO LK-DTU-OUT-DOW-NAME
           END-EVALUATE
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7000 - PARSE DATE-1 (YYYY-MM-DD FORMAT) INTO WORK FIELDS      *
      *---------------------------------------------------------------*
       7000-PARSE-DATE-1.
      *
           IF LK-DTU-INPUT-DATE-1 = SPACES
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'INPUT DATE 1 IS BLANK'
                   TO LK-DTU-ERROR-MSG
               GO TO 7000-EXIT
           END-IF
      *
      *    EXTRACT YYYY, MM, DD FROM YYYY-MM-DD
      *
           MOVE LK-DTU-INPUT-DATE-1(1:4) TO WS-PARSE-YYYY
           MOVE LK-DTU-INPUT-DATE-1(6:2) TO WS-PARSE-MM
           MOVE LK-DTU-INPUT-DATE-1(9:2) TO WS-PARSE-DD
      *
      *    VALIDATE RANGES
      *
           IF WS-PARSE-YYYY < 1900 OR > 2099
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'YEAR OUT OF RANGE (1900-2099)'
                   TO LK-DTU-ERROR-MSG
               GO TO 7000-EXIT
           END-IF
      *
           IF WS-PARSE-MM < 01 OR > 12
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'MONTH OUT OF RANGE (01-12)'
                   TO LK-DTU-ERROR-MSG
               GO TO 7000-EXIT
           END-IF
      *
      *    VALIDATE DAY FOR MONTH
      *
           MOVE WS-PARSE-YYYY TO WS-WORK-YYYY
           PERFORM 8000-CHECK-LEAP-YEAR
           MOVE WS-MONTH-DAYS(WS-PARSE-MM) TO WS-MAX-DAYS
           IF WS-PARSE-MM = 2 AND WS-IS-LEAP-YEAR
               ADD 1 TO WS-MAX-DAYS
           END-IF
      *
           IF WS-PARSE-DD < 01 OR > WS-MAX-DAYS
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'DAY OUT OF RANGE FOR MONTH'
                   TO LK-DTU-ERROR-MSG
           END-IF
           .
       7000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7100 - PARSE DATE-2 (YYYY-MM-DD FORMAT) INTO WORK FIELDS      *
      *---------------------------------------------------------------*
       7100-PARSE-DATE-2.
      *
           IF LK-DTU-INPUT-DATE-2 = SPACES
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'INPUT DATE 2 IS BLANK'
                   TO LK-DTU-ERROR-MSG
               GO TO 7100-EXIT
           END-IF
      *
           MOVE LK-DTU-INPUT-DATE-2(1:4) TO WS-PARSE-YYYY
           MOVE LK-DTU-INPUT-DATE-2(6:2) TO WS-PARSE-MM
           MOVE LK-DTU-INPUT-DATE-2(9:2) TO WS-PARSE-DD
      *
           IF WS-PARSE-YYYY < 1900 OR > 2099
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'DATE 2: YEAR OUT OF RANGE'
                   TO LK-DTU-ERROR-MSG
               GO TO 7100-EXIT
           END-IF
      *
           IF WS-PARSE-MM < 01 OR > 12
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'DATE 2: MONTH OUT OF RANGE'
                   TO LK-DTU-ERROR-MSG
               GO TO 7100-EXIT
           END-IF
      *
           MOVE WS-PARSE-YYYY TO WS-WORK-YYYY
           PERFORM 8000-CHECK-LEAP-YEAR
           MOVE WS-MONTH-DAYS(WS-PARSE-MM) TO WS-MAX-DAYS
           IF WS-PARSE-MM = 2 AND WS-IS-LEAP-YEAR
               ADD 1 TO WS-MAX-DAYS
           END-IF
      *
           IF WS-PARSE-DD < 01 OR > WS-MAX-DAYS
               MOVE +4 TO LK-DTU-RETURN-CODE
               MOVE 'DATE 2: DAY OUT OF RANGE'
                   TO LK-DTU-ERROR-MSG
           END-IF
           .
       7100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - CHECK IF WS-WORK-YYYY IS A LEAP YEAR                   *
      *        LEAP YEAR: DIVISIBLE BY 4, EXCEPT CENTURIES UNLESS      *
      *        ALSO DIVISIBLE BY 400                                    *
      *---------------------------------------------------------------*
       8000-CHECK-LEAP-YEAR.
      *
           MOVE 'N' TO WS-LEAP-YEAR-FLAG
      *
           DIVIDE WS-WORK-YYYY BY 4
               GIVING WS-QUOTIENT-WORK
               REMAINDER WS-REMAINDER-4
      *
           DIVIDE WS-WORK-YYYY BY 100
               GIVING WS-QUOTIENT-WORK
               REMAINDER WS-REMAINDER-100
      *
           DIVIDE WS-WORK-YYYY BY 400
               GIVING WS-QUOTIENT-WORK
               REMAINDER WS-REMAINDER-400
      *
           IF WS-REMAINDER-4 = 0
               IF WS-REMAINDER-100 NOT = 0
                   MOVE 'Y' TO WS-LEAP-YEAR-FLAG
               ELSE
                   IF WS-REMAINDER-400 = 0
                       MOVE 'Y' TO WS-LEAP-YEAR-FLAG
                   END-IF
               END-IF
           END-IF
           .
       8000-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMDTEL0                                              *
      ****************************************************************
