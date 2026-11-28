// BaphOS: оболочка на Quickshell для niri. Запуск: qs -c baphos
// Пуск с клавиатуры: qs -c baphos ipc call start toggle  (в niri — Mod+D)
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property bool startOpen: false
    property bool settingsOpen: false
    property bool keysOpen: false
    property bool altarOpen: false
    property bool mapOpen: false
    property string mapOutput: ""
    function toggleMap() {
        if (mapOpen) { mapOpen = false; Sfx.play("close"); return; }
        mapOutput = Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
        startOpen = false; altarOpen = false;
        mapOpen = true;
        Sfx.play("open");
    }
    property var altarScreen: Quickshell.screens[0]

    function toggleAltar(screen) {
        if (altarOpen && (!screen || screen === altarScreen)) { altarOpen = false; Sfx.play("close"); return; }
        altarScreen = screen || focusedScreen() || Quickshell.screens[0];
        startOpen = false;
        altarOpen = true;
        Sfx.play("open");
    }
    property var startScreen: Quickshell.screens[0]

    function toggleStart(screen) {
        if (startOpen && (!screen || screen === startScreen)) { startOpen = false; Sfx.play("close"); return; }
        startScreen = screen || focusedScreen() || Quickshell.screens[0];
        altarOpen = false;
        startOpen = true;
        Sfx.play("open");
        Story.onStartOpened();
    }

    // экран под фокусом niri — из имени активного выхода
    function focusedScreen() {
        const name = Niri.focusedOutput;
        return Quickshell.screens.find(s => s.name === name) || null;
    }

    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }

    Widgets {}

    Variants {
        model: Quickshell.screens
        Taskbar {
            startOpen: root.startOpen && root.startScreen === modelData
            onStartClicked: root.toggleStart(modelData)
            altarOpen: root.altarOpen && root.altarScreen === modelData
            onAltarClicked: root.toggleAltar(modelData)
        }
    }

    Variants {
        model: Quickshell.screens
        Embers {}
    }

    ControlCenter {
        screen: root.altarScreen
        open: root.altarOpen
        onCloseRequested: root.altarOpen = false
        onLockRequested: lock.lock()
    }

    Osd {
        screen: root.focusedScreen() || Quickshell.screens[0]
    }

    // звук входа: только если niri запущен меньше 90 с назад (а не при каждом перезапуске оболочки)
    Process {
        running: true
        command: ["sh", "-c", "ps -o etimes= -C niri | sort -n | head -1"]
        stdout: StdioCollector { onStreamFinished: if (Number(text.trim()) < 90) Sfx.play("login") }
    }

    Notifications {
        screen: root.focusedScreen() || Quickshell.screens[0]
    }

    Lock { id: lock }

    Variants {
        model: Quickshell.screens
        DungeonMap {
            open: root.mapOpen && root.mapOutput === modelData.name
            onCloseRequested: { root.mapOpen = false; Sfx.play("close"); }
        }
    }
    IpcHandler {
        target: "map"
        function toggle(): void { root.toggleMap() }
    }
    IpcHandler {
        target: "banner"
        function say(text: string): void { Banner.show(text, Theme.scarlet) }
    }

    Variants {
        model: Quickshell.screens
        BannerOverlay {}
    }

    StartMenu {
        screen: root.startScreen
        open: root.startOpen
        onCloseRequested: root.startOpen = false
        onLockRequested: lock.lock()
        onLaunched: Story.onLaunched()
        onSettingsRequested: { root.startOpen = false; root.settingsOpen = true; }
    }

    Settings {
        open: root.settingsOpen
        onDismissed: root.settingsOpen = false
    }

    KeyScroll {
        screen: root.focusedScreen() || Quickshell.screens[0]
        open: root.keysOpen
        onDismissed: root.keysOpen = false
    }

    StoryOverlay {
        screen: root.focusedScreen() || Quickshell.screens[0]
    }

    RitualWindow {
        open: Story.ritualOpen
        onDismissed: Story.ritualOpen = false
    }

    BasementWindow {
        open: Story.basementOpen
        onDismissed: Story.basementOpen = false
    }

    // сюжет: показать/проверить (qs -c baphos ipc call story <функция>)
    IpcHandler {
        target: "story"
        function stage(n: int): void { Store.data.storyStage = Math.max(0, Math.min(5, n)); Store.data.stageMinutes = 0 }
        function ritual(n: int): void { Story.offerRitual(Math.max(1, Math.min(3, n))) }
        function glitch(n: int): void { Story.glitch(n) }
        function whisper(): void { Story.say() }
        function basement(): void { Story.basementOpen = true }
        function lamb(): void { Story.lambWalk() }
        function intro(): void { Story.intro() }
        function close(): void { Story.ritualOpen = false; Story.basementOpen = false }
    }

    Variants {
        model: Quickshell.screens
        ScreenshotTool {}
    }

    IpcHandler {
        target: "shot"
        function region(): void { Shot.begin() }
        function cancel(): void { Shot.cancel() }
    }

    IpcHandler {
        target: "window"
        function minimize(): void { Niri.minimize(Niri.windows.find(w => w.is_focused) || null) }
        function restore(): void { const id = Niri.minimized[Niri.minimized.length - 1]; Niri.restore(Niri.windows.find(w => w.id === id) || null) }
    }

    IpcHandler {
        target: "game"
        function toggle(): void { Store.data.gameMode = !Store.data.gameMode }
    }

    IpcHandler {
        target: "altar"
        function toggle(): void { root.toggleAltar(null) }
    }

    IpcHandler {
        target: "keys"
        function toggle(): void { root.keysOpen = !root.keysOpen }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.settingsOpen = !root.settingsOpen }
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { Store.nextWallpaper() }
        function set(name: string): void { if (Store.wallpapers.includes(name)) Store.data.wallpaper = name }
    }

    IpcHandler {
        target: "start"
        function toggle(): void { root.toggleStart(null) }
        function close(): void { root.startOpen = false }
    }
}
