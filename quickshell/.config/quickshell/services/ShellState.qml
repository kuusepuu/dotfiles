pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool powerMenuOpen: false
    // The click-opened bar popup that is currently open; opening one closes the others
    property var activePopup: null
    // All bar windows; included in focus grabs so clicking the bar doesn't count as an outside click
    property var barWindows: []
}
