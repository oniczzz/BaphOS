// BaphOS: сервер уведомлений и всплывашки справа снизу, над панелью.
// Клик — основное действие (или закрыть), правый клик — закрыть. Critical не исчезают сами.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

Scope {
    id: root
    property var screen: Quickshell.screens[0]
    property var popups: []          // показанные сейчас

    function remove(n) { popups = popups.filter(p => p !== n) }

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
            Sfx.play("bell");
            n.tracked = true;
            n.closed.connect(() => root.remove(n));
            root.popups = [n].concat(root.popups).slice(0, 5);
        }
    }

    PanelWindow {
        screen: root.screen
        visible: root.popups.length > 0
        anchors { bottom: true; right: true }
        margins { bottom: Theme.barHeight + 6; right: 6 }
        implicitWidth: 340
        implicitHeight: column.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "baphos-notifications"

        Column {
            id: column
            width: parent.width
            spacing: 6
            Repeater {
                model: root.popups
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    width: column.width
                    implicitHeight: content.implicitHeight + 16
                    color: Theme.bg
                    border.width: Theme.border
                    border.color: critical ? Theme.scarlet : (area.containsMouse ? Theme.blood : Theme.dried)

                    Timer {
                        running: !card.critical && !area.containsMouse
                        interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
                        onTriggered: card.modelData.expire()
                    }

                    Row {
                        id: content
                        x: 8; y: 8
                        width: parent.width - 16
                        spacing: 8
                        IconImage {
                            implicitSize: 32
                            visible: source != ""
                            source: card.modelData.image || (card.modelData.appIcon ? Quickshell.iconPath(card.modelData.appIcon, true) : "")
                        }
                        Column {
                            width: parent.width - 40
                            spacing: 2
                            PixelText {
                                width: parent.width
                                text: card.modelData.appName || ""
                                color: Theme.dim
                                visible: text !== ""
                            }
                            PixelText {
                                width: parent.width
                                text: card.modelData.summary
                                color: card.critical ? Theme.scarlet : Theme.text
                                font.bold: true
                            }
                            PixelText {
                                width: parent.width
                                text: card.modelData.body
                                visible: text !== ""
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                color: Theme.text
                            }
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            const def = card.modelData.actions.find(a => a.identifier === "default");
                            if (mouse.button === Qt.LeftButton && def) def.invoke();
                            else card.modelData.dismiss();
                        }
                    }
                }
            }
        }
    }
}
