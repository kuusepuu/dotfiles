import QtQuick
import QtQuick.Shapes
import qs.config

// One outlined chevron segment of the bar.
//   side "left":   notch (or flat) on the left, tip pointing right      ▷  >
//   side "center": notch on both sides, receives both arrows             > [ ] <
//   side "right":  tip pointing left, notch (or flat) on the right       <  ◁
Item {
    id: root

    required property var bar
    property string side: "left"
    property color accent: Theme.text
    // Content as [icon, label] pairs; icons are drawn larger than the label text
    property var parts: []
    property var compactParts: parts
    property Component content: null        // custom content instead of parts
    property real contentWidth0: -1         // natural content widths for custom content (full / compact)
    property real contentWidth1: contentWidth0
    property int priority: 0                // > 0: may be hidden on narrow screens, highest first
    property bool present: true             // false when the hardware is missing
    property bool alert: false              // pulsing critical state
    property real padExtra: 0               // extra horizontal padding (base px) on both sides

    readonly property bool hovered: mouse.containsMouse
    readonly property bool compact: bar.tier >= 1

    signal clicked(int button)
    signal scrolled(int delta)              // +1 up, -1 down

    readonly property real s: bar.s
    readonly property real h: bar.h
    readonly property real k: bar.k
    readonly property real bw: Math.max(1, Math.round(Theme.border * s))
    readonly property real pad: Math.round(Theme.pad * s)
    readonly property real fontSize: Math.round(Theme.fontSize * s)

    // The outermost chevrons get a flat edge against the screen edge
    readonly property string startEdge: side === "right" ? "tip" : (bar.firstLeft === root ? "flat" : "notch")
    readonly property string endEdge: side === "left" ? "tip" : (bar.lastRight === root ? "flat" : "notch")
    readonly property real insetStart: (startEdge === "flat" ? pad * 1.3 : k + pad * 0.5) + padExtra * s
    readonly property real insetEnd: (endEdge === "flat" ? pad * 1.3 : k + pad * 0.5) + padExtra * s

    readonly property real w0: Math.ceil((contentWidth0 >= 0 ? contentWidth0 : fullMeasure.implicitWidth) + insetStart + insetEnd)
    readonly property real w1: Math.ceil((contentWidth1 >= 0 ? contentWidth1 : compactMeasure.implicitWidth) + insetStart + insetEnd)

    visible: present && !bar.layout.hidden.includes(root)
    implicitWidth: (compact ? w1 : w0) + bar.extraFor(side)
    implicitHeight: h

    // Invisible copies of both variants, measured independently of the current tier
    Parts {
        id: fullMeasure
        parts: root.parts
        opacity: 0
    }

    Parts {
        id: compactMeasure
        parts: root.compactParts
        opacity: 0
    }

    property real pulse: 0
    SequentialAnimation on pulse {
        running: root.alert
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.pulse = 0
        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 700; easing.type: Easing.InOutSine }
    }

    readonly property real tint: Math.max(mouse.pressed ? 0.24 : hovered ? 0.13 : 0, pulse * 0.3)

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        containsMode: Shape.FillContains

        readonly property real b: root.bw / 2
        readonly property real w: width
        readonly property real h: height
        readonly property real tl: root.startEdge === "tip" ? root.k : b
        readonly property real ml: root.startEdge === "notch" ? root.k : b
        readonly property real tr: root.endEdge === "tip" ? w - root.k : w - b
        readonly property real mr: root.endEdge === "notch" ? w - root.k : w - b

        ShapePath {
            strokeColor: root.accent
            strokeWidth: root.bw
            joinStyle: ShapePath.MiterJoin
            fillColor: Theme.alpha(Theme.mix(Theme.base, root.accent, root.tint), Theme.bgOpacity)

            Behavior on fillColor {
                ColorAnimation { duration: Theme.animFast }
            }
            Behavior on strokeColor {
                ColorAnimation { duration: Theme.animMed }
            }

            startX: shape.tl
            startY: shape.b
            PathLine { x: shape.tr; y: shape.b }
            PathLine { x: shape.mr; y: shape.h / 2 }
            PathLine { x: shape.tr; y: shape.h - shape.b }
            PathLine { x: shape.tl; y: shape.h - shape.b }
            PathLine { x: shape.ml; y: shape.h / 2 }
            PathLine { x: shape.tl; y: shape.b }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        containmentMask: shape
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
        onWheel: e => {
            const d = e.angleDelta.y !== 0 ? e.angleDelta.y : -e.angleDelta.x;
            if (d !== 0) root.scrolled(d > 0 ? 1 : -1);
        }
    }

    // Content area between the slanted edges
    Item {
        id: area
        x: root.insetStart
        width: root.width - root.insetStart - root.insetEnd
        height: parent.height

        Parts {
            anchors.centerIn: parent
            visible: root.content === null
            parts: root.compact ? root.compactParts : root.parts
        }

        Loader {
            anchors.fill: parent
            active: root.content !== null
            sourceComponent: root.content
        }
    }

    component Parts: Row {
        id: row

        property var parts: []

        spacing: Math.round(root.fontSize * 0.8)

        Repeater {
            model: row.parts

            Row {
                id: part

                required property var modelData

                spacing: Math.round(root.fontSize * 0.4)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: part.modelData[0] ?? ""
                    color: root.accent
                    font.family: Theme.font
                    font.pixelSize: Math.round(root.fontSize * 1.3)

                    Behavior on color {
                        ColorAnimation { duration: Theme.animMed }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: part.modelData[1] ?? ""
                    color: root.accent
                    font.family: Theme.font
                    font.pixelSize: root.fontSize
                    font.bold: true

                    Behavior on color {
                        ColorAnimation { duration: Theme.animMed }
                    }
                }
            }
        }
    }
}
