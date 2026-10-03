return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local tab = ctx.Window:CreateTab("Main", "P")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer
    local speedEnabled = false
    local speed = 16
    local playerEsp = false
    local itemEsp = false
    local highlights = {}

    local function clearHighlights(kind)
        for instance, data in pairs(highlights) do
            if not kind or data.Kind == kind then
                if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
                if data.Gui then pcall(function() data.Gui:Destroy() end) end
                highlights[instance] = nil
            end
        end
    end

    local function tag(instance, kind, color, text)
        if highlights[instance] or not instance.Parent then return end
        local adornee = instance:IsA("Model") and (instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Head") or instance.PrimaryPart) or instance
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

    tab:CreateSection("Player")
    tab:CreateToggle("WalkSpeed", false, function(enabled)
        speedEnabled = enabled
        if not enabled then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = 16 end
        end
    end)
    tab:CreateSlider("WalkSpeed value", {Min = 16, Max = 120, Default = 32}, function(value)
        speed = value
    end)

    tab:CreateSection("ESP")
    tab:CreateToggle("Piggy & players ESP", false, function(enabled)
        playerEsp = enabled
        if not enabled then clearHighlights("Player") end
    end)
    tab:CreateToggle("Tools ESP", false, function(enabled)
        itemEsp = enabled
        if not enabled then clearHighlights("Item") end
    end)
    tab:CreateButton("Teleport to nearest item", function()
        local root = Common.Root()
        local nearest
        local distance = math.huge
        for _, instance in ipairs(workspace:GetDescendants()) do
            if instance:IsA("BasePart") and instance.Parent and (instance.Parent:FindFirstChild("ItemPickupScript") or instance:FindFirstChild("ClickDetector") or instance.Parent:FindFirstChild("ClickDetector")) then
                local current = (instance.Position - root.Position).Magnitude
                if current < distance then
                    nearest = instance
                    distance = current
                end
            end
        end
        if nearest then root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0) end
    end)

    scope:Connect(RunService.Heartbeat, function()
        if speedEnabled then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = speed end
        end
        if playerEsp then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character and not highlights[player.Character] then
                    tag(player.Character, "Player", Color3.fromRGB(80, 170, 255), player.DisplayName)
                end
            end
            local piggy = workspace:FindFirstChild("PiggyNPC")
            if piggy and not highlights[piggy] then
                tag(piggy, "Player", Color3.fromRGB(255, 80, 80), "Piggy")
            end
        end
        if itemEsp then
            for _, instance in ipairs(workspace:GetDescendants()) do
                if instance.Name == "ItemPickupScript" and instance.Parent and not highlights[instance.Parent] then
                    tag(instance.Parent, "Item", Color3.fromRGB(255, 210, 70), instance.Parent.Name)
                end
            end
        end
        for instance in pairs(highlights) do
            if not instance.Parent then highlights[instance] = nil end
        end
    end)

    scope:AddRestore(function() clearHighlights() end)
end
