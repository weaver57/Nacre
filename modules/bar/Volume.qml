import QtQuick
import "../../services" as Services

/**
 * Volume — global volume indicator and control for the bar.
 *
 * Shows speaker icon + volume percentage.
 * - Scroll up/down: adjust volume by 5% steps (AudioService.scrollStep)
 * - Click: toggle mute
 *
 * This is the first scrollable widget in Nacre. The scroll-to-action
 * pattern (scroll step = 5%) is documented in CONVENTIONS.md for
 * consistency with future scrollable widgets.
 *
 * Colors are hardcoded (Phase 2 acceptable debt, themed in Phase 4).
 */
Item {
    id: root

    visible: Services.AudioService.available

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: volumeRow.implicitHeight

    Row {
        id: volumeRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Speaker icon — changes based on mute/volume level
        Text {
            text: {
                if (Services.AudioService.muted) return "🔇"
                if (Services.AudioService.volume < 0.33) return "🔈"
                if (Services.AudioService.volume < 0.66) return "🔉"
                return "🔊"
            }
            color: "#cdd6f4"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        // Volume percentage
        Text {
            text: Math.round(Services.AudioService.volume * 100) + "%"
            color: "#cdd6f4"
            font.pixelSize: 13
            font.family: "monospace"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Scroll to adjust volume ──────────────────────────────────
    // One scroll step = AudioService.scrollStep (5%).
    // This is the first scrollable widget — the pattern is documented
    // in CONVENTIONS.md for consistency with future scroll widgets.
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                Services.AudioService.adjustVolume(Services.AudioService.scrollStep)
            } else if (event.angleDelta.y < 0) {
                Services.AudioService.adjustVolume(-Services.AudioService.scrollStep)
            }
        }
    }

    // ── Click to toggle mute ─────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: Services.AudioService.toggleMute()
    }

    Component.onCompleted: {
        console.log("[Volume] widget created — available:",
                     Services.AudioService.available)
    }
}
