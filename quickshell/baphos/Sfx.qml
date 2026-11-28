// BaphOS: звуки (assets/sounds, синтез art/sounds.py) через pw-play. Выключаются в Алтаре/Настройках.
// Один и тот же звук — не чаще раза в 150 мс (колесо громкости не превращается в пулемёт).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property var last: ({})

    // gap — минимум мс между одинаковыми звуками; volume — громкость 0..1
    function play(name, gap, volume) {
        if (!Store.data.sounds || Mode.quiet) return;
        const now = Date.now();
        if (now - (root.last[name] || 0) < (gap ?? 150)) return;
        root.last[name] = now;
        Quickshell.execDetached(["pw-play", "--volume", String(volume ?? 0.55), Theme.asset("sounds/" + name + ".wav")]);
    }
}
