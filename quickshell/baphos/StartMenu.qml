// BaphOS: Пуск в духе меню Persona 5 — своя графика, своя палитра.
//   Алая полоса с полутоном влетает наискось; слева пункты на косых лентах лесенкой; выбранный —
//   рваная алая клякса, белая лента, чёрный текст, лёгкая дрожь; справа косая «карточка статуса».
//   «ПРИЗВАТЬ» — поиск и все программы (можно сразу печатать), «ПОКИНУТЬ» — питание с подтверждением.
//   Клавиши: ↑/↓, Enter, Esc (назад/закрыть). Мышь: наведение выбирает, клик — действие.
import QtQuick
import QtQuick.Shapes
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
    property real t: 0                  // 0..1 — проявление (полоса, пункты)
    property int tick: 0                // дрожь выбранного пункта
    property string page: "main"        // main | apps | power
    property int sel: 0

    // окно живёт всегда (иначе первое открытие ждёт ~1 с); закрыто — пустая маска, клики насквозь
    visible: true
    mask: Region { item: menuWin.shown ? root : nothing }
    Item { id: nothing; width: 0; height: 0 }
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-start"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            page = "main"; sel = 0; search.text = "";
            shown = true;
            if (Store.data.animations && !Mode.calm) { t = 0; showAnim.restart(); } else t = 1;
            keys.forceActiveFocus();
        } else {
            if (Store.data.animations && !Mode.calm) hideAnim.restart(); else { t = 0; shown = false; }
        }
    }
    NumberAnimation { id: showAnim; target: menuWin; property: "t"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
    NumberAnimation { id: hideAnim; target: menuWin; property: "t"; to: 0; duration: 140; easing.type: Easing.InCubic
        onFinished: menuWin.shown = false }
    Timer { interval: 220; repeat: true; running: menuWin.shown && Store.data.animations; onTriggered: menuWin.tick++ }

    // ── программы ──
    readonly property var allApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    function app(id) { return allApps.find(e => e.id === id) || DesktopEntries.heuristicLookup(id) || null; }
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
        return allApps.filter(e => [e.name, e.genericName, e.comment, (e.keywords || []).join(" ")]
            .some(s => (s || "").toLowerCase().includes(q)));
    }
    function launch(entry) {
        if (!entry) return;
        entry.execute();
        menuWin.launched();
        menuWin.closeRequested();
    }

    // ── пункты страниц ──
    readonly property var mainItems: [
        { label: Story.label("start", "ПРИЗВАТЬ").toUpperCase(), hint: "все программы и поиск", act: () => { menuWin.page = "apps"; menuWin.sel = 0; search.forceActiveFocus(); } },
        { label: "ТЕРМИНАЛ", hint: "kitty", act: () => menuWin.launch(menuWin.app("kitty")) },
        { label: "БРАУЗЕР", hint: "Helium", act: () => menuWin.launch(menuWin.app("helium")) },
        { label: "ФАЙЛЫ", hint: "Nautilus", act: () => menuWin.launch(menuWin.app("org.gnome.Nautilus")) },
        { label: "ИГРЫ", hint: "Steam", act: () => menuWin.launch(menuWin.app("steam")) },
        { label: "НАСТРОЙКИ", hint: "BaphOS", act: () => menuWin.settingsRequested() },
        { label: "ЗАМОК", hint: "заблокировать экран", act: () => { menuWin.closeRequested(); menuWin.lockRequested(); } },
        { label: Story.label("logout", "ПОКИНУТЬ").toUpperCase(), hint: "выход, перезагрузка, выключение", act: () => { menuWin.page = "power"; menuWin.sel = 0; } },
    ]
    property int armed: -1
    readonly property var powerItems: [
        { label: "ВЫЙТИ", hint: "закончить сеанс", cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
        { label: "ПЕРЕЗАГРУЗКА", hint: "заново", cmd: ["systemctl", "reboot"] },
        { label: "ВЫКЛЮЧЕНИЕ", hint: "уснуть", cmd: ["systemctl", "poweroff"] },
        { label: "НАЗАД", hint: "", cmd: null },
    ]
    readonly property var items: page === "power" ? powerItems : mainItems
    function activate(i) {
        if (page === "power") {
            const it = powerItems[i];
            if (!it.cmd) { page = "main"; sel = 7; armed = -1; return; }
            if (armed === i) Quickshell.execDetached(it.cmd); else { armed = i; disarm.restart(); }
            return;
        }
        mainItems[i].act();
    }
    Timer { id: disarm; interval: 3000; onTriggered: menuWin.armed = -1 }

    // ── вид ──
    Item {
        id: root
        anchors.fill: parent
        visible: menuWin.shown
        opacity: Math.min(1, menuWin.t * 3)

        MouseArea { anchors.fill: parent; onClicked: menuWin.closeRequested() }
        Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.72 }

        // огромный бледный сигил
        Image {
            source: Theme.asset("sigil/sigil-128.png")
            width: 768; height: 768; smooth: false
            x: parent.width * 0.42; y: parent.height * 0.08
            opacity: 0.06
            rotation: -12
        }

        // алая полоса наискось, влетает слева
        Item {
            id: band
            width: parent.width * 1.4; height: 300
            x: -parent.width * 0.2 - (1 - menuWin.t) * parent.width
            y: parent.height * 0.5 - 150
            rotation: -14
            Rectangle { anchors.fill: parent; color: Theme.scarlet }
            Image { anchors.fill: parent; source: Theme.asset("ui/halftone.png"); fillMode: Image.Tile; smooth: false; opacity: 0.8 }
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 10; color: Theme.bg }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 18; color: Theme.bg }
        }

        // ── пункты лесенкой ──
        Item {
            id: column
            x: 90; y: parent.height * 0.12
            width: 760; height: parent.height * 0.8
            visible: menuWin.page !== "apps"

            Repeater {
                model: menuWin.items
                Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool cur: menuWin.sel === index
                    readonly property real appear: Math.max(0, Math.min(1, menuWin.t * 2.2 - index * 0.12))
                    width: 640; height: 64
                    x: index * 28 - (1 - appear) * 240 + (cur ? 18 : 0)
                    y: index * 74
                    opacity: appear
                    Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }

                    // рваная клякса за выбранным
                    Shape {
                        visible: row.cur
                        antialiasing: false
                        x: -36; y: -22
                        rotation: (menuWin.tick % 2 ? -2 : 1)
                        ShapePath {
                            fillColor: Theme.scarlet
                            strokeColor: Theme.bg
                            strokeWidth: 4
                            PathPolyline {
                                path: [Qt.point(0, 40), Qt.point(70, 0), Qt.point(120, 30), Qt.point(260, 6), Qt.point(330, 26),
                                       Qt.point(520, 0), Qt.point(560, 34), Qt.point(700, 18), Qt.point(670, 60), Qt.point(720, 92),
                                       Qt.point(560, 104), Qt.point(470, 92), Qt.point(300, 112), Qt.point(150, 96), Qt.point(40, 110),
                                       Qt.point(60, 74), Qt.point(0, 40)]
                            }
                        }
                    }
                    // косая лента
                    Shape {
                        antialiasing: false
                        ShapePath {
                            fillColor: row.cur ? Theme.text : Theme.bg
                            strokeColor: row.cur ? Theme.bg : Theme.text
                            strokeWidth: 3
                            startX: 24; startY: 0
                            PathLine { x: 640; y: 0 }
                            PathLine { x: 616; y: 64 }
                            PathLine { x: 0; y: 64 }
                            PathLine { x: 24; y: 0 }
                        }
                    }
                    Text {
                        x: 44; anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        color: row.cur ? Theme.bg : (menuWin.page === "power" && menuWin.armed === row.index ? Theme.scarlet : Theme.text)
                        font.family: Theme.font; font.pixelSize: 32; font.bold: true
                        renderType: Text.NativeRendering
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 42; verticalCenter: parent.verticalCenter }
                        text: menuWin.page === "power" && menuWin.armed === row.index ? "ТОЧНО? ЕЩЁ РАЗ" : row.modelData.hint
                        color: row.cur ? Theme.blood : Theme.dim
                        font.family: Theme.font; font.pixelSize: 16
                        renderType: Text.NativeRendering
                    }
                    // указатель
                    Text {
                        visible: row.cur
                        x: -30; anchors.verticalCenter: parent.verticalCenter
                        text: "▶"; color: Theme.bg
                        font.family: Theme.font; font.pixelSize: 24
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: menuWin.sel = row.index
                        onClicked: menuWin.activate(row.index)
                    }
                }
            }
        }

        // ── карточка статуса справа ──
        Item {
            id: card
            readonly property real appear: Math.max(0, Math.min(1, menuWin.t * 1.6 - 0.3))
            width: 420; height: 300
            x: parent.width - width - 80 + (1 - appear) * 300
            y: parent.height * 0.14
            opacity: appear
            rotation: 4
            visible: menuWin.page !== "apps"
            Shape {
                antialiasing: false
                ShapePath {
                    fillColor: Theme.text
                    strokeColor: Theme.bg
                    strokeWidth: 4
                    startX: 30; startY: 0
                    PathLine { x: 420; y: 14 }
                    PathLine { x: 396; y: 300 }
                    PathLine { x: 0; y: 284 }
                    PathLine { x: 30; y: 0 }
                }
            }
            Column {
                x: 44; y: 26
                spacing: 6
                Text { id: bigClock; color: Theme.bg; font.family: Theme.font; font.pixelSize: 48; font.bold: true; renderType: Text.NativeRendering }
                Text { id: bigDate; color: Theme.blood; font.family: Theme.font; font.pixelSize: 24; renderType: Text.NativeRendering }
                Rectangle { width: 320; height: 4; color: Theme.scarlet }
                Text { text: (Quickshell.env("USER") ?? "").toUpperCase() + " · " + Story.label("user", "служитель"); color: Theme.bg; font.family: Theme.font; font.pixelSize: 16; renderType: Text.NativeRendering }
                Text { text: Store.data.story && Store.data.effects ? "ЭТАП ЗАРАЖЕНИЯ " + Store.data.storyStage : "СЮЖЕТ СПИТ"; color: Theme.crimson; font.family: Theme.font; font.pixelSize: 16; renderType: Text.NativeRendering }
                Text { text: "BaphOS"; color: Theme.scarlet; font.family: Theme.fontGothic; font.pixelSize: 48; renderType: Text.NativeRendering }
            }
            Timer {
                interval: 1000; repeat: true; running: menuWin.shown; triggeredOnStart: true
                onTriggered: { const d = new Date(); bigClock.text = Qt.formatDateTime(d, "HH:mm"); bigDate.text = Qt.locale("ru_RU").toString(d, "dddd, d MMMM").toUpperCase(); }
            }
        }

        // ── ПРИЗВАТЬ: поиск и все программы ──
        Item {
            id: appsPage
            visible: menuWin.page === "apps"
            x: 90; y: parent.height * 0.1
            width: Math.min(900, parent.width - 180); height: parent.height * 0.78

            Shape {
                antialiasing: false
                ShapePath {
                    fillColor: Theme.text; strokeColor: Theme.bg; strokeWidth: 3
                    startX: 20; startY: 0
                    PathLine { x: 620; y: 0 }
                    PathLine { x: 600; y: 56 }
                    PathLine { x: 0; y: 56 }
                    PathLine { x: 20; y: 0 }
                }
            }
            TextInput {
                id: search
                x: 40; y: 0; width: 540; height: 56
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.bg
                font.family: Theme.font; font.pixelSize: 24; font.bold: true
                renderType: Text.NativeRendering
                onTextChanged: { list.currentIndex = 0; if (text && menuWin.page !== "apps") menuWin.page = "apps"; }
                Keys.onEscapePressed: { if (text) text = ""; else { menuWin.page = "main"; keys.forceActiveFocus(); } }
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onReturnPressed: menuWin.launch(menuWin.apps[list.currentIndex])
                Keys.onEnterPressed: menuWin.launch(menuWin.apps[list.currentIndex])
                Text { visible: !search.text; text: "ЧТО ПРИЗВАТЬ?   ?сеть   >команда"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
            }
            ListView {
                id: list
                y: 80; width: parent.width; height: parent.height - 80
                clip: true
                model: menuWin.apps
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                delegate: Item {
                    id: arow
                    required property var modelData
                    required property int index
                    readonly property bool cur: ListView.isCurrentItem
                    width: 620; height: 40
                    x: (index % 2) * 14 + (cur ? 16 : 0)
                    Behavior on x { NumberAnimation { duration: 80 } }
                    Shape {
                        antialiasing: false
                        ShapePath {
                            fillColor: arow.cur ? Theme.scarlet : Theme.bg
                            strokeColor: arow.cur ? Theme.bg : Theme.text
                            strokeWidth: 2
                            startX: 14; startY: 0
                            PathLine { x: 620; y: 0 }
                            PathLine { x: 606; y: 40 }
                            PathLine { x: 0; y: 40 }
                            PathLine { x: 14; y: 0 }
                        }
                    }
                    Row {
                        x: 30; anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        IconImage { anchors.verticalCenter: parent.verticalCenter; implicitSize: 24; source: Quickshell.iconPath(arow.modelData.icon, "application-x-executable") }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: arow.modelData.name.toUpperCase()
                            color: arow.cur ? Theme.bg : Theme.text
                            font.family: Theme.font; font.pixelSize: 16; font.bold: true
                            renderType: Text.NativeRendering
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = arow.index
                        onClicked: menuWin.launch(arow.modelData)
                    }
                }
            }
        }

        // подсказка снизу
        Text {
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: 90; bottomMargin: Theme.barHeight + 20 }
            text: menuWin.page === "apps" ? "↑↓ выбрать · ENTER призвать · ESC назад" : "↑↓ выбрать · ENTER · ESC закрыть · печатай — поиск"
            color: Theme.dim
            font.family: Theme.font; font.pixelSize: 16
            renderType: Text.NativeRendering
            opacity: menuWin.t
        }
    }

    // клавиатура на главной и в «Покинуть»
    Item {
        id: keys
        focus: menuWin.open && menuWin.page !== "apps"
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) { if (menuWin.page === "power") { menuWin.page = "main"; menuWin.sel = 7; } else menuWin.closeRequested(); }
            else if (e.key === Qt.Key_Down) menuWin.sel = (menuWin.sel + 1) % menuWin.items.length;
            else if (e.key === Qt.Key_Up) menuWin.sel = (menuWin.sel - 1 + menuWin.items.length) % menuWin.items.length;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) menuWin.activate(menuWin.sel);
            else if (e.text && e.text.trim() && menuWin.page === "main") { menuWin.page = "apps"; search.text = e.text; search.forceActiveFocus(); }
            else return;
            e.accepted = true;
        }
    }
}
