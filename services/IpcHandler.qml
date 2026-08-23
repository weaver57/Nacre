import QtQuick

/**
 * IpcHandler — the external-control door.
 *
 * Registers a named IPC target on the shell root so external processes
 * (CLI tools, AI agents, scripts) can talk to the running shell.
 *
 * Phase 0: just a stub with a ping method. The real IPC transport
 * (D-Bus, socket, or Quickshell's own mechanism) gets wired in later.
 * Right now this only proves the interface exists and is callable.
 *
 * The `targetName` is the well-known name other processes use to
 * address this shell instance. Change it if you want multiple shells
 * on the same machine.
 */
QtObject {
    id: root

    // ── Identity ──────────────────────────────────────────────────
    // Well-known name for this IPC target. External processes use
    // this to find and address the shell.
    readonly property string targetName: "org.nacre.shell"

    // ── Methods ───────────────────────────────────────────────────
    // These are the "API" that external callers hit. For now there's
    // only one. New methods get added here as the AI CLI integration
    // and other external tools need them.

    /**
     * Ping — trivial health-check.
     * Returns a fixed string so callers can confirm the shell is alive.
     *
     * Future: this is where the AI CLI sends commands like
     * "toggle bar", "reload config", "spawn widget", etc.
     */
    function ping() {
        console.log("[IPC] ping received from", Qt.target ?? "unknown")
        return "pong from " + targetName
    }

    // ── Future hooks ──────────────────────────────────────────────
    // When real IPC lands, the transport layer calls into these:
    //
    //   function handleCommand(command, args) { ... }
    //   function broadcast(event, payload) { ... }
    //
    // For now, ping is the only door open.
}
