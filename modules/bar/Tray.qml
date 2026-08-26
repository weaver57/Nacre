import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "../../services" as Services

/**
 * Tray — system tray icons for the bar (Phase 2 spec §2.6.5).
 *
 * A Repeater bound to TrayService.items; each item renders its icon at
 * a fixed size. Click → TrayService.activate(item).
 *
 * NO LOCAL STATE (same rule as Workspaces in Phase 1): this widget
 * reflects the service, it owns nothing. Items appear/disappear as
 * their owning processes come and go — the binding handles it.
 *
 * KNOWN INTENTIONAL GAP (spec 2.1.2 / 2.6.4): LEFT-CLICK ONLY.
 * Right-click / context menus are NOT rendered in Phase 2 — the
 * DBusMenu popup surface is explicitly deferred. Items with
 * `onlyMenu === true` will still attempt activate() on click, which
 * most StatusNotifierItem hosts treat as opening their menu window.
 *
 * Colors are hardcoded (Phase 2 acceptable debt, themed in Phase 4).
 */
Item {
    id: root

    visible: Services.TrayService.available

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: Services.TrayService.items

            delegate: Item {
                id: trayItem

                required property var modelData

                // Forced uniform size from Config (spec 2.8): external
                // apps ship inconsistent native icon sizes.
                readonly property int _iconSize: Config.Config.trayIconSize

                readonly property string _label:
                    modelData.tooltipTitle || modelData.title || modelData.id

                width: _iconSize
                height: _iconSize

                // Tray icon — item.icon is a ready-to-use image:// URL
                // on this Quickshell build.
                Image {
                    id: icon
                    anchors.centerIn: parent
                    source: modelData.icon ?? ""
                    sourceSize.width: trayItem._iconSize
                    sourceSize.height: trayItem._iconSize
                    width: trayItem._iconSize
                    height: trayItem._iconSize
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    // Icon themes vary; don't render a broken-image box
                    // for items whose icon name isn't installed.
                    visible: status !== Image.Error && modelData.icon
                }

                // Fallback glyph when the icon can't load — the item
                // must never silently vanish from the bar.
                Text {
                    anchors.centerIn: parent
                    visible: !icon.visible
                    text: "▪"
                    color: "#cdd6f4"
                    font.pixelSize: 13
                }

                // Left-click → primary action. RIGHT-CLICK IS OUT OF
                // SCOPE FOR PHASE 2 (see file docblock) — no context
                // menu surface exists here by explicit decision.
                MouseArea {
                    id: clickArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (event) => {
                        if (event.button === Qt.LeftButton)
                            Services.TrayService.activate(trayItem.modelData)
                    }
                }

                // Hover tooltip from the item's own tooltip data —
                // read-only presentation of service data, not state.
                ToolTip.visible: clickArea.containsMouse && _label !== ""
                ToolTip.delay: 400
                ToolTip.text: trayItem._label +
                    (modelData.tooltipDescription
                     ? "\n" + modelData.tooltipDescription : "")
            }
        }
    }
}
