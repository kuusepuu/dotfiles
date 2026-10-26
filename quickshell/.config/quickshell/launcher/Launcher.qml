import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// App launcher (SUPER+Space): search chevron, category chevrons and a list of nested icon/name tiles.
// ↑/↓ select, ↵ launch, →/← show/hide an app's actions, Tab/Shift+Tab category, Ctrl+S pin, Esc close.
PanelWindow {
    id: win

    readonly property bool open: ShellState.launcherOpen
    readonly property real s: Config.scaleFor(screen)

    property int catIndex: 0
    property int selected: 0
    property string expanded: ""            // id of the app whose actions are listed under it

    readonly property var category: Apps.categories[catIndex] ?? Apps.all
    readonly property var results: Apps.search(input.text, category)
    // Results with the expanded app's actions inserted after it
    readonly property var rows: {
        const i = results.findIndex(r => !r.action && r.entry.id === expanded);
        if (i < 0) return results;
        const p = results[i];
        const children = Array.from(p.entry.actions).map(a => ({
            key: `${p.entry.id}/${a.id}`,
            entry: p.entry,
            action: a,
            cat: p.cat,
            idx: [],
            header: "",
            child: true,
        }));
        const keys = new Set(children.map(c => c.key));
        const rest = results.slice(i + 1).filter(r => !keys.has(r.key));
        return [...results.slice(0, i + 1), ...children, ...rest];
    }
    readonly property int appCount: results.filter(r => !r.action).length

    readonly property real w: Math.round(640 * s)
    readonly property real rowH: Math.round(44 * s)
    readonly property real rowGap: Math.round(6 * s)
    readonly property int visibleRows: 8

    function move(d) {
        if (rows.length) selected = Math.max(0, Math.min(rows.length - 1, selected + d));
    }

    function setCategory(i) {
        catIndex = i;
        selected = 0;
        expanded = "";
    }

    function activate(i) {
        const r = rows[i];
        if (!r) return;
        ShellState.launcherOpen = false;
        Apps.launch(r.entry, r.action);
    }

    function toggleActions(i) {
        const r = rows[i];
        if (!r || r.action || !r.entry.actions.length) return false;
        expanded = expanded === r.entry.id ? "" : r.entry.id;
        selected = i;
        return true;
    }

    function collapse() {
        if (!expanded) return false;
        const parent = rows.findIndex(r => !r.action && r.entry.id === expanded);
        expanded = "";
        if (parent >= 0) selected = parent;
        return true;
    }

    function pin(i) {
        const r = rows[i];
        if (!r || r.action) return;
        Apps.togglePin(r.entry.id);
        // Pinning reorders the empty-query view; keep the same app selected
        selected = Math.max(0, rows.findIndex(x => x.key === r.key));
    }

    function handleKey(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        const k = e.key;
        if (k === Qt.Key_Escape || (ctrl && k === Qt.Key_BracketLeft)) ShellState.launcherOpen = false;
        else if (k === Qt.Key_Up || (ctrl && (k === Qt.Key_K || k === Qt.Key_P))) move(-1);
        else if (k === Qt.Key_Down || (ctrl && (k === Qt.Key_J || k === Qt.Key_N))) move(1);
        else if (k === Qt.Key_PageUp) move(-visibleRows);
        else if (k === Qt.Key_PageDown) move(visibleRows);
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) activate(selected);
        else if (k === Qt.Key_Tab) setCategory((catIndex + 1) % Apps.categories.length);
        else if (k === Qt.Key_Backtab) setCategory((catIndex + Apps.categories.length - 1) % Apps.categories.length);
        else if (k === Qt.Key_Right && input.cursorPosition === input.text.length && expanded !== rows[selected]?.entry.id) return toggleActions(selected);
        else if (k === Qt.Key_Left && expanded) return collapse();
        else if (ctrl && k === Qt.Key_S) pin(selected);
        else if (ctrl && k === Qt.Key_U) input.remove(0, input.cursorPosition);
        else if (ctrl && k === Qt.Key_W) input.clear();
        else return false;
        return true;
    }

    onOpenChanged: if (open) {
        screen = Hypr.focusedScreen;
        input.clear();
        setCategory(0);
        input.forceActiveFocus();
    }

    onSelectedChanged: list.positionViewAtIndex(selected, ListView.Contain)
    onRowsChanged: Qt.callLater(() => list.positionViewAtIndex(selected, ListView.Contain))

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
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Theme.alpha(Theme.crust, 0.7)
        opacity: win.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animMed }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.launcherOpen = false
        }

        Item {
            anchors.centerIn: parent
            width: win.w
            height: column.implicitHeight
            scale: win.open ? 1 : 0.95

            Behavior on scale {
                NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
            }

            // Clicks in the gaps between tiles shouldn't close the launcher
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: column
                width: parent.width
                spacing: Math.round(12 * win.s)

                // ── Search ─────────────────────────────────────────────────
                Item {
                    id: search

                    readonly property real k: Math.round(height * Theme.slant)
                    readonly property real inset: k + Math.round(Theme.pad * win.s)

                    width: parent.width
                    height: Math.round(52 * win.s)

                    ChevronShape {
                        anchors.fill: parent
                        accent: Theme.mauve
                        fill: Theme.alpha(Theme.base, 0.95)
                        bw: Math.max(1, Math.round(Theme.border * win.s * 1.5))
                        k: search.k
                        startEdge: "notch"
                        endEdge: "notch"
                    }

                    Text {
                        id: glyph
                        x: search.inset
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.search
                        color: Theme.mauve
                        font.family: Theme.font
                        font.pixelSize: Math.round(Theme.fontSize * 1.5 * win.s)
                    }

                    TextInput {
                        id: input
                        anchors.left: glyph.right
                        anchors.leftMargin: Math.round(12 * win.s)
                        anchors.right: counter.left
                        anchors.rightMargin: Math.round(12 * win.s)
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        selectionColor: Theme.alpha(Theme.mauve, 0.4)
                        selectedTextColor: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Math.round(Theme.fontSize * 1.15 * win.s)
                        clip: true
                        focus: true

                        onTextChanged: {
                            win.selected = 0;
                            win.expanded = "";
                        }
                        Keys.onPressed: e => e.accepted = win.handleKey(e)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: `Search ${win.category === Apps.all ? "apps" : win.category.name.toLowerCase()}…`
                            color: Theme.overlay0
                            font: input.font
                        }
                    }

                    Text {
                        id: counter
                        anchors.right: parent.right
                        anchors.rightMargin: search.inset
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${win.appCount} ${win.appCount === 1 ? "app" : "apps"}`
                        color: Theme.overlay1
                        font.family: Theme.font
                        font.pixelSize: Math.round(Theme.fontSizeSmall * win.s)
                    }
                }

                // ── Categories ─────────────────────────────────────────────
                Row {
                    id: cats

                    readonly property real h: Math.round(30 * win.s)
                    readonly property real k: Math.round(h * Theme.slant)

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(Theme.gap * win.s) - k

                    Repeater {
                        model: Apps.categories

                        Item {
                            id: tab

                            required property var modelData
                            required property int index
                            readonly property bool active: win.catIndex === index
                            readonly property bool first: index === 0
                            readonly property bool last: index === Apps.categories.length - 1

                            // Inactive tabs show only their icon
                            width: Math.ceil(tabLabel.implicitWidth + 2 * cats.k + Math.round(14 * win.s))
                            height: cats.h

                            Behavior on width {
                                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                            }

                            ChevronShape {
                                id: tabShape
                                anchors.fill: parent
                                accent: tab.active || tabArea.containsMouse ? tab.modelData.accent : Theme.alpha(tab.modelData.accent, 0.45)
                                fill: Theme.alpha(Theme.mix(Theme.base, tab.modelData.accent, tab.active ? 0.25 : 0), 0.95)
                                bw: Math.max(1, Math.round(Theme.border * win.s))
                                k: cats.k
                                startEdge: tab.first ? "flat" : "notch"
                                endEdge: tab.last ? "flat" : "tip"
                            }

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: (tab.first ? 0 : cats.k / 2) - (tab.last ? 0 : cats.k / 2)
                                text: tab.active ? `${tab.modelData.icon}  ${tab.modelData.name}` : tab.modelData.icon
                                color: tab.active ? tab.modelData.accent : Theme.subtext0
                                font.family: Theme.font
                                font.pixelSize: Math.round(Theme.fontSizeSmall * win.s)
                                font.bold: true
                            }

                            MouseArea {
                                id: tabArea
                                anchors.fill: parent
                                containmentMask: tabShape
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.setCategory(tab.index)
                            }
                        }
                    }
                }

                // ── Results ────────────────────────────────────────────────
                ListView {
                    id: list
                    width: parent.width
                    height: win.visibleRows * (win.rowH + win.rowGap) - win.rowGap
                    clip: true
                    spacing: win.rowGap
                    boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel {
                        values: win.rows
                        objectProp: "key"
                    }

                    delegate: AppRow {
                        required property var modelData
                        required property int index

                        row: modelData
                        width: list.width
                        s: win.s
                        selected: index === win.selected
                        expanded: !modelData.action && win.expanded === modelData.entry.id
                        onHovered: win.selected = index
                        onClicked: win.activate(index)
                        onToggleActions: win.toggleActions(index)
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: win.rows.length === 0
                        text: "No matching apps"
                        color: Theme.overlay1
                        font.family: Theme.font
                        font.pixelSize: Math.round(Theme.fontSize * win.s)
                    }
                }

                // ── Hints ──────────────────────────────────────────────────
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↵ launch    → actions    ⇥ category    ^S pin    esc close"
                    color: Theme.overlay0
                    font.family: Theme.font
                    font.pixelSize: Math.round(Theme.fontSizeSmall * win.s)
                }
            }
        }
    }
}
