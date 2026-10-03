return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local mode = ctx.Mode or "Legit"
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local localPlayer = Players.LocalPlayer
    local items = {}
    local interactives = {}
    local traps = {}
    local doors = {}
    local bots = {}
    local visuals = {}
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

    local bookName = "Piggy universe"
    if game.PlaceId == 4623386862 then
        bookName = "Book 1"
    elseif game.PlaceId == 5661005779 then
        bookName = "Book 2"
    end

    local function getPart(object)
        if not object or not object.Parent then return nil end
        if object:IsA("BasePart") then return object end
        if object:IsA("Model") then
            return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object:FindFirstChildWhichIsA("BasePart", true)
        end
        local parent = object.Parent
        if parent and parent:IsA("BasePart") then return parent end
        if parent and parent:IsA("Model") then
            return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
        end
    end

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

    local function book2ItemFrom(instance)
        if instance.Name == "ItemHandler" and instance.Parent then return instance.Parent end
        if instance:IsA("Tool") and (instance:FindFirstChildWhichIsA("ProximityPrompt", true) or instance:FindFirstChildWhichIsA("ClickDetector", true)) then
            return instance
        end
        if instance:IsA("Model") and (instance:FindFirstChildWhichIsA("ProximityPrompt", true) or instance:FindFirstChildWhichIsA("ClickDetector", true)) then
            if instance:FindFirstChild("Handle") or aliases[token(instance.Name)] or not tostring(instance.Name):find("%a") then
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
            items[item] = true
            itemNameCache[item] = nil
        end
        if instance:IsA("ClickDetector") or instance:IsA("ProximityPrompt") then
            interactives[instance] = true
        end
        if instance:IsA("BasePart") then
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
                if item.Parent then tag(item, "Item", Color3.fromRGB(255, 210, 70), itemDisplayName(item)) end
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
            if item.Parent and getPart(item) then
                list[#list + 1] = item
            else
                items[item] = nil
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
            if item.Parent and itemDisplayName(item) == name then
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
            local part = getPart(item)
            if part then
                local distance = (part.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best = item
                    bestDistance = distance
                end
            else
                items[item] = nil
            end
        end
        return best
    end

    local function grabItem(item, returnAfter)
        local part = getPart(item)
        if not part then return false end
        local click, prompt = detectorFor(item)
        if not click and not prompt then return false end
        local root = Common.Root()
        local old = root.CFrame
        root.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
        task.wait(0.05)
        if click and fireclickdetector then pcall(fireclickdetector, click) end
        if prompt and fireproximityprompt then pcall(fireproximityprompt, prompt) end
        task.wait(0.08)
        if returnAfter and root.Parent then root.CFrame = old end
        return true
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

    local function autoCompleteStep()
        local list = interactiveList()
        if #list > 0 then
            for _ = 1, math.min(3, #list) do
                completeCursor = completeCursor % #list + 1
                triggerInteractive(list[completeCursor], false)
            end
        end
        local item = nearestItem()
        if item then grabItem(item, false) end
        local root = Common.Root()
        for interactive in pairs(interactives) do
            local parent = interactive.Parent
            local part = getPart(interactive)
            if parent and part then
                local lower = string.lower(parent.Name .. " " .. part.Name)
                if string.find(lower, "exit", 1, true) or string.find(lower, "escape", 1, true) or string.find(lower, "final", 1, true) then
                    triggerInteractive(interactive, false)
                    if firetouchinterest then Common.Touch(root, part) end
                end
            end
        end
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

    local function applyGodMode()
        if not godMode then return end
        setCharacterTouch(true)
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
            if item then grabItem(item, true) end
        end)
        tab:CreateButton("Teleport to selected item", function()
            local item = selectedItem and findItemByName(selectedItem)
            if item then teleportItem(item) end
        end)
        tab:CreateButton("Grab nearest item", function()
            local item = nearestItem()
            if item then grabItem(item, true) end
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
        rage:CreateToggle("Auto complete objectives", false, function(value)
            autoComplete = value
            if value then
                scope:Loop("autoComplete", 0.25, autoCompleteStep)
            else
                scope:StopTask("autoComplete")
            end
        end)
        rage:CreateToggle("Auto grab items", false, function(value)
            autoGrab = value
            if value then
                scope:Loop("autoGrab", 0.2, function()
                    local item = nearestItem()
                    if item then grabItem(item, false) end
                end)
            else
                scope:StopTask("autoGrab")
            end
        end)
        rage:CreateToggle("Auto interact", false, function(value)
            autoInteract = value
            if value then
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
        rage:CreateToggle("God mode (bots only)", false, function(value)
            godMode = value
            setCharacterTouch(value)
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
        main:CreateLabel("Item tools use Piggy ItemPickupScript / ClickDetector objects")
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
