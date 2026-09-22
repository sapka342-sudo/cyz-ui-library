# cyz

Eine moderne UI-Library für Roblox. Eine einzige Datei, keine Abhängigkeiten,
keine externen Assets — jedes Icon ist aus Primitiven gezeichnet, es kann also
nichts nachladen und fehlschlagen.

```lua
local Cyz = loadstring(game:HttpGet("https://raw.githubusercontent.com/sapka342-sudo/cyz-ui-library/main/src/cyz.lua"))()

local Window = Cyz:CreateWindow({
    Title    = "mein script",
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

`RightShift` blendet das Menü ein und aus.

---

## Inhalt

- [Aufbau](#aufbau)
- [Fenster](#fenster)
- [Tabs und Sections](#tabs-und-sections)
- [Elemente](#elemente)
- [Flags](#flags)
- [Konfigurationen](#konfigurationen)
- [Themes](#themes)
- [Benachrichtigungen und Dialoge](#benachrichtigungen-und-dialoge)
- [Wasserzeichen](#wasserzeichen)
- [Aufräumen](#aufräumen)
- [Umgebungen](#umgebungen)

---

## Aufbau

```
src/cyz.lua        die Library
examples/demo.lua  Showcase mit jedem Element
```

Die Library ist eine Datei, weil sie per `loadstring` geladen wird. Sie ist
intern in benannte Regionen gegliedert (`--#region`), die man im Editor
zuklappen kann.

---

## Fenster

```lua
local Window = Cyz:CreateWindow({
    Title        = "cyz",                     -- Name links oben
    SubTitle     = "v1.0.0",                  -- Zeile darunter
    Size         = UDim2.fromOffset(760, 500),
    MinSize      = Vector2.new(480, 320),     -- Grenzen für den Resize-Griff
    MaxSize      = Vector2.new(1400, 900),
    Position     = UDim2.fromScale(0.5, 0.5),
    Theme        = "Midnight",
    Acrylic      = true,                      -- 3D-Welt hinter dem Menü weichzeichnen
    Resizable    = true,
    ToggleKey    = Enum.KeyCode.RightShift,
    ToggleButton = true,                      -- schwebender Chip zum Wiederöffnen
    ConfigFolder = "cyz/meinscript",
    DestroyOnClose = false,                   -- X schließt statt zu entladen
    OnClose      = function() end,
})
```

| Methode | Wirkung |
|---|---|
| `Window:AddTab(opts)` | Neuer Tab, siehe unten |
| `Window:SelectTab(x)` | `x` = Index, Titel oder Tab-Objekt |
| `Window:Toggle(bool?)` | Ein-/ausblenden; ohne Argument umschalten |
| `Window:Minimize(bool?)` | Auf die Titelleiste einklappen |
| `Window:Dialog(opts)` | Modal, siehe unten |
| `Window:SetTitle(s)` / `SetSubTitle(s)` | Kopfzeile ändern |
| `Window:SetToggleKey(key)` | Menü-Taste neu belegen |
| `Window:AddThemeSection(tab, titel?)` | Fertige Theme-Auswahl einsetzen |
| `Window:AddConfigSection(tab, titel?)` | Fertige Config-Verwaltung einsetzen |

Das Fenster lässt sich an Titelleiste und Kopfbereich ziehen und unten rechts
in der Größe ändern. Es kann nicht so weit aus dem Bild gezogen werden, dass man
es nicht mehr zurückholen kann.

---

## Tabs und Sections

```lua
local Tab = Window:AddTab({ Title = "Visuals", Icon = "V" })
local Box = Tab:AddSection("ESP")
```

`Icon` nimmt einen eingebauten Glyphennamen (`close`, `minimize`, `check`,
`chevron`, `search`, `dot`), eine Asset-ID (`"rbxassetid://123"` oder `123`),
oder einen beliebigen Text — dann wird dessen erster Buchstabe gesetzt.

Elemente können auch direkt an den Tab gehängt werden, dann landen sie in einer
unbenannten Section:

```lua
Tab:AddToggle("Fly", { Title = "Fly" })
```

---

## Elemente

Jede `Add*`-Methode akzeptiert beide Schreibweisen:

```lua
Box:AddToggle("FlagName", { Title = "…" })
Box:AddToggle({ Flag = "FlagName", Title = "…" })
```

Jede gibt ein Element-Objekt zurück mit `:SetValue(v, silent?)`, `:SetTitle(s)`,
`:SetDescription(s)`, `:SetVisible(b)`, `:SetEnabled(b)`, `:Destroy()` und dem
aktuellen Wert unter `.Value`.

### Button

```lua
Box:AddButton({
    Title       = "Kill all",
    Description = "Optionale zweite Zeile",
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

Ein Toggle kann eine kompakte Tastenbelegung direkt in der Zeile tragen:

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
    Rounding = 0,      -- Nachkommastellen
    Step     = nil,    -- optionale Rasterung
    Suffix   = "°",
    Callback = function(v) end,
})
```

Der Zahlenwert rechts ist ein Eingabefeld — man kann den Wert auch tippen.

### Dropdown

```lua
Box:AddDropdown("Target", {
    Title     = "Target part",
    Values    = { "Head", "Torso" },
    Default   = "Head",      -- Wert, oder Index als Zahl
    Multi     = false,
    Search    = false,       -- ab 10 Einträgen automatisch an
    AllowNull = true,
    Callback  = function(v) end,
})
```

Bei `Multi = true` ist `.Value` eine Menge (`{ ["Head"] = true }`);
`:GetSelected()` gibt eine geordnete Liste zurück. `:SetValues(liste)` tauscht
die Auswahlmöglichkeiten und behält gültige Auswahlen bei. `:Open()` und
`:Close()` klappen das Panel auch ohne Mausklick auf.

### Input

```lua
Box:AddInput("PlayerName", {
    Title       = "Target player",
    Placeholder = "username",
    Numeric     = false,
    MaxLength   = nil,
    Finished    = true,   -- false = Callback bei jedem Zeichen
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
    Callback        = function(active) end,   -- Taste ausgelöst
    ChangedCallback = function(key, mode) end, -- Belegung geändert
})
```

`Escape` beim Belegen löscht die Taste.

### Colorpicker

```lua
Box:AddColorpicker("EspColor", {
    Title        = "Box colour",
    Default      = Color3.fromRGB(110, 120, 255),
    Transparency = 0,      -- weglassen, um den Alpha-Regler auszublenden
    Callback     = function(farbe, transparenz) end,
})
```

SV-Fläche, Farbtonleiste, optionale Alpha-Leiste und ein Hex-Feld. Auch hier
öffnen und schließen `:Open()` und `:Close()` das Panel aus dem Code heraus.

### Theme-Picker

```lua
Box:AddThemePicker({ Callback = function(name) end })
```

Ein Raster aus Kacheln, die jeweils in den Farben des Themes gezeichnet sind,
das sie anbieten.

### Statisches

```lua
Box:AddLabel("Text", { Bold = false, RichText = false, TextSize = 12.5 })
Box:AddParagraph({ Title = "Überschrift", Content = "Fließtext" })
Box:AddDivider()
```

---

## Flags

Jedes Element mit einem Flag-Namen schreibt in zwei Tabellen:

```lua
Cyz.Flags["Aimbot"]    --> der rohe Wert
Cyz.Options["Aimbot"]  --> das Element-Objekt
```

Bequemer:

```lua
Cyz:Get("Aimbot")
Cyz:Set("Aimbot", true)          -- ruft den Callback
Cyz:Set("Aimbot", true, true)    -- still
Cyz:Dump()                       -- alle Flags mit Typ und Wert
```

---

## Konfigurationen

```lua
Cyz:SetConfigFolder("cyz/meinscript")

Cyz:SaveConfig("default")   --> true | false, fehler
Cyz:LoadConfig("default")
Cyz:DeleteConfig("default")
Cyz:ListConfigs()           --> { "default", … }

Cyz:IgnoreFlag("PlayerName")  -- vom Speichern ausnehmen
```

`Window:AddConfigSection(tab)` setzt dafür eine fertige Oberfläche ein.
`Color3` und `EnumItem` werden verlustfrei serialisiert.

Ohne Dateisystemzugriff geben die Funktionen `false` mit einer Begründung
zurück; die Flags funktionieren weiterhin im Speicher.

---

## Themes

Mitgeliefert: `Midnight`, `Obsidian`, `Rose`, `Aurora`, `Amber`, `Daylight`.

```lua
Cyz:SetTheme("Rose")
Cyz:GetTheme()        --> die Farbtabelle
Cyz:GetThemeName()
Cyz:ListThemes()

Cyz:RegisterTheme("Meins", {
    Accent = Color3.fromRGB(0, 200, 255),
    Window = Color3.fromRGB(10, 12, 16),
    -- alles Weitere wird von Midnight geerbt
})
```

Ein Themewechsel läuft animiert über die gesamte bestehende Oberfläche; es muss
nichts neu aufgebaut werden.

Hintergrund-Weichzeichner:

```lua
Cyz:SetAcrylic(true)
Cyz:SetAcrylicIntensity(18)
```

---

## Benachrichtigungen und Dialoge

```lua
Cyz:Notify({
    Title    = "Gespeichert",
    Content  = "Config geschrieben.",
    Kind     = "success",   -- info | success | warning | error
    Duration = 5,           -- 0 = bleibt stehen
    Buttons  = {            -- optional; dann kein Klick-zum-Schließen
        { Title = "Rückgängig", Callback = function() end },
    },
})
```

```lua
Window:Dialog({
    Title       = "Alles löschen?",
    Content     = "Das lässt sich nicht rückgängig machen.",
    Dismissable = true,
    Buttons = {
        { Title = "Abbrechen" },
        { Title = "Löschen", Danger = true, Callback = function() end },
    },
})
```

---

## Wasserzeichen

```lua
Cyz:SetWatermark("cyz v{version}  •  {fps} fps  •  {ping} ms")
Cyz:SetWatermarkPosition(UDim2.fromOffset(16, 16))
Cyz:SetWatermark(nil)   -- aus
```

Platzhalter: `{fps}` `{ping}` `{game}` `{player}` `{time}` `{version}`.

---

## Aufräumen

```lua
Cyz:Destroy()   -- alias: Cyz:Unload()
```

Trennt jede Verbindung, entfernt den Weichzeichner und löscht die Oberfläche.

Beim Laden räumt die Library eine vorherige Instanz selbst weg — ein erneutes
Ausführen des Scripts stapelt also keine zweite Oberfläche mit doppelt
feuernden Tastenbelegungen. Wer zwei Instanzen nebeneinander will, setzt vorher
`getgenv().__CYZ_KEEP_PREVIOUS = true`.

---

## Umgebungen

Die Library läuft ohne Executor-Globals. Was fehlt, wird abgefangen:

| Funktion | Ohne sie |
|---|---|
| `gethui` | Oberfläche geht nach CoreGui, sonst PlayerGui |
| `writefile` / `readfile` / … | Configs deaktiviert, Flags laufen weiter |
| `BlurEffect` in Lighting | Acrylic bleibt aus, sonst unverändert |

Auf Touch-Geräten wird ein kleineres Standardfenster gewählt, der Resize-Griff
ausgeblendet, und der schwebende Chip dient zum Wiederöffnen.

---

## Lokale Entwicklung

`examples/demo.lua` lädt `cyz/cyz.lua` aus dem Workspace-Ordner des Executors,
wenn es dort liegt, und greift sonst auf `CYZ_URL` zurück. So testet man
Änderungen, ohne jedes Mal hochzuladen.
