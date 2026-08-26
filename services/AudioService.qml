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
 * Reading: `volume`/`muted` are PURE BINDINGS to Pipewire — never assigned
 * anywhere in this file. Assigning them would destroy the binding (QML
 * semantics), after which external changes (media keys, pavucontrol)
 * stop reaching the widget. wpctl writes need no manual sync either:
 * PipeWire emits change notifications, the bindings re-evaluate, done.
 * (An earlier _syncFromPipewire/onVolumeChanged scheme did exactly this
 * wrong — removed. See Phase 2 audit.)
 *
 * Writing: single wpctl Process with a one-deep pending queue — commands
 * issued while a previous wpctl is still running are replayed on exit
 * instead of silently dropped during fast scrolling.
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
    // Pure binding — NEVER assign this property; it would break the
    // reactive chain to Pipewire. Widget never does math.
    readonly property real volume: available
        ? Pipewire.defaultAudioSink.audio.volume
        : 0.0

    // ── Muted state ──────────────────────────────────────────────
    // Pure binding — same rule as volume.
    readonly property bool muted: available
        ? Pipewire.defaultAudioSink.audio.muted
        : false

    // ── Scroll step size ─────────────────────────────────────────
    // One scroll step = 2% volume change (0.02). Documented in
    // CONVENTIONS.md so all future scrollable widgets use the same ratio.
    readonly property real scrollStep: 0.02

    // ── wpctl runner ─────────────────────────────────────────────
    // All write actions go through wpctl for reliability.
    property var _process: Process {
        id: proc
        command: ["wpctl"]

        onExited: {
            // Drain the queue — a command that arrived while we were
            // busy gets replayed now instead of being dropped.
            if (root._pendingCommand !== null) {
                proc.command = root._pendingCommand
                root._pendingCommand = null
                proc.running = true
            }
        }
    }

    // Command waiting for the process to free up (one-deep is enough:
    // each drain runs to completion before the next replay).
    property var _pendingCommand: null

    function _run(args) {
        if (proc.running) {
            _pendingCommand = args   // latest request wins
        } else {
            proc.command = args
            proc.running = true
        }
    }

    // ── Actions ──────────────────────────────────────────────────

    /**
     * Set volume to a specific value (0.0–1.0).
     * Clamped to valid range before dispatch.
     */
    function setVolume(value) {
        const clamped = Math.max(0.0, Math.min(1.0, value))
        _run(["wpctl", "set-volume", "@DEFAULT_SINK@", clamped.toFixed(2)])
    }

    /**
     * Adjust volume by a delta (-1.0 to 1.0).
     * Convenience wrapper for scroll/keybind interaction.
     * One scroll step = scrollStep (2% = 0.02).
     */
    function adjustVolume(delta) {
        setVolume(volume + delta)
    }

    /**
     * Toggle mute on the default sink.
     */
    function toggleMute() {
        console.log("[AudioService] toggle mute")
        _run(["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"])
    }

    // ── State transition logging ─────────────────────────────────
    onMutedChanged: console.log("[AudioService] muted:", muted)
    onAvailableChanged: console.log("[AudioService] available:", available,
                                     "volume:", Math.round(volume * 100) + "%")

    Component.onCompleted: {
        console.log("[AudioService] ready — volume:",
                     Math.round(volume * 100) + "%", "muted:", muted)
    }
}
