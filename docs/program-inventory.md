# AUTOSALES Program Inventory

## Summary

| Category | Count |
|----------|------:|
| Online Programs | 76 |
| Batch Programs | 11 |
| Report Programs | 14 |
| Common Modules | 16 |
| **Total COBOL Programs** | **117** |

---

## ADM - Administration Module (8 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| ADMCFG00 | System configuration maintenance (INQ/UPD/LST) | ADMC | ~580 | Medium | SYSTEM_CONFIG | COMLGEL0, COMDBEL0 |
| ADMDLR00 | Dealer master maintenance (INQ/ADD/UPD/LST) | ADMD | ~680 | Medium | DEALER | COMFMTL0, COMLGEL0, COMDBEL0 |
| ADMINC00 | Incentive program setup (INQ/ADD/UPD/ACT/DEAC) | ADMI | ~720 | High | INCENTIVE_PROGRAM | COMLGEL0, COMDBEL0, COMFMTL0 |
| ADMMFG00 | Model master maintenance (INQ/ADD/UPD/LST) | ADMM | ~620 | Medium | MODEL_MASTER | COMMSGL0, COMLGEL0, COMDBEL0 |
| ADMPRC00 | Pricing master maintenance (INQ/ADD/UPD) | ADMP | ~650 | High | PRICE_MASTER | COMFMTL0, COMLGEL0, COMDBEL0 |
| ADMPRD00 | F&I product catalog maintenance (INQ/ADD/UPD/LST) | ADMF | ~550 | Medium | SYSTEM_CONFIG | COMFMTL0, COMLGEL0, COMDBEL0 |
| ADMSEC00 | Security / sign-on processing | ADMS | 616 | Medium | SYSTEM_USER | COMLGEL0, COMMSGL0 |
| ADMTAX00 | Tax rate maintenance (INQ/ADD/UPD) | ADMT | ~560 | Medium | TAX_RATE | COMTAXL0, COMLGEL0, COMDBEL0 |

## CUS - Customer Module (7 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| CUSADD00 | Customer profile creation with duplicate check | CSAD | ~750 | High | CUSTOMER, SYSTEM_USER | COMFMTL0, COMLGEL0, COMDBEL0 |
| CUSCRED0 | Credit pre-qualification (income-based scoring) | CSCR | ~680 | High | CUSTOMER, CREDIT_CHECK | COMFMTL0, COMLGEL0, COMDBEL0 |
| CUSHIS00 | Customer purchase history display | CSHI | ~520 | Medium | CUSTOMER, SALES_DEAL, VEHICLE, TRADE_IN | COMFMTL0, COMDTEL0 |
| CUSINQ00 | Customer search by name/phone/DL/ID (paginated) | CSIQ | ~580 | Medium | CUSTOMER | COMFMTL0, COMMSGL0 |
| CUSLEAD0 | Lead tracking & lifecycle management | CSLD | ~620 | High | CUSTOMER_LEAD, CUSTOMER | COMLGEL0, COMDBEL0, COMDTEL0 |
| CUSLST00 | Customer browse with sort options (paginated) | CSLS | ~480 | Low | CUSTOMER | COMFMTL0, COMMSGL0 |
| CUSUPD00 | Customer profile update with field-level audit | CSUP | ~620 | Medium | CUSTOMER | COMFMTL0, COMLGEL0, COMDBEL0 |

## SAL - Sales Process Module (8 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| SALQOT00 | Deal worksheet / quote generation | SALQ | ~950 | High | SALES_DEAL, DEAL_LINE_ITEM, CUSTOMER, VEHICLE, PRICE_MASTER, VEHICLE_OPTION, TAX_RATE, TRADE_IN, INCENTIVE_APPLIED, SYSTEM_USER | COMPRCL0, COMTAXL0, COMSEQL0, COMFMTL0, COMLGEL0, COMDBEL0 |
| SALNEG00 | Price negotiation (counter offers, discounts) | SALN | ~720 | High | SALES_DEAL, SYSTEM_USER, CUSTOMER, TAX_RATE | COMPRCL0, COMTAXL0, COMFMTL0, COMLGEL0 |
| SALAPV00 | Sales approval workflow (authority check) | SALA | 562 | High | SALES_DEAL, SALES_APPROVAL, SYSTEM_USER | COMLGEL0, COMDBEL0, COMMSGL0 |
| SALCMP00 | Sale completion / delivery (checklist) | SALC | ~780 | High | SALES_DEAL, VEHICLE, STOCK_POSITION, TRADE_IN, FINANCE_APP | COMSTCK0, COMSEQL0, COMLGEL0, COMDBEL0, COMFMTL0 |
| SALCAN00 | Sale cancellation / unwind (full reversal) | SALX | ~820 | High | SALES_DEAL, VEHICLE, STOCK_POSITION, INCENTIVE_APPLIED, INCENTIVE_PROGRAM, FLOOR_PLAN_VEHICLE | COMSTCK0, COMLGEL0, COMDBEL0 |
| SALINC00 | Incentive / rebate application | SALI | ~680 | High | INCENTIVE_PROGRAM, INCENTIVE_APPLIED, SALES_DEAL, VEHICLE, CUSTOMER | COMPRCL0, COMTAXL0, COMFMTL0, COMLGEL0 |
| SALTRD00 | Trade-in vehicle evaluation | SALT | ~700 | High | TRADE_IN, SALES_DEAL, PRICE_MASTER | COMVALD0, COMVINL0, COMFMTL0, COMLGEL0, COMDBEL0 |
| SALVAL00 | Deal validation (comprehensive pre-approval check) | SALV | ~750 | High | SALES_DEAL, CUSTOMER, CREDIT_CHECK, VEHICLE, SYSTEM_USER, SYSTEM_CONFIG, TRADE_IN, INCENTIVE_APPLIED | COMDBEL0, COMMSGL0 |

## FIN - Finance & Insurance Module (7 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| FINAPP00 | Finance application capture (Loan/Lease/Cash) | FNAP | ~680 | High | SALES_DEAL, FINANCE_APP | COMLONL0, COMSEQL0, COMFMTL0, COMLGEL0, COMDBEL0 |
| FINAPV00 | Finance approval/conditional/decline processing | FNAV | ~620 | High | FINANCE_APP, SALES_DEAL | COMLONL0, COMFMTL0, COMLGEL0, COMDBEL0 |
| FINCAL00 | Loan payment calculator (what-if, side-by-side) | FNCL | ~480 | Medium | None (read-only calculator) | COMLONL0, COMFMTL0 |
| FINCHK00 | Credit check interface (bureau simulation) | FNCK | ~650 | High | CREDIT_CHECK, CUSTOMER, SALES_DEAL | COMFMTL0, COMLGEL0, COMDBEL0 |
| FINDOC00 | Finance document generation (loan/lease/cash) | FNDC | ~850 | High | SALES_DEAL, CUSTOMER, VEHICLE, MODEL_MASTER, FINANCE_APP, TRADE_IN, LEASE_TERMS | COMFMTL0, COMLONL0, COMLESL0, COMDBEL0 |
| FINLSE00 | Lease calculator (full payment structure) | FNLS | ~580 | Medium | LEASE_TERMS, FINANCE_APP | COMLESL0, COMFMTL0, COMLGEL0 |
| FINPRD00 | F&I product selection (multi-select, gross calc) | FNPR | ~620 | High | SALES_DEAL, FINANCE_PRODUCT | COMFMTL0, COMLGEL0, COMDBEL0 |

## FPL - Floor Plan Module (5 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| FPLADD00 | Add vehicle to floor plan | FPLA | ~580 | Medium | FLOOR_PLAN_VEHICLE, VEHICLE, DEALER, LENDER | COMVALD0, COMFMTL0, COMLGEL0, COMDBEL0 |
| FPLINQ00 | Floor plan vehicle inquiry (paginated) | FPLI | ~520 | Medium | FLOOR_PLAN_VEHICLE, VEHICLE, MODEL_MASTER | COMFMTL0, COMINTL0 |
| FPLINT00 | Floor plan interest accrual (single/batch) | FPLN | ~620 | High | FLOOR_PLAN_VEHICLE, FLOOR_PLAN_INTEREST | COMINTL0, COMDBEL0 |
| FPLPAY00 | Floor plan payoff processing | FPLP | ~550 | Medium | FLOOR_PLAN_VEHICLE | COMINTL0, COMFMTL0, COMLGEL0 |
| FPLRPT00 | Floor plan exposure report (grouped by lender) | FPLR | ~580 | Medium | FLOOR_PLAN_VEHICLE, VEHICLE, LENDER | COMFMTL0, COMINTL0 |

## PLI - Production & Logistics Module (8 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| PLIALLO0 | Vehicle allocation engine (priority-based) | PLAL | ~650 | High | PRODUCTION_ORDER, VEHICLE, SYSTEM_CONFIG, DEALER, STOCK_POSITION | COMSTCK0, COMLGEL0 |
| PLIDLVR0 | Delivery confirmation (damage inspect, stock) | PLDL | ~620 | High | VEHICLE, SHIPMENT, SHIPMENT_VEHICLE, PDI_SCHEDULE | COMSTCK0, COMLGEL0, COMVALD0 |
| PLIETA00 | ETA tracking display (transit timeline) | PLET | ~520 | Medium | SHIPMENT, SHIPMENT_VEHICLE, VEHICLE, TRANSIT_STATUS | COMDTEL0, COMFMTL0 |
| PLIPROD0 | Production completion processing | PLPR | ~680 | High | PRODUCTION_ORDER, VEHICLE, VEHICLE_OPTION | COMVALD0, COMVINL0, COMDBEL0, COMLGEL0 |
| PLIRECON | Production-to-stock reconciliation | PLRC | ~580 | Medium | PRODUCTION_ORDER, VEHICLE, SHIPMENT, SHIPMENT_VEHICLE | COMDTEL0, COMFMTL0, COMMSGL0 |
| PLISHPN0 | Shipment creation and dispatch | PLSH | ~620 | High | SHIPMENT, SHIPMENT_VEHICLE, VEHICLE | COMSEQL0, COMSTCK0, COMLGEL0 |
| PLITRNS0 | Transit status update (EDI 214) | PLTR | ~580 | High | SHIPMENT, TRANSIT_STATUS, VEHICLE | COMEDIL0, COMDBEL0, COMLGEL0 |
| PLIVPDS0 | PDI scheduling and tracking | PLPD | ~520 | Medium | PDI_SCHEDULE, VEHICLE | COMLGEL0, COMDBEL0 |

## REG - Registration & Title Module (5 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| REGGEN00 | Registration document generation | RGGE | ~620 | High | REGISTRATION, SALES_DEAL, VEHICLE, CUSTOMER, TAX_RATE | COMVALD0, COMTAXL0, COMLGEL0, COMDBEL0 |
| REGINQ00 | Registration inquiry (by REG ID/VIN/deal) | RGIN | ~480 | Medium | REGISTRATION, VEHICLE, CUSTOMER, SALES_DEAL | COMDBEL0 |
| REGSTS00 | Registration status update (DMV response) | RGST | ~520 | Medium | REGISTRATION, TITLE_STATUS | COMLGEL0, COMDBEL0 |
| REGSUB00 | Registration submission to state DMV | RGSB | ~550 | Medium | REGISTRATION, TITLE_STATUS, VEHICLE, CUSTOMER | COMLGEL0, COMDBEL0 |
| REGVAL00 | Registration validation against state rules | RGVL | ~520 | Medium | REGISTRATION, CUSTOMER, TAX_RATE | COMVALD0, COMLGEL0, COMDBEL0 |

## STK - Stock Management Module (10 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| STKADJT0 | Manual stock adjustments (damage, write-off, reclass) | STKA | ~550 | Medium | VEHICLE, STOCK_ADJUSTMENT, STOCK_POSITION | COMSTCK0, COMLGEL0, COMDBEL0 |
| STKAGIN0 | Stock aging engine (days on lot, aging buckets) | STKG | ~580 | Medium | VEHICLE, PRICE_MASTER | COMDTEL0, COMFMTL0 |
| STKALRT0 | Low stock alert processor | STKL | ~450 | Low | STOCK_POSITION, MODEL_MASTER | COMFMTL0, COMMSGL0 |
| STKHLD00 | Vehicle hold/release management | STKH | ~480 | Medium | VEHICLE, STOCK_POSITION | COMSTCK0, COMLGEL0 |
| STKINQ00 | Stock position inquiry (filtered, paginated) | STKI | ~520 | Medium | STOCK_POSITION, MODEL_MASTER | COMFMTL0, COMMSGL0 |
| STKRCN00 | Stock reconciliation (system vs physical count) | STKR | ~580 | High | STOCK_POSITION, MODEL_MASTER, STOCK_ADJUSTMENT | COMLGEL0, COMDBEL0 |
| STKSNAP0 | Daily stock snapshot capture | STKN | ~520 | Medium | STOCK_POSITION, VEHICLE, PRICE_MASTER, STOCK_SNAPSHOT | COMDBEL0, COMLGEL0 |
| STKSUM00 | Stock summary dashboard (by body style) | STKS | ~480 | Low | STOCK_POSITION, MODEL_MASTER, PRICE_MASTER, VEHICLE | COMFMTL0 |
| STKTRN00 | Inter-dealer stock transfer | STKT | ~620 | High | STOCK_TRANSFER, VEHICLE, DEALER | COMSTCK0, COMSEQL0, COMLGEL0 |
| STKVALS0 | Stock valuation (floor plan exposure) | STKV | ~520 | Medium | VEHICLE, PRICE_MASTER, FLOOR_PLAN_VEHICLE | COMPRCL0, COMFMTL0 |

## VEH - Vehicle Module (8 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| VEHAGE00 | Inventory aging display (bucket summary + detail) | VHAG | ~520 | Medium | VEHICLE, PRICE_SCHEDULE | COMDTEL0, COMFMTL0, COMPRCL0 |
| VEHALL00 | Vehicle allocation from manufacturer | VHAL | ~580 | High | PRODUCTION_ORDER, VEHICLE, DEALER | COMVALD0, COMSTCK0, COMLGEL0 |
| VEHINQ00 | Vehicle inquiry by VIN/stock (detail + options + history) | VHIQ | ~620 | Medium | VEHICLE, VEHICLE_OPTION, VEHICLE_STATUS_HIST, MODEL_MASTER | COMFMTL0, COMVINL0 |
| VEHLOC00 | Lot location management (INQ/ADD/UPD/ASGN) | VHLC | ~580 | Medium | LOT_LOCATION, VEHICLE | COMLGEL0, COMDBEL0 |
| VEHLST00 | Vehicle listing with dynamic filters (paginated) | VHLS | ~550 | Medium | VEHICLE, MODEL_MASTER | COMFMTL0, COMMSGL0 |
| VEHRCV00 | Vehicle receiving / dock check-in | VHRC | ~680 | High | VEHICLE, PDI_SCHEDULE, VEHICLE_STATUS_HIST | COMVALD0, COMVINL0, COMSTCK0, COMSEQL0, COMLGEL0 |
| VEHTRN00 | Dealer-to-dealer trade/transfer (request/approve/complete) | VHTR | ~650 | High | VEHICLE, STOCK_TRANSFER | COMSTCK0, COMLGEL0, COMSEQL0 |
| VEHUPD00 | Vehicle status update (validated transitions) | VHUP | ~550 | Medium | VEHICLE, VEHICLE_STATUS_HIST | COMSTCK0, COMLGEL0 |

## WRC - Warranty & Recall Module (6 Programs)

| Program ID | Description | IMS Tran | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| WRCINQ00 | Warranty coverage lookup (remaining days calc) | WRCI | ~520 | Medium | WARRANTY, VEHICLE, MODEL_MASTER, SALES_DEAL, CUSTOMER | COMFMTL0, COMDTEL0 |
| WRCNOTF0 | Recall notification generation (by campaign) | WRNF | ~620 | High | RECALL_CAMPAIGN, RECALL_VEHICLE, SALES_DEAL, CUSTOMER, RECALL_NOTIFICATION | COMLGEL0, COMDBEL0 |
| WRCRCL00 | Recall management (INQ/VEH/UPD status) | WRCR | ~580 | Medium | RECALL_CAMPAIGN, RECALL_VEHICLE, VEHICLE | COMLGEL0, COMDBEL0, COMFMTL0 |
| WRCRCLB0 | Recall batch (inbound manufacturer feed) | WRRB | ~620 | High | RECALL_CAMPAIGN, RECALL_VEHICLE, VEHICLE | COMVALD0, COMDBEL0, COMLGEL0 |
| WRCRPT00 | Warranty claims summary report | WRRT | ~480 | Medium | WARRANTY_CLAIM, DEALER | COMFMTL0, COMDBEL0 |
| WRCWAR00 | Warranty registration (4 standard coverages) | WRWA | ~580 | Medium | WARRANTY, SALES_DEAL, VEHICLE | COMDTEL0, COMLGEL0, COMDBEL0 |

## BAT - Batch Programs (11 Programs)

| Program ID | Description | Schedule | Lines | Complexity | Key Tables | Called Subroutines |
|-----------|-------------|----------|------:|------------|------------|-------------------|
| BATDLY00 | Daily end-of-day processing | Nightly | ~780 | High | VEHICLE, SALES_DEAL, FLOOR_PLAN_VEHICLE, FLOOR_PLAN_LENDER, FLOOR_PLAN_INTEREST, RESTART_CONTROL | COMCKPL0, COMINTL0, COMDBEL0, COMLGEL0 |
| BATWKL00 | Weekly batch (aging, warranty notices, recall %) | Sunday | ~680 | High | VEHICLE, WARRANTY, CUSTOMER, RECALL_CAMPAIGN, RECALL_VEHICLE, RECALL_NOTIFICATION, RESTART_CONTROL | COMCKPL0, COMDTEL0, COMDBEL0, COMLGEL0 |
| BATMTH00 | Monthly close (stats, counter roll, archive) | Last business day | ~750 | High | DEALER, SALES_DEAL, MONTHLY_SNAPSHOT, STOCK_POSITION, FINANCE_PRODUCT, RESTART_CONTROL | COMCKPL0, COMDBEL0, COMLGEL0 |
| BATCRM00 | CRM feed extract (pipe-delimited) | Daily | ~620 | Medium | CUSTOMER, SALES_DEAL, BATCH_CONTROL, BATCH_CHECKPOINT | COMCKPL0, COMDBEL0, COMLGEL0 |
| BATDMS00 | DMS interface (deal + inventory export) | Daily | ~650 | Medium | VEHICLE, SALES_DEAL, CUSTOMER, DEALER, BATCH_CONTROL, BATCH_CHECKPOINT | COMCKPL0, COMDBEL0, COMLGEL0 |
| BATGLINT | General ledger interface (GL posting entries) | Daily | ~620 | High | SALES_DEAL, VEHICLE, FINANCE_APP, BATCH_CHECKPOINT | COMCKPL0, COMDBEL0, COMLGEL0 |
| BATDLAKE | Data lake extract (JSON-like) | Daily | ~580 | Medium | AUDIT_LOG, SALES_DEAL, VEHICLE, CUSTOMER, FINANCE_APP, REGISTRATION, BATCH_CHECKPOINT | COMCKPL0, COMDBEL0, COMLGEL0 |
| BATINB00 | Manufacturer inbound allocation feed | As received | ~620 | High | VEHICLE, MODEL_MASTER, BATCH_CHECKPOINT | COMCKPL0, COMDBEL0, COMLGEL0 |
| BATPUR00 | Quarterly purge/archive | Quarterly | ~550 | Medium | REGISTRATION, AUDIT_LOG, RECALL_NOTIFICATION, RESTART_CONTROL | COMCKPL0, COMDBEL0 |
| BATVAL00 | Data validation/integrity batch | Weekly | ~580 | Medium | SALES_DEAL, CUSTOMER, VEHICLE, DEALER, RESTART_CONTROL | COMCKPL0, COMVINL0, COMDBEL0 |
| BATRSTRT | Restart utility for batch recovery | On-demand | ~380 | Low | BATCH_CHECKPOINT | None |

## COM - Common Modules (16 Programs)

| Program ID | Description | Lines | Complexity | Key Tables | Interface |
|-----------|-------------|------:|------------|------------|-----------|
| COMCKPL0 | Checkpoint/restart handler (CHKP/XRST/DONE/FAIL) | ~580 | High | RESTART_CONTROL | CALL using function/data/result |
| COMDBEL0 | DB2 error handler (SQLCODE evaluation) | ~420 | Medium | None | CALL using SQLCA + context |
| COMDTEL0 | Date/time utilities (JULG/GJUL/DAYS/BDAY/AGED/CURR) | ~620 | Medium | None | CALL using function/input/output |
| COMEDIL0 | EDI message parser (EDI 214 + EDI 856) | ~750 | High | None | CALL using request/result |
| COMFMTL0 | Field formatting (CURR/PHON/SSNM/VINF/PCTF/RATF) | ~580 | Medium | None | CALL using function/input/output |
| COMINTL0 | Floor plan interest calculation (30/360, ACT/365, ACT/ACT) | ~680 | High | FLOOR_PLAN_VEHICLE, FLOOR_PLAN_INTEREST | CALL using request/result |
| COMLESL0 | Lease payment calculation | ~520 | High | None | CALL using request/result |
| COMLGEL0 | Audit logging (INSERT into AUDIT_LOG) | ~380 | Low | AUDIT_LOG | CALL using user/program/action/table/key/old/new |
| COMLONL0 | Loan amortization calculation | ~480 | High | None | CALL using request/result |
| COMMSGL0 | IMS DC message builder (INFO/ERR/WARN) | ~380 | Low | None | CALL using function/text/severity/program/output |
| COMPRCL0 | Vehicle pricing engine (MSRP/INVP/GROS/MRGN/DEAL) | ~620 | High | PRICE_MASTER | CALL using input/result |
| COMSEQL0 | Sequence number generator (NEXT_DEAL_NUM, etc.) | ~380 | Medium | SYSTEM_CONFIG | CALL using request/result |
| COMSTCK0 | Stock count update (RECV/SOLD/HOLD/RLSE/TRNI/TRNO/ALOC) | ~620 | High | STOCK_POSITION, VEHICLE, VEHICLE_STATUS_HIST | CALL using request/result |
| COMTAXL0 | Tax calculation (state/county/city + fees) | ~580 | High | TAX_RATE | CALL using state/county/city/input/result |
| COMVALD0 | VIN validation (17-char, check digit, NHTSA) | ~480 | High | None | CALL using VIN/RC/error/decoded |
| COMVINL0 | VIN decoder (WMI, VDS, check, year, plant, seq) | ~520 | High | None | CALL using request/result |

## RPT - Report Programs (14 Programs)

| Program ID | Description | Lines | Complexity |
|-----------|-------------|------:|------------|
| RPTAGN00 | Agent/Salesperson performance report | ~480 | Medium |
| RPTCOM00 | Commission report | ~520 | Medium |
| RPTCUS00 | Customer activity report | ~480 | Medium |
| RPTDLY00 | Daily sales summary report | ~550 | Medium |
| RPTFIN00 | Finance summary report | ~520 | Medium |
| RPTFPL00 | Floor plan exposure report | ~480 | Medium |
| RPTINV00 | Inventory valuation report | ~550 | Medium |
| RPTMFG00 | Manufacturer report | ~480 | Medium |
| RPTMTH00 | Monthly performance report | ~580 | High |
| RPTPRF00 | Profitability analysis report | ~580 | High |
| RPTREG00 | Registration status report | ~450 | Medium |
| RPTSUP00 | Supplier/vendor report | ~450 | Low |
| RPTWAR00 | Warranty claims report | ~480 | Medium |
| RPTWKL00 | Weekly activity report | ~520 | Medium |
