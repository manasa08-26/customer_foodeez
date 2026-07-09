#!/usr/bin/env python3
"""Resize raw screenshots for Google Play phone listing."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OUT = ROOT / "play_store"

# Google Play phone screenshots: between 320px and 3840px on each side.
# Common high-quality size for phones:
TARGET_W = 1080
TARGET_H = 1920

ORDERED_NAMES = [
    "01_home",
    "02_restaurant_list_menu",
    "03_restaurant_details",
    "04_cart",
    "05_orders",
    "06_profile",
    "07_login",
]


def fit_center(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    src = img.convert("RGB")
    scale = max(target_w / src.width, target_h / src.height)
    resized = src.resize(
        (int(src.width * scale), int(src.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    RAW.mkdir(parents=True, exist_ok=True)

    mapping = {
        "home.png": "01_home.png",
        "menu.png": "02_restaurant_list_menu.png",
        "restaurant.png": "03_restaurant_details.png",
        "restaurant_details.png": "03_restaurant_details.png",
        "cart.png": "04_cart.png",
        "orders.png": "05_orders.png",
        "profile.png": "06_profile.png",
        "login.png": "07_login.png",
    }

    found = []
    for raw_name, out_name in mapping.items():
        src = RAW / raw_name
        if not src.exists():
            continue
        img = Image.open(src)
        out_img = fit_center(img, TARGET_W, TARGET_H)
        dest = OUT / out_name
        out_img.save(dest, "PNG", optimize=True)
        found.append(f"{src.name} -> {dest.name} ({out_img.size})")

    if not found:
        print("No raw screenshots found in:")
        print(f"  {RAW}")
        print("Capture with: ./store_assets/screenshots/capture.sh <name>")
        return

    print("Prepared Play Store screenshots:")
    for line in found:
        print(f"  {line}")
    print(f"\nOutput folder: {OUT}")


if __name__ == "__main__":
    main()
