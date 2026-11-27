// BaphOS: загрузка CPU, память и температура CPU из /proc и /sys раз в 2 секунды.
// Датчик coretemp ищется по имени один раз (номер hwmon меняется от загрузки к загрузке).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property int temp: 0          // °C

    property var _prev: null
    property string tempPath: ""

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dt = total - root._prev.total, di = idle - root._prev.idle;
                root.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            }
            root._prev = { total: total, idle: idle };
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kv = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) kv[m[1]] = Number(m[2]);
            }
            if (kv.MemTotal) {
                root.memTotalGb = kv.MemTotal / 1048576;
                root.memUsedGb = (kv.MemTotal - kv.MemAvailable) / 1048576;
                root.mem = root.memUsedGb / root.memTotalGb;
            }
        }
    }
    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.temp = Math.round(Number(text().trim()) / 1000)
    }
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$h/name\")\" = coretemp ] && { echo \"$h/temp1_input\"; exit; }; done; for h in /sys/class/hwmon/hwmon*; do [ -r \"$h/temp1_input\" ] && { echo \"$h/temp1_input\"; exit; }; done"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); if (root.tempPath) tempFile.reload(); }
    }
}
