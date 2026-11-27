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
    property var startScreen: Quickshell.screens[0]

    function toggleStart(screen) {
        if (startOpen && (!screen || screen === startScreen)) { startOpen = false; return; }
        startScreen = screen || focusedScreen() || Quickshell.screens[0];
        startOpen = true;
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
        }
    }

    Notifications {
        screen: root.focusedScreen() || Quickshell.screens[0]
    }

    Lock { id: lock }

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
