import QtQuick
import "../../services" as Services

/**
 * Battery — global battery indicator for the bar.
 *
 * Shows battery percentage and a charging indicator.
 * Global widget (not per-monitor) — battery state is the same
 * on every screen. Only visible when BatteryService.available is true
 * (i.e., machine has a laptop battery — hidden on desktops).
 *
 * This is the first "global widget" in Nacre — unlike Workspaces
 * (per-monitor), battery/audio/tray/network are not screen-specific.
 * See CONVENTIONS.md for the distinction.
 *
 * Colors are hardcoded (Phase 2 acceptable debt, themed in Phase 4).
 */
Item {
    id: root

    // Only visible on machines with a battery
    visible: Services.BatteryService.available

    implicitWidth: batteryRow.implicitWidth
    implicitHeight: batteryRow.implicitHeight

    Row {
        id: batteryRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Battery icon text (chargning indicator)
        Text {
            text: Services.BatteryService.charging ? "⚡" : "🔋"
            color: "#cdd6f4"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        // Percentage text
        Text {
            text: Services.BatteryService.percentage + "%"
            color: "#cdd6f4"
            font.pixelSize: 13
            font.family: "monospace"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component.onCompleted: {
        console.log("[Battery] widget created — available:",
                     Services.BatteryService.available)
    }
}
