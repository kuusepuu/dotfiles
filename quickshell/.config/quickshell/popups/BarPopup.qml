import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// Popup that drops down from a bar chevron. hoverMode: opens while the chevron (or the popup) is hovered;
// otherwise open/toggle it from a click and it closes on outside click.
PopupWindow {
    id: popup

    required property Item target
    property bool hoverMode: false
    property bool open: false
    property color accent: target.accent
    default property alias content: inner.data

    readonly property real s: target.s
    readonly property real padding: Math.round(12 * s)
    readonly property real slide: Math.round(10 * s)

    function toggle() {
        open = !open;
    }

    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: target.height + Math.round(6 * s)
    anchor.rect.width: target.width
    anchor.rect.height: 1
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    implicitWidth: card.width
    implicitHeight: card.height
    color: "transparent"
    visible: open || card.opacity > 0.01

    onOpenChanged: if (open && !hoverMode) ShellState.activePopup = popup

    Connections {
        target: ShellState
        function onActivePopupChanged() {
            if (!popup.hoverMode && ShellState.activePopup !== popup) popup.open = false;
        }
    }

    // ── Hover behaviour ────────────────────────────────────────────────────
    readonly property bool hot: target.hovered || cardHover.hovered
    onHotChanged: {
        if (!hoverMode) return;
        if (hot) {
            closeTimer.stop();
            if (!open) openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }
    }

    Timer {
        id: openTimer
        interval: 350
        onTriggered: popup.open = true
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: popup.open = false
    }

    HyprlandFocusGrab {
        active: popup.open && !popup.hoverMode
        windows: [popup, popup.target.QsWindow.window]
        onCleared: popup.open = false
    }

    Rectangle {
        id: card

        width: inner.implicitWidth + 2 * popup.padding
        height: inner.implicitHeight + 2 * popup.padding
        y: popup.open ? 0 : -popup.slide
        opacity: popup.open ? 1 : 0
        radius: Math.round(Theme.radius * popup.s)
        color: Theme.bg
        border.color: popup.accent
        border.width: Math.max(1, Math.round(Theme.border * popup.s))

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            id: cardHover
        }

        Column {
            id: inner
            x: popup.padding
            y: popup.padding
            spacing: Math.round(8 * popup.s)
        }
    }
}
