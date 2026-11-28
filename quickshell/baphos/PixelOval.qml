// Пиксельный овал из горизонтальных полосок 4 px: кольцо цвета ring, внутри — core.
import QtQuick

Item {
    id: ov
    property color ring: Theme.scarlet
    property color edge: "#ffd98c"
    property color core: Theme.blood
    property int thick: 3            // толщина кольца в «пикселях» (по 4 px)
    readonly property int rows: Math.max(2, Math.floor(height / 4))

    Repeater {
        model: ov.rows
        Item {
            id: row
            required property int index
            readonly property real yy: (index + 0.5) / ov.rows * 2 - 1
            readonly property real half: Math.sqrt(Math.max(0, 1 - yy * yy)) * ov.width / 2
            readonly property real w: Math.floor(half / 4) * 8
            readonly property real innerYY: Math.abs(yy) * ov.rows / Math.max(1, ov.rows - ov.thick * 2)
            readonly property real innerHalf: innerYY >= 1 ? 0 : Math.sqrt(1 - innerYY * innerYY) * (ov.width / 2 - ov.thick * 4)
            readonly property real iw: Math.floor(innerHalf / 4) * 8
            y: index * 4
            width: ov.width; height: 4
            Rectangle { x: (ov.width - row.w) / 2; width: row.w; height: 4; color: ov.ring }
            Rectangle { visible: row.w > 8; x: (ov.width - row.w) / 2; width: 4; height: 4; color: ov.edge }
            Rectangle { visible: row.w > 8; x: (ov.width + row.w) / 2 - 4; width: 4; height: 4; color: ov.edge }
            Rectangle { x: (ov.width - row.iw) / 2; width: row.iw; height: 4; color: ov.core }
        }
    }
}
