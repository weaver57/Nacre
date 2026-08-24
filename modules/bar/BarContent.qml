import QtQuick
import "../../config" as Config
import "../../services" as Services

/**
 * BarContent — the actual bar layout.
 *
 * Real bar layout with two consumer widgets:
 *   - Workspaces (left): compositor-driven, reads HyprlandService
 *   - Clock (right): time-driven, reads SystemClock + Config
 *
 * Layout:
 *   [workspaces] ........................ [clock]
 *
 * Proves the service pattern generalizes: both widgets bind
 * reactively to their data source, no local state, no polling.
 */
Rectangle {
    id: bar

    color: Config.Config.barPosition === "top" ? "#1a1a2e" : "#16213e"

    // ── Workspaces (left-aligned) ────────────────────────────────
    Workspaces {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    // ── Clock (right-aligned) ──────────────────────────────────
    // Time-driven data source — proves the pattern works beyond Hyprland.
    Clock {
        id: clock
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }
}
