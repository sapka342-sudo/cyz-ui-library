--[[
    cyz — full component showcase

    Run this to see every element the library ships with. Point CYZ_URL at
    wherever you host cyz.lua; while developing, drop cyz.lua into your
    executor's workspace folder as cyz/cyz.lua and this picks it up instead.
]]

local CYZ_URL = "https://raw.githubusercontent.com/sapka342-sudo/cyz-ui-library/main/src/cyz.lua"

local function loadCyz()
    if isfile and isfile("cyz/cyz.lua") then
        return loadstring(readfile("cyz/cyz.lua"), "=cyz")()
    end
    return loadstring(game:HttpGet(CYZ_URL), "=cyz")()
end

local Cyz = loadCyz()

--------------------------------------------------------------------- window --

local Window = Cyz:CreateWindow({
    Title        = "cyz",
    SubTitle     = "component showcase",
    Size         = UDim2.fromOffset(760, 500),
    Theme        = "Midnight",
    Acrylic      = true,
    ToggleKey    = Enum.KeyCode.RightShift,
    ConfigFolder = "cyz/demo",
})

Cyz:SetWatermark("cyz v{version}  •  {fps} fps  •  {ping} ms")

----------------------------------------------------------------------- main --

local Main = Window:AddTab({ Title = "Main", Icon = "M" })

local Combat = Main:AddSection("Combat")

Combat:AddToggle("AimbotEnabled", {
    Title       = "Aimbot",
    Description = "Locks the camera onto the closest valid target.",
    Default     = false,
    Callback    = function(v) print("[demo] aimbot:", v) end,
}):AddKeyPicker("AimbotKey", { Default = Enum.KeyCode.E, Mode = "Hold" })

Combat:AddSlider("AimbotFOV", {
    Title    = "Field of view",
    Min      = 10,
    Max      = 360,
    Default  = 120,
    Rounding = 0,
    Suffix   = "°",
    Callback = function(v) print("[demo] fov:", v) end,
})

Combat:AddSlider("AimbotSmoothing", {
    Title    = "Smoothing",
    Min      = 0,
    Max      = 1,
    Default  = 0.25,
    Rounding = 2,
    Callback = function(v) print("[demo] smoothing:", v) end,
})

Combat:AddDropdown("AimbotPart", {
    Title    = "Target part",
    Values   = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" },
    Default  = "Head",
    Callback = function(v) print("[demo] part:", v) end,
})

Combat:AddDropdown("AimbotChecks", {
    Title       = "Target filters",
    Description = "All selected filters must pass.",
    Values      = { "Visible", "Alive", "Not teammate", "In FOV", "Has head" },
    Multi       = true,
    Default     = { "Alive", "In FOV" },
    Callback    = function(v)
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        print("[demo] filters:", n)
    end,
})

Combat:AddDivider()

Combat:AddButton({
    Title       = "Reset combat settings",
    Description = "Puts every value in this section back to its default.",
    Callback    = function()
        Cyz:Set("AimbotEnabled", false)
        Cyz:Set("AimbotFOV", 120)
        Cyz:Set("AimbotSmoothing", 0.25)
        Cyz:Notify({ Title = "Reset", Content = "Combat settings restored.", Kind = "success" })
    end,
})

local Movement = Main:AddSection("Movement")

Movement:AddToggle("FlyEnabled", { Title = "Fly", Default = false })
Movement:AddSlider("FlySpeed", { Title = "Fly speed", Min = 16, Max = 400, Default = 80, Suffix = " studs/s" })
Movement:AddToggle("NoclipEnabled", { Title = "Noclip", Default = false })
Movement:AddKeybind("NoclipKey", {
    Title    = "Noclip bind",
    Default  = Enum.KeyCode.V,
    Mode     = "Toggle",
    Callback = function(active) print("[demo] noclip bind:", active) end,
})

--------------------------------------------------------------------- visuals --

local Visuals = Window:AddTab({ Title = "Visuals", Icon = "V" })

local Esp = Visuals:AddSection("ESP")

Esp:AddToggle("EspEnabled", { Title = "Enable ESP", Default = true })
Esp:AddColorpicker("EspColor", {
    Title        = "Box colour",
    Default      = Color3.fromRGB(110, 120, 255),
    Transparency = 0,
    Callback     = function(c, t) print("[demo] esp colour:", c, t) end,
})
Esp:AddColorpicker("EspFillColor", {
    Title   = "Fill colour",
    Default = Color3.fromRGB(255, 90, 140),
})
Esp:AddDropdown("EspStyle", {
    Title   = "Box style",
    Values  = { "Corners", "Full box", "Outline only", "Filled" },
    Default = "Corners",
})
Esp:AddSlider("EspDistance", { Title = "Max distance", Min = 50, Max = 5000, Default = 1500, Suffix = "m" })

local World = Visuals:AddSection("World")

World:AddToggle("Fullbright", { Title = "Fullbright", Default = false })
World:AddSlider("FovSlider", { Title = "Camera FOV", Min = 40, Max = 120, Default = 70 })
World:AddDropdown("TimeOfDay", {
    Title   = "Time of day",
    Values  = { "Dawn", "Noon", "Dusk", "Midnight" },
    Default = "Noon",
    Search  = true,
})

------------------------------------------------------------------ inputs tab --

local Inputs = Window:AddTab({ Title = "Inputs", Icon = "I" })

local Text = Inputs:AddSection("Text")

Text:AddInput("PlayerName", {
    Title       = "Target player",
    Placeholder = "username",
    Callback    = function(v) print("[demo] target:", v) end,
})
Text:AddInput("WebhookUrl", {
    Title       = "Webhook URL",
    Placeholder = "https://…",
    Width       = 180,
})
Text:AddInput("MaxPlayers", {
    Title       = "Max players",
    Placeholder = "12",
    Numeric     = true,
    Width       = 70,
})

local Static = Inputs:AddSection("Static content")

Static:AddParagraph({
    Title   = "About this demo",
    Content = "Every element on this page is a real, live control. Values are "
           .. "stored in Cyz.Flags under the flag name passed as the first "
           .. "argument, and survive a config save/load round trip.",
})
Static:AddLabel("Labels are plain text with no card around them.")
Static:AddLabel("They can be bold, too.", { Bold = true })
Static:AddDivider()
Static:AddLabel("<b>Rich text</b> works when you opt in.", { RichText = true })

local Feedback = Inputs:AddSection("Feedback")

Feedback:AddButton({
    Title       = "Show notifications",
    Description = "Fires one toast of each kind.",
    Callback    = function()
        Cyz:Notify({ Title = "Info", Content = "Just so you know.", Kind = "info" })
        task.wait(0.35)
        Cyz:Notify({ Title = "Success", Content = "That worked.", Kind = "success" })
        task.wait(0.35)
        Cyz:Notify({ Title = "Warning", Content = "Check this.", Kind = "warning" })
        task.wait(0.35)
        Cyz:Notify({ Title = "Error", Content = "That did not work.", Kind = "error" })
    end,
})

Feedback:AddButton({
    Title       = "Toast with actions",
    Description = "A toast that waits for a decision instead of timing out.",
    Callback    = function()
        Cyz:Notify({
            Title    = "Unsaved changes",
            Content  = "Save before switching config?",
            Duration = 0,
            Kind     = "warning",
            Buttons  = {
                { Title = "Discard" },
                { Title = "Save", Callback = function()
                    Cyz:Notify({ Title = "Saved", Kind = "success", Duration = 2 })
                end },
            },
        })
    end,
})

Feedback:AddButton({
    Title       = "Open a dialog",
    Description = "A modal that blocks the window until answered.",
    Callback    = function()
        Window:Dialog({
            Title   = "Delete everything?",
            Content = "This removes all saved configs. It cannot be undone.",
            Buttons = {
                { Title = "Cancel" },
                { Title = "Delete", Danger = true, Callback = function()
                    Cyz:Notify({ Title = "Deleted", Kind = "error" })
                end },
            },
        })
    end,
})

--------------------------------------------------------------------- settings --

local Settings = Window:AddTab({ Title = "Settings", Icon = "S" })

Window:AddThemeSection(Settings, "Appearance")
Window:AddConfigSection(Settings, "Configuration")

local About = Settings:AddSection("About")
About:AddParagraph({
    Title   = "cyz v" .. Cyz.Version,
    Content = "Single-file UI library for Roblox. Press RightShift to hide "
           .. "and show this window.",
})
About:AddButton({
    Title       = "Unload",
    Description = "Destroys the interface and disconnects every listener.",
    Callback    = function()
        Window:Dialog({
            Title   = "Unload cyz?",
            Content = "The interface closes and all listeners are disconnected.",
            Buttons = {
                { Title = "Cancel" },
                { Title = "Unload", Danger = true, Callback = function() Cyz:Destroy() end },
            },
        })
    end,
})

Window:SelectTab(1)

Cyz:Notify({
    Title    = "cyz loaded",
    Content  = "Press RightShift to toggle the menu.",
    Kind     = "success",
    Duration = 6,
})

return Cyz
