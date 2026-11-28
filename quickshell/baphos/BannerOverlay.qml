// Отрисовка Banner на одном экране: полоса проявляется, надпись наплывает (1.0 → 1.12), затем всё гаснет.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: ov
    required property var modelData
    screen: modelData
    property real t: 0                   // 0..1 по времени показа

    visible: t > 0 && t < 1
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}                      // клики насквозь
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-banner"

    Connections {
        target: Banner
        function onSeqChanged() { anim.restart(); }
    }
    NumberAnimation { id: anim; target: ov; property: "t"; from: 0.001; to: 1; duration: Banner.duration }

    // проявление 0..0.15, держится, гаснет 0.75..1
    readonly property real fade: t < 0.15 ? t / 0.15 : t > 0.75 ? (1 - t) / 0.25 : 1

    Item {
        anchors.fill: parent
        opacity: ov.fade
        // затемнение экрана
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.35 }
        // полоса: плотная середина, края растворяются ступенями (пиксельный градиент)
        Column {
            anchors.centerIn: parent
            width: parent.width
            Repeater {
                model: [0.2, 0.4, 0.6, 0.8]
                Rectangle { required property real modelData; width: parent.width; height: 8; color: "black"; opacity: modelData }
            }
            Rectangle { width: parent.width; height: 170; color: "black"; opacity: 0.92 }
            Repeater {
                model: [0.8, 0.6, 0.4, 0.2]
                Rectangle { required property real modelData; width: parent.width; height: 8; color: "black"; opacity: modelData }
            }
        }
        // тонкие линии по краям полосы, расходятся от центра
        Repeater {
            model: [-68, 66]
            Rectangle {
                required property int modelData
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height / 2 + modelData
                width: parent.width * (0.35 + 0.25 * ov.t); height: 2
                color: Theme.blood
            }
        }
        // надпись: тень-ореол и сама, наплывает
        Item {
            anchors.centerIn: parent
            width: label.implicitWidth; height: label.implicitHeight
            scale: 1.0 + 0.12 * ov.t
            Text {
                x: 3; y: 3
                text: label.text; font: label.font
                color: Theme.dried
                renderType: Text.NativeRendering
            }
            Text {
                id: label
                text: Banner.text
                color: Banner.color
                font.family: Theme.font; font.pixelSize: 64; font.bold: true; font.letterSpacing: 6
                renderType: Text.NativeRendering
            }
        }
    }
}
