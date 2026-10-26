import QtQuick
import qs.config

// Small rounded text/icon button used in popups and the notification center
Rectangle {
    id: root

    property real s: 1
    property string text: ""
    property color accent: Theme.text
    property bool active: false
    property real size: Theme.fontSize
    signal clicked

    implicitWidth: label.implicitWidth + Math.round(14 * s)
    implicitHeight: label.implicitHeight + Math.round(8 * s)
    radius: Math.round(6 * s)
    color: area.pressed ? Theme.alpha(accent, 0.3) : (area.containsMouse || active) ? Theme.alpha(accent, 0.15) : "transparent"
    border.color: Theme.alpha(accent, area.containsMouse || active ? 0.8 : 0.35)
    border.width: Math.max(1, Math.round(1.5 * s))

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.accent
        font.family: Theme.font
        font.pixelSize: Math.round(root.size * root.s)
        font.bold: true
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
