       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINAPV00.
      ****************************************************************
      * PROGRAM:  FINAPV00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   FINANCE - FINANCE APPROVAL / DECLINE PROCESSING    *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PROCESSES FINANCE APPLICATION DECISIONS:            *
      *             AP = APPROVE  (RECORDS APPROVED TERMS)           *
      *             CD = CONDITIONAL (STIPULATIONS REQUIRED)         *
      *             DN = DECLINE  (ALLOWS RESUBMIT TO NEW LENDER)   *
      *           ON APPROVE: RECALCULATES PAYMENT WITH APPROVED     *
      *           APR/AMOUNT. UPDATES SALES_DEAL.AMOUNT_FINANCED.    *
      *           TRACKS LENDER DECISION AND TIMESTAMP.              *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * TRANS:    FNAV - FINANCE APPROVAL                            *
      * CALLS:    COMLONL0 - LOAN RECALCULATION                     *
      *           COMFMTL0 - FIELD FORMATTING                       *
      *           COMLGEL0 - AUDIT LOGGING                          *
      *           COMDBEL0 - DB2 ERROR HANDLER                      *
      * TABLES:   AUTOSALE.FINANCE_APP                                *
      *           AUTOSALE.SALES_DEAL                                 *
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
                                          VALUE 'FINAPV00'.
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
           COPY DCLFINAP.
      *
           COPY DCLSLDEL.
      *
      *    INPUT FIELDS
      *
       01  WS-APV-INPUT.
           05  WS-AI-FINANCE-ID          PIC X(12).
           05  WS-AI-ACTION              PIC X(02).
               88  WS-AI-APPROVE                     VALUE 'AP'.
               88  WS-AI-CONDITIONAL                 VALUE 'CD'.
               88  WS-AI-DECLINE                     VALUE 'DN'.
           05  WS-AI-APPROVED-AMT        PIC X(11).
           05  WS-AI-APPROVED-APR        PIC X(06).
           05  WS-AI-STIPULATIONS        PIC X(200).
      *
      *    NUMERIC CONVERTED FIELDS
      *
       01  WS-NUM-FIELDS.
           05  WS-NUM-APVD-AMT          PIC S9(09)V99 COMP-3
                                                       VALUE +0.
           05  WS-NUM-APVD-APR          PIC S9(03)V9(04) COMP-3
                                                       VALUE +0.
      *
      *    OUTPUT MESSAGE LAYOUT
      *
       01  WS-APV-OUTPUT.
           05  WS-VO-STATUS-LINE.
               10  WS-VO-MSG-ID         PIC X(08).
               10  FILLER               PIC X(01) VALUE SPACE.
               10  WS-VO-MSG-TEXT       PIC X(70).
           05  WS-VO-BLANK-1            PIC X(79) VALUE SPACES.
           05  WS-VO-HEADER.
               10  FILLER               PIC X(40)
                   VALUE '---- FINANCE DECISION PROCESSING ---- '.
               10  FILLER               PIC X(39) VALUE SPACES.
           05  WS-VO-FIN-ID-LINE.
               10  FILLER               PIC X(12)
                   VALUE 'FINANCE ID: '.
               10  WS-VO-FINANCE-ID     PIC X(12).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'ACTION: '.
               10  WS-VO-ACTION         PIC X(10).
               10  FILLER               PIC X(32) VALUE SPACES.
           05  WS-VO-DEAL-LINE.
               10  FILLER               PIC X(06) VALUE 'DEAL: '.
               10  WS-VO-DEAL-NUMBER    PIC X(10).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(08)
                   VALUE 'LENDER: '.
               10  WS-VO-LENDER         PIC X(05).
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06)
                   VALUE 'TYPE: '.
               10  WS-VO-FIN-TYPE       PIC X(01).
               10  FILLER               PIC X(33) VALUE SPACES.
           05  WS-VO-OLD-TERMS.
               10  FILLER               PIC X(18)
                   VALUE 'REQUESTED:        '.
               10  FILLER               PIC X(05) VALUE 'AMT: '.
               10  WS-VO-REQ-AMT        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'APR: '.
               10  WS-VO-REQ-APR        PIC ZZ9.999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(05) VALUE SPACES.
               10  FILLER               PIC X(06) VALUE 'TERM: '.
               10  WS-VO-REQ-TERM       PIC Z(02)9.
               10  FILLER               PIC X(12) VALUE SPACES.
           05  WS-VO-NEW-TERMS.
               10  FILLER               PIC X(18)
                   VALUE 'APPROVED:         '.
               10  FILLER               PIC X(05) VALUE 'AMT: '.
               10  WS-VO-APV-AMT        PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(05) VALUE 'APR: '.
               10  WS-VO-APV-APR        PIC ZZ9.999.
               10  FILLER               PIC X(01) VALUE '%'.
               10  FILLER               PIC X(23) VALUE SPACES.
           05  WS-VO-BLANK-2            PIC X(79) VALUE SPACES.
           05  WS-VO-PMT-LINE.
               10  FILLER               PIC X(17)
                   VALUE 'MONTHLY PAYMENT: '.
               10  WS-VO-MONTHLY-PMT    PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(03) VALUE SPACES.
               10  FILLER               PIC X(17)
                   VALUE 'TOTAL PAYMENTS: '.
               10  WS-VO-TOTAL-PMT      PIC $ZZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(15) VALUE SPACES.
           05  WS-VO-INT-LINE.
               10  FILLER               PIC X(17)
                   VALUE 'TOTAL INTEREST:  '.
               10  WS-VO-TOTAL-INT      PIC $ZZ,ZZZ,ZZ9.99.
               10  FILLER               PIC X(49) VALUE SPACES.
           05  WS-VO-STIP-LINE.
               10  FILLER               PIC X(14)
                   VALUE 'STIPULATIONS: '.
               10  WS-VO-STIP-TEXT      PIC X(65).
           05  WS-VO-STATUS-LINE-2.
               10  FILLER               PIC X(12)
                   VALUE 'NEW STATUS: '.
               10  WS-VO-NEW-STATUS     PIC X(02).
               10  FILLER               PIC X(65) VALUE SPACES.
           05  WS-VO-FILLER             PIC X(79) VALUE SPACES.
      *
      *    LOAN CALCULATION CALL FIELDS
      *
       01  WS-LOAN-REQUEST.
           05  WS-LN-FUNCTION           PIC X(04).
           05  WS-LN-PRINCIPAL          PIC S9(09)V99 COMP-3.
           05  WS-LN-APR                PIC S9(03)V9(04) COMP-3.
           05  WS-LN-TERM-MONTHS        PIC S9(04)    COMP.
           05  WS-LN-DEALER-CODE        PIC X(05).
           05  WS-LN-VIN                PIC X(17).
      *
       01  WS-LOAN-RESULT.
           05  WS-LR-RETURN-CODE        PIC S9(04)    COMP.
           05  WS-LR-RETURN-MSG         PIC X(79).
           05  WS-LR-MONTHLY-PMT        PIC S9(07)V99 COMP-3.
           05  WS-LR-TOTAL-PAYMENTS     PIC S9(09)V99 COMP-3.
           05  WS-LR-TOTAL-INTEREST     PIC S9(09)V99 COMP-3.
           05  WS-LR-MONTHLY-RATE       PIC S9(01)V9(08) COMP-3.
           05  WS-LR-AMORT-MONTHS       PIC S9(04)    COMP.
           05  WS-LR-AMORT-TABLE.
               10  WS-LR-AMORT-ENTRY    OCCURS 12 TIMES.
                   15  WS-AM-MONTH-NUM  PIC S9(04)    COMP.
                   15  WS-AM-PAYMENT    PIC S9(07)V99 COMP-3.
                   15  WS-AM-PRINCIPAL  PIC S9(07)V99 COMP-3.
                   15  WS-AM-INTEREST   PIC S9(07)V99 COMP-3.
                   15  WS-AM-CUM-INT    PIC S9(09)V99 COMP-3.
                   15  WS-AM-BALANCE    PIC S9(09)V99 COMP-3.
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
      *    AUDIT LOG CALL FIELDS
      *
       01  WS-AUD-USER-ID              PIC X(08).
       01  WS-AUD-PROGRAM-ID           PIC X(08) VALUE 'FINAPV00'.
       01  WS-AUD-ACTION-TYPE          PIC X(08).
       01  WS-AUD-TABLE-NAME           PIC X(18).
       01  WS-AUD-KEY-VALUE            PIC X(30).
       01  WS-AUD-OLD-VALUE            PIC X(100).
       01  WS-AUD-NEW-VALUE            PIC X(100).
       01  WS-AUD-RETURN-CODE          PIC S9(04) COMP.
       01  WS-AUD-ERROR-MSG            PIC X(79).
      *
      *    DB2 ERROR HANDLER FIELDS
      *
       01  WS-DBE-PROGRAM-NAME         PIC X(08) VALUE 'FINAPV00'.
       01  WS-DBE-SECTION-NAME         PIC X(30).
       01  WS-DBE-TABLE-NAME           PIC X(18).
       01  WS-DBE-OPERATION            PIC X(08).
       01  WS-DBE-RESULT-AREA.
           05  WS-DBE-RESULT-CODE      PIC S9(04) COMP.
           05  WS-DBE-RESULT-MSG       PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-RETURN-CODE              PIC S9(04) COMP VALUE +0.
       01  WS-OLD-STATUS               PIC X(02) VALUE SPACES.
       01  WS-RECALC-PRINCIPAL         PIC S9(09)V99 COMP-3
                                                       VALUE +0.
      *
      *    NULL INDICATORS
      *
       01  WS-NULL-INDICATORS.
           05  WS-NI-STIP-LEN          PIC S9(04) COMP VALUE +0.
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
               PERFORM 4000-FETCH-FINANCE-APP
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 5000-PROCESS-DECISION
           END-IF
      *
           IF WS-RETURN-CODE = +0
               PERFORM 6000-UPDATE-FINANCE-APP
           END-IF
      *
           IF WS-RETURN-CODE = +0
           AND WS-AI-APPROVE
               PERFORM 7000-UPDATE-DEAL-AMOUNT
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
           INITIALIZE WS-APV-OUTPUT
           INITIALIZE WS-APV-INPUT
           INITIALIZE WS-NUM-FIELDS
           MOVE 'FINAPV00' TO WS-VO-MSG-ID
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
                   TO WS-VO-MSG-TEXT
           ELSE
               MOVE WS-INP-KEY-DATA(1:12)
                   TO WS-AI-FINANCE-ID
               MOVE WS-INP-BODY(1:2)
                   TO WS-AI-ACTION
               MOVE WS-INP-BODY(3:11)
                   TO WS-AI-APPROVED-AMT
               MOVE WS-INP-BODY(14:6)
                   TO WS-AI-APPROVED-APR
               MOVE WS-INP-BODY(20:200)
                   TO WS-AI-STIPULATIONS
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT                                       *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-AI-FINANCE-ID = SPACES
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FINANCE ID IS REQUIRED'
                   TO WS-VO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
           IF NOT WS-AI-APPROVE
           AND NOT WS-AI-CONDITIONAL
           AND NOT WS-AI-DECLINE
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'ACTION MUST BE AP(APPROVE) CD(COND) DN(DECLINE)'
                   TO WS-VO-MSG-TEXT
               GO TO 3000-EXIT
           END-IF
      *
      *    APPROVE REQUIRES APPROVED AMOUNT AND APR
      *
           IF WS-AI-APPROVE
               IF WS-AI-APPROVED-AMT = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'APPROVED AMOUNT REQUIRED FOR APPROVAL'
                       TO WS-VO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
               IF WS-AI-APPROVED-APR = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'APPROVED APR REQUIRED FOR APPROVAL'
                       TO WS-VO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
      *
               COMPUTE WS-NUM-APVD-AMT =
                   FUNCTION NUMVAL(WS-AI-APPROVED-AMT)
               END-COMPUTE
               COMPUTE WS-NUM-APVD-APR =
                   FUNCTION NUMVAL(WS-AI-APPROVED-APR)
               END-COMPUTE
           END-IF
      *
      *    CONDITIONAL REQUIRES STIPULATIONS
      *
           IF WS-AI-CONDITIONAL
               IF WS-AI-STIPULATIONS = SPACES
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE 'STIPULATIONS REQUIRED FOR CONDITIONAL APPROVAL'
                       TO WS-VO-MSG-TEXT
                   GO TO 3000-EXIT
               END-IF
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-FETCH-FINANCE-APP - RETRIEVE EXISTING APPLICATION    *
      ****************************************************************
       4000-FETCH-FINANCE-APP.
      *
           EXEC SQL
               SELECT FINANCE_ID
                    , DEAL_NUMBER
                    , CUSTOMER_ID
                    , FINANCE_TYPE
                    , LENDER_CODE
                    , APP_STATUS
                    , AMOUNT_REQUESTED
                    , APR_REQUESTED
                    , TERM_MONTHS
                    , DOWN_PAYMENT
               INTO  :FINANCE-ID      OF DCLFINANCE-APP
                    , :DEAL-NUMBER    OF DCLFINANCE-APP
                    , :CUSTOMER-ID   OF DCLFINANCE-APP
                    , :FINANCE-TYPE  OF DCLFINANCE-APP
                    , :LENDER-CODE   OF DCLFINANCE-APP
                    , :APP-STATUS    OF DCLFINANCE-APP
                    , :AMOUNT-REQUESTED OF DCLFINANCE-APP
                    , :APR-REQUESTED OF DCLFINANCE-APP
                    , :TERM-MONTHS   OF DCLFINANCE-APP
                    , :DOWN-PAYMENT  OF DCLFINANCE-APP
               FROM   AUTOSALE.FINANCE_APP
               WHERE  FINANCE_ID = :WS-AI-FINANCE-ID
           END-EXEC
      *
           IF SQLCODE = +100
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'FINANCE APPLICATION NOT FOUND'
                   TO WS-VO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
           IF SQLCODE NOT = +0
               MOVE '4000-FETCH'     TO WS-DBE-SECTION-NAME
               MOVE 'FINANCE_APP'    TO WS-DBE-TABLE-NAME
               MOVE 'SELECT'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON FINANCE APP LOOKUP'
                   TO WS-VO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    SAVE OLD STATUS FOR AUDIT
      *
           MOVE APP-STATUS OF DCLFINANCE-APP TO WS-OLD-STATUS
      *
      *    CANNOT DECIDE ON ALREADY-DECIDED APP (UNLESS RESUBMIT)
      *
           IF APP-STATUS OF DCLFINANCE-APP = 'AP'
               MOVE +8 TO WS-RETURN-CODE
               MOVE 'APPLICATION ALREADY APPROVED - CANNOT REDECIDE'
                   TO WS-VO-MSG-TEXT
               GO TO 4000-EXIT
           END-IF
      *
      *    FORMAT EXISTING TERMS DISPLAY
      *
           MOVE FINANCE-ID OF DCLFINANCE-APP TO WS-VO-FINANCE-ID
           MOVE DEAL-NUMBER OF DCLFINANCE-APP TO WS-VO-DEAL-NUMBER
           MOVE LENDER-CODE OF DCLFINANCE-APP TO WS-VO-LENDER
           MOVE FINANCE-TYPE OF DCLFINANCE-APP TO WS-VO-FIN-TYPE
           MOVE AMOUNT-REQUESTED TO WS-VO-REQ-AMT
           MOVE APR-REQUESTED    TO WS-VO-REQ-APR
           MOVE TERM-MONTHS OF DCLFINANCE-APP TO WS-VO-REQ-TERM
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5000-PROCESS-DECISION - APPLY APPROVAL/CONDITION/DECLINE  *
      ****************************************************************
       5000-PROCESS-DECISION.
      *
           EVALUATE TRUE
               WHEN WS-AI-APPROVE
                   PERFORM 5100-PROCESS-APPROVE
               WHEN WS-AI-CONDITIONAL
                   PERFORM 5200-PROCESS-CONDITIONAL
               WHEN WS-AI-DECLINE
                   PERFORM 5300-PROCESS-DECLINE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    5100-PROCESS-APPROVE                                      *
      ****************************************************************
       5100-PROCESS-APPROVE.
      *
           MOVE 'APPROVED'  TO WS-VO-ACTION
           MOVE 'AP'        TO WS-VO-NEW-STATUS
      *
      *    RECALCULATE PAYMENT WITH APPROVED TERMS
      *
           IF FINANCE-TYPE OF DCLFINANCE-APP = 'L'
      *        LOAN - RECALCULATE
               COMPUTE WS-RECALC-PRINCIPAL =
                   WS-NUM-APVD-AMT - DOWN-PAYMENT
                       OF DCLFINANCE-APP
               END-COMPUTE
      *
               MOVE 'CALC'               TO WS-LN-FUNCTION
               MOVE WS-RECALC-PRINCIPAL  TO WS-LN-PRINCIPAL
               MOVE WS-NUM-APVD-APR     TO WS-LN-APR
               MOVE TERM-MONTHS OF DCLFINANCE-APP
                                          TO WS-LN-TERM-MONTHS
               MOVE SPACES                TO WS-LN-DEALER-CODE
               MOVE SPACES                TO WS-LN-VIN
      *
               CALL 'COMLONL0' USING WS-LOAN-REQUEST
                                      WS-LOAN-RESULT
      *
               IF WS-LR-RETURN-CODE NOT = +0
                   MOVE +8 TO WS-RETURN-CODE
                   MOVE WS-LR-RETURN-MSG TO WS-VO-MSG-TEXT
                   GO TO 5100-EXIT
               END-IF
      *
      *        FORMAT RECALCULATED PAYMENT
      *
               MOVE WS-LR-MONTHLY-PMT    TO WS-VO-MONTHLY-PMT
               MOVE WS-LR-TOTAL-PAYMENTS TO WS-VO-TOTAL-PMT
               MOVE WS-LR-TOTAL-INTEREST TO WS-VO-TOTAL-INT
      *
      *        UPDATE DCLGEN FIELDS FOR DB2 UPDATE
      *
               MOVE WS-LR-MONTHLY-PMT    TO MONTHLY-PAYMENT
           END-IF
      *
           MOVE WS-NUM-APVD-AMT TO WS-VO-APV-AMT
           MOVE WS-NUM-APVD-APR TO WS-VO-APV-APR
           MOVE SPACES           TO WS-VO-STIP-TEXT
      *
           MOVE 'FINANCE APPLICATION APPROVED SUCCESSFULLY'
               TO WS-VO-MSG-TEXT
           .
       5100-EXIT.
           EXIT.
      *
      ****************************************************************
      *    5200-PROCESS-CONDITIONAL                                  *
      ****************************************************************
       5200-PROCESS-CONDITIONAL.
      *
           MOVE 'CONDITIONAL' TO WS-VO-ACTION
           MOVE 'CD'          TO WS-VO-NEW-STATUS
           MOVE WS-AI-STIPULATIONS(1:65) TO WS-VO-STIP-TEXT
      *
      *    IF APPROVED AMOUNTS PROVIDED, SHOW THEM
      *
           IF WS-AI-APPROVED-AMT NOT = SPACES
               COMPUTE WS-NUM-APVD-AMT =
                   FUNCTION NUMVAL(WS-AI-APPROVED-AMT)
               END-COMPUTE
               MOVE WS-NUM-APVD-AMT TO WS-VO-APV-AMT
           END-IF
      *
           IF WS-AI-APPROVED-APR NOT = SPACES
               COMPUTE WS-NUM-APVD-APR =
                   FUNCTION NUMVAL(WS-AI-APPROVED-APR)
               END-COMPUTE
               MOVE WS-NUM-APVD-APR TO WS-VO-APV-APR
           END-IF
      *
           MOVE 'CONDITIONAL APPROVAL - STIPULATIONS REQUIRED'
               TO WS-VO-MSG-TEXT
           .
      *
      ****************************************************************
      *    5300-PROCESS-DECLINE                                      *
      ****************************************************************
       5300-PROCESS-DECLINE.
      *
           MOVE 'DECLINED'  TO WS-VO-ACTION
           MOVE 'DN'        TO WS-VO-NEW-STATUS
           MOVE SPACES      TO WS-VO-STIP-TEXT
      *
           MOVE 'FINANCE APPLICATION DECLINED - MAY RESUBMIT TO NEW LEN
      -    'DER' TO WS-VO-MSG-TEXT
           .
      *
      ****************************************************************
      *    6000-UPDATE-FINANCE-APP                                   *
      ****************************************************************
       6000-UPDATE-FINANCE-APP.
      *
           EVALUATE TRUE
               WHEN WS-AI-APPROVE
                   EXEC SQL
                       UPDATE AUTOSALE.FINANCE_APP
                          SET APP_STATUS      = 'AP'
                            , AMOUNT_APPROVED = :WS-NUM-APVD-AMT
                            , APR_APPROVED    = :WS-NUM-APVD-APR
                            , MONTHLY_PAYMENT = :MONTHLY-PAYMENT
                            , DECISION_TS     = CURRENT TIMESTAMP
                            , UPDATED_TS      = CURRENT TIMESTAMP
                       WHERE  FINANCE_ID = :WS-AI-FINANCE-ID
                   END-EXEC
               WHEN WS-AI-CONDITIONAL
                   MOVE FUNCTION LENGTH(WS-AI-STIPULATIONS)
                       TO STIPULATIONS-LN
                   MOVE WS-AI-STIPULATIONS TO STIPULATIONS-TX
                   EXEC SQL
                       UPDATE AUTOSALE.FINANCE_APP
                          SET APP_STATUS   = 'CD'
                            , STIPULATIONS = :STIPULATIONS
                            , DECISION_TS  = CURRENT TIMESTAMP
                            , UPDATED_TS   = CURRENT TIMESTAMP
                       WHERE  FINANCE_ID = :WS-AI-FINANCE-ID
                   END-EXEC
               WHEN WS-AI-DECLINE
                   EXEC SQL
                       UPDATE AUTOSALE.FINANCE_APP
                          SET APP_STATUS  = 'DN'
                            , DECISION_TS = CURRENT TIMESTAMP
                            , UPDATED_TS  = CURRENT TIMESTAMP
                       WHERE  FINANCE_ID = :WS-AI-FINANCE-ID
                   END-EXEC
           END-EVALUATE
      *
           IF SQLCODE NOT = +0
               MOVE '6000-UPDATE'    TO WS-DBE-SECTION-NAME
               MOVE 'FINANCE_APP'    TO WS-DBE-TABLE-NAME
               MOVE 'UPDATE'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR ON FINANCE APP UPDATE'
                   TO WS-VO-MSG-TEXT
               GO TO 6000-EXIT
           END-IF
      *
      *    AUDIT LOG
      *
           MOVE IO-PCB-USER-ID TO WS-AUD-USER-ID
           MOVE 'UPDATE'       TO WS-AUD-ACTION-TYPE
           MOVE 'FINANCE_APP'  TO WS-AUD-TABLE-NAME
           MOVE WS-AI-FINANCE-ID TO WS-AUD-KEY-VALUE
           STRING 'STATUS=' WS-OLD-STATUS
                  DELIMITED BY SIZE
                  INTO WS-AUD-OLD-VALUE
           STRING 'STATUS=' WS-AI-ACTION
                  DELIMITED BY SIZE
                  INTO WS-AUD-NEW-VALUE
           CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                  WS-AUD-PROGRAM-ID
                                  WS-AUD-ACTION-TYPE
                                  WS-AUD-TABLE-NAME
                                  WS-AUD-KEY-VALUE
                                  WS-AUD-OLD-VALUE
                                  WS-AUD-NEW-VALUE
                                  WS-AUD-RETURN-CODE
                                  WS-AUD-ERROR-MSG
           .
       6000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    7000-UPDATE-DEAL-AMOUNT - APPROVED AMOUNT TO DEAL         *
      ****************************************************************
       7000-UPDATE-DEAL-AMOUNT.
      *
           EXEC SQL
               UPDATE AUTOSALE.SALES_DEAL
                  SET AMOUNT_FINANCED = :WS-NUM-APVD-AMT
                    , UPDATED_TS      = CURRENT TIMESTAMP
               WHERE  DEAL_NUMBER =
                   :DEAL-NUMBER OF DCLFINANCE-APP
           END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE '7000-UPDATE'    TO WS-DBE-SECTION-NAME
               MOVE 'SALES_DEAL'     TO WS-DBE-TABLE-NAME
               MOVE 'UPDATE'         TO WS-DBE-OPERATION
               CALL 'COMDBEL0' USING SQLCA
                                      WS-DBE-PROGRAM-NAME
                                      WS-DBE-SECTION-NAME
                                      WS-DBE-TABLE-NAME
                                      WS-DBE-OPERATION
                                      WS-DBE-RESULT-AREA
               MOVE +16 TO WS-RETURN-CODE
               MOVE 'DB2 ERROR UPDATING DEAL AMOUNT FINANCED'
                   TO WS-VO-MSG-TEXT
           ELSE
      *        AUDIT THE DEAL UPDATE
               MOVE 'UPDATE'       TO WS-AUD-ACTION-TYPE
               MOVE 'SALES_DEAL'   TO WS-AUD-TABLE-NAME
               MOVE DEAL-NUMBER OF DCLFINANCE-APP
                   TO WS-AUD-KEY-VALUE
               MOVE SPACES         TO WS-AUD-OLD-VALUE
               STRING 'AMT_FINANCED=' WS-AI-APPROVED-AMT
                      DELIMITED BY SIZE
                      INTO WS-AUD-NEW-VALUE
               CALL 'COMLGEL0' USING WS-AUD-USER-ID
                                      WS-AUD-PROGRAM-ID
                                      WS-AUD-ACTION-TYPE
                                      WS-AUD-TABLE-NAME
                                      WS-AUD-KEY-VALUE
                                      WS-AUD-OLD-VALUE
                                      WS-AUD-NEW-VALUE
                                      WS-AUD-RETURN-CODE
                                      WS-AUD-ERROR-MSG
           END-IF
           .
      *
      ****************************************************************
      *    9000-SEND-OUTPUT                                          *
      ****************************************************************
       9000-SEND-OUTPUT.
      *
           MOVE WS-APV-OUTPUT TO WS-OUT-DATA
           MOVE WS-OUT-MSG-LENGTH TO WS-OUT-LL
           MOVE +0 TO WS-OUT-ZZ
      *
           CALL 'CBLTDLI' USING WS-ISRT
                                IO-PCB
                                WS-OUTPUT-MSG
      *
           IF IO-PCB-STATUS NOT = SPACES
               MOVE 'FNAV' TO WS-ABEND-CODE
           END-IF
           .
      ****************************************************************
      * END OF FINAPV00                                              *
      ****************************************************************
