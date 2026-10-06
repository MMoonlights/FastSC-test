function explicitId(item)
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

function treeId(item)
    local values = {item.Name}
    for _, descendant in ipairs(item:GetDescendants()) do
        values[#values + 1] = descendant.Name
    end
    local joined = token(table.concat(values, " "))
    for alias, id in pairs(aliases) do
        if #alias >= 4 and joined:find(alias, 1, true) then return id end
    end
end

function meshSignatures(item)
    local result = {}
    local function add(object)
        local meshId = ""
        local textureId = ""
        local scale
        if object:IsA("SpecialMesh") then
            meshId = cleanAssetId(object.MeshId)
            textureId = cleanAssetId(object.TextureId)
            scale = object.Scale
        elseif object:IsA("MeshPart") then
            meshId = cleanAssetId(object.MeshId)
            local ok, texture = pcall(function() return object.TextureID end)
            if ok then textureId = cleanAssetId(texture) end
        end
        result[#result + 1] = {
            MeshId = meshId,
            TextureId = textureId,
            Scale = scale,
        }
    end
    if item:IsA("SpecialMesh") or item:IsA("MeshPart") then add(item) end
    for _, descendant in ipairs(item:GetDescendants()) do
        if descendant:IsA("SpecialMesh") or descendant:IsA("MeshPart") then
            add(descendant)
        end
    end
    return result
end

function hasMeshSignature(signatures, meshIds, textureIds)
    for _, signature in ipairs(signatures) do
        if meshIds and table.find(meshIds, signature.MeshId) then return signature end
        if textureIds and table.find(textureIds, signature.TextureId) then return signature end
    end
end

function signatureId(item)
    if item:FindFirstChildWhichIsA("SurfaceGui", true) and item:FindFirstChild("ItemPickupScript", true) then
        return "KeyCode"
    end

    local signatures = meshSignatures(item)
    local color = particleColor(item)
    local colorName = color and colorIds[color] or nil
    local part = getPart(item)
    local brick = part and part.BrickColor.Name or nil

    if hasMeshSignature(signatures, {"16198309"}, {"16198294"}) then return "Hammer" end
    if hasMeshSignature(signatures, {"16884681"}, {"16884673", "16884681"}) then return "Wrench" end
    if hasMeshSignature(signatures, {"72012879"}) then return "Gun" end
    if hasMeshSignature(signatures, {"741743576"}) then return "Carrot" end
    if hasMeshSignature(signatures, {"1771168429"}, {"1771169634"}) then return "WaterGun" end
    if hasMeshSignature(signatures, {"120607730"}) then return "Mallet" end
    if hasMeshSignature(signatures, {"15886761"}) then return "Crossbow" end
    if hasMeshSignature(signatures, {"725833400"}, {"725833458"}) then return "Ammo" end

    local explosive = hasMeshSignature(signatures, {"27787143"})
    if explosive then
        if explosive.Scale and explosive.Scale.Magnitude < 1 then return "TNT" end
        return "FireExtinguisher"
    end

    local gear = hasMeshSignature(signatures, {"524706126"})
    if gear then
        if colorName == "Green" or brick == "Shamrock" then return "GreenGear" end
        if brick == "Persimmon" or colorName == "Red" or colorName == "White" then return "RedGear" end
        return "Gear"
    end

    local keySignature
    for _, signature in ipairs(signatures) do
        if signature.MeshId == "456878024" then
            local validScale = not signature.Scale
                or ((signature.Scale - Vector3.new(5, 5, 5)).Magnitude <= 0.25)
            if validScale then
                keySignature = signature
                break
            end
        end
    end
    if keySignature and colorName then
        return colorName .. "Key"
    end

    if item:IsA("UnionOperation") or item:FindFirstChildWhichIsA("UnionOperation", true) then
        if colorName == "Blue" then return "BlueKeycard" end
        if colorName == "Orange" then return "OrangeKeycard" end
        if colorName == "Red" then return "RedKeycard" end
    end

    if brickColors[brick] then
        local colorId = brickColors[brick]
        if brick == "Shamrock" then return "GreenGear" end
        if brick == "Persimmon" and item:FindFirstChildWhichIsA("UnionOperation", true) then return "Gas" end
        if keySignature then return colorId .. "Key" end
    end

    if brick == "Burnt Sienna" or brick == "BurntSienna" then return "Plank" end
end

function itemId(item)
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

function itemDisplayName(item)
    local id = itemId(item)
    local cached = itemNameCache[item]
    if cached and cached.Name then return cached.Name end
    return displayNames[id] or tostring(id or "Unknown Item")
end

function requirementExists(id)
    return (requirementCounts[id] or 0) > 0
end

function currentEventsRoot()
    local map = currentMapModel()
    if not map then return nil end
    return map:FindFirstChild("Events")
        or map:FindFirstChild("events")
        or map:FindFirstChild("EventFolder")
        or map:FindFirstChild("Event")
end

function requirementEventMesh(parent)
    if not parent then return false end
    local mesh = parent:FindFirstChildWhichIsA("SpecialMesh", true)
    return mesh
        and cleanAssetId(mesh.MeshId) == "524497312"
        and (mesh.Scale - Vector3.new(0.75, 0.5, 0.75)).Magnitude <= 0.08
end

function requirementHost(value)
    local current = value and value.Parent
    local fallback
    for _ = 1, 6 do
        if not current or current == workspace then break end
        if items[current] then return nil end
        if current:IsA("BasePart") or current:IsA("Model") then
            fallback = fallback or current
            if requirementEventMesh(current) then return current end
            if current:FindFirstChildWhichIsA("ClickDetector", true)
                or current:FindFirstChildWhichIsA("ProximityPrompt", true)
                or current:FindFirstChildWhichIsA("TouchTransmitter", true) then
                return current
            end
            local lower = string.lower(current.Name)
            if lower:find("door", 1, true)
                or lower:find("gate", 1, true)
                or lower:find("lock", 1, true)
                or lower:find("safe", 1, true)
                or lower:find("panel", 1, true)
                or lower:find("power", 1, true)
                or lower:find("gear", 1, true)
                or lower:find("generator", 1, true)
                or lower:find("machine", 1, true)
                or lower:find("event", 1, true) then
                return current
            end
        end
        current = current.Parent
    end
    return fallback
end

optionalObjectiveIds = {
    Ammo = true,
    Gun = true,
    Bone = true,
    Grass = true,
    Apple = true,
    Rose = true,
    Crossbow = true,
}

carrotProgressionMaps = {
    Store = true,
    Refinery = true,
    WinterHoliday = true,
    ["Winter Holiday"] = true,
}

function isObjectiveRequirement(value)
    if not value or not value.Parent or not value:IsA("StringValue") then return false end
    local requirementId = aliases[token(value.Value)]
    if not requirementId then return false end
    if optionalObjectiveIds[requirementId] then return false end
    if requirementId == "Carrot" and not carrotProgressionMaps[currentMapName()] then return false end
    if itemObjectFrom(value) then return false end

    local map = currentMapModel()
    if not map or not value:IsDescendantOf(map) then return false end

    if value.Name == "ToolRequired" then return true end

    local host = requirementHost(value)
    if host then
        local events = currentEventsRoot()
        if events and value:IsDescendantOf(events) then return true end
        if requirementEventMesh(host) then return true end
        if host:FindFirstChildWhichIsA("ClickDetector", true)
            or host:FindFirstChildWhichIsA("ProximityPrompt", true)
            or host:FindFirstChildWhichIsA("TouchTransmitter", true) then
            return true
        end
    end

    return false
end

function updateRequirement(value)
    local old = requirementIdByValue[value]
    if old then
        requirementCounts[old] = math.max(0, (requirementCounts[old] or 1) - 1)
        if requirementCounts[old] == 0 then requirementCounts[old] = nil end
    end

    local id
    if isObjectiveRequirement(value) then
        id = aliases[token(value.Value)]
    end

    requirementIdByValue[value] = id
    if id then requirementCounts[id] = (requirementCounts[id] or 0) + 1 end
    itemUiDirty = true
end

function trackRequirement(value)
    requirements[value] = true
    if not trackedRequirements[value] then
        trackedRequirements[value] = true
        updateRequirement(value)
        scope:Connect(value:GetPropertyChangedSignal("Value"), function()
            updateRequirement(value)
        end)
        scope:Connect(value.AncestryChanged, function()
            if value.Parent then updateRequirement(value) end
        end)
    end
end

function refreshRequirementsNear(instance)
    local current = instance and instance.Parent
    local seen = {}
    for _ = 1, 6 do
        if not current or current == workspace then break end
        for _, child in ipairs(current:GetChildren()) do
            if child:IsA("StringValue") and not seen[child] then
                seen[child] = true
                if requirements[child] or aliases[token(child.Value)] then
                    trackRequirement(child)
                    updateRequirement(child)
                end
            end
        end
        current = current.Parent
    end
end

function untrackRequirement(value)
    requirements[value] = nil
    local id = requirementIdByValue[value]
    if id then
        requirementCounts[id] = math.max(0, (requirementCounts[id] or 1) - 1)
        if requirementCounts[id] == 0 then requirementCounts[id] = nil end
    end
    requirementIdByValue[value] = nil
    trackedRequirements[value] = nil
    itemUiDirty = true
end

function itemStagePresent(id)
    local bucket = itemsById[id]
    if bucket then
        for item in pairs(bucket) do
            if isWorldItem(item) then return true end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local backpack = player:FindFirstChild("Backpack")
        for _, container in ipairs({player.Character, backpack}) do
            if container then
                for _, object in ipairs(container:GetChildren()) do
                    if object:IsA("Tool") then
                        local resolved = itemId(object)
                        if resolved == id or aliases[token(object.Name)] == id then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function ancestorRequirementLocks(item)
    local map = currentMapModel()
    local current = item

    for _ = 1, 7 do
        if not current or current == workspace or current == map then break end

        -- ItemFolder/Items/Spawn folders are shared containers. Looking through
        -- every requirement below them makes one locked pickup hide unrelated
        -- items in the same folder, which can stall Full Run on a valid item.
        if current ~= item and current:IsA("Folder") then
            local name = token(current.Name)
            if name == "items"
                or name == "itemfolder"
                or name == "itemfolder1"
                or name:find("pickup", 1, true)
                or name:find("spawn", 1, true) then
                break
            end
        end

        for _, child in ipairs(current:GetChildren()) do
            if child:IsA("StringValue") then
                local id = aliases[token(child.Value)]
                if id and requirementExists(id) then return true end
            end
        end

        for value in pairs(requirements) do
            if value.Parent and value:IsDescendantOf(current) and isObjectiveRequirement(value) then
                local id = aliases[token(value.Value)]
                if id and requirementExists(id) then return true end
            end
        end

        current = current.Parent
    end
    return false
end
function isAvailableWorldItem(item)
    if not isWorldItem(item) then return false end
    local part = getPart(item)
    if not part then return false end

    local id = itemId(item)
    local map = currentMapName()

    local profile = mapProfiles[map]
    local gate = profile and profile.Gates and profile.Gates[id]
    if gate then
        for _, dependency in ipairs(gate.Present or {}) do
            if itemStagePresent(dependency) then return false end
        end
        for _, dependency in ipairs(gate.Active or {}) do
            if requirementExists(dependency) then return false end
        end
        for _, dependency in ipairs(gate.Synthetic or {}) do
            if not syntheticCompleted or not syntheticCompleted[dependency] then
                return false
            end
        end
    end

    if ancestorRequirementLocks(item) then
        return false
    end

    local click = item:FindFirstChildWhichIsA("ClickDetector", true)
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and not prompt.Enabled and not click then
        return false
    end

    return true
end

function removeIndexedBucket(item)
    local id = itemIndexedId[item]
    if not id then return end
    local bucket = itemsById[id]
    if bucket then
        bucket[item] = nil
        if next(bucket) == nil then itemsById[id] = nil end
    end
    itemIndexedId[item] = nil
end

function indexItem(item)
    if not item or not item.Parent or not isWorldItem(item) then return end
    removeIndexedBucket(item)
    itemNameCache[item] = nil
    items[item] = true
    local id = itemId(item)
    itemIndexedId[item] = id
    itemUiDirty = true
    local bucket = itemsById[id]
    if not bucket then
        bucket = setmetatable({}, {__mode = "k"})
        itemsById[id] = bucket
    end
    bucket[item] = true
end

function unindexItem(item)
    removeIndexedBucket(item)
    items[item] = nil
    itemNameCache[item] = nil
    itemUiDirty = true
end

function watchItemSignature(instance, item)
    if trackedItemSignals[instance] then return end
    trackedItemSignals[instance] = true

    local function reclassify()
        if item and item.Parent and isWorldItem(item) then
            indexItem(item)
        end
    end

    if instance:IsA("SpecialMesh") then
        scope:Connect(instance:GetPropertyChangedSignal("MeshId"), reclassify)
        scope:Connect(instance:GetPropertyChangedSignal("TextureId"), reclassify)
        scope:Connect(instance:GetPropertyChangedSignal("Scale"), reclassify)
    elseif instance:IsA("MeshPart") then
        scope:Connect(instance:GetPropertyChangedSignal("MeshId"), reclassify)
        pcall(function()
            scope:Connect(instance:GetPropertyChangedSignal("TextureID"), reclassify)
        end)
    elseif instance:IsA("ParticleEmitter") then
        scope:Connect(instance:GetPropertyChangedSignal("Color"), reclassify)
    elseif instance:IsA("StringValue") then
        scope:Connect(instance:GetPropertyChangedSignal("Value"), reclassify)
    end
end

function book2ItemFrom(instance)
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

function trueFlag(container, name)
    if not container then return false end
    local value = container:FindFirstChild(name)
    if value and value:IsA("BoolValue") then return value.Value == true end
    local attribute = container:GetAttribute(name)
    return attribute == true
end

function isPiggyPlayer(player)
    local character = player and player.Character
    return trueFlag(character, "Enemy")
        or trueFlag(player, "Enemy")
        or trueFlag(character, "IsPiggy")
        or trueFlag(player, "IsPiggy")
        or trueFlag(character, "Piggy")
        or trueFlag(player, "Piggy")
end

function underPiggyFolder(instance)
    local current = instance
    while current and current ~= workspace do
        if current.Name == "PiggyNPC" then return true end
        current = current.Parent
    end
    return false
end

function isBotModel(model)
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

function registerPiggyFolder(folder)
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

function register(instance)
    local item = itemObjectFrom(instance) or book2ItemFrom(instance)
    if item then
        watchItemSignature(instance, item)
        if isWorldItem(item) then
            indexItem(item)
        else
            unindexItem(item)
            if removeVisual then removeVisual(item) end
        end
    end
    if instance:IsA("ClickDetector") or instance:IsA("ProximityPrompt") then
        interactives[instance] = true
        refreshRequirementsNear(instance)
    elseif instance:IsA("TouchTransmitter") then
        refreshRequirementsNear(instance)
    end
    if instance:IsA("StringValue") then
        trackRequirement(instance)
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

function unregister(instance)
    unindexItem(instance)
    interactives[instance] = nil
    traps[instance] = nil
    doors[instance] = nil
    bots[instance] = nil
    if instance:IsA("StringValue") then
        untrackRequirement(instance)
    else
        requirements[instance] = nil
    end
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

function attachPlayer(player)
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

function tag(object, kind, color, title)
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

function clearKind(kind)
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

function detectorFor(item)
    if not item then return nil end
    return item:FindFirstChildWhichIsA("ClickDetector", true),
        item:FindFirstChildWhichIsA("ProximityPrompt", true),
        item:FindFirstChildWhichIsA("TouchTransmitter", true)
end

function firePickupInteraction(item, part)
    if not item or not item.Parent or not part or not part.Parent then return false end

    local fired = false
    local click, prompt, touch = detectorFor(item)

    if click and click.Parent and fireclickdetector then
        local oldDistance = click.MaxActivationDistance
        pcall(function() click.MaxActivationDistance = math.huge end)
        pcall(fireclickdetector, click)
        pcall(function() click.MaxActivationDistance = oldDistance end)
        fired = true
    end

    if prompt and prompt.Parent and prompt.Enabled and fireproximityprompt then
        local oldHold = prompt.HoldDuration
        pcall(function() prompt.HoldDuration = 0 end)
        pcall(fireproximityprompt, prompt)
        pcall(function() prompt.HoldDuration = oldHold end)
        fired = true
    end

    -- Several Piggy pickup variants are touch-backed even when their visible
    -- pickup model also contains a Script/ItemHandler. Always try a server-side
    -- touch as a fallback so Full Run is not limited to click/prompt items.
    local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and firetouchinterest then
        local touchPart = touch and touch.Parent
        if not touchPart or not touchPart:IsA("BasePart") then touchPart = part end

        if touchPart and touchPart.Parent then
            Common.Touch(root, touchPart)
            fired = true
        end
        if part ~= touchPart and part.Parent then
            Common.Touch(root, part)
            fired = true
        end
    end

    return fired
end

function itemList()
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

function itemNames()
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

function refreshItemDropdown()
    if not itemDropdown or not itemUiDirty then return end
    local names = itemNames()
    local signature = table.concat(names, "\0")
    itemUiDirty = false
    if signature == itemDropdownSignature then return end
    itemDropdownSignature = signature
    itemDropdown:Refresh(names)
    if not selectedItem or not table.find(names, selectedItem) then
        selectedItem = names[1]
    end
end

function findItemByName(name)
    local id = aliases[token(name)]
    local bucket = id and itemsById[id]
    if bucket then
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local best
        local bestDistance = math.huge
        for item in pairs(bucket) do
            if isAvailableWorldItem(item) then
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
    for item in pairs(items) do
        if isAvailableWorldItem(item) and itemDisplayName(item) == name then
            return item
        end
    end
end

function nearestItem()
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

function grabItem(item, returnAfter, expectedId)
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

    local click, prompt, touch = detectorFor(item)
    if not (click and fireclickdetector)
        and not (prompt and fireproximityprompt)
        and not (touch and firetouchinterest)
        and not firetouchinterest then
        lastPickupStatus = "item has no supported pickup interaction"
        return false
    end

    pickupBusy = true
    local runGeneration = automationGeneration
    local root = Common.Root()
    local old = root.CFrame

    local function cancelled()
        return runGeneration ~= automationGeneration
    end

    local function confirm(timeout)
        local deadline = os.clock() + timeout
        repeat
            if cancelled() then return nil end
            if expectedId and findOwnedById then
                local ownedTool = findOwnedById(expectedId)
                if ownedTool then return ownedTool end
            end
            task.wait(0.04)
        until os.clock() >= deadline
    end

    local owned
    local success = pcall(function()
        local confirmWindows = {0.45, 0.65, 0.9}

        for attempt = 1, 3 do
            if cancelled() then break end
            if expectedId and findOwnedById then
                owned = findOwnedById(expectedId)
                if owned then break end
            end

            part = getPart(item)
            if not part then break end

            -- Re-resolve detectors every attempt because staged Piggy pickups can
            -- replace their interaction instance after the first server response.
            click, prompt, touch = detectorFor(item)

            local target = part.CFrame + Vector3.new(0, 1.75, 0)
            beginAutomationMove(target)
            automationDeadline = os.clock() + 3
            task.wait(0.04)

            local fired = firePickupInteraction(item, part)
            if not fired then
                lastPickupStatus = "pickup interaction unavailable"
                break
            end

            owned = confirm(confirmWindows[attempt])
            if owned then break end

            -- If the world model disappeared, keep waiting for the Tool replica
            -- instead of immediately selecting another objective.
            if not item.Parent then
                owned = confirm(0.9)
                break
            end

            task.wait(0.04)
        end

        if not owned then
            owned = confirm(0.9)
        end
    end)

    if not cancelled() then endAutomationMove() end

    -- Manual "Grab selected" returns to the old position. Full Run deliberately
    -- stays beside a failed pickup so the next retry does not bounce back and
    -- forth between the item and the previous objective.
    if returnAfter and not cancelled() then
        if root and root.Parent then
            root.CFrame = old
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    pickupBusy = false

    if cancelled() then
        lastPickupStatus = "cancelled"
        return false
    end

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
        if isWorldItem(item) then indexItem(item) end
    else
        lastPickupStatus = "item despawned, waiting for inventory replication failed"
    end
    return false
end
function teleportItem(item)
    local part = getPart(item)
    if part then Common.Root().CFrame = part.CFrame + Vector3.new(0, 3, 0) end
end

function triggerInteractive(interactive, returnAfter)
    if not interactive or not interactive.Parent then return false end
    local item = itemObjectFrom(interactive)
    if item then return false end
    local part = getPart(interactive)
    if not part then return false end
    local root = Common.Root()
    local old = root.CFrame
    beginAutomationMove(part.CFrame + Vector3.new(0, 2.5, 0))
    task.wait(0.02)
    if interactive:IsA("ClickDetector") and fireclickdetector then
        pcall(fireclickdetector, interactive)
    elseif interactive:IsA("ProximityPrompt") and fireproximityprompt then
        pcall(fireproximityprompt, interactive)
    end
    local lower = string.lower(part.Name)
    if (string.find(lower, "exit", 1, true) or string.find(lower, "escape", 1, true)) and firetouchinterest then
        Common.Touch(root, part)
    end
    task.wait(0.03)
    endAutomationMove()
    if returnAfter and root.Parent then
        root.CFrame = old
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

function interactiveList()
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

targetNames = {
    BlueKey = "Blue Door",
    GreenKey = "Green Door",
    RedKey = "Red Door",
    OrangeKey = "Orange Door",
    YellowKey = "Yellow Door / Safe",
    PurpleKey = "Purple Door / Safe",
    WhiteKey = "Exit / White Lock",
    Wrench = "Power / Wrench Panel",
    Hammer = "Boards / Hammer Event",
    KeyCode = "Number Lock",
    BlueKeycard = "Blue Keycard Reader",
    RedKeycard = "Red Keycard Reader",
    OrangeKeycard = "Orange Keycard Reader",
    GreenKeycard = "Green Keycard Reader",
    RedGear = "Gear Mechanism",
    GreenGear = "Gear Mechanism",
    WhiteGear = "Sewer Control",
    RedEgg = "Egg Display",
    GreenEgg = "Egg Display",
    EmptyVial = "Vial Station",
    GreenVial = "Vial Station",
    PurpleVial = "Vial Station",
    Coin = "Coin Machine",
    Mallet = "High Striker",
    WaterGun = "Carnival Target",
    Mirror = "Vault / Mirror Event",
    TankBullet = "Tank",
    Gas = "Tank / Generator",
    Screwdriver = "Screwdriver Panel",
    Mop = "Mop Event",
    Blowtorch = "Blowtorch Event",
    Ladder = "Ladder Event",
    Rope = "Rope Event",
    GrapplingHook = "Grappling Hook Event",
    Battery = "Battery Slot",
    RemoteControl = "Remote Screen",
    Candle = "Candle Event",
    TNT = "TNT Event",
    Dynamite = "Dynamite Event",
    Pipe = "Pipe Event",
    WoodenSword = "Sword Event",
}

function idFromText(value)
    local exact = aliases[token(value)]
    if exact then return exact end
    local compact = token(value)
    for alias, id in pairs(aliases) do
        if #alias >= 4 and compact:find(alias, 1, true) then return id end
    end
end

function belongsToItem(instance)
    local current = instance
    while current and current ~= workspace do
        if items[current] then return true end
        current = current.Parent
    end
    return false
end

freeInteractionWords = {
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
    "cannon",
    "artillery",
    "screen",
    "crane",
    "pump",
    "wheel",
}

function interactionHost(interactive)
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

function hostRequiresItem(host)
    if not host then return false end
    for _, descendant in ipairs(host:GetDescendants()) do
        if descendant:IsA("StringValue") and idFromText(descendant.Value) then
            return true
        end
    end
    return false
end

function freeInteractionName(interactive)
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

