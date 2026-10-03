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
    local circle = Common.DrawingCircle(scope, settings.FOV, Color3.fromRGB(230, 60, 80))
    local weapons = ReplicatedStorage:FindFirstChild("Weapons")
    local weaponValues = weapons and Common.CreateDescendantCache(scope, weapons, function(instance)
        return instance:IsA("ValueBase")
    end)

    local function eachWeaponValue(names, callback)
        if not weaponValues then return end
        weaponValues:Each(function(item)
            if table.find(names, item.Name) then callback(item) end
        end)
    end

    local function changeValues(names, enabled, value)
        eachWeaponValue(names, function(item)
            if enabled then
                scope:Set(item, "Value", value)
            else
                scope:Restore(item, "Value")
            end
        end)
    end

    local function ammoValues()
        local gui = localPlayer:FindFirstChild("PlayerGui")
        local client = gui and gui:FindFirstChild("GUI") and gui.GUI:FindFirstChild("Client")
        local variables = client and client:FindFirstChild("Variables")
        return variables and variables:FindFirstChild("ammocount"), variables and variables:FindFirstChild("ammocount2")
    end

    local function applyHitbox(root)
        if not root then return end
        if settings.Hitbox > 2 then
            local size = settings.Hitbox
            scope:Set(root, "Size", Vector3.new(size, size, size))
            scope:Set(root, "Transparency", 0.5)
            scope:Set(root, "CanCollide", false)
        else
            scope:Restore(root, "Size")
            scope:Restore(root, "Transparency")
            scope:Restore(root, "CanCollide")
        end
    end

    local function refreshHitboxes()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team ~= localPlayer.Team and player.Character then
                applyHitbox(player.Character:FindFirstChild("HumanoidRootPart"))
            end
        end
    end

    local function attachPlayer(player)
        if player == localPlayer then return end
        scope:Connect(player.CharacterAdded, function(character)
            local root = character:WaitForChild("HumanoidRootPart", 5)
            if player.Team ~= localPlayer.Team then applyHitbox(root) end
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do attachPlayer(player) end
    scope:Connect(Players.PlayerAdded, attachPlayer)

    tab:CreateSection("Gun mods")
    tab:CreateToggle("Infinite ammo", false, function(enabled)
        if enabled then
            scope:Loop("ammo", 0.1, function()
                local ammo, ammo2 = ammoValues()
                if ammo then scope:Set(ammo, "Value", 778) end
                if ammo2 then scope:Set(ammo2, "Value", 778) end
            end)
        else
            scope:StopTask("ammo")
            local ammo, ammo2 = ammoValues()
            if ammo then scope:Restore(ammo, "Value") end
            if ammo2 then scope:Restore(ammo2, "Value") end
        end
    end)
    tab:CreateToggle("Quick fire rate", false, function(enabled)
        changeValues({"FireRate", "BFireRate"}, enabled, 0.01)
    end)
    tab:CreateToggle("Quick reload", false, function(enabled)
        changeValues({"ReloadTime", "EReloadTime"}, enabled, 0.001)
    end)
    tab:CreateToggle("No spread", false, function(enabled)
        changeValues({"MaxSpread", "Spread", "SpreadControl"}, enabled, 0)
    end)
    tab:CreateToggle("No recoil", false, function(enabled)
        changeValues({"RecoilControl", "Recoil"}, enabled, 0)
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
        refreshHitboxes()
    end)

    scope:Connect(localPlayer:GetPropertyChangedSignal("Team"), refreshHitboxes)

    scope:Connect(RunService.RenderStepped, function()
        if circle then
            circle.Position = UserInputService:GetMouseLocation()
            circle.Radius = settings.FOV
            circle.Visible = settings.Aimbot
        end
        if not settings.Aimbot then return end
        local target = Common.NearestToCursor({
            FOV = settings.FOV,
            TeamCheck = true,
            Part = "Head",
            MaxDistance = settings.MaxDistance,
        })
        local head = target and target.Character and target.Character:FindFirstChild("Head")
        local camera = workspace.CurrentCamera
        if head and camera then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, head.Position)
        end
    end)
end
