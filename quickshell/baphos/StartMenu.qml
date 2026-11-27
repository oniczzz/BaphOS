// BaphOS: меню «Пуск» в стиле Win98 — готическая полоса слева, поиск, список, питание.
// Прозрачный слой на весь экран: клик мимо меню закрывает его, Esc тоже.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: menuWin
    property bool open: false
    signal closeRequested()
    signal lockRequested()

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-start"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) { search.text = ""; list.currentIndex = 0; search.forceActiveFocus(); }

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

    Bevel {
        id: panel
        width: 440; height: 580
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 3; bottomMargin: Theme.barHeight - 2 }
        MouseArea { anchors.fill: parent }   // клики внутри не закрывают меню

        // ── полоса слева: дизеринг и готическая надпись ──
        Item {
            id: banner
            width: 44
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            Rectangle { anchors.fill: parent; color: Theme.blood }
            Image {
                anchors.fill: parent
                source: Theme.asset("ui/checker.png")
                fillMode: Image.Tile
                smooth: false
                opacity: 0.85
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#000000" }
                    GradientStop { position: 0.6; color: "#00000000" }
                }
            }
            Text {
                text: "BaphOS"
                color: Theme.scarlet
                font.family: Theme.fontGothic
                font.pixelSize: 48
                renderType: Text.NativeRendering
                rotation: -90
                transformOrigin: Item.TopLeft
                x: 0
                y: parent.height - 6
            }
        }

        ColumnLayout {
            anchors { left: banner.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 8 }
            spacing: 8

            // шапка
            RowLayout {
                spacing: 10
                Image { source: Theme.asset("sigil/sigil-64.png"); Layout.preferredWidth: 64; Layout.preferredHeight: 64; smooth: false }
                ColumnLayout {
                    spacing: 2
                    PixelText { text: Quickshell.env("USER") ?? ""; color: Theme.scarlet; font.pixelSize: 24 }
                    PixelText { text: "служитель тьмы"; color: Theme.dim }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bevelLo }

            // поиск
            Bevel {
                sunken: true
                face: Theme.bg
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Image { id: lens; source: Theme.icon("search", "dim"); width: 24; height: 24; smooth: false; anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: search
                    anchors { left: lens.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 6; rightMargin: 6 }
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
                    PixelText { visible: !search.text; text: "Призвать программу..."; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // приложения
            Bevel {
                sunken: true
                face: Theme.bg
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    id: list
                    anchors { fill: parent; margins: 2 }
                    clip: true
                    model: menuWin.apps
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool cur: ListView.isCurrentItem
                        width: list.width; height: 28
                        color: cur ? Theme.scarlet : "transparent"
                        Row {
                            anchors { fill: parent; leftMargin: 6 }
                            spacing: 8
                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 16
                                source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                            }
                            PixelText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: list.width - 40
                                text: row.modelData.name
                                color: row.cur ? Theme.bg : Theme.text
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: menuWin.launch(row.modelData)
                        }
                    }
                    PixelText { anchors.centerIn: parent; visible: list.count === 0; text: "Пустота. Ничего не найдено."; color: Theme.dim }
                }
            }

            // питание: второй клик подтверждает (кроме блокировки)
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [
                        { label: "Замок", icon: "lock", confirm: false, cmd: null },
                        { label: "Выход", icon: "logout", confirm: true, cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
                        { label: "Заново", icon: "reload", confirm: true, cmd: ["systemctl", "reboot"] },
                        { label: "Уснуть", icon: "power", confirm: true, cmd: ["systemctl", "poweroff"] },
                    ]
                    PixelButton {
                        id: pw
                        required property var modelData
                        property bool armed: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        active: armed
                        onClicked: {
                            if (!modelData.cmd) { menuWin.closeRequested(); menuWin.lockRequested(); return; }
                            if (armed || !modelData.confirm) Quickshell.execDetached(modelData.cmd);
                            else { armed = true; disarm.restart(); }
                        }
                        Timer { id: disarm; interval: 3000; onTriggered: pw.armed = false }
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Image { source: Theme.icon(pw.modelData.icon, pw.armed ? "scarlet" : "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                            PixelText { text: pw.armed ? "Точно?" : pw.modelData.label; color: pw.armed ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }
    }
}
