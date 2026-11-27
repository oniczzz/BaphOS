// BaphOS: виджеты на рабочем столе (слой Bottom — под окнами): «Гримуар» (часы, луна, полночь),
// «Око системы» (CPU, память, температура), «Литания» (музыка через MPRIS). На самом большом экране.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: w
    visible: Store.data.widgets
    screen: Quickshell.screens.reduce((a, b) => (b.width * b.height > a.width * a.height ? b : a), Quickshell.screens[0])
    anchors { top: true; right: true }
    margins { top: 16; right: 16 }
    implicitWidth: 280
    implicitHeight: col.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "baphos-widgets"

    property date now: new Date()
    Timer { interval: 1000; running: w.visible; repeat: true; triggeredOnStart: true; onTriggered: w.now = new Date() }

    // фаза луны: от известного новолуния 06.01.2000 18:14 UTC, синодический месяц 29.530588853 сут.
    readonly property real moonAge: {
        const days = (now.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
        return ((days % 29.530588853) + 29.530588853) % 29.530588853;
    }
    readonly property int moonLit: Math.round((1 - Math.cos(2 * Math.PI * moonAge / 29.530588853)) / 2 * 100)
    readonly property string moonName: ["новолуние", "растущий серп", "первая четверть", "растущая луна",
        "полнолуние", "убывающая луна", "последняя четверть", "убывающий серп"][Math.floor(((moonAge / 29.530588853) * 8 + 0.5)) % 8]

    readonly property string midnight: {
        if (now.getHours() === 3) return "Час бесов";
        const left = (24 * 60) - (now.getHours() * 60 + now.getMinutes());
        return "до полуночи " + Math.floor(left / 60) + ":" + String(left % 60).padStart(2, "0");
    }

    // плеер с треком: играющий, иначе первый (вкладки браузера без трека не считаются)
    readonly property var player: {
        const ps = Mpris.players.values;
        const named = ps.filter(p => p.trackTitle);
        return named.find(p => p.isPlaying) || named[0] || null;
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // ── Гримуар ──
        WinPanel {
            width: parent.width
            title: "Гримуар"
            icon: "moon"
            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: Qt.formatDateTime(w.now, "HH:mm")
                    color: Theme.scarlet
                    font.family: Theme.fontNum; font.pixelSize: 32
                    renderType: Text.NativeRendering
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                PixelText {
                    text: Qt.locale("ru_RU").toString(w.now, "dddd, d MMMM")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle { width: parent.width; height: 1; color: Theme.dried }
                PixelText { text: "Луна: " + w.moonName + ", " + w.moonLit + "%"; color: Theme.dim; width: parent.width }
                PixelText { text: w.midnight; color: w.now.getHours() === 3 ? Theme.scarlet : Theme.dim; width: parent.width }
            }
        }

        // ── Око системы ──
        WinPanel {
            width: parent.width
            title: "Око системы"
            icon: "eye"
            GridLayout {
                width: parent.width
                columns: 3
                columnSpacing: 8
                rowSpacing: 6
                PixelText { text: "CPU" }
                PixelBar { Layout.fillWidth: true; value: SysInfo.cpu }
                PixelText { text: Math.round(SysInfo.cpu * 100) + "%"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                PixelText { text: "ОЗУ" }
                PixelBar { Layout.fillWidth: true; value: SysInfo.mem }
                PixelText { text: SysInfo.memUsedGb.toFixed(1); Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                PixelText { text: "Жар" }
                PixelBar { Layout.fillWidth: true; value: SysInfo.temp / 100; fill: SysInfo.temp >= 85 ? Theme.scarlet : Theme.crimson }
                PixelText { text: SysInfo.temp + "°"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
            }
        }

        // ── Литания (музыка) ──
        WinPanel {
            id: music
            visible: w.player !== null
            width: parent.width
            title: "Литания"
            icon: "music"
            Column {
                width: parent.width
                spacing: 6
                PixelText { width: parent.width; text: w.player?.trackTitle || "без названия"; color: Theme.scarlet }
                PixelText { width: parent.width; text: w.player?.trackArtist || ""; color: Theme.dim; visible: text !== "" }
                PixelBar {
                    width: parent.width
                    implicitHeight: 10
                    value: w.player && w.player.length > 0 ? w.player.position / w.player.length : 0
                    fill: Theme.crimson
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    PixelButton {
                        width: 40; height: 32
                        onClicked: w.player?.previous()
                        Image { anchors.centerIn: parent; source: Theme.icon("forward", "bone"); width: 24; height: 24; smooth: false; mirror: true }
                    }
                    PixelButton {
                        width: 48; height: 32
                        onClicked: w.player?.togglePlaying()
                        Image { anchors.centerIn: parent; source: Theme.icon(w.player?.isPlaying ? "pause" : "play", "scarlet"); width: 24; height: 24; smooth: false }
                    }
                    PixelButton {
                        width: 40; height: 32
                        onClicked: w.player?.next()
                        Image { anchors.centerIn: parent; source: Theme.icon("forward", "bone"); width: 24; height: 24; smooth: false }
                    }
                }
            }
            // позицию MPRIS надо пинать вручную
            Timer { interval: 1000; running: music.visible && (w.player?.isPlaying ?? false); repeat: true; onTriggered: w.player.positionChanged() }
        }
    }
}
