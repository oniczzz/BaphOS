// Заголовок раздела Настроек: крупный текст + алая черта.
import QtQuick

Column {
    property alias text: t.text
    property string hint: ""
    width: parent ? parent.width : 400
    spacing: 4
    PixelText { id: t; color: Theme.scarlet; font.pixelSize: 24 }
    PixelText { text: parent.hint; visible: text !== ""; color: Theme.dim; width: parent.width; wrapMode: Text.Wrap; elide: Text.ElideNone }
    Rectangle { width: parent.width; height: 2; color: Theme.dried }
}
