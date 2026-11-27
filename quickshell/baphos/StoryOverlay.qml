// BaphOS: слой сюжета поверх всего (Overlay), никогда не ловит клики (пустая маска):
// глитчи, интро «СИГНАЛ ПОЛУЧЕН», шёпот культа сверху, ягнёнок в короне над панелью задач.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: ov
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-story"
    mask: Region { item: nothing }
    Item { id: nothing; width: 0; height: 0 }

    Connections {
        target: Story
        function onGlitch(strength) { glitch.burst(strength) }
        function onWhisper(text) { whisper.show(text) }
        function onIntro() { intro.play() }
        function onLambWalk() { lamb.walk() }
    }

    // ── глитч: рваные полосы, у сильного — алая вспышка ──
    Item {
        id: glitch
        anchors.fill: parent
        property int ticksLeft: 0
        property int power: 1
        visible: ticksLeft > 0
        function burst(p) { power = p; ticksLeft = 3 + p * 3; reroll(); ticker.start(); }
        function reroll() {
            for (let i = 0; i < bars.count; i++) {
                const b = bars.itemAt(i);
                if (!b) continue;
                b.visible = i < 4 + power * 4;
                b.y = Math.floor(Math.random() * height / 4) * 4;
                b.height = 4 * (1 + Math.floor(Math.random() * (2 + power * 3)));
                b.x = Math.floor(Math.random() * width * 0.6);
                b.width = width * (0.15 + Math.random() * 0.6);
                b.color = ["#ff1a1a", "#000000", "#6b0000", "#d8d8d8"][Math.floor(Math.random() * (power > 2 ? 4 : 3))];
            }
        }
        Timer {
            id: ticker
            interval: 60; repeat: true
            onTriggered: { glitch.ticksLeft--; if (glitch.ticksLeft <= 0) stop(); else glitch.reroll(); }
        }
        Rectangle { anchors.fill: parent; color: Theme.scarlet; opacity: glitch.power >= 3 && glitch.ticksLeft % 2 ? 0.12 : 0 }
        Repeater { id: bars; model: 16; Rectangle { opacity: 0.9 } }
    }

    // ── интро: вирус «загружается» ──
    Rectangle {
        id: intro
        anchors.fill: parent
        color: "#000000"
        opacity: 0.88
        visible: false
        property string full: "СИГНАЛ ПОЛУЧЕН\n\n> baphomet.exe ........ загружен\n> печати сняты ......... 3 из 3\n> добро пожаловать домой"
        property int n: 0
        function play() { n = 0; visible = true; typer.start(); glitch.burst(3); }
        Text {
            anchors.centerIn: parent
            text: intro.full.slice(0, intro.n) + (intro.n % 2 ? "█" : "")
            color: Theme.scarlet
            font.family: Theme.fontNum; font.pixelSize: 16
            renderType: Text.NativeRendering
            lineHeight: 1.6
        }
        Timer {
            id: typer
            interval: 45; repeat: true
            onTriggered: {
                intro.n++;
                if (intro.n === 14 || intro.n === 60) glitch.burst(2);
                if (intro.n > intro.full.length + 40) { stop(); intro.visible = false; }
            }
        }
    }

    // ── шёпот культа: сверху, печатается по буквам ──
    Bevel {
        id: whisper
        kind: "panel"
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 24 }
        width: Math.max(360, msg.implicitWidth + 2 * inset + 24)
        height: 56
        visible: false
        property string full: ""
        property int n: 0
        function show(t) { full = t; n = 0; visible = true; wtyper.start(); hide.restart(); }
        Row {
            anchors.centerIn: parent
            spacing: 10
            Image { source: Theme.asset("sigil/sigil-32.png"); width: 32; height: 32; smooth: false; anchors.verticalCenter: parent.verticalCenter }
            PixelText { id: msg; text: whisper.full.slice(0, whisper.n); color: Theme.scarlet; anchors.verticalCenter: parent.verticalCenter }
        }
        Timer { id: wtyper; interval: 40; repeat: true; onTriggered: { whisper.n++; if (whisper.n >= whisper.full.length) stop(); } }
        Timer { id: hide; interval: 7000; onTriggered: whisper.visible = false }
    }

    // ── Агнец в красной короне гуляет над панелью задач ──
    Image {
        id: lamb
        property bool walking: false
        property int frame: 0
        visible: walking
        y: ov.height - Theme.barHeight - height + 4
        source: Theme.asset("story/lamb-" + frame + ".png")
        smooth: false
        function walk() { x = -width; walking = true; stepper.start(); }
        Timer {
            id: stepper
            interval: 120; repeat: true
            onTriggered: {
                lamb.frame = 1 - lamb.frame;
                lamb.x += 6;
                if (lamb.x > ov.width) { stop(); lamb.walking = false; }
            }
        }
    }
}
