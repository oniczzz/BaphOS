// Пиксельная рамка BaphOS (9-slice из art/frames.py), без сглаживания.
//   kind: "panel" — узорная (рога на углах, алая жилка с «цепью»), "well" — вдавленное поле,
//         "btn" / "btn-hover" / "btn-active" — кнопки со срезанными углами.
// sunken (для совместимости) = "well". Дети кладутся внутрь, с отступом inset.
import QtQuick

Item {
    id: frame
    property bool sunken: false
    property string kind: sunken ? "well" : "panel"
    property color face: "transparent"          // не нужен: заливка нарисована в рамке
    default property alias content: inner.data
    readonly property int border: kind === "panel" ? 16 : 6
    property int inset: kind === "panel" ? 11 : 4

    BorderImage {
        anchors.fill: parent
        source: Theme.asset("ui/frame-" + frame.kind + ".png")
        border { left: frame.border; right: frame.border; top: frame.border; bottom: frame.border }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
        smooth: false
    }

    Item {
        id: inner
        anchors { fill: parent; margins: frame.inset }
    }
}
