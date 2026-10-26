import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.config
import qs.services
import qs.popups
import qs.widgets
import ".."

Chevron {
    id: root

    readonly property var devices: Networking.devices.values.filter(d => d.connected)
    // Prefer wired when both are up
    readonly property var dev: devices.find(d => d.type === DeviceType.Wired) ?? devices[0] ?? null
    readonly property bool wifi: dev?.type === DeviceType.Wifi

    side: "right"
    accent: dev ? Theme.green : Theme.red
    parts: dev ? [[Icons.down, SysStats.formatRate(SysStats.netDown)], [Icons.up, SysStats.formatRate(SysStats.netUp)]] : [[Icons.offline, "Offline"]]
    compactParts: dev ? [[Icons.down, SysStats.formatRate(SysStats.netDown)]] : [[Icons.offline, ""]]

    onClicked: Quickshell.execDetached(Config.netTool)

    BarPopup {
        id: popup
        target: root
        hoverMode: true

        onOpenChanged: if (open && root.dev) addr.running = true

        Process {
            id: addr
            property string ip4: ""
            command: ["ip", "-j", "addr", "show", "dev", root.dev?.name ?? "lo"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const info = JSON.parse(text)[0]?.addr_info ?? [];
                        addr.ip4 = info.filter(a => a.family === "inet").map(a => `${a.local}/${a.prefixlen}`).join(", ");
                    } catch (e) {
                        addr.ip4 = "";
                    }
                }
            }
        }

        Label {
            s: root.s
            text: root.dev ? `${root.wifi ? Icons.wifi : Icons.ethernet}  ${root.wifi ? (root.dev.network?.name ?? root.dev.name) : root.dev.name}` : `${Icons.offline}  No connection`
            color: root.accent
            font.bold: true
        }

        Repeater {
            model: root.dev ? [
                ["Interface", root.dev.name],
                ["Address", addr.ip4 || "…"],
                root.wifi ? ["Signal", `${Math.round((root.dev.network?.signalStrength ?? 0) * 100)}%`] : ["Link", `${root.dev.linkSpeed ?? "?"} Mb/s`],
                ["Down", SysStats.formatRate(SysStats.netDown)],
                ["Up", SysStats.formatRate(SysStats.netUp)],
            ] : []

            Item {
                required property var modelData
                width: Math.round(240 * root.s)
                height: k.implicitHeight

                Label {
                    id: k
                    s: root.s
                    size: Theme.fontSizeSmall
                    text: modelData[0]
                    color: Theme.subtext0
                }

                Label {
                    anchors.right: parent.right
                    s: root.s
                    size: Theme.fontSizeSmall
                    text: modelData[1]
                }
            }
        }
    }
}
