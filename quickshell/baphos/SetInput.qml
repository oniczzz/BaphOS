// Настройки → Клавиатура и мышь: раскладки и их переключение, тачпад, скорость мыши.
// Всё пишется в ~/.config/niri/input.kdl (InputConf) — niri применяет сразу.
import QtQuick

Column {
    id: page
    spacing: 16
    function set(key, value) { Store.data[key] = value; InputConf.write(); }

    SetTitle { text: "Клавиатура и мышь"; hint: "Применяется сразу." }

    Choice {
        label: "Раскладки"
        options: [["us,ru", "EN + RU"], ["us,ru,ua", "EN + RU + UA"], ["us", "только EN"], ["ru,us", "RU + EN (RU первой)"]]
        current: Store.data.kbLayouts
        onPicked: v => page.set("kbLayouts", v)
    }
    Choice {
        label: "Переключение раскладки"
        options: [["grp:alt_shift_toggle", "Alt+Shift"], ["grp:ctrl_shift_toggle", "Ctrl+Shift"], ["grp:caps_toggle", "Caps Lock"], ["grp:win_space_toggle", "Win+Пробел"]]
        current: Store.data.kbToggle
        onPicked: v => page.set("kbToggle", v)
    }

    PixelText { text: "Тачпад"; color: Theme.scarlet }
    PixelSwitch { text: "Нажатие касанием (тап)"; checked: Store.data.tpTap; onToggled: v => page.set("tpTap", v) }
    PixelSwitch { text: "Естественная прокрутка"; hint: "как на телефоне: тянешь вниз — страница едет вниз"; checked: Store.data.tpNatural; onToggled: v => page.set("tpNatural", v) }
    Column {
        width: page.width; spacing: 4
        PixelText { text: "Скорость тачпада" }
        PixelSlider { width: Math.min(page.width, 520); icon: "sliders"; value: (Store.data.tpSpeed + 1) / 2; onMoved: v => page.set("tpSpeed", v * 2 - 1) }
    }

    PixelText { text: "Мышь"; color: Theme.scarlet }
    Column {
        width: page.width; spacing: 4
        PixelText { text: "Скорость мыши" }
        PixelSlider { width: Math.min(page.width, 520); icon: "sliders"; value: (Store.data.mouseSpeed + 1) / 2; onMoved: v => page.set("mouseSpeed", v * 2 - 1) }
    }
    PixelSwitch { text: "Без ускорения (для игр)"; hint: "курсор двигается ровно на столько, на сколько мышь"; checked: Store.data.mouseFlat; onToggled: v => page.set("mouseFlat", v) }
}
