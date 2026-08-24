import QtQuick
import Quickshell

/**
 * DrawersScope — the multi-monitor orchestrator.
 *
 * Spawns one ScreenShell per display using Variants. This is the
 * single place that makes multi-monitor "just work" — no per-display
 * hard-wiring.
 */
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ScreenShell {
                required property var modelData

                screen: modelData
            }
        }
    }
}
