#!/usr/bin/env bash
# Manual verification checklist — Phase 2 spec §2.11.2 / §2.11.3
#
# Run this on a live Hyprland session. Each item requires the
# human to confirm visually or via a quick check, then mark pass/fail.
#
# Usage:
#   chmod +x scripts/verify-phase2-manual.sh
#   ./scripts/verify-phase2-manual.sh

set -uo pipefail

PASS=0
FAIL=0

green() { printf "\033[32m  ✓ %s\033[0m\n" "$1"; }
red()   { printf "\033[31m  ✗ %s\033[0m\n" "$1"; }
header(){ echo ""; echo "── $1 ──"; }

confirm() {
    local label="$1"
    echo -n "  ▸ $label — [y/n] "
    read -r ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        green "$label"
        ((PASS++))
    else
        red "$label"
        ((FAIL++))
    fi
}

echo "╔══════════════════════════════════════════════════╗"
echo "║  Nacre Phase 2 — Manual Verification Checklist  ║"
echo "╚══════════════════════════════════════════════════╝"

# ══════════════════════════════════════════════════════════════════
# §2.11.2 Manual verification
# ══════════════════════════════════════════════════════════════════
header "Battery (§2.3 / §2.7)"

confirm "Battery widget shows correct percentage"
confirm "Battery icon reflects charge state (charging ⚡ vs discharging 🔋)"
confirm "Unplug AC adapter → battery updates live within ~5s"
confirm "Plug AC adapter back → charging icon appears"

header "Battery — no battery (§2.7 collapse)"

confirm "On a machine/VM with no battery, battery widget is hidden (not broken icon)"
confirm "No layout jank or gap in bar where battery would be"

header "Volume (§2.4 / §2.7)"

confirm "Volume widget shows current volume percentage"
confirm "Scroll up on volume widget → volume increases audibly"
confirm "Scroll down on volume widget → volume decreases audibly"
confirm "Click volume widget → mute toggles (speaker icon changes to 🔇)"
confirm "Click again → unmutes (icon returns to normal)"

header "Media keys (§2.9)"

confirm "XF86AudioRaiseVolume key → volume increases"
confirm "XF86AudioLowerVolume key → volume decreases"
confirm "XF86AudioMute key → mute toggles"

header "Tray (§2.6)"

confirm "Tray shows at least 2 real running app icons"
confirm "Tray icons have correct tooltip on hover"
confirm "Click a tray icon → app window activates / comes to foreground"
confirm "Tray icons have consistent uniform size"

header "Network (§2.5)"

confirm "Network widget shows wifi icon + SSID when connected"
confirm "Toggle wifi off → widget shows disconnected state"
confirm "Toggle wifi back on → widget recovers to wifi + SSID"
confirm "Ethernet connection shows eth icon (if available)"

header "Multi-monitor (§2.10)"

confirm "Battery/volume/network/tray render on ALL connected monitors"
confirm "Widgets are identical across monitors (not just primary)"

# ══════════════════════════════════════════════════════════════════
# §2.11.3 Regression check
# ══════════════════════════════════════════════════════════════════
header "Regression — Phase 0/1 (§2.11.3)"

confirm "Bar renders at correct position (top or bottom per config)"
confirm "Bar height matches config value"
confirm "Workspaces show correct workspace list for this monitor"
confirm "Workspace click switches workspace"
confirm "Clock shows correct time in configured format"
confirm "IPC ping returns 'pong'"
confirm "IPC barToggle hides and shows the bar"
confirm "Config live-reload works (edit shell.json → values change)"
confirm "Persistent workspace tracking works (switch workspace → state.json updates)"
confirm "No console errors in quickshell log"

# ══════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════╗"
printf "║  Results: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m  (of %d) ║\n" "$PASS" "$FAIL" "$((PASS + FAIL))"
echo "╚══════════════════════════════════════════╝"

if [[ $FAIL -eq 0 ]]; then
    echo ""
    echo "All manual checks pass. Phase 2 is complete per §2.12."
    exit 0
else
    echo ""
    echo "$FAIL check(s) failed — address before starting Phase 3."
    exit 1
fi
