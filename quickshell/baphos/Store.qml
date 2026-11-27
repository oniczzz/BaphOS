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
        }
    }
}
