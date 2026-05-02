"""Capture AgentWidget proposal + undo screenshots for pitch video v2.

Produces in docs/demo_screenshots/:
  35_agent_proposal.png — Pending proposal card (amber) with dry-run preview,
                          Execute + Cancel buttons, expiry clock
  36_agent_undo.png     — Executed state (green) with "Undo (Xs)" button
                          and live countdown visible

Requires AUTOSALES app running on http://localhost:3004 (UI) + 8480 (API).
Uses the "Inventory Rebalance" recipe card which produces transfer_stock
proposals based on real inventory — more reliable than hand-crafted payloads
and a better pitch use case (cross-dealer optimization).
Widget is captured in "expanded" (medium) size — 720px wide.
"""
import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "docs", "demo_screenshots")
BASE_URL = "http://localhost:3004"

# Trigger: click Inventory Rebalance recipe card, then append a directive
# nudging the agent to propose concrete transfers (not just a report).
REBALANCE_SUFFIX = (
    " Propose specific transfer_stock actions I can confirm — one at a time. "
    "Skip the narrative report; go straight to the first proposal."
)


def capture():
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
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

        # Open Agent, cycle size to "expanded" (medium — matches 32/33 screenshots)
        print("Opening Agent (expanded / medium size)...")
        page.locator('button:has-text("AI Agent")').first.click()
        time.sleep(2)
        expand = page.locator(
            'button[title*="Expand"], button[aria-label*="Expand"], button[title*="expand"]'
        ).first
        if expand.count() > 0:
            expand.click()
            time.sleep(1)

        # Click "Inventory Rebalance" recipe card to pre-fill the template
        print("Clicking Inventory Rebalance recipe...")
        rebalance_card = page.locator(
            'button:has(p:has-text("Inventory Rebalance"))'
        ).first
        rebalance_card.click()
        time.sleep(1)

        # Append directive so agent proposes transfers, not just a report
        textarea = page.locator('textarea[placeholder*="Ask the agent"]').first
        current = textarea.input_value()
        textarea.fill(current + REBALANCE_SUFFIX)
        time.sleep(0.5)
        textarea.press("Enter")

        # ── Wait for PROPOSAL card to appear ─────────────────────────────────
        # The proposal card shows "Proposed action — awaiting confirmation"
        # in an amber panel with Execute + Cancel buttons.
        print("Waiting for proposal card (up to 300s)...")
        proposal_locator = page.locator(
            'text=/Proposed action.*awaiting confirmation/'
        ).first
        try:
            proposal_locator.wait_for(state="visible", timeout=300000)
        except Exception as e:
            # Fallback: capture whatever's on screen so we can debug
            debug_path = os.path.join(SCREENSHOTS_DIR, "_debug_proposal_timeout.png")
            page.screenshot(path=debug_path, full_page=True)
            print(f"  TIMEOUT — debug screenshot at {debug_path}")
            # Dump last assistant message content for log review
            try:
                content = page.locator('[class*="rounded-2xl"]').last.text_content(timeout=2000)
                print(f"  Last message content (trimmed):\n{(content or '')[:600]}")
            except Exception:
                pass
            raise
        time.sleep(2)  # let impact preview fully render

        # Scroll to bottom so the full proposal card + buttons are in frame
        page.evaluate(
            "() => { const panels = document.querySelectorAll('[class*=\"overflow-y\"]'); "
            "panels.forEach(p => p.scrollTop = p.scrollHeight); }"
        )
        time.sleep(1)
        path1 = os.path.join(SCREENSHOTS_DIR, "35_agent_proposal.png")
        page.screenshot(path=path1)
        print(f"  Captured: 35_agent_proposal.png")

        # ── Execute the proposal, wait for UNDO countdown ─────────────────────
        print("\nExecuting proposal...")
        execute_btn = page.locator('button:has-text("Execute")').first
        execute_btn.click()

        # Undo button text: "Undo (60s)" ... counts down to 0
        # Wait for it to appear (executed state)
        print("Waiting for executed state + undo countdown (up to 60s)...")
        undo_locator = page.locator('button:has-text("Undo (")').first
        undo_locator.wait_for(state="visible", timeout=60000)
        # Capture early so the countdown number is high (e.g. 58s / 57s) — more impactful
        time.sleep(2)

        page.evaluate(
            "() => { const panels = document.querySelectorAll('[class*=\"overflow-y\"]'); "
            "panels.forEach(p => p.scrollTop = p.scrollHeight); }"
        )
        time.sleep(0.5)
        path2 = os.path.join(SCREENSHOTS_DIR, "36_agent_undo.png")
        page.screenshot(path=path2)
        print(f"  Captured: 36_agent_undo.png")

        browser.close()
        print("\nDone. 2 screenshots saved to docs/demo_screenshots/")


if __name__ == "__main__":
    capture()
