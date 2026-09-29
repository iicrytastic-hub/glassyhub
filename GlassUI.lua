--[[
    GlassUI - minimal glass-style UI library with top tabs
    Usage:
        local Library = loadstring(game:HttpGet("YOUR_RAW_URL"))()
        local Window = Library:CreateWindow({ Title = "My Hub" })
        local Tab = Window:Tab("Main")
        Tab:Toggle({ Name = "Example", Callback = function(v) print(v) end })
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Library = {}

local Theme = {
    Accent = Color3.fromRGB(255, 70, 130),
    Text = Color3.fromRGB(246, 238, 242),
    SubText = Color3.fromRGB(190, 160, 172),
    Glass = Color3.fromRGB(16, 8, 12),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

-- helpers ------------------------------------------------------------------

-- every global input connection goes through here so Destroy can clean them all up
local AllConnections = {}
local function on(signal, fn)
    local c = signal:Connect(fn)
    table.insert(AllConnections, c)
    return c
end

local KEY_LABELS = { RightBracket = "]", LeftBracket = "[", Backquote = "`", Semicolon = ";", Quote = "'" }
local function keyLabel(key)
    return KEY_LABELS[key.Name] or key.Name
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    return inst
end

local function tween(obj, props, t)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function corner(r)
    return create("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(transparency, color)
    return create("UIStroke", {
        Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0.85,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

-- Parent order matches what working scripts do: CoreGui first, then PlayerGui,
-- with gethui() last. Each attempt is verified, not assumed.
local function attach(gui)
    local targets = {
        function() return game:GetService("CoreGui") end,
        function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end,
        function() return gethui and gethui() end,
    }
    for _, get in ipairs(targets) do
        local okGet, target = pcall(get)
        if okGet and target then
            local okParent = pcall(function() gui.Parent = target end)
            if okParent and gui.Parent == target then
                return target
            end
        end
    end
    return nil
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    on(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- window -------------------------------------------------------------------

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Library:CreateWindow(opts)
    opts = opts or {}
    -- re-running the script replaces the old window instead of stacking a second one
    local env = (getgenv and getgenv()) or _G
    if env.__GlassUIWindow then
        pcall(function() env.__GlassUIWindow:Destroy() end)
    end

    local self = setmetatable({}, Window)
    env.__GlassUIWindow = self
    self.Tabs = {}
    self.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightBracket
    self.Connections = {}
    self._hooks = {}

    self.Gui = create("ScreenGui", {
        Name = "GlassUI_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    })
    if opts.Parent then
        self.Gui.Parent = opts.Parent
    else
        attach(self.Gui)
    end
    if self.Gui.Parent then
        warn("[GlassUI] window created in: " .. tostring(self.Gui.Parent))
    else
        warn("[GlassUI] could not parent the window anywhere")
    end

    -- glass panel (static) + a separate animated outline
    local mainStroke = stroke(0.1)
    mainStroke.Thickness = 2
    local glassGrad = create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.25),
        }),
        Color = ColorSequence.new(Color3.fromRGB(255, 140, 190), Color3.fromRGB(60, 50, 55)),
    })
    local strokeGrad = create("UIGradient", { Rotation = 0 })

    local main = create("Frame", {
        Name = "Main",
        Size = opts.Size or UDim2.fromOffset(540, 380),
        Position = UDim2.new(0.5, -270, 0.5, -190),
        BackgroundColor3 = Color3.fromRGB(70, 22, 40),
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Parent = self.Gui,
    }, { corner(14), mainStroke, glassGrad })
    strokeGrad.Parent = mainStroke
    self.Main = main

    -- background watermark: a "L :( V E" wordmark by default,
    -- or your own image via opts.Logo (asset id) / opts.LogoUrl (raw PNG link)
    local mark = create("Frame", {
        Name = "Watermark",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.6, 0),
        Size = UDim2.fromOffset(340, 130),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = main,
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
        }),
    })
    local function wordLetter(txt)
        create("TextLabel", {
            Size = UDim2.fromOffset(68, 110),
            BackgroundTransparency = 1,
            Text = txt,
            TextColor3 = Theme.Accent,
            TextTransparency = 0.88,
            Font = Enum.Font.GothamBlack,
            TextSize = 96,
            ZIndex = 0,
            Parent = mark,
        })
    end
    wordLetter("L")
    -- the "O" is a sideways frown
    local frownSlot = create("Frame", {
        Size = UDim2.fromOffset(84, 110), BackgroundTransparency = 1, ZIndex = 0, Parent = mark,
    })
    create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(84, 84),
        BackgroundTransparency = 1,
        Text = ":(",
        TextColor3 = Theme.Accent,
        TextTransparency = 0.88,
        Font = Enum.Font.GothamBlack,
        TextSize = 84,
        Rotation = 90,
        ZIndex = 0,
        Parent = frownSlot,
    })
    wordLetter("V")
    wordLetter("E")

    local logoImg = create("ImageLabel", {
        Name = "Logo",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.6, 0),
        Size = UDim2.fromOffset(230, 230),
        BackgroundTransparency = 1,
        ImageTransparency = opts.LogoTransparency or 0.85,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 0,
        Visible = false,
        Parent = main,
    })
    local function useImage(id)
        logoImg.Image = id
        logoImg.Visible = true
        mark.Visible = false
    end
    if opts.Logo then
        useImage(opts.Logo)
    elseif opts.LogoUrl then
        task.spawn(function()
            local ok, err = pcall(function()
                local data = game:HttpGet(opts.LogoUrl)
                writefile("GlassUI_logo.png", data)
                local getAsset = getcustomasset or getsynasset
                useImage(getAsset("GlassUI_logo.png"))
            end)
            if not ok then
                warn("[GlassUI] could not load logo image, keeping the wordmark: " .. tostring(err))
            end
        end)
    end

    -- top bar
    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        Parent = main,
    })
    makeDraggable(topbar, main)

    create("TextLabel", {
        Size = UDim2.new(0, 110, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = opts.Title or "GlassUI",
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = topbar,
    })

    self.TabBar = create("Frame", {
        Size = UDim2.new(1, -170, 1, 0),
        Position = UDim2.fromOffset(130, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = topbar,
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local hideBtn = create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.92,
        Text = "–",
        TextColor3 = Theme.SubText,
        Font = Theme.FontBold,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = topbar,
    }, { corner(8) })
    hideBtn.MouseEnter:Connect(function() tween(hideBtn, { BackgroundTransparency = 0.8 }) end)
    hideBtn.MouseLeave:Connect(function() tween(hideBtn, { BackgroundTransparency = 0.92 }) end)

    create("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.fromOffset(12, 46),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Parent = main,
    })

    self.Content = create("Frame", {
        Size = UDim2.new(1, -24, 1, -62),
        Position = UDim2.fromOffset(12, 54),
        BackgroundTransparency = 1,
        Parent = main,
    })

    -- optional background blur (blurs the game world behind the menu)
    if opts.Blur ~= false then
        self.Blur = create("BlurEffect", { Size = 0, Parent = Lighting })
    end

    self.Visible = true
    if self.Blur then tween(self.Blur, { Size = 10 }, 0.3) end

    -- small pill shown while hidden, so the menu can always be reopened
    local pill = create("TextButton", {
        Size = UDim2.fromOffset(110, 26),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        BackgroundColor3 = Theme.Glass,
        BackgroundTransparency = 0.3,
        Text = (opts.Title or "GlassUI") .. "  \u{25BE}",
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 12,
        AutoButtonColor = false,
        Visible = false,
        Parent = self.Gui,
    }, { corner(13), stroke(0.7) })
    pill.MouseButton1Click:Connect(function() self:SetVisible(true) end)

    function self:SetVisible(v)
        self.Visible = v
        main.Visible = v
        pill.Visible = not v
        if self.Blur then tween(self.Blur, { Size = v and 10 or 0 }, 0.25) end
    end

    hideBtn.MouseButton1Click:Connect(function()
        self:SetVisible(false)
        self:Notify({ Title = "Hidden", Text = "Press " .. keyLabel(self.ToggleKey) .. " or click the pill at the top." })
    end)

    table.insert(self.Connections, on(UIS.InputBegan, function(input)
        if input.KeyCode == self.ToggleKey and not UIS:GetFocusedTextBox() then
            self:SetVisible(not self.Visible)
        end
    end))

    -- flowing RGB outline: colours drift and circle the edge continuously
    self.RGB = opts.RGB ~= false
    self.RGBSpeed = opts.RGBSpeed or 0.05        -- hue cycles per second (also sets the circling speed)
    self.RGBSpread = opts.RGBSpread or 0.6       -- how much of the colour wheel shows at once
    self.RGBSaturation = opts.RGBSaturation or 0.7
    self.Palette = opts.Palette or "theme"       -- "theme" (red/pink) or "rainbow"
    local RED = Color3.fromRGB(235, 25, 60)
    local PINK = Color3.fromRGB(255, 105, 180)

    local function applyStatic()
        strokeGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
        strokeGrad.Rotation = 0
        mainStroke.Transparency = 0.75
        mainStroke.Thickness = 1
    end
    local function applyRGB()
        mainStroke.Transparency = 0.1
        mainStroke.Thickness = 2
    end
    if self.RGB then applyRGB() else applyStatic() end

    local STOPS = 8
    local startClock = os.clock()
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if not self.RGB or not main.Visible then return end
        local t = os.clock() - startClock
        local base = t * self.RGBSpeed
        local keys = {}
        for i = 0, STOPS do
            local color
            if self.Palette == "rainbow" then
                local h = (base + (i / STOPS) * self.RGBSpread) % 1
                color = Color3.fromHSV(h, self.RGBSaturation, 1)
            else
                -- one smooth wave of red <-> pink around the edge; ends match so it loops seamlessly
                local w = 0.5 + 0.5 * math.sin(2 * math.pi * (t * self.RGBSpeed * 4 + i / STOPS))
                color = RED:Lerp(PINK, w)
            end
            keys[i + 1] = ColorSequenceKeypoint.new(i / STOPS, color)
        end
        strokeGrad.Color = ColorSequence.new(keys)
        strokeGrad.Rotation = (t * self.RGBSpeed * 600) % 360
    end))

    function self:SetRGB(on)
        self.RGB = on
        if on then applyRGB() else applyStatic() end
    end

    -- toast holder (lives outside main so it stays visible when hidden)
    self.Toasts = create("Frame", {
        Size = UDim2.new(0, 260, 1, -20),
        Position = UDim2.new(1, -270, 0, 10),
        BackgroundTransparency = 1,
        Parent = self.Gui,
    }, {
        create("UIListLayout", {
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    return self
end

function Window:Notify(o)
    o = o or {}
    local toast = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Glass,
        BackgroundTransparency = 1,
        Parent = self.Toasts,
    }, {
        corner(10),
        stroke(1),
        create("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        }),
        create("UIListLayout", { Padding = UDim.new(0, 2) }),
    })
    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = o.Title or "Notice",
        TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 13, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = toast,
    })
    local body = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Text = o.Text or "", TextColor3 = Theme.SubText, Font = Theme.Font, TextSize = 12,
        TextWrapped = true, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = toast,
    })
    local s = toast:FindFirstChildOfClass("UIStroke")
    tween(toast, { BackgroundTransparency = 0.2 }, 0.25)
    tween(s, { Transparency = 0.75 }, 0.25)
    tween(title, { TextTransparency = 0 }, 0.25)
    tween(body, { TextTransparency = 0 }, 0.25)
    task.delay(o.Duration or 3, function()
        tween(toast, { BackgroundTransparency = 1 }, 0.25)
        tween(s, { Transparency = 1 }, 0.25)
        tween(title, { TextTransparency = 1 }, 0.25)
        tween(body, { TextTransparency = 1 }, 0.25)
        task.wait(0.3)
        toast:Destroy()
    end)
end

-- register cleanup that should run when the window is destroyed (turn features off, etc.)
function Window:OnDestroy(fn)
    table.insert(self._hooks, fn)
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, fn in ipairs(self._hooks) do pcall(fn) end
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    for _, c in ipairs(AllConnections) do pcall(function() c:Disconnect() end) end
    table.clear(AllConnections)
    if self.Blur then self.Blur:Destroy() end
    if self.Gui then self.Gui:Destroy() end
    local env = (getgenv and getgenv()) or _G
    if env.__GlassUIWindow == self then env.__GlassUIWindow = nil end
end

-- tabs ---------------------------------------------------------------------

function Window:Tab(name)
    local tab = setmetatable({ Window = self, Order = 0 }, Tab)

    local btn = create("TextButton", {
        Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.SubText,
        Font = Theme.Font,
        TextSize = 13,
        AutoButtonColor = false,
        LayoutOrder = #self.Tabs,
        Parent = self.TabBar,
    }, {
        create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
    })
    local line = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0.5, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = btn,
    }, { corner(1) })

    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = self.Content,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) }),
    })

    tab.Page = page
    tab.Button = btn

    local function select()
        for _, t in ipairs(self.Tabs) do
            t.Page.Visible = false
            tween(t.Button, { TextColor3 = Theme.SubText })
            tween(t.Line, { Size = UDim2.new(0, 0, 0, 2) })
        end
        page.Visible = true
        tween(btn, { TextColor3 = Theme.Text })
        tween(line, { Size = UDim2.new(1, -24, 0, 2) })
    end
    tab.Line = line
    tab.Select = select

    btn.MouseButton1Click:Connect(select)
    btn.MouseEnter:Connect(function()
        if not page.Visible then tween(btn, { TextColor3 = Theme.Text }) end
    end)
    btn.MouseLeave:Connect(function()
        if not page.Visible then tween(btn, { TextColor3 = Theme.SubText }) end
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then select() end
    return tab
end

-- components ---------------------------------------------------------------

function Tab:_row(height)
    self.Order = self.Order + 1
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.93,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
        ClipsDescendants = true,
        Parent = self.Page,
    }, { corner(8), stroke(0.9) })
    return row
end

local function rowLabel(row, text, y, h)
    return create("TextLabel", {
        Size = UDim2.new(1, -110, 0, h or 36),
        Position = UDim2.fromOffset(12, y or 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
end

function Tab:Section(text)
    self.Order = self.Order + 1
    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = Theme.SubText,
        Font = Theme.FontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = self.Order,
        Parent = self.Page,
    }, { create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 6) }) })
end

function Tab:Label(text)
    local row = self:_row(30)
    local l = rowLabel(row, text, 0, 30)
    l.TextColor3 = Theme.SubText
    l.Size = UDim2.new(1, -24, 0, 30)
    return { Set = function(_, t) l.Text = t end }
end

function Tab:Button(o)
    local row = self:_row(36)
    rowLabel(row, o.Name or "Button")
    local b = create("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row,
    })
    b.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0.88 }) end)
    b.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 0.93 }) end)
    b.MouseButton1Click:Connect(function()
        tween(row, { BackgroundTransparency = 0.8 }, 0.08)
        task.delay(0.1, function() tween(row, { BackgroundTransparency = 0.88 }) end)
        if o.Callback then task.spawn(o.Callback) end
    end)
end

function Tab:Toggle(o)
    local state = o.Default or false
    local row = self:_row(36)
    rowLabel(row, o.Name or "Toggle")

    local track = create("Frame", {
        Size = UDim2.fromOffset(38, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.8,
        Parent = row,
    }, { corner(10) })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = track,
    }, { corner(7) })

    local function set(v, silent)
        state = v
        tween(track, { BackgroundColor3 = v and Theme.Accent or Color3.new(1, 1, 1), BackgroundTransparency = v and 0.15 or 0.8 })
        tween(knob, { Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
        if not silent and o.Callback then task.spawn(o.Callback, state) end
    end
    set(state, true)
    if state and o.Callback then task.spawn(o.Callback, state) end

    local b = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
    b.MouseButton1Click:Connect(function() set(not state) end)

    return { Set = function(_, v) set(v) end, Get = function() return state end }
end

function Tab:Slider(o)
    local min, max = o.Min or 0, o.Max or 100
    local inc = o.Increment or 1
    local suffix = o.Suffix or ""
    local value = math.clamp(o.Default or min, min, max)

    local function pctOf(v) return (v - min) / (max - min) end

    local row = self:_row(54)
    rowLabel(row, o.Name or "Slider", 4, 26)
    local valLabel = create("TextLabel", {
        Size = UDim2.new(0, 90, 0, 26), Position = UDim2.new(1, -102, 0, 4), BackgroundTransparency = 1,
        Text = tostring(value) .. suffix, TextColor3 = Theme.SubText, Font = Theme.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })

    local bar = create("Frame", {
        Size = UDim2.new(1, -36, 0, 8), Position = UDim2.new(0, 18, 1, -22),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, Parent = row,
    }, { corner(4) })
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar,
    }, {
        corner(4),
        create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(225, 25, 65), Color3.fromRGB(255, 115, 185)),
        }),
    })
    local glow = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(30, 30), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Parent = bar,
    }, { corner(15) })
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = bar,
    }, { corner(7), stroke(0.4, Theme.Accent) })

    -- smooth follow: the knob glides toward the target instead of snapping to it
    local shown, goal = pctOf(value), pctOf(value)
    local conn
    local function render(p)
        fill.Size = UDim2.fromScale(p, 1)
        knob.Position = UDim2.fromScale(p, 0.5)
        glow.Position = UDim2.fromScale(p, 0.5)
    end
    render(shown)

    local function animate()
        if conn then return end
        conn = RunService.RenderStepped:Connect(function(dt)
            shown = shown + (goal - shown) * (1 - math.exp(-dt * 14))
            if math.abs(goal - shown) < 0.0005 then
                shown = goal
                conn:Disconnect()
                conn = nil
            end
            render(shown)
        end)
    end

    local function commit(v, silent)
        v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
        v = tonumber(string.format("%.3f", v))
        if v == value then return end
        value = v
        valLabel.Text = tostring(value) .. suffix
        if not silent and o.Callback then task.spawn(o.Callback, value) end
    end

    local dragging, hovering = false, false
    local function look()
        local active = dragging or hovering
        tween(knob, { Size = dragging and UDim2.fromOffset(18, 18) or UDim2.fromOffset(14, 14) }, 0.15)
        tween(glow, { BackgroundTransparency = dragging and 0.65 or (hovering and 0.82 or 1) }, 0.2)
        tween(valLabel, { TextColor3 = active and Theme.Text or Theme.SubText }, 0.15)
    end

    local function fromX(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        goal = pct
        animate()
        commit(min + pct * (max - min))
    end

    row.MouseEnter:Connect(function() hovering = true; look() end)
    row.MouseLeave:Connect(function() hovering = false; look() end)
    row.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            look()
            fromX(input.Position.X)
        end
    end)
    on(UIS.InputEnded, function(input)
        if dragging and isPress(input) then
            dragging = false
            goal = pctOf(value) -- settle onto the snapped value
            animate()
            look()
        end
    end)
    on(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)

    return {
        Set = function(_, v)
            v = math.clamp(v, min, max)
            goal = pctOf(v)
            animate()
            commit(v)
        end,
        Get = function() return value end,
    }
end

function Tab:Dropdown(o)
    local options = o.Options or {}
    local current = o.Default or options[1]
    local open = false
    local itemH = 28
    local fullH = 36 + #options * itemH + 6

    local row = self:_row(36)
    rowLabel(row, o.Name or "Dropdown")
    local sel = create("TextLabel", {
        Size = UDim2.new(0, 130, 0, 36), Position = UDim2.new(1, -160, 0, 0), BackgroundTransparency = 1,
        Text = tostring(current or ""), TextColor3 = Theme.Accent, Font = Theme.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })
    local arrow = create("TextLabel", {
        Size = UDim2.fromOffset(20, 36), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1,
        Text = "▾", TextColor3 = Theme.SubText, Font = Theme.Font, TextSize = 14, Parent = row,
    })
    local list = create("Frame", {
        Size = UDim2.new(1, -16, 0, #options * itemH), Position = UDim2.fromOffset(8, 38),
        BackgroundTransparency = 1, Parent = row,
    }, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

    local head = create("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", Parent = row })
    local function toggle()
        open = not open
        tween(row, { Size = UDim2.new(1, 0, 0, open and fullH or 36) })
        tween(arrow, { Rotation = open and 180 or 0 })
    end
    head.MouseButton1Click:Connect(toggle)

    for i, opt in ipairs(options) do
        local ob = create("TextButton", {
            Size = UDim2.new(1, 0, 0, itemH), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
            Text = tostring(opt), TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 12,
            AutoButtonColor = false, LayoutOrder = i, Parent = list,
        }, { corner(6) })
        ob.MouseEnter:Connect(function() tween(ob, { BackgroundTransparency = 0.9 }) end)
        ob.MouseLeave:Connect(function() tween(ob, { BackgroundTransparency = 1 }) end)
        ob.MouseButton1Click:Connect(function()
            current = opt
            sel.Text = tostring(opt)
            toggle()
            if o.Callback then task.spawn(o.Callback, opt) end
        end)
    end

    return {
        Set = function(_, v) current = v; sel.Text = tostring(v); if o.Callback then task.spawn(o.Callback, v) end end,
        Get = function() return current end,
    }
end

function Tab:Keybind(o)
    local key = o.Default or Enum.KeyCode.Unknown
    local listening = false
    local row = self:_row(36)
    rowLabel(row, o.Name or "Keybind")

    local kb = create("TextButton", {
        Size = UDim2.fromOffset(76, 24), Position = UDim2.new(1, -88, 0.5, -12),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88,
        Text = key == Enum.KeyCode.Unknown and "None" or key.Name,
        TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 12, AutoButtonColor = false, Parent = row,
    }, { corner(6) })

    kb.MouseButton1Click:Connect(function()
        listening = true
        kb.Text = "..."
        tween(kb, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.5 })
    end)

    on(UIS.InputBegan, function(input, processed)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            key = input.KeyCode == Enum.KeyCode.Escape and Enum.KeyCode.Unknown or input.KeyCode
            kb.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
            tween(kb, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88 })
        elseif not UIS:GetFocusedTextBox() and key ~= Enum.KeyCode.Unknown and input.KeyCode == key then
            if o.Callback then task.spawn(o.Callback) end
        end
    end)

    return { Get = function() return key end }
end

return Library
