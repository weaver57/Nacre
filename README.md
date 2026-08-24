# Nacre

<div align="center">

**A highly customizable and modular Linux desktop environment**

Built on [Quickshell](https://quickshell.org/) — the flexible toolkit for creating desktop shells with QtQuick

![License](https://img.shields.io/badge/license-LGPL--3.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![Quickshell](https://img.shields.io/badge/Quickshell-0.3+-green)

</div>

---

## What is Nacre?

Nacre is a modular, highly customizable desktop environment for Linux, built on top of [Quickshell](https://quickshell.org/). It leverages QML (Qt's declarative UI language) to provide a beautiful, responsive, and deeply configurable desktop experience.

Inspired by the nacreous iridescence of mother-of-pearl, Nacre brings a unique aesthetic philosophy to Linux desktops — combining visual elegance with powerful modularity.

## Features

- **Fully Modular Architecture** — Pick and choose only the components you need
- **QML-Powered UI** — Beautiful, hardware-accelerated interfaces with live reload
- **Deep Customization** — Configure every aspect through simple QML files
- **Wayland Native** — Built for modern Wayland compositors with X11 fallback
- **Lightweight** — Minimal resource footprint, maximum flexibility
- **Plugin System** — Extend Nacre with community-created and custom plugins
- **Multi-Monitor Support** — Seamless multi-display workflows
- **Theming Engine** — Create and share complete visual themes
- **IPC Ready** — Inter-component communication for complex workflows

## Components

| Component | Description |
|-----------|-------------|
| **Panel** | Status bar with system tray, clock, workspaces, and custom widgets |
| **Dock** | Application launcher and taskbar with animations |
| **Widgets** | Standalone desktop widgets (weather, system monitor, notes, etc.) |
| **Lockscreen** | Secure and beautiful lock screen with blur effects |
| **Notifications** | Elegant notification center with action support |
| **Dashboard** | Quick settings and system control panel |

## Requirements

- Linux with a Wayland compositor (Hyprland, Sway, etc.)
- [Quickshell](https://quickshell.org/) 0.3+
- Qt 6.5+ with Quick module
- CMake 3.20+
- C++20 compiler

## Installation

### From Source

```bash
git clone https://github.com/your-username/nacre.git
cd nacre

# Create config and state directories, copy defaults
mkdir -p ~/.config/nacre
mkdir -p ~/.local/state/nacre
cp shell.default.json ~/.config/nacre/shell.json
cp state.default.json ~/.local/state/nacre/state.json
```

### Symlink Convention

For development, run directly from the repo:

```bash
quickshell -p /path/to/nacre
```

For installed usage, symlink into Quickshell's config path:

```bash
# Quickshell looks for configs in ~/.config/quickshell/
mkdir -p ~/.config/quickshell
ln -s /path/to/nacre ~/.config/quickshell/nacre

# Then launch with:
quickshell -c nacre
```

### Config Files

| File | Location | Purpose | Gitignored? |
|------|----------|---------|-------------|
| `shell.default.json` | repo root | Shipped default config | No (committed) |
| `state.default.json` | repo root | Shipped default state | No (committed) |
| `shell.json` | `~/.config/nacre/` | Live user preferences | Yes |
| `state.json` | `~/.local/state/nacre/` | Live runtime state (XDG) | Yes |

**Never commit your live `shell.json` or `state.json`** — these are personal runtime config, not source.

## Quick Start

Launch the shell:

```bash
quickshell -p .
```

Quickshell loads `shell.qml` from the current directory. Edit `~/.config/nacre/shell.json` and save — changes appear instantly.

## Testing Phase 0

After launching, run the smoke test in another terminal:

```bash
./scripts/test-phase0.sh
```

Or verify manually:

```bash
# 1. Check the bar is rendering (look for a colored rectangle at screen edge)
# 2. Edit config and watch it update live:
echo '{"bar":{"height":48,"position":"top"},"theme":"default"}' > ~/.config/nacre/shell.json

# 3. Test IPC ping (when transport is wired):
# qdbus org.nacre.shell /org/nacre ping
```

## Configuration

Nacre reads a single JSON file:

```
~/.config/nacre/shell.json
```

### Example shell.json

```json
{
    "bar": {
        "height": 32,
        "position": "top",
        "enabledByDefault": true
    },
    "clock": {
        "format": "HH:mm"
    },
    "theme": "default",
    "modules": {
        "bar": {
            "enabled": true
        }
    }
}
```

### Config Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `bar.height` | int | `32` | Bar height in pixels |
| `bar.position` | string | `"top"` | `"top"` or `"bottom"` |
| `bar.enabledByDefault` | bool | `true` | Bar on at startup (seeded into GlobalStates) |
| `clock.format` | string | `"HH:mm"` | Time format string |
| `theme` | string | `"default"` | Active theme name |
| `modules.<name>.enabled` | bool | `true` | Enable/disable any module |

### Live Reload

`ConfigManager` watches `shell.json` with `QFileSystemWatcher`. Edit the file and save — changes appear instantly. No restarts, no signals, no manual reload.

### Disabling Modules

Set `modules.<name>.enabled` to `false`:

```json
{
    "modules": {
        "bar": { "enabled": false }
    }
}
```

The `ModuleWrapper` Loader fully destroys the component — no half-states.

## Project Structure

```
nacre/
├── modules/
│   ├── bar/                   # Bar module (three-layer pattern)
│   │   ├── BarWrapper.qml     # Layer 1: container + Loader
│   │   ├── BarContent.qml     # Layer 3: pure UI
│   │   └── qmldir
│   └── drawers/               # Multi-monitor orchestrator
│       ├── DrawersScope.qml   # Iterates screens, spawns per-display shells
│       ├── ScreenShell.qml    # Per-screen container for modules
│       └── qmldir
├── components/                # Shared UI primitives
│   ├── ContentWindow.qml      # Screen-anchored surface sized from Config
│   ├── ModuleWrapper.qml      # Generic Loader pattern (reused by every module)
│   └── qmldir
├── config/                    # User preferences
│   ├── Config.qml             # shell.json → typed properties
│   └── qmldir
├── state/                     # Runtime state (separate from config)
│   ├── GlobalStates.qml       # Ephemeral toggles (not persisted)
│   ├── Persistent.qml         # Survives restarts (state.json)
│   └── qmldir
├── services/                  # Service layer (data sources, no UI)
│   ├── HyprlandService.qml    # Compositor data (wraps Quickshell.Hyprland)
│   ├── IpcHandler.qml         # External control (CLI, AI, scripts)
│   └── qmldir
├── utils/                     # Shared utility functions and helpers
├── assets/                    # Icons, fonts, images, and static resources
├── scripts/                   # Test and utility scripts
│   └── test-phase0.sh         # Phase 0 smoke test
├── shell.qml                  # Shell entry point (Quickshell loads this)
├── CMakeLists.txt             # Build configuration for C++ components
├── shell.default.json         # Shipped default config
├── state.default.json         # Shipped default state
└── CONVENTIONS.md             # Module pattern and state architecture spec
```

## Contributing

Nacre welcomes contributions! Whether it's bug reports, feature requests, documentation, or code — everything helps.

Please read our contributing guidelines (coming soon) before submitting a pull request.

## Architecture

Nacre follows a layered architecture where each piece has a single responsibility:

```
┌──────────────────────────────────────────────────────────┐
│  Config              (user preferences, persisted)       │
│  ~/.config/nacre/shell.json → bar.height, position, etc. │
├──────────────────────────────────────────────────────────┤
│  GlobalStates        (ephemeral runtime UI state)        │
│  barOpen, launcherOpen, screenLocked — resets on restart │
├──────────────────────────────────────────────────────────┤
│  Persistent          (runtime state, survives restarts)  │
│  ~/.local/state/nacre/state.json                         │
├──────────────────────────────────────────────────────────┤
│  ContentWindow       (screen-anchored surface)           │
│  visible: Config.enabled && GlobalStates.open            │
├──────────────────────────────────────────────────────────┤
│  Module pattern:  Wrapper → Loader → Content             │
│  See CONVENTIONS.md for the three-layer structure         │
├──────────────────────────────────────────────────────────┤
│  Service Layer (HyprlandService, etc.)                  │
│  Reactive data, no UI. Widgets read properties.          │
├──────────────────────────────────────────────────────────┤
│  IpcHandler + GlobalShortcuts (control mechanisms)       │
│  Both converge on GlobalStates — never bypass the module │
└──────────────────────────────────────────────────────────┘
```

### Three Singletons

| Singleton | Directory | Purpose | Persists? |
|-----------|-----------|---------|-----------|
| **Config** | `config/` | User preferences (height, position, theme) | ✅ `~/.config/nacre/shell.json` |
| **GlobalStates** | `state/` | Ephemeral UI toggles (barOpen, launcherOpen) | ❌ Resets on restart |
| **Persistent** | `state/` | Runtime state that survives (workspace, history) | ✅ `~/.local/state/nacre/state.json` |

### Module Pattern

Every module follows the same three-layer shape. See **[CONVENTIONS.md](CONVENTIONS.md)** for the full specification.

```
Wrapper (properties + IPC + Loader)
  └─ Loader (reads GlobalStates.<name>Open)
       └─ Content (pure rendering)
```

### Control Flow

Every visibility toggle converges on `GlobalStates`:

```
Keybind → GlobalShortcut → GlobalStates → Module visibility
              ↑                                    ↑
              └── IPC calls the same path ─────────┘
```

**Never:** keybind → Hyprland dispatcher → module reacts. This ensures every toggle is observable, testable, and consistent.

### Service Layer

Services are singletons that own a data source and expose it reactively. Zero visual elements — pure `QtObject` + logic. Widgets read properties; services own the data.

```
Widget → reads Service property (reactive binding)
Widget → calls Service.action() (dispatch)
Service → wraps external source (Hyprland, D-Bus, etc.)
```

| Service | Data source | Key properties |
|---------|-------------|----------------|
| **HyprlandService** | Hyprland IPC | `workspaces`, `focusedWorkspace`, `monitors` |

**Never:** Widget imports `Quickshell.Hyprland` directly. All compositor access goes through the service.

### Initialization Order

1. Config loads (user preferences from shell.json)
2. GlobalStates initializes (all defaults, ephemeral)
3. Persistent loads (saved runtime state from state.json)
4. Services available (HyprlandService wraps Quickshell.Hyprland)
5. Modules activate based on `Config.isModuleEnabled()`
6. Modules bind to GlobalStates + Services for runtime behavior

## Roadmap

- [x] Project structure locked in
- [x] Config singleton (JSON → typed properties)
- [x] Three singletons: Config, GlobalStates, Persistent
- [x] DrawersScope (multi-monitor orchestrator)
- [x] ContentWindow (screen-anchored surface)
- [x] Module pattern (three-layer structure)
- [x] Bar module (Phase 0 scaffolding)
- [x] IPC handler (stub with ping)
- [x] CONVENTIONS.md (module pattern spec)
- [x] Service layer pattern (HyprlandService)
- [ ] Workspaces widget (proves service → widget binding)
- [ ] Clock widget (proves non-Hyprland data source)
- [ ] Launcher module
- [ ] Notifications module
- [ ] OSD module
- [ ] Real IPC transport (D-Bus / socket)
- [ ] AI CLI integration
- [ ] Theming engine
- [ ] Documentation and guides

## Acknowledgments

- [Quickshell](https://quickshell.org/) — The foundation that makes Nacre possible
- The Wayland and Qt communities for building the technologies Nacre relies on
- All the contributors and testers helping shape this project

## License

Nacre is licensed under the [GNU Lesser General Public License v3.0](LICENSE).

---

<div align="center">

**Nacre** — *Your desktop, your way.*

</div>
