#!/usr/bin/env bash
# Phase 2 test — Core Status Services
#
# Validates BatteryService, AudioService, NetworkService, TrayService
# and their widgets against Phase 2 spec (sections 2.3–2.8) and
# CONVENTIONS.md.
#
# Usage:
#   chmod +x scripts/test-phase2-services.sh
#   ./scripts/test-phase2-services.sh

set -uo pipefail

PASS=0
FAIL=0
TOTAL=0

green() { printf "\033[32m  ✓ %s\033[0m\n" "$1"; }
red()   { printf "\033[31m  ✗ %s\033[0m\n" "$1"; }
info()  { printf "\033[36m  → %s\033[0m\n" "$1"; }
header(){ echo ""; echo "── $1 ──"; }

check() {
    ((TOTAL++))
    if eval "$2" > /dev/null 2>&1; then
        green "$1"
        ((PASS++))
    else
        red "$1"
        ((FAIL++))
    fi
}

echo "╔══════════════════════════════════════════╗"
echo "║  Nacre Phase 2 — Core Status Services   ║"
echo "╚══════════════════════════════════════════╝"

# ══════════════════════════════════════════════════════════════════
# 1. FILES EXIST
# ══════════════════════════════════════════════════════════════════
header "1. File Existence"

check "services/BatteryService.qml exists"  "test -f services/BatteryService.qml"
check "services/AudioService.qml exists"    "test -f services/AudioService.qml"
check "services/NetworkService.qml exists"  "test -f services/NetworkService.qml"
check "services/TrayService.qml exists"     "test -f services/TrayService.qml"
check "modules/bar/Battery.qml exists"      "test -f modules/bar/Battery.qml"
check "modules/bar/Volume.qml exists"       "test -f modules/bar/Volume.qml"
check "modules/bar/Network.qml exists"      "test -f modules/bar/Network.qml"
check "modules/bar/Tray.qml exists"         "test -f modules/bar/Tray.qml"
check "Strategy B script removed"           "test ! -f scripts/nmcli-query.sh"
check "DEPENDENCIES.md exists"              "test -f DEPENDENCIES.md"

# ══════════════════════════════════════════════════════════════════
# 2. QMLDIR REGISTRATION
# ══════════════════════════════════════════════════════════════════
header "2. qmldir Registration"

check "BatteryService singleton"   "grep -q '^singleton BatteryService' services/qmldir"
check "AudioService singleton"     "grep -q '^singleton AudioService' services/qmldir"
check "NetworkService singleton"   "grep -q '^singleton NetworkService' services/qmldir"
check "TrayService singleton"      "grep -q '^singleton TrayService' services/qmldir"
check "Battery widget registered"  "grep -q 'Battery.qml' modules/bar/qmldir"
check "Volume widget registered"   "grep -q 'Volume.qml' modules/bar/qmldir"
check "Network widget registered"  "grep -q 'Network.qml' modules/bar/qmldir"
check "Tray widget registered"     "grep -q 'Tray.qml' modules/bar/qmldir"

# Every singleton file has pragma Singleton (CONVENTIONS rule 1)
for f in services/BatteryService.qml services/AudioService.qml services/NetworkService.qml services/TrayService.qml; do
    if [[ -f "$f" ]]; then
        name=$(basename "$f")
        check "$name has pragma Singleton" "head -1 '$f' | grep -q 'pragma Singleton'"
    fi
done

# ══════════════════════════════════════════════════════════════════
# 3. BATTERYSERVICE — read-only UPower wrapper (spec 2.3)
# ══════════════════════════════════════════════════════════════════
header "3. BatteryService"

if [[ -f "services/BatteryService.qml" ]]; then
    check "Imports UPower"                           "grep -q 'Quickshell.Services.UPower' services/BatteryService.qml"
    check "available property exists"                "grep -q 'property bool available' services/BatteryService.qml"
    check "available is derived from batteries"      "grep -qE 'available:.*_batteries\\.length > 0' services/BatteryService.qml"
    check "Multi-battery aggregation (spec 2.3.4)"  "grep -qE 'weighted \\+= pct \\* weight' services/BatteryService.qml"
    check "Has percentage property"                  "grep -q 'property real percentage' services/BatteryService.qml"
    check "Has charging property"                    "grep -q 'property bool charging' services/BatteryService.qml"
    check "Has state string property"                "grep -q 'property string state' services/BatteryService.qml"
    check "State maps to enum strings"               "grep -q '\"charging\"' services/BatteryService.qml && grep -q '\"discharging\"' services/BatteryService.qml && grep -q '\"full\"' services/BatteryService.qml"
    check "energyFull weighting"                     "grep -q 'energyFull' services/BatteryService.qml"
    check "No callLater retry hack"                  "grep -q 'readonly property bool available' services/BatteryService.qml && ! grep -q 'Qt.callLater' services/BatteryService.qml"
    check "Has timeRemaining property"               "grep -q 'property int timeRemaining' services/BatteryService.qml"
    check "Has iconName property"                    "grep -q 'property string iconName' services/BatteryService.qml"
    check "Read-only: no setter actions"             "! grep -qE 'function (set|toggle)' services/BatteryService.qml"
    check "No visual elements"                       "! grep -qE 'Rectangle \{|Text \{|Item \{' services/BatteryService.qml"
    check "No UI module imports"                     "! grep -qE 'import.*modules|import.*components' services/BatteryService.qml"
else
    info "BatteryService.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 4. BATTERY WIDGET — global, availability collapse (spec 2.3/2.7)
# ══════════════════════════════════════════════════════════════════
header "4. Battery Widget"

if [[ -f "modules/bar/Battery.qml" ]]; then
    check "Imports services/"                    "grep -q 'import.*services' modules/bar/Battery.qml"
    check "Imports config/"                      "grep -q 'import.*config' modules/bar/Battery.qml"
    check "Uses BatteryService"                  "grep -q 'BatteryService' modules/bar/Battery.qml"
    check "Guards on available (collapse)"       "grep -q 'visible: Services.BatteryService.available' modules/bar/Battery.qml"
    check "Reads lowThreshold from Config"       "grep -q 'batteryLowThreshold' modules/bar/Battery.qml"
    check "Is global widget (no screen prop)"    "! grep -q 'required property.*screen\|property var screen' modules/bar/Battery.qml"
    check "In BarContent"                        "grep -q 'Battery {' modules/bar/BarContent.qml"
    check "No click actions (Phase 3 scope)"     "! grep -qE 'MouseArea|onClick' modules/bar/Battery.qml"
else
    info "Battery.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 5. AUDIOSERVICE — Pipewire wrapper with actions (spec 2.4)
# ══════════════════════════════════════════════════════════════════
header "5. AudioService"

if [[ -f "services/AudioService.qml" ]]; then
    check "Imports Pipewire"                      "grep -q 'Quickshell.Services.Pipewire' services/AudioService.qml"
    check "Imports Quickshell.Io"                 "grep -q 'Quickshell.Io' services/AudioService.qml"
    check "Imports Config"                        "grep -q 'config' services/AudioService.qml"
    check "available property exists"             "grep -q 'property bool available' services/AudioService.qml"
    check "volume property (normalized 0-1)"      "grep -q 'property real volume' services/AudioService.qml"
    check "muted property"                        "grep -q 'property bool muted' services/AudioService.qml"
    check "setVolume function"                    "grep -q 'function setVolume' services/AudioService.qml"
    check "setVolume clamps input"                "grep -q 'Math.max' services/AudioService.qml && grep -q 'Math.min' services/AudioService.qml"
    check "toggleMute function"                   "grep -q 'function toggleMute' services/AudioService.qml"
    check "adjustVolume function"                 "grep -q 'function adjustVolume' services/AudioService.qml"
    check "scrollStep on service (Config-tunable)" "grep -q 'property real scrollStep' services/AudioService.qml"
    check "scrollStep binds to Config"            "grep -q 'Config.Config.audioScrollStep' services/AudioService.qml"
    check "Writes via wpctl"                      "grep -q 'wpctl' services/AudioService.qml"
    check "volume/muted pure bindings (no assign)" "! grep -qE '^\s*(volume|muted)\s*=' services/AudioService.qml"
    check "No _syncFromPipewire machinery"        "! grep -qE '(function _syncFromPipewire|onVolumeChanged:.*_sync)' services/AudioService.qml"
    check "_pendingCommand queue mechanism"        "grep -q '_pendingCommand' services/AudioService.qml"
    check "Sink-switching deferred"               "! grep -qE 'property var sinks' services/AudioService.qml"
    check "No visual elements"                    "! grep -qE 'Rectangle \{|Text \{|Item \{' services/AudioService.qml"
    check "No UI module imports"                  "! grep -qE 'import.*modules|import.*components' services/AudioService.qml"
else
    info "AudioService.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 6. VOLUME WIDGET — global, scrollable (spec 2.4.4)
# ══════════════════════════════════════════════════════════════════
header "6. Volume Widget"

if [[ -f "modules/bar/Volume.qml" ]]; then
    check "Imports services/"                    "grep -q 'import.*services' modules/bar/Volume.qml"
    check "Uses AudioService"                    "grep -q 'AudioService' modules/bar/Volume.qml"
    check "Guards on available (collapse)"       "grep -q 'visible: Services.AudioService.available' modules/bar/Volume.qml"
    check "Has WheelHandler for scroll"          "grep -q 'WheelHandler' modules/bar/Volume.qml"
    check "Normalizes wheel delta by 120"        "grep -q 'angleDelta.y / 120' modules/bar/Volume.qml"
    check "Calls adjustVolume on scroll"         "grep -q 'adjustVolume' modules/bar/Volume.qml"
    check "Uses service scrollStep"              "grep -q 'scrollStep' modules/bar/Volume.qml"
    check "Has click-to-mute MouseArea"          "grep -q 'MouseArea' modules/bar/Volume.qml"
    check "Calls toggleMute on click"            "grep -q 'toggleMute' modules/bar/Volume.qml"
    check "Is global widget (no screen prop)"    "! grep -q 'required property.*screen\|property var screen' modules/bar/Volume.qml"
    check "In BarContent"                        "grep -q 'Volume {' modules/bar/BarContent.qml"
    check "No click actions on Battery (dead code)" "! grep -qE 'MouseArea|onClick' modules/bar/Battery.qml"
else
    info "Volume.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 7. NETWORKSERVICE — direct NM binding (spec 2.5, Strategy A)
# ══════════════════════════════════════════════════════════════════
header "7. NetworkService"

if [[ -f "services/NetworkService.qml" ]]; then
    check "Imports Quickshell.Networking"        "grep -q 'import Quickshell.Networking' services/NetworkService.qml"
    check "available property exists"            "grep -q 'property bool available' services/NetworkService.qml"
    check "Has connectionType property"          "grep -q 'property string connectionType' services/NetworkService.qml"
    check "Has ssid property"                    "grep -q 'property string ssid' services/NetworkService.qml"
    check "signalStrength normalized 0-100"      "grep -q 'Math.max(0' services/NetworkService.qml && grep -q 'Math.min(100' services/NetworkService.qml"
    check "Scales binding's 0-1 signal to 0-100" "grep -q '\\\\* 100' services/NetworkService.qml"
    check "Binds Networking.devices (event-driven)" "grep -q 'Networking.devices' services/NetworkService.qml"
    check "Wifi detected by capability, not enum" "grep -q 'networks !== undefined' services/NetworkService.qml"
    check "No subprocess spawning"               "! grep -q 'Process {' services/NetworkService.qml"
    check "No polling timer"                     "! grep -q 'Timer {' services/NetworkService.qml"
    check "No callLater scheduling hack"         "! grep -q '_scheduleNextPoll' services/NetworkService.qml"
    check "No nmcli anywhere"                    "! grep -q 'nmcli' services/NetworkService.qml"
    check "No hardcoded absolute paths"          "! grep -qE '/home/[a-zA-Z]' services/NetworkService.qml"
    check "Read-only: no network actions"        "! grep -qE 'function (connect|switchTo|disconnect)' services/NetworkService.qml"
    check "No visual elements"                   "! grep -qE 'Rectangle \{|Text \{|Item \{' services/NetworkService.qml"
    check "No UI module imports"                 "! grep -qE 'import.*modules|import.*components' services/NetworkService.qml"
    check "Registered in qmldir"                 "grep -q 'NetworkService' services/qmldir"
else
    info "NetworkService.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 8. NETWORKMANAGER REACHABILITY (Strategy A backing service)
# ══════════════════════════════════════════════════════════════════
header "8. NetworkManager Reachability"

if systemctl is-active NetworkManager > /dev/null 2>&1; then
    check "NetworkManager daemon active" "true"
    NM_STATE=$(busctl --system get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager State 2>/dev/null | grep -oE '[0-9]+' || echo "?")
    info "NM global State = $NM_STATE (70 = connected globally)"
    check "NM responds on system D-Bus"  "test '$NM_STATE' != '?'"
else
    check "NetworkManager daemon active" "false"
    info "NetworkManager inactive — NetworkService will report available: false (expected)"
fi

# ══════════════════════════════════════════════════════════════════
# 9. NETWORK WIDGET — global, read-only (spec 2.5)
# ══════════════════════════════════════════════════════════════════
header "9. Network Widget"

if [[ -f "modules/bar/Network.qml" ]]; then
    check "Imports services/"                    "grep -q 'import.*services' modules/bar/Network.qml"
    check "Uses NetworkService"                  "grep -q 'NetworkService' modules/bar/Network.qml"
    check "Guards on available (collapse)"       "grep -q 'visible: Services.NetworkService.available' modules/bar/Network.qml"
    check "Displays connection type"             "grep -q 'connectionType' modules/bar/Network.qml"
    check "Displays SSID when on wifi"           "grep -q '\.ssid' modules/bar/Network.qml"
    check "Shows signal strength bars for wifi"  "grep -q 'signalStrength' modules/bar/Network.qml"
    check "Read-only: no action calls"           "! grep -qE '(connect|disconnect|switch)[A-Za-z]*\(' modules/bar/Network.qml"
    check "Is global widget (no screen prop)"    "! grep -q 'required property.*screen\|property var screen' modules/bar/Network.qml"
    check "In BarContent"                        "grep -q 'Network {' modules/bar/BarContent.qml"
else
    info "Network.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 10. SYSTEM DEPENDENCIES (see DEPENDENCIES.md)
# ══════════════════════════════════════════════════════════════════
header "10. Dependencies"

check "NetworkManager daemon present"    "systemctl cat NetworkManager > /dev/null 2>&1 || test -d /etc/NetworkManager"
check "wpctl installed (AudioService)"   "command -v wpctl"
check "upower D-Bus service reachable"   "busctl --user get-property org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower DaemonVersion > /dev/null 2>&1 || upower -e > /dev/null 2>&1"
info "nmcli CLI is NOT a Nacre dependency (Strategy A dropped it)"

# ══════════════════════════════════════════════════════════════════
# 11. RUNTIME SMOKE CHECK (requires running shell)
# ══════════════════════════════════════════════════════════════════
header "11. Runtime Smoke Check"

SHELL_PID=$(pgrep -x quickshell 2>/dev/null || true)
if [[ -n "$SHELL_PID" ]]; then
    check "quickshell running (PID: $SHELL_PID)" "true"
    STATUS_OUTPUT=$(qs ipc --pid "$SHELL_PID" call nacre shellStatus 2>/dev/null || true)
    check "IPC responds while Phase 2 services loaded" \
        "echo '$STATUS_OUTPUT' | python3 -m json.tool > /dev/null 2>&1"    # Volume IPC methods (spec 2.9.1)
    VOL_BEFORE=$(wpctl get-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "0.5")
    qs ipc --pid "$SHELL_PID" call nacre volumeIncrease 2>/dev/null
    sleep 0.5
    VOL_AFTER=$(wpctl get-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "$VOL_BEFORE")
    check "IPC volumeIncrease (spec 2.9.1)" "echo \"$VOL_AFTER > $VOL_BEFORE\" | bc -l 2>/dev/null | grep -q 1"
    qs ipc --pid "$SHELL_PID" call nacre volumeDecrease 2>/dev/null
    sleep 0.3
    check "IPC volumeDecrease callable" "true"
    qs ipc --pid "$SHELL_PID" call nacre volumeToggleMute 2>/dev/null
    sleep 0.3
    qs ipc --pid "$SHELL_PID" call nacre volumeToggleMute 2>/dev/null
    check "IPC volumeToggleMute callable" "true"
else
    info "quickshell not running — skipping runtime checks (launch: quickshell -p .)"
fi

# ══════════════════════════════════════════════════════════════════
# 12. TRAY SERVICE (spec 2.6)
# ══════════════════════════════════════════════════════════════════
header "12. Tray Service"

if [[ -f "services/TrayService.qml" ]]; then
    check "Imports SystemTray binding"           "grep -q 'Quickshell.Services.SystemTray' services/TrayService.qml"
    check "Exposes items passthrough (spec 2.6.3)" "grep -qE 'property var items' services/TrayService.qml"
    check "activate(item) action (spec 2.6.4)"   "grep -q 'function activate(item)' services/TrayService.qml"
    check "No secondaryActivate scope creep"     "! grep -q 'root\.secondaryActivate\|item\.secondaryActivate\|\.secondaryActivate(' services/TrayService.qml"
    check "onItemsChanged diagnostic log"        "grep -q 'onItemsChanged' services/TrayService.qml"
    check "No visual elements"                   "! grep -qE 'Rectangle \{|Text \{|Item \{' services/TrayService.qml"
else
    info "TrayService.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 13. TRAY WIDGET (spec 2.6.5)
# ══════════════════════════════════════════════════════════════════
header "13. Tray Widget"

if [[ -f "modules/bar/Tray.qml" ]]; then
    check "Registered in modules/bar/qmldir"     "grep -q 'Tray 1.0 Tray.qml' modules/bar/qmldir"
    check "Chained into BarContent"              "grep -q 'Tray {' modules/bar/BarContent.qml"
    check "Imports QtQuick.Controls (ToolTip)"   "grep -q 'import QtQuick.Controls' modules/bar/Tray.qml"
    check "Repeater bound to service items"      "grep -q 'Repeater' modules/bar/Tray.qml && grep -q 'model: Services.TrayService.items' modules/bar/Tray.qml"
    check "Click routes through service activate" "grep -q 'Services.TrayService.activate' modules/bar/Tray.qml"
    check "Config-driven icon size (spec 2.8)"   "grep -q '_iconSize' modules/bar/Tray.qml && grep -q 'Config.trayIconSize' modules/bar/Tray.qml"
    check "Left-click-only documented"           "grep -qiE 'left-click only|out of scope for phase 2' modules/bar/Tray.qml"
    check "Limitation noted in CONVENTIONS.md"   "grep -q 'Left-click activate only' CONVENTIONS.md"
    check "No local state on delegates"          "! grep -q 'required property var modelData' modules/bar/Tray.qml || grep -q 'readonly property' modules/bar/Tray.qml"
else
    info "Tray.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 14. CONFIG ADDITIONS (spec 2.8)
# ══════════════════════════════════════════════════════════════════
header "14. Config Preferences"

check "batteryLowThreshold property"     "grep -q 'batteryLowThreshold' config/Config.qml"
check "audioScrollStep property"         "grep -q 'audioScrollStep' config/Config.qml"
check "trayIconSize property"            "grep -q 'trayIconSize' config/Config.qml"
check "Defaults in shell.default.json"   "grep -q 'lowThreshold' shell.default.json && grep -q 'scrollStep' shell.default.json && grep -q 'iconSize' shell.default.json"
check "shell.default.json valid JSON"    "python3 -m json.tool shell.default.json > /dev/null"
check "AudioService reads Config"        "grep -qE 'Config\.Config\.audioScrollStep' services/AudioService.qml"
check "Tray reads Config iconSize"       "grep -q 'Config.trayIconSize' modules/bar/Tray.qml"
check "No preferences in GlobalStates"   "! grep -qE 'lowThreshold|scrollStep|iconSize' state/GlobalStates.qml"

# ══════════════════════════════════════════════════════════════════
# 15. CONSUMER WIDGETS (spec 2.7)
# ══════════════════════════════════════════════════════════════════
header "15. Consumer Widgets"

# Battery — three visual states + low-threshold warning color
check "Battery low-threshold uses Config"         "grep -q 'batteryLowThreshold' modules/bar/Battery.qml"
check "Battery _isLow derived from threshold"     "grep -q '_isLow' modules/bar/Battery.qml && grep -q 'discharging' modules/bar/Battery.qml"
check "Battery low color differs from standard"   "grep -q '#f38ba8' modules/bar/Battery.qml && grep -q '#cdd6f4' modules/bar/Battery.qml"
check "Battery hides when unavailable"            "grep -q 'visible: Services.BatteryService.available' modules/bar/Battery.qml"

# Network — connection type, signal bars, availability collapse
check "Network reflects connectionType"           "grep -q 'connectionType' modules/bar/Network.qml"
check "Network signal bars for wifi"              "grep -q 'signalStrength' modules/bar/Network.qml"
check "Network hides when unavailable"            "grep -q 'visible: Services.NetworkService.available' modules/bar/Network.qml"

# Volume — mute visual, scroll → adjustVolume, click → toggleMute
check "Volume mute icon reflected"                "grep -q 'muted' modules/bar/Volume.qml"
check "Volume scroll calls adjustVolume"          "grep -q 'adjustVolume' modules/bar/Volume.qml"
check "Volume click calls toggleMute"             "grep -q 'toggleMute' modules/bar/Volume.qml"

# Battery/Network/Volume have no click actions (Phase 3 scope)
check "Battery has no MouseArea"                  "! grep -qE 'MouseArea' modules/bar/Battery.qml"
check "Network has no MouseArea"                  "! grep -qE 'MouseArea' modules/bar/Network.qml"

# ══════════════════════════════════════════════════════════════════
# 16. IPC EXPANSION (spec 2.9)
# ══════════════════════════════════════════════════════════════════
header "16. IPC Volume Methods"

check "volumeIncrease exists"        "grep -q 'function volumeIncrease' services/IpcHandler.qml"
check "volumeDecrease exists"        "grep -q 'function volumeDecrease' services/IpcHandler.qml"
check "volumeToggleMute exists"      "grep -q 'function volumeToggleMute' services/IpcHandler.qml"
check "volumeIncrease calls adjustVolume" "grep -A3 'function volumeIncrease' services/IpcHandler.qml | grep -q 'adjustVolume'"
check "volumeDecrease calls adjustVolume" "grep -A3 'function volumeDecrease' services/IpcHandler.qml | grep -q 'adjustVolume'"
check "volumeToggleMute calls toggleMute" "grep -A3 'function volumeToggleMute' services/IpcHandler.qml | grep -q 'toggleMute'"
check "Uses AudioService.scrollStep for delta" "grep -q 'scrollStep' services/IpcHandler.qml"
check "No battery/network/tray IPC — read-only per spec 2.9.3" "! grep -q 'function batteryIncrease\|function networkConnect\|function trayActivate' services/IpcHandler.qml"
check "Keybind docs in DEPENDENCIES.md" "grep -q 'volumeIncrease' DEPENDENCIES.md && grep -q 'volumeDecrease' DEPENDENCIES.md"
check "IPC methods documented in CONVENTIONS.md" "grep -q 'volumeIncrease' CONVENTIONS.md"

# ══════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════╗"
printf "║  Results: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m  (of %d) ║\n" "$PASS" "$FAIL" "$TOTAL"
echo "╚══════════════════════════════════════════╝"

if [[ $FAIL -eq 0 ]]; then
    echo ""
    echo "All checks pass."
    exit 0
else
    echo ""
    echo "Fix the $FAIL failure(s) above."
    exit 1
fi
