       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSHIS00.
      ****************************************************************
      * PROGRAM:  CUSHIS00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   CUSTOMER - PURCHASE HISTORY                        *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DISPLAYS CUSTOMER PURCHASE HISTORY BY QUERYING     *
      *           SALES_DEAL JOINED WITH VEHICLE. LISTS DEAL DATE,   *
      *           VIN, YEAR/MAKE/MODEL, DEAL TYPE, SALE PRICE, AND   *
      *           TRADE-IN INFO. SHOWS SUMMARY: TOTAL PURCHASES,     *
      *           TOTAL SPENT, AVERAGE DEAL VALUE. INDICATES REPEAT  *
      *           BUYER STATUS (>1 PURCHASE).                         *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    CSHI - CUSTOMER HISTORY                            *
      * CALLS:    COMFMTL0 - FORMAT CURRENCY, DATES                 *
      *           COMDTEL0 - DATE UTILITIES                          *
      * TABLES:   AUTOSALE.CUSTOMER (SELECT)                         *
      *           AUTOSALE.SALES_DEAL (SELECT)                       *
      *           AUTOSALE.VEHICLE (JOIN)                            *
      *           AUTOSALE.TRADE_IN (LEFT JOIN)                      *
      ****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-3090.
       OBJECT-COMPUTER. IBM-3090.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       01  WS-PROGRAM-FIELDS.
           05  WS-PROGRAM-NAME           PIC X(08)
                                          VALUE 'CUSHIS00'.
           05  WS-ABEND-CODE             PIC X(04) VALUE SPACES.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
           COPY WSMSGFMT.
      *
      *    DCLGEN COPIES
      *
           COPY DCLCUSTM.
      *
           COPY DCLSLDEL.
      *
           COPY DCLVEHCL.
      *
           COPY DCLTRDEIN.
      *
      *    INPUT FIELDS
      *
       01  WS-HIS-INPUT.
           05  WS-HI-FUNCTION            PIC X(02).
               88  WS-HI-INQUIRY                     VALUE 'IQ'.
           05  WS-HI-CUST-ID             PIC X(09).
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-HIS-OUTPUT.
           05  WS-HO-STATUS-LINE.
               10  WS-HO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-HO-MSG-TEXT       PIC X(70).
           05  WS-HO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-HO-CUST-HEADER.
               10  FILLER               PIC X(35)
                   VALUE '---- PURCHASE HISTORY ----         '.
               10  FILLER               PIC X(44) VALUE SPACES.
           05  WS-HO-CUST-LINE.
               10  FILLER               PIC X(13)
                   VALUE 'CUSTOMER ID: '.
               10  WS-HO-CUST-ID        PIC Z(08)9.
               10  FILLER               PIC X(04) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'NAME: '.
               10  WS-HO-CUST-NAME      PIC X(40).
               10  FILLER               PIC X(06) VALUE SPACES.
           05  WS-HO-REPEAT-LINE.
               10  FILLER               PIC X(08)
                   VALUE 'STATUS: '.
               10  WS-HO-REPEAT-FLAG    PIC X(20).
               10  FILLER               PIC X(51) VALUE SPACES.
           05  WS-HO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-HO-COL-HDR.
               10  FILLER               PIC X(11)
                   VALUE 'DEAL DATE  '.
               10  FILLER               PIC X(18)
                   VALUE 'VIN               '.
               10  FILLER               PIC X(18)
                   VALUE 'YEAR/MAKE/MODEL   '.
               10  FILLER               PIC X(03) VALUE 'TY '.
               10  FILLER               PIC X(14)
                   VALUE 'SALE PRICE    '.
               10  FILLER               PIC X(15)
                   VALUE 'TRADE-IN       '.
           05  WS-HO-SEPARATOR           PIC X(79) VALUE ALL '-'.
           05  WS-HO-DEAL-LINES.
               10  WS-HO-DEAL-LINE      OCCURS 10 TIMES.
                   15  WS-HO-DL-DATE     PIC X(10).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-HO-DL-VIN      PIC X(17).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-HO-DL-YMM      PIC X(17).
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-HO-DL-TYPE     PIC X(01).
                   15  FILLER            PIC X(02) VALUE SPACES.
                   15  WS-HO-DL-PRICE    PIC $ZZZ,ZZ9.99.
                   15  FILLER            PIC X(01) VALUE SPACE.
                   15  WS-HO-DL-TRADE    PIC $ZZZ,ZZ9.99.
                   15  FILLER            PIC X(02) VALUE SPACES.
           05  WS-HO-BLANK-3            PIC X(79) VALUE SPACES.
           05  WS-HO-SUMMARY-HEADER.
               10  FILLER               PIC X(30)
                   VALUE '---- SUMMARY ----             '.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-HO-SUM-LINE1.
               10  FILLER               PIC X(19)
                   VALUE 'TOTAL PURCHASES:   '.
               10  WS-HO-TOTAL-PURCH    PIC Z(04)9.
               10  FILLER               PIC X(55) VALUE SPACES.
           05  WS-HO-SUM-LINE2.
               10  FILLER               PIC X(14)
                   VALUE 'TOTAL SPENT:  '.
               10  WS-HO-TOTAL-SPENT    PIC $Z,ZZZ,ZZ9.99.
               10  FILLER               PIC X(51) VALUE SPACES.
           05  WS-HO-SUM-LINE3.
               10  FILLER               PIC X(14)
                   VALUE 'AVERAGE DEAL: '.
               10  WS-HO-AVG-DEAL       PIC $Z,ZZZ,ZZ9.99.
               10  FILLER               PIC X(51) VALUE SPACES.
           05  WS-HO-FILLER             PIC X(200) VALUE SPACES.
      *
      *    FORMAT CALL FIELDS
      *
       01  WS-FMT-REQUEST.
           05  WS-FMT-FUNCTION          PIC X(04).
           05  WS-FMT-INPUT             PIC X(30).
       01  WS-FMT-RESULT.
           05  WS-FMT-RC                PIC S9(04) COMP.
           05  WS-FMT-OUTPUT            PIC X(40).
      *
      *    DATE CALL FIELDS
      *
       01  WS-DTE-REQUEST.
           05  WS-DTE-FUNCTION          PIC X(04).
           05  WS-DTE-INPUT-DATE        PIC X(10).
       01  WS-DTE-RESULT.
           05  WS-DTE-RC                PIC S9(04) COMP.
           05  WS-DTE-OUTPUT            PIC X(20).
      *
      *    WORKING FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-RETURN-CODE           PIC S9(04) COMP VALUE +0.
           05  WS-CUST-ID-NUM           PIC S9(09) COMP VALUE +0.
           05  WS-DEAL-IDX              PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-PURCHASES       PIC S9(04) COMP VALUE +0.
           05  WS-TOTAL-SPENT           PIC S9(09)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-AVERAGE-DEAL          PIC S9(09)V9(2) COMP-3
                                                     VALUE +0.
           05  WS-CUST-FIRST            PIC X(30)  VALUE SPACES.
           05  WS-CUST-LAST             PIC X(30)  VALUE SPACES.
      *
      *    CURSOR FETCH FIELDS
      *
       01  WS-CF-DEAL.
           05  WS-CF-DEAL-DATE          PIC X(10).
           05  WS-CF-VIN                PIC X(17).
           05  WS-CF-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-CF-MAKE-CODE          PIC X(03).
           05  WS-CF-MODEL-CODE         PIC X(06).
           05  WS-CF-DEAL-TYPE          PIC X(01).
           05  WS-CF-TOTAL-PRICE        PIC S9(09)V9(2) COMP-3.
           05  WS-CF-TRADE-ALLOW        PIC S9(09)V9(2) COMP-3.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-DEAL-DATE          PIC S9(04) COMP VALUE +0.
           05  WS-NI-TRADE-ALLOW        PIC S9(04) COMP VALUE +0.
      *
      *    YEAR/MAKE/MODEL WORK FIELD
      *
       01  WS-YMM-WORK                  PIC X(17)  VALUE SPACES.
       01  WS-YEAR-DISP                 PIC 9(04).
      *
      *    CURSOR FOR PURCHASE HISTORY
      *
           EXEC SQL
               DECLARE CSR_PURCH_HIST CURSOR FOR
               SELECT SD.DEAL_DATE
                    , SD.VIN
                    , V.MODEL_YEAR
                    , V.MAKE_CODE
                    , V.MODEL_CODE
                    , SD.DEAL_TYPE
                    , SD.TOTAL_PRICE
                    , SD.TRADE_ALLOW
               FROM   AUTOSALE.SALES_DEAL SD
                    , AUTOSALE.VEHICLE V
               WHERE  SD.CUSTOMER_ID = :WS-CUST-ID-NUM
                 AND  V.VIN          = SD.VIN
                 AND  SD.DEAL_STATUS IN ('CL', 'DL', 'AP')
               ORDER BY SD.DEAL_DATE DESC
           END-EXEC.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-PCB-STATUS             PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-PCB-MOD-NAME           PIC X(08).
           05  IO-PCB-USER-ID            PIC X(08).
      *
       01  DB-PCB-1.
           05  FILLER                    PIC X(22).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF WS-RETURN-CODE = +0
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 4000-FETCH-CUSTOMER
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-FETCH-HISTORY
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-COMPUTE-SUMMARY
           END-IF
      *
           PERFORM 9000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE                                           *
      ****************************************************************
       1000-INITIALIZE.
      *
           MOVE +0 TO WS-RETURN-CODE
           INITIALIZE WS-HIS-OUTPUT
           MOVE 'CUSHIS00' TO WS-HO-MSG-ID
           MOVE +0 TO WS-TOTAL-PURCHASES
           MOVE +0 TO WS-TOTAL-SPENT
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT                                        *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'IMS GU FAILED - UNABLE TO RECEIVE INPUT'
                   TO WS-HO-MSG-TEXT
           ELSE
               MOVE WS-INP-FUNCTION      TO WS-HI-FUNCTION
               MOVE WS-INP-KEY-DATA(1:9) TO WS-HI-CUST-ID
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-HI-FUNCTION = SPACES
               MOVE 'IQ' TO WS-HI-FUNCTION
           END-IF
      *
           IF WS-HI-CUST-ID = SPACES OR ZEROS
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER ID IS REQUIRED' TO WS-HO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           COMPUTE WS-CUST-ID-NUM =
               FUNCTION NUMVAL(WS-HI-CUST-ID)
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-FETCH-CUSTOMER - VERIFY CUSTOMER EXISTS              *
      ****************************************************************
       4000-FETCH-CUSTOMER.
      *
           EXEC SQL
               SELECT FIRST_NAME
                    , LAST_NAME
               INTO  :WS-CUST-FIRST
                   , :WS-CUST-LAST
               FROM   AUTOSALE.CUSTOMER
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'CUSTOMER NOT FOUND' TO WS-HO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON CUSTOMER LOOKUP'
                   TO WS-HO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           MOVE WS-CUST-ID-NUM TO WS-HO-CUST-ID
           STRING WS-CUST-LAST  DELIMITED BY '  '
                  ', '           DELIMITED BY SIZE
                  WS-CUST-FIRST  DELIMITED BY '  '
               INTO WS-HO-CUST-NAME
           END-STRING
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-FETCH-HISTORY - GET PURCHASE RECORDS                 *
      ****************************************************************
       5000-FETCH-HISTORY.
      *
           EXEC SQL
               OPEN CSR_PURCH_HIST
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'ERROR OPENING PURCHASE HISTORY CURSOR'
                   TO WS-HO-MSG-TEXT
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-DEAL-IDX
      *
           PERFORM UNTIL WS-DEAL-IDX >= 10
               EXEC SQL
                   FETCH CSR_PURCH_HIST
                   INTO  :WS-CF-DEAL-DATE
                              :WS-NI-DEAL-DATE
                       , :WS-CF-VIN
                       , :WS-CF-MODEL-YEAR
                       , :WS-CF-MAKE-CODE
                       , :WS-CF-MODEL-CODE
                       , :WS-CF-DEAL-TYPE
                       , :WS-CF-TOTAL-PRICE
                       , :WS-CF-TRADE-ALLOW
               END-EXEC
      *
               IF SQLCODE = +100
                   EXIT PERFORM
               END-IF
      *
               IF SQLCODE NOT = +0
                   EXIT PERFORM
               END-IF
      *
               ADD +1 TO WS-DEAL-IDX
      *
      *        FORMAT DEAL DATE
      *
               IF WS-NI-DEAL-DATE >= +0
                   MOVE WS-CF-DEAL-DATE TO
                       WS-HO-DL-DATE(WS-DEAL-IDX)
               ELSE
                   MOVE 'N/A       ' TO
                       WS-HO-DL-DATE(WS-DEAL-IDX)
               END-IF
      *
               MOVE WS-CF-VIN TO WS-HO-DL-VIN(WS-DEAL-IDX)
      *
      *        BUILD YEAR/MAKE/MODEL
      *
               MOVE WS-CF-MODEL-YEAR TO WS-YEAR-DISP
               INITIALIZE WS-YMM-WORK
               STRING WS-YEAR-DISP  DELIMITED BY SIZE
                      ' '           DELIMITED BY SIZE
                      WS-CF-MAKE-CODE DELIMITED BY '  '
                      ' '           DELIMITED BY SIZE
                      WS-CF-MODEL-CODE DELIMITED BY '  '
                   INTO WS-YMM-WORK
               END-STRING
               MOVE WS-YMM-WORK TO WS-HO-DL-YMM(WS-DEAL-IDX)
      *
               MOVE WS-CF-DEAL-TYPE TO
                   WS-HO-DL-TYPE(WS-DEAL-IDX)
      *
      *        FORMAT CURRENCY
      *
               MOVE WS-CF-TOTAL-PRICE TO
                   WS-HO-DL-PRICE(WS-DEAL-IDX)
      *
               IF WS-CF-TRADE-ALLOW > +0
                   MOVE WS-CF-TRADE-ALLOW TO
                       WS-HO-DL-TRADE(WS-DEAL-IDX)
               ELSE
                   MOVE +0 TO WS-HO-DL-TRADE(WS-DEAL-IDX)
               END-IF
      *
      *        ACCUMULATE TOTALS
      *
               ADD +1 TO WS-TOTAL-PURCHASES
               ADD WS-CF-TOTAL-PRICE TO WS-TOTAL-SPENT
           END-PERFORM
      *
           EXEC SQL
               CLOSE CSR_PURCH_HIST
           END-EXEC
      *
           IF WS-DEAL-IDX = +0
               MOVE 'NO PURCHASE HISTORY FOUND FOR THIS CUSTOMER'
                   TO WS-HO-MSG-TEXT
               MOVE 'FIRST-TIME BUYER' TO WS-HO-REPEAT-FLAG
           ELSE
               MOVE 'PURCHASE HISTORY DISPLAYED'
                   TO WS-HO-MSG-TEXT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    6000-COMPUTE-SUMMARY                                      *
      ****************************************************************
       6000-COMPUTE-SUMMARY.
      *
      *    ALSO GET FULL COUNT (CURSOR MAY HAVE BEEN LIMITED TO 10)
      *
           EXEC SQL
               SELECT COUNT(*)
                    , COALESCE(SUM(TOTAL_PRICE), 0)
               INTO  :WS-TOTAL-PURCHASES
                   , :WS-TOTAL-SPENT
               FROM   AUTOSALE.SALES_DEAL
               WHERE  CUSTOMER_ID = :WS-CUST-ID-NUM
                 AND  DEAL_STATUS IN ('CL', 'DL', 'AP')
           END-EXEC
      *
           MOVE WS-TOTAL-PURCHASES TO WS-HO-TOTAL-PURCH
           MOVE WS-TOTAL-SPENT    TO WS-HO-TOTAL-SPENT
      *
           IF WS-TOTAL-PURCHASES > +0
               COMPUTE WS-AVERAGE-DEAL =
                   WS-TOTAL-SPENT / WS-TOTAL-PURCHASES
               MOVE WS-AVERAGE-DEAL TO WS-HO-AVG-DEAL
           ELSE
               MOVE +0 TO WS-HO-AVG-DEAL
           END-IF
      *
      *    DETERMINE REPEAT BUYER STATUS
      *
           IF WS-TOTAL-PURCHASES > 1
               MOVE 'REPEAT BUYER' TO WS-HO-REPEAT-FLAG
           ELSE
               IF WS-TOTAL-PURCHASES = 1
                   MOVE 'SINGLE PURCHASE' TO WS-HO-REPEAT-FLAG
               ELSE
                   MOVE 'NO PURCHASES' TO WS-HO-REPEAT-FLAG
               END-IF
           END-IF
      *
      *    FORMAT DATES VIA COMDTEL0
      *
           MOVE 'FMTD' TO WS-DTE-FUNCTION
           CALL 'COMDTEL0' USING WS-DTE-REQUEST
                                  WS-DTE-RESULT
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-HIS-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'CSHI' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF CUSHIS00                                              *
      ****************************************************************
