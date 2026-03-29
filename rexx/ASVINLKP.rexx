/* REXX - ASVINLKP: VIN Lookup Utility for AUTOSALES                */
/*                                                                   */
/* Description: Takes VIN as input, queries AUTOSALE.VEHICLE via    */
/*              EXECSQL, displays vehicle details (year, make,       */
/*              model, color, status, dealer), shows deal history     */
/*              if vehicle has been sold.                             */
/*                                                                   */
/* Usage:       TSO EXEC 'AUTOSALE.REXX(ASVINLKP)' EXEC             */
/*              TSO ASVINLKP vin_number                              */
/*              TSO ASVINLKP ?     (for help)                        */
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

  /* Get VIN from argument or prompt */
  vin_input = STRIP(parm)
  IF vin_input = '' THEN DO
    SAY ''
    CALL CHAROUT , '  Enter VIN (17 characters): '
    PULL vin_input
    vin_input = STRIP(vin_input)
  END

  /* Validate VIN length */
  IF LENGTH(vin_input) \= 17 THEN DO
    SAY '*** Invalid VIN length:' LENGTH(vin_input) '(expected 17)'
    EXIT 8
  END

  SAY ''
  SAY COPIES('=',68)
  SAY '   AUTOSALES - VIN Lookup'
  SAY '   VIN:' vin_input
  SAY COPIES('=',68)

  /* Query vehicle table */
  sql_veh = "SELECT V.VIN, V.MODEL_YEAR, V.MAKE_CODE, V.MODEL_CODE,",
            "V.EXTERIOR_COLOR, V.INTERIOR_COLOR, V.VEHICLE_STATUS,",
            "V.DEALER_CODE, V.STOCK_NUMBER, V.DAYS_IN_STOCK,",
            "V.PDI_COMPLETE, V.ODOMETER, V.RECEIVE_DATE,",
            "M.MODEL_NAME, M.BODY_STYLE, M.ENGINE_TYPE, M.TRANSMISSION",
            "FROM AUTOSALE.VEHICLE V",
            "JOIN AUTOSALE.MODEL_MASTER M",
            "ON V.MODEL_YEAR = M.MODEL_YEAR",
            "AND V.MAKE_CODE = M.MAKE_CODE",
            "AND V.MODEL_CODE = M.MODEL_CODE",
            "WHERE V.VIN = '"vin_input"'"

  ADDRESS DSNREXX "EXECSQL OPEN C1 USING" sql_veh

  ADDRESS DSNREXX "EXECSQL FETCH C1 INTO",
    ":vin, :myear, :make, :model, :extcolor, :intcolor,",
    ":vstatus, :dealer, :stocknum, :daysinstock,",
    ":pdicomplete, :odometer, :rcvdate,",
    ":modelname, :bodystyle, :engtype, :transtype"

  IF SQLCODE \= 0 THEN DO
    SAY ''
    SAY '  Vehicle not found for VIN:' vin_input
    ADDRESS DSNREXX "EXECSQL CLOSE C1"
    EXIT 4
  END

  ADDRESS DSNREXX "EXECSQL CLOSE C1"

  /* Decode vehicle status */
  SELECT
    WHEN vstatus = 'PR' THEN status_desc = 'Produced'
    WHEN vstatus = 'AL' THEN status_desc = 'Allocated'
    WHEN vstatus = 'SH' THEN status_desc = 'Shipped'
    WHEN vstatus = 'IT' THEN status_desc = 'In Transit'
    WHEN vstatus = 'DL' THEN status_desc = 'Delivered'
    WHEN vstatus = 'AV' THEN status_desc = 'Available'
    WHEN vstatus = 'HD' THEN status_desc = 'On Hold'
    WHEN vstatus = 'SD' THEN status_desc = 'Sold'
    WHEN vstatus = 'TR' THEN status_desc = 'Transfer'
    OTHERWISE status_desc = vstatus
  END

  /* Decode body style */
  SELECT
    WHEN bodystyle = 'SD' THEN body_desc = 'Sedan'
    WHEN bodystyle = 'SV' THEN body_desc = 'SUV'
    WHEN bodystyle = 'TK' THEN body_desc = 'Truck'
    WHEN bodystyle = 'CP' THEN body_desc = 'Coupe'
    WHEN bodystyle = 'HB' THEN body_desc = 'Hatchback'
    WHEN bodystyle = 'VN' THEN body_desc = 'Van'
    WHEN bodystyle = 'CV' THEN body_desc = 'Convertible'
    OTHERWISE body_desc = bodystyle
  END

  /* Display vehicle details */
  SAY ''
  SAY '  VEHICLE DETAILS'
  SAY '  ' COPIES('-',62)
  SAY '  VIN:            ' vin
  SAY '  Year:           ' myear
  SAY '  Make:           ' STRIP(make)
  SAY '  Model:          ' STRIP(modelname) '('STRIP(model)')'
  SAY '  Body Style:     ' body_desc
  SAY '  Engine:         ' STRIP(engtype)
  SAY '  Transmission:   ' STRIP(transtype)
  SAY '  Exterior Color: ' STRIP(extcolor)
  SAY '  Interior Color: ' STRIP(intcolor)
  SAY '  Status:         ' status_desc '('STRIP(vstatus)')'
  SAY '  Dealer Code:    ' STRIP(dealer)
  SAY '  Stock Number:   ' STRIP(stocknum)
  SAY '  Days in Stock:  ' daysinstock
  SAY '  PDI Complete:   ' pdicomplete
  SAY '  Odometer:       ' odometer
  SAY '  Received:       ' rcvdate

  /* Query vehicle options */
  SAY ''
  SAY '  INSTALLED OPTIONS'
  SAY '  ' COPIES('-',62)

  sql_opt = "SELECT OPTION_CODE, OPTION_DESC, OPTION_PRICE, INSTALLED_FLAG",
            "FROM AUTOSALE.VEHICLE_OPTION",
            "WHERE VIN = '"vin_input"'",
            "ORDER BY OPTION_CODE"

  ADDRESS DSNREXX "EXECSQL OPEN C2 USING" sql_opt
  opt_count = 0
  opt_total = 0
  DO FOREVER
    ADDRESS DSNREXX "EXECSQL FETCH C2 INTO :ocode, :odesc, :oprice, :oflag"
    IF SQLCODE \= 0 THEN LEAVE
    opt_count = opt_count + 1
    opt_total = opt_total + oprice
    SAY '   ' STRIP(ocode) '-' STRIP(odesc) RIGHT('$'FORMAT(oprice,,2),12)
  END
  ADDRESS DSNREXX "EXECSQL CLOSE C2"

  IF opt_count = 0 THEN
    SAY '   No options recorded.'
  ELSE
    SAY '   Total options value:' RIGHT('$'FORMAT(opt_total,,2),12)

  /* If sold, show deal history */
  IF vstatus = 'SD' THEN DO
    SAY ''
    SAY '  DEAL HISTORY'
    SAY '  ' COPIES('-',62)

    sql_deal = "SELECT D.DEAL_NUMBER, D.DEAL_DATE, D.DEAL_TYPE,",
               "D.DEAL_STATUS, D.TOTAL_PRICE, D.FRONT_GROSS,",
               "D.BACK_GROSS, D.TOTAL_GROSS,",
               "C.FIRST_NAME, C.LAST_NAME",
               "FROM AUTOSALE.SALES_DEAL D",
               "JOIN AUTOSALE.CUSTOMER C ON D.CUSTOMER_ID = C.CUSTOMER_ID",
               "WHERE D.VIN = '"vin_input"'",
               "ORDER BY D.DEAL_DATE DESC"

    ADDRESS DSNREXX "EXECSQL OPEN C3 USING" sql_deal
    DO FOREVER
      ADDRESS DSNREXX "EXECSQL FETCH C3 INTO",
        ":dealnum, :dealdate, :dealtype, :dealstat,",
        ":totprice, :fgross, :bgross, :tgross,",
        ":fname, :lname"
      IF SQLCODE \= 0 THEN LEAVE

      SAY '  Deal #:       ' STRIP(dealnum)
      SAY '  Deal Date:    ' dealdate
      SAY '  Customer:     ' STRIP(fname) STRIP(lname)
      SAY '  Deal Type:    ' dealtype
      SAY '  Status:       ' STRIP(dealstat)
      SAY '  Total Price:  ' RIGHT('$'FORMAT(totprice,,2),12)
      SAY '  Front Gross:  ' RIGHT('$'FORMAT(fgross,,2),12)
      SAY '  Back Gross:   ' RIGHT('$'FORMAT(bgross,,2),12)
      SAY '  Total Gross:  ' RIGHT('$'FORMAT(tgross,,2),12)
      SAY ''
    END
    ADDRESS DSNREXX "EXECSQL CLOSE C3"
  END

  SAY COPIES('=',68)
  EXIT 0

/* ----------------------------------------------------------------- */
/* Show help                                                         */
/* ----------------------------------------------------------------- */
show_help:
  SAY ''
  SAY 'ASVINLKP - AUTOSALES VIN Lookup Utility'
  SAY ''
  SAY 'Retrieves vehicle details by VIN from AUTOSALE.VEHICLE.'
  SAY 'Includes options and deal history for sold vehicles.'
  SAY ''
  SAY 'Usage:  TSO ASVINLKP 1HGBH41JXMN109186'
  SAY '        TSO ASVINLKP ?   (this help)'
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
