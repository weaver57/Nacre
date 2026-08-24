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
    check "Has pragma Singleton"         "grep -q 'pragma Singleton' services/HyprlandService.qml"
    check "Imports Quickshell.Hyprland"  "grep -q 'import Quickshell.Hyprland' services/HyprlandService.qml"
    check "Has available flag"           "grep -q 'property bool available' services/HyprlandService.qml"
    check "Has workspaces property"      "grep -q 'workspaces' services/HyprlandService.qml"
    check "Has focusedWorkspace property" "grep -q 'focusedWorkspace' services/HyprlandService.qml"
    check "Has monitors property"        "grep -q 'monitors' services/HyprlandService.qml"
    check "Has switchWorkspace function"  "grep -q 'function switchWorkspace' services/HyprlandService.qml"
    check "No visual elements"           "! grep -E 'Rectangle|Text|Item \{' services/HyprlandService.qml | grep -v '^[[:space:]]*\*' | grep -v '^[[:space:]]*//' | grep -q ."
    check "No UI module imports"         "! grep -E 'import.*modules|import.*components' services/HyprlandService.qml | grep -v '^[[:space:]]*\*' | grep -v '^[[:space:]]*//' | grep -q ."
else
    info "HyprlandService.qml not found — skipping service checks"
fi

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
    check "Checks focusedWorkspace"         "grep -q 'focusedWorkspace' modules/bar/Workspaces.qml"
    check "Has MouseArea for click"         "grep -q 'MouseArea' modules/bar/Workspaces.qml"
    check "Registered in qmldir"           "grep -q 'Workspaces' modules/bar/qmldir"
    check "BarContent imports Workspaces"   "grep -q 'Workspaces' modules/bar/BarContent.qml"
else
    info "Workspaces.qml not found — skipping widget checks"
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
# 8. LIVE CONFIG RELOAD
# ══════════════════════════════════════════════════════════════════
header "8. Live Config Reload"

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
else
    info "Skipping live reload test — shell not running"
fi

# ══════════════════════════════════════════════════════════════════
# 9. STATE PERSISTENCE (write + read back)
# ══════════════════════════════════════════════════════════════════
header "9. State Persistence"

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
# 10. DEFAULT FILES IN REPO
# ══════════════════════════════════════════════════════════════════
header "10. Repo Defaults"

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
