import QtQuick
import qs.config
import qs.services
import qs.popups

BarPopup {
    id: popup

    hoverMode: true
    accent: Theme.maroon

    StatPopup {
        s: popup.s
        title: `${Icons.cpu}  CPU`
        value: `${Math.round(SysStats.cpu)}%`
        history: SysStats.cpuHistory
        accent: popup.accent
        lines: {
            const l = [["Frequency", `${SysStats.cpuFreq.toFixed(2)} GHz`]];
            if (HwProbe.hasCpuTemp) l.push(["Temperature", `${Math.round(SysStats.cpuTemp)}°C`]);
            l.push(["Memory", `${SysStats.memUsed.toFixed(1)} / ${SysStats.memTotal.toFixed(1)} GiB`]);
            return l;
        }
    }
}
