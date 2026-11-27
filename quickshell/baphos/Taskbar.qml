// BaphOS: панель задач снизу в стиле Win98 (чёрно-красная).
//   [Пуск] [окно] [окно] ...      [трей] [♫ плеер] [CPU/RAM] [RU звук батарея] [свеча 21:45]
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

PanelWindow {
    id: bar
    required property var modelData
    property bool startOpen: false
    property bool altarOpen: false
    signal startClicked()
    signal altarClicked()

    screen: modelData
    anchors { bottom: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "#0c0606"
    WlrLayershell.namespace: "baphos-taskbar"

    // фон панели — узорная рамка, видна только её верхняя кромка (алая жилка с «цепью»)
    BorderImage {
        x: -16; y: -2
        width: parent.width + 32; height: parent.height + 20
        source: Theme.asset("ui/frame-panel.png")
        border { left: 16; right: 16; top: 16; bottom: 16 }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
        smooth: false
    }

    RowLayout {
        anchors { fill: parent; topMargin: 9; bottomMargin: 2; leftMargin: 3; rightMargin: 3 }
        spacing: 4

        // ── Пуск ──
        PixelButton {
            Layout.fillHeight: true
            Layout.preferredWidth: startRow.implicitWidth + 16
            active: bar.startOpen
            onClicked: bar.startClicked()
            Row {
                id: startRow
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.parent.sunken ? 1 : 0
                spacing: 6
                Image {
                    source: Theme.asset("sigil/sigil-32.png")
                    width: 32; height: 32; smooth: false
                    anchors.verticalCenter: parent.verticalCenter
                }
                PixelText { text: Story.label("start", "Пуск"); color: Theme.scarlet; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.bevelLo }
        Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.bevelHiIn }

        // ── открытые окна ──
        Row {
            id: tasks
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3
            clip: true
            readonly property int n: ToplevelManager.toplevels.values.length
            Repeater {
                model: ToplevelManager.toplevels
                PixelButton {
                    id: win
                    required property var modelData
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
                    height: tasks.height
                    width: Math.min(200, Math.max(120, (tasks.width - 3 * tasks.n) / Math.max(1, tasks.n)))
                    active: modelData.activated
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) modelData.close();
                        else modelData.activate();
                    }
                    Row {
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: win.sunken ? 1 : 0 }
                        spacing: 6
                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
                            source: Quickshell.iconPath(win.entry?.icon ?? win.modelData.appId, "application-x-executable")
                        }
                        PixelText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 22
                            text: win.modelData.title || win.modelData.appId
                            color: win.active ? Theme.scarlet : Theme.text
                            font.bold: win.active
                        }
                    }
                }
            }
        }

        // ── трей ──
        Bevel {
            kind: "well"
            visible: SystemTray.items.values.length > 0
            Layout.fillHeight: true
            Layout.preferredWidth: trayRow.implicitWidth + 16
            Row {
                id: trayRow
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: SystemTray.items
                    Item {
                        id: trayItem
                        required property var modelData
                        width: 18; height: 24
                        IconImage { anchors.centerIn: parent; implicitSize: 16; source: trayItem.modelData.icon }
                        QsMenuAnchor {
                            id: menu
                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.edges: Edges.Top
                            anchor.gravity: Edges.Top
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                    if (trayItem.modelData.hasMenu) menu.open();
                                } else if (mouse.button === Qt.MiddleButton) trayItem.modelData.secondaryActivate();
                                else trayItem.modelData.activate();
                            }
                        }
                    }
                }
            }
        }

        // ── мини-плеер: эквалайзер + бегущая строка (клик — пауза, правый клик — Алтарь) ──
        PixelButton {
            id: media
            readonly property var player: {
                const ps = Mpris.players.values.filter(p => p.trackTitle);
                return ps.find(p => p.isPlaying) || ps[0] || null;
            }
            readonly property bool playing: player?.isPlaying ?? false
            readonly property string line: player ? (player.trackArtist ? player.trackArtist + " — " : "") + player.trackTitle : ""
            property int tick: 0
            visible: player !== null
            Layout.fillHeight: true
            Layout.preferredWidth: 210
            onClicked: m => { if (m.button === Qt.RightButton) bar.altarClicked(); else player?.togglePlaying(); }
            Timer { interval: 125; repeat: true; running: media.visible && media.playing && Store.data.animations; onTriggered: media.tick++ }
            Row {
                id: eq
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 3
                        height: media.playing ? 4 + ((media.tick * (index + 3) * 7 + index * 5) % 5) * 4 : 4
                        anchors.bottom: parent.bottom
                        color: index % 2 ? Theme.crimson : Theme.scarlet
                    }
                }
                height: 22
            }
            Item {
                id: marquee
                anchors { left: eq.right; leftMargin: 8; right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                clip: true
                readonly property int gap: 40
                readonly property int shift: t1.implicitWidth > width ? (media.tick * 2) % (t1.implicitWidth + gap) : 0
                PixelText { id: t1; x: -marquee.shift; anchors.verticalCenter: parent.verticalCenter; text: media.line; color: media.playing ? Theme.text : Theme.dim; elide: Text.ElideNone }
                PixelText { x: t1.implicitWidth + marquee.gap - marquee.shift; visible: t1.implicitWidth > marquee.width; anchors.verticalCenter: parent.verticalCenter; text: media.line; color: t1.color; elide: Text.ElideNone }
            }
        }

        // ── «Око»: мини-шкалы CPU и RAM ──
        Bevel {
            kind: "well"
            Layout.fillHeight: true
            Layout.preferredWidth: 34
            Row {
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: [SysInfo.cpu, SysInfo.mem]
                    Column {
                        required property real modelData
                        spacing: 1
                        Repeater {
                            model: 6
                            Rectangle {
                                required property int index
                                width: 8; height: 3
                                readonly property bool lit: (5 - index) < Math.round(parent.modelData * 6)
                                color: !lit ? Theme.dried : (index < 2 ? Theme.scarlet : Theme.crimson)
                            }
                        }
                    }
                }
            }
            MouseArea { anchors.fill: parent; onClicked: bar.altarClicked() }
        }

        // ── статус: раскладка, звук, батарея (клик — Алтарь, колесо — громкость) ──
        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
        PixelButton {
            id: status
            readonly property var a: Pipewire.defaultAudioSink?.audio ?? null
            readonly property int vol: a ? Math.round(a.volume * 100) : 0
            readonly property var dev: UPower.displayDevice
            readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
            readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
            active: bar.altarOpen
            Layout.fillHeight: true
            Layout.preferredWidth: statusRow.implicitWidth + 16
            onClicked: m => { if (m.button === Qt.MiddleButton) Niri.nextLayout(); else bar.altarClicked(); }
            onWheel: w => { if (a) a.volume = Math.max(0, Math.min(1.5, a.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))) }
            Row {
                id: statusRow
                anchors.centerIn: parent
                anchors.verticalCenterOffset: status.down ? 1 : 0
                spacing: 6
                PixelText { text: Niri.layoutShort || "--"; color: Theme.scarlet; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24; height: 24; smooth: false
                    source: !status.a || status.a.muted ? Theme.icon("volume-x", "dim")
                          : Theme.icon(status.vol > 66 ? "volume-3" : status.vol > 33 ? "volume-2" : "volume-1", "bone")
                }
                PixelText { text: status.vol; anchors.verticalCenter: parent.verticalCenter; color: status.a?.muted ? Theme.dim : Theme.text }
                Image {
                    visible: status.dev && status.dev.isLaptopBattery
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24; height: 24; smooth: false
                    source: Theme.icon(status.charging ? "zap" : status.pct > 66 ? "battery-full" : status.pct > 25 ? "battery-medium" : "battery-low",
                                       status.pct <= 15 && !status.charging ? "scarlet" : "bone")
                }
                PixelText { visible: status.dev && status.dev.isLaptopBattery; text: Math.round(status.pct); anchors.verticalCenter: parent.verticalCenter; color: status.pct <= 15 ? Theme.scarlet : Theme.text }
            }
        }

        // ── часы со свечой (клик — Алтарь) ──
        PixelButton {
            id: clockBtn
            property int tick: 0
            active: bar.altarOpen
            Layout.fillHeight: true
            Layout.preferredWidth: clockRow.implicitWidth + 16
            onClicked: bar.altarClicked()
            Timer {
                interval: 125; repeat: true; triggeredOnStart: true
                running: true
                onTriggered: {
                    if (Store.data.animations) clockBtn.tick++;
                    const d = new Date();
                    clockTime.text = Qt.formatDateTime(d, "HH:mm");
                    clockDate.text = Qt.formatDateTime(d, "dd.MM.yyyy");
                }
            }
            Row {
                id: clockRow
                anchors.centerIn: parent
                anchors.verticalCenterOffset: clockBtn.down ? 1 : 0
                spacing: 6
                Item {
                    width: 12; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    Image { source: Theme.asset("wallpapers/anim/flame-" + (clockBtn.tick % 4) + ".png"); smooth: false; y: 0 }
                    Rectangle { x: 4; y: 12; width: 4; height: 2; color: Theme.dim }
                    Rectangle { x: 2; y: 14; width: 8; height: 16; color: Theme.text }
                    Rectangle { x: 2; y: 14; width: 2; height: 16; color: Theme.dim }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text { id: clockTime; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.scarlet; font.family: Theme.fontNum; font.pixelSize: 16; font.bold: true; renderType: Text.NativeRendering }
                    Text { id: clockDate; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.dim; font.family: Theme.fontNum; font.pixelSize: 12; renderType: Text.NativeRendering }
                }
            }
        }
    }
}
