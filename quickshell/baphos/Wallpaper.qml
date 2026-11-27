// BaphOS: обои на слое Background. Для каждого экрана берётся файл точно под его разрешение
// (art/wallpapers.py рисует 1920x1080, 1366x768, 2560x1440); иначе ближайший — без сглаживания.
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

    Image {
        anchors.fill: parent
        source: Theme.asset("wallpapers/" + Store.data.wallpaper + "-" + wall.size + ".png")
        fillMode: Image.PreserveAspectCrop
        smooth: false
        asynchronous: true
        cache: false
    }
}
