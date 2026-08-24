import QtQuick
import Quickshell
import "../../config" as Config

/**
 * Clock — time display for the bar.
 *
 * PROVES THE PATTERN GENERALIZES:
 *   Workspaces = compositor-driven (Hyprland events)
 *   Clock      = time-driven (SystemClock ticks)
 *
 * Both consume different data sources but follow the same pattern:
 *   service owns data → widget binds reactively → no local state.
 *
 * Uses Quickshell's built-in SystemClock directly — no custom service
 * needed because SystemClock already behaves like one (reactive property,
 * owns its data source, zero UI).
 *
 * Updates once per minute (SystemClock.Minutes precision). Format reads
 * from Config.clock.format — live-reloadable without restart.
 */
Item {
    id: root

    // ── Clock source ─────────────────────────────────────────────
    // SystemClock is a Quickshell singleton that ticks at the chosen
    // precision. Minutes saves CPU vs Seconds — the eye can't tell
    // the difference in a bar clock at minute granularity.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Display ──────────────────────────────────────────────────
    Text {
        id: timeText

        anchors.verticalCenter: parent.verticalCenter

        // Format from Config — live-reloadable via shell.json
        text: Qt.formatDateTime(clock.date, Config.Config.clockFormat)

        color: "#e0e0e0"
        font.family: "monospace"
        font.pixelSize: 13

        // ── Placeholder while Config loads ───────────────────────
        Component.onCompleted: {
            console.log("[Clock] format:", Config.Config.clockFormat)
        }
    }

    // ── Sizing ───────────────────────────────────────────────────
    // Let the parent layout size us based on text width.
    implicitWidth: timeText.implicitWidth + 16
    implicitHeight: timeText.implicitHeight + 8
}
