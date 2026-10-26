import QtQuick
import QtQuick.Shapes
import qs.config

// Outlined six-point chevron shared by the bar, power menu and launcher.
//   startEdge / endEdge: "tip" points outward, "notch" receives a neighbour's tip, "flat" is straight
Shape {
    id: root

    property color accent: Theme.text
    property color fill: Theme.bg
    property real bw: Theme.border
    property real k: 0                      // horizontal run of the slanted edges
    property string startEdge: "flat"
    property string endEdge: "flat"

    readonly property real b: bw / 2
    readonly property real tl: startEdge === "tip" ? k : b
    readonly property real ml: startEdge === "notch" ? k : b
    readonly property real tr: endEdge === "tip" ? width - k : width - b
    readonly property real mr: endEdge === "notch" ? width - k : width - b

    preferredRendererType: Shape.CurveRenderer
    containsMode: Shape.FillContains

    ShapePath {
        strokeColor: root.accent
        strokeWidth: root.bw
        joinStyle: ShapePath.MiterJoin
        fillColor: root.fill

        Behavior on fillColor {
            ColorAnimation { duration: Theme.animFast }
        }
        Behavior on strokeColor {
            ColorAnimation { duration: Theme.animMed }
        }

        startX: root.tl
        startY: root.b
        PathLine { x: root.tr; y: root.b }
        PathLine { x: root.mr; y: root.height / 2 }
        PathLine { x: root.tr; y: root.height - root.b }
        PathLine { x: root.tl; y: root.height - root.b }
        PathLine { x: root.ml; y: root.height / 2 }
        PathLine { x: root.tl; y: root.b }
    }
}
