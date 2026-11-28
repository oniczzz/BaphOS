// BaphOS: сервер уведомлений. Всплывают как диалог из пиксельной RPG — внизу по центру, над панелью:
//   слева портрет (иконка приложения), сверху табличка с именем, текст печатается по букве с блипом,
//   в конце мигает ▼. Уведомления идут очередью, по одному; справа снизу — сколько ещё ждут.
//   Клик: пока печатает — допечатать сразу; потом — действие по умолчанию и следующее.
//   Правый клик — убрать это. Critical не уходят сами.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root
    property var screen: Quickshell.screens[0]
    property var queue: []
    readonly property var cur: queue.length ? queue[0] : null

    function remove(n) { queue = queue.filter(p => p !== n); }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            Inbox.add(n.appName, n.summary, n.body);
            if ((Store.data.dnd || Mode.quiet) && n.urgency !== NotificationUrgency.Critical) return;   // «Не беспокоить» / игра
            n.tracked = true;
            n.closed.connect(() => root.remove(n));
            root.queue = root.queue.concat([n]).slice(-6);
        }
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: root.cur !== null
        anchors { bottom: true }
        margins { bottom: Theme.barHeight + 14 }
        implicitWidth: Math.min(860, (root.screen?.width ?? 1366) - 120)
        implicitHeight: 168
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "baphos-notifications"

        // ── печать ──
        readonly property string summary: root.cur ? (root.cur.summary || "") : ""
        readonly property string body: root.cur ? (root.cur.body || "").replace(/\s+/g, " ").trim() : ""
        readonly property int total: summary.length + body.length
        property int typed: 0
        readonly property bool done: typed >= total
        readonly property bool critical: root.cur ? root.cur.urgency === NotificationUrgency.Critical : false
        property real pop: 0

        Connections {
            target: root
            function onCurChanged() {
                win.typed = 0;
                if (root.cur) {
                    Sfx.play("bell", 150, 0.35);
                    win.pop = 0; popAnim.restart();
                    typer.restart();
                }
            }
        }
        NumberAnimation { id: popAnim; target: win; property: "pop"; from: 0; to: 1; duration: 160; easing.type: Easing.OutBack }
        Timer {
            id: typer
            interval: 26; repeat: true
            running: root.cur !== null && !win.done
            onTriggered: {
                // в спокойном режиме и без анимаций — сразу целиком
                if (!Store.data.animations || Mode.calm) { win.typed = win.total; return; }
                win.typed = Math.min(win.total, win.typed + 1);
                const all = win.summary + win.body;
                const ch = all.charAt(win.typed - 1);
                if (ch.trim() && win.typed % 2 === 0) Sfx.play("talk", 50, 0.4);
            }
        }
        // дочитано — подождать и показать следующее
        Timer {
            running: root.cur !== null && win.done && !win.critical && !area.containsMouse
            interval: root.cur && root.cur.expireTimeout > 0 ? root.cur.expireTimeout : 3500 + win.total * 25
            onTriggered: if (root.cur) root.cur.expire()
        }
        property int blink: 0
        Timer { interval: 400; repeat: true; running: win.visible && win.done; onTriggered: win.blink++ }

        Item {
            id: box
            width: parent.width; height: parent.height
            y: (1 - win.pop) * 30
            opacity: Math.min(1, win.pop * 2)

            // рамка диалога: кость снаружи, алая жилка внутри
            Rectangle {
                id: frame
                anchors { fill: parent; topMargin: 18 }
                color: Theme.bg
                border.width: 4; border.color: win.critical ? Theme.scarlet : Theme.text
                Rectangle {
                    anchors { fill: parent; margins: 8 }
                    color: "transparent"
                    border.width: 2; border.color: Theme.blood
                }
            }

            // портрет
            Rectangle {
                id: portrait
                x: 20; y: 36
                width: 112; height: 112
                color: Theme.coal
                border.width: 2; border.color: Theme.crimson
                Image {
                    anchors.centerIn: parent
                    width: 96; height: 96
                    smooth: false; mipmap: false
                    sourceSize: Qt.size(48, 48)          // маленькая иконка, растянутая крупными пикселями
                    source: !root.cur ? "" : (root.cur.image || (root.cur.appIcon ? Quickshell.iconPath(root.cur.appIcon, true) : "")
                            || Quickshell.iconPath((root.cur.appName || "").toLowerCase(), true) || Theme.asset("sigil/sigil-64.png"))
                }
            }

            // табличка с именем
            Rectangle {
                x: 150; y: 0
                width: nameText.implicitWidth + 28; height: 36
                color: Theme.bg
                border.width: 4; border.color: win.critical ? Theme.scarlet : Theme.text
                Text {
                    id: nameText
                    anchors.centerIn: parent
                    text: (root.cur?.appName || "Неизвестный").toUpperCase()
                    color: Theme.scarlet
                    font.family: Theme.font; font.pixelSize: 16; font.bold: true
                    renderType: Text.NativeRendering
                }
            }

            // текст
            Column {
                x: 152; y: 46
                width: parent.width - 152 - 30
                spacing: 6
                Text {
                    width: parent.width
                    text: "* " + win.summary.slice(0, win.typed)
                    color: win.critical ? Theme.scarlet : Theme.text
                    font.family: Theme.font; font.pixelSize: 24; font.bold: true
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
                Text {
                    width: parent.width
                    text: win.body.slice(0, Math.max(0, win.typed - win.summary.length))
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: 16
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }

            // ▼ и очередь
            Text {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 22; bottomMargin: 14 }
                text: (root.queue.length > 1 ? "ещё " + (root.queue.length - 1) + "  " : "") + (win.blink % 2 ? " " : "▼")
                visible: win.done
                color: Theme.scarlet
                font.family: Theme.font; font.pixelSize: 16
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: area
                anchors.fill: frame
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    const n = root.cur;
                    if (!n) return;
                    if (mouse.button === Qt.RightButton) { n.dismiss(); return; }
                    if (!win.done) { win.typed = win.total; return; }
                    const def = n.actions.find(a => a.identifier === "default");
                    if (def) def.invoke();
                    n.dismiss();
                }
            }
        }
    }
}
