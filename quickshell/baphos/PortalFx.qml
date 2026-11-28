// BaphOS: окно перешло на другой монитор — на старом месте схлопывается тёмный портал,
// на новом раскрывается алый (Niri.portalJump). Клики насквозь.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: fx
    required property var modelData
    screen: modelData
    visible: inA.running || outA.running
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-portal"

    property point at: Qt.point(0, 0)
    property bool incoming: false     // true — окно пришло сюда (алый), false — ушло отсюда (тёмный)
    property real k: 0                // 0..1 — раскрытость овала

    function place(c) {
        at = (c.x < 0) ? Qt.point(width / 2, height / 2) : c;
    }
    Connections {
        target: Niri
        function onPortalJump(fromOutput, fromCenter, toOutput, toCenter) {
            if (Mode.calm || !Store.data.animations) return;
            if (fromOutput === fx.modelData.name) {
                fx.incoming = false; fx.place(fromCenter); outA.stop(); inA.restart(); Sfx.play("portal-in", 200, 0.5);
            } else if (toOutput === fx.modelData.name) {
                fx.incoming = true; fx.place(toCenter); inA.stop(); outA.restart(); Sfx.play("portal-out", 200, 0.5);
            }
        }
    }
    // ушло: овал раскрылся и сразу схлопнулся; пришло: раскрылся, подержался, погас
    SequentialAnimation {
        id: inA
        NumberAnimation { target: fx; property: "k"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
        NumberAnimation { target: fx; property: "k"; to: 0; duration: 260; easing.type: Easing.InCubic }
    }
    SequentialAnimation {
        id: outA
        PauseAnimation { duration: 120 }
        NumberAnimation { target: fx; property: "k"; from: 0; to: 1; duration: 180; easing.type: Easing.OutBack }
        PauseAnimation { duration: 140 }
        NumberAnimation { target: fx; property: "k"; to: 0; duration: 220; easing.type: Easing.InCubic }
    }

    PixelOval {
        readonly property int fullW: 180
        readonly property int fullH: 300
        width: Math.max(8, Math.round(fullW * fx.k / 8) * 8)
        height: Math.max(8, Math.round(fullH * Math.min(1, fx.k * 1.3) / 4) * 4)
        x: fx.at.x - width / 2
        y: fx.at.y - height / 2
        visible: fx.k > 0.02
        ring: fx.incoming ? Theme.scarlet : Theme.blood
        edge: fx.incoming ? "#ffd98c" : Theme.crimson
        core: fx.incoming ? Theme.blood : Theme.bg
        opacity: 0.92
        // воронка внутри
        PixelOval {
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.62 / 8) * 8
            height: Math.round(parent.height * 0.62 / 4) * 4
            thick: 2
            ring: fx.incoming ? Theme.crimson : Theme.dried
            edge: ring
            core: fx.incoming ? Theme.dried : "#050000"
            PixelOval {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.5 / 8) * 8
                height: Math.round(parent.height * 0.5 / 4) * 4
                thick: 1
                ring: fx.incoming ? Theme.blood : Theme.bg
                edge: ring
                core: Theme.bg
            }
        }
    }
}
