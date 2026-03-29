/* REXX - ASDBCHK: DB2 Health Check for AUTOSALES                   */
/*                                                                   */
/* Description: Queries DB2 catalog for AUTOSALE schema. Reports     */
/*              table space sizes, percent used, tables needing       */
/*              REORG (based on CLUSTERRATIO), packages needing       */
/*              REBIND, and displays recommendations.                 */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASDBCHK)' EXEC              */
/*              TSO ASDBCHK ?     (for help)                         */
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

  schema    = 'AUTOSALES'
  dbname    = 'AUTODB'
  reorg_threshold = 80   /* CLUSTERRATIO below this triggers REORG */
  space_threshold = 85   /* Percent full above this triggers alert */

  SAY ''
  SAY COPIES('=',72)
  SAY '   AUTOSALES - DB2 Health Check Report'
  SAY '   Database:' dbname '  Schema:' schema
  SAY '   Run Date:' DATE('U') TIME()
  SAY COPIES('=',72)

  /* ---- Section 1: Table Space Sizes ---- */
  SAY ''
  SAY '  1. TABLE SPACE STATUS'
  SAY '  ' COPIES('-',66)
  SAY '  ' LEFT('Tablespace',18) LEFT('Status',10) LEFT('Pages',10),
         LEFT('PctUsed',8) LEFT('PartSize',10)

  sql_ts = "SELECT DBNAME, NAME, STATUS, NACTIVEF, SPACE, PERCACTIVE",
           "FROM SYSIBM.SYSTABLESPACE",
           "WHERE DBNAME = '"dbname"'",
           "ORDER BY NAME"

  ADDRESS DSNREXX "EXECSQL EXECSQL OPEN C1 USING" sql_ts
  IF RC \= 0 THEN DO
    SAY '*** DB2 connection failed. RC='RC
    SAY '*** Attempting catalog query via DSN command...'
    ADDRESS TSO "DSN SYSTEM(DB2P)"
    EXIT 8
  END

  ts_count = 0
  warn_count = 0
  DO FOREVER
    ADDRESS DSNREXX "EXECSQL FETCH C1 INTO :tsdb, :tsname, :tsstatus,",
                    ":tspages, :tsspace, :tspct"
    IF SQLCODE \= 0 THEN LEAVE
    ts_count = ts_count + 1

    /* Flag spaces over threshold */
    flag = ''
    IF tspct > space_threshold THEN DO
      flag = ' ***'
      warn_count = warn_count + 1
    END

    SAY '  ' LEFT(tsname,18) LEFT(tsstatus,10) RIGHT(tspages,10),
           RIGHT(tspct'%',8) RIGHT(tsspace,10) flag
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C1"

  SAY ''
  SAY '   Tablespaces checked:' ts_count
  IF warn_count > 0 THEN
    SAY '   *** WARNING:' warn_count 'tablespace(s) above' space_threshold'% full'

  /* ---- Section 2: REORG Candidates ---- */
  SAY ''
  SAY '  2. REORG CANDIDATES (CLUSTERRATIO <' reorg_threshold'%)'
  SAY '  ' COPIES('-',66)
  SAY '  ' LEFT('Table',30) LEFT('Index',20) LEFT('ClusterRatio',12)

  sql_reorg = "SELECT T.NAME, I.NAME, I.CLUSTERRATIO",
              "FROM SYSIBM.SYSTABLES T, SYSIBM.SYSINDEXES I",
              "WHERE T.CREATOR = '"schema"'",
              "AND I.TBCREATOR = T.CREATOR",
              "AND I.TBNAME = T.NAME",
              "AND I.CLUSTERRATIOF < "reorg_threshold,
              "ORDER BY I.CLUSTERRATIOF"

  ADDRESS DSNREXX "EXECSQL OPEN C2 USING" sql_reorg
  reorg_count = 0
  DO FOREVER
    ADDRESS DSNREXX "EXECSQL FETCH C2 INTO :tblname, :ixname, :cluster"
    IF SQLCODE \= 0 THEN LEAVE
    reorg_count = reorg_count + 1
    SAY '  ' LEFT(tblname,30) LEFT(ixname,20) RIGHT(cluster'%',12)
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C2"

  IF reorg_count = 0 THEN
    SAY '   No tables currently need REORG.'
  ELSE
    SAY '   Tables needing REORG:' reorg_count

  /* ---- Section 3: REBIND Candidates ---- */
  SAY ''
  SAY '  3. REBIND CANDIDATES (Stale packages)'
  SAY '  ' COPIES('-',66)
  SAY '  ' LEFT('Package',20) LEFT('Coll-ID',12) LEFT('LastBind',20),
         LEFT('Valid',6)

  sql_rebind = "SELECT NAME, COLLID, LASTUSED, VALID",
               "FROM SYSIBM.SYSPACKAGE",
               "WHERE COLLID LIKE 'AUTO%'",
               "AND (VALID = 'N' OR OPERATIVE = 'N')",
               "ORDER BY NAME"

  ADDRESS DSNREXX "EXECSQL OPEN C3 USING" sql_rebind
  rebind_count = 0
  DO FOREVER
    ADDRESS DSNREXX "EXECSQL FETCH C3 INTO :pkgname, :collid,",
                    ":lastbind, :valid"
    IF SQLCODE \= 0 THEN LEAVE
    rebind_count = rebind_count + 1
    SAY '  ' LEFT(pkgname,20) LEFT(collid,12) LEFT(lastbind,20),
           LEFT(valid,6)
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C3"

  IF rebind_count = 0 THEN
    SAY '   All packages are valid - no REBIND needed.'
  ELSE
    SAY '   Packages needing REBIND:' rebind_count

  /* ---- Section 4: Recommendations ---- */
  SAY ''
  SAY '  4. RECOMMENDATIONS'
  SAY '  ' COPIES('-',66)

  IF warn_count > 0 THEN
    SAY '   - Extend or reorganize tablespaces above' space_threshold'%'
  IF reorg_count > 0 THEN
    SAY '   - Run REORG TABLESPACE for' reorg_count 'candidate(s)'
  IF rebind_count > 0 THEN
    SAY '   - Run REBIND PACKAGE for' rebind_count 'package(s)'
  IF warn_count = 0 & reorg_count = 0 & rebind_count = 0 THEN
    SAY '   - DB2 health is good. No actions required.'

  SAY ''
  SAY COPIES('=',72)
  SAY '   DB2 Health Check complete.'
  SAY COPIES('=',72)

  EXIT 0

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASDBCHK - AUTOSALES DB2 Health Check'
  SAY ''
  SAY 'Queries DB2 catalog for AUTOSALES schema.'
  SAY 'Reports: tablespace sizes, REORG candidates, REBIND needs.'
  SAY ''
  SAY 'Usage:  TSO ASDBCHK     (run health check)'
  SAY '        TSO ASDBCHK ?   (this help)'
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
