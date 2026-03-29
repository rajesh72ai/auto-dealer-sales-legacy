      ****************************************************************
      * COPYBOOK: WSWRC000                                         *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  WARRANTY AND RECALL DATA AREAS FOR CLAIM         *
      *           PROCESSING, RECALL CAMPAIGNS, AND NOTIFICATIONS   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      ****************************************************************
      *
      *    WARRANTY CLAIM RECORD
      *
       01  WS-WARRANTY-RECORD.
           05  WS-WRC-CLAIM-NUMBER    PIC X(12)    VALUE SPACES.
           05  WS-WRC-DEALER-CODE     PIC X(05)    VALUE SPACES.
           05  WS-WRC-VIN             PIC X(17)    VALUE SPACES.
           05  WS-WRC-CLAIM-DATE      PIC X(10)    VALUE SPACES.
           05  WS-WRC-REPAIR-DATE     PIC X(10)    VALUE SPACES.
           05  WS-WRC-MILEAGE         PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-WRC-CLAIM-TYPE      PIC X(02)    VALUE SPACES.
               88  WS-WRC-BASIC                    VALUE 'BA'.
               88  WS-WRC-POWERTRAIN               VALUE 'PT'.
               88  WS-WRC-EXTENDED                 VALUE 'EX'.
               88  WS-WRC-GOODWILL                 VALUE 'GW'.
               88  WS-WRC-RECALL                   VALUE 'RC'.
               88  WS-WRC-CAMPAIGN                 VALUE 'CM'.
               88  WS-WRC-PREDELIVERY              VALUE 'PD'.
           05  WS-WRC-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-WRC-SUBMITTED                VALUE 'SB'.
               88  WS-WRC-IN-REVIEW                VALUE 'IR'.
               88  WS-WRC-APPROVED                 VALUE 'AP'.
               88  WS-WRC-PARTIAL-APR              VALUE 'PA'.
               88  WS-WRC-DENIED                   VALUE 'DN'.
               88  WS-WRC-PAID                     VALUE 'PD'.
               88  WS-WRC-APPEALED                 VALUE 'AL'.
               88  WS-WRC-VOID                     VALUE 'VD'.
           05  WS-WRC-CAUSAL-PART     PIC X(12)    VALUE SPACES.
           05  WS-WRC-COMPLAINT-CODE  PIC X(04)    VALUE SPACES.
           05  WS-WRC-CORRECTION-CODE PIC X(04)    VALUE SPACES.
           05  WS-WRC-OP-CODE         PIC X(06)    VALUE SPACES.
           05  WS-WRC-LABOR-HOURS     PIC S9(03)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-LABOR-RATE      PIC S9(05)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-LABOR-AMT       PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-PARTS-AMT       PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-SUBLET-AMT      PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-OTHER-AMT       PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-TOTAL-CLAIM     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-APPROVED-AMT    PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-WRC-TECHNICIAN-ID   PIC X(08)    VALUE SPACES.
           05  WS-WRC-SERVICE-ADVISOR PIC X(08)    VALUE SPACES.
           05  WS-WRC-CUSTOMER-CONCERN PIC X(80)   VALUE SPACES.
           05  WS-WRC-CORRECTION-DESC PIC X(80)    VALUE SPACES.
           05  WS-WRC-DENIAL-REASON   PIC X(40)    VALUE SPACES.
      *
      *    RECALL CAMPAIGN RECORD
      *
       01  WS-RECALL-CAMPAIGN.
           05  WS-RCL-CAMPAIGN-NUM    PIC X(10)    VALUE SPACES.
           05  WS-RCL-NHTSA-NUM       PIC X(12)    VALUE SPACES.
           05  WS-RCL-DESCRIPTION     PIC X(80)    VALUE SPACES.
           05  WS-RCL-EFFECTIVE-DATE  PIC X(10)    VALUE SPACES.
           05  WS-RCL-EXPIRY-DATE     PIC X(10)    VALUE SPACES.
           05  WS-RCL-SEVERITY        PIC X(01)    VALUE SPACES.
               88  WS-RCL-SAFETY-CRITICAL          VALUE 'C'.
               88  WS-RCL-SAFETY-RECALL            VALUE 'S'.
               88  WS-RCL-EMISSIONS                VALUE 'E'.
               88  WS-RCL-SERVICE-CAMP             VALUE 'V'.
               88  WS-RCL-CUSTOMER-SAT             VALUE 'A'.
           05  WS-RCL-AFFECTED-MODELS PIC X(40)    VALUE SPACES.
           05  WS-RCL-AFFECTED-YEARS  PIC X(20)    VALUE SPACES.
           05  WS-RCL-AFFECTED-VINS.
               10  WS-RCL-VIN-FROM    PIC X(17)    VALUE SPACES.
               10  WS-RCL-VIN-TO      PIC X(17)    VALUE SPACES.
           05  WS-RCL-REMEDY-TYPE     PIC X(02)    VALUE SPACES.
               88  WS-RCL-REPAIR                   VALUE 'RP'.
               88  WS-RCL-REPLACE                  VALUE 'RC'.
               88  WS-RCL-INSPECT                  VALUE 'IN'.
               88  WS-RCL-REPROGRAM                VALUE 'RG'.
           05  WS-RCL-EST-LABOR-HOURS PIC S9(03)V99 COMP-3
                                                    VALUE +0.
           05  WS-RCL-PARTS-REQUIRED  PIC X(01)    VALUE 'N'.
               88  WS-RCL-PARTS-YES               VALUE 'Y'.
               88  WS-RCL-PARTS-NO                VALUE 'N'.
           05  WS-RCL-PARTS-AVAIL     PIC X(01)    VALUE 'N'.
               88  WS-RCL-PARTS-AVAILABLE          VALUE 'Y'.
               88  WS-RCL-PARTS-BACKORDERED        VALUE 'N'.
           05  WS-RCL-TOTAL-AFFECTED  PIC S9(09)   COMP
                                                    VALUE +0.
           05  WS-RCL-TOTAL-COMPLETED PIC S9(09)   COMP
                                                    VALUE +0.
           05  WS-RCL-COMPLETION-PCT  PIC S9(03)V99 COMP-3
                                                    VALUE +0.
           05  WS-RCL-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-RCL-ACTIVE                   VALUE 'AC'.
               88  WS-RCL-SUSPENDED                VALUE 'SU'.
               88  WS-RCL-COMPLETED                VALUE 'CP'.
               88  WS-RCL-EXPIRED                  VALUE 'EX'.
      *
      *    RECALL NOTIFICATION RECORD
      *
       01  WS-RECALL-NOTIFICATION.
           05  WS-RNF-NOTIFICATION-ID PIC X(12)    VALUE SPACES.
           05  WS-RNF-CAMPAIGN-NUM    PIC X(10)    VALUE SPACES.
           05  WS-RNF-VIN             PIC X(17)    VALUE SPACES.
           05  WS-RNF-CUSTOMER-ID     PIC X(10)    VALUE SPACES.
           05  WS-RNF-CUSTOMER-NAME   PIC X(40)    VALUE SPACES.
           05  WS-RNF-ADDR-LINE-1     PIC X(40)    VALUE SPACES.
           05  WS-RNF-ADDR-LINE-2     PIC X(40)    VALUE SPACES.
           05  WS-RNF-CITY            PIC X(30)    VALUE SPACES.
           05  WS-RNF-STATE           PIC X(02)    VALUE SPACES.
           05  WS-RNF-ZIP             PIC X(09)    VALUE SPACES.
           05  WS-RNF-PHONE           PIC X(15)    VALUE SPACES.
           05  WS-RNF-EMAIL           PIC X(60)    VALUE SPACES.
           05  WS-RNF-NOTIFY-METHOD   PIC X(02)    VALUE SPACES.
               88  WS-RNF-BY-MAIL                  VALUE 'ML'.
               88  WS-RNF-BY-PHONE                 VALUE 'PH'.
               88  WS-RNF-BY-EMAIL                 VALUE 'EM'.
               88  WS-RNF-ALL-METHODS              VALUE 'AL'.
           05  WS-RNF-NOTIFY-DATE     PIC X(10)    VALUE SPACES.
           05  WS-RNF-FIRST-NOTICE    PIC X(10)    VALUE SPACES.
           05  WS-RNF-SECOND-NOTICE   PIC X(10)    VALUE SPACES.
           05  WS-RNF-THIRD-NOTICE    PIC X(10)    VALUE SPACES.
           05  WS-RNF-NOTICE-COUNT    PIC S9(02)   COMP
                                                    VALUE +0.
           05  WS-RNF-STATUS          PIC X(02)    VALUE SPACES.
               88  WS-RNF-PENDING                  VALUE 'PN'.
               88  WS-RNF-SENT                     VALUE 'ST'.
               88  WS-RNF-APPT-SCHED              VALUE 'AS'.
               88  WS-RNF-COMPLETED                VALUE 'CP'.
               88  WS-RNF-UNDELIVERABLE            VALUE 'UD'.
               88  WS-RNF-OWNER-CHANGE             VALUE 'OC'.
           05  WS-RNF-ASSIGNED-DEALER PIC X(05)    VALUE SPACES.
           05  WS-RNF-APPT-DATE       PIC X(10)    VALUE SPACES.
           05  WS-RNF-COMPLETION-DATE PIC X(10)    VALUE SPACES.
           05  WS-RNF-CLAIM-NUMBER    PIC X(12)    VALUE SPACES.
      ****************************************************************
      * END OF WSWRC000                                              *
      ****************************************************************
