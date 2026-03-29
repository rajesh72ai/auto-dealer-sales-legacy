      ****************************************************************
      * COPYBOOK: WSAUDIT                                          *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  AUDIT LOGGING WORKING STORAGE WITH FIELDS        *
      *           MATCHING THE AUTOSALE.AUDIT_LOG DB2 TABLE         *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    ALL AUTOSALES PROGRAMS WRITE AUDIT RECORDS TO    *
      *           THE AUDIT_LOG TABLE FOR COMPLIANCE AND TRACKING.  *
      *           THE COMMON MODULE ASAUDT00 HANDLES THE INSERT.   *
      ****************************************************************
      *
      *    AUDIT LOG RECORD (MATCHES AUTOSALE.AUDIT_LOG TABLE)
      *
       01  WS-AUDIT-RECORD.
           05  WS-AUD-LOG-ID          PIC S9(09)   COMP
                                                    VALUE +0.
           05  WS-AUD-TIMESTAMP       PIC X(26)    VALUE SPACES.
           05  WS-AUD-PROGRAM-ID      PIC X(08)    VALUE SPACES.
           05  WS-AUD-TRANSACTION-ID  PIC X(08)    VALUE SPACES.
           05  WS-AUD-USER-ID         PIC X(08)    VALUE SPACES.
           05  WS-AUD-TERMINAL-ID     PIC X(08)    VALUE SPACES.
           05  WS-AUD-DEALER-CODE     PIC X(05)    VALUE SPACES.
           05  WS-AUD-ACTION-TYPE     PIC X(03)    VALUE SPACES.
               88  WS-AUD-INSERT                   VALUE 'INS'.
               88  WS-AUD-UPDATE                   VALUE 'UPD'.
               88  WS-AUD-DELETE                   VALUE 'DEL'.
               88  WS-AUD-INQUIRY                  VALUE 'INQ'.
               88  WS-AUD-APPROVE                  VALUE 'APR'.
               88  WS-AUD-REJECT                   VALUE 'REJ'.
               88  WS-AUD-PRINT                    VALUE 'PRT'.
               88  WS-AUD-LOGON                    VALUE 'LON'.
               88  WS-AUD-LOGOFF                   VALUE 'LOF'.
               88  WS-AUD-TRANSFER                 VALUE 'XFR'.
               88  WS-AUD-CANCEL                   VALUE 'CAN'.
               88  WS-AUD-SUBMIT                   VALUE 'SUB'.
           05  WS-AUD-TABLE-NAME      PIC X(18)    VALUE SPACES.
           05  WS-AUD-KEY-VALUE       PIC X(40)    VALUE SPACES.
           05  WS-AUD-OLD-VALUE       PIC X(200)   VALUE SPACES.
           05  WS-AUD-NEW-VALUE       PIC X(200)   VALUE SPACES.
           05  WS-AUD-DESCRIPTION     PIC X(80)    VALUE SPACES.
           05  WS-AUD-STATUS          PIC X(01)    VALUE 'S'.
               88  WS-AUD-STAT-SUCCESS             VALUE 'S'.
               88  WS-AUD-STAT-FAILURE             VALUE 'F'.
               88  WS-AUD-STAT-WARNING             VALUE 'W'.
           05  WS-AUD-SOURCE          PIC X(01)    VALUE 'O'.
               88  WS-AUD-SRC-ONLINE               VALUE 'O'.
               88  WS-AUD-SRC-BATCH                VALUE 'B'.
               88  WS-AUD-SRC-INTERFACE            VALUE 'I'.
           05  WS-AUD-SQLCODE         PIC S9(09)   COMP
                                                    VALUE +0.
           05  WS-AUD-IMS-STATUS      PIC X(02)    VALUE SPACES.
      *
      *    AUDIT LOG HOST VARIABLE NULL INDICATORS
      *
       01  WS-AUD-NULL-IND.
           05  NI-AUD-OLD-VALUE       PIC S9(04)   COMP
                                                    VALUE -1.
           05  NI-AUD-NEW-VALUE       PIC S9(04)   COMP
                                                    VALUE -1.
           05  NI-AUD-DESCRIPTION     PIC S9(04)   COMP
                                                    VALUE -1.
           05  NI-AUD-SQLCODE         PIC S9(04)   COMP
                                                    VALUE -1.
           05  NI-AUD-IMS-STATUS      PIC S9(04)   COMP
                                                    VALUE -1.
      *
      *    AUDIT FUNCTION CONTROL
      *
       01  WS-AUD-CONTROL.
           05  WS-AUD-ENABLED-FLAG    PIC X(01)    VALUE 'Y'.
               88  WS-AUD-ENABLED                  VALUE 'Y'.
               88  WS-AUD-DISABLED                 VALUE 'N'.
           05  WS-AUD-DETAIL-FLAG     PIC X(01)    VALUE 'Y'.
               88  WS-AUD-WITH-DETAIL              VALUE 'Y'.
               88  WS-AUD-NO-DETAIL                VALUE 'N'.
           05  WS-AUD-WRITE-COUNT     PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-AUD-ERROR-COUNT     PIC S9(07)   COMP-3
                                                    VALUE +0.
      *
      *    AUDIT ACTION TYPE LITERALS
      *
       01  WS-AUD-ACTION-LITERALS.
           05  WS-AUD-LIT-INS        PIC X(03)    VALUE 'INS'.
           05  WS-AUD-LIT-UPD        PIC X(03)    VALUE 'UPD'.
           05  WS-AUD-LIT-DEL        PIC X(03)    VALUE 'DEL'.
           05  WS-AUD-LIT-INQ        PIC X(03)    VALUE 'INQ'.
           05  WS-AUD-LIT-APR        PIC X(03)    VALUE 'APR'.
           05  WS-AUD-LIT-REJ        PIC X(03)    VALUE 'REJ'.
           05  WS-AUD-LIT-PRT        PIC X(03)    VALUE 'PRT'.
           05  WS-AUD-LIT-XFR        PIC X(03)    VALUE 'XFR'.
      ****************************************************************
      * END OF WSAUDIT                                               *
      ****************************************************************
