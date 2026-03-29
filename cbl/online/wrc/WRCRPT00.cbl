       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRCRPT00.
      ****************************************************************
      * PROGRAM:  WRCRPT00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   WRC - WARRANTY CLAIMS SUMMARY REPORT               *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  ONLINE SUMMARY REPORT OF WARRANTY CLAIMS FOR A     *
      *           DEALER. ACCEPTS DEALER CODE AND OPTIONAL DATE      *
      *           RANGE, QUERIES WARRANTY_CLAIM TABLE, AND RETURNS   *
      *           TOTALS BY CLAIM TYPE WITH COUNTS AND DOLLAR        *
      *           AMOUNTS. INCLUDES APPROVED/DENIED BREAKDOWNS,      *
      *           GRAND TOTALS, AND AVERAGE CLAIM AMOUNT.            *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    WRRT - WARRANTY CLAIMS REPORT                      *
      * MFS MOD:  ASWRRT00                                           *
      * TABLES:   AUTOSALE.WARRANTY_CLAIM (READ)                     *
      *           AUTOSALE.DEALER         (READ)                     *
      * CALLS:    COMFMTL0 - FIELD FORMATTING                        *
      *           COMDBEL0 - DB2 ERROR HANDLER                       *
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
                                          VALUE 'WRCRPT00'.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASWRRT00'.
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
           COPY WSSQLCA.
      *
           COPY WSIOPCB.
      *
      *    INPUT MESSAGE AREA (FROM MFS)
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
           05  WS-IN-FROM-DATE           PIC X(10).
           05  WS-IN-TO-DATE             PIC X(10).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
      *    DEALER INFO
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-DEALER-NAME        PIC X(40).
           05  WS-OUT-DATE-RANGE         PIC X(25).
      *    SUMMARY LINES BY CLAIM TYPE (7 TYPES MAX)
           05  WS-OUT-TYPE-COUNT         PIC S9(04) COMP.
           05  WS-OUT-TYPE-DTL OCCURS 7 TIMES.
               10  WS-OUT-CT-DESC        PIC X(14).
               10  WS-OUT-CT-CLAIMS      PIC Z(5)9.
               10  WS-OUT-CT-LABOR       PIC Z(8)9.99.
               10  WS-OUT-CT-PARTS       PIC Z(8)9.99.
               10  WS-OUT-CT-TOTAL       PIC Z(8)9.99.
               10  WS-OUT-CT-APPROVED    PIC Z(5)9.
               10  WS-OUT-CT-DENIED      PIC Z(5)9.
      *    GRAND TOTALS
           05  WS-OUT-GRAND-CLAIMS       PIC Z(6)9.
           05  WS-OUT-GRAND-LABOR        PIC Z(9)9.99.
           05  WS-OUT-GRAND-PARTS        PIC Z(9)9.99.
           05  WS-OUT-GRAND-TOTAL        PIC Z(9)9.99.
           05  WS-OUT-GRAND-APPROVED     PIC Z(6)9.
           05  WS-OUT-GRAND-DENIED       PIC Z(6)9.
           05  WS-OUT-AVG-CLAIM          PIC Z(8)9.99.
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-CURRENT-DATE           PIC X(10).
           05  WS-CURRENT-TS             PIC X(26).
           05  WS-ROW-COUNT              PIC S9(04) COMP VALUE +0.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-FROM-DATE              PIC X(10).
           05  WS-TO-DATE                PIC X(10).
           05  WS-DATE-FILTER            PIC X(01)  VALUE 'N'.
               88  WS-USE-DATE-RANGE                VALUE 'Y'.
               88  WS-NO-DATE-RANGE                 VALUE 'N'.
      *
      *    ACCUMULATOR FIELDS
      *
       01  WS-ACCUMULATORS.
           05  WS-GRAND-CLAIMS           PIC S9(07) COMP VALUE +0.
           05  WS-GRAND-LABOR            PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-GRAND-PARTS            PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-GRAND-TOTAL            PIC S9(09)V99 COMP-3
                                                    VALUE +0.
           05  WS-GRAND-APPROVED         PIC S9(07) COMP VALUE +0.
           05  WS-GRAND-DENIED           PIC S9(07) COMP VALUE +0.
           05  WS-AVG-CLAIM              PIC S9(09)V99 COMP-3
                                                    VALUE +0.
      *
      *    DB2 HOST VARIABLES - DEALER
      *
       01  WS-HV-DEALER.
           05  WS-HV-DLR-CODE           PIC X(05).
           05  WS-HV-DLR-NAME           PIC X(40).
      *
      *    DB2 HOST VARIABLES - CURSOR FETCH (SUMMARY BY TYPE)
      *
       01  WS-HV-SUMMARY.
           05  WS-HV-SM-CLAIM-TYPE      PIC X(02).
           05  WS-HV-SM-CLAIM-COUNT     PIC S9(07) COMP.
           05  WS-HV-SM-LABOR-TOTAL     PIC S9(09)V99 COMP-3.
           05  WS-HV-SM-PARTS-TOTAL     PIC S9(09)V99 COMP-3.
           05  WS-HV-SM-CLAIM-TOTAL     PIC S9(09)V99 COMP-3.
           05  WS-HV-SM-APPROVED-CT     PIC S9(07) COMP.
           05  WS-HV-SM-DENIED-CT       PIC S9(07) COMP.
      *
      *    CLAIM TYPE DESCRIPTION TABLE
      *
       01  WS-CLAIM-TYPE-TABLE.
           05  FILLER PIC X(16) VALUE 'BABASIC         '.
           05  FILLER PIC X(16) VALUE 'PTPOWERTRAIN    '.
           05  FILLER PIC X(16) VALUE 'EXEXTENDED      '.
           05  FILLER PIC X(16) VALUE 'GWGOODWILL      '.
           05  FILLER PIC X(16) VALUE 'RCRECALL        '.
           05  FILLER PIC X(16) VALUE 'CMCAMPAIGN      '.
           05  FILLER PIC X(16) VALUE 'PDPRE-DELIVERY  '.
       01  WS-CLAIM-TYPE-REDEF REDEFINES WS-CLAIM-TYPE-TABLE.
           05  WS-CTD-ENTRY OCCURS 7 TIMES.
               10  WS-CTD-CODE           PIC X(02).
               10  WS-CTD-DESC           PIC X(14).
      *
       01  WS-CTD-INDEX                  PIC S9(04) COMP VALUE +0.
       01  WS-TYPE-FOUND                 PIC X(14) VALUE SPACES.
      *
      *    FORMAT MODULE LINKAGE
      *
       01  WS-FMT-FUNCTION               PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA        PIC X(40).
           05  WS-FMT-INPUT-NUM          PIC S9(09)V99 COMP-3.
       01  WS-FMT-OUTPUT                 PIC X(40).
       01  WS-FMT-RETURN-CODE            PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG              PIC X(50).
      *
      *    DB ERROR MODULE LINKAGE
      *
       01  WS-DBE-SQLCODE                PIC S9(09) COMP.
       01  WS-DBE-PROGRAM                PIC X(08).
       01  WS-DBE-PARAGRAPH              PIC X(30).
       01  WS-DBE-TABLE-NAME             PIC X(18).
       01  WS-DBE-RETURN-CODE            PIC S9(04) COMP.
      *
      *    CURSOR - CLAIMS SUMMARY BY TYPE (WITH DATE RANGE)
      *
           EXEC SQL DECLARE CSR_CLAIM_RPT CURSOR FOR
               SELECT WC.CLAIM_TYPE
                    , COUNT(*)
                    , SUM(WC.LABOR_AMT)
                    , SUM(WC.PARTS_AMT)
                    , SUM(WC.TOTAL_CLAIM)
                    , SUM(CASE WHEN WC.CLAIM_STATUS IN
                          ('AP', 'PA', 'PD') THEN 1 ELSE 0 END)
                    , SUM(CASE WHEN WC.CLAIM_STATUS = 'DN'
                          THEN 1 ELSE 0 END)
               FROM   AUTOSALE.WARRANTY_CLAIM WC
               WHERE  WC.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  (WC.CLAIM_DATE >= :WS-FROM-DATE
                       OR :WS-DATE-FILTER = 'N')
                 AND  (WC.CLAIM_DATE <= :WS-TO-DATE
                       OR :WS-DATE-FILTER = 'N')
               GROUP BY WC.CLAIM_TYPE
               ORDER BY WC.CLAIM_TYPE
           END-EXEC
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  FILLER                    PIC X(10).
           05  IO-STATUS                 PIC X(02).
           05  FILLER                    PIC X(20).
           05  IO-USER                   PIC X(08).
      *
       01  DB-PCB-1.
           05  DB-1-DBD-NAME            PIC X(08).
           05  DB-1-SEG-LEVEL           PIC X(02).
           05  DB-1-STATUS              PIC X(02).
           05  FILLER                   PIC X(20).
      *
       PROCEDURE DIVISION.
      *
       ENTRY 'DLITCBL' USING IO-PCB, DB-PCB-1.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-RECEIVE-INPUT
      *
           IF IO-STATUS = '  '
               PERFORM 3000-VALIDATE-INPUT
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 4000-VALIDATE-DEALER
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 5000-RETRIEVE-SUMMARY
           END-IF
      *
           IF WS-OUT-MESSAGE = SPACES
               PERFORM 6000-FORMAT-GRAND-TOTALS
           END-IF
      *
           PERFORM 8000-SEND-OUTPUT
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR WORK AREAS                        *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE WS-INPUT-MSG
           INITIALIZE WS-OUTPUT-MSG
           INITIALIZE WS-WORK-FIELDS
           INITIALIZE WS-ACCUMULATORS
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'WARRANTY CLAIMS SUMMARY REPORT'
               TO WS-OUT-TITLE
      *
           EXEC SQL
               SET :WS-CURRENT-TS = CURRENT TIMESTAMP
           END-EXEC
           MOVE WS-CURRENT-TS(1:10) TO WS-CURRENT-DATE
           .
      *
      ****************************************************************
      *    2000-RECEIVE-INPUT - GU CALL ON IO-PCB                    *
      ****************************************************************
       2000-RECEIVE-INPUT.
      *
           CALL 'CBLTDLI' USING WS-GU
                                IO-PCB
                                WS-INPUT-MSG
      *
           IF IO-STATUS NOT = '  '
               MOVE 'WRCRPT00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS AND DATES     *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'DEALER CODE IS REQUIRED FOR CLAIMS REPORT'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
      *    DETERMINE DATE RANGE FILTERING
      *
           IF WS-IN-FROM-DATE NOT = SPACES
           AND WS-IN-TO-DATE NOT = SPACES
               MOVE 'Y' TO WS-DATE-FILTER
               MOVE WS-IN-FROM-DATE TO WS-FROM-DATE
               MOVE WS-IN-TO-DATE TO WS-TO-DATE
      *
      *        VALIDATE FROM-DATE <= TO-DATE
      *
               IF WS-FROM-DATE > WS-TO-DATE
                   MOVE 'FROM DATE MUST BE BEFORE OR EQUAL TO DATE'
                       TO WS-OUT-MESSAGE
                   GO TO 3000-EXIT
               END-IF
      *
               STRING WS-FROM-DATE ' TO ' WS-TO-DATE
                      DELIMITED BY SIZE
                   INTO WS-OUT-DATE-RANGE
               END-STRING
           ELSE
               IF WS-IN-FROM-DATE NOT = SPACES
               AND WS-IN-TO-DATE = SPACES
                   MOVE 'Y' TO WS-DATE-FILTER
                   MOVE WS-IN-FROM-DATE TO WS-FROM-DATE
                   MOVE WS-CURRENT-DATE TO WS-TO-DATE
      *
                   STRING WS-FROM-DATE ' TO ' WS-TO-DATE
                          DELIMITED BY SIZE
                       INTO WS-OUT-DATE-RANGE
                   END-STRING
               ELSE
                   MOVE 'N' TO WS-DATE-FILTER
                   MOVE 'ALL DATES' TO WS-OUT-DATE-RANGE
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-VALIDATE-DEALER - VERIFY DEALER EXISTS               *
      ****************************************************************
       4000-VALIDATE-DEALER.
      *
           EXEC SQL
               SELECT D.DEALER_CODE
                    , D.DEALER_NAME
               INTO  :WS-HV-DLR-CODE
                    , :WS-HV-DLR-NAME
               FROM  AUTOSALE.DEALER D
               WHERE D.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND D.ACTIVE_FLAG = 'Y'
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   MOVE WS-HV-DLR-CODE TO WS-OUT-DEALER-CODE
                   MOVE WS-HV-DLR-NAME TO WS-OUT-DEALER-NAME
               WHEN +100
                   MOVE 'DEALER NOT FOUND OR INACTIVE'
                       TO WS-OUT-MESSAGE
               WHEN OTHER
                   MOVE 'WRCRPT00' TO WS-DBE-PROGRAM
                   MOVE '4000-VALIDATE-DEALER'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.DEALER' TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'WRCRPT00: DB2 ERROR READING DEALER'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5000-RETRIEVE-SUMMARY - OPEN CURSOR AND FETCH ROWS        *
      ****************************************************************
       5000-RETRIEVE-SUMMARY.
      *
           EXEC SQL OPEN CSR_CLAIM_RPT END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'WRCRPT00' TO WS-DBE-PROGRAM
               MOVE '5000-RETRIEVE-SUMMARY'
                   TO WS-DBE-PARAGRAPH
               MOVE 'AUTOSALE.WARRANTY_CLAIM'
                   TO WS-DBE-TABLE-NAME
               MOVE SQLCODE TO WS-DBE-SQLCODE
               CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                    WS-DBE-PROGRAM
                                    WS-DBE-PARAGRAPH
                                    WS-DBE-TABLE-NAME
                                    WS-DBE-RETURN-CODE
               MOVE 'WRCRPT00: ERROR OPENING CLAIMS CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 5000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 5100-FETCH-SUMMARY
               UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +7
      *
           EXEC SQL CLOSE CSR_CLAIM_RPT END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO WARRANTY CLAIMS FOUND FOR THIS DEALER'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-ROW-COUNT TO WS-OUT-TYPE-COUNT
           END-IF
           .
       5000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5100-FETCH-SUMMARY - FETCH ONE SUMMARY ROW PER TYPE       *
      ****************************************************************
       5100-FETCH-SUMMARY.
      *
           EXEC SQL FETCH CSR_CLAIM_RPT
               INTO  :WS-HV-SM-CLAIM-TYPE
                    , :WS-HV-SM-CLAIM-COUNT
                    , :WS-HV-SM-LABOR-TOTAL
                    , :WS-HV-SM-PARTS-TOTAL
                    , :WS-HV-SM-CLAIM-TOTAL
                    , :WS-HV-SM-APPROVED-CT
                    , :WS-HV-SM-DENIED-CT
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   PERFORM 5200-FORMAT-SUMMARY-LINE
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'WRCRPT00' TO WS-DBE-PROGRAM
                   MOVE '5100-FETCH-SUMMARY'
                       TO WS-DBE-PARAGRAPH
                   MOVE 'AUTOSALE.WARRANTY_CLAIM'
                       TO WS-DBE-TABLE-NAME
                   MOVE SQLCODE TO WS-DBE-SQLCODE
                   CALL 'COMDBEL0' USING WS-DBE-SQLCODE
                                        WS-DBE-PROGRAM
                                        WS-DBE-PARAGRAPH
                                        WS-DBE-TABLE-NAME
                                        WS-DBE-RETURN-CODE
                   MOVE 'WRCRPT00: DB2 ERROR READING CLAIMS'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5200-FORMAT-SUMMARY-LINE - FORMAT DETAIL ROW FOR TYPE     *
      ****************************************************************
       5200-FORMAT-SUMMARY-LINE.
      *
      *    LOOKUP CLAIM TYPE DESCRIPTION
      *
           MOVE SPACES TO WS-TYPE-FOUND
           PERFORM VARYING WS-CTD-INDEX FROM +1 BY +1
               UNTIL WS-CTD-INDEX > +7
               IF WS-CTD-CODE(WS-CTD-INDEX) =
                  WS-HV-SM-CLAIM-TYPE
                   MOVE WS-CTD-DESC(WS-CTD-INDEX)
                       TO WS-TYPE-FOUND
               END-IF
           END-PERFORM
           IF WS-TYPE-FOUND = SPACES
               MOVE WS-HV-SM-CLAIM-TYPE TO WS-TYPE-FOUND
           END-IF
      *
           MOVE WS-TYPE-FOUND
               TO WS-OUT-CT-DESC(WS-ROW-COUNT)
           MOVE WS-HV-SM-CLAIM-COUNT
               TO WS-OUT-CT-CLAIMS(WS-ROW-COUNT)
           MOVE WS-HV-SM-LABOR-TOTAL
               TO WS-OUT-CT-LABOR(WS-ROW-COUNT)
           MOVE WS-HV-SM-PARTS-TOTAL
               TO WS-OUT-CT-PARTS(WS-ROW-COUNT)
           MOVE WS-HV-SM-CLAIM-TOTAL
               TO WS-OUT-CT-TOTAL(WS-ROW-COUNT)
           MOVE WS-HV-SM-APPROVED-CT
               TO WS-OUT-CT-APPROVED(WS-ROW-COUNT)
           MOVE WS-HV-SM-DENIED-CT
               TO WS-OUT-CT-DENIED(WS-ROW-COUNT)
      *
      *    ACCUMULATE GRAND TOTALS
      *
           ADD WS-HV-SM-CLAIM-COUNT TO WS-GRAND-CLAIMS
           ADD WS-HV-SM-LABOR-TOTAL TO WS-GRAND-LABOR
           ADD WS-HV-SM-PARTS-TOTAL TO WS-GRAND-PARTS
           ADD WS-HV-SM-CLAIM-TOTAL TO WS-GRAND-TOTAL
           ADD WS-HV-SM-APPROVED-CT TO WS-GRAND-APPROVED
           ADD WS-HV-SM-DENIED-CT   TO WS-GRAND-DENIED
           .
      *
      ****************************************************************
      *    6000-FORMAT-GRAND-TOTALS - COMPUTE AND FORMAT TOTALS      *
      ****************************************************************
       6000-FORMAT-GRAND-TOTALS.
      *
           MOVE WS-GRAND-CLAIMS   TO WS-OUT-GRAND-CLAIMS
           MOVE WS-GRAND-LABOR    TO WS-OUT-GRAND-LABOR
           MOVE WS-GRAND-PARTS    TO WS-OUT-GRAND-PARTS
           MOVE WS-GRAND-TOTAL    TO WS-OUT-GRAND-TOTAL
           MOVE WS-GRAND-APPROVED TO WS-OUT-GRAND-APPROVED
           MOVE WS-GRAND-DENIED   TO WS-OUT-GRAND-DENIED
      *
      *    COMPUTE AVERAGE CLAIM AMOUNT
      *
           IF WS-GRAND-CLAIMS > +0
               COMPUTE WS-AVG-CLAIM =
                   WS-GRAND-TOTAL / WS-GRAND-CLAIMS
               MOVE WS-AVG-CLAIM TO WS-OUT-AVG-CLAIM
           ELSE
               MOVE +0 TO WS-OUT-AVG-CLAIM
           END-IF
      *
      *    FORMAT GRAND TOTAL USING COMFMTL0
      *
           MOVE 'CUR ' TO WS-FMT-FUNCTION
           MOVE WS-GRAND-TOTAL TO WS-FMT-INPUT-NUM
           CALL 'COMFMTL0' USING WS-FMT-FUNCTION
                                 WS-FMT-INPUT
                                 WS-FMT-OUTPUT
                                 WS-FMT-RETURN-CODE
                                 WS-FMT-ERROR-MSG
      *
           STRING 'CLAIMS SUMMARY: '
                  WS-OUT-GRAND-CLAIMS ' CLAIMS, TOTAL '
                  WS-FMT-OUTPUT(1:15)
                  DELIMITED BY SIZE
               INTO WS-OUT-MESSAGE
           END-STRING
           .
      *
      ****************************************************************
      *    8000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       8000-SEND-OUTPUT.
      *
           COMPUTE WS-OUT-LL =
               FUNCTION LENGTH(WS-OUTPUT-MSG)
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-STATUS NOT = '  '
               CONTINUE
           END-IF
           .
      ****************************************************************
      * END OF WRCRPT00                                              *
      ****************************************************************
