import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.popups
import ".."

Chevron {
    id: root

    side: "left"
    accent: Theme.peach
    priority: 2
    parts: [[Icons.ram, `${SysStats.memUsed.toFixed(1)}G / ${SysStats.memTotal.toFixed(1)}G`]]
    compactParts: [[Icons.ram, `${SysStats.memUsed.toFixed(1)}G`]]

    onClicked: Quickshell.execDetached(Config.sysMonitor)

    BarPopup {
        target: root
        hoverMode: true

        StatPopup {
            s: root.s
            title: `${Icons.ram}  Memory`
            value: `${Math.round(SysStats.memPercent)}%`
            history: SysStats.memHistory
            accent: root.accent
            lines: [["Used", `${SysStats.memUsed.toFixed(1)} GiB`], ["Total", `${SysStats.memTotal.toFixed(1)} GiB`]]
        }
    }
}
