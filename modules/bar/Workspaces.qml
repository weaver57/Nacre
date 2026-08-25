import QtQuick
import "../../services" as Services

/**
 * Workspaces — workspace indicator for the bar.
 *
 * Per-monitor: each ContentWindow renders its own Workspaces.
 * This widget filters to show only the workspaces assigned to
 * this bar's monitor, identified via HyprlandService.monitorFor(screen).
 *
 * The active pill reflects THIS monitor's focused workspace,
 * not the global focus — critical for multi-monitor correctness.
 */
Row {
    id: root

    required property var screen

    spacing: 4
    anchors.verticalCenter: parent.verticalCenter

    // ── Per-monitor filtering ────────────────────────────────────
    // Get the HyprlandMonitor for this bar's screen.
    // HyprlandService.monitors is an ObjectModel — we search by name.
    readonly property var _myMonitor: {
        if (!Services.HyprlandService.available) return null
        var screenName = root.screen.name
        for (var i = 0; i < Services.HyprlandService.monitors.count; i++) {
            var m = Services.HyprlandService.monitors.get(i)
            if (m.name === screenName) return m
        }
        return null
    }

    // This monitor's currently active workspace (for highlighting the right pill)
    // Falls back to global focusedWorkspace if per-monitor lookup fails.
    readonly property var _activeWorkspace:
        _myMonitor && _myMonitor.activeWorkspace ? _myMonitor.activeWorkspace
        : Services.HyprlandService.focusedWorkspace

    Component.onCompleted: {
        var screenName = root.screen.name
        var found = _myMonitor !== null
        console.log("[Workspaces] screen:", screenName, "monitor found:", found)
        if (found) console.log("[Workspaces] monitor:", _myMonitor.name, "active:", _activeWorkspace ? _activeWorkspace.id : "none")
    }

    // ── Workspace pills ──────────────────────────────────────────
    // Filter: only show workspaces whose monitor matches this bar's monitor.
    // HyprlandWorkspace has a `monitor` property (HyprlandMonitor).
    Repeater {
        id: repeater
        model: Services.HyprlandService.workspaces

        Rectangle {
            id: pill

            required property var modelData
            readonly property int wsId: modelData.id
            readonly property string wsName: modelData.name ?? wsId

            // Is this workspace on this bar's monitor?
            // Fallback: if monitor lookup fails, show all workspaces
            readonly property bool belongsToThisMonitor:
                root._myMonitor === null
                || (modelData.monitor !== null && modelData.monitor.name === root._myMonitor.name)

            // Is this the active workspace on THIS monitor?
            readonly property bool isActive:
                root._activeWorkspace !== null
                && root._activeWorkspace.id === wsId

            // Hide workspaces that belong to other monitors
            visible: belongsToThisMonitor

            width: Math.max(28, wsLabel.implicitWidth + 16)
            height: 22
            radius: 4

            color: isActive ? "#7c3aed" : "#3d3d5c"
            border.color: isActive ? "#a78bfa" : "transparent"
            border.width: isActive ? 1 : 0

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Text {
                id: wsLabel
                anchors.centerIn: parent
                text: pill.wsName
                color: pill.isActive ? "#ffffff" : "#a0a0b0"
                font.family: "monospace"
                font.pixelSize: 11
                font.bold: pill.isActive
            }

            // Window count indicator
            Rectangle {
                visible: pill.modelData.toplevels && pill.modelData.toplevels.count > 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 2
                width: 4
                height: 4
                radius: 2
                color: pill.isActive ? "#a78bfa" : "#555577"
            }

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
