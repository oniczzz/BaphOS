// BaphOS: история уведомлений за сессию (последние 30) — её показывает «Алтарь».
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property var items: []        // [{ app, summary, body, time }] — новые сверху

    function add(app, summary, body) {
        root.items = [{ app: app || "", summary: summary || "", body: body || "",
                        time: Qt.formatDateTime(new Date(), "HH:mm") }].concat(root.items).slice(0, 30);
    }
    function clear() { root.items = []; }
}
