       IDENTIFICATION DIVISION.
       PROGRAM-ID. STKINQ00.
      ****************************************************************
      * PROGRAM:  STKINQ00                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   STOCK MANAGEMENT - STOCK INQUIRY                   *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  DISPLAYS STOCK POSITION FOR A DEALER WITH OPTIONAL *
      *           FILTERS BY MODEL YEAR, MAKE, MODEL, AND STATUS.    *
      *           JOINS MODEL_MASTER FOR DESCRIPTION. SHOWS LOW      *
      *           STOCK ALERT WHEN ON_HAND < REORDER_POINT.          *
      * IMS:      ONLINE IMS DC TRANSACTION                          *
      * ENTRY:    DLITCBL                                            *
      * MFS MOD:  ASSTKI00                                           *
      * TABLES:   AUTOSALE.STOCK_POSITION (READ)                     *
      *           AUTOSALE.MODEL_MASTER   (READ)                     *
      * CALLS:    COMFMTL0 - CURRENCY FORMATTING                    *
      *           COMMSGL0 - MESSAGE BUILDER                         *
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
                                          VALUE 'STKINQ00'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
           05  WS-MOD-NAME               PIC X(08)
                                          VALUE 'ASSTKI00'.
      *
      *    IMS FUNCTION CODES
      *
       01  WS-IMS-FUNCTIONS.
           05  WS-GU                     PIC X(04) VALUE 'GU  '.
           05  WS-ISRT                   PIC X(04) VALUE 'ISRT'.
      *
      *    COPY IN SQLCA
      *
           COPY WSSQLCA.
      *
      *    COPY IN IMS I/O PCB AND DB PCB MASKS
      *
           COPY WSIOPCB.
      *
      *    COPY IN DCLGEN FOR STOCK_POSITION
      *
           COPY DCLSTKPS.
      *
      *    COPY IN DCLGEN FOR MODEL_MASTER
      *
           COPY DCLMODEL.
      *
      *    INPUT MESSAGE AREA (FROM MFS)
      *
       01  WS-INPUT-MSG.
           05  WS-IN-LL                  PIC S9(04) COMP.
           05  WS-IN-ZZ                  PIC S9(04) COMP.
           05  WS-IN-TRAN-CODE           PIC X(08).
           05  WS-IN-DEALER-CODE         PIC X(05).
           05  WS-IN-MODEL-YEAR          PIC X(04).
           05  WS-IN-MAKE-CODE           PIC X(03).
           05  WS-IN-MODEL-CODE          PIC X(06).
           05  WS-IN-STATUS-FILTER       PIC X(02).
      *
      *    OUTPUT MESSAGE AREA (TO MFS)
      *
       01  WS-OUTPUT-MSG.
           05  WS-OUT-LL                 PIC S9(04) COMP.
           05  WS-OUT-ZZ                 PIC S9(04) COMP.
           05  WS-OUT-TITLE              PIC X(40).
           05  WS-OUT-DEALER-CODE        PIC X(05).
           05  WS-OUT-DEALER-LABEL       PIC X(10).
           05  WS-OUT-LINE-COUNT         PIC S9(04) COMP.
           05  WS-OUT-DETAIL OCCURS 15 TIMES.
               10  WS-OUT-MODEL-YR       PIC X(04).
               10  WS-OUT-MAKE           PIC X(03).
               10  WS-OUT-MODEL          PIC X(06).
               10  WS-OUT-MODEL-DESC     PIC X(30).
               10  WS-OUT-ON-HAND        PIC Z(4)9.
               10  WS-OUT-IN-TRANSIT     PIC Z(4)9.
               10  WS-OUT-ALLOCATED      PIC Z(4)9.
               10  WS-OUT-ON-HOLD        PIC Z(4)9.
               10  WS-OUT-SOLD-MTD       PIC Z(4)9.
               10  WS-OUT-SOLD-YTD       PIC Z(4)9.
               10  WS-OUT-REORDER-PT     PIC Z(4)9.
               10  WS-OUT-ALERT-FLAG     PIC X(05).
           05  WS-OUT-MESSAGE            PIC X(79).
      *
      *    WORK FIELDS
      *
       01  WS-WORK-FIELDS.
           05  WS-ROW-COUNT              PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-MODEL-YEAR-NUM         PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-MODEL-YEAR-ALPHA       PIC X(04)  VALUE SPACES.
           05  WS-EOF-FLAG               PIC X(01)  VALUE 'N'.
               88  WS-END-OF-DATA                   VALUE 'Y'.
               88  WS-MORE-DATA                     VALUE 'N'.
           05  WS-FILTER-YEAR            PIC S9(04) COMP
                                                     VALUE +0.
           05  WS-MODEL-DESC-WORK        PIC X(40)  VALUE SPACES.
           05  WS-LOW-STOCK-FLAG         PIC X(01)  VALUE 'N'.
               88  WS-LOW-STOCK                     VALUE 'Y'.
      *
      *    CURSOR DECLARATION FOR STOCK INQUIRY
      *
           EXEC SQL DECLARE CSR_STK_INQ CURSOR FOR
               SELECT S.DEALER_CODE
                    , S.MODEL_YEAR
                    , S.MAKE_CODE
                    , S.MODEL_CODE
                    , S.ON_HAND_COUNT
                    , S.IN_TRANSIT_COUNT
                    , S.ALLOCATED_COUNT
                    , S.ON_HOLD_COUNT
                    , S.SOLD_MTD
                    , S.SOLD_YTD
                    , S.REORDER_POINT
                    , M.MODEL_NAME
               FROM   AUTOSALE.STOCK_POSITION S
               JOIN   AUTOSALE.MODEL_MASTER   M
                 ON   S.MODEL_YEAR = M.MODEL_YEAR
                AND   S.MAKE_CODE  = M.MAKE_CODE
                AND   S.MODEL_CODE = M.MODEL_CODE
               WHERE  S.DEALER_CODE = :WS-IN-DEALER-CODE
                 AND  (S.MODEL_YEAR  = :WS-FILTER-YEAR
                       OR :WS-FILTER-YEAR = 0)
                 AND  (S.MAKE_CODE   = :WS-IN-MAKE-CODE
                       OR :WS-IN-MAKE-CODE = '   ')
                 AND  (S.MODEL_CODE  = :WS-IN-MODEL-CODE
                       OR :WS-IN-MODEL-CODE = '      ')
               ORDER BY S.MODEL_YEAR DESC
                      , S.MAKE_CODE
                      , S.MODEL_CODE
           END-EXEC
      *
      *    COMMON MODULE LINKAGE AREAS
      *
       01  WS-FMT-FUNCTION              PIC X(04).
       01  WS-FMT-INPUT.
           05  WS-FMT-INPUT-ALPHA       PIC X(40).
           05  WS-FMT-INPUT-NUM         PIC S9(09)V99 COMP-3.
           05  WS-FMT-INPUT-RATE        PIC S9(02)V9(04) COMP-3.
           05  WS-FMT-INPUT-PCT         PIC S9(03)V99 COMP-3.
       01  WS-FMT-OUTPUT                PIC X(40).
       01  WS-FMT-RETURN-CODE           PIC S9(04) COMP.
       01  WS-FMT-ERROR-MSG             PIC X(50).
      *
       01  WS-MSG-FUNCTION              PIC X(04).
       01  WS-MSG-TEXT                   PIC X(79).
       01  WS-MSG-SEVERITY              PIC X(04).
       01  WS-MSG-PROGRAM-ID            PIC X(08).
       01  WS-MSG-OUTPUT-AREA           PIC X(256).
       01  WS-MSG-RETURN-CODE           PIC S9(04) COMP.
      *
      *    DB2 HOST VARIABLES FOR CURSOR FETCH
      *
       01  WS-HOST-VARS.
           05  WS-HV-DEALER-CODE        PIC X(05).
           05  WS-HV-MODEL-YEAR         PIC S9(04) COMP.
           05  WS-HV-MAKE-CODE          PIC X(03).
           05  WS-HV-MODEL-CODE         PIC X(06).
           05  WS-HV-ON-HAND            PIC S9(04) COMP.
           05  WS-HV-IN-TRANSIT         PIC S9(04) COMP.
           05  WS-HV-ALLOCATED          PIC S9(04) COMP.
           05  WS-HV-ON-HOLD            PIC S9(04) COMP.
           05  WS-HV-SOLD-MTD           PIC S9(04) COMP.
           05  WS-HV-SOLD-YTD           PIC S9(04) COMP.
           05  WS-HV-REORDER-PT         PIC S9(04) COMP.
           05  WS-HV-MODEL-NAME.
               49  WS-HV-MODEL-NAME-LN  PIC S9(04) COMP.
               49  WS-HV-MODEL-NAME-TX  PIC X(40).
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
               PERFORM 4000-RETRIEVE-STOCK
           END-IF
      *
           PERFORM 5000-SEND-OUTPUT
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
           MOVE +0 TO WS-FILTER-YEAR
           MOVE SPACES TO WS-OUT-MESSAGE
           MOVE 'STOCK POSITION INQUIRY' TO WS-OUT-TITLE
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
               MOVE 'STKINQ00: ERROR RECEIVING INPUT MESSAGE'
                   TO WS-OUT-MESSAGE
           END-IF
           .
      *
      ****************************************************************
      *    3000-VALIDATE-INPUT - CHECK REQUIRED FIELDS               *
      ****************************************************************
       3000-VALIDATE-INPUT.
      *
           IF WS-IN-DEALER-CODE = SPACES
               MOVE 'DEALER CODE IS REQUIRED FOR STOCK INQUIRY'
                   TO WS-OUT-MESSAGE
               GO TO 3000-EXIT
           END-IF
      *
           MOVE WS-IN-DEALER-CODE TO WS-OUT-DEALER-CODE
           MOVE 'DEALER:' TO WS-OUT-DEALER-LABEL
      *
      *    CONVERT MODEL YEAR IF PROVIDED
      *
           IF WS-IN-MODEL-YEAR NOT = SPACES
           AND WS-IN-MODEL-YEAR NOT = '0000'
               MOVE WS-IN-MODEL-YEAR TO WS-MODEL-YEAR-ALPHA
               COMPUTE WS-FILTER-YEAR =
                   FUNCTION NUMVAL(WS-MODEL-YEAR-ALPHA)
           ELSE
               MOVE +0 TO WS-FILTER-YEAR
           END-IF
           .
       3000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4000-RETRIEVE-STOCK - OPEN CURSOR AND FETCH ROWS          *
      ****************************************************************
       4000-RETRIEVE-STOCK.
      *
           EXEC SQL OPEN CSR_STK_INQ END-EXEC
      *
           IF SQLCODE NOT = +0
               MOVE 'STKINQ00: ERROR OPENING STOCK CURSOR'
                   TO WS-OUT-MESSAGE
               GO TO 4000-EXIT
           END-IF
      *
           MOVE +0 TO WS-ROW-COUNT
           MOVE 'N' TO WS-EOF-FLAG
      *
           PERFORM 4100-FETCH-ROW
               UNTIL WS-END-OF-DATA
               OR WS-ROW-COUNT >= +15
      *
           EXEC SQL CLOSE CSR_STK_INQ END-EXEC
      *
           IF WS-ROW-COUNT = +0
               MOVE 'NO STOCK POSITION RECORDS FOUND FOR CRITERIA'
                   TO WS-OUT-MESSAGE
           ELSE
               MOVE WS-ROW-COUNT TO WS-OUT-LINE-COUNT
           END-IF
           .
       4000-EXIT.
           EXIT.
      *
      ****************************************************************
      *    4100-FETCH-ROW - FETCH ONE ROW AND FORMAT FOR DISPLAY     *
      ****************************************************************
       4100-FETCH-ROW.
      *
           EXEC SQL FETCH CSR_STK_INQ
               INTO  :WS-HV-DEALER-CODE
                    , :WS-HV-MODEL-YEAR
                    , :WS-HV-MAKE-CODE
                    , :WS-HV-MODEL-CODE
                    , :WS-HV-ON-HAND
                    , :WS-HV-IN-TRANSIT
                    , :WS-HV-ALLOCATED
                    , :WS-HV-ON-HOLD
                    , :WS-HV-SOLD-MTD
                    , :WS-HV-SOLD-YTD
                    , :WS-HV-REORDER-PT
                    , :WS-HV-MODEL-NAME
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN +0
                   ADD +1 TO WS-ROW-COUNT
                   PERFORM 4200-FORMAT-DETAIL-LINE
               WHEN +100
                   MOVE 'Y' TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE 'Y' TO WS-EOF-FLAG
                   MOVE 'STKINQ00: DB2 ERROR READING STOCK DATA'
                       TO WS-OUT-MESSAGE
           END-EVALUATE
           .
      *
      ****************************************************************
      *    4200-FORMAT-DETAIL-LINE - POPULATE OUTPUT DETAIL ROW      *
      ****************************************************************
       4200-FORMAT-DETAIL-LINE.
      *
           MOVE WS-HV-MODEL-YEAR  TO WS-OUT-MODEL-YR(WS-ROW-COUNT)
           MOVE WS-HV-MAKE-CODE   TO WS-OUT-MAKE(WS-ROW-COUNT)
           MOVE WS-HV-MODEL-CODE  TO WS-OUT-MODEL(WS-ROW-COUNT)
           MOVE WS-HV-MODEL-NAME-TX
                                   TO WS-OUT-MODEL-DESC(WS-ROW-COUNT)
           MOVE WS-HV-ON-HAND     TO WS-OUT-ON-HAND(WS-ROW-COUNT)
           MOVE WS-HV-IN-TRANSIT
                                   TO WS-OUT-IN-TRANSIT(WS-ROW-COUNT)
           MOVE WS-HV-ALLOCATED   TO WS-OUT-ALLOCATED(WS-ROW-COUNT)
           MOVE WS-HV-ON-HOLD     TO WS-OUT-ON-HOLD(WS-ROW-COUNT)
           MOVE WS-HV-SOLD-MTD    TO WS-OUT-SOLD-MTD(WS-ROW-COUNT)
           MOVE WS-HV-SOLD-YTD    TO WS-OUT-SOLD-YTD(WS-ROW-COUNT)
           MOVE WS-HV-REORDER-PT
                                   TO WS-OUT-REORDER-PT(WS-ROW-COUNT)
      *
      *    LOW STOCK ALERT CHECK
      *
           IF WS-HV-ON-HAND < WS-HV-REORDER-PT
               MOVE '*LOW*' TO WS-OUT-ALERT-FLAG(WS-ROW-COUNT)
           ELSE
               MOVE SPACES TO WS-OUT-ALERT-FLAG(WS-ROW-COUNT)
           END-IF
           .
      *
      ****************************************************************
      *    5000-SEND-OUTPUT - ISRT CALL ON IO-PCB                    *
      ****************************************************************
       5000-SEND-OUTPUT.
      *
      *    FORMAT MESSAGE IF ERROR
      *
           IF WS-OUT-MESSAGE NOT = SPACES
               MOVE 'ERR ' TO WS-MSG-FUNCTION
               MOVE WS-OUT-MESSAGE TO WS-MSG-TEXT
               MOVE 'E' TO WS-MSG-SEVERITY
               MOVE WS-PROGRAM-NAME TO WS-MSG-PROGRAM-ID
               CALL 'COMMSGL0' USING WS-MSG-FUNCTION
                                     WS-MSG-TEXT
                                     WS-MSG-SEVERITY
                                     WS-MSG-PROGRAM-ID
                                     WS-MSG-OUTPUT-AREA
                                     WS-MSG-RETURN-CODE
           END-IF
      *
      *    SET OUTPUT MESSAGE LENGTH
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
      * END OF STKINQ00                                              *
      ****************************************************************
