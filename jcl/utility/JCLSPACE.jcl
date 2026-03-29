//*********************************************************************
//* JCL:      JCLSPACE
//* SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING
//* PURPOSE:  IDCAMS LISTCAT FOR SPACE MONITORING
//*           CATALOGS AND REPORTS SPACE UTILIZATION FOR ALL
//*           AUTOSALES DATASETS, DB2 TABLESPACES, AND VSAM FILES
//* SCHEDULE: DAILY 05:00 CST
//* ON ERROR: NOTIFY STORAGE ADMIN IF SPACE CRITICAL
//*********************************************************************
//AUTOSLU6 JOB (ACCT),'AUTOSALES-SPACE',CLASS=A,MSGCLASS=H,
//          MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*
//*-------------------------------------------------------------------
//* STEP010 - LISTCAT ALL AUTOSALE PRODUCTION DATASETS
//*-------------------------------------------------------------------
//LCAT01   EXEC PGM=IDCAMS
//SYSPRINT DD DSN=AUTOSALE.PROD.REPORT.SPACE.PROD,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(5,2),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSIN    DD *
  LISTCAT ENTRIES(AUTOSALE.PROD.**) -
    ALL
  IF LASTCC LE 4 THEN -
    SET MAXCC = 0
/*
//*
//*-------------------------------------------------------------------
//* STEP020 - LISTCAT ALL AUTOSALE WORK DATASETS
//*-------------------------------------------------------------------
//LCAT02   EXEC PGM=IDCAMS
//SYSPRINT DD DSN=AUTOSALE.PROD.REPORT.SPACE.WORK,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(2,1),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSIN    DD *
  LISTCAT ENTRIES(AUTOSALE.WORK.**) -
    ALL
  IF LASTCC LE 4 THEN -
    SET MAXCC = 0
/*
//*
//*-------------------------------------------------------------------
//* STEP030 - LISTCAT ARCHIVE DATASETS
//*-------------------------------------------------------------------
//LCAT03   EXEC PGM=IDCAMS
//SYSPRINT DD DSN=AUTOSALE.PROD.REPORT.SPACE.ARCH,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(2,1),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSIN    DD *
  LISTCAT ENTRIES(AUTOSALE.PROD.ARCHIVE.**) -
    ALL
  IF LASTCC LE 4 THEN -
    SET MAXCC = 0
/*
//*
//*-------------------------------------------------------------------
//* STEP040 - DB2 TABLESPACE SPACE QUERY
//*-------------------------------------------------------------------
//DB2SPACE EXEC PGM=IKJEFT01,DYNAMNBR=20
//SYSTSPRT DD SYSOUT=*
//JOBLIB   DD DSN=DSNLOAD,DISP=SHR
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  SELECT DBNAME, NAME AS TSNAME,
         NACTIVE AS ACTIVE_PAGES,
         SPACE AS ALLOC_KB,
         REORGPEND, COPYPEND, CHKPEND
  FROM SYSIBM.SYSTABLESPACESTATS
  WHERE DBNAME = 'AUTODB'
  ORDER BY SPACE DESC;
/*
//*
//*-------------------------------------------------------------------
//* STEP050 - GENERATE SPACE SUMMARY REPORT
//*-------------------------------------------------------------------
//SUMMARY  EXEC PGM=SORT,COND=(0,NE)
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=AUTOSALE.PROD.REPORT.SPACE.PROD,DISP=SHR
//SORTOUT  DD SYSOUT=A
//SYSIN    DD *
  SORT FIELDS=COPY
  OUTFIL BUILD=(1,133)
  OPTION VLSHRT
/*
//
