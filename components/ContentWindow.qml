import QtQuick
import Quickshell
import "../config" as Config
import "../state" as State

/**
 * ContentWindow — the actual on-screen surface, one per monitor.
 *
 * Visibility logic (two-layer check):
 *   1. Config.isModuleEnabled("bar") — user preference (persisted in shell.json)
 *   2. State.GlobalStates.barOpen — runtime toggle (ephemeral, resets on restart)
 *
 * Both must be true for the window to show. Config controls whether
 * the module is installed/enabled; GlobalStates controls whether it's
 * open right now this session.
 *
 * When hidden, the PanelWindow is fully invisible and the compositor
 * reclaims the exclusion zone — other windows fill the space.
 */
PanelWindow {
    id: root

    required property var screen

    screen: root.screen

    // ── Visibility ────────────────────────────────────────────────
    // Preference (persisted) AND runtime toggle (ephemeral) must both be true
    visible: Config.Config.isModuleEnabled("bar") && State.GlobalStates.barOpen

    // ── Height from Config ────────────────────────────────────────
    implicitHeight: Config.Config.barHeight ?? 32

    // ── Anchor to top edge ────────────────────────────────────────
    // Phase 0: hardcoded to top. Phase 2+ will read from Config.barPosition
    // once the multi-position layout system is built.
    anchors {
        top: true
        left: true
        right: true
    }

    // ── Background ────────────────────────────────────────────────
    // Visible so the bar has a surface. Theme colors come in Phase 4.
    color: "#1a1a2e"

    // ── Content slot ──────────────────────────────────────────────
    // Modules drop their content here. ContentWindow knows nothing
    // about what a "bar" is — it just hosts a region of content.
    default property alias content: container.data

    Item {
        id: container
        anchors.fill: parent
    }
}
