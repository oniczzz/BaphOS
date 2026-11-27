// BaphOS: события niri (раскладка клавиатуры) из `niri msg --json event-stream` — без опроса.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var layouts: []          // ["English (US)", "Russian"]
    property int layoutIdx: 0
    property var workspaces: []       // как в `niri msg --json workspaces`
    readonly property string focusedOutput: (workspaces.find(w => w.is_focused) || {}).output || ""
    readonly property string layoutShort: {
        const n = layouts[layoutIdx] || "";
        if (n.startsWith("Russian")) return "RU";
        if (n.startsWith("English")) return "EN";
        return n.slice(0, 2).toUpperCase();
    }

    function nextLayout() { Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]) }

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                let ev;
                try { ev = JSON.parse(line); } catch (e) { return; }
                if (ev.WorkspacesChanged) {
                    root.workspaces = ev.WorkspacesChanged.workspaces;
                } else if (ev.WorkspaceActivated && ev.WorkspaceActivated.focused) {
                    const id = ev.WorkspaceActivated.id;
                    root.workspaces = root.workspaces.map(w => Object.assign({}, w, { is_focused: w.id === id }));
                } else if (ev.KeyboardLayoutsChanged) {
                    root.layouts = ev.KeyboardLayoutsChanged.keyboard_layouts.names;
                    root.layoutIdx = ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx;
                } else if (ev.KeyboardLayoutSwitched) {
                    root.layoutIdx = ev.KeyboardLayoutSwitched.idx;
                }
            }
        }
        // niri перезапустился или поток оборвался — переподключиться
        onExited: restart.start()
    }
    Timer { id: restart; interval: 2000; onTriggered: stream.running = true }
}
