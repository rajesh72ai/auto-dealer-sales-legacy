      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.RECALL_CAMPAIGN)                      *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLRCCMP))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLRECALL-CAMPAIGN)                           *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.RECALL_CAMPAIGN TABLE
           ( RECALL_ID        CHAR(10) NOT NULL,
             NHTSA_NUM        CHAR(12),
             RECALL_DESC      VARCHAR(200) NOT NULL,
             SEVERITY         CHAR(1) NOT NULL,
             AFFECTED_YEARS   VARCHAR(40) NOT NULL,
             AFFECTED_MODELS  VARCHAR(100) NOT NULL,
             REMEDY_DESC      VARCHAR(200) NOT NULL,
             REMEDY_AVAIL_DT  DATE,
             ANNOUNCED_DATE   DATE NOT NULL,
             TOTAL_AFFECTED   INTEGER NOT NULL,
             TOTAL_COMPLETED  INTEGER NOT NULL,
             CAMPAIGN_STATUS  CHAR(1) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.RECALL_CAMPAIGN         *
      ******************************************************************
       01  DCLRECALL-CAMPAIGN.
           10 RECALL-ID         PIC X(10).
           10 NHTSA-NUM         PIC X(12).
           10 RECALL-DESC.
              49 RECALL-DESC-LN PIC S9(4) COMP.
              49 RECALL-DESC-TX PIC X(200).
           10 SEVERITY          PIC X(1).
           10 AFFECTED-YEARS.
              49 AFFECTED-YEARS-LN PIC S9(4) COMP.
              49 AFFECTED-YEARS-TX PIC X(40).
           10 AFFECTED-MODELS.
              49 AFFECTED-MODELS-LN PIC S9(4) COMP.
              49 AFFECTED-MODELS-TX PIC X(100).
           10 REMEDY-DESC.
              49 REMEDY-DESC-LN PIC S9(4) COMP.
              49 REMEDY-DESC-TX PIC X(200).
           10 REMEDY-AVAIL-DT   PIC X(10).
           10 ANNOUNCED-DATE    PIC X(10).
           10 TOTAL-AFFECTED    PIC S9(9) COMP.
           10 TOTAL-COMPLETED   PIC S9(9) COMP.
           10 CAMPAIGN-STATUS   PIC X(1).
           10 CREATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 13     *
      ******************************************************************
