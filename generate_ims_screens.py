"""
Generate simulated IMS DC terminal screens (3270 green-screen) for the
AUTOSALES system using PIL.

Produces 8 IMS DC screens matching the MFS mapsets and COBOL programs:
  1. ADMSEC00 — IMS Sign-On
  2. ASMENU   — Main Menu (CLIST)
  3. VEHINQ00 — Vehicle Inquiry
  4. SALQOT00 — Deal Listing
  5. FINCAL00 — Loan Calculator
  6. FPLRPT00 — Floor Plan Exposure
  7. STKINQ00 — Stock Position Inquiry
  8. BATRSTRT — Batch Restart Control (REXX)

Output: docs/demo_ims_screens/*.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "docs", "demo_ims_screens")
os.makedirs(OUTPUT_DIR, exist_ok=True)

W, H = 1280, 720

# Colors
IMS_GREEN = '#33FF33'
IMS_TURQ = '#00E5E5'
IMS_BG = '#000000'
LABEL_GREEN = '#228B22'
SEPARATOR_GREEN = '#1A5A1A'
IMS_RED = '#FF4444'
IMS_WHITE = '#FFFFFF'
IMS_YELLOW = '#FFFF00'


def get_fonts():
    try:
        return {
            'bms': ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14),
            'bms_title': ImageFont.truetype('C:/Windows/Fonts/consolab.ttf', 16),
            'bms_large': ImageFont.truetype('C:/Windows/Fonts/consolab.ttf', 18),
            'small': ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12),
        }
    except Exception:
        d = ImageFont.load_default()
        return {'bms': d, 'bms_title': d, 'bms_large': d, 'small': d}


FONTS = get_fonts()


def _add_scanlines(draw, h):
    for y in range(0, h, 3):
        draw.line([(0, y), (W, y)], fill='#0A0A0A', width=1)


def _add_border(draw):
    draw.rectangle([8, 8, W - 8, H - 8], outline='#1A3A1A', width=2)


def _add_status_bar(draw, tran_id="VEHI", user_id="TSMITH01"):
    draw.text((20, 12), f"AUTOSALES", font=FONTS['bms_title'], fill=IMS_TURQ)
    draw.text((W - 300, 12), f"TRAN: {tran_id}   USER: {user_id}", font=FONTS['small'], fill=LABEL_GREEN)
    draw.text((W - 120, 12), "03/30/2026", font=FONTS['small'], fill=LABEL_GREEN)


def _add_pfkeys(draw, keys="PF3=EXIT  PF5=UPDATE  PF7=BACK  PF8=FORWARD"):
    draw.line([(20, H - 45), (W - 20, H - 45)], fill=SEPARATOR_GREEN, width=1)
    draw.text((20, H - 38), keys, font=FONTS['small'], fill=LABEL_GREEN)


def _new_screen():
    img = Image.new('RGB', (W, H), IMS_BG)
    draw = ImageDraw.Draw(img)
    _add_scanlines(draw, H)
    _add_border(draw)
    return img, draw


def _draw_separator(draw, y):
    draw.line([(20, y), (W - 20, y)], fill=SEPARATOR_GREEN, width=1)


# ═══════════════════════════════════════════════════════════════
# Screen 1: IMS Sign-On
# ═══════════════════════════════════════════════════════════════
def screen_signon():
    img, draw = _new_screen()
    draw.text((20, 12), "AUTOSALES", font=FONTS['bms_title'], fill=IMS_TURQ)
    draw.text((W - 200, 12), "IMS DC SIGN-ON", font=FONTS['small'], fill=LABEL_GREEN)

    y = 100
    draw.text((W // 2 - 200, y), "AUTOSALES DEALER MANAGEMENT SYSTEM", font=FONTS['bms_large'], fill=IMS_GREEN)
    y += 40
    draw.text((W // 2 - 180, y), "IMS DC / COBOL / DB2 / z/OS", font=FONTS['bms'], fill=IMS_TURQ)

    y = 220
    _draw_separator(draw, y)
    y += 20
    draw.text((300, y), "USER ID  :", font=FONTS['bms'], fill=IMS_GREEN)
    draw.text((500, y), "TSMITH01", font=FONTS['bms'], fill=IMS_WHITE)
    y += 30
    draw.text((300, y), "PASSWORD :", font=FONTS['bms'], fill=IMS_GREEN)
    draw.text((500, y), "********", font=FONTS['bms'], fill=IMS_WHITE)
    y += 30
    draw.text((300, y), "DEALER   :", font=FONTS['bms'], fill=IMS_GREEN)
    draw.text((500, y), "DLR01 - LAKEWOOD FORD", font=FONTS['bms'], fill=IMS_WHITE)

    y = 400
    _draw_separator(draw, y)
    y += 15
    draw.text((300, y), "SIGN-ON SUCCESSFUL", font=FONTS['bms'], fill=IMS_GREEN)
    y += 25
    draw.text((300, y), "LAST LOGIN: 03/29/2026 16:42:00", font=FONTS['small'], fill=LABEL_GREEN)
    y += 20
    draw.text((300, y), "FAILED ATTEMPTS: 0", font=FONTS['small'], fill=LABEL_GREEN)

    _add_pfkeys(draw, "ENTER=PROCEED  PF3=EXIT")
    img.save(os.path.join(OUTPUT_DIR, "ims_01_signon.png"))


# ═══════════════════════════════════════════════════════════════
# Screen 2: Main Menu (CLIST ASMENU)
# ════════════���══════════════════════════════════════════════════
def screen_menu():
    img, draw = _new_screen()
    _add_status_bar(draw, "MENU", "TSMITH01")

    y = 50
    draw.text((W // 2 - 200, y), "AUTOSALES - MAIN MENU", font=FONTS['bms_large'], fill=IMS_GREEN)
    y += 15
    _draw_separator(draw, y + 20)

    y = 100
    items = [
        ("1", "CUSTOMER MANAGEMENT", "CUSI - Customer inquiry, add, update, credit check"),
        ("2", "SALES DESK", "SALQ - Quotes, negotiation, approval, completion"),
        ("3", "FINANCE & LENDING", "FNAP - Finance apps, calculators, F&I products"),
        ("4", "VEHICLE INVENTORY", "VEHI - Vehicle inquiry, receiving, transfers"),
        ("5", "STOCK MANAGEMENT", "STKI - Positions, adjustments, aging, alerts"),
        ("6", "FLOOR PLAN", "FPLI - Floor plan add, payoff, interest, report"),
        ("7", "PRODUCTION/LOGISTICS", "PLPR - Production, shipments, transit, PDI"),
        ("8", "REGISTRATION/WARRANTY", "REGI - Registration, warranty, recall campaigns"),
        ("9", "BATCH SUBMISSION", "REXX ASSUBMIT - Submit batch jobs"),
        ("A", "BATCH STATUS", "REXX ASSTATUS - Check job status via SDSF"),
        ("B", "REPORTS BROWSE", "CLIST ASBROWSE - Browse report output"),
        ("C", "DB2 HEALTH CHECK", "REXX ASDBCHK - Tablespace/REORG check"),
        ("D", "IMS STATUS", "REXX ASIMSCHK - Transaction queue depths"),
        ("X", "EXIT", "Return to TSO READY prompt"),
    ]
    for code, label, desc in items:
        y += 30
        draw.text((100, y), code, font=FONTS['bms'], fill=IMS_TURQ)
        draw.text((150, y), f". {label}", font=FONTS['bms'], fill=IMS_GREEN)
        draw.text((550, y), desc, font=FONTS['small'], fill=LABEL_GREEN)

    y += 50
    _draw_separator(draw, y)
    y += 15
    draw.text((100, y), "SELECTION: _", font=FONTS['bms'], fill=IMS_WHITE)

    _add_pfkeys(draw, "ENTER=SELECT  PF3=EXIT")
    img.save(os.path.join(OUTPUT_DIR, "ims_02_main_menu.png"))


# ═══════════════════════════════════════════════════════════════
# Screen 3: Vehicle Inquiry (VEHINQ00)
# ══════════════════════════════════════════════════════════════��
def screen_vehicle_inquiry():
    img, draw = _new_screen()
    _add_status_bar(draw, "VEHI", "TSMITH01")

    y = 50
    draw.text((W // 2 - 150, y), "VEHICLE INQUIRY", font=FONTS['bms_large'], fill=IMS_GREEN)
    _draw_separator(draw, y + 25)

    y = 90
    draw.text((30, y), "VIN: 1FTFW1E53NFA00101", font=FONTS['bms'], fill=IMS_WHITE)
    draw.text((500, y), "STOCK#: F01-0101", font=FONTS['bms'], fill=IMS_WHITE)

    y += 30
    draw.text((30, y), "---- VEHICLE INFORMATION ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "YEAR: 2025  MAKE: FRD  MODEL: F150XL    COLOR: WHT/GRY", font=FONTS['bms'], fill=IMS_GREEN)
    y += 22
    draw.text((30, y), "STATUS: AV (AVAILABLE)          DEALER: DLR01", font=FONTS['bms'], fill=IMS_GREEN)
    y += 22
    draw.text((30, y), "LOT: FRNT01                     PDI: Y   DAMAGE: N", font=FONTS['bms'], fill=IMS_GREEN)
    y += 22
    draw.text((30, y), "RECV DATE: 07/05/2025           DAYS IN STOCK: 088", font=FONTS['bms'], fill=IMS_GREEN)
    y += 22
    draw.text((30, y), "ODOMETER: 000012", font=FONTS['bms'], fill=IMS_GREEN)

    y += 30
    draw.text((30, y), "---- INSTALLED OPTIONS ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "CODE   DESCRIPTION                        PRICE", font=FONTS['bms'], fill=IMS_YELLOW)
    opts = [
        ("XLTPKG", "XLT CHROME APPEARANCE PKG", "1,995.00"),
        ("TOWMAX", "MAX TRAILER TOW PACKAGE", "1,295.00"),
        ("BEDLNR", "SPRAY-IN BEDLINER", "595.00"),
        ("NAVSYS", "NAVIGATION SYSTEM W/ SYNC 4", "795.00"),
    ]
    for code, desc, price in opts:
        y += 20
        draw.text((30, y), f"{code:6s} {desc:35s} {price:>10s}", font=FONTS['bms'], fill=IMS_GREEN)

    y += 30
    draw.text((30, y), "---- STATUS HISTORY ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "SEQ  OLD  NEW  CHANGED BY  REASON                     DATE", font=FONTS['bms'], fill=IMS_YELLOW)
    history = [
        ("004", "DL", "AV", "TSMITH01", "PDI COMPLETED - ALL ITEMS PASSED", "07/05/25"),
        ("003", "IT", "DL", "SYSTEM", "DELIVERED TO DEALER DOCK", "07/01/25"),
        ("002", "AL", "IT", "SYSTEM", "SHIPPED VIA TRUCK CARRIER JBHT", "06/25/25"),
        ("001", "PR", "AL", "SYSTEM", "ALLOCATED TO DEALER DLR01", "06/15/25"),
    ]
    for seq, old, new, by, reason, date in history:
        y += 20
        draw.text((30, y), f"{seq}  {old}   {new}   {by:10s}  {reason:30s} {date}", font=FONTS['bms'], fill=IMS_GREEN)

    _add_pfkeys(draw, "PF3=EXIT  PF5=UPDATE  PF7=BACK  PF8=FORWARD")
    img.save(os.path.join(OUTPUT_DIR, "ims_03_vehicle_inquiry.png"))


# ═══��═══════════════════════════════════════════════════════════
# Screen 4: Deal Listing (SALQOT00)
# ══════════���═════════════════════════════════════════��══════════
def screen_deal_listing():
    img, draw = _new_screen()
    _add_status_bar(draw, "SALL", "JPATTER1")

    y = 50
    draw.text((W // 2 - 120, y), "DEAL LISTING", font=FONTS['bms_large'], fill=IMS_GREEN)
    _draw_separator(draw, y + 25)

    y = 90
    draw.text((30, y), "DEALER: DLR01    STATUS FILTER: __", font=FONTS['bms'], fill=IMS_WHITE)

    y += 30
    draw.text((30, y), "DEAL#      CUSTOMER         VEHICLE              STATUS   PRICE       DATE", font=FONTS['bms'], fill=IMS_YELLOW)
    _draw_separator(draw, y + 20)

    deals = [
        ("D000000001", "HENDERSON, M.", "2025 FRD F150XL", "FI", "38,608.94", "03/15/26"),
        ("D000000002", "MITCHELL, S.", "2025 FRD MUSTGT", "DL", "52,340.00", "03/10/26"),
        ("D000000003", "GARCIA, R.", "2025 FRD ESCSEL", "AP", "34,125.00", "03/20/26"),
        ("D000000004", "WOLFE, J.", "2026 FRD F150XL", "NE", "41,200.00", "03/25/26"),
        ("D000000005", "THOMPSON, D.", "2025 FRD MUSTGT", "WS", "48,900.00", "03/28/26"),
        ("D000000006", "REYES, A.", "2025 FRD ESCSEL", "PA", "32,800.00", "03/29/26"),
    ]
    for deal, cust, veh, status, price, date in deals:
        y += 22
        draw.text((30, y), f"{deal} {cust:16s} {veh:20s} {status:8s} {price:>11s} {date}", font=FONTS['bms'], fill=IMS_GREEN)

    y += 40
    draw.text((30, y), "PAGE: 01 OF 01                 TOTAL DEALS: 006", font=FONTS['bms'], fill=LABEL_GREEN)

    _add_pfkeys(draw, "PF3=EXIT  PF5=NEW DEAL  PF7=PREV PAGE  PF8=NEXT PAGE")
    img.save(os.path.join(OUTPUT_DIR, "ims_04_deal_listing.png"))


# ═══���═══════════════════════════════════════════════════════════
# Screen 5: Loan Calculator (FINCAL00)
# ═══════════════════════════════════════════════════════════════
def screen_loan_calculator():
    img, draw = _new_screen()
    _add_status_bar(draw, "FNCL", "TSMITH01")

    y = 50
    draw.text((W // 2 - 180, y), "LOAN PAYMENT CALCULATOR", font=FONTS['bms_large'], fill=IMS_GREEN)
    _draw_separator(draw, y + 25)

    y = 95
    draw.text((30, y), "PRINCIPAL:    30,000.00    APR:  5.90%    TERM: 060 MO", font=FONTS['bms'], fill=IMS_WHITE)
    y += 22
    draw.text((30, y), "DOWN PAYMENT:  5,000.00    NET:  25,000.00", font=FONTS['bms'], fill=IMS_WHITE)

    y += 35
    draw.text((30, y), "---- PRIMARY CALCULATION ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "MONTHLY PAYMENT:      482.63", font=FONTS['bms'], fill=IMS_GREEN)
    y += 20
    draw.text((30, y), "TOTAL OF PAYMENTS: 28,957.80", font=FONTS['bms'], fill=IMS_GREEN)
    y += 20
    draw.text((30, y), "TOTAL INTEREST:     3,957.80", font=FONTS['bms'], fill=IMS_GREEN)

    y += 35
    draw.text((30, y), "---- TERM COMPARISON ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "TERM    MONTHLY     TOTAL PMT    TOTAL INT", font=FONTS['bms'], fill=IMS_YELLOW)
    terms = [("036", "758.93", "27,321.48", "2,321.48"), ("048", "588.45", "28,245.60", "3,245.60"),
             ("060", "482.63", "28,957.80", "3,957.80"), ("072", "413.22", "29,751.84", "4,751.84")]
    for term, monthly, total, interest in terms:
        y += 20
        draw.text((30, y), f"{term}     {monthly:>10s}  {total:>12s}  {interest:>10s}", font=FONTS['bms'], fill=IMS_GREEN)

    y += 35
    draw.text((30, y), "---- AMORTIZATION (FIRST 12 MONTHS) ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "MO  PAYMENT    PRINCIPAL   INTEREST   CUM INT    BALANCE", font=FONTS['bms'], fill=IMS_YELLOW)
    amort = [("01", "482.63", "359.63", "123.00", "123.00", "24,640.37"),
             ("02", "482.63", "361.40", "121.23", "244.23", "24,278.97"),
             ("03", "482.63", "363.18", "119.45", "363.68", "23,915.79")]
    for mo, pmt, prin, intrest, cum, bal in amort:
        y += 20
        draw.text((30, y), f"{mo}   {pmt:>8s}   {prin:>9s}  {intrest:>9s}  {cum:>9s}  {bal:>10s}", font=FONTS['bms'], fill=IMS_GREEN)
    y += 20
    draw.text((30, y), "...", font=FONTS['bms'], fill=LABEL_GREEN)

    _add_pfkeys(draw, "PF3=EXIT")
    img.save(os.path.join(OUTPUT_DIR, "ims_05_loan_calculator.png"))


# ═══════════════════════════════════════════════════════════════
# Screen 6: Floor Plan Exposure (FPLRPT00)
# ══════════════════════════════════��════════════════════════════
def screen_floorplan_report():
    img, draw = _new_screen()
    _add_status_bar(draw, "FPLR", "JPATTER1")

    y = 50
    draw.text((W // 2 - 200, y), "FLOOR PLAN EXPOSURE REPORT", font=FONTS['bms_large'], fill=IMS_GREEN)
    _draw_separator(draw, y + 25)

    y = 95
    draw.text((30, y), "DEALER: DLR01 - LAKEWOOD FORD", font=FONTS['bms'], fill=IMS_WHITE)

    y += 35
    draw.text((30, y), "---- GRAND TOTALS ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "TOTAL VEHICLES:    015    TOTAL BALANCE:    465,000.00", font=FONTS['bms'], fill=IMS_GREEN)
    y += 20
    draw.text((30, y), "TOTAL INTEREST:  3,250.00  WTD AVG RATE:       5.25%", font=FONTS['bms'], fill=IMS_GREEN)
    y += 20
    draw.text((30, y), "AVG DAYS ON FLOOR:  045", font=FONTS['bms'], fill=IMS_GREEN)

    y += 35
    draw.text((30, y), "---- BY LENDER ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "LENDER     VEHICLES  BALANCE       INTEREST    AVG RATE  AVG DAYS", font=FONTS['bms'], fill=IMS_YELLOW)
    lenders = [("ALLY1", "008", "248,000.00", "1,750.00", "4.50%", "038"),
               ("CHASE", "005", "155,000.00", "1,100.00", "6.00%", "052"),
               ("BMWFS", "002", "62,000.00", "400.00", "5.75%", "048")]
    for lender, vehs, bal, interest, rate, days in lenders:
        y += 20
        draw.text((30, y), f"{lender:10s} {vehs:>5s}     {bal:>12s}  {interest:>10s}  {rate:>8s}  {days:>5s}", font=FONTS['bms'], fill=IMS_GREEN)

    y += 35
    draw.text((30, y), "---- AGE BUCKETS ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "0-30 DAYS:  005    31-60 DAYS:  006    61-90 DAYS:  003    91+ DAYS:  001", font=FONTS['bms'], fill=IMS_GREEN)

    y += 35
    draw.text((30, y), "---- NEW/USED SPLIT ----", font=FONTS['bms'], fill=IMS_TURQ)
    y += 22
    draw.text((30, y), "NEW:  012  ($372,000)     USED:  003  ($93,000)", font=FONTS['bms'], fill=IMS_GREEN)

    _add_pfkeys(draw, "PF3=EXIT  PF6=PRINT")
    img.save(os.path.join(OUTPUT_DIR, "ims_06_floorplan_report.png"))


# ═══════════════════════════���═══════════════════════════════���═══
# Screen 7: Stock Position Inquiry (STKINQ00)
# ═══════════════════════════════════════════════════════════════
def screen_stock_inquiry():
    img, draw = _new_screen()
    _add_status_bar(draw, "STKI", "JPATTER1")

    y = 50
    draw.text((W // 2 - 180, y), "STOCK POSITION INQUIRY", font=FONTS['bms_large'], fill=IMS_GREEN)
    _draw_separator(draw, y + 25)

    y = 95
    draw.text((30, y), "DEALER: DLR01    YEAR: 0000  MAKE: ___  MODEL: ______", font=FONTS['bms'], fill=IMS_WHITE)

    y += 35
    draw.text((30, y), "YEAR MAKE  MODEL  DESCRIPTION          ON-HAND  IN-TRAN  ALLOC  ON-HLD  MTD  YTD  RO-PT  ALERT", font=FONTS['bms'], fill=IMS_YELLOW)
    _draw_separator(draw, y + 18)

    stock = [
        ("2025", "FRD", "F150XL", "F-150 XL", "003", "001", "001", "001", "002", "005", "003", ""),
        ("2026", "FRD", "F150XL", "F-150 XL", "001", "000", "000", "000", "000", "000", "003", "**LOW**"),
        ("2025", "FRD", "ESCSEL", "ESCAPE SEL", "001", "000", "000", "000", "001", "002", "003", "**LOW**"),
        ("2025", "FRD", "MUSTGT", "MUSTANG GT", "001", "000", "000", "000", "002", "003", "003", "**LOW**"),
        ("2026", "FRD", "EXPLLT", "EXPLORER LTD", "000", "001", "000", "000", "000", "000", "003", "**LOW**"),
    ]
    for yr, make, model, desc, oh, it, al, hd, mtd, ytd, ro, alert in stock:
        y += 22
        color = IMS_RED if alert else IMS_GREEN
        draw.text((30, y), f"{yr} {make}  {model:6s} {desc:20s} {oh:>5s}    {it:>5s}    {al:>3s}    {hd:>3s}   {mtd:>3s}  {ytd:>3s}   {ro:>3s}  {alert}", font=FONTS['bms'], fill=color)

    y += 40
    draw.text((30, y), "PAGE: 01 OF 01                     TOTAL MODELS: 005", font=FONTS['bms'], fill=LABEL_GREEN)

    _add_pfkeys(draw, "PF3=EXIT  PF7=PREV PAGE  PF8=NEXT PAGE")
    img.save(os.path.join(OUTPUT_DIR, "ims_07_stock_inquiry.png"))


# ════���═════════════════════��════════════════════════════════════
# Screen 8: Batch Restart Control (REXX BATRSTRT)
# ══════════���════════════════════════════════════════════════════
def screen_batch_restart():
    img, draw = _new_screen()
    draw.text((20, 12), "AUTOSALES", font=FONTS['bms_title'], fill=IMS_TURQ)
    draw.text((W - 350, 12), "REXX: ASSTATUS / BATRSTRT   USER: SYSADMIN", font=FONTS['small'], fill=LABEL_GREEN)

    y = 50
    draw.text((W // 2 - 180, y), "BATCH RESTART CONTROL", font=FONTS['bms_large'], fill=IMS_GREEN)
    _draw_separator(draw, y + 25)

    y = 95
    draw.text((30, y), "FUNC: DISP  (DISP=DISPLAY  RESET=RESET  COMPL=COMPLETE)", font=FONTS['bms'], fill=IMS_WHITE)

    y += 35
    draw.text((30, y), "PROGRAM    DESCRIPTION              LAST RUN     STATUS  RECORDS  STEP", font=FONTS['bms'], fill=IMS_YELLOW)
    _draw_separator(draw, y + 18)

    jobs = [
        ("BATDLY00", "DAILY END OF DAY", "03/29/2026", "OK", "000142", "003"),
        ("BATMTH00", "MONTHLY CLOSE", "02/28/2026", "OK", "000089", "005"),
        ("BATWKL00", "WEEKLY PROCESSING", "03/28/2026", "OK", "000050", "002"),
        ("BATPUR00", "PURGE/ARCHIVE", "03/01/2026", "OK", "001250", "003"),
        ("BATVAL00", "DATA VALIDATION", "03/29/2026", "WARN", "000003", "001"),
        ("BATGLINT", "GL POSTING", "03/29/2026", "OK", "000045", "004"),
        ("BATCRM00", "CRM FEED EXTRACT", "03/29/2026", "OK", "000320", "002"),
        ("BATDMS00", "DMS INTERFACE", "03/29/2026", "OK", "000180", "003"),
        ("BATDLAKE", "DATA LAKE EXTRACT", "03/29/2026", "OK", "000890", "005"),
        ("BATINB00", "INBOUND VEHICLE FEED", "03/28/2026", "OK", "000015", "001"),
        ("BATRSTRT", "RESTART UTILITY", "N/A", "N/A", "N/A", "N/A"),
    ]
    for prog, desc, lastrun, status, records, step in jobs:
        y += 22
        color = IMS_YELLOW if status == "WARN" else IMS_GREEN
        if status == "N/A":
            color = LABEL_GREEN
        draw.text((30, y), f"{prog:10s} {desc:24s} {lastrun:12s} {status:>7s}  {records:>6s}   {step:>3s}", font=FONTS['bms'], fill=color)

    _add_pfkeys(draw, "PF3=EXIT  PF5=RESET  PF6=COMPLETE")
    img.save(os.path.join(OUTPUT_DIR, "ims_08_batch_restart.png"))


# ═══════════════════════════════════════════════════════════════
# Generate all screens
# ═════════════════════���═════════════════════════════════════════
if __name__ == "__main__":
    screen_signon()
    screen_menu()
    screen_vehicle_inquiry()
    screen_deal_listing()
    screen_loan_calculator()
    screen_floorplan_report()
    screen_stock_inquiry()
    screen_batch_restart()
    print(f"Generated 8 IMS DC screens in {OUTPUT_DIR}")
