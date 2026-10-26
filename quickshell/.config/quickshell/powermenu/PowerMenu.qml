import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Full-screen dimmed overlay with nested chevron tiles. ←/→ or 1–5 to pick, Enter to run, Esc to close.
PanelWindow {
    id: win

    readonly property bool open: ShellState.powerMenuOpen
    readonly property real s: Config.scaleFor(screen)
    property int selected: 0

    readonly property var actions: [
        { icon: Icons.lock, label: "Lock", color: Theme.lavender, run: () => Quickshell.execDetached(Config.lockCmd) },
        { icon: Icons.suspend, label: "Suspend", color: Theme.sapphire, run: () => Quickshell.execDetached(Config.suspendCmd) },
        { icon: Icons.logout, label: "Logout", color: Theme.green, run: () => Hypr.exit() },
        { icon: Icons.reboot, label: "Reboot", color: Theme.peach, run: () => Quickshell.execDetached(Config.rebootCmd) },
        { icon: Icons.power, label: "Shutdown", color: Theme.red, run: () => Quickshell.execDetached(Config.poweroffCmd) },
    ]

    function activate(i) {
        const a = actions[i];
        ShellState.powerMenuOpen = false;
        // Let the overlay fade before locking/suspending
        runTimer.action = a;
        runTimer.restart();
    }

    Timer {
        id: runTimer
        property var action: null
        interval: Theme.animMed
        onTriggered: action?.run()
    }

    onOpenChanged: if (open) {
        screen = Hypr.focusedScreen;
        selected = 0;
    }

    screen: Hypr.focusedScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open || dim.opacity > 0.01
    WlrLayershell.namespace: "quickshell:powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Theme.alpha(Theme.crust, 0.7)
        opacity: win.open ? 1 : 0
        focus: win.open

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMed }
        }

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) ShellState.powerMenuOpen = false;
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Backtab) win.selected = (win.selected + win.actions.length - 1) % win.actions.length;
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab) win.selected = (win.selected + 1) % win.actions.length;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) win.activate(win.selected);
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5) win.activate(e.key - Qt.Key_1);
            else return;
            e.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.powerMenuOpen = false
        }

        Row {
            id: tiles

            readonly property real h: Math.round(160 * win.s)
            readonly property real k: Math.round(h * Theme.slant * 0.6)

            anchors.centerIn: parent
            spacing: Math.round(10 * win.s) - k
            scale: win.open ? 1 : 0.92

            Behavior on scale {
                NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: win.actions

                Item {
                    id: tile

                    required property var modelData
                    required property int index
                    readonly property bool sel: win.selected === index
                    readonly property bool first: index === 0
                    readonly property bool last: index === win.actions.length - 1
                    readonly property real bw: Math.max(1, Math.round(Theme.border * win.s * (sel ? 1.5 : 1)))

                    width: Math.round(185 * win.s)
                    height: tiles.h

                    Shape {
                        id: shape
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        containsMode: Shape.FillContains

                        readonly property real b: tile.bw / 2
                        readonly property real k: tiles.k
                        readonly property real tl: shape.b
                        readonly property real ml: tile.first ? shape.b : shape.k
                        readonly property real tr: tile.last ? width - shape.b : width - shape.k
                        readonly property real mr: width - shape.b

                        ShapePath {
                            strokeColor: tile.modelData.color
                            strokeWidth: tile.bw
                            joinStyle: ShapePath.MiterJoin
                            fillColor: Theme.alpha(Theme.mix(Theme.base, tile.modelData.color, tile.sel ? 0.2 : 0), 0.95)

                            Behavior on fillColor {
                                ColorAnimation { duration: Theme.animFast }
                            }

                            startX: shape.tl
                            startY: shape.b
                            PathLine { x: shape.tr; y: shape.b }
                            PathLine { x: shape.mr; y: shape.height / 2 }
                            PathLine { x: shape.tr; y: shape.height - shape.b }
                            PathLine { x: shape.tl; y: shape.height - shape.b }
                            PathLine { x: shape.ml; y: shape.height / 2 }
                            PathLine { x: shape.tl; y: shape.b }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (tile.first ? 0 : tiles.k / 2) - (tile.last ? 0 : tiles.k / 2)
                        spacing: Math.round(8 * win.s)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.icon
                            color: tile.modelData.color
                            font.family: Theme.font
                            font.pixelSize: Math.round(48 * win.s)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `${tile.index + 1}  ${tile.modelData.label}`
                            color: tile.sel ? tile.modelData.color : Theme.subtext0
                            font.family: Theme.font
                            font.pixelSize: Math.round(Theme.fontSizeSmall * win.s)
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        containmentMask: shape
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.selected = tile.index
                        onClicked: win.activate(tile.index)
                    }
                }
            }
        }
    }
}
