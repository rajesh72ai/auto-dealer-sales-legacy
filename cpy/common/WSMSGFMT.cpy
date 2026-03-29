      ****************************************************************
      * COPYBOOK: WSMSGFMT                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  IMS DC MESSAGE FORMATTING AREAS FOR INPUT AND    *
      *           OUTPUT MESSAGE SEGMENTS TO/FROM TERMINALS         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    ALL IMS DC MESSAGES HAVE A 4-BYTE LL/ZZ PREFIX   *
      *           (LL = SEGMENT LENGTH, ZZ = RESERVED/ZEROS).      *
      *           MFS FORMATS THE PHYSICAL SCREEN; THESE ARE       *
      *           THE LOGICAL MESSAGE LAYOUTS.                      *
      ****************************************************************
      *
      *    INPUT MESSAGE FROM TERMINAL (GU/GN ON I/O PCB)
      *
       01  WS-INPUT-MSG.
           05  WS-INP-LL              PIC S9(04)   COMP.
           05  WS-INP-ZZ              PIC S9(04)   COMP.
           05  WS-INP-TRANCODE        PIC X(08).
           05  WS-INP-DATA.
               10  WS-INP-FUNCTION    PIC X(02).
                   88  WS-INP-INQUIRY              VALUE 'IQ'.
                   88  WS-INP-ADD                  VALUE 'AD'.
                   88  WS-INP-UPDATE               VALUE 'UP'.
                   88  WS-INP-DELETE               VALUE 'DL'.
                   88  WS-INP-NEXT                 VALUE 'NX'.
                   88  WS-INP-PREV                 VALUE 'PV'.
                   88  WS-INP-HELP                 VALUE 'HP'.
                   88  WS-INP-EXIT                 VALUE 'EX'.
               10  WS-INP-KEY-DATA    PIC X(30).
               10  WS-INP-BODY        PIC X(1920).
      *
      *    INPUT MESSAGE TOTAL LENGTH
      *
       01  WS-INP-MSG-LENGTH          PIC S9(09)   COMP
                                       VALUE +1964.
      *
      *    OUTPUT MESSAGE TO TERMINAL (ISRT ON I/O PCB)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL              PIC S9(04)   COMP.
           05  WS-OUT-ZZ              PIC S9(04)   COMP
                                       VALUE +0.
           05  WS-OUT-DATA.
               10  WS-OUT-STATUS-LINE.
                   15  WS-OUT-MSG-ID  PIC X(08).
                   15  FILLER         PIC X(01)    VALUE SPACE.
                   15  WS-OUT-MSG-TEXT
                                       PIC X(70).
               10  WS-OUT-BODY        PIC X(1880).
      *
      *    OUTPUT MESSAGE TOTAL LENGTH
      *
       01  WS-OUT-MSG-LENGTH          PIC S9(09)   COMP
                                       VALUE +1964.
      *
      *    MESSAGE SEGMENT LENGTH WORK FIELD
      *
       01  WS-MSG-SEGMENT-LENGTH      PIC S9(09)   COMP
                                       VALUE +0.
      *
      *    ERROR SCREEN OUTPUT AREA
      *
       01  WS-ERROR-SCREEN.
           05  WS-ERRS-LL             PIC S9(04)   COMP.
           05  WS-ERRS-ZZ             PIC S9(04)   COMP
                                       VALUE +0.
           05  WS-ERRS-DATA.
               10  WS-ERRS-TITLE.
                   15  FILLER         PIC X(30)
                       VALUE '*** AUTOSALES ERROR SCREEN ***'.
                   15  FILLER         PIC X(49)    VALUE SPACES.
               10  WS-ERRS-BLANK-1    PIC X(79)    VALUE SPACES.
               10  WS-ERRS-MSG-LINE.
                   15  FILLER         PIC X(09)
                       VALUE 'MESSAGE: '.
                   15  WS-ERRS-MSG    PIC X(70)    VALUE SPACES.
               10  WS-ERRS-BLANK-2    PIC X(79)    VALUE SPACES.
               10  WS-ERRS-PGM-LINE.
                   15  FILLER         PIC X(09)
                       VALUE 'PROGRAM: '.
                   15  WS-ERRS-PGM-ID PIC X(08)    VALUE SPACES.
                   15  FILLER         PIC X(05)
                       VALUE '  AT '.
                   15  WS-ERRS-PARA   PIC X(30)    VALUE SPACES.
                   15  FILLER         PIC X(27)    VALUE SPACES.
               10  WS-ERRS-CODE-LINE.
                   15  FILLER         PIC X(12)
                       VALUE 'SQLCODE:    '.
                   15  WS-ERRS-SQLCODE PIC -(09)9.
                   15  FILLER         PIC X(05)
                       VALUE '    '.
                   15  FILLER         PIC X(12)
                       VALUE 'IMS STATUS: '.
                   15  WS-ERRS-IMS-STAT
                                       PIC X(02)    VALUE SPACES.
                   15  FILLER         PIC X(37)    VALUE SPACES.
               10  WS-ERRS-BLANK-3    PIC X(79)    VALUE SPACES.
               10  WS-ERRS-TIME-LINE.
                   15  FILLER         PIC X(06)
                       VALUE 'DATE: '.
                   15  WS-ERRS-DATE   PIC X(10)    VALUE SPACES.
                   15  FILLER         PIC X(08)
                       VALUE '  TIME: '.
                   15  WS-ERRS-TIME   PIC X(08)    VALUE SPACES.
                   15  FILLER         PIC X(10)
                       VALUE '  USERID: '.
                   15  WS-ERRS-USERID PIC X(08)    VALUE SPACES.
                   15  FILLER         PIC X(29)    VALUE SPACES.
               10  WS-ERRS-BLANK-4    PIC X(79)    VALUE SPACES.
               10  WS-ERRS-ACTION-LINE.
                   15  FILLER         PIC X(50)
                       VALUE 'PRESS PF3 TO RETURN OR CONTAC
      -               'T HELP DESK.     '.
                   15  FILLER         PIC X(29)    VALUE SPACES.
      *
      *    ERROR SCREEN TOTAL LENGTH
      *
       01  WS-ERRS-TOTAL-LENGTH       PIC S9(09)   COMP
                                       VALUE +720.
      *
      *    COMMON MESSAGE CONSTANTS
      *
       01  WS-MSG-CONSTANTS.
           05  WS-MSG-NO-DATA         PIC X(40)
               VALUE 'NO DATA FOUND FOR YOUR REQUEST.         '.
           05  WS-MSG-ADDED-OK        PIC X(40)
               VALUE 'RECORD ADDED SUCCESSFULLY.              '.
           05  WS-MSG-UPDATED-OK      PIC X(40)
               VALUE 'RECORD UPDATED SUCCESSFULLY.            '.
           05  WS-MSG-DELETED-OK      PIC X(40)
               VALUE 'RECORD DELETED SUCCESSFULLY.            '.
           05  WS-MSG-DUP-KEY         PIC X(40)
               VALUE 'RECORD ALREADY EXISTS - DUPLICATE KEY.  '.
           05  WS-MSG-NOT-AUTH        PIC X(40)
               VALUE 'YOU ARE NOT AUTHORIZED FOR THIS FUNCTION'.
           05  WS-MSG-INVALID-FUNC    PIC X(40)
               VALUE 'INVALID FUNCTION CODE ENTERED.          '.
           05  WS-MSG-SYS-ERROR       PIC X(40)
               VALUE 'SYSTEM ERROR - CONTACT HELP DESK.       '.
      ****************************************************************
      * END OF WSMSGFMT                                              *
      ****************************************************************
