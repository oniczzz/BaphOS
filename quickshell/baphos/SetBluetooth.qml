// Настройки → Bluetooth: вкл/выкл, поиск, устройства (подключить, отключить, сопрячь, забыть).
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Column {
    id: page
    spacing: 12
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name || "").localeCompare(b.name || "")) : []

    SetTitle { text: "Bluetooth"; hint: page.adapter ? "Включи поиск, чтобы найти новые устройства." : "Адаптер Bluetooth не найден." }

    Row {
        spacing: 12
        visible: page.adapter !== null
        PixelSwitch { width: 220; text: "Bluetooth"; checked: page.adapter?.enabled ?? false; onToggled: v => page.adapter.enabled = v }
        PixelSwitch { width: 260; text: "Искать устройства"; checked: page.adapter?.discovering ?? false; onToggled: v => page.adapter.discovering = v }
    }

    Repeater {
        model: page.adapter?.enabled ? page.devices : []
        Bevel {
            id: dev
            required property var modelData
            kind: modelData.connected ? "btn-active" : "btn"
            width: page.width; height: 44
            Row {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 10
                Image { source: Theme.icon("bluetooth", dev.modelData.connected ? "scarlet" : "dim"); width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    PixelText { text: dev.modelData.name || dev.modelData.address; color: dev.modelData.connected ? Theme.scarlet : Theme.text }
                    PixelText { text: dev.modelData.connected ? "подключено" : dev.modelData.paired ? "сопряжено" : "рядом"; color: Theme.dim; font.pixelSize: 12 }
                }
            }
            Row {
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                spacing: 6
                PixelButton {
                    width: 150; height: 30
                    onClicked: {
                        if (dev.modelData.connected) dev.modelData.disconnect();
                        else if (dev.modelData.paired) dev.modelData.connect();
                        else dev.modelData.pair();
                    }
                    PixelText { anchors.centerIn: parent; text: dev.modelData.connected ? "Отключить" : dev.modelData.paired ? "Подключить" : "Сопрячь" }
                }
                PixelButton {
                    visible: dev.modelData.paired
                    width: 100; height: 30
                    onClicked: dev.modelData.forget()
                    PixelText { anchors.centerIn: parent; text: "Забыть"; color: Theme.dim }
                }
            }
        }
    }
}
