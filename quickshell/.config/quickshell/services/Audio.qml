pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool ready: sink?.ready ?? false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    // App playback streams, grouped by application so e.g. three Firefox streams get one slider
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
    readonly property var apps: {
        const groups = {};
        for (const n of streams) {
            const name = n.properties["application.name"] || n.description || n.name;
            if (!groups[name]) groups[name] = { name, icon: n.properties["application.icon-name"] ?? "", nodes: [] };
            groups[name].nodes.push(n);
        }
        return Object.values(groups);
    }

    readonly property string formFactor: sink?.properties["device.form-factor"] ?? ""

    PwObjectTracker {
        objects: [root.sink, ...root.sinks, ...root.streams]
    }

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
}
