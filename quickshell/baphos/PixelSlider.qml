// Пиксельный ползунок: вдавленное поле с блоками; клик/перетаскивание — значение, колесо — ±5%.
import QtQuick

Item {
    id: sl
    property real value: 0             // 0..1
    property string icon: ""
    property bool muted: false
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 30

    Image {
        id: ic
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 24; height: 24; smooth: false
        source: sl.icon ? Theme.icon(sl.icon, sl.muted ? "dim" : "bone") : ""
        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: sl.iconClicked() }
    }
    Bevel {
        id: track
        kind: "well"
        anchors { left: ic.right; leftMargin: 8; right: pct.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        height: 22
        Row {
            id: blocks
            anchors.fill: parent
            spacing: 2
            readonly property int n: Math.max(1, Math.floor((width + 2) / 8))
            Repeater {
                model: blocks.n
                Rectangle {
                    required property int index
                    width: 6; height: blocks.height
                    readonly property bool on: index < Math.round(Math.max(0, Math.min(1, sl.value)) * blocks.n)
                    color: sl.muted ? Theme.dried : (index >= blocks.n - 2 ? Theme.scarlet : Theme.crimson)
                    visible: on
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            function set(mx) { sl.moved(Math.max(0, Math.min(1, mx / width))); }
            onPressed: m => set(m.x)
            onPositionChanged: m => { if (pressed) set(m.x); }
            onWheel: w => sl.moved(Math.max(0, Math.min(1, sl.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
    PixelText {
        id: pct
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 44
        horizontalAlignment: Text.AlignRight
        text: Math.round(sl.value * 100) + "%"
        color: sl.muted ? Theme.dim : Theme.text
    }
}
