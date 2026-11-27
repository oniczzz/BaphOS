// BaphOS: звуки (assets/sounds, синтез art/sounds.py) через pw-play. Выключаются в Алтаре/Настройках.
// Один и тот же звук — не чаще раза в 150 мс (колесо громкости не превращается в пулемёт).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property var last: ({})

    function play(name) {
        if (!Store.data.sounds || Mode.quiet) return;
        const now = Date.now();
        if (now - (root.last[name] || 0) < 150) return;
        root.last[name] = now;
        Quickshell.execDetached(["pw-play", "--volume", "0.55", Theme.asset("sounds/" + name + ".wav")]);
    }
}
