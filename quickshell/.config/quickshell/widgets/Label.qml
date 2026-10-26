import QtQuick
import qs.config

Text {
    property real s: 1
    property real size: Theme.fontSize

    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Math.round(size * s)
    textFormat: Text.PlainText
}
