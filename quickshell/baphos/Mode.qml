// BaphOS: режимы тишины.
//   quiet — игровой режим (Mod+G) или окно во весь экран: сюжет молчит, нет углей, звуков и всплывашек.
//   calm  — «Спокойный режим» (Алтарь/Настройки): выключены сюжет, глитчи, угли, живые обои, мозаика
//           и эффекты окон niri (ссылка niri/fx.kdl -> fx-off.kdl), чтобы ничего не казалось багом.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    readonly property bool fullscreen: ToplevelManager.activeToplevel?.fullscreen ?? false
    readonly property bool calm: !Store.data.effects
    readonly property bool quiet: calm || Store.data.gameMode || (Store.data.autoGameMode && fullscreen)

    // эффекты окон в niri: переключить ссылку niri/fx.kdl (niri перечитает конфиг сам)
    function syncNiri() {
        Quickshell.execDetached(["sh", "-c", 'r=$(dirname "$(readlink -f "$1")"); ln -sfn "fx-$2.kdl" "$r/niri/fx.kdl"',
                                 "sh", Quickshell.shellDir + "/assets", calm ? "off" : "on"]);
    }
    onCalmChanged: syncNiri()
}
