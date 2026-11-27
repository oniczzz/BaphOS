// BaphOS: окно «Ритуал» — молитва проявляется по строкам, ключевые слова нужно произнести (ввести).
// «Не сейчас» — отложить: культ предложит снова позже.
import QtQuick
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: win
    property bool open: false
    signal dismissed()
    title: "Ритуал"
    visible: open
    implicitWidth: 640
    implicitHeight: 520
    color: Theme.bg
    onVisibleChanged: {
        if (!visible && open) dismissed();
        if (visible) { shown = 0; field.text = ""; message = ""; lineTimer.start(); field.forceActiveFocus(); }
    }

    readonly property var prayer: Story.prayers[Story.ritual] || { title: "", lines: [], key: "" }
    property int shown: 0
    property string message: ""
    property int tick: 0
    Timer { id: lineTimer; interval: 700; repeat: true; onTriggered: { win.shown++; if (win.shown >= win.prayer.lines.length) stop(); } }
    Timer { interval: 125; repeat: true; running: win.visible; onTriggered: win.tick++ }

    // тряска при ошибке: пиксельные рывки
    property int shake: 0
    Timer { id: shaker; interval: 40; repeat: true; onTriggered: { win.shake--; if (win.shake <= 0) stop(); } }

    Bevel {
        kind: "panel"
        anchors.fill: parent
        anchors.margins: 8
        x: win.shake > 0 ? (win.shake % 2 ? 6 : -6) : 0

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 128; Layout.preferredHeight: 128
                Rectangle {
                    anchors.centerIn: parent
                    readonly property int ph: win.tick % 12
                    readonly property int lvl: ph < 6 ? ph : 12 - ph
                    width: 128 + lvl * 8; height: width
                    color: Theme.blood
                    opacity: 0.1 * lvl
                }
                Image { anchors.fill: parent; source: Theme.asset("sigil/sigil-128.png"); smooth: false }
            }
            PixelText { Layout.alignment: Qt.AlignHCenter; text: win.prayer.title; color: Theme.scarlet; font.pixelSize: 24 }
            Column {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: win.prayer.lines
                    PixelText {
                        required property string modelData
                        required property int index
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        visible: index < win.shown
                        color: index === win.prayer.lines.length - 1 ? Theme.scarlet : Theme.text
                    }
                }
            }
            Item { Layout.fillHeight: true }
            PixelText {
                Layout.alignment: Qt.AlignHCenter
                text: "Произнеси: «" + win.prayer.key + "»"
                color: Theme.dim
                visible: win.shown >= win.prayer.lines.length
            }
            Bevel {
                kind: "well"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                TextInput {
                    id: field
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Theme.scarlet
                    font.family: Theme.font; font.pixelSize: Theme.fontPx
                    renderType: Text.NativeRendering
                    onAccepted: {
                        if (!Story.tryPrayer(text)) {
                            win.message = "Слова не те. Тьма не слышит.";
                            win.shake = 8; shaker.start();
                            text = "";
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                PixelText { Layout.fillWidth: true; text: win.message; color: Theme.scarlet }
                PixelButton {
                    Layout.preferredWidth: 140; Layout.preferredHeight: 34
                    onClicked: win.dismissed()
                    PixelText { anchors.centerIn: parent; text: "Не сейчас"; color: Theme.dim }
                }
            }
        }
    }
}
