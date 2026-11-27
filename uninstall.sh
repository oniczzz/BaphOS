#!/usr/bin/env bash
# BaphOS: отключает райс. Убирает только свои симлинки и свой config.kdl niri
# (его прежняя версия — самый свежий ~/.config/niri/config.kdl.bak.<дата> — возвращается на место).
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
H="${HOME:?HOME не задан}"

for dst in "$H/.config/quickshell/baphos" "$H/.local/share/icons/BaphOS"; do
  if [[ -L "$dst" && "$(readlink -- "$dst")" == "$REPO"/* ]]; then
    rm -- "$dst"
    echo "убран $dst"
  fi
done

NIRI="$H/.config/niri/config.kdl"
if grep -qF -- "include \"$REPO/niri/baphos.kdl\"" "$NIRI" 2>/dev/null; then
  last="$(ls -1t -- "$NIRI".bak.* 2>/dev/null | head -1 || true)"
  if [[ -n "$last" ]]; then
    mv -f -- "$last" "$NIRI"
    echo "niri: вернул $last"
  else
    echo "niri: бэкапа нет — $NIRI оставлен (убери из него строку include BaphOS)"
  fi
fi
