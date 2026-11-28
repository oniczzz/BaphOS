// BaphOS: «Настройки» как в Windows/KDE (Mod+S, Пуск → Настройки, ipc call settings toggle).
// Слева разделы, справа страница с прокруткой. Страница грузится, только когда открыта.
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
    implicitWidth: 1040
    implicitHeight: 680
    color: Theme.bg
    onVisibleChanged: if (!visible && open) dismissed()     // закрыли крестиком или Mod+Q

    property int tab: 0
    readonly property var tabs: [
        ["Экран", "monitor", displayPage],
        ["Звук", "volume-3", soundPage],
        ["Сеть", "wifi", networkPage],
        ["Bluetooth", "bluetooth", btPage],
        ["Клавиатура и мышь", "keyboard", inputPage],
        ["Питание", "battery-full", powerPage],
        ["Приложения", "terminal", appsPage],
        ["Вид", "sparkles", lookPage],
        ["Сюжет", "skull", storyPage],
        ["О системе", "eye", aboutPage],
    ]

    Component { id: displayPage; SetDisplay {} }
    Component { id: soundPage; SetSound {} }
    Component { id: networkPage; SetNetwork {} }
    Component { id: btPage; SetBluetooth {} }
    Component { id: inputPage; SetInput {} }
    Component { id: powerPage; SetPower {} }
    Component { id: appsPage; SetApps {} }

    // ── Вид: обои и переключатели ──
    Component {
        id: lookPage
        Column {
            spacing: 14
            SetTitle { text: "Вид"; hint: "Обои: клик — поставить (переход мозаикой). Ещё: Win+Shift+W." }
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
            PixelSwitch { text: "Живые обои и анимации"; hint: "мерцание, пламя, мозаика, раскрытие Пуска. Выкл — ноль нагрузки"; checked: Store.data.animations; onToggled: v => Store.data.animations = v }
            PixelSwitch { text: "Спокойный режим"; hint: "выключить сюжет, глитчи, угли, живые обои и эффекты окон — если что-то кажется багом"; checked: Mode.calm; onToggled: v => Store.data.effects = !v }
            PixelSwitch { text: "Игровой режим сам, когда окно во весь экран"; hint: "игры и видео без глитчей, звуков и всплывающих уведомлений"; checked: Store.data.autoGameMode; onToggled: v => Store.data.autoGameMode = v }
            PixelSwitch { text: "Звуки"; hint: "колокол уведомлений, шёпот культа, вход в систему"; checked: Store.data.sounds; onToggled: v => Store.data.sounds = v }
            PixelSwitch { text: "Виджеты на столе"; hint: "Гримуар, Око системы, Литания"; checked: Store.data.widgets; onToggled: v => Store.data.widgets = v }
            PixelSwitch { text: "Не беспокоить"; hint: "уведомления только в истории Алтаря"; checked: Store.data.dnd; onToggled: v => Store.data.dnd = v }
        }
    }

    // ── Сюжет ──
    Component {
        id: storyPage
        Column {
            spacing: 14
            SetTitle { text: "Сюжет"; hint: "Вымышленная история: в систему проник вирус культа. Он только рисует — ничего не удаляет, не трогает файлы вне ~/.local/state/baphos и не ходит в сеть." }
            PixelSwitch { text: "Сюжет включён"; hint: "глитчи, послания культа, ритуалы"; checked: Store.data.story; onToggled: v => Store.data.story = v }
            PixelText { text: "Этап заражения: " + Store.data.storyStage + " из 5" }
            PixelButton {
                id: reset
                property bool armed: false
                width: 280; height: 38
                active: armed
                onClicked: { if (armed) { Store.resetStory(); armed = false; } else { armed = true; disarmReset.restart(); } }
                Timer { id: disarmReset; interval: 3000; onTriggered: reset.armed = false }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Image { source: Theme.icon("reload", reset.armed ? "scarlet" : "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                    PixelText { text: reset.armed ? "Точно? Всё забудется" : "Сбросить прогресс"; color: reset.armed ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ── О системе ──
    property string kernel: ""
    property string cpuName: ""
    property string uptime: ""
    property string version: ""
    FileView { path: "/proc/sys/kernel/osrelease"; onLoaded: win.kernel = text().trim() }
    FileView { path: "/proc/cpuinfo"; onLoaded: { const m = text().match(/model name\s*:\s*(.+)/); win.cpuName = m ? m[1].trim() : ""; } }
    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: { const s = Math.floor(Number(text().split(" ")[0])); win.uptime = Math.floor(s / 3600) + " ч " + Math.floor(s % 3600 / 60) + " мин"; }
    }
    FileView { path: Theme.asset("../VERSION"); onLoaded: win.version = text().trim() }
    Timer { interval: 30000; running: win.visible && win.tab === 9; repeat: true; onTriggered: up.reload() }
    Component {
        id: aboutPage
        Column {
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
            PixelText { text: "Шрифты: Monocraft (OFL) · логотип — Jacquard 24 (OFL)"; color: Theme.dim; width: parent.width }
            PixelText { text: "Иконки интерфейса: Pixelarticons (MIT). Остальная графика — своя."; color: Theme.dim; width: parent.width }
            PixelText { text: "github.com/oniczzz/BaphOS"; color: Theme.crimson }
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    RowLayout {
        anchors { fill: parent; margins: 10 }
        spacing: 10

        // ── разделы слева ──
        Bevel {
            kind: "panel"
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            Column {
                anchors.fill: parent
                spacing: 4
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Image { source: Theme.asset("sigil/sigil-32.png"); width: 32; height: 32; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "BaphOS"; color: Theme.scarlet; font.family: Theme.fontGothic; font.pixelSize: 48; renderType: Text.NativeRendering }
                }
                Item { width: 1; height: 4 }
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

        // ── страница справа, с прокруткой ──
        Bevel {
            kind: "panel"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Flickable {
                id: scroll
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + 10 : 0
                boundsBehavior: Flickable.StopAtBounds
                Loader {
                    id: pageLoader
                    width: scroll.width - 8
                    active: win.visible
                    sourceComponent: win.tabs[win.tab][2]
                    onLoaded: scroll.contentY = 0
                    onItemChanged: if (item) item.width = Qt.binding(() => pageLoader.width)
                }
            }
            // полоса прокрутки
            Rectangle {
                visible: scroll.contentHeight > scroll.height
                anchors.right: parent.right
                width: 6; color: Theme.blood
                y: scroll.visibleArea.yPosition * scroll.height
                height: scroll.visibleArea.heightRatio * scroll.height
            }
        }
    }
}
