import QtQuick
import qs.config
import qs.widgets

// Title + current value, history graph, and key/value lines
Column {
    id: root

    property real s: 1
    property string title: ""
    property string value: ""
    property var history: []
    property color accent: Theme.text
    property var lines: []                  // [[label, value], ...]

    spacing: Math.round(8 * s)

    Item {
        width: graph.width
        height: titleLabel.implicitHeight

        Label {
            id: titleLabel
            s: root.s
            text: root.title
            color: root.accent
            font.bold: true
        }

        Label {
            anchors.right: parent.right
            s: root.s
            text: root.value
            color: Theme.text
            font.bold: true
        }
    }

    Graph {
        id: graph
        width: Math.round(240 * root.s)
        height: Math.round(64 * root.s)
        values: root.history
        color: root.accent
    }

    Repeater {
        model: root.lines

        Item {
            required property var modelData
            width: graph.width
            height: key.implicitHeight

            Label {
                id: key
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
