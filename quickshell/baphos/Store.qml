// BaphOS: настройки и состояние в ~/.local/state/baphos/settings.json.
// Это единственный файл, который оболочка пишет на диск.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.local/state/baphos"
    readonly property alias data: adapter

    readonly property var wallpapers: ["crimson-moon", "ritual", "forest", "cathedral", "sigil"]

    function resetStory() {
        adapter.storyStage = 0;
        adapter.storySeen = [];
        adapter.storyMinutes = 0;
        adapter.stageMinutes = 0;
        adapter.launches = 0;
        adapter.startOpens = 0;
    }

    function nextWallpaper() {
        const i = wallpapers.indexOf(adapter.wallpaper);
        adapter.wallpaper = wallpapers[(i + 1) % wallpapers.length];
    }

    FileView {
        id: file
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // файла ещё нет — создать со значениями по умолчанию
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property string wallpaper: "crimson-moon"
            property bool animations: true      // живые обои и мозаика
            property bool widgets: true         // Гримуар, Око системы, Литания
            property bool dnd: false            // «Не беспокоить»: уведомления только в истории
            property bool nightLight: false     // ночной свет (wlsunset)
            property bool sounds: true          // звуки BaphOS (assets/sounds)
            property bool gameMode: false       // игровой режим: без глитчей, звуков, всплывашек
            // клавиатура и мышь (пишутся в ~/.config/niri/input.kdl — InputConf)
            property string kbLayouts: "us,ru"
            property string kbToggle: "grp:alt_shift_toggle"
            property bool tpTap: true
            property bool tpNatural: true
            property real tpSpeed: 0.0
            property real mouseSpeed: 0.0
            property bool mouseFlat: false
            property int lockMinutes: 10        // автоблокировка; 0 — никогда
            property bool banners: true         // баннеры на весь экран (замок, выход)
            property bool effects: true         // false = «Спокойный режим»: без сюжета, глитчей, углей, живых обоев и эффектов окон
            property bool autoGameMode: true    // включать его самому, когда окно во весь экран
            property var favorites: ["kitty", "org.gnome.Nautilus", "helium", "steam", "discord", "org.telegram.desktop"]  // избранное в Пуске
            property bool story: true           // сюжет (вирус культа) — только визуальный
            property int storyStage: 0          // этап заражения
            property var storySeen: []          // какие события сюжета уже были
            property int storyMinutes: 0        // минуты сюжета всего
            property int stageMinutes: 0        // минуты на текущем этапе
            property int launches: 0            // запуски программ из Пуска
            property int startOpens: 0          // сколько раз открыт Пуск
        }
    }
}
