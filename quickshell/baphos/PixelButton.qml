// Пиксельная кнопка: срезанные углы; наведение — алый контур; нажата/active — алый контур,
// тёмно-красная заливка и «шахматка» (память о Win98) и сдвиг содержимого на 1 px вниз.
import QtQuick

Bevel {
    id: btn
    property bool active: false
    property alias hovered: area.containsMouse
    readonly property bool down: area.pressed || active
    signal clicked(var mouse)
    signal wheel(var wheel)

    kind: down ? "btn-active" : (area.containsMouse ? "btn-hover" : "btn")
    sunken: down

    Image {
        anchors.fill: parent
        visible: btn.active
        source: Theme.asset("ui/checker.png")
        fillMode: Image.Tile
        smooth: false
        opacity: 0.6
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -btn.inset
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => btn.clicked(mouse)
        onWheel: wheel => btn.wheel(wheel)
    }
}
