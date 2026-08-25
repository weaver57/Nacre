import QtQuick
import Quickshell
import "./config" as Config
import "./state" as State
import "./components" as Components
import "./modules/bar" as Bar
import "./services" as Services

/**
 * Nacre shell entry point.
 *
 * Initialization order (enforced):
 *   1. Config loads user preferences from shell.json
 *   2. GlobalStates initializes — barOpen seeded from Config.bar.enabledByDefault
 *   3. Persistent loads saved runtime state from state.json
 *   4. Modules activate based on Config.isModuleEnabled()
 *   5. Modules bind to GlobalStates for runtime behavior
 *
 * This order matters because GlobalStates.barOpen reads Config at init time.
 * If Config isn't ready, the seed value is wrong and the bar starts invisible.
 */
Scope {
    id: shell

    // ── Explicit initialization order ─────────────────────────────
    // QML doesn't guarantee property init order, so we force it
    // with Component.onCompleted dependencies.

    // 1. Config (loaded via FileView.blockLoading — ready before anything else)
    property var _configReady: Config.Config._raw

    // 2. GlobalStates (no dependencies except Config — seeded at init)
    property var _statesReady: State.GlobalStates

    // 3. Persistent (loads state.json, XDG state directory)
    property var _persistentReady: State.Persistent

    // ── Per-screen module host ────────────────────────────────────
    // Each monitor gets its own ContentWindow. The Variants model
    // handles hotplug — screens plugged in/out at runtime are
    // created/destroyed automatically.
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Components.ContentWindow {
                required property var modelData

                screen: modelData

                // Bar module — visible if Config enabled AND GlobalStates.open
                Bar.BarWrapper {
                    screen: modelData
                }
            }
        }
    }

    // ── IPC handler ─────────────────────────────────────────────
    // NOT a singleton — must be a child element to register with
    // Quickshell's IPC system. Instantiated here directly.
    Services.IpcHandler { }

    // ── Startup ───────────────────────────────────────────────────
    Component.onCompleted: {
        console.log("[Nacre] initialization order:")
        console.log("  1. Config — height:", Config.Config.barHeight, "position:", Config.Config.barPosition)
        console.log("  2. GlobalStates — barOpen:", State.GlobalStates.barOpen)
        console.log("  3. Persistent — workspace:", State.Persistent.lastWorkspace)
        console.log("[Nacre] started —", Quickshell.screens.length, "monitor(s)")
        console.log("[IPC] target: nacre — try: qs ipc call nacre ping")
    }
}
