pragma Singleton
import QtQuick
import Quickshell.Hyprland

/**
 * HyprlandService — compositor data source.
 *
 * Wraps Quickshell.Hyprland's singleton into a clean, opinionated interface.
 * Widgets never import Quickshell.Hyprland directly — they go through this
 * service. This keeps compositor-specific code in ONE file so swapping
 * compositors later (niri, Sway) means rewriting only this file.
 *
 * Rules:
 *   - Pure data, zero visual elements (no Rectangle, Text, Item).
 *   - Exposes reactive QML properties — never poll-based.
 *   - Action functions dispatch through Hyprland, never bypass the service.
 *   - No UI module imports. Services → modules, never the reverse.
 *   - Safe to instantiate even if Hyprland IPC isn't ready yet.
 *
 * Properties are pass-through aliases where the shape already matches.
 * If a future transformation is needed (e.g. filtering, sorting, computing
 * derived state), it goes here — not in the widget.
 */
QtObject {
    id: root

    // ── Availability ──────────────────────────────────────────────
    // Flipped true once we confirm Hyprland's IPC is responsive.
    // Consumers MUST check this before reading data-dependent properties.
    // Shows a neutral placeholder when false — not a blank crash-shaped gap.
    property bool available: false

    // ── Workspaces ────────────────────────────────────────────────
    // All workspaces, sorted by id. Named workspaces have negative ids
    // and appear before unnamed ones.
    //
    // ObjectModel<HyprlandWorkspace> — each entry has:
    //   id, name, focused, active, monitor, toplevels, hasFullscreen, urgent
    //
    // Use HyprlandService.workspaces in a Repeater. Each item is a
    // HyprlandWorkspace with reactive properties.
    //
    // NOTE: Can't use property alias here — Hyprland is an imported
    // singleton, not a local id. Direct binding achieves the same
    // reactivity: Hyprland's properties change → this property updates.
    property var workspaces: Hyprland.workspaces

    // ── Focused workspace ─────────────────────────────────────────
    // The workspace that has keyboard focus RIGHT NOW.
    // May be null — consumers MUST null-check before accessing .id, .name.
    property var focusedWorkspace: Hyprland.focusedWorkspace

    // ── Monitors ──────────────────────────────────────────────────
    // All connected monitors. Each has:
    //   id, name, focused, activeWorkspace, width, height, scale, x, y
    //
    // Per-monitor widgets bind to their monitor's activeWorkspace
    // to show the correct workspace indicator per display.
    property var monitors: Hyprland.monitors

    // ── Focused monitor ───────────────────────────────────────────
    // The monitor that currently has keyboard focus.
    // May be null.
    property var focusedMonitor: Hyprland.focusedMonitor

    // ── Active toplevel ───────────────────────────────────────────
    // The window (toplevel) that currently has focus.
    // May be null. Useful for future window-title or app-indicator widgets.
    property var activeToplevel: Hyprland.activeToplevel

    // ── All toplevels ─────────────────────────────────────────────
    // Every window open across all workspaces.
    // ObjectModel<Toplevel> — useful for future taskbar/dock work.
    property var toplevels: Hyprland.toplevels

    // ── Actions ───────────────────────────────────────────────────
    // Compositor dispatchers routed through the service.
    // Widgets NEVER call Hyprland.dispatch() directly.

    /**
     * Switch to a workspace by id.
     * @param id  The workspace id (integer). Named workspaces have negative ids.
     */
    function switchWorkspace(id) {
        if (!available) {
            console.warn("[HyprlandService] switchWorkspace: not available")
            return
        }
        Hyprland.dispatch("workspace " + id)
    }

    /**
     * Switch to a workspace by name.
     * @param name  The workspace name string (e.g. "1", "web", "code").
     */
    function switchToWorkspace(name) {
        if (!available) {
            console.warn("[HyprlandService] switchToWorkspace: not available")
            return
        }
        Hyprland.dispatch("workspace " + name)
    }

    /**
     * Move the focused window to a workspace without following it.
     * @param id  Target workspace id.
     */
    function moveToWorkspace(id) {
        if (!available) {
            console.warn("[HyprlandService] moveToWorkspace: not available")
            return
        }
        Hyprland.dispatch("movetoworkspace " + id)
    }

    /**
     * Move the focused window to a workspace and follow it.
     * @param id  Target workspace id.
     */
    function moveToWorkspaceFollow(id) {
        if (!available) {
            console.warn("[HyprlandService] moveToWorkspaceFollow: not available")
            return
        }
        Hyprland.dispatch("movetoworkspace " + id + " follow")
    }

    /**
     * Toggle floating on the focused window.
     */
    function toggleFloating() {
        if (!available) return
        Hyprland.dispatch("togglefloating")
    }

    /**
     * Kill the focused window.
     */
    function killActive() {
        if (!available) return
        Hyprland.dispatch("killactive")
    }

    /**
     * Pass a raw dispatcher command. Use sparingly — prefer named
     * functions above so callers don't need to know Hyprland syntax.
     * @param request  Raw Hyprland dispatcher string.
     */
    function dispatch(request) {
        if (!available) {
            console.warn("[HyprlandService] dispatch: not available")
            return
        }
        Hyprland.dispatch(request)
    }

    // ── Refresh helpers ───────────────────────────────────────────
    // Hyprland doesn't always send events for state changes (e.g.
    // monitor plug/unplug). These force a re-read when needed.

    function refreshWorkspaces() { Hyprland.refreshWorkspaces() }
    function refreshMonitors()   { Hyprland.refreshMonitors() }
    function refreshToplevels()  { Hyprland.refreshToplevels() }

    // ── Availability detection ────────────────────────────────────
    // Hyprland's IPC socket paths are the ground truth. If they exist,
    // the compositor is responsive. We check on first event AND on
    // Component.onCompleted (covers both fast and slow startup).
    Connections {
        target: Hyprland
        function onRawEvent() {
            if (!root.available) {
                root.available = true
                console.log("[HyprlandService] available — Hyprland IPC responsive")
            }
        }
    }

    Component.onCompleted: {
        // If Hyprland loaded without error, the import succeeded,
        // which means the compositor is at least partially alive.
        // The rawEvent handler above will confirm full responsiveness.
        if (Hyprland.workspaces && Hyprland.workspaces.count > 0) {
            available = true
            console.log("[HyprlandService] available —", Hyprland.workspaces.count, "workspaces")
        } else {
            console.log("[HyprlandService] waiting for Hyprland IPC...")
        }
    }
}
