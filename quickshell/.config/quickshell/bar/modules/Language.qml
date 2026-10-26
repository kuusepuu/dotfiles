import QtQuick
import qs.config
import qs.services
import ".."

Chevron {
    id: root

    side: "right"
    accent: Theme.rosewater
    priority: 5
    present: KbLayout.layout !== ""
    parts: [[Icons.keyboard, KbLayout.short]]
    compactParts: [["", KbLayout.short]]

    onClicked: KbLayout.next()
}
