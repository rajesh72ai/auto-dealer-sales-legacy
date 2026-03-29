      ****************************************************************
      * COPYBOOK: WSPARAM                                          *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING  *
      * PURPOSE:  SHARED PARAMETER AREA FOR CALL INTERFACES        *
      *           BETWEEN CALLING AND CALLED PROGRAMS               *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                       *
      * DATE:     2026-03-29                                       *
      * NOTES:    ALL INTER-PROGRAM COMMUNICATION USES THE COMMON  *
      *           PARM-AREA HEADER PLUS FUNCTION-SPECIFIC BLOCKS.  *
      *           CALLING PROGRAMS SET WS-CALL-FUNCTION AND THE    *
      *           APPROPRIATE PARAMETER BLOCK BEFORE THE CALL.     *
      ****************************************************************
      *
      *    COMMON PARAMETER AREA HEADER
      *
       01  WS-PARM-AREA.
           05  WS-PARM-HEADER.
               10  WS-CALL-FUNCTION   PIC X(04)    VALUE SPACES.
                   88  WS-FUNC-INIT                VALUE 'INIT'.
                   88  WS-FUNC-PROCESS             VALUE 'PROC'.
                   88  WS-FUNC-TERM                VALUE 'TERM'.
                   88  WS-FUNC-VALIDATE            VALUE 'VALD'.
                   88  WS-FUNC-CALCULATE           VALUE 'CALC'.
                   88  WS-FUNC-FORMAT              VALUE 'FRMT'.
                   88  WS-FUNC-LOOKUP              VALUE 'LKUP'.
               10  WS-CALL-STATUS     PIC X(02)    VALUE SPACES.
                   88  WS-CALL-OK                  VALUE '00'.
                   88  WS-CALL-WARNING             VALUE '04'.
                   88  WS-CALL-ERROR               VALUE '08'.
                   88  WS-CALL-SEVERE              VALUE '16'.
               10  WS-CALL-PROGRAM    PIC X(08)    VALUE SPACES.
               10  WS-CALL-MSG        PIC X(79)    VALUE SPACES.
               10  WS-CALL-DEALER     PIC X(05)    VALUE SPACES.
               10  WS-CALL-USER       PIC X(08)    VALUE SPACES.
               10  WS-CALL-TIMESTAMP  PIC X(26)    VALUE SPACES.
      *
      *    TAX CALCULATION PARAMETER BLOCK
      *    (CALLED MODULE: ASTAXC00)
      *
       01  WS-TAX-CALC-PARMS.
           05  WS-TAX-FUNCTION        PIC X(04)    VALUE SPACES.
               88  WS-TAX-CALC-SALES               VALUE 'SLST'.
               88  WS-TAX-CALC-LUXURY              VALUE 'LUXT'.
               88  WS-TAX-CALC-FET                 VALUE 'FETT'.
               88  WS-TAX-CALC-ALL                 VALUE 'ALLT'.
           05  WS-TAX-STATE-CODE      PIC X(02)    VALUE SPACES.
           05  WS-TAX-COUNTY-CODE     PIC X(05)    VALUE SPACES.
           05  WS-TAX-CITY-CODE       PIC X(05)    VALUE SPACES.
           05  WS-TAX-VEHICLE-TYPE    PIC X(02)    VALUE SPACES.
               88  WS-TAX-NEW-VEHICLE              VALUE 'NW'.
               88  WS-TAX-USED-VEHICLE             VALUE 'US'.
               88  WS-TAX-DEMO                     VALUE 'DM'.
           05  WS-TAX-TAXABLE-AMT     PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-TAX-TRADE-ALLOW     PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-TAX-NET-TAXABLE     PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-TAX-RESULTS.
               10  WS-TAX-STATE-RATE  PIC S9(03)V9(04) COMP-3
                                                    VALUE +0.
               10  WS-TAX-STATE-AMT   PIC S9(09)V99 COMP-3
                                                    VALUE +0.
               10  WS-TAX-COUNTY-RATE PIC S9(03)V9(04) COMP-3
                                                    VALUE +0.
               10  WS-TAX-COUNTY-AMT  PIC S9(09)V99 COMP-3
                                                    VALUE +0.
               10  WS-TAX-CITY-RATE   PIC S9(03)V9(04) COMP-3
                                                    VALUE +0.
               10  WS-TAX-CITY-AMT    PIC S9(09)V99 COMP-3
                                                    VALUE +0.
               10  WS-TAX-LUXURY-AMT  PIC S9(09)V99 COMP-3
                                                    VALUE +0.
               10  WS-TAX-FET-AMT     PIC S9(09)V99 COMP-3
                                                    VALUE +0.
               10  WS-TAX-TOTAL-AMT   PIC S9(09)V99 COMP-3
                                                    VALUE +0.
      *
      *    VEHICLE PRICING PARAMETER BLOCK
      *    (CALLED MODULE: ASPRCC00)
      *
       01  WS-PRICING-PARMS.
           05  WS-PRC-FUNCTION        PIC X(04)    VALUE SPACES.
               88  WS-PRC-CALC-MSRP               VALUE 'MSRP'.
               88  WS-PRC-CALC-INVOICE             VALUE 'INVC'.
               88  WS-PRC-CALC-DEAL                VALUE 'DEAL'.
               88  WS-PRC-HOLDBACK                 VALUE 'HLBK'.
           05  WS-PRC-VIN             PIC X(17)    VALUE SPACES.
           05  WS-PRC-STOCK-NUM       PIC X(10)    VALUE SPACES.
           05  WS-PRC-BASE-MSRP       PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-DEST-CHARGE     PIC S9(05)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-OPTIONS-TOTAL   PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-TOTAL-MSRP      PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-INVOICE-AMT     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-HOLDBACK-AMT    PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-DEALER-COST     PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-REBATE-AMT      PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-NET-PRICE       PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-MARGIN-AMT      PIC S9(07)V99 COMP-3
                                                    VALUE +0.
           05  WS-PRC-MARGIN-PCT      PIC S9(03)V99 COMP-3
                                                    VALUE +0.
      *
      *    DATE UTILITY PARAMETER BLOCK
      *    (CALLED MODULE: ASDTUT00)
      *
       01  WS-DATE-UTIL-PARMS.
           05  WS-DTU-FUNCTION        PIC X(04)    VALUE SPACES.
               88  WS-DTU-FORMAT                   VALUE 'FRMT'.
               88  WS-DTU-VALIDATE                 VALUE 'VALD'.
               88  WS-DTU-DIFF                     VALUE 'DIFF'.
               88  WS-DTU-ADD-DAYS                 VALUE 'ADDD'.
               88  WS-DTU-DAY-OF-WEEK              VALUE 'DOWK'.
               88  WS-DTU-JULIAN                   VALUE 'JULN'.
           05  WS-DTU-INPUT-DATE-1    PIC X(10)    VALUE SPACES.
           05  WS-DTU-INPUT-DATE-2    PIC X(10)    VALUE SPACES.
           05  WS-DTU-INPUT-FORMAT    PIC X(04)    VALUE 'CCYY'.
               88  WS-DTU-FMT-CCYYMMDD            VALUE 'CCYY'.
               88  WS-DTU-FMT-MMDDYYYY            VALUE 'MMDD'.
               88  WS-DTU-FMT-JULIAN               VALUE 'JULN'.
           05  WS-DTU-OUTPUT-DATE     PIC X(10)    VALUE SPACES.
           05  WS-DTU-OUTPUT-JULIAN   PIC 9(07)    VALUE ZEROS.
           05  WS-DTU-DAYS-DIFF       PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-DTU-ADD-DAYS-NUM    PIC S9(07)   COMP-3
                                                    VALUE +0.
           05  WS-DTU-DAY-NUM         PIC 9(01)    VALUE ZERO.
           05  WS-DTU-DAY-NAME        PIC X(09)    VALUE SPACES.
      *
      *    VIN VALIDATION PARAMETER BLOCK
      *    (CALLED MODULE: ASVINV00)
      *
       01  WS-VIN-VALID-PARMS.
           05  WS-VIN-INPUT           PIC X(17)    VALUE SPACES.
           05  WS-VIN-VALID-FLAG      PIC X(01)    VALUE SPACES.
               88  WS-VIN-IS-VALID                 VALUE 'Y'.
               88  WS-VIN-IS-INVALID               VALUE 'N'.
           05  WS-VIN-ERROR-MSG       PIC X(50)    VALUE SPACES.
           05  WS-VIN-DECODED.
               10  WS-VIN-WMI         PIC X(03)    VALUE SPACES.
               10  WS-VIN-VDS         PIC X(05)    VALUE SPACES.
               10  WS-VIN-CHECK-DIGIT PIC X(01)    VALUE SPACES.
               10  WS-VIN-VIS         PIC X(08)    VALUE SPACES.
               10  WS-VIN-YEAR-CODE   PIC X(01)    VALUE SPACES.
               10  WS-VIN-PLANT-CODE  PIC X(01)    VALUE SPACES.
               10  WS-VIN-SEQ-NUM     PIC X(06)    VALUE SPACES.
           05  WS-VIN-MANUFACTURER    PIC X(30)    VALUE SPACES.
           05  WS-VIN-MODEL-YEAR      PIC 9(04)    VALUE ZEROS.
           05  WS-VIN-ASSEMBLY-PLANT  PIC X(30)    VALUE SPACES.
      *
      *    DEALER LOOKUP PARAMETER BLOCK
      *    (CALLED MODULE: ASDLRL00)
      *
       01  WS-DEALER-LOOKUP-PARMS.
           05  WS-DLR-FUNCTION        PIC X(04)    VALUE SPACES.
               88  WS-DLR-BY-CODE                  VALUE 'CODE'.
               88  WS-DLR-BY-NAME                  VALUE 'NAME'.
               88  WS-DLR-BY-REGION                VALUE 'REGN'.
           05  WS-DLR-INPUT-CODE      PIC X(05)    VALUE SPACES.
           05  WS-DLR-INPUT-NAME      PIC X(40)    VALUE SPACES.
           05  WS-DLR-INPUT-REGION    PIC X(03)    VALUE SPACES.
           05  WS-DLR-FOUND-FLAG      PIC X(01)    VALUE 'N'.
               88  WS-DLR-FOUND                    VALUE 'Y'.
               88  WS-DLR-NOT-FOUND                VALUE 'N'.
           05  WS-DLR-RESULT-COUNT    PIC S9(04)   COMP
                                                    VALUE +0.
      ****************************************************************
      * END OF WSPARAM                                               *
      ****************************************************************
