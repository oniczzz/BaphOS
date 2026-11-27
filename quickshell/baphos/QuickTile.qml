// Плитка-переключатель «Алтаря»: иконка + подпись (+ строка состояния). Включена — алая рамка и шахматка.
import QtQuick

PixelButton {
    id: tile
    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool on: false

    active: on
    implicitHeight: 52

    Row {
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter; verticalCenterOffset: tile.down ? 1 : 0 }
        spacing: 8
        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 24; smooth: false
            source: tile.icon ? Theme.icon(tile.icon, tile.on ? "scarlet" : "dim") : ""
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            PixelText { text: tile.label; color: tile.on ? Theme.scarlet : Theme.text }
            PixelText { text: tile.sub; color: Theme.dim; visible: text !== ""; font.pixelSize: 12 }
        }
    }
}
