// BaphOS: палитра, шрифты и размеры — одно место для всей оболочки.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg: "#000000"
    readonly property color bgAlt: "#0a0a0a"
    readonly property color coal: "#161212"
    readonly property color scarlet: "#ff1a1a"
    readonly property color crimson: "#a00000"
    readonly property color blood: "#6b0000"
    readonly property color dried: "#3a0000"
    readonly property color text: "#d8d8d8"
    readonly property color dim: "#787070"

    // объём в стиле Win98: грань кнопки и четыре линии фаски
    readonly property color face: "#140909"
    readonly property color faceHover: "#1e0c0c"
    readonly property color bevelHi: "#a31414"      // внешний свет (верх, лево)
    readonly property color bevelHiIn: "#4a0505"    // внутренний свет
    readonly property color bevelLo: "#000000"      // внешняя тень (низ, право)
    readonly property color bevelLoIn: "#260707"    // внутренняя тень

    // шрифты (fonts/ в репозитории, OFL): чёткие только на своих размерах
    readonly property string font: "Pixelify Sans"   // интерфейс, кириллица: 16 / 24 px
    readonly property int fontPx: 16
    readonly property string fontNum: "Press Start 2P" // часы и цифры: 8 / 16 px
    readonly property string fontGothic: "Jacquard 24" // логотип, только латиница: 24 / 48 px
    readonly property string fontMono: "Cozette"       // моно: 13 px

    readonly property int barHeight: 40
    readonly property int border: 2

    // графика из репозитория (assets — симлинк на ../../assets)
    function asset(path) { return Quickshell.shellDir + "/assets/" + path }
    function icon(name, color, size) { return asset("ui/" + name + "-" + (color || "scarlet") + "-" + (size || 24) + ".png") }
}
