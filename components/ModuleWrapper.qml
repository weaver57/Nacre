import QtQuick
import "../config" as Config

/**
 * ModuleWrapper — generic Loader pattern for conditionally loading modules.
 *
 * The wrapper sets `moduleName` and provides content via the default
 * property slot. ModuleWrapper reads Config to decide whether the
 * module should be active, and loads/unloads accordingly.
 *
 * Usage:
 *   ModuleWrapper {
 *       moduleName: "bar"
 *       BarContent { }   // goes into default property (content)
 *   }
 */
Item {
    id: root

    // ── Module identity ───────────────────────────────────────────
    required property string moduleName

    // ── Content slot ──────────────────────────────────────────────
    // The actual module content goes here as a child.
    default property alias content: loader.sourceComponent

    // ── Active state ──────────────────────────────────────────────
    // Read from Config: modules.<name>.enabled (bool).
    // Falls back to true if the key is missing — modules are opt-out.
    property bool active: {
        var modules = Config.Config._raw.modules ?? {}
        return modules[root.moduleName]?.enabled ?? true
    }

    // ── Loader ────────────────────────────────────────────────────
    Loader {
        id: loader
        anchors.fill: parent
        active: root.active
    }

    // ── Convenience ───────────────────────────────────────────────
    readonly property bool loaded: loader.status === Loader.Ready
}
