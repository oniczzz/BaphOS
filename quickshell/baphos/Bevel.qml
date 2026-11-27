// Объёмная рамка в стиле Win98: 2 px света сверху-слева и 2 px тени снизу-справа.
// sunken — вдавленная (поле ввода, нажатая кнопка, «колодец» трея). Дети кладутся внутрь.
import QtQuick

Item {
    id: bevel
    property bool sunken: false
    property color face: Theme.face
    default property alias content: inner.data
    readonly property int inset: 2

    Rectangle { anchors.fill: parent; color: bevel.face }

    // внешняя пара линий
    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: bevel.sunken ? Theme.bevelLo : Theme.bevelHi }
    Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: bevel.sunken ? Theme.bevelLo : Theme.bevelHi }
    Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: bevel.sunken ? Theme.bevelHi : Theme.bevelLo }
    Rectangle { x: parent.width - 1; y: 0; width: 1; height: parent.height; color: bevel.sunken ? Theme.bevelHi : Theme.bevelLo }
    // внутренняя пара
    Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: bevel.sunken ? Theme.bevelLoIn : Theme.bevelHiIn }
    Rectangle { x: 1; y: 1; width: 1; height: parent.height - 2; color: bevel.sunken ? Theme.bevelLoIn : Theme.bevelHiIn }
    Rectangle { x: 1; y: parent.height - 2; width: parent.width - 2; height: 1; color: bevel.sunken ? Theme.bevelHiIn : Theme.bevelLoIn }
    Rectangle { x: parent.width - 2; y: 1; width: 1; height: parent.height - 2; color: bevel.sunken ? Theme.bevelHiIn : Theme.bevelLoIn }

    Item {
        id: inner
        anchors { fill: parent; margins: bevel.inset }
    }
}
