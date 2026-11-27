// Пиксельный флажок-«печать»: вдавленный квадрат, включён — алый крест внутри. Подпись справа.
import QtQuick

Item {
    id: sw
    property bool checked: false
    property string text: ""
    property string hint: ""
    signal toggled(bool value)

    implicitWidth: 360
    implicitHeight: hint ? 44 : 26

    Bevel {
        id: box
        kind: area.containsMouse ? "btn-hover" : "well"
        width: 26; height: 26
        Item {
            anchors.fill: parent
            visible: sw.checked
            // крест 2 px из пикселей
            Repeater {
                model: 7
                Item {
                    required property int index
                    Rectangle { x: index * 2 + 2; y: index * 2 + 2; width: 2; height: 2; color: Theme.scarlet }
                    Rectangle { x: 14 - index * 2; y: index * 2 + 2; width: 2; height: 2; color: Theme.scarlet }
                }
            }
        }
    }
    Column {
        anchors { left: box.right; leftMargin: 10; top: parent.top; topMargin: 1 }
        spacing: 2
        PixelText { text: sw.text; color: sw.checked ? Theme.scarlet : Theme.text }
        PixelText { text: sw.hint; color: Theme.dim; visible: text !== "" }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: sw.toggled(!sw.checked)
    }
}
