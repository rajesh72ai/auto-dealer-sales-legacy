//*********************************************************************
//* JCL:      JCLVAL00
//* SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING
//* PURPOSE:  WEEKLY DATA VALIDATION
//*           1. EXECUTE BATVAL00 - CROSS-TABLE REFERENTIAL
//*              INTEGRITY CHECKS, ORPHAN DETECTION, BALANCE
//*              VERIFICATION BETWEEN DETAIL AND SUMMARY TABLES
//* SCHEDULE: SUNDAY 02:00 CST
//* ON ERROR: GENERATE EXCEPTION REPORT AND NOTIFY DBA
//*********************************************************************
//AUTOSLV0 JOB (ACCT),'AUTOSALES-VALID',CLASS=A,MSGCLASS=H,
//          MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*
//JOBLIB   DD DSN=AUTOSALE.PROD.LOADLIB,DISP=SHR
//         DD DSN=DSNLOAD,DISP=SHR
//*
//*-------------------------------------------------------------------
//* STEP010 - EXECUTE VALIDATION BATCH (IMS BMP)
//*-------------------------------------------------------------------
//VALID    EXEC IMSBATCH,MBR=BATVAL00,
//         PSB=PSBBAT05,
//         IMSID=IMSA,
//         PRTY=(7,13,2)
//STEPLIB  DD DSN=AUTOSALE.PROD.LOADLIB,DISP=SHR
//         DD DSN=DSNLOAD,DISP=SHR
//         DD DSN=IMS.RESLIB,DISP=SHR
//DFSRESLB DD DSN=IMS.RESLIB,DISP=SHR
//IMS      DD DSN=IMS.PSBLIB,DISP=SHR
//         DD DSN=IMS.DBDLIB,DISP=SHR
//PROCLIB  DD DSN=IMS.PROCLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//VALRPT   DD DSN=AUTOSALE.PROD.REPORT.VALIDATN,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(5,2),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//CTLCARD  DD *
  PROCESS-DATE=&LYYMMDD
  ORPHAN-CHECK=Y
  BALANCE-CHECK=Y
  REF-INTEGRITY=Y
  MAX-ERRORS=500
/*
//*
//*-------------------------------------------------------------------
//* STEP020 - SORT VALIDATION EXCEPTIONS BY SEVERITY
//*-------------------------------------------------------------------
//SORTEXCP EXEC PGM=SORT,
//         COND=(4,LT,VALID)
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=AUTOSALE.PROD.REPORT.VALIDATN,DISP=SHR
//SORTOUT  DD DSN=AUTOSALE.PROD.REPORT.VALIDSRT,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(5,2),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSIN    DD *
  SORT FIELDS=(2,1,CH,A,3,8,CH,A)
  INCLUDE COND=(2,1,CH,NE,C' ')
  OUTFIL FNAMES=SORTOUT
/*
//*
//*-------------------------------------------------------------------
//* STEP030 - PRINT VALIDATION SUMMARY
//*-------------------------------------------------------------------
//PRINT    EXEC PGM=IEBGENER,
//         COND=(4,LT,VALID)
//SYSUT1   DD DSN=AUTOSALE.PROD.REPORT.VALIDSRT,DISP=SHR
//SYSUT2   DD SYSOUT=A,DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*-------------------------------------------------------------------
//* STEP040 - CLEANUP WORK FILES
//*-------------------------------------------------------------------
//CLEANUP  EXEC PGM=IEFBR14,COND=(4,LT,VALID)
//DEL1     DD DSN=AUTOSALE.PROD.REPORT.VALIDATN,
//         DISP=(OLD,DELETE,DELETE)
//DEL2     DD DSN=AUTOSALE.PROD.REPORT.VALIDSRT,
//         DISP=(OLD,DELETE,DELETE)
//
