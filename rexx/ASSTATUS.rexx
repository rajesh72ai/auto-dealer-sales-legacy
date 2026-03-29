/* REXX - ASSTATUS: Batch Job Status Monitor for AUTOSALES          */
/*                                                                   */
/* Description: Checks status of submitted AUTOSALES batch jobs      */
/*              using the SDSF REXX interface. Displays job name,    */
/*              number, status, return code, start/end time.         */
/*              Option to view SYSPRINT output.                      */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASSTATUS)' EXEC             */
/*              TSO ASSTATUS ?        (for help)                     */
/*              TSO ASSTATUS jobname  (specific job)                 */
/*                                                                   */
/* Author:      AUTOSALES Development Team                           */
/* System:      AUTOSALES - IMS DC/COBOL/DB2 z/OS                   */
/* ----------------------------------------------------------------- */
  SIGNAL ON ERROR
  SIGNAL ON SYNTAX
  PARSE ARG parm .

  IF parm = '?' THEN DO
    CALL show_help
    EXIT 0
  END

  /* AUTOSALES job name prefixes */
  as_prefix = 'AUTOSALE'

  /* If specific job name provided, use it; else show all */
  IF parm \= '' THEN
    filter_job = STRIP(parm)
  ELSE
    filter_job = as_prefix'*'

  SAY ''
  SAY COPIES('=',72)
  SAY '   AUTOSALES - Batch Job Status Monitor'
  SAY COPIES('=',72)
  SAY ''
  SAY LEFT('Job Name',8) LEFT('JobNum',8) LEFT('Status',10),
      LEFT('MaxRC',6) LEFT('Start Time',17) LEFT('End Time',17)
  SAY COPIES('-',8) COPIES('-',8) COPIES('-',10),
      COPIES('-',6) COPIES('-',17) COPIES('-',17)

  /* Access SDSF via REXX interface */
  RC = ISFCALLS('ON')
  IF RC \= 0 THEN DO
    SAY '*** Unable to initialize SDSF REXX interface. RC='RC
    SAY '*** Attempting alternate status check via STATUS command...'
    CALL check_via_status filter_job
    EXIT 0
  END

  /* Set SDSF owner filter */
  ISFOWNER = '*'
  ISFPREFIX = filter_job

  /* Query the status display (ST panel) */
  ADDRESS SDSF "ISFEXEC ST"
  st_rc = RC

  IF st_rc \= 0 THEN DO
    SAY '*** SDSF ST query failed. RC='st_rc
    RC = ISFCALLS('OFF')
    EXIT 8
  END

  /* Process returned job entries */
  job_found = 0
  DO ix = 1 TO JNAME.0
    jobname  = JNAME.ix
    jobnum   = JOBID.ix
    jobstat  = STATUS.ix
    retcode  = RETCODE.ix
    strttime = STRTTIME.ix
    endtime  = ENDTIME.ix

    /* Only show AUTOSALES jobs */
    IF LEFT(jobname,4) = 'AUTO' | LEFT(jobname,3) = 'BAT' |,
       LEFT(jobname,3) = 'RPT' THEN DO
      job_found = job_found + 1
      SAY LEFT(jobname,8) LEFT(jobnum,8) LEFT(jobstat,10),
          LEFT(retcode,6) LEFT(strttime,17) LEFT(endtime,17)
    END
  END

  IF job_found = 0 THEN DO
    SAY ''
    SAY '  No AUTOSALES jobs found matching:' filter_job
  END
  ELSE DO
    SAY ''
    SAY '  Total jobs found:' job_found
  END

  /* Offer to view SYSPRINT */
  SAY ''
  CALL CHAROUT , '  View SYSPRINT for a job? (Enter job number or N): '
  PULL view_job

  IF view_job \= 'N' & view_job \= '' THEN DO
    CALL view_sysprint view_job
  END

  RC = ISFCALLS('OFF')
  EXIT 0

/* ----------------------------------------------------------------- */
/* View SYSPRINT output for a specific job                           */
/* ----------------------------------------------------------------- */
view_sysprint:
  PARSE ARG vjob
  SAY ''
  SAY COPIES('-',72)
  SAY '  SYSPRINT output for job' vjob
  SAY COPIES('-',72)

  ISFPREFIX = vjob
  ADDRESS SDSF "ISFEXEC ST"
  IF RC = 0 THEN DO
    DO ix = 1 TO JNAME.0
      IF JOBID.ix = vjob THEN DO
        ADDRESS SDSF "ISFACT ST TOKEN('"TOKEN.ix"') PARM(NP SA)"
        IF RC = 0 THEN DO
          /* Read SYSPRINT DD */
          DO ddix = 1 TO DDNAME.0
            IF DDNAME.ddix = 'SYSPRINT' THEN DO
              ADDRESS SDSF "ISFBROWSE ST TOKEN('"TOKEN.ddix"')"
              DO lix = 1 TO ISFLINE.0
                SAY ISFLINE.lix
              END
              LEAVE
            END
          END
        END
        LEAVE
      END
    END
  END
  ELSE
    SAY '*** Unable to retrieve output for job' vjob
  RETURN

/* ----------------------------------------------------------------- */
/* Alternate status check via TSO STATUS command                     */
/* ----------------------------------------------------------------- */
check_via_status:
  PARSE ARG stat_filter
  SAY ''
  SAY '  (Using TSO STATUS command - limited information)'
  SAY ''
  ADDRESS TSO "STATUS" stat_filter
  RETURN

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASSTATUS - AUTOSALES Batch Job Status Monitor'
  SAY ''
  SAY 'Displays status of AUTOSALES batch jobs via SDSF.'
  SAY 'Shows: job name, number, status, RC, start/end time.'
  SAY ''
  SAY 'Usage:  TSO ASSTATUS           (all AUTOSALES jobs)'
  SAY '        TSO ASSTATUS jobname   (specific job)'
  SAY '        TSO ASSTATUS ?         (this help)'
  SAY ''
  RETURN

/* ----------------------------------------------------------------- */
/* Error handlers                                                    */
/* ----------------------------------------------------------------- */
ERROR:
  SAY '*** Error at line' SIGL':' SOURCELINE(SIGL)
  SAY '*** RC='RC
  RC = ISFCALLS('OFF')
  EXIT 12

SYNTAX:
  SAY '*** Syntax error at line' SIGL':' ERRORTEXT(RC)
  RC = ISFCALLS('OFF')
  EXIT 12
