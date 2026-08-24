import QtQuick

/**
 * ScreenShell — one shell instance bound to a single physical display.
 *
 * Spawned by DrawersScope for each connected screen. Owns the bar,
 * drawers, and any other per-screen components for this display.
 */
Item {
    id: shell

    required property var screen

    anchors.fill: parent

    // Per-screen components are added as children by the parent.
}
