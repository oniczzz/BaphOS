// BaphOS: меню «Пуск» — поиск по приложениям, питание. Прозрачный слой на весь экран:
// клик мимо меню закрывает его, Esc тоже.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: menuWin
    property bool open: false
    signal closeRequested()

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-start"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) { search.text = ""; list.currentIndex = 0; search.forceActiveFocus(); }

    // все видимые приложения, по алфавиту
    readonly property var allApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var apps: {
        const q = search.text.trim().toLowerCase();
        if (!q) return allApps;
        return allApps.filter(e =>
            [e.name, e.genericName, e.comment, (e.keywords || []).join(" ")]
                .some(s => (s || "").toLowerCase().includes(q)));
    }

    function launch(entry) {
        if (!entry) return;
        entry.execute();
        menuWin.closeRequested();
    }

    MouseArea { anchors.fill: parent; onClicked: menuWin.closeRequested() }

    Rectangle {
        id: panel
        width: 380; height: 500
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 4; bottomMargin: Theme.barHeight + 2 }
        color: Theme.bg
        border.width: Theme.border
        border.color: Theme.scarlet
        MouseArea { anchors.fill: parent }   // клики внутри не закрывают меню

        ColumnLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 8

            // шапка: сигил и имя
            Row {
                spacing: 10
                Image { source: Theme.asset("sigil/sigil-64.png"); width: 64; height: 64; smooth: false }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    PixelText { text: "BaphOS"; color: Theme.scarlet; font.pixelSize: 26 }
                    PixelText { text: Quickshell.env("USER") ?? ""; color: Theme.dim }
                }
            }

            // поиск
            Rectangle {
                Layout.fillWidth: true
                height: 26
                color: Theme.bgAlt
                border.width: Theme.border
                border.color: search.activeFocus ? Theme.scarlet : Theme.blood
                TextInput {
                    id: search
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.blood
                    font.family: Theme.font
                    font.pixelSize: Theme.fontPx
                    renderType: Text.NativeRendering
                    onTextChanged: list.currentIndex = 0
                    Keys.onEscapePressed: menuWin.closeRequested()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: menuWin.launch(menuWin.apps[list.currentIndex])
                    Keys.onEnterPressed: menuWin.launch(menuWin.apps[list.currentIndex])
                    PixelText { visible: !search.text; text: "Поиск..."; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // приложения
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: menuWin.apps
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width; height: 26
                    color: ListView.isCurrentItem ? Theme.dried : (rowArea.containsMouse ? Theme.coal : "transparent")
                    border.width: ListView.isCurrentItem ? 1 : 0
                    border.color: Theme.scarlet
                    Row {
                        anchors { fill: parent; leftMargin: 6 }
                        spacing: 8
                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 18
                            source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        }
                        PixelText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: list.width - 40
                            text: row.modelData.name
                            color: row.ListView.isCurrentItem ? Theme.scarlet : Theme.text
                        }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = row.index
                        onClicked: menuWin.launch(row.modelData)
                    }
                }
                PixelText { anchors.centerIn: parent; visible: list.count === 0; text: "Ничего не найдено"; color: Theme.dim }
            }

            // питание: второй клик подтверждает
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [
                        ["Выход", ["niri", "msg", "action", "quit", "--skip-confirmation"]],
                        ["Перезагрузка", ["systemctl", "reboot"]],
                        ["Выключение", ["systemctl", "poweroff"]],
                    ]
                    PixelButton {
                        id: pw
                        required property var modelData
                        property bool armed: false
                        Layout.fillWidth: true
                        height: 26
                        active: armed
                        onClicked: {
                            if (armed) Quickshell.execDetached(modelData[1]);
                            else { armed = true; disarm.restart(); }
                        }
                        Timer { id: disarm; interval: 3000; onTriggered: pw.armed = false }
                        PixelText { anchors.centerIn: parent; text: pw.armed ? "Точно?" : pw.modelData[0]; color: pw.armed ? Theme.scarlet : Theme.text }
                    }
                }
            }
        }
    }
}
