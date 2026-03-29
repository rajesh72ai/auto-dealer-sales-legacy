       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMEDIL0.
      ****************************************************************
      * PROGRAM:  COMEDIL0                                           *
      * SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING    *
      * MODULE:   COMMON - EDI MESSAGE PARSER MODULE                 *
      * AUTHOR:   AUTOSALES DEVELOPMENT TEAM                         *
      * DATE:     2026-03-29                                         *
      * PURPOSE:  PARSES INBOUND EDI MESSAGES FOR VEHICLE SHIPMENT   *
      *           AND DELIVERY TRACKING. SUPPORTS EDI 214 (CARRIER   *
      *           SHIPMENT STATUS) AND EDI 856 (ADVANCE SHIP NOTICE).*
      *           USES STRING/UNSTRING TO PARSE DELIMITED SEGMENTS.  *
      * CALLABLE: YES - VIA CALL 'COMEDIL0' USING LS-EDI-REQUEST    *
      *                                            LS-EDI-RESULT     *
      * EDI 214:  TRANSPORTATION CARRIER SHIPMENT STATUS MESSAGE     *
      *           SEGMENTS: B10, L11, AT7, AT8, LX, MS1, MS2        *
      * EDI 856:  ADVANCE SHIP NOTICE / MANIFEST                    *
      *           SEGMENTS: BSN, HL, REF, DTM, TD5, N1, LIN, SN1   *
      * NOTES:    ANSI X12 004010 STANDARD USING '*' ELEMENT SEP    *
      *           AND '~' SEGMENT TERMINATOR                         *
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
                                          VALUE 'COMEDIL0'.
           05  WS-PROGRAM-VERSION        PIC X(06)
                                          VALUE '01.00 '.
      *
      *    COPY IN EDI LAYOUTS
      *
           COPY WSEDI000.
      *
      *    SEGMENT PARSING WORK FIELDS
      *
       01  WS-PARSE-WORK.
           05  WS-RAW-SEGMENT            PIC X(512)   VALUE SPACES.
           05  WS-SEGMENT-ID             PIC X(03)    VALUE SPACES.
           05  WS-ELEMENT-COUNT          PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-SEGMENT-COUNT          PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-VEHICLE-COUNT          PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-BUFFER-POS             PIC S9(04)   COMP
                                                       VALUE +1.
           05  WS-BUFFER-LEN             PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-SEG-START              PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-SEG-END                PIC S9(04)   COMP
                                                       VALUE +0.
           05  WS-TALLY-COUNT            PIC S9(04)   COMP
                                                       VALUE +0.
      *
      *    ELEMENT EXTRACTION ARRAY (UP TO 20 ELEMENTS PER SEGMENT)
      *
       01  WS-ELEMENT-TABLE.
           05  WS-ELEMENT-ENTRY          OCCURS 20 TIMES.
               10  WS-ELEM-VALUE         PIC X(50)    VALUE SPACES.
               10  WS-ELEM-LENGTH        PIC S9(04)   COMP
                                                       VALUE +0.
      *
      *    ELEMENT WORK BUFFER FOR UNSTRING
      *
       01  WS-ELEM-WORK.
           05  WS-ELEM-01                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-02                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-03                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-04                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-05                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-06                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-07                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-08                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-09                PIC X(50)    VALUE SPACES.
           05  WS-ELEM-10                PIC X(50)    VALUE SPACES.
      *
      *    CONTROL FLAGS
      *
       01  WS-PARSE-FLAGS.
           05  WS-PARSE-ERROR-FLAG       PIC X(01)    VALUE 'N'.
               88  WS-PARSE-ERROR                     VALUE 'Y'.
               88  WS-PARSE-OK                        VALUE 'N'.
           05  WS-END-OF-MSG-FLAG        PIC X(01)    VALUE 'N'.
               88  WS-END-OF-MSG                      VALUE 'Y'.
               88  WS-MORE-SEGMENTS                   VALUE 'N'.
           05  WS-HL-LEVEL               PIC X(01)    VALUE SPACES.
               88  WS-HL-SHIPMENT                     VALUE 'S'.
               88  WS-HL-ITEM                         VALUE 'I'.
      *
      *    856 VEHICLE DETAIL TABLE (MAX 25 VEHICLES PER ASN)
      *
       01  WS-856-VEH-TABLE.
           05  WS-856-MAX-VEHICLES       PIC S9(04)   COMP
                                                       VALUE +25.
           05  WS-856-VEH-COUNT          PIC S9(04)   COMP
                                                       VALUE +0.
      *
       LINKAGE SECTION.
      *
      *    EDI PARSE REQUEST
      *
       01  LS-EDI-REQUEST.
           05  LS-ER-MSG-TYPE            PIC X(03).
               88  LS-ER-IS-214                       VALUE '214'.
               88  LS-ER-IS-856                       VALUE '856'.
           05  LS-ER-MSG-BUFFER          PIC X(4096).
           05  LS-ER-MSG-LENGTH          PIC S9(04)   COMP.
      *
      *    EDI PARSE RESULT
      *
       01  LS-EDI-RESULT.
           05  LS-EP-RETURN-CODE         PIC S9(04)   COMP.
           05  LS-EP-RETURN-MSG          PIC X(79).
           05  LS-EP-SEGMENT-COUNT       PIC S9(04)   COMP.
           05  LS-EP-ERROR-COUNT         PIC S9(04)   COMP.
      *    214 PARSED FIELDS
           05  LS-EP-214-DATA.
               10  LS-EP-214-SHIPMENT-ID PIC X(20).
               10  LS-EP-214-REF-NUM     PIC X(20).
               10  LS-EP-214-CARRIER     PIC X(04).
               10  LS-EP-214-SCAC        PIC X(04).
               10  LS-EP-214-STATUS-CODE PIC X(02).
               10  LS-EP-214-STATUS-DATE PIC X(08).
               10  LS-EP-214-STATUS-TIME PIC X(06).
               10  LS-EP-214-CITY        PIC X(30).
               10  LS-EP-214-STATE       PIC X(02).
               10  LS-EP-214-ZIP         PIC X(09).
               10  LS-EP-214-VIN         PIC X(17).
               10  LS-EP-214-DEST-DEALER PIC X(05).
               10  LS-EP-214-ETA-DATE    PIC X(08).
      *    856 PARSED FIELDS
           05  LS-EP-856-DATA.
               10  LS-EP-856-SHIPMENT-ID PIC X(20).
               10  LS-EP-856-BOL         PIC X(20).
               10  LS-EP-856-SHIP-DATE   PIC X(08).
               10  LS-EP-856-CARRIER     PIC X(04).
               10  LS-EP-856-SCAC        PIC X(04).
               10  LS-EP-856-DEST-DEALER PIC X(05).
               10  LS-EP-856-DEST-NAME   PIC X(35).
               10  LS-EP-856-VEH-COUNT   PIC S9(04)   COMP.
               10  LS-EP-856-VEHICLES.
                   15  LS-EP-856-VEH-ENTRY
                                          OCCURS 25 TIMES.
                       20  LS-EP-856-VEH-VIN
                                          PIC X(17).
                       20  LS-EP-856-VEH-MAKE
                                          PIC X(10).
                       20  LS-EP-856-VEH-MODEL
                                          PIC X(20).
                       20  LS-EP-856-VEH-YEAR
                                          PIC 9(04).
      *    CONTROL NUMBER VALIDATION
           05  LS-EP-ISA-CONTROL         PIC 9(09).
           05  LS-EP-GS-CONTROL          PIC 9(09).
           05  LS-EP-ST-CONTROL          PIC X(09).
      *
       PROCEDURE DIVISION USING LS-EDI-REQUEST
                                LS-EDI-RESULT.
      *
       0000-MAIN-CONTROL.
      *
           PERFORM 1000-INITIALIZE
      *
           PERFORM 2000-VALIDATE-INPUTS
      *
           IF LS-EP-RETURN-CODE = +0
               PERFORM 3000-PARSE-ENVELOPE
           END-IF
      *
           IF LS-EP-RETURN-CODE = +0
               EVALUATE TRUE
                   WHEN LS-ER-IS-214
                       PERFORM 4000-PARSE-214-MESSAGE
                   WHEN LS-ER-IS-856
                       PERFORM 5000-PARSE-856-MESSAGE
               END-EVALUATE
           END-IF
      *
           IF LS-EP-RETURN-CODE = +0
               PERFORM 6000-VALIDATE-TRAILER
           END-IF
      *
           GOBACK
           .
      *
      ****************************************************************
      *    1000-INITIALIZE - CLEAR RESULT FIELDS                     *
      ****************************************************************
       1000-INITIALIZE.
      *
           INITIALIZE LS-EDI-RESULT
           INITIALIZE WS-PARSE-WORK
           INITIALIZE WS-ELEM-WORK
           INITIALIZE WS-PARSE-FLAGS
           MOVE +0 TO LS-EP-RETURN-CODE
           MOVE +0 TO LS-EP-SEGMENT-COUNT
           MOVE +0 TO LS-EP-ERROR-COUNT
           MOVE +1 TO WS-BUFFER-POS
           MOVE 'N' TO WS-PARSE-ERROR-FLAG
           MOVE 'N' TO WS-END-OF-MSG-FLAG
           .
      *
      ****************************************************************
      *    2000-VALIDATE-INPUTS - VALIDATE REQUEST                   *
      ****************************************************************
       2000-VALIDATE-INPUTS.
      *
           IF NOT LS-ER-IS-214
           AND NOT LS-ER-IS-856
               MOVE +8 TO LS-EP-RETURN-CODE
               STRING 'COMEDIL0: UNSUPPORTED EDI TYPE: '
                      LS-ER-MSG-TYPE
                      DELIMITED BY SIZE
                      INTO LS-EP-RETURN-MSG
           END-IF
      *
           IF LS-ER-MSG-LENGTH < +20
               MOVE +8 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: MESSAGE TOO SHORT TO PARSE'
                   TO LS-EP-RETURN-MSG
           END-IF
      *
           IF LS-ER-MSG-LENGTH > +4096
               MOVE +8 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: MESSAGE EXCEEDS 4096 BYTE LIMIT'
                   TO LS-EP-RETURN-MSG
           END-IF
      *
           MOVE LS-ER-MSG-LENGTH TO WS-BUFFER-LEN
           .
      *
      ****************************************************************
      *    3000-PARSE-ENVELOPE - PARSE ISA/GS/ST HEADERS             *
      ****************************************************************
       3000-PARSE-ENVELOPE.
      *
      *    EXTRACT FIRST SEGMENT (SHOULD BE ISA)
      *
           PERFORM 8000-GET-NEXT-SEGMENT
      *
           IF WS-SEGMENT-ID NOT = 'ISA'
               MOVE +8 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: EXPECTED ISA SEGMENT NOT FOUND'
                   TO LS-EP-RETURN-MSG
               GOBACK
           END-IF
      *
      *    PARSE ISA ELEMENTS
      *
           PERFORM 8100-PARSE-SEGMENT-ELEMENTS
      *
      *    ISA CONTROL NUMBER IS ELEMENT 13
      *
           IF WS-ELEMENT-COUNT >= +13
               MOVE WS-ELEM-VALUE(13)
                   TO LS-EP-ISA-CONTROL
           END-IF
      *
           ADD +1 TO LS-EP-SEGMENT-COUNT
      *
      *    NEXT SHOULD BE GS (FUNCTIONAL GROUP)
      *
           PERFORM 8000-GET-NEXT-SEGMENT
      *
           IF WS-SEGMENT-ID NOT = 'GS '
               MOVE +8 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: EXPECTED GS SEGMENT NOT FOUND'
                   TO LS-EP-RETURN-MSG
               GOBACK
           END-IF
      *
           PERFORM 8100-PARSE-SEGMENT-ELEMENTS
      *
      *    GS CONTROL NUMBER IS ELEMENT 6
      *
           IF WS-ELEMENT-COUNT >= +6
               MOVE WS-ELEM-VALUE(6)
                   TO LS-EP-GS-CONTROL
           END-IF
      *
           ADD +1 TO LS-EP-SEGMENT-COUNT
      *
      *    NEXT SHOULD BE ST (TRANSACTION SET HEADER)
      *
           PERFORM 8000-GET-NEXT-SEGMENT
      *
           IF WS-SEGMENT-ID NOT = 'ST '
               MOVE +8 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: EXPECTED ST SEGMENT NOT FOUND'
                   TO LS-EP-RETURN-MSG
               GOBACK
           END-IF
      *
           PERFORM 8100-PARSE-SEGMENT-ELEMENTS
      *
      *    VALIDATE TRANSACTION SET ID MATCHES REQUEST TYPE
      *
           IF WS-ELEMENT-COUNT >= +1
               IF WS-ELEM-VALUE(1)(1:3) NOT = LS-ER-MSG-TYPE
                   MOVE +8 TO LS-EP-RETURN-CODE
                   MOVE 'COMEDIL0: ST TYPE DOES NOT MATCH REQUEST'
                       TO LS-EP-RETURN-MSG
                   GOBACK
               END-IF
           END-IF
      *
           IF WS-ELEMENT-COUNT >= +2
               MOVE WS-ELEM-VALUE(2)
                   TO LS-EP-ST-CONTROL
           END-IF
      *
           ADD +1 TO LS-EP-SEGMENT-COUNT
           .
      *
      ****************************************************************
      *    4000-PARSE-214-MESSAGE - PARSE EDI 214 BODY SEGMENTS      *
      *    B10 = BEGINNING SEGMENT                                   *
      *    L11 = REFERENCE NUMBERS                                   *
      *    AT7 = SHIPMENT STATUS DETAIL                              *
      *    MS1/MS2 = EQUIPMENT/VEHICLE INFO                          *
      ****************************************************************
       4000-PARSE-214-MESSAGE.
      *
      *    LOOP THROUGH REMAINING SEGMENTS
      *
           PERFORM UNTIL WS-END-OF-MSG
               OR WS-PARSE-ERROR
      *
               PERFORM 8000-GET-NEXT-SEGMENT
      *
               IF NOT WS-END-OF-MSG
                   PERFORM 8100-PARSE-SEGMENT-ELEMENTS
                   ADD +1 TO LS-EP-SEGMENT-COUNT
      *
                   EVALUATE WS-SEGMENT-ID
      *
      *                B10 - BEGINNING SEGMENT FOR 214
      *
                       WHEN 'B10'
                           IF WS-ELEMENT-COUNT >= +1
                               MOVE WS-ELEM-VALUE(1)
                                   TO LS-EP-214-REF-NUM
                           END-IF
                           IF WS-ELEMENT-COUNT >= +2
                               MOVE WS-ELEM-VALUE(2)
                                   TO LS-EP-214-SHIPMENT-ID
                           END-IF
                           IF WS-ELEMENT-COUNT >= +3
                               MOVE WS-ELEM-VALUE(3)
                                   TO LS-EP-214-SCAC
                           END-IF
      *
      *                L11 - REFERENCE NUMBERS
      *
                       WHEN 'L11'
                           IF WS-ELEMENT-COUNT >= +1
      *                        CHECK QUALIFIER IN ELEMENT 2
                               IF WS-ELEMENT-COUNT >= +2
                                   IF WS-ELEM-VALUE(2)(1:2) = 'VN'
                                       MOVE WS-ELEM-VALUE(1)
                                           TO LS-EP-214-VIN
                                   END-IF
                               END-IF
                           END-IF
      *
      *                AT7 - SHIPMENT STATUS DETAIL
      *
                       WHEN 'AT7'
                           IF WS-ELEMENT-COUNT >= +1
                               MOVE WS-ELEM-VALUE(1)
                                   TO LS-EP-214-STATUS-CODE
                           END-IF
      *
      *                AT8 - SHIPMENT STATUS DATE/TIME
      *
                       WHEN 'AT8'
                           IF WS-ELEMENT-COUNT >= +1
                               MOVE WS-ELEM-VALUE(1)
                                   TO LS-EP-214-STATUS-DATE
                           END-IF
                           IF WS-ELEMENT-COUNT >= +2
                               MOVE WS-ELEM-VALUE(2)
                                   TO LS-EP-214-STATUS-TIME
                           END-IF
      *
      *                MS1 - EQUIPMENT CITY/STATE/ZIP
      *
                       WHEN 'MS1'
                           IF WS-ELEMENT-COUNT >= +1
                               MOVE WS-ELEM-VALUE(1)
                                   TO LS-EP-214-CITY
                           END-IF
                           IF WS-ELEMENT-COUNT >= +2
                               MOVE WS-ELEM-VALUE(2)
                                   TO LS-EP-214-STATE
                           END-IF
                           IF WS-ELEMENT-COUNT >= +3
                               MOVE WS-ELEM-VALUE(3)
                                   TO LS-EP-214-ZIP
                           END-IF
      *
      *                N1 - NAME SEGMENT (DESTINATION DEALER)
      *
                       WHEN 'N1 '
                           IF WS-ELEMENT-COUNT >= +1
                               IF WS-ELEM-VALUE(1)(1:2) = 'ST'
                                   IF WS-ELEMENT-COUNT >= +4
                                       MOVE WS-ELEM-VALUE(4)
                                        TO LS-EP-214-DEST-DEALER
                                   END-IF
                               END-IF
                           END-IF
      *
      *                DTM - DATE/TIME REFERENCE (ETA)
      *
                       WHEN 'DTM'
                           IF WS-ELEMENT-COUNT >= +1
                               IF WS-ELEM-VALUE(1)(1:3) = '017'
                                   IF WS-ELEMENT-COUNT >= +2
                                       MOVE WS-ELEM-VALUE(2)
                                           TO LS-EP-214-ETA-DATE
                                   END-IF
                               END-IF
                           END-IF
      *
      *                SE/GE/IEA - TRAILER SEGMENTS
      *
                       WHEN 'SE '
                       WHEN 'GE '
                       WHEN 'IEA'
                           CONTINUE
      *
                       WHEN OTHER
      *                    UNKNOWN SEGMENT - SKIP
                           CONTINUE
                   END-EVALUATE
               END-IF
      *
           END-PERFORM
      *
           IF NOT WS-PARSE-ERROR
               MOVE +0 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: EDI 214 PARSED SUCCESSFULLY'
                   TO LS-EP-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    5000-PARSE-856-MESSAGE - PARSE EDI 856 BODY SEGMENTS      *
      *    BSN = BEGINNING SEGMENT FOR SHIP NOTICE                   *
      *    HL  = HIERARCHICAL LEVEL                                  *
      *    REF = REFERENCE ID (VIN)                                  *
      *    DTM = DATE/TIME                                           *
      *    TD5 = CARRIER DETAILS                                     *
      *    N1  = NAME (DESTINATION)                                  *
      *    LIN = ITEM IDENTIFICATION                                 *
      ****************************************************************
       5000-PARSE-856-MESSAGE.
      *
           MOVE +0 TO WS-856-VEH-COUNT
      *
           PERFORM UNTIL WS-END-OF-MSG
               OR WS-PARSE-ERROR
      *
               PERFORM 8000-GET-NEXT-SEGMENT
      *
               IF NOT WS-END-OF-MSG
                   PERFORM 8100-PARSE-SEGMENT-ELEMENTS
                   ADD +1 TO LS-EP-SEGMENT-COUNT
      *
                   EVALUATE WS-SEGMENT-ID
      *
      *                BSN - BEGINNING SEGMENT FOR ASN
      *
                       WHEN 'BSN'
                           IF WS-ELEMENT-COUNT >= +2
                               MOVE WS-ELEM-VALUE(2)
                                   TO LS-EP-856-SHIPMENT-ID
                           END-IF
                           IF WS-ELEMENT-COUNT >= +3
                               MOVE WS-ELEM-VALUE(3)
                                   TO LS-EP-856-SHIP-DATE
                           END-IF
      *
      *                HL - HIERARCHICAL LEVEL
      *
                       WHEN 'HL '
                           IF WS-ELEMENT-COUNT >= +3
                               IF WS-ELEM-VALUE(3)(1:1) = 'S'
                                   MOVE 'S' TO WS-HL-LEVEL
                               ELSE
                                   MOVE 'I' TO WS-HL-LEVEL
                               END-IF
                           END-IF
      *
      *                TD5 - CARRIER DETAILS
      *
                       WHEN 'TD5'
                           IF WS-ELEMENT-COUNT >= +3
                               MOVE WS-ELEM-VALUE(3)
                                   TO LS-EP-856-SCAC
                           END-IF
                           IF WS-ELEMENT-COUNT >= +4
                               MOVE WS-ELEM-VALUE(4)
                                   TO LS-EP-856-CARRIER
                           END-IF
      *
      *                REF - REFERENCE IDS
      *
                       WHEN 'REF'
                           IF WS-ELEMENT-COUNT >= +2
                               IF WS-ELEM-VALUE(1)(1:2) = 'VN'
      *                            VIN REFERENCE
                                   IF WS-856-VEH-COUNT
                                       < +25
                                       ADD +1 TO WS-856-VEH-COUNT
                                       MOVE WS-ELEM-VALUE(2)
                                        TO LS-EP-856-VEH-VIN
                                            (WS-856-VEH-COUNT)
                                   END-IF
                               END-IF
                               IF WS-ELEM-VALUE(1)(1:2) = 'BM'
      *                            BILL OF LADING
                                   MOVE WS-ELEM-VALUE(2)
                                       TO LS-EP-856-BOL
                               END-IF
                           END-IF
      *
      *                N1 - NAME SEGMENT
      *
                       WHEN 'N1 '
                           IF WS-ELEMENT-COUNT >= +1
                               IF WS-ELEM-VALUE(1)(1:2) = 'ST'
      *                            SHIP-TO (DESTINATION DEALER)
                                   IF WS-ELEMENT-COUNT >= +2
                                       MOVE WS-ELEM-VALUE(2)
                                        TO LS-EP-856-DEST-NAME
                                   END-IF
                                   IF WS-ELEMENT-COUNT >= +4
                                       MOVE WS-ELEM-VALUE(4)
                                        TO LS-EP-856-DEST-DEALER
                                   END-IF
                               END-IF
                           END-IF
      *
      *                LIN - LINE ITEM
      *
                       WHEN 'LIN'
                           IF WS-ELEMENT-COUNT >= +3
                               IF WS-ELEM-VALUE(2)(1:2) = 'VN'
                                   IF WS-856-VEH-COUNT
                                       < +25
                                   AND WS-856-VEH-COUNT > +0
                                       CONTINUE
                                   END-IF
                               END-IF
                           END-IF
      *
      *                DTM - DATE/TIME REFERENCE
      *
                       WHEN 'DTM'
                           IF WS-ELEMENT-COUNT >= +2
                               IF WS-ELEM-VALUE(1)(1:3) = '011'
      *                            SHIPPED DATE
                                   MOVE WS-ELEM-VALUE(2)
                                       TO LS-EP-856-SHIP-DATE
                               END-IF
                           END-IF
      *
      *                TRAILER SEGMENTS
      *
                       WHEN 'SE '
                       WHEN 'GE '
                       WHEN 'IEA'
                           CONTINUE
      *
                       WHEN OTHER
                           CONTINUE
                   END-EVALUATE
               END-IF
      *
           END-PERFORM
      *
           MOVE WS-856-VEH-COUNT TO LS-EP-856-VEH-COUNT
      *
           IF NOT WS-PARSE-ERROR
               MOVE +0 TO LS-EP-RETURN-CODE
               MOVE 'COMEDIL0: EDI 856 PARSED SUCCESSFULLY'
                   TO LS-EP-RETURN-MSG
           END-IF
           .
      *
      ****************************************************************
      *    6000-VALIDATE-TRAILER - VALIDATE SE SEGMENT COUNT         *
      ****************************************************************
       6000-VALIDATE-TRAILER.
      *
      *    SE SEGMENT CONTAINS COUNT OF SEGMENTS IN TRANSACTION
      *    (ALREADY INCREMENTED LS-EP-SEGMENT-COUNT)
      *    VALIDATION WOULD COMPARE SE COUNT TO OUR COUNT
      *
           IF LS-EP-ERROR-COUNT > +0
               MOVE +4 TO LS-EP-RETURN-CODE
               STRING 'COMEDIL0: PARSED WITH '
                      LS-EP-ERROR-COUNT ' ERRORS'
                      DELIMITED BY SIZE
                      INTO LS-EP-RETURN-MSG
           ELSE
               MOVE +0 TO LS-EP-RETURN-CODE
           END-IF
           .
      *
      ****************************************************************
      *    8000-GET-NEXT-SEGMENT - EXTRACT NEXT SEGMENT FROM BUFFER  *
      *    SEGMENTS TERMINATED BY '~'                                *
      ****************************************************************
       8000-GET-NEXT-SEGMENT.
      *
           MOVE SPACES TO WS-RAW-SEGMENT
           MOVE SPACES TO WS-SEGMENT-ID
      *
      *    CHECK IF WE HAVE REACHED END OF BUFFER
      *
           IF WS-BUFFER-POS >= WS-BUFFER-LEN
               MOVE 'Y' TO WS-END-OF-MSG-FLAG
           ELSE
      *
      *        FIND NEXT SEGMENT TERMINATOR '~'
      *
               MOVE WS-BUFFER-POS TO WS-SEG-START
      *
               INSPECT LS-ER-MSG-BUFFER(WS-BUFFER-POS:
                   WS-BUFFER-LEN - WS-BUFFER-POS + 1)
                   TALLYING WS-TALLY-COUNT
                   FOR CHARACTERS BEFORE INITIAL '~'
      *
               IF WS-TALLY-COUNT > +0
                   COMPUTE WS-SEG-END =
                       WS-BUFFER-POS + WS-TALLY-COUNT - 1
      *
                   MOVE LS-ER-MSG-BUFFER(
                       WS-BUFFER-POS:WS-TALLY-COUNT)
                       TO WS-RAW-SEGMENT
      *
      *            EXTRACT SEGMENT ID (FIRST 2-3 CHARS BEFORE '*')
      *
                   UNSTRING WS-RAW-SEGMENT
                       DELIMITED BY '*'
                       INTO WS-SEGMENT-ID
                   END-UNSTRING
      *
      *            ADVANCE PAST THE '~' TERMINATOR
      *
                   COMPUTE WS-BUFFER-POS =
                       WS-SEG-END + 2
               ELSE
      *            NO MORE TERMINATORS - END OF MESSAGE
                   MOVE 'Y' TO WS-END-OF-MSG-FLAG
               END-IF
      *
               MOVE +0 TO WS-TALLY-COUNT
           END-IF
           .
      *
      ****************************************************************
      *    8100-PARSE-SEGMENT-ELEMENTS - SPLIT SEGMENT ON '*'       *
      ****************************************************************
       8100-PARSE-SEGMENT-ELEMENTS.
      *
           INITIALIZE WS-ELEMENT-TABLE
           INITIALIZE WS-ELEM-WORK
           MOVE +0 TO WS-ELEMENT-COUNT
      *
      *    UNSTRING RAW SEGMENT INTO ELEMENTS DELIMITED BY '*'
      *
           UNSTRING WS-RAW-SEGMENT
               DELIMITED BY '*'
               INTO WS-SEGMENT-ID
                    WS-ELEM-01
                    WS-ELEM-02
                    WS-ELEM-03
                    WS-ELEM-04
                    WS-ELEM-05
                    WS-ELEM-06
                    WS-ELEM-07
                    WS-ELEM-08
                    WS-ELEM-09
                    WS-ELEM-10
               TALLYING IN WS-ELEMENT-COUNT
           END-UNSTRING
      *
      *    SUBTRACT 1 FOR SEGMENT ID ITSELF
      *
           SUBTRACT +1 FROM WS-ELEMENT-COUNT
      *
      *    COPY TO INDEXED TABLE FOR EASY ACCESS
      *
           IF WS-ELEMENT-COUNT >= +1
               MOVE WS-ELEM-01 TO WS-ELEM-VALUE(1)
           END-IF
           IF WS-ELEMENT-COUNT >= +2
               MOVE WS-ELEM-02 TO WS-ELEM-VALUE(2)
           END-IF
           IF WS-ELEMENT-COUNT >= +3
               MOVE WS-ELEM-03 TO WS-ELEM-VALUE(3)
           END-IF
           IF WS-ELEMENT-COUNT >= +4
               MOVE WS-ELEM-04 TO WS-ELEM-VALUE(4)
           END-IF
           IF WS-ELEMENT-COUNT >= +5
               MOVE WS-ELEM-05 TO WS-ELEM-VALUE(5)
           END-IF
           IF WS-ELEMENT-COUNT >= +6
               MOVE WS-ELEM-06 TO WS-ELEM-VALUE(6)
           END-IF
           IF WS-ELEMENT-COUNT >= +7
               MOVE WS-ELEM-07 TO WS-ELEM-VALUE(7)
           END-IF
           IF WS-ELEMENT-COUNT >= +8
               MOVE WS-ELEM-08 TO WS-ELEM-VALUE(8)
           END-IF
           IF WS-ELEMENT-COUNT >= +9
               MOVE WS-ELEM-09 TO WS-ELEM-VALUE(9)
           END-IF
           IF WS-ELEMENT-COUNT >= +10
               MOVE WS-ELEM-10 TO WS-ELEM-VALUE(10)
           END-IF
           .
      ****************************************************************
      * END OF COMEDIL0                                               *
      ****************************************************************
