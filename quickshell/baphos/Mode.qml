// BaphOS: «тихо ли сейчас». Игровой режим (плитка в Алтаре, Mod+G) или окно во весь экран
// (игра, видео) — тогда никаких «скримеров»: сюжет молчит, нет углей, звуков и всплывающих уведомлений.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    readonly property bool fullscreen: ToplevelManager.activeToplevel?.fullscreen ?? false
    readonly property bool quiet: Store.data.gameMode || (Store.data.autoGameMode && fullscreen)
}
