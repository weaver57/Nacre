pragma Singleton
import QtQuick
import Quickshell.Networking

/**
 * NetworkService — reactive network state via direct NetworkManager
 * binding (Phase 2 spec §2.5, Strategy A).
 *
 * This build of Quickshell ships Quickshell.Networking — a first-party,
 * event-driven NetworkManager binding sitting on the system D-Bus
 * (org.freedesktop.NetworkManager). NetworkService binds to it
 * reactively: NM pushes property-change signals over D-Bus, and every
 * property below re-evaluates automatically. No Process, no output
 * parsing, no polling timer — the same pattern HyprlandService uses
 * for the compositor.
 *
 * Discovery notes (probed live against this machine's NM version):
 *   • Devices/networks populate asynchronously over D-Bus — bindings,
 *     not one-shot reads, are mandatory.
 *   • Device.type enum numbering differs from raw NM D-Bus values, so
 *     wifi-vs-wired is detected by CAPABILITY (a device exposing a
 *     `networks` model is wireless), not by comparing magic numbers.
 *   • WifiNetwork.signalStrength arrives normalized 0.0–1.0 and is
 *     scaled to 0–100 here — widgets never do unit math.
 *
 * Availability contract (§1.3.4): available means "NetworkManager is
 * reachable and reporting" — NOT "currently connected", which is what
 * connectionType expresses. Read-only in Phase 2: network switching is
 * explicitly deferred (§2.5.3); the binding exposes connect/disconnect
 * methods but this service deliberately does not surface them.
 */
QtObject {
    id: root

    // ── State ────────────────────────────────────────────────────

    // True when NetworkManager answers: at least one managed device
    // reported, or connectivity is known. False while NM is unreachable
    // (service stopped) or before the first D-Bus round-trip lands.
    readonly property bool available:
        _devices.length > 0 || Networking.connectivity > 0

    // wifi / ethernet / disconnected — small enum-like string per §2.5.2.
    readonly property string connectionType: {
        const dev = _activeDevice
        if (!dev) return "disconnected"
        if (dev.networks !== undefined) return "wifi"      // capability check
        return "ethernet"
    }

    // Current AP name when on wifi, empty otherwise.
    readonly property string ssid: _activeNetwork ? (_activeNetwork.name ?? "") : ""

    // Normalized 0–100, wifi only; 0 otherwise.
    readonly property int signalStrength: {
        if (!_activeNetwork) return 0
        const raw = _activeNetwork.signalStrength ?? 0
        return Math.max(0, Math.min(100, Math.round(raw * 100)))
    }

    // ── Internal reactive plumbing ───────────────────────────────

    // All NM-managed devices. Populates asynchronously over D-Bus;
    // re-evaluates on add/remove/change signals.
    readonly property var _devices: Networking.devices?.values ?? []

    // First device with an active connection (wifi or wired).
    readonly property var _activeDevice: {
        const devs = _devices
        for (let i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].connected) return devs[i]
        }
        return null
    }

    // Active AP within the active wifi device, if any.
    readonly property var _activeNetwork: {
        const dev = _activeDevice
        if (!dev || dev.networks === undefined) return null
        const nets = dev.networks.values ?? []
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i]
        }
        return null
    }

    // ── State transition logging ─────────────────────────────────
    // Fires only on actual changes, never on polls (there are none).
    // Logged via callLater because change handlers run mid-binding
    // evaluation, before sibling properties have been updated.
    onAvailableChanged: {
        console.log("[NetworkService] available:", available)
    }
    onConnectionTypeChanged: {
        Qt.callLater(function () {
            console.log("[NetworkService] connection:", root.connectionType,
                root.connectionType === "wifi"
                    ? "(\"" + root.ssid + "\", " + root.signalStrength + "%)"
                    : "")
        })
    }

    Component.onCompleted: {
        console.log("[NetworkService] bound to Quickshell.Networking",
                     "(NetworkManager via system D-Bus) — event-driven")
    }
}
