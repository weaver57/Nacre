pragma Singleton
import QtQuick
import "../config" as Config

/**
 * GlobalStates — ephemeral runtime UI state.
 *
 * Answers "what is true RIGHT NOW this session?" Not persisted.
 * Resets to defaults on shell restart.
 *
 * Initialization order (enforced in shell.qml):
 *   1. Config loads (user preferences from shell.json)
 *   2. GlobalStates initializes — barOpen seeded from Config in Component.onCompleted
 *   3. Modules check Config.isModuleEnabled(), then bind to GlobalStates
 *
 * IMPORTANT: We cannot read Config at property-definition time because
 * QML lazy-loads singletons — Config may not be instantiated yet when
 * this file is first evaluated. The seeding happens in Component.onCompleted
 * instead, after all singletons are guaranteed ready.
 */
QtObject {
    id: root

    // ── Bar state ─────────────────────────────────────────────────
    // Starts true (safe default). Seeded from Config.bar.enabledByDefault
    // in Component.onCompleted — AFTER Config is guaranteed ready.
    // After seeding, independent — toggling barOpen does NOT change Config.
    property bool barOpen: true

    // ── Drawer/overlay state ──────────────────────────────────────
    property bool launcherOpen: false
    property bool notificationPanelOpen: false
    property bool overviewOpen: false
    property bool sessionMenuOpen: false

    // ── OSD state ─────────────────────────────────────────────────
    property bool osdVolumeOpen: false
    property bool osdBrightnessOpen: false

    // ── Lock screen ───────────────────────────────────────────────
    property bool screenLocked: false

    // ── Convenience ───────────────────────────────────────────────
    // True if any overlay is covering the screen
    readonly property bool anyOverlayOpen:
        launcherOpen || notificationPanelOpen || overviewOpen ||
        sessionMenuOpen || screenLocked

    Component.onCompleted: {
        // Seed from Config NOW — Config is guaranteed ready because
        // shell.qml forces Config._raw evaluation before this loads.
        barOpen = Config.Config.barEnabledByDefault
        console.log("[GlobalStates] initialized — barOpen:", barOpen)
    }
}
