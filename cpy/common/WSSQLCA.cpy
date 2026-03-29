      ****************************************************************
      * COPYBOOK: WSSQLCA                                          *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  SQLCA INCLUDE AND SQL RETURN CODE CHECKING        *
      *           FIELDS FOR DB2 ERROR HANDLING                     *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      ****************************************************************
      *
      *    DB2 SQLCA - INCLUDED VIA EXEC SQL
      *
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *    SQL STATUS CHECKING FIELDS
      *
       01  WS-SQL-STATUS-FIELDS.
           05  WS-SQL-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-SQL-OK                       VALUE '00'.
               88  WS-SQL-NOT-FOUND                VALUE 'NF'.
               88  WS-SQL-DUP-KEY                  VALUE 'DK'.
               88  WS-SQL-MULT-ROWS                VALUE 'MR'.
               88  WS-SQL-MISMATCH                 VALUE 'MM'.
               88  WS-SQL-RESOURCE                 VALUE 'RS'.
               88  WS-SQL-DEADLOCK                 VALUE 'DL'.
               88  WS-SQL-TIMEOUT                  VALUE 'TO'.
               88  WS-SQL-OTHER-ERR                VALUE 'OE'.
           05  WS-SQL-OPERATION       PIC X(10)    VALUE SPACES.
           05  WS-SQL-TABLE-NAME      PIC X(18)    VALUE SPACES.
           05  WS-SQL-SAVED-CODE      PIC S9(09)   COMP
                                                    VALUE +0.
      *
      *    SQLCODE VALUE CHECKING AREA
      *
       01  WS-SQLCODE-CHECK.
           05  WS-SQLCODE-VALUE       PIC S9(09)   COMP
                                                    VALUE +0.
               88  WS-SQLCODE-SUCCESS              VALUE +0.
               88  WS-SQLCODE-NOT-FOUND            VALUE +100.
               88  WS-SQLCODE-DUP-INSERT           VALUE -803.
               88  WS-SQLCODE-MULT-ROWS            VALUE -811.
               88  WS-SQLCODE-PLAN-MISMATCH        VALUE -818.
               88  WS-SQLCODE-UNAVAILABLE          VALUE -904.
               88  WS-SQLCODE-DEADLOCK             VALUE -911.
               88  WS-SQLCODE-TIMEOUT              VALUE -913.
               88  WS-SQLCODE-ROLLBACK             VALUE -911
                                                          -913.
               88  WS-SQLCODE-NEG-WARNING          VALUE -100.
               88  WS-SQLCODE-WARNING              VALUE +1
                                                   THRU +99.
               88  WS-SQLCODE-SEVERE               VALUE -900
                                                   THRU -999.
      *
      *    SQL ERROR MESSAGE FORMATTING
      *
       01  WS-SQL-ERROR-MSG.
           05  FILLER                  PIC X(09)
                                       VALUE 'SQLCODE: '.
           05  WS-SQL-ERR-CODE-DISP   PIC -(09)9.
           05  FILLER                  PIC X(02)
                                       VALUE ', '.
           05  WS-SQL-ERR-STATE-LBL   PIC X(10)
                                       VALUE 'SQLSTATE: '.
           05  WS-SQL-ERR-STATE       PIC X(05)    VALUE SPACES.
           05  FILLER                  PIC X(02)
                                       VALUE ', '.
           05  WS-SQL-ERR-TABLE-LBL   PIC X(07)
                                       VALUE 'TABLE: '.
           05  WS-SQL-ERR-TABLE       PIC X(18)    VALUE SPACES.
      *
      *    SQL RETRY CONTROL FIELDS
      *
       01  WS-SQL-RETRY-FIELDS.
           05  WS-SQL-RETRY-COUNT     PIC S9(04)   COMP
                                                    VALUE +0.
           05  WS-SQL-RETRY-MAX       PIC S9(04)   COMP
                                                    VALUE +3.
           05  WS-SQL-RETRY-FLAG      PIC X(01)    VALUE 'N'.
               88  WS-SQL-SHOULD-RETRY             VALUE 'Y'.
               88  WS-SQL-NO-RETRY                 VALUE 'N'.
      *
      *    CURSOR STATUS TRACKING
      *
       01  WS-CURSOR-STATUS.
           05  WS-CURSOR-OPEN-FLAG    PIC X(01)    VALUE 'N'.
               88  WS-CURSOR-IS-OPEN               VALUE 'Y'.
               88  WS-CURSOR-IS-CLOSED             VALUE 'N'.
           05  WS-CURSOR-FETCH-COUNT  PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-CURSOR-NAME         PIC X(18)    VALUE SPACES.
      ****************************************************************
      * END OF WSSQLCA                                               *
      ****************************************************************
