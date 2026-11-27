// BaphOS: Пуск — раскрытый гримуар.
//   левая страница: свечи, дышащий сигил, BaphOS, «Избранное» (3x2), питание и Настройки
//   корешок с прошивкой; правая страница: поиск (?сеть, >команда) и все программы
//   (правый клик по программе — в избранное / убрать).
// Раскрывается снизу ступенями по 8 px, строки списка проявляются каскадом. Клик мимо или Esc — закрыть.
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
    signal settingsRequested()
    signal launched()

    property bool shown: false
    property int reveal: 0
    property int tick: 0
    readonly property int panelW: 780
    readonly property int panelH: Math.min(580, menuWin.height - Theme.barHeight - 8)

    // окно живёт всегда (иначе первое открытие ждёт ~1 с); закрыто — пустая маска, клики насквозь
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
    Timer {
        id: stepper
        interval: 16; repeat: true
        onTriggered: {
            if (menuWin.open) { menuWin.reveal = Math.min(menuWin.panelH, menuWin.reveal + 48); if (menuWin.reveal >= menuWin.panelH) stop(); }
            else { menuWin.reveal = Math.max(0, menuWin.reveal - menuWin.panelH / 3); if (menuWin.reveal <= 0) { stop(); menuWin.shown = false; } }
        }
    }
    Timer { interval: 125; repeat: true; running: menuWin.shown && Store.data.animations; onTriggered: menuWin.tick++ }

    // ── программы ──
    readonly property var allApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    // ищем в уже загруженном списке — тогда избранное пересчитается, когда программы подгрузятся
    readonly property var favorites: (Store.data.favorites || []).map(id => allApps.find(e => e.id === id)).filter(e => e)
    function isFav(e) { return (Store.data.favorites || []).includes(e.id); }
    function toggleFav(e) {
        const f = (Store.data.favorites || []).slice();
        const i = f.indexOf(e.id);
        if (i >= 0) f.splice(i, 1); else if (f.length < 6) f.push(e.id);
        Store.data.favorites = f;
    }
    readonly property var apps: {
        const raw = search.text.trim();
        if (raw.startsWith("?") && raw.length > 1) {
            const q = raw.slice(1).trim();
            return [{ name: "Искать в сети: " + q, icon: "web-browser",
                      execute: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]) }];
        }
        if (raw.startsWith(">") && raw.length > 1) {
            const c = raw.slice(1).trim();
            return [{ name: "Выполнить: " + c, icon: "utilities-terminal",
                      execute: () => Quickshell.execDetached(["kitty", "--hold", "sh", "-c", c]) }];
        }
        const q = raw.toLowerCase();
        if (!q) return allApps;
        return allApps.filter(e =>
            [e.name, e.genericName, e.comment, (e.keywords || []).join(" ")]
                .some(s => (s || "").toLowerCase().includes(q)));
    }
    function launch(entry) {
        if (!entry) return;
        entry.execute();
        menuWin.launched();
        menuWin.closeRequested();
    }

    MouseArea { id: catcher; anchors.fill: parent; enabled: menuWin.shown; onClicked: menuWin.closeRequested() }

    // свеча из пикселей: воск, фитиль, живое пламя
    component Candle: Item {
        property int phase: 0
        width: 12; height: 44
        Image { source: Theme.asset("wallpapers/anim/flame-" + ((menuWin.tick + parent.phase) % 4) + ".png"); smooth: false }
        Rectangle { x: 4; y: 12; width: 4; height: 2; color: Theme.dim }
        Rectangle { x: 0; y: 14; width: 12; height: 30; color: Theme.text }
        Rectangle { x: 0; y: 14; width: 4; height: 30; color: Theme.dim }
        Rectangle { x: 8; y: 18; width: 2; height: 6; color: "#f0f0f0" }          // потёк воска
    }
    // заголовок с орнаментом: † ──── Текст ──── †
    component Ornament: RowLayout {
        property string label: ""
        spacing: 8
        PixelText { text: "†"; color: Theme.blood }
        Rectangle { Layout.fillWidth: true; height: 2; color: Theme.dried }
        PixelText { text: parent.label; color: Theme.scarlet }
        Rectangle { Layout.fillWidth: true; height: 2; color: Theme.dried }
        PixelText { text: "†"; color: Theme.blood }
    }

    Item {
        id: clipper
        width: menuWin.panelW + 8
        height: menuWin.reveal
        clip: true
        visible: menuWin.shown
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 4; bottomMargin: Theme.barHeight - 4 }

        Rectangle { x: 8; y: clipper.height - menuWin.panelH + 8; width: menuWin.panelW; height: menuWin.panelH - 8; color: "#000000"; opacity: 0.6 }

        Bevel {
            id: book
            kind: "panel"
            width: menuWin.panelW; height: menuWin.panelH - 8
            y: clipper.height - menuWin.panelH
            MouseArea { anchors.fill: parent }

            // страницы — тёмный пергамент
            Image { anchors.fill: parent; source: Theme.asset("ui/page.png"); fillMode: Image.Tile; smooth: false }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ══ левая страница ══
                ColumnLayout {
                    Layout.preferredWidth: 330
                    Layout.fillHeight: true
                    Layout.margins: 8
                    spacing: 8

                    // свечи, сигил, имя
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Candle { x: 6; y: 20; phase: 0 }
                        Candle { x: 28; y: 34; phase: 2 }
                        Candle { anchors.right: parent.right; anchors.rightMargin: 28; y: 34; phase: 1 }
                        Candle { anchors.right: parent.right; anchors.rightMargin: 6; y: 20; phase: 3 }
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 0
                            width: 96; height: 96
                            Image { anchors.fill: parent; source: Theme.asset("sigil/sigil-32.png"); smooth: false }
                        }
                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 92 }
                            text: "BaphOS"; color: Theme.scarlet
                            font.family: Theme.fontGothic; font.pixelSize: 48
                            renderType: Text.NativeRendering
                        }
                    }
                    PixelText {
                        Layout.alignment: Qt.AlignHCenter
                        text: (Quickshell.env("USER") ?? "") + " · " + Story.label("user", "служитель")
                        color: Theme.dim
                    }

                    Ornament { Layout.fillWidth: true; label: "Избранное" }

                    // избранное 3x2
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 6; rowSpacing: 6
                        Repeater {
                            model: menuWin.favorites
                            PixelButton {
                                id: fav
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 78
                                onClicked: m => { if (m.button === Qt.RightButton) menuWin.toggleFav(modelData); else menuWin.launch(modelData); }
                                Column {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: fav.down ? 1 : 0
                                    spacing: 6
                                    IconImage {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        implicitSize: 32
                                        source: Quickshell.iconPath(fav.modelData.icon, "application-x-executable")
                                    }
                                    PixelText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 92
                                        horizontalAlignment: Text.AlignHCenter
                                        text: fav.modelData.name
                                        color: fav.hovered ? Theme.scarlet : Theme.text
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                    PixelText {
                        Layout.alignment: Qt.AlignHCenter
                        visible: menuWin.favorites.length === 0
                        text: "Пусто. ПКМ по программе — в избранное."
                        color: Theme.dim
                        font.pixelSize: 12
                    }

                    Item { Layout.fillHeight: true }

                    // питание и Настройки: подпись наведённой кнопки — над рядом
                    PixelText {
                        id: powerHint
                        Layout.alignment: Qt.AlignHCenter
                        text: " "
                        color: Theme.scarlet
                        font.pixelSize: 12
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: [
                                { label: "Настройки", icon: "settings-cog", confirm: false, cmd: "settings" },
                                { label: "Замок", icon: "lock", confirm: false, cmd: "lock" },
                                { label: Story.label("logout", "Выход"), icon: "logout", confirm: true, cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
                                { label: "Заново", icon: "reload", confirm: true, cmd: ["systemctl", "reboot"] },
                                { label: "Уснуть", icon: "power", confirm: true, cmd: ["systemctl", "poweroff"] },
                            ]
                            PixelButton {
                                id: pw
                                required property var modelData
                                property bool armed: false
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                active: armed
                                onHoveredChanged: powerHint.text = hovered ? (armed ? "Точно? Ещё раз." : modelData.label) : " "
                                onClicked: {
                                    if (modelData.cmd === "settings") { menuWin.settingsRequested(); return; }
                                    if (modelData.cmd === "lock") { menuWin.closeRequested(); menuWin.lockRequested(); return; }
                                    if (armed) Quickshell.execDetached(modelData.cmd);
                                    else { armed = true; powerHint.text = "Точно? Ещё раз."; disarm.restart(); }
                                }
                                Timer { id: disarm; interval: 3000; onTriggered: pw.armed = false }
                                Image {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: pw.down ? 1 : 0
                                    source: Theme.icon(pw.modelData.icon, pw.armed || pw.hovered ? "scarlet" : "bone")
                                    width: 24; height: 24; smooth: false
                                }
                            }
                        }
                    }
                }

                // ══ корешок ══
                Image {
                    Layout.preferredWidth: 24
                    Layout.fillHeight: true
                    source: Theme.asset("ui/spine.png")
                    fillMode: Image.TileVertically
                    smooth: false
                }

                // ══ правая страница ══
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 8
                    spacing: 8

                    Ornament { Layout.fillWidth: true; label: Story.label("start", "Призыв") }

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
                            PixelText { visible: !search.text; text: Story.label("search", "Призвать..."); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: menuWin.apps
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool cur: ListView.isCurrentItem
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
                            PixelText { x: 6; anchors.verticalCenter: parent.verticalCenter; visible: row.cur; text: "†"; color: Theme.scarlet; font.bold: true }
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
                                    width: list.width - 80
                                    text: row.modelData.name
                                    color: row.cur ? Theme.scarlet : Theme.text
                                }
                            }
                            // отметка избранного
                            Rectangle {
                                anchors { right: parent.right; rightMargin: 30; verticalCenter: parent.verticalCenter }
                                visible: row.modelData.id !== undefined && menuWin.isFav(row.modelData)
                                width: 6; height: 6; rotation: 45; color: Theme.blood
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
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: list.currentIndex = row.index
                                onClicked: m => {
                                    if (m.button === Qt.RightButton) { if (row.modelData.id !== undefined) menuWin.toggleFav(row.modelData); }
                                    else menuWin.launch(row.modelData);
                                }
                            }
                        }
                        PixelText { anchors.centerIn: parent; visible: list.count === 0; text: "Пустота. Ничего не найдено."; color: Theme.dim }
                    }
                    PixelText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "ПКМ — избранное · ?сеть · >команда"
                        color: Theme.dim
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
