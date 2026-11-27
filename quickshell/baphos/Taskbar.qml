// BaphOS: панель задач снизу, как в Windows.
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
    color: Theme.bg
    WlrLayershell.namespace: "baphos-taskbar"

    // верхняя граница панели
    Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right } height: Theme.border; color: Theme.blood }

    RowLayout {
        anchors { fill: parent; topMargin: Theme.border + 2; bottomMargin: 2; leftMargin: 4; rightMargin: 6 }
        spacing: 4

        // ── Пуск ──
        PixelButton {
            Layout.fillHeight: true
            Layout.preferredWidth: startRow.implicitWidth + 14
            active: bar.startOpen
            onClicked: bar.startClicked()
            Row {
                id: startRow
                anchors.centerIn: parent
                spacing: 6
                Image {
                    source: Theme.asset("sigil/sigil-32.png")
                    width: 22; height: 22
                    smooth: false
                    anchors.verticalCenter: parent.verticalCenter
                }
                PixelText { text: "Пуск"; color: Theme.scarlet; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // ── открытые окна ──
        Row {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3
            clip: true
            Repeater {
                model: ToplevelManager.toplevels
                PixelButton {
                    id: win
                    required property var modelData
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
                    height: parent.height
                    width: Math.min(190, Math.max(110, (parent.width - 3 * ToplevelManager.toplevels.values.length) / Math.max(1, ToplevelManager.toplevels.values.length)))
                    active: modelData.activated
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) modelData.close();
                        else modelData.activate();
                    }
                    Row {
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
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
                        }
                    }
                }
            }
        }

        // ── трей ──
        Row {
            Layout.fillHeight: true
            spacing: 4
            Repeater {
                model: SystemTray.items
                Item {
                    id: trayItem
                    required property var modelData
                    width: 20; height: parent.height
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                    }
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
                            } else if (mouse.button === Qt.MiddleButton) {
                                trayItem.modelData.secondaryActivate();
                            } else {
                                trayItem.modelData.activate();
                            }
                        }
                    }
                }
            }
        }

        // ── раскладка ──
        PixelButton {
            Layout.fillHeight: true
            Layout.preferredWidth: 34
            onClicked: Niri.nextLayout()
            PixelText { anchors.centerIn: parent; text: Niri.layoutShort || "--"; color: Theme.scarlet }
        }

        // ── звук: колесо — громкость, клик — выкл/вкл ──
        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
        PixelButton {
            readonly property var sink: Pipewire.defaultAudioSink
            visible: sink !== null
            Layout.fillHeight: true
            Layout.preferredWidth: vol.implicitWidth + 14
            onClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
            onWheel: w => {
                if (!sink?.audio) return;
                sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05)));
            }
            PixelText {
                id: vol
                anchors.centerIn: parent
                text: !parent.sink?.audio ? "звук"
                    : parent.sink.audio.muted ? "звук выкл"
                    : "звук " + Math.round(parent.sink.audio.volume * 100) + "%"
                color: parent.sink?.audio?.muted ? Theme.dim : Theme.text
            }
        }

        // ── батарея (только если есть) ──
        PixelText {
            readonly property var dev: UPower.displayDevice
            readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
            visible: dev && dev.isLaptopBattery
            Layout.fillHeight: true
            text: (dev && dev.state === UPowerDeviceState.Charging ? "заряд+ " : "заряд ") + Math.round(pct) + "%"
            color: pct <= 15 ? Theme.scarlet : Theme.text
        }

        // ── часы ──
        Column {
            Layout.fillHeight: true
            Layout.preferredWidth: 72
            PixelText { id: clockTime; width: parent.width; height: parent.height / 2; horizontalAlignment: Text.AlignHCenter; color: Theme.scarlet }
            PixelText { id: clockDate; width: parent.width; height: parent.height / 2; horizontalAlignment: Text.AlignHCenter; color: Theme.dim }
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
