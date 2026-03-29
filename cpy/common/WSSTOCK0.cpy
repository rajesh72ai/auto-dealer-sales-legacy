      ****************************************************************
      * COPYBOOK: WSSTOCK0                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  STOCK POSITION WORKING STORAGE FOR VEHICLE       *
      *           INVENTORY MANAGEMENT AND TRANSFER PROCESSING      *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      ****************************************************************
      *
      *    STOCK COUNT SUMMARY FIELDS
      *
       01  WS-STOCK-COUNTS.
           05  WS-STK-TOTAL-UNITS     PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-NEW-COUNT       PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-USED-COUNT      PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-DEMO-COUNT      PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-LOANER-COUNT    PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-IN-TRANSIT      PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-ON-ORDER        PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-ALLOCATED       PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-AVAILABLE       PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-STK-HELD-COUNT      PIC S9(07)   COMP-3
                                                    VALUE +0.
      *
      *    STOCK VALUE SUMMARY
      *
       01  WS-STOCK-VALUES.
           05  WS-STK-TOTAL-COST      PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-STK-TOTAL-MSRP      PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-STK-TOTAL-INVOICE   PIC S9(11)V99 COMP-3
                                                    VALUE +0.
           05  WS-STK-AVG-COST        PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-STK-AVG-AGE-DAYS    PIC S9(05)   COMP-3
                                                    VALUE +0.
      *
      *    STOCK STATUS TRACKING
      *
       01  WS-STOCK-STATUS.
           05  WS-STK-STATUS-CODE     PIC X(02)    VALUE SPACES.
               88  WS-STK-AVAILABLE-ST             VALUE 'AV'.
               88  WS-STK-ALLOCATED-ST             VALUE 'AL'.
               88  WS-STK-IN-TRANSIT-ST            VALUE 'IT'.
               88  WS-STK-ON-ORDER-ST              VALUE 'OO'.
               88  WS-STK-SOLD-ST                  VALUE 'SD'.
               88  WS-STK-HOLD-ST                  VALUE 'HD'.
               88  WS-STK-DEMO-ST                  VALUE 'DM'.
               88  WS-STK-LOANER-ST                VALUE 'LN'.
               88  WS-STK-WHOLESALE-ST             VALUE 'WS'.
               88  WS-STK-DAMAGED-ST               VALUE 'DG'.
               88  WS-STK-RETURNED-ST              VALUE 'RT'.
           05  WS-STK-LOCATION-CODE   PIC X(04)    VALUE SPACES.
           05  WS-STK-LOT-POSITION    PIC X(06)    VALUE SPACES.
           05  WS-STK-DAYS-IN-STOCK   PIC S9(05)   COMP-3
                                                    VALUE +0.
           05  WS-STK-AGING-BUCKET    PIC X(01)    VALUE SPACES.
               88  WS-STK-AGE-0-30                 VALUE '1'.
               88  WS-STK-AGE-31-60                VALUE '2'.
               88  WS-STK-AGE-61-90                VALUE '3'.
               88  WS-STK-AGE-91-120               VALUE '4'.
               88  WS-STK-AGE-OVER-120             VALUE '5'.
      *
      *    STOCK TRANSFER DATA AREA
      *
       01  WS-STOCK-TRANSFER.
           05  WS-XFR-TRANSFER-NUM    PIC X(10)    VALUE SPACES.
           05  WS-XFR-TRANSFER-TYPE   PIC X(02)    VALUE SPACES.
               88  WS-XFR-DEALER-TO-DEALER         VALUE 'DD'.
               88  WS-XFR-FACTORY-TO-DEALER        VALUE 'FD'.
               88  WS-XFR-DEALER-TRADE             VALUE 'DT'.
               88  WS-XFR-WHOLESALE                VALUE 'WS'.
               88  WS-XFR-RETURN-FACTORY           VALUE 'RF'.
           05  WS-XFR-FROM-DEALER     PIC X(05)    VALUE SPACES.
           05  WS-XFR-TO-DEALER       PIC X(05)    VALUE SPACES.
           05  WS-XFR-VIN             PIC X(17)    VALUE SPACES.
           05  WS-XFR-STOCK-NUM       PIC X(10)    VALUE SPACES.
           05  WS-XFR-TRANSFER-DATE   PIC X(10)    VALUE SPACES.
           05  WS-XFR-EFFECTIVE-DATE  PIC X(10)    VALUE SPACES.
           05  WS-XFR-TRANSFER-AMT    PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-XFR-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-XFR-PENDING                  VALUE 'PN'.
               88  WS-XFR-APPROVED                 VALUE 'AP'.
               88  WS-XFR-IN-TRANSIT               VALUE 'IT'.
               88  WS-XFR-RECEIVED                 VALUE 'RC'.
               88  WS-XFR-CANCELLED                VALUE 'CX'.
           05  WS-XFR-REASON          PIC X(40)    VALUE SPACES.
           05  WS-XFR-AUTH-USER       PIC X(08)    VALUE SPACES.
      *
      *    STOCK SEARCH CRITERIA
      *
       01  WS-STOCK-SEARCH.
           05  WS-STK-SRCH-DEALER     PIC X(05)    VALUE SPACES.
           05  WS-STK-SRCH-MAKE       PIC X(10)    VALUE SPACES.
           05  WS-STK-SRCH-MODEL      PIC X(20)    VALUE SPACES.
           05  WS-STK-SRCH-YEAR       PIC 9(04)    VALUE ZEROS.
           05  WS-STK-SRCH-COLOR      PIC X(15)    VALUE SPACES.
           05  WS-STK-SRCH-STATUS     PIC X(02)    VALUE SPACES.
           05  WS-STK-SRCH-TYPE       PIC X(02)    VALUE SPACES.
               88  WS-STK-SRCH-NEW                 VALUE 'NW'.
               88  WS-STK-SRCH-USED                VALUE 'US'.
               88  WS-STK-SRCH-ALL                 VALUE 'AL'.
           05  WS-STK-SRCH-MAX-ROWS   PIC S9(04)   COMP
                                                    VALUE +50.
      ****************************************************************
      * END OF WSSTOCK0                                              *
      ****************************************************************
