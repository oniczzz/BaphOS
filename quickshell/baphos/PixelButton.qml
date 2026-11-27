// Пиксельная кнопка: чёрная плашка с рамкой; наведение — тёмно-красная, нажатие/активна — алая рамка.
import QtQuick

Rectangle {
    id: btn
    property bool active: false
    property alias hovered: area.containsMouse
    signal clicked(var mouse)
    signal wheel(var wheel)

    color: area.pressed ? Theme.dried : (area.containsMouse || active ? Theme.coal : Theme.bg)
    border.width: Theme.border
    border.color: active || area.pressed ? Theme.scarlet : (area.containsMouse ? Theme.blood : Theme.dried)
    radius: 0

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => btn.clicked(mouse)
        onWheel: wheel => btn.wheel(wheel)
    }
}
