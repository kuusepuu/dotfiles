pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Resolves hardware paths once at startup so nothing depends on hwmonN numbering.
Singleton {
    id: root

    property bool ready: false
    property string cpuTempPath: ""
    property string gpuDevice: ""           // /sys/class/drm/cardN/device
    property string gpuTempPath: ""
    property string backlight: ""           // /sys/class/backlight/<dev>

    readonly property bool hasCpuTemp: cpuTempPath !== ""
    readonly property bool hasGpu: gpuDevice !== ""
    readonly property bool hasGpuTemp: gpuTempPath !== ""
    readonly property bool hasBacklight: backlight !== ""

    Process {
        running: true
        command: ["sh", "-c", `
            for want in k10temp coretemp zenpower; do
                for d in /sys/class/hwmon/hwmon*; do
                    [ "$(cat "$d/name" 2>/dev/null)" = "$want" ] && [ -r "$d/temp1_input" ] && { echo "cpuTemp=$d/temp1_input"; break 2; }
                done
            done
            want_card="$1"; best=""; best_vram=-1
            for c in /sys/class/drm/card[0-9]*; do
                case "$c" in *-*) continue ;; esac
                [ -r "$c/device/gpu_busy_percent" ] || continue
                if [ -n "$want_card" ]; then
                    [ "$(basename "$c")" = "$want_card" ] && { best="$c"; break; }
                    continue
                fi
                v=$(cat "$c/device/mem_info_vram_total" 2>/dev/null || echo 0)
                [ "$v" -gt "$best_vram" ] && { best="$c"; best_vram="$v"; }
            done
            if [ -n "$best" ]; then
                echo "gpu=$(readlink -f "$best/device")"
                for t in "$best"/device/hwmon/hwmon*/temp1_input; do [ -r "$t" ] && { echo "gpuTemp=$t"; break; }; done
            fi
            for b in /sys/class/backlight/*; do [ -r "$b/brightness" ] && { echo "backlight=$b"; break; }; done
            true
        `, "probe", Config.gpuCard]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i < 0) continue;
                    const k = line.slice(0, i), v = line.slice(i + 1);
                    if (k === "cpuTemp") root.cpuTempPath = v;
                    else if (k === "gpu") root.gpuDevice = v;
                    else if (k === "gpuTemp") root.gpuTempPath = v;
                    else if (k === "backlight") root.backlight = v;
                }
                root.ready = true;
            }
        }
    }
}
