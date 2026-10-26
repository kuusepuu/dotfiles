pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    property bool dnd: false
    property bool centerOpen: false
    property var entries: []                // newest first; each wraps a live Notification
    readonly property var popups: entries.filter(e => e.popup).slice(0, Config.notifMaxPopups)
    readonly property int unread: entries.filter(e => !e.read).length

    // Ticks so "2m ago" labels stay fresh
    property real now: Date.now()
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    function age(t) {
        const m = Math.floor((now - t) / 60000);
        if (m < 1) return "now";
        if (m < 60) return `${m}m`;
        const h = Math.floor(m / 60);
        return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
    }

    onCenterOpenChanged: if (centerOpen) {
        markAllRead();
        hideAllPopups();
    }

    function markAllRead() {
        for (const e of entries) e.read = true;
    }

    // SUPER+N: hide the newest popup (it stays in the center, like dunstctl close)
    function dismissLatest() {
        const e = entries.find(e => e.popup);
        if (e) e.popup = false;
    }

    // SUPER+SHIFT+N: hide all popups
    function hideAllPopups() {
        for (const e of entries) e.popup = false;
    }

    // Center "clear" button: really dismiss everything
    function clearAll() {
        for (const e of entries.slice()) e.notification.dismiss();
    }

    function _remove(entry) {
        entries = entries.filter(e => e !== entry);
        entry.destroy();
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const e = entryComp.createObject(root, { notification: n, popup: !root.dnd, read: root.centerOpen });
            root.entries = [e, ...root.entries];
            // Keep the history bounded: drop the oldest
            for (const old of root.entries.slice(Config.notifHistory)) old.notification.dismiss();
        }
    }

    Component {
        id: entryComp

        QtObject {
            id: entry

            required property Notification notification
            property bool popup: true
            property bool read: false
            property real time: Date.now()

            readonly property int timeout: {
                switch (notification?.urgency) {
                case NotificationUrgency.Low: return Config.notifTimeoutLow;
                case NotificationUrgency.Critical: return Config.notifTimeoutCritical;
                default: return Config.notifTimeoutNormal;
                }
            }

            readonly property Timer timer: Timer {
                interval: entry.timeout
                running: entry.popup && entry.timeout > 0 && !entry.paused
                onTriggered: entry.popup = false
            }
            property bool paused: false     // hovering a popup pauses its timeout

            // A replacing notification (same id, e.g. notify-send -r) updates this object in place: show it again
            function bump() {
                time = Date.now();
                read = root.centerOpen;
                if (!root.dnd) {
                    popup = true;
                    timer.restart();
                }
            }

            readonly property Connections conn: Connections {
                target: entry.notification
                function onClosed() {
                    root._remove(entry);
                }
                function onSummaryChanged() {
                    entry.bump();
                }
                function onBodyChanged() {
                    entry.bump();
                }
            }
        }
    }
}
