import QtQuick
import Nacre.Config

/**
 * ModuleWrapper — generic Loader pattern for conditionally loading modules.
 *
 * Every module (bar, launcher, notifications, OSD, …) gets its own
 * Wrapper that uses this component. The wrapper sets `moduleName` and
 * `moduleSource`, and ModuleWrapper handles the rest: reading Config
 * to decide whether the module should be active, loading/unloading
 * the actual content, and exposing a clean `active` state.
 *
 * Usage — each module creates its own wrapper:
 *
 *   // In modules/bar/BarWrapper.qml
 *   ModuleWrapper {
 *       moduleName: "bar"
 *       moduleSource: BarContent { }
 *   }
 *
 * The wrapper never inspects what's inside `moduleSource`. It just
 * loads it when the config says "yes" and unloads it when it says "no".
 */
Item {
    id: root

    // ── Module identity ───────────────────────────────────────────
    // Each module declares its name and what to load. The name is
    // used to look up `modules.<name>.enabled` in Config. If the
    // key doesn't exist, the module defaults to enabled.
    required property string moduleName
    required property Item   moduleSource

    // ── Active state ──────────────────────────────────────────────
    // Read from Config: modules.<name>.enabled (bool).
    // Falls back to true if the key is missing — modules are opt-out,
    // not opt-in.
    readonly property bool active: {
        const modules = Config.manager.rawConfig?.modules ?? {}
        return modules[root.moduleName]?.enabled ?? true
    }

    // ── Loader ────────────────────────────────────────────────────
    // sourceComponent is set/cleared based on `active`. When false,
    // the component is fully destroyed — no half-states, no hidden
    // rendering.
    Loader {
        id: loader
        anchors.fill: parent
        active: root.active
        sourceComponent: root.moduleSource
    }

    // ── Convenience ───────────────────────────────────────────────
    // Expose whether the module is currently loaded, so parents can
    // react (e.g. hide empty space when a module is off).
    readonly property bool loaded: loader.status === Loader.Ready
}
