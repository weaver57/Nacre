import QtQuick
import "../../services" as Services

/**
 * Workspaces — workspace indicator for the bar.
 *
 * PROVES THE SERVICE LOOP:
 *   1. Compositor event (workspace changed) → Hyprland's event socket fires
 *   2. Hyprland's properties update → HyprlandService aliases update
 *   3. Repeater model updates → pill visual states re-render
 *   4. User clicks a pill → HyprlandService.switchWorkspace(id)
 *   5. Hyprland.dispatch("workspace N") → compositor switches
 *   6. Back to step 1
 *
 * If this full loop works, the architecture is validated end-to-end.
 *
 * Per-monitor note:
 *   Each ContentWindow renders its own Workspaces. For now, all monitors
 *   show the same global workspace list. Per-monitor filtering (showing
 *   only that monitor's workspaces) comes when we wire monitor-awareness
 *   into the bar layout.
 */
Row {
    id: root

    spacing: 4
    anchors.verticalCenter: parent.verticalCenter

    // ── Workspace pills ──────────────────────────────────────────
    // One element per workspace. Model is HyprlandService.workspaces
    // (an ObjectModel<HyprlandWorkspace> from Quickshell.Hyprland).
    //
    // Each workspace has: id, name, focused, active, monitor, toplevels
    // We bind the visual "active" state to focusedWorkspace.id from the service.
    Repeater {
        id: repeater
        model: Services.HyprlandService.workspaces

        Rectangle {
            id: pill

            required property var modelData   // HyprlandWorkspace
            readonly property int wsId: modelData.id
            readonly property string wsName: modelData.name ?? wsId
            readonly property bool isFocused:
                Services.HyprlandService.focusedWorkspace !== null
                && Services.HyprlandService.focusedWorkspace.id === wsId

            width: Math.max(28, wsLabel.implicitWidth + 16)
            height: 22
            radius: 4

            // ── Visual state ────────────────────────────────────
            // Focused workspace: bright accent. Others: subtle.
            color: isFocused ? "#7c3aed" : "#3d3d5c"
            border.color: isFocused ? "#a78bfa" : "transparent"
            border.width: isFocused ? 1 : 0

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            // ── Workspace label ─────────────────────────────────
            Text {
                id: wsLabel
                anchors.centerIn: parent
                text: pill.wsName
                color: pill.isFocused ? "#ffffff" : "#a0a0b0"
                font.family: "monospace"
                font.pixelSize: 11
                font.bold: pill.isFocused
            }

            // ── Window count indicator ──────────────────────────
            // Small dot below the pill if workspace has windows.
            Rectangle {
                visible: pill.modelData.toplevels && pill.modelData.toplevels.count > 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 2
                width: 4
                height: 4
                radius: 2
                color: pill.isFocused ? "#a78bfa" : "#555577"
            }

            // ── Click to switch ─────────────────────────────────
            // THIS IS THE CRITICAL PROOF POINT:
            //   user click → service function → Hyprland.dispatch()
            //   → compositor switches → event fires → service updates
            //   → Repeater re-renders → isFocused flips → pill highlights
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Workspaces] switching to workspace", pill.wsId)
                    Services.HyprlandService.switchWorkspace(pill.wsId)
                }
            }
        }
    }
}
