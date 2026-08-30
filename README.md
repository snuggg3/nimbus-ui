# TsUI — Game‑agnostic Roblox UI library

**TsUI** is a lightweight, visual‑language‑inspired UI library for Roblox written in Luau.  
Place it as a `ModuleScript` (e.g. in `ReplicatedStorage`) and require it from a `LocalScript`:

```lua
local TsUI = require(game:GetService("ReplicatedStorage"):WaitForChild("TsUI"))
local Window = TsUI:CreateWindow({ Title = "My UI", Size = UDim2.fromOffset(700, 500) })
local Tab = Window:CreateTab({ Name = "Main" })
Tab:CreateButton({ Name = "Example", Callback = function() print("Clicked") end })
```

The library is **non‑strict** and provides a full suite of built‑in components (Button, Toggle, Slider, Dropdown, Input, Keybind, Label, Divider, Section), a flexible state system, theming, and a notification system — all game‑agnostic and usable in any Roblox experience.

---

## Table of Contents

1. [Library Overview](#library-overview)
2. [Features](#features)
3. [Installation / Setup](#installation--setup)
4. [Basic Usage](#basic-usage)
5. [UI Components](#ui-components)
   - [Button](#button)
   - [Toggle](#toggle)
   - [Slider](#slider)
   - [Dropdown](#dropdown)
   - [Input](#input)
   - [Keybind](#keybind)
   - [Label](#label)
   - [Divider](#divider)
   - [Section](#section)
6. [Configuration & Properties](#configuration--properties)
7. [Events, Callbacks & State](#events--callbacks--state)
8. [Advanced Usage](#advanced-usage)
9. [Complete Examples](#complete-examples)
10. [API Reference](#api-reference)
11. [Common Mistakes / Troubleshooting](#common-mistakes--troubleshooting)
12. [Credits / Disclaimer](#credits--disclaimer)

---

## 1. Library Overview

TsUI follows a **container‑component** architecture:

- **`Library`** (returned by `require`) is the global entry point. It holds the theme, state, and global methods (`CreateWindow`, `Notify`, `Get`, `Set`, `SerializeConfig`, etc.).
- **`Window`** represents a movable, resizable, closable window. It contains tabs and a content area.
- **`Tab`** is a page inside a window. Tabs host the UI components.
- **`Section`** is a container with a header and padded content area. Components can be placed directly inside a `Section`.
- **Components** (`Button`, `Toggle`, `Slider`, etc.) are builders that create a row (or standalone element) inside a tab's content or a section's content.

Everything is **client‑only** — the library asserts it is running from a `LocalScript` and accesses `Players.LocalPlayer.PlayerGui`. Using it on the server will error.

---

## 2. Features

| Category | What it does |
|---|---|
| **Theming** | Global `Theme` table with colors, fonts, corner radius, and animation info. Can be overridden per‑session via `Library:SetTheme()`. |
| **State** | `State.register/set` for ID‑based shared state, plus `Library:Get/Set/Toggle/OnChanged`. Values can be fired to callbacks. |
| **Components** | 9 ready‑to‑use UI elements: Button, Toggle, Slider, Dropdown, Input, Keybind, Label, Divider, Section. |
| **Window management** | Create, close, minimize, drag, toggle visibility, select tabs, set title. |
| **Notifications** | `Library:Notify()` shows transient toast messages with progress bar, auto‑dismiss, and click‑to‑dismiss. |
| **Config persistence** | `Library:SaveConfig/`LoadConfig` persists `State` values to `File` via `writefile`/`readfile` (executor‑enabled environments only). |
| **Component registration** | `Library:RegisterComponent(name, builder)` lets you add custom components accessible as `Tab:CreateMyComponent(...)`. |
| **Stateful handles** | Each component returns a handle with `Get()`, `Set()`, `SetName()`, and `Destroy()`. |

---

## 3. Installation / Setup

1. **Add the ModuleScript**  
   Create a `ModuleScript` named `TsUI` (or any name you prefer) and place it in `ReplicatedStorage` (or anywhere accessible from the client).

2. **Require it from a `LocalScript`**  
   ```lua
   local TsUI = require(game:GetService("ReplicatedStorage"):WaitForChild("TsUI"))
   ```

3. **Create a window**  
   ```lua
   local Window = TsUI:CreateWindow({ Title = "My UI", Size = UDim2.fromOffset(700, 500) })
   ```

4. **Start building UI**  
   Use `Window:CreateTab()`, components, or `Library:Notify()`.

**Note:** The library requires an executor that exposes `writefile`, `readfile`, `isfile`, `isfolder`, and `makefolder` for config persistence (`SaveConfig`/`LoadConfig`). In Roblox Studio/Player these functions exist natively; in some exploit environments they may be stubbed or missing — in that case `SaveConfig`/`LoadConfig` will return `false`.

---

## 4. Basic Usage

### Creating a window

```lua
local Window = TsUI:CreateWindow({
	Title = "My Cool UI",
	Size = UDim2.fromOffset(800, 600),
	Position = UDim2.fromScale(0.5, 0.5), -- center
	ToggleKey = Enum.KeyCode.LeftShift, -- toggle window with Shift
	CloseBehavior = "Destroy", -- or "Hide"
})
```

### Creating a tab

```lua
local tab = Window:CreateTab({ Name = "Main" })
```

### Adding components

Each component is added via the tab (or a section):

```lua
tab:CreateButton({ Name = "Click me", Callback = function() print("Button clicked") end })
tab:CreateToggle({ Id = "enabled", Name = "Enabled", Default = false, Callback = function(v) print("Toggle:", v) end })
tab:CreateSlider({ Name = "Volume", Min = 0, Max = 100, Step = 1, Default = 50, Suffix = "%", Callback = function(v) print("Volume:", v) end })
tab:CreateDropdown({ Name = "Pick", Options = {"A","B","C"}, Default = "A", Callback = function(v) print("Selected:", v) end })
tab:CreateInput({ Name = "Name", Placeholder = "Enter name", Default = "Guest", Width = 200, Callback = function(t) print("Input:", t) end })
tab:CreateKeybind({ Name = "Fly", Default = Enum.KeyCode.F, OnChanged = function(k) print("Keybind changed:", k) end })
tab:CreateLabel({ Text = "A label", SubText = "some subtext" })
tab:CreateDivider({ Name = "Settings" })
tab:CreateSection({ Name = "My Section" })
```

### Window events

```lua
-- Switch tab
Window:SelectTab("Main")

-- Minimize / restore
Window:SetMinimized(true)   -- collapse to small height
Window:SetMinimized(false)  -- restore

-- Toggle visibility
Window:SetVisible(false)
Window:Toggle()             -- flip current visibility

-- Destroy
Window:Destroy()
```

### Global state

```lua
-- Read/write shared values
local health = Library:Get("Health")      -- returns the current value (or nil)
Library:Set("Health", 0, true)            -- set and fire callback

-- Toggle a boolean
Library:Toggle("SoundEnabled", true)      -- flips value and fires

-- Listen for changes
Library:OnChanged("Health", function(v)
	print("Health changed to", v)
end)
```

### Serializing / applying config

```lua
local config = Library:SerializeConfig() -- { Health = 0, ... }
Library:ApplyConfig({ Health = 100 })    -- sets values and fires callbacks
```

### Saving / loading config (client‑only)

```lua
Library:SetConfigFolder("MyGame_UIConfigs")
Library:SaveConfig("my_session")   -- saves to TsUI_Configs/my_session.json
Library:LoadConfig("my_session")   -- loads and applies
```

### Notifications

```lua
Library:Notify({
	Title = "Success",
	Message = "Your change has been saved",
	Type = "Success",
	Duration = 5,         -- seconds (minimum 1)
	Callback = function() print("User dismissed") end
})
```

---

## 5. UI Components

Each component returns a **handle** with the following shared API:

- `handle:Get()` – returns the current value
- `handle:Set(value, fireCallback?)` – sets the value; if `fireCallback` is not `false`, the `Callback` (or `OnChanged` for keybind) fires
- `handle:SetName(name)` – changes the displayed name/text
- `handle:Destroy()` – cleanly destroys the GUI elements and disconnects connections

### 5.1 Button

**Description:** A clickable button with optional primary/secondary style, hover/pressed states, and disabled styling.

**Constructor:** `tab:CreateButton(options)`

**Parameters (`OptionButton`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Name` | `string?` | `"Button"` | Button text |
| `Callback` | `() -> ()?` | `nil` | Function called on click |
| `Style` | `("Primary" \| "Secondary")?` | `"Primary"` | Colorscheme |
| `Disabled` | `boolean?` | `false` | Disables interaction |

**Properties / Methods on handle:**

| Method | Return | Description |
|---|---|---|
| `:Get()` | `()` | Always returns `nil` (buttons have no value) |
| `:SetDisabled(value)` | `()` | Enable/disable the button |
| `:SetName(name)` | `()` | Change the button’s label |
| `:Click()` | `()` | Programmatically trigger the click (respects disabled state) |
| `:Destroy()` | `()` | Standard destroy |

**Default styling:** Primary uses `Theme.Primary` / `Theme.PrimaryHover` / `Theme.PrimaryPressed`; Secondary uses `Theme.Content` / `Theme.Hover` / `Theme.Border` with a stroke.

**Example:**

```lua
tab:CreateButton({
	Name = "Submit",
	Style = "Secondary",
	Callback = function()
		print("Submitted!")
	end
})
```

---

### 5.2 Toggle

**Description:** A toggle switch with a track and knob. Can be identified by an `Id` for shared state.

**Constructor:** `tab:CreateToggle(options)`

**Parameters (`OptionToggle`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Id` | `string?` | `nil` | If provided, shares state across components with the same Id |
| `Name` | `string?` | `"Toggle"` | Label text |
| `Default` | `boolean?` | `nil` (defaults to `false`) | Initial state |
| `Callback` | `(boolean) -> ()?` | `nil` | Fires when the user changes the toggle |

**Handle API:**

| Method | Return | Description |
|---|---|---|
| `:Get()` | `boolean` | Current boolean value |
| `:Set(value, fireCallback?)` | `()` | Set the boolean; `fireCallback` defaults to `true` |
| `:SetName(name)` | `()` | Change the label |
| `:Destroy()` | `()` | Standard destroy |

**Shared‑state behavior:** If `Id` is provided, the toggle participates in `State.register`. All toggles with the same `Id` share the same value; only the most recently constructed instance visually reflects programmatic changes via `Library:Set` until the earlier ones are destroyed and their `unregister` clears.

**Example:**

```lua
tab:CreateToggle({
	Name = "Enabled",
	Id = "example.enabled",   -- shared across the experience
	Default = false,
	Callback = function(value)
		print("Enabled:", value)
	end
})
```

---

### 5.3 Slider

**Description:** A horizontal slider with a fill track and draggable knob. The user can click‑drag the knob or use mouse‑enter to start dragging.

**Constructor:** `tab:CreateSlider(options)`

**Parameters (`OptionSlider`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Id` | `string?` | `nil` | Shared‑state identifier |
| `Name` | `string?` | `"Slider"` | Label text |
| `Min` | `number?` | `0` | Minimum value |
| `Max` | `number?` | `100` | Maximum value |
| `Step` | `number?` | `1` | Granularity; if `max < min` they are swapped |
| `Default` | `number?` | `nil` (defaults to `Min`) | Initial value |
| `Suffix` | `string?` | `""` | Shown after the value in the label |
| `Callback` | `(number) -> ()?` | `nil` | Fires when value changes (user drag or programmatic set) |

**Handle API:** Same as Toggle (`Get`, `Set`, `SetName`, `Destroy`). `Get()` returns `number`.

**Rounding:** Values are snapped to the nearest step via `roundToStep`, then clamped to `[Min, Max]`. Display uses `formatNumber` (`"%g"` format).

**Example:**

```lua
tab:CreateSlider({
	Name = "Volume",
	Min = 0,
	Max = 10,
	Step = 0.1,
	Default = 5,
	Suffix = "x",
	Callback = function(value)
		print("Volume set to", value, "x")
	end
})
```

---

### 5.4 Dropdown

**Description:** A button that opens a scrollable list of options. Selecting an option closes the list and updates the displayed value.

**Constructor:** `tab:CreateDropdown(options)`

**Parameters (`OptionDropdown`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Id` | `string?` | `nil` | Shared‑state identifier |
| `Name` | `string?` | `"Dropdown"` | Label text |
| `Options` | `{ string }?` | `nil` (must provide) | List of option strings |
| `Default` | `string?` | First element of `Options` (if any) | Initially selected value |
| `Callback` | `(string\?) -> ()?` | `nil` | Fires when selection changes; receives `nil` if no selection |

**Handle API:** Same structure. `Get()` returns `string?` (the selected value, or `nil` if none).

**Key behaviors:**

- If `Default` is not provided, the first option is selected.
- Clicking the label toggles the list open/close.
- The list opens **upward** if there’s insufficient space below; otherwise downward.
- Only one dropdown can be “active” at a time; opening a new one closes the previous.
- `SetOptions(newOptions, keepSelection?)` on the handle can dynamically replace the option list. If `keepSelection` is false (default) and the current selection is no longer in the list, selection is cleared.

**Example:**

```lua
local dropdown = tab:CreateDropdown({
	Name = "Theme",
	Options = {"Light", "Dark", "System"},
	Default = "Light",
	Callback = function(choice)
		print("Selected theme:", choice)
	end
})

-- Later, change options and keep the selection if possible:
dropdown:SetOptions({"Light", "Dark"}, true) -- keeps "Light" if possible
```

---

### 5.5 Input

**Description:** A text box inside a row. The value updates when the user focuses out (presses Esc or clicks away). Can be identified by an `Id`.

**Constructor:** `tab:CreateInput(options)`

**Parameters (`OptionInput`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Id` | `string?` | `nil` | Shared‑state identifier |
| `Name` | `string?` | `"Input"` | Label text |
| `Placeholder` | `string?` | `""` | Placeholder text inside the box |
| `Default` | `string?` | `""` | Initial text |
| `Width` | `number?` | `150` | Width of the input box (pixels) |
| `Callback` | `(string) -> ()?` | `nil` | Fires when the user focuses out with a non‑empty value |

**Handle API:** `Get()` returns `string`. `Set(value, fireCallback?)` updates the box text.

**Example:**

```lua
tab:CreateInput({
	Name = "Player name",
	Placeholder = "Type your name",
	Default = "Guest",
	Width = 250,
	Callback = function(text)
		print("Submitted name:", text)
	end
})
```

---

### 5.6 Keybind

**Description:** A button that displays the currently bound key. Clicking it opens a listener so the player can press a new key. Includes an `OnChanged` callback that fires when the key is rebound, and a regular `Callback` that fires when the bound key is pressed in‑game.

**Constructor:** `tab:CreateKeybind(options)`

**Parameters (`OptionKeybind`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Id` | `string?` | `nil` | Shared‑state identifier |
| `Name` | `string?` | `"Keybind"` | Label text |
| `Default` | `Enum.KeyCode?` | `nil` (displays “None”) | Initially bound key |
| `Callback` | `(Enum.KeyCode\?) -> ()?` | `nil` | Fires when the bound key is pressed (while not rebinding) |
| `OnChanged` | `(Enum.KeyCode\?) -> ()?` | `nil` | Fires when the key is rebound via the UI |

**Handle API:** `Get()` returns `Enum.KeyCode?`. `Set(value, fireCallback?)` updates the displayed key.

**Rebinding flow:**

1. Click the key button → text shows `...` and a listener waits for a key press.
2. Press any key → the button displays that key (or `Escape` to cancel and restore the previous key).
3. `OnChanged` fires with the new key (or the restored key if cancelled).
4. The regular `Callback` fires whenever that key is pressed later (outside of rebinding).

**Important:** If a `TextBox` has focus, key presses are ignored so the library doesn’t interfere with typing.

**Example:**

```lua
tab:CreateKeybind({
	Name = "Fly toggle",
	Default = Enum.KeyCode.F,
	OnChanged = function(newKey)
		print("New keybind:", newKey)
	end,
	Callback = function(key)
		print("Fly key pressed:", key)
	end
})
```

---

### 5.7 Label

**Description:** A multi‑line label with optional subtext. The label automatically sizes to its content.

**Constructor:** `tab:CreateLabel(options)`

**Parameters (`OptionLabel`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Text` | `string?` | `"Label"` | Main text |
| `SubText` | `string?` | `""` | Smaller secondary text (shown if non‑empty) |

**Handle API:**

| Method | Return | Description |
|---|---|---|
| `:SetText(value)` | `()` | Change the main text |
| `:SetSubText(value)` | `()` | Change the subtext; hides if empty |
| `:Destroy()` | `()` | Standard destroy |

**Example:**

```lua
tab:CreateLabel({
	Text = "This is a label",
	SubText = "optional subline"
})
```

---

### 5.8 Divider

**Description:** A horizontal line optionally with a centered header name.

**Constructor:** `tab:CreateDivider(options)`

**Parameters (`OptionDivider`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Name` | `string?` | `nil` | If provided, a header label appears centered on the line |

**Handle API:** `Destroy()` only.

**Example:**

```lua
tab:CreateDivider({ Name = "Settings" }) -- line with "SETTINGS" centered
```

---

### 5.9 Section

**Description:** A container with a header and automatically‑sized content area. Components can be placed inside a section via the tab/section’s internal content, or more commonly by using the section as a visual group. Sections are themselves components registered with the library, so they can be added to tabs.

**Constructor:** `tab:CreateSection(options)` (or `Window:CreateSection`)

**Parameters (`OptionSection`):**

| Param | Type | Default | Description |
|---|---|---|---|
| `Name` | `string?` | `nil` | Header text; if omitted, no header and slightly smaller height |

**Handle API (inherits `Container`):**

| Method | Description |
|---|---|
| `:SetName(name)` | Updates the header text |
| `:Destroy()` | Destroys the section and all its child components |

Sections have an internal `_content` frame where you can parent additional UI, but the typical pattern is to add components through the tab, which automatically parent to the section if one is active. The section also provides `Container`-style `Destroy` that cleans its internal trove.

**Example:**

```lua
local section = tab:CreateSection({ Name = "Advanced" })
-- Components added after this will be parented inside the section's content area.
-- Or manually:
section._content:AddChild(someOtherGui) -- not typically needed
```

---

## 6. Configuration & Properties

### Theme

The `Theme` table is globally available and used as the default for all new components. It can be overridden at any time:

```lua
Library:SetTheme({
	Primary = Color3.fromRGB(255, 0, 0),
	PrimaryHover = Color3.fromRGB(200, 0, 0),
	Font = Enum.Font.Fantasy,
	CornerRadius = 6,
	FastAnimation = TweenInfo.new(0.08),
})
```

Only **newly created** components pick up the new theme; existing elements retain their original styling.

### Window options (`CreateWindow`)

| Option | Type | Default | Description |
|---|---|---|---|
| `Title` | `string` | `"Window"` | Title bar text |
| `Size` | `UDim2` | `UDim2.fromOffset(680, 480)` | Initial window size |
| `Position` | `UDim2?` | `center` (0.5, 0.5) | Initial position |
| `LogoText` | `string?` | `"TS"` | Text inside the logo frame |
| `ToggleKey` | `Enum.KeyCode?` | `nil` | Press this key to toggle window visibility |
| `Scale` | `number?` | `nil` | UIScale factor applied to the main frame |
| `CloseBehavior` | `"Hide"` / `"Destroy"` | `"Hide"` | What the close button does: hide the GUI or destroy the window |

### Tab options (`CreateTab`)

| Option | Type | Default |
|---|---|---|
| `Name` | `string?` | generated from order (first tab unnamed, etc.) |

### Component options (shared defaults)

| Component | Default `Name` | Other notable defaults |
|---|---|---|
| `Button` | `"Button"` | `Style = "Primary"` |
| `Toggle` | `"Toggle"` | `Default = false` |
| `Slider` | `"Slider"` | `Min = 0`, `Max = 100`, `Step = 1` |
| `Dropdown` | `"Dropdown"` | `Options` required |
| `Input` | `"Input"` | `Width = 150` |
| `Keybind` | `"Keybind"` | `Default = nil` (“None”) |
| `Label` | `"Label"` | — |
| `Divider` | `nil` (no name) | — |
| `Section` | `nil` (no header) | — |

### State `Id` sharing

Components that accept an `Id` (`Toggle`, `Slider`, `Dropdown`, `Input`, `Keybind`) register their value under that string in the global `State.entries` table. When multiple components share an `Id`:

- They all read/write the **same** value.
- `Library:Set(id, value)` and `Library:Toggle(id)` affect the shared value.
- Only the **most recently constructed** instance visually reflects programmatic changes via its internal `apply` closure, because `State.register` overwrites `entry.apply`. To avoid surprises, use unique `Id`s or destroy components in reverse order of creation if you need to re‑register.

### Config persistence (`SaveConfig`/`LoadConfig`)

- Enabled only if `writefile`/`readfile`/`isfile`/`isfolder`/`makefolder` are functions (true in Roblox Studio/Player).
- Config folder defaults to `"TsUI_Configs"` under the Roblox place file.
- `SetConfigFolder(folder)` changes the base folder name.
- Saved configs are plain JSON of the `State.entries` table, with `EnumKeyCode` values serialized to their `.Name` string.
- `LoadConfig` decodes the JSON and calls `Library:ApplyConfig`, which fires all callbacks.

---

## 7. Events, Callbacks & State

### Callback signatures

| Component | Callback parameter(s) | When fires |
|---|---|---|
| `Button` | `()` | On mouse click (if not disabled) |
| `Toggle` | `boolean` | When the user toggles the switch |
| `Slider` | `number` | When the user releases the knob **or** when `Set(value, true)` is called programmatically |
| `Dropdown` | `string?` | When the user selects a new option; `nil` if selection cleared |
| `Input` | `string` | When the user focuses out and the box is non‑empty |
| `Keybind` | `Enum.KeyCode?` (Callback) | When the bound key is pressed in‑game (not during rebinding) |
| `Keybind` | `Enum.KeyCode?` (OnChanged) | When the key is rebound via the UI (or cancelled) |
| `Label` | — | N/A (static) |
| `Divider` | — | N/A |
| `Section` | — | N/A |

### State system (`State`)

- `State.register(id, defaultValue, apply)` – creates or retrieves a shared entry.
- `State.set(id, value, fireCallback)` – updates the value and fires `entry.apply(value, fireCallback)` plus `entry.changed:Fire(value)`.
- `Library:Get(id)` – returns the current value (fixed bug: now returns falsy values correctly).
- `Library:Set(id, value, fireCallback?)` – sets the value; `fireCallback` defaults to `true`; returns `true`.
- `Library:Toggle(id, fireCallback?)` – flips the boolean value; returns `true` if the entry existed and was boolean, else `false`.
- `Library:OnChanged(id, callback)` – returns a `RBXScriptConnection` that fires when `Library:Set` or `Library:Toggle` is called for that `id`.
- `Library:SerializeConfig()` / `Library:ApplyConfig(config)` – convert the state table to/from a plain JSON‑compatible table.

### `bindState` helper (internal)

Each component uses `bindState(options, defaultValue, apply)` to create a local `bound` table plus a `Signal` (`changed`). The `bound` object has:

- `bound.get()` → current value
- `bound.set(value, fireCallback?)` → updates `bound.value` and fires `entry.apply` / `entry.changed`
- `bound.unregister()` – if the component had an `Id`, removes its `apply` from the shared entry (cleanup on destroy).

---

## 8. Advanced Usage

### Custom component registration

```lua
TsUI:RegisterComponent("MyComponent", function(container, options)
	-- container is a Container instance (has _content, _trove, Destroy)
	-- build your UI using container._content, make(), addList(), etc.
	-- return a handle with Get/Set/Destroy as needed
end)
```

After registration, the component is available as `Tab:CreateMyComponent(options)` or `Section:CreateMyComponent(options)`.

### Programmatic value updates

```lua
-- Set a toggle from elsewhere
Library:Set("MyToggle", true, true) -- third arg fires callback

-- Or via the handle
local toggle = tab:CreateToggle({ Name = "My Toggle", Id = "mytoggle" })
toggle:Set(true, false) -- set without firing callback this time
```

### Minimizing / restoring windows

```lua
Window:SetMinimized(true)   -- collapses to 44px height
Window:SetMinimized(false)  -- restores to original size
```

### Dragging the window

Drag by holding the **title bar** (the colored bar at the top). The window follows the mouse. Press `ToggleKey` (if set) to auto‑hide/show.

### Notification stacking & limits

- Notifications are stacked in a vertical `Frame` inside a global `ScreenGui`.
- A maximum of **6** toasts are kept; when a 7th appears, the oldest is automatically dismissed (its callback fires if set).
- Each toast has a progress bar that tween‑fills over its `Duration`. Dismissing early stops the tween.

### Using `Library:Get` with falsy values

The bug fix: `Library:Get(id)` now returns the stored value even when it is `false`, `0`, or `""`. Previously it would return `nil` for any falsy value because of the `entry and entry.value or nil` pattern. Code that relied on the old (incorrect) behavior should be updated to handle the correct return type.

---

## 9. Complete Examples

### 9.1 Minimal window with all components

```lua
local TsUI = require(game:GetService("ReplicatedStorage"):WaitForChild("TsUI"))

local win = TsUI:CreateWindow({
	Title = "All Components",
	Size = UDim2.fromOffset(900, 700),
	ToggleKey = Enum.KeyCode.RightShift,
})

local tab = win:CreateTab({ Name = "Controls" })

-- Button
tab:CreateButton({
	Name = "Say Hello",
	Callback = function()
		print("Hello from the button!")
	end,
	Style = "Secondary",
})

-- Toggle
tab:CreateToggle({
	Name = "Echo",
	Id = "echo_toggle",
	Default = false,
	Callback = function(v)
		print("Echo toggled:", v)
	end,
})

-- Slider
tab:CreateSlider({
	Name = "Speed",
	Min = 0,
	Max = 50,
	Step = 5,
	Default = 25,
	Suffix = " studs/s",
	Callback = function(v)
		print("Speed set to", v)
	end,
})

-- Dropdown
tab:CreateDropdown({
	Name = "Color",
	Options = {"Red", "Green", "Blue"},
	Default = "Red",
	Callback = function(c)
		print("Color selected:", c)
	end,
})

-- Input
tab:CreateInput({
	Name = "Name",
	Placeholder = "Type something",
	Default = "Guest",
	Width = 200,
	Callback = function(t)
		print("Typed:", t),
	end,
})

-- Keybind
tab:CreateKeybind({
	Name = "Toggle UI",
	Default = Enum.KeyCode.LeftShift,
	OnChanged = function(k)
		print("Keybind changed to:", k),
	end,
	Callback = function(k)
		print("Shift pressed in‑game"),
	end,
})

-- Label
tab:CreateLabel({
	Text = "Adjust settings above",
	SubText = "Use the controls to interact",
})

-- Divider
tab:CreateDivider({ Name = "Extra" })

-- Section
tab:CreateSection({ Name = "Settings" })
-- (Components added after a section will be laid out in the section's content area.)
```

### 9.2 Saving / loading UI state

```lua
local TsUI = require(game:GetService("ReplicatedStorage"):WaitForChild("TsUI"))

local win = TsUI:CreateWindow({ Title = "Saves", ToggleKey = Enum.KeyCode.RightShift })

-- Assume we have a toggle and a slider whose values we want to persist
local toggle = win:CreateTab({ Name "Prefs" }):CreateToggle({
	Name = "Notifications",
	Id = "notif_toggle",
	Default = true,
})

local slider = win:CreateTab({ Name "Prefs" }):CreateSlider({
	Name = "Volume",
	Min = 0,
	Max = 100,
	Default = 50,
	Id = "volume_slider",
})

-- Save button (outside UI, e.g., another keybind or command)
local function saveConfig()
	local ok = TsUI:SaveConfig("my_ui_save")
	if ok then
		print("Config saved!")
	else
		warn("Could not save config – this executor may not support writefile.")
	end
end

-- Load button
local function loadConfig()
	local ok = TsUI:LoadConfig("my_ui_save")
	if ok then
		print("Config loaded and applied!")
	else
		warn("Config load failed.")
	end
end
```

### 9.3 Theming at runtime

```lua
-- Change the primary color for all future UI elements
TsUI:SetTheme({
	Primary = Color3.fromRGB(100, 150, 255),
	PrimaryHover = Color3.fromRGB(70, 110, 200),
	PrimaryPressed = Color3.fromRGB(40, 70, 130),
	Font = Enum.Font.GothamBold,
	CornerRadius = 6,
	Animation = TweenInfo.new(0.2),
	FastAnimation = TweenInfo.new(0.1),
})
```

### 9.4 Custom component via registration

```lua
-- Register a "StatusBar" component that shows a colored bar with a text label
TsUI:RegisterComponent("StatusBar", function(container, options)
	local text = options.Text or "Status"
	local color = options.Color or Theme.Primary

	local bar = Instance.new("Frame")
	bar.Name = "StatusBar"
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0
	bar.AutomaticSize = Enum.AutomaticSize.Y
	bar.Parent = container._content

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Font = Theme.FontMedium
	label.TextSize = 14
	label.TextColor3 = Theme.Text
	label.Text = text
	label.Parent = bar

	-- handle destroy
	local handle = {
		Destroy = function()
			bar:Destroy()
		end,
	}
	return handle
end)

-- Usage:
local tab = win:CreateTab({ Name = "Stats" })
local status = tab:CreateStatusBar({ Text = "Online: 42", Color = Color3.fromRGB(0, 255, 0) })
```

---

## 10. API Reference

### `Library` fields/methods

| Name | Parameters | Return | Description |
|---|---|---|---|
| `:CreateWindow(options)` | `OptionWindow` | `WindowHandle` | Creates and returns a window |
| `:Notify(options)` | `OptionNotification` | `nil` | Shows a transient toast |
| `:Get(id)` | `string` | `any` | Reads a stored value (fixed to return falsy values) |
| `:Set(id, value, fireCallback?)` | `string, any, boolean?` | `boolean` | Sets a stored value; fires callback unless `fireCallback == false` |
| `:Toggle(id, fireCallback?)` | `string, boolean?` | `boolean` | Flips a boolean stored value; returns whether entry existed & was boolean |
| `:OnChanged(id, callback)` | `string, (value) -> ()` | `RBXScriptConnection` | Connects to value‑change events |
| `:SerializeConfig()` | – | `{[string]: any}` | Returns a table of all `State.entries` values |
| `:ApplyConfig(config)` | `{[string]: any}` | `nil` | Calls `Library:Set` for each entry; fires callbacks |
| `:SetConfigFolder(folder)` | `string` | `nil` | Changes the base folder for `SaveConfig`/`LoadConfig` |
| `:SaveConfig(name)` | `string` | `boolean` | Saves config to `configFolder/name.json`; returns `false` if executor lacks file API |
| `:LoadConfig(name)` | `string` | `boolean` | Loads and applies config; returns `false` if executor lacks file API or file not found |
| `:SetTheme(overrides)` | `{[string]: any}` | `nil` | Overrides `Theme` tokens for newly created elements |
| `:Destroy()` | – | `nil` | Destroys all windows, cleans notifications, disconnects dropdown watcher |

### `WindowHandle` methods

| Name | Parameters | Return | Description |
|---|---|---|---|
| `:CreateTab(options)` | `OptionTab?` | `TabHandle` | Creates a tab; auto‑selects if first |
| `:SelectTab(target)` | `any` (`TabHandle` or `string`) | `TabHandle?` | Selects a tab by name or reference; `nil` if not found or already selected |
| `:SetVisible(visible)` | `boolean` | `nil` | Sets `gui.Enabled` |
| `:Toggle()` | – | `nil` | Toggles visibility |
| `:SetMinimized(minimized)` | `boolean` | `nil` | Minimize (44px) / restore |
| `:SetTitle(title)` | `string` | `nil` | Changes the window title (also updates GUI name) |
| `:Destroy()` | – | `nil` | Destroys the window and all its tabs |

### `TabHandle` methods (inherits `Container`)

| Name | Parameters | Return | Description |
|---|---|---|---|
| `:Select()` | – | `self` | Programmatically select this tab |
| `:SetName(newName)` | `string` | `nil` | Changes the tab’s displayed name |
| `:Destroy()` | – | `nil` | Removes from window’s tab list; if it was active, selects the first remaining tab |

### Component option types (summary)

- `OptionButton`: `Name`, `Callback`, `Style`, `Disabled`
- `OptionToggle`: `Id`, `Name`, `Default`, `Callback`
- `OptionSlider`: `Id`, `Name`, `Min`, `Max`, `Step`, `Default`, `Suffix`, `Callback`
- `OptionDropdown`: `Id`, `Name`, `Options`, `Default`, `Callback`
- `OptionInput`: `Id`, `Name`, `Placeholder`, `Default`, `Width`, `Callback`
- `OptionKeybind`: `Id`, `Name`, `Default`, `Callback`, `OnChanged`
- `OptionLabel`: `Text`, `SubText`
- `OptionDivider`: `Name`
- `OptionSection`: `Name`
- `OptionWindow`: `Title`, `Size`, `Position`, `LogoText`, `ToggleKey`, `Scale`, `CloseBehavior`
- `OptionNotification`: `Title`, `Message`, `Duration`, `Type`, `Callback`

### `ValueHandle`

```lua
export type ValueHandle = {
	Get: (self: ValueHandle) -> any,
	Set: (self: ValueHandle, value: any, fireCallback: boolean?) -> (),
	SetName: (self: ValueHandle, name: string) -> (),
	Destroy: (self: ValueHandle) -> (),
}
```

Returned by `State.register` entries (accessible via `State.entries[id]`). Not typically used directly; prefer `Library:Get/Set`.

---

## 11. Common Mistakes / Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Players.LocalPlayer is nil` / "TsUI must be used from the client" | Script running on server or `LocalScript` placed inside `Workspace`/`ServerScriptService`. | Put the `LocalScript` inside `StarterPlayerScripts`, `StarterGui`, or the player's `Character`. |
| Components don’t appear / are invisible | `make` parent order or `ClipsDescendants` on parent frames. | Ensure components are parented to `container._content` or a tab’s content area; the library sets `Parent = container._content` internally. |
| Toggle / Slider value always `false` / `0` after `Library:Set` | Using the same `Id` on multiple simultaneously‑visible components; only the last‑registered `apply` takes effect. | Use unique `Id`s per component, or destroy components in reverse order if sharing state. |
| `SaveConfig` returns `false` | The running executor does not expose `writefile`/`readfile` etc. | In Roblox Studio/Player this should work; in exploit environments you may need to enable the globals or use a different persistence method. |
| Dropdown list not opening | `ActiveDropdown` conflict – only one dropdown can be open at a time. Close the existing one before opening another. | Call `dropdown:SetOptions(newOpts)` or click the existing dropdown to close it first. |
| Notification not showing / disappearing immediately | `Duration` set too low (< 1) or the notification stack full (6 max). | Ensure `Duration >= 1`. The stack automatically evicts oldest after 6. |
| Keybind “None” won’t change | `Default` was set to `Enum.KeyCode.None` or nil; nil displays as “None” and pressing a key will replace it. | Set `Default` to `nil` explicitly if you want “None”, or to a real `Enum.KeyCode`. |
| `Library:Get` returns `nil` for a toggle that’s `false` | (Pre‑fixed bug) This was a known issue; the library now returns `false` correctly. Update code that previously checked `if val then ... end` to handle `false` as a valid value. | No action needed – the library is fixed. |
| Window drag not working on some devices | Input type not `MouseButton1` or `Touch`. | The library supports both; ensure no GUI object is stealing the input before the drag connection fires. |
| Theme changes have no effect on existing UI | Theme is read at component creation time; existing elements keep their original styling. | Re‑create the affected components after calling `Library:SetTheme()`, or manually update their properties. |

---

## 12. Credits / Disclaimer

**Credits**  
The TsUI UI library and its accompanying documentation were mostly written with the assistance of AI (deepseek‑harness / Nemotron). The core Luau implementation, Roblox UI patterns, and architectural decisions are based on standard Roblox development practices. All code has been reviewed for correctness against the original source.

**Disclaimer**  
- This library is provided as‑is for educational and hobbyist use in Roblox experiences.  
- It is designed to be **game‑agnostic** and does not depend on any specific game mechanics, though it uses Roblox services (`Players`, `UserInputService`, `TweenService`, `GuiService`, `TextService`, `HttpService`).  
- Config persistence (`SaveConfig`/`LoadConfig`) relies on `writefile`/`readfile`; these functions are **always available in Roblox Studio and the official Player**, but may be stubbed or absent in third‑party executors.  
- The library **asserts client‑only usage**; using it on the server will yield errors.  
- Callbacks and events fire on the client; do not rely on them for authoritative game state — the server should always validate client‑sent data.  
- The author is not responsible for any unintended behavior caused by misconfiguration, executor limitations, or misuse of the library’s API.

---

*End of README*
