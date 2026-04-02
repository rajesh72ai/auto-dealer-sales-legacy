"""Capture screenshots of all key AUTOSALES screens for the demo deck."""
import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "docs", "demo_screenshots")
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

BASE_URL = "http://localhost:3004"


def capture():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1400, "height": 900})
        page = context.new_page()

        def screenshot(name, wait=2):
            time.sleep(wait)
            path = os.path.join(SCREENSHOTS_DIR, name)
            page.screenshot(path=path)
            print(f"  Captured: {name}")

        # 1. Login Page
        print("1. Login Page...")
        page.goto(f"{BASE_URL}/login")
        page.wait_for_load_state("networkidle")
        screenshot("01_login.png")

        # Login
        print("   Logging in...")
        time.sleep(5)  # Wait for React to render
        page.fill('input[id="userId"]', 'ADMIN001')
        page.fill('input[id="password"]', 'Admin123')
        page.click('button[type="submit"]')
        page.wait_for_url("**/dashboard**", timeout=20000)

        # 2. Dashboard (with System Health)
        print("2. Dashboard...")
        page.wait_for_load_state("networkidle")
        screenshot("02_dashboard.png", 3)

        # 3. Customers
        print("3. Customers...")
        page.goto(f"{BASE_URL}/customers")
        page.wait_for_load_state("networkidle")
        screenshot("03_customers.png", 3)

        # 4. Deal Pipeline
        print("4. Deal Pipeline...")
        page.goto(f"{BASE_URL}/deals")
        page.wait_for_load_state("networkidle")
        screenshot("04_deal_pipeline.png", 3)

        # 5. Vehicle Inventory
        print("5. Vehicle List...")
        page.goto(f"{BASE_URL}/vehicles")
        page.wait_for_load_state("networkidle")
        screenshot("05_vehicle_list.png", 3)

        # 6. Vehicle Detail (first available vehicle)
        print("6. Vehicle Detail...")
        page.goto(f"{BASE_URL}/vehicles/1FTFW1E53NFA00101")
        page.wait_for_load_state("networkidle")
        screenshot("06_vehicle_detail.png", 3)

        # 7. Loan Calculator
        print("7. Loan Calculator...")
        page.goto(f"{BASE_URL}/finance/loan-calculator")
        page.wait_for_load_state("networkidle")
        screenshot("07_loan_calculator.png", 3)

        # 8. Lease Calculator
        print("8. Lease Calculator...")
        page.goto(f"{BASE_URL}/finance/lease-calculator")
        page.wait_for_load_state("networkidle")
        screenshot("08_lease_calculator.png", 3)

        # 9. Finance Applications
        print("9. Finance Applications...")
        page.goto(f"{BASE_URL}/finance/applications")
        page.wait_for_load_state("networkidle")
        screenshot("09_finance_apps.png", 3)

        # 10. Floor Plan
        print("10. Floor Plan...")
        page.goto(f"{BASE_URL}/floor-plan")
        page.wait_for_load_state("networkidle")
        screenshot("10_floor_plan.png", 3)

        # 11. Floor Plan Exposure Report
        print("11. FP Exposure Report...")
        page.goto(f"{BASE_URL}/floor-plan/reports")
        page.wait_for_load_state("networkidle")
        screenshot("11_fp_exposure.png", 3)

        # 12. Stock Dashboard
        print("12. Stock Dashboard...")
        page.goto(f"{BASE_URL}/stock")
        page.wait_for_load_state("networkidle")
        screenshot("12_stock_dashboard.png", 3)

        # 13. Stock Positions
        print("13. Stock Positions...")
        page.goto(f"{BASE_URL}/stock/positions")
        page.wait_for_load_state("networkidle")
        screenshot("13_stock_positions.png", 3)

        # 14. Vehicle Aging
        print("14. Vehicle Aging...")
        page.goto(f"{BASE_URL}/vehicles/aging")
        page.wait_for_load_state("networkidle")
        screenshot("14_vehicle_aging.png", 3)

        # 15. Stock Transfers
        print("15. Stock Transfers...")
        page.goto(f"{BASE_URL}/stock/transfers")
        page.wait_for_load_state("networkidle")
        screenshot("15_stock_transfers.png", 3)

        # 16. Production Orders
        print("16. Production Orders...")
        page.goto(f"{BASE_URL}/production/orders")
        page.wait_for_load_state("networkidle")
        screenshot("16_production_orders.png", 3)

        # 17. Shipments
        print("17. Shipments...")
        page.goto(f"{BASE_URL}/shipments")
        page.wait_for_load_state("networkidle")
        screenshot("17_shipments.png", 3)

        # 18. PDI Schedule
        print("18. PDI Schedule...")
        page.goto(f"{BASE_URL}/pdi")
        page.wait_for_load_state("networkidle")
        screenshot("18_pdi_schedule.png", 3)

        # 19. Registration
        print("19. Registrations...")
        page.goto(f"{BASE_URL}/registration")
        page.wait_for_load_state("networkidle")
        screenshot("19_registrations.png", 3)

        # 20. Warranty
        print("20. Warranty...")
        page.goto(f"{BASE_URL}/warranty")
        page.wait_for_load_state("networkidle")
        screenshot("20_warranty.png", 3)

        # 21. Warranty Claims
        print("21. Warranty Claims...")
        page.goto(f"{BASE_URL}/warranty-claims")
        page.wait_for_load_state("networkidle")
        screenshot("21_warranty_claims.png", 3)

        # 22. Recall Campaigns
        print("22. Recall Campaigns...")
        page.goto(f"{BASE_URL}/recall")
        page.wait_for_load_state("networkidle")
        screenshot("22_recall_campaigns.png", 3)

        # 23. Batch Jobs
        print("23. Batch Jobs...")
        page.goto(f"{BASE_URL}/batch/jobs")
        page.wait_for_load_state("networkidle")
        screenshot("23_batch_jobs.png", 3)

        # 24. Batch Reports
        print("24. Batch Reports...")
        page.goto(f"{BASE_URL}/batch/reports")
        page.wait_for_load_state("networkidle")
        screenshot("24_batch_reports.png", 3)

        # 25. Admin - Dealers
        print("25. Admin Dealers...")
        page.goto(f"{BASE_URL}/admin/dealers")
        page.wait_for_load_state("networkidle")
        screenshot("25_admin_dealers.png", 3)

        # 26. Admin - User Management
        print("26. User Management...")
        page.goto(f"{BASE_URL}/admin/users")
        page.wait_for_load_state("networkidle")
        screenshot("26_user_management.png", 3)

        # 27. Admin - Audit Log
        print("27. Audit Log...")
        page.goto(f"{BASE_URL}/admin/audit-log")
        page.wait_for_load_state("networkidle")
        screenshot("27_audit_log.png", 3)

        # 28. Lot Locations
        print("28. Lot Locations...")
        page.goto(f"{BASE_URL}/admin/lot-locations")
        page.wait_for_load_state("networkidle")
        screenshot("28_lot_locations.png", 3)

        browser.close()
        count = len(os.listdir(SCREENSHOTS_DIR))
        print(f"\nDone! {count} screenshots saved to {SCREENSHOTS_DIR}")


if __name__ == "__main__":
    capture()
