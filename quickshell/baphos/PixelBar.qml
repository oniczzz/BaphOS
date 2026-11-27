// Шкала из блоков, как индикатор загрузки Win98: вдавленная, внутри квадраты 6x10 с промежутком 2 px.
import QtQuick

Bevel {
    id: bar
    property real value: 0          // 0..1
    property color fill: value > 0.85 ? Theme.scarlet : Theme.crimson
    sunken: true
    face: Theme.bg
    implicitHeight: 16

    Row {
        id: row
        anchors { fill: parent; margins: 1 }
        spacing: 2
        readonly property int n: Math.max(1, Math.floor((width + 2) / 8))
        Repeater {
            model: row.n
            Rectangle {
                required property int index
                width: 6; height: row.height
                color: bar.fill
                visible: index < Math.round(Math.max(0, Math.min(1, bar.value)) * row.n)
            }
        }
    }
}
