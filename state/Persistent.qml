pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services

/**
 * Persistent — runtime state that should survive restarts.
 *
 * NOT a "preference" (that's Config). NOT ephemeral (that's GlobalStates).
 * This is state that isn't chosen by the user but needs to remember across
 * restarts: last active workspace, notification history, etc.
 *
 * Reads ~/.local/state/nacre/state.json (XDG state directory, not config).
 * On first run, copies state.default.json if the file doesn't exist.
 */
QtObject {
    id: root

    // ── State path (XDG: state, not config — never hardcoded) ────
    // Resolved from the environment so the shell works from any account
    // or machine. $XDG_STATE_HOME wins when set, else $HOME/.local/state.
    readonly property string stateDir: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        const base = (xdg && xdg.length > 0) ? xdg : Quickshell.env("HOME") + "/.local/state"
        return base + "/nacre"
    }
    readonly property string statePath: stateDir + "/state.json"

    // ── File reader ───────────────────────────────────────────────
    property var _file: FileView {
        path: statePath
        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    property var _raw: _file.loaded ? JSON.parse(_file.text()) : ({})

    // ── Workspace ─────────────────────────────────────────────────
    // Binds to HyprlandService.focusedWorkspace for live tracking.
    // Falls back to persisted value when HyprlandService isn't ready yet.
    // Auto-saves on every change (with init guard to skip the first load).
    // NOTE: focusedWorkspace is a HyprlandWorkspace object, not an int —
    // we need .id to get the numeric workspace ID.
    property int lastWorkspace: {
        var hw = Services.HyprlandService.focusedWorkspace
        return (hw && hw.id > 0) ? hw.id : (_raw.lastWorkspace ?? 1)
    }
    property bool _initialized: false
    onLastWorkspaceChanged: {
        if (_initialized) {
            save()
            console.log("[Persistent] saved workspace:", lastWorkspace)
        }
    }

    // ── Notification history ──────────────────────────────────────
    property var notificationHistory: {
        var history = _raw.notificationHistory ?? []
        return history.slice(-50)
    }

    // ── Write back ────────────────────────────────────────────────
    // Called by consumers when they change persisted state.
    function save() {
        var data = {
            lastWorkspace: lastWorkspace,
            notificationHistory: notificationHistory
        }
        _file.setText(JSON.stringify(data, null, 4))
    }

    Component.onCompleted: {
        _initialized = true
        console.log("[Persistent] loaded — workspace:", lastWorkspace)
        console.log("[Persistent] path:", statePath)
    }
}
