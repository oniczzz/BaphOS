// BaphOS: обои на слое Background — картинка точно под разрешение экрана, «живые» спрайты поверх
// и переход пиксельной мозаикой при смене (блоки 64x64 закрывают экран и рассыпаются).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wall
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "baphos-wallpaper"

    readonly property string size: {
        const w = modelData.width, h = modelData.height;
        for (const s of ["1920x1080", "1366x768", "2560x1440"])
            if (s === w + "x" + h) return s;
        return w > 1920 ? "2560x1440" : (w > 1366 ? "1920x1080" : "1366x768");
    }
    property string shown: ""                       // что видно сейчас (меняется посреди мозаики)
    Component.onCompleted: shown = Store.data.wallpaper
    readonly property string base: "wallpapers/" + shown + "-" + size

    Connections {
        target: Store.data
        function onWallpaperChanged() {
            if (Store.data.wallpaper === wall.shown) return;
            if (!Store.data.animations) { wall.shown = Store.data.wallpaper; return; }
            mosaic.start();
        }
    }

    Image {
        id: picture
        anchors.fill: parent
        source: wall.shown ? Theme.asset(wall.base + ".png") : ""
        fillMode: Image.PreserveAspectCrop
        smooth: false
        cache: false
    }

    WallpaperAnim {
        anchors.fill: parent
        jsonPath: wall.shown ? Theme.asset(wall.base + ".json") : ""
        running: Store.data.animations && !mosaic.active
    }

    // ── сюжет: с этапа «Знак» на обоях проступает сигил (ступенчатое дыхание) ──
    Image {
        anchors.centerIn: parent
        visible: Story.stage >= 3
        source: Theme.asset("sigil/sigil-128.png")
        width: 512; height: 512
        smooth: false
        property int ph: 0
        opacity: [0.04, 0.06, 0.08, 0.10, 0.08, 0.06][ph]
        Timer { interval: 400; repeat: true; running: parent.visible && Store.data.animations; onTriggered: parent.ph = (parent.ph + 1) % 6 }
    }

    // ── мозаика ──
    Item {
        id: mosaic
        anchors.fill: parent
        property bool active: false
        property int t: 0
        readonly property int cell: 64
        readonly property int cols: Math.ceil(width / cell)
        readonly property int rows: Math.ceil(height / cell)
        function start() { t = 0; active = true; stepper.start(); }

        Timer {
            id: stepper
            interval: 40
            repeat: true
            onTriggered: {
                mosaic.t++;
                if (mosaic.t === 10) wall.shown = Store.data.wallpaper;   // всё закрыто — меняем картинку
                if (mosaic.t >= 20) { stop(); mosaic.active = false; }
            }
        }

        Loader {
            anchors.fill: parent
            active: mosaic.active
            sourceComponent: Grid {
                columns: mosaic.cols
                Repeater {
                    model: mosaic.cols * mosaic.rows
                    Rectangle {
                        readonly property int d: Math.floor(Math.random() * 10)   // своя задержка у блока
                        width: mosaic.cell; height: mosaic.cell
                        color: [Theme.bg, Theme.bg, Theme.dried, Theme.blood][Math.floor(Math.random() * 4)]
                        visible: mosaic.t >= d && mosaic.t < 10 + d
                    }
                }
            }
        }
    }
}
