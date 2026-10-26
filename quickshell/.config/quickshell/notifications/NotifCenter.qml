import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets

// Slide-out history panel (bell click / SUPER+H)
PanelWindow {
    id: win

    readonly property bool open: Notifs.centerOpen
    readonly property real s: Config.scaleFor(screen)
    readonly property real pad: Math.round(12 * s)

    // Pick the screen when opening, so it doesn't jump monitors while open
    onOpenChanged: if (open) screen = Hypr.focusedScreen
    screen: Hypr.focusedScreen

    anchors {
        top: true
        right: true
    }
    margins {
        top: Math.round(6 * s)
        right: Math.round(Theme.margin * s)
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: Math.round(420 * s)
    implicitHeight: panel.height
    color: "transparent"
    visible: open || panel.opacity > 0.01
    WlrLayershell.namespace: "quickshell:notifcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: win.open
        windows: [win, ...ShellState.barWindows]
        onCleared: Notifs.centerOpen = false
    }

    Rectangle {
        id: panel

        width: parent.width
        height: content.implicitHeight + 2 * win.pad
        x: win.open ? 0 : width / 3
        opacity: win.open ? 1 : 0
        radius: Math.round(Theme.radius * win.s)
        color: Theme.bg
        border.color: Theme.pink
        border.width: Math.max(1, Math.round(Theme.border * win.s))
        focus: win.open

        Keys.onEscapePressed: Notifs.centerOpen = false

        Behavior on x {
            NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animMed }
        }

        Column {
            id: content
            x: win.pad
            y: win.pad
            width: parent.width - 2 * win.pad
            spacing: Math.round(10 * win.s)

            Item {
                width: parent.width
                height: dnd.implicitHeight

                Label {
                    s: win.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Icons.bell}  Notifications`
                    color: Theme.pink
                    font.bold: true
                }

                Row {
                    anchors.right: parent.right
                    spacing: Math.round(6 * win.s)

                    IconButton {
                        id: dnd
                        s: win.s
                        text: Notifs.dnd ? `${Icons.bellOff} DND` : `${Icons.bell} DND`
                        accent: Notifs.dnd ? Theme.peach : Theme.overlay2
                        active: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }

                    IconButton {
                        s: win.s
                        text: `${Icons.clearAll} Clear`
                        accent: Theme.red
                        visible: Notifs.entries.length > 0
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            Label {
                s: win.s
                visible: Notifs.entries.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: Math.round(16 * win.s)
                bottomPadding: Math.round(16 * win.s)
                text: "No notifications"
                color: Theme.overlay1
            }

            ListView {
                id: list
                visible: count > 0
                width: parent.width
                height: Math.min(contentHeight, (win.screen?.height ?? 1080) * 0.7 - y - 2 * win.pad)
                clip: true
                spacing: Math.round(8 * win.s)
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel {
                    values: Notifs.entries
                }

                delegate: NotifCard {
                    required property var modelData
                    entry: modelData
                    s: win.s
                    inCenter: true
                    width: list.width
                }

                remove: Transition {
                    NumberAnimation { property: "x"; to: list.width; duration: Theme.animMed; easing.type: Easing.InCubic }
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.animMed }
                }
            }
        }
    }
}
