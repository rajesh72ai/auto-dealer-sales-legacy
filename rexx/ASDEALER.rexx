/* REXX - ASDEALER: Dealer Dashboard for AUTOSALES                  */
/*                                                                   */
/* Description: Takes dealer code as input, queries multiple tables   */
/*              for dealer KPIs. Displays inventory count, MTD sales, */
/*              floor plan balance, open warranty claims.             */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASDEALER)' EXEC             */
/*              TSO ASDEALER dealer_code                             */
/*              TSO ASDEALER ?     (for help)                        */
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

  /* Get dealer code from argument or prompt */
  dealer_code = STRIP(parm)
  IF dealer_code = '' THEN DO
    SAY ''
    CALL CHAROUT , '  Enter Dealer Code (5 chars): '
    PULL dealer_code
    dealer_code = STRIP(dealer_code)
  END

  IF LENGTH(dealer_code) \= 5 THEN DO
    SAY '*** Invalid dealer code length:' LENGTH(dealer_code)
    EXIT 8
  END

  /* Get dealer info */
  sql_dlr = "SELECT DEALER_NAME, CITY, STATE_CODE, REGION_CODE,",
            "ZONE_CODE, DEALER_PRINCIPAL, MAX_INVENTORY",
            "FROM AUTOSALE.DEALER",
            "WHERE DEALER_CODE = '"dealer_code"'"

  ADDRESS DSNREXX "EXECSQL OPEN C1 USING" sql_dlr
  ADDRESS DSNREXX "EXECSQL FETCH C1 INTO :dname, :dcity, :dstate,",
                  ":dregion, :dzone, :dprincipal, :dmaxinv"

  IF SQLCODE \= 0 THEN DO
    SAY '*** Dealer not found:' dealer_code
    ADDRESS DSNREXX "EXECSQL CLOSE C1"
    EXIT 4
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C1"

  /* Current date components for MTD queries */
  cur_date = DATE('S')
  cur_year = LEFT(cur_date,4)
  cur_month = SUBSTR(cur_date,5,2)
  mtd_start = cur_year'-'cur_month'-01'

  SAY ''
  SAY COPIES('=',68)
  SAY '   AUTOSALES - Dealer Dashboard'
  SAY '   Date:' DATE('U') TIME()
  SAY COPIES('=',68)
  SAY ''
  SAY '  DEALER INFORMATION'
  SAY '  ' COPIES('-',62)
  SAY '  Dealer Code:    ' dealer_code
  SAY '  Dealer Name:    ' STRIP(dname)
  SAY '  Location:       ' STRIP(dcity)', 'STRIP(dstate)
  SAY '  Region/Zone:    ' STRIP(dregion) '/' STRIP(dzone)
  SAY '  Principal:      ' STRIP(dprincipal)
  SAY '  Max Inventory:  ' dmaxinv

  /* ---- KPI 1: Inventory Count by Status ---- */
  SAY ''
  SAY '  CURRENT INVENTORY'
  SAY '  ' COPIES('-',62)

  sql_inv = "SELECT VEHICLE_STATUS, COUNT(*) AS CNT",
            "FROM AUTOSALE.VEHICLE",
            "WHERE DEALER_CODE = '"dealer_code"'",
            "GROUP BY VEHICLE_STATUS",
            "ORDER BY VEHICLE_STATUS"

  ADDRESS DSNREXX "EXECSQL OPEN C2 USING" sql_inv
  total_inv = 0
  DO FOREVER
    ADDRESS DSNREXX "EXECSQL FETCH C2 INTO :inv_stat, :inv_cnt"
    IF SQLCODE \= 0 THEN LEAVE
    total_inv = total_inv + inv_cnt

    SELECT
      WHEN inv_stat = 'AV' THEN sdesc = 'Available'
      WHEN inv_stat = 'HD' THEN sdesc = 'On Hold'
      WHEN inv_stat = 'IT' THEN sdesc = 'In Transit'
      WHEN inv_stat = 'DL' THEN sdesc = 'Delivered'
      WHEN inv_stat = 'SD' THEN sdesc = 'Sold'
      WHEN inv_stat = 'TR' THEN sdesc = 'Transfer'
      OTHERWISE sdesc = inv_stat
    END

    SAY '   ' LEFT(sdesc,15) RIGHT(inv_cnt,6)
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C2"

  SAY '   ' COPIES('-',21)
  SAY '   ' LEFT('Total',15) RIGHT(total_inv,6)
  pct_used = FORMAT(total_inv / dmaxinv * 100,,1)
  SAY '    Capacity Used:' pct_used'%'

  /* ---- KPI 2: MTD Sales ---- */
  SAY ''
  SAY '  MONTH-TO-DATE SALES'
  SAY '  ' COPIES('-',62)

  sql_mtd = "SELECT COUNT(*) AS DEAL_CNT,",
            "COALESCE(SUM(TOTAL_PRICE),0) AS TOT_REV,",
            "COALESCE(SUM(FRONT_GROSS),0) AS TOT_FG,",
            "COALESCE(SUM(BACK_GROSS),0) AS TOT_BG,",
            "COALESCE(SUM(TOTAL_GROSS),0) AS TOT_TG",
            "FROM AUTOSALE.SALES_DEAL",
            "WHERE DEALER_CODE = '"dealer_code"'",
            "AND DEAL_DATE >= '"mtd_start"'",
            "AND DEAL_STATUS NOT IN ('CA','UW')"

  ADDRESS DSNREXX "EXECSQL OPEN C3 USING" sql_mtd
  ADDRESS DSNREXX "EXECSQL FETCH C3 INTO :deal_cnt, :tot_rev,",
                  ":tot_fg, :tot_bg, :tot_tg"
  ADDRESS DSNREXX "EXECSQL CLOSE C3"

  SAY '   Deals Closed:   ' RIGHT(deal_cnt,8)
  SAY '   Total Revenue:  ' RIGHT('$'FORMAT(tot_rev,,2),14)
  SAY '   Front Gross:    ' RIGHT('$'FORMAT(tot_fg,,2),14)
  SAY '   Back Gross:     ' RIGHT('$'FORMAT(tot_bg,,2),14)
  SAY '   Total Gross:    ' RIGHT('$'FORMAT(tot_tg,,2),14)
  IF deal_cnt > 0 THEN
    SAY '   Avg Gross/Deal: ' RIGHT('$'FORMAT(tot_tg/deal_cnt,,2),14)

  /* ---- KPI 3: Floor Plan Balance ---- */
  SAY ''
  SAY '  FLOOR PLAN SUMMARY'
  SAY '  ' COPIES('-',62)

  sql_fp = "SELECT COUNT(*) AS FP_CNT,",
           "COALESCE(SUM(CURRENT_BALANCE),0) AS FP_BAL,",
           "COALESCE(SUM(INTEREST_ACCRUED),0) AS FP_INT,",
           "COALESCE(AVG(DAYS_ON_FLOOR),0) AS AVG_DAYS",
           "FROM AUTOSALE.FLOOR_PLAN_VEHICLE",
           "WHERE DEALER_CODE = '"dealer_code"'",
           "AND FP_STATUS = 'AC'"

  ADDRESS DSNREXX "EXECSQL OPEN C4 USING" sql_fp
  ADDRESS DSNREXX "EXECSQL FETCH C4 INTO :fp_cnt, :fp_bal,",
                  ":fp_int, :fp_avgdays"
  ADDRESS DSNREXX "EXECSQL CLOSE C4"

  SAY '   Active Units:     ' RIGHT(fp_cnt,8)
  SAY '   Total Balance:    ' RIGHT('$'FORMAT(fp_bal,,2),14)
  SAY '   Accrued Interest: ' RIGHT('$'FORMAT(fp_int,,2),14)
  SAY '   Avg Days on Floor:' RIGHT(fp_avgdays,8)

  /* ---- KPI 4: Open Warranty Claims ---- */
  SAY ''
  SAY '  OPEN WARRANTY CLAIMS'
  SAY '  ' COPIES('-',62)

  sql_war = "SELECT W.WARRANTY_TYPE, COUNT(*) AS W_CNT",
            "FROM AUTOSALE.WARRANTY W",
            "JOIN AUTOSALE.VEHICLE V ON W.VIN = V.VIN",
            "WHERE V.DEALER_CODE = '"dealer_code"'",
            "AND W.WARRANTY_STATUS = 'AC'",
            "GROUP BY W.WARRANTY_TYPE",
            "ORDER BY W.WARRANTY_TYPE"

  ADDRESS DSNREXX "EXECSQL OPEN C5 USING" sql_war
  war_total = 0
  DO FOREVER
    ADDRESS DSNREXX "EXECSQL FETCH C5 INTO :wtype, :wcnt"
    IF SQLCODE \= 0 THEN LEAVE
    war_total = war_total + wcnt

    SELECT
      WHEN wtype = 'BT' THEN wdesc = 'Bumper-to-Bumper'
      WHEN wtype = 'PT' THEN wdesc = 'Powertrain'
      WHEN wtype = 'CR' THEN wdesc = 'Corrosion'
      WHEN wtype = 'EM' THEN wdesc = 'Emission'
      OTHERWISE wdesc = wtype
    END

    SAY '   ' LEFT(wdesc,20) RIGHT(wcnt,6)
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C5"

  IF war_total = 0 THEN
    SAY '   No open warranty claims.'
  ELSE
    SAY '   Total Open Claims:' RIGHT(war_total,6)

  SAY ''
  SAY COPIES('=',68)
  EXIT 0

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASDEALER - AUTOSALES Dealer Dashboard'
  SAY ''
  SAY 'Displays KPIs for a dealer: inventory, MTD sales,'
  SAY 'floor plan balance, open warranty claims.'
  SAY ''
  SAY 'Usage:  TSO ASDEALER DLR01'
  SAY '        TSO ASDEALER ?     (this help)'
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
