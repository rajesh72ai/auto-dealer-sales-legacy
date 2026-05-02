"""Capture AgentWidget screenshots for pitch video v2.

Outputs in docs/demo_screenshots/:
  32_agent_empty.png    — widget open, 8 workflow recipe cards visible (expanded)
  33_agent_response.png — Morning Briefing completed, tables + cost badge
  34_agent_history.png  — history panel open with persisted conversations
"""
import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "docs", "demo_screenshots")
BASE_URL = "http://localhost:3004"


def capture():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1600, "height": 1000})
        page = context.new_page()

        print("Logging in...")
        page.goto(f"{BASE_URL}/login")
        page.wait_for_load_state("networkidle")
        time.sleep(2)
        page.fill('input[id="userId"]', 'ADMIN001')
        page.fill('input[id="password"]', 'Admin123')
        page.click('button[type="submit"]')
        page.wait_for_url("**/dashboard**", timeout=20000)
        page.wait_for_load_state("networkidle")
        time.sleep(2)

        agent_button = page.locator('button:has-text("AI Agent")').first

        def open_agent():
            agent_button.click()
            time.sleep(2)

        def close_agent():
            agent_button.click()
            time.sleep(1)

        def click_expand_if_available():
            # Cycle size: compact -> expanded. Expanded shows 2-col workflow grid.
            expand = page.locator('button[title*="Expand"], button[aria-label*="Expand"], button[title*="expand"]').first
            if expand.count() > 0:
                expand.click()
                time.sleep(1)

        # ── Shot 1: Empty state with workflow cards ──────────────────────────
        print("\n1. Agent empty state...")
        open_agent()
        click_expand_if_available()
        time.sleep(1)
        path = os.path.join(SCREENSHOTS_DIR, "32_agent_empty.png")
        page.screenshot(path=path)
        print(f"  Captured: 32_agent_empty.png")

        # ── Shot 2: Completed Deal Health Check response ─────────────────────
        print("\n2. Deal Health Check response...")
        # Deal Health Check produces a clean tabular RED/YELLOW/GREEN verdict fast.
        health_card = page.locator('button:has(p:has-text("Deal Health Check"))').first
        health_card.click()
        time.sleep(1)

        textarea = page.locator('textarea[placeholder*="Ask the agent"]').first
        current = textarea.input_value()
        filled = current.replace("{deal-number}", "DL01000001")
        textarea.fill(filled)
        time.sleep(0.5)
        textarea.press("Enter")

        print("  Waiting for agent stream to fully complete (up to 180s)...")
        # A completed response means the PDF/Email/Copy buttons appear AND
        # the assistant message has substantive content (>500 chars) with markdown tables.
        done = False
        for i in range(180):
            time.sleep(1)
            try:
                pdf_buttons = page.locator('button:has-text("PDF")').count()
                copy_buttons = page.locator('button:has-text("Copy")').count()
                # Check that the assistant message block has a <table> rendered (indicates final formatted output)
                tables = page.locator('.max-w-\\[95\\%\\] table, [class*="rounded-2xl"] table').count()
                if pdf_buttons >= 1 and copy_buttons >= 1 and tables >= 1:
                    done = True
                    print(f"  Response complete after {i+1}s (PDF+Copy+table detected)")
                    break
            except Exception:
                pass
        if not done:
            print("  (fallback: waited full 180s without detecting complete markers)")
        time.sleep(3)

        # Scroll to bottom of message area so cost badge + export buttons are visible
        page.evaluate(
            "() => { const panels = document.querySelectorAll('[class*=\"overflow-y\"]'); "
            "panels.forEach(p => p.scrollTop = p.scrollHeight); }"
        )
        time.sleep(1)
        path = os.path.join(SCREENSHOTS_DIR, "33_agent_response.png")
        page.screenshot(path=path)
        print(f"  Captured: 33_agent_response.png")

        # ── Shot 3: History panel ────────────────────────────────────────────
        print("\n3. Agent history panel...")
        history_button = page.locator('button[title*="History"], button[aria-label*="History"]').first
        if history_button.count() == 0:
            # Fallback: find by lucide icon class or position (2nd header button: Plus, History, Trash, X)
            history_button = page.locator('header button, [class*="border-b"] button').nth(1)
        history_button.click()
        time.sleep(2)
        path = os.path.join(SCREENSHOTS_DIR, "34_agent_history.png")
        page.screenshot(path=path)
        print(f"  Captured: 34_agent_history.png")

        browser.close()
        print("\nDone. 3 screenshots saved to docs/demo_screenshots/")


if __name__ == "__main__":
    capture()
