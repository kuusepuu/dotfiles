pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

Singleton {
    id: root

    property string layout: ""
    readonly property string short: Config.layoutNames[layout] ?? layout.slice(0, 2).toUpperCase()

    function next() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const i = event.data.indexOf(",");
            root.layout = event.data.slice(i + 1);
        }
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards ?? [];
                    const main = kbs.find(k => k.main) ?? kbs[0];
                    if (main) root.layout = main.active_keymap;
                } catch (e) {}
            }
        }
    }
}
