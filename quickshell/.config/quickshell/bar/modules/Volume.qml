import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.popups
import ".."

Chevron {
    id: root

    readonly property int pct: Math.round(Audio.volume * 100)
    readonly property string icon: Audio.muted ? Icons.volMute
        : Audio.formFactor === "headset" ? Icons.headset
        : Audio.formFactor === "headphone" ? Icons.headphones
        : Icons.volume(Audio.volume, false)

    side: "right"
    accent: Audio.muted ? Theme.overlay1 : Theme.sapphire
    present: Audio.sink !== null
    parts: [Audio.muted ? [Icons.volMute, "Muted"] : [icon, `${pct}%`]]
    compactParts: [Audio.muted ? [Icons.volMute, ""] : [icon, `${pct}%`]]

    onClicked: b => {
        if (b === Qt.RightButton) Quickshell.execDetached(Config.audioTool);
        else if (b === Qt.MiddleButton) Audio.toggleMute();
        else mixer.toggle();
    }
    onScrolled: d => Audio.setVolume(Audio.volume + d * 0.01)

    BarPopup {
        id: mixer
        target: root
        accent: Theme.sapphire

        VolumeMixer {
            s: root.s
            accent: Theme.sapphire
        }
    }
}
