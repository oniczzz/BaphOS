// BaphOS: баннер на весь экран в духе souls-игр — чёрная полоса, крупная надпись медленно
// наплывает, удар. Рисует BannerOverlay (по одному на экран).
//   Banner.show(текст, цвет)             — просто показать
//   Banner.leave("logout"|"reboot"|"poweroff") — показать и потом выполнить
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property string text: ""
    property color color: Theme.scarlet
    property int seq: 0                 // растёт с каждым показом — оверлеи перезапускают анимацию
    property var after: null
    readonly property int duration: 2600

    function enabled() { return Store.data.banners !== false; }
    function show(t, c) {
        if (!enabled()) return;
        root.text = t; root.color = c || Theme.scarlet; root.seq++;
        Sfx.play("slam", 300, 0.7);
    }
    readonly property var leaving: ({
        logout:   ["ТЫ ПОКИНУЛ НАС", ["niri", "msg", "action", "quit", "--skip-confirmation"]],
        reboot:   ["ПЕРЕРОЖДЕНИЕ", ["systemctl", "reboot"]],
        poweroff: ["ТЬМА", ["systemctl", "poweroff"]],
    })
    function leave(kind) {
        const l = leaving[kind];
        if (!l) return;
        if (!enabled()) { Quickshell.execDetached(l[1]); return; }
        show(l[0], Theme.crimson);
        root.after = l[1];
        go.restart();
    }
    Timer { id: go; interval: 1900; onTriggered: { if (root.after) Quickshell.execDetached(root.after); root.after = null; } }
}
