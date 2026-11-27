// BaphOS: вид экрана блокировки — затемнённые обои, сигил, часы, поле пароля.
// Используется и в настоящей блокировке (Lock.qml), и в окне-превью.
import QtQuick
import Quickshell

Rectangle {
    id: view
    property bool showInput: true
    property string message: ""
    property bool busy: false
    property alias password: field.text
    signal submit(string password)

    color: Theme.bg

    Image {
        anchors.fill: parent
        source: Theme.asset("wallpapers/" + Store.data.wallpaper + "-1920x1080.png")
        fillMode: Image.PreserveAspectCrop
        smooth: false
    }
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.6 }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Theme.asset("sigil/sigil-64.png")
            width: 192; height: 192
            smooth: false
        }
        PixelText {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.scarlet
            font.pixelSize: 52
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
        PixelText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale("ru_RU").toString(new Date(), "dddd, d MMMM")
            color: Theme.dim
        }

        Rectangle {
            visible: view.showInput
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280; height: 30
            color: Theme.bg
            border.width: Theme.border
            border.color: view.message ? Theme.scarlet : (field.activeFocus ? Theme.blood : Theme.dried)
            TextInput {
                id: field
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "†"
                color: Theme.scarlet
                font.family: Theme.font
                font.pixelSize: Theme.fontPx
                renderType: Text.NativeRendering
                focus: true
                enabled: !view.busy
                onAccepted: if (text.length) view.submit(text)
                PixelText {
                    anchors.centerIn: parent
                    visible: !field.text
                    text: view.busy ? "..." : "пароль"
                    color: Theme.dim
                }
            }
        }
        PixelText {
            visible: view.showInput
            anchors.horizontalCenter: parent.horizontalCenter
            text: view.message
            color: Theme.scarlet
        }
    }

    function focusInput() { field.forceActiveFocus() }
}
