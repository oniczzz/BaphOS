// BaphOS: табличка комнаты при смене рабочего стола (своего дизайна, в духе табличек испытательных камер):
//   крупный номер, «из N», полоска пройденных комнат и пиктограммы окон этой комнаты.
//   Выезжает слева ступенями, держится секунду с небольшим и уезжает. В игре и спокойном режиме — нет.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: sign
    required property var modelData
    screen: modelData
    property int idx: 1
    property real k: 0

    visible: k > 0
    anchors { top: true; left: true }
    margins { top: 24; left: 0 }
    implicitWidth: 260
    implicitHeight: 330
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-room-sign"

    readonly property var rooms: Niri.workspaces.filter(w => w.output === modelData.name).sort((a, b) => a.idx - b.idx)
    readonly property var here: rooms.find(w => w.idx === idx) || null
    readonly property var wins: here ? Niri.windows.filter(w => w.workspace_id === here.id) : []

    Connections {
        target: Niri
        function onWorkspaceSwitched(output, idx) {
            if (output !== sign.modelData.name || Mode.quiet || !Store.data.roomSigns) return;
            sign.idx = idx;
            anim.restart();
        }
    }
    SequentialAnimation {
        id: anim
        NumberAnimation { target: sign; property: "k"; to: 1; duration: Store.data.animations ? 180 : 0; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 1300 }
        NumberAnimation { target: sign; property: "k"; to: 0; duration: Store.data.animations ? 200 : 0; easing.type: Easing.InCubic }
    }

    Rectangle {
        id: plate
        width: 236; height: signCol.implicitHeight + 34
        // ступенчатый выезд по 12 px
        x: Math.round((sign.k - 1) * 260 / 12) * 12 + 18
        color: Theme.coal
        border.width: 3; border.color: Theme.text
        Rectangle { anchors { fill: parent; margins: 6 } color: "transparent"; border.width: 2; border.color: Theme.blood }

        Column {
            id: signCol
            x: 20; y: 16
            width: parent.width - 40
            spacing: 6
            Row {
                spacing: 6
                Text {
                    text: (sign.idx < 10 ? "0" : "") + sign.idx
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 64; font.bold: true
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                    text: "/" + (sign.rooms.length < 10 ? "0" : "") + sign.rooms.length
                    color: Theme.dim
                    font.family: Theme.font; font.pixelSize: 24
                    renderType: Text.NativeRendering
                }
            }
            // пройденные комнаты
            Row {
                spacing: 4
                Repeater {
                    model: sign.rooms.length
                    Rectangle {
                        required property int index
                        width: Math.min(18, (196 - 4 * sign.rooms.length) / Math.max(1, sign.rooms.length)); height: 10
                        color: index + 1 < sign.idx ? Theme.crimson : index + 1 === sign.idx ? Theme.scarlet : "transparent"
                        border.width: 2; border.color: index + 1 === sign.idx ? Theme.scarlet : Theme.dried
                    }
                }
            }
            Rectangle { width: parent.width; height: 2; color: Theme.dried }
            Text {
                text: "КОМНАТА · " + sign.modelData.name
                color: Theme.scarlet
                font.family: Theme.font; font.pixelSize: 12
                renderType: Text.NativeRendering
            }
            // пиктограммы: окна этой комнаты, пусто — «?»
            Grid {
                columns: 4; spacing: 8
                Repeater {
                    model: sign.wins.slice(0, 8)
                    Rectangle {
                        id: pic
                        required property var modelData
                        readonly property var entry: DesktopEntries.heuristicLookup(modelData.app_id)
                        width: 40; height: 40
                        color: Theme.bg
                        border.width: 2; border.color: Theme.dim
                        IconImage { anchors.centerIn: parent; implicitSize: 28; source: Quickshell.iconPath(pic.entry?.icon ?? pic.modelData.app_id, "application-x-executable") }
                    }
                }
                Rectangle {
                    visible: sign.wins.length === 0
                    width: 40; height: 40
                    color: Theme.bg
                    border.width: 2; border.color: Theme.dried
                    Text { anchors.centerIn: parent; text: "?"; color: Theme.dried; font.family: Theme.font; font.pixelSize: 24; renderType: Text.NativeRendering }
                }
            }
        }
    }
}
