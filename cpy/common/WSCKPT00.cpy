      ****************************************************************
      * COPYBOOK: WSCKPT00                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  CHECKPOINT/RESTART WORKING STORAGE FOR BATCH     *
      *           PROGRAMS USING IMS SYMBOLIC CHKP/XRST             *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    BATCH PROGRAMS ISSUE CHKP (SYMBOLIC) CALLS TO    *
      *           IMS AT REGULAR INTERVALS. ON RESTART, AN XRST    *
      *           CALL IS ISSUED TO RESTORE THE CHECKPOINT DATA    *
      *           AND RESUME PROCESSING.                            *
      ****************************************************************
      *
      *    CHECKPOINT CONTROL FIELDS
      *
       01  WS-CHECKPOINT-CONTROL.
           05  WS-CHECKPOINT-ID       PIC X(08)    VALUE SPACES.
           05  WS-CHECKPOINT-FREQ     PIC S9(07)   COMP-3
                                                    VALUE +500.
           05  WS-COMMIT-COUNT        PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-PROCESSED   PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-RECORDS-SINCE-CHKP  PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-CHECKPOINT-COUNT    PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-CHECKPOINT-SEQ      PIC 9(08)    VALUE 0.
      *
      *    RESTART CONTROL FIELDS
      *
       01  WS-RESTART-CONTROL.
           05  WS-RESTART-FLAG        PIC X(01)    VALUE 'N'.
               88  WS-IS-RESTART                   VALUE 'Y'.
               88  WS-NORMAL-START                 VALUE 'N'.
           05  WS-RESTART-STATUS      PIC X(02)    VALUE SPACES.
               88  WS-RESTART-OK                   VALUE '  '.
               88  WS-RESTART-FAILED               VALUE 'RF'.
               88  WS-RESTART-NA                   VALUE 'NA'.
           05  WS-RESTART-KEY         PIC X(30)    VALUE SPACES.
           05  WS-LAST-KEY-VALUE      PIC X(30)    VALUE SPACES.
           05  WS-RESTART-TIMESTAMP   PIC X(26)    VALUE SPACES.
      *
      *    CHECKPOINT DATA AREA
      *    (THIS AREA IS PASSED TO THE CHKP CALL AND RESTORED
      *     BY THE XRST CALL ON RESTART)
      *
       01  WS-CHECKPOINT-AREA.
           05  WS-CHKP-EYE-CATCHER   PIC X(08)
                                       VALUE 'ASCHKP00'.
           05  WS-CHKP-PROGRAM-ID     PIC X(08)    VALUE SPACES.
           05  WS-CHKP-TIMESTAMP      PIC X(26)    VALUE SPACES.
           05  WS-CHKP-LAST-KEY       PIC X(30)    VALUE SPACES.
           05  WS-CHKP-RECORDS-IN     PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-CHKP-RECORDS-OUT    PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-CHKP-RECORDS-ERR    PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-CHKP-TOTAL-AMT      PIC S9(13)V99 COMP-3
                                                    VALUE +0.
           05  WS-CHKP-ACCUM-1        PIC S9(13)V99 COMP-3
                                                    VALUE +0.
           05  WS-CHKP-ACCUM-2        PIC S9(13)V99 COMP-3
                                                    VALUE +0.
           05  WS-CHKP-USER-DATA      PIC X(100)   VALUE SPACES.
      *
      *    CHECKPOINT AREA LENGTH
      *
       01  WS-CHKP-AREA-LENGTH       PIC S9(09)   COMP
                                       VALUE +240.
      *
      *    DL/I FUNCTION CODES FOR CHECKPOINT/RESTART
      *
       01  WS-CHKP-FUNCTIONS.
           05  WS-CHKP-FUNCTION       PIC X(04)    VALUE 'CHKP'.
           05  WS-XRST-FUNCTION       PIC X(04)    VALUE 'XRST'.
      *
      *    CHECKPOINT I/O AREA (8-BYTE ID PASSED TO CHKP)
      *
       01  WS-CHKP-IO-AREA.
           05  WS-CHKP-IO-ID          PIC X(08)    VALUE SPACES.
      *
      *    XRST I/O AREA (RESTORED ON RESTART)
      *
       01  WS-XRST-IO-AREA.
           05  WS-XRST-IO-ID          PIC X(08)    VALUE SPACES.
           05  WS-XRST-IO-LENGTH      PIC S9(09)   COMP
                                                    VALUE +240.
      *
      *    CHECKPOINT TIMING FIELDS
      *
       01  WS-CHKP-TIMING.
           05  WS-CHKP-START-TIME     PIC S9(15)   COMP-3
                                                    VALUE +0.
           05  WS-CHKP-END-TIME       PIC S9(15)   COMP-3
                                                    VALUE +0.
           05  WS-CHKP-ELAPSED        PIC S9(09)   COMP-3
                                                    VALUE +0.
           05  WS-CHKP-INTERVAL-SEC   PIC S9(07)   COMP-3
                                                    VALUE +0.
      ****************************************************************
      * END OF WSCKPT00                                              *
      ****************************************************************
