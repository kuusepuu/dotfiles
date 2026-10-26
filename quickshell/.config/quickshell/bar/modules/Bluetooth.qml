import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.config
import qs.popups
import qs.widgets
import ".."

Chevron {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var first: connected[0] ?? null

    function devName(d) {
        return d.name || d.deviceName || d.address;
    }

    function devBattery(d) {
        return d.batteryAvailable ? ` ${Math.round(d.battery * 100)}%` : "";
    }

    side: "right"
    accent: on ? Theme.sky : Theme.overlay1
    present: Bluetooth.adapters.values.length > 0
    parts: [!on ? [Icons.btOff, "Off"]
        : first ? [Icons.btConnected, `${devName(first)}${devBattery(first)}${connected.length > 1 ? " +" + (connected.length - 1) : ""}`]
        : [Icons.bt, "On"]]
    compactParts: [!on ? [Icons.btOff, ""] : first ? [Icons.btConnected, connected.length > 1 ? String(connected.length) : ""] : [Icons.bt, ""]]

    onClicked: Quickshell.execDetached(Config.btTool)

    BarPopup {
        target: root
        hoverMode: true

        Item {
            width: Math.max(Math.round(220 * root.s), title.implicitWidth + toggle.implicitWidth + Math.round(16 * root.s))
            height: toggle.implicitHeight

            Label {
                id: title
                s: root.s
                anchors.verticalCenter: parent.verticalCenter
                text: `${Icons.bt}  ${root.adapter?.name ?? "Bluetooth"}`
                color: root.accent
                font.bold: true
            }

            IconButton {
                id: toggle
                s: root.s
                anchors.right: parent.right
                text: root.on ? "On" : "Off"
                accent: root.on ? Theme.green : Theme.overlay1
                active: root.on
                onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }
        }

        Label {
            s: root.s
            size: Theme.fontSizeSmall
            visible: root.connected.length === 0
            text: root.on ? "No devices connected" : "Adapter is off"
            color: Theme.subtext0
        }

        Repeater {
            model: root.connected

            Label {
                required property var modelData
                s: root.s
                size: Theme.fontSizeSmall
                text: `${Icons.btConnected}  ${root.devName(modelData)}${root.devBattery(modelData)}`
            }
        }
    }
}
