import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.widgets

Rectangle {
    id: root

    required property var entry
    property real s: 1
    property bool inCenter: false
    property bool slideIn: false            // animate in from the right when created

    // Slide the visuals, not the delegate itself, so ListView transitions can't interrupt it
    property real offset: slideIn ? width : 0
    Component.onCompleted: if (slideIn) slideAnim.start()
    NumberAnimation {
        id: slideAnim
        target: root
        property: "offset"
        to: 0
        duration: Theme.animSlow
        easing.type: Easing.OutCubic
    }
    transform: Translate { x: root.offset }
    opacity: slideIn ? 1 - root.offset / Math.max(1, root.width) * 0.8 : 1

    readonly property var n: entry?.notification ?? null
    readonly property color accent: n?.urgency === NotificationUrgency.Critical ? Theme.red
        : n?.urgency === NotificationUrgency.Low ? Theme.surface1 : Theme.mauve
    readonly property var progress: n?.hints?.value
    readonly property string iconSource: {
        // image may be an icon-theme lookup for the app icon; resolve it so a missing icon shows nothing
        const img = n?.image ?? "";
        if (img.startsWith("image://icon/")) {
            const found = Quickshell.iconPath(img.slice(13), true);
            if (found) return found;
        } else if (img) {
            return img;
        }
        const icon = n?.appIcon ?? "";
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.startsWith("file:")) return icon;
        return icon ? Quickshell.iconPath(icon, true) : "";
    }
    readonly property var actions: (n?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property var defaultAction: (n?.actions ?? []).find(a => a.identifier === "default") ?? null
    readonly property real gap: Math.round(10 * s)

    implicitHeight: body.implicitHeight + 2 * gap
    radius: Math.round(Theme.radius * s)
    color: area.containsMouse ? Theme.alpha(Theme.mix(Theme.base, accent, 0.06), Theme.bgOpacity) : Theme.bg
    border.color: accent
    border.width: Math.max(1, Math.round(Theme.border * s))

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onContainsMouseChanged: root.entry.paused = containsMouse
        onClicked: e => {
            if (e.button === Qt.LeftButton && root.defaultAction) {
                root.defaultAction.invoke();
                return;
            }
            // Right/middle click or no default action: dismiss from the popup, or for good from the center
            if (root.inCenter || e.button === Qt.MiddleButton) root.n.dismiss();
            else root.entry.popup = false;
        }
    }

    Row {
        id: body
        x: root.gap
        y: root.gap
        width: root.width - 2 * root.gap
        spacing: root.gap

        IconImage {
            id: icon
            visible: root.iconSource !== ""
            source: root.iconSource
            implicitSize: Math.round(44 * root.s)
            asynchronous: true
        }

        Column {
            width: body.width - (icon.visible ? icon.width + body.spacing : 0)
            spacing: Math.round(4 * root.s)

            Item {
                width: parent.width
                height: appLabel.implicitHeight

                Label {
                    id: appLabel
                    s: root.s
                    size: Theme.fontSizeSmall
                    width: parent.width - meta.width - Math.round(8 * root.s)
                    elide: Text.ElideRight
                    text: root.n?.appName || "Notification"
                    color: Theme.subtext0
                }

                Row {
                    id: meta
                    anchors.right: parent.right
                    spacing: Math.round(8 * root.s)

                    Label {
                        s: root.s
                        size: Theme.fontSizeSmall
                        text: root.entry ? Notifs.age(root.entry.time) : ""
                        color: Theme.overlay1
                    }

                    Label {
                        s: root.s
                        size: Theme.fontSizeSmall
                        text: Icons.close
                        color: closeArea.containsMouse ? Theme.red : Theme.overlay1

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            anchors.margins: -Math.round(4 * root.s)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.n.dismiss()
                        }
                    }
                }
            }

            Label {
                s: root.s
                width: parent.width
                visible: text !== ""
                text: root.n?.summary ?? ""
                color: root.n?.urgency === NotificationUrgency.Critical ? Theme.rosewater : Theme.text
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Label {
                s: root.s
                size: Theme.fontSizeSmall + 1
                width: parent.width
                visible: text !== ""
                text: root.n?.body ?? ""
                textFormat: Text.StyledText
                color: root.n?.urgency === NotificationUrgency.Low ? Theme.overlay1 : Theme.subtext1
                linkColor: Theme.blue
                wrapMode: Text.Wrap
                maximumLineCount: root.inCenter ? 3 : 5
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Rectangle {
                visible: root.progress !== undefined && root.progress !== null
                width: parent.width
                height: Math.round(4 * root.s)
                radius: height / 2
                color: Theme.surface0

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, Number(root.progress ?? 0))) / 100
                    height: parent.height
                    radius: height / 2
                    color: root.accent === Theme.surface1 ? Theme.mauve : root.accent

                    Behavior on width {
                        NumberAnimation { duration: Theme.animMed }
                    }
                }
            }

            Flow {
                visible: root.actions.length > 0
                width: parent.width
                spacing: Math.round(6 * root.s)

                Repeater {
                    model: root.actions

                    IconButton {
                        required property var modelData
                        s: root.s
                        size: Theme.fontSizeSmall
                        text: modelData.text
                        accent: root.accent === Theme.surface1 ? Theme.overlay2 : root.accent
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
