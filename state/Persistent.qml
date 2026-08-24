pragma Singleton
import QtQuick
import Quickshell.Io

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

    // ── State path (XDG: state, not config) ──────────────────────
    readonly property string stateDir:  "/home/weaver/.local/state/nacre"
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
    property int lastWorkspace: _raw.lastWorkspace ?? 1

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
        console.log("[Persistent] loaded — workspace:", lastWorkspace)
        console.log("[Persistent] path:", statePath)
    }
}
