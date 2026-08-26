# Nacre Conventions

The rules that keep a shell "modular" instead of "five modules built five different ways."

Every convention here was learned the hard way. Follow them.

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

## QML Singleton Rules

These are non-negotiable. Every one was a runtime crash before we learned it.

### Rule 1: `pragma Singleton` in every singleton file

Every file registered as `singleton` in a `qmldir` must declare `pragma Singleton` at the top. Quickshell rejects the shell if it's missing.

```qml
// ✅ Correct
pragma Singleton
import QtQuick
QtObject { ... }

// ❌ Wrong — missing pragma
import QtQuick
QtObject { ... }
```

### Rule 2: No `property alias` to imported singletons

`property alias` requires a local `id`. Imported singletons (`Hyprland`, `Config`, etc.) are not local ids. Use `property var` with a direct binding instead.

```qml
// ✅ Correct — direct binding
property var workspaces: Hyprland.workspaces

// ❌ Wrong — alias to imported singleton
property alias workspaces: Hyprland.workspaces
```

### Rule 3: No *visual* children inside `QtObject`

`QtObject` cannot hold **visual** types (`Rectangle`, `Item`, `Text`). Non-visual helper objects that are plain QObjects (`Timer`, `Process`, `FileView`, `SplitParser`) are fine — they live in the object's resources and are used by AudioService and NetworkService. Use `Component.onCompleted` for startup logic.

```qml
// ✅ Correct
QtObject {
    property var _timer: Timer { interval: 5000; running: true }
    Component.onCompleted: { /* ... */ }
}

// ❌ Wrong — Rectangle is a visual Item
QtObject {
    property var _box: Rectangle { color: "red" }
}
```

### Rule 4: Never instantiate singletons with `{}`

Singletons are auto-created by QML on first access. You cannot create them with `MySingleton {}`.

```qml
// ✅ Correct — reference the singleton
Component.onCompleted: console.log(Services.IpcHandler.targetName)

// ❌ Wrong — trying to instantiate
Services.IpcHandler { id: ipc }
```

### Rule 5: No `property alias` to Config properties

Same as Rule 2 — Config is an imported singleton. Use `property var` or read directly.

```qml
// ✅ Correct
property var barHeight: Config.Config.barHeight

// ❌ Wrong
property alias barHeight: Config.Config.barHeight
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
2. **Availability flag.** Every service exposes `property bool available`. Set it unconditionally in `Component.onCompleted` if the import succeeded.
3. **No cross-service imports** if avoidable. If a dependency is unavoidable, document it at the top of the file.
4. **One file per service.** No "god service" that owns multiple unrelated data sources.

### The rule

```
Widget → reads Service property (reactive binding)
Widget → calls Service.action() (dispatch)
Service → wraps external source (Hyprland, D-Bus, etc.)
```

**Never:** `Widget → imports Quickshell.Hyprland directly`

### Scroll interaction convention

One wheel step = a fixed delta owned by the service, so every scrollable widget behaves the same:

- `AudioService.scrollStep` — user-tunable via Config `audio.scrollStep` (default 0.02, i.e. 2% per wheel step). Service-owned so all consumers share one ratio; Config-tunable because it is a preference (Phase 2 spec §2.8), never hardcoded in widgets
- Widgets normalize raw wheel input by `angleDelta.y / 120` before calling `adjustVolume(delta)`
- Any future scrollable widget must declare its step size on its service, never hardcode it in the widget

### NetworkService (direct NetworkManager — Strategy A)

Quickshell ships `Quickshell.Networking` in this build — a first-party, event-driven NetworkManager binding over the system D-Bus. The service binds to it reactively; NM pushes D-Bus property-change signals, and there is **no polling timer and no subprocess** anywhere.

- `available` means "NetworkManager is reachable and reporting", **not** "currently connected" — disconnected is expressed via `connectionType === "disconnected"`
- Never compare device-type enum magic numbers: this build's numbering differs from raw NM D-Bus values. Detect wifi by capability (device exposes a `networks` model)
- `WifiNetwork.signalStrength` is normalized 0.0–1.0 by the binding; the service scales it to 0–100 so widgets never do unit math
- Read-only in Phase 2 — the binding exposes connect/disconnect, but this service deliberately does not surface those until a network-management module exists

### TrayService (StatusNotifierItem passthrough)

Structurally the thinnest service in Nacre: tray items are externally-owned, dynamically appearing/disappearing processes — the service is a clean-typed pass-through of `Quickshell.Services.SystemTray`, not a data owner.

- **Left-click activate only (Phase 2 scope limit, spec 2.1.2/2.6.4):** right-click context menus and the DBusMenu popup surface are explicitly deferred. This is a documented, intentional gap — if you find yourself wanting `secondaryActivate()` or menu rendering, that is new scope, schedule it as its own slice.
- Tray items arrive asynchronously after startup; the item list is a reactive binding, never polled or copied into local arrays.
- `TrayService.available` means "at least one tray item registered" — an empty tray hides the widget rather than leaving a gap in the bar.
- The widget owns no state (same rule as Workspaces): icons, tooltips and activation all come from the service's items.

### HyprlandService (worked example)

```qml
// services/HyprlandService.qml
pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root
    property bool available: false

    // Direct bindings — NOT aliases (Rule 2)
    property var workspaces: Hyprland.workspaces
    property var focusedWorkspace: Hyprland.focusedWorkspace
    property var monitors: Hyprland.monitors

    function switchWorkspace(id) {
        if (!available) return
        Hyprland.dispatch("workspace " + id)
    }

    Component.onCompleted: {
        available = true
        console.log("[HyprlandService] available —", Hyprland.workspaces.count, "workspaces")
    }
}
```

### SystemClock (no custom service needed)

Quickshell's built-in `SystemClock` already behaves like a service (reactive property, owns its data source). Use it directly — no wrapper needed.

```qml
// modules/bar/Clock.qml
SystemClock {
    id: clock
    precision: SystemClock.Minutes
}
Text {
    text: Qt.formatDateTime(clock.date, Config.Config.clockFormat)
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

The outer container. Owns module-scoped properties, handles initialization, and loads the content.

```qml
// modules/<name>/<Name>Wrapper.qml
import QtQuick

Item {
    id: wrapper
    anchors.fill: parent

    // Load the real content
    <Name>Content {
        anchors.fill: parent
    }
}
```

### Layer 2: Loader (when needed)

For modules with runtime visibility toggles, the Wrapper uses a Loader bound to `GlobalStates.<name>Open`. When `false`, the component is fully destroyed — no half-states, no hidden rendering.

ContentWindow already gates visibility via `GlobalStates.barOpen`, so the bar's Wrapper doesn't need a Loader — it just loads BarContent directly.

### Layer 3: Content

Pure rendering. Knows nothing about visibility, IPC, or state management. Just draws what it's told to draw. Reads from services and Config — never from raw JSON.

```qml
// modules/bar/BarContent.qml
Rectangle {
    Workspaces { anchors.left: parent.left; ... }   // compositor-driven
    Clock { anchors.right: parent.right; ... }       // time-driven
}
```

### Widget rules

- **No availability guards on widgets.** Don't wrap widgets in `visible: service.available`. Let the Repeater handle empty models — it renders nothing when the model is empty, which is correct.
- **No local state.** Widgets are pure reflections of their data source. If a widget needs to remember something, it goes in GlobalStates or Persistent.
- **No raw JSON access.** All data flows through Config, GlobalStates, Persistent, or services.

### Global vs per-monitor widgets (spec 2.10)

Some widgets are naturally per-monitor (Workspaces — each Variants-spawned bar instance shows that monitor's workspaces). Others represent global system state — one battery, one default audio sink, one tray, one network connection, regardless of how many monitors exist.

**Decision:** render global widgets identically on every monitor's bar. Each ContentWindow instance shows the full status cluster (battery, volume, network, tray), all bound to the same singleton services — cheap (no duplicated state, just duplicated rendering), and every monitor's bar is a complete, self-sufficient status view.

**Why not primary-monitor-only?** That requires defining what "primary" means, special-casing ContentWindow, and choosing an empty bar vs. a missing-widget bar on secondary monitors — unnecessary complexity for marginal benefit.

**How to tell:** global widgets have no `screen` property and import only services/Config. Per-monitor widgets accept `required property var screen` and filter by it.

---

## Bar Layout

The bar is the first real module. Its layout conventions become the template for other modules.

### Current layout

```
[workspace pills] .......................... [clock]
  left-aligned                              right-aligned
  reads HyprlandService                     reads SystemClock + Config
```

### Positioning

Widgets anchor to the bar edges:

```qml
// Left-aligned widget
Workspaces {
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
}

// Right-aligned widget
Clock {
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
}

// Center widget (future: system tray, notifications)
SomeWidget {
    anchors.centerIn: parent
}
```

### Adding a new bar widget

1. Create `modules/bar/<Widget>.qml`
2. Import the service it needs (`import "../../services" as Services`)
3. Bind to the service property reactively
4. Add to BarContent.qml with appropriate anchoring
5. Register in `modules/bar/qmldir`

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
GlobalShortcut {
    name: "<module>.toggle"
    description: "Toggle <module>"
    onPressed: {
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

### IPC Methods (current)

All methods live in `services/IpcHandler.qml`. Hyprland keybinds call them via `qs ipc call nacre <method>`.

| Method | Return | What it does |
|--------|--------|-------------|
| `ping` | `string` | Health check → "pong from nacre" |
| `barToggle` | `void` | Toggle bar visibility |
| `barShow` | `void` | Force bar visible |
| `barHide` | `void` | Force bar hidden |
| `workspaceSwitch(id: int)` | `void` | Switch to workspace N |
| `shellStatus` | `string` | JSON with shell state |
| `volumeIncrease` | `void` | AudioService.adjustVolume(+step) (spec 2.9.1) |
| `volumeDecrease` | `void` | AudioService.adjustVolume(-step) (spec 2.9.1) |
| `volumeToggleMute` | `void` | AudioService.toggleMute() (spec 2.9.1) |

Every IPC method must have a real caller (spec 2.9.3). Volume methods are called by Hyprland media keybinds (XF86AudioRaiseVolume/LowerVolume/Mute). Battery, network, and tray are read-only in Phase 2 — no IPC methods for them until a real use case exists.

---

## Relative Imports

During development, all QML files use relative paths. Module imports (`import Nacre.Config`) only work after installation.

```qml
// In modules/bar/BarContent.qml:
import "../../config" as Config      // → config/Config.qml
import "../../services" as Services  // → services/HyprlandService.qml

// In components/ContentWindow.qml:
import "../config" as Config         // → config/Config.qml
import "../state" as State           // → state/GlobalStates.qml

// In shell.qml:
import "./config" as Config          // → config/
import "./state" as State            // → state/
import "./services" as Services      // → services/
```

The `qmldir` files still exist for future installation, but for development, relative imports just work.

---

## Naming

| Pattern | Example |
|---------|---------|
| Module directory | `modules/bar/`, `modules/launcher/` |
| Wrapper | `BarWrapper.qml`, `LauncherWrapper.qml` |
| Content | `BarContent.qml`, `LauncherContent.qml` |
| Widget (bar) | `Workspaces.qml`, `Clock.qml` |
| GlobalStates property | `barOpen`, `launcherOpen` |
| IPC method | `toggleBar()`, `toggleLauncher()` |
| Config preference | `bar.enabledByDefault`, `bar.height` |
| Shortcut name | `bar.toggle`, `launcher.toggle` |
| Service file | `HyprlandService.qml`, `AudioService.qml` |

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
├── <Name>Wrapper.qml       # Layer 1: container + content loader
├── <Name>Content.qml       # Layer 3: pure UI layout
├── <Widget>.qml            # Individual widgets (Workspaces, Clock, etc.)
└── qmldir

components/
├── ContentWindow.qml       # Screen-anchored surface (one per monitor)
├── ModuleWrapper.qml       # Generic Loader pattern
└── qmldir
```

---

## Checklist

### Adding a new module

- [ ] Three-layer structure (Wrapper → Loader → Content)
- [ ] `GlobalStates.<name>Open` controls the Loader
- [ ] `Config.isModuleEnabled("<name>")` gates the ContentWindow
- [ ] IPC method in IpcHandler or module handler
- [ ] GlobalShortcut calls same GlobalStates toggle
- [ ] Content has no visibility/state logic
- [ ] Naming follows convention table above

### Adding a new service

- [ ] Pure QtObject — zero visual elements
- [ ] `pragma Singleton` declared
- [ ] Owns exactly one data source
- [ ] `property var` for reactive properties (not `property alias`)
- [ ] No visual children (Connections, Timer, etc.) inside QtObject
- [ ] `available` flag set in Component.onCompleted
- [ ] No UI module imports
- [ ] All compositor actions go through named functions, not raw `dispatch()`

### Adding a new bar widget

- [ ] File in `modules/bar/<Widget>.qml`
- [ ] Imports service it needs (`import "../../services" as Services`)
- [ ] Binds to service property reactively (no local state)
- [ ] No `visible: service.available` guard — let Repeater handle empty models
- [ ] Registered in `modules/bar/qmldir`
- [ ] Added to BarContent.qml with correct anchoring
