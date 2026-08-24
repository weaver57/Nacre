import QtQuick

/**
 * BarWrapper — the bar module's entry point.
 *
 * Phase 0: plain bar content. ContentWindow handles visibility
 * based on Config, so no Loader needed here yet.
 */
Item {
    id: wrapper

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "#2d2d44"

        Text {
            anchors.centerIn: parent
            text: "bar (Phase 0)"
            color: "#ffffff"
            font.family: "monospace"
            font.pixelSize: 14
        }
    }
}
