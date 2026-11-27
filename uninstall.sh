#!/usr/bin/env bash
# BaphOS: убирает симлинки на этот репозиторий (только свои) и сессию из SDDM.
# Бэкапы <имя>.bak.<дата> остаются на месте — верни нужный руками.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
H="${HOME:?HOME не задан}"

for dst in "$H/.config/labwc" "$H/.local/share/themes/BaphOS" "$H/.local/share/icons/BaphOS"; do
  if [[ -L "$dst" && "$(readlink -- "$dst")" == "$REPO"/* ]]; then
    rm -- "$dst"
    echo "убран $dst"
  fi
done

if [[ "${1:-}" == --system && -f /usr/share/wayland-sessions/baphos.desktop ]]; then
  sudo rm -f -- /usr/share/wayland-sessions/baphos.desktop
  echo "убрана сессия BaphOS"
fi
