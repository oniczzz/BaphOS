// Настройки → Питание: профиль (power-profiles-daemon), автоблокировка, батарея.
import QtQuick
import Quickshell.Services.UPower

Column {
    id: page
    spacing: 16
    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0

    SetTitle { text: "Питание" }

    Choice {
        label: "Режим работы"
        options: [[PowerProfile.PowerSaver, "Экономия"], [PowerProfile.Balanced, "Баланс"]]
                 .concat(PowerProfiles.hasPerformanceProfile ? [[PowerProfile.Performance, "Производительность"]] : [])
        current: PowerProfiles.profile
        onPicked: v => PowerProfiles.profile = v
    }

    Choice {
        label: "Блокировать экран, если простаивает"
        options: [[5, "5 мин"], [10, "10 мин"], [15, "15 мин"], [30, "30 мин"], [60, "1 час"], [0, "никогда"]]
        current: Store.data.lockMinutes
        onPicked: v => Store.data.lockMinutes = v
    }

    Column {
        visible: page.dev && page.dev.isLaptopBattery
        width: page.width; spacing: 6
        PixelText { text: "Батарея"; color: Theme.scarlet }
        PixelBar { width: Math.min(page.width, 520); value: page.pct / 100 }
        PixelText {
            text: Math.round(page.pct) + "% · " + (page.dev?.state === UPowerDeviceState.Charging ? "заряжается"
                  : page.dev?.state === UPowerDeviceState.FullyCharged ? "заряжена" : "от батареи")
            color: Theme.dim
        }
    }
}
