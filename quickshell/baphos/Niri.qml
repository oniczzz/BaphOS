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

    // рабочие столы одного монитора, по порядку
    function workspacesOn(output) { return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx); }
    function focusWorkspace(output, idx) {
        Quickshell.execDetached(["sh", "-c", "niri msg action focus-monitor " + output + " && niri msg action focus-workspace " + idx]);
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
                } else if (ev.WorkspaceActivated) {
                    // активен на своём мониторе; если focused — ещё и фокус
                    const id = ev.WorkspaceActivated.id, focused = ev.WorkspaceActivated.focused;
                    const out = (root.workspaces.find(w => w.id === id) || {}).output;
                    root.workspaces = root.workspaces.map(w => Object.assign({}, w, {
                        is_active: w.output === out ? w.id === id : w.is_active,
                        is_focused: focused ? w.id === id : w.is_focused,
                    }));
                } else if (ev.WorkspaceActiveWindowChanged) {
                    const e = ev.WorkspaceActiveWindowChanged;
                    root.workspaces = root.workspaces.map(w => w.id === e.workspace_id
                        ? Object.assign({}, w, { active_window_id: e.active_window_id }) : w);
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
