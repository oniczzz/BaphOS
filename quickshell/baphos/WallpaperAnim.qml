// BaphOS: «живые» обои. Картинка статична, поверх оживают мелкие спрайты по данным генератора
// (<сцена>-<ШxВ>.json): звёзды мерцают, пламя свечей дрожит, глаза моргают, розетка пульсирует,
// пролетают мыши и вороны, на «Сигиле» проскакивает глитч. Один таймер на 8 тиков в секунду —
// как в пиксельных играх; анимации выключены — таймер стоит и пламя замирает на первом кадре.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: anim
    property string jsonPath: ""
    property bool running: true
    property var info: ({})
    property int tick: 0
    readonly property int px: info.scale || 4

    FileView {
        path: anim.jsonPath
        onLoaded: { try { anim.info = JSON.parse(text()); } catch (e) { anim.info = {}; } }
        onLoadFailed: anim.info = {}
    }

    Timer {
        interval: 125
        repeat: true
        running: anim.running && anim.visible
        onTriggered: {
            anim.tick++;
            // звёзды: пара случайных за тик
            for (let i = 0; i < 2 && stars.count; i++) stars.itemAt(Math.floor(Math.random() * stars.count))?.toggle();
            // пламя: каждый тик свой кадр
            for (let i = 0; i < flames.count; i++) { const f = flames.itemAt(i); if (f) f.frame = Math.floor(Math.random() * 4); }
            // глаза: моргание (культисты парами) и появление/исчезновение в лесу
            for (let i = 0; i < eyes.count; i++) eyes.itemAt(i)?.step();
            if (eyes.count && Math.random() < 1 / 30) {
                const k = Math.floor(Math.random() * eyes.count);
                eyes.itemAt(k)?.closeFor(2);
                eyes.itemAt(k ^ 1)?.closeFor(2);
            }
            flier.step();
            glitch.step();
        }
    }

    // ── звёзды ──
    Repeater {
        id: stars
        model: anim.info.stars || []
        Rectangle {
            required property var modelData
            property bool dimmed: false
            function toggle() { dimmed = !dimmed }
            x: modelData[0]; y: modelData[1]
            width: anim.px; height: anim.px
            color: "#262020"
            visible: dimmed
        }
    }

    // ── пламя свечей ──
    Repeater {
        id: flames
        model: anim.info.flames || []
        Image {
            required property var modelData
            property int frame: 0
            x: modelData[0]; y: modelData[1]
            source: Theme.asset("wallpapers/anim/flame-" + frame + ".png")
            smooth: false
        }
    }

    // ── глаза: закрытие = чёрная заплатка ──
    Repeater {
        id: eyes
        model: anim.info.eyes || []
        Rectangle {
            required property var modelData
            required property int index
            property int closed: 0
            readonly property bool lone: modelData[3] <= anim.px   // глаза в лесу (полоска 1 px)
            function closeFor(t) { closed = Math.max(closed, t) }
            function step() {
                if (closed > 0) closed--;
                else if (lone && Math.random() < 1 / 120) closed = 16 + Math.floor(Math.random() * 40);
            }
            x: modelData[0]; y: modelData[1]
            width: modelData[2]; height: modelData[3]
            color: "#000000"
            visible: closed > 0
        }
    }

    // ── пульс розетки собора: ступенчатое затемнение ──
    Repeater {
        model: anim.info.pulse || []
        Rectangle {
            required property var modelData
            x: modelData[0]; y: modelData[1]
            width: modelData[2]; height: modelData[3]
            color: "#000000"
            readonly property int phase: anim.tick % 16
            opacity: [0, 0.12, 0.25, 0.38, 0.5, 0.38, 0.25, 0.12][phase < 8 ? phase : 15 - phase] || 0
        }
    }

    // ── пролетающие: мышь (луна) или ворон (собор) ──
    Image {
        id: flier
        property bool flying: false
        property int dir: 1
        readonly property var cfg: anim.info.fliers || []
        visible: flying
        smooth: false
        source: cfg.length ? Theme.asset("wallpapers/anim/" + cfg[0] + "-" + (anim.tick % 2) + ".png") : ""
        mirror: dir < 0
        function step() {
            if (!cfg.length) return;
            if (!flying) {
                if (Math.random() < 1 / 320) {
                    dir = Math.random() < 0.5 ? 1 : -1;
                    x = dir > 0 ? -width : anim.width;
                    y = cfg[1] + Math.floor(Math.random() * Math.max(1, cfg[2] - cfg[1]) / anim.px) * anim.px;
                    flying = true;
                }
                return;
            }
            x += dir * anim.px * 3;
            if (anim.tick % 3 === 0) y += (Math.random() < 0.5 ? -1 : 1) * anim.px;
            if (x < -width * 2 || x > anim.width + width) flying = false;
        }
    }

    // ── глитч «Сигила»: на пару тиков рваные полосы ──
    Item {
        id: glitch
        anchors.fill: parent
        property int ticksLeft: 0
        visible: ticksLeft > 0
        function step() {
            if (!anim.info.glitch) return;
            if (ticksLeft > 0) { ticksLeft--; reroll(); }
            else if (Math.random() < 1 / 70) { ticksLeft = 2; reroll(); }
        }
        function reroll() {
            for (let i = 0; i < bars.count; i++) {
                const b = bars.itemAt(i);
                if (!b) continue;
                b.y = Math.floor(Math.random() * anim.height / anim.px) * anim.px;
                b.height = anim.px * (1 + Math.floor(Math.random() * 4));
                b.x = Math.floor(Math.random() * anim.width / 3);
                b.width = anim.width / 3 + Math.random() * anim.width / 2;
                b.color = ["#ff1a1a", "#000000", "#6b0000"][i % 3];
            }
        }
        Repeater {
            id: bars
            model: 5
            Rectangle { opacity: 0.85 }
        }
    }
}
