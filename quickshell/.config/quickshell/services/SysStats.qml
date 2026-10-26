pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.config

Singleton {
    id: root

    property real cpu: 0                    // percent
    property real cpuFreq: 0                // GHz, average
    property real cpuTemp: 0                // °C
    property real memUsed: 0                // GiB
    property real memTotal: 0               // GiB
    readonly property real memPercent: memTotal > 0 ? memUsed / memTotal * 100 : 0
    property real gpu: 0                    // percent
    property real gpuTemp: 0
    property real vramUsed: 0               // GiB
    property real vramTotal: 0
    property real netDown: 0                // bytes/s
    property real netUp: 0

    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []

    property var _cpuPrev: null
    property var _netPrev: null

    function push(hist, v) {
        const h = hist.concat([v]);
        return h.length > Config.historyLength ? h.slice(h.length - Config.historyLength) : h;
    }

    function formatRate(b) {
        if (b < 1024 * 1024) return Math.round(b / 1024) + " KB/s";
        if (b < 1024 * 1024 * 1024) return (b / 1048576).toFixed(1) + " MB/s";
        return (b / 1073741824).toFixed(1) + " GB/s";
    }

    Timer {
        interval: Config.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            cpuinfo.reload();
            netdev.reload();
            if (HwProbe.hasCpuTemp) cpuTempFile.reload();
            if (HwProbe.hasGpu) {
                gpuBusy.reload();
                vramUsedFile.reload();
                vramTotalFile.reload();
            }
            if (HwProbe.hasGpuTemp) gpuTempFile.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] ?? 0);
            const total = f.slice(0, 8).reduce((a, b) => a + b, 0);
            if (root._cpuPrev) {
                const dt = total - root._cpuPrev.total;
                if (dt > 0) root.cpu = Math.max(0, Math.min(100, (1 - (idle - root._cpuPrev.idle) / dt) * 100));
                root.cpuHistory = root.push(root.cpuHistory, root.cpu);
            }
            root._cpuPrev = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(/MemTotal:\s+(\d+)/.exec(t)?.[1] ?? 0);
            const avail = Number(/MemAvailable:\s+(\d+)/.exec(t)?.[1] ?? 0);
            root.memTotal = total / 1048576;
            root.memUsed = (total - avail) / 1048576;
            root.memHistory = root.push(root.memHistory, root.memPercent);
        }
    }

    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const re = /cpu MHz\s*:\s*([\d.]+)/g;
            const t = text();
            const mhz = [];
            let m;
            while ((m = re.exec(t)) !== null) mhz.push(Number(m[1]));
            if (mhz.length) root.cpuFreq = mhz.reduce((a, b) => a + b, 0) / mhz.length / 1000;
        }
    }

    FileView {
        id: cpuTempFile
        path: HwProbe.cpuTempPath
        onLoaded: root.cpuTemp = Number(text()) / 1000
    }

    FileView {
        id: gpuBusy
        path: HwProbe.hasGpu ? HwProbe.gpuDevice + "/gpu_busy_percent" : ""
        onLoaded: {
            root.gpu = Number(text());
            root.gpuHistory = root.push(root.gpuHistory, root.gpu);
        }
    }

    FileView {
        id: vramUsedFile
        path: HwProbe.hasGpu ? HwProbe.gpuDevice + "/mem_info_vram_used" : ""
        onLoaded: root.vramUsed = Number(text()) / 1073741824
    }

    FileView {
        id: vramTotalFile
        path: HwProbe.hasGpu ? HwProbe.gpuDevice + "/mem_info_vram_total" : ""
        onLoaded: root.vramTotal = Number(text()) / 1073741824
    }

    FileView {
        id: gpuTempFile
        path: HwProbe.gpuTempPath
        onLoaded: root.gpuTemp = Number(text()) / 1000
    }

    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            // Count only the interfaces NetworkManager reports as connected, so docker/veth/bridges don't double count.
            const active = Networking.devices.values.filter(d => d.connected).map(d => d.name);
            const skip = /^(lo|veth|docker|br-|virbr|vnet|tun|tap|wg)/;
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = /^\s*([^:]+):\s*(.*)$/.exec(line);
                if (!m) continue;
                const name = m[1].trim();
                if (active.length ? !active.includes(name) : skip.test(name)) continue;
                const f = m[2].trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root._netPrev) {
                const dt = (now - root._netPrev.t) / 1000;
                if (dt > 0) {
                    root.netDown = Math.max(0, (rx - root._netPrev.rx) / dt);
                    root.netUp = Math.max(0, (tx - root._netPrev.tx) / dt);
                }
            }
            root._netPrev = { rx, tx, t: now };
        }
    }
}
