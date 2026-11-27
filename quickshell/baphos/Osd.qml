// BaphOS: попап громкости и яркости, как в игре — снизу по центру, над панелью; гаснет через 1.5 с.
// Громкость ловится сама (PipeWire); яркость — через IPC osd brightness (клавиши яркости в niri).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: osd
    property string kind: "volume"
    property real value: 0
    property bool muted: false
    property bool shown: false
    property int tick: 0

    visible: true
    anchors { bottom: true }
    margins { bottom: Theme.barHeight + 60 }
    implicitWidth: 360
    implicitHeight: 76
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-osd"
    mask: Region { item: nothing }
    Item { id: nothing; width: 0; height: 0 }

    function show(k, v, m) {
        kind = k; value = v; muted = m;
        shown = true;
        hide.restart();
        Sfx.play("tick");
    }
    Timer { id: hide; interval: 1500; onTriggered: osd.shown = false }
    Timer { interval: 125; repeat: true; running: osd.shown && Store.data.animations; onTriggered: osd.tick++ }

    // ── громкость: следим за динамиком по умолчанию ──
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    property bool ready: false
    Timer { interval: 1500; running: true; onTriggered: osd.ready = true }   // не показывать при старте
    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() { if (osd.ready) osd.show("volume", target.volume, target.muted) }
        function onMutedChanged() { if (osd.ready) osd.show("volume", target.volume, target.muted) }
    }

    // ── яркость: IPC меняет и показывает ──
    Process {
        id: bright
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5) osd.show("brightness", Number(f[2]) / Number(f[4]), false);
            }
        }
    }
    IpcHandler {
        target: "osd"
        function brightness(step: int): void {
            bright.command = ["sh", "-c", "brightnessctl -q set " + Math.abs(step) + "%" + (step >= 0 ? "+" : "-") + " && brightnessctl -m"];
            bright.running = true;
        }
    }

    Bevel {
        kind: "panel"
        anchors.fill: parent
        visible: osd.shown
        Row {
            anchors.centerIn: parent
            spacing: 10
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 48; height: 48; smooth: false
                source: osd.kind === "brightness" ? Theme.icon("sun", "scarlet", 48)
                      : osd.muted ? Theme.icon("volume-x", "dim", 48)
                      : Theme.icon(osd.value > 0.66 ? "volume-3" : osd.value > 0.33 ? "volume-2" : "volume-1", "scarlet", 48)
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                PixelText {
                    text: (osd.kind === "brightness" ? "Свет" : osd.muted ? "Тишина" : "Звук") + "  " + Math.round(osd.value * 100) + "%"
                    color: osd.muted ? Theme.dim : Theme.scarlet
                }
                Row {
                    spacing: 2
                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            width: 10; height: 14
                            readonly property bool lit: index < Math.round(Math.min(1, osd.value) * 20)
                            color: !lit ? Theme.dried : osd.muted ? Theme.dim : (index >= 17 ? Theme.scarlet : Theme.crimson)
                        }
                    }
                }
            }
            // свеча: пламя дрожит, пока попап виден
            Item {
                width: 12; height: 40
                anchors.verticalCenter: parent.verticalCenter
                Image { source: Theme.asset("wallpapers/anim/flame-" + (osd.tick % 4) + ".png"); smooth: false }
                Rectangle { x: 4; y: 12; width: 4; height: 2; color: Theme.dim }
                Rectangle { x: 2; y: 14; width: 8; height: 26; color: Theme.text }
                Rectangle { x: 2; y: 14; width: 2; height: 26; color: Theme.dim }
            }
        }
    }
}
