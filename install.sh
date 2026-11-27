#!/usr/bin/env bash
# BaphOS: собирает графику и подключает райс к niri.
#   ./install.sh
# Что делает (только в ~/.config и ~/.local/share):
#   ~/.config/niri/config.kdl      — короткий файл: include BaphOS + include "monitor.kdl" (твои мониторы)
#   ~/.config/quickshell/baphos    — симлинк на оболочку из репозитория
#   ~/.local/share/icons/BaphOS    — симлинк на курсор
# Чужой файл на месте не удаляется: он переименовывается в <имя>.bak.<дата>.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
H="${HOME:?HOME не задан}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[1;31m[BaphOS]\033[0m %s\n' "$*"; }

backup() { # backup <путь>: убирает с дороги, не удаляя
  local p="$1"
  if [[ -L "$p" ]]; then
    rm -- "$p"                      # симлинк: убираем только сам симлинк
  elif [[ -e "$p" ]]; then
    mv -- "$p" "$p.bak.$STAMP"
    say "бэкап: $p.bak.$STAMP"
  fi
}

link() { # link <в репо> <куда>
  local src="$REPO/$1" dst="$2"
  [[ -e "$src" ]] || { say "нет $src"; exit 1; }
  [[ -L "$dst" && "$(readlink -- "$dst")" == "$src" ]] && return 0
  mkdir -p -- "$(dirname -- "$dst")"
  backup "$dst"
  ln -s -- "$src" "$dst"
  say "$dst -> $src"
}

say "рисую графику (Pillow, nearest-neighbor)"
cd "$REPO"
python3 art/cursor.py assets/cursors/BaphOS
[[ -f art/sigil.py ]] && python3 art/sigil.py assets/sigil
[[ -f art/wallpapers.py ]] && python3 art/wallpapers.py assets/wallpapers

link assets/cursors/BaphOS   "$H/.local/share/icons/BaphOS"
link quickshell/baphos       "$H/.config/quickshell/baphos"

# niri: свой config.kdl с include BaphOS; мониторы остаются в monitor.kdl
NIRI="$H/.config/niri/config.kdl"
WANT="include \"$REPO/niri/baphos.kdl\""
if ! grep -qxF -- "$WANT" "$NIRI" 2>/dev/null; then
  mkdir -p -- "$H/.config/niri"
  backup "$NIRI"
  [[ -e "$H/.config/niri/monitor.kdl" ]] || printf '// Мониторы: этот файл пишет nwg-displays.\n' >"$H/.config/niri/monitor.kdl"
  cat >"$NIRI" <<EOF
// Конфиг niri. BaphOS подключён первым, мониторы — вторыми.
// Свои настройки (клавиши, правила окон) пиши НИЖЕ — они перекроют BaphOS.
$WANT
include "monitor.kdl"
EOF
  say "$NIRI: подключён BaphOS"
fi
niri validate -c "$NIRI" >/dev/null 2>&1 && say "niri validate: ok" || { say "niri validate: ОШИБКА"; niri validate -c "$NIRI"; exit 1; }

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface cursor-theme BaphOS || true
  gsettings set org.gnome.desktop.interface cursor-size 16 || true
fi

say "готово. niri перечитает конфиг сам; оболочка: qs -c baphos (стартует с niri)"
