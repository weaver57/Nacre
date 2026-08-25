pragma Singleton
import QtQuick
import Quickshell.Services.UPower

/**
 * BatteryService — reactive battery state from UPower.
 *
 * Wraps Quickshell.Services.UPower — first-party UPower integration.
 * Exposes a single aggregated battery view: percentage, charging state,
 * time remaining. Multiple batteries reduce to one effective state
 * inside this service (widgets never see raw arrays).
 *
 * Read-only by design: battery state isn't user-settable.
 *
 * Data source: scans UPower.devices for a real laptop battery.
 * UPower.displayDevice is an aggregate and unreliable for availability
 * checks (isLaptopBattery can return false even on laptops).
 * Available on machines with a laptop battery; false on desktops.
 *
 * NOTE: UPower populates its devices list asynchronously over D-Bus.
 * The initial scan may find nothing, so we retry with Qt.callLater
 * until a battery appears or we give up after a few attempts.
 */
QtObject {
    id: root

    // ── Battery device reference ─────────────────────────────────
    // The first device that passes isLaptopBattery — reduced to a
    // single device so widgets never see raw arrays.
    property var _battery: null

    // ── Device scan ──────────────────────────────────────────────
    // Scan UPower.devices.values for the first real laptop battery.
    // Called on startup and retried via Qt.callLater if devices
    // haven't populated yet (D-Bus async).
    function _scanDevices() {
        var list = UPower.devices ? UPower.devices.values : []
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].isLaptopBattery) {
                _battery = list[i]
                console.log("[BatteryService] found battery:", list[i].model,
                             "percentage:", list[i].percentage)
                return true
            }
        }
        // Last resort: displayDevice if it reports as a laptop battery
        if (_battery === null && UPower.displayDevice
                && UPower.displayDevice.ready
                && UPower.displayDevice.isLaptopBattery) {
            _battery = UPower.displayDevice
            console.log("[BatteryService] using displayDevice as battery")
            return true
        }
        return false
    }

    // ── Availability ─────────────────────────────────────────────
    // False on desktops with no battery — first real exercise of the
    // unavailability contract. Don't hardcode true.
    readonly property bool available: _battery !== null

    // ── Charge percentage (0–100) ────────────────────────────────
    // UPower may report as 0.0–1.0 fraction or 0–100 integer
    // depending on version. Normalize to always be 0–100.
    readonly property real percentage: available
        ? Math.round(_battery.percentage <= 1 ? _battery.percentage * 100 : _battery.percentage)
        : 0

    // ── Charging state ───────────────────────────────────────────
    readonly property bool charging: available
        ? (_battery.state === UPowerDeviceState.Charging ||
           _battery.state === UPowerDeviceState.PendingCharge)
        : false

    // ── Clean state string ───────────────────────────────────────
    // Exposed as an enum-like string, not raw UPower type — consistent
    // with Phase 1 rule: services expose clean data, not wrapped objects.
    readonly property string state: {
        if (!available) return "unknown"
        switch (_battery.state) {
            case UPowerDeviceState.Charging:        return "charging"
            case UPowerDeviceState.Discharging:     return "discharging"
            case UPowerDeviceState.FullyCharged:    return "full"
            case UPowerDeviceState.PendingCharge:   return "charging"
            case UPowerDeviceState.PendingDischarge: return "discharging"
            case UPowerDeviceState.Empty:           return "empty"
            default:                                return "unknown"
        }
    }

    // ── Time remaining (seconds) ─────────────────────────────────
    // charging → timeToFull, discharging → timeToEmpty, else 0
    readonly property int timeRemaining: {
        if (!available) return 0
        if (charging) return Math.round(_battery.timeToFull)
        if (state === "discharging") return Math.round(_battery.timeToEmpty)
        return 0
    }

    // ── Icon name ────────────────────────────────────────────────
    // UPower provides standard freedesktop icon names
    readonly property string iconName: available
        ? _battery.iconName
        : ""

    Component.onCompleted: {
        // Initial scan — may find nothing if D-Bus hasn't populated yet.
        // Retry a few times with Qt.callLater to catch async population.
        if (!_scanDevices()) {
            Qt.callLater(function() {
                if (!_scanDevices()) {
                    Qt.callLater(function() {
                        if (!_scanDevices()) {
                            Qt.callLater(function() { _scanDevices() })
                        }
                    })
                }
            })
        }
        console.log("[BatteryService] available:", available,
                     "percentage:", percentage,
                     "state:", state)
    }
}
