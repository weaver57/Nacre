import QtQuick
import Nacre.Components

/**
 * BarWrapper — the bar module's entry point.
 *
 * Uses ModuleWrapper to conditionally load BarContent based on
 * `modules.bar.enabled` in Config. This is the reference
 * implementation of the Wrapper pattern — every future module
 * (launcher, notifications, OSD, …) follows this same shape:
 *
 *   ModuleWrapper {
 *       moduleName: "<module>"
 *       moduleSource: <ModuleContent> { }
 *   }
 *
 * To disable the bar, set `"modules": { "bar": { "enabled": false } }`
 * in shell.json. No code changes needed.
 */
ModuleWrapper {
    moduleName: "bar"
    moduleSource: BarContent { }
}
