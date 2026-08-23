import QtQuick
import Quickshell
import Nacre.Config

/**
 * ContentWindow — the actual on-screen surface, one per monitor.
 *
 * Anchors itself to a screen edge and sizes itself from Config.
 * Hosts whatever module content gets placed inside it via the
 * `content` property. Knows nothing about bars, drawers, or
 * what it's actually displaying — it's just a region of screen space.
 *
 * Modules drop their UI into `content`; ContentWindow handles
 * positioning, sizing, and screen binding.
 */
PanelWindow {
    id: root

    // ── Screen assignment ─────────────────────────────────────────
    // Set by ScreenShell — determines which physical display this
    // surface renders on.
    required property var screen

    screen: root.screen

    // ── Geometry from Config ──────────────────────────────────────
    // Height/width adapts to bar.position. The window always spans
    // the full width (or height) of the assigned screen.
    implicitHeight: Config.barPosition === "top" || Config.barPosition === "bottom"
                    ? Config.barHeight
                    : screen.height

    implicitWidth: Config.barPosition === "left" || Config.barPosition === "right"
                   ? Config.barHeight
                   : screen.width

    // ── Edge anchoring ────────────────────────────────────────────
    // Panels live at the very edge of the screen. The exclusion zone
    // tells the compositor to reserve space so maximized windows
    // don't overlap this surface.
    anchors {
        top:    Config.isBarAtTop    ? true : undefined
        bottom: Config.isBarAtBottom ? true : undefined
        left:   Config.barPosition === "left"  ? true : undefined
        right:  Config.barPosition === "right" ? true : undefined
    }

    // ── Appearance ────────────────────────────────────────────────
    color: "transparent"

    // ── Content slot ──────────────────────────────────────────────
    // Modules place their UI here. ContentWindow only cares that
    // something fills this space — it never inspects the children.
    default property alias content: container.data

    Item {
        id: container
        anchors.fill: parent
    }
}
