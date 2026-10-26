pragma Singleton
import QtQuick
import Quickshell

// Catppuccin Mocha + base sizes (everything is multiplied by the per-screen scale)
Singleton {
    readonly property color rosewater: "#f5e0dc"
    readonly property color flamingo:  "#f2cdcd"
    readonly property color pink:      "#f5c2e7"
    readonly property color mauve:     "#cba6f7"
    readonly property color red:       "#f38ba8"
    readonly property color maroon:    "#eba0ac"
    readonly property color peach:     "#fab387"
    readonly property color yellow:    "#f9e2af"
    readonly property color green:     "#a6e3a1"
    readonly property color teal:      "#94e2d5"
    readonly property color sky:       "#89dceb"
    readonly property color sapphire:  "#74c7ec"
    readonly property color blue:      "#89b4fa"
    readonly property color lavender:  "#b4befe"
    readonly property color text:      "#cdd6f4"
    readonly property color subtext1:  "#bac2de"
    readonly property color subtext0:  "#a6adc8"
    readonly property color overlay2:  "#9399b2"
    readonly property color overlay1:  "#7f849c"
    readonly property color overlay0:  "#6c7086"
    readonly property color surface2:  "#585b70"
    readonly property color surface1:  "#45475a"
    readonly property color surface0:  "#313244"
    readonly property color base:      "#1e1e2e"
    readonly property color mantle:    "#181825"
    readonly property color crust:     "#11111b"

    readonly property real bgOpacity: 0.92
    readonly property color bg: alpha(base, bgOpacity)

    readonly property string font: "CaskaydiaCove Nerd Font Propo"

    // Base sizes at scale 1.0 (1440p)
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 12
    readonly property int barHeight: 36
    readonly property real slant: 0.36      // chevron tip run, as a fraction of bar height
    readonly property real border: 2
    readonly property int gap: 6            // gap between chevrons
    readonly property int pad: 10           // padding between text and the slanted edges
    readonly property int margin: 8         // bar distance from screen edges
    readonly property int radius: 10

    readonly property int animFast: 150
    readonly property int animMed: 250
    readonly property int animSlow: 400

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
}
