//*********************************************************************
//* JCL:      JCLCOPY
//* SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING
//* PURPOSE:  DFDSS DATASET BACKUP
//*           FULL VOLUME COPY OF ALL AUTOSALE DATASETS TO
//*           BACKUP VOLUME FOR DISASTER RECOVERY
//* SCHEDULE: WEEKLY SUNDAY 00:00 CST
//* ON ERROR: CRITICAL - NOTIFY STORAGE ADMIN AND DBA
//*********************************************************************
//AUTOSLU5 JOB (ACCT),'AUTOSALES-COPY',CLASS=A,MSGCLASS=H,
//          MSGLEVEL=(1,1),NOTIFY=&SYSUID,
//          REGION=0M,TIME=120
//*
//*-------------------------------------------------------------------
//* STEP010 - DFDSS DUMP OF PRODUCTION LOADLIB
//*-------------------------------------------------------------------
//DMPLOAD  EXEC PGM=ADRDSSU,REGION=0M
//SYSPRINT DD SYSOUT=*
//DASD1    DD UNIT=SYSDA,VOL=SER=PROD01,DISP=SHR
//TAPE1    DD DSN=AUTOSALE.PROD.BACKUP.DFDSS.LOADLIB,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=TAPE,
//         LABEL=(1,SL),
//         DCB=(RECFM=FB,BLKSIZE=32760)
//SYSIN    DD *
  DUMP DATASET(                              -
       INCLUDE(AUTOSALE.PROD.LOADLIB)        -
       )                                     -
       OUTDDNAME(TAPE1)                      -
       OPTIMIZE(4)                           -
       COMPRESS                              -
       TOLERATE(ENQFAILURE)
/*
//*
//*-------------------------------------------------------------------
//* STEP020 - DFDSS DUMP OF DDL AND SOURCE LIBRARIES
//*-------------------------------------------------------------------
//DMPSRC   EXEC PGM=ADRDSSU,REGION=0M,
//         COND=(4,LT,DMPLOAD)
//SYSPRINT DD SYSOUT=*
//DASD1    DD UNIT=SYSDA,VOL=SER=PROD01,DISP=SHR
//TAPE2    DD DSN=AUTOSALE.PROD.BACKUP.DFDSS.SOURCE,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=TAPE,
//         LABEL=(1,SL),
//         DCB=(RECFM=FB,BLKSIZE=32760)
//SYSIN    DD *
  DUMP DATASET(                              -
       INCLUDE(AUTOSALE.PROD.DDL,            -
               AUTOSALE.PROD.DBD,            -
               AUTOSALE.PROD.PSB,            -
               AUTOSALE.PROD.MFS,            -
               AUTOSALE.PROD.COPYLIB,        -
               AUTOSALE.PROD.JCLLIB,         -
               AUTOSALE.PROD.CLIST,          -
               AUTOSALE.PROD.REXX)           -
       )                                     -
       OUTDDNAME(TAPE2)                      -
       OPTIMIZE(4)                           -
       COMPRESS                              -
       TOLERATE(ENQFAILURE)
/*
//*
//*-------------------------------------------------------------------
//* STEP030 - DFDSS DUMP OF REPORT AND ARCHIVE DATASETS
//*-------------------------------------------------------------------
//DMPRPT   EXEC PGM=ADRDSSU,REGION=0M,
//         COND=(4,LT,DMPSRC)
//SYSPRINT DD SYSOUT=*
//DASD1    DD UNIT=SYSDA,VOL=SER=PROD01,DISP=SHR
//TAPE3    DD DSN=AUTOSALE.PROD.BACKUP.DFDSS.REPORTS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=TAPE,
//         LABEL=(1,SL),
//         DCB=(RECFM=FB,BLKSIZE=32760)
//SYSIN    DD *
  DUMP DATASET(                              -
       INCLUDE(AUTOSALE.PROD.REPORT.**)      -
       )                                     -
       OUTDDNAME(TAPE3)                      -
       OPTIMIZE(4)                           -
       COMPRESS                              -
       TOLERATE(ENQFAILURE)
/*
//*
//*-------------------------------------------------------------------
//* STEP040 - DFDSS DUMP OF SEED AND CONFIGURATION DATA
//*-------------------------------------------------------------------
//DMPCONF  EXEC PGM=ADRDSSU,REGION=0M,
//         COND=(4,LT,DMPRPT)
//SYSPRINT DD SYSOUT=*
//DASD1    DD UNIT=SYSDA,VOL=SER=PROD01,DISP=SHR
//TAPE4    DD DSN=AUTOSALE.PROD.BACKUP.DFDSS.CONFIG,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=TAPE,
//         LABEL=(1,SL),
//         DCB=(RECFM=FB,BLKSIZE=32760)
//SYSIN    DD *
  DUMP DATASET(                              -
       INCLUDE(AUTOSALE.PROD.SEED.**,        -
               AUTOSALE.PROD.ARCHIVE.**)     -
       )                                     -
       OUTDDNAME(TAPE4)                      -
       OPTIMIZE(4)                           -
       COMPRESS                              -
       TOLERATE(ENQFAILURE)
/*
//
