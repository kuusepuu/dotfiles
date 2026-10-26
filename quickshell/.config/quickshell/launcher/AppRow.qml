import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// One launcher result: a short icon tile (flat → tip) nested into a long name tile (notch → flat),
// shaped like the Lock and Shutdown tiles of the power menu. Expanded actions get only an indented name tile.
Item {
    id: root

    required property var row               // { entry, action, cat, idx, header, child }
    property real s: 1
    property bool selected: false
    property bool expanded: false

    signal hovered
    signal clicked
    signal toggleActions

    readonly property var entry: row.entry
    readonly property bool child: row.child ?? false
    readonly property bool hasActions: !row.action && entry.actions.length > 0
    readonly property color accent: row.cat?.accent ?? Theme.lavender

    readonly property real fullH: Math.round(44 * s)
    readonly property real tileH: child ? Math.round(34 * s) : fullH
    readonly property real k: Math.round(tileH * Theme.slant)
    readonly property real gap: Math.round(Theme.gap * s)
    // Icon tile is fullH + k wide and the name tile overlaps it by k - gap, so name tiles start at fullH + gap
    readonly property real nameX: fullH + gap + (child ? Math.round(18 * s) : 0)
    readonly property real pad: Math.round(Theme.pad * s)

    readonly property real bw: Math.max(1, Math.round(Theme.border * s * (selected ? 1.5 : 1)))
    readonly property color stroke: selected ? accent : Theme.alpha(accent, 0.45)
    readonly property color fill: Theme.alpha(Theme.mix(Theme.base, accent, selected ? 0.2 : 0), 0.95)

    readonly property string title: row.action ? row.action.name : entry.name
    readonly property string subtitle: {
        if (child) return "";
        if (row.action) return entry.name;
        return entry.genericName && entry.genericName !== entry.name ? entry.genericName : entry.comment;
    }
    readonly property string iconSource: {
        const icon = row.action?.icon || entry.icon;
        return icon.startsWith("/") ? `file://${icon}` : Quickshell.iconPath(icon, "application-x-executable");
    }

    function esc(c) {
        return c === "&" ? "&amp;" : c === "<" ? "&lt;" : c === ">" ? "&gt;" : c;
    }

    // Title with the query's matched characters recoloured
    function highlight(text, idx, color) {
        const hit = new Set(idx);
        let out = "";
        for (let i = 0; i < text.length; i++) out += hit.has(i) ? `<font color="${color}">${esc(text[i])}</font>` : esc(text[i]);
        return out;
    }

    implicitHeight: (header.visible ? header.height : 0) + tileH

    Text {
        id: header
        visible: root.row.header !== ""
        text: root.row.header
        color: Theme.overlay1
        font.family: Theme.font
        font.pixelSize: Math.round(Theme.fontSizeSmall * root.s)
        font.bold: true
        leftPadding: root.nameX + Math.round(Theme.slant * root.fullH)
        topPadding: Math.round(4 * root.s)
        bottomPadding: Math.round(4 * root.s)
    }

    Item {
        id: tiles
        y: header.visible ? header.height : 0
        width: parent.width
        height: root.tileH

        ChevronShape {
            visible: !root.child
            width: root.fullH + root.k
            height: parent.height
            accent: root.stroke
            fill: root.fill
            bw: root.bw
            k: root.k
            startEdge: "flat"
            endEdge: "tip"

            IconImage {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -root.k / 2
                implicitSize: Math.round(root.tileH * 0.6)
                source: root.iconSource
                asynchronous: true
            }
        }

        ChevronShape {
            x: root.nameX
            width: parent.width - x
            height: parent.height
            accent: root.stroke
            fill: root.fill
            bw: root.bw
            k: root.k
            startEdge: "notch"
            endEdge: "flat"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Position changes rather than enter, so rows scrolling under a resting cursor don't steal the selection
            onPositionChanged: root.hovered()
            onClicked: root.clicked()
        }

        Row {
            id: label
            x: root.nameX + root.k + Math.round(4 * root.s)
            width: badges.x - x - root.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(10 * root.s)

            IconImage {
                visible: root.child
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Math.round(root.tileH * 0.5)
                source: root.iconSource
                asynchronous: true
            }

            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                text: root.highlight(root.title, root.row.idx, root.selected ? Theme.text : root.accent)
                textFormat: Text.StyledText
                color: root.selected ? root.accent : Theme.text
                font.family: Theme.font
                font.pixelSize: Math.round((root.child ? Theme.fontSizeSmall : Theme.fontSize) * root.s)
                font.bold: true

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, label.width - titleText.width - label.spacing)
                visible: text !== ""
                text: root.subtitle
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.overlay1
                font.family: Theme.font
                font.pixelSize: Math.round(Theme.fontSizeSmall * root.s)
            }
        }

        Row {
            id: badges
            x: parent.width - width - root.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(8 * root.s)

            Text {
                visible: !root.row.action && Apps.isPinned(root.entry.id)
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.pin
                color: root.accent
                font.family: Theme.font
                font.pixelSize: Math.round(Theme.fontSize * root.s)
            }

            Text {
                visible: root.hasActions
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.chevronRight
                color: root.expanded || chevronArea.containsMouse ? root.accent : Theme.overlay1
                rotation: root.expanded ? 90 : 0
                font.family: Theme.font
                font.pixelSize: Math.round(Theme.fontSize * 1.3 * root.s)

                Behavior on rotation {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    id: chevronArea
                    anchors.fill: parent
                    anchors.margins: -Math.round(6 * root.s)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleActions()
                }
            }
        }
    }
}
