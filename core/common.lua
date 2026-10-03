local Common = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

Common.Players = Players
Common.LocalPlayer = Players.LocalPlayer
Common.UserInputService = UserInputService
Common.Workspace = Workspace

function Common.Character(player)
    player = player or Players.LocalPlayer
    return player.Character or player.CharacterAdded:Wait()
end

function Common.Humanoid(player)
    local character = Common.Character(player)
    return character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
end

function Common.Root(player)
    local character = Common.Character(player)
    return character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
end

function Common.Alive(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and root ~= nil and humanoid.Health > 0
end

function Common.Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title or "FastSC"),
            Text = tostring(text or ""),
            Duration = duration or 4,
        })
    end)
end

function Common.NearestToCursor(options)
    options = options or {}
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    local mouse = UserInputService:GetMouseLocation()
    local best
    local bestDistance = options.FOV or math.huge
    local localPlayer = Players.LocalPlayer
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and Common.Alive(player) then
            if not options.TeamCheck or player.Team ~= localPlayer.Team then
                local part = player.Character:FindFirstChild(options.Part or "HumanoidRootPart")
                if part then
                    local point, visible = camera:WorldToViewportPoint(part.Position)
                    if visible then
                        local distance = (Vector2.new(point.X, point.Y) - mouse).Magnitude
                        if distance < bestDistance then
                            if not options.MaxDistance or (part.Position - Common.Root().Position).Magnitude <= options.MaxDistance then
                                best = player
                                bestDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestDistance
end

function Common.NearestCharacter(origin, maxDistance, predicate)
    local best
    local bestDistance = maxDistance or math.huge
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Model") and descendant.PrimaryPart and descendant ~= Players.LocalPlayer.Character then
            local humanoid = descendant:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and not Players:GetPlayerFromCharacter(descendant) then
                local distance = (descendant.PrimaryPart.Position - origin).Magnitude
                if distance < bestDistance and (not predicate or predicate(descendant)) then
                    best = descendant
                    bestDistance = distance
                end
            end
        end
    end
    return best, bestDistance
end

function Common.Highlight(scope, adornee, name, color)
    if not adornee then return nil end
    local existing = adornee:FindFirstChild(name)
    if existing and existing:IsA("Highlight") then return existing end
    local highlight = Instance.new("Highlight")
    highlight.Name = name
    highlight.Adornee = adornee
    highlight.FillColor = color or Color3.fromRGB(230, 60, 80)
    highlight.FillTransparency = 0.55
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = adornee
    if scope then scope:TrackInstance(highlight) end
    return highlight
end

function Common.DrawingCircle(scope, radius, color)
    if not Drawing then return nil end
    local circle = Drawing.new("Circle")
    circle.Visible = false
    circle.Filled = false
    circle.Thickness = 2
    circle.Transparency = 1
    circle.NumSides = 64
    circle.Radius = radius or 100
    circle.Color = color or Color3.fromRGB(230, 60, 80)
    if scope then scope:TrackDrawing(circle) end
    return circle
end

function Common.FireClick(detector)
    if detector and fireclickdetector then
        pcall(fireclickdetector, detector)
    end
end

function Common.FirePrompt(prompt)
    if prompt and fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    end
end

function Common.Touch(part, target)
    if firetouchinterest and part and target then
        pcall(function()
            firetouchinterest(part, target, 0)
            firetouchinterest(part, target, 1)
        end)
    end
end

return Common
