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

- Linux (Wayland compositor or X11 window manager)
- Quickshell 0.3+
- Qt 6.5+
- QML modules (installed with Quickshell)

## Installation

> **Note:** Nacre is currently under active development. Installation instructions will be available once the initial release is ready.

### From Source

```bash
git clone https://github.com/your-username/nacre.git
cd nacre
# Build and install instructions coming soon
```

## Quick Start

Once installed, start Nacre with:

```bash
nacre
```

Or run individual components:

```bash
nacre panel
nacre dock
nacre lockscreen
```

## Configuration

Nacre is configured through QML files located in `~/.config/nacre/`. Each component has its own configuration module:

```
~/.config/nacre/
├── nacre.conf          # Global settings
├── panel/
│   ├── main.qml        # Panel layout
│   └── widgets/        # Custom panel widgets
├── dock/
│   └── main.qml        # Dock configuration
├── widgets/
│   └── ...             # Desktop widget configs
├── lockscreen/
│   └── main.qml        # Lockscreen appearance
└── themes/
    └── ...             # Theme files
```

### Live Reload

Thanks to Quickshell, all changes are reflected **instantly** — just save your QML files and see the result immediately. No restarts required.

## Project Structure

```
nacre/
├── modules/
│   ├── bar/                   # Bar module
│   │   ├── BarWrapper.qml     # Wrapper — conditionally loads BarContent
│   │   ├── BarContent.qml     # Phase 0: bare rectangle (scaffolding)
│   │   └── qmldir
│   └── drawers/               # Multi-monitor orchestrator
│       ├── DrawersScope.qml   # Iterates screens, spawns per-display shells
│       ├── ScreenShell.qml    # Per-screen container for modules
│       └── qmldir
├── components/                # Shared UI primitives
│   ├── ContentWindow.qml      # Screen-anchored surface sized from Config
│   ├── ModuleWrapper.qml      # Generic Loader pattern (reused by every module)
│   └── qmldir
├── config/                    # Configuration layer
│   ├── ConfigManager.h/cpp    # C++ backend — file watching, JSON parsing
│   ├── Config.qml             # QML singleton — single source of truth
│   └── qmldir
├── services/                  # System service integrations (audio, network, etc.)
├── utils/                     # Shared utility functions and helpers
└── assets/                    # Icons, fonts, images, and static resources
```

## Contributing

Nacre welcomes contributions! Whether it's bug reports, feature requests, documentation, or code — everything helps.

Please read our contributing guidelines (coming soon) before submitting a pull request.

## Architecture

Nacre follows a layered architecture where each piece has a single responsibility:

```
┌──────────────────────────────────────────────────────────┐
│  Config (singleton)                                      │
│  ~/.config/nacre/shell.json → typed properties           │
├──────────────────────────────────────────────────────────┤
│  DrawersScope                                            │
│  Iterates screens → ScreenShell per monitor              │
├──────────────────────────────────────────────────────────┤
│  ContentWindow                                           │
│  Screen-anchored surface, sizes from Config              │
├──────────────────────────────────────────────────────────┤
│  ModuleWrapper              (generic, in components/)    │
│  Loader reads Config, loads/unloads module content       │
├──────────────────────────────────────────────────────────┤
│  BarWrapper → BarContent    (Phase 0: colored rect)      │
│  Future: LauncherWrapper, NotificationWrapper, …         │
└──────────────────────────────────────────────────────────┘
```

### The Wrapper Pattern

Every module follows the same shape:

```qml
// modules/<name>/<Name>Wrapper.qml
ModuleWrapper {
    moduleName: "<name>"
    moduleSource: <Name>Content { }
}
```

`ModuleWrapper` handles the lifecycle: it reads `modules.<name>.enabled` from Config, and when `false`, the Loader fully destroys the component — no half-states, no hidden rendering. To disable any module, set `"modules": { "<name>": { "enabled": false } }` in `shell.json`.

This is the convention that makes adding new modules mechanical: write the content, write a one-line wrapper, done.

**Key principle:** nothing below a layer ever reaches up. Modules don't parse JSON — they read `Config.*`. ContentWindow doesn't know what a bar is — it just hosts a region. DrawersScope doesn't know what modules exist — it just spawns shells.

## Roadmap

- [x] Project structure locked in
- [x] Config singleton (JSON → typed properties)
- [x] DrawersScope (multi-monitor orchestrator)
- [x] ContentWindow (screen-anchored surface)
- [x] ModuleWrapper (generic Loader pattern)
- [x] Bar module (Phase 0 scaffolding)
- [ ] Bar content: clock, system tray, workspaces
- [ ] Launcher module
- [ ] Notifications module
- [ ] OSD module
- [ ] Services layer
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
