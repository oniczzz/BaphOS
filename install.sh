#!/usr/bin/env bash
# BaphOS: собирает графику и подключает райс к niri.
#   ./install.sh
# Что делает (только в ~/.config и ~/.local/share):
#   ~/.config/niri/config.kdl      — короткий файл: include BaphOS + include "monitor.kdl" (твои мониторы)
#   ~/.config/quickshell/baphos    — симлинк на оболочку из репозитория
#   ~/.local/share/icons/BaphOS    — симлинк на тему значков и курсор
#   foot, fastfetch, fish (prompt и цвета) — симлинки на файлы репозитория
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
python3 art/cursor.py assets/icons/BaphOS
python3 art/icons.py assets/icons/BaphOS          # после курсора: пишет общий index.theme
[[ -f art/sigil.py ]] && python3 art/sigil.py assets/sigil
[[ -f art/wallpapers.py ]] && python3 art/wallpapers.py assets/wallpapers
python3 art/fastfetch_logo.py fastfetch/logo.txt

link assets/icons/BaphOS     "$H/.local/share/icons/BaphOS"
mkdir -p -- "$H/.local/state/baphos"          # настройки оболочки (обои, сюжет)
link quickshell/baphos       "$H/.config/quickshell/baphos"
link foot/foot.ini            "$H/.config/foot/foot.ini"
link fastfetch               "$H/.config/fastfetch"
link fish/functions/fish_prompt.fish "$H/.config/fish/functions/fish_prompt.fish"
link fish/conf.d/baphos.fish "$H/.config/fish/conf.d/baphos.fish"
link gtk/gtk.css              "$H/.config/gtk-3.0/gtk.css"
link gtk/gtk.css              "$H/.config/gtk-4.0/gtk.css"
link qt/BaphOS.conf           "$H/.config/qt6ct/colors/BaphOS.conf"

# qt6ct: стиль Fusion + палитра BaphOS (файл с абсолютным путём — пишется здесь, не симлинк)
QT="$H/.config/qt6ct/qt6ct.conf"
if ! grep -qF "colors/BaphOS.conf" "$QT" 2>/dev/null; then
  backup "$QT"
  cat >"$QT" <<QTCONF
[Appearance]
color_scheme_path=$H/.config/qt6ct/colors/BaphOS.conf
custom_palette=true
icon_theme=BaphOS
standard_dialogs=default
style=Fusion

[Fonts]
fixed="Cozette,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="Cozette,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

[Interface]
activate_item_on_single_click=1
menus_have_icons=true
show_shortcuts_in_context_menus=true
QTCONF
  say "$QT: палитра BaphOS"
fi

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
  gsettings set org.gnome.desktop.interface icon-theme BaphOS || true
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || true
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
  gsettings set org.gnome.desktop.interface accent-color red 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-name 'Cozette 10' || true
  gsettings set org.gnome.desktop.interface document-font-name 'Cozette 10' || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'Cozette 10' || true
fi

say "готово. niri перечитает конфиг сам; оболочка: qs -c baphos (стартует с niri)"
