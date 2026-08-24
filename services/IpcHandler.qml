import QtQuick
import Quickshell.Io
import "../state" as State
import "../services" as Services

/**
 * IpcHandler — the external-control door.
 *
 * Instantiated directly in shell.qml as a child of Scope.
 * NOT a singleton — Quickshell.Io.IpcHandler must be a child element
 * to register with the IPC system.
 *
 * Accessible from terminal via:
 *   qs ipc --id <instance> call nacre <method> [args]
 *
 * Methods:
 *   ping              → health check
 *   barToggle         → toggle bar visibility
 *   barShow / barHide → explicit bar control
 *   workspaceSwitch N → switch to workspace N
 *   shellStatus       → JSON with shell state
 *
 * All argument and return types must be explicitly typed.
 */
IpcHandler {
    id: root

    // ── Identity ──────────────────────────────────────────────────
    target: "nacre"

    // ── Health check ─────────────────────────────────────────────
    function ping(): string {
        console.log("[IPC] ping")
        return "pong from " + target
    }

    // ── Bar control ──────────────────────────────────────────────
    function barToggle(): void {
        console.log("[IPC] bar.toggle —", !State.GlobalStates.barOpen ? "showing" : "hiding")
        State.GlobalStates.barOpen = !State.GlobalStates.barOpen
    }

    function barShow(): void {
        console.log("[IPC] bar.show")
        State.GlobalStates.barOpen = true
    }

    function barHide(): void {
        console.log("[IPC] bar.hide")
        State.GlobalStates.barOpen = false
    }

    // ── Workspace control ────────────────────────────────────────
    function workspaceSwitch(id: int): void {
        console.log("[IPC] workspace.switch —", id)
        Services.HyprlandService.switchWorkspace(id)
    }

    // ── Shell status ─────────────────────────────────────────────
    function shellStatus(): string {
        var status = {
            target: target,
            barOpen: State.GlobalStates.barOpen,
            hyprlandAvailable: Services.HyprlandService.available,
            workspaceCount: Services.HyprlandService.workspaces
                ? Services.HyprlandService.workspaces.count : 0,
            focusedWorkspace: Services.HyprlandService.focusedWorkspace
                ? Services.HyprlandService.focusedWorkspace.id : -1
        }
        return JSON.stringify(status)
    }
}
