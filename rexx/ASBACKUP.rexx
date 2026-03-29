/* REXX - ASBACKUP: Backup Orchestrator for AUTOSALES               */
/*                                                                   */
/* Description: Submits backup JCLs in correct order (DB2 UNLOAD,    */
/*              DFDSS COPY). Waits for each job to complete before    */
/*              next. Logs backup status to dataset. Sends            */
/*              notification on completion.                           */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASBACKUP)' EXEC             */
/*              TSO ASBACKUP ?         (for help)                    */
/*              TSO ASBACKUP FULL      (full backup)                 */
/*              TSO ASBACKUP INCR      (incremental)                 */
/*                                                                   */
/* Author:      AUTOSALES Development Team                           */
/* System:      AUTOSALES - IMS DC/COBOL/DB2 z/OS                   */
/* ----------------------------------------------------------------- */
  SIGNAL ON ERROR
  SIGNAL ON SYNTAX
  PARSE ARG parm .
  parm = STRIP(parm)

  IF parm = '?' THEN DO
    CALL show_help
    EXIT 0
  END

  /* Configuration */
  hlq       = 'AUTOSALE'
  jcllib    = hlq'.JCL.UTILITY'
  logdsn    = hlq'.BACKUP.LOG'
  backup_dt = DATE('S') TIME('N')
  max_wait  = 120   /* Max wait iterations (2 hours at 60-sec intervals) */
  wait_int  = 60    /* Wait interval in seconds */

  /* Determine backup type */
  IF parm = '' THEN parm = 'FULL'
  UPPER parm
  IF parm \= 'FULL' & parm \= 'INCR' THEN DO
    SAY '*** Invalid backup type:' parm '(use FULL or INCR)'
    EXIT 8
  END

  SAY ''
  SAY COPIES('=',68)
  SAY '   AUTOSALES - Backup Orchestrator'
  SAY '   Type:' parm '  Started:' DATE('U') TIME()
  SAY COPIES('=',68)

  /* Define backup job sequence */
  IF parm = 'FULL' THEN DO
    job_count = 4
    job.1 = 'BKDB2UNL'  ; desc.1 = 'DB2 Full Unload (all tables)'
    job.2 = 'BKDB2IMG'  ; desc.2 = 'DB2 Image Copy (tablespaces)'
    job.3 = 'BKVSAM'    ; desc.3 = 'DFDSS Copy (VSAM/IMS databases)'
    job.4 = 'BKGDG'     ; desc.4 = 'GDG Backup (sequential files)'
  END
  ELSE DO
    job_count = 2
    job.1 = 'BKDB2INC'  ; desc.1 = 'DB2 Incremental Image Copy'
    job.2 = 'BKVSINC'   ; desc.2 = 'DFDSS Incremental (changed extents)'
  END

  /* Log start */
  CALL write_log 'BACKUP STARTED - Type:' parm 'Date:' backup_dt

  /* Submit jobs in sequence */
  total_rc = 0
  DO i = 1 TO job_count
    SAY ''
    SAY '  Step' i 'of' job_count':' desc.i
    SAY '  Submitting' job.i'...'

    submit_dsn = "'"jcllib"("job.i")'"
    ADDRESS TSO "SUBMIT" submit_dsn
    sub_rc = RC

    IF sub_rc \= 0 THEN DO
      SAY '  *** SUBMIT failed for' job.i 'RC='sub_rc
      CALL write_log 'FAILED - Job:' job.i 'SUBMIT RC='sub_rc
      total_rc = MAX(total_rc, sub_rc)
      ITERATE
    END

    SAY '  Submitted. Waiting for completion...'
    CALL write_log 'SUBMITTED - Job:' job.i

    /* Wait for job to complete */
    completed = 0
    DO w = 1 TO max_wait
      CALL SysSleep wait_int  /* Wait interval */

      /* Check job status via SDSF */
      RC = ISFCALLS('ON')
      ISFPREFIX = job.i
      ADDRESS SDSF "ISFEXEC ST"
      IF RC = 0 THEN DO
        DO jx = 1 TO JNAME.0
          IF JNAME.jx = job.i THEN DO
            IF STATUS.jx = 'OUTPUT' | STATUS.jx = 'COMP' THEN DO
              job_rc = RETCODE.jx
              completed = 1
              LEAVE
            END
          END
        END
      END
      RC = ISFCALLS('OFF')

      IF completed THEN LEAVE

      /* Show progress */
      IF w // 10 = 0 THEN
        SAY '    ... waiting (' w * wait_int 'seconds elapsed)'
    END

    IF completed THEN DO
      SAY '  Completed. RC='job_rc
      CALL write_log 'COMPLETED - Job:' job.i 'RC='job_rc
      IF DATATYPE(job_rc,'W') = 1 THEN
        total_rc = MAX(total_rc, job_rc)
    END
    ELSE DO
      SAY '  *** TIMEOUT waiting for' job.i
      CALL write_log 'TIMEOUT - Job:' job.i
      total_rc = MAX(total_rc, 8)
      SAY '  Continue with next step? (Y/N)'
      PULL cont
      IF cont \= 'Y' THEN DO
        SAY '  Backup aborted by user.'
        CALL write_log 'ABORTED by user at step' i
        LEAVE
      END
    END
  END

  /* Summary */
  SAY ''
  SAY COPIES('=',68)
  IF total_rc <= 4 THEN
    SAY '   Backup completed successfully. Overall RC='total_rc
  ELSE
    SAY '   Backup completed with errors. Overall RC='total_rc
  SAY '   Ended:' DATE('U') TIME()
  SAY COPIES('=',68)

  CALL write_log 'BACKUP ENDED - Overall RC='total_rc

  /* Send notification */
  CALL send_notification parm total_rc

  EXIT total_rc

/* ----------------------------------------------------------------- */
/* Write to backup log dataset                                       */
/* ----------------------------------------------------------------- */
write_log:
  PARSE ARG log_msg
  log_line = DATE('S') TIME() '-' log_msg
  ADDRESS TSO "ALLOC FI(BKLOG) DA('"logdsn"') MOD REUSE"
  PUSH log_line
  ADDRESS TSO "EXECIO 1 DISKW BKLOG (FINIS"
  ADDRESS TSO "FREE FI(BKLOG)"
  RETURN

/* ----------------------------------------------------------------- */
/* Send completion notification                                      */
/* ----------------------------------------------------------------- */
send_notification:
  PARSE ARG ntype nrc
  SAY ''
  SAY '  Sending backup notification...'
  /* Send TSO message to operations userid */
  msg_text = 'AUTOSALES' ntype 'backup complete. RC='nrc DATE('U') TIME()
  ADDRESS TSO "SEND '"msg_text"' USER(OPER01)"
  ADDRESS TSO "SEND '"msg_text"' USER(DBAADMIN)"
  SAY '  Notification sent to OPER01 and DBAADMIN.'
  RETURN

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASBACKUP - AUTOSALES Backup Orchestrator'
  SAY ''
  SAY 'Submits backup JCLs in sequence, waits for completion,'
  SAY 'logs status, and sends notification.'
  SAY ''
  SAY 'Usage:  TSO ASBACKUP FULL   (full backup - 4 steps)'
  SAY '        TSO ASBACKUP INCR   (incremental - 2 steps)'
  SAY '        TSO ASBACKUP ?      (this help)'
  SAY ''
  SAY 'Backup sequence (FULL):'
  SAY '  1. DB2 Full Unload       (all AUTOSALES tables)'
  SAY '  2. DB2 Image Copy        (all tablespaces)'
  SAY '  3. DFDSS Copy            (VSAM/IMS databases)'
  SAY '  4. GDG Backup            (sequential datasets)'
  SAY ''
  RETURN

/* ----------------------------------------------------------------- */
/* Error handlers                                                    */
/* ----------------------------------------------------------------- */
ERROR:
  SAY '*** Error at line' SIGL':' SOURCELINE(SIGL)
  SAY '*** RC='RC
  CALL write_log 'ERROR at line' SIGL 'RC='RC
  EXIT 12

SYNTAX:
  SAY '*** Syntax error at line' SIGL':' ERRORTEXT(RC)
  EXIT 12
