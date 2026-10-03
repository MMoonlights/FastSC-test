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
    local esp = {}

    local function role(player)
        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")
        if character and character:FindFirstChild("Knife") or backpack and backpack:FindFirstChild("Knife") then return "Murderer" end
        if character and character:FindFirstChild("Gun") or backpack and backpack:FindFirstChild("Gun") then return "Sheriff" end
        return "Innocent"
    end

    local colors = {
        Murderer = Color3.fromRGB(255, 70, 80),
        Sheriff = Color3.fromRGB(80, 150, 255),
        Innocent = Color3.fromRGB(70, 220, 130),
    }

    local function clearEsp()
        for instance, highlight in pairs(esp) do
            pcall(function() highlight:Destroy() end)
            esp[instance] = nil
        end
    end

    tab:CreateSection("Combat")
    tab:CreateToggle("Silent aim", false, function(enabled)
        silentAim = enabled
        if circle then circle.Visible = enabled end
    end)
    tab:CreateToggle("Auto kill all", false, function(enabled)
        if enabled then
            scope:Loop("killAll", 0.05, function()
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
            scope:Loop("killSheriff", 0.08, function()
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
        if not enabled then clearEsp() end
    end)
    tab:CreateToggle("Dropped gun ESP", false, function(enabled)
        gunEsp = enabled
    end)
    tab:CreateButton("Teleport to dropped gun", function()
        local root = Common.Root()
        for _, model in ipairs(workspace:GetChildren()) do
            local gun = model:IsA("Model") and model:FindFirstChild("GunDrop")
            if gun then
                root.CFrame = gun.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end)

    farmTab:CreateSection("Coins")
    farmTab:CreateToggle("Auto farm coins", false, function(enabled)
        if enabled then
            scope:Loop("coins", 0.08, function()
                local root = Common.Root()
                local nearest
                local best = math.huge
                for _, item in ipairs(workspace:GetDescendants()) do
                    if item:IsA("BasePart") and (item.Name == "Coin_Server" or item.Name == "Coin") then
                        local distance = (item.Position - root.Position).Magnitude
                        if distance < best then
                            nearest = item
                            best = distance
                        end
                    end
                end
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
        local mouse = UserInputService:GetMouseLocation()
        if circle then
            circle.Position = mouse
            circle.Visible = silentAim
        end
        if silentAim then
            local localRole = role(localPlayer)
            local targetRole = localRole == "Sheriff" and "Murderer" or localRole == "Murderer" and "Sheriff" or nil
            if targetRole then
                local best
                local distance = circle and circle.Radius or 100
                local camera = workspace.CurrentCamera
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and Common.Alive(player) and role(player) == targetRole then
                        local root = player.Character.HumanoidRootPart
                        local point, visible = camera:WorldToViewportPoint(root.Position)
                        if visible then
                            local current = (Vector2.new(point.X, point.Y) - mouse).Magnitude
                            if current < distance then
                                best = player
                                distance = current
                            end
                        end
                    end
                end
                if best then
                    local character = localPlayer.Character
                    local gun = character and character:FindFirstChild("Gun")
                    local knife = character and character:FindFirstChild("Knife")
                    local targetRoot = best.Character.HumanoidRootPart
                    if gun and gun:FindFirstChild("Gun") and gun.Gun:FindFirstChild("KnifeLocal") then
                        local remote = gun.Gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
                        if remote then pcall(function() remote:InvokeServer(1, targetRoot.Position, "AH2") end) end
                    elseif knife and knife:FindFirstChild("Throw") then
                        pcall(function() knife.Throw:FireServer(targetRoot.CFrame, targetRoot.Position) end)
                    end
                end
            end
        end
        if roleEsp then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    local character = player.Character
                    local currentRole = role(player)
                    local highlight = esp[character]
                    if not highlight or not highlight.Parent then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "FastSC_MM2"
                        highlight.Adornee = character
                        highlight.FillTransparency = 0.55
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = character
                        esp[character] = highlight
                    end
                    highlight.FillColor = colors[currentRole]
                    highlight.OutlineColor = colors[currentRole]
                end
            end
        end
        if gunEsp then
            for _, model in ipairs(workspace:GetChildren()) do
                local gun = model:IsA("Model") and model:FindFirstChild("GunDrop")
                if gun and not gun:FindFirstChild("FastSC_Gun") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "FastSC_Gun"
                    highlight.Adornee = gun
                    highlight.FillColor = Color3.fromRGB(80, 255, 120)
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = gun
                end
            end
        end
    end)

    scope:AddRestore(clearEsp)
end
