import QtQuick
import Quickshell
import Nacre.Config

/**
 * DrawersScope — the multi-monitor orchestrator.
 *
 * Iterates every connected screen and spawns one ScreenShell per display.
 * This is the single place that makes multi-monitor "just work" — no
 * per-display hard-wiring. When a monitor is plugged in or removed at
 * runtime, the children update automatically via the Repeater model.
 *
 * Usage: place this as the root component of your shell entry point.
 */
RootObject {
    id: root

    // ── Screen management ─────────────────────────────────────────
    // Quickshell exposes connectedScreens as a list of Screen objects.
    // Repeater reacts to additions/removals without manual bookkeeping.
    Repeater {
        model: Quickshell.screens

        ScreenShell {
            required property var modelData

            screen: modelData
        }
    }
}
