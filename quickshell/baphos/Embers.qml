// BaphOS: тлеющие угли над панелью задач — иногда от её кромки поднимаются пиксельные искры
// и гаснут ступенями (алая → багровая → кровь). Слой над окнами, клики проходят насквозь.
// 8 тиков в секунду, только когда включены анимации.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: em
    required property var modelData
    screen: modelData
    visible: Store.data.animations && !Mode.quiet
    anchors { bottom: true; left: true; right: true }
    margins { bottom: Theme.barHeight - 6 }
    implicitHeight: 140
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "baphos-embers"
    mask: Region { item: nothing }
    Item { id: nothing; width: 0; height: 0 }

    readonly property var shades: ["#ffd8a0", "#ff5040", "#ff1a1a", "#a00000", "#6b0000", "#3a0000"]

    Timer {
        interval: 125
        repeat: true
        running: em.visible
        onTriggered: {
            for (let i = 0; i < sparks.count; i++) {
                const s = sparks.itemAt(i);
                if (!s) continue;
                if (s.life > 0) {
                    s.life--;
                    s.y -= 4;
                    if (Math.random() < 0.4) s.x += (Math.random() < 0.5 ? -2 : 2);
                } else if (Math.random() < 0.012) {
                    s.x = Math.floor(Math.random() * em.width / 2) * 2;
                    s.y = em.height - 4;
                    s.life = 10 + Math.floor(Math.random() * 14);
                    s.max = s.life;
                }
            }
        }
    }

    Repeater {
        id: sparks
        model: 14
        Rectangle {
            property int life: 0
            property int max: 1
            visible: life > 0
            width: life > max * 0.6 ? 4 : 2
            height: width
            color: em.shades[Math.min(em.shades.length - 1, Math.floor((1 - life / max) * em.shades.length))]
        }
    }
}
