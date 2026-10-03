return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local tab = ctx.Window:CreateTab("Main", "M")
    local farmTab = ctx.Window:CreateTab("Farm", "F")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local localPlayer = Players.LocalPlayer
    local circle = Common.DrawingCircle(scope, 100, Color3.fromRGB(230, 60, 80))
    local silentAim = false
    local roleEsp = false
    local gunEsp = false
    local roleHighlights = {}
    local gunHighlights = {}
    local coinCache = Common.CreateDescendantCache(scope, workspace, function(instance)
        return instance:IsA("BasePart") and (instance.Name == "Coin_Server" or instance.Name == "Coin")
    end)
    local gunCache = Common.CreateDescendantCache(scope, workspace, function(instance)
        return instance:IsA("BasePart") and instance.Name == "GunDrop"
    end)

    local function role(player)
        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")
        if (character and character:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer" end
        if (character and character:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then return "Sheriff" end
        return "Innocent"
    end

    local colors = {
        Murderer = Color3.fromRGB(255, 70, 80),
        Sheriff = Color3.fromRGB(80, 150, 255),
        Innocent = Color3.fromRGB(70, 220, 130),
    }

    local function clearTable(objects)
        for instance, highlight in pairs(objects) do
            pcall(function() highlight:Destroy() end)
            objects[instance] = nil
        end
    end

    local function updateRoleEsp()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local character = player.Character
                local currentRole = role(player)
                local highlight = roleHighlights[character]
                if not highlight or not highlight.Parent then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "FastSC_MM2"
                    highlight.Adornee = character
                    highlight.FillTransparency = 0.55
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = character
                    roleHighlights[character] = highlight
                end
                highlight.FillColor = colors[currentRole]
                highlight.OutlineColor = colors[currentRole]
            end
        end
        for character in pairs(roleHighlights) do
            if not character.Parent then roleHighlights[character] = nil end
        end
    end

    local function updateGunEsp()
        gunCache:Each(function(gun)
            if not gunHighlights[gun] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "FastSC_Gun"
                highlight.Adornee = gun
                highlight.FillColor = Color3.fromRGB(80, 255, 120)
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = gun
                gunHighlights[gun] = highlight
            end
        end)
        for gun, highlight in pairs(gunHighlights) do
            if not gun.Parent then
                pcall(function() highlight:Destroy() end)
                gunHighlights[gun] = nil
            end
        end
    end

    local function fireSilentAim()
        if not silentAim then return end
        local localRole = role(localPlayer)
        local targetRole = localRole == "Sheriff" and "Murderer" or localRole == "Murderer" and "Sheriff" or nil
        if not targetRole then return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local mouse = UserInputService:GetMouseLocation()
        local best
        local bestDistance = circle and circle.Radius or 100
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and Common.Alive(player) and role(player) == targetRole then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local point, visible = camera:WorldToViewportPoint(root.Position)
                    if visible then
                        local distance = (Vector2.new(point.X, point.Y) - mouse).Magnitude
                        if distance < bestDistance then
                            best = player
                            bestDistance = distance
                        end
                    end
                end
            end
        end
        if not best then return end
        local character = localPlayer.Character
        local gun = character and character:FindFirstChild("Gun")
        local knife = character and character:FindFirstChild("Knife")
        local targetRoot = best.Character and best.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        if gun and gun:FindFirstChild("Gun") and gun.Gun:FindFirstChild("KnifeLocal") then
            local remote = gun.Gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
            if remote then pcall(function() remote:InvokeServer(1, targetRoot.Position, "AH2") end) end
        elseif knife and knife:FindFirstChild("Throw") then
            pcall(function() knife.Throw:FireServer(targetRoot.CFrame, targetRoot.Position) end)
        end
    end

    tab:CreateSection("Combat")
    tab:CreateToggle("Silent aim", false, function(enabled)
        silentAim = enabled
        if circle then circle.Visible = enabled end
        if enabled then
            scope:Loop("silentAim", 0.05, fireSilentAim)
        else
            scope:StopTask("silentAim")
        end
    end)
    tab:CreateToggle("Auto kill all", false, function(enabled)
        if enabled then
            scope:Loop("killAll", 0.08, function()
                local root = Common.Root()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and Common.Alive(player) then
                        player.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -2)
                    end
                end
            end)
        else
            scope:StopTask("killAll")
        end
    end)
    tab:CreateToggle("Auto kill sheriff", false, function(enabled)
        if enabled then
            scope:Loop("killSheriff", 0.1, function()
                local root = Common.Root()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and Common.Alive(player) and role(player) == "Sheriff" then
                        player.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -2)
                    end
                end
            end)
        else
            scope:StopTask("killSheriff")
        end
    end)

    tab:CreateSection("Visuals")
    tab:CreateToggle("Role ESP", false, function(enabled)
        roleEsp = enabled
        if enabled then
            updateRoleEsp()
            scope:Loop("roleEsp", 0.25, updateRoleEsp)
        else
            scope:StopTask("roleEsp")
            clearTable(roleHighlights)
        end
    end)
    tab:CreateToggle("Dropped gun ESP", false, function(enabled)
        gunEsp = enabled
        if enabled then
            updateGunEsp()
            scope:Loop("gunEsp", 0.4, updateGunEsp)
        else
            scope:StopTask("gunEsp")
            clearTable(gunHighlights)
        end
    end)
    tab:CreateButton("Teleport to dropped gun", function()
        local root = Common.Root()
        local gun = gunCache:Nearest(root.Position, function(instance) return instance.Position end)
        if gun then root.CFrame = gun.CFrame + Vector3.new(0, 3, 0) end
    end)

    farmTab:CreateSection("Coins")
    farmTab:CreateToggle("Auto farm coins", false, function(enabled)
        if enabled then
            scope:Loop("coins", 0.08, function()
                local root = Common.Root()
                local nearest = coinCache:Nearest(root.Position, function(instance) return instance.Position end)
                if nearest then
                    root.CFrame = nearest.CFrame
                    Common.Touch(root, nearest)
                end
            end)
        else
            scope:StopTask("coins")
        end
    end)

    scope:Connect(RunService.RenderStepped, function()
        if circle then
            circle.Position = UserInputService:GetMouseLocation()
            circle.Visible = silentAim
        end
    end)

    scope:AddRestore(function()
        clearTable(roleHighlights)
        clearTable(gunHighlights)
    end)
end
