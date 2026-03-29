      ****************************************************************
      * COPYBOOK: WSCOMMON                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  SHARED CONSTANTS AND WORKING STORAGE USED BY     *
      *           ALL PROGRAMS IN THE AUTOSALES SYSTEM              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      ****************************************************************
      *
      *    PROGRAM IDENTIFICATION
      *
       01  WS-PROGRAM-CONSTANTS.
           05  WS-PROGRAM-ID          PIC X(08)    VALUE SPACES.
           05  WS-PROGRAM-VERSION     PIC X(06)    VALUE '01.00 '.
           05  WS-SYSTEM-ID           PIC X(08)    VALUE 'AUTOSALE'.
           05  WS-SUBSYSTEM-ID        PIC X(04)    VALUE SPACES.
      *
      *    DATE AND TIME FIELDS
      *
       01  WS-DATE-TIME-FIELDS.
           05  WS-CURRENT-DATE.
               10  WS-CURRENT-YYYY    PIC 9(04).
               10  WS-CURRENT-MM      PIC 9(02).
               10  WS-CURRENT-DD      PIC 9(02).
           05  WS-CURRENT-DATE-X REDEFINES WS-CURRENT-DATE
                                       PIC X(08).
           05  WS-CURRENT-TIME.
               10  WS-CURRENT-HH      PIC 9(02).
               10  WS-CURRENT-MN      PIC 9(02).
               10  WS-CURRENT-SS      PIC 9(02).
               10  WS-CURRENT-HS      PIC 9(02).
           05  WS-CURRENT-TIME-X REDEFINES WS-CURRENT-TIME
                                       PIC X(08).
           05  WS-CURRENT-TIMESTAMP   PIC X(26)    VALUE SPACES.
           05  WS-JULIAN-DATE         PIC 9(07)    VALUE ZEROS.
           05  WS-DAY-OF-WEEK         PIC 9(01)    VALUE ZERO.
           05  WS-FORMATTED-DATE      PIC X(10)    VALUE SPACES.
           05  WS-FORMATTED-TIME      PIC X(08)    VALUE SPACES.
      *
      *    RETURN AND ABEND CODES
      *
       01  WS-RETURN-FIELDS.
           05  WS-RETURN-CODE         PIC S9(04)   COMP VALUE +0.
           05  WS-ABEND-CODE          PIC S9(04)   COMP VALUE +0.
           05  WS-ABEND-CODE-X REDEFINES WS-ABEND-CODE
                                       PIC X(02).
           05  WS-USER-ABEND-CODE     PIC 9(04)    VALUE 0.
           05  WS-REASON-CODE         PIC S9(08)   COMP VALUE +0.
      *
      *    DB2 STATUS FIELDS
      *
       01  WS-DB2-STATUS-FIELDS.
           05  WS-DB2-SQLCODE         PIC S9(09)   COMP VALUE +0.
           05  WS-DB2-SQLSTATE        PIC X(05)    VALUE SPACES.
           05  WS-DB2-SQLERRD3        PIC S9(09)   COMP VALUE +0.
           05  WS-DB2-ROWS-AFFECTED   PIC S9(09)   COMP VALUE +0.
      *
      *    USER AND SESSION FIELDS
      *
       01  WS-SESSION-FIELDS.
           05  WS-USER-ID             PIC X(08)    VALUE SPACES.
           05  WS-DEALER-CODE         PIC X(05)    VALUE SPACES.
           05  WS-TERMINAL-ID         PIC X(08)    VALUE SPACES.
           05  WS-REGION-CODE         PIC X(03)    VALUE SPACES.
           05  WS-DISTRICT-CODE       PIC X(03)    VALUE SPACES.
           05  WS-ZONE-CODE           PIC X(02)    VALUE SPACES.
           05  WS-SECURITY-LEVEL      PIC 9(02)    VALUE 0.
      *
      *    COMMON STATUS FLAGS AND SWITCHES
      *
       01  WS-STATUS-FLAGS.
           05  WS-EOF-FLAG            PIC X(01)    VALUE 'N'.
               88  WS-EOF                          VALUE 'Y'.
               88  WS-NOT-EOF                      VALUE 'N'.
           05  WS-ERROR-FLAG          PIC X(01)    VALUE 'N'.
               88  WS-ERROR                        VALUE 'Y'.
               88  WS-NO-ERROR                     VALUE 'N'.
           05  WS-FIRST-TIME-FLAG     PIC X(01)    VALUE 'Y'.
               88  WS-FIRST-TIME                   VALUE 'Y'.
               88  WS-NOT-FIRST-TIME               VALUE 'N'.
           05  WS-FOUND-FLAG          PIC X(01)    VALUE 'N'.
               88  WS-FOUND                        VALUE 'Y'.
               88  WS-NOT-FOUND                    VALUE 'N'.
           05  WS-VALID-FLAG          PIC X(01)    VALUE 'Y'.
               88  WS-VALID                        VALUE 'Y'.
               88  WS-NOT-VALID                    VALUE 'N'.
           05  WS-UPDATE-FLAG         PIC X(01)    VALUE 'N'.
               88  WS-UPDATE-NEEDED                VALUE 'Y'.
               88  WS-NO-UPDATE                    VALUE 'N'.
           05  WS-RESTART-FLAG        PIC X(01)    VALUE 'N'.
               88  WS-IS-RESTART                   VALUE 'Y'.
               88  WS-NOT-RESTART                  VALUE 'N'.
           05  WS-DEBUG-FLAG          PIC X(01)    VALUE 'N'.
               88  WS-DEBUG-ON                     VALUE 'Y'.
               88  WS-DEBUG-OFF                    VALUE 'N'.
           05  WS-BATCH-FLAG          PIC X(01)    VALUE 'N'.
               88  WS-BATCH-MODE                   VALUE 'Y'.
               88  WS-ONLINE-MODE                  VALUE 'N'.
      *
      *    ERROR MESSAGE AREA
      *
       01  WS-ERROR-FIELDS.
           05  WS-ERROR-MSG           PIC X(79)    VALUE SPACES.
           05  WS-ERROR-PARAGRAPH     PIC X(30)    VALUE SPACES.
           05  WS-ERROR-SEVERITY      PIC X(01)    VALUE SPACES.
               88  WS-SEV-INFO                     VALUE 'I'.
               88  WS-SEV-WARNING                  VALUE 'W'.
               88  WS-SEV-ERROR                    VALUE 'E'.
               88  WS-SEV-SEVERE                   VALUE 'S'.
           05  WS-ERROR-COUNT         PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-WARNING-COUNT       PIC S9(07)   COMP-3
                                                    VALUE +0.
      *
      *    COMMON COUNTERS AND ACCUMULATORS
      *
       01  WS-COMMON-COUNTERS.
           05  WS-RECORDS-READ        PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-WRITTEN     PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-UPDATED     PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-DELETED     PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-REJECTED    PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-PROCESSED   PIC S9(09)   COMP-3
                                                    VALUE +0.
      *
      *    DISPLAY WORK FIELDS
      *
       01  WS-DISPLAY-FIELDS.
           05  WS-DISP-COUNTER        PIC Z,ZZZ,ZZ9.
           05  WS-DISP-AMOUNT         PIC $ZZZ,ZZZ,ZZ9.99.
           05  WS-DISP-RATE           PIC Z9.9999.
           05  WS-DISP-DATE           PIC XXXX/XX/XX.
           05  WS-DISP-TIME           PIC XX:XX:XX.
      *
      *    COMMON LITERAL VALUES
      *
       01  WS-COMMON-LITERALS.
           05  WS-LIT-AUTOSALES       PIC X(08)
                                       VALUE 'AUTOSALE'.
           05  WS-LIT-ABEND           PIC X(05)
                                       VALUE 'ABEND'.
           05  WS-LIT-SUCCESS         PIC X(07)
                                       VALUE 'SUCCESS'.
           05  WS-LIT-FAILURE         PIC X(07)
                                       VALUE 'FAILURE'.
           05  WS-LIT-YES             PIC X(01)    VALUE 'Y'.
           05  WS-LIT-NO              PIC X(01)    VALUE 'N'.
           05  WS-LIT-SPACES          PIC X(01)    VALUE SPACE.
           05  WS-LIT-ZEROS           PIC X(01)    VALUE ZERO.
      ****************************************************************
      * END OF WSCOMMON                                              *
      ****************************************************************
