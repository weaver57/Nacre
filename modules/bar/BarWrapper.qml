import QtQuick

/**
 * BarWrapper — the bar module's entry point.
 *
 * Layer 1 of the three-layer pattern.
 * Receives `screen` from ContentWindow and passes it to BarContent
 * so widgets can filter by monitor.
 */
Item {
    id: wrapper

    required property var screen

    anchors.fill: parent

    BarContent {
        anchors.fill: parent
        screen: wrapper.screen
    }
}
