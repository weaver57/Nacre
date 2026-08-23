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
│   ├── bar/            # Status bar, panels, and top/bottom bars
│   └── drawers/        # App drawers, popups, and overlay menus
├── components/         # Shared UI components and widgets
├── config/             # Default configuration files and templates
├── services/           # System service integrations (audio, network, etc.)
├── utils/              # Shared utility functions and helpers
└── assets/             # Icons, fonts, images, and static resources
```

## Contributing

Nacre welcomes contributions! Whether it's bug reports, feature requests, documentation, or code — everything helps.

Please read our contributing guidelines (coming soon) before submitting a pull request.

## Roadmap

- [x] Project structure locked in
- [ ] Core shell infrastructure and IPC
- [ ] Bar module with system tray
- [ ] Drawers module with app launcher
- [ ] Component library
- [ ] Services layer
- [ ] Configuration system
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
