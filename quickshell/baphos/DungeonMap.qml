// BaphOS: «карта подвала» (Mod+Tab) — переключатель окон в духе карты из roguelike-подземелий.
//   Каждый монитор — этаж, его рабочие столы — комнаты по коридору, окна — предметы в комнатах.
//   Где ты сейчас — комната светится; пустой стол — неисследованная «?»; стол со свёрнутыми — тайник.
//   Внизу табличка «подобранного предмета»: программа и заголовок окна.
//   ←/→ комната, ↑/↓ этаж, Tab / Shift+Tab — следующее/предыдущее окно, Enter — туда, Esc — закрыть.
//   Мышь: клик по предмету или комнате. При открытии выбрано предыдущее окно (как Alt+Tab).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: map
    required property var modelData
    property bool open: false
    signal closeRequested()
    screen: modelData

    property bool shown: false
    property real t: 0
    property int blink: 0

    visible: true
    mask: Region { item: map.shown ? root : nothing }
    Item { id: nothing; width: 0; height: 0 }
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-map"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── модель: этажи (мониторы слева направо) → комнаты (столы) → предметы (окна) ──
    function ts(w) { const f = w.focus_timestamp; return f ? (f.secs || 0) * 1e9 + (f.nanos || 0) : 0; }
    function winOrder(a, b) {
        const pa = a.layout?.pos_in_scrolling_layout, pb = b.layout?.pos_in_scrolling_layout;
        if (pa && pb) return pa[0] - pb[0] || pa[1] - pb[1];
        return a.id - b.id;
    }
    property var floors: []
    function rebuild() {
        const outs = [...new Set(Niri.workspaces.map(w => w.output))];
        const xOf = o => (Quickshell.screens.find(s => s.name === o)?.x ?? 0);
        outs.sort((a, b) => xOf(a) - xOf(b));
        floors = outs.map(o => ({
            output: o,
            rooms: Niri.workspaces.filter(w => w.output === o).sort((a, b) => a.idx - b.idx).map(w => {
                const wins = Niri.windows.filter(x => x.workspace_id === w.id).sort(winOrder);
                return { ws: w, wins: wins, stash: wins.length > 0 && wins.every(x => Niri.minimized.includes(x.id)) };
            }),
        }));
    }
    readonly property var allWins: {
        const out = [];
        for (const f of floors) for (const r of f.rooms) for (const w of r.wins) out.push({ w: w, ws: r.ws.id });
        return out;
    }

    property int selWs: -1          // id стола
    property int selWin: -1         // id окна (-1 — комната без предмета)
    readonly property var selWindow: Niri.windows.find(w => w.id === selWin) || null

    function pick(wsId, winId) {
        if (wsId !== selWs) Sfx.play("step", 60, 0.5);
        selWs = wsId; selWin = winId;
    }
    function roomOf(wsId) {
        for (let f = 0; f < floors.length; f++)
            for (let r = 0; r < floors[f].rooms.length; r++)
                if (floors[f].rooms[r].ws.id === wsId) return [f, r];
        return [0, 0];
    }
    function enterRoom(f, r) {
        const room = floors[f]?.rooms[r];
        if (!room) return;
        const act = room.wins.find(x => x.id === room.ws.active_window_id) || room.wins[0];
        pick(room.ws.id, act ? act.id : -1);
    }
    function moveRoom(d) {
        const [f, r] = roomOf(selWs);
        enterRoom(f, Math.max(0, Math.min(floors[f].rooms.length - 1, r + d)));
    }
    function moveFloor(d) {
        const [f, r] = roomOf(selWs);
        const nf = Math.max(0, Math.min(floors.length - 1, f + d));
        enterRoom(nf, Math.min(r, floors[nf].rooms.length - 1));
    }
    function cycle(d) {
        const list = allWins;
        if (!list.length) return;
        let i = list.findIndex(x => x.w.id === selWin);
        i = (i + d + list.length) % list.length;
        pick(list[i].ws, list[i].w.id);
    }
    function go() {
        const room = floors.flatMap(f => f.rooms).find(r => r.ws.id === selWs);
        if (selWin >= 0) Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(selWin)]);
        else if (room) Niri.focusWorkspace(room.ws.output, room.ws.idx);
        closeRequested();
    }

    onOpenChanged: {
        if (open) {
            rebuild();
            // по умолчанию — предыдущее окно (самое недавнее, кроме текущего)
            const byTime = Niri.windows.filter(w => !w.is_focused).sort((a, b) => ts(b) - ts(a));
            const prev = byTime[0] || Niri.windows.find(w => w.is_focused);
            if (prev) { selWs = prev.workspace_id; selWin = prev.id; }
            else { const cur = Niri.workspaces.find(w => w.is_focused); selWs = cur ? cur.id : -1; selWin = -1; }
            shown = true;
            if (Store.data.animations && !Mode.calm) { t = 0; showAnim.restart(); } else t = 1;
            keys.forceActiveFocus();
        } else {
            if (Store.data.animations && !Mode.calm) hideAnim.restart(); else { t = 0; shown = false; }
        }
    }
    NumberAnimation { id: showAnim; target: map; property: "t"; from: 0; to: 1; duration: 300 }
    NumberAnimation { id: hideAnim; target: map; property: "t"; to: 0; duration: 120; onFinished: map.shown = false }
    Timer { interval: 350; repeat: true; running: map.shown; onTriggered: map.blink++ }
    // окна открылись/закрылись, пока карта открыта
    Connections {
        target: Niri
        enabled: map.shown
        function onWindowsChanged() { map.rebuild(); }
        function onWorkspacesChanged() { map.rebuild(); }
    }

    readonly property int roomW: 150
    readonly property int roomH: 108
    readonly property int hall: 34
    readonly property int floorGap: 64

    Item {
        id: root
        anchors.fill: parent
        visible: map.shown
        opacity: Math.min(1, map.t * 2)

        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.93 }
        MouseArea { anchors.fill: parent; onClicked: map.closeRequested() }

        Column {
            anchors.centerIn: parent
            spacing: 22

            // заголовок
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Image { source: Theme.asset("sigil/sigil-32.png"); width: 32; height: 32; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "КАРТА ПОДВАЛА"; color: Theme.scarlet; font.family: Theme.font; font.pixelSize: 32; font.bold: true; renderType: Text.NativeRendering }
                Image { source: Theme.asset("sigil/sigil-32.png"); width: 32; height: 32; smooth: false; anchors.verticalCenter: parent.verticalCenter }
            }

            // этажи
            Column {
                id: floorsCol
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: map.floorGap
                Repeater {
                    model: map.floors
                    Row {
                        id: floorRow
                        required property var modelData
                        required property int index
                        spacing: 16
                        // подпись этажа
                        Column {
                            width: 120
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "ЭТАЖ " + (floorRow.index + 1); color: Theme.text; font.family: Theme.font; font.pixelSize: 16; font.bold: true; renderType: Text.NativeRendering }
                            Text { text: floorRow.modelData.output; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; renderType: Text.NativeRendering }
                        }
                        Row {
                            spacing: map.hall
                            Repeater {
                                model: floorRow.modelData.rooms
                                Item {
                                    id: room
                                    required property var modelData
                                    required property int index
                                    readonly property var ws: modelData.ws
                                    readonly property bool here: ws.is_focused
                                    readonly property bool sel: map.selWs === ws.id
                                    readonly property bool empty: modelData.wins.length === 0
                                    // комнаты проявляются по очереди, ступенями
                                    readonly property real appear: Math.max(0, Math.min(1, map.t * 3 - (floorRow.index * 4 + index) * 0.15))
                                    width: map.roomW; height: map.roomH
                                    scale: Math.round(appear * 4) / 4
                                    opacity: appear > 0 ? 1 : 0

                                    // коридор к следующей комнате
                                    Rectangle {
                                        visible: room.index < floorRow.modelData.rooms.length - 1
                                        x: parent.width; y: parent.height / 2 - 7
                                        width: map.hall; height: 14
                                        color: Theme.coal
                                        border.width: 2; border.color: Theme.dried
                                    }
                                    // лестница вниз на следующий этаж (из первой комнаты)
                                    Rectangle {
                                        visible: room.index === 0 && floorRow.index < map.floors.length - 1
                                        x: parent.width / 2 - 7; y: parent.height
                                        width: 14; height: map.floorGap
                                        color: Theme.coal
                                        border.width: 2; border.color: Theme.dried
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: room.here ? Theme.blood : room.empty ? "#050303" : Theme.coal
                                        border.width: room.sel ? 4 : 3
                                        border.color: room.sel ? (map.blink % 2 ? Theme.scarlet : Theme.text)
                                                    : room.modelData.stash ? Theme.crimson
                                                    : room.empty ? Theme.dried : room.ws.is_active ? Theme.text : Theme.dim
                                        // пол — шахматка тёмных плит
                                        Grid {
                                            anchors { fill: parent; margins: 6 }
                                            columns: 6
                                            opacity: room.empty ? 0.25 : 0.5
                                            Repeater {
                                                model: 24
                                                Rectangle {
                                                    required property int index
                                                    width: (map.roomW - 12) / 6; height: (map.roomH - 12) / 4
                                                    color: (index + Math.floor(index / 6)) % 2 ? "transparent" : Theme.bgAlt
                                                }
                                            }
                                        }
                                    }
                                    // номер комнаты
                                    Text {
                                        x: 7; y: 4
                                        text: room.modelData.stash ? "тайник" : String(room.ws.idx)
                                        color: room.here ? Theme.text : Theme.dim
                                        font.family: Theme.font; font.pixelSize: 12
                                        renderType: Text.NativeRendering
                                    }
                                    Text {
                                        visible: room.empty
                                        anchors.centerIn: parent
                                        text: "?"; color: Theme.dried
                                        font.family: Theme.font; font.pixelSize: 32; font.bold: true
                                        renderType: Text.NativeRendering
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: { map.pick(room.ws.id, -1); map.go(); }
                                    }
                                    // предметы: до 6 иконок, дальше «+N»
                                    Grid {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: 6
                                        columns: 3; spacing: 8
                                        Repeater {
                                            model: room.modelData.wins.slice(0, room.modelData.wins.length > 6 ? 5 : 6)
                                            Item {
                                                id: item
                                                required property var modelData
                                                readonly property bool cur: map.selWin === modelData.id
                                                readonly property var entry: DesktopEntries.heuristicLookup(modelData.app_id)
                                                width: 36; height: 36
                                                // пьедестал под выбранным предметом
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: item.cur ? Theme.scarlet : "transparent"
                                                    opacity: item.cur ? 0.35 : 0
                                                }
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.width: 2
                                                    border.color: item.cur ? Theme.scarlet : "transparent"
                                                }
                                                IconImage {
                                                    anchors.centerIn: parent
                                                    // выбранный предмет «парит»
                                                    anchors.verticalCenterOffset: item.cur && map.blink % 2 ? -2 : 0
                                                    implicitSize: 28
                                                    source: Quickshell.iconPath(item.entry?.icon ?? item.modelData.app_id, "application-x-executable")
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onEntered: map.pick(room.ws.id, item.modelData.id)
                                                    onClicked: { map.pick(room.ws.id, item.modelData.id); map.go(); }
                                                }
                                            }
                                        }
                                        Text {
                                            visible: room.modelData.wins.length > 6
                                            width: 36; height: 36
                                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                            text: "+" + (room.modelData.wins.length - 5)
                                            color: Theme.text; font.family: Theme.font; font.pixelSize: 16
                                            renderType: Text.NativeRendering
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // табличка «подобран предмет»
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(520, pickupCol.implicitWidth + 60); height: 92
                color: Theme.bg
                border.width: 3; border.color: Theme.text
                Rectangle { anchors { fill: parent; margins: 6 } color: "transparent"; border.width: 2; border.color: Theme.blood }
                Column {
                    id: pickupCol
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: map.selWindow
                              ? (DesktopEntries.heuristicLookup(map.selWindow.app_id)?.name ?? map.selWindow.app_id ?? "?").toUpperCase()
                              : "ПУСТАЯ КОМНАТА"
                        color: Theme.scarlet
                        font.family: Theme.font; font.pixelSize: 32; font.bold: true
                        renderType: Text.NativeRendering
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, map.width * 0.6)
                        elide: Text.ElideRight
                        text: map.selWindow ? (map.selWindow.title || "") : "здесь пока никто не живёт"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: 16
                        renderType: Text.NativeRendering
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "←→ комната · ↑↓ этаж · TAB предмет · ENTER войти · ESC уйти"
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: 16
                renderType: Text.NativeRendering
            }
        }
    }

    Item {
        id: keys
        focus: map.open
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) map.closeRequested();
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_A) map.moveRoom(-1);
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_D) map.moveRoom(1);
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_W) map.moveFloor(-1);
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_S) map.moveFloor(1);
            else if (e.key === Qt.Key_Backtab || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier))) map.cycle(-1);
            else if (e.key === Qt.Key_Tab) map.cycle(1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) map.go();
            else return;
            e.accepted = true;
        }
    }
}
