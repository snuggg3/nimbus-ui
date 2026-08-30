# Nimbus UI

A clean, lightweight Roblox UI library written in Luau. Inspired by TypeScript's design aesthetic, it provides modern-looking UI components for game interfaces, admin panels, settings menus, and more.

---

## Installation

Paste this one line into a **LocalScript** in `StarterPlayerScripts` or `StarterGui`:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/snuggg3/nimbus-ui/main/src/init.luau"))()
```

That's it — no extra setup needed.

---

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/snuggg3/nimbus-ui/main/src/init.luau"))()

-- Create a window
local Window = Library:CreateWindow({
    Title = "My Script"
})

-- Add a tab
local Tab = Window:CreateTab({
    Name = "Settings"
})

-- Add a section inside the tab
local Section = Tab:CreateSection({
    Name = "General"
})

-- Add a button
Section:CreateButton({
    Name = "Say Hello",
    Callback = function()
        print("Hello!")
    end
})

-- Add a toggle
Section:CreateToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end
})

-- Show a notification
Library:Notify({
    Title = "Loaded",
    Content = "UI ready!",
    Type = "Success",
    Duration = 3
})
```

---

## `loadstring`

### What it does

`loadstring` downloads the library's source code from GitHub and executes it, returning the `Library` object. It must be called inside a **LocalScript** because it creates UI elements that only exist on the client.

### Syntax

```lua
local Library = loadstring(game:HttpGet("URL"))()
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `URL` | string | The raw GitHub URL pointing to `src/init.luau` |

### Return Value

| Value | Type | Description |
|-------|------|-------------|
| `Library` | table | The main library object with all methods for creating UI |

### Notes

- Run this **once** at the top of your script.
- Place it in `StarterPlayerScripts` or `StarterGui`.
- If you want a specific version, replace `main` with a tag or commit hash (e.g. `refs/tags/v1.0.0`).

---

## Library Functions

### `Library:CreateWindow`

Creates a new window.

```lua
local Window = Library:CreateWindow({
    Title = "My Window",          -- Window title
    Size = Vector2.new(580, 460), -- Width x Height (default: 580x460)
    Position = UDim2.new(0.5, 0, 0.5, 0), -- Screen position (default: center)
    MinSize = Vector2.new(400, 300) -- Minimum window size (default: 400x300)
})
```

**Returns:** `Window`

---

### `Library:Notify`

Shows a notification popup in the top-right corner.

```lua
Library:Notify({
    Title = "Title",          -- Notification title
    Content = "Message here",  -- Notification body text
    Duration = 5,             -- Seconds before auto-dismiss (0 = manual only)
    Type = "Info"             -- "Info" | "Success" | "Warning" | "Error"
})
```

**Returns:** `Notification`

---

### `Library:Destroy`

Removes all UI created by the library and cleans up all event connections.

```lua
Library:Destroy()
```

---

## Window Functions

### `Window:CreateTab`

Adds a tab to the window.

```lua
local Tab = Window:CreateTab({
    Name = "Tab Name"
})
```

**Returns:** `Tab`

---

### `Window:SetTitle`

Changes the window title at any time.

```lua
Window:SetTitle("New Title")
```

---

### `Window:Destroy`

Closes and destroys the window and all its contents.

```lua
Window:Destroy()
```

---

## Tab Functions

### `Tab:CreateSection`

Adds a section inside the tab. Sections group related elements together.

```lua
local Section = Tab:CreateSection({
    Name = "Section Title"
})
```

**Returns:** `Section`

---

## Section Functions

All section functions return the created component object so you can store a reference for later use.

### `Section:CreateButton`

A clickable button.

```lua
Section:CreateButton({
    Name = "Click Me",
    Callback = function()
        print("Button clicked")
    end
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `Button:SetText(text)` | Changes the button text |
| `Button:SetCallback(fn)` | Sets a new callback |
| `Button:SetEnabled(bool)` | Enables or disables the button |
| `Button:Destroy()` | Removes the button |

---

### `Section:CreateToggle`

An on/off switch.

```lua
Section:CreateToggle({
    Name = "Feature Toggle",
    Default = false,          -- Initial value
    Callback = function(value) -- boolean
        print("Value:", value)
    end
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `Toggle:GetValue()` | Returns current `boolean` value |
| `Toggle:SetValue(bool)` | Sets the toggle state |
| `Toggle:SetCallback(fn)` | Sets a new callback |
| `Toggle:SetEnabled(bool)` | Enables or disables the toggle |
| `Toggle:Destroy()` | Removes the toggle |

---

### `Section:CreateSlider`

A draggable number slider.

```lua
Section:CreateSlider({
    Name = "Volume",
    Min = 0,               -- Minimum value
    Max = 100,             -- Maximum value
    Default = 50,          -- Starting value
    Increment = 1,         -- Step size (use 0.1 for decimals)
    Suffix = "%",          -- Optional text appended to the value label
    Callback = function(value) -- number
        print("Volume:", value)
    end
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `Slider:GetValue()` | Returns current number value |
| `Slider:SetValue(number)` | Sets the slider position |
| `Slider:SetMinMax(min, max)` | Updates min and max |
| `Slider:SetCallback(fn)` | Sets a new callback |
| `Slider:SetEnabled(bool)` | Enables or disables the slider |
| `Slider:Destroy()` | Removes the slider |

---

### `Section:CreateDropdown`

A single-select dropdown menu.

```lua
Section:CreateDropdown({
    Name = "Difficulty",
    Options = {"Easy", "Normal", "Hard"},
    Default = "Normal",         -- Initial selection (optional)
    Placeholder = "Select...", -- Text shown when nothing is selected
    Callback = function(value)   -- string
        print("Selected:", value)
    end
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `Dropdown:GetValue()` | Returns current selection as a `string` |
| `Dropdown:SetValue(value)` | Programmatically selects an option |
| `Dropdown:SetOptions({options})` | Replaces the option list |
| `Dropdown:SetCallback(fn)` | Sets a new callback |
| `Dropdown:SetEnabled(bool)` | Enables or disables the dropdown |
| `Dropdown:Destroy()` | Removes the dropdown |

---

### `Section:CreateMultiDropdown`

A multi-select dropdown where you can pick multiple options.

```lua
Section:CreateMultiDropdown({
    Name = "Permissions",
    Options = {"Admin", "Moderator", "VIP", "Member"},
    Default = {"Member"},          -- Table of pre-selected options
    Placeholder = "Select...",      -- Placeholder text
    Callback = function(values)      -- Table: {"Option1", "Option2"}
        print("Selected:", table.concat(values, ", "))
    end
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `MultiDropdown:GetValue()` | Returns table of selected options |
| `MultiDropdown:SetValue({options})` | Sets selected options |
| `MultiDropdown:SetOptions({options})` | Replaces the option list |
| `MultiDropdown:SetCallback(fn)` | Sets a new callback |
| `MultiDropdown:SetEnabled(bool)` | Enables or disables the dropdown |
| `MultiDropdown:Destroy()` | Removes the dropdown |

---

### `Section:CreateTextbox`

A text input field.

```lua
Section:CreateTextbox({
    Name = "Username",
    Placeholder = "Enter name...",
    Default = "",                    -- Initial text (optional)
    Callback = function(value)       -- string
        print("Input:", value)
    end
})
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `Name` | string | Label shown above the input |
| `Placeholder` | string | Gray text when empty (default: "Enter text...") |
| `Default` | string | Pre-filled text |
| `Numeric` | boolean | If `true`, only allows numbers (default: `false`) |
| `Finished` | boolean | If `true`, fires callback only on Enter or blur (default: `false`) |
| `ClearTextOnFocus` | boolean | Clears text on click (default: `false`) |
| `Callback` | function | Called with the text value |

**Methods:**

| Method | Description |
|--------|-------------|
| `Textbox:GetValue()` | Returns current text as `string` |
| `Textbox:SetValue(text)` | Sets the input text |
| `Textbox:SetPlaceholder(text)` | Changes placeholder text |
| `Textbox:Focus()` | Programmatically focuses the input |
| `Textbox:SetCallback(fn)` | Sets a new callback |
| `Textbox:SetEnabled(bool)` | Enables or disables the textbox |
| `Textbox:Destroy()` | Removes the textbox |

---

### `Section:CreateKeybind`

A button that lets the user bind a key or mouse button.

```lua
Section:CreateKeybind({
    Name = "Toggle UI",
    Default = { KeyCode = Enum.KeyCode.F },  -- Starting key
    Mode = "Toggle",  -- "Toggle" | "Hold" | "Always"
    Callback = function(active)  -- boolean for Toggle/Hold modes
        print("Key pressed, active:", active)
    end
})
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `Name` | string | Label shown next to the keybind |
| `Default` | table | `{KeyCode = Enum.KeyCode.F}` or `{UserInputType = Enum.UserInputType.MouseButton1}` |
| `Mode` | string | `"Toggle"` (on/off), `"Hold"` (true while held), `"Always"` (fires once per press) |
| `Callback` | function | Called when the key is activated |

**Methods:**

| Method | Description |
|--------|-------------|
| `Keybind:GetValue()` | Returns `{KeyCode, UserInputType, Name}` or `nil` |
| `Keybind:SetValue(keyData)` | Sets the key programmatically |
| `Keybind:SetMode("Toggle"|"Hold"|"Always")` | Changes activation mode |
| `Keybind:SetCallback(fn)` | Sets a new callback |
| `Keybind:SetEnabled(bool)` | Enables or disables the keybind |
| `Keybind:Destroy()` | Removes the keybind |

---

### `Section:CreateLabel`

A static text label for headings, descriptions, or info.

```lua
Section:CreateLabel({
    Text = "This is a label",
    Alignment = "Left",    -- "Left" | "Center" | "Right"
    TextSize = 14,        -- Font size (default: 13)
    TextColor = Color3.new(1, 0, 0) -- Custom color (default: Theme text color)
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `Label:SetText(text)` | Changes the label text |
| `Label:SetColor(color3)` | Changes the text color |
| `Label:Destroy()` | Removes the label |

---

### `Section:CreateDivider`

A horizontal line used to visually separate groups.

```lua
Section:CreateDivider({
    Text = "Section End"  -- Optional centered text on the line
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `Divider:Destroy()` | Removes the divider |

---

## Callback Patterns

Every interactive component follows the same callback pattern:

```lua
-- Toggle, Slider, Dropdown, Textbox, Keybind all use:
Callback = function(value)
    -- value type depends on the component
end

-- Buttons use:
Callback = function()
    -- no value for buttons
end
```

Callbacks are **not** fired when you set a value programmatically with `SetValue`. Pass `true` as a second argument to fire the callback:

```lua
Toggle:SetValue(true, true)  -- sets to true AND fires callback
```

---

## Theming

The library exposes its theme for basic customization:

```lua
local Theme = Library:GetTheme()

-- Read colors
print(Theme.Colors.Primary)           -- Color3
print(Theme.Colors.Background)        -- Color3
print(Theme.Sizing.CornerRadius)     -- number
print(Theme.Typography.Size.MD)      -- number

-- Modify live (affects future components)
Theme.Colors.Primary = Color3.fromRGB(255, 100, 100)
Theme.Colors.Background = Color3.fromRGB(30, 30, 30)
```

---

## Component Hierarchy

A typical UI structure looks like this:

```
Library
└── Window
    ├── Tab (Settings)
    │   ├── Section (General)
    │   │   ├── Button
    │   │   ├── Toggle
    │   │   └── Slider
    │   └── Section (Advanced)
    │       ├── Dropdown
    │       └── Keybind
    └── Tab (Info)
        └── Section
            ├── Label
            └── Divider
```

---

## File Structure

```
src/
├── init.luau         -- Main entry point (load this)
├── themes.luau       -- Color and style definitions
├── utils.luau        -- Internal helpers (tweening, input, etc.)
├── core.luau          -- Base component classes
└── components/
    ├── window.luau
    ├── tab.luau
    ├── section.luau
    ├── button.luau
    ├── toggle.luau
    ├── slider.luau
    ├── dropdown.luau
    ├── multidropdown.luau
    ├── textbox.luau
    ├── keybind.luau
    ├── notification.luau
    ├── label.luau
    └── divider.luau
```
