// Настройки → Сеть: Wi-Fi вкл/выкл, список сетей (nmcli), подключение (пароль — если сеть новая).
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: page
    spacing: 12
    property bool wifi: true
    property var nets: []          // [{ ssid, signal, secure, inUse, known }]
    property var known: []
    property string asking: ""     // сеть, для которой спрашиваем пароль
    property string status: ""

    function reload() { radio.running = true; knownProc.running = true; list.running = true; }
    Component.onCompleted: reload()
    Process { id: radio; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { onStreamFinished: page.wifi = text.trim() === "enabled" } }
    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector { onStreamFinished: page.known = text.split("\n").filter(l => l.includes("wireless")).map(l => l.split(":")[0]) }
    }
    Process {
        id: list
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const l of text.split("\n")) {
                    const f = l.split(":");
                    if (f.length < 4 || !f[1] || seen[f[1]]) continue;
                    seen[f[1]] = true;
                    out.push({ ssid: f[1], signal: Number(f[2]), secure: f[3] !== "" && f[3] !== "--", inUse: f[0] === "*" });
                }
                page.nets = out.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
            }
        }
    }
    Process {
        id: act
        stdout: StdioCollector { onStreamFinished: page.status = text.trim().split("\n").pop() }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop() }
        onExited: refresh.restart()
    }
    Timer { id: refresh; interval: 1500; onTriggered: page.reload() }

    function connect(n) {
        status = "Подключаюсь к " + n.ssid + "...";
        if (!n.secure || known.includes(n.ssid)) act.command = known.includes(n.ssid) ? ["nmcli", "connection", "up", "id", n.ssid] : ["nmcli", "dev", "wifi", "connect", n.ssid];
        else { asking = n.ssid; status = ""; return; }
        act.running = true;
    }

    SetTitle { text: "Сеть"; hint: "Клик по сети — подключиться. Для новой защищённой сети спросит пароль." }

    Row {
        spacing: 8
        PixelSwitch {
            width: 240
            text: "Wi-Fi"
            checked: page.wifi
            onToggled: v => { page.wifi = v; Quickshell.execDetached(["nmcli", "radio", "wifi", v ? "on" : "off"]); refresh.restart(); }
        }
        PixelButton {
            width: 160; height: 32
            onClicked: { page.status = "Ищу сети..."; page.reload(); }
            Row { anchors.centerIn: parent; spacing: 6
                Image { source: Theme.icon("reload", "bone"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                PixelText { text: "Обновить"; anchors.verticalCenter: parent.verticalCenter } }
        }
    }
    PixelText { text: page.status; visible: text !== ""; color: Theme.dim; width: page.width; wrapMode: Text.Wrap; elide: Text.ElideNone }

    // пароль для новой сети
    Row {
        visible: page.asking !== ""
        spacing: 8
        PixelText { text: "Пароль для «" + page.asking + "»:"; anchors.verticalCenter: parent.verticalCenter }
        Bevel {
            kind: "well"; width: 260; height: 32
            TextInput {
                id: pass
                anchors { fill: parent; leftMargin: 6 }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password; passwordCharacter: "†"
                color: Theme.scarlet; font.family: Theme.font; font.pixelSize: Theme.fontPx
                onAccepted: {
                    page.status = "Подключаюсь к " + page.asking + "...";
                    act.command = ["nmcli", "dev", "wifi", "connect", page.asking, "password", text];
                    act.running = true; text = ""; page.asking = "";
                }
            }
        }
        PixelButton { width: 100; height: 32; onClicked: { pass.text = ""; page.asking = ""; } PixelText { anchors.centerIn: parent; text: "Отмена"; color: Theme.dim } }
    }

    Repeater {
        model: page.wifi ? page.nets : []
        PixelButton {
            id: net
            required property var modelData
            width: page.width; height: 36
            active: modelData.inUse
            onClicked: if (!modelData.inUse) page.connect(modelData)
            Row {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 10
                Image { source: Theme.icon("wifi", net.modelData.inUse ? "scarlet" : net.modelData.signal > 60 ? "bone" : "dim"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                PixelText { width: page.width - 260; text: net.modelData.ssid; color: net.modelData.inUse ? Theme.scarlet : Theme.text; anchors.verticalCenter: parent.verticalCenter }
            }
            PixelText {
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: (net.modelData.inUse ? "подключено · " : page.known.includes(net.modelData.ssid) ? "известная · " : "")
                      + (net.modelData.secure ? "пароль · " : "открытая · ") + net.modelData.signal + "%"
                color: Theme.dim
            }
        }
    }
}
