// BaphOS: окно «Настройки» (Mod+S, шестерёнка в Пуске, ipc call settings toggle).
// Вкладки: Обои, Вид, Сюжет, О системе. Всё пишется в ~/.local/state/baphos/settings.json (Store).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: win
    property bool open: false
    signal dismissed()

    title: "BaphOS — Настройки"
    visible: open
    implicitWidth: 820
    implicitHeight: 560
    color: Theme.bg
    onVisibleChanged: if (!visible && open) dismissed()     // закрыли крестиком или Mod+Q

    property int tab: 0
    readonly property var tabs: [["Обои", "monitor"], ["Вид", "sliders"], ["Сюжет", "skull"], ["О системе", "eye"]]

    // ── данные «О системе» ──
    property string kernel: ""
    property string cpuName: ""
    property string uptime: ""
    property string version: ""
    FileView { path: "/proc/sys/kernel/osrelease"; onLoaded: win.kernel = text().trim() }
    FileView { path: "/proc/cpuinfo"; onLoaded: { const m = text().match(/model name\s*:\s*(.+)/); win.cpuName = m ? m[1].trim() : ""; } }
    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            win.uptime = Math.floor(s / 3600) + " ч " + Math.floor(s % 3600 / 60) + " мин";
        }
    }
    FileView { path: Theme.asset("../VERSION"); onLoaded: win.version = text().trim() }
    Timer { interval: 30000; running: win.visible && win.tab === 3; repeat: true; onTriggered: up.reload() }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    RowLayout {
        anchors { fill: parent; margins: 10 }
        spacing: 10

        // ── вкладки слева ──
        Bevel {
            kind: "panel"
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            Column {
                anchors.fill: parent
                spacing: 6
                Image { anchors.horizontalCenter: parent.horizontalCenter; source: Theme.asset("sigil/sigil-64.png"); width: 64; height: 64; smooth: false }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "BaphOS"; color: Theme.scarlet
                    font.family: Theme.fontGothic; font.pixelSize: 48
                    renderType: Text.NativeRendering
                }
                Item { width: 1; height: 6 }
                Repeater {
                    model: win.tabs
                    PixelButton {
                        required property var modelData
                        required property int index
                        width: parent.width; height: 38
                        active: win.tab === index
                        onClicked: win.tab = index
                        Row {
                            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                            spacing: 8
                            Image { source: Theme.icon(modelData[1], win.tab === index ? "scarlet" : "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                            PixelText { text: modelData[0]; color: win.tab === index ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }

        // ── страница ──
        Bevel {
            kind: "panel"
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Обои
            Column {
                anchors.fill: parent
                visible: win.tab === 0
                spacing: 10
                PixelText { text: "Обои"; color: Theme.scarlet; font.pixelSize: 24 }
                PixelText { text: "Клик — поставить (переход мозаикой). Ещё: Mod+Shift+W."; color: Theme.dim }
                Grid {
                    columns: 3
                    spacing: 10
                    Repeater {
                        model: [["crimson-moon", "Багровая луна"], ["ritual", "Ритуал"], ["forest", "Лес"], ["cathedral", "Собор"], ["sigil", "Сигил"]]
                        Item {
                            required property var modelData
                            readonly property bool cur: Store.data.wallpaper === modelData[0]
                            width: 168; height: 120
                            Bevel {
                                kind: parent.cur ? "btn-active" : (ma.containsMouse ? "btn-hover" : "btn")
                                width: 168; height: 98   // 160x90 + рамка: ровно 1/3 сцены 480x270
                                Image { anchors.fill: parent; source: Theme.asset("wallpapers/thumb-" + modelData[0] + ".png"); smooth: false; fillMode: Image.PreserveAspectCrop }
                            }
                            PixelText { y: 100; text: (parent.cur ? "† " : "") + modelData[1]; color: parent.cur ? Theme.scarlet : Theme.text }
                            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: Store.data.wallpaper = modelData[0] }
                        }
                    }
                }
            }

            // Вид
            Column {
                anchors.fill: parent
                visible: win.tab === 1
                spacing: 14
                PixelText { text: "Вид"; color: Theme.scarlet; font.pixelSize: 24 }
                PixelSwitch {
                    text: "Живые обои и анимации"
                    hint: "мерцание, пламя, мозаика, раскрытие Пуска. Выкл — ноль нагрузки"
                    checked: Store.data.animations
                    onToggled: v => Store.data.animations = v
                }
                PixelSwitch {
                    text: "Виджеты на столе"
                    hint: "Гримуар, Око системы, Литания"
                    checked: Store.data.widgets
                    onToggled: v => Store.data.widgets = v
                }
            }

            // Сюжет
            Column {
                anchors.fill: parent
                visible: win.tab === 2
                spacing: 14
                PixelText { text: "Сюжет"; color: Theme.scarlet; font.pixelSize: 24 }
                PixelText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "Вымышленная история: в систему проник вирус культа. Он только рисует — ничего не удаляет, не трогает файлы вне ~/.local/state/baphos и не ходит в сеть."
                    color: Theme.dim
                }
                PixelSwitch {
                    text: "Сюжет включён"
                    hint: "глитчи, послания культа, ритуалы"
                    checked: Store.data.story
                    onToggled: v => Store.data.story = v
                }
                PixelText { text: "Этап заражения: " + Store.data.storyStage; color: Theme.text }
                PixelButton {
                    id: reset
                    property bool armed: false
                    width: 260; height: 38
                    active: armed
                    onClicked: {
                        if (armed) { Store.resetStory(); armed = false; }
                        else { armed = true; disarmReset.restart(); }
                    }
                    Timer { id: disarmReset; interval: 3000; onTriggered: reset.armed = false }
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Image { source: Theme.icon("reload", reset.armed ? "scarlet" : "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                        PixelText { text: reset.armed ? "Точно? Всё забудется" : "Сбросить прогресс"; color: reset.armed ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            // О системе
            Column {
                anchors.fill: parent
                visible: win.tab === 3
                spacing: 8
                Row {
                    spacing: 14
                    Image { source: Theme.asset("sigil/sigil-128.png"); width: 128; height: 128; smooth: false }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text { text: "BaphOS"; color: Theme.scarlet; font.family: Theme.fontGothic; font.pixelSize: 48; renderType: Text.NativeRendering }
                        PixelText { text: "версия " + (win.version || "?"); color: Theme.dim }
                        PixelText { text: "niri + Quickshell · пиксель-арт"; color: Theme.dim }
                    }
                }
                Rectangle { width: parent.width; height: 2; color: Theme.dried }
                GridLayout {
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 4
                    PixelText { text: "Процессор"; color: Theme.scarlet }
                    PixelText { text: win.cpuName }
                    PixelText { text: "Память"; color: Theme.scarlet }
                    PixelText { text: SysInfo.memTotalGb.toFixed(1) + " ГБ" }
                    PixelText { text: "Ядро"; color: Theme.scarlet }
                    PixelText { text: win.kernel }
                    PixelText { text: "Бодрствует"; color: Theme.scarlet }
                    PixelText { text: win.uptime }
                }
                Rectangle { width: parent.width; height: 2; color: Theme.dried }
                PixelText { text: "Шрифты: Pixelify Sans, Jacquard 24, Press Start 2P (OFL) · Cozette (MIT)"; color: Theme.dim; width: parent.width }
                PixelText { text: "Иконки интерфейса: Pixelarticons (MIT). Остальная графика — своя."; color: Theme.dim; width: parent.width }
                PixelText { text: "github.com/oniczzz/BaphOS"; color: Theme.crimson }
            }
        }
    }
}
