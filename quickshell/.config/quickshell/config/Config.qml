pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // ── Scaling ────────────────────────────────────────────────────────────
    // Global multiplier on top of the automatic per-screen scale.
    property real uiScale: 1.0
    // Optional per-monitor pins, keyed by output name:
    //   "DP-2": { scale: 0.9, tier: 1 }   tier: 0 full labels, 1 compact, 2 compact + hide low-priority
    property var overrides: ({})
    // false = chevrons keep their natural width (islands); true = each side stretches to meet the clock
    property bool fillWidth: true

    // ── Stats ──────────────────────────────────────────────────────────────
    property int pollInterval: 3000
    property int historyLength: 60
    property int cpuTempCritical: 85
    property int gpuTempCritical: 90
    property string gpuCard: ""             // "" = auto: the card with the most VRAM

    // ── Keyboard layout labels (Hyprland layout name → bar text) ───────────
    property var layoutNames: ({ "English (US)": "EN", "Estonian": "EE" })

    // ── Notifications ─────────────────────────────────────────────────────
    property int notifHistory: 20
    property int notifMaxPopups: 5
    property int notifTimeoutLow: 5000
    property int notifTimeoutNormal: 8000
    property int notifTimeoutCritical: 0    // 0 = until dismissed

    // ── Launcher ──────────────────────────────────────────────────────────
    property int launcherHalfLifeDays: 7    // how fast usage counts fade from the ranking
    // Category tabs. An app goes to the first tab whose `cats` share a freedesktop Categories= value with it,
    // so the order is also the match priority (Steam is Network;Game → Games, not Web).
    property var launcherCategories: [
        { name: "Games", icon: Icons.gamepad, accent: Theme.peach, cats: ["Game"] },
        { name: "Dev", icon: Icons.code, accent: Theme.green, cats: ["Development", "IDE", "TextEditor"] },
        { name: "Graphics", icon: Icons.palette, accent: Theme.mauve, cats: ["Graphics", "Photography"] },
        { name: "Media", icon: Icons.media, accent: Theme.pink, cats: ["AudioVideo", "Audio", "Video", "Player"] },
        { name: "Office", icon: Icons.office, accent: Theme.yellow, cats: ["Office", "Education", "Science"] },
        { name: "Web", icon: Icons.web, accent: Theme.sapphire, cats: ["Network", "WebBrowser", "Email", "Chat", "InstantMessaging"] },
        { name: "System", icon: Icons.cog, accent: Theme.teal, cats: ["System", "Settings", "Utility", "TerminalEmulator", "FileManager"] },
    ]

    // ── Commands ──────────────────────────────────────────────────────────
    property var terminal: ["kitty", "-e"]   // prefix for Terminal=true apps
    property var sysMonitor: ["kitty", "-e", "btop"]
    property var gpuTool: ["lact"]
    property var netTool: ["kitty", "-e", "nmtui"]
    property var audioTool: ["pavucontrol"]
    property var btTool: ["blueman-manager"]
    property var lockCmd: ["loginctl", "lock-session"]
    property var suspendCmd: ["loginctl", "suspend"]
    property var rebootCmd: ["systemctl", "reboot"]
    property var poweroffCmd: ["systemctl", "poweroff"]

    function scaleFor(screen) {
        const o = overrides[screen?.name] ?? {};
        const h = screen?.height ?? 1440;
        const auto = Math.max(0.8, Math.min(1.3, Math.sqrt(h / 1440)));
        return (o.scale ?? auto) * uiScale;
    }

    function tierFor(screen) {
        return overrides[screen?.name]?.tier ?? -1;
    }
}
