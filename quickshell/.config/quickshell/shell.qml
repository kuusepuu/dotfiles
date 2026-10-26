//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "bar"
import "notifications"
import "osd"
import "powermenu"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    NotifPopups {}
    NotifCenter {}
    Osd {}
    PowerMenu {}

    IpcHandler {
        target: "notifs"

        function dismissLatest(): void {
            Notifs.dismissLatest();
        }
        function hideAll(): void {
            Notifs.hideAllPopups();
        }
        function clearAll(): void {
            Notifs.clearAll();
        }
        function toggleCenter(): void {
            Notifs.centerOpen = !Notifs.centerOpen;
        }
        function toggleDnd(): void {
            Notifs.dnd = !Notifs.dnd;
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            ShellState.powerMenuOpen = !ShellState.powerMenuOpen;
        }
    }
}
