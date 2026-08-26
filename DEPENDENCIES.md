# System Dependencies

Runtime requirements for Nacre, by service. Anything marked **required** will
degrade the corresponding bar widget if missing (the widget's service reports
`available: false` and the shell continues without it).

## Core

| Dependency | Required | Used by | Notes |
|------------|----------|---------|-------|
| [Quickshell](https://quickshell.outfoxxed.me/) | ✅ required | everything | Shell runtime |
| Hyprland | ✅ required | `HyprlandService` | Compositor; workspaces, dispatch |

## Phase 2 status services

| Dependency | Required | Used by | Notes |
|------------|----------|---------|-------|
| upower | recommended | `BatteryService` | Via `Quickshell.Services.UPower`. Absent → battery widget hidden (`available: false`). Desktops normally lack it. |
| pipewire + wireplumber (`wpctl`) | recommended | `AudioService` | Reads via `Quickshell.Services.Pipewire`, writes via `wpctl`. Absent → volume widget hidden. |
| networkmanager (daemon) | recommended | `NetworkService` | Strategy A: direct D-Bus via `Quickshell.Networking` — event-driven, no subprocess. Daemon absent → network widget hidden. The `nmcli` CLI is **not** a Nacre dependency.

## Paired keybinds (spec 2.9.2)

Media keys should route through Nacre IPC so `AudioService.scrollStep`
(user-tunable, spec 2.8) is the single source of truth for step size.
Add to `~/.config/hypr/keybindings.conf`:

```
binddel = , XF86AudioRaiseVolume, $d nacre volume increase , exec, qs ipc call nacre volumeIncrease
binddel = , XF86AudioLowerVolume, $d nacre volume decrease , exec, qs ipc call nacre volumeDecrease
binddl  = , XF86AudioMute,        $d nacre volume toggle mute, exec, qs ipc call nacre volumeToggleMute
```

If existing wpctl/hyde-shell keybinds are present, comment them out to
avoid double-triggering.

## Development / testing

| Dependency | Used by | Notes |
|------------|---------|-------|
| bash, coreutils | `scripts/test-*.sh` | Test suites |
| python3 | `scripts/test-*.sh` | JSON validation |

Install on Arch/Hyprland:

```
pacman -S quickshell hyprland networkmanager upower pipewire wireplumber
```
