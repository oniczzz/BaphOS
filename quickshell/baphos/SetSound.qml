// Настройки → Звук: устройство вывода и ввода (клик — сделать основным), громкость каждого.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Column {
    id: page
    spacing: 14
    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var sinks: nodes.filter(n => n.isSink)
    readonly property var sources: nodes.filter(n => !n.isSink)
    PwObjectTracker { objects: page.nodes }

    SetTitle { text: "Звук"; hint: "Клик по устройству — сделать его основным." }

    Repeater {
        model: [["Вывод", page.sinks, true], ["Ввод (микрофон)", page.sources, false]]
        Column {
            id: group
            required property var modelData
            width: page.width
            spacing: 6
            PixelText { text: group.modelData[0]; color: Theme.scarlet }
            Repeater {
                model: group.modelData[1]
                Bevel {
                    id: dev
                    required property var modelData
                    readonly property bool isDefault: group.modelData[2] ? Pipewire.defaultAudioSink === modelData : Pipewire.defaultAudioSource === modelData
                    kind: isDefault ? "btn-active" : "btn"
                    width: group.width; height: 78
                    Column {
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 2 }
                        spacing: 4
                        PixelText {
                            width: parent.width
                            text: (dev.isDefault ? "† " : "") + (dev.modelData.description || dev.modelData.nickname || dev.modelData.name)
                            color: dev.isDefault ? Theme.scarlet : Theme.text
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (group.modelData[2]) Pipewire.preferredDefaultAudioSink = dev.modelData;
                                    else Pipewire.preferredDefaultAudioSource = dev.modelData;
                                }
                            }
                        }
                        PixelSlider {
                            width: parent.width
                            icon: group.modelData[2] ? (dev.modelData.audio.muted ? "volume-x" : "volume-3") : (dev.modelData.audio.muted ? "mic-off" : "mic")
                            value: Math.min(1, dev.modelData.audio.volume)
                            muted: dev.modelData.audio.muted
                            onMoved: v => dev.modelData.audio.volume = v
                            onIconClicked: dev.modelData.audio.muted = !dev.modelData.audio.muted
                        }
                    }
                }
            }
        }
    }
}
