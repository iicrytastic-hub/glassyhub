-- Peep Hub
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/iicrytastic-hub/glassyhub/main/GlassUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local lp = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "Peep Hub",
    ToggleKey = Enum.KeyCode.RightBracket, -- the ] key
    Blur = true,

    -- The Lil Peep "L:(OVE" artwork is embedded in GlassUI.lua, nothing to host.
    LogoTransparency = 0.55, -- lower = bolder, higher = fainter
    -- LogoColor = Color3.fromRGB(255, 255, 255), -- tint (white keeps original colours)
})

local function getHumanoid()
    local char = lp.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local Tab = Window:Tab("Movement")

-- WalkSpeed ---------------------------------------------------------------
Tab:Section("Speed")
local speed, speedConn = 16, nil

Tab:Toggle({
    Name = "Custom WalkSpeed",
    Callback = function(on)
        if speedConn then speedConn:Disconnect(); speedConn = nil end
        if on then
            -- re-applied every frame so respawns and game resets don't undo it
            speedConn = RunService.Heartbeat:Connect(function()
                local h = getHumanoid()
                if h and h.WalkSpeed ~= speed then h.WalkSpeed = speed end
            end)
        else
            local h = getHumanoid()
            if h then h.WalkSpeed = 16 end
        end
    end,
})
Tab:Slider({
    Name = "WalkSpeed", Min = 16, Max = 150, Default = 16, Increment = 1,
    Callback = function(v) speed = v end,
})

-- Noclip -------------------------------------------------------------------
Tab:Section("Collision")
local noclipConn
Tab:Toggle({
    Name = "Noclip",
    Callback = function(on)
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if on then
            noclipConn = RunService.Stepped:Connect(function()
                local char = lp.Character
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        end
    end,
})

-- Infinite jump -------------------------------------------------------------
Tab:Section("Jump")
local jumpConn
Tab:Toggle({
    Name = "Infinite Jump",
    Callback = function(on)
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        if on then
            jumpConn = UIS.JumpRequest:Connect(function()
                local h = getHumanoid()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end,
})

-- Fly ----------------------------------------------------------------------
Tab:Section("Flight")
local flySpeed, flyConn, flyBV, flyBG = 60, nil, nil, nil

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local h = getHumanoid()
    if h then h.PlatformStand = false end
end

local function startFly()
    stopFly()
    flyConn = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local h = getHumanoid()
        if not (root and h) then return end
        Camera = workspace.CurrentCamera

        -- (re)create the movers so respawning while flying still works
        if not flyBV or flyBV.Parent ~= root then
            if flyBV then flyBV:Destroy() end
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBV.Velocity = Vector3.zero
            flyBV.Parent = root
        end
        if not flyBG or flyBG.Parent ~= root then
            if flyBG then flyBG:Destroy() end
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBG.P = 9e4
            flyBG.Parent = root
        end
        h.PlatformStand = true

        -- MoveDirection works for WASD, gamepad and mobile thumbstick alike
        local cf = Camera.CFrame
        local rel = cf:VectorToObjectSpace(h.MoveDirection)
        local dir = cf.RightVector * rel.X + cf.LookVector * -rel.Z
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then
            dir += Vector3.yAxis
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.Q) then
            dir -= Vector3.yAxis
        end

        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyBG.CFrame = cf
    end)
end

local flyToggle = Tab:Toggle({
    Name = "Fly",
    Callback = function(on)
        if on then startFly() else stopFly() end
    end,
})
Tab:Slider({
    Name = "Fly speed", Min = 10, Max = 300, Default = 60, Increment = 5,
    Callback = function(v) flySpeed = v end,
})
Tab:Keybind({
    Name = "Fly keybind", Default = Enum.KeyCode.F,
    Callback = function() flyToggle:Set(not flyToggle:Get()) end,
})
Tab:Label("Fly: WASD to move, Space/E up, Shift/Q down")

-- Fullbright ---------------------------------------------------------------
Tab:Section("Visuals")
local fbConn
local fbSaved = {}
local FB_PROPS = { Brightness = 2, ClockTime = 14, FogEnd = 1e6, GlobalShadows = false,
                   Ambient = Color3.new(1, 1, 1), OutdoorAmbient = Color3.new(1, 1, 1) }

local function applyFullbright()
    for prop, value in pairs(FB_PROPS) do
        if Lighting[prop] ~= value then Lighting[prop] = value end
    end
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("Atmosphere") and fx.Density ~= 0 then fx.Density = 0 end
    end
end

Tab:Toggle({
    Name = "Fullbright",
    Callback = function(on)
        if fbConn then fbConn:Disconnect(); fbConn = nil end
        if on then
            -- remember the original lighting so switching off restores it
            fbSaved = {}
            for prop in pairs(FB_PROPS) do fbSaved[prop] = Lighting[prop] end
            fbSaved.atmo = {}
            for _, fx in ipairs(Lighting:GetChildren()) do
                if fx:IsA("Atmosphere") then fbSaved.atmo[fx] = fx.Density end
            end
            -- re-applied every frame because games often reset lighting
            fbConn = RunService.RenderStepped:Connect(applyFullbright)
        else
            for prop, value in pairs(fbSaved) do
                if prop ~= "atmo" then Lighting[prop] = value end
            end
            for fx, density in pairs(fbSaved.atmo or {}) do
                if fx.Parent then fx.Density = density end
            end
        end
    end,
})

-- Everything above gets switched off when the UI is destroyed --------------
Window:OnDestroy(function()
    if speedConn then speedConn:Disconnect() end
    if noclipConn then noclipConn:Disconnect() end
    if jumpConn then jumpConn:Disconnect() end
    stopFly()
    if fbConn then
        fbConn:Disconnect()
        for prop, value in pairs(fbSaved) do
            if prop ~= "atmo" then Lighting[prop] = value end
        end
        for fx, density in pairs(fbSaved.atmo or {}) do
            if fx.Parent then fx.Density = density end
        end
    end
    local h = getHumanoid()
    if h then h.WalkSpeed = 16 end
end)

-- Settings ------------------------------------------------------------------
local Settings = Window:Tab("Settings")

Settings:Section("Outline")
Settings:Toggle({
    Name = "Flowing outline", Default = true,
    Callback = function(on) Window:SetRGB(on) end,
})
Settings:Slider({
    Name = "Flow speed", Min = 1, Max = 20, Default = 5,
    Callback = function(v) Window.RGBSpeed = v / 100 end,
})

Settings:Section("Menu")
Settings:Button({
    Name = "Destroy UI",
    Callback = function() Window:Destroy() end,
})
