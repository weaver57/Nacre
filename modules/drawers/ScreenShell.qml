import QtQuick
import Nacre.Config

/**
 * ScreenShell — one shell instance bound to a single physical display.
 *
 * Spawned by DrawersScope for each connected screen. Owns the bar,
 * drawers, and any other per-screen components for this display.
 *
 * The `screen` property is set by the parent Repeater — don't set it
 * manually. Each ScreenShell inherits the geometry of its assigned
 * screen, so positioning inside is always relative to that display.
 */
Item {
    id: shell

    // Assigned by DrawersScope via modelData — the Qt screen this shell owns.
    required property var screen

    anchors.fill: parent

    // All children render on this screen's surface automatically
    // because QtQuick propagates the screen assignment down the tree.

    // ── Per-screen components go here ─────────────────────────────
    // Bar, drawers, widgets, and overlays will be added as children.
    // Example:
    //   Bar { screen: shell.screen }
    //   Drawer { screen: shell.screen }
}
