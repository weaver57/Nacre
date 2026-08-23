pragma Singleton
import QtQuick

/**
 * Config — Single source of truth for all shell configuration.
 *
 * Backed by ~/.config/nacre/shell.json. Reloads automatically on save.
 * Every other component reads settings from here — never parse JSON directly.
 *
 * Example shell.json:
 * {
 *   "bar": {
 *     "height": 36,
 *     "position": "bottom",
 *     "visible": true
 *   },
 *   "theme": "ocean"
 * }
 */
QtObject {
    id: root

    // ── Raw access (used internally) ──────────────────────────────
    readonly property var manager: ConfigManager

    // ── Bar ───────────────────────────────────────────────────────
    readonly property int    barHeight:   manager.barHeight
    readonly property string barPosition: manager.barPosition   // "top" | "bottom"
    readonly property bool   barVisible:  manager.barVisible

    // ── Theme ─────────────────────────────────────────────────────
    readonly property string theme: manager.theme

    // ── Convenience ───────────────────────────────────────────────
    readonly property bool isBarAtTop:    barPosition === "top"
    readonly property bool isBarAtBottom: barPosition === "bottom"
}
