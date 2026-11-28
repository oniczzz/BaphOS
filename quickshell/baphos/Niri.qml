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
    property var windows: []          // как в `niri msg --json windows`
    property var minimized: []        // id окон, «свёрнутых» с панели задач (лежат на последнем столе)
    // окно перешло на другой монитор: откуда/куда (выход и центр окна в координатах экрана)
    signal portalJump(string fromOutput, point fromCenter, string toOutput, point toCenter)
    // на мониторе переключился стол
    signal workspaceSwitched(string output, int idx)
    function centerOf(win) {
        const l = win?.layout;
        if (!l || !l.tile_pos_in_workspace_view) return Qt.point(-1, -1);
        return Qt.point(l.tile_pos_in_workspace_view[0] + l.tile_size[0] / 2, l.tile_pos_in_workspace_view[1] + l.tile_size[1] / 2);
    }
    readonly property string focusedOutput: (workspaces.find(w => w.is_focused) || {}).output || ""
    readonly property string layoutShort: {
        const n = layouts[layoutIdx] || "";
        if (n.startsWith("Russian")) return "RU";
        if (n.startsWith("English")) return "EN";
        return n.slice(0, 2).toUpperCase();
    }

    // рабочие столы одного монитора, по порядку
    // рабочие столы монитора по порядку; стол, где лежат только свёрнутые окна, не показываем
    function workspacesOn(output) {
        return workspaces.filter(w => {
            if (w.output !== output) return false;
            const ws = windows.filter(x => x.workspace_id === w.id);
            return !(ws.length > 0 && ws.every(x => minimized.includes(x.id)));
        }).sort((a, b) => a.idx - b.idx);
    }
    function focusWorkspace(output, idx) {
        Quickshell.execDetached(["sh", "-c", "niri msg action focus-monitor " + output + " && niri msg action focus-workspace " + idx]);
    }

    // окно niri для окна панели задач (по app_id и заголовку)
    function windowFor(appId, title) { return windows.find(w => w.app_id === appId && w.title === title) || null; }
    function isMinimized(win) { return !!win && minimized.includes(win.id); }
    // свернуть: убрать на последний (пустой) стол своего монитора, фокус остаётся где был
    function minimize(win) {
        if (!win) return;
        minimized = minimized.concat([win.id]);
        Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", "--window-id", String(win.id), "--focus", "false", "99"]);
    }
    // развернуть: на текущий стол монитора с фокусом и дать фокус
    function restore(win) {
        if (!win) return;
        minimized = minimized.filter(id => id !== win.id);
        const from = (workspaces.find(w => w.id === win.workspace_id) || {}).output;
        const out = focusedOutput || from;
        const cur = workspaces.find(w => w.output === out && w.is_active);
        const move = (out === from && cur)
            ? "niri msg action move-window-to-workspace --window-id " + win.id + " --focus false " + cur.idx
            : "niri msg action move-window-to-monitor --id " + win.id + " " + out;
        Quickshell.execDetached(["sh", "-c", move + " && niri msg action focus-window --id " + win.id]);
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
                    const ws = root.workspaces.find(w => w.id === id) || {};
                    const out = ws.output;
                    const was = root.workspaces.find(w => w.output === out && w.is_active);
                    if (out && was && was.id !== id) root.workspaceSwitched(out, ws.idx);
                    root.workspaces = root.workspaces.map(w => Object.assign({}, w, {
                        is_active: w.output === out ? w.id === id : w.is_active,
                        is_focused: focused ? w.id === id : w.is_focused,
                    }));
                } else if (ev.WorkspaceActiveWindowChanged) {
                    const e = ev.WorkspaceActiveWindowChanged;
                    root.workspaces = root.workspaces.map(w => w.id === e.workspace_id
                        ? Object.assign({}, w, { active_window_id: e.active_window_id }) : w);
                } else if (ev.WindowsChanged) {
                    root.windows = ev.WindowsChanged.windows;
                } else if (ev.WindowOpenedOrChanged) {
                    const w = ev.WindowOpenedOrChanged.window;
                    const old = root.windows.find(x => x.id === w.id);
                    if (old && old.workspace_id !== w.workspace_id) {
                        const a = (root.workspaces.find(x => x.id === old.workspace_id) || {}).output;
                        const b = (root.workspaces.find(x => x.id === w.workspace_id) || {}).output;
                        if (a && b && a !== b) root.portalJump(a, root.centerOf(old), b, root.centerOf(w));
                    }
                    root.windows = root.windows.some(x => x.id === w.id) ? root.windows.map(x => x.id === w.id ? w : x) : root.windows.concat([w]);
                } else if (ev.WindowClosed) {
                    root.windows = root.windows.filter(x => x.id !== ev.WindowClosed.id);
                    root.minimized = root.minimized.filter(id => id !== ev.WindowClosed.id);
                } else if (ev.WindowFocusChanged) {
                    // окно нашли и открыли сами (Alt+Tab и т.п.) — оно больше не «свёрнуто»
                    const id = ev.WindowFocusChanged.id;
                    if (id !== null && root.minimized.includes(id)) root.minimized = root.minimized.filter(x => x !== id);
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
