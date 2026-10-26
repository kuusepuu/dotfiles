import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Output switcher, master volume and per-app volume
Column {
    id: root

    property real s: 1
    property color accent: Theme.sapphire
    readonly property real w: Math.round(300 * s)

    spacing: Math.round(8 * s)

    Label {
        s: root.s
        text: `${Icons.speaker}  Output`
        color: root.accent
        font.bold: true
    }

    Repeater {
        model: Audio.sinks

        Rectangle {
            id: sinkRow

            required property var modelData
            readonly property bool current: modelData === Audio.sink

            width: root.w
            height: sinkLabel.implicitHeight + Math.round(8 * root.s)
            radius: Math.round(6 * root.s)
            color: current ? Theme.alpha(root.accent, 0.15) : sinkMouse.containsMouse ? Theme.alpha(root.accent, 0.08) : "transparent"

            Label {
                id: sinkLabel
                s: root.s
                size: Theme.fontSizeSmall
                x: Math.round(6 * root.s)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * x
                elide: Text.ElideRight
                text: `${sinkRow.current ? "●" : "○"}  ${sinkRow.modelData.nickname || sinkRow.modelData.description || sinkRow.modelData.name}`
                color: sinkRow.current ? root.accent : Theme.text
            }

            MouseArea {
                id: sinkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.setDefaultSink(sinkRow.modelData)
            }
        }
    }

    Rectangle {
        width: root.w
        height: 1
        color: Theme.surface1
    }

    VolumeRow {
        s: root.s
        width: root.w
        name: "Master"
        accent: root.accent
        value: Audio.volume
        muted: Audio.muted
        onMoved: v => Audio.setVolume(v)
        onToggleMute: Audio.toggleMute()
    }

    Label {
        s: root.s
        size: Theme.fontSizeSmall
        visible: Audio.apps.length === 0
        text: "No apps playing"
        color: Theme.subtext0
    }

    Repeater {
        model: Audio.apps

        VolumeRow {
            required property var modelData
            readonly property var audio: modelData.nodes[0].audio

            s: root.s
            width: root.w
            name: modelData.name
            accent: root.accent
            value: audio?.volume ?? 0
            muted: audio?.muted ?? false
            onMoved: v => {
                for (const n of modelData.nodes) if (n.audio) n.audio.volume = v;
            }
            onToggleMute: {
                const m = !muted;
                for (const n of modelData.nodes) if (n.audio) n.audio.muted = m;
            }
        }
    }

    component VolumeRow: Item {
        id: row

        property real s: 1
        property string name: ""
        property color accent: Theme.sapphire
        property real value: 0
        property bool muted: false
        signal moved(real v)
        signal toggleMute

        height: Math.max(nameLabel.implicitHeight, slider.implicitHeight)

        Label {
            id: nameLabel
            s: row.s
            size: Theme.fontSizeSmall
            width: Math.round(90 * row.s)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: row.name
            color: row.muted ? Theme.overlay1 : Theme.text

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: row.toggleMute()
            }
        }

        Slider {
            id: slider
            s: row.s
            anchors.left: nameLabel.right
            anchors.leftMargin: Math.round(8 * row.s)
            anchors.right: pctLabel.left
            anchors.rightMargin: Math.round(8 * row.s)
            anchors.verticalCenter: parent.verticalCenter
            value: row.value
            dimmed: row.muted
            accent: row.accent
            onMoved: v => row.moved(v)
        }

        Label {
            id: pctLabel
            s: row.s
            size: Theme.fontSizeSmall
            width: Math.round(40 * row.s)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: row.muted ? Icons.volMute : `${Math.round(row.value * 100)}%`
            color: row.muted ? Theme.overlay1 : Theme.text
        }
    }
}
