import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import "modules"

PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData

    // ── Per-screen scale ───────────────────────────────────────────────────
    readonly property real s: Config.scaleFor(screen)
    readonly property real h: Math.round(Theme.barHeight * s)
    readonly property real k: Math.round(h * Theme.slant)
    readonly property real spacing: Math.round(Theme.gap * s) - k - Math.max(1, Math.round(Theme.border * s)) / 2
    readonly property real m: Math.round(Theme.margin * s)

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: m
        left: m
        right: m
    }
    implicitHeight: h
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"

    Component.onCompleted: ShellState.barWindows = ShellState.barWindows.concat([bar])
    Component.onDestruction: ShellState.barWindows = ShellState.barWindows.filter(w => w !== bar)

    readonly property list<Item> leftItems: [ram, cpu, gpu, workspaces]
    readonly property list<Item> rightItems: [bluetooth, language, volume, network, battery, bell, power]
    readonly property Item firstLeft: leftItems.find(c => c.present) ?? null
    readonly property Item lastRight: rightItems.filter(c => c.present).pop() ?? null

    // ── Fit to width ───────────────────────────────────────────────────────
    // tier 0: full labels · 1: compact labels · 2: compact + low-priority chevrons hidden.
    // Only natural widths (w0/w1) are read here, never the laid-out widths, so there is no binding loop.
    readonly property var layout: {
        const avail = width;
        const S = spacing;
        const L = leftItems.filter(c => c.present);
        const R = rightItems.filter(c => c.present);
        const C = clock;
        const sideW = (items, t, hidden) => items.filter(c => !hidden.includes(c)).reduce((a, c) => a + (t ? c.w1 : c.w0) + S, 0);
        const fits = (t, hidden) => 2 * Math.max(sideW(L, t, hidden), sideW(R, t, hidden)) + (t ? C.w1 : C.w0) <= avail;
        const hideOrder = L.concat(R).filter(c => c.priority > 0).sort((a, b) => b.priority - a.priority);

        const forced = Config.tierFor(screen);
        let tier = 0;
        let hidden = [];
        if (forced >= 0) {
            tier = Math.min(forced, 1);
            if (forced >= 2) hidden = hideOrder;
        } else if (fits(0, [])) {
            tier = 0;
        } else {
            tier = 1;
            for (const c of hideOrder) {
                if (fits(1, hidden)) break;
                hidden = hidden.concat([c]);
            }
        }

        const half = (avail - (tier ? C.w1 : C.w0)) / 2;
        const vl = L.filter(c => !hidden.includes(c));
        const vr = R.filter(c => !hidden.includes(c));
        const extra = items => Config.fillWidth && items.length ? Math.max(0, (half - sideW(items, tier, [])) / items.length) : 0;
        return {
            tier: hidden.length ? 2 : tier,
            hidden,
            half,
            extraL: extra(vl),
            extraR: extra(vr),
        };
    }
    readonly property int tier: layout.tier

    function extraFor(side) {
        return side === "left" ? layout.extraL : side === "right" ? layout.extraR : 0;
    }

    Item {
        anchors.fill: parent

        Row {
            anchors.left: parent.left
            spacing: bar.spacing

            Ram { id: ram; bar: bar }
            Cpu { id: cpu; bar: bar }
            Gpu { id: gpu; bar: bar }
            Workspaces { id: workspaces; bar: bar }
        }

        Clock {
            id: clock
            bar: bar
            x: bar.layout.half
        }

        Row {
            anchors.right: parent.right
            spacing: bar.spacing

            Bluetooth { id: bluetooth; bar: bar }
            Language { id: language; bar: bar }
            Volume { id: volume; bar: bar }
            Network { id: network; bar: bar }
            Battery { id: battery; bar: bar }
            Bell { id: bell; bar: bar }
            Power { id: power; bar: bar }
        }
    }
}
