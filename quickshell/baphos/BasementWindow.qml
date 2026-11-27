// BaphOS: пасхалка «Подвал» — каменная комната сверху, по полу катятся слёзы, на алтаре парит
// «Кровь Агнца». Своя графика (art/story.py).
import QtQuick
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: win
    property bool open: false
    signal dismissed()
    title: "Подвал"
    visible: open
    implicitWidth: 520
    implicitHeight: 440
    color: Theme.bg
    onVisibleChanged: if (!visible && open) dismissed()

    property int tick: 0
    readonly property bool taken: (Store.data.storySeen || []).includes("vial")
    Timer { interval: 125; repeat: true; running: win.visible; onTriggered: win.tick++ }

    Bevel {
        kind: "panel"
        anchors.fill: parent
        anchors.margins: 8
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 480; Layout.preferredHeight: 288
                clip: true
                Image { anchors.fill: parent; source: Theme.asset("story/basement.png"); smooth: false }
                // слёзы: катятся вниз по комнате
                Repeater {
                    model: 6
                    Image {
                        required property int index
                        source: Theme.asset("story/tear.png"); smooth: false
                        x: 48 + index * 72
                        y: 32 + ((win.tick * 4 + index * 37) % 220)
                    }
                }
                // флакон на алтаре — парит на 4 px вверх-вниз
                Image {
                    visible: !win.taken
                    source: Theme.asset("story/blood-vial.png"); smooth: false
                    x: 240 - width / 2
                    y: 144 - height + (win.tick % 8 < 4 ? 0 : -4)
                }
            }
            PixelText {
                Layout.alignment: Qt.AlignHCenter
                text: win.taken ? "Алтарь пуст. Кровь Агнца уже с тобой." : "Ты спустился в подвал. На алтаре — Кровь Агнца."
                color: win.taken ? Theme.dim : Theme.scarlet
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                PixelButton {
                    visible: !win.taken
                    Layout.preferredWidth: 160; Layout.preferredHeight: 36
                    onClicked: {
                        Store.data.storySeen = (Store.data.storySeen || []).concat(["vial"]);
                        Story.glitch(2);
                        Story.whisper("Кровь Агнца теперь с тобой. +1 к вере.");
                    }
                    PixelText { anchors.centerIn: parent; text: "Взять"; color: Theme.scarlet }
                }
                PixelButton {
                    Layout.preferredWidth: 160; Layout.preferredHeight: 36
                    onClicked: win.dismissed()
                    PixelText { anchors.centerIn: parent; text: "Подняться"; color: Theme.text }
                }
            }
        }
    }
}
