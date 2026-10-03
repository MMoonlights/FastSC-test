return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local combat = ctx.Window:CreateTab("Combat", "D")
    local visual = ctx.Window:CreateTab("Visual", "V")
    local mods = ctx.Window:CreateTab("Mods", "M")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local Lighting = game:GetService("Lighting")
    local localPlayer = Players.LocalPlayer
    local killAura = false
    local noclip = false
    local aimbot = false
    local fov = 120
    local noBandageDelay = false
    local noECooldown = false
    local fireDelay
    local spread
    local reload
    local espSettings = {Buildings = false, Items = false, Mobs = false}
    local espObjects = {}
    local modifiedPrompts = {}
    local noclipParts = {}
    local circle = Common.DrawingCircle(scope, fov, Color3.fromRGB(230, 60, 80))
    local humanoidCache = Common.CreateDescendantCache(scope, workspace, function(instance)
        return instance:IsA("Humanoid")
    end)

    local function clearEsp(kind)
        for object, data in pairs(espObjects) do
            if not kind or data.Kind == kind then
                pcall(function() data.Highlight:Destroy() end)
                espObjects[object] = nil
            end
        end
    end

    local function mark(object, kind, color)
        if not object or not object.Parent or espObjects[object] then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "FastSC_" .. kind
        highlight.Adornee = object
        highlight.FillColor = color
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = object
        espObjects[object] = {Kind = kind, Highlight = highlight}
    end

    local function restoreNoclip()
        for part in pairs(noclipParts) do
            scope:Restore(part, "CanCollide")
            noclipParts[part] = nil
        end
    end

    local function applyNoclip(character)
        if not noclip or not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                noclipParts[part] = true
                scope:Set(part, "CanCollide", false)
            end
        end
    end

    local function attachCharacter(character)
        applyNoclip(character)
        scope:Connect(character.DescendantAdded, function(instance)
            if noclip and instance:IsA("BasePart") then
                noclipParts[instance] = true
                scope:Set(instance, "CanCollide", false)
            end
        end)
    end

    if localPlayer.Character then attachCharacter(localPlayer.Character) end
    scope:Connect(localPlayer.CharacterAdded, attachCharacter)

    local function nearestMobHead()
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local best
        local bestDistance = fov
        humanoidCache:Each(function(humanoid)
            local model = humanoid.Parent
            if model and humanoid.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                local head = model:FindFirstChild("Head")
                if head then
                    local point, visible = camera:WorldToViewportPoint(head.Position)
                    if visible then
                        local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
                        if distance < bestDistance then
                            best = head
                            bestDistance = distance
                        end
                    end
                end
            end
        end)
        return best
    end

    local function refreshEsp()
        if espSettings.Items then
            local items = workspace:FindFirstChild("RuntimeItems")
            if items then
                for _, item in ipairs(items:GetChildren()) do mark(item, "Items", Color3.fromRGB(80, 170, 255)) end
            end
        end
        if espSettings.Buildings then
            for _, folderName in ipairs({"Towns", "RandomBuildings"}) do
                local folder = workspace:FindFirstChild(folderName)
                if folder then
                    for _, item in ipairs(folder:GetChildren()) do
                        if item:IsA("Model") then mark(item, "Buildings", Color3.fromRGB(255, 220, 80)) end
                    end
                end
            end
        end
        if espSettings.Mobs then
            humanoidCache:Each(function(humanoid)
                local model = humanoid.Parent
                if model and humanoid.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                    mark(model, "Mobs", Color3.fromRGB(255, 80, 80))
                end
            end)
        end
        for object, data in pairs(espObjects) do
            if not object.Parent then
                pcall(function() data.Highlight:Destroy() end)
                espObjects[object] = nil
            end
        end
    end

    local function weaponConfiguration()
        local character = localPlayer.Character
        local tool = character and character:FindFirstChildWhichIsA("Tool")
        return tool and tool:FindFirstChildWhichIsA("Configuration")
    end

    local function applyWeaponMods()
        local configuration = weaponConfiguration()
        if not configuration then return end
        local fireValue = configuration:FindFirstChild("FireDelay")
        local spreadValue = configuration:FindFirstChild("SpreadAngle")
        local reloadValue = configuration:FindFirstChild("ReloadDuration")
        if fireDelay and fireValue then scope:Set(fireValue, "Value", fireDelay) end
        if spread and spreadValue then scope:Set(spreadValue, "Value", spread) end
        if reload and reloadValue then scope:Set(reloadValue, "Value", reload) end
    end

    combat:CreateSection("Combat")
    combat:CreateToggle("Kill aura", false, function(value)
        killAura = value
        if value then
            scope:Loop("killAura", 0.08, function()
                local character = localPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local tool = character and character:FindFirstChildWhichIsA("Tool")
                local swing = tool and tool:FindFirstChild("SwingEvent")
                if root and swing then
                    local target = Common.NearestCharacter(root.Position, 12, nil, {
                        Each = function(_, callback)
                            humanoidCache:Each(function(humanoid)
                                if humanoid.Parent then callback(humanoid.Parent) end
                            end)
                        end,
                    })
                    if target then
                        local targetPart = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
                        if targetPart then pcall(function() swing:FireServer(targetPart.Position) end) end
                    end
                end
            end)
        else
            scope:StopTask("killAura")
        end
    end)
    combat:CreateToggle("NoClip", false, function(value)
        noclip = value
        if value then
            applyNoclip(localPlayer.Character)
        else
            restoreNoclip()
        end
    end)
    combat:CreateToggle("Aimbot", false, function(value)
        aimbot = value
        if circle then circle.Visible = value end
    end)
    combat:CreateSlider("Aimbot FOV", {Min = 40, Max = 300, Default = 120}, function(value)
        fov = value
        if circle then circle.Radius = value end
    end)

    visual:CreateSection("ESP")
    visual:CreateToggle("Buildings ESP", false, function(value)
        espSettings.Buildings = value
        if not value then clearEsp("Buildings") end
    end)
    visual:CreateToggle("Items ESP", false, function(value)
        espSettings.Items = value
        if not value then clearEsp("Items") end
    end)
    visual:CreateToggle("Mobs ESP", false, function(value)
        espSettings.Mobs = value
        if not value then clearEsp("Mobs") end
    end)

    mods:CreateSection("Gun mods")
    mods:CreateSlider("Fire delay", {Min = 0.05, Max = 5, Default = 1, Precise = true}, function(value)
        fireDelay = value
        applyWeaponMods()
    end)
    mods:CreateSlider("Spread angle", {Min = 0, Max = 5, Default = 1, Precise = true}, function(value)
        spread = value
        applyWeaponMods()
    end)
    mods:CreateSlider("Reload time", {Min = 0.05, Max = 5, Default = 1, Precise = true}, function(value)
        reload = value
        applyWeaponMods()
    end)
    mods:CreateButton("Reset gun mods", function()
        local configuration = weaponConfiguration()
        if configuration then
            for _, name in ipairs({"FireDelay", "SpreadAngle", "ReloadDuration"}) do
                local value = configuration:FindFirstChild(name)
                if value then scope:Restore(value, "Value") end
            end
        end
        fireDelay = nil
        spread = nil
        reload = nil
    end)
    mods:CreateToggle("No bandage delay", false, function(value)
        noBandageDelay = value
        if value then
            scope:Loop("bandage", 0.1, function()
                local character = localPlayer.Character
                local gui = localPlayer:FindFirstChild("PlayerGui")
                local bandageGui = gui and gui:FindFirstChild("BandageUse")
                local bandage = character and character:FindFirstChild("Bandage")
                local use = bandage and bandage:FindFirstChild("Use")
                if bandageGui and bandageGui.Enabled and use then pcall(function() use:FireServer() end) end
            end)
        else
            scope:StopTask("bandage")
        end
    end)
    mods:CreateToggle("No E cooldown", false, function(value)
        noECooldown = value
        if not value then
            for prompt in pairs(modifiedPrompts) do
                scope:Restore(prompt, "HoldDuration")
                modifiedPrompts[prompt] = nil
            end
        end
    end)
    mods:CreateToggle("Full brightness", false, function(value)
        if value then
            scope:Set(Lighting, "Brightness", 5)
            scope:Set(Lighting, "GlobalShadows", false)
            scope:Set(Lighting, "OutdoorAmbient", Color3.new(1, 1, 1))
        else
            scope:Restore(Lighting, "Brightness")
            scope:Restore(Lighting, "GlobalShadows")
            scope:Restore(Lighting, "OutdoorAmbient")
        end
    end)
    mods:CreateButton("Skip tutorial", function()
        local value = game:GetService("ReplicatedStorage"):FindFirstChild("TutorialStep")
        if value then value.Value = 4 end
    end)

    scope:Connect(ProximityPromptService.PromptButtonHoldBegan, function(prompt)
        if noECooldown then
            modifiedPrompts[prompt] = true
            scope:Set(prompt, "HoldDuration", 0)
        end
    end)

    scope:Loop("weaponMods", 0.25, function()
        if fireDelay or spread or reload then applyWeaponMods() end
    end)

    scope:Loop("esp", 0.4, refreshEsp)

    scope:Connect(RunService.RenderStepped, function()
        local camera = workspace.CurrentCamera
        if circle and camera then
            circle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            circle.Radius = fov
            circle.Visible = aimbot
        end
        if aimbot and camera then
            local head = nearestMobHead()
            if head then camera.CFrame = CFrame.lookAt(camera.CFrame.Position, head.Position) end
        end
    end)

    scope:AddRestore(function()
        restoreNoclip()
        clearEsp()
        for prompt in pairs(modifiedPrompts) do
            scope:Restore(prompt, "HoldDuration")
        end
    end)
end
