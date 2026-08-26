import QtQuick
import "../../config" as Config
import "../../services" as Services

/**
 * Battery — global battery indicator for the bar (Phase 2 §2.7.1).
 *
 * Shows a charge-state icon + percentage text. The icon reflects three
 * visual states:
 *   - Charging: ⚡ (regardless of percentage)
 *   - Full:     🔋 with standard color
 *   - Low:      🔋 with a warning color — when percentage ≤
 *               Config.batteryLowThreshold while discharging
 *   - Normal:   🔋 with standard color
 *
 * Global widget (not per-monitor). Collapses entirely when
 * BatteryService.available is false (desktops with no battery).
 * No click/interaction — that is a Phase 3+ concern (power menu).
 *
 * Colors are hardcoded (Phase 2 acceptable debt, themed in Phase 4).
 */
Item {
    id: root

    visible: Services.BatteryService.available

    readonly property bool _isLow:
        Services.BatteryService.percentage <= Config.Config.batteryLowThreshold
        && Services.BatteryService.state === "discharging"

    implicitWidth: batteryRow.implicitWidth
    implicitHeight: batteryRow.implicitHeight

    Row {
        id: batteryRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Charge-state icon — three visual states
        Text {
            text: {
                if (Services.BatteryService.charging) return "⚡"
                if (Services.BatteryService.state === "full") return "🔋"
                return "🔋"
            }
            color: root._isLow ? "#f38ba8" : "#cdd6f4"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        // Percentage text — warning color when low
        Text {
            text: Services.BatteryService.percentage + "%"
            color: root._isLow ? "#f38ba8" : "#cdd6f4"
            font.pixelSize: 13
            font.family: "monospace"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component.onCompleted: {
        console.log("[Battery] widget created — available:",
                     Services.BatteryService.available,
                     "lowThreshold:", Config.Config.batteryLowThreshold)
    }
}
