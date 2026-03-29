      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.DEAL_LINE_ITEM)                       *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLDLITM))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLDEAL-LINE-ITEM)                            *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.DEAL_LINE_ITEM TABLE
           ( DEAL_NUMBER      CHAR(10) NOT NULL,
             LINE_SEQ         SMALLINT NOT NULL,
             LINE_TYPE        CHAR(2) NOT NULL,
             DESCRIPTION      VARCHAR(40) NOT NULL,
             AMOUNT           DECIMAL(11,2) NOT NULL,
             COST             DECIMAL(11,2) NOT NULL,
             TAXABLE_FLAG     CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.DEAL_LINE_ITEM          *
      ******************************************************************
       01  DCLDEAL-LINE-ITEM.
           10 DEAL-NUMBER       PIC X(10).
           10 LINE-SEQ          PIC S9(4) COMP.
           10 LINE-TYPE         PIC X(2).
           10 DESCRIPTION-TEXT.
              49 DESCRIPTION-LN PIC S9(4) COMP.
              49 DESCRIPTION-TX PIC X(40).
           10 AMOUNT            PIC S9(9)V9(2) COMP-3.
           10 COST              PIC S9(9)V9(2) COMP-3.
           10 TAXABLE-FLAG      PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7      *
      ******************************************************************
