/* REXX - ASSUBMIT: Job Submission Helper for AUTOSALES              */
/*                                                                   */
/* Description: Prompts user for batch job type, lists available     */
/*              JCLs, allows date override, submits selected JCL     */
/*              via SUBMIT command, and displays job number.          */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASSUBMIT)' EXEC             */
/*              TSO ASSUBMIT ?     (for help)                        */
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

  /* Dataset HLQ for JCL libraries */
  hlq = 'AUTOSALE'
  jcllib = hlq'.JCL'

  /* Define job types and their JCL members */
  daily_jobs   = 'BATDLY00 BATVAL00 BATPUR00'
  weekly_jobs  = 'BATWKL00 BATCRM00'
  monthly_jobs = 'BATMTH00 BATGLINT'
  report_jobs  = 'RPTDLY00 RPTWKL00 RPTMTH00 RPTINV00 RPTCOM00',
                 'RPTFIN00 RPTCUS00 RPTMFG00 RPTAGN00 RPTWAR00',
                 'RPTPRF00 RPTFPL00 RPTREG00 RPTSUP00'
  utility_jobs = 'BATDMS00 BATDLAKE BATINB00 BATRSTRT'

  /* Display menu */
  SAY ''
  SAY COPIES('=',60)
  SAY '   AUTOSALES - Batch Job Submission Helper'
  SAY COPIES('=',60)
  SAY ''
  SAY '  Select job type:'
  SAY ''
  SAY '    1  Daily batch jobs'
  SAY '    2  Weekly batch jobs'
  SAY '    3  Monthly batch jobs'
  SAY '    4  Report jobs'
  SAY '    5  Utility jobs'
  SAY '    X  Exit'
  SAY ''
  SAY COPIES('-',60)
  CALL CHAROUT , '  Enter selection: '
  PULL selection

  IF selection = 'X' THEN DO
    SAY 'Job submission cancelled.'
    EXIT 0
  END

  /* Determine job list based on selection */
  SELECT
    WHEN selection = 1 THEN job_list = daily_jobs
    WHEN selection = 2 THEN job_list = weekly_jobs
    WHEN selection = 3 THEN job_list = monthly_jobs
    WHEN selection = 4 THEN job_list = report_jobs
    WHEN selection = 5 THEN job_list = utility_jobs
    OTHERWISE DO
      SAY '*** Invalid selection:' selection
      EXIT 8
    END
  END

  /* Display available JCLs for selected type */
  SAY ''
  SAY '  Available JCLs:'
  SAY ''
  job_count = WORDS(job_list)
  DO i = 1 TO job_count
    member = WORD(job_list, i)
    SAY '   ' RIGHT(i,2)'.  'member
  END
  SAY ''
  CALL CHAROUT , '  Enter number to submit (or X to cancel): '
  PULL job_sel

  IF job_sel = 'X' THEN DO
    SAY 'Job submission cancelled.'
    EXIT 0
  END

  IF DATATYPE(job_sel,'W') = 0 | job_sel < 1 | job_sel > job_count THEN DO
    SAY '*** Invalid job selection:' job_sel
    EXIT 8
  END

  submit_member = WORD(job_list, job_sel)

  /* For report jobs, allow date parameter override */
  run_date = ''
  IF selection = 4 THEN DO
    SAY ''
    CALL CHAROUT , '  Report date override (YYYY-MM-DD or ENTER for today): '
    PULL run_date
    IF run_date = '' THEN
      run_date = DATE('S')
    ELSE DO
      /* Validate date format */
      IF LENGTH(run_date) \= 10 THEN DO
        SAY '*** Invalid date format. Use YYYY-MM-DD'
        EXIT 8
      END
    END
    SAY '  Report date set to:' run_date
  END

  /* Confirm submission */
  SAY ''
  SAY '  Submitting:' submit_member
  SAY '  From:      ' jcllib'('submit_member')'
  IF run_date \= '' THEN
    SAY '  Run date:  ' run_date
  SAY ''
  CALL CHAROUT , '  Confirm submit? (Y/N): '
  PULL confirm

  IF confirm \= 'Y' THEN DO
    SAY 'Job submission cancelled.'
    EXIT 0
  END

  /* Build and submit the JCL */
  submit_dsn = "'"jcllib"("submit_member")'"

  IF run_date \= '' THEN DO
    /* For date-parameterized jobs, edit JCL inline before submit */
    ADDRESS TSO "ALLOC FI(JCLIN) DA("submit_dsn") SHR REUSE"
    ADDRESS TSO "SUBMIT "submit_dsn
  END
  ELSE DO
    ADDRESS TSO "SUBMIT "submit_dsn
  END

  /* Capture job number from submit */
  submit_rc = RC
  IF submit_rc = 0 THEN DO
    SAY ''
    SAY COPIES('=',60)
    SAY '  Job' submit_member 'submitted successfully.'
    SAY '  Use ASSTATUS to monitor job progress.'
    SAY COPIES('=',60)
  END
  ELSE DO
    SAY ''
    SAY '*** SUBMIT failed with RC='submit_rc
    SAY '*** Check dataset:' jcllib'('submit_member')'
  END

  EXIT submit_rc

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASSUBMIT - AUTOSALES Job Submission Helper'
  SAY ''
  SAY 'Interactively select and submit AUTOSALES batch JCLs.'
  SAY 'Job types: daily, weekly, monthly, report, utility.'
  SAY 'Report jobs allow a date parameter override.'
  SAY ''
  SAY 'Usage:  TSO ASSUBMIT      (interactive mode)'
  SAY '        TSO ASSUBMIT ?    (this help)'
  SAY ''
  RETURN

/* ----------------------------------------------------------------- */
/* Error handlers                                                    */
/* ----------------------------------------------------------------- */
ERROR:
  SAY '*** Error at line' SIGL':' SOURCELINE(SIGL)
  SAY '*** RC='RC
  EXIT 12

SYNTAX:
  SAY '*** Syntax error at line' SIGL':' ERRORTEXT(RC)
  EXIT 12
