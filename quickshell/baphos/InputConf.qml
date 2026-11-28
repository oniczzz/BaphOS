// BaphOS: пишет ~/.config/niri/input.kdl из настроек (раскладки, тачпад, мышь); niri перечитает сам.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    function write() {
        const d = Store.data;
        const tp = (d.tpTap ? "        tap\n" : "") + (d.tpNatural ? "        natural-scroll\n" : "")
                 + "        accel-speed " + d.tpSpeed.toFixed(2) + "\n";
        const ms = "        accel-speed " + d.mouseSpeed.toFixed(2) + "\n" + (d.mouseFlat ? '        accel-profile "flat"\n' : "");
        file.setText("// BaphOS: клавиатура, тачпад, мышь. Этот файл пишут Настройки BaphOS (раздел «Клавиатура и мышь»).\n"
            + "input {\n    keyboard {\n        xkb {\n"
            + '            layout "' + d.kbLayouts + '"\n'
            + (d.kbToggle ? '            options "' + d.kbToggle + '"\n' : "")
            + "        }\n    }\n    touchpad {\n" + tp + "    }\n    mouse {\n" + ms + "    }\n}\n");
    }
    FileView { id: file; path: Quickshell.env("HOME") + "/.config/niri/input.kdl"; blockWrites: false }
}
