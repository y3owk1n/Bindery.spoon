# Bindery.spoon

**Contextual keybinding management for focused workflows** — A Hammerspoon module designed for users who prefer single-window focus over tiling window managers. Perfect for distraction-free computing and application-specific workflows.

> [!NOTE]
> If you like this, please help out with the project instead of just asking for features and fixes. I probably do not
> have extra time to maintain this project as long as it works for me.

## Philosophy

This module is built around a simple principle: **one application, one focus**. If you appreciate clean workspaces without overlapping windows, contextual shortcuts that change based on your current app, and the ability to hide visual clutter automatically, Bindery is designed for your workflow.

Unlike tiling window managers that divide screen real estate, Bindery embraces the single-window paradigm while providing intelligent automation and context-aware shortcuts.

## Features

### App Launcher System

- **Hyper-key app switching** — Lightning-fast application launching with customizable shortcuts
- **Consistent access pattern** — Same modifier + letter combinations across all apps
- **Launch or focus behavior** — Brings existing windows to front or launches new instances

### Contextual Bindings

- **App-specific shortcuts** — Different keybindings activate automatically based on the frontmost application
- **Clean context switching** — Bindings activate/deactivate seamlessly as you switch between apps
- **Conflict-free** — No worry about shortcut collisions between applications

### Focus Enhancement

- **Auto-hide distractions** — Automatically hide all windows except the frontmost
- **Auto-maximize option** — Maximize windows when activated for full-screen focus
- **Toggle controls** — Runtime switching of focus behaviors via hotkeys

### Custom Actions

- **Flexible binding system** — Define any custom actions with modifier + key combinations
- **Menu automation** — Safe menu item selection with error handling
- **Workflow integration** — Perfect for repetitive tasks and application automation

## Installation

### Prerequisites

- [Hammerspoon](https://www.hammerspoon.org/) installed
- Basic Lua knowledge helpful for configuration

### Setup

#### Manual

1. Place `Bindery.spoon` in `~/.hammerspoon/Spoons/`
2. Add to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Bindery")
spoon.Bindery:start()
```

3. Reload Hammerspoon configuration

#### Using [Pack.spoon](https://github.com/y3owk1n/pack.spoon)

```lua
---@type Hs.Pack.PluginSpec
return {
 name = "Bindery",
 url = "https://github.com/y3owk1n/Bindery.spoon.git",
 config = function()
  ---@type Hs.Bindery.Config
  local binderyConfig = {}

  spoon.Bindery:start(binderyConfig)
 end,
}
```

## Configuration

### Basic App Launchers

```lua
spoon.Bindery:start({
 apps = {
  modifier = spoon.Bindery.specialModifiers.hyper, -- Hyper key, you dont have to use this, it's just a convenient export
  bindings = {
   ["Safari"] = "b",
   ["Ghostty"] = "t",
   ["Notes"] = "n",
   ["Mail"] = "m",
   ["WhatsApp"] = "w",
   ["Finder"] = "f",
   ["System Settings"] = "s",
   ["Passwords"] = "p",
  },
 },
})
```

### Focus Enhancement Features

```lua
spoon.Bindery:start({
 watcher = {
  hideAllWindowExceptFront = {
   enabled = true,
   bindings = {
    modifier = spoon.Bindery.specialModifiers.hyper,
    key = "1",
   },
  },
  autoMaximizeWindow = {
   enabled = true,
   bindings = {
    modifier = spoon.Bindery.specialModifiers.hyper,
    key = "2",
   },
  },
 },
})
```

### Custom Global Actions

```lua
spoon.Bindery:start({
 customBindings = {
  spotlightRemap = {
   modifier = spoon.Bindery.specialModifiers.hyper,
   key = "return",
   action = function()
    spoon.Bindery.keyStroke("cmd", "space") -- You can just use the `hs.eventtap.keyStroke` directly, this is just a wrapper that does 0 delay by default.
   end,
  },
  toggleCurrPrevApp = {
   modifier = spoon.Bindery.specialModifiers.hyper,
   key = "l",
   action = function()
    spoon.Bindery.keyStroke({ "cmd" }, "tab")

    hs.timer.doAfter(0.01, function()
     spoon.Bindery.keyStroke({}, "return")
    end)
   end,
  },
  maximizeWindow = {
   modifier = { "ctrl", "shift" },
   key = "m",
   action = function()
    spoon.Bindery.keyStroke({ "fn", "ctrl" }, "f")
   end,
  },
  moveWindow = {
   modifier = { "ctrl", "shift" },
   key = "h",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
   end,
  },
  moveWindowRight = {
   modifier = { "ctrl", "shift" },
   key = "l",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
   end,
  },
  moveWindowBottom = {
   modifier = { "ctrl", "shift" },
   key = "j",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
   end,
  },
  moveWindowTop = {
   modifier = { "ctrl", "shift" },
   key = "k",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
   end,
  },
 },
})
```

### Application-Specific Contextual Bindings

```lua
spoon.Bindery:start({
 contextualBindings = {
  ["Safari"] = {
   {
    modifier = {"cmd", "shift"},
    key = "r",
    action = function()
     spoon.Bindery.safeSelectMenuItem({"Develop", "Enter Responsive Design Mode"})
    end
   },
   {
    modifier = {"cmd", "alt"},
    key = "i",
    action = function()
     spoon.Bindery.keyStroke({"cmd", "alt"}, "i") -- Web Inspector
    end
   }
  },
  ["Finder"] = {
   {
   modifier = { "cmd" },
   key = "q",
   action = function()
    bindery.keyStroke({ "cmd" }, "w")
   end,
   },
  },
 }
})
```

### Complete Configuration Example

```lua
spoon.Bindery:start({
 logLevel = "info",

 -- App launchers with hyper key
 apps = {
  modifier = spoon.Bindery.specialModifiers.hyper, -- Hyper key, you dont have to use this, it's just a convenient export
  bindings = {
   ["Safari"] = "b",
   ["Ghostty"] = "t",
   ["Notes"] = "n",
   ["Mail"] = "m",
   ["WhatsApp"] = "w",
   ["Finder"] = "f",
   ["System Settings"] = "s",
   ["Passwords"] = "p",
  },
 },

 -- Global custom actions
 customBindings = {
  spotlightRemap = {
   modifier = spoon.Bindery.specialModifiers.hyper,
   key = "return",
   action = function()
    spoon.Bindery.keyStroke("cmd", "space") -- You can just use the `hs.eventtap.keyStroke` directly, this is just a wrapper that does 0 delay by default.
   end,
  },
  toggleCurrPrevApp = {
   modifier = spoon.Bindery.specialModifiers.hyper,
   key = "l",
   action = function()
    spoon.Bindery.keyStroke({ "cmd" }, "tab")

    hs.timer.doAfter(0.01, function()
     spoon.Bindery.keyStroke({}, "return")
    end)
   end,
  },
  maximizeWindow = {
   modifier = { "ctrl", "shift" },
   key = "m",
   action = function()
    spoon.Bindery.keyStroke({ "fn", "ctrl" }, "f")
   end,
  },
  moveWindow = {
   modifier = { "ctrl", "shift" },
   key = "h",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Left" })
   end,
  },
  moveWindowRight = {
   modifier = { "ctrl", "shift" },
   key = "l",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Right" })
   end,
  },
  moveWindowBottom = {
   modifier = { "ctrl", "shift" },
   key = "j",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Bottom" })
   end,
  },
  moveWindowTop = {
   modifier = { "ctrl", "shift" },
   key = "k",
   action = function()
    spoon.Bindery.safeSelectMenuItem({ "Window", "Move & Resize", "Top" })
   end,
  },
 },

 -- App-specific contextual shortcuts
 contextualBindings = {
  ["Safari"] = {
   {
    modifier = {"cmd", "shift"},
    key = "r",
    action = function()
     spoon.Bindery.safeSelectMenuItem({"Develop", "Enter Responsive Design Mode"})
    end
   },
   {
    modifier = {"cmd", "alt"},
    key = "i",
    action = function()
     spoon.Bindery.keyStroke({"cmd", "alt"}, "i") -- Web Inspector
    end
   }
  },
  ["Finder"] = {
   {
   modifier = { "cmd" },
   key = "q",
   action = function()
    bindery.keyStroke({ "cmd" }, "w")
   end,
   },
  },
 }
 },

 -- Focus and window management
 watcher = {
  hideAllWindowExceptFront = {
   enabled = true,
   bindings = {
    modifier = spoon.Bindery.specialModifiers.hyper,
    key = "1",
   },
  },
  autoMaximizeWindow = {
   enabled = true,
   bindings = {
    modifier = spoon.Bindery.specialModifiers.hyper,
    key = "2",
   },
  },
 },
})
```

## Usage Patterns

### Single-Window Focus Workflow

1. **Launch/Switch**: Use hyper key + letter to instantly switch between applications
2. **Context Work**: Shortcuts automatically adapt to the current application
3. **Clean Desktop**: Enable auto-hide to maintain visual focus on current work
4. **Toggle Behaviors**: Use runtime toggles to adjust focus settings as needed

### Application-Specific Workflows

Define shortcuts that only activate when specific applications are frontmost:

- Development shortcuts in your code editor
- Browser-specific developer tools access
- Design application-specific actions
- Communication app quick actions

### Focus States

- **Default**: Normal multi-window behavior
- **Hide Mode**: Only current window visible, others hidden
- **Maximize Mode**: Current window maximized for full-screen focus
- **Combined**: Hide + maximize for ultimate focus

## API Reference

### Available Functions

```lua
-- Special modifier keys
spoon.Bindery.specialModifiers.hyper
spoon.Bindery.specialModifiers.meh

-- Key stroke utility
spoon.Bindery.keyStroke(modifiers, key, delay, application)

-- Safe menu item selection with error handling
spoon.Bindery.safeSelectMenuItem({"Menu", "Submenu", "Item"})
```

### Configuration Structure

```lua
{
    logLevel = "warning",                    -- Log verbosity
    apps = {                                -- App launcher configuration
        modifier = {...},                    -- Modifier keys for app switching
        bindings = {...}                     -- App name to key mappings
    },
    customBindings = {                       -- Global custom actions
        [name] = {
            modifier = {...},
            key = "...",
            action = function() ... end
        }
    },
    contextualBindings = {                   -- App-specific shortcuts
        [appName] = {
            { modifier = {...}, key = "...", action = function() ... end }
        }
    },
    watcher = {                             -- Window management behaviors
        hideAllWindowExceptFront = {
            enabled = true/false,
            bindings = { modifier = {...}, key = "..." }
        },
        autoMaximizeWindow = {
            enabled = true/false,
            bindings = { modifier = {...}, key = "..." }
        }
    }
}
```

## Who This Is For

Bindery is designed for users who:

- Prefer single-window focus over tiling window managers
- Want context-aware shortcuts that change based on the current application
- Appreciate clean, distraction-free workspaces
- Need consistent app-switching patterns
- Value automation for repetitive tasks
- Work better with maximum screen real estate for individual applications

## Troubleshooting

### Menu Item Paths

For `safeSelectMenuItem`, use the exact menu hierarchy as it appears in the application's menu bar.

### Permission Issues

Ensure Hammerspoon has Accessibility permissions in System Preferences > Security & Privacy.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details.
