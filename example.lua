-- Host GlassUI.lua at a raw URL and paste it below
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/iicrytastic-hub/glassyhub/main/GlassUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "Testing Grounds",
    ToggleKey = Enum.KeyCode.RightShift,
    Blur = true,
})

local function getHumanoid()
    local char = lp.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local Tab = Window:Tab("Movement")

-- WalkSpeed ---------------------------------------------------------------
Tab:Section("Speed")
local speed, speedOn, speedConn = 16, false, nil

Tab:Toggle({
    Name = "Custom WalkSpeed",
    Callback = function(on)
        speedOn = on
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

-- Settings ------------------------------------------------------------------
local Settings = Window:Tab("Settings")
Settings:Section("Glass")
Settings:Toggle({
    Name = "Flowing RGB glass", Default = true,
    Callback = function(on) Window:SetRGB(on) end,
})
Settings:Slider({
    Name = "Flow speed", Min = 1, Max = 20, Default = 5,
    Callback = function(v) Window.RGBSpeed = v / 100 end,
})
Settings:Button({
    Name = "Unload",
    Callback = function()
        if speedConn then speedConn:Disconnect() end
        if noclipConn then noclipConn:Disconnect() end
        if jumpConn then jumpConn:Disconnect() end
        local h = getHumanoid()
        if h then h.WalkSpeed = 16 end
        Window:Destroy()
    end,
})
