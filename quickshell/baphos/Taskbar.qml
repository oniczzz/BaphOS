// BaphOS: панель задач снизу в стиле Win98 (чёрно-красная).
//   [Пуск] [окно] [окно] ...                 |колодец: трей  RU  звук  батарея  21:45 / 27.11|
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar
    required property var modelData
    property bool startOpen: false
    signal startClicked()

    screen: modelData
    anchors { bottom: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.face
    WlrLayershell.namespace: "baphos-taskbar"

    // верхняя грань панели — выпуклая
    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Theme.bevelHi }
    Rectangle { x: 0; y: 1; width: parent.width; height: 1; color: Theme.bevelHiIn }

    RowLayout {
        anchors { fill: parent; topMargin: 4; bottomMargin: 2; leftMargin: 3; rightMargin: 3 }
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
                PixelText { text: "Пуск"; color: Theme.scarlet; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
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

        // ── колодец: трей, раскладка, звук, батарея, часы ──
        Bevel {
            sunken: true
            Layout.fillHeight: true
            Layout.preferredWidth: well.implicitWidth + 16
            RowLayout {
                id: well
                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                spacing: 8

                Repeater {
                    model: SystemTray.items
                    Item {
                        id: trayItem
                        required property var modelData
                        Layout.preferredWidth: 18; Layout.fillHeight: true
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

                // раскладка
                PixelText {
                    text: Niri.layoutShort || "--"
                    color: Theme.scarlet
                    font.bold: true
                    MouseArea { anchors.fill: parent; onClicked: Niri.nextLayout() }
                }

                // звук: значок по уровню, колесо — громкость, клик — выкл
                PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
                Item {
                    id: volRow
                    readonly property var a: Pipewire.defaultAudioSink?.audio ?? null
                    readonly property int pct: a ? Math.round(a.volume * 100) : 0
                    visible: a !== null
                    implicitWidth: volInner.implicitWidth
                    implicitHeight: volInner.implicitHeight
                    Row {
                        id: volInner
                        spacing: 2
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24; smooth: false
                            source: !volRow.a || volRow.a.muted ? Theme.icon("volume-x", "dim")
                                  : Theme.icon(volRow.pct > 66 ? "volume-3" : volRow.pct > 33 ? "volume-2" : "volume-1", "bone")
                        }
                        PixelText { anchors.verticalCenter: parent.verticalCenter; text: volRow.pct; color: volRow.a?.muted ? Theme.dim : Theme.text }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (volRow.a) volRow.a.muted = !volRow.a.muted
                        onWheel: w => { if (volRow.a) volRow.a.volume = Math.max(0, Math.min(1.5, volRow.a.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))) }
                    }
                }

                // батарея (только если есть)
                Row {
                    readonly property var dev: UPower.displayDevice
                    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
                    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
                    visible: dev && dev.isLaptopBattery
                    spacing: 2
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24; height: 24; smooth: false
                        source: Theme.icon(parent.charging ? "zap" : parent.pct > 66 ? "battery-full" : parent.pct > 25 ? "battery-medium" : "battery-low",
                                           parent.pct <= 15 && !parent.charging ? "scarlet" : "bone")
                    }
                    PixelText { anchors.verticalCenter: parent.verticalCenter; text: Math.round(parent.pct); color: parent.pct <= 15 ? Theme.scarlet : Theme.text }
                }

                // часы
                Column {
                    spacing: 3
                    Text {
                        id: clockTime
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.scarlet
                        font.family: Theme.fontNum; font.pixelSize: 16
                        renderType: Text.NativeRendering
                    }
                    Text {
                        id: clockDate
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.dim
                        font.family: Theme.fontNum; font.pixelSize: 8
                        renderType: Text.NativeRendering
                    }
                    Timer {
                        interval: 1000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: {
                            const d = new Date();
                            clockTime.text = Qt.formatDateTime(d, "HH:mm");
                            clockDate.text = Qt.formatDateTime(d, "dd.MM.yyyy");
                        }
                    }
                }
            }
        }
    }
}
