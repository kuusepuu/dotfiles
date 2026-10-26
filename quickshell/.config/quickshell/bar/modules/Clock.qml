import QtQuick
import Quickshell
import qs.config
import qs.popups
import ".."

Chevron {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    side: "center"
    accent: Theme.lavender
    padExtra: 14
    parts: [[Icons.clock, Qt.formatDateTime(clock.date, "HH:mm")], [Icons.calendar, Qt.formatDateTime(clock.date, "ddd dd MMM")]]
    compactParts: [["", Qt.formatDateTime(clock.date, "HH:mm")], ["", Qt.formatDateTime(clock.date, "ddd dd")]]

    onClicked: calendar.toggle()

    BarPopup {
        id: calendar
        target: root

        CalendarView {
            s: root.s
            accent: root.accent
            today: clock.date
        }
    }
}
