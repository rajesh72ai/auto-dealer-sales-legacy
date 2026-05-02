"""Capture a screenshot of the AI chat widget with a live conversation."""
import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "docs", "demo_screenshots")
BASE_URL = "http://localhost:3004"


def capture_ai_chat():
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

        # Open AI chat
        print("Opening AI Assistant...")
        chat_button = page.locator('button:has-text("AI Assistant")')
        chat_button.click()
        time.sleep(2)

        # Select Mistral Small provider
        print("Selecting Mistral Small...")
        provider_select = page.locator('select')
        if provider_select.count() > 0:
            provider_select.select_option(value="mistral")
            time.sleep(1)

        # Send a question
        print("Sending: Show stock summary...")
        chat_input = page.locator('input[placeholder="Ask anything..."]')
        chat_input.fill("Show me the stock summary for dealer DLR01")
        chat_input.press("Enter")

        # Wait for response (tool-calling loop takes time)
        print("Waiting for AI response (up to 90s)...")
        # Wait until the loading spinner disappears
        page.wait_for_selector('.animate-spin', state='detached', timeout=90000)
        time.sleep(3)  # Let markdown render fully

        # Capture
        path = os.path.join(SCREENSHOTS_DIR, "29_ai_chat.png")
        page.screenshot(path=path)
        print(f"Captured: {path}")

        browser.close()


if __name__ == "__main__":
    capture_ai_chat()
