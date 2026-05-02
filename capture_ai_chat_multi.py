"""Capture multiple AI chat screenshots showing different interactions."""
import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "docs", "demo_screenshots")
BASE_URL = "http://localhost:3004"


def capture():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1400, "height": 900})
        page = context.new_page()

        # Login
        print("Logging in...")
        page.goto(f"{BASE_URL}/login")
        page.wait_for_load_state("networkidle")
        time.sleep(3)
        page.fill('input[id="userId"]', 'ADMIN001')
        page.fill('input[id="password"]', 'Admin123')
        page.click('button[type="submit"]')
        page.wait_for_url("**/dashboard**", timeout=20000)
        page.wait_for_load_state("networkidle")
        time.sleep(2)

        def open_chat():
            chat_button = page.locator('button:has-text("AI Assistant")')
            chat_button.click()
            time.sleep(2)
            provider_select = page.locator('.fixed select').first
            if provider_select.count() > 0:
                provider_select.select_option(value="mistral")
                time.sleep(1)

        def close_chat():
            close_button = page.locator('button:has-text("AI Assistant")')
            close_button.click()
            time.sleep(1)

        def send_and_capture(question, filename, wait=90):
            chat_input = page.locator('input[placeholder="Ask anything..."]')
            chat_input.click()
            time.sleep(0.5)
            chat_input.fill(question)
            time.sleep(0.5)
            chat_input.press("Enter")
            print(f"  Waiting for response to: {question}")
            try:
                page.wait_for_selector('.animate-spin', state='visible', timeout=10000)
            except Exception:
                print("  (spinner not detected, waiting 5s)")
                time.sleep(5)
            page.wait_for_selector('.animate-spin', state='detached', timeout=wait * 1000)
            time.sleep(4)
            path = os.path.join(SCREENSHOTS_DIR, filename)
            page.screenshot(path=path)
            print(f"  Captured: {filename}")

        # Screenshot 1: Stock summary (on dashboard)
        print("\n1. Stock summary...")
        open_chat()
        send_and_capture(
            "Show me the stock summary for dealer DLR01",
            "29_ai_chat.png"
        )
        close_chat()

        # Screenshot 2: Recent deals (navigate to deals page)
        print("\n2. Recent deals...")
        page.goto(f"{BASE_URL}/deals")
        page.wait_for_load_state("networkidle")
        time.sleep(2)
        open_chat()
        send_and_capture(
            "Show me recent deals for dealer DLR01",
            "30_ai_chat_deals.png"
        )
        close_chat()

        # Screenshot 3: Warranty claims
        print("\n3. Warranty claims...")
        page.goto(f"{BASE_URL}/deals")
        page.wait_for_load_state("networkidle")
        time.sleep(2)
        open_chat()
        send_and_capture(
            "Show warranty claims for dealer DLR01",
            "31_ai_chat_warranty.png"
        )

        browser.close()
        print("\nDone! All 3 screenshots captured.")


if __name__ == "__main__":
    capture()
