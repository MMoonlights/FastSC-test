return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local combat = ctx.Window:CreateTab("Combat", "D")
    local movement = ctx.Window:CreateTab("Movement", "M")
    local automation = ctx.Window:CreateTab("Automation", "A")
    local visuals = ctx.Window:CreateTab("Visuals", "V")
    local shopTab = ctx.Window:CreateTab("Shop", "S")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local localPlayer = Players.LocalPlayer
    local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
    local settings = {
        Camlock = false,
        CamlockKey = Enum.KeyCode.C,
        Target = nil,
        Prediction = 0.165,
        AutoPrediction = false,
        AimPart = "HumanoidRootPart",
        Distance = 150,
        FOV = 120,
        ShowFOV = false,
        Highlight = false,
        Tracer = false,
        Hitbox = 2,
        Speed = false,
        SpeedValue = 0.37,
        Fly = false,
        FlySpeed = 3,
        Bhop = false,
        Strafe = false,
        Antislow = false,
        AutoClicker = false,
        PlayerESP = false,
    }
    local circle = Common.DrawingCircle(scope, settings.FOV, Color3.fromRGB(230, 60, 80))
    local tracer
    if Drawing then
        tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Thickness = 2
        tracer.Color = Color3.fromRGB(230, 60, 80)
        scope:TrackDrawing(tracer)
    end
    local targetHighlight
    local espHighlights = {}
    local oldHitboxes = {}
    local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}
    local selectedShop

    local function prediction()
        if not settings.AutoPrediction then return settings.Prediction end
        local pingString = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        local ping = tonumber(string.match(pingString, "[%d%.]+")) or 70
        if ping < 20 then return 0.139 end
        if ping < 35 then return 0.152 end
        if ping < 50 then return 0.171 end
        if ping < 75 then return 0.183 end
        if ping < 95 then return 0.196 end
        if ping < 110 then return 0.209 end
        if ping < 130 then return 0.224 end
        if ping < 155 then return 0.239 end
        if ping < 180 then return 0.256 end
        if ping < 200 then return 0.274 end
        return 0.296
    end

    local function clearTarget()
        settings.Target = nil
        if targetHighlight then
            pcall(function() targetHighlight:Destroy() end)
            targetHighlight = nil
        end
        if tracer then tracer.Visible = false end
    end

    local function acquireTarget()
        local player = Common.NearestToCursor({FOV = settings.FOV, Part = settings.AimPart, MaxDistance = settings.Distance})
        settings.Target = player
        if targetHighlight then pcall(function() targetHighlight:Destroy() end) targetHighlight = nil end
        if player and settings.Highlight and player.Character then
            targetHighlight = Instance.new("Highlight")
            targetHighlight.Name = "FastSC_Target"
            targetHighlight.Adornee = player.Character
            targetHighlight.FillColor = Color3.fromRGB(230, 60, 80)
            targetHighlight.FillTransparency = 0.55
            targetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            targetHighlight.Parent = player.Character
        end
    end

    combat:CreateSection("Camlock")
    combat:CreateToggle("Camlock", false, function(value)
        settings.Camlock = value
        if not value then clearTarget() end
    end)
    combat:CreateKeybind("Camlock key", Enum.KeyCode.C, function(key)
        if key then settings.CamlockKey = key end
    end)
    combat:CreateDropdown("Aim part", {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}, settings.AimPart, function(value)
        settings.AimPart = value
    end)
    combat:CreateInput("Prediction", "0.165", function(value)
        settings.Prediction = tonumber(value) or settings.Prediction
    end)
    combat:CreateToggle("Auto prediction", false, function(value) settings.AutoPrediction = value end)
    combat:CreateSlider("Distance", {Min = 50, Max = 500, Default = 150}, function(value) settings.Distance = value end)
    combat:CreateSlider("FOV radius", {Min = 30, Max = 400, Default = 120}, function(value)
        settings.FOV = value
        if circle then circle.Radius = value end
    end)
    combat:CreateToggle("Show FOV", false, function(value)
        settings.ShowFOV = value
        if circle then circle.Visible = value end
    end)
    combat:CreateToggle("Target highlight", false, function(value)
        settings.Highlight = value
        if settings.Target then acquireTarget() end
    end)
    combat:CreateToggle("Tracer", false, function(value)
        settings.Tracer = value
        if not value and tracer then tracer.Visible = false end
    end)

    combat:CreateSection("Hitbox")
    combat:CreateSlider("Enemy hitbox size", {Min = 2, Max = 30, Default = 2}, function(value)
        settings.Hitbox = value
    end)
    combat:CreateButton("Reset enemy hitboxes", function()
        for part, data in pairs(oldHitboxes) do
            if part and part.Parent then
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
            end
            oldHitboxes[part] = nil
        end
        settings.Hitbox = 2
    end)
    combat:CreateButton("No recoil", function()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
    end)

    movement:CreateSection("Movement")
    movement:CreateToggle("CFrame speed", false, function(value) settings.Speed = value end)
    movement:CreateSlider("CFrame speed value", {Min = 5, Max = 100, Default = 37}, function(value) settings.SpeedValue = value / 100 end)
    movement:CreateToggle("CFrame fly", false, function(value) settings.Fly = value end)
    movement:CreateSlider("Fly speed", {Min = 1, Max = 12, Default = 3}, function(value) settings.FlySpeed = value end)
    movement:CreateToggle("Bhop", false, function(value) settings.Bhop = value end)
    movement:CreateToggle("Strafe jump", false, function(value) settings.Strafe = value end)
    movement:CreateToggle("Antislow", false, function(value) settings.Antislow = value end)
    movement:CreateToggle("Auto clicker", false, function(value) settings.AutoClicker = value end)

    automation:CreateSection("Combat automation")
    automation:CreateToggle("Auto reload", false, function(enabled)
        if enabled then
            scope:Loop("reload", 0.05, function()
                local character = localPlayer.Character
                local tool = character and character:FindFirstChildWhichIsA("Tool")
                local ammo = tool and tool:FindFirstChild("Ammo")
                if tool and ammo and ammo.Value <= 0 and mainEvent then mainEvent:FireServer("Reload", tool) end
            end)
        else
            scope:StopTask("reload")
        end
    end)
    automation:CreateToggle("Auto stomp", false, function(enabled)
        if enabled then
            scope:Loop("stomp", 0.08, function()
                if mainEvent then mainEvent:FireServer("Stomp") end
            end)
        else
            scope:StopTask("stomp")
        end
    end)
    automation:CreateToggle("Auto activate equipped tool", false, function(enabled)
        if enabled then
            scope:Loop("activate", 0.12, function()
                local tool = localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then tool:Activate() end
            end)
        else
            scope:StopTask("activate")
        end
    end)
    automation:CreateToggle("Auto buy armor", false, function(enabled)
        if enabled then
            scope:Loop("armor", 1, function()
                local character = localPlayer.Character
                local bodyEffects = character and character:FindFirstChild("BodyEffects")
                local armor = bodyEffects and bodyEffects:FindFirstChild("Armor")
                local shop = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Shop")
                local item = shop and shop:FindFirstChild("[High-Medium Armor] - $2513")
                if armor and armor.Value < 75 and item and item:FindFirstChild("ClickDetector") then
                    local root = Common.Root()
                    local old = root.CFrame
                    local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                    if part then root.CFrame = part.CFrame + Vector3.new(0, 3, 0) end
                    task.wait(0.15)
                    Common.FireClick(item.ClickDetector)
                    task.wait(0.15)
                    root.CFrame = old
                end
            end)
        else
            scope:StopTask("armor")
        end
    end)
    automation:CreateToggle("Auto eat", false, function(enabled)
        if enabled then
            scope:Loop("eat", 0.35, function()
                local character = localPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health >= 55 then return end
                local chicken = character:FindFirstChild("[Chicken]") or localPlayer.Backpack:FindFirstChild("[Chicken]")
                if not chicken then
                    local shop = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Shop")
                    local item = shop and shop:FindFirstChild("[Chicken] - $7")
                    if item and item:FindFirstChild("ClickDetector") then Common.FireClick(item.ClickDetector) end
                else
                    if chicken.Parent ~= character then humanoid:EquipTool(chicken) end
                    chicken:Activate()
                end
            end)
        else
            scope:StopTask("eat")
        end
    end)
    automation:CreateToggle("Anti stomp", false, function(enabled)
        if enabled then
            scope:Loop("antiStomp", 0.05, function()
                local character = localPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 5 then
                    for _, item in ipairs(character:GetChildren()) do
                        if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then item:Destroy() end
                    end
                end
            end)
        else
            scope:StopTask("antiStomp")
        end
    end)
    automation:CreateButton("Open skin crate", function()
        if mainEvent then mainEvent:FireServer("PurchaseSkinCrate", false) end
    end)
    automation:CreateButton("Drop 10K", function()
        if mainEvent then mainEvent:FireServer("DropMoney", "10000") end
    end)
    automation:CreateToggle("Auto drop cash", false, function(value)
        if value then
            scope:Loop("dropCash", 1, function()
                if mainEvent then mainEvent:FireServer("DropMoney", "10000") end
            end)
        else
            scope:StopTask("dropCash")
        end
    end)

    visuals:CreateSection("Players")
    visuals:CreateToggle("Player highlight", false, function(value)
        settings.PlayerESP = value
        if not value then
            for character, highlight in pairs(espHighlights) do
                pcall(function() highlight:Destroy() end)
                espHighlights[character] = nil
            end
        end
    end)
    visuals:CreateToggle("World tint", false, function(value)
        local effect = Lighting:FindFirstChild("FastSC_WorldColor")
        if value then
            if not effect then
                effect = Instance.new("ColorCorrectionEffect")
                effect.Name = "FastSC_WorldColor"
                effect.TintColor = Color3.fromRGB(180, 120, 255)
                effect.Parent = Lighting
                scope:TrackInstance(effect)
            end
        elseif effect then
            effect:Destroy()
        end
    end)
    visuals:CreateButton("Highlight dropped cash", function()
        local ignored = workspace:FindFirstChild("Ignored")
        local drop = ignored and ignored:FindFirstChild("Drop")
        if not drop then return end
        for _, item in ipairs(drop:GetChildren()) do
            if item.Name == "MoneyDrop" and not item:FindFirstChild("FastSC_Cash") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "FastSC_Cash"
                highlight.Adornee = item
                highlight.FillColor = Color3.fromRGB(70, 255, 120)
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = item
            end
        end
    end)

    local shop = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Shop")
    local shopNames = {}
    if shop then
        for _, item in ipairs(shop:GetChildren()) do shopNames[#shopNames + 1] = item.Name end
        table.sort(shopNames)
    end
    selectedShop = shopNames[1]
    shopTab:CreateSection("Buy")
    shopTab:CreateDropdown("Item", shopNames, selectedShop, function(value) selectedShop = value end)
    shopTab:CreateButton("Teleport & buy", function()
        local item = shop and selectedShop and shop:FindFirstChild(selectedShop)
        local click = item and item:FindFirstChild("ClickDetector")
        if item and click then
            local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
            if part then Common.Root().CFrame = part.CFrame + Vector3.new(0, 3, 0) end
            task.wait(0.15)
            Common.FireClick(click)
        end
    end)

    scope:Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        local name = input.KeyCode.Name
        if flyKeys[name] ~= nil then flyKeys[name] = true end
        if settings.Camlock and input.KeyCode == settings.CamlockKey then
            if settings.Target then clearTarget() else acquireTarget() end
        end
    end)
    scope:Connect(UserInputService.InputEnded, function(input)
        local name = input.KeyCode.Name
        if flyKeys[name] ~= nil then flyKeys[name] = false end
    end)

    scope:Connect(RunService.Heartbeat, function()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and humanoid then
            if settings.Speed then root.CFrame = root.CFrame + humanoid.MoveDirection * settings.SpeedValue end
            if settings.Bhop and humanoid.MoveDirection.Magnitude > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            if settings.Strafe and humanoid:GetState() == Enum.HumanoidStateType.Freefall and humanoid.MoveDirection.Magnitude > 0 then
                character:TranslateBy(humanoid.MoveDirection / 3.1)
            end
            if settings.Antislow then
                local bodyEffects = character:FindFirstChild("BodyEffects")
                local movementFolder = bodyEffects and bodyEffects:FindFirstChild("Movement")
                if movementFolder then
                    for _, name in ipairs({"NoJumping", "ReduceWalk", "NoWalkSpeed"}) do
                        local item = movementFolder:FindFirstChild(name)
                        if item then item:Destroy() end
                    end
                end
                local reloadValue = bodyEffects and bodyEffects:FindFirstChild("Reload")
                if reloadValue and reloadValue.Value then reloadValue.Value = false end
            end
            if settings.Fly then
                root.AssemblyLinearVelocity = Vector3.zero
                local camera = workspace.CurrentCamera
                local direction = Vector3.zero
                if flyKeys.W then direction += camera.CFrame.LookVector end
                if flyKeys.S then direction -= camera.CFrame.LookVector end
                if flyKeys.A then direction -= camera.CFrame.RightVector end
                if flyKeys.D then direction += camera.CFrame.RightVector end
                if flyKeys.Space then direction += Vector3.yAxis end
                if flyKeys.LeftShift then direction -= Vector3.yAxis end
                if direction.Magnitude > 0 then root.CFrame += direction.Unit * settings.FlySpeed end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    if not oldHitboxes[enemyRoot] then
                        oldHitboxes[enemyRoot] = {Size = enemyRoot.Size, Transparency = enemyRoot.Transparency, CanCollide = enemyRoot.CanCollide}
                    end
                    if settings.Hitbox > 2 then
                        enemyRoot.Size = Vector3.new(settings.Hitbox, settings.Hitbox, settings.Hitbox)
                        enemyRoot.Transparency = 0.5
                        enemyRoot.CanCollide = false
                    else
                        local data = oldHitboxes[enemyRoot]
                        enemyRoot.Size = data.Size
                        enemyRoot.Transparency = data.Transparency
                        enemyRoot.CanCollide = data.CanCollide
                    end
                end
            end
        end

        if settings.PlayerESP then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    local character2 = player.Character
                    local highlight = espHighlights[character2]
                    if not highlight or not highlight.Parent then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "FastSC_Player"
                        highlight.Adornee = character2
                        highlight.FillColor = Color3.fromRGB(230, 60, 80)
                        highlight.FillTransparency = 0.65
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = character2
                        espHighlights[character2] = highlight
                    end
                end
            end
        end
    end)

    scope:Connect(RunService.RenderStepped, function()
        local camera = workspace.CurrentCamera
        if circle then
            circle.Position = UserInputService:GetMouseLocation()
            circle.Radius = settings.FOV
            circle.Visible = settings.ShowFOV
        end
        if settings.AutoClicker then
            pcall(function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) end)
            pcall(function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
        end
        local target = settings.Target
        local part = target and target.Character and target.Character:FindFirstChild(settings.AimPart)
        if settings.Camlock and part and camera then
            local predicted = part.Position + part.AssemblyLinearVelocity * prediction()
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, predicted)
            if tracer then
                local point, visible = camera:WorldToViewportPoint(part.Position)
                tracer.Visible = settings.Tracer and visible
                if tracer.Visible then
                    tracer.From = UserInputService:GetMouseLocation()
                    tracer.To = Vector2.new(point.X, point.Y)
                end
            end
        elseif tracer then
            tracer.Visible = false
        end
    end)

    scope:AddRestore(function()
        clearTarget()
        for part, data in pairs(oldHitboxes) do
            if part and part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                    part.CanCollide = data.CanCollide
                end)
            end
        end
        for character, highlight in pairs(espHighlights) do
            pcall(function() highlight:Destroy() end)
            espHighlights[character] = nil
        end
    end)
end
