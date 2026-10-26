import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import ".."

Chevron {
    id: root

    readonly property string monitorName: bar.screen?.name ?? ""
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === monitorName) ?? null
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor?.name === monitorName)
        .sort((a, b) => a.id - b.id)
    readonly property var activeWs: monitor?.activeWorkspace ?? null

    readonly property real btnW: Math.round(fontSize * 1.9)
    readonly property real btnH: Math.round(h * 0.62)

    side: "left"
    accent: Theme.mauve
    contentWidth0: Math.max(1, workspaces.length) * btnW

    onScrolled: d => Hypr.focusWorkspace(d > 0 ? "e-1" : "e+1")

    content: Component {
        Item {
            // Sliding highlight behind the active workspace
            Rectangle {
                readonly property int idx: root.workspaces.indexOf(root.activeWs)
                visible: idx >= 0
                x: Math.max(0, idx) * root.btnW + (root.width - root.insetStart - root.insetEnd - root.workspaces.length * root.btnW) / 2
                anchors.verticalCenter: parent.verticalCenter
                width: root.btnW
                height: root.btnH
                radius: Math.round(5 * root.s)
                color: Theme.alpha(Theme.green, 0.14)
                border.color: Theme.alpha(Theme.green, 0.5)
                border.width: Math.max(1, Math.round(root.s))

                Behavior on x {
                    NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                }
            }

            Row {
                anchors.centerIn: parent

                Repeater {
                    model: root.workspaces

                    Item {
                        id: btn

                        required property var modelData
                        readonly property bool active: modelData === root.activeWs

                        width: root.btnW
                        height: root.h

                        Text {
                            anchors.centerIn: parent
                            text: btn.modelData.name
                            color: btn.modelData.urgent ? Theme.red : btn.active ? Theme.green : wsMouse.containsMouse ? Theme.lavender : Theme.mauve
                            font.family: Theme.font
                            font.pixelSize: root.fontSize
                            font.bold: true

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hypr.focusWorkspace(btn.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
