import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.popups
import qs.widgets
import ".."

Chevron {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real pct: !dev ? 0 : dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && pct < 20
    readonly property bool critical: !charging && pct < 10

    function duration(sec) {
        if (!sec) return "–";
        const h = Math.floor(sec / 3600), m = Math.round(sec % 3600 / 60);
        return h ? `${h}h ${m}m` : `${m}m`;
    }

    side: "right"
    present: dev?.isLaptopBattery ?? false
    accent: critical ? Theme.red : low ? Theme.yellow : Theme.green
    alert: critical
    parts: [[charging ? Icons.batteryCharging : Icons.battery(pct), `${Math.round(pct)}%`]]

    BarPopup {
        target: root
        hoverMode: true

        Label {
            s: root.s
            text: `${Icons.battery(root.pct)}  Battery ${Math.round(root.pct)}%`
            color: root.accent
            font.bold: true
        }

        Label {
            s: root.s
            size: Theme.fontSizeSmall
            text: root.charging ? `Full in ${root.duration(root.dev?.timeToFull)}` : `Empty in ${root.duration(root.dev?.timeToEmpty)}`
            color: Theme.subtext0
        }

        Label {
            s: root.s
            size: Theme.fontSizeSmall
            visible: (root.dev?.changeRate ?? 0) !== 0
            text: `${Math.abs(root.dev?.changeRate ?? 0).toFixed(1)} W`
            color: Theme.subtext0
        }
    }
}
