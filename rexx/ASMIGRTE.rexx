/* REXX - ASMIGRTE: Environment Migration for AUTOSALES             */
/*                                                                   */
/* Description: Copies programs/JCL from one environment to another  */
/*              (DEV->QA->PROD). Uses IEBCOPY for load library copy. */
/*              Updates dataset HLQ in JCL members. Creates           */
/*              migration audit trail.                                */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASMIGRTE)' EXEC             */
/*              TSO ASMIGRTE ?                     (for help)        */
/*              TSO ASMIGRTE DEV QA membername     (migrate member)  */
/*                                                                   */
/* Author:      AUTOSALES Development Team                           */
/* System:      AUTOSALES - IMS DC/COBOL/DB2 z/OS                   */
/* ----------------------------------------------------------------- */
  SIGNAL ON ERROR
  SIGNAL ON SYNTAX
  PARSE ARG parm

  IF STRIP(parm) = '?' THEN DO
    CALL show_help
    EXIT 0
  END

  /* Environment HLQs */
  env_hlq.DEV  = 'AUTODEV'
  env_hlq.QA   = 'AUTOQA'
  env_hlq.PROD = 'AUTOSALE'

  /* Valid promotion paths */
  valid_path.1 = 'DEV QA'
  valid_path.2 = 'QA PROD'
  valid_paths  = 2

  /* Library suffixes */
  lib.1  = 'LOADLIB'  ; libdesc.1  = 'Load Library (executables)'
  lib.2  = 'COBOL'    ; libdesc.2  = 'COBOL Source'
  lib.3  = 'COPYLIB'  ; libdesc.3  = 'Copybooks'
  lib.4  = 'JCL'      ; libdesc.4  = 'JCL Procedures'
  lib.5  = 'DBRM'     ; libdesc.5  = 'DB2 DBRMs'
  lib.6  = 'MFS'      ; libdesc.6  = 'MFS Definitions'
  lib_count = 6

  audit_dsn = 'AUTOSALE.MIGRATE.AUDIT'

  /* Parse arguments or prompt */
  PARSE VAR parm from_env to_env member_list

  IF from_env = '' THEN DO
    SAY ''
    SAY COPIES('=',68)
    SAY '   AUTOSALES - Environment Migration'
    SAY COPIES('=',68)
    SAY ''
    SAY '  Source environment:'
    SAY '    1. DEV  (AUTODEV)'
    SAY '    2. QA   (AUTOQA)'
    SAY ''
    CALL CHAROUT , '  Select source (1-2): '
    PULL from_sel
    IF from_sel = 1 THEN from_env = 'DEV'
    ELSE IF from_sel = 2 THEN from_env = 'QA'
    ELSE DO
      SAY '*** Invalid selection'
      EXIT 8
    END

    SAY ''
    SAY '  Target environment:'
    SAY '    1. QA   (AUTOQA)'
    SAY '    2. PROD (AUTOSALE)'
    SAY ''
    CALL CHAROUT , '  Select target (1-2): '
    PULL to_sel
    IF to_sel = 1 THEN to_env = 'QA'
    ELSE IF to_sel = 2 THEN to_env = 'PROD'
    ELSE DO
      SAY '*** Invalid selection'
      EXIT 8
    END

    SAY ''
    CALL CHAROUT , '  Member name(s) to migrate (space-separated): '
    PULL member_list
  END

  UPPER from_env to_env member_list

  /* Validate promotion path */
  path_valid = 0
  DO p = 1 TO valid_paths
    IF valid_path.p = from_env to_env THEN DO
      path_valid = 1
      LEAVE
    END
  END

  IF \path_valid THEN DO
    SAY '*** Invalid promotion path:' from_env '->' to_env
    SAY '*** Valid paths: DEV->QA, QA->PROD'
    EXIT 8
  END

  IF member_list = '' THEN DO
    SAY '*** No members specified for migration'
    EXIT 8
  END

  /* Confirm migration */
  SAY ''
  SAY COPIES('=',68)
  SAY '  Migration Summary'
  SAY COPIES('-',68)
  SAY '  From:    ' from_env '('env_hlq.from_env')'
  SAY '  To:      ' to_env '('env_hlq.to_env')'
  SAY '  Members: ' member_list
  SAY '  Date:    ' DATE('U') TIME()
  SAY COPIES('-',68)

  IF to_env = 'PROD' THEN DO
    SAY ''
    SAY '  *** WARNING: Migrating to PRODUCTION ***'
    CALL CHAROUT , '  Type YES to confirm: '
    PULL confirm
    IF confirm \= 'YES' THEN DO
      SAY '  Migration cancelled.'
      EXIT 0
    END
  END
  ELSE DO
    CALL CHAROUT , '  Confirm? (Y/N): '
    PULL confirm
    IF confirm \= 'Y' THEN DO
      SAY '  Migration cancelled.'
      EXIT 0
    END
  END

  /* Process each member */
  src_hlq = env_hlq.from_env
  tgt_hlq = env_hlq.to_env
  total_rc = 0
  mem_count = WORDS(member_list)

  DO m = 1 TO mem_count
    member = WORD(member_list, m)
    SAY ''
    SAY '  Migrating member:' member

    /* Copy across all library types */
    DO lx = 1 TO lib_count
      src_dsn = "'"src_hlq"."lib.lx"'"
      tgt_dsn = "'"tgt_hlq"."lib.lx"'"

      /* Check if member exists in source */
      ADDRESS TSO "ALLOC FI(SRCLIB) DA("src_dsn") SHR REUSE"
      ADDRESS TSO "LISTDS "src_dsn" MEMBERS"
      src_rc = RC

      IF src_rc = 0 THEN DO
        /* Use IEBCOPY for load library, TSO COPY for others */
        IF lib.lx = 'LOADLIB' THEN DO
          SAY '   Copying' member 'from' lib.lx '(IEBCOPY)...'
          /* Build IEBCOPY inline */
          QUEUE " COPY OUTDD=SYSUT2,INDD=SYSUT1"
          QUEUE " SELECT MEMBER="member
          ADDRESS TSO "ALLOC FI(SYSUT1) DA("src_dsn") SHR REUSE"
          ADDRESS TSO "ALLOC FI(SYSUT2) DA("tgt_dsn") SHR REUSE"
          ADDRESS TSO "ALLOC FI(SYSIN) NEW REUSE UNIT(VIO)",
                      "SPACE(1,1) TRACKS RECFM(F B) LRECL(80)"
          ADDRESS TSO "EXECIO 2 DISKW SYSIN (FINIS"
          ADDRESS TSO "CALL 'SYS1.LINKLIB(IEBCOPY)'"
          copy_rc = RC
          ADDRESS TSO "FREE FI(SYSUT1 SYSUT2 SYSIN)"
        END
        ELSE DO
          SAY '   Copying' member 'from' lib.lx '...'
          ADDRESS ISPEXEC "LMCOPY FROMID("src_dsn")",
                          "TODATAID("tgt_dsn")",
                          "FROMMEM("member") REPLACE"
          copy_rc = RC
        END

        IF copy_rc = 0 THEN
          SAY '    Copied successfully.'
        ELSE
          SAY '    *** Copy RC='copy_rc '(member may not exist in this library)'

        total_rc = MAX(total_rc, copy_rc)
      END

      ADDRESS TSO "FREE FI(SRCLIB)"
    END

    /* For JCL members, update HLQ references */
    IF WORDPOS('JCL', lib.1 lib.2 lib.3 lib.4 lib.5 lib.6) > 0 THEN DO
      CALL update_jcl_hlq member tgt_hlq src_hlq
    END

    /* Write audit trail */
    CALL write_audit from_env to_env member
  END

  SAY ''
  SAY COPIES('=',68)
  SAY '  Migration complete. Overall RC='total_rc
  SAY '  Members migrated:' mem_count
  SAY COPIES('=',68)

  EXIT total_rc

/* ----------------------------------------------------------------- */
/* Update HLQ in JCL member after copy                               */
/* ----------------------------------------------------------------- */
update_jcl_hlq:
  PARSE ARG umember utgt_hlq usrc_hlq

  SAY '   Updating HLQ references in JCL...'
  jcl_dsn = "'"utgt_hlq".JCL'"

  ADDRESS ISPEXEC "EDIT DATASET("jcl_dsn") MEMBER("umember")"
  ADDRESS ISREDIT "CHANGE '"usrc_hlq"' '"utgt_hlq"' ALL"
  chg_count = RC
  ADDRESS ISREDIT "SAVE"
  ADDRESS ISREDIT "END"

  SAY '    HLQ updated:' usrc_hlq '->' utgt_hlq
  RETURN

/* ----------------------------------------------------------------- */
/* Write audit trail record                                          */
/* ----------------------------------------------------------------- */
write_audit:
  PARSE ARG afrom ato amember

  audit_line = LEFT(DATE('S'),8) LEFT(TIME(),8),
               LEFT(USERID(),8) LEFT(afrom,4) LEFT(ato,4),
               LEFT(amember,8) 'MIGRATED'

  ADDRESS TSO "ALLOC FI(AUDIT) DA('"audit_dsn"') MOD REUSE"
  PUSH audit_line
  ADDRESS TSO "EXECIO 1 DISKW AUDIT (FINIS"
  ADDRESS TSO "FREE FI(AUDIT)"
  RETURN

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASMIGRTE - AUTOSALES Environment Migration'
  SAY ''
  SAY 'Copies programs and JCL between environments,'
  SAY 'updating dataset HLQs and creating an audit trail.'
  SAY ''
  SAY 'Usage:  TSO ASMIGRTE                   (interactive)'
  SAY '        TSO ASMIGRTE DEV QA BATDLY00   (specific member)'
  SAY '        TSO ASMIGRTE QA PROD RPTDLY00 RPTWKL00'
  SAY '        TSO ASMIGRTE ?                 (this help)'
  SAY ''
  SAY 'Environments: DEV (AUTODEV) -> QA (AUTOQA) -> PROD (AUTOSALE)'
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
