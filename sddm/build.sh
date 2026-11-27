#!/usr/bin/env bash
# Собирает тему SDDM в build/sddm/BaphOS: QML + шрифты, сигил, рамки, иконки, обои из репозитория.
set -euo pipefail
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT="$REPO/build/sddm/BaphOS"
mkdir -p -- "$OUT/fonts"
cp -- "$REPO"/sddm/BaphOS/{Main.qml,metadata.desktop,theme.conf} "$OUT/"
cp -- "$REPO"/fonts/*.ttf "$OUT/fonts/"
cp -- "$REPO/assets/sigil/sigil-64.png" "$OUT/"
cp -- "$REPO"/assets/ui/frame-{panel,well,btn,btn-hover,btn-active}.png "$OUT/"
cp -- "$REPO"/assets/ui/{reload,power}-bone-24.png "$OUT/"
cp -- "$REPO/assets/wallpapers/crimson-moon-1920x1080.png" "$OUT/background.png"
echo "$OUT"
