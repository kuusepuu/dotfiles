import QtQuick
import Quickshell
import qs.config
import qs.services
import ".."

// GPU usage | GPU temperature
Chevron {
    id: root

    readonly property bool critical: HwProbe.hasGpuTemp && SysStats.gpuTemp >= Config.gpuTempCritical
    readonly property var usage: [Icons.gpu, `${Math.round(SysStats.gpu)}%`]

    side: "left"
    accent: critical ? Theme.red : Theme.teal
    alert: critical
    present: HwProbe.hasGpu
    parts: HwProbe.hasGpuTemp ? [usage, ["", "|"], [Icons.temp, `${Math.round(SysStats.gpuTemp)}°C`]] : [usage]
    compactParts: HwProbe.hasGpuTemp ? [usage, ["", "|"], [Icons.temp, `${Math.round(SysStats.gpuTemp)}°`]] : [usage]

    onClicked: Quickshell.execDetached(Config.gpuTool)

    GpuPopup {
        target: root
        accent: root.accent
    }
}
