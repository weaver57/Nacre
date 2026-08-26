pragma Singleton
import QtQuick
import Quickshell.Services.UPower

/**
 * BatteryService — reactive battery state from UPower.
 *
 * Wraps Quickshell.Services.UPower — first-party UPower integration.
 * Exposes a single aggregated battery view: percentage, charging state,
 * clean state string, time remaining. Per Phase 2 spec §2.3.4, multiple
 * batteries reduce to ONE effective state here (percentage weighted by
 * each battery's energyFull capacity) — widgets never see raw arrays.
 *
 * Read-only by design: battery state isn't user-settable.
 *
 * Availability contract (§1.3.4): available is a REACTIVE scan of
 * UPower.devices — no one-shot startup probe, no callLater retry hacks.
 * If UPower populates slowly over D-Bus or a battery appears later
 * (hotplug), bindings re-evaluate automatically. False on desktops.
 */
QtObject {
    id: root

    // ── Reactive device scan ─────────────────────────────────────
    // Every laptop battery UPower currently reports. Re-evaluates when
    // the ObjectModel changes AND when any member device's properties
    // change (QML bindings track the property reads below).
    readonly property var _batteries: {
        const list = UPower.devices ? UPower.devices.values : []
        const out = []
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].isLaptopBattery) out.push(list[i])
        }
        return out
    }

    // ── Availability ─────────────────────────────────────────────
    // False on machines with no laptop battery (desktops).
    readonly property bool available: _batteries.length > 0

    // ── Charge percentage (0–100, capacity-weighted aggregate) ───
    // Weighted by energyFull so a big battery dominates the average —
    // the physically correct effective charge. Batteries that don't
    // expose energyFull fall back to unweighted mean participation.
    // UPower may report 0.0–1.0 or 0–100 depending on version;
    // normalized to always be 0–100.
    readonly property real percentage: {
        if (!available) return 0
        let weighted = 0
        let totalWeight = 0
        for (let i = 0; i < _batteries.length; i++) {
            const b = _batteries[i]
            const pct = b.percentage <= 1 ? b.percentage * 100 : b.percentage
            const weight = (b.energyFull ?? 0) > 0 ? b.energyFull : 1
            weighted += pct * weight
            totalWeight += weight
        }
        return totalWeight > 0 ? Math.round(weighted / totalWeight) : 0
    }

    // ── Charging state (any battery charging) ────────────────────
    readonly property bool charging: {
        if (!available) return false
        for (let i = 0; i < _batteries.length; i++) {
            const s = _batteries[i].state
            if (s === UPowerDeviceState.Charging ||
                s === UPowerDeviceState.PendingCharge) return true
        }
        return false
    }

    // ── Clean state string ───────────────────────────────────────
    // Enum-like string per spec §2.3.2 — services expose clean data,
    // not wrapped objects. Aggregate rule: charging wins; full only if
    // every battery reports fully charged; discharging otherwise.
    readonly property string state: {
        if (!available) return "unknown"
        if (charging) return "charging"
        let allFull = true
        for (let i = 0; i < _batteries.length; i++) {
            const s = _batteries[i].state
            if (s === UPowerDeviceState.FullyCharged) continue
            allFull = false
            break
        }
        if (allFull) return "full"
        return "discharging"
    }

    // ── Time remaining (seconds, worst-case across batteries) ────
    // charging → longest timeToFull; discharging → shortest timeToEmpty.
    readonly property int timeRemaining: {
        if (!available || state === "full") return 0
        let best = 0
        for (let i = 0; i < _batteries.length; i++) {
            const b = _batteries[i]
            const t = Math.round(charging ? b.timeToFull ?? 0 : b.timeToEmpty ?? 0)
            if (t <= 0) continue
            best = best === 0 ? t : (charging ? Math.max(best, t) : Math.min(best, t))
        }
        return best
    }

    // ── Icon name (freedesktop standard, from first battery) ─────
    readonly property string iconName: available ? (_batteries[0].iconName ?? "") : ""

    // ── State transition logging ─────────────────────────────────
    onAvailableChanged: console.log("[BatteryService] available:", available)
    onStateChanged: console.log("[BatteryService] state:", state,
                                 "percentage:", percentage + "%")

    Component.onCompleted: {
        console.log("[BatteryService] scanning", _batteries.length,
                     "battery(ies) reactively via UPower")
    }
}
