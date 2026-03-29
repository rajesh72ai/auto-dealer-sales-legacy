      ****************************************************************
      * COPYBOOK: WSPLI000                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  PRODUCTION AND LOGISTICS I/O AREAS FOR VEHICLE   *
      *           ORDERING, SHIPMENT, AND TRANSIT TRACKING          *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      ****************************************************************
      *
      *    PRODUCTION ORDER RECORD
      *
       01  WS-PRODUCTION-RECORD.
           05  WS-PRD-ORDER-NUMBER    PIC X(12)    VALUE SPACES.
           05  WS-PRD-ORDER-DATE      PIC X(10)    VALUE SPACES.
           05  WS-PRD-DEALER-CODE     PIC X(05)    VALUE SPACES.
           05  WS-PRD-PRIORITY-CODE   PIC X(01)    VALUE SPACES.
               88  WS-PRD-STOCK-ORDER              VALUE 'S'.
               88  WS-PRD-SOLD-ORDER               VALUE 'D'.
               88  WS-PRD-DEMO-ORDER               VALUE 'M'.
               88  WS-PRD-FLEET-ORDER              VALUE 'F'.
           05  WS-PRD-VEHICLE-SPEC.
               10  WS-PRD-MODEL-CODE  PIC X(06)    VALUE SPACES.
               10  WS-PRD-YEAR        PIC 9(04)    VALUE ZEROS.
               10  WS-PRD-TRIM-LEVEL  PIC X(04)    VALUE SPACES.
               10  WS-PRD-EXT-COLOR   PIC X(04)    VALUE SPACES.
               10  WS-PRD-INT-COLOR   PIC X(04)    VALUE SPACES.
               10  WS-PRD-ENGINE-CODE PIC X(04)    VALUE SPACES.
               10  WS-PRD-TRANS-CODE  PIC X(02)    VALUE SPACES.
                   88  WS-PRD-AUTOMATIC            VALUE 'AT'.
                   88  WS-PRD-MANUAL               VALUE 'MT'.
                   88  WS-PRD-CVT                  VALUE 'CV'.
               10  WS-PRD-DRIVE-TYPE  PIC X(03)    VALUE SPACES.
                   88  WS-PRD-FWD                  VALUE 'FWD'.
                   88  WS-PRD-RWD                  VALUE 'RWD'.
                   88  WS-PRD-AWD                  VALUE 'AWD'.
                   88  WS-PRD-4WD                  VALUE '4WD'.
           05  WS-PRD-OPTIONS.
               10  WS-PRD-OPT-COUNT   PIC S9(02)   COMP
                                                    VALUE +0.
               10  WS-PRD-OPT-CODES   PIC X(06)
                                       OCCURS 30 TIMES.
           05  WS-PRD-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-PRD-SUBMITTED               VALUE 'SB'.
               88  WS-PRD-ACCEPTED                 VALUE 'AC'.
               88  WS-PRD-SCHEDULED                VALUE 'SC'.
               88  WS-PRD-IN-PRODUCTION            VALUE 'IP'.
               88  WS-PRD-COMPLETED                VALUE 'CP'.
               88  WS-PRD-SHIPPED                  VALUE 'SH'.
               88  WS-PRD-CANCELLED                VALUE 'CX'.
               88  WS-PRD-ON-HOLD                  VALUE 'HO'.
           05  WS-PRD-SCHED-BUILD-DT  PIC X(10)    VALUE SPACES.
           05  WS-PRD-ACTUAL-BUILD-DT PIC X(10)    VALUE SPACES.
           05  WS-PRD-VIN-ASSIGNED    PIC X(17)    VALUE SPACES.
           05  WS-PRD-EST-SHIP-DATE   PIC X(10)    VALUE SPACES.
           05  WS-PRD-BASE-INVOICE    PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRD-OPT-INVOICE     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRD-DEST-CHARGE     PIC S9(05)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRD-TOTAL-INVOICE   PIC S9(07)V99 COMP-3
                                                    VALUE +0.
      *
      *    SHIPMENT RECORD
      *
       01  WS-SHIPMENT-RECORD.
           05  WS-SHP-SHIPMENT-ID     PIC X(12)    VALUE SPACES.
           05  WS-SHP-CARRIER-CODE    PIC X(04)    VALUE SPACES.
           05  WS-SHP-CARRIER-NAME    PIC X(35)    VALUE SPACES.
           05  WS-SHP-SCAC-CODE       PIC X(04)    VALUE SPACES.
           05  WS-SHP-TRUCK-NUM       PIC X(10)    VALUE SPACES.
           05  WS-SHP-BOL-NUMBER      PIC X(20)    VALUE SPACES.
           05  WS-SHP-SHIP-DATE       PIC X(10)    VALUE SPACES.
           05  WS-SHP-EST-ARRIVAL     PIC X(10)    VALUE SPACES.
           05  WS-SHP-ACTUAL-ARRIVAL  PIC X(10)    VALUE SPACES.
           05  WS-SHP-ORIGIN-PLANT    PIC X(04)    VALUE SPACES.
           05  WS-SHP-ORIGIN-CITY     PIC X(30)    VALUE SPACES.
           05  WS-SHP-ORIGIN-STATE    PIC X(02)    VALUE SPACES.
           05  WS-SHP-DEST-DEALER     PIC X(05)    VALUE SPACES.
           05  WS-SHP-DEST-CITY       PIC X(30)    VALUE SPACES.
           05  WS-SHP-DEST-STATE      PIC X(02)    VALUE SPACES.
           05  WS-SHP-VEHICLE-COUNT   PIC S9(03)   COMP
                                                    VALUE +0.
           05  WS-SHP-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-SHP-LOADED                   VALUE 'LD'.
               88  WS-SHP-DEPARTED                 VALUE 'DP'.
               88  WS-SHP-IN-TRANSIT               VALUE 'IT'.
               88  WS-SHP-ARRIVED                  VALUE 'AR'.
               88  WS-SHP-RECEIVED                 VALUE 'RC'.
               88  WS-SHP-INSPECTED                VALUE 'IN'.
               88  WS-SHP-DAMAGED                  VALUE 'DG'.
      *
      *    TRANSIT STATUS UPDATE RECORD
      *
       01  WS-TRANSIT-UPDATE.
           05  WS-TRN-SHIPMENT-ID     PIC X(12)    VALUE SPACES.
           05  WS-TRN-VIN             PIC X(17)    VALUE SPACES.
           05  WS-TRN-UPDATE-DATE     PIC X(10)    VALUE SPACES.
           05  WS-TRN-UPDATE-TIME     PIC X(08)    VALUE SPACES.
           05  WS-TRN-STATUS-CODE     PIC X(02)    VALUE SPACES.
           05  WS-TRN-LOCATION-CITY   PIC X(30)    VALUE SPACES.
           05  WS-TRN-LOCATION-STATE  PIC X(02)    VALUE SPACES.
           05  WS-TRN-LOCATION-ZIP    PIC X(09)    VALUE SPACES.
           05  WS-TRN-REMARKS         PIC X(50)    VALUE SPACES.
           05  WS-TRN-EXCEPTION-FLAG  PIC X(01)    VALUE 'N'.
               88  WS-TRN-EXCEPTION               VALUE 'Y'.
               88  WS-TRN-NORMAL                   VALUE 'N'.
           05  WS-TRN-EXCEPTION-CODE  PIC X(04)    VALUE SPACES.
               88  WS-TRN-DELAY                    VALUE 'DLAY'.
               88  WS-TRN-DAMAGE                   VALUE 'DAMG'.
               88  WS-TRN-REROUTE                  VALUE 'RERT'.
               88  WS-TRN-WEATHER                  VALUE 'WTHR'.
               88  WS-TRN-MECHANICAL               VALUE 'MECH'.
      *
      *    PRODUCTION SEARCH CRITERIA
      *
       01  WS-PRD-SEARCH.
           05  WS-PRD-SRCH-DEALER     PIC X(05)    VALUE SPACES.
           05  WS-PRD-SRCH-ORDER-NUM  PIC X(12)    VALUE SPACES.
           05  WS-PRD-SRCH-STATUS     PIC X(02)    VALUE SPACES.
           05  WS-PRD-SRCH-FROM-DATE  PIC X(10)    VALUE SPACES.
           05  WS-PRD-SRCH-TO-DATE    PIC X(10)    VALUE SPACES.
           05  WS-PRD-SRCH-MODEL      PIC X(06)    VALUE SPACES.
      ****************************************************************
      * END OF WSPLI000                                              *
      ****************************************************************
