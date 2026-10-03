return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local tab = ctx.Window:CreateTab("Combat", "A")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local localPlayer = Players.LocalPlayer
    local settings = {
        Aimbot = false,
        FOV = 100,
        MaxDistance = 150,
        Hitbox = 2,
    }
    local originals = {
        FireRate = {},
        ReloadTime = {},
        EReloadTime = {},
        Spread = {},
        Recoil = {},
    }
    local circle = Common.DrawingCircle(scope, settings.FOV, Color3.fromRGB(230, 60, 80))

    local function changeValues(names, bucket, enabled, value)
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if table.find(names, item.Name) and item:IsA("ValueBase") then
                if enabled then
                    if originals[bucket][item] == nil then originals[bucket][item] = item.Value end
                    pcall(function() item.Value = value end)
                elseif originals[bucket][item] ~= nil then
                    pcall(function() item.Value = originals[bucket][item] end)
                    originals[bucket][item] = nil
                end
            end
        end
    end

    tab:CreateSection("Gun mods")
    tab:CreateToggle("Infinite ammo", false, function(enabled)
        if enabled then
            scope:Loop("ammo", 0.05, function()
                local gui = localPlayer:FindFirstChild("PlayerGui")
                local variables = gui and gui:FindFirstChild("GUI") and gui.GUI:FindFirstChild("Client") and gui.GUI.Client:FindFirstChild("Variables")
                if variables then
                    local ammo = variables:FindFirstChild("ammocount")
                    local ammo2 = variables:FindFirstChild("ammocount2")
                    if ammo then ammo.Value = 778 end
                    if ammo2 then ammo2.Value = 778 end
                end
            end)
        else
            scope:StopTask("ammo")
        end
    end)
    tab:CreateToggle("Quick fire rate", false, function(enabled)
        changeValues({"FireRate", "BFireRate"}, "FireRate", enabled, 0.01)
    end)
    tab:CreateToggle("Quick reload", false, function(enabled)
        changeValues({"ReloadTime"}, "ReloadTime", enabled, 0.001)
        changeValues({"EReloadTime"}, "EReloadTime", enabled, 0.001)
    end)
    tab:CreateToggle("No spread", false, function(enabled)
        changeValues({"MaxSpread", "Spread", "SpreadControl"}, "Spread", enabled, 0)
    end)
    tab:CreateToggle("No recoil", false, function(enabled)
        changeValues({"RecoilControl", "Recoil"}, "Recoil", enabled, 0)
    end)

    tab:CreateSection("Aim")
    tab:CreateToggle("Aimbot", false, function(enabled)
        settings.Aimbot = enabled
        if circle then circle.Visible = enabled end
    end)
    tab:CreateSlider("FOV radius", {Min = 30, Max = 300, Default = 100}, function(value)
        settings.FOV = value
        if circle then circle.Radius = value end
    end)
    tab:CreateSlider("Max distance", {Min = 75, Max = 400, Default = 150}, function(value)
        settings.MaxDistance = value
    end)
    tab:CreateSlider("Enemy hitbox", {Min = 2, Max = 25, Default = 2}, function(value)
        settings.Hitbox = value
    end)

    scope:Connect(RunService.Heartbeat, function()
        local size = settings.Hitbox
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team ~= localPlayer.Team and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    if size > 2 then
                        root.Size = Vector3.new(size, size, size)
                        root.Transparency = 0.5
                        root.CanCollide = false
                    else
                        root.Size = Vector3.new(2, 2, 1)
                        root.Transparency = 1
                        root.CanCollide = false
                    end
                end
            end
        end
    end)

    scope:Connect(RunService.RenderStepped, function()
        if circle then
            circle.Position = UserInputService:GetMouseLocation()
            circle.Radius = settings.FOV
            circle.Visible = settings.Aimbot
        end
        if not settings.Aimbot then return end
        local target = Common.NearestToCursor({FOV = settings.FOV, TeamCheck = true, Part = "Head", MaxDistance = settings.MaxDistance})
        local head = target and target.Character and target.Character:FindFirstChild("Head")
        local camera = workspace.CurrentCamera
        if head and camera then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, head.Position)
        end
    end)
end
