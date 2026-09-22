--[[

     ██████╗██╗   ██╗███████╗
    ██╔════╝╚██╗ ██╔╝╚══███╔╝
    ██║      ╚████╔╝   ███╔╝
    ██║       ╚██╔╝   ███╔╝
    ╚██████╗   ██║   ███████╗
     ╚═════╝   ╚═╝   ╚══════╝

    cyz — a modern UI library for Roblox
    version 1.0.0

    Single file, no dependencies, no external assets.
    Every icon is drawn from primitives so nothing can 404.

    Quick start:

        local Cyz = loadstring(game:HttpGet("<url>/cyz.lua"))()

        local Window = Cyz:CreateWindow({
            Title = "my script",
            SubTitle = "v1.0.0",
            Theme = "Midnight",
        })

        local Tab = Window:AddTab({ Title = "Main" })
        local Box = Tab:AddSection("Combat")

        Box:AddToggle("Aimbot", { Title = "Aimbot", Default = false,
            Callback = function(v) print(v) end })

    Full API: see README.md

]]

--#region ── environment ───────────────────────────────────────────────────────

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")
local Stats              = game:FindService("Stats")

local LocalPlayer = Players.LocalPlayer

-- Executor globals are optional everywhere. The library must stay usable in
-- Studio, where none of them exist.
local function envfn(name)
    local ok, fn = pcall(function() return (getgenv and getgenv() or _G)[name] end)
    if ok and type(fn) == "function" then return fn end
    local ok2, fn2 = pcall(function() return getfenv()[name] end)
    if ok2 and type(fn2) == "function" then return fn2 end
    return nil
end

local FS = {
    write      = envfn("writefile"),
    read       = envfn("readfile"),
    isfile     = envfn("isfile"),
    isfolder   = envfn("isfolder"),
    makefolder = envfn("makefolder"),
    listfiles  = envfn("listfiles"),
    delfile    = envfn("delfile"),
}
local HAS_FS = FS.write and FS.read and FS.isfile and FS.isfolder and FS.makefolder and true or false

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--#endregion

--#region ── util ──────────────────────────────────────────────────────────────

local Cyz = {
    Version        = "1.0.0",
    Flags          = {},   -- flag -> raw value
    Options        = {},   -- flag -> element object
    Windows        = {},
    Connections    = {},
    Instances      = {},   -- theme-bound { Instance, Property, Token, Alpha }
    Unloaded       = false,
    _themeName     = "Midnight",
}
Cyz.__index = Cyz

local function Connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(Cyz.Connections, conn)
    return conn
end

local function New(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(parent, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function Pad(parent, t, b, l, r)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or l or 0),
        Parent        = parent,
    })
end

local function List(parent, padding, dir, align)
    return New("UIListLayout", {
        Padding              = UDim.new(0, padding or 0),
        FillDirection        = dir or Enum.FillDirection.Vertical,
        SortOrder            = Enum.SortOrder.LayoutOrder,
        VerticalAlignment    = align or Enum.VerticalAlignment.Top,
        Parent               = parent,
    })
end

local function round(n, places)
    local m = 10 ^ (places or 0)
    return math.floor(n * m + 0.5) / m
end

local function clamp01(n) return math.clamp(n, 0, 1) end

--- Tween shorthand. Returns the tween so callers can wait on it.
local EASE = Enum.EasingStyle.Quint
local function tw(inst, props, dur, style, dir)
    local tween = TweenService:Create(
        inst,
        TweenInfo.new(dur or 0.18, style or EASE, dir or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

--#endregion

--#region ── themes ────────────────────────────────────────────────────────────

local Themes = {}

Themes.Midnight = {
    Name        = "Midnight",
    Window      = Color3.fromRGB(16, 17, 23),
    Sidebar     = Color3.fromRGB(13, 14, 19),
    Topbar      = Color3.fromRGB(16, 17, 23),
    Card        = Color3.fromRGB(22, 23, 31),
    Elevated    = Color3.fromRGB(28, 30, 40),
    Hover       = Color3.fromRGB(34, 36, 48),
    Active      = Color3.fromRGB(41, 44, 58),
    Stroke      = Color3.fromRGB(40, 42, 56),
    StrokeSoft  = Color3.fromRGB(30, 32, 43),
    Text        = Color3.fromRGB(238, 240, 248),
    SubText     = Color3.fromRGB(150, 155, 175),
    Muted       = Color3.fromRGB(96, 101, 122),
    Accent      = Color3.fromRGB(110, 120, 255),
    AccentHover = Color3.fromRGB(132, 141, 255),
    AccentText  = Color3.fromRGB(255, 255, 255),
    Success     = Color3.fromRGB(70, 200, 140),
    Warning     = Color3.fromRGB(240, 185, 80),
    Danger      = Color3.fromRGB(240, 90, 100),
    Shadow      = Color3.fromRGB(0, 0, 0),
    Dark        = true,
}

Themes.Obsidian = {
    Name        = "Obsidian",
    Window      = Color3.fromRGB(12, 12, 13),
    Sidebar     = Color3.fromRGB(9, 9, 10),
    Topbar      = Color3.fromRGB(12, 12, 13),
    Card        = Color3.fromRGB(18, 18, 20),
    Elevated    = Color3.fromRGB(25, 25, 28),
    Hover       = Color3.fromRGB(32, 32, 36),
    Active      = Color3.fromRGB(40, 40, 45),
    Stroke      = Color3.fromRGB(38, 38, 42),
    StrokeSoft  = Color3.fromRGB(26, 26, 29),
    Text        = Color3.fromRGB(240, 240, 242),
    SubText     = Color3.fromRGB(148, 148, 156),
    Muted       = Color3.fromRGB(95, 95, 102),
    Accent      = Color3.fromRGB(52, 211, 178),
    AccentHover = Color3.fromRGB(78, 228, 196),
    AccentText  = Color3.fromRGB(8, 20, 18),
    Success     = Color3.fromRGB(70, 200, 140),
    Warning     = Color3.fromRGB(240, 185, 80),
    Danger      = Color3.fromRGB(240, 90, 100),
    Shadow      = Color3.fromRGB(0, 0, 0),
    Dark        = true,
}

Themes.Rose = {
    Name        = "Rose",
    Window      = Color3.fromRGB(23, 16, 21),
    Sidebar     = Color3.fromRGB(19, 13, 17),
    Topbar      = Color3.fromRGB(23, 16, 21),
    Card        = Color3.fromRGB(31, 22, 29),
    Elevated    = Color3.fromRGB(39, 28, 37),
    Hover       = Color3.fromRGB(48, 34, 45),
    Active      = Color3.fromRGB(57, 41, 54),
    Stroke      = Color3.fromRGB(55, 40, 52),
    StrokeSoft  = Color3.fromRGB(40, 29, 38),
    Text        = Color3.fromRGB(246, 236, 242),
    SubText     = Color3.fromRGB(176, 152, 168),
    Muted       = Color3.fromRGB(120, 100, 114),
    Accent      = Color3.fromRGB(244, 93, 140),
    AccentHover = Color3.fromRGB(250, 123, 162),
    AccentText  = Color3.fromRGB(255, 255, 255),
    Success     = Color3.fromRGB(70, 200, 140),
    Warning     = Color3.fromRGB(240, 185, 80),
    Danger      = Color3.fromRGB(240, 90, 100),
    Shadow      = Color3.fromRGB(0, 0, 0),
    Dark        = true,
}

Themes.Aurora = {
    Name        = "Aurora",
    Window      = Color3.fromRGB(13, 21, 20),
    Sidebar     = Color3.fromRGB(10, 17, 16),
    Topbar      = Color3.fromRGB(13, 21, 20),
    Card        = Color3.fromRGB(19, 29, 28),
    Elevated    = Color3.fromRGB(25, 38, 36),
    Hover       = Color3.fromRGB(31, 47, 45),
    Active      = Color3.fromRGB(38, 57, 54),
    Stroke      = Color3.fromRGB(36, 54, 51),
    StrokeSoft  = Color3.fromRGB(25, 39, 37),
    Text        = Color3.fromRGB(233, 245, 242),
    SubText     = Color3.fromRGB(142, 168, 162),
    Muted       = Color3.fromRGB(92, 114, 109),
    Accent      = Color3.fromRGB(126, 217, 87),
    AccentHover = Color3.fromRGB(150, 232, 115),
    AccentText  = Color3.fromRGB(10, 26, 12),
    Success     = Color3.fromRGB(70, 200, 140),
    Warning     = Color3.fromRGB(240, 185, 80),
    Danger      = Color3.fromRGB(240, 90, 100),
    Shadow      = Color3.fromRGB(0, 0, 0),
    Dark        = true,
}

Themes.Amber = {
    Name        = "Amber",
    Window      = Color3.fromRGB(23, 19, 14),
    Sidebar     = Color3.fromRGB(19, 15, 11),
    Topbar      = Color3.fromRGB(23, 19, 14),
    Card        = Color3.fromRGB(31, 26, 19),
    Elevated    = Color3.fromRGB(40, 33, 24),
    Hover       = Color3.fromRGB(49, 41, 30),
    Active      = Color3.fromRGB(58, 48, 35),
    Stroke      = Color3.fromRGB(56, 47, 34),
    StrokeSoft  = Color3.fromRGB(41, 34, 25),
    Text        = Color3.fromRGB(247, 241, 231),
    SubText     = Color3.fromRGB(172, 158, 136),
    Muted       = Color3.fromRGB(116, 105, 89),
    Accent      = Color3.fromRGB(245, 166, 35),
    AccentHover = Color3.fromRGB(252, 186, 72),
    AccentText  = Color3.fromRGB(32, 22, 4),
    Success     = Color3.fromRGB(70, 200, 140),
    Warning     = Color3.fromRGB(240, 185, 80),
    Danger      = Color3.fromRGB(240, 90, 100),
    Shadow      = Color3.fromRGB(0, 0, 0),
    Dark        = true,
}

Themes.Daylight = {
    Name        = "Daylight",
    Window      = Color3.fromRGB(246, 247, 250),
    Sidebar     = Color3.fromRGB(240, 241, 245),
    Topbar      = Color3.fromRGB(246, 247, 250),
    Card        = Color3.fromRGB(255, 255, 255),
    Elevated    = Color3.fromRGB(246, 247, 250),
    Hover       = Color3.fromRGB(236, 238, 243),
    Active      = Color3.fromRGB(226, 229, 237),
    Stroke      = Color3.fromRGB(221, 224, 232),
    StrokeSoft  = Color3.fromRGB(234, 236, 242),
    Text        = Color3.fromRGB(24, 26, 34),
    SubText     = Color3.fromRGB(104, 110, 126),
    Muted       = Color3.fromRGB(150, 156, 172),
    Accent      = Color3.fromRGB(78, 92, 240),
    AccentHover = Color3.fromRGB(98, 111, 245),
    AccentText  = Color3.fromRGB(255, 255, 255),
    Success     = Color3.fromRGB(32, 160, 104),
    Warning     = Color3.fromRGB(202, 142, 20),
    Danger      = Color3.fromRGB(214, 58, 70),
    Shadow      = Color3.fromRGB(80, 90, 120),
    Dark        = false,
}

local Theme = Themes.Midnight

--- Bind an instance property to a theme token so re-theming is automatic.
--- A literal Color3 is applied once and never re-themed, which is what a caller
--- passing a fixed colour means.
local function Paint(inst, map, alpha)
    for prop, token in pairs(map) do
        if typeof(token) == "Color3" then
            inst[prop] = token
        else
            table.insert(Cyz.Instances, { Inst = inst, Prop = prop, Token = token, Alpha = alpha })
            local c = Theme[token]
            if c then
                if alpha and alpha[prop] then
                    inst[prop] = c:Lerp(Theme.Window, alpha[prop])
                else
                    inst[prop] = c
                end
            end
        end
    end
    return inst
end

local function Stroke(parent, token, thickness, transparency)
    local s = New("UIStroke", {
        Thickness     = thickness or 1,
        Transparency  = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent        = parent,
    })
    Paint(s, { Color = token or "Stroke" })
    return s
end

function Cyz:SetTheme(name)
    local t = type(name) == "table" and name or Themes[name]
    if not t then return false end
    Theme = t
    Cyz._themeName = t.Name or tostring(name)

    -- Walk backwards: a destroyed instance drops out of the registry here, which
    -- is the only place the registry is ever pruned.
    for i = #Cyz.Instances, 1, -1 do
        local e = Cyz.Instances[i]
        local c = Theme[e.Token]
        if c then
            local target = c
            if e.Alpha and e.Alpha[e.Prop] then
                target = c:Lerp(Theme.Window, e.Alpha[e.Prop])
            end
            local ok = pcall(function() tw(e.Inst, { [e.Prop] = target }, 0.25) end)
            if not ok then table.remove(Cyz.Instances, i) end
        end
    end

    for _, listener in ipairs(Cyz._themeListeners) do
        pcall(listener, Cyz._themeName)
    end
    return true
end

--- Anything that renders the theme list itself (the theme picker) registers here
--- so a theme change from any source keeps every picker in sync.
Cyz._themeListeners = {}

function Cyz:GetTheme() return Theme end
function Cyz:GetThemeName() return Cyz._themeName end
function Cyz:ListThemes()
    local out = {}
    for k in pairs(Themes) do table.insert(out, k) end
    table.sort(out)
    return out
end
function Cyz:RegisterTheme(name, tbl)
    local base = {}
    for k, v in pairs(Themes.Midnight) do base[k] = v end
    for k, v in pairs(tbl) do base[k] = v end
    base.Name = name
    Themes[name] = base
    return base
end

--#endregion

--#region ── glyphs (drawn, never loaded) ──────────────────────────────────────

-- Every icon below is built from Frames. No asset ids, so nothing can fail to
-- load, and every glyph inherits the theme automatically.

local Glyph = {}

local function bar(parent, props)
    local f = New("Frame", props)
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

--- ✕
function Glyph.Close(parent, size, token)
    local holder = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = parent,
    })
    for _, rot in ipairs({ 45, -45 }) do
        local b = bar(holder, {
            Size = UDim2.new(1, 0, 0, 1.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Rotation = rot,
        })
        Corner(b, 1)
        Paint(b, { BackgroundColor3 = token or "SubText" })
    end
    return holder
end

--- ─
function Glyph.Minimize(parent, size, token)
    local holder = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = parent,
    })
    local b = bar(holder, {
        Size = UDim2.new(1, 0, 0, 1.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
    })
    Corner(b, 1)
    Paint(b, { BackgroundColor3 = token or "SubText" })
    return holder
end

--- ✓  (two bars forming a tick)
function Glyph.Check(parent, size, token)
    local holder = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = parent,
    })
    local short = bar(holder, {
        Size = UDim2.fromOffset(size * 0.42, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, -size * 0.22, 0.5, size * 0.14),
        Rotation = 45,
    })
    local long = bar(holder, {
        Size = UDim2.fromOffset(size * 0.74, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, size * 0.08, 0.5, 0),
        Rotation = -45,
    })
    Corner(short, 1); Corner(long, 1)
    Paint(short, { BackgroundColor3 = token or "AccentText" })
    Paint(long,  { BackgroundColor3 = token or "AccentText" })
    return holder
end

--- ⌄  (chevron; rotate the holder for other directions)
function Glyph.Chevron(parent, size, token)
    local holder = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = parent,
    })
    local w = size * 0.5
    local l = bar(holder, {
        Size = UDim2.fromOffset(w, 1.6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, -w * 0.34, 0.5, 0),
        Rotation = 45,
    })
    local r = bar(holder, {
        Size = UDim2.fromOffset(w, 1.6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, w * 0.34, 0.5, 0),
        Rotation = -45,
    })
    Corner(l, 1); Corner(r, 1)
    Paint(l, { BackgroundColor3 = token or "SubText" })
    Paint(r, { BackgroundColor3 = token or "SubText" })
    return holder
end

--- ⌕
function Glyph.Search(parent, size, token)
    local holder = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = parent,
    })
    local ring = New("Frame", {
        Size = UDim2.fromOffset(size * 0.62, size * 0.62),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = holder,
    })
    Corner(ring, 99)
    local rs = New("UIStroke", { Thickness = 1.5, Parent = ring })
    Paint(rs, { Color = token or "SubText" })
    local handle = bar(holder, {
        Size = UDim2.fromOffset(size * 0.34, 1.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(size * 0.74, size * 0.74),
        Rotation = 45,
    })
    Corner(handle, 1)
    Paint(handle, { BackgroundColor3 = token or "SubText" })
    return holder
end

--- a filled dot, used for tab bullets and bound-key markers
function Glyph.Dot(parent, size, token)
    local d = New("Frame", {
        Size = UDim2.fromOffset(size, size),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BorderSizePixel = 0,
        Parent = parent,
    })
    Corner(d, 99)
    Paint(d, { BackgroundColor3 = token or "Accent" })
    return d
end

--- The tab rail marker: a rounded vertical pill.
function Glyph.Pill(parent, token)
    local p = New("Frame", {
        Size = UDim2.fromOffset(3, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        Parent = parent,
    })
    Corner(p, 2)
    Paint(p, { BackgroundColor3 = token or "Accent" })
    return p
end

--- A generic "icon plate": a rounded square holding an initial letter. Used
--- when a tab supplies an Icon string that is not a known glyph name and not
--- an asset id.
function Glyph.Letter(parent, size, letter, token)
    local lbl = New("TextLabel", {
        Size = UDim2.fromOffset(size, size),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = string.upper(string.sub(letter or "?", 1, 1)),
        Font = Enum.Font.GothamBold,
        TextSize = math.floor(size * 0.72),
        Parent = parent,
    })
    Paint(lbl, { TextColor3 = token or "SubText" })
    return lbl
end

local GLYPHS = {
    close = Glyph.Close, minimize = Glyph.Minimize, check = Glyph.Check,
    chevron = Glyph.Chevron, search = Glyph.Search, dot = Glyph.Dot,
}

--- Resolve an Icon option into something renderable.
--- Accepts: nil, a glyph name, "rbxassetid://123", a number, or a single letter.
local function RenderIcon(parent, icon, size, token)
    if icon == nil then return nil end
    if type(icon) == "number" then icon = "rbxassetid://" .. icon end
    if type(icon) == "string" then
        local lower = string.lower(icon)
        if GLYPHS[lower] then return GLYPHS[lower](parent, size, token) end
        if string.match(icon, "^rbx") or string.match(icon, "^http") then
            local img = New("ImageLabel", {
                Size = UDim2.fromOffset(size, size),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = icon,
                ScaleType = Enum.ScaleType.Fit,
                Parent = parent,
            })
            Paint(img, { ImageColor3 = token or "SubText" })
            return img
        end
        return Glyph.Letter(parent, size, icon, token)
    end
    return nil
end

--#endregion

--#region ── interaction helpers ───────────────────────────────────────────────

--- Hover + press states for any clickable surface.
local function Interactive(button, opts)
    opts = opts or {}
    local idle    = opts.Idle    or "Card"
    local hover   = opts.Hover   or "Hover"
    local press   = opts.Press   or "Active"
    local hovered, pressed = false, false

    local function refresh()
        local token = idle
        if pressed then token = press elseif hovered then token = hover end
        tw(button, { BackgroundColor3 = Theme[token] }, 0.14)
    end

    Connect(button.MouseEnter, function() hovered = true; refresh() end)
    Connect(button.MouseLeave, function() hovered = false; pressed = false; refresh() end)
    Connect(button.MouseButton1Down, function() pressed = true; refresh() end)
    Connect(button.MouseButton1Up, function() pressed = false; refresh() end)

    return { Refresh = refresh }
end

--- A circular ripple from the click point. Cheap, and it makes presses read.
local function Ripple(button, color)
    Connect(button.MouseButton1Down, function(x, y)
        local abs = button.AbsolutePosition
        local size = button.AbsoluteSize
        local rel  = Vector2.new(x - abs.X, y - abs.Y)
        local far  = math.max(rel.X, size.X - rel.X)
        local fary = math.max(rel.Y, size.Y - rel.Y)
        local radius = math.sqrt(far * far + fary * fary) * 2

        local circle = New("Frame", {
            BackgroundColor3 = color or Theme.Text,
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(rel.X, rel.Y),
            Size = UDim2.fromOffset(0, 0),
            ZIndex = button.ZIndex,
            Parent = button,
        })
        Corner(circle, 999)

        tw(circle, { Size = UDim2.fromOffset(radius, radius), BackgroundTransparency = 1 }, 0.5,
            Enum.EasingStyle.Quart)
        task.delay(0.52, function() if circle then circle:Destroy() end end)
    end)
end

--- Make `handle` drag `target`, keeping it inside the viewport.
local function Draggable(handle, target, onEnd)
    local dragging, dragStart, startPos = false, nil, nil

    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                    if onEnd then onEnd(target.Position) end
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - dragStart
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                   or Vector2.new(1920, 1080)
        local size   = target.AbsoluteSize
        local anchor = target.AnchorPoint

        -- The top-left corner sits at  scale*viewport + offset - anchor*size.
        -- Clamp that corner into the allowed screen range, then solve back for
        -- the offset. Leaving 60px on screen means the window can never be
        -- dragged somewhere it cannot be dragged back from.
        local function offsetFor(desired, scale, viewport, anchorAxis, extent, minEdge, maxEdge)
            local corner = scale * viewport + desired - anchorAxis * extent
            corner = math.clamp(corner, minEdge, maxEdge)
            return corner - scale * viewport + anchorAxis * extent
        end

        local x = offsetFor(startPos.X.Offset + delta.X, startPos.X.Scale, vp.X,
                            anchor.X, size.X, 60 - size.X, vp.X - 60)
        local y = offsetFor(startPos.Y.Offset + delta.Y, startPos.Y.Scale, vp.Y,
                            anchor.Y, size.Y, 0, vp.Y - size.Y - 8)

        target.Position = UDim2.new(startPos.X.Scale, x, startPos.Y.Scale, y)
    end)
end

--- Bottom-right resize grip.
local function Resizable(grip, target, minSize, maxSize, onResize)
    local resizing, startPos, startSize = false, nil, nil

    Connect(grip.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing  = true
            startPos  = input.Position
            startSize = target.AbsoluteSize
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not resizing then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - startPos
        local w = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
        local h = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
        target.Size = UDim2.fromOffset(w, h)
        if onResize then onResize(w, h) end
    end)
end

--#endregion

--#region ── screen gui ────────────────────────────────────────────────────────

local function safeParent(gui)
    -- Preference order: gethui() > protected CoreGui > CoreGui > PlayerGui.
    local gethui = envfn("gethui")
    if gethui then
        local ok, hidden = pcall(gethui)
        if ok and hidden then
            local ok2 = pcall(function() gui.Parent = hidden end)
            if ok2 then return true end
        end
    end

    local protect = envfn("protect_gui")
    if protect then pcall(protect, gui) end
    local syn_protect = (syn and syn.protect_gui)
    if type(syn_protect) == "function" then pcall(syn_protect, gui) end

    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if ok and gui.Parent then return true end

    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                   or LocalPlayer:WaitForChild("PlayerGui", 5)
        if pg then gui.Parent = pg; return true end
    end
    return false
end

-- Executors re-run scripts constantly. Without a sweep here, every re-execute
-- leaves the previous interface on screen with all of its input listeners still
-- attached, so keybinds fire twice and the old window can never be closed.
-- Destroying the previous library instance also disconnects it; the orphan sweep
-- is the fallback for a GUI whose module reference was already lost.
local GENV = (getgenv and getgenv()) or _G

local function unloadPrevious()
    if GENV.__CYZ_KEEP_PREVIOUS then return end

    local previous = GENV.__CYZ_ACTIVE
    if type(previous) == "table" and type(previous.Destroy) == "function" then
        pcall(function() previous:Destroy() end)
    end

    local function sweep(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ScreenGui") and string.match(child.Name, "^cyz_%d+$") then
                pcall(function() child:Destroy() end)
            end
        end
    end
    pcall(function() sweep(envfn("gethui") and envfn("gethui")()) end)
    pcall(function() sweep(game:GetService("CoreGui")) end)
    pcall(function() sweep(LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
end
unloadPrevious()

local ScreenGui = New("ScreenGui", {
    Name             = "cyz_" .. tostring(math.random(100000, 999999)),
    ResetOnSpawn     = false,
    IgnoreGuiInset   = true,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    DisplayOrder      = 9999,
})
safeParent(ScreenGui)
Cyz.ScreenGui = ScreenGui

-- Publishing the instance is what makes the next run's unloadPrevious() able to
-- disconnect this one, rather than only destroying its GUI and orphaning every
-- input listener it registered.
GENV.__CYZ_ACTIVE = Cyz

--#endregion

--#region ── notifications ─────────────────────────────────────────────────────

local NotifyHolder = New("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -16, 0, 16),
    Size = UDim2.fromOffset(300, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 5000,
    Parent = ScreenGui,
})
List(NotifyHolder, 10).HorizontalAlignment = Enum.HorizontalAlignment.Right

local NOTIFY_KIND = {
    info    = "Accent",
    success = "Success",
    warning = "Warning",
    error   = "Danger",
}

--- Cyz:Notify{ Title, Content, Duration, Kind = "info"|"success"|"warning"|"error" }
function Cyz:Notify(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local duration = opts.Duration or opts.Time or 5
    local accent   = NOTIFY_KIND[string.lower(opts.Kind or opts.Type or "info")] or "Accent"

    -- A UIListLayout owns the Position of its direct children, so the slide-in
    -- cannot animate the card itself. The wrapper takes the layout slot and the
    -- card moves freely inside it.
    local wrapper = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 5000,
        Parent = NotifyHolder,
    })

    local card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 5000,
        Parent = wrapper,
    })

    -- The body is the dismiss target, so it has to be a button; action buttons
    -- are its children and therefore still win the click.
    local body = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = card,
    })
    Paint(body, { BackgroundColor3 = "Elevated" })
    Corner(body, 10)
    Stroke(body, "Stroke", 1, 0.2)
    Pad(body, 12, 12, 14, 12)
    List(body, 4)

    local accentBar = New("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0, 8),
        BorderSizePixel = 0,
        ZIndex = 5001,
        Parent = card,
    })
    Corner(accentBar, 2)
    Paint(accentBar, { BackgroundColor3 = accent })

    local title = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = tostring(opts.Title or "Notification"),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = body,
    })
    Paint(title, { TextColor3 = "Text" })

    if opts.Content or opts.Description or opts.Text then
        local content = New("TextLabel", {
            Size = UDim2.new(1, -20, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = tostring(opts.Content or opts.Description or opts.Text),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Parent = body,
        })
        Paint(content, { TextColor3 = "SubText" })
    end

    -- action buttons, if any
    if opts.Buttons then
        local row = New("Frame", {
            Size = UDim2.new(1, -20, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Parent = body,
        })
        New("UIPadding", { PaddingTop = UDim.new(0, 6), Parent = row })
        local rl = List(row, 6, Enum.FillDirection.Horizontal)
        rl.VerticalAlignment = Enum.VerticalAlignment.Center
        for _, b in ipairs(opts.Buttons) do
            local btn = New("TextButton", {
                Size = UDim2.fromOffset(78, 22),
                Text = tostring(b.Title or "OK"),
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Parent = row,
            })
            Corner(btn, 6)
            Paint(btn, { BackgroundColor3 = "Card", TextColor3 = "Text" })
            Interactive(btn)
            Connect(btn.MouseButton1Click, function()
                if b.Callback then task.spawn(b.Callback) end
                tw(card, { GroupTransparency = 1 }, 0.2)
                task.delay(0.22, function() if wrapper then wrapper:Destroy() end end)
            end)
        end
    end

    -- progress bar
    local track = New("Frame", {
        Size = UDim2.new(1, -16, 0, 2),
        Position = UDim2.new(0, 8, 1, -5),
        AnchorPoint = Vector2.new(0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.85,
        ZIndex = 5001,
        Parent = card,
    })
    Corner(track, 2)
    Paint(track, { BackgroundColor3 = "Muted" })
    local fill = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Parent = track,
    })
    Corner(fill, 2)
    Paint(fill, { BackgroundColor3 = accent })

    -- enter
    card.Position = UDim2.fromOffset(40, 0)
    tw(card, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.32)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        tw(card, { GroupTransparency = 1, Position = UDim2.fromOffset(40, 0) }, 0.24)
        task.delay(0.26, function() if wrapper then wrapper:Destroy() end end)
    end

    -- Click-to-dismiss would swallow the intent of an action toast, so it is
    -- only wired up when the toast has no buttons of its own.
    if not opts.Buttons then
        Connect(body.MouseButton1Click, dismiss)
    end

    if duration > 0 then
        tw(fill, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)
        task.delay(duration, dismiss)
    else
        track.Visible = false
    end

    return { Dismiss = dismiss, Instance = card }
end

--#endregion

--#region ── watermark ─────────────────────────────────────────────────────────

local Watermark = {}
do
    local frame = New("Frame", {
        Name = "Watermark",
        Position = UDim2.fromOffset(16, 16),
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 4000,
        Parent = ScreenGui,
    })
    Paint(frame, { BackgroundColor3 = "Elevated" })
    Corner(frame, 7)
    Stroke(frame, "Stroke", 1, 0.25)
    Pad(frame, 0, 0, 10, 10)

    local accentBar = New("Frame", {
        Size = UDim2.new(0, 2, 1, -10),
        Position = UDim2.new(0, -6, 0, 5),
        BorderSizePixel = 0,
        ZIndex = 4001,
        Parent = frame,
    })
    Corner(accentBar, 2)
    Paint(accentBar, { BackgroundColor3 = "Accent" })

    local label = New("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Text = "cyz",
        ZIndex = 4001,
        Parent = frame,
    })
    Paint(label, { TextColor3 = "Text" })

    local template, conn
    local fps, acc, frames = 60, 0, 0

    function Watermark:Set(text)
        template = text
        frame.Visible = text ~= nil and text ~= false
        if not frame.Visible then
            if conn then conn:Disconnect(); conn = nil end
            return
        end
        if not conn then
            conn = Connect(RunService.RenderStepped, function(dt)
                acc = acc + dt; frames = frames + 1
                if acc >= 0.5 then
                    fps = math.floor(frames / acc + 0.5)
                    acc, frames = 0, 0
                end
                local ping = 0
                if Stats then
                    local ok, v = pcall(function()
                        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    if ok and v then ping = math.floor(v) end
                end
                local out = template
                out = string.gsub(out, "{fps}", tostring(fps))
                out = string.gsub(out, "{ping}", tostring(ping))
                out = string.gsub(out, "{game}", tostring(game.PlaceId))
                out = string.gsub(out, "{player}", LocalPlayer and LocalPlayer.Name or "?")
                out = string.gsub(out, "{time}", os.date("%H:%M:%S"))
                out = string.gsub(out, "{version}", Cyz.Version)
                label.Text = out
            end)
        end
    end

    function Watermark:Position(udim2) frame.Position = udim2 end
    Watermark.Instance = frame
end

--- Cyz:SetWatermark("cyz | {fps} fps | {ping} ms")
--- Tokens: {fps} {ping} {game} {player} {time} {version}
function Cyz:SetWatermark(text) Watermark:Set(text) end
function Cyz:SetWatermarkPosition(pos) Watermark:Position(pos) end

--#endregion

--#region ── acrylic / backdrop ────────────────────────────────────────────────

-- Two independent conditions decide whether the world is blurred: the user
-- turned the effect on, and a window is currently on screen. Storing them
-- separately avoids the reference-counting drift a shared counter produces when
-- one of the two is toggled from more than one place.
local Acrylic = { Enabled = false, Shown = false, Blur = nil, Intensity = 18 }

function Acrylic:_apply()
    if not self.Blur then return end
    tw(self.Blur, { Size = (self.Enabled and self.Shown) and self.Intensity or 0 }, 0.35)
end

function Acrylic:SetEnabled(on)
    if on and not self.Blur then
        local ok, blur = pcall(function()
            local b = Instance.new("BlurEffect")
            b.Name = "cyz_blur"
            b.Size = 0
            b.Parent = Lighting
            return b
        end)
        if not ok then return false end
        self.Blur = blur
    end
    self.Enabled = on == true
    self:_apply()
    return true
end

function Acrylic:SetShown(shown)
    self.Shown = shown == true
    self:_apply()
end

function Acrylic:Destroy()
    if self.Blur then pcall(function() self.Blur:Destroy() end) end
    self.Blur = nil
end

--- Turn the background blur on or off at runtime.
function Cyz:SetAcrylic(enabled) return Acrylic:SetEnabled(enabled ~= false) end
function Cyz:SetAcrylicIntensity(n)
    Acrylic.Intensity = math.clamp(tonumber(n) or 18, 0, 56)
    Acrylic:_apply()
end

--#endregion

--#region ── config / flags ────────────────────────────────────────────────────

local Config = {
    Folder   = nil,   -- e.g. "cyz/myscript"
    Ignored  = {},
}

local function ensureFolder(path)
    if not HAS_FS or not path then return false end
    local parts, acc = string.split(path, "/"), nil
    for _, part in ipairs(parts) do
        if part ~= "" then
            acc = acc and (acc .. "/" .. part) or part
            if not FS.isfolder(acc) then
                local ok = pcall(FS.makefolder, acc)
                if not ok then return false end
            end
        end
    end
    return true
end

-- Every encoded form is a pure dictionary. A table that mixes array entries
-- with string keys does not round-trip through JSONEncode, and the damage only
-- shows up when a config is loaded back.
local function serialize(value)
    local t = typeof(value)
    if t == "Color3" then
        return {
            __t = "Color3",
            r = math.floor(value.R * 255 + 0.5),
            g = math.floor(value.G * 255 + 0.5),
            b = math.floor(value.B * 255 + 0.5),
        }
    elseif t == "EnumItem" then
        return { __t = "Enum", enum = tostring(value.EnumType), name = value.Name }
    elseif t == "table" then
        local out = {}
        for k, v in pairs(value) do out[k] = serialize(v) end
        return out
    end
    return value
end

local function deserialize(value)
    if type(value) == "table" then
        if value.__t == "Color3" then
            return Color3.fromRGB(value.r or 0, value.g or 0, value.b or 0)
        elseif value.__t == "Enum" then
            local ok, item = pcall(function()
                return Enum[string.gsub(value.enum, "^Enum%.", "")][value.name]
            end)
            return ok and item or nil
        end
        local out = {}
        for k, v in pairs(value) do out[k] = deserialize(v) end
        return out
    end
    return value
end

function Cyz:SetConfigFolder(folder)
    Config.Folder = folder
    ensureFolder(folder)
    return HAS_FS
end

function Cyz:IgnoreFlag(flag, ignore)
    Config.Ignored[flag] = ignore ~= false
end

function Cyz:GetConfigTable()
    local data = { __cyz = Cyz.Version, theme = Cyz._themeName, flags = {} }
    for flag, element in pairs(Cyz.Options) do
        if not Config.Ignored[flag] and not element.IgnoreConfig then
            data.flags[flag] = serialize(element:GetConfigValue())
        end
    end
    return data
end

function Cyz:LoadConfigTable(data)
    if type(data) ~= "table" then return false, "not a table" end
    if data.theme and Themes[data.theme] then Cyz:SetTheme(data.theme) end
    for flag, raw in pairs(data.flags or {}) do
        local element = Cyz.Options[flag]
        if element and not Config.Ignored[flag] then
            local ok, err = pcall(function() element:SetConfigValue(deserialize(raw)) end)
            if not ok then warn("[cyz] failed to restore flag '" .. flag .. "': " .. tostring(err)) end
        end
    end
    return true
end

local function configPath(name)
    return (Config.Folder or "cyz") .. "/" .. name .. ".json"
end

function Cyz:SaveConfig(name)
    if not HAS_FS then return false, "no filesystem access in this environment" end
    if not name or name == "" then return false, "no name" end
    ensureFolder(Config.Folder or "cyz")
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Cyz:GetConfigTable())
    if not ok then return false, "encode failed" end
    local ok2, err = pcall(FS.write, configPath(name), encoded)
    if not ok2 then return false, tostring(err) end
    return true
end

function Cyz:LoadConfig(name)
    if not HAS_FS then return false, "no filesystem access in this environment" end
    local path = configPath(name)
    if not FS.isfile(path) then return false, "config does not exist" end
    local ok, raw = pcall(FS.read, path)
    if not ok then return false, "read failed" end
    local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 then return false, "corrupt config" end
    return Cyz:LoadConfigTable(decoded)
end

function Cyz:DeleteConfig(name)
    if not HAS_FS or not FS.delfile then return false, "no filesystem access" end
    local path = configPath(name)
    if not FS.isfile(path) then return false, "config does not exist" end
    local ok = pcall(FS.delfile, path)
    return ok
end

function Cyz:ListConfigs()
    if not HAS_FS or not FS.listfiles then return {} end
    local folder = Config.Folder or "cyz"
    if not FS.isfolder(folder) then return {} end
    local ok, files = pcall(FS.listfiles, folder)
    if not ok then return {} end
    local out = {}
    for _, f in ipairs(files) do
        local name = string.match(f, "([^/\\]+)%.json$")
        if name then table.insert(out, name) end
    end
    table.sort(out)
    return out
end

--#endregion

--#region ── element base ──────────────────────────────────────────────────────

local Element = {}
Element.__index = Element

function Element:SetTitle(text)
    if self.TitleLabel then self.TitleLabel.Text = tostring(text) end
    return self
end

function Element:SetDescription(text)
    if self.DescLabel then
        self.DescLabel.Text = tostring(text or "")
        self.DescLabel.Visible = text ~= nil and text ~= ""
    end
    return self
end

function Element:SetVisible(visible)
    if self.Holder then self.Holder.Visible = visible ~= false end
    return self
end

function Element:SetEnabled(enabled)
    self.Disabled = enabled == false
    if self.Holder then
        local t = self.Disabled and 0.5 or 0
        for _, d in ipairs(self.Holder:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                pcall(function() d.TextTransparency = t end)
            end
        end
        if self.Holder:IsA("GuiObject") then
            self.Holder.Active = not self.Disabled
        end
    end
    return self
end

function Element:Destroy()
    if self.Flag then
        Cyz.Options[self.Flag] = nil
        Cyz.Flags[self.Flag]   = nil
    end
    if self.Holder then self.Holder:Destroy() end
end

--- Default config bridge; elements with richer state override these.
function Element:GetConfigValue() return self.Value end
function Element:SetConfigValue(v) if self.SetValue then self:SetValue(v, true) end end

local function bindFlag(element, flag, value)
    element.Flag = flag
    if flag then
        Cyz.Options[flag] = element
        Cyz.Flags[flag]   = value
    end
end

local function setFlag(element, value)
    element.Value = value
    if element.Flag then Cyz.Flags[element.Flag] = value end
end

--- Normalise `Add*(flag, opts)` and `Add*(opts)` into one shape.
local function norm(a, b)
    if type(a) == "table" then
        return a.Flag or a.Name, a
    end
    local opts = b or {}
    return a, opts
end

local function fire(cb, ...)
    if type(cb) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function() cb(table.unpack(args, 1, args.n)) end)
        if not ok then warn("[cyz] callback error: " .. tostring(err)) end
    end)
end

--#endregion

--#region ── section (groupbox) ────────────────────────────────────────────────

local Section = {}
Section.__index = Section

--- Build the standard "row" chrome: a card with a title, optional description,
--- and a right-hand control slot. Every element reuses this so spacing,
--- hit areas and hover states stay identical across the library.
local function Row(section, opts)
    opts = opts or {}
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = section:_NextOrder(),
        Parent = section.Container,
    })

    -- A Frame has no AutoButtonColor/Text, and assigning them raises, so the
    -- button-only properties have to be added rather than passed as nil.
    local cardProps = {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = holder,
    }
    if opts.Button then
        cardProps.Text = ""
        cardProps.AutoButtonColor = false
    end
    local card = New(opts.Button and "TextButton" or "Frame", cardProps)
    Paint(card, { BackgroundColor3 = "Card" })
    Corner(card, 8)
    Stroke(card, "StrokeSoft", 1, 0.35)

    local inner = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    })
    Pad(inner, 9, 9, 12, 10)

    local text = New("Frame", {
        Size = UDim2.new(1, -(opts.ControlWidth or 0) - (opts.ControlWidth and 12 or 0), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = inner,
    })
    List(text, 2)

    local title = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 15),
        BackgroundTransparency = 1,
        Text = tostring(opts.Title or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1,
        Parent = text,
    })
    Paint(title, { TextColor3 = "Text" })

    local desc = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = tostring(opts.Description or ""),
        Visible = opts.Description ~= nil and opts.Description ~= "",
        Font = Enum.Font.Gotham,
        TextSize = 11.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = text,
    })
    Paint(desc, { TextColor3 = "SubText" })

    local control
    if opts.ControlWidth then
        control = New("Frame", {
            Size = UDim2.new(0, opts.ControlWidth, 0, opts.ControlHeight or 22),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            BackgroundTransparency = 1,
            Parent = card,
        })
    end

    return {
        Holder     = holder,
        Card       = card,
        Inner      = inner,
        TitleLabel = title,
        DescLabel  = desc,
        Control    = control,
    }
end

function Section:_NextOrder()
    self._order = (self._order or 0) + 1
    return self._order
end

function Section:AddDivider()
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 9),
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self.Container,
    })
    local line = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromScale(0, 0.5),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.4,
        Parent = holder,
    })
    Paint(line, { BackgroundColor3 = "Stroke" })
    return setmetatable({ Holder = holder }, Element)
end

function Section:AddLabel(text, opts)
    opts = type(text) == "table" and text or (opts or {})
    local str = type(text) == "string" and text or (opts.Title or opts.Text or "")

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self.Container,
    })
    Pad(holder, 2, 2, 2, 2)
    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = tostring(str),
        Font = opts.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = opts.TextSize or 12.5,
        TextWrapped = true,
        RichText = opts.RichText == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    Paint(label, { TextColor3 = opts.Color or "SubText" })

    local e = setmetatable({ Holder = holder, TitleLabel = label }, Element)
    function e:SetText(v) label.Text = tostring(v); return self end
    return e
end

function Section:AddParagraph(opts)
    opts = opts or {}
    local row = Row(self, { Title = opts.Title, Description = opts.Content or opts.Description })
    row.DescLabel.TextSize = 12
    return setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
    }, Element)
end

--#endregion

--#region ── element: button ───────────────────────────────────────────────────

function Section:AddButton(opts)
    opts = opts or {}
    local row = Row(self, {
        Title = opts.Title or "Button",
        Description = opts.Description,
        Button = true,
        ControlWidth = 22,
        ControlHeight = 22,
    })

    local card = row.Card
    Interactive(card)
    Ripple(card, Theme.Text)

    -- trailing chevron, rotated to point right
    local chev = New("Frame", {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Rotation = -90,
        Parent = row.Control,
    })
    Glyph.Chevron(chev, 14, "Muted")

    Connect(card.MouseEnter, function() tw(chev, { Position = UDim2.new(0.5, 3, 0.5, 0) }, 0.16) end)
    Connect(card.MouseLeave, function() tw(chev, { Position = UDim2.fromScale(0.5, 0.5) }, 0.16) end)

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Callback = opts.Callback,
    }, Element)

    Connect(card.MouseButton1Click, function()
        if e.Disabled then return end
        fire(e.Callback)
    end)

    function e:SetCallback(fn) self.Callback = fn; return self end
    function e:Fire() fire(self.Callback); return self end
    e.IgnoreConfig = true
    return e
end

--#endregion

--#region ── element: toggle ───────────────────────────────────────────────────

function Section:AddToggle(a, b)
    local flag, opts = norm(a, b)
    local value = opts.Default == true

    local row = Row(self, {
        Title = opts.Title or flag or "Toggle",
        Description = opts.Description,
        Button = true,
        ControlWidth = 36,
        ControlHeight = 20,
    })

    Interactive(row.Card)

    local track = New("Frame", {
        Size = UDim2.fromOffset(36, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BorderSizePixel = 0,
        Parent = row.Control,
    })
    Corner(track, 10)
    Paint(track, { BackgroundColor3 = "Elevated" })
    local trackStroke = Stroke(track, "Stroke", 1, 0.2)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        BorderSizePixel = 0,
        Parent = track,
    })
    Corner(knob, 99)
    Paint(knob, { BackgroundColor3 = "Muted" })

    local tick = Glyph.Check(knob, 10, "AccentText")
    tick.Visible = false

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Value = value, Callback = opts.Callback, Type = "Toggle",
    }, Element)

    function e:SetValue(v, silent)
        v = v == true
        setFlag(self, v)
        tw(track, { BackgroundColor3 = v and Theme.Accent or Theme.Elevated }, 0.18)
        tw(trackStroke, { Transparency = v and 1 or 0.2 }, 0.18)
        tw(knob, {
            Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = v and Theme.AccentText or Theme.Muted,
            Size = UDim2.fromOffset(14, 14),
        }, 0.22, Enum.EasingStyle.Back)
        tick.Visible = v
        if self._addons then for _, fn in ipairs(self._addons) do fn(v) end end
        if not silent then fire(self.Callback, v) end
        return self
    end

    function e:Toggle() return self:SetValue(not self.Value) end
    function e:OnChanged(fn) self.Callback = fn; return self end

    Connect(row.Card.MouseButton1Click, function()
        if e.Disabled then return end
        e:Toggle()
    end)

    bindFlag(e, flag, value)
    e:SetValue(value, true)
    if opts.Default == true then fire(opts.Callback, true) end
    return e
end

--#endregion

--#region ── element: slider ───────────────────────────────────────────────────

function Section:AddSlider(a, b)
    local flag, opts = norm(a, b)
    local min      = opts.Min or opts.Minimum or 0
    local max      = opts.Max or opts.Maximum or 100
    local rounding = opts.Rounding or opts.Decimals or 0
    local suffix   = opts.Suffix or ""
    local step     = opts.Step
    local value    = math.clamp(opts.Default or min, min, max)

    local row = Row(self, {
        Title = opts.Title or flag or "Slider",
        Description = opts.Description,
    })

    -- Sliders need the full width, so the control sits on its own line.
    local barRow = New("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = row.TitleLabel.Parent,
    })

    local track = New("Frame", {
        Size = UDim2.new(1, -46, 0, 5),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        Parent = barRow,
    })
    Corner(track, 3)
    Paint(track, { BackgroundColor3 = "Elevated" })

    local fill = New("Frame", {
        Size = UDim2.fromScale(0, 1),
        BorderSizePixel = 0,
        Parent = track,
    })
    Corner(fill, 3)
    Paint(fill, { BackgroundColor3 = "Accent" })

    local knob = New("Frame", {
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = track,
    })
    Corner(knob, 99)
    Paint(knob, { BackgroundColor3 = "AccentText" })
    Stroke(knob, "Accent", 2, 0)

    local readout = New("TextBox", {
        Size = UDim2.fromOffset(42, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Text = "0",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false,
        Parent = barRow,
    })
    Paint(readout, { TextColor3 = "SubText" })

    local hit = New("TextButton", {
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 4,
        Parent = barRow,
    })

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Value = value, Callback = opts.Callback, Type = "Slider",
        Min = min, Max = max,
    }, Element)

    local function display(v)
        local text = tostring(rounding > 0 and string.format("%." .. rounding .. "f", v) or math.floor(v))
        return text .. suffix
    end

    function e:SetValue(v, silent)
        v = tonumber(v) or min
        if step then v = min + round((v - min) / step) * step end
        v = round(math.clamp(v, self.Min, self.Max), rounding)
        setFlag(self, v)
        local alpha = (self.Max - self.Min) == 0 and 0 or (v - self.Min) / (self.Max - self.Min)
        tw(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.1)
        tw(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.1)
        if not readout:IsFocused() then readout.Text = display(v) end
        if not silent then fire(self.Callback, v) end
        return self
    end

    function e:SetRange(newMin, newMax)
        self.Min, self.Max = newMin, newMax
        return self:SetValue(self.Value, true)
    end
    function e:OnChanged(fn) self.Callback = fn; return self end

    -- drag
    local dragging = false
    local function fromX(x)
        local alpha = clamp01((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X))
        e:SetValue(e.Min + (e.Max - e.Min) * alpha)
    end

    Connect(hit.InputBegan, function(input)
        if e.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tw(knob, { Size = UDim2.fromOffset(16, 16) }, 0.12)
            fromX(input.Position.X)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                tw(knob, { Size = UDim2.fromOffset(12, 12) }, 0.12)
            end
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            fromX(input.Position.X)
        end
    end)

    -- typed entry
    Connect(readout.FocusLost, function()
        local typed = tonumber(string.match(readout.Text, "%-?%d+%.?%d*"))
        if typed then e:SetValue(typed) else readout.Text = display(e.Value) end
    end)

    bindFlag(e, flag, value)
    e:SetValue(value, true)
    if opts.Default ~= nil then fire(opts.Callback, value) end
    return e
end

--#endregion

--#region ── element: input ────────────────────────────────────────────────────

function Section:AddInput(a, b)
    local flag, opts = norm(a, b)
    local value = tostring(opts.Default or "")

    local row = Row(self, {
        Title = opts.Title or flag or "Input",
        Description = opts.Description,
        ControlWidth = opts.Width or 120,
        ControlHeight = 26,
    })

    local field = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Parent = row.Control,
    })
    Corner(field, 6)
    Paint(field, { BackgroundColor3 = "Elevated" })
    local fs = Stroke(field, "Stroke", 1, 0.25)

    local box = New("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = value,
        PlaceholderText = tostring(opts.Placeholder or ""),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = opts.ClearOnFocus == true,
        Parent = field,
    })
    Paint(box, { TextColor3 = "Text", PlaceholderColor3 = "Muted" })

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Value = value, Callback = opts.Callback, Type = "Input",
    }, Element)

    function e:SetValue(v, silent)
        v = tostring(v or "")
        if opts.MaxLength then v = string.sub(v, 1, opts.MaxLength) end
        if opts.Numeric then v = string.match(v, "%-?%d*%.?%d*") or "" end
        setFlag(self, v)
        if box.Text ~= v then box.Text = v end
        if not silent then fire(self.Callback, v) end
        return self
    end
    function e:OnChanged(fn) self.Callback = fn; return self end

    Connect(box.Focused, function()
        tw(fs, { Color = Theme.Accent, Transparency = 0 }, 0.15)
    end)
    Connect(box.FocusLost, function(enter)
        tw(fs, { Color = Theme.Stroke, Transparency = 0.25 }, 0.15)
        if opts.Finished ~= false then e:SetValue(box.Text) end
        if enter and opts.OnEnter then fire(opts.OnEnter, box.Text) end
    end)
    Connect(box:GetPropertyChangedSignal("Text"), function()
        if opts.Finished == false then e:SetValue(box.Text) end
    end)

    bindFlag(e, flag, value)
    return e
end

Section.AddTextbox = Section.AddInput

--#endregion

--#region ── element: keybind ──────────────────────────────────────────────────

local function keyName(key)
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.UserInputType then
            local short = string.gsub(key.Name, "MouseButton", "MB")
            return short
        end
        return key.Name
    end
    return tostring(key or "None")
end

local function toKey(v)
    if typeof(v) == "EnumItem" then return v end
    if type(v) == "string" then
        if Enum.KeyCode[v] then return Enum.KeyCode[v] end
        local ok, item = pcall(function() return Enum.UserInputType[v] end)
        if ok and item then return item end
    end
    return nil
end

function Section:AddKeybind(a, b)
    local flag, opts = norm(a, b)
    local key  = toKey(opts.Default)
    local mode = opts.Mode or "Toggle"   -- Toggle | Hold | Always

    local row = Row(self, {
        Title = opts.Title or flag or "Keybind",
        Description = opts.Description,
        ControlWidth = 96,
        ControlHeight = 24,
    })

    local modeBtn = New("TextButton", {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.fromOffset(0, 0),
        Text = mode,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Visible = opts.ShowMode ~= false,
        Parent = row.Control,
    })
    Corner(modeBtn, 6)
    Paint(modeBtn, { BackgroundColor3 = "Elevated", TextColor3 = "SubText" })
    Stroke(modeBtn, "Stroke", 1, 0.3)
    Interactive(modeBtn, { Idle = "Elevated" })

    local keyBtn = New("TextButton", {
        Size = UDim2.fromOffset(opts.ShowMode == false and 96 or 48, 24),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Text = keyName(key),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = row.Control,
    })
    Corner(keyBtn, 6)
    Paint(keyBtn, { BackgroundColor3 = "Elevated", TextColor3 = "Text" })
    local keyStroke = Stroke(keyBtn, "Stroke", 1, 0.3)
    Interactive(keyBtn, { Idle = "Elevated" })

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Value = key, Mode = mode, Active = mode == "Always",
        Callback = opts.Callback, ChangedCallback = opts.ChangedCallback,
        Type = "Keybind",
    }, Element)

    local MODES = { "Toggle", "Hold", "Always" }
    local function cycleMode()
        local idx = table.find(MODES, e.Mode) or 1
        e.Mode = MODES[(idx % #MODES) + 1]
        modeBtn.Text = e.Mode
        if e.Mode == "Always" then e.Active = true
        elseif e.Mode == "Hold" then e.Active = false end
        fire(e.ChangedCallback, e.Value, e.Mode)
    end
    Connect(modeBtn.MouseButton1Click, cycleMode)

    local listening = false
    function e:SetValue(v, silent)
        local k = toKey(v)
        setFlag(self, k)
        keyBtn.Text = listening and "..." or keyName(k)
        if not silent then fire(self.ChangedCallback, k, self.Mode) end
        return self
    end

    function e:SetMode(m)
        if table.find(MODES, m) then
            e.Mode = m; modeBtn.Text = m
            if m == "Always" then e.Active = true end
        end
        return self
    end

    function e:GetState() return self.Active end
    function e:OnClick(fn) self.Callback = fn; return self end

    Connect(keyBtn.MouseButton1Click, function()
        if e.Disabled then return end
        listening = true
        keyBtn.Text = "..."
        tw(keyStroke, { Color = Theme.Accent, Transparency = 0 }, 0.15)
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if listening then
            -- Escape clears the bind; anything else becomes it.
            if input.KeyCode == Enum.KeyCode.Escape then
                listening = false
                tw(keyStroke, { Color = Theme.Stroke, Transparency = 0.3 }, 0.15)
                e:SetValue(nil)
                return
            end
            local chosen
            if input.UserInputType == Enum.UserInputType.Keyboard then
                chosen = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                chosen = input.UserInputType
            end
            if chosen then
                listening = false
                tw(keyStroke, { Color = Theme.Stroke, Transparency = 0.3 }, 0.15)
                e:SetValue(chosen)
            end
            return
        end

        if gpe or e.Disabled or not e.Value then return end
        local matches = (input.KeyCode == e.Value) or (input.UserInputType == e.Value)
        if not matches then return end

        if e.Mode == "Toggle" then
            e.Active = not e.Active
            fire(e.Callback, e.Active)
        elseif e.Mode == "Hold" then
            e.Active = true
            fire(e.Callback, true)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if listening or e.Disabled or not e.Value then return end
        if e.Mode ~= "Hold" then return end
        local matches = (input.KeyCode == e.Value) or (input.UserInputType == e.Value)
        if matches then
            e.Active = false
            fire(e.Callback, false)
        end
    end)

    function e:GetConfigValue() return { key = self.Value, mode = self.Mode } end
    function e:SetConfigValue(v)
        if type(v) == "table" then
            self:SetValue(v.key, true)
            self:SetMode(v.mode or self.Mode)
        else
            self:SetValue(v, true)
        end
    end

    bindFlag(e, flag, key)
    return e
end

--#endregion

--#region ── overlay popups (dropdown, colorpicker) ────────────────────────────

--- Shared popup plumbing: anchor a panel to a control, flip it when it would
--- fall off screen, and close it on any outside click.
local function OpenPopup(window, anchor, width, height, build)
    local overlay = window.Overlay
    if window._popup then window._popup:Close() end

    local panel = New("CanvasGroup", {
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 600,
        Parent = overlay,
    })

    local body = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Parent = panel,
    })
    Paint(body, { BackgroundColor3 = "Elevated" })
    Corner(body, 8)
    Stroke(body, "Stroke", 1, 0.1)

    -- position relative to the overlay
    local function place()
        if not anchor.Parent then return end
        local ap = anchor.AbsolutePosition
        local asz = anchor.AbsoluteSize
        local op = overlay.AbsolutePosition
        local osz = overlay.AbsoluteSize

        local x = ap.X - op.X + asz.X - width
        x = math.clamp(x, 8, math.max(8, osz.X - width - 8))

        local below = ap.Y - op.Y + asz.Y + 6
        local above = ap.Y - op.Y - height - 6
        local y = below
        if below + height > osz.Y - 8 and above >= 8 then y = above end
        y = math.clamp(y, 8, math.max(8, osz.Y - height - 8))

        panel.Position = UDim2.fromOffset(x, y)
    end
    place()

    local catcher = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 599,
        Parent = overlay,
    })

    local popup = {}
    local closed = false
    local conns  = {}

    --- Connections scoped to this popup. A popup is opened and closed many times
    --- per session, so its handlers must not accumulate on the library-wide list.
    function popup:Connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(conns, c)
        return c
    end

    function popup:Close()
        if closed then return end
        closed = true
        window._popup = nil
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        conns = {}
        tw(panel, { GroupTransparency = 1, Position = panel.Position + UDim2.fromOffset(0, -6) }, 0.14)
        catcher:Destroy()
        task.delay(0.16, function() if panel then panel:Destroy() end end)
    end
    popup.Body  = body
    popup.Panel = panel
    function popup:Resize(h)
        height = h
        panel.Size = UDim2.fromOffset(width, h)
        place()
    end

    popup:Connect(catcher.MouseButton1Click, function() popup:Close() end)
    window._popup = popup

    build(popup)

    panel.Position = panel.Position + UDim2.fromOffset(0, -6)
    place()
    tw(panel, { GroupTransparency = 0 }, 0.16)

    return popup
end

--#endregion

--#region ── element: dropdown ─────────────────────────────────────────────────

function Section:AddDropdown(a, b)
    local flag, opts = norm(a, b)
    local values = opts.Values or opts.Options or {}
    local multi  = opts.Multi == true
    local window = self.Tab.Window

    local function defaultValue()
        if multi then
            local t = {}
            if type(opts.Default) == "table" then
                for _, v in ipairs(opts.Default) do t[v] = true end
            elseif opts.Default then
                t[opts.Default] = true
            end
            return t
        end
        if type(opts.Default) == "number" then return values[opts.Default] end
        if opts.Default ~= nil then return opts.Default end
        return opts.AllowNull == false and values[1] or nil
    end

    local row = Row(self, {
        Title = opts.Title or flag or "Dropdown",
        Description = opts.Description,
        ControlWidth = opts.Width or 148,
        ControlHeight = 26,
    })

    local button = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = row.Control,
    })
    Corner(button, 6)
    Paint(button, { BackgroundColor3 = "Elevated" })
    local bStroke = Stroke(button, "Stroke", 1, 0.25)
    Interactive(button, { Idle = "Elevated" })

    local label = New("TextLabel", {
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = "—",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = button,
    })
    Paint(label, { TextColor3 = "Text" })

    local chevHolder = New("Frame", {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        BackgroundTransparency = 1,
        Parent = button,
    })
    Glyph.Chevron(chevHolder, 14, "Muted")

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Values = values, Multi = multi, Callback = opts.Callback, Type = "Dropdown",
        Value = defaultValue(),
    }, Element)

    local function displayText()
        if multi then
            local picked = {}
            for _, v in ipairs(e.Values) do
                if e.Value[v] then table.insert(picked, tostring(v)) end
            end
            if #picked == 0 then return opts.Placeholder or "None" end
            if #picked > 3 then return #picked .. " selected" end
            return table.concat(picked, ", ")
        end
        if e.Value == nil then return opts.Placeholder or "None" end
        return tostring(e.Value)
    end

    local function refresh()
        label.Text = displayText()
        local empty = (multi and next(e.Value) == nil) or (not multi and e.Value == nil)
        tw(label, { TextColor3 = empty and Theme.Muted or Theme.Text }, 0.15)
    end

    function e:SetValue(v, silent)
        if multi then
            local t = {}
            if type(v) == "table" then
                if #v > 0 then
                    for _, item in ipairs(v) do t[item] = true end
                else
                    for item, on in pairs(v) do if on then t[item] = true end end
                end
            elseif v ~= nil then
                t[v] = true
            end
            setFlag(self, t)
        else
            setFlag(self, v)
        end
        refresh()
        if self._rebuild then self._rebuild() end
        if not silent then fire(self.Callback, self.Value) end
        return self
    end

    function e:SetValues(newValues, silent)
        self.Values = newValues or {}
        if multi then
            local kept = {}
            for _, v in ipairs(self.Values) do if self.Value[v] then kept[v] = true end end
            setFlag(self, kept)
        elseif self.Value ~= nil and not table.find(self.Values, self.Value) then
            setFlag(self, nil)
        end
        refresh()
        if self._rebuild then self._rebuild() end
        if not silent then fire(self.Callback, self.Value) end
        return self
    end
    e.Refresh = e.SetValues

    function e:GetSelected()
        if not multi then return self.Value end
        local out = {}
        for _, v in ipairs(self.Values) do if self.Value[v] then table.insert(out, v) end end
        return out
    end
    function e:OnChanged(fn) self.Callback = fn; return self end

    -- popup
    local ROW_H, MAX_ROWS = 28, 8
    --- Open the menu. Split out from the click handler so the panel can also be
    --- opened from code, which is both a useful API and the only way this path
    --- can be exercised without a real mouse.
    function e:Open()
        if self.Disabled then return self end

        tw(bStroke, { Color = Theme.Accent, Transparency = 0 }, 0.15)
        tw(chevHolder, { Rotation = 180 }, 0.2)

        local searchable = opts.Search == true or #e.Values > 10
        local headerH = searchable and 34 or 0

        local popup = OpenPopup(window, button, math.max(row.Control.AbsoluteSize.X, 160), 40, function(p)
            local searchText = ""

            local list = New("ScrollingFrame", {
                Size = UDim2.new(1, -8, 1, -8 - headerH),
                Position = UDim2.fromOffset(4, 4 + headerH),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 601,
                Parent = p.Body,
            })
            Paint(list, { ScrollBarImageColor3 = "Muted" })
            List(list, 2)

            if searchable then
                local searchBox = New("Frame", {
                    Size = UDim2.new(1, -8, 0, 26),
                    Position = UDim2.fromOffset(4, 4),
                    BorderSizePixel = 0,
                    ZIndex = 601,
                    Parent = p.Body,
                })
                Corner(searchBox, 6)
                Paint(searchBox, { BackgroundColor3 = "Card" })

                local ico = New("Frame", {
                    Size = UDim2.fromOffset(13, 13),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 8, 0.5, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 602,
                    Parent = searchBox,
                })
                Glyph.Search(ico, 13, "Muted")

                local tb = New("TextBox", {
                    Size = UDim2.new(1, -32, 1, 0),
                    Position = UDim2.fromOffset(26, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    PlaceholderText = "Search…",
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    ZIndex = 602,
                    Parent = searchBox,
                })
                Paint(tb, { TextColor3 = "Text", PlaceholderColor3 = "Muted" })
                p:Connect(tb:GetPropertyChangedSignal("Text"), function()
                    searchText = string.lower(tb.Text)
                    if e._rebuild then e._rebuild() end
                end)
                task.defer(function() pcall(function() tb:CaptureFocus() end) end)
            end

            local function build()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("GuiObject") then c:Destroy() end
                end

                local shown = 0
                for i, v in ipairs(e.Values) do
                    local text = tostring(v)
                    if searchText == "" or string.find(string.lower(text), searchText, 1, true) then
                        shown = shown + 1
                        local selected = multi and e.Value[v] == true or (not multi and e.Value == v)

                        local item = New("TextButton", {
                            Size = UDim2.new(1, 0, 0, ROW_H - 2),
                            Text = "",
                            AutoButtonColor = false,
                            BackgroundTransparency = selected and 0 or 1,
                            BorderSizePixel = 0,
                            LayoutOrder = i,
                            ZIndex = 602,
                            Parent = list,
                        })
                        Corner(item, 5)
                        if selected then Paint(item, { BackgroundColor3 = "Accent" }) end

                        local il = New("TextLabel", {
                            Size = UDim2.new(1, -28, 1, 0),
                            Position = UDim2.fromOffset(9, 0),
                            BackgroundTransparency = 1,
                            Text = text,
                            Font = selected and Enum.Font.GothamMedium or Enum.Font.Gotham,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 603,
                            Parent = item,
                        })
                        Paint(il, { TextColor3 = selected and "AccentText" or "SubText" })

                        if selected then
                            local ck = New("Frame", {
                                Size = UDim2.fromOffset(12, 12),
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -9, 0.5, 0),
                                BackgroundTransparency = 1,
                                ZIndex = 603,
                                Parent = item,
                            })
                            Glyph.Check(ck, 12, "AccentText")
                        end

                        if not selected then
                            p:Connect(item.MouseEnter, function()
                                tw(item, { BackgroundTransparency = 0 }, 0.12)
                                item.BackgroundColor3 = Theme.Hover
                            end)
                            p:Connect(item.MouseLeave, function()
                                tw(item, { BackgroundTransparency = 1 }, 0.12)
                            end)
                        end

                        p:Connect(item.MouseButton1Click, function()
                            if multi then
                                local t = {}
                                for k, on in pairs(e.Value) do t[k] = on end
                                t[v] = not t[v] or nil
                                e:SetValue(t)
                            else
                                if e.Value == v and opts.AllowNull ~= false then
                                    e:SetValue(nil)
                                else
                                    e:SetValue(v)
                                end
                                if not multi then p:Close() end
                            end
                        end)
                    end
                end

                if shown == 0 then
                    local empty = New("TextLabel", {
                        Size = UDim2.new(1, 0, 0, ROW_H),
                        BackgroundTransparency = 1,
                        Text = "No results",
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        ZIndex = 602,
                        Parent = list,
                    })
                    Paint(empty, { TextColor3 = "Muted" })
                    shown = 1
                end

                p:Resize(math.min(shown, MAX_ROWS) * ROW_H + 8 + headerH)
            end

            e._rebuild = build
            build()
        end)

        local closeFn = popup.Close
        popup.Close = function(...)
            e._rebuild = nil
            tw(bStroke, { Color = Theme.Stroke, Transparency = 0.25 }, 0.15)
            tw(chevHolder, { Rotation = 0 }, 0.2)
            return closeFn(...)
        end
        return self
    end

    function e:Close()
        if window._popup then window._popup:Close() end
        return self
    end

    Connect(button.MouseButton1Click, function()
        if e.Disabled then return end
        if window._popup then window._popup:Close() else e:Open() end
    end)

    bindFlag(e, flag, e.Value)
    refresh()
    if opts.Default ~= nil then fire(opts.Callback, e.Value) end
    return e
end

--#endregion

--#region ── element: colorpicker ──────────────────────────────────────────────

function Section:AddColorpicker(a, b)
    local flag, opts = norm(a, b)
    local window = self.Tab.Window
    local color  = opts.Default or Color3.fromRGB(255, 255, 255)
    local alpha  = opts.Transparency or 0
    local useAlpha = opts.Transparency ~= nil

    local row = Row(self, {
        Title = opts.Title or flag or "Color",
        Description = opts.Description,
        ControlWidth = 44,
        ControlHeight = 24,
    })

    local swatchBtn = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = row.Control,
    })
    Corner(swatchBtn, 6)
    Stroke(swatchBtn, "Stroke", 1, 0.2)

    local e = setmetatable({
        Holder = row.Holder, TitleLabel = row.TitleLabel, DescLabel = row.DescLabel,
        Value = color, Transparency = alpha, Callback = opts.Callback, Type = "Colorpicker",
    }, Element)

    function e:SetValue(v, silent)
        if typeof(v) == "Color3" then setFlag(self, v) end
        swatchBtn.BackgroundColor3 = self.Value
        swatchBtn.BackgroundTransparency = self.Transparency or 0
        if self._sync then self._sync() end
        if not silent then fire(self.Callback, self.Value, self.Transparency) end
        return self
    end

    function e:SetTransparency(t, silent)
        self.Transparency = clamp01(t or 0)
        return self:SetValue(self.Value, silent)
    end
    function e:OnChanged(fn) self.Callback = fn; return self end

    function e:GetConfigValue()
        return { color = self.Value, transparency = self.Transparency }
    end
    function e:SetConfigValue(v)
        if type(v) == "table" then
            self.Transparency = v.transparency or 0
            self:SetValue(v.color, true)
        else
            self:SetValue(v, true)
        end
    end

    --- Same split as the dropdown: the panel is openable from code.
    function e:Open()
        if self.Disabled then return self end

        local H, S, V = Color3.toHSV(e.Value)
        local panelH = useAlpha and 232 or 208

        OpenPopup(window, swatchBtn, 224, panelH, function(p)
            local content = New("Frame", {
                Size = UDim2.new(1, -20, 1, -20),
                Position = UDim2.fromOffset(10, 10),
                BackgroundTransparency = 1,
                ZIndex = 601,
                Parent = p.Body,
            })

            -- SV square: hue base + white gradient (x) + black gradient (y)
            local square = New("Frame", {
                Size = UDim2.new(1, 0, 0, 118),
                BackgroundColor3 = Color3.fromHSV(H, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 601,
                Parent = content,
            })
            Corner(square, 6)

            local whiteLayer = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 602,
                Parent = square,
            })
            Corner(whiteLayer, 6)
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = whiteLayer,
            })

            local blackLayer = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 603,
                Parent = square,
            })
            Corner(blackLayer, 6)
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Parent = blackLayer,
            })

            local cursor = New("Frame", {
                Size = UDim2.fromOffset(12, 12),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 605,
                Parent = square,
            })
            Corner(cursor, 99)
            New("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0),
                              Transparency = 0.65, Parent = cursor })

            -- hue bar
            local hueBar = New("Frame", {
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.fromOffset(0, 128),
                BorderSizePixel = 0,
                ZIndex = 601,
                Parent = content,
            })
            Corner(hueBar, 7)
            New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,   0,   0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,   0,   0)),
                }),
                Parent = hueBar,
            })

            local hueKnob = New("Frame", {
                Size = UDim2.fromOffset(6, 18),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(H, 0, 0.5, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 602,
                Parent = hueBar,
            })
            Corner(hueKnob, 3)
            New("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0),
                              Transparency = 0.6, Parent = hueKnob })

            local alphaBar, alphaKnob
            if useAlpha then
                alphaBar = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.fromOffset(0, 150),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 601,
                    Parent = content,
                })
                Corner(alphaBar, 7)
                New("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    Parent = alphaBar,
                })
                alphaKnob = New("Frame", {
                    Size = UDim2.fromOffset(6, 18),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(e.Transparency, 0, 0.5, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 602,
                    Parent = alphaBar,
                })
                Corner(alphaKnob, 3)
                New("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0),
                                  Transparency = 0.6, Parent = alphaKnob })
            end

            -- hex field
            local hexRow = New("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                Position = UDim2.fromOffset(0, useAlpha and 174 or 152),
                BorderSizePixel = 0,
                ZIndex = 601,
                Parent = content,
            })
            Corner(hexRow, 6)
            Paint(hexRow, { BackgroundColor3 = "Card" })

            local hexBox = New("TextBox", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = "#FFFFFF",
                Font = Enum.Font.Code,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 602,
                Parent = hexRow,
            })
            Paint(hexBox, { TextColor3 = "Text" })

            local function apply(silent)
                local c = Color3.fromHSV(H, S, V)
                e.Value = c
                if e.Flag then Cyz.Flags[e.Flag] = c end
                square.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                cursor.Position = UDim2.fromScale(S, 1 - V)
                hueKnob.Position = UDim2.new(H, 0, 0.5, 0)
                if alphaBar then
                    alphaBar.BackgroundColor3 = c
                    alphaKnob.Position = UDim2.new(e.Transparency, 0, 0.5, 0)
                end
                if not hexBox:IsFocused() then
                    hexBox.Text = string.format("#%02X%02X%02X",
                        math.floor(c.R * 255 + 0.5),
                        math.floor(c.G * 255 + 0.5),
                        math.floor(c.B * 255 + 0.5))
                end
                swatchBtn.BackgroundColor3 = c
                swatchBtn.BackgroundTransparency = e.Transparency or 0
                if not silent then fire(e.Callback, c, e.Transparency) end
            end

            e._sync = function()
                H, S, V = Color3.toHSV(e.Value)
                apply(true)
            end

            -- drag helpers
            local function dragSurface(surface, onMove)
                local active = false
                p:Connect(surface.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        active = true
                        onMove(input.Position)
                    end
                end)
                p:Connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then active = false end
                end)
                p:Connect(UserInputService.InputChanged, function(input)
                    if not active then return end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        onMove(input.Position)
                    end
                end)
            end

            local squareHit = New("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                Text = "", ZIndex = 604, Parent = square,
            })
            dragSurface(squareHit, function(pos)
                S = clamp01((pos.X - square.AbsolutePosition.X) / math.max(1, square.AbsoluteSize.X))
                V = 1 - clamp01((pos.Y - square.AbsolutePosition.Y) / math.max(1, square.AbsoluteSize.Y))
                apply()
            end)

            local hueHit = New("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                Text = "", ZIndex = 603, Parent = hueBar,
            })
            dragSurface(hueHit, function(pos)
                H = clamp01((pos.X - hueBar.AbsolutePosition.X) / math.max(1, hueBar.AbsoluteSize.X))
                apply()
            end)

            if alphaBar then
                local alphaHit = New("TextButton", {
                    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                    Text = "", ZIndex = 603, Parent = alphaBar,
                })
                dragSurface(alphaHit, function(pos)
                    e.Transparency = clamp01(
                        (pos.X - alphaBar.AbsolutePosition.X) / math.max(1, alphaBar.AbsoluteSize.X))
                    apply()
                end)
            end

            p:Connect(hexBox.FocusLost, function()
                local hex = string.gsub(hexBox.Text, "#", "")
                if #hex == 6 and string.match(hex, "^%x+$") then
                    local r = tonumber(string.sub(hex, 1, 2), 16)
                    local g = tonumber(string.sub(hex, 3, 4), 16)
                    local bl = tonumber(string.sub(hex, 5, 6), 16)
                    H, S, V = Color3.toHSV(Color3.fromRGB(r, g, bl))
                    apply()
                else
                    apply(true)
                end
            end)

            apply(true)
        end)
        return self
    end

    function e:Close()
        if window._popup then window._popup:Close() end
        return self
    end

    Connect(swatchBtn.MouseButton1Click, function()
        if e.Disabled then return end
        if window._popup then window._popup:Close() else e:Open() end
    end)

    bindFlag(e, flag, color)
    e:SetValue(color, true)
    return e
end

Section.AddColorPicker = Section.AddColorpicker

--#endregion

--#region ── element: theme picker ─────────────────────────────────────────────

--- A grid of theme swatches. Each chip paints itself in the colours of the theme
--- it offers, so the choice is visible before it is made. The chip colours are
--- literal on purpose: they must show their own theme, not the active one.
function Section:AddThemePicker(opts)
    opts = opts or {}
    local names = opts.Values or Cyz:ListThemes()

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_NextOrder(),
        Parent = self.Container,
    })

    local grid = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = holder,
    })
    New("UIGridLayout", {
        CellSize        = UDim2.new(0.5, -4, 0, 46),
        CellPadding     = UDim2.fromOffset(8, 8),
        FillDirection   = Enum.FillDirection.Horizontal,
        SortOrder       = Enum.SortOrder.LayoutOrder,
        Parent          = grid,
    })

    local chips = {}

    local function paintChip(name)
        local chip = chips[name]
        if not chip then return end
        local selected = Cyz:GetThemeName() == name
        tw(chip.Stroke, {
            Color = selected and chip.Theme.Accent or chip.Theme.Stroke,
            Thickness = selected and 2 or 1,
            Transparency = selected and 0 or 0.35,
        }, 0.16)
        tw(chip.Tick, { Size = UDim2.fromOffset(selected and 12 or 0, selected and 12 or 0) }, 0.2,
           Enum.EasingStyle.Back)
    end

    local function refresh()
        for name in pairs(chips) do paintChip(name) end
    end

    for i, name in ipairs(names) do
        local themeData = Themes[name]
        if themeData then
            local chip = New("TextButton", {
                Size = UDim2.fromScale(1, 1),
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = themeData.Card,
                BorderSizePixel = 0,
                LayoutOrder = i,
                Parent = grid,
            })
            Corner(chip, 8)
            local stroke = New("UIStroke", {
                Thickness = 1,
                Transparency = 0.35,
                Color = themeData.Stroke,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = chip,
            })

            -- accent swatch
            local swatch = New("Frame", {
                Size = UDim2.fromOffset(22, 22),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 11, 0.5, 0),
                BackgroundColor3 = themeData.Accent,
                BorderSizePixel = 0,
                Parent = chip,
            })
            Corner(swatch, 7)

            -- a sliver of the window colour, so dark and light themes read apart
            local base = New("Frame", {
                Size = UDim2.fromOffset(8, 22),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 11, 0.5, 0),
                BackgroundColor3 = themeData.Window,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = chip,
            })
            Corner(base, 4)

            local label = New("TextLabel", {
                Size = UDim2.new(1, -62, 1, 0),
                Position = UDim2.fromOffset(41, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextSize = 12.5,
                TextColor3 = themeData.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = chip,
            })

            -- Without clipping, the checkmark child keeps rendering at full size
            -- while the holder is scaled to zero, so every chip shows a tick.
            local tickHolder = New("Frame", {
                Size = UDim2.fromOffset(0, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -11, 0.5, 0),
                BackgroundColor3 = themeData.Accent,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = chip,
            })
            Corner(tickHolder, 99)
            Glyph.Check(tickHolder, 9, themeData.AccentText)

            chips[name] = { Button = chip, Stroke = stroke, Tick = tickHolder, Theme = themeData }

            Connect(chip.MouseEnter, function()
                if Cyz:GetThemeName() ~= name then
                    tw(stroke, { Transparency = 0, Color = themeData.Accent }, 0.14)
                end
                tw(chip, { BackgroundColor3 = themeData.Hover }, 0.14)
            end)
            Connect(chip.MouseLeave, function()
                tw(chip, { BackgroundColor3 = themeData.Card }, 0.14)
                paintChip(name)
            end)
            Connect(chip.MouseButton1Click, function()
                Cyz:SetTheme(name)
                if opts.Callback then fire(opts.Callback, name) end
            end)
        end
    end

    table.insert(Cyz._themeListeners, refresh)
    refresh()

    local e = setmetatable({ Holder = holder, Type = "ThemePicker" }, Element)
    e.IgnoreConfig = true
    function e:Refresh() refresh() end
    return e
end

--#endregion

--#region ── addons: toggle+keybind / toggle+color on one row ──────────────────

--- Attach a compact keybind to an existing toggle, Linoria-style.
function Element:AddKeyPicker(a, b)
    local flag, opts = norm(a, b)
    if not self.Holder then return self end

    local card = self.Holder:FindFirstChildWhichIsA("GuiObject")
    -- place a small pill left of the existing control
    local pill = New("TextButton", {
        Size = UDim2.fromOffset(42, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -56, 0.5, 0),
        Text = keyName(toKey(opts.Default)),
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = card,
    })
    Corner(pill, 5)
    Paint(pill, { BackgroundColor3 = "Elevated", TextColor3 = "SubText" })
    local st = Stroke(pill, "Stroke", 1, 0.35)

    local sub = setmetatable({
        Value = toKey(opts.Default), Mode = opts.Mode or "Toggle",
        Active = (opts.Mode or "Toggle") == "Always",
        Callback = opts.Callback, Type = "Keybind",
    }, Element)

    local listening = false
    function sub:SetValue(v, silent)
        local k = toKey(v)
        setFlag(self, k)
        pill.Text = listening and "..." or keyName(k)
        if not silent then fire(self.Callback, k) end
        return self
    end
    function sub:GetConfigValue() return { key = self.Value, mode = self.Mode } end
    function sub:SetConfigValue(v)
        if type(v) == "table" then self:SetValue(v.key, true); self.Mode = v.mode or self.Mode
        else self:SetValue(v, true) end
    end

    Connect(pill.MouseButton1Click, function()
        listening = true
        pill.Text = "..."
        tw(st, { Color = Theme.Accent, Transparency = 0 }, 0.15)
    end)

    local owner = self
    Connect(UserInputService.InputBegan, function(input, gpe)
        if listening then
            if input.KeyCode == Enum.KeyCode.Escape then
                listening = false
                tw(st, { Color = Theme.Stroke, Transparency = 0.35 }, 0.15)
                sub:SetValue(nil)
                return
            end
            local chosen
            if input.UserInputType == Enum.UserInputType.Keyboard then chosen = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then chosen = input.UserInputType end
            if chosen then
                listening = false
                tw(st, { Color = Theme.Stroke, Transparency = 0.35 }, 0.15)
                sub:SetValue(chosen)
            end
            return
        end
        if gpe or not sub.Value then return end
        if input.KeyCode == sub.Value or input.UserInputType == sub.Value then
            if sub.Mode == "Toggle" then
                if owner.Toggle then owner:Toggle() end
            elseif sub.Mode == "Hold" then
                if owner.SetValue then owner:SetValue(true) end
            end
            fire(sub.Callback, sub.Value)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if sub.Mode ~= "Hold" or not sub.Value then return end
        if input.KeyCode == sub.Value or input.UserInputType == sub.Value then
            if owner.SetValue then owner:SetValue(false) end
        end
    end)

    bindFlag(sub, flag, sub.Value)
    self.KeyPicker = sub
    return self
end

--#endregion

--#region ── section factory ───────────────────────────────────────────────────

local function CreateSection(tab, title, opts)
    opts = opts or {}
    local self = setmetatable({ Tab = tab, _order = 0 }, Section)

    local holder = New("Frame", {
        Name = "Section_" .. tostring(title or "?"),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = tab:_NextOrder(),
        Parent = tab.Page,
    })
    List(holder, 8)

    if title then
        local head = New("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Parent = holder,
        })
        local bullet = Glyph.Dot(head, 4, "Accent")
        bullet.AnchorPoint = Vector2.new(0, 0.5)
        bullet.Position = UDim2.new(0, 1, 0.5, 0)

        local label = New("TextLabel", {
            Size = UDim2.new(1, -14, 1, 0),
            Position = UDim2.fromOffset(14, 0),
            BackgroundTransparency = 1,
            Text = tostring(title),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = head,
        })
        Paint(label, { TextColor3 = "SubText" })
        self.TitleLabel = label
    end

    local container = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = holder,
    })
    List(container, 6)

    self.Holder    = holder
    self.Container = container

    function self:SetTitle(v) if self.TitleLabel then self.TitleLabel.Text = tostring(v) end; return self end
    function self:SetVisible(v) holder.Visible = v ~= false; return self end
    function self:Destroy() holder:Destroy() end

    return self
end

--#endregion

--#region ── tab ───────────────────────────────────────────────────────────────

local Tab = {}
Tab.__index = Tab

function Tab:_NextOrder()
    self._order = (self._order or 0) + 1
    return self._order
end

function Tab:AddSection(title, opts)
    if type(title) == "table" then opts = title; title = opts.Title end
    return CreateSection(self, title, opts)
end
Tab.AddGroupbox = Tab.AddSection
Tab.CreateSection = Tab.AddSection

--- Elements added straight to a tab land in an implicit untitled section.
function Tab:_Default()
    if not self._defaultSection then
        self._defaultSection = CreateSection(self, nil, {})
    end
    return self._defaultSection
end

for _, name in ipairs({
    "AddButton", "AddToggle", "AddSlider", "AddInput", "AddTextbox",
    "AddDropdown", "AddColorpicker", "AddColorPicker", "AddKeybind",
    "AddLabel", "AddParagraph", "AddDivider", "AddThemePicker",
}) do
    Tab[name] = function(self, ...)
        local section = self:_Default()
        return section[name](section, ...)
    end
end

function Tab:Select() return self.Window:SelectTab(self) end
function Tab:SetTitle(v)
    self.Title = v
    if self.ButtonLabel then self.ButtonLabel.Text = tostring(v) end
    return self
end
function Tab:SetVisible(v)
    if self.Button then self.Button.Visible = v ~= false end
    return self
end
function Tab:Destroy()
    if self.Button then self.Button:Destroy() end
    if self.Page then self.Page:Destroy() end
    local idx = table.find(self.Window.Tabs, self)
    if idx then table.remove(self.Window.Tabs, idx) end
end

--#endregion

--#region ── window ────────────────────────────────────────────────────────────

local Window = {}
Window.__index = Window

local SIDEBAR_W = 168
local TOPBAR_H  = 42

function Cyz:CreateWindow(opts)
    opts = opts or {}
    if opts.Theme then Cyz:SetTheme(opts.Theme) end
    if opts.ConfigFolder then Cyz:SetConfigFolder(opts.ConfigFolder) end

    local self = setmetatable({
        Tabs = {}, _tabOrder = 0, Minimized = false, Visible = true,
    }, Window)

    local size = opts.Size or UDim2.fromOffset(IS_MOBILE and 520 or 700, IS_MOBILE and 360 or 470)
    local minSize = opts.MinSize or Vector2.new(480, 320)
    local maxSize = opts.MaxSize or Vector2.new(1400, 900)

    -- root canvas group so open/close can fade the whole window at once
    local root = New("CanvasGroup", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = opts.Position or UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    local scale = New("UIScale", { Scale = 0.94, Parent = root })

    local shell = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    Paint(shell, { BackgroundColor3 = "Window" })
    Corner(shell, 12)
    Stroke(shell, "Stroke", 1, 0.15)

    -- A subtle top sheen, as its own layer. It must NOT be a UIGradient on the
    -- shell: a gradient's Transparency multiplies the object's own background,
    -- so putting it here would make the whole window see-through below the
    -- gradient's first keypoint.
    local sheen = New("Frame", {
        Size = UDim2.new(1, 0, 0, 96),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = shell,
    })
    Corner(sheen, 12)
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.955),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent = sheen,
    })

    ---------------------------------------------------------------- sidebar --
    local sidebar = New("Frame", {
        Size = UDim2.new(0, SIDEBAR_W, 1, 0),
        BorderSizePixel = 0,
        Parent = shell,
    })
    Paint(sidebar, { BackgroundColor3 = "Sidebar" })

    local sideEdge = New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.5,
        Parent = sidebar,
    })
    Paint(sideEdge, { BackgroundColor3 = "Stroke" })

    -- brand
    local brand = New("Frame", {
        Size = UDim2.new(1, 0, 0, TOPBAR_H + 8),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    Pad(brand, 0, 0, 16, 12)

    local mark = New("Frame", {
        Size = UDim2.fromOffset(26, 26),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        Parent = brand,
    })
    Corner(mark, 8)
    Paint(mark, { BackgroundColor3 = "Accent" })
    local markLabel = New("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = string.upper(string.sub(tostring(opts.Title or "C"), 1, 1)),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = mark,
    })
    Paint(markLabel, { TextColor3 = "AccentText" })

    local titleLabel = New("TextLabel", {
        Size = UDim2.new(1, -36, 0, 15),
        Position = UDim2.new(0, 34, 0.5, -10),
        BackgroundTransparency = 1,
        Text = tostring(opts.Title or "cyz"),
        Font = Enum.Font.GothamBold,
        TextSize = 13.5,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = brand,
    })
    Paint(titleLabel, { TextColor3 = "Text" })

    local subLabel = New("TextLabel", {
        Size = UDim2.new(1, -36, 0, 12),
        Position = UDim2.new(0, 34, 0.5, 4),
        BackgroundTransparency = 1,
        Text = tostring(opts.SubTitle or opts.Subtitle or ""),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = brand,
    })
    Paint(subLabel, { TextColor3 = "Muted" })

    local tabList = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -(TOPBAR_H + 8) - 34),
        Position = UDim2.fromOffset(0, TOPBAR_H + 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar,
    })
    Paint(tabList, { ScrollBarImageColor3 = "Stroke" })
    Pad(tabList, 4, 8, 10, 10)
    List(tabList, 3)

    -- sidebar footer: theme + version
    local footer = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 1, -34),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    Pad(footer, 0, 8, 14, 12)
    local footLabel = New("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "cyz v" .. Cyz.Version,
        Font = Enum.Font.Gotham,
        TextSize = 10.5,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })
    Paint(footLabel, { TextColor3 = "Muted" })

    ----------------------------------------------------------------- topbar --
    local topbar = New("Frame", {
        Size = UDim2.new(1, -SIDEBAR_W, 0, TOPBAR_H),
        Position = UDim2.fromOffset(SIDEBAR_W, 0),
        BackgroundTransparency = 1,
        Parent = shell,
    })

    local topEdge = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.5,
        Parent = topbar,
    })
    Paint(topEdge, { BackgroundColor3 = "Stroke" })

    local crumb = New("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.fromOffset(18, 0),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = topbar,
    })
    Paint(crumb, { TextColor3 = "Text" })

    local function controlButton(offsetX, glyphFn, tooltip)
        local btn = New("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, offsetX, 0.5, 0),
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = topbar,
        })
        Corner(btn, 7)
        local g = glyphFn(btn, 11, "Muted")
        Connect(btn.MouseEnter, function()
            tw(btn, { BackgroundTransparency = 0 }, 0.14)
            btn.BackgroundColor3 = Theme.Hover
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("Frame") then tw(d, { BackgroundColor3 = Theme.Text }, 0.14) end
            end
            if g:IsA("Frame") and #g:GetChildren() == 0 then tw(g, { BackgroundColor3 = Theme.Text }, 0.14) end
        end)
        Connect(btn.MouseLeave, function()
            tw(btn, { BackgroundTransparency = 1 }, 0.14)
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("Frame") then tw(d, { BackgroundColor3 = Theme.Muted }, 0.14) end
            end
        end)
        return btn, g
    end

    local closeBtn = controlButton(-10, Glyph.Close)
    local minBtn   = controlButton(-42, Glyph.Minimize)

    ---------------------------------------------------------------- content --
    local content = New("Frame", {
        Size = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H),
        Position = UDim2.fromOffset(SIDEBAR_W, TOPBAR_H),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = shell,
    })

    -- overlay for popups: sibling of content so popups escape its clipping
    local overlay = New("Frame", {
        Name = "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 500,
        Parent = shell,
    })

    -- resize grip
    local grip = New("TextButton", {
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 520,
        Visible = opts.Resizable ~= false and not IS_MOBILE,
        Parent = shell,
    })
    for i = 1, 3 do
        local d = New("Frame", {
            Size = UDim2.fromOffset(3, 3),
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -3, 1, -3 - (i - 1) * 4),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.4,
            Parent = grip,
        })
        Corner(d, 1)
        Paint(d, { BackgroundColor3 = "Muted" })
    end

    self.Root     = root
    self.Shell    = shell
    self.Sidebar  = sidebar
    self.Topbar   = topbar
    self.Content  = content
    self.Overlay  = overlay
    self.TabList  = tabList
    self.Crumb    = crumb
    self.Scale    = scale

    Draggable(topbar, root)
    Draggable(brand, root)
    Resizable(grip, root, minSize, maxSize, function() if self._popup then self._popup:Close() end end)

    ---------------------------------------------------------------- toggles --
    function self:Toggle(state)
        if state == nil then state = not self.Visible end
        self.Visible = state
        if self._popup then self._popup:Close() end
        if state then
            root.Visible = true
            tw(root, { GroupTransparency = 0 }, 0.22)
            tw(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
            Acrylic:SetShown(true)
        else
            tw(root, { GroupTransparency = 1 }, 0.18)
            tw(scale, { Scale = 0.94 }, 0.2)
            Acrylic:SetShown(false)
            task.delay(0.2, function() if not self.Visible then root.Visible = false end end)
        end
        if self.ToggleButton then
            self.ToggleButton.Visible = not state
        end
        return self
    end

    function self:Minimize(state)
        if state == nil then state = not self.Minimized end
        self.Minimized = state
        if self._popup then self._popup:Close() end
        if state then
            self._restoreSize = root.Size
            tw(root, { Size = UDim2.fromOffset(root.AbsoluteSize.X, TOPBAR_H + 8) }, 0.28)
        else
            tw(root, { Size = self._restoreSize or size }, 0.28)
        end
        return self
    end

    Connect(closeBtn.MouseButton1Click, function()
        if opts.OnClose then fire(opts.OnClose) end
        if opts.DestroyOnClose then Cyz:Destroy() else self:Toggle(false) end
    end)
    Connect(minBtn.MouseButton1Click, function() self:Minimize() end)

    -- mobile / always-available reopen chip
    if opts.ToggleButton ~= false then
        local chip = New("TextButton", {
            Name = "cyz_chip",
            Size = UDim2.fromOffset(46, 46),
            Position = opts.ToggleButtonPosition or UDim2.fromOffset(18, 18),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 4500,
            Parent = ScreenGui,
        })
        Corner(chip, 14)
        Paint(chip, { BackgroundColor3 = "Accent" })
        Stroke(chip, "AccentHover", 1, 0.4)
        local chipLabel = New("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = string.upper(string.sub(tostring(opts.Title or "C"), 1, 1)),
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            ZIndex = 4501,
            Parent = chip,
        })
        Paint(chipLabel, { TextColor3 = "AccentText" })
        Draggable(chip, chip)
        Connect(chip.MouseButton1Click, function() self:Toggle(true) end)
        self.ToggleButton = chip
    end

    -- keyboard toggle
    local toggleKey = opts.ToggleKey or opts.MenuKeybind or Enum.KeyCode.RightShift
    if type(toggleKey) == "string" then toggleKey = Enum.KeyCode[toggleKey] end
    self.ToggleKey = toggleKey
    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if self.ToggleKey and input.KeyCode == self.ToggleKey then self:Toggle() end
    end)
    function self:SetToggleKey(k) self.ToggleKey = toKey(k); return self end

    ------------------------------------------------------------------- tabs --
    function self:AddTab(tabOpts)
        if type(tabOpts) == "string" then tabOpts = { Title = tabOpts } end
        tabOpts = tabOpts or {}

        local tab = setmetatable({
            Window = self, Title = tabOpts.Title or "Tab", _order = 0,
        }, Tab)

        self._tabOrder = self._tabOrder + 1

        local btn = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = self._tabOrder,
            Parent = tabList,
        })
        Corner(btn, 7)

        local marker = Glyph.Pill(btn)
        marker.Size = UDim2.fromOffset(3, 0)
        marker.Position = UDim2.new(0, -6, 0.5, 0)

        local iconHolder
        if tabOpts.Icon then
            iconHolder = New("Frame", {
                Size = UDim2.fromOffset(16, 16),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 8, 0.5, 0),
                BackgroundTransparency = 1,
                Parent = btn,
            })
            RenderIcon(iconHolder, tabOpts.Icon, 16, "Muted")
        end

        local label = New("TextLabel", {
            Size = UDim2.new(1, -(iconHolder and 34 or 20), 1, 0),
            Position = UDim2.fromOffset(iconHolder and 32 or 11, 0),
            BackgroundTransparency = 1,
            Text = tostring(tab.Title),
            Font = Enum.Font.GothamMedium,
            TextSize = 12.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        Paint(label, { TextColor3 = "SubText" })

        local page = New("ScrollingFrame", {
            Name = "Page_" .. tostring(tab.Title),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            Parent = content,
        })
        Paint(page, { ScrollBarImageColor3 = "Stroke" })
        Pad(page, 16, 20, 18, 16)
        List(page, 14)

        tab.Button      = btn
        tab.ButtonLabel = label
        tab.Marker      = marker
        tab.Page        = page
        tab.Icon        = iconHolder

        local hovered = false
        Connect(btn.MouseEnter, function()
            hovered = true
            if self.ActiveTab ~= tab then
                tw(btn, { BackgroundTransparency = 0 }, 0.14)
                btn.BackgroundColor3 = Theme.Hover
                tw(label, { TextColor3 = Theme.Text }, 0.14)
            end
        end)
        Connect(btn.MouseLeave, function()
            hovered = false
            if self.ActiveTab ~= tab then
                tw(btn, { BackgroundTransparency = 1 }, 0.14)
                tw(label, { TextColor3 = Theme.SubText }, 0.14)
            end
        end)
        Connect(btn.MouseButton1Click, function() self:SelectTab(tab) end)

        table.insert(self.Tabs, tab)
        if not self.ActiveTab then self:SelectTab(tab) end
        return tab
    end
    self.CreateTab = self.AddTab

    function self:SelectTab(target)
        if type(target) == "number" then target = self.Tabs[target] end
        if type(target) == "string" then
            for _, t in ipairs(self.Tabs) do
                if t.Title == target then target = t; break end
            end
        end
        if type(target) ~= "table" or not target.Page then return self end
        if self._popup then self._popup:Close() end

        for _, t in ipairs(self.Tabs) do
            local active = t == target
            t.Page.Visible = active
            tw(t.Button, { BackgroundTransparency = active and 0 or 1 }, 0.16)
            if active then t.Button.BackgroundColor3 = Theme.Active end
            tw(t.ButtonLabel, { TextColor3 = active and Theme.Text or Theme.SubText }, 0.16)
            tw(t.Marker, { Size = UDim2.fromOffset(3, active and 16 or 0) }, 0.22,
               Enum.EasingStyle.Back)
            if t.Icon then
                for _, d in ipairs(t.Icon:GetDescendants()) do
                    if d:IsA("Frame") then
                        tw(d, { BackgroundColor3 = active and Theme.Accent or Theme.Muted }, 0.16)
                    elseif d:IsA("ImageLabel") then
                        tw(d, { ImageColor3 = active and Theme.Accent or Theme.Muted }, 0.16)
                    end
                end
                if t.Icon:FindFirstChildWhichIsA("ImageLabel") then
                    tw(t.Icon:FindFirstChildWhichIsA("ImageLabel"),
                       { ImageColor3 = active and Theme.Accent or Theme.Muted }, 0.16)
                end
            end
        end

        -- slide the new page in
        target.Page.Position = UDim2.fromOffset(0, 10)
        tw(target.Page, { Position = UDim2.fromOffset(0, 0) }, 0.26)

        self.ActiveTab = target
        crumb.Text = tostring(target.Title)
        return self
    end

    ---------------------------------------------------------------- dialogs --
    function self:Dialog(dOpts)
        dOpts = dOpts or {}
        if self._popup then self._popup:Close() end

        local scrim = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 800,
            Parent = shell,
        })
        tw(scrim, { BackgroundTransparency = 0.5 }, 0.2)

        local box = New("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(dOpts.Width or 320, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            ZIndex = 801,
            Parent = shell,
        })
        local boxScale = New("UIScale", { Scale = 0.92, Parent = box })

        local body = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
            ZIndex = 801,
            Parent = box,
        })
        Paint(body, { BackgroundColor3 = "Elevated" })
        Corner(body, 12)
        Stroke(body, "Stroke", 1, 0.1)
        Pad(body, 16, 14, 16, 16)
        List(body, 8)

        local dTitle = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 17),
            BackgroundTransparency = 1,
            Text = tostring(dOpts.Title or "Confirm"),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            ZIndex = 802,
            Parent = body,
        })
        Paint(dTitle, { TextColor3 = "Text" })

        if dOpts.Content or dOpts.Description then
            local dBody = New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = tostring(dOpts.Content or dOpts.Description),
                Font = Enum.Font.Gotham,
                TextSize = 12.5,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 2,
                ZIndex = 802,
                Parent = body,
            })
            Paint(dBody, { TextColor3 = "SubText" })
        end

        local btnRow = New("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            ZIndex = 802,
            Parent = body,
        })
        local rowLayout = List(btnRow, 8, Enum.FillDirection.Horizontal)
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

        local dialog = {}
        function dialog:Close()
            tw(scrim, { BackgroundTransparency = 1 }, 0.16)
            tw(box, { GroupTransparency = 1 }, 0.16)
            tw(boxScale, { Scale = 0.94 }, 0.16)
            task.delay(0.18, function()
                if scrim then scrim:Destroy() end
                if box then box:Destroy() end
            end)
        end
        Connect(scrim.MouseButton1Click, function()
            if dOpts.Dismissable ~= false then dialog:Close() end
        end)

        local buttons = dOpts.Buttons or { { Title = "OK" } }
        for i, b in ipairs(buttons) do
            local primary = b.Primary == true or (i == #buttons and b.Primary ~= false and #buttons > 1)
            local danger = b.Danger == true
            local btn = New("TextButton", {
                Size = UDim2.fromOffset(b.Width or 92, 30),
                Text = tostring(b.Title or "OK"),
                Font = Enum.Font.GothamMedium,
                TextSize = 12.5,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                LayoutOrder = i,
                ZIndex = 803,
                Parent = btnRow,
            })
            Corner(btn, 7)
            if danger then
                Paint(btn, { BackgroundColor3 = "Danger", TextColor3 = "AccentText" })
            elseif primary then
                Paint(btn, { BackgroundColor3 = "Accent", TextColor3 = "AccentText" })
                Interactive(btn, { Idle = "Accent", Hover = "AccentHover", Press = "Accent" })
            else
                Paint(btn, { BackgroundColor3 = "Card", TextColor3 = "Text" })
                Interactive(btn)
            end
            Ripple(btn, Color3.new(1, 1, 1))
            Connect(btn.MouseButton1Click, function()
                if b.Callback then fire(b.Callback) end
                dialog:Close()
            end)
        end

        tw(box, { GroupTransparency = 0 }, 0.2)
        tw(boxScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
        return dialog
    end

    ---------------------------------------------------------- config tab UX --
    --- Drop a ready-made config manager into any tab.
    function self:AddConfigSection(tab, title)
        local box = tab:AddSection(title or "Configuration")
        if not HAS_FS then
            box:AddParagraph({
                Title = "Unavailable",
                Content = "This environment has no file access, so configs cannot be saved. "
                       .. "Flags still work in memory.",
            })
            return box
        end

        local nameInput = box:AddInput("__cfg_name", {
            Title = "Config name",
            Placeholder = "default",
            IgnoreConfig = true,
        })
        nameInput.IgnoreConfig = true

        local listDrop = box:AddDropdown("__cfg_list", {
            Title = "Saved configs",
            Values = Cyz:ListConfigs(),
            AllowNull = true,
        })
        listDrop.IgnoreConfig = true

        box:AddButton({ Title = "Save", Description = "Write the current values to disk",
            Callback = function()
                local name = nameInput.Value
                if name == "" then
                    Cyz:Notify({ Title = "Name required", Kind = "warning",
                                 Content = "Type a config name first." })
                    return
                end
                local ok, err = Cyz:SaveConfig(name)
                Cyz:Notify({
                    Title = ok and "Saved" or "Save failed",
                    Content = ok and ("Config '" .. name .. "' written.") or tostring(err),
                    Kind = ok and "success" or "error",
                })
                listDrop:SetValues(Cyz:ListConfigs(), true)
            end })

        box:AddButton({ Title = "Load", Description = "Restore the selected config",
            Callback = function()
                local name = listDrop.Value or nameInput.Value
                if not name or name == "" then
                    Cyz:Notify({ Title = "Pick a config", Kind = "warning" })
                    return
                end
                local ok, err = Cyz:LoadConfig(name)
                Cyz:Notify({
                    Title = ok and "Loaded" or "Load failed",
                    Content = ok and ("Config '" .. name .. "' applied.") or tostring(err),
                    Kind = ok and "success" or "error",
                })
            end })

        box:AddButton({ Title = "Delete", Description = "Remove the selected config",
            Callback = function()
                local name = listDrop.Value
                if not name then return end
                self:Dialog({
                    Title = "Delete config?",
                    Content = "'" .. name .. "' will be removed permanently.",
                    Buttons = {
                        { Title = "Cancel" },
                        { Title = "Delete", Danger = true, Callback = function()
                            Cyz:DeleteConfig(name)
                            listDrop:SetValues(Cyz:ListConfigs(), true)
                            Cyz:Notify({ Title = "Deleted", Kind = "success" })
                        end },
                    },
                })
            end })

        box:AddButton({ Title = "Refresh list", Callback = function()
            listDrop:SetValues(Cyz:ListConfigs(), true)
            Cyz:Notify({ Title = "List refreshed", Kind = "info", Duration = 2 })
        end })

        return box
    end

    --- Drop a ready-made theme picker into any tab.
    function self:AddThemeSection(tab, title)
        local box = tab:AddSection(title or "Appearance")
        box:AddLabel("Theme")
        box:AddThemePicker({})
        box:AddToggle("__acrylic", {
            Title = "Background blur",
            Description = "Blurs the 3D world behind the menu.",
            Default = opts.Acrylic == true,
            Callback = function(v) Acrylic:SetEnabled(v) end,
        }).IgnoreConfig = true
        return box
    end

    function self:SetTitle(v) titleLabel.Text = tostring(v); return self end
    function self:SetSubTitle(v) subLabel.Text = tostring(v); return self end
    function self:Destroy() Cyz:Destroy() end

    -- present
    table.insert(Cyz.Windows, self)
    if opts.Acrylic then Acrylic:SetEnabled(true) end
    Acrylic:SetShown(true)
    tw(root, { GroupTransparency = 0 }, 0.26)
    tw(scale, { Scale = 1 }, 0.36, Enum.EasingStyle.Back)

    return self
end

Cyz.Window = Cyz.CreateWindow

--#endregion

--#region ── lifecycle ─────────────────────────────────────────────────────────

function Cyz:Destroy()
    if Cyz.Unloaded then return end
    Cyz.Unloaded = true

    for _, conn in ipairs(Cyz.Connections) do pcall(function() conn:Disconnect() end) end
    Cyz.Connections = {}

    Acrylic:SetShown(false)
    Acrylic:Destroy()

    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end

    Cyz.Windows  = {}
    Cyz.Options  = {}
    Cyz.Flags    = {}
    Cyz.Instances = {}
end
Cyz.Unload = Cyz.Destroy

--- Convenience: read a flag's value without touching the element.
function Cyz:Get(flag)
    local e = Cyz.Options[flag]
    return e and e.Value or Cyz.Flags[flag]
end

--- Convenience: write a flag's value and fire its callback.
function Cyz:Set(flag, value, silent)
    local e = Cyz.Options[flag]
    if e and e.SetValue then e:SetValue(value, silent) end
    return e
end

--- Introspection helper for debugging a script's own state.
function Cyz:Dump()
    local out = {}
    for flag, element in pairs(Cyz.Options) do
        out[flag] = { type = element.Type, value = element.Value }
    end
    return out
end

--#endregion

return Cyz
