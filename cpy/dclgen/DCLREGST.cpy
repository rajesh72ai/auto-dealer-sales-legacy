      ******************************************************************
      * DCLGEN TABLE(AUTOSALE.REGISTRATION)                         *
      *       LIBRARY(AUTOSALE.COPYLIB(DCLREGST))                   *
      *       ACTION(REPLACE)                                        *
      *       LANGUAGE(COBOL)                                        *
      *       STRUCTURE(DCLREGISTRATION)                              *
      *       APTS(YES)                                              *
      *       ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING      *
      *       STATEMENTS.                                            *
      ******************************************************************
           EXEC SQL DECLARE AUTOSALE.REGISTRATION TABLE
           ( REG_ID           CHAR(12) NOT NULL,
             DEAL_NUMBER      CHAR(10) NOT NULL,
             VIN              CHAR(17) NOT NULL,
             CUSTOMER_ID      INTEGER NOT NULL,
             REG_STATE        CHAR(2) NOT NULL,
             REG_TYPE         CHAR(2) NOT NULL,
             PLATE_NUMBER     VARCHAR(10),
             TITLE_NUMBER     VARCHAR(20),
             LIEN_HOLDER      VARCHAR(60),
             LIEN_HOLDER_ADDR VARCHAR(100),
             REG_STATUS       CHAR(2) NOT NULL,
             SUBMISSION_DATE  DATE,
             ISSUED_DATE      DATE,
             REG_FEE_PAID     DECIMAL(7,2) NOT NULL,
             TITLE_FEE_PAID   DECIMAL(7,2) NOT NULL,
             CREATED_TS       TIMESTAMP NOT NULL,
             UPDATED_TS       TIMESTAMP NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE AUTOSALE.REGISTRATION            *
      ******************************************************************
       01  DCLREGISTRATION.
           10 REG-ID            PIC X(12).
           10 DEAL-NUMBER       PIC X(10).
           10 VIN               PIC X(17).
           10 CUSTOMER-ID       PIC S9(9) COMP.
           10 REG-STATE         PIC X(2).
           10 REG-TYPE          PIC X(2).
           10 PLATE-NUMBER.
              49 PLATE-NUMBER-LN PIC S9(4) COMP.
              49 PLATE-NUMBER-TX PIC X(10).
           10 TITLE-NUMBER.
              49 TITLE-NUMBER-LN PIC S9(4) COMP.
              49 TITLE-NUMBER-TX PIC X(20).
           10 LIEN-HOLDER.
              49 LIEN-HOLDER-LN PIC S9(4) COMP.
              49 LIEN-HOLDER-TX PIC X(60).
           10 LIEN-HOLDER-ADDR.
              49 LIEN-HOLDER-ADDR-LN PIC S9(4) COMP.
              49 LIEN-HOLDER-ADDR-TX PIC X(100).
           10 REG-STATUS        PIC X(2).
           10 SUBMISSION-DATE   PIC X(10).
           10 ISSUED-DATE       PIC X(10).
           10 REG-FEE-PAID      PIC S9(5)V9(2) COMP-3.
           10 TITLE-FEE-PAID    PIC S9(5)V9(2) COMP-3.
           10 CREATED-TS        PIC X(26).
           10 UPDATED-TS        PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 17     *
      ******************************************************************
