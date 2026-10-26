import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Volume (and, where a backlight exists, brightness) OSD at the bottom centre of the focused monitor
PanelWindow {
    id: win

    readonly property real s: Config.scaleFor(screen)
    property bool shown: false
    property string kind: "volume"          // volume | brightness
    property real brightness: 0

    readonly property real value: kind === "volume" ? Audio.volume : brightness
    readonly property bool muted: kind === "volume" && Audio.muted
    readonly property color accent: kind === "volume" ? (muted ? Theme.overlay1 : Theme.sapphire) : Theme.yellow

    function show(k) {
        if (!armed) return;
        kind = k;
        screen = Hypr.focusedScreen;
        shown = true;
        hideTimer.restart();
    }

    screen: Hypr.focusedScreen
    anchors.bottom: true
    margins.bottom: Math.round(90 * s)
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: card.width
    implicitHeight: card.height + Math.round(20 * s)
    color: "transparent"
    visible: shown || card.opacity > 0.01
    mask: Region {}
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay

    // Ignore the volume "changes" that happen at startup or when the default sink switches
    property bool armed: false
    Timer {
        id: armTimer
        interval: 800
        running: true
        onTriggered: win.armed = true
    }
    Connections {
        target: Audio
        function onSinkChanged() {
            win.armed = false;
            armTimer.restart();
        }
        function onVolumeChanged() {
            win.show("volume");
        }
        function onMutedChanged() {
            win.show("volume");
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: win.shown = false
    }

    // Backlight: sysfs doesn't notify reliably, so poll while one exists (laptops/VMs only)
    Timer {
        interval: 250
        running: HwProbe.hasBacklight
        repeat: true
        onTriggered: {
            bl.reload();
            blMax.reload();
        }
    }
    FileView {
        id: bl
        path: HwProbe.hasBacklight ? HwProbe.backlight + "/brightness" : ""
        onLoaded: {
            const max = Number(blMax.text()) || 1;
            const v = Number(text()) / max;
            if (Math.abs(v - win.brightness) > 0.001) {
                const first = win.brightness === 0;
                win.brightness = v;
                if (!first) win.show("brightness");
            }
        }
    }
    FileView {
        id: blMax
        path: HwProbe.hasBacklight ? HwProbe.backlight + "/max_brightness" : ""
    }

    Rectangle {
        id: card

        width: row.implicitWidth + Math.round(32 * win.s)
        height: row.implicitHeight + Math.round(20 * win.s)
        y: win.shown ? 0 : Math.round(20 * win.s)
        opacity: win.shown ? 1 : 0
        radius: height / 2
        color: Theme.bg
        border.color: win.accent
        border.width: Math.max(1, Math.round(Theme.border * win.s))

        Behavior on y {
            NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animMed }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.animFast }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Math.round(14 * win.s)

            Label {
                anchors.verticalCenter: parent.verticalCenter
                s: win.s
                size: Theme.fontSize * 1.5
                width: Math.round(28 * win.s)
                horizontalAlignment: Text.AlignHCenter
                text: win.kind === "volume" ? Icons.volume(Audio.volume, Audio.muted) : Icons.brightness
                color: win.accent
            }

            Slider {
                anchors.verticalCenter: parent.verticalCenter
                s: win.s
                implicitWidth: Math.round(240 * win.s)
                value: win.value
                accent: win.accent
                dimmed: win.muted
                enabled: false
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                s: win.s
                width: Math.round(44 * win.s)
                horizontalAlignment: Text.AlignRight
                text: win.muted ? "Muted" : `${Math.round(win.value * 100)}%`
                color: win.accent
                font.bold: true
            }
        }
    }
}
