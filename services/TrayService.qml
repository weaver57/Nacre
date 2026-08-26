pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

/**
 * TrayService — pass-through of the system tray item list (Phase 2 §2.6).
 *
 * Wraps Quickshell.Services.SystemTray (StatusNotifierItem protocol).
 * Structurally different from every other Nacre service per spec §2.6.2:
 * the items are externally-owned, dynamically appearing/disappearing
 * processes' icons — the service's job is a thin, cleanly-typed
 * passthrough, NOT ownership of the data.
 *
 * Ground truth from live probe of this Quickshell build:
 * - SystemTray.items is an ObjectModel; access via .values
 * - Items populate ASYNCHRONOUSLY after startup — the binding below
 *   re-evaluates automatically, never poll.
 * - item.icon is a ready-to-use image://icon/<name> URL string.
 *   (Older docs describe icon objects; this build exposes QString.)
 * - Each item carries native activate() / secondaryActivate() methods.
 *
 * Scope limit (spec 2.1.2 / 2.6.4): LEFT-CLICK ACTIVATE ONLY.
 * Secondary-click and context-menu rendering (DBusMenu popups) are
 * explicitly deferred — see CONVENTIONS.md service notes.
 */
QtObject {
    id: root

    // ── Reactive item list ───────────────────────────────────────
    // Re-evaluates on item registration/unregistration. Each entry is
    // a StatusNotifierItem with at minimum: icon (image:// URL string),
    // title/tooltipTitle, tooltipDescription, id, activate().
    readonly property var items: {
        const model = SystemTray.items
        return model && model.values ? model.values : []
    }

    // ── Availability ─────────────────────────────────────────────
    // The SystemTray service itself always exists in a Quickshell shell;
    // "available" here means there is anything to show. An empty tray
    // hides the widget rather than rendering an empty gap.
    readonly property bool available: items.length > 0

    /**
     * Activate a tray item — left-click behavior (primary action,
     * usually opens the app's main window). Per spec 2.6.4 this is the
     * ONLY tray action in Phase 2; secondaryActivate/context menus are
     * deferred.
     */
    function activate(item) {
        if (!item) {
            console.warn("[TrayService] activate called with null item")
            return
        }
        if (typeof item.activate !== "function") {
            console.warn("[TrayService] item has no activate method:",
                         item.id ?? "(unknown)")
            return
        }
        console.log("[TrayService] activating:", item.id)
        item.activate()
    }

    // One-shot diagnostic: log when the async item list first populates
    // and whenever its size changes (items register/unregister).
    onItemsChanged: console.log("[TrayService] tray items:", items.length)
}
