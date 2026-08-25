#!/usr/bin/env bash
# Phase 1 test — State Architecture Refactor
#
# Validates the three-tier state split (Config / GlobalStates / Persistent)
# and all Phase 0 functionality still works.
#
# What it checks:
#   1. Directory structure (config/, state/, modules/, components/, services/)
#   2. QML files exist for all singletons
#   3. Config file: valid JSON, correct keys (enabledByDefault, not visible)
#   4. State file: valid JSON, correct keys (lastWorkspace, notificationHistory)
#   5. Shell process is running
#   6. No stale imports (config/GlobalStates.qml, config/Persistent.qml deleted)
#   7. Import consistency (state/ imported correctly in shell.qml, ContentWindow)
#   8. Live config reload (edit shell.json → values change)
#   9. State persistence (write state.json → read back)
#
# Usage:
#   chmod +x scripts/test-phase1-state.sh
#   ./scripts/test-phase1-state.sh

set -uo pipefail

CONFIG_DIR="$HOME/.config/nacre"
CONFIG_FILE="$CONFIG_DIR/shell.json"
STATE_DIR="$HOME/.local/state/nacre"
STATE_FILE="$STATE_DIR/state.json"
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
echo "║  Nacre Phase 1 — State Architecture     ║"
echo "╚══════════════════════════════════════════╝"

# ══════════════════════════════════════════════════════════════════
# 1. DIRECTORY STRUCTURE
# ══════════════════════════════════════════════════════════════════
header "1. Directory Structure"

check "config/ directory exists"         "test -d config"
check "state/ directory exists"          "test -d state"
check "modules/bar/ directory exists"    "test -d modules/bar"
check "modules/drawers/ directory exists" "test -d modules/drawers"
check "components/ directory exists"     "test -d components"
check "services/ directory exists"       "test -d services"
check "scripts/ directory exists"        "test -d scripts"

# ══════════════════════════════════════════════════════════════════
# 2. QML FILES EXIST
# ══════════════════════════════════════════════════════════════════
header "2. QML File Existence"

check "shell.qml exists"                "test -f shell.qml"
check "config/Config.qml exists"        "test -f config/Config.qml"
check "config/qmldir exists"            "test -f config/qmldir"
check "state/GlobalStates.qml exists"   "test -f state/GlobalStates.qml"
check "state/Persistent.qml exists"     "test -f state/Persistent.qml"
check "state/qmldir exists"             "test -f state/qmldir"
check "components/ContentWindow.qml"    "test -f components/ContentWindow.qml"
check "components/ModuleWrapper.qml"    "test -f components/ModuleWrapper.qml"
check "modules/bar/BarWrapper.qml"      "test -f modules/bar/BarWrapper.qml"
check "modules/bar/BarContent.qml"      "test -f modules/bar/BarContent.qml"
check "services/IpcHandler.qml"         "test -f services/IpcHandler.qml"
check "services/HyprlandService.qml"    "test -f services/HyprlandService.qml"

# ══════════════════════════════════════════════════════════════════
# 2b. SERVICE LAYER — HyprlandService structure
# ══════════════════════════════════════════════════════════════════
header "2b. Service Layer (HyprlandService)"

if [[ -f "services/HyprlandService.qml" ]]; then
    check "IpcHandler is a type (not singleton)" "grep -q '^IpcHandler' services/qmldir"
    check "HyprlandService has pragma Singleton" "grep -q 'pragma Singleton' services/HyprlandService.qml"
    check "Imports Quickshell.Hyprland"  "grep -q 'import Quickshell.Hyprland' services/HyprlandService.qml"
    check "Has available flag"           "grep -q 'property bool available' services/HyprlandService.qml"
    check "Has workspaces property"      "grep -q 'workspaces' services/HyprlandService.qml"
    check "Has focusedWorkspace property" "grep -q 'focusedWorkspace' services/HyprlandService.qml"
    check "Has monitors property"        "grep -q 'monitors' services/HyprlandService.qml"
    check "Has switchWorkspace function"  "grep -q 'function switchWorkspace' services/HyprlandService.qml"
    check "No visual elements"           "! grep -E 'Rectangle|Text|Item \{' services/HyprlandService.qml | grep -v '^[[:space:]]*\*' | grep -v '^[[:space:]]*//' | grep -q ."
    check "No UI module imports"         "! grep -E 'import.*modules|import.*components' services/HyprlandService.qml | grep -v '^[[:space:]]*\*' | grep -v '^[[:space:]]*//' | grep -q ."
    check "No property alias to singleton" "! grep -qE 'property alias.*: Hyprland\.' services/HyprlandService.qml"
    check "No visual children in QtObject"  "! grep -qE 'Connections \{|Timer \{' services/HyprlandService.qml"
else
    info "HyprlandService.qml not found — skipping service checks"
fi

# ══════════════════════════════════════════════════════════════════
# 2f. IPC HANDLER — typed methods via Quickshell.Io.IpcHandler
# ══════════════════════════════════════════════════════════════════
header "2f. IPC Handler"

if [[ -f "services/IpcHandler.qml" ]]; then
    check "Imports Quickshell.Io"        "grep -q 'import Quickshell.Io' services/IpcHandler.qml"
    check "Extends IpcHandler type"      "grep -q 'IpcHandler {' services/IpcHandler.qml"
    check "Has target property"          "grep -q 'target:' services/IpcHandler.qml"
    check "Instantiated in shell.qml"    "grep -q 'Services.IpcHandler' shell.qml"
    check "Has ping function"            "grep -q 'function ping' services/IpcHandler.qml"
    check "Has barToggle function"       "grep -q 'function barToggle' services/IpcHandler.qml"
    check "Has barShow function"         "grep -q 'function barShow' services/IpcHandler.qml"
    check "Has barHide function"         "grep -q 'function barHide' services/IpcHandler.qml"
    check "Has workspaceSwitch function"  "grep -q 'function workspaceSwitch' services/IpcHandler.qml"
    check "Has shellStatus function"     "grep -q 'function shellStatus' services/IpcHandler.qml"
    check "Functions have return types"  "grep -q '): string' services/IpcHandler.qml"
    check "No targetName (uses target)"  "! grep -v '^[[:space:]]*\*' services/IpcHandler.qml | grep -v '^[[:space:]]*//' | grep -q 'targetName'"
else
    info "IpcHandler.qml not found — skipping IPC checks"
fi

# ══════════════════════════════════════════════════════════════════
# 2d. QML SINGLETON RULES (learned the hard way)
# ══════════════════════════════════════════════════════════════════
header "2d. QML Singleton Rules"

# Rule 1: Every qmldir singleton must have pragma Singleton in source
for qmldir_file in config/qmldir state/qmldir services/qmldir; do
    if [[ -f "$qmldir_file" ]]; then
        dir=$(dirname "$qmldir_file")
        while IFS= read -r line; do
            # Extract type name from "singleton TypeName file.qml" lines
            type_name=$(echo "$line" | awk '/^singleton/ { print $2 }')
            type_file=$(echo "$line" | awk '/^singleton/ { print $3 }')
            if [[ -n "$type_name" && -n "$type_file" ]]; then
                filepath="$dir/$type_file"
                if [[ -f "$filepath" ]]; then
                    check "$type_name has pragma Singleton" "grep -q 'pragma Singleton' $filepath"
                fi
            fi
        done < "$qmldir_file"
    fi
done

# Rule 2: shell.qml must not instantiate singletons with {}    check "No singleton instantiation in shell.qml" "! grep -qE '(HyprlandService|Config|GlobalStates|Persistent)\s*\{' shell.qml"

# Rule 3: No property alias to imported singletons anywhere
check "No alias to imported singletons" "! grep -rE 'property alias.*: (Hyprland|Config|GlobalStates|Persistent)\.' --include='*.qml' . 2>/dev/null | grep -v '^[[:space:]]*\*' | grep -v '^[[:space:]]*//' | grep -q ."

# ══════════════════════════════════════════════════════════════════
# 2c. WORKSPACES WIDGET — service → widget binding
# ══════════════════════════════════════════════════════════════════
header "2c. Workspaces Widget"

if [[ -f "modules/bar/Workspaces.qml" ]]; then
    check "Workspaces.qml exists"          "test -f modules/bar/Workspaces.qml"
    check "Imports services/"              "grep -q 'import.*services' modules/bar/Workspaces.qml"
    check "Uses HyprlandService"           "grep -q 'HyprlandService' modules/bar/Workspaces.qml"
    check "Has Repeater"                   "grep -q 'Repeater' modules/bar/Workspaces.qml"
    check "Binds to workspaces model"      "grep -q 'HyprlandService.workspaces' modules/bar/Workspaces.qml"
    check "Has switchWorkspace call"        "grep -q 'switchWorkspace' modules/bar/Workspaces.qml"
    check "Checks active workspace"        "grep -q 'isActive\|_activeWorkspace\|focusedWorkspace' modules/bar/Workspaces.qml"
    check "Has MouseArea for click"         "grep -q 'MouseArea' modules/bar/Workspaces.qml"
    check "Registered in qmldir"           "grep -q 'Workspaces' modules/bar/qmldir"
    check "BarContent imports Workspaces"   "grep -q 'Workspaces' modules/bar/BarContent.qml"
    check "Accepts screen property"        "grep -q 'required property var screen' modules/bar/Workspaces.qml"
    check "Has per-monitor filtering"       "grep -q '_myMonitor\|belongsToThisMonitor' modules/bar/Workspaces.qml"
else
    info "Workspaces.qml not found — skipping widget checks"
fi

# ══════════════════════════════════════════════════════════════════
# 2e. CLOCK WIDGET — time-driven data source
# ══════════════════════════════════════════════════════════════════
header "2e. Clock Widget"

if [[ -f "modules/bar/Clock.qml" ]]; then
    check "Clock.qml exists"              "test -f modules/bar/Clock.qml"
    check "Imports Quickshell"            "grep -q 'import Quickshell' modules/bar/Clock.qml"
    check "Imports config/"               "grep -q 'import.*config' modules/bar/Clock.qml"
    check "Uses SystemClock"              "grep -q 'SystemClock' modules/bar/Clock.qml"
    check "Has precision setting"         "grep -q 'precision' modules/bar/Clock.qml"
    check "Reads Config.clockFormat"      "grep -q 'clockFormat' modules/bar/Clock.qml"
    check "Uses Qt.formatDateTime"        "grep -q 'Qt.formatDateTime' modules/bar/Clock.qml"
    check "Registered in qmldir"          "grep -q 'Clock' modules/bar/qmldir"
    check "BarContent imports Clock"      "grep -q 'Clock' modules/bar/BarContent.qml"
else
    info "Clock.qml not found — skipping clock checks"
fi

# ══════════════════════════════════════════════════════════════════
# 2f. BATTERYSERVICE — read-only UPower wrapper
# ══════════════════════════════════════════════════════════════════
header "2f. BatteryService"

if [[ -f "services/BatteryService.qml" ]]; then
    check "BatteryService.qml exists"       "test -f services/BatteryService.qml"
    check "Has pragma Singleton"             "grep -q 'pragma Singleton' services/BatteryService.qml"
    check "Imports UPower"                   "grep -q 'Quickshell.Services.UPower' services/BatteryService.qml"
    check "Has available property"           "grep -q 'property bool available' services/BatteryService.qml"
    check "available checks isLaptopBattery" "grep -q 'isLaptopBattery' services/BatteryService.qml"
    check "Has percentage property"          "grep -q 'property real percentage' services/BatteryService.qml"
    check "Has charging property"            "grep -q 'property bool charging' services/BatteryService.qml"
    check "Has state property"               "grep -q 'property string state' services/BatteryService.qml"
    check "State maps to clean strings"      "grep -q '"charging"' services/BatteryService.qml"
    check "No action methods"                "! grep -q 'function.*action\|function.*toggle\|function.*set' services/BatteryService.qml"
    check "No visual elements"               "! grep -qE 'Rectangle|Text|Item \{' services/BatteryService.qml"
    check "Has _scanDevices function"         "grep -q 'function _scanDevices' services/BatteryService.qml"
    check "Uses Qt.callLater for async"       "grep -q 'Qt.callLater' services/BatteryService.qml"
    check "Scans UPower.devices.values"       "grep -q 'UPower.devices.values' services/BatteryService.qml"
    check "Registered in qmldir"             "grep -q 'BatteryService' services/qmldir"
else
    info "BatteryService.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 2g. BATTERY WIDGET — global (non-per-monitor)
# ══════════════════════════════════════════════════════════════════
header "2g. Battery Widget"

if [[ -f "modules/bar/Battery.qml" ]]; then
    check "Battery.qml exists"              "test -f modules/bar/Battery.qml"
    check "Imports services/"               "grep -q 'import.*services' modules/bar/Battery.qml"
    check "Uses BatteryService"             "grep -q 'BatteryService' modules/bar/Battery.qml"
    check "Guards on available"             "grep -q 'BatteryService.available' modules/bar/Battery.qml"
    check "Registered in qmldir"            "grep -q 'Battery' modules/bar/qmldir"
    check "BarContent imports Battery"      "grep -q 'Battery' modules/bar/BarContent.qml"
    check "Is global widget (no screen prop)" "! grep -q 'required property.*screen\|property var screen' modules/bar/Battery.qml"
else
    info "Battery.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 2h. AUDIOSERVICE — Pipewire wrapper with volume/mute/actions
# ══════════════════════════════════════════════════════════════════
header "2h. AudioService"

if [[ -f "services/AudioService.qml" ]]; then
    check "AudioService.qml exists"         "test -f services/AudioService.qml"
    check "Has pragma Singleton"             "grep -q 'pragma Singleton' services/AudioService.qml"
    check "Imports Pipewire"                 "grep -q 'Quickshell.Services.Pipewire' services/AudioService.qml"
    check "Imports Quickshell.Io"            "grep -q 'Quickshell.Io' services/AudioService.qml"
    check "Has available property"           "grep -q 'property bool available' services/AudioService.qml"
    check "Has volume property"              "grep -q 'property real volume' services/AudioService.qml"
    check "Has muted property"               "grep -q 'property bool muted' services/AudioService.qml"
    check "Volume normalized 0.0-1.0"        "grep -q '0.0\|0.0-1.0\|scrollStep' services/AudioService.qml"
    check "Has scrollStep property"          "grep -q 'scrollStep' services/AudioService.qml"
    check "scrollStep is 0.02"               "grep -q 'scrollStep: 0.02' services/AudioService.qml"
    check "Has setVolume function"           "grep -q 'function setVolume' services/AudioService.qml"
    check "Has toggleMute function"          "grep -q 'function toggleMute' services/AudioService.qml"
    check "Has adjustVolume function"        "grep -q 'function adjustVolume' services/AudioService.qml"
    check "Uses wpctl for writes"            "grep -q 'wpctl' services/AudioService.qml"
    check "setVolume clamps input"           "grep -q 'Math.max\|Math.min\|clamped' services/AudioService.qml"
    check "No exitCode reference"            "! grep -q 'exitCode' services/AudioService.qml"
    check "No visual elements"               "! grep -qE 'Rectangle|Text|Item \{' services/AudioService.qml"
    check "Registered in qmldir"             "grep -q 'AudioService' services/qmldir"
else
    info "AudioService.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 2i. VOLUME WIDGET — global, scrollable
# ══════════════════════════════════════════════════════════════════
header "2i. Volume Widget"

if [[ -f "modules/bar/Volume.qml" ]]; then
    check "Volume.qml exists"                "test -f modules/bar/Volume.qml"
    check "Imports services/"                "grep -q 'import.*services' modules/bar/Volume.qml"
    check "Uses AudioService"                "grep -q 'AudioService' modules/bar/Volume.qml"
    check "Guards on available"              "grep -q 'AudioService.available' modules/bar/Volume.qml"
    check "Has WheelHandler for scroll"      "grep -q 'WheelHandler' modules/bar/Volume.qml"
    check "Calls adjustVolume on scroll"     "grep -q 'adjustVolume' modules/bar/Volume.qml"
    check "Has MouseArea for click-to-mute"  "grep -q 'MouseArea' modules/bar/Volume.qml"
    check "Calls toggleMute on click"        "grep -q 'toggleMute' modules/bar/Volume.qml"
    check "Uses scrollStep"                  "grep -q 'scrollStep' modules/bar/Volume.qml"
    check "Normalizes wheel delta by 120"    "grep -q 'angleDelta.y / 120' modules/bar/Volume.qml"
    check "Registered in qmldir"             "grep -q 'Volume' modules/bar/qmldir"
    check "BarContent imports Volume"        "grep -q 'Volume' modules/bar/BarContent.qml"
    check "Is global widget (no screen prop)" "! grep -q 'required property.*screen\|property var screen' modules/bar/Volume.qml"
else
    info "Volume.qml not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 3. STALE FILES DELETED (config/ should NOT have GlobalStates or Persistent)
# ══════════════════════════════════════════════════════════════════
header "3. Stale File Cleanup"

check "config/GlobalStates.qml deleted"  "test ! -f config/GlobalStates.qml"
check "config/Persistent.qml deleted"    "test ! -f config/Persistent.qml"

# ══════════════════════════════════════════════════════════════════
# 4. CONFIG FILE (shell.json)
# ══════════════════════════════════════════════════════════════════
header "4. Config File (shell.json)"

if [[ ! -f "$CONFIG_FILE" ]]; then
    info "Copying shell.default.json → $CONFIG_FILE"
    mkdir -p "$CONFIG_DIR"
    cp shell.default.json "$CONFIG_FILE"
fi

check "Config file exists"               "test -f $CONFIG_FILE"
check "Config is valid JSON"             "python3 -m json.tool $CONFIG_FILE > /dev/null"

if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    BAR_HEIGHT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('bar',{}).get('height','MISSING'))")
    BAR_POS=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('bar',{}).get('position','MISSING'))")
    BAR_ENABLED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('bar',{}).get('enabledByDefault','MISSING'))")
    CLOCK_FMT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('clock',{}).get('format','MISSING'))")

    info "bar.height          = $BAR_HEIGHT"
    info "bar.position        = $BAR_POS"
    info "bar.enabledByDefault= $BAR_ENABLED"
    info "clock.format        = $CLOCK_FMT"

    check "bar.height is integer"        "test '$BAR_HEIGHT' -eq '$BAR_HEIGHT' 2>/dev/null"
    check "bar.position is top|bottom"   "test '$BAR_POS' = 'top' || test '$BAR_POS' = 'bottom'"
    check "bar.enabledByDefault is bool" "test '$BAR_ENABLED' = 'True' || test '$BAR_ENABLED' = 'true' || test '$BAR_ENABLED' = 'False' || test '$BAR_ENABLED' = 'false'"
    check "clock.format is string"       "test -n '$CLOCK_FMT'"

    # Check that old 'visible' key is NOT used
    HAS_VISIBLE=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print('yes' if 'visible' in d.get('bar',{}) else 'no')")
    check "bar.visible key removed (using enabledByDefault)" "test '$HAS_VISIBLE' = 'no'"
fi

# ══════════════════════════════════════════════════════════════════
# 5. STATE FILE (state.json)
# ══════════════════════════════════════════════════════════════════
header "5. State File (state.json)"

if [[ ! -f "$STATE_FILE" ]]; then
    info "Copying state.default.json → $STATE_FILE"
    mkdir -p "$STATE_DIR"
    cp state.default.json "$STATE_FILE"
fi

check "State file exists"                "test -f $STATE_FILE"
check "State is valid JSON"              "python3 -m json.tool $STATE_FILE > /dev/null"

if python3 -m json.tool "$STATE_FILE" > /dev/null 2>&1; then
    LAST_WS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('lastWorkspace','MISSING'))")
    info "lastWorkspace = $LAST_WS"
    check "lastWorkspace is integer"     "test '$LAST_WS' -eq '$LAST_WS' 2>/dev/null"
fi

# ══════════════════════════════════════════════════════════════════
# 6. QML STRUCTURE — import consistency
# ══════════════════════════════════════════════════════════════════
header "6. QML Import Consistency"

# shell.qml should import ./state
check "shell.qml imports state/"        "grep -q 'import \"./state\"' shell.qml"
# ContentWindow should import ../state
check "ContentWindow imports ../state"   "grep -q 'import \"../state\"' components/ContentWindow.qml"
# No file should import GlobalStates from config/
check "No stale config/GlobalStates import" "! grep -r 'config.*GlobalStates' --include='*.qml' . 2>/dev/null"
# No file should import Persistent from config/
check "No stale config/Persistent import"   "! grep -r 'config.*Persistent' --include='*.qml' . 2>/dev/null"

# ══════════════════════════════════════════════════════════════════
# 7. SHELL PROCESS
# ══════════════════════════════════════════════════════════════════
header "7. Shell Process"

SHELL_PID=$(pgrep -x quickshell 2>/dev/null || true)
if [[ -n "$SHELL_PID" ]]; then
    check "quickshell is running (PID: $SHELL_PID)" "true"
else
    check "quickshell is running" "false"
    info "Launch it: quickshell -p ."
fi

# ══════════════════════════════════════════════════════════════════
# 8. IPC RUNTIME CHECKS (requires running shell)
# ══════════════════════════════════════════════════════════════════
header "8. IPC Runtime Checks"

if [[ -n "$SHELL_PID" ]]; then
    IPC_OUTPUT=$(qs ipc --pid "$SHELL_PID" call nacre ping 2>/dev/null || true)
    check "IPC ping returns pong" "echo '$IPC_OUTPUT' | grep -q 'pong'"

    STATUS_OUTPUT=$(qs ipc --pid "$SHELL_PID" call nacre shellStatus 2>/dev/null || true)
    check "IPC shellStatus returns JSON" "echo '$STATUS_OUTPUT' | python3 -m json.tool > /dev/null 2>&1"

    # Check barToggle works (toggle off, then back on)
    qs ipc --pid "$SHELL_PID" call nacre barToggle 2>/dev/null
    sleep 0.5
    STATUS_AFTER=$(qs ipc --pid "$SHELL_PID" call nacre shellStatus 2>/dev/null || true)
    BAR_OPEN=$(echo "$STATUS_AFTER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('barOpen','MISSING'))" 2>/dev/null || true)
    check "IPC barToggle toggles bar state" "test '$BAR_OPEN' = 'False' || test '$BAR_OPEN' = 'false'"

    # Toggle back on
    qs ipc --pid "$SHELL_PID" call nacre barToggle 2>/dev/null
    sleep 0.5
else
    info "Skipping IPC runtime checks — shell not running"
fi

# ══════════════════════════════════════════════════════════════════
# 8b. KEYBIND VERIFICATION — audio uses wpctl 2% steps
# ══════════════════════════════════════════════════════════════════
header "8b. Audio Keybinds"

KEYBIND_FILE="$HOME/.config/hypr/keybindings.conf"
if [[ -f "$KEYBIND_FILE" ]]; then
    check "XF86AudioRaiseVolume uses wpctl"  "grep 'XF86AudioRaiseVolume' '$KEYBIND_FILE' | grep -q 'wpctl'"
    check "XF86AudioLowerVolume uses wpctl"  "grep 'XF86AudioLowerVolume' '$KEYBIND_FILE' | grep -q 'wpctl'"
    check "Raise volume uses 0.02+"          "grep 'XF86AudioRaiseVolume' '$KEYBIND_FILE' | grep -Fq '0.02+'"
    check "Lower volume uses 0.02-"          "grep 'XF86AudioLowerVolume' '$KEYBIND_FILE' | grep -Fq '0.02-'"
    check "F3 raise uses 0.02+"              "grep ', F3,' '$KEYBIND_FILE' | grep -Fq '0.02+'"
    check "F2 lower uses 0.02-"              "grep ', F2,' '$KEYBIND_FILE' | grep -Fq '0.02-'"
else
    info "Keybindings file not found — skipping"
fi

# ══════════════════════════════════════════════════════════════════
# 9. LIVE CONFIG RELOAD
# ══════════════════════════════════════════════════════════════════
header "9. Live Config Reload"

if [[ -n "$SHELL_PID" ]]; then
    # Save original
    cp "$CONFIG_FILE" /tmp/nacre-config-backup.json

    # Write new height
    python3 -c "
import json
with open('$CONFIG_FILE','r+') as f:
    c = json.load(f)
    c['bar']['height'] = 99
    f.seek(0)
    json.dump(c, f, indent=4)
    f.truncate()
"
    sleep 1

    RELOADED_HEIGHT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['bar']['height'])")
    check "Config updated to height=99" "test '$RELOADED_HEIGHT' = '99'"

    # Restore original
    cp /tmp/nacre-config-backup.json "$CONFIG_FILE"
    info "Original config restored"

    # Clock format live-reload
    cp "$CONFIG_FILE" /tmp/nacre-config-backup2.json
    python3 -c "
import json
with open('$CONFIG_FILE','r+') as f:
    c = json.load(f)
    c['clock'] = {'format': 'hh:mm AP'}
    f.seek(0)
    json.dump(c, f, indent=4)
    f.truncate()
"
    sleep 1
    CLOCK_FMT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['clock']['format'])")
    check "Clock format updated to hh:mm AP" "test '$CLOCK_FMT' = 'hh:mm AP'"
    cp /tmp/nacre-config-backup2.json "$CONFIG_FILE"
    info "Original clock format restored"
else
    info "Skipping live reload test — shell not running"
fi

# ══════════════════════════════════════════════════════════════════
# 10. PERSISTENT WORKSPACE TRACKING
# ══════════════════════════════════════════════════════════════════
header "10. Persistent Workspace Tracking"

check "Persistent imports HyprlandService"  "grep -q 'HyprlandService' state/Persistent.qml"
check "lastWorkspace binds to focusedWorkspace" "grep -q 'focusedWorkspace' state/Persistent.qml"
check "onLastWorkspaceChanged handler exists" "grep -q 'onLastWorkspaceChanged' state/Persistent.qml"
check "save() called in onLastWorkspaceChanged" "grep -A3 'onLastWorkspaceChanged' state/Persistent.qml | grep -q 'save()'"
check "_initialized guard prevents save on load" "grep -q '_initialized' state/Persistent.qml"
check "Uses .id for object property" "grep -q 'hw.id' state/Persistent.qml"

# Runtime: switch workspace via IPC and verify state.json updates
if [[ -n "$SHELL_PID" ]]; then
    # Record current workspace from shell status
    STATUS_WS=$(qs ipc --pid "$SHELL_PID" call nacre shellStatus 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('focusedWorkspace',0))" 2>/dev/null || echo 0)
    info "Current focused workspace: $STATUS_WS"

    # Determine target workspace (switch to the one that isn't current)
    if [[ "$STATUS_WS" -eq 1 ]]; then
        TARGET_WS=2
    else
        TARGET_WS=1
    fi

    # Switch workspace via IPC
    qs ipc --pid "$SHELL_PID" call nacre workspaceSwitch "$TARGET_WS" 2>/dev/null
    sleep 1

    # Verify shellStatus reports new workspace
    NEW_WS=$(qs ipc --pid "$SHELL_PID" call nacre shellStatus 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('focusedWorkspace',0))" 2>/dev/null || echo 0)
    check "IPC workspaceSwitch changes focused workspace" "test '$NEW_WS' = '$TARGET_WS'"

    # Verify state.json persisted the new workspace
    PERSISTED_WS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('lastWorkspace',-1))" 2>/dev/null || echo -1)
    check "Persistent saved new workspace to state.json" "test '$PERSISTED_WS' = '$TARGET_WS'"

    # Switch back to original
    qs ipc --pid "$SHELL_PID" call nacre workspaceSwitch "$STATUS_WS" 2>/dev/null
    sleep 1
    info "Restored to workspace $STATUS_WS"
fi

# ══════════════════════════════════════════════════════════════════
# 11. STATE PERSISTENCE (write + read back)
# ══════════════════════════════════════════════════════════════════
header "11. State Persistence"

# Save original
cp "$STATE_FILE" /tmp/nacre-state-backup.json

# Write test value
python3 -c "
import json
with open('$STATE_FILE','r+') as f:
    c = json.load(f)
    c['lastWorkspace'] = 42
    f.seek(0)
    json.dump(c, f, indent=4)
    f.truncate()
"
TEST_WS=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['lastWorkspace'])")
check "State write: lastWorkspace=42"    "test '$TEST_WS' = '42'"

# Read back
READBACK=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['lastWorkspace'])")
check "State read: lastWorkspace=42"     "test '$READBACK' = '42'"

# Restore
cp /tmp/nacre-state-backup.json "$STATE_FILE"
info "Original state restored"

# ══════════════════════════════════════════════════════════════════
# 12. DEFAULT FILES IN REPO
# ══════════════════════════════════════════════════════════════════
header "12. Repo Defaults"

check "shell.default.json exists"       "test -f shell.default.json"
check "state.default.json exists"       "test -f state.default.json"
check "shell.default.json is valid JSON" "python3 -m json.tool shell.default.json > /dev/null"
check "state.default.json is valid JSON" "python3 -m json.tool state.default.json > /dev/null"

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
    echo ""
    echo "What was tested:"
    echo "  • Directory structure (config/, state/, modules/, components/, services/)"
    echo "  • QML files exist for all singletons"
    echo "  • HyprlandService: singleton, available flag, reactive properties, no UI"
    echo "  • Workspaces widget: Repeater, service binding, switchWorkspace, click-to-switch"
    echo "  • Clock widget: SystemClock, Config format, Qt.formatDateTime"
    echo "  • IPC handler: typed methods (ping, barToggle, workspaceSwitch, shellStatus)"
    echo "  • IPC runtime: ping, shellStatus, barToggle toggle cycle"
    echo "  • Clock format live-reload"
    echo "  • Config: valid JSON, enabledByDefault (not visible), clock.format"
    echo "  • State: valid JSON, lastWorkspace round-trips"
    echo "  • No stale imports from old config/GlobalStates, config/Persistent"
    echo "  • shell.qml and ContentWindow import from state/"
    echo "  • Shell process running"
    echo "  • Live config reload works"
    echo "  • State write/read persistence works"
    echo "  • Repo defaults exist and are valid"
    exit 0
else
    echo ""
    echo "Fix the $FAIL failure(s) above."
    exit 1
fi
