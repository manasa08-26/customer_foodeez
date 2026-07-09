#!/bin/zsh
# Capture current emulator screen.
# Usage from project root:
#   ./store_assets/screenshots/capture.sh home
#   ./store_assets/screenshots/capture.sh menu
#   ./store_assets/screenshots/capture.sh restaurant
#   ./store_assets/screenshots/capture.sh cart
#   ./store_assets/screenshots/capture.sh orders
#   ./store_assets/screenshots/capture.sh profile
#   ./store_assets/screenshots/capture.sh login
set -e

NAME="${1:?Usage: ./capture.sh <name>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/raw"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/${NAME}.png"

adb exec-out screencap -p > "$OUT"

python3 - <<PY
from PIL import Image
p = "$OUT"
img = Image.open(p)
print(f"Saved {p}  size={img.size}")
PY
