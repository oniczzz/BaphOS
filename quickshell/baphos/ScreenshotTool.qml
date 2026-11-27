// BaphOS: инструмент скриншота (Mod+Shift+S) — по одному на экран, всегда готов (открывается сразу).
//   Экран замирает и темнеет; тянешь область — она светлая, рамка из бегущих «муравьёв», алые уголки,
//   размер; прицел и пиксельная лупа x6 у курсора. Под областью — Копировать / Сохранить / Весь экран / Отмена.
//   Enter — сохранить и скопировать, Ctrl+C — скопировать, Ctrl+S — сохранить, F — весь экран,
//   Esc или правый клик — отмена, двойной клик по области — сохранить и скопировать.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: tool
    required property var modelData
    screen: modelData
    readonly property bool active: Shot.output === modelData.name

    visible: true
    mask: Region { item: tool.active ? area : nothing }
    Item { id: nothing; width: 0; height: 0 }
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-screenshot"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // выделение (в пикселях экрана)
    property real sx: 0; property real sy: 0; property real ex: 0; property real ey: 0
    property bool dragging: false
    property bool selected: false
    property real mx: width / 2; property real my: height / 2
    property int tick: 0
    property real flash: 0
    readonly property real rx: Math.min(sx, ex)
    readonly property real ry: Math.min(sy, ey)
    readonly property real rw: Math.abs(ex - sx)
    readonly property real rh: Math.abs(ey - sy)

    onActiveChanged: {
        if (active) { selected = false; dragging = false; keys.forceActiveFocus(); }
    }
    Timer { interval: 100; repeat: true; running: tool.active; onTriggered: tool.tick++ }

    function finish(mode) {
        if (!selected || rw < 2 || rh < 2) return;
        Shot.take(rx, ry, rw, rh, mode);
        flash = 0.7;
        flashFade.start();
    }
    function selectAll() { sx = 0; sy = 0; ex = width; ey = height; selected = true; }
    Timer {
        id: flashFade
        interval: 40; repeat: true
        onTriggered: { tool.flash = Math.max(0, tool.flash - 0.18); if (tool.flash <= 0) { stop(); Shot.cancel(); } }
    }

    Item {
        anchors.fill: parent
        visible: tool.active

        // замороженный кадр
        Image {
            id: frozen
            anchors.fill: parent
            source: tool.active ? "file://" + Shot.frame + "?" + Shot.nonce : ""
            cache: false
            smooth: false
        }

        // затемнение вокруг области (или всего экрана, пока не выделено)
        readonly property color dim: "#99000000"
        Rectangle { color: parent.dim; x: 0; y: 0; width: parent.width; height: tool.selected || tool.dragging ? tool.ry : parent.height }
        Rectangle { visible: tool.selected || tool.dragging; color: parent.dim; x: 0; y: tool.ry + tool.rh; width: parent.width; height: parent.height - tool.ry - tool.rh }
        Rectangle { visible: tool.selected || tool.dragging; color: parent.dim; x: 0; y: tool.ry; width: tool.rx; height: tool.rh }
        Rectangle { visible: tool.selected || tool.dragging; color: parent.dim; x: tool.rx + tool.rw; y: tool.ry; width: parent.width - tool.rx - tool.rw; height: tool.rh }

        // прицел
        Rectangle { visible: !tool.selected; x: 0; y: Math.round(tool.my); width: parent.width; height: 1; color: Theme.blood }
        Rectangle { visible: !tool.selected; x: Math.round(tool.mx); y: 0; width: 1; height: parent.height; color: Theme.blood }

        // рамка: бегущие муравьи
        Item {
            visible: tool.selected || tool.dragging
            x: tool.rx - 2; y: tool.ry - 2
            width: tool.rw + 4; height: tool.rh + 4
            readonly property int off: (tool.tick * 2) % 16
            Item { x: 0; y: 0; width: parent.width; height: 2; clip: true
                Image { x: -parent.parent.off; width: parent.width + 16; height: 2; source: Theme.asset("ui/ants-h.png"); fillMode: Image.Tile; smooth: false } }
            Item { x: 0; y: parent.height - 2; width: parent.width; height: 2; clip: true
                Image { x: -(16 - parent.parent.off); width: parent.width + 16; height: 2; source: Theme.asset("ui/ants-h.png"); fillMode: Image.Tile; smooth: false } }
            Item { x: 0; y: 0; width: 2; height: parent.height; clip: true
                Image { y: -(16 - parent.parent.off); width: 2; height: parent.height + 16; source: Theme.asset("ui/ants-v.png"); fillMode: Image.Tile; smooth: false } }
            Item { x: parent.width - 2; y: 0; width: 2; height: parent.height; clip: true
                Image { y: -parent.parent.off; width: 2; height: parent.height + 16; source: Theme.asset("ui/ants-v.png"); fillMode: Image.Tile; smooth: false } }
            // алые уголки
            Repeater {
                model: [[0, 0, 1, 1], [1, 0, -1, 1], [0, 1, 1, -1], [1, 1, -1, -1]]
                Item {
                    required property var modelData
                    x: modelData[0] ? parent.width : 0
                    y: modelData[1] ? parent.height : 0
                    Rectangle { x: modelData[2] > 0 ? -4 : -12; y: modelData[3] > 0 ? -4 : 0; width: 16; height: 4; color: Theme.scarlet }
                    Rectangle { x: modelData[2] > 0 ? -4 : 0; y: modelData[3] > 0 ? -4 : -12; width: 4; height: 16; color: Theme.scarlet }
                }
            }
        }

        // размер
        Bevel {
            kind: "well"
            visible: tool.selected || tool.dragging
            x: Math.min(tool.rx, parent.width - width - 4)
            y: tool.ry > 40 ? tool.ry - height - 8 : tool.ry + 8
            width: sizeText.implicitWidth + 16; height: 28
            PixelText { id: sizeText; anchors.centerIn: parent; text: Math.round(tool.rw) + "×" + Math.round(tool.rh); color: Theme.scarlet }
        }

        // пиксельная лупа x6 у курсора
        Bevel {
            id: loupe
            kind: "panel"
            visible: !tool.selected
            width: 156; height: 176
            readonly property int zoom: 6
            x: tool.mx + 28 + width > parent.width ? tool.mx - 28 - width : tool.mx + 28
            y: tool.my + 28 + height > parent.height ? tool.my - 28 - height : tool.my + 28
            Item {
                id: lens
                width: parent.width; height: parent.width
                clip: true
                Image {
                    source: frozen.source
                    cache: false
                    smooth: false
                    width: frozen.width * loupe.zoom; height: frozen.height * loupe.zoom
                    x: -tool.mx * loupe.zoom + lens.width / 2
                    y: -tool.my * loupe.zoom + lens.height / 2
                }
                Rectangle {   // пиксель под курсором
                    anchors.centerIn: parent
                    width: loupe.zoom + 4; height: loupe.zoom + 4
                    color: "transparent"; border.width: 2; border.color: Theme.scarlet
                }
            }
            PixelText {
                anchors { horizontalCenter: parent.horizontalCenter; top: lens.bottom; topMargin: 2 }
                text: Math.round(tool.mx) + ", " + Math.round(tool.my)
                color: Theme.dim; font.pixelSize: 12
            }
        }

        // подсказка сверху
        Bevel {
            kind: "panel"
            visible: !tool.selected && !tool.dragging
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 24 }
            width: hint.implicitWidth + 2 * inset + 16; height: 52
            Row {
                id: hint
                anchors.centerIn: parent
                spacing: 10
                Image { source: Theme.icon("camera", "scarlet"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                PixelText { text: "Выдели область · F — весь экран · Esc — отмена"; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // мышь
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPositionChanged: m => {
                tool.mx = m.x; tool.my = m.y;
                if (tool.dragging) { tool.ex = m.x; tool.ey = m.y; }
            }
            onPressed: m => {
                if (m.button === Qt.RightButton) { Shot.cancel(); return; }
                tool.sx = m.x; tool.sy = m.y; tool.ex = m.x; tool.ey = m.y;
                tool.dragging = true; tool.selected = false;
            }
            onReleased: m => {
                if (m.button !== Qt.LeftButton || !tool.dragging) return;
                tool.dragging = false;
                tool.selected = tool.rw >= 4 && tool.rh >= 4;
            }
            onDoubleClicked: m => {
                if (tool.selected && m.x >= tool.rx && m.x <= tool.rx + tool.rw && m.y >= tool.ry && m.y <= tool.ry + tool.rh)
                    tool.finish("both");
            }
        }

        // панель действий под областью
        Bevel {
            id: bar
            kind: "panel"
            visible: tool.selected
            width: actions.implicitWidth + 2 * inset; height: 58
            x: Math.max(4, Math.min(tool.rx + tool.rw / 2 - width / 2, parent.width - width - 4))
            y: tool.ry + tool.rh + 12 + height < parent.height - Theme.barHeight ? tool.ry + tool.rh + 12
             : Math.max(4, tool.ry - height - 12)
            Row {
                id: actions
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: [["copy", "Копировать", "copy"], ["save", "Сохранить", "both"], ["scale", "Весь экран", "all"], ["close", "Отмена", "cancel"]]
                    PixelButton {
                        id: act
                        required property var modelData
                        width: actRow.implicitWidth + 18; height: 36
                        onClicked: {
                            if (modelData[2] === "cancel") Shot.cancel();
                            else if (modelData[2] === "all") tool.selectAll();
                            else tool.finish(modelData[2]);
                        }
                        Row {
                            id: actRow
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: act.down ? 1 : 0
                            spacing: 6
                            Image { source: Theme.icon(act.modelData[0], act.hovered ? "scarlet" : "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                            PixelText { text: act.modelData[1]; color: act.hovered ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }

        // вспышка после снимка
        Rectangle { anchors.fill: parent; color: "#ffffff"; opacity: tool.flash; visible: tool.flash > 0 }
    }

    // клавиши
    Item {
        id: keys
        focus: tool.active
        Keys.onPressed: e => {
            if (!tool.active) return;
            if (e.key === Qt.Key_Escape) Shot.cancel();
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) tool.finish("both");
            else if (e.key === Qt.Key_F) tool.selectAll();
            else if (e.key === Qt.Key_C && (e.modifiers & Qt.ControlModifier)) tool.finish("copy");
            else if (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier)) tool.finish("both");
            else return;
            e.accepted = true;
        }
    }
}
