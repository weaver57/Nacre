import QtQuick
import "../../services" as Services

/**
 * Network — global network status indicator for the bar.
 *
 * Shows connection type icon + SSID (when wifi) or "eth" (when ethernet).
 * Shows a "no connection" icon when NetworkManager is reachable but
 * nothing is connected. Hidden only when NetworkService is unavailable
 * (NetworkManager unreachable on this machine).
 *
 * Global widget (not per-monitor) — network state is the same everywhere.
 * Colors are hardcoded (Phase 2 acceptable debt, themed in Phase 4).
 */
Item {
    id: root

    // Hidden only when the backing system is absent (desktops without
    // NetworkManager). Disconnected is a real state worth showing.
    visible: Services.NetworkService.available

    implicitWidth: networkRow.implicitWidth
    implicitHeight: networkRow.implicitHeight

    Row {
        id: networkRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Connection type icon
        Text {
            text: {
                switch (Services.NetworkService.connectionType) {
                    case "wifi": return "\u{1F4F6}"
                    case "ethernet": return "\u{1F50C}"
                    default: return "\u{1F4F5}"
                }
            }
            color: "#cdd6f4"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        // SSID or connection type label
        Text {
            visible: Services.NetworkService.connectionType !== "disconnected"
            text: {
                if (Services.NetworkService.connectionType === "wifi") {
                    return Services.NetworkService.ssid
                } else if (Services.NetworkService.connectionType === "ethernet") {
                    return "eth"
                }
                return ""
            }
            color: "#cdd6f4"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        // Signal strength bars (wifi only)
        Text {
            visible: Services.NetworkService.connectionType === "wifi"
            text: {
                var s = Services.NetworkService.signalStrength
                if (s >= 80) return "\u2582\u2584\u2586\u2588"
                if (s >= 60) return "\u2582\u2584\u2586\u2591"
                if (s >= 40) return "\u2582\u2584\u2591\u2591"
                if (s >= 20) return "\u2582\u2591\u2591\u2591"
                return "\u2591\u2591\u2591\u2591"
            }
            color: "#cdd6f4"
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component.onCompleted: {
        console.log("[Network] widget created — available:",
                     Services.NetworkService.available,
                     "type:", Services.NetworkService.connectionType)
    }
}
