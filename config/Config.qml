pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Config — user preferences.
 *
 * Reads ~/.config/nacre/shell.json. On first run, copies the
 * default config from the repo if the file doesn't exist.
 *
 * Path convention:
 *   ~/.config/nacre/shell.json  (live config, gitignored)
 *   repo/shell.default.json     (shipped default, committed)
 */
QtObject {
    id: root

    // ── Config path (XDG — never hardcoded) ──────────────────────
    // Resolved from the environment so the shell works from any account
    // or machine. $XDG_CONFIG_HOME wins when set, else $HOME/.config.
    readonly property string configDir: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME")
        const base = (xdg && xdg.length > 0) ? xdg : Quickshell.env("HOME") + "/.config"
        return base + "/nacre"
    }
    readonly property string configPath: configDir + "/shell.json"

    // ── File reader ───────────────────────────────────────────────
    property var _file: FileView {
        path: configPath
        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    property var _raw: _file.loaded ? JSON.parse(_file.text()) : ({})

    // ── Bar preferences ───────────────────────────────────────────
    readonly property int    barHeight:          _raw.bar?.height ?? 32
    readonly property string barPosition:        _raw.bar?.position ?? "top"
    readonly property bool   barEnabledByDefault: _raw.bar?.enabledByDefault ?? true

    // ── Clock preferences ────────────────────────────────────────
    readonly property string clockFormat: _raw.clock?.format ?? "HH:mm"

    // ── Theme ─────────────────────────────────────────────────────
    readonly property string theme: _raw.theme ?? "default"

    // ── Module preferences (opt-out) ──────────────────────────────
    // NOTE: bar.enabledByDefault is the user preference for the bar module.
    //       This function checks if ANY module is explicitly disabled.
    function isModuleEnabled(name) {
        // Bar uses the dedicated property above
        if (name === "bar") return barEnabledByDefault
        var modules = _raw.modules ?? {}
        return modules[name]?.enabled ?? true
    }

    // ── Convenience ───────────────────────────────────────────────
    readonly property bool isBarAtTop:    barPosition === "top"
    readonly property bool isBarAtBottom: barPosition === "bottom"

    Component.onCompleted: {
        console.log("[Config] loaded — height:", barHeight, "position:", barPosition)
        console.log("[Config] path:", configPath)
    }
}
