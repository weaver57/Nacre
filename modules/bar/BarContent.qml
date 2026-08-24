import QtQuick
import "../../config"

/**
 * BarContent — Phase 0 bar implementation.
 *
 * Bare colored rectangle. Proves the Loader convention works:
 * ModuleWrapper loads this when modules.bar.enabled is true,
 * destroys it when false. The actual bar (clock, tray, workspaces)
 * comes later — this is just the skeleton proving the pattern holds.
 *
 * This file will be replaced entirely once real bar widgets land.
 * Don't build on this — it's throwaway scaffolding.
 */
Rectangle {
    id: bar

    color: Config.barPosition === "top" ? "#1a1a2e" : "#16213e"

    // Placeholder label so you can see it's actually rendering
    Text {
        anchors.centerIn: parent
        text: "bar (Phase 0)"
        color: "#e0e0e0"
        font.family: "monospace"
        font.pixelSize: 14
    }
}
