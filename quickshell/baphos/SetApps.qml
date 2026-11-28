// Настройки → Приложения по умолчанию: браузер (xdg-settings), файлы (xdg-mime), терминал.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: page
    spacing: 16
    property string browser: ""
    property string files: ""
    property string term: ""

    readonly property var all: DesktopEntries.applications.values
    readonly property var browsers: all.filter(e => (e.categories || []).includes("WebBrowser"))
    readonly property var fileManagers: all.filter(e => (e.categories || []).includes("FileManager"))
    readonly property var terminals: all.filter(e => (e.categories || []).includes("TerminalEmulator") && !e.noDisplay)

    function reload() { b.running = true; f.running = true; t.reload(); }
    Component.onCompleted: reload()
    Process { id: b; command: ["xdg-settings", "get", "default-web-browser"]; stdout: StdioCollector { onStreamFinished: page.browser = text.trim() } }
    Process { id: f; command: ["xdg-mime", "query", "default", "inode/directory"]; stdout: StdioCollector { onStreamFinished: page.files = text.trim() } }
    FileView { id: t; path: Quickshell.env("HOME") + "/.config/xdg-terminals.list"; onLoaded: page.term = text().trim().split("\n")[0] }
    Timer { id: again; interval: 500; onTriggered: page.reload() }

    SetTitle { text: "Приложения по умолчанию" }

    Choice {
        label: "Браузер"
        options: page.browsers.map(e => [e.id + ".desktop", e.name])
        current: page.browser
        onPicked: v => { Quickshell.execDetached(["xdg-settings", "set", "default-web-browser", v]); again.restart(); }
    }
    Choice {
        label: "Файлы"
        options: page.fileManagers.map(e => [e.id + ".desktop", e.name])
        current: page.files
        onPicked: v => { Quickshell.execDetached(["xdg-mime", "default", v, "inode/directory"]); again.restart(); }
    }
    Choice {
        label: "Терминал"
        options: page.terminals.map(e => [e.id + ".desktop", e.name])
        current: page.term
        onPicked: v => { t.setText(v + "\n"); again.restart(); }
    }
    PixelText { width: page.width; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Theme.dim
        text: "Терминал по Win+T задаётся в niri (сейчас kitty); выбор здесь — для «Открыть в терминале» в Файлах." }
}
