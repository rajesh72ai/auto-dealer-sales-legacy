       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMMSGL0.
      ****************************************************************
      * PROGRAM:   COMMSGL0                                          *
      * SYSTEM:    AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING   *
      * AUTHOR:    AUTOSALES DEVELOPMENT TEAM                        *
      * DATE:      2026-03-29                                        *
      * PURPOSE:   IMS DC MESSAGE BUILDER MODULE. CONSTRUCTS         *
      *            FORMATTED MESSAGE SEGMENTS FOR OUTPUT TO IMS       *
      *            TERMINALS. ALL MESSAGES INCLUDE LL/ZZ PREFIX,      *
      *            TIMESTAMP, SEVERITY INDICATOR, AND PROPER          *
      *            FORMATTING FOR MFS SCREEN DISPLAY.                 *
      *                                                              *
      * CALL INTERFACE:                                              *
      *   CALL 'COMMSGL0' USING LK-MSG-FUNCTION                     *
      *                         LK-MSG-TEXT                           *
      *                         LK-MSG-SEVERITY                      *
      *                         LK-MSG-PROGRAM-ID                    *
      *                         LK-MSG-OUTPUT-AREA                   *
      *                         LK-MSG-RETURN-CODE                   *
      *                                                              *
      * FUNCTIONS:                                                   *
      *   INFO - BUILD INFORMATIONAL MESSAGE                         *
      *   ERR  - BUILD ERROR MESSAGE                                 *
      *   WARN - BUILD WARNING MESSAGE                               *
      *   SCRN - BUILD FULL SCREEN WITH HEADER/FOOTER                *
      *   CLR  - BUILD CLEAR SCREEN MESSAGE                          *
      *                                                              *
      * RETURN CODES:                                                *
      *   00 - MESSAGE BUILT SUCCESSFULLY                            *
      *   04 - WARNING (MESSAGE TRUNCATED)                           *
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
       01  WS-MODULE-ID            PIC X(08) VALUE 'COMMSGL0'.
      *
      *    CURRENT DATE/TIME FOR MESSAGE TIMESTAMP
      *
       01  WS-CURRENT-DATE-TIME.
           05  WS-CURR-YYYY        PIC 9(04).
           05  WS-CURR-MM          PIC 9(02).
           05  WS-CURR-DD          PIC 9(02).
           05  WS-CURR-HH          PIC 9(02).
           05  WS-CURR-MN          PIC 9(02).
           05  WS-CURR-SS          PIC 9(02).
           05  WS-CURR-HS          PIC 9(02).
           05  FILLER              PIC X(05).
      *
      *    FORMATTED TIMESTAMP STRINGS
      *
       01  WS-FORMATTED-DATE       PIC X(10) VALUE SPACES.
       01  WS-FORMATTED-TIME       PIC X(08) VALUE SPACES.
       01  WS-FORMATTED-TIMESTAMP  PIC X(19) VALUE SPACES.
      *
      *    SEVERITY INDICATOR CHARACTERS
      *
       01  WS-SEVERITY-TABLE.
           05  WS-SEV-INFO-CHAR    PIC X(01) VALUE 'I'.
           05  WS-SEV-WARN-CHAR    PIC X(01) VALUE 'W'.
           05  WS-SEV-ERROR-CHAR   PIC X(01) VALUE 'E'.
           05  WS-SEV-SEVERE-CHAR  PIC X(01) VALUE 'S'.
      *
      *    MESSAGE SEGMENT LENGTH CALCULATION
      *
       01  WS-MSG-LENGTHS.
           05  WS-TEXT-LENGTH      PIC S9(04) COMP VALUE 0.
           05  WS-SEGMENT-LENGTH   PIC S9(04) COMP VALUE 0.
           05  WS-LL-VALUE         PIC S9(04) COMP VALUE 0.
           05  WS-LINE-LENGTH      PIC S9(04) COMP VALUE 79.
      *
      *    MESSAGE BUILD WORK AREA
      *
       01  WS-MSG-BUILD-AREA.
           05  WS-MSG-HEADER-LINE  PIC X(79) VALUE SPACES.
           05  WS-MSG-BODY-LINE    PIC X(79) VALUE SPACES.
           05  WS-MSG-FOOTER-LINE  PIC X(79) VALUE SPACES.
      *
      *    SCREEN HEADER LINE BUILD
      *
       01  WS-SCREEN-HEADER.
           05  WS-HDR-SYSTEM-NAME  PIC X(20)
               VALUE 'AUTOSALES           '.
           05  WS-HDR-SEPARATOR    PIC X(04)
               VALUE ' -- '.
           05  WS-HDR-SCREEN-TITLE PIC X(30) VALUE SPACES.
           05  WS-HDR-FILLER      PIC X(05) VALUE SPACES.
           05  WS-HDR-DATE        PIC X(10) VALUE SPACES.
           05  WS-HDR-SPACE       PIC X(02) VALUE SPACES.
           05  WS-HDR-TIME        PIC X(08) VALUE SPACES.
      *
      *    SCREEN FOOTER LINE BUILD
      *
       01  WS-SCREEN-FOOTER.
           05  WS-FTR-PGM-LABEL   PIC X(05) VALUE 'PGM: '.
           05  WS-FTR-PGM-ID      PIC X(08) VALUE SPACES.
           05  WS-FTR-SPACE1      PIC X(04) VALUE SPACES.
           05  WS-FTR-MSG-AREA    PIC X(50) VALUE SPACES.
           05  WS-FTR-SPACE2      PIC X(04) VALUE SPACES.
           05  WS-FTR-HELP-TEXT   PIC X(08)
               VALUE 'PF1=HELP'.
      *
      *    STATUS LINE FORMAT
      *
       01  WS-STATUS-LINE.
           05  WS-SL-MSG-ID       PIC X(08) VALUE SPACES.
           05  WS-SL-SEPARATOR    PIC X(01) VALUE SPACE.
           05  WS-SL-SEVERITY     PIC X(01) VALUE SPACES.
           05  WS-SL-SEPARATOR2   PIC X(01) VALUE SPACE.
           05  WS-SL-TIMESTAMP    PIC X(19) VALUE SPACES.
           05  WS-SL-SEPARATOR3   PIC X(01) VALUE SPACE.
           05  WS-SL-TEXT         PIC X(48) VALUE SPACES.
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-MSG-ID-PREFIX   PIC X(03) VALUE 'AS '.
           05  WS-MSG-SEQUENCE    PIC 9(05) VALUE 0.
           05  WS-MSG-ID-BUILT    PIC X(08) VALUE SPACES.
           05  WS-SEVERITY-IND    PIC X(01) VALUE SPACES.
           05  WS-LINE-COUNT      PIC 9(02) VALUE 0.
           05  WS-BODY-OFFSET     PIC S9(04) COMP VALUE 0.
      *
       LINKAGE SECTION.
      *
       01  LK-MSG-FUNCTION         PIC X(04).
      *
       01  LK-MSG-TEXT             PIC X(200).
      *
       01  LK-MSG-SEVERITY         PIC X(01).
           88  LK-SEV-INFO                    VALUE 'I'.
           88  LK-SEV-WARNING                 VALUE 'W'.
           88  LK-SEV-ERROR                   VALUE 'E'.
           88  LK-SEV-SEVERE                  VALUE 'S'.
      *
       01  LK-MSG-PROGRAM-ID      PIC X(08).
      *
       01  LK-MSG-OUTPUT-AREA.
           05  LK-MSG-OUT-LL      PIC S9(04) COMP.
           05  LK-MSG-OUT-ZZ      PIC S9(04) COMP.
           05  LK-MSG-OUT-DATA    PIC X(1960).
      *
       01  LK-MSG-RETURN-CODE     PIC S9(04) COMP.
      *
       PROCEDURE DIVISION USING LK-MSG-FUNCTION
                                LK-MSG-TEXT
                                LK-MSG-SEVERITY
                                LK-MSG-PROGRAM-ID
                                LK-MSG-OUTPUT-AREA
                                LK-MSG-RETURN-CODE.
      *
       0000-MAIN-ENTRY.
      *
           MOVE ZEROS TO LK-MSG-RETURN-CODE
      *
      *    GET CURRENT TIMESTAMP
      *
           PERFORM 8000-GET-TIMESTAMP
      *
           EVALUATE LK-MSG-FUNCTION
               WHEN 'INFO'
                   PERFORM 1000-BUILD-INFO-MSG
               WHEN 'ERR '
                   PERFORM 2000-BUILD-ERROR-MSG
               WHEN 'WARN'
                   PERFORM 3000-BUILD-WARNING-MSG
               WHEN 'SCRN'
                   PERFORM 4000-BUILD-SCREEN-MSG
               WHEN 'CLR '
                   PERFORM 5000-BUILD-CLEAR-MSG
               WHEN OTHER
                   MOVE +8 TO LK-MSG-RETURN-CODE
           END-EVALUATE
      *
           GOBACK
           .
      *
      *---------------------------------------------------------------*
      * 1000 - BUILD INFORMATIONAL MESSAGE SEGMENT                     *
      *        FORMAT: LL ZZ MSGID I TIMESTAMP TEXT                    *
      *---------------------------------------------------------------*
       1000-BUILD-INFO-MSG.
      *
           MOVE 'I' TO WS-SEVERITY-IND
           PERFORM 6000-BUILD-STATUS-LINE
           PERFORM 7000-ASSEMBLE-SEGMENT
           .
       1000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 2000 - BUILD ERROR MESSAGE SEGMENT                             *
      *        FORMAT: LL ZZ MSGID E TIMESTAMP TEXT                    *
      *        ERROR MESSAGES USE HIGHLIGHTED INDICATORS                *
      *---------------------------------------------------------------*
       2000-BUILD-ERROR-MSG.
      *
           MOVE 'E' TO WS-SEVERITY-IND
           PERFORM 6000-BUILD-STATUS-LINE
      *
      *    FOR ERRORS, ALSO ADD PROGRAM ID TO THE MESSAGE
      *
           STRING WS-STATUS-LINE
               DELIMITED BY SIZE
               INTO WS-MSG-HEADER-LINE
      *
           STRING 'PROGRAM: '
                  LK-MSG-PROGRAM-ID
                  '  '
                  WS-FORMATTED-TIMESTAMP
               DELIMITED BY SIZE
               INTO WS-MSG-BODY-LINE
      *
           PERFORM 7100-ASSEMBLE-ERROR-SEGMENT
           .
       2000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 3000 - BUILD WARNING MESSAGE SEGMENT                           *
      *        FORMAT: LL ZZ MSGID W TIMESTAMP TEXT                    *
      *---------------------------------------------------------------*
       3000-BUILD-WARNING-MSG.
      *
           MOVE 'W' TO WS-SEVERITY-IND
           PERFORM 6000-BUILD-STATUS-LINE
           PERFORM 7000-ASSEMBLE-SEGMENT
           .
       3000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 4000 - BUILD FULL SCREEN OUTPUT WITH HEADER AND FOOTER         *
      *        INCLUDES SYSTEM HEADER LINE, BODY CONTENT, AND          *
      *        FOOTER WITH PROGRAM ID AND PF KEY HELP                  *
      *---------------------------------------------------------------*
       4000-BUILD-SCREEN-MSG.
      *
      *    BUILD SCREEN HEADER
      *
           MOVE WS-FORMATTED-DATE TO WS-HDR-DATE
           MOVE WS-FORMATTED-TIME TO WS-HDR-TIME
      *
      *    USE MESSAGE TEXT AS SCREEN TITLE (FIRST 30 CHARS)
      *
           MOVE LK-MSG-TEXT(1:30) TO WS-HDR-SCREEN-TITLE
      *
      *    BUILD SCREEN FOOTER
      *
           MOVE LK-MSG-PROGRAM-ID TO WS-FTR-PGM-ID
      *
      *    IF THERE IS A MESSAGE BEYOND 30 CHARS, USE IT
      *    AS THE FOOTER STATUS MESSAGE
      *
           IF LK-MSG-TEXT(31:50) NOT = SPACES
               MOVE LK-MSG-TEXT(31:50) TO WS-FTR-MSG-AREA
           ELSE
               MOVE SPACES TO WS-FTR-MSG-AREA
           END-IF
      *
      *    ASSEMBLE FULL SCREEN SEGMENT
      *    HEADER (79) + 22 BLANK BODY LINES + FOOTER (79)
      *    TOTAL = 1896 BYTES + 4 (LL/ZZ) = 1900
      *
           MOVE +1900 TO LK-MSG-OUT-LL
           MOVE +0    TO LK-MSG-OUT-ZZ
      *
      *    PLACE HEADER AT START OF DATA
      *
           MOVE WS-SCREEN-HEADER TO LK-MSG-OUT-DATA(1:79)
      *
      *    SEPARATOR LINE AFTER HEADER
      *
           MOVE ALL '-' TO LK-MSG-OUT-DATA(80:79)
      *
      *    INITIALIZE BODY AREA (22 LINES * 79 = 1738 BYTES)
      *
           MOVE SPACES TO LK-MSG-OUT-DATA(159:1738)
      *
      *    SEPARATOR LINE BEFORE FOOTER
      *
           MOVE ALL '-' TO LK-MSG-OUT-DATA(1818:79)
      *
      *    FOOTER AT END
      *
           MOVE WS-SCREEN-FOOTER
               TO LK-MSG-OUT-DATA(1897:79)
           .
       4000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 5000 - BUILD CLEAR SCREEN MESSAGE                              *
      *        SENDS A SHORT SEGMENT TO CLEAR THE TERMINAL             *
      *---------------------------------------------------------------*
       5000-BUILD-CLEAR-MSG.
      *
      *    MINIMUM SEGMENT: LL + ZZ + ONE BLANK LINE
      *
           MOVE +83 TO LK-MSG-OUT-LL
           MOVE +0  TO LK-MSG-OUT-ZZ
           MOVE SPACES TO LK-MSG-OUT-DATA(1:79)
           .
       5000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 6000 - BUILD STATUS LINE FROM MESSAGE COMPONENTS               *
      *        FORMAT: ASNNNNN S YYYY-MM-DD HH:MM:SS TEXT              *
      *---------------------------------------------------------------*
       6000-BUILD-STATUS-LINE.
      *
      *    BUILD MESSAGE ID (AS + SEQUENCE)
      *
           ADD 1 TO WS-MSG-SEQUENCE
           STRING WS-MSG-ID-PREFIX
                  WS-MSG-SEQUENCE
               DELIMITED BY SIZE
               INTO WS-MSG-ID-BUILT
      *
      *    ASSEMBLE STATUS LINE
      *
           MOVE WS-MSG-ID-BUILT    TO WS-SL-MSG-ID
           MOVE WS-SEVERITY-IND    TO WS-SL-SEVERITY
           MOVE WS-FORMATTED-TIMESTAMP
                                    TO WS-SL-TIMESTAMP
      *
      *    MOVE MESSAGE TEXT (TRUNCATE IF NEEDED)
      *
           IF LK-MSG-TEXT(49:1) NOT = SPACE
               MOVE LK-MSG-TEXT(1:48) TO WS-SL-TEXT
               MOVE +4 TO LK-MSG-RETURN-CODE
           ELSE
               MOVE LK-MSG-TEXT(1:48) TO WS-SL-TEXT
           END-IF
           .
       6000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7000 - ASSEMBLE SINGLE-LINE MESSAGE SEGMENT                    *
      *        SETS LL/ZZ AND COPIES STATUS LINE TO OUTPUT             *
      *---------------------------------------------------------------*
       7000-ASSEMBLE-SEGMENT.
      *
      *    LL = 4 (LL/ZZ) + 79 (STATUS LINE) = 83
      *
           MOVE +83 TO LK-MSG-OUT-LL
           MOVE +0  TO LK-MSG-OUT-ZZ
           MOVE WS-STATUS-LINE TO LK-MSG-OUT-DATA(1:79)
           .
       7000-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 7100 - ASSEMBLE MULTI-LINE ERROR SEGMENT                       *
      *        INCLUDES STATUS LINE PLUS DETAIL LINE                   *
      *---------------------------------------------------------------*
       7100-ASSEMBLE-ERROR-SEGMENT.
      *
      *    LL = 4 (LL/ZZ) + 79 (STATUS) + 79 (DETAIL) = 162
      *
           MOVE +162 TO LK-MSG-OUT-LL
           MOVE +0   TO LK-MSG-OUT-ZZ
           MOVE WS-MSG-HEADER-LINE
               TO LK-MSG-OUT-DATA(1:79)
           MOVE WS-MSG-BODY-LINE
               TO LK-MSG-OUT-DATA(80:79)
           .
       7100-EXIT.
           EXIT.
      *
      *---------------------------------------------------------------*
      * 8000 - GET CURRENT TIMESTAMP AND FORMAT FOR DISPLAY            *
      *---------------------------------------------------------------*
       8000-GET-TIMESTAMP.
      *
           MOVE FUNCTION CURRENT-DATE
               TO WS-CURRENT-DATE-TIME
      *
      *    FORMAT DATE: YYYY-MM-DD
      *
           STRING WS-CURR-YYYY '-'
                  WS-CURR-MM   '-'
                  WS-CURR-DD
               DELIMITED BY SIZE
               INTO WS-FORMATTED-DATE
      *
      *    FORMAT TIME: HH:MM:SS
      *
           STRING WS-CURR-HH ':'
                  WS-CURR-MN ':'
                  WS-CURR-SS
               DELIMITED BY SIZE
               INTO WS-FORMATTED-TIME
      *
      *    FORMAT TIMESTAMP: YYYY-MM-DD HH:MM:SS
      *
           STRING WS-FORMATTED-DATE ' '
                  WS-FORMATTED-TIME
               DELIMITED BY SIZE
               INTO WS-FORMATTED-TIMESTAMP
           .
       8000-EXIT.
           EXIT.
      ****************************************************************
      * END OF COMMSGL0                                              *
      ****************************************************************
