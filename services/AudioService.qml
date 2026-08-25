pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * AudioService — reactive audio state from PipeWire.
 *
 * Wraps Quickshell.Services.Pipewire — first-party PipeWire integration.
 * Exposes default sink volume and mute state. Actions use wpctl for
 * reliability (PipeWire QML property writes can be flaky — see issue #54).
 *
 * Reading: Pipewire.defaultAudioSink.audio (requires PwObjectTracker in shell.qml).
 * Writing: wpctl via Process (reliable, covers all edge cases).
 *
 * Sink-switching is deferred — this service reflects the current default
 * sink only. See Phase 2 spec section 2.4.2.
 */
QtObject {
    id: root

    // ── Availability ─────────────────────────────────────────────
    // False when Pipewire isn't ready or no default sink exists.
    readonly property bool available: Pipewire.ready
        && Pipewire.defaultAudioSink !== null
        && Pipewire.defaultAudioSink.audio !== null

    // ── Volume (0.0–1.0, normalized) ─────────────────────────────
    // Raw Pipewire volume is already 0.0–1.0. Widget never does math.
    property real volume: available
        ? Pipewire.defaultAudioSink.audio.volume
        : 0.0

    // ── Muted state ──────────────────────────────────────────────
    property bool muted: available
        ? Pipewire.defaultAudioSink.audio.muted
        : false

    // ── Scroll step size ─────────────────────────────────────────
    // One scroll step = 5% volume change. Documented in CONVENTIONS.md
    // so all future scrollable widgets use the same ratio.
    readonly property real scrollStep: 0.05

    // ── wpctl wrapper ────────────────────────────────────────────
    // All write actions go through wpctl for reliability.
    // QML property writes to Pipewire can silently fail.
    property var _process: Process {
        command: ["wpctl"]
    }

    // ── Actions ──────────────────────────────────────────────────

    /**
     * Set volume to a specific value (0.0–1.0).
     * Clamped to valid range before dispatch.
     */
    function setVolume(value) {
        var clamped = Math.max(0.0, Math.min(1.0, value))
        _process.command = ["wpctl", "set-volume", "@DEFAULT_SINK@",
                            clamped.toFixed(2)]
        _process.running = true
        console.log("[AudioService] set volume:", clamped.toFixed(2))
    }

    /**
     * Adjust volume by a delta (-1.0 to 1.0).
     * Convenience wrapper for scroll/keybind interaction.
     * One scroll step = scrollStep (0.05 = 5%).
     */
    function adjustVolume(delta) {
        var newVol = Math.max(0.0, Math.min(1.0, volume + delta))
        setVolume(newVol)
    }

    /**
     * Toggle mute on the default sink.
     */
    function toggleMute() {
        _process.command = ["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"]
        _process.running = true
        console.log("[AudioService] toggle mute")
    }

    // ── Sync state from Pipewire ─────────────────────────────────
    // wpctl writes are async — re-read from Pipewire after a short
    // delay to keep QML properties in sync.
    property var _syncTimer: Timer {
        interval: 200
        repeat: false
        onTriggered: root._syncFromPipewire()
    }

    function _syncFromPipewire() {
        if (!available) return
        volume = Pipewire.defaultAudioSink.audio.volume
        muted = Pipewire.defaultAudioSink.audio.muted
    }

    // ── Watch for external volume changes (e.g. hardware keys) ──
    // Re-sync when Pipewire reports a different volume than we have.
    // This covers volume changes from outside Nacre (pavucontrol, media keys).
    onVolumeChanged: {
        if (available && Math.abs(Pipewire.defaultAudioSink.audio.volume - volume) > 0.01) {
            // External change detected — let Pipewire be the source of truth
            volume = Pipewire.defaultAudioSink.audio.volume
        }
    }

    Component.onCompleted: {
        console.log("[AudioService] available:", available,
                     "volume:", volume.toFixed(2),
                     "muted:", muted)
    }
}
