// BaphOS: меню «Пуск» в пиксель-арте.
//   Открытие — меню растёт снизу вверх ступенями по 8 px, строки проявляются каскадом;
//   шапка: свечи с живым пламенем, готическое «BaphOS», «дышащий» сигил;
//   выбранная строка — шахматка, алый крест, сдвиг на 4 px и язычок пламени.
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

    // видимость живёт дольше open — чтобы успела проиграться анимация закрытия
    property bool shown: false
    property int reveal: 0              // сколько пикселей меню видно (растёт ступенями)
    property int tick: 0                // общий тик анимаций (пламя, дыхание, каскад)
    readonly property int panelH: 600

    // окно живёт всегда (иначе первое открытие ждёт создания поверхности ~1 с);
    // закрыто — пустая маска: клики проходят насквозь, клавиатура не захвачена
    visible: true
    mask: Region { item: menuWin.shown ? catcher : nothing }
    Item { id: nothing; width: 0; height: 0 }
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-start"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            search.text = "";
            list.currentIndex = 0;
            tick = 0;
            reveal = Store.data.animations ? 0 : panelH;
            shown = true;
            search.forceActiveFocus();
        }
        stepper.restart();
    }

    // ступени открытия/закрытия: 8 px за шаг, раскрытие ~0.15 с, закрытие в 3 ступени
    Timer {
        id: stepper
        interval: 16
        repeat: true
        onTriggered: {
            if (menuWin.open) {
                menuWin.reveal = Math.min(menuWin.panelH, menuWin.reveal + 48);
                if (menuWin.reveal >= menuWin.panelH) stop();
            } else {
                menuWin.reveal = Math.max(0, menuWin.reveal - menuWin.panelH / 3);
                if (menuWin.reveal <= 0) { stop(); menuWin.shown = false; }
            }
        }
    }
    // живые мелочи: пламя, дыхание сигила, каскад строк (8 тиков в секунду)
    Timer {
        interval: 125
        repeat: true
        running: menuWin.shown && Store.data.animations
        onTriggered: menuWin.tick++
    }

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

    MouseArea { id: catcher; anchors.fill: parent; enabled: menuWin.shown; onClicked: menuWin.closeRequested() }

    // окно-обрезка: показывает нижние reveal пикселей меню — меню «растёт» из панели задач
    Item {
        id: clipper
        width: 456 + 8
        height: menuWin.reveal
        clip: true
        visible: menuWin.shown
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 4; bottomMargin: Theme.barHeight - 4 }

        // жёсткая пиксельная тень
        Rectangle {
            x: 8; y: clipper.height - menuWin.panelH + 8
            width: 456; height: menuWin.panelH - 8
            color: "#000000"; opacity: 0.55
        }

        Bevel {
            id: panel
            kind: "panel"
            width: 456; height: menuWin.panelH - 8
            y: clipper.height - menuWin.panelH
            MouseArea { anchors.fill: parent }   // клики внутри не закрывают меню

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                // ── шапка: свеча, сигил, BaphOS, свеча ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.bg
                        Image { anchors.fill: parent; source: Theme.asset("ui/checker.png"); fillMode: Image.Tile; smooth: false; opacity: 0.25 }
                    }
                    Repeater {
                        model: 2
                        Item {
                            required property int index
                            x: index === 0 ? 8 : parent.width - 20
                            y: 18
                            width: 12; height: 52
                            Image {
                                source: Theme.asset("wallpapers/anim/flame-" + ((menuWin.tick + parent.index * 2) % 4) + ".png")
                                smooth: false
                            }
                            Rectangle { x: 4; y: 12; width: 4; height: 4; color: Theme.dim }       // фитиль
                            Rectangle { x: 0; y: 16; width: 12; height: 36; color: Theme.text } // воск
                            Rectangle { x: 0; y: 16; width: 4; height: 36; color: Theme.dim }  // тень на воске
                        }
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: 12
                        Item {
                            width: 64; height: 64
                            anchors.verticalCenter: parent.verticalCenter
                            // «дыхание»: ступенчатое свечение под сигилом
                            Rectangle {
                                anchors.centerIn: parent
                                readonly property int ph: menuWin.tick % 12
                                readonly property int lvl: ph < 6 ? ph : 12 - ph
                                width: 64 + lvl * 4; height: width
                                radius: 0
                                color: Theme.blood
                                opacity: 0.08 * lvl
                            }
                            Image { anchors.fill: parent; source: Theme.asset("sigil/sigil-64.png"); smooth: false }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "BaphOS"
                                color: Theme.scarlet
                                font.family: Theme.fontGothic; font.pixelSize: 48
                                renderType: Text.NativeRendering
                            }
                            PixelText { text: (Quickshell.env("USER") ?? "") + " · служитель"; color: Theme.dim }
                        }
                    }
                }

                // ── поиск ──
                Bevel {
                    kind: "well"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    Image { id: lens; source: Theme.icon("search", search.activeFocus ? "scarlet" : "dim"); width: 24; height: 24; smooth: false; anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter } }
                    TextInput {
                        id: search
                        anchors { left: lens.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 6; rightMargin: 6 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.scarlet
                        selectionColor: Theme.blood
                        font.family: Theme.font
                        font.pixelSize: Theme.fontPx
                        renderType: Text.NativeRendering
                        cursorDelegate: Rectangle { width: 8; color: Theme.scarlet; visible: search.activeFocus && (menuWin.tick % 4 < 2) }
                        onTextChanged: list.currentIndex = 0
                        Keys.onEscapePressed: menuWin.closeRequested()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onReturnPressed: menuWin.launch(menuWin.apps[list.currentIndex])
                        Keys.onEnterPressed: menuWin.launch(menuWin.apps[list.currentIndex])
                        PixelText { visible: !search.text; text: "Призвать программу..."; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // ── приложения ──
                Bevel {
                    kind: "well"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        id: list
                        anchors.fill: parent
                        clip: true
                        model: menuWin.apps
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool cur: ListView.isCurrentItem
                            // каскад: строка проявляется в свой тик после открытия
                            readonly property bool appeared: !Store.data.animations || menuWin.tick >= Math.min(row.index, 14) / 4
                            width: list.width; height: 30
                            opacity: appeared ? 1 : 0

                            Rectangle {
                                anchors.fill: parent
                                visible: row.cur
                                color: Theme.dried
                                Image { anchors.fill: parent; source: Theme.asset("ui/checker.png"); fillMode: Image.Tile; smooth: false }
                                Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 2; color: Theme.scarlet }
                            }
                            PixelText {
                                x: 6; anchors.verticalCenter: parent.verticalCenter
                                visible: row.cur
                                text: "†"; color: Theme.scarlet; font.bold: true
                            }
                            Row {
                                x: row.cur ? 22 : 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 16
                                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                }
                                PixelText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: list.width - 70
                                    text: row.modelData.name
                                    color: row.cur ? Theme.scarlet : Theme.text
                                }
                            }
                            Image {
                                visible: row.cur
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                source: Theme.asset("wallpapers/anim/flame-" + (menuWin.tick % 4) + ".png")
                                smooth: false
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

                // ── питание: второй клик подтверждает (кроме замка) ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
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
                            Layout.preferredHeight: 36
                            active: armed
                            onClicked: {
                                if (!modelData.cmd) { menuWin.closeRequested(); menuWin.lockRequested(); return; }
                                if (armed || !modelData.confirm) Quickshell.execDetached(modelData.cmd);
                                else { armed = true; disarm.restart(); }
                            }
                            Timer { id: disarm; interval: 3000; onTriggered: pw.armed = false }
                            Row {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: pw.down ? 1 : 0
                                spacing: 4
                                Image { source: Theme.icon(pw.modelData.icon, pw.armed || pw.hovered ? "scarlet" : "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                                PixelText { text: pw.armed ? "Точно?" : pw.modelData.label; color: pw.armed ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }
            }
        }
    }
}
