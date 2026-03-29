//*********************************************************************
//* JCL:      JCLREORG
//* SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING
//* PURPOSE:  DB2 REORG FOR KEY TABLESPACES
//*           REORGANIZES HIGH-ACTIVITY TABLESPACES TO RECLAIM
//*           SPACE AND IMPROVE ACCESS PATHS. INCLUDES:
//*           - VEHICLE, SALES_DEAL, CUSTOMER, AUDIT_LOG
//*           - FLOOR_PLAN_VEHICLE, STOCK_POSITION
//* SCHEDULE: MONTHLY 1ST SUNDAY 02:00 CST
//* ON ERROR: CONTACT DBA - REORG FAILURES MAY LEAVE TS IN REORP
//*********************************************************************
//AUTOSLU1 JOB (ACCT),'AUTOSALES-REORG',CLASS=A,MSGCLASS=H,
//          MSGLEVEL=(1,1),NOTIFY=&SYSUID,
//          REGION=0M,TIME=120
//*
//JOBLIB   DD DSN=DSNLOAD,DISP=SHR
//*
//*-------------------------------------------------------------------
//* STEP010 - REORG VEHICLE TABLESPACE
//*-------------------------------------------------------------------
//REORGVH  EXEC PGM=IKJEFT01,DYNAMNBR=20
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  REORG TABLESPACE AUTODB.TSVEHICL
    SHRLEVEL CHANGE
    LOG YES
    SORTDATA YES
    SORTKEYS YES
    STATISTICS TABLE(ALL) INDEX(ALL) UPDATE ALL
    REPORT YES;
/*
//*
//*-------------------------------------------------------------------
//* STEP020 - REORG SALES DEAL TABLESPACE
//*-------------------------------------------------------------------
//REORGSD  EXEC PGM=IKJEFT01,DYNAMNBR=20,
//         COND=(4,LT,REORGVH)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  REORG TABLESPACE AUTODB.TSSLDEAL
    SHRLEVEL CHANGE
    LOG YES
    SORTDATA YES
    SORTKEYS YES
    STATISTICS TABLE(ALL) INDEX(ALL) UPDATE ALL
    REPORT YES;
/*
//*
//*-------------------------------------------------------------------
//* STEP030 - REORG CUSTOMER TABLESPACE
//*-------------------------------------------------------------------
//REORGCS  EXEC PGM=IKJEFT01,DYNAMNBR=20,
//         COND=(4,LT,REORGSD)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  REORG TABLESPACE AUTODB.TSCUSTMR
    SHRLEVEL CHANGE
    LOG YES
    SORTDATA YES
    STATISTICS TABLE(ALL) INDEX(ALL) UPDATE ALL
    REPORT YES;
/*
//*
//*-------------------------------------------------------------------
//* STEP040 - REORG AUDIT LOG TABLESPACE (LARGEST)
//*-------------------------------------------------------------------
//REORGAL  EXEC PGM=IKJEFT01,DYNAMNBR=20,
//         COND=(4,LT,REORGCS)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  REORG TABLESPACE AUTODB.TSAUDITL
    SHRLEVEL CHANGE
    LOG YES
    SORTDATA YES
    SORTKEYS YES
    STATISTICS TABLE(ALL) INDEX(ALL) UPDATE ALL
    REPORT YES;
/*
//*
//*-------------------------------------------------------------------
//* STEP050 - REORG FLOOR PLAN TABLESPACE
//*-------------------------------------------------------------------
//REORGFP  EXEC PGM=IKJEFT01,DYNAMNBR=20,
//         COND=(4,LT,REORGAL)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  REORG TABLESPACE AUTODB.TSFLRPLN
    SHRLEVEL CHANGE
    LOG YES
    SORTDATA YES
    STATISTICS TABLE(ALL) INDEX(ALL) UPDATE ALL
    REPORT YES;
/*
//*
//*-------------------------------------------------------------------
//* STEP060 - REORG STOCK HISTORY TABLESPACE
//*-------------------------------------------------------------------
//REORGSH  EXEC PGM=IKJEFT01,DYNAMNBR=20,
//         COND=(4,LT,REORGFP)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBAG)
  RUN PROGRAM(DSNTIAD) PLAN(DSNTIAD) -
      LIB('DSNLOAD')
  END
//SYSIN    DD *
  REORG TABLESPACE AUTODB.TSSTKHST
    SHRLEVEL CHANGE
    LOG YES
    SORTDATA YES
    STATISTICS TABLE(ALL) INDEX(ALL) UPDATE ALL
    REPORT YES;
/*
//
