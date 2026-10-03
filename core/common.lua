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
    local localRoot = options.MaxDistance and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and Common.Alive(player) and (not options.TeamCheck or player.Team ~= localPlayer.Team) then
            local part = player.Character:FindFirstChild(options.Part or "HumanoidRootPart")
            if part then
                local point, visible = camera:WorldToViewportPoint(part.Position)
                if visible then
                    local distance = (Vector2.new(point.X, point.Y) - mouse).Magnitude
                    local inWorldRange = not options.MaxDistance or localRoot and (part.Position - localRoot.Position).Magnitude <= options.MaxDistance
                    if distance < bestDistance and inWorldRange then
                        best = player
                        bestDistance = distance
                    end
                end
            end
        end
    end
    return best, bestDistance
end

function Common.CreateDescendantCache(scope, root, predicate)
    local cache = {Items = {}, Count = 0}

    local function add(instance)
        if cache.Items[instance] or not predicate(instance) then return end
        cache.Items[instance] = true
        cache.Count += 1
    end

    local function remove(instance)
        if not cache.Items[instance] then return end
        cache.Items[instance] = nil
        cache.Count -= 1
    end

    for _, instance in ipairs(root:GetDescendants()) do
        add(instance)
    end

    if scope then
        scope:Connect(root.DescendantAdded, add)
        scope:Connect(root.DescendantRemoving, remove)
    end

    function cache:Add(instance)
        add(instance)
    end

    function cache:Remove(instance)
        remove(instance)
    end

    function cache:Each(callback)
        for instance in pairs(self.Items) do
            if instance.Parent then
                callback(instance)
            else
                remove(instance)
            end
        end
    end

    function cache:Nearest(origin, positionGetter, filter)
        local best
        local bestDistance = math.huge
        self:Each(function(instance)
            if not filter or filter(instance) then
                local position = positionGetter(instance)
                if position then
                    local distance = (position - origin).Magnitude
                    if distance < bestDistance then
                        best = instance
                        bestDistance = distance
                    end
                end
            end
        end)
        return best, bestDistance
    end

    return cache
end

function Common.NearestCharacter(origin, maxDistance, predicate, cache)
    local best
    local bestDistance = maxDistance or math.huge
    local function consider(model)
        if model == Players.LocalPlayer.Character or Players:GetPlayerFromCharacter(model) then return end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
        if not humanoid or humanoid.Health <= 0 or not root then return end
        local distance = (root.Position - origin).Magnitude
        if distance < bestDistance and (not predicate or predicate(model)) then
            best = model
            bestDistance = distance
        end
    end
    if cache then
        cache:Each(consider)
    else
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") then consider(descendant) end
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
