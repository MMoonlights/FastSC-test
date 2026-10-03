return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local tab = ctx.Window:CreateTab("Combat", "R")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local localPlayer = Players.LocalPlayer
    local settings = {
        Enabled = false,
        ESP = true,
        TeamCheck = true,
        WallCheck = true,
        AutoFire = true,
        FOV = 323,
        HitPart = "Head",
    }
    local circle = Common.DrawingCircle(scope, settings.FOV, Color3.fromRGB(255, 255, 255))
    local highlights = {}

    local function clearHighlights()
        for character, highlight in pairs(highlights) do
            pcall(function() highlight:Destroy() end)
            highlights[character] = nil
        end
    end

    local function visible(character, part)
        if not settings.WallCheck then return true end
        local camera = workspace.CurrentCamera
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {localPlayer.Character, camera}
        local direction = part.Position - camera.CFrame.Position
        local hit = workspace:Raycast(camera.CFrame.Position, direction, params)
        return not hit or hit.Instance:IsDescendantOf(character)
    end

    tab:CreateSection("Aim")
    tab:CreateToggle("Aimbot", false, function(value)
        settings.Enabled = value
        if circle then circle.Visible = value end
    end)
    tab:CreateToggle("Auto fire", true, function(value) settings.AutoFire = value end)
    tab:CreateToggle("Wall check", true, function(value) settings.WallCheck = value end)
    tab:CreateSlider("FOV", {Min = 60, Max = 500, Default = 323}, function(value)
        settings.FOV = value
        if circle then circle.Radius = value end
    end)
    tab:CreateDropdown("Hit part", {"Head", "UpperTorso", "HumanoidRootPart"}, "Head", function(value)
        settings.HitPart = value
    end)

    tab:CreateSection("Visuals")
    tab:CreateToggle("Enemy ESP", true, function(value)
        settings.ESP = value
        if not value then clearHighlights() end
    end)

    scope:Connect(RunService.RenderStepped, function()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        if circle then
            circle.Position = center
            circle.Radius = settings.FOV
            circle.Visible = settings.Enabled
        end
        local target
        local best = settings.FOV
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and Common.Alive(player) then
                local character = player.Character
                local teammate = character.HumanoidRootPart:FindFirstChild("TeammateLabel") ~= nil
                if not settings.TeamCheck or not teammate then
                    local part = character:FindFirstChild(settings.HitPart)
                    if part then
                        local point, onScreen = camera:WorldToViewportPoint(part.Position)
                        local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
                        if onScreen and distance < best and visible(character, part) then
                            target = player
                            best = distance
                        end
                    end
                    if settings.ESP then
                        local highlight = highlights[character]
                        if not highlight or not highlight.Parent then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "FastSC_Rivals"
                            highlight.Adornee = character
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.55
                            highlight.OutlineColor = Color3.fromRGB(210, 210, 210)
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.Parent = character
                            highlights[character] = highlight
                        end
                    end
                end
            end
        end
        if settings.Enabled and target then
            local part = target.Character:FindFirstChild(settings.HitPart)
            if part then
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, part.Position)
                if settings.AutoFire then
                    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
                end
            end
        end
    end)

    scope:AddRestore(clearHighlights)
end
