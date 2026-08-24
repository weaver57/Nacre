# Nacre Conventions

The rules that keep a shell "modular" instead of "five modules built five different ways."

---

## State Architecture

Every property in Nacre belongs to exactly one of three tiers. The distinguishing test:

> *"If I ask the user to describe this in words, do they say 'I want X' (Config) or 'right now X is happening' (GlobalStates) or 'remember that X happened' (Persistent)?"*

| Tier | Directory | Persisted? | Answers | Example |
|------|-----------|------------|---------|---------|
| **Config** | `config/` | ✅ `shell.json` | What did the user *choose*? | `bar.height`, `bar.position`, `clock.format` |
| **GlobalStates** | `state/` | ❌ Resets on restart | What is true *right now*? | `barOpen`, `launcherOpen`, `screenLocked` |
| **Persistent** | `state/` | ✅ `state.json` | What should survive a restart? | `lastWorkspace`, `notificationHistory` |

### Rules

- **Config is read-only at runtime.** Only a settings action (not yet built) writes to it. Widgets never write to Config.
- **GlobalStates is ephemeral.** Seed values come from Config at startup, then GlobalStates is free to change independently.
- **Persistent is write-on-demand.** Consumers call `Persistent.save()` when they change state that needs to survive restarts.
- **Modules bind to GlobalStates, not Config, for runtime visibility.** Config gates whether a module is *installed*; GlobalStates gates whether it's *open right now*.

### Import paths

```qml
import "../config" as Config    // Config singleton
import "../state" as State      // GlobalStates, Persistent
import "../services" as Services // HyprlandService, etc.
```

---

## Service Layer

Services are **singletons that own a data source and expose it reactively**, cleanly separated from UI.

### What qualifies as a service

A service is a `QtObject` that:

- Owns exactly **one** external data source (compositor, D-Bus, clock, etc.)
- Exposes that data as **reactive QML properties only** — never poll-based
- May expose **action functions** (e.g. dispatch a command) but never owns visual state
- Contains **zero QML visual elements** (no `Rectangle`, `Text`, `Item`)
- Is safe to instantiate even if its backing system isn't available yet

### Directory & naming

```
services/
├── HyprlandService.qml   # compositor data
├── AudioService.qml      # (Phase 2)
├── IpcHandler.qml        # external control
└── qmldir
```

| Pattern | Example |
|---------|---------|
| File | `<Name>Service.qml` |
| Singleton | `HyprlandService` |
| Property | `workspaces`, `focusedWorkspace` |
| Action | `switchWorkspace(id)` |
| Availability | `property bool available: false` |

### Lifecycle rules

1. **No reverse imports.** Services must never import UI modules. Direction is strictly: `services → modules`, never the reverse.
2. **Availability flag.** Every service exposes `property bool available: false`, flipped true once the data source responds. Consumers check this before reading data.
3. **No cross-service imports** if avoidable. If a dependency is unavoidable, document it at the top of the file.
4. **One file per service.** No "god service" that owns multiple unrelated data sources.

### The rule

```
Widget → reads Service property (reactive binding)
Widget → calls Service.action() (dispatch)
Service → wraps external source (Hyprland, D-Bus, etc.)
```

**Never:** `Widget → imports Quickshell.Hyprland directly`

This keeps compositor-specific code in ONE file. Swapping compositors means rewriting only the service, not every widget.

### HyprlandService (worked example)

```qml
// services/HyprlandService.qml
import QtQuick
import Quickshell.Hyprland

QtObject {
    property bool available: false
    property alias workspaces: Hyprland.workspaces
    property alias focusedWorkspace: Hyprland.focusedWorkspace
    property alias monitors: Hyprland.monitors

    function switchWorkspace(id) {
        Hyprland.dispatch("workspace " + id)
    }
}
```

Widgets consume it:

```qml
// modules/bar/Workspaces.qml
Repeater {
    model: Services.HyprlandService.workspaces
    // ...
}
```

---

## Module Structure

Every UI module follows this exact three-layer shape. No exceptions.

```
┌─────────────────────────────────────────────────┐
│  Wrapper (outer container)                      │
│  Module-scoped properties, init, IPC binding    │
├─────────────────────────────────────────────────┤
│  Loader                                         │
│  Conditional instantiation from GlobalStates    │
├─────────────────────────────────────────────────┤
│  Content (actual UI)                            │
│  Pure rendering, no state logic                 │
└─────────────────────────────────────────────────┘
```

### Layer 1: Wrapper

The outer container. Owns module-scoped properties, handles initialization, and binds to IPC.

```qml
// modules/<name>/<Name>Wrapper.qml
Item {
    id: wrapper

    anchors.fill: parent

    // Module-scoped properties (if any)
    // ...

    // IPC binding (see Control Mechanisms below)
    // ...

    Loader {
        id: loader
        anchors.fill: parent
        active: State.GlobalStates.<name>Open
        sourceComponent: Component { /* Layer 3 */ }
    }
}
```

### Layer 2: Loader

Reads `GlobalStates.<name>Open` to decide whether to instantiate the content. When `false`, the component is fully destroyed — no half-states, no hidden rendering.

### Layer 3: Content

Pure rendering. Knows nothing about visibility, IPC, or state management. Just draws what it's told to draw.

```qml
// modules/<name>/<Name>Content.qml
Rectangle {
    // Visual content only
}
```

---

## Control Mechanisms

Every module that toggles visibility exposes **two** control paths. Both converge on the same `GlobalStates` property. Never bypass one for the other.

### 1. IPC Handler (external control)

For CLI tools, AI agents, scripts, and other processes.

```qml
// In IpcHandler.qml or module-specific handler
function toggle<Name>() {
    State.GlobalStates.<name>Open = !State.GlobalStates.<name>Open
}
```

### 2. Global Shortcut (keybind)

For Hyprland keybinds. Calls the same IPC method — never reaches into Hyprland directly.

```qml
// In the module's Wrapper or a dedicated Shortcuts.qml
GlobalShortcut {
    name: "<module>.toggle"
    description: "Toggle <module>"
    onPressed: {
        // Same path as IPC — through GlobalStates
        State.GlobalStates.<name>Open = !State.GlobalStates.<name>Open
    }
}
```

### The rule

```
Keybind → GlobalShortcut → GlobalStates → Module visibility
              ↑                                    ↑
              └── IPC calls the same path ─────────┘
```

**Never:** `Keybind → Hyprland dispatcher → module reacts`

This ensures every toggle is observable, testable, and consistent regardless of how it was triggered.

---

## Naming

| Pattern | Example |
|---------|---------|
| Module directory | `modules/bar/`, `modules/launcher/` |
| Wrapper | `BarWrapper.qml`, `LauncherWrapper.qml` |
| Content | `BarContent.qml`, `LauncherContent.qml` |
| GlobalStates property | `barOpen`, `launcherOpen` |
| IPC method | `toggleBar()`, `toggleLauncher()` |
| Config preference | `bar.enabledByDefault`, `bar.height` |
| Shortcut name | `bar.toggle`, `launcher.toggle` |

---

## File Layout

```
config/
├── Config.qml              # User preferences (persisted)
└── qmldir

state/
├── GlobalStates.qml        # Ephemeral runtime toggles (not persisted)
├── Persistent.qml          # Runtime state that survives restarts
└── qmldir

services/
├── HyprlandService.qml     # Compositor data (wraps Quickshell.Hyprland)
├── IpcHandler.qml          # External control (CLI, AI, scripts)
└── qmldir

modules/<name>/
├── <Name>Wrapper.qml       # Layer 1: container + IPC + Loader
├── <Name>Content.qml       # Layer 3: pure UI
└── qmldir
```

---

## Checklist

When adding a new module, verify:

- [ ] Three-layer structure (Wrapper → Loader → Content)
- [ ] `GlobalStates.<name>Open` controls the Loader
- [ ] `Config.isModuleEnabled("<name>")` gates the ContentWindow
- [ ] IPC method in IpcHandler or module handler
- [ ] GlobalShortcut calls same GlobalStates toggle
- [ ] Content has no visibility/state logic
- [ ] Naming follows convention table above

When adding a new service, verify:

- [ ] Pure QtObject — zero visual elements
- [ ] Owns exactly one data source
- [ ] `available` flag exposed and checked by consumers
- [ ] No UI module imports
- [ ] All compositor actions go through named functions, not raw `dispatch()`
