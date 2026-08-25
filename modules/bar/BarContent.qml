import QtQuick
import "../../config" as Config
import "../../services" as Services

/**
 * BarContent — the actual bar layout.
 *
 * Layout:
 *   [workspaces] ........................ [volume] [battery] [clock]
 *
 * screen is threaded from ContentWindow → BarWrapper → BarContent → Workspaces
 * so the Workspaces widget can filter workspaces by monitor.
 *
 * Volume, Battery are global widgets (same on all monitors).
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

    // ── Battery (right-aligned, left of clock) ─────────────────
    // Global widget — battery state is the same on every screen.
    Battery {
        id: battery
        anchors.right: clock.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    // ── Volume (right-aligned, left of battery) ────────────────
    // Global widget — scrollable: scroll to adjust, click to mute.
    Volume {
        id: volume
        anchors.right: battery.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }
}
