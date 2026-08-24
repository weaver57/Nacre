import QtQuick
import "../../config" as Config
import "../../services" as Services

/**
 * BarContent — the actual bar layout.
 *
 * Phase 0 was a placeholder rectangle. This is the first real content:
 * workspaces on the left, clock will go on the right (Phase 1 step 1.6).
 *
 * Layout:
 *   [workspaces] ........................ [clock]
 *
 * The bar's height and background color come from Config.
 * The workspaces widget reads from HyprlandService — proving
 * the service → widget binding works end-to-end.
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

    // ── Center label (temporary — clock goes here in 1.6) ────────
    Text {
        anchors.centerIn: parent
        text: Services.HyprlandService.available
              ? "Nacre"
              : "waiting for Hyprland..."
        color: "#666677"
        font.family: "monospace"
        font.pixelSize: 12
    }
}
