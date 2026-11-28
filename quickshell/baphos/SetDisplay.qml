// Настройки → Экран: разрешение, частота, масштаб каждого монитора (сразу, через niri);
// «Сохранить» пишет ~/.config/niri/monitor.kdl, «Расположение» — перетаскивание (nwg-displays).
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: page
    spacing: 14
    property var outputs: ({})
    property string status: ""

    function reload() { read.running = true; }
    Component.onCompleted: reload()
    Process {
        id: read
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector { onStreamFinished: { try { page.outputs = JSON.parse(text); } catch (e) {} } }
    }
    function apply(name, args) {
        Quickshell.execDetached(["niri", "msg", "output", name].concat(args));
        refresh.restart();
    }
    Timer { id: refresh; interval: 600; onTriggered: page.reload() }

    // monitor.kdl из текущего состояния всех мониторов
    Process {
        id: save
        command: [Quickshell.env("HOME") + "/.local/bin/baphos-save-monitors"]
        onExited: code => page.status = code === 0 ? "Сохранено в ~/.config/niri/monitor.kdl" : "Не удалось сохранить"
    }

    SetTitle { text: "Экран"; hint: "Изменения применяются сразу. «Сохранить» — чтобы остались после перезагрузки." }

    Row {
        spacing: 8
        PixelButton {
            width: 220; height: 36
            onClicked: Quickshell.execDetached(["nwg-displays"])
            Row { anchors.centerIn: parent; spacing: 6
                Image { source: Theme.icon("monitor", "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                PixelText { text: "Расположение"; anchors.verticalCenter: parent.verticalCenter } }
        }
        PixelButton {
            width: 180; height: 36
            onClicked: save.running = true
            Row { anchors.centerIn: parent; spacing: 6
                Image { source: Theme.icon("save", "scarlet"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                PixelText { text: "Сохранить"; color: Theme.scarlet; anchors.verticalCenter: parent.verticalCenter } }
        }
    }
    PixelText { text: page.status; visible: text !== ""; color: Theme.dim }

    Repeater {
        model: Object.keys(page.outputs)
        Bevel {
            id: card
            required property string modelData
            readonly property var o: page.outputs[modelData]
            readonly property var cur: o && o.current_mode !== null ? o.modes[o.current_mode] : null
            readonly property var sizes: o ? [...new Set(o.modes.map(m => m.width + "x" + m.height))] : []
            readonly property string size: cur ? cur.width + "x" + cur.height : ""
            readonly property var rates: o ? o.modes.filter(m => m.width + "x" + m.height === size)
                                                  .map(m => (m.refresh_rate / 1000).toFixed(3)) : []
            kind: "panel"
            width: page.width
            height: inner.implicitHeight + 2 * inset + 8
            Column {
                id: inner
                width: parent.width
                spacing: 10
                PixelText { text: card.modelData + "  ·  " + (card.o ? card.o.make + " " + card.o.model : ""); color: Theme.scarlet }
                Choice {
                    label: "Разрешение"
                    options: card.sizes.slice(0, 8).map(s => [s, s.replace("x", "×")])
                    current: card.size
                    onPicked: v => page.apply(card.modelData, ["mode", v])
                }
                Choice {
                    label: "Частота"
                    options: [...new Set(card.rates)].map(r => [r, Math.round(Number(r)) + " Гц"])
                    current: card.cur ? (card.cur.refresh_rate / 1000).toFixed(3) : ""
                    onPicked: v => page.apply(card.modelData, ["mode", card.size + "@" + v])
                }
                Choice {
                    label: "Масштаб"
                    options: [["1", "100%"], ["1.25", "125%"], ["1.5", "150%"], ["2", "200%"]]
                    current: card.o ? String(card.o.logical.scale) : ""
                    onPicked: v => page.apply(card.modelData, ["scale", v])
                }
            }
        }
    }
}
