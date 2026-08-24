import QtQuick

/**
 * BarWrapper — the bar module's entry point.
 *
 * Layer 1 of the three-layer pattern:
 *   Wrapper (this) → Loader → Content (BarContent)
 *
 * ContentWindow already gates visibility via GlobalStates.barOpen,
 * so the Loader here is for module-level content, not window visibility.
 */
Item {
    id: wrapper

    anchors.fill: parent

    // ── Load the real bar content ──────────────────────────────
    BarContent {
        anchors.fill: parent
    }
}
