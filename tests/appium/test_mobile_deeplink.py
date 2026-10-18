"""Appium 2 deep-link checks for nascon://entity/match-m1 and nascon://stream/cs-session-101."""

import json
import shutil
import subprocess
import urllib.request

import pytest

APPIUM = "http://localhost:4723/status"
DEEP_LINKS = (
    "nascon://entity/match-m1",
    "nascon://stream/cs-session-101",
)


def test_appium_status_ready():
    with urllib.request.urlopen(APPIUM, timeout=5) as response:
        body = json.load(response)
        assert response.status == 200
    value = body.get("value", body)
    assert value.get("ready") is True


@pytest.mark.parametrize("link", DEEP_LINKS)
def test_android_deep_link_opens_app(link):
    if shutil.which("adb") is None:
        pytest.skip("adb is not installed")
    devices = subprocess.run(["adb", "devices"], check=True, capture_output=True, text=True)
    online = [line for line in devices.stdout.splitlines()[1:] if line.strip().endswith("device")]
    if not online:
        pytest.skip("no Android device is attached")
    started = subprocess.run(
        [
            "adb", "shell", "am", "start", "-W",
            "-a", "android.intent.action.VIEW",
            "-d", link,
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=5,
    )
    assert "Error" not in started.stdout
    assert started.returncode == 0
