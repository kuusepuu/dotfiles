import QtQuick
import qs.config

Item {
    id: root

    property real s: 1
    property real value: 0                  // 0..1
    property color accent: Theme.sapphire
    property bool dimmed: false
    signal moved(real value)

    implicitWidth: Math.round(200 * s)
    implicitHeight: Math.round(18 * s)

    readonly property real trackH: Math.round(6 * s)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackH
        radius: height / 2
        color: Theme.surface0

        Rectangle {
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: height / 2
            color: root.dimmed ? Theme.overlay0 : root.accent

            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(1, root.value)) * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(14 * root.s)
        height: width
        radius: width / 2
        color: drag.containsMouse || drag.pressed ? Theme.text : Theme.subtext1
        border.color: root.dimmed ? Theme.overlay0 : root.accent
        border.width: Math.max(1, Math.round(2 * root.s))
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function set(x) {
            root.moved(Math.max(0, Math.min(1, x / width)));
        }
        onPressed: e => set(e.x)
        onPositionChanged: e => { if (pressed) set(e.x); }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.01 : -0.01))))
    }
}
