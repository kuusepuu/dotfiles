import QtQuick
import QtQuick.Controls
import qs.config
import qs.widgets

// Month calendar with ISO week numbers; scroll or use the arrows to change month
Column {
    id: root

    property real s: 1
    property color accent: Theme.lavender
    property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()

    readonly property real cell: Math.round(32 * s)

    function shift(d) {
        let m = month + d, y = year;
        while (m < 0) { m += 12; y--; }
        while (m > 11) { m -= 12; y++; }
        month = m;
        year = y;
    }

    spacing: Math.round(6 * s)

    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }

    Item {
        width: grid.width + weeks.width
        height: header.implicitHeight

        IconButton {
            s: root.s
            text: "‹"
            accent: root.accent
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.shift(-1)
        }

        Label {
            id: header
            s: root.s
            anchors.centerIn: parent
            text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
            color: Theme.blue
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.month = root.today.getMonth();
                    root.year = root.today.getFullYear();
                }
            }
        }

        IconButton {
            s: root.s
            text: "›"
            accent: root.accent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.shift(1)
        }
    }

    DayOfWeekRow {
        width: grid.width
        locale: grid.locale
        spacing: 0
        delegate: Label {
            required property string shortName
            s: root.s
            size: Theme.fontSizeSmall
            text: shortName.slice(0, 2)
            color: Theme.subtext0
            horizontalAlignment: Text.AlignHCenter
            width: root.cell
            font.bold: true
        }
    }

    Row {
        MonthGrid {
            id: grid
            month: root.month
            year: root.year
            locale: Qt.locale("en_GB")      // Monday first
            spacing: 0
            width: root.cell * 7

            delegate: Item {
                id: day

                required property var model
                readonly property bool isToday: model.day === root.today.getDate() && model.month === root.today.getMonth() && model.year === root.today.getFullYear()

                width: root.cell
                height: root.cell

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cell - Math.round(4 * root.s)
                    height: width
                    radius: width / 2
                    visible: day.isToday
                    color: Theme.alpha(Theme.green, 0.18)
                    border.color: Theme.green
                    border.width: Math.max(1, Math.round(1.5 * root.s))
                }

                Label {
                    anchors.centerIn: parent
                    s: root.s
                    size: Theme.fontSizeSmall
                    text: day.model.day
                    font.bold: day.isToday
                    color: day.isToday ? Theme.green : day.model.month === root.month ? Theme.text : Theme.surface2
                }
            }
        }

        WeekNumberColumn {
            id: weeks
            month: root.month
            year: root.year
            locale: grid.locale
            spacing: 0
            height: grid.height
            delegate: Label {
                required property int weekNumber
                s: root.s
                size: Theme.fontSizeSmall - 1
                text: weekNumber
                color: Theme.lavender
                opacity: 0.7
                width: root.cell
                height: root.cell
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
