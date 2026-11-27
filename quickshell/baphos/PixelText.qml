// Текст пиксельным шрифтом (по умолчанию Pixelify Sans 16 px — чёткий размер).
import QtQuick

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontPx
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
