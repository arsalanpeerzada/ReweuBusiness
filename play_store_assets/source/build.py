"""Render the Google Play listing graphics from index.html with headless Chrome.

Usage (from the repo root):  python play_store_assets/source/build.py
Output: play_store_assets/google_play/*.png (flattened RGB, exact Play sizes).
Set CHROME to override the Chrome executable path.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

SRC = Path(__file__).resolve().parent
OUT = SRC.parent / "google_play"
CHROME = os.environ.get("CHROME", r"C:\Program Files\Google\Chrome\Application\chrome.exe")

ASSETS = [
    ("icon", "app_icon_512.png", 512, 512),
    ("icon1024", "app_icon_1024.png", 1024, 1024),
    ("feature", "feature_graphic_1024x500.png", 1024, 500),
    ("shot1", "phone_1_incident_feed.png", 1080, 1920),
    ("shot2", "phone_2_critical_alerts.png", 1080, 1920),
    ("shot3", "phone_3_contact_guest.png", 1080, 1920),
    ("shot4", "phone_4_service_recovery.png", 1080, 1920),
    ("shot5", "phone_5_analytics.png", 1080, 1920),
    ("shot6", "phone_6_biometric_lock.png", 1080, 1920),
]


def render(asset: str, out_name: str, w: int, h: int) -> None:
    url = (SRC / "index.html").as_uri() + "#" + asset
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.png"
        subprocess.run(
            [
                CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--allow-file-access-from-files", "--force-device-scale-factor=1",
                f"--window-size={w},{h}", "--virtual-time-budget=4000",
                f"--user-data-dir={tmp}", f"--screenshot={raw}", url,
            ],
            check=True, capture_output=True,
        )
        img = Image.open(raw).convert("RGB")
        if img.size != (w, h):
            sys.exit(f"{asset}: rendered {img.size}, expected {(w, h)}")
        img.save(OUT / out_name, "PNG", optimize=True)
    print(f"{out_name}  {w}x{h}  {(OUT / out_name).stat().st_size // 1024} KB")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    only = set(sys.argv[1:])
    for spec in ASSETS:
        if not only or spec[0] in only:
            render(*spec)
