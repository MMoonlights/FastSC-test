return function(ctx)
    local scope = ctx.Scope
    local mode = ctx.Mode or "Legit"
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local localPlayer = Players.LocalPlayer
    local enemies = {}
    local loot = {}
    local materials = {}
    local visuals = {}
    local infiniteJump = false
    local noclip = false
    local speedEnabled = false
    local speedValue = mode == "Rage" and 70 or 24
    local jumpEnabled = false
    local jumpValue = mode == "Rage" and 100 or 60
    local enemyEsp = false
    local lootEsp = false
    local materialEsp = false
    local hitboxEnabled = false
    local hitboxSize = 8

    local function rootPart(object)
        if not object or not object.Parent then return nil end
        if object:IsA("BasePart") then return object end
        if object:IsA("Model") then
            return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object:FindFirstChildWhichIsA("BasePart", true)
        end
    end

    local function ancestorMatches(instance, words)
        local current = instance
        while current and current ~= workspace do
            local name = string.lower(current.Name)
            for _, word in ipairs(words) do
                if string.find(name, word, 1, true) then return true end
            end
            current = current.Parent
        end
        return false
    end

    local function isEnemy(model)
        if not model or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then return false end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        local name = string.lower(model.Name)
        return string.find(name, "infect", 1, true)
            or string.find(name, "enemy", 1, true)
            or string.find(name, "bandit", 1, true)
            or string.find(name, "piggy", 1, true)
            or model:GetAttribute("Hostile") == true
            or model:GetAttribute("Enemy") == true
    end

    local function register(instance)
        if instance:IsA("Humanoid") and instance.Parent and isEnemy(instance.Parent) then
            enemies[instance.Parent] = true
        elseif instance:IsA("Model") and isEnemy(instance) then
            enemies[instance] = true
        end
        if instance:IsA("BasePart") or instance:IsA("Model") then
            if ancestorMatches(instance, {"lootcrate", "loot crate", "crate", "chest"}) then
                loot[instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model") or instance] = true
            end
            if ancestorMatches(instance, {"material", "resource", "scrap", "wood", "stone", "metal", "ore", "log"}) then
                materials[instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model") or instance] = true
            end
        end
    end

    for _, instance in ipairs(workspace:GetDescendants()) do register(instance) end
    scope:Connect(workspace.DescendantAdded, register)
    scope:Connect(workspace.DescendantRemoving, function(instance)
        enemies[instance] = nil
        loot[instance] = nil
        materials[instance] = nil
    end)

    local function clearVisual(object)
        local data = visuals[object]
        if not data then return end
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.Gui then pcall(function() data.Gui:Destroy() end) end
        visuals[object] = nil
    end

    local function clearKind(kind)
        for object, data in pairs(visuals) do
            if not kind or data.Kind == kind then clearVisual(object) end
        end
    end

    local function tag(object, kind, color, title)
        if not object or not object.Parent or visuals[object] then return end
        local part = rootPart(object)
        if not part then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "FastSC_" .. kind
        highlight.Adornee = object:IsA("Model") and object or part
        highlight.FillColor = color
        highlight.FillTransparency = 0.65
        highlight.OutlineColor = color
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = object:IsA("Model") and object or part
        local gui = Instance.new("BillboardGui")
        gui.Name = "FastSC_Label"
        gui.Adornee = part
        gui.Size = UDim2.new(0, 180, 0, 30)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = part
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.4
        label.Text = title
        label.Parent = gui
        visuals[object] = {Kind = kind, Highlight = highlight, Gui = gui, Label = label, Title = title}
    end

    scope:Loop("visuals", 0.3, function()
        if enemyEsp then
            for enemy in pairs(enemies) do
                local humanoid = enemy.Parent and enemy:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then tag(enemy, "Enemy", Color3.fromRGB(255, 70, 80), enemy.Name) end
            end
        end
        if lootEsp then
            for object in pairs(loot) do if object.Parent then tag(object, "Loot", Color3.fromRGB(255, 210, 70), object.Name) end end
        end
        if materialEsp then
            for object in pairs(materials) do if object.Parent then tag(object, "Material", Color3.fromRGB(80, 220, 150), object.Name) end end
        end
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        for object, data in pairs(visuals) do
            local part = rootPart(object)
            if not object.Parent or not part then
                clearVisual(object)
            elseif root and data.Label then
                data.Label.Text = data.Title .. "  [" .. tostring(math.floor((part.Position - root.Position).Magnitude)) .. "]"
            end
        end
    end)

    local function nearest(set)
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best
        local distance = math.huge
        for object in pairs(set) do
            local part = rootPart(object)
            if part then
                local current = (part.Position - root.Position).Magnitude
                if current < distance then
                    best = object
                    distance = current
                end
            end
        end
        return best
    end

    local function teleportTo(object)
        local part = rootPart(object)
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if part and root then root.CFrame = part.CFrame + Vector3.new(0, 3, 0) end
    end

    local function applyNoclip()
        local character = localPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then scope:Set(part, "CanCollide", false) end
        end
    end

    local function restoreNoclip()
        local character = localPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then scope:Restore(part, "CanCollide") end
        end
    end

    local function refreshHitboxes()
        for enemy in pairs(enemies) do
            local part = rootPart(enemy)
            if part then
                if hitboxEnabled then
                    scope:Set(part, "Size", Vector3.new(hitboxSize, hitboxSize, hitboxSize))
                    scope:Set(part, "Transparency", 0.45)
                    scope:Set(part, "CanCollide", false)
                else
                    scope:Restore(part, "Size")
                    scope:Restore(part, "Transparency")
                    scope:Restore(part, "CanCollide")
                end
            end
        end
    end

    local main = ctx.Window:CreateTab(mode, mode == "Rage" and "R" or "L")
    local visual = ctx.Window:CreateTab("ESP", "E")
    local player = ctx.Window:CreateTab("Player", "P")

    main:CreateSection("Resources")
    main:CreateButton("Teleport to nearest lootcrate", function() teleportTo(nearest(loot)) end)
    main:CreateButton("Teleport to nearest material", function() teleportTo(nearest(materials)) end)

    if mode == "Rage" then
        main:CreateSection("Combat")
        main:CreateToggle("Enemy hitbox", false, function(value)
            hitboxEnabled = value
            refreshHitboxes()
        end)
        main:CreateSlider("Hitbox size", {Min = 3, Max = 25, Default = hitboxSize}, function(value)
            hitboxSize = value
            if hitboxEnabled then refreshHitboxes() end
        end)
    end

    visual:CreateSection("Visuals")
    visual:CreateToggle("Enemies ESP", false, function(value)
        enemyEsp = value
        if not value then clearKind("Enemy") end
    end)
    visual:CreateToggle("Lootcrates ESP", false, function(value)
        lootEsp = value
        if not value then clearKind("Loot") end
    end)
    visual:CreateToggle("Materials ESP", false, function(value)
        materialEsp = value
        if not value then clearKind("Material") end
    end)
    visual:CreateToggle("Fullbright", false, function(value)
        if value then
            scope:Set(Lighting, "Brightness", 4)
            scope:Set(Lighting, "GlobalShadows", false)
            scope:Set(Lighting, "Ambient", Color3.new(1, 1, 1))
            scope:Set(Lighting, "OutdoorAmbient", Color3.new(1, 1, 1))
        else
            scope:Restore(Lighting, "Brightness")
            scope:Restore(Lighting, "GlobalShadows")
            scope:Restore(Lighting, "Ambient")
            scope:Restore(Lighting, "OutdoorAmbient")
        end
    end)

    player:CreateSection("Movement")
    player:CreateToggle("Speed", false, function(value)
        speedEnabled = value
        if not value then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then scope:Restore(humanoid, "WalkSpeed") end
        end
    end)
    player:CreateSlider("Speed value", {Min = 16, Max = mode == "Rage" and 140 or 40, Default = speedValue}, function(value) speedValue = value end)
    player:CreateToggle("Jump", false, function(value)
        jumpEnabled = value
        if not value then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then scope:Restore(humanoid, "JumpPower") end
        end
    end)
    player:CreateSlider("Jump value", {Min = 50, Max = mode == "Rage" and 180 or 85, Default = jumpValue}, function(value) jumpValue = value end)
    player:CreateToggle("Infinite jump", false, function(value) infiniteJump = value end)
    player:CreateToggle("Noclip", false, function(value)
        noclip = value
        if value then applyNoclip() else restoreNoclip() end
    end)

    scope:Connect(UserInputService.JumpRequest, function()
        if infiniteJump then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    scope:Loop("playerState", 0.05, function()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if speedEnabled and humanoid then scope:Set(humanoid, "WalkSpeed", speedValue) end
        if jumpEnabled and humanoid then scope:Set(humanoid, "JumpPower", jumpValue) end
        if noclip then applyNoclip() end
    end)

    scope:Loop("hitboxes", 0.2, function()
        if hitboxEnabled then refreshHitboxes() end
    end)

    scope:AddRestore(function()
        clearKind()
        restoreNoclip()
        hitboxEnabled = false
        refreshHitboxes()
    end)
end
