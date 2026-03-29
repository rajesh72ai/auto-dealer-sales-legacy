      ****************************************************************
      * COPYBOOK: WSDBPCB                                          *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  IMS DB PCB (DATABASE PROGRAM COMMUNICATION       *
      *           BLOCK) MASK FOR DL/I DATABASE ACCESS              *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    THE DB PCB MASK IS USED TO CHECK STATUS CODES    *
      *           RETURNED BY DL/I CALLS (GU, GN, GNP, GHU,       *
      *           GHN, GHNP, ISRT, DLET, REPL). EACH DATABASE     *
      *           REFERENCED BY THE PROGRAM HAS ITS OWN PCB.       *
      ****************************************************************
      *
      *    IMS DB PCB MASK
      *
       01  DB-PCB-MASK.
           05  DB-DBD-NAME            PIC X(08).
           05  DB-SEG-LEVEL           PIC X(02).
           05  DB-STATUS-CODE         PIC X(02).
               88  DB-STATUS-OK                    VALUE '  '.
               88  DB-STATUS-GOOD                  VALUE '  '.
               88  DB-STATUS-GA                    VALUE 'GA'.
               88  DB-STATUS-GB                    VALUE 'GB'.
               88  DB-STATUS-GE                    VALUE 'GE'.
               88  DB-STATUS-GK                    VALUE 'GK'.
               88  DB-STATUS-II                    VALUE 'II'.
               88  DB-STATUS-DA                    VALUE 'DA'.
               88  DB-STATUS-DJ                    VALUE 'DJ'.
               88  DB-STATUS-RX                    VALUE 'RX'.
               88  DB-STATUS-IX                    VALUE 'IX'.
               88  DB-STATUS-LB                    VALUE 'LB'.
               88  DB-STATUS-LC                    VALUE 'LC'.
               88  DB-STATUS-LD                    VALUE 'LD'.
               88  DB-STATUS-GP                    VALUE 'GP'.
               88  DB-STATUS-AI                    VALUE 'AI'.
               88  DB-STATUS-AK                    VALUE 'AK'.
               88  DB-STATUS-AM                    VALUE 'AM'.
               88  DB-STATUS-NOT-FOUND             VALUE 'GE'.
               88  DB-STATUS-HIER-CHANGE           VALUE 'GA'
                                                          'GK'.
               88  DB-STATUS-END-OF-DB             VALUE 'GB'.
               88  DB-STATUS-DUP-KEY               VALUE 'II'.
               88  DB-STATUS-FATAL                 VALUE 'AI'
                                                          'AK'
                                                          'AM'.
           05  DB-PROC-OPTIONS        PIC X(04).
           05  FILLER                 PIC S9(05)   COMP.
           05  DB-SEG-NAME-FB         PIC X(08).
           05  DB-KEY-LENGTH          PIC S9(05)   COMP.
           05  DB-NUM-SENS-SEGS       PIC S9(05)   COMP.
           05  DB-KEY-FB-AREA         PIC X(50).
      *
      *    DB PCB STATUS CODE DESCRIPTIONS
      *
       01  WS-DB-STATUS-TABLE.
           05  FILLER                 PIC X(40)
               VALUE 'bb SUCCESSFUL DL/I CALL               '.
           05  FILLER                 PIC X(40)
               VALUE 'GA MOVED TO NEW PARENT AT HIGHER LEVEL'.
           05  FILLER                 PIC X(40)
               VALUE 'GB END OF DATABASE REACHED             '.
           05  FILLER                 PIC X(40)
               VALUE 'GE SEGMENT NOT FOUND                   '.
           05  FILLER                 PIC X(40)
               VALUE 'GK SEG FOUND AT DIFF HIERARCHY PATH   '.
           05  FILLER                 PIC X(40)
               VALUE 'II SEGMENT ALREADY EXISTS (DUP KEY)    '.
           05  FILLER                 PIC X(40)
               VALUE 'DA DATA UNAVAILABLE                    '.
           05  FILLER                 PIC X(40)
               VALUE 'DJ SEGMENT/PARENT NOT FOUND FOR ISRT   '.
           05  FILLER                 PIC X(40)
               VALUE 'RX INVALID REPL/DLET WITHOUT HOLD CALL '.
           05  FILLER                 PIC X(40)
               VALUE 'IX INVALID CALL FOR PROCESSING OPTION  '.
           05  FILLER                 PIC X(40)
               VALUE 'AI PCB NOT OPEN OR NOT AVAILABLE       '.
           05  FILLER                 PIC X(40)
               VALUE 'AK INVALID SSA                         '.
           05  FILLER                 PIC X(40)
               VALUE 'AM CALL NOT COMPATIBLE WITH PCB        '.
       01  WS-DB-STATUS-ENTRIES REDEFINES WS-DB-STATUS-TABLE.
           05  WS-DB-STATUS-ENTRY     OCCURS 13 TIMES.
               10  WS-DB-STAT-CODE    PIC X(02).
               10  FILLER             PIC X(01).
               10  WS-DB-STAT-DESC    PIC X(37).
      *
      *    DL/I FUNCTION CODE CONSTANTS
      *
       01  WS-DLI-FUNCTION-CODES.
           05  WS-DLI-GU             PIC X(04)    VALUE 'GU  '.
           05  WS-DLI-GN             PIC X(04)    VALUE 'GN  '.
           05  WS-DLI-GNP            PIC X(04)    VALUE 'GNP '.
           05  WS-DLI-GHU            PIC X(04)    VALUE 'GHU '.
           05  WS-DLI-GHN            PIC X(04)    VALUE 'GHN '.
           05  WS-DLI-GHNP           PIC X(04)    VALUE 'GHNP'.
           05  WS-DLI-ISRT           PIC X(04)    VALUE 'ISRT'.
           05  WS-DLI-DLET           PIC X(04)    VALUE 'DLET'.
           05  WS-DLI-REPL           PIC X(04)    VALUE 'REPL'.
           05  WS-DLI-CHKP           PIC X(04)    VALUE 'CHKP'.
           05  WS-DLI-XRST           PIC X(04)    VALUE 'XRST'.
           05  WS-DLI-ROLB           PIC X(04)    VALUE 'ROLB'.
      *
      *    SSA (SEGMENT SEARCH ARGUMENT) WORK AREA
      *
       01  WS-SSA-WORK-AREA.
           05  WS-SSA-UNQUALIFIED.
               10  WS-SSA-SEG-NAME   PIC X(08)    VALUE SPACES.
               10  WS-SSA-BLANK      PIC X(01)    VALUE SPACE.
           05  WS-SSA-QUALIFIED.
               10  WS-SSAQ-SEG-NAME  PIC X(08)    VALUE SPACES.
               10  WS-SSAQ-LPAREN    PIC X(01)    VALUE '('.
               10  WS-SSAQ-FLD-NAME  PIC X(08)    VALUE SPACES.
               10  WS-SSAQ-REL-OPER  PIC X(02)    VALUE SPACES.
               10  WS-SSAQ-FLD-VALUE PIC X(30)    VALUE SPACES.
               10  WS-SSAQ-RPAREN    PIC X(01)    VALUE ')'.
      ****************************************************************
      * END OF WSDBPCB                                               *
      ****************************************************************
