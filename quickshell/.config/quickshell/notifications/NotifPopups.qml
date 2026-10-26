import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Popups top-right on the focused monitor
PanelWindow {
    id: win

    readonly property real s: Config.scaleFor(screen)

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
    implicitWidth: Math.round(400 * s)
    implicitHeight: Math.max(1, list.contentHeight)
    color: "transparent"
    visible: Notifs.popups.length > 0 || list.count > 0
    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    ListView {
        id: list
        anchors.fill: parent
        interactive: false
        spacing: Math.round(8 * win.s)
        model: ScriptModel {
            values: Notifs.popups
        }

        delegate: NotifCard {
            required property var modelData
            entry: modelData
            s: win.s
            width: list.width
            slideIn: true
        }

        remove: Transition {
            NumberAnimation { property: "x"; to: list.width; duration: Theme.animMed; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.animMed }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.animMed; easing.type: Easing.OutCubic }
        }
    }
}
