// BaphOS: состояние скриншота (Mod+Shift+S). Замораживает кадр экрана с фокусом (grim) и
// отдаёт его ScreenshotTool этого экрана; вырезает и сохраняет bin/baphos-shot.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string output: ""            // на каком экране сейчас инструмент ("" — закрыт)
    property int nonce: 0                 // меняется с каждым новым кадром (сброс кэша картинки)
    readonly property string frame: Quickshell.env("XDG_RUNTIME_DIR") + "/baphos-frozen.png"
    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/baphos-shot"
    property string pending: ""

    function begin() {
        if (grab.running || root.output) return;
        root.pending = Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
        grab.command = ["grim", "-o", root.pending, root.frame];
        grab.running = true;
    }
    function cancel() { root.output = ""; }
    function take(x, y, w, h, mode) {
        save.command = [root.tool, root.frame, String(Math.round(x)), String(Math.round(y)),
                        String(Math.round(w)), String(Math.round(h)), mode];
        save.running = true;
        Sfx.play("shutter");
    }

    Process {
        id: grab
        onExited: code => { if (code === 0) { root.nonce++; root.output = root.pending; } }
    }
    Process { id: save }
}
