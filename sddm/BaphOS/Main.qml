// BaphOS: экран входа SDDM (Qt6). Всё нужное лежит в папке темы (SDDM не видит домашнюю папку):
// шрифты, сигил, рамки, обои — install.sh --system кладёт их сюда из репозитория.
import QtQuick

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#000000"

    readonly property color scarlet: "#ff1a1a"
    readonly property color text: "#d8d8d8"
    readonly property color dim: "#787070"
    readonly property color dried: "#3a0000"

    FontLoader { id: uiFont; source: "fonts/PixelifySans.ttf" }
    FontLoader { id: gothic; source: "fonts/Jacquard24-Regular.ttf" }
    FontLoader { id: numFont; source: "fonts/PressStart2P-Regular.ttf" }

    property int session: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""

    Connections {
        target: sddm
        function onLoginFailed() { root.message = "Неверно. Тьма не открывается."; password.text = ""; password.forceActiveFocus(); }
        function onLoginSucceeded() { root.message = ""; }
    }

    function doLogin() {
        root.message = "";
        sddm.login(user.text, password.text, root.session);
    }

    // имена сессий из модели SDDM
    Repeater { id: sessions; model: sessionModel; Item { required property string name; property string n: name } }

    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: false
    }
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.45 }

    // часы
    Text {
        id: clock
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 48 }
        color: root.scarlet
        font.family: numFont.name; font.pixelSize: 32
        renderType: Text.NativeRendering
        Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm") }
    }

    component Frame: BorderImage {
        property string kind: "panel"
        source: "frame-" + kind + ".png"
        readonly property int b: kind === "panel" ? 16 : 6
        border { left: b; right: b; top: b; bottom: b }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
        smooth: false
    }
    component Label: Text {
        color: root.text
        font.family: uiFont.name; font.pixelSize: 16
        renderType: Text.NativeRendering
    }

    // ── панель входа ──
    Item {
        anchors.centerIn: parent
        width: 440; height: 470
        Rectangle { x: 8; y: 8; width: parent.width; height: parent.height; color: "#000000"; opacity: 0.55 }   // жёсткая тень
        Frame { anchors.fill: parent }

        Column {
            anchors { fill: parent; margins: 28 }
            spacing: 12

            Image { anchors.horizontalCenter: parent.horizontalCenter; source: "sigil-64.png"; width: 128; height: 128; smooth: false }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "BaphOS"; color: root.scarlet
                font.family: gothic.name; font.pixelSize: 48
                renderType: Text.NativeRendering
            }

            Frame {
                kind: "well"; width: parent.width; height: 36
                TextInput {
                    id: user
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    text: userModel.lastUser
                    color: root.text
                    font.family: uiFont.name; font.pixelSize: 16
                    renderType: Text.NativeRendering
                    KeyNavigation.tab: password
                    onAccepted: password.forceActiveFocus()
                    Label { visible: !user.text; text: "имя"; color: root.dim; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Frame {
                kind: "well"; width: parent.width; height: 36
                TextInput {
                    id: password
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "†"
                    color: root.scarlet
                    font.family: uiFont.name; font.pixelSize: 16
                    renderType: Text.NativeRendering
                    focus: true
                    KeyNavigation.tab: user
                    onAccepted: root.doLogin()
                    Label { visible: !password.text; text: "пароль"; color: root.dim; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // сессия: ‹ niri ›
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Label {
                    text: "‹"; color: root.scarlet; font.pixelSize: 24
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.session = (root.session - 1 + sessionModel.rowCount()) % Math.max(1, sessionModel.rowCount()) }
                }
                Label { text: "сеанс: " + (sessions.itemAt(root.session)?.n ?? "—"); anchors.verticalCenter: parent.verticalCenter }
                Label {
                    text: "›"; color: root.scarlet; font.pixelSize: 24
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.session = (root.session + 1) % Math.max(1, sessionModel.rowCount()) }
                }
            }

            Frame {
                id: loginBtn
                kind: loginArea.pressed ? "btn-active" : (loginArea.containsMouse ? "btn-hover" : "btn")
                width: parent.width; height: 40
                Label { anchors.centerIn: parent; text: "Войти во тьму"; color: root.scarlet; font.bold: true }
                MouseArea { id: loginArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.doLogin() }
            }

            Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.message; color: root.scarlet; visible: text !== "" }
        }
    }

    // ── питание ──
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
        spacing: 8
        Repeater {
            model: [["reload", "Заново", () => sddm.reboot(), sddm.canReboot], ["power", "Уснуть", () => sddm.powerOff(), sddm.canPowerOff]]
            Frame {
                required property var modelData
                visible: modelData[3]
                kind: pa.containsMouse ? "btn-hover" : "btn"
                width: 120; height: 40
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Image { source: modelData[0] + "-bone-24.png"; width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: modelData[1]; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; onClicked: modelData[2]() }
            }
        }
    }
}
