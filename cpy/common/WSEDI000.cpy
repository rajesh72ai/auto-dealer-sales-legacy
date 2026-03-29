      ****************************************************************
      * COPYBOOK: WSEDI000                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  EDI MESSAGE LAYOUTS FOR VEHICLE SHIPMENT AND     *
      *           DELIVERY TRACKING (EDI 214 AND EDI 856)          *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    EDI 214 = TRANSPORTATION CARRIER SHIPMENT STATUS *
      *           EDI 856 = ADVANCE SHIP NOTICE / MANIFEST         *
      *           LAYOUTS FOLLOW ANSI X12 STANDARD STRUCTURE       *
      ****************************************************************
      *
      *    EDI INTERCHANGE ENVELOPE (ISA/IEA)
      *
       01  WS-EDI-ISA-SEGMENT.
           05  WS-ISA-SEG-ID          PIC X(03)    VALUE 'ISA'.
           05  WS-ISA-AUTH-QUAL       PIC X(02)    VALUE '00'.
           05  WS-ISA-AUTH-INFO       PIC X(10)    VALUE SPACES.
           05  WS-ISA-SEC-QUAL        PIC X(02)    VALUE '00'.
           05  WS-ISA-SEC-INFO        PIC X(10)    VALUE SPACES.
           05  WS-ISA-SENDER-QUAL     PIC X(02)    VALUE 'ZZ'.
           05  WS-ISA-SENDER-ID       PIC X(15)    VALUE SPACES.
           05  WS-ISA-RECVR-QUAL      PIC X(02)    VALUE 'ZZ'.
           05  WS-ISA-RECVR-ID        PIC X(15)    VALUE SPACES.
           05  WS-ISA-DATE            PIC X(06)    VALUE SPACES.
           05  WS-ISA-TIME            PIC X(04)    VALUE SPACES.
           05  WS-ISA-STD-ID          PIC X(01)    VALUE 'U'.
           05  WS-ISA-VERSION         PIC X(05)    VALUE '00401'.
           05  WS-ISA-CONTROL-NUM     PIC 9(09)    VALUE ZEROS.
           05  WS-ISA-ACK-REQ        PIC X(01)    VALUE '0'.
           05  WS-ISA-USAGE-IND       PIC X(01)    VALUE 'P'.
               88  WS-ISA-PRODUCTION               VALUE 'P'.
               88  WS-ISA-TEST                     VALUE 'T'.
           05  WS-ISA-ELEM-SEP        PIC X(01)    VALUE '*'.
      *
      *    EDI FUNCTIONAL GROUP (GS/GE)
      *
       01  WS-EDI-GS-SEGMENT.
           05  WS-GS-SEG-ID           PIC X(02)    VALUE 'GS'.
           05  WS-GS-FUNC-CODE        PIC X(02)    VALUE SPACES.
               88  WS-GS-SHIP-NOTICE               VALUE 'SH'.
               88  WS-GS-SHIP-STATUS               VALUE 'QM'.
           05  WS-GS-SENDER-CODE      PIC X(15)    VALUE SPACES.
           05  WS-GS-RECVR-CODE       PIC X(15)    VALUE SPACES.
           05  WS-GS-DATE             PIC X(08)    VALUE SPACES.
           05  WS-GS-TIME             PIC X(04)    VALUE SPACES.
           05  WS-GS-CONTROL-NUM      PIC 9(09)    VALUE ZEROS.
           05  WS-GS-RESP-AGENCY      PIC X(02)    VALUE 'X '.
           05  WS-GS-VERSION          PIC X(06)
                                       VALUE '004010'.
      *
      *    EDI TRANSACTION SET HEADER (ST)
      *
       01  WS-EDI-ST-SEGMENT.
           05  WS-ST-SEG-ID           PIC X(02)    VALUE 'ST'.
           05  WS-ST-TXNSET-ID        PIC X(03)    VALUE SPACES.
               88  WS-ST-IS-214                    VALUE '214'.
               88  WS-ST-IS-856                    VALUE '856'.
           05  WS-ST-CONTROL-NUM      PIC X(09)    VALUE SPACES.
      *
      *---------------------------------------------------------------
      *    EDI 214 - TRANSPORTATION CARRIER SHIPMENT STATUS MESSAGE
      *---------------------------------------------------------------
      *
       01  WS-EDI-214-RECORD.
           05  WS-214-HEADER.
               10  WS-214-TRAN-TYPE   PIC X(03)    VALUE '214'.
               10  WS-214-REF-NUMBER  PIC X(20)    VALUE SPACES.
               10  WS-214-SHIPMENT-ID PIC X(20)    VALUE SPACES.
               10  WS-214-CARRIER-CODE PIC X(04)   VALUE SPACES.
               10  WS-214-CARRIER-NAME PIC X(35)   VALUE SPACES.
               10  WS-214-SCAC-CODE   PIC X(04)    VALUE SPACES.
           05  WS-214-STATUS-DETAIL.
               10  WS-214-STATUS-CODE PIC X(02)    VALUE SPACES.
                   88  WS-214-PICKED-UP            VALUE 'AF'.
                   88  WS-214-IN-TRANSIT           VALUE 'IT'.
                   88  WS-214-OUT-FOR-DLVY         VALUE 'OA'.
                   88  WS-214-DELIVERED            VALUE 'D1'.
                   88  WS-214-DAMAGED              VALUE 'CD'.
                   88  WS-214-REFUSED              VALUE 'CA'.
               10  WS-214-STATUS-DATE PIC X(08)    VALUE SPACES.
               10  WS-214-STATUS-TIME PIC X(06)    VALUE SPACES.
               10  WS-214-CITY        PIC X(30)    VALUE SPACES.
               10  WS-214-STATE       PIC X(02)    VALUE SPACES.
               10  WS-214-ZIP         PIC X(09)    VALUE SPACES.
               10  WS-214-COUNTRY     PIC X(03)    VALUE 'US '.
           05  WS-214-VEHICLE-INFO.
               10  WS-214-VIN         PIC X(17)    VALUE SPACES.
               10  WS-214-MAKE        PIC X(10)    VALUE SPACES.
               10  WS-214-MODEL       PIC X(20)    VALUE SPACES.
               10  WS-214-YEAR        PIC 9(04)    VALUE ZEROS.
               10  WS-214-COLOR       PIC X(15)    VALUE SPACES.
           05  WS-214-DEST-INFO.
               10  WS-214-DEST-DEALER PIC X(05)    VALUE SPACES.
               10  WS-214-DEST-NAME   PIC X(35)    VALUE SPACES.
               10  WS-214-DEST-CITY   PIC X(30)    VALUE SPACES.
               10  WS-214-DEST-STATE  PIC X(02)    VALUE SPACES.
               10  WS-214-DEST-ZIP    PIC X(09)    VALUE SPACES.
               10  WS-214-ETA-DATE    PIC X(08)    VALUE SPACES.
      *
      *---------------------------------------------------------------
      *    EDI 856 - ADVANCE SHIP NOTICE / MANIFEST
      *---------------------------------------------------------------
      *
       01  WS-EDI-856-RECORD.
           05  WS-856-HEADER.
               10  WS-856-TRAN-TYPE   PIC X(03)    VALUE '856'.
               10  WS-856-SHIPMENT-ID PIC X(20)    VALUE SPACES.
               10  WS-856-BOL-NUMBER  PIC X(20)    VALUE SPACES.
               10  WS-856-SHIP-DATE   PIC X(08)    VALUE SPACES.
               10  WS-856-SCHED-DLVY  PIC X(08)    VALUE SPACES.
               10  WS-856-CARRIER-CODE PIC X(04)   VALUE SPACES.
               10  WS-856-CARRIER-NAME PIC X(35)   VALUE SPACES.
               10  WS-856-SCAC-CODE   PIC X(04)    VALUE SPACES.
               10  WS-856-TRUCK-NUM   PIC X(10)    VALUE SPACES.
           05  WS-856-ORIGIN-INFO.
               10  WS-856-ORIGIN-NAME PIC X(35)    VALUE SPACES.
               10  WS-856-ORIGIN-CITY PIC X(30)    VALUE SPACES.
               10  WS-856-ORIG-STATE  PIC X(02)    VALUE SPACES.
               10  WS-856-ORIG-ZIP    PIC X(09)    VALUE SPACES.
               10  WS-856-ORIG-COUNTRY PIC X(03)   VALUE 'US '.
           05  WS-856-DEST-INFO.
               10  WS-856-DEST-DEALER PIC X(05)    VALUE SPACES.
               10  WS-856-DEST-NAME   PIC X(35)    VALUE SPACES.
               10  WS-856-DEST-ADDR   PIC X(40)    VALUE SPACES.
               10  WS-856-DEST-CITY   PIC X(30)    VALUE SPACES.
               10  WS-856-DEST-STATE  PIC X(02)    VALUE SPACES.
               10  WS-856-DEST-ZIP    PIC X(09)    VALUE SPACES.
               10  WS-856-DEST-COUNTRY PIC X(03)   VALUE 'US '.
           05  WS-856-VEHICLE-COUNT   PIC S9(04)   COMP
                                                    VALUE +0.
      *
      *    EDI 856 VEHICLE DETAIL (REPEATING FOR EACH VEHICLE)
      *
       01  WS-856-VEHICLE-DETAIL.
           05  WS-856-VEH-SEQ         PIC 9(03)    VALUE ZEROS.
           05  WS-856-VEH-VIN         PIC X(17)    VALUE SPACES.
           05  WS-856-VEH-MAKE        PIC X(10)    VALUE SPACES.
           05  WS-856-VEH-MODEL       PIC X(20)    VALUE SPACES.
           05  WS-856-VEH-YEAR        PIC 9(04)    VALUE ZEROS.
           05  WS-856-VEH-TRIM        PIC X(15)    VALUE SPACES.
           05  WS-856-VEH-EXT-COLOR   PIC X(15)    VALUE SPACES.
           05  WS-856-VEH-INT-COLOR   PIC X(15)    VALUE SPACES.
           05  WS-856-VEH-ENGINE      PIC X(10)    VALUE SPACES.
           05  WS-856-VEH-TRANS       PIC X(10)    VALUE SPACES.
           05  WS-856-VEH-INVOICE-AMT PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-856-VEH-MSRP        PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-856-VEH-ORDER-NUM   PIC X(12)    VALUE SPACES.
      *
      *    EDI PROCESSING CONTROL FIELDS
      *
       01  WS-EDI-CONTROL.
           05  WS-EDI-DIRECTION       PIC X(01)    VALUE SPACES.
               88  WS-EDI-INBOUND                  VALUE 'I'.
               88  WS-EDI-OUTBOUND                 VALUE 'O'.
           05  WS-EDI-PARTNER-ID      PIC X(15)    VALUE SPACES.
           05  WS-EDI-SEGMENT-COUNT   PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-EDI-RECORD-COUNT    PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-EDI-ERROR-COUNT     PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-EDI-ELEMENT-SEP     PIC X(01)    VALUE '*'.
           05  WS-EDI-SEGMENT-TERM    PIC X(01)    VALUE '~'.
      *
      *    EDI WORK BUFFER
      *
       01  WS-EDI-WORK-BUFFER         PIC X(512)   VALUE SPACES.
       01  WS-EDI-BUFFER-LENGTH       PIC S9(04)   COMP
                                                    VALUE +0.
      ****************************************************************
      * END OF WSEDI000                                              *
      ****************************************************************
