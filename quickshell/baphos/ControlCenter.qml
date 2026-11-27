// BaphOS: «Алтарь» — центр управления (клик по часам/трею, Mod+N). Вырастает над панелью справа.
//   шапка (сигил, бодрствование, питание) · ползунки (звук, микрофон, яркость)
//   плитки (Wi-Fi, Bluetooth, Не беспокоить, Ночной свет, Живые обои, Сюжет) · календарь · уведомления
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

PanelWindow {
    id: cc
    property bool open: false
    signal closeRequested()
    signal lockRequested()

    property bool shown: false
    property int reveal: 0
    readonly property int panelH: Math.min(740, cc.height - Theme.barHeight - 8)

    visible: true
    mask: Region { item: cc.shown ? catcher : nothing }
    Item { id: nothing; width: 0; height: 0 }
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "baphos-altar"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            reveal = Store.data.animations ? 0 : panelH;
            shown = true;
            readBrightness.running = true;
            readWifi.running = true;
            readUptime.reload();
            month = new Date();
        }
        stepper.restart();
    }
    Timer {
        id: stepper
        interval: 16; repeat: true
        onTriggered: {
            if (cc.open) { cc.reveal = Math.min(cc.panelH, cc.reveal + 56); if (cc.reveal >= cc.panelH) stop(); }
            else { cc.reveal = Math.max(0, cc.reveal - cc.panelH / 3); if (cc.reveal <= 0) { stop(); cc.shown = false; } }
        }
    }

    // ── данные ──
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var source: Pipewire.defaultAudioSource?.audio ?? null

    property real brightness: 0
    property int brightMax: 1
    Process {
        id: readBrightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");      // устройство,класс,текущее,процент,максимум
                if (f.length >= 5) { cc.brightness = Number(f[2]) / Number(f[4]); cc.brightMax = Number(f[4]); }
            }
        }
    }
    function setBrightness(v) {
        brightness = v;
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(1, Math.round(v * 100)) + "%"]);
    }

    property bool wifi: false
    Process {
        id: readWifi
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: cc.wifi = text.trim() === "enabled" }
    }
    function toggleWifi() {
        wifi = !wifi;
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifi ? "on" : "off"]);
    }

    readonly property var bt: Bluetooth.defaultAdapter
    // скриншот после того, как Алтарь закроется (чтобы его не было в кадре)
    Timer { id: shotDelay; interval: 350; onTriggered: Shot.begin() }
    property string uptime: ""
    FileView {
        id: readUptime
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            cc.uptime = Math.floor(s / 3600) + " ч " + Math.floor(s % 3600 / 60) + " мин";
        }
    }

    // ночной свет: wlsunset живёт, пока включён (тёплый экран 3400K)
    Process {
        running: Store.data.nightLight
        command: ["wlsunset", "-t", "3400", "-T", "3401"]
    }

    // календарь
    property date month: new Date()
    readonly property var monthNames: ["январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь"]
    readonly property var cells: {
        const y = month.getFullYear(), m = month.getMonth();
        const first = (new Date(y, m, 1).getDay() + 6) % 7;          // понедельник = 0
        const days = new Date(y, m + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < 42; i++) { const d = i - first + 1; out.push(d >= 1 && d <= days ? d : 0); }
        return out;
    }
    readonly property bool thisMonth: { const n = new Date(); return n.getMonth() === month.getMonth() && n.getFullYear() === month.getFullYear(); }

    MouseArea { id: catcher; anchors.fill: parent; enabled: cc.shown; onClicked: cc.closeRequested() }
    Item { focus: cc.open; Keys.onEscapePressed: cc.closeRequested() }

    Item {
        id: clipper
        width: 440 + 8
        height: cc.reveal
        clip: true
        visible: cc.shown
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: Theme.barHeight - 4 }

        Rectangle { x: 8; y: clipper.height - cc.panelH + 8; width: 440; height: cc.panelH - 8; color: "#000000"; opacity: 0.55 }

        Bevel {
            kind: "panel"
            width: 440; height: cc.panelH - 8
            y: clipper.height - cc.panelH
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // ── шапка ──
                RowLayout {
                    spacing: 10
                    Image { source: Theme.asset("sigil/sigil-32.png"); Layout.preferredWidth: 32; Layout.preferredHeight: 32; smooth: false }
                    ColumnLayout {
                        spacing: 0
                        PixelText { text: "Алтарь"; color: Theme.scarlet; font.pixelSize: 24 }
                        PixelText { text: "бодрствует " + cc.uptime; color: Theme.dim; font.pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Repeater {
                        model: [["lock", null], ["logout", ["niri", "msg", "action", "quit", "--skip-confirmation"]],
                                ["reload", ["systemctl", "reboot"]], ["power", ["systemctl", "poweroff"]]]
                        PixelButton {
                            id: pb
                            required property var modelData
                            property bool armed: false
                            Layout.preferredWidth: 36; Layout.preferredHeight: 36
                            active: armed
                            onClicked: {
                                if (!modelData[1]) { cc.closeRequested(); cc.lockRequested(); return; }
                                if (armed) Quickshell.execDetached(modelData[1]); else { armed = true; disarm.restart(); }
                            }
                            Timer { id: disarm; interval: 3000; onTriggered: pb.armed = false }
                            Image { anchors.centerIn: parent; source: Theme.icon(pb.modelData[0], pb.armed || pb.hovered ? "scarlet" : "bone"); width: 24; height: 24; smooth: false }
                        }
                    }
                }

                // ── ползунки ──
                PixelSlider {
                    Layout.fillWidth: true
                    icon: !cc.sink || cc.sink.muted ? "volume-x" : (cc.sink.volume > 0.66 ? "volume-3" : cc.sink.volume > 0.33 ? "volume-2" : "volume-1")
                    value: cc.sink ? Math.min(1, cc.sink.volume) : 0
                    muted: cc.sink?.muted ?? true
                    onMoved: v => { if (cc.sink) cc.sink.volume = v; }
                    onIconClicked: if (cc.sink) cc.sink.muted = !cc.sink.muted
                }
                PixelSlider {
                    Layout.fillWidth: true
                    visible: cc.source !== null
                    icon: cc.source?.muted ? "mic-off" : "mic"
                    value: cc.source ? Math.min(1, cc.source.volume) : 0
                    muted: cc.source?.muted ?? true
                    onMoved: v => { if (cc.source) cc.source.volume = v; }
                    onIconClicked: if (cc.source) cc.source.muted = !cc.source.muted
                }
                PixelSlider {
                    Layout.fillWidth: true
                    icon: "sun"
                    value: cc.brightness
                    onMoved: v => cc.setBrightness(v)
                }

                // ── плитки ──
                // игровой режим — во всю ширину
                QuickTile {
                    Layout.fillWidth: true
                    icon: "gamepad"
                    label: "Игровой режим"
                    on: Store.data.gameMode
                    sub: Store.data.gameMode ? "тишина: без глитчей, звуков и всплывашек"
                       : Mode.quiet ? "сейчас сам: окно во весь экран" : "выкл — Mod+G"
                    onClicked: Store.data.gameMode = !Store.data.gameMode
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 6; rowSpacing: 6
                    QuickTile { Layout.fillWidth: true; icon: "wifi"; label: "Wi-Fi"; sub: cc.wifi ? "включён" : "выключен"; on: cc.wifi; onClicked: cc.toggleWifi() }
                    QuickTile {
                        Layout.fillWidth: true; icon: "bluetooth"; label: "Bluetooth"
                        on: cc.bt?.enabled ?? false
                        sub: !cc.bt ? "нет адаптера" : (cc.bt.enabled ? "включён" : "выключен")
                        onClicked: if (cc.bt) cc.bt.enabled = !cc.bt.enabled
                    }
                    QuickTile { Layout.fillWidth: true; icon: Store.data.dnd ? "bell-off" : "bell"; label: "Не беспокоить"; sub: Store.data.dnd ? "тишина" : "выкл"; on: Store.data.dnd; onClicked: Store.data.dnd = !Store.data.dnd }
                    QuickTile { Layout.fillWidth: true; icon: "moon"; label: "Ночной свет"; sub: Store.data.nightLight ? "тёплый экран" : "выкл"; on: Store.data.nightLight; onClicked: Store.data.nightLight = !Store.data.nightLight }
                    QuickTile { Layout.fillWidth: true; icon: "sparkles"; label: "Живые обои"; sub: Store.data.animations ? "анимации" : "выкл"; on: Store.data.animations; onClicked: Store.data.animations = !Store.data.animations }
                    QuickTile { Layout.fillWidth: true; icon: Store.data.sounds ? "volume-3" : "volume-x"; label: "Звуки"; sub: Store.data.sounds ? "колокол, шёпот" : "выкл"; on: Store.data.sounds; onClicked: Store.data.sounds = !Store.data.sounds }
                    QuickTile { Layout.fillWidth: true; icon: "monitor"; label: "Скриншот"; sub: "выделить область"; onClicked: { cc.closeRequested(); shotDelay.start(); } }
                    QuickTile { Layout.fillWidth: true; icon: "skull"; label: "Сюжет"; sub: Store.data.story ? "этап " + Store.data.storyStage : "выкл"; on: Store.data.story; onClicked: Store.data.story = !Store.data.story }
                }

                // ── календарь ──
                Bevel {
                    kind: "well"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 196
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            PixelText { text: "‹"; color: Theme.scarlet; font.pixelSize: 24; MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: cc.month = new Date(cc.month.getFullYear(), cc.month.getMonth() - 1, 1) } }
                            PixelText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: cc.monthNames[cc.month.getMonth()] + " " + cc.month.getFullYear(); color: Theme.scarlet }
                            PixelText { text: "›"; color: Theme.scarlet; font.pixelSize: 24; MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: cc.month = new Date(cc.month.getFullYear(), cc.month.getMonth() + 1, 1) } }
                        }
                        Grid {
                            Layout.alignment: Qt.AlignHCenter
                            columns: 7
                            columnSpacing: 2; rowSpacing: 0
                            Repeater {
                                model: ["пн", "вт", "ср", "чт", "пт", "сб", "вс"]
                                PixelText { required property string modelData; required property int index; width: 52; horizontalAlignment: Text.AlignHCenter; text: modelData; color: index >= 5 ? Theme.crimson : Theme.dim; font.pixelSize: 12 }
                            }
                            Repeater {
                                model: cc.cells
                                Rectangle {
                                    required property int modelData
                                    required property int index
                                    readonly property bool today: cc.thisMonth && modelData === new Date().getDate()
                                    width: 52; height: 22
                                    color: today ? Theme.scarlet : "transparent"
                                    PixelText {
                                        anchors.centerIn: parent
                                        text: parent.modelData || ""
                                        color: parent.today ? Theme.bg : (parent.index % 7 >= 5 ? Theme.crimson : Theme.text)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── уведомления ──
                RowLayout {
                    Layout.fillWidth: true
                    Image { source: Theme.icon("bell", "bone"); Layout.preferredWidth: 24; Layout.preferredHeight: 24; smooth: false }
                    PixelText { Layout.fillWidth: true; text: "Шёпоты (" + Inbox.items.length + ")"; color: Theme.text }
                    PixelButton {
                        Layout.preferredWidth: 110; Layout.preferredHeight: 28
                        visible: Inbox.items.length > 0
                        onClicked: Inbox.clear()
                        PixelText { anchors.centerIn: parent; text: "Очистить"; color: Theme.dim }
                    }
                }
                Bevel {
                    kind: "well"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        anchors.fill: parent
                        clip: true
                        model: Inbox.items
                        spacing: 4
                        delegate: Column {
                            required property var modelData
                            width: ListView.view.width
                            PixelText { width: parent.width; text: modelData.time + "  " + (modelData.app || "") ; color: Theme.dim; font.pixelSize: 12 }
                            PixelText { width: parent.width; text: modelData.summary; color: Theme.scarlet }
                            PixelText { width: parent.width; text: modelData.body; color: Theme.text; visible: text !== ""; maximumLineCount: 2; wrapMode: Text.Wrap }
                        }
                        PixelText { anchors.centerIn: parent; visible: Inbox.items.length === 0; text: "Тишина. Никто не шепчет."; color: Theme.dim }
                    }
                }
            }
        }
    }
}
