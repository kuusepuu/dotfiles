import QtQuick
import qs.config
import qs.services
import ".."

Chevron {
    id: root

    side: "right"
    accent: Notifs.dnd ? Theme.overlay1 : Theme.pink
    parts: [Notifs.dnd ? [Icons.bellOff, ""] : Notifs.unread > 0 ? [Icons.bellBadge, String(Notifs.unread)] : [Icons.bell, ""]]

    onClicked: b => {
        if (b === Qt.RightButton) Notifs.dnd = !Notifs.dnd;
        else Notifs.centerOpen = !Notifs.centerOpen;
    }
}
