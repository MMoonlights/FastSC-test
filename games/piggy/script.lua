return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local tab = ctx.Window:CreateTab("Main", "P")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local speedEnabled = false
    local speed = 32
    local playerEsp = false
    local itemEsp = false
    local highlights = {}
    local items = {}

    local function clearHighlight(instance)
        local data = highlights[instance]
        if not data then return end
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.Gui then pcall(function() data.Gui:Destroy() end) end
        highlights[instance] = nil
    end

    local function clearHighlights(kind)
        for instance, data in pairs(highlights) do
            if not kind or data.Kind == kind then
                clearHighlight(instance)
            end
        end
    end

    local function positionOf(instance)
        if not instance or not instance.Parent then return nil end
        if instance:IsA("BasePart") then return instance.Position end
        if instance:IsA("Model") then
            local part = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
            return part and part.Position
        end
    end

    local function tag(instance, kind, color, text)
        if highlights[instance] or not instance or not instance.Parent then return end
        local adornee = instance:IsA("Model") and (instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Head") or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")) or instance
        if not adornee then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "FastSC_" .. kind
        highlight.Adornee = instance
        highlight.FillColor = color
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = instance
        local gui = Instance.new("BillboardGui")
        gui.Name = "FastSC_Tag"
        gui.Adornee = adornee
        gui.Size = UDim2.new(0, 160, 0, 30)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = adornee
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.45
        label.Text = text
        label.Parent = gui
        highlights[instance] = {Kind = kind, Highlight = highlight, Gui = gui}
    end

    local function registerItem(instance)
        local item
        if instance.Name == "ItemPickupScript" then
            item = instance.Parent
        elseif instance:IsA("ClickDetector") then
            item = instance.Parent
        end
        if not item or not item.Parent then return end
        items[item] = true
        if itemEsp then
            tag(item, "Item", Color3.fromRGB(255, 210, 70), item.Name)
        end
    end

    for _, instance in ipairs(workspace:GetDescendants()) do
        registerItem(instance)
    end

    scope:Connect(workspace.DescendantAdded, registerItem)
    scope:Connect(workspace.DescendantRemoving, function(instance)
        if items[instance] then
            items[instance] = nil
            clearHighlight(instance)
        end
    end)

    local function attachPlayer(player)
        if player == localPlayer then return end
        local function onCharacter(character)
            if playerEsp then
                task.defer(function()
                    if character.Parent then
                        tag(character, "Player", Color3.fromRGB(80, 170, 255), player.DisplayName)
                    end
                end)
            end
        end
        if player.Character then onCharacter(player.Character) end
        scope:Connect(player.CharacterAdded, onCharacter)
        scope:Connect(player.CharacterRemoving, clearHighlight)
    end

    for _, player in ipairs(Players:GetPlayers()) do attachPlayer(player) end
    scope:Connect(Players.PlayerAdded, attachPlayer)

    scope:Connect(workspace.DescendantAdded, function(instance)
        if playerEsp and instance:IsA("Model") and instance.Name == "PiggyNPC" then
            task.defer(function()
                if instance.Parent then tag(instance, "Player", Color3.fromRGB(255, 80, 80), "Piggy") end
            end)
        end
    end)

    local function currentHumanoid()
        local character = localPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    tab:CreateSection("Player")
    tab:CreateToggle("WalkSpeed", false, function(enabled)
        speedEnabled = enabled
        if enabled then
            scope:Loop("speed", 0.05, function()
                local humanoid = currentHumanoid()
                if humanoid then scope:Set(humanoid, "WalkSpeed", speed) end
            end)
        else
            scope:StopTask("speed")
            local humanoid = currentHumanoid()
            if humanoid then scope:Restore(humanoid, "WalkSpeed") end
        end
    end)
    tab:CreateSlider("WalkSpeed value", {Min = 16, Max = 120, Default = 32}, function(value)
        speed = value
    end)

    tab:CreateSection("ESP")
    tab:CreateToggle("Piggy & players ESP", false, function(enabled)
        playerEsp = enabled
        if enabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    tag(player.Character, "Player", Color3.fromRGB(80, 170, 255), player.DisplayName)
                end
            end
            local piggy = workspace:FindFirstChild("PiggyNPC", true)
            if piggy then tag(piggy, "Player", Color3.fromRGB(255, 80, 80), "Piggy") end
        else
            clearHighlights("Player")
        end
    end)
    tab:CreateToggle("Tools ESP", false, function(enabled)
        itemEsp = enabled
        if enabled then
            for item in pairs(items) do
                if item.Parent then tag(item, "Item", Color3.fromRGB(255, 210, 70), item.Name) end
            end
        else
            clearHighlights("Item")
        end
    end)
    tab:CreateButton("Teleport to nearest item", function()
        local root = Common.Root()
        local nearest
        local best = math.huge
        for item in pairs(items) do
            local position = positionOf(item)
            if position then
                local distance = (position - root.Position).Magnitude
                if distance < best then
                    nearest = item
                    best = distance
                end
            else
                items[item] = nil
            end
        end
        if nearest then
            if nearest:IsA("BasePart") then
                root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
            elseif nearest:IsA("Model") then
                nearest = nearest.PrimaryPart or nearest:FindFirstChildWhichIsA("BasePart")
                if nearest then root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0) end
            end
        end
    end)

    scope:Loop("highlightCleanup", 1, function()
        for instance in pairs(highlights) do
            if not instance.Parent then highlights[instance] = nil end
        end
    end)

    scope:AddRestore(function()
        scope:StopTask("speed")
        local humanoid = currentHumanoid()
        if humanoid then scope:Restore(humanoid, "WalkSpeed") end
        clearHighlights()
    end)
end
