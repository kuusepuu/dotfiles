import QtQuick
import Quickshell
import qs.config
import qs.services
import ".."

// CPU usage | CPU temperature
Chevron {
    id: root

    readonly property bool critical: HwProbe.hasCpuTemp && SysStats.cpuTemp >= Config.cpuTempCritical
    readonly property var usage: [Icons.cpu, `${Math.round(SysStats.cpu)}%`]

    side: "left"
    accent: critical ? Theme.red : Theme.maroon
    alert: critical
    parts: HwProbe.hasCpuTemp ? [usage, ["", "|"], [Icons.temp, `${Math.round(SysStats.cpuTemp)}°C`]] : [usage]
    compactParts: HwProbe.hasCpuTemp ? [usage, ["", "|"], [Icons.temp, `${Math.round(SysStats.cpuTemp)}°`]] : [usage]

    onClicked: Quickshell.execDetached(Config.sysMonitor)

    CpuPopup {
        target: root
        accent: root.accent
    }
}
