import QtQuick
import "../../config" as Config
import "../../services" as Services

/**
 * BarContent — the actual bar layout.
 *
 * Layout:
 *   [workspaces] ........................ [clock]
 *
 * screen is threaded from ContentWindow → BarWrapper → BarContent → Workspaces
 * so the Workspaces widget can filter workspaces by monitor.
 */
Rectangle {
    id: bar

    required property var screen

    color: Config.Config.barPosition === "top" ? "#1a1a2e" : "#16213e"

    // ── Workspaces (left-aligned, per-monitor) ──────────────────
    Workspaces {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        screen: bar.screen
    }

    // ── Clock (right-aligned) ──────────────────────────────────
    Clock {
        id: clock
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }
}
