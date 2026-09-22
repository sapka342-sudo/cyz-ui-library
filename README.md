# cyz

A modern UI library for Roblox. One file, no dependencies, no external assets —
every icon is drawn from primitives, so nothing can fail to load at runtime.

```lua
local Cyz = loadstring(game:HttpGet("https://raw.githubusercontent.com/sapka342-sudo/cyz-ui-library/main/src/cyz.lua"))()

local Window = Cyz:CreateWindow({
    Title    = "my script",
    SubTitle = "v1.0.0",
    Theme    = "Midnight",
    Acrylic  = true,
})

local Tab = Window:AddTab({ Title = "Main" })
local Box = Tab:AddSection("Combat")

Box:AddToggle("Aimbot", {
    Title    = "Aimbot",
    Default  = false,
    Callback = function(v) print(v) end,
})
```

`RightShift` shows and hides the menu.

> **Note** — `HttpGet` can only reach the URL above once this repository is
> **public**. While it is private, raw.githubusercontent.com answers `404` and
> the loader fails. Either switch the repository to public in Settings, or host
> `src/cyz.lua` somewhere reachable and point the URL there.

---

## Contents

- [Layout](#layout)
- [Window](#window)
- [Tabs and sections](#tabs-and-sections)
- [Elements](#elements)
- [Flags](#flags)
- [Configs](#configs)
- [Themes](#themes)
- [Notifications and dialogs](#notifications-and-dialogs)
- [Watermark](#watermark)
- [Unloading](#unloading)
- [Environments](#environments)

---

## Layout

```
src/cyz.lua        the library
examples/demo.lua  showcase using every element
```

The library is a single file because it is loaded with `loadstring`. Internally
it is split into named regions (`--#region`) that fold in most editors.

---

## Window

```lua
local Window = Cyz:CreateWindow({
    Title        = "cyz",                     -- name in the top left
    SubTitle     = "v1.0.0",                  -- line underneath it
    Size         = UDim2.fromOffset(760, 500),
    MinSize      = Vector2.new(480, 320),     -- limits for the resize grip
    MaxSize      = Vector2.new(1400, 900),
    Position     = UDim2.fromScale(0.5, 0.5),
    Theme        = "Midnight",
    Acrylic      = true,                      -- blur the 3D world behind the menu
    Resizable    = true,
    ToggleKey    = Enum.KeyCode.RightShift,
    ToggleButton = true,                      -- floating chip to reopen it
    ConfigFolder = "cyz/myscript",
    DestroyOnClose = false,                   -- X hides instead of unloading
    OnClose      = function() end,
})
```

| Method | Effect |
|---|---|
| `Window:AddTab(opts)` | New tab, see below |
| `Window:SelectTab(x)` | `x` = index, title or tab object |
| `Window:Toggle(bool?)` | Show/hide; no argument toggles |
| `Window:Minimize(bool?)` | Collapse to the title bar |
| `Window:Dialog(opts)` | Modal, see below |
| `Window:SetTitle(s)` / `SetSubTitle(s)` | Change the header |
| `Window:SetToggleKey(key)` | Rebind the menu key |
| `Window:AddThemeSection(tab, title?)` | Drop in a ready-made theme picker |
| `Window:AddConfigSection(tab, title?)` | Drop in a ready-made config manager |

The window drags by its title bar and header, and resizes from the bottom-right
grip. It cannot be dragged so far off screen that it can't be dragged back.

---

## Tabs and sections

```lua
local Tab = Window:AddTab({ Title = "Visuals", Icon = "V" })
local Box = Tab:AddSection("ESP")
```

`Icon` takes a built-in glyph name (`close`, `minimize`, `check`, `chevron`,
`search`, `dot`), an asset id (`"rbxassetid://123"` or `123`), or any text — in
which case its first letter is used.

Elements can also be added straight to a tab, where they land in an untitled
section:

```lua
Tab:AddToggle("Fly", { Title = "Fly" })
```

---

## Elements

Every `Add*` method accepts both spellings:

```lua
Box:AddToggle("FlagName", { Title = "…" })
Box:AddToggle({ Flag = "FlagName", Title = "…" })
```

Each returns an element object with `:SetValue(v, silent?)`, `:SetTitle(s)`,
`:SetDescription(s)`, `:SetVisible(b)`, `:SetEnabled(b)`, `:Destroy()`, and the
current value on `.Value`.

### Button

```lua
Box:AddButton({
    Title       = "Kill all",
    Description = "Optional second line",
    Callback    = function() end,
})
```

### Toggle

```lua
local t = Box:AddToggle("Aimbot", {
    Title    = "Aimbot",
    Default  = false,
    Callback = function(v) end,
})
t:Toggle()
```

A toggle can carry a compact keybind inline on the same row:

```lua
Box:AddToggle("Aimbot", { Title = "Aimbot" })
   :AddKeyPicker("AimbotKey", { Default = Enum.KeyCode.E, Mode = "Hold" })
```

### Slider

```lua
Box:AddSlider("FOV", {
    Title    = "Field of view",
    Min      = 10,
    Max      = 360,
    Default  = 120,
    Rounding = 0,      -- decimal places
    Step     = nil,    -- optional snapping
    Suffix   = "deg",
    Callback = function(v) end,
})
```

The number on the right is an input field — the value can be typed as well.

### Dropdown

```lua
Box:AddDropdown("Target", {
    Title     = "Target part",
    Values    = { "Head", "Torso" },
    Default   = "Head",      -- a value, or an index as a number
    Multi     = false,
    Search    = false,       -- switches on automatically past 10 entries
    AllowNull = true,
    Callback  = function(v) end,
})
```

With `Multi = true`, `.Value` is a set (`{ ["Head"] = true }`) and
`:GetSelected()` returns an ordered list. `:SetValues(list)` swaps the choices
and keeps any selection that is still valid. `:Open()` and `:Close()` drive the
panel without a pointer.

### Input

```lua
Box:AddInput("PlayerName", {
    Title       = "Target player",
    Placeholder = "username",
    Numeric     = false,
    MaxLength   = nil,
    Finished    = true,   -- false fires the callback on every keystroke
    Width       = 120,
    Callback    = function(v) end,
})
```

### Keybind

```lua
Box:AddKeybind("NoclipKey", {
    Title           = "Noclip",
    Default         = Enum.KeyCode.V,
    Mode            = "Toggle",   -- Toggle | Hold | Always
    ShowMode        = true,
    Callback        = function(active) end,    -- key fired
    ChangedCallback = function(key, mode) end, -- binding changed
})
```

`Escape` while binding clears the key.

### Colorpicker

```lua
Box:AddColorpicker("EspColor", {
    Title        = "Box colour",
    Default      = Color3.fromRGB(110, 120, 255),
    Transparency = 0,      -- omit to hide the alpha slider
    Callback     = function(colour, transparency) end,
})
```

An SV square, a hue bar, an optional alpha bar and a hex field. `:Open()` and
`:Close()` drive the panel from code here too.

### Theme picker

```lua
Box:AddThemePicker({ Callback = function(name) end })
```

A grid of tiles, each painted in the colours of the theme it offers.

### Static content

```lua
Box:AddLabel("Text", { Bold = false, RichText = false, TextSize = 12.5 })
Box:AddParagraph({ Title = "Heading", Content = "Body copy" })
Box:AddDivider()
```

---

## Flags

Every element with a flag name writes into two tables:

```lua
Cyz.Flags["Aimbot"]    --> the raw value
Cyz.Options["Aimbot"]  --> the element object
```

More conveniently:

```lua
Cyz:Get("Aimbot")
Cyz:Set("Aimbot", true)          -- fires the callback
Cyz:Set("Aimbot", true, true)    -- silent
Cyz:Dump()                       -- every flag with its type and value
```

---

## Configs

```lua
Cyz:SetConfigFolder("cyz/myscript")

Cyz:SaveConfig("default")   --> true | false, error
Cyz:LoadConfig("default")
Cyz:DeleteConfig("default")
Cyz:ListConfigs()           --> { "default", ... }

Cyz:IgnoreFlag("PlayerName")  -- exclude from saving
```

`Window:AddConfigSection(tab)` drops in a ready-made interface for this.
`Color3` and `EnumItem` survive the round trip intact.

Without filesystem access these return `false` plus a reason; flags keep
working in memory.

---

## Themes

Shipped: `Midnight`, `Obsidian`, `Rose`, `Aurora`, `Amber`, `Daylight`.

```lua
Cyz:SetTheme("Rose")
Cyz:GetTheme()        --> the colour table
Cyz:GetThemeName()
Cyz:ListThemes()

Cyz:RegisterTheme("Mine", {
    Accent = Color3.fromRGB(0, 200, 255),
    Window = Color3.fromRGB(10, 12, 16),
    -- everything else is inherited from Midnight
})
```

A theme change animates across the whole existing interface; nothing is rebuilt.

Background blur:

```lua
Cyz:SetAcrylic(true)
Cyz:SetAcrylicIntensity(18)
```

---

## Notifications and dialogs

```lua
Cyz:Notify({
    Title    = "Saved",
    Content  = "Config written.",
    Kind     = "success",   -- info | success | warning | error
    Duration = 5,           -- 0 keeps it on screen
    Buttons  = {            -- optional; suppresses click-to-dismiss
        { Title = "Undo", Callback = function() end },
    },
})
```

```lua
Window:Dialog({
    Title       = "Delete everything?",
    Content     = "This cannot be undone.",
    Dismissable = true,
    Buttons = {
        { Title = "Cancel" },
        { Title = "Delete", Danger = true, Callback = function() end },
    },
})
```

---

## Watermark

```lua
Cyz:SetWatermark("cyz v{version} | {fps} fps | {ping} ms")
Cyz:SetWatermarkPosition(UDim2.fromOffset(16, 16))
Cyz:SetWatermark(nil)   -- off
```

Placeholders: `{fps}` `{ping}` `{game}` `{player}` `{time}` `{version}`.

---

## Unloading

```lua
Cyz:Destroy()   -- alias: Cyz:Unload()
```

Disconnects every connection, removes the blur and destroys the interface.

Loading the library unloads a previous instance first, so re-running the script
cannot stack a second interface with keybinds firing twice. To keep two
instances side by side, set `getgenv().__CYZ_KEEP_PREVIOUS = true` beforehand.

---

## Environments

The library runs without executor globals. Anything missing is handled:

| Function | Without it |
|---|---|
| `gethui` | Interface goes to CoreGui, else PlayerGui |
| `writefile` / `readfile` / ... | Configs disabled, flags keep working |
| `BlurEffect` in Lighting | Acrylic stays off, nothing else changes |

On touch devices the default window is smaller, the resize grip is hidden, and
the floating chip is used to reopen the menu.

---

## Local development

`examples/demo.lua` loads `cyz/cyz.lua` from the executor's workspace folder if
it is there, and falls back to `CYZ_URL` otherwise — so changes can be tested
without uploading each time.
