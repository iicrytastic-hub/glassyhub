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

-- embedded logo (transparent PNG, base64) ------------------------------------
local EMBEDDED_LOGO = [[
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
]]

-- pure-Lua base64 decoder so the embedded logo works on any executor
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_INDEX = {}
for i = 1, #B64 do B64_INDEX[B64:byte(i)] = i - 1 end
local function decodeBase64(data)
    data = data:gsub("[^%w%+/]", "")
    local out, n = {}, 0
    local full = #data - (#data % 4)
    for i = 1, full, 4 do
        local a, b, c, d = data:byte(i, i + 3)
        local v = B64_INDEX[a] * 262144 + B64_INDEX[b] * 4096 + B64_INDEX[c] * 64 + B64_INDEX[d]
        n += 1
        out[n] = string.char(math.floor(v / 65536), math.floor(v / 256) % 256, v % 256)
    end
    local rem = #data - full
    if rem == 2 then
        local a, b = data:byte(full + 1, full + 2)
        n += 1
        out[n] = string.char(B64_INDEX[a] * 4 + math.floor(B64_INDEX[b] / 16))
    elseif rem == 3 then
        local a, b, c = data:byte(full + 1, full + 3)
        n += 1
        out[n] = string.char(
            B64_INDEX[a] * 4 + math.floor(B64_INDEX[b] / 16),
            (B64_INDEX[b] % 16) * 16 + math.floor(B64_INDEX[c] / 4)
        )
    end
    return table.concat(out)
end

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
        Size = opts.LogoSize or UDim2.fromOffset(250, 246),
        BackgroundTransparency = 1,
        -- ImageColor3 tints the PNG (default white = keeps the artwork's own pink/white)
        ImageColor3 = opts.LogoColor or Color3.new(1, 1, 1),
        -- lower = more visible. 0.85 is a faint watermark, ~0.6 is bolder
        ImageTransparency = opts.LogoTransparency or 0.55,
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
    elseif not opts.LogoUrl and opts.Logo ~= false then
        -- default: the embedded L:(OVE artwork
        task.spawn(function()
            local ok, err = pcall(function()
                local getAsset = getcustomasset or getsynasset
                writefile("GlassUI_logo.png", decodeBase64(EMBEDDED_LOGO))
                useImage(getAsset("GlassUI_logo.png"))
            end)
            if not ok then
                warn("[GlassUI] could not load embedded logo, keeping the wordmark: " .. tostring(err))
            end
        end)
    elseif opts.LogoUrl then
        task.spawn(function()
            local ok, err = pcall(function()
                local data = game:HttpGet(opts.LogoUrl)
                -- a 404 page is still "successful" text, so check it's really a PNG
                if type(data) ~= "string" or data:sub(2, 4) ~= "PNG" then
                    error("that link is not a PNG (check the raw URL)")
                end
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
