pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Dispatch helpers that work with both the Lua and the legacy hyprlang config.
Singleton {
    id: root

    readonly property bool lua: Hyprland.usingLua

    function focusWorkspace(ws) {
        const arg = typeof ws === "number" ? ws : `"${ws}"`;
        Hyprland.dispatch(lua ? `hl.dsp.focus({ workspace = ${arg} })` : `workspace ${ws}`);
    }

    function exit() {
        Hyprland.dispatch(lua ? "hl.dsp.exit()" : "exit");
    }

    // The ShellScreen that Hyprland currently has focused
    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }
}
