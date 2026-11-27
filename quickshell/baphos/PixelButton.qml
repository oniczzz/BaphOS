// Кнопка Win98 в палитре BaphOS: выпуклая; нажата или active — вдавлена, active ещё и «шахматка».
import QtQuick

Bevel {
    id: btn
    property bool active: false
    property alias hovered: area.containsMouse
    signal clicked(var mouse)
    signal wheel(var wheel)

    sunken: area.pressed || active
    face: area.containsMouse && !sunken ? Theme.faceHover : Theme.face

    Image {
        anchors.fill: parent
        visible: btn.active
        source: Theme.asset("ui/checker.png")
        fillMode: Image.Tile
        smooth: false
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
