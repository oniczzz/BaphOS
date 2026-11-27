// BaphOS: палитра, шрифт и размеры — одно место для всей оболочки.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg: "#000000"
    readonly property color bgAlt: "#0a0a0a"
    readonly property color coal: "#161212"
    readonly property color scarlet: "#ff1a1a"
    readonly property color blood: "#6b0000"
    readonly property color dried: "#3a0000"
    readonly property color text: "#d8d8d8"
    readonly property color dim: "#787070"

    // пиксельный шрифт: Cozette — растровый, чёткий только на своём размере
    readonly property string font: "Cozette"
    readonly property int fontPx: 13

    readonly property int barHeight: 32
    readonly property int border: 2

    // графика из репозитория (assets — симлинк на ../../assets)
    function asset(path) { return Quickshell.shellDir + "/assets/" + path }
}
