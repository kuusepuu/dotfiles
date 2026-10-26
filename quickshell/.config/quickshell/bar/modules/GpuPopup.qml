import QtQuick
import qs.config
import qs.services
import qs.popups

BarPopup {
    id: popup

    hoverMode: true
    accent: Theme.teal

    StatPopup {
        s: popup.s
        title: `${Icons.gpu}  GPU`
        value: `${Math.round(SysStats.gpu)}%`
        history: SysStats.gpuHistory
        accent: popup.accent
        lines: {
            const l = [["VRAM", `${SysStats.vramUsed.toFixed(1)} / ${SysStats.vramTotal.toFixed(0)} GiB`]];
            if (HwProbe.hasGpuTemp) l.push(["Temperature", `${Math.round(SysStats.gpuTemp)}°C`]);
            return l;
        }
    }
}
