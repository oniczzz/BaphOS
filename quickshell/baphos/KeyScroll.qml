// BaphOS: «Свиток клавиш» — шпаргалка (Mod+Shift+/), клик или Esc закрывает.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: scroll
    property bool open: false
    signal dismissed()

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#a0000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-keys"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var keys: [
        ["Mod+D", "Пуск: поиск, ?сеть, >команда"],
        ["Mod+T", "Терминал (kitty)"],
        ["Mod+B", "Браузер (Helium)"],
        ["Mod+S", "Настройки BaphOS"],
        ["Mod+N", "Алтарь: звук, свет, Wi-Fi..."],
        ["Mod+G", "Игровой режим (тишина)"],
        ["Mod+Shift+W", "Сменить обои"],
        ["Super+Alt+L", "Заблокировать"],
        ["Alt+Tab", "Предыдущее окно"],
        ["Mod+Tab", "Список окон"],
        ["Mod+O", "Обзор столов"],
        ["Mod+Q", "Закрыть окно"],
        ["Mod+F", "Развернуть колонку"],
        ["Mod+Shift+F", "Во весь экран"],
        ["Mod+←/→", "Фокус влево/вправо"],
        ["Mod+Ctrl+←/→", "Двигать колонку"],
        ["Mod+↑/↓", "Фокус вверх/вниз"],
        ["Mod+1..9", "Рабочий стол N"],
        ["Mod+R", "Ширина колонки"],
        ["Mod+V", "Окно плавающее/нет"],
        ["Mod+Shift+S", "Скриншот области"],
        ["Print", "Скриншот"],
        ["Mod+Alt+S", "Steam"],
        ["Mod+Shift+D/G", "Discord / Telegram"],
        ["Alt+Shift", "Раскладка RU/EN"],
        ["Mod+Shift+E", "Выйти из niri"],
    ]

    MouseArea { anchors.fill: parent; onClicked: scroll.dismissed() }
    Item { focus: scroll.open; Keys.onEscapePressed: scroll.dismissed() }

    Bevel {
        kind: "panel"
        anchors.centerIn: parent
        width: 760
        height: col.implicitHeight + 2 * inset + 8
        Column {
            id: col
            width: parent.width
            spacing: 10
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                Image { source: Theme.asset("sigil/sigil-32.png"); width: 32; height: 32; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                PixelText { text: "Свиток клавиш"; color: Theme.scarlet; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                Image { source: Theme.asset("sigil/sigil-32.png"); width: 32; height: 32; smooth: false; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle { width: parent.width; height: 2; color: Theme.dried }
            GridLayout {
                width: parent.width
                columns: 4
                columnSpacing: 12
                rowSpacing: 4
                Repeater {
                    model: scroll.keys
                    Item {
                        required property var modelData
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        implicitHeight: 24
                        Bevel {
                            id: cap
                            kind: "btn"
                            width: Math.max(64, keyText.implicitWidth + 14); height: 24
                            PixelText { id: keyText; anchors.centerIn: parent; text: modelData[0]; color: Theme.scarlet }
                        }
                        PixelText { anchors { left: cap.right; leftMargin: 8; right: parent.right; verticalCenter: parent.verticalCenter } text: modelData[1] }
                    }
                }
            }
            PixelText { anchors.horizontalCenter: parent.horizontalCenter; text: "Mod = клавиша Super (Win). Клик или Esc — свернуть свиток."; color: Theme.dim }
        }
    }
}
