// BaphOS: оболочка на Quickshell для niri. Запуск: qs -c baphos
// Пуск с клавиатуры: qs -c baphos ipc call start toggle  (в niri — Mod+D)
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property bool startOpen: false
    property var startScreen: Quickshell.screens[0]

    function toggleStart(screen) {
        if (startOpen && (!screen || screen === startScreen)) { startOpen = false; return; }
        startScreen = screen || focusedScreen() || Quickshell.screens[0];
        startOpen = true;
    }

    // экран под фокусом niri — из имени активного выхода
    function focusedScreen() {
        const name = Niri.focusedOutput;
        return Quickshell.screens.find(s => s.name === name) || null;
    }

    Variants {
        model: Quickshell.screens
        Taskbar {
            startOpen: root.startOpen && root.startScreen === modelData
            onStartClicked: root.toggleStart(modelData)
        }
    }

    StartMenu {
        screen: root.startScreen
        open: root.startOpen
        onCloseRequested: root.startOpen = false
    }

    IpcHandler {
        target: "start"
        function toggle(): void { root.toggleStart(null) }
        function close(): void { root.startOpen = false }
    }
}
