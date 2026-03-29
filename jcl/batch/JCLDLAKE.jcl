//*********************************************************************
//* JCL:      JCLDLAKE
//* SYSTEM:   AUTOSALES - AUTOMOTIVE DEALER SALES & REPORTING
//* PURPOSE:  DATA LAKE EXTRACT
//*           1. EXECUTE BATDLAKE - EXTRACT DELTA CHANGES FROM
//*              DB2 TABLES SINCE LAST EXTRACT
//*           2. SORT/TRANSFORM TO PARQUET-COMPATIBLE DELIMITED FORMAT
//*           3. FTP EXTRACT FILES TO DATA LAKE LANDING ZONE
//* SCHEDULE: DAILY 01:00 CST
//* ON ERROR: RETRY ONCE, THEN ALERT DATA ENGINEERING TEAM
//*********************************************************************
//AUTOSLDL JOB (ACCT),'AUTOSALES-DLAKE',CLASS=A,MSGCLASS=H,
//          MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*
//JOBLIB   DD DSN=AUTOSALE.PROD.LOADLIB,DISP=SHR
//         DD DSN=DSNLOAD,DISP=SHR
//*
//* JES2 OUTPUT FOR SYSLOG
//*
//OUTPUT01 OUTPUT JESDS=ALL,CLASS=H,DEFAULT=YES
//*
//*-------------------------------------------------------------------
//* STEP010 - EXECUTE DATA LAKE EXTRACT (IMS BMP)
//*-------------------------------------------------------------------
//EXTRACT  EXEC IMSBATCH,MBR=BATDLAKE,
//         PSB=PSBBAT01,
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
//EXTVEH   DD DSN=AUTOSALE.WORK.DLAKE.VEHICLE,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(100,30),RLSE),
//         DCB=(RECFM=FB,LRECL=600,BLKSIZE=0)
//EXTDEAL  DD DSN=AUTOSALE.WORK.DLAKE.DEALS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(80,20),RLSE),
//         DCB=(RECFM=FB,LRECL=800,BLKSIZE=0)
//EXTCUST  DD DSN=AUTOSALE.WORK.DLAKE.CUSTOMER,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(50,10),RLSE),
//         DCB=(RECFM=FB,LRECL=400,BLKSIZE=0)
//CTLCARD  DD *
  EXTRACT-DATE=&LYYMMDD
  EXTRACT-TYPE=DELTA
  DELIMITER=PIPE
  NULL-INDICATOR=\N
  TIMESTAMP-FMT=ISO
/*
//*
//*-------------------------------------------------------------------
//* STEP020 - SORT VEHICLE EXTRACT AND ADD PIPE DELIMITERS
//*-------------------------------------------------------------------
//SORTVEH  EXEC PGM=ICETOOL,COND=(4,LT,EXTRACT)
//TOOLMSG  DD SYSOUT=*
//DFSMSG   DD SYSOUT=*
//INVEH    DD DSN=AUTOSALE.WORK.DLAKE.VEHICLE,DISP=SHR
//OUTVEH   DD DSN=AUTOSALE.WORK.DLAKE.VEH.PIPE,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(100,30),RLSE),
//         DCB=(RECFM=VB,LRECL=700,BLKSIZE=0)
//TOOLIN   DD *
  SORT FROM(INVEH) TO(OUTVEH) USING(VPIP)
/*
//VPIPCNTL DD *
  SORT FIELDS=(1,17,CH,A)
  OUTREC FIELDS=(1,17,C'|',
                 18,5,C'|',
                 23,4,ZD,EDIT=(TTTT),C'|',
                 27,3,C'|',
                 30,6,C'|',
                 36,3,C'|',
                 39,3,C'|',
                 42,2,C'|',
                 44,10,C'|',
                 54,10,C'|',
                 64,10,C'|',
                 74,5,ZD,EDIT=(TTTTT))
/*
//*
//*-------------------------------------------------------------------
//* STEP030 - SORT DEALS EXTRACT
//*-------------------------------------------------------------------
//SORTDEAL EXEC PGM=SORT,COND=(4,LT,EXTRACT)
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=AUTOSALE.WORK.DLAKE.DEALS,DISP=SHR
//SORTOUT  DD DSN=AUTOSALE.WORK.DLAKE.DEAL.PIPE,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(80,20),RLSE),
//         DCB=(RECFM=VB,LRECL=900,BLKSIZE=0)
//SYSIN    DD *
  SORT FIELDS=(1,10,CH,A)
  OUTREC BUILD=(1,800)
/*
//*
//*-------------------------------------------------------------------
//* STEP040 - FTP EXTRACTS TO DATA LAKE LANDING ZONE
//*-------------------------------------------------------------------
//FTP      EXEC PGM=FTP,PARM='(EXIT',COND=(4,LT,EXTRACT)
//SYSPRINT DD SYSOUT=*
//OUTPUT   DD SYSOUT=*
//INPUT    DD *
  DATALAKE.CORP.COM 21
  AUTOSALES_SVC
  XXXXXXXX
  ASCII
  CD /landing/autosales/daily
  PUT 'AUTOSALE.WORK.DLAKE.VEH.PIPE' vehicle_delta.csv
  PUT 'AUTOSALE.WORK.DLAKE.DEAL.PIPE' deals_delta.csv
  PUT 'AUTOSALE.WORK.DLAKE.CUSTOMER' customer_delta.csv
  QUIT
/*
//*
//*-------------------------------------------------------------------
//* STEP050 - CLEANUP WORK DATASETS
//*-------------------------------------------------------------------
//CLEANUP  EXEC PGM=IEFBR14,COND=(4,LT,FTP)
//DEL1     DD DSN=AUTOSALE.WORK.DLAKE.VEHICLE,
//         DISP=(OLD,DELETE,DELETE)
//DEL2     DD DSN=AUTOSALE.WORK.DLAKE.DEALS,
//         DISP=(OLD,DELETE,DELETE)
//DEL3     DD DSN=AUTOSALE.WORK.DLAKE.CUSTOMER,
//         DISP=(OLD,DELETE,DELETE)
//DEL4     DD DSN=AUTOSALE.WORK.DLAKE.VEH.PIPE,
//         DISP=(OLD,DELETE,DELETE)
//DEL5     DD DSN=AUTOSALE.WORK.DLAKE.DEAL.PIPE,
//         DISP=(OLD,DELETE,DELETE)
//
