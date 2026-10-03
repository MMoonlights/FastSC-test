return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local mode = ctx.Mode or "Legit"
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local PathfindingService = game:GetService("PathfindingService")
    local Lighting = game:GetService("Lighting")
    local localPlayer = Players.LocalPlayer
    local items = {}
    local interactives = {}
    local traps = {}
    local doors = {}
    local bots = {}
    local visuals = {}
    local requirements = {}
    local escapeTargets = {}
    local selectedItem
    local infiniteJump = false
    local itemEsp = false
    local playerEsp = false
    local piggyEsp = false
    local trapEsp = false
    local speedEnabled = false
    local speedValue = mode == "Rage" and 60 or 24
    local jumpEnabled = false
    local jumpValue = mode == "Rage" and 90 or 60
    local noclip = false
    local fullbright = false
    local godMode = false
    local trapBypass = false
    local doorsRemoved = false
    local botsFrozen = false
    local autoGrab = false
    local autoComplete = false
    local autoInteract = false
    local completeCursor = 0
    local removeVisual
    local refreshVisuals
    local objectiveCurrentLabel
    local objectiveNeededLabel
    local objectiveStatusLabel
    local currentObjective
    local findOwnedById
    local lastPickupStatus = "idle"
    local objectiveEsp = false
    local objectiveVisualTarget
    local autoCompleteBusy = false
    local pickupBusy = false
    local objectiveCooldowns = setmetatable({}, {__mode = "k"})
    local disabledEnemyTouches = setmetatable({}, {__mode = "k"})
    local reachabilityCache = setmetatable({}, {__mode = "k"})
    local freeInteractionCooldowns = setmetatable({}, {__mode = "k"})
    local objectiveMapLabel

    local bookName = "Piggy universe"
    if game.PlaceId == 4623386862 then
        bookName = "Book 1"
    elseif game.PlaceId == 5661005779 then
        bookName = "Book 2"
    end

    local mapNames = {
        "House",
        "Station",
        "Gallery",
        "Forest",
        "School",
        "Hospital",
        "Metro",
        "Carnival",
        "City",
        "Mall",
        "Outpost",
        "Plant",
        "Alleys",
        "Store",
        "Refinery",
        "SafePlace",
        "The Safe Place",
        "Sewers",
        "Factory",
        "Port",
        "Ship",
        "Docks",
        "Temple",
        "Camp",
        "Lab",
        "DistortedMemory",
        "Distorted Memory",
        "WinterHoliday",
        "Winter Holiday",
        "Heist",
        "Distraction",
        "Breakout",
        "Mansion",
    }

    local function currentMapName()
        for _, name in ipairs(mapNames) do
            if workspace:FindFirstChild(name) then return name end
        end
        for _, child in ipairs(workspace:GetChildren()) do
            local lower = string.lower(child.Name)
            for _, name in ipairs(mapNames) do
                if lower == string.lower(name) then return name end
            end
        end
        return "Unknown"
    end

    local function getPart(object)
        if not object or not object.Parent then return nil end
        if object:IsA("BasePart") then return object end
        if object:IsA("Tool") then
            return object:FindFirstChild("Handle") or object:FindFirstChildWhichIsA("BasePart", true)
        end
        if object:IsA("Model") then
            return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object:FindFirstChildWhichIsA("BasePart", true)
        end
        local parent = object.Parent
        if parent and parent:IsA("Tool") then
            return parent:FindFirstChild("Handle") or parent:FindFirstChildWhichIsA("BasePart", true)
        end
        if parent and parent:IsA("BasePart") then return parent end
        if parent and parent:IsA("Model") and not Players:GetPlayerFromCharacter(parent) then
            return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
        end
    end

    local function playerCharacterAncestor(instance)
        local current = instance
        while current and current ~= workspace do
            if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
                return current
            end
            current = current.Parent
        end
    end

    local function isWorldItem(item)
        if not item or not item.Parent then return false end
        if playerCharacterAncestor(item) then return false end
        local backpack = localPlayer:FindFirstChild("Backpack")
        if backpack and item:IsDescendantOf(backpack) then return false end
        return item:IsDescendantOf(workspace)
    end

    local automationActive = false
    local automationTarget

    local function setAutomationCollision(enabled)
        local character = localPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if enabled then
                    scope:Set(part, "CanCollide", false)
                elseif not noclip then
                    scope:Restore(part, "CanCollide")
                end
            end
        end
    end

    local function beginAutomationMove(target)
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root then return false end
        automationActive = true
        automationTarget = target
        setAutomationCollision(true)
        if humanoid then scope:Set(humanoid, "AutoRotate", false) end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = target
        return true
    end

    local function endAutomationMove()
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        automationTarget = nil
        automationActive = false
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if humanoid then scope:Restore(humanoid, "AutoRotate") end
        if not noclip then setAutomationCollision(false) end
    end

    scope:Connect(RunService.PreSimulation, function()
        if not automationActive then return end
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if automationTarget then root.CFrame = automationTarget end
        setAutomationCollision(true)
    end)

    local function hasAncestorName(instance, word)
        word = string.lower(word)
        local current = instance
        while current and current ~= workspace do
            if string.find(string.lower(current.Name), word, 1, true) then return true end
            current = current.Parent
        end
        return false
    end

    local function itemObjectFrom(instance)
        if instance.Name == "ItemPickupScript" and instance.Parent then
            return instance.Parent
        end
        local current = instance
        while current and current ~= workspace do
            if current:FindFirstChild("ItemPickupScript") then return current end
            current = current.Parent
        end
    end

    local itemNameCache = setmetatable({}, {__mode = "k"})

    local displayNames = {
        BlueKey = "Blue Key",
        OrangeKey = "Orange Key",
        GreenKey = "Green Key",
        RedKey = "Red Key",
        YellowKey = "Yellow Key",
        WhiteKey = "White Key",
        PurpleKey = "Purple Key",
        BlueKeycard = "Blue Keycard",
        RedKeycard = "Red Keycard",
        OrangeKeycard = "Orange Keycard",
        GreenKeycard = "Green Keycard",
        RedGear = "Red Gear",
        GreenGear = "Green Gear",
        WhiteGear = "White Gear",
        KeyCode = "Key Code",
        WaterGun = "Water Gun",
        FireExtinguisher = "Fire Extinguisher",
        SmokeBomb = "Smoke Bomb",
        SmokeGrenade = "Smoke Grenade",
        GrapplingHook = "Grappling Hook",
        WoodenSword = "Wooden Sword",
        FencingFoil = "Fencing Foil",
        EmptyVial = "Empty Vial",
        GreenVial = "Green Vial",
        PinkVial = "Pink Vial",
        GreenWire = "Green Wire",
        RedWire = "Red Wire",
        BlueWire = "Blue Wire",
        YellowWire = "Yellow Wire",
        Screwdriver = "Screwdriver",
        Scissors = "Scissors",
        Blowtorch = "Blowtorch",
        Flashlight = "Flashlight",
        Crowbar = "Crowbar",
        Dynamite = "Dynamite",
        Battery = "Battery",
        Batteries = "Batteries",
        Remote = "Remote",
        Ladder = "Ladder",
        Shovel = "Shovel",
        Candle = "Candle",
        Hammer = "Hammer",
        Wrench = "Wrench",
        Plank = "Plank",
        Ammo = "Ammo",
        Gun = "Gun",
        Carrot = "Carrot",
        Grass = "Grass",
        Bone = "Bone",
        Book = "Book",
        Rope = "Rope",
        Ticket = "Ticket",
        TNT = "TNT",
        Pipe = "Pipe",
        Bat = "Bat",
        Gas = "Gas",
        Axe = "Axe",
        Gear = "Gear",
        Keycard = "Keycard",
        Key = "Key",
        Mallet = "Mallet",
        Crossbow = "Crossbow",
    }

    local aliases = {}
    local function token(value)
        return string.lower(tostring(value or "")):gsub("[^%w]", "")
    end

    for id, display in pairs(displayNames) do
        aliases[token(id)] = id
        aliases[token(display)] = id
    end

    local function cleanAssetId(value)
        return tostring(value or ""):match("%d+") or ""
    end

    local function particleColor(item)
        local emitter = item:FindFirstChildWhichIsA("ParticleEmitter", true)
        return emitter and tostring(emitter.Color) or nil
    end

    local colorIds = {
        ["0 0 1 1 0 1 0 1 1 0 "] = "Blue",
        ["0 1 0.333333 0 0 1 1 0.333333 0 0 "] = "Orange",
        ["0 0 1 0 0 1 0 1 0 0 "] = "Green",
        ["0 1 0 0 0 1 1 0 0 0 "] = "Red",
        ["0 1 1 0 0 1 1 1 0 0 "] = "Yellow",
        ["0 1 1 1 0 1 1 1 1 0 "] = "White",
        ["0 0.666667 0.333333 1 0 1 0.666667 0.333333 1 0 "] = "Purple",
        ["0 0.333333 0.666667 0 0 1 0.333333 0.666667 0 0 "] = "Green",
    }

    local brickColors = {
        ["Lime green"] = "Green",
        ["Really red"] = "Red",
        ["Toothpaste"] = "Blue",
        ["Neon orange"] = "Orange",
        ["Gold"] = "Yellow",
        ["Alder"] = "Purple",
        ["Institutional white"] = "White",
        ["Shamrock"] = "Green",
        ["Persimmon"] = "Red",
    }

    local function explicitId(item)
        for _, key in ipairs({"DisplayName", "ItemName", "ToolName", "ItemType", "Type", "KeyType"}) do
            local value = item:GetAttribute(key)
            if type(value) == "string" and aliases[token(value)] then
                return aliases[token(value)]
            end
        end
        for _, descendant in ipairs(item:GetDescendants()) do
            if descendant:IsA("StringValue") then
                local name = string.lower(descendant.Name)
                if name == "displayname" or name == "itemname" or name == "toolname" or name == "itemtype" or name == "type" then
                    local id = aliases[token(descendant.Value)]
                    if id then return id end
                end
            end
        end
    end

    local function treeId(item)
        local values = {item.Name}
        for _, descendant in ipairs(item:GetDescendants()) do
            values[#values + 1] = descendant.Name
        end
        local joined = token(table.concat(values, " "))
        for alias, id in pairs(aliases) do
            if #alias >= 4 and joined:find(alias, 1, true) then return id end
        end
    end

    local function signatureId(item)
        if item:FindFirstChildWhichIsA("SurfaceGui", true) and item:FindFirstChild("ItemPickupScript", true) then
            return "KeyCode"
        end

        local mesh = item:FindFirstChildWhichIsA("SpecialMesh", true)
        local meshId = mesh and cleanAssetId(mesh.MeshId) or ""
        local textureId = mesh and cleanAssetId(mesh.TextureId) or ""
        local color = particleColor(item)
        local colorName = color and colorIds[color] or nil
        local part = getPart(item)
        local brick = part and part.BrickColor.Name or nil

        if meshId == "456878024" and colorName then return colorName .. "Key" end
        if meshId == "524706126" then
            if colorName == "Green" or brick == "Shamrock" then return "GreenGear" end
            if brick == "Persimmon" or colorName == "Red" or colorName == "White" then return "RedGear" end
            return "Gear"
        end
        if meshId == "16198309" or textureId == "16198294" then return "Hammer" end
        if meshId == "16884681" or textureId == "16884673" then return "Wrench" end
        if meshId == "72012879" then return "Gun" end
        if meshId == "741743576" then return "Carrot" end
        if meshId == "1771168429" or textureId == "1771169634" then return "WaterGun" end
        if meshId == "120607730" then return "Mallet" end
        if meshId == "15886761" then return "Crossbow" end
        if meshId == "27787143" and mesh then
            if mesh.Scale.Magnitude < 1 then return "TNT" end
            return "FireExtinguisher"
        end
        if meshId == "725833400" or textureId == "725833458" then return "Ammo" end

        if item:IsA("UnionOperation") or item:FindFirstChildWhichIsA("UnionOperation", true) then
            if colorName == "Blue" then return "BlueKeycard" end
            if colorName == "Orange" then return "OrangeKeycard" end
            if colorName == "Red" then return "RedKeycard" end
        end

        if brickColors[brick] then
            local colorId = brickColors[brick]
            if brick == "Shamrock" then return "GreenGear" end
            if brick == "Persimmon" and item:FindFirstChildWhichIsA("UnionOperation", true) then return "Gas" end
            return colorId .. "Key"
        end

        if brick == "Burnt Sienna" or brick == "BurntSienna" then return "Plank" end
    end

    local function itemId(item)
        if not item then return nil end
        local cached = itemNameCache[item]
        if cached then return cached.Id end
        local id = explicitId(item) or signatureId(item) or treeId(item) or aliases[token(item.Name)]
        if not id and tostring(item.Name):find("%a") then
            local normalized = token(item.Name)
            id = aliases[normalized]
            if not id then
                local text = tostring(item.Name):gsub("_", " "):gsub("(%l)(%u)", "%1 %2")
                text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                id = text
            end
        end
        if not id then
            local part = getPart(item)
            local color = part and brickColors[part.BrickColor.Name] or nil
            id = color and (color .. "Item") or "UnknownItem"
        end
        itemNameCache[item] = {Id = id, Name = displayNames[id] or id:gsub("(%l)(%u)", "%1 %2")}
        return id
    end

    local function itemDisplayName(item)
        local id = itemId(item)
        local cached = itemNameCache[item]
        if cached and cached.Name then return cached.Name end
        return displayNames[id] or tostring(id or "Unknown Item")
    end

    local function requirementExists(id)
        local targetToken = token(id)
        for value in pairs(requirements) do
            if value.Parent and token(value.Value) == targetToken then
                return true
            end
        end
        return false
    end

    local function computeReachable(part)
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not part or not part.Parent then return false end

        local cached = reachabilityCache[part]
        local now = os.clock()
        if cached and now - cached.Time < 1.25 then
            if (cached.Origin - root.Position).Magnitude < 10 and (cached.Target - part.Position).Magnitude < 3 then
                return cached.Value
            end
        end

        local offsets = {
            Vector3.zero,
            Vector3.new(0, -math.max(1, part.Size.Y * 0.5), 0),
            Vector3.new(3, 0, 0),
            Vector3.new(-3, 0, 0),
            Vector3.new(0, 0, 3),
            Vector3.new(0, 0, -3),
        }

        local reachable = false
        for _, offset in ipairs(offsets) do
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentCanClimb = true,
                WaypointSpacing = 4,
            })
            local ok = pcall(function()
                path:ComputeAsync(root.Position, part.Position + offset)
            end)
            if ok and path.Status == Enum.PathStatus.Success then
                reachable = true
                break
            end
        end

        if not reachable and (part.Position - root.Position).Magnitude <= 12 then
            local direction = part.Position - root.Position
            local parameters = RaycastParams.new()
            parameters.FilterType = Enum.RaycastFilterType.Exclude
            parameters.FilterDescendantsInstances = {character}
            local hit = workspace:Raycast(root.Position, direction, parameters)
            if not hit or hit.Instance == part or hit.Instance:IsDescendantOf(part.Parent) then
                reachable = true
            end
        end

        reachabilityCache[part] = {
            Time = now,
            Origin = root.Position,
            Target = part.Position,
            Value = reachable,
        }
        return reachable
    end

    local function isAvailableWorldItem(item)
        if not isWorldItem(item) then return false end
        local part = getPart(item)
        if not part then return false end

        local id = itemId(item)
        local map = currentMapName()

        if map == "House" and id == "WhiteKey" then
            if requirementExists("RedGear") or requirementExists("GreenGear") then
                return false
            end
        end

        return computeReachable(part)
    end

    local function book2ItemFrom(instance)
        if instance.Name == "ItemHandler" and instance.Parent then
            return instance.Parent
        end
        local hasInteraction = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
            or instance:FindFirstChildWhichIsA("ClickDetector", true)
        if instance:IsA("Tool") and hasInteraction then
            return instance
        end
        if instance:IsA("Model") and hasInteraction then
            if instance:FindFirstChild("Handle") or aliases[token(instance.Name)] then
                return instance
            end
        end
    end

    local function trueFlag(container, name)
        if not container then return false end
        local value = container:FindFirstChild(name)
        if value and value:IsA("BoolValue") then return value.Value == true end
        local attribute = container:GetAttribute(name)
        return attribute == true
    end

    local function isPiggyPlayer(player)
        local character = player and player.Character
        return trueFlag(character, "Enemy")
            or trueFlag(player, "Enemy")
            or trueFlag(character, "IsPiggy")
            or trueFlag(player, "IsPiggy")
            or trueFlag(character, "Piggy")
            or trueFlag(player, "Piggy")
    end

    local function underPiggyFolder(instance)
        local current = instance
        while current and current ~= workspace do
            if current.Name == "PiggyNPC" then return true end
            current = current.Parent
        end
        return false
    end

    local function isBotModel(model)
        if not model or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then return false end
        if underPiggyFolder(model) then return true end
        local lower = string.lower(model.Name)
        if lower == "piggynpc" or string.find(lower, "piggy", 1, true) or string.find(lower, "bot", 1, true) then
            return model:FindFirstChildOfClass("Humanoid") ~= nil
                or model:FindFirstChild("HumanoidRootPart") ~= nil
                or model:FindFirstChild("Head") ~= nil
        end
        return false
    end

    local function registerPiggyFolder(folder)
        if not folder or folder.Name ~= "PiggyNPC" then return end
        for _, child in ipairs(folder:GetDescendants()) do
            if child:IsA("Model") and (child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head")) then
                bots[child] = true
            end
        end
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then bots[child] = true end
        end
        scope:Connect(folder.DescendantAdded, function(child)
            if child:IsA("Model") and (child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head")) then
                bots[child] = true
            elseif child.Parent == folder and child:IsA("BasePart") then
                bots[child] = true
            end
        end)
        scope:Connect(folder.ChildRemoved, function(child)
            bots[child] = nil
            removeVisual(child)
        end)
    end

    local function register(instance)
        local item = itemObjectFrom(instance) or book2ItemFrom(instance)
        if item then
            itemNameCache[item] = nil
            if isWorldItem(item) then
                items[item] = true
            else
                if not isWorldItem(item) then items[item] = nil end
                if removeVisual then removeVisual(item) end
            end
        end
        if instance:IsA("ClickDetector") or instance:IsA("ProximityPrompt") then
            interactives[instance] = true
        end
        if instance:IsA("StringValue") then
            requirements[instance] = true
        end
        if instance:IsA("BasePart") then
            local lower = string.lower(instance.Name)
            if string.find(lower, "escape", 1, true) or string.find(lower, "exit", 1, true) or string.find(lower, "final", 1, true) then
                escapeTargets[instance] = true
            elseif instance.DataCost == 25 and instance:FindFirstChildWhichIsA("Script") then
                escapeTargets[instance] = true
            end
            if hasAncestorName(instance, "trap") then traps[instance] = true end
            if hasAncestorName(instance, "door") or hasAncestorName(instance, "gate") then doors[instance] = true end
        elseif instance:IsA("Model") and isBotModel(instance) then
            bots[instance] = true
        elseif instance:IsA("Humanoid") and instance.Parent and isBotModel(instance.Parent) then
            bots[instance.Parent] = true
        end
    end

    local function unregister(instance)
        items[instance] = nil
        interactives[instance] = nil
        traps[instance] = nil
        doors[instance] = nil
        bots[instance] = nil
        requirements[instance] = nil
        escapeTargets[instance] = nil
        itemNameCache[instance] = nil
        local visual = visuals[instance]
        if visual then
            if visual.Highlight then pcall(function() visual.Highlight:Destroy() end) end
            if visual.Gui then pcall(function() visual.Gui:Destroy() end) end
            visuals[instance] = nil
        end
    end

    for _, instance in ipairs(workspace:GetDescendants()) do register(instance) end
    registerPiggyFolder(workspace:FindFirstChild("PiggyNPC"))
    scope:Connect(workspace.ChildAdded, registerPiggyFolder)
    scope:Connect(workspace.DescendantAdded, register)
    scope:Connect(workspace.DescendantRemoving, unregister)

    local function attachPlayer(player)
        if player == localPlayer then return end
        local function watchCharacter(character)
            local function watchEnemy(enemy)
                if enemy.Name == "Enemy" and enemy:IsA("BoolValue") then
                    scope:Connect(enemy:GetPropertyChangedSignal("Value"), function()
                        if piggyEsp or playerEsp then refreshVisuals() end
                    end)
                end
            end
            local enemy = character:FindFirstChild("Enemy")
            if enemy then watchEnemy(enemy) end
            scope:Connect(character.ChildAdded, watchEnemy)
        end
        if player.Character then watchCharacter(player.Character) end
        scope:Connect(player.CharacterAdded, watchCharacter)
    end

    for _, player in ipairs(Players:GetPlayers()) do attachPlayer(player) end
    scope:Connect(Players.PlayerAdded, attachPlayer)

    removeVisual = function(object)
        local data = visuals[object]
        if not data then return end
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.Gui then pcall(function() data.Gui:Destroy() end) end
        visuals[object] = nil
    end

    local function tag(object, kind, color, title)
        if not object or not object.Parent then return end
        local current = visuals[object]
        if current and current.Kind == kind then
            current.Title = title
            return
        end
        if current then removeVisual(object) end
        local adornee = getPart(object)
        if not adornee then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "FastSC_" .. kind
        highlight.Adornee = object:IsA("Model") and object or adornee
        highlight.FillColor = color
        highlight.FillTransparency = 0.65
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = object:IsA("Model") and object or adornee
        local gui = Instance.new("BillboardGui")
        gui.Name = "FastSC_Label"
        gui.Adornee = adornee
        gui.Size = UDim2.new(0, 180, 0, 32)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = adornee
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

    local function clearKind(kind)
        for object, data in pairs(visuals) do
            if not kind or data.Kind == kind then removeVisual(object) end
        end
    end

    refreshVisuals = function()
        if itemEsp then
            for item in pairs(items) do
                if isAvailableWorldItem(item) then
                    tag(item, "Item", Color3.fromRGB(255, 210, 70), itemDisplayName(item))
                else
                    removeVisual(item)
                    if not isWorldItem(item) then items[item] = nil end
                end
            end
        end
        if piggyEsp then
            local piggyFolder = workspace:FindFirstChild("PiggyNPC")
            if piggyFolder then
                for _, bot in ipairs(piggyFolder:GetChildren()) do
                    if bot:IsA("Model") or bot:IsA("BasePart") then
                        bots[bot] = true
                        tag(bot, "Piggy", Color3.fromRGB(255, 70, 80), "Piggy: " .. bot.Name)
                    end
                end
                for _, bot in ipairs(piggyFolder:GetDescendants()) do
                    if bot:IsA("Model") and (bot:FindFirstChildOfClass("Humanoid") or bot:FindFirstChild("HumanoidRootPart") or bot:FindFirstChild("Head")) then
                        bots[bot] = true
                        tag(bot, "Piggy", Color3.fromRGB(255, 70, 80), "Piggy: " .. bot.Name)
                    end
                end
            end
            for bot in pairs(bots) do
                if bot.Parent then tag(bot, "Piggy", Color3.fromRGB(255, 70, 80), "Piggy: " .. bot.Name) end
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character and isPiggyPlayer(player) then
                    tag(player.Character, "Piggy", Color3.fromRGB(255, 70, 80), "Piggy: " .. player.DisplayName)
                end
            end
        end
        if trapEsp then
            for trap in pairs(traps) do
                if trap.Parent then tag(trap, "Trap", Color3.fromRGB(255, 125, 55), trap.Name) end
            end
        end
        if playerEsp then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    if piggyEsp and isPiggyPlayer(player) then
                        tag(player.Character, "Piggy", Color3.fromRGB(255, 70, 80), "Piggy: " .. player.DisplayName)
                    else
                        tag(player.Character, "Player", Color3.fromRGB(80, 170, 255), "Survivor: " .. player.DisplayName)
                    end
                end
            end
        end
        if objectiveEsp then
            local target = currentObjective and currentObjective.Target or nil
            if target ~= objectiveVisualTarget then
                clearKind("Objective")
                objectiveVisualTarget = target
            end
            if target and target.Parent then
                tag(target, "Objective", Color3.fromRGB(170, 100, 255), currentObjective.ItemName .. " -> " .. currentObjective.TargetName)
            end
        elseif objectiveVisualTarget then
            clearKind("Objective")
            objectiveVisualTarget = nil
        end
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        for object, data in pairs(visuals) do
            local part = getPart(object)
            if not object.Parent or not part then
                removeVisual(object)
            elseif root and data.Label then
                data.Label.Text = data.Title .. "  [" .. tostring(math.floor((part.Position - root.Position).Magnitude)) .. "]"
            end
        end
    end

    scope:Loop("visuals", 0.25, refreshVisuals)

    local function detectorFor(item)
        if not item then return nil end
        return item:FindFirstChildWhichIsA("ClickDetector", true), item:FindFirstChildWhichIsA("ProximityPrompt", true)
    end

    local function itemList()
        local list = {}
        for item in pairs(items) do
            if isAvailableWorldItem(item) and getPart(item) then
                list[#list + 1] = item
            else
                if not isWorldItem(item) then items[item] = nil end
                if removeVisual then removeVisual(item) end
            end
        end
        table.sort(list, function(a, b) return itemDisplayName(a) < itemDisplayName(b) end)
        return list
    end

    local function itemNames()
        local names = {}
        local seen = {}
        for _, item in ipairs(itemList()) do
            local name = itemDisplayName(item)
            if not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
        return names
    end

    local function findItemByName(name)
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local best
        local bestDistance = math.huge
        for item in pairs(items) do
            if isAvailableWorldItem(item) and itemDisplayName(item) == name then
                local part = getPart(item)
                if part then
                    local distance = root and (part.Position - root.Position).Magnitude or 0
                    if distance < bestDistance then
                        best = item
                        bestDistance = distance
                    end
                end
            end
        end
        return best
    end

    local function nearestItem()
        local root = Common.Root()
        local best
        local bestDistance = math.huge
        for item in pairs(items) do
            local part = isAvailableWorldItem(item) and getPart(item) or nil
            if part then
                local distance = (part.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best = item
                    bestDistance = distance
                end
            else
                if not isWorldItem(item) then items[item] = nil end
            end
        end
        return best
    end

    local function grabItem(item, returnAfter, expectedId)
        if pickupBusy then
            lastPickupStatus = "another pickup is still running"
            return false
        end
        if not item or not item.Parent then
            lastPickupStatus = "item unavailable"
            return false
        end

        expectedId = expectedId or itemId(item)
        if not isAvailableWorldItem(item) then
            lastPickupStatus = "item exists but is still locked or unreachable"
            return false
        end
        if expectedId and findOwnedById and findOwnedById(expectedId) then
            lastPickupStatus = "already owned"
            return true, findOwnedById(expectedId)
        end

        local part = getPart(item)
        if not part then
            lastPickupStatus = "item has no usable part"
            return false
        end

        local click, prompt = detectorFor(item)
        local useClick = click and click.Parent and fireclickdetector
        local usePrompt = not useClick and prompt and prompt.Parent and fireproximityprompt
        if not useClick and not usePrompt then
            lastPickupStatus = "item has no supported pickup interaction"
            return false
        end

        pickupBusy = true
        local root = Common.Root()
        local old = root.CFrame

        local function confirm(timeout)
            local deadline = os.clock() + timeout
            repeat
                if expectedId and findOwnedById then
                    local ownedTool = findOwnedById(expectedId)
                    if ownedTool then return ownedTool end
                end
                task.wait(0.05)
            until os.clock() >= deadline
        end

        local owned
        local success = pcall(function()
            for attempt = 1, 2 do
                part = getPart(item)
                if not part then break end
                local target = part.CFrame + Vector3.new(0, 2.5, 0)
                beginAutomationMove(target)
                task.wait(0.025)

                if useClick and click and click.Parent then
                    pcall(fireclickdetector, click)
                elseif usePrompt and prompt and prompt.Parent then
                    pcall(fireproximityprompt, prompt)
                end

                owned = confirm(attempt == 1 and 0.55 or 0.8)
                if owned then break end
                if not item.Parent then break end
            end

            if not owned then
                owned = confirm(0.7)
            end
        end)

        endAutomationMove()
        if returnAfter or not owned then
            if root and root.Parent then
                root.CFrame = old
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end

        pickupBusy = false

        if not success then
            lastPickupStatus = "pickup handler failed"
            return false
        end

        if owned then
            lastPickupStatus = "confirmed: " .. (displayNames[expectedId] or tostring(expectedId))
            return true, owned
        end

        if item.Parent then
            lastPickupStatus = "server did not confirm pickup"
        else
            lastPickupStatus = "item despawned, but no Tool appeared in inventory"
        end
        return false
    end

    local function teleportItem(item)
        local part = getPart(item)
        if part then Common.Root().CFrame = part.CFrame + Vector3.new(0, 3, 0) end
    end

    local function triggerInteractive(interactive, returnAfter)
        if not interactive or not interactive.Parent then return false end
        local item = itemObjectFrom(interactive)
        if item then return false end
        local part = getPart(interactive)
        if not part then return false end
        local root = Common.Root()
        local old = root.CFrame
        root.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
        task.wait(0.03)
        if interactive:IsA("ClickDetector") and fireclickdetector then
            pcall(fireclickdetector, interactive)
        elseif interactive:IsA("ProximityPrompt") and fireproximityprompt then
            pcall(fireproximityprompt, interactive)
        end
        local lower = string.lower(part.Name)
        if (string.find(lower, "exit", 1, true) or string.find(lower, "escape", 1, true)) and firetouchinterest then
            Common.Touch(root, part)
        end
        task.wait(0.04)
        if returnAfter and root.Parent then root.CFrame = old end
        return true
    end

    local function interactiveList()
        local list = {}
        for interactive in pairs(interactives) do
            if interactive.Parent and not itemObjectFrom(interactive) then
                list[#list + 1] = interactive
            else
                interactives[interactive] = nil
            end
        end
        return list
    end

    local targetNames = {
        BlueKey = "Blue Door",
        GreenKey = "Green Door",
        RedKey = "Red Door",
        OrangeKey = "Orange Door",
        YellowKey = "Yellow Door",
        PurpleKey = "Purple Door",
        WhiteKey = "Front Door",
        Wrench = "Power Panel",
        Hammer = "Front Door",
        KeyCode = "Number Lock",
        BlueKeycard = "Blue Keycard Reader",
        RedKeycard = "Red Keycard Reader",
        OrangeKeycard = "Orange Keycard Reader",
        GreenKeycard = "Green Keycard Reader",
    }

    local function idFromText(value)
        local exact = aliases[token(value)]
        if exact then return exact end
        local compact = token(value)
        for alias, id in pairs(aliases) do
            if #alias >= 4 and compact:find(alias, 1, true) then return id end
        end
    end

    local function belongsToItem(instance)
        local current = instance
        while current and current ~= workspace do
            if items[current] then return true end
            current = current.Parent
        end
        return false
    end

    local freeInteractionWords = {
        "button",
        "lever",
        "switch",
        "generator",
        "valve",
        "fuse",
        "breaker",
        "keypad",
        "code",
        "terminal",
        "console",
        "panel",
        "crank",
        "elevator",
        "bridge",
        "power",
        "machine",
        "control",
        "handle",
    }

    local function interactionHost(interactive)
        local current = interactive and interactive.Parent
        local fallback = current
        for _ = 1, 3 do
            if not current or current == workspace then break end
            if current:IsA("Model") then return current end
            fallback = current
            current = current.Parent
        end
        return fallback
    end

    local function hostRequiresItem(host)
        if not host then return false end
        for _, descendant in ipairs(host:GetDescendants()) do
            if descendant:IsA("StringValue") and idFromText(descendant.Value) then
                return true
            end
        end
        return false
    end

    local function freeInteractionName(interactive)
        local host = interactionHost(interactive)
        local chunks = {}
        local current = host
        for _ = 1, 3 do
            if not current or current == workspace then break end
            chunks[#chunks + 1] = string.lower(current.Name)
            current = current.Parent
        end
        return table.concat(chunks, " ")
    end

    local function isFreeProgressInteraction(interactive)
        if not interactive or not interactive.Parent then return false end
        if itemObjectFrom(interactive) or belongsToItem(interactive) then return false end
        local host = interactionHost(interactive)
        if not host or hostRequiresItem(host) then return false end
        if playerCharacterAncestor(host) or underPiggyFolder(host) then return false end

        local name = freeInteractionName(interactive)
        if name:find("exit", 1, true) or name:find("escape", 1, true) or name:find("final", 1, true) then
            return false
        end

        local matched = false
        for _, word in ipairs(freeInteractionWords) do
            if name:find(word, 1, true) then
                matched = true
                break
            end
        end
        if not matched then return false end

        local part = getPart(host) or getPart(interactive)
        if not part or not computeReachable(part) then return false end
        local cooldown = freeInteractionCooldowns[interactive]
        return not cooldown or cooldown <= os.clock()
    end

    local function runFreeInteractionStep()
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local best
        local bestPart
        local bestDistance = math.huge

        for interactive in pairs(interactives) do
            if isFreeProgressInteraction(interactive) then
                local host = interactionHost(interactive)
                local part = getPart(host) or getPart(interactive)
                if part then
                    local distance = (part.Position - root.Position).Magnitude
                    if distance < bestDistance then
                        best = interactive
                        bestPart = part
                        bestDistance = distance
                    end
                end
            end
        end

        if not best or not bestPart then return false end

        beginAutomationMove(bestPart.CFrame + bestPart.CFrame.LookVector * -2 + Vector3.new(0, 1.5, 0))
        task.wait(0.025)
        if best:IsA("ClickDetector") and fireclickdetector then
            pcall(fireclickdetector, best)
        elseif best:IsA("ProximityPrompt") and fireproximityprompt then
            pcall(fireproximityprompt, best)
        end
        freeInteractionCooldowns[best] = os.clock() + 0.8
        task.wait(0.06)
        endAutomationMove()
        table.clear(reachabilityCache)
        return true
    end

    local function targetFromRequirement(value)
        local current = value.Parent
        local fallback
        for _ = 1, 5 do
            if not current or current == workspace then break end
            if items[current] then return nil end
            if current:IsA("Model") or current:IsA("BasePart") then
                local part = getPart(current)
                if part then
                    fallback = fallback or current
                    local lower = string.lower(current.Name)
                    local hasInteraction = current:FindFirstChildWhichIsA("ClickDetector", true)
                        or current:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local isNamed = lower:find("door", 1, true)
                        or lower:find("gate", 1, true)
                        or lower:find("panel", 1, true)
                        or lower:find("lock", 1, true)
                        or lower:find("power", 1, true)
                        or lower:find("safe", 1, true)
                    local mesh = current:FindFirstChildWhichIsA("SpecialMesh", true)
                    local eventMesh = mesh and cleanAssetId(mesh.MeshId) == "524497312"
                    if hasInteraction or isNamed or eventMesh then return current end
                end
            end
            current = current.Parent
        end
        return fallback
    end

    local function readableTargetName(id, target)
        if targetNames[id] then return targetNames[id] end
        if target then
            local name = tostring(target.Name)
            if name:find("%a") then
                name = name:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):gsub("%s+", " ")
                return name
            end
        end
        return "Objective"
    end

    local function findItemById(id)
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local best
        local bestDistance = math.huge
        for item in pairs(items) do
            if isAvailableWorldItem(item) and itemId(item) == id then
                local part = getPart(item)
                if part then
                    local distance = root and (part.Position - root.Position).Magnitude or 0
                    if distance < bestDistance then
                        best = item
                        bestDistance = distance
                    end
                end
            end
        end
        return best, bestDistance
    end

    findOwnedById = function(id)
        local character = localPlayer.Character
        local backpack = localPlayer:FindFirstChild("Backpack")
        for _, container in ipairs({character, backpack}) do
            if container then
                for _, object in ipairs(container:GetChildren()) do
                    if object:IsA("Tool") then
                        local resolved = itemId(object)
                        local alias = aliases[token(object.Name)]
                        if resolved == id or alias == id then
                            return object
                        end
                    end
                end
            end
        end
    end

    local function collectObjectives()
        local result = {}
        local seen = {}
        for value in pairs(requirements) do
            if value.Parent and not belongsToItem(value) then
                local id = idFromText(value.Value)
                if id then
                    local target = targetFromRequirement(value)
                    local part = target and getPart(target)
                    if target and part then
                        local key = tostring(target) .. ":" .. id
                        if not seen[key] then
                            seen[key] = true
                            result[#result + 1] = {
                                Id = id,
                                ItemName = displayNames[id] or id:gsub("(%l)(%u)", "%1 %2"),
                                Target = target,
                                Part = part,
                                TargetName = readableTargetName(id, target),
                                Requirement = value,
                            }
                        end
                    end
                end
            end
        end
        return result
    end

    local function chooseObjective(objectives)
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local best
        local bestScore = math.huge
        for _, objective in ipairs(objectives) do
            local owned = findOwnedById(objective.Id)
            local worldItem, worldDistance = findItemById(objective.Id)
            local score
            if owned then
                score = 0
            elseif worldItem then
                score = 100 + (worldDistance or 0)
            else
                score = 100000
                if root and objective.Part then
                    score = score + (objective.Part.Position - root.Position).Magnitude
                end
            end
            local cooldown = objective.Requirement and objectiveCooldowns[objective.Requirement]
            if cooldown and cooldown > os.clock() then score = score + 50000 end
            if score < bestScore then
                best = objective
                bestScore = score
            end
        end
        return best, bestScore
    end

    local function objectiveText(objective)
        if not objective then return "Current objective: none detected" end
        return "Current objective: " .. objective.ItemName .. " -> " .. objective.TargetName
    end

    local function remainingText(objectives)
        if #objectives == 0 then return "Items needed: none, exit is next" end
        local names = {}
        local seen = {}
        for _, objective in ipairs(objectives) do
            if not seen[objective.ItemName] then
                seen[objective.ItemName] = true
                names[#names + 1] = objective.ItemName
            end
        end
        table.sort(names)
        return "Items needed: " .. table.concat(names, ", ")
    end

    local function refreshObjectiveState()
        local objectives = collectObjectives()
        currentObjective = chooseObjective(objectives)
        if objectiveMapLabel then objectiveMapLabel:Set("Map: " .. currentMapName() .. " | active objectives: " .. tostring(#objectives)) end
        if objectiveCurrentLabel then objectiveCurrentLabel:Set(objectiveText(currentObjective)) end
        if objectiveNeededLabel then objectiveNeededLabel:Set(remainingText(objectives)) end
        if objectiveStatusLabel then
            if not currentObjective then
                objectiveStatusLabel:Set("Status: objectives clear, escape is next")
            elseif findOwnedById(currentObjective.Id) then
                objectiveStatusLabel:Set("Status: item owned, apply it to " .. currentObjective.TargetName)
            elseif findItemById(currentObjective.Id) then
                objectiveStatusLabel:Set("Status: collect " .. currentObjective.ItemName .. " | pickup: " .. lastPickupStatus)
            else
                objectiveStatusLabel:Set("Status: waiting for " .. currentObjective.ItemName .. " to become available | pickup: " .. lastPickupStatus)
            end
        end
        return objectives, currentObjective
    end

    local function equipRequired(id)
        local object = findOwnedById(id)
        if not object then
            local worldItem = findItemById(id)
            if worldItem then
                local picked = grabItem(worldItem, false, id)
                if picked then
                    task.wait(0.1)
                    object = findOwnedById(id)
                end
            end
        end
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if object and object:IsA("Tool") and humanoid and object.Parent ~= character then
            humanoid:EquipTool(object)
            task.wait(0.08)
        end
        return object
    end

    local function activateObjective(objective)
        if not objective or not objective.Target or not objective.Target.Parent then return false end
        local root = Common.Root()
        local part = getPart(objective.Target)
        if not part then return false end
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local target = part.CFrame + part.CFrame.LookVector * -2 + Vector3.new(0, 1.5, 0)
        beginAutomationMove(target)
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        task.wait(0.025)
        local fired = false
        if objective.Target:IsA("ClickDetector") and fireclickdetector then
            pcall(fireclickdetector, objective.Target)
            fired = true
        elseif objective.Target:IsA("ProximityPrompt") and fireproximityprompt then
            pcall(fireproximityprompt, objective.Target)
            fired = true
        end
        for _, descendant in ipairs(objective.Target:GetDescendants()) do
            if descendant:IsA("ClickDetector") and fireclickdetector then
                pcall(fireclickdetector, descendant)
                fired = true
            elseif descendant:IsA("ProximityPrompt") and fireproximityprompt then
                pcall(fireproximityprompt, descendant)
                fired = true
            end
        end
        if firetouchinterest then
            Common.Touch(root, part)
            fired = true
        end
        local equipped = character and character:FindFirstChildWhichIsA("Tool")
        if equipped then pcall(function() equipped:Activate() end) end
        task.wait(0.08)
        endAutomationMove()
        return fired
    end

    local function autoEscapeStep()
        local root = Common.Root()
        local best
        local bestDistance = math.huge
        for part in pairs(escapeTargets) do
            if part.Parent then
                local distance = (part.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best = part
                    bestDistance = distance
                end
            end
        end
        if not best then
            for interactive in pairs(interactives) do
                if interactive.Parent then
                    local part = getPart(interactive)
                    local name = string.lower((interactive.Parent and interactive.Parent.Name or "") .. " " .. (part and part.Name or ""))
                    if part and (name:find("exit", 1, true) or name:find("escape", 1, true) or name:find("final", 1, true)) then
                        best = part
                        break
                    end
                end
            end
        end
        if not best then return false end
        beginAutomationMove(best.CFrame + Vector3.new(0, 2, 0))
        task.wait(0.025)
        if firetouchinterest then Common.Touch(root, best) end
        local click = best:FindFirstChildWhichIsA("ClickDetector", true)
        local prompt = best:FindFirstChildWhichIsA("ProximityPrompt", true)
        if click and fireclickdetector then pcall(fireclickdetector, click) end
        if prompt and fireproximityprompt then pcall(fireproximityprompt, prompt) end
        task.wait(0.05)
        endAutomationMove()
        return true
    end

    local function autoCompleteStep()
        if autoCompleteBusy then return end
        autoCompleteBusy = true
        local objectives, objective = refreshObjectiveState()
        if #objectives == 0 then
            if runFreeInteractionStep() then
                task.wait(0.05)
                refreshObjectiveState()
            else
                autoEscapeStep()
            end
            autoCompleteBusy = false
            return
        end
        if not objective then
            autoCompleteBusy = false
            return
        end
        local required = equipRequired(objective.Id)
        if required then
            if activateObjective(objective) and objective.Requirement then
                objectiveCooldowns[objective.Requirement] = os.clock() + 0.6
                table.clear(reachabilityCache)
            end
        else
            runFreeInteractionStep()
        end
        refreshObjectiveState()
        autoCompleteBusy = false
    end

    local godParts = {
        Head = true,
        HumanoidRootPart = true,
        UpperTorso = true,
        LowerTorso = true,
        Torso = true,
        LeftFoot = true,
        RightFoot = true,
        LeftHand = true,
        RightHand = true,
        LeftLowerLeg = true,
        RightLowerLeg = true,
        LeftUpperLeg = true,
        RightUpperLeg = true,
        LeftLowerArm = true,
        RightLowerArm = true,
        LeftUpperArm = true,
        RightUpperArm = true,
        LeftArm = true,
        RightArm = true,
        LeftLeg = true,
        RightLeg = true,
    }

    local function setCharacterTouch(enabled)
        local character = localPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and (godParts[part.Name] or part.Parent == character) then
                if enabled then
                    scope:Set(part, "CanTouch", false)
                else
                    scope:Restore(part, "CanTouch")
                end
            end
        end
    end

    local function disableEnemyTouchTransmitters(model)
        if not model or not model.Parent then return end
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("TouchTransmitter") and descendant.Parent and not disabledEnemyTouches[descendant] then
                local parent = descendant.Parent
                local ok = pcall(function() descendant.Parent = nil end)
                if ok then disabledEnemyTouches[descendant] = parent end
            end
        end
    end

    local function restoreEnemyTouchTransmitters()
        for transmitter, parent in pairs(disabledEnemyTouches) do
            if transmitter and parent and parent.Parent then
                pcall(function() transmitter.Parent = parent end)
            end
            disabledEnemyTouches[transmitter] = nil
        end
    end

    local function applyGodMode()
        if not godMode then return end
        setCharacterTouch(true)
        for bot in pairs(bots) do
            disableEnemyTouchTransmitters(bot)
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character and isPiggyPlayer(player) then
                disableEnemyTouchTransmitters(player.Character)
            end
        end
    end

    scope:Connect(RunService.PreSimulation, applyGodMode)
    scope:Connect(localPlayer.CharacterAdded, function(character)
        scope:Connect(character.DescendantAdded, function(instance)
            if godMode and instance:IsA("BasePart") and (godParts[instance.Name] or instance.Parent == character) then
                scope:Set(instance, "CanTouch", false)
            end
        end)
        if godMode then task.defer(applyGodMode) end
    end)

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

    local function applyTrapBypass(value)
        for trap in pairs(traps) do
            if trap.Parent then
                if value then
                    scope:Set(trap, "CanTouch", false)
                else
                    scope:Restore(trap, "CanTouch")
                end
            end
        end
    end

    local function applyDoors(value)
        for part in pairs(doors) do
            if part.Parent then
                if value then
                    scope:Set(part, "CanCollide", false)
                    scope:Set(part, "Transparency", math.max(part.Transparency, 0.55))
                else
                    scope:Restore(part, "CanCollide")
                    scope:Restore(part, "Transparency")
                end
            end
        end
    end

    local function applyBotFreeze(value)
        for bot in pairs(bots) do
            local root = getPart(bot)
            if root then
                if value then
                    scope:Set(root, "Anchored", true)
                else
                    scope:Restore(root, "Anchored")
                end
            end
        end
    end

    local function setupVisualTab(tab)
        tab:CreateSection("ESP")
        tab:CreateToggle("Item ESP", false, function(value)
            itemEsp = value
            if not value then clearKind("Item") end
        end)
        tab:CreateToggle("Piggy / Bot ESP", false, function(value)
            piggyEsp = value
            if not value then clearKind("Piggy") end
        end)
        tab:CreateToggle("Player ESP", false, function(value)
            playerEsp = value
            if not value then clearKind("Player") end
        end)
        tab:CreateToggle("Trap ESP", false, function(value)
            trapEsp = value
            if not value then clearKind("Trap") end
        end)
        tab:CreateToggle("Fullbright", false, function(value)
            fullbright = value
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
    end

    local function setupItemTab(tab)
        tab:CreateSection("Items")
        local names = itemNames()
        local dropdown = tab:CreateDropdown("Item", names, names[1], function(value)
            selectedItem = value
        end)
        selectedItem = names[1]
        tab:CreateButton("Refresh item list", function()
            local updated = itemNames()
            dropdown:Refresh(updated)
            if not selectedItem or not table.find(updated, selectedItem) then selectedItem = updated[1] end
        end)
        tab:CreateButton("Grab selected item", function()
            local item = selectedItem and findItemByName(selectedItem)
            if item then grabItem(item, true, itemId(item)) end
        end)
        tab:CreateButton("Teleport to selected item", function()
            local item = selectedItem and findItemByName(selectedItem)
            if item then teleportItem(item) end
        end)
        tab:CreateButton("Grab nearest item", function()
            local item = nearestItem()
            if item then grabItem(item, true, itemId(item)) end
        end)
    end

    local function setupObjectiveHelper(tab)
        tab:CreateSection("Objective Helper")
        objectiveMapLabel = tab:CreateLabel("Map: " .. currentMapName())
        objectiveCurrentLabel = tab:CreateLabel("Current objective: scanning...")
        objectiveNeededLabel = tab:CreateLabel("Items needed: scanning...")
        objectiveStatusLabel = tab:CreateLabel("Status: scanning map...")
        tab:CreateToggle("Objective ESP", false, function(value)
            objectiveEsp = value
            if not value then
                clearKind("Objective")
                objectiveVisualTarget = nil
            end
        end)
        tab:CreateButton("Refresh objectives", refreshObjectiveState)
        tab:CreateButton("Teleport to required item", function()
            local _, objective = refreshObjectiveState()
            if not objective then return end
            local item = findItemById(objective.Id)
            if item then teleportItem(item) end
        end)
        tab:CreateButton("Teleport to objective target", function()
            local _, objective = refreshObjectiveState()
            local part = objective and getPart(objective.Target)
            if part then Common.Root().CFrame = part.CFrame + Vector3.new(0, 2.5, 0) end
        end)
    end

    local function setupPlayerTab(tab, rage)
        tab:CreateSection("Movement")
        tab:CreateToggle("WalkSpeed", false, function(value)
            speedEnabled = value
            if not value then
                local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then scope:Restore(humanoid, "WalkSpeed") end
            end
        end)
        tab:CreateSlider("WalkSpeed value", {Min = 16, Max = rage and 120 or 40, Default = speedValue}, function(value)
            speedValue = value
        end)
        tab:CreateToggle("JumpPower", false, function(value)
            jumpEnabled = value
            if not value then
                local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then scope:Restore(humanoid, "JumpPower") end
            end
        end)
        tab:CreateSlider("JumpPower value", {Min = 50, Max = rage and 160 or 80, Default = jumpValue}, function(value)
            jumpValue = value
        end)
        tab:CreateToggle("Infinite jump", false, function(value) infiniteJump = value end)
        tab:CreateToggle("Noclip", false, function(value)
            noclip = value
            if value then applyNoclip() else restoreNoclip() end
        end)
    end

    if mode == "Rage" then
        local rage = ctx.Window:CreateTab("Rage", "R")
        local itemsTab = ctx.Window:CreateTab("Items", "I")
        local visualsTab = ctx.Window:CreateTab("ESP", "E")
        local playerTab = ctx.Window:CreateTab("Player", "P")

        rage:CreateSection(bookName)
        rage:CreateLabel("Universe support: Book 1, Book 2 and extra Piggy places")
        setupObjectiveHelper(rage)
        rage:CreateToggle("Auto complete objectives", false, function(value)
            autoComplete = value
            if value then
                autoGrab = false
                autoInteract = false
                scope:StopTask("autoGrab")
                scope:StopTask("autoInteract")
                scope:Loop("autoComplete", 0.4, autoCompleteStep)
            else
                scope:StopTask("autoComplete")
            end
        end)
        rage:CreateToggle("Auto grab items", false, function(value)
            autoGrab = value
            if value then
                autoComplete = false
                autoInteract = false
                scope:StopTask("autoComplete")
                scope:StopTask("autoInteract")
                scope:Loop("autoGrab", 0.2, function()
                    local item = nearestItem()
                    if item then grabItem(item, false, itemId(item)) end
                end)
            else
                scope:StopTask("autoGrab")
            end
        end)
        rage:CreateToggle("Auto interact", false, function(value)
            autoInteract = value
            if value then
                autoComplete = false
                autoGrab = false
                scope:StopTask("autoComplete")
                scope:StopTask("autoGrab")
                scope:Loop("autoInteract", 0.2, function()
                    local list = interactiveList()
                    if #list == 0 then return end
                    completeCursor = completeCursor % #list + 1
                    triggerInteractive(list[completeCursor], false)
                end)
            else
                scope:StopTask("autoInteract")
            end
        end)
        rage:CreateButton("Complete one objective pass", autoCompleteStep)
        rage:CreateSection("Bypasses")
        rage:CreateToggle("God mode", false, function(value)
            godMode = value
            if value then
                applyGodMode()
            else
                setCharacterTouch(false)
                restoreEnemyTouchTransmitters()
            end
        end)
        rage:CreateToggle("Trap bypass", false, function(value)
            trapBypass = value
            applyTrapBypass(value)
        end)
        rage:CreateToggle("Remove doors locally", false, function(value)
            doorsRemoved = value
            applyDoors(value)
        end)
        rage:CreateToggle("Freeze Piggy / bots", false, function(value)
            botsFrozen = value
            applyBotFreeze(value)
        end)

        setupItemTab(itemsTab)
        setupVisualTab(visualsTab)
        setupPlayerTab(playerTab, true)
    else
        local main = ctx.Window:CreateTab("Legit", "L")
        local visualsTab = ctx.Window:CreateTab("ESP", "E")
        local playerTab = ctx.Window:CreateTab("Player", "P")

        main:CreateSection(bookName)
        main:CreateLabel("Item names are resolved from Piggy mesh, color and metadata signatures")
        setupObjectiveHelper(main)
        setupItemTab(main)
        setupVisualTab(visualsTab)
        setupPlayerTab(playerTab, false)
    end

    scope:Connect(UserInputService.JumpRequest, function()
        if infiniteJump then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    scope:Loop("objectiveHelper", 0.4, refreshObjectiveState)

    scope:Loop("playerState", 0.05, function()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if speedEnabled and humanoid then scope:Set(humanoid, "WalkSpeed", speedValue) end
        if jumpEnabled and humanoid then scope:Set(humanoid, "JumpPower", jumpValue) end
        if noclip then applyNoclip() end
        if godMode then setCharacterTouch(true) end
    end)

    scope:Loop("rageRefresh", 0.5, function()
        if trapBypass then applyTrapBypass(true) end
        if doorsRemoved then applyDoors(true) end
        if botsFrozen then applyBotFreeze(true) end
    end)

    scope:AddRestore(function()
        clearKind()
        setCharacterTouch(false)
        restoreEnemyTouchTransmitters()
        restoreNoclip()
        applyTrapBypass(false)
        applyDoors(false)
        applyBotFreeze(false)
        if fullbright then
            scope:Restore(Lighting, "Brightness")
            scope:Restore(Lighting, "GlobalShadows")
            scope:Restore(Lighting, "Ambient")
            scope:Restore(Lighting, "OutdoorAmbient")
        end
    end)
end
