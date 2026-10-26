import QtQuick
import qs.config
import qs.services
import ".."

Chevron {
    id: root

    side: "right"
    accent: Theme.red
    parts: [[Icons.power, ""]]

    onClicked: ShellState.powerMenuOpen = true
}
