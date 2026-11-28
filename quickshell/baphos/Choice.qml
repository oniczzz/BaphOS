// Выбор одного варианта кнопками: options = [[значение, подпись], ...]; выбранный — «нажат».
import QtQuick

Column {
    id: ch
    property string label: ""
    property var options: []
    property var current
    signal picked(var value)
    spacing: 4
    PixelText { text: ch.label; visible: text !== "" }
    Flow {
        width: ch.parent ? ch.parent.width : 600
        spacing: 6
        Repeater {
            model: ch.options
            PixelButton {
                id: opt
                required property var modelData
                active: String(ch.current) === String(modelData[0])
                width: optText.implicitWidth + 20; height: 32
                onClicked: ch.picked(modelData[0])
                PixelText { id: optText; anchors.centerIn: parent; text: opt.modelData[1]; color: opt.active ? Theme.scarlet : Theme.text }
            }
        }
    }
}
