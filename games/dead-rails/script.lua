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
    local fireDelay = 1
    local spread = 1
    local reload = 1
    local espSettings = {Buildings = false, Items = false, Mobs = false}
    local espObjects = {}
    local circle = Common.DrawingCircle(scope, fov, Color3.fromRGB(230, 60, 80))

    local function clearEsp(kind)
        for object, data in pairs(espObjects) do
            if not kind or data.Kind == kind then
                pcall(function() data.Highlight:Destroy() end)
                espObjects[object] = nil
            end
        end
    end

    local function mark(object, kind, color)
        if not object or espObjects[object] then return end
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

    combat:CreateSection("Combat")
    combat:CreateToggle("Kill aura", false, function(value) killAura = value end)
    combat:CreateToggle("NoClip", false, function(value) noclip = value end)
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
    mods:CreateSlider("Fire delay", {Min = 0.05, Max = 5, Default = 1, Precise = true}, function(value) fireDelay = value end)
    mods:CreateSlider("Spread angle", {Min = 0, Max = 5, Default = 1, Precise = true}, function(value) spread = value end)
    mods:CreateSlider("Reload time", {Min = 0.05, Max = 5, Default = 1, Precise = true}, function(value) reload = value end)
    mods:CreateToggle("No bandage delay", false, function(value) noBandageDelay = value end)
    mods:CreateToggle("No E cooldown", false, function(value) noECooldown = value end)
    mods:CreateToggle("Full brightness", false, function(value)
        if value then
            Lighting.Brightness = 5
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
    end)
    mods:CreateButton("Skip tutorial", function()
        local value = game:GetService("ReplicatedStorage"):FindFirstChild("TutorialStep")
        if value then value.Value = 4 end
    end)

    scope:Connect(ProximityPromptService.PromptButtonHoldBegan, function(prompt)
        if noECooldown then prompt.HoldDuration = 0 end
    end)

    scope:Connect(RunService.Heartbeat, function()
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if character and noclip then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        if killAura and root then
            local tool = character:FindFirstChildWhichIsA("Tool")
            local swing = tool and tool:FindFirstChild("SwingEvent")
            if swing then
                local target = Common.NearestCharacter(root.Position, 12)
                if target and target.PrimaryPart then
                    pcall(function() swing:FireServer(target.PrimaryPart.Position) end)
                end
            end
        end
        local tool = character and character:FindFirstChildWhichIsA("Tool")
        local configuration = tool and tool:FindFirstChildWhichIsA("Configuration")
        if configuration then
            local value = configuration:FindFirstChild("FireDelay")
            local value2 = configuration:FindFirstChild("SpreadAngle")
            local value3 = configuration:FindFirstChild("ReloadDuration")
            if value then value.Value = fireDelay end
            if value2 then value2.Value = spread end
            if value3 then value3.Value = reload end
        end
        if noBandageDelay then
            local gui = localPlayer:FindFirstChild("PlayerGui")
            local bandageGui = gui and gui:FindFirstChild("BandageUse")
            local bandage = character and character:FindFirstChild("Bandage")
            local use = bandage and bandage:FindFirstChild("Use")
            if bandageGui and bandageGui.Enabled and use then pcall(function() use:FireServer() end) end
        end
    end)

    scope:Connect(RunService.RenderStepped, function()
        local camera = workspace.CurrentCamera
        if circle and camera then
            circle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            circle.Radius = fov
            circle.Visible = aimbot
        end
        if aimbot and camera then
            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            local best
            local bestDistance = fov
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    local head = model:FindFirstChild("Head")
                    if humanoid and humanoid.Health > 0 and head then
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
            end
            if best then camera.CFrame = CFrame.lookAt(camera.CFrame.Position, best.Position) end
        end
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
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then mark(model, "Mobs", Color3.fromRGB(255, 80, 80)) end
                end
            end
        end
    end)

    scope:AddRestore(function() clearEsp() end)
end
