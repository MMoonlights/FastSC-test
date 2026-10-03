return function(ctx)
    local scope = ctx.Scope
    local tab = ctx.Window:CreateTab("Combat", "B")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local localPlayer = Players.LocalPlayer
    local active = false
    local lastParry = 0

    local function ball()
        local balls = workspace:FindFirstChild("Balls")
        if not balls then return nil end
        for _, item in ipairs(balls:GetChildren()) do
            if item:GetAttribute("realBall") then return item end
        end
    end

    tab:CreateSection("Parry")
    tab:CreateToggle("Auto parry", false, function(enabled)
        active = enabled
    end)
    tab:CreateSlider("Parry threshold", {Min = 0.25, Max = 1.2, Default = 0.65, Precise = true, Suffix = "s"}, function(value)
        ctx.Config.Set("BladeBallThreshold", value)
    end)

    scope:Connect(RunService.PreSimulation, function()
        if not active then return end
        local current = ball()
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not current or not root then return end
        local zoomies = current:FindFirstChild("zoomies")
        local velocity = zoomies and zoomies.VectorVelocity.Magnitude or current.AssemblyLinearVelocity.Magnitude
        if velocity <= 0 then return end
        local distance = (root.Position - current.Position).Magnitude
        local threshold = ctx.Config.Get("BladeBallThreshold", 0.65)
        if current:GetAttribute("target") == localPlayer.Name and distance / velocity <= threshold and tick() - lastParry > 0.12 then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            lastParry = tick()
        end
    end)
end
