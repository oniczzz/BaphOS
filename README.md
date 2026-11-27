# BaphOS

Пиксельный сатанинский райс для **niri** с оболочкой на **Quickshell**, для слабого железа
(без blur и шейдеров). Палитра — чёрный, алый, тёмно-красный. Вся графика рисуется кодом
(`art/*.py`, Pillow, nearest-neighbor).

> В разработке: этапы — база niri → панель задач и Пуск → обои и сигил → темы → сюжет.

![Пуск](assets/previews/start-menu.png)

## Панель задач и Пуск

- **Пуск** (кнопка с сигилом или `Mod+D`): поиск по приложениям, стрелки + Enter, Esc — закрыть;
  выход / перезагрузка / выключение — по второму клику («Точно?»).
- **Окна**: клик — перейти к окну, средний клик — закрыть. Свернуть окно в niri нельзя — такой функции у него нет.
- **Справа**: трей, раскладка (клик — переключить), звук (колесо — громкость, клик — выкл), заряд батареи, часы.

## Установка

```sh
git clone https://github.com/oniczzz/BaphOS.git ~/projects/BaphOS
cd ~/projects/BaphOS
./install.sh
```

Пакеты: `niri quickshell python-pillow xorg-xcursorgen`, шрифт `cozette-otb` (AUR).

`install.sh` трогает только `~/.config` и `~/.local/share`:
- `~/.config/niri/config.kdl` становится коротким файлом: `include` BaphOS и `include "monitor.kdl"`.
  Свои настройки пиши в нём **ниже** — они перекроют BaphOS. Старый файл уходит в `config.kdl.bak.<дата>`.
- `~/.config/quickshell/baphos` и курсор `~/.local/share/icons/BaphOS` — симлинки на репозиторий.

`./uninstall.sh` убирает симлинки и возвращает прежний `config.kdl` из последнего бэкапа.

## Состав

```
art/          генераторы графики: pixel.py (палитра), cursor.py, sigil.py
niri/         baphos.kdl — оформление, анимации, клавиши
quickshell/   оболочка BaphOS: shell.qml, Taskbar, StartMenu, Theme (палитра), Niri (события niri)
assets/       курсор BaphOS (16 px), сигил, превью
```

## Лицензия

MIT. Шрифт Cozette — отдельный пакет (MIT), в репозиторий не входит.
