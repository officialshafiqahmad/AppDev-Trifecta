"""Selenium Grid 4 checks for the guest web player. Run with: pytest -n 3 tests/selenium/"""

import json
import os
import time
import urllib.request

import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

BASE = os.environ.get("AUDIT_BASE_URL", "http://localhost:8080")
GRID = os.environ.get("SELENIUM_GRID_URL", "http://localhost:4444")
GUEST_SELECTORS = (
    "guest-video-player",
    "live-score-banner",
    "pinned-merch-card",
    "add-to-guest-cart-btn",
    "guest-cart-count",
    "chat-message-list",
    "chat-input-field",
    "chat-send-btn",
    "progressive-auth-modal",
)


def grid_driver():
    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    return webdriver.Remote(command_executor=GRID, options=options)


@pytest.fixture
def browser():
    driver = grid_driver()
    driver.set_page_load_timeout(10)
    yield driver
    driver.quit()


def test_qr_resolution_loads_player_without_login(browser):
    browser.get(f"{BASE}/q/m1-live")
    WebDriverWait(browser, 3).until(EC.url_contains("/web/matches/match-m1/live"))
    WebDriverWait(browser, 3).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, '[data-testid="guest-video-player"]'))
    )
    banner = browser.find_element(By.CSS_SELECTOR, '[data-testid="live-score-banner"]')
    assert banner.is_displayed()
    modal = browser.find_element(By.CSS_SELECTOR, '[data-testid="progressive-auth-modal"]')
    assert modal.is_displayed() is False


def test_guest_chat_opens_progressive_modal(browser):
    browser.get(f"{BASE}/web/matches/match-m1/live")
    WebDriverWait(browser, 3).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, '[data-testid="chat-input-field"]'))
    )
    before = len(browser.find_elements(By.CSS_SELECTOR, '[data-testid="chat-message-list"] li'))
    browser.find_element(By.CSS_SELECTOR, '[data-testid="chat-input-field"]').send_keys("guest hello")
    browser.find_element(By.CSS_SELECTOR, '[data-testid="chat-send-btn"]').click()
    WebDriverWait(browser, 3).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, '[data-testid="progressive-auth-modal"]'))
    )
    after = len(browser.find_elements(By.CSS_SELECTOR, '[data-testid="chat-message-list"] li'))
    assert after == before


def test_guest_cart_and_score_sync(browser):
    browser.get(f"{BASE}/web/matches/match-m1/live")
    WebDriverWait(browser, 3).until(
        EC.text_to_be_present_in_element((By.CSS_SELECTOR, '[data-testid="live-score-banner"]'), "-")
    )
    before = browser.find_element(By.CSS_SELECTOR, '[data-testid="live-score-banner"]').text
    browser.find_element(By.CSS_SELECTOR, '[data-testid="add-to-guest-cart-btn"]').click()
    WebDriverWait(browser, 3).until(
        EC.text_to_be_present_in_element((By.CSS_SELECTOR, '[data-testid="guest-cart-count"]'), "1")
    )
    payload = json.dumps({
        "event_id": f"selenium-goal-{time.time_ns()}",
        "match_id": "match-m1",
        "type": "score",
        "payload": {"team_id": "club-alpha-1", "event_type": "goal"},
    }).encode()
    request = urllib.request.Request(
        f"{BASE}/audit/v1/events",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=5) as response:
        assert response.status == 201
    WebDriverWait(browser, 0.5).until(
        lambda driver: driver.find_element(By.CSS_SELECTOR, '[data-testid="live-score-banner"]').text != before
    )


def test_required_selectors_exist(browser):
    browser.get(f"{BASE}/web/costream/cs-session-101")
    for selector in GUEST_SELECTORS:
        assert browser.find_elements(By.CSS_SELECTOR, f'[data-testid="{selector}"]')
