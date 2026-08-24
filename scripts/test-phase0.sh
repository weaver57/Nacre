#!/usr/bin/env bash
# Phase 0 smoke test — basic shell health check.
#
# For the full state architecture test, run test-phase1-state.sh instead.
#
# What it checks:
#   1. Config file exists and is valid JSON
#   2. Config values are correct
#   3. Shell process is running
#   4. IPC stub exists
#
# Usage:
#   chmod +x scripts/test-phase0.sh
#   ./scripts/test-phase0.sh

set -uo pipefail

CONFIG_DIR="$HOME/.config/nacre"
CONFIG_FILE="$CONFIG_DIR/shell.json"
PASS=0
FAIL=0

green() { printf "\033[32m✓ %s\033[0m\n" "$1"; }
red()   { printf "\033[31m✗ %s\033[0m\n" "$1"; }
info()  { printf "\033[36m→ %s\033[0m\n" "$1"; }

echo "=== Nacre Phase 0 Test ==="
echo ""

# ── Test 1: Config file exists and is valid JSON ──────────────
echo "1. Config file"

if [[ ! -f "$CONFIG_FILE" ]]; then
    info "Copying shell.default.json → $CONFIG_FILE"
    mkdir -p "$CONFIG_DIR"
    cp shell.default.json "$CONFIG_FILE"
fi

if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    green "Config is valid JSON"
    ((PASS++))
else
    red "Config is invalid JSON"
    ((FAIL++))
fi

# ── Test 2: Config values are readable ────────────────────────
echo ""
echo "2. Config values"

if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    HEIGHT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['bar']['height'])")
    POSITION=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['bar']['position'])")
    ENABLED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['bar'].get('enabledByDefault', json.load(open('$CONFIG_FILE'))['bar'].get('visible', 'MISSING')))")

    info "bar.height          = $HEIGHT"
    info "bar.position        = $POSITION"
    info "bar.enabledByDefault= $ENABLED"

    if [[ "$HEIGHT" =~ ^[0-9]+$ ]] && [[ "$POSITION" == "top" || "$POSITION" == "bottom" ]]; then
        green "Config values look correct"
        ((PASS++))
    else
        red "Config values unexpected"
        ((FAIL++))
    fi
else
    red "Cannot read config — invalid JSON"
    ((FAIL++))
fi

# ── Test 3: Shell process is running ──────────────────────────
echo ""
echo "3. Shell process"

SHELL_PID=$(pgrep -x quickshell 2>/dev/null || true)

if [[ -n "$SHELL_PID" ]]; then
    green "Shell is running (PID: $SHELL_PID)"
    ((PASS++))
else
    red "Shell is not running"
    info "Launch it: quickshell -p ."
    ((FAIL++))
fi

# ── Test 4: IPC stub ──────────────────────────────────────────
echo ""
echo "4. IPC stub"

if [[ -f "services/IpcHandler.qml" ]]; then
    green "IpcHandler.qml exists"
    ((PASS++))
else
    red "IpcHandler.qml missing"
    ((FAIL++))
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [[ $FAIL -eq 0 ]]; then
    echo ""
    echo "Phase 0 checks pass."
    echo ""
    echo "To verify live reload manually:"
    echo "  1. Watch the bar on screen"
    echo "  2. Run:"
    echo "     python3 -c \"import json; f=open('$CONFIG_FILE','r+'); c=json.load(f); c['bar']['height']=48; f.seek(0); json.dump(c,f,indent=4); f.truncate()\""
    echo "  3. Bar should resize to 48px immediately"
    echo ""
    echo "Phase 0 is go."
    exit 0
else
    echo "Fix the failures above before moving on."
    exit 1
fi
