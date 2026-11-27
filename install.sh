#!/usr/bin/env bash
# BaphOS: собирает графику и раскладывает конфиги симлинками на этот репозиторий.
#   ./install.sh            пользовательская часть (только ~/.config, ~/.local/share)
#   ./install.sh --system   плюс сессия BaphOS для SDDM (/usr/share/wayland-sessions, через sudo)
# Чужой файл на месте симлинка не удаляется: он переименовывается в <имя>.bak.<дата>.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
H="${HOME:?HOME не задан}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[1;31m[BaphOS]\033[0m %s\n' "$*"; }

# link <файл/папка в репо> <куда>
link() {
  local src="$REPO/$1" dst="$2"
  [[ -e "$src" ]] || { say "нет $src"; exit 1; }
  mkdir -p -- "$(dirname -- "$dst")"
  if [[ -L "$dst" ]]; then
    [[ "$(readlink -- "$dst")" == "$src" ]] && return 0
    rm -- "$dst"                      # чужой симлинк: убираем только сам симлинк
  elif [[ -e "$dst" ]]; then
    mv -- "$dst" "$dst.bak.$STAMP"
    say "бэкап: $dst.bak.$STAMP"
  fi
  ln -s -- "$src" "$dst"
  say "$dst -> $src"
}

say "рисую графику (Pillow, nearest-neighbor)"
cd "$REPO"
python3 art/buttons.py themes/labwc/BaphOS/openbox-3
python3 art/cursor.py assets/cursors/BaphOS

link labwc                         "$H/.config/labwc"
link themes/labwc/BaphOS           "$H/.local/share/themes/BaphOS"
link assets/cursors/BaphOS         "$H/.local/share/icons/BaphOS"

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface cursor-theme BaphOS || true
  gsettings set org.gnome.desktop.interface cursor-size 16 || true
fi

if [[ "${1:-}" == --system ]]; then
  say "сессия BaphOS для SDDM"
  sudo install -Dm644 -- "$REPO/session/baphos.desktop" /usr/share/wayland-sessions/baphos.desktop
fi

say "готово. Сессия «BaphOS» — в списке SDDM (после ./install.sh --system)"
