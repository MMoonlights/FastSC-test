Solver = {}

function Solver.isFreeProgressInteraction(interactive)
    if not interactive or not interactive.Parent then return false end
    if itemObjectFrom(interactive) or belongsToItem(interactive) then return false end
    local host = interactionHost(interactive)
    if not host or hostRequiresItem(host) then return false end
    if playerCharacterAncestor(host) or underPiggyFolder(host) then return false end

    local name = freeInteractionName(interactive)
    if name:find("exit", 1, true)
        or name:find("escape", 1, true)
        or name:find("final", 1, true)
        or name:find("quest", 1, true)
        or name:find("secret", 1, true)
        or name:find("hidden", 1, true)
        or name:find("insolence", 1, true) then
        return false
    end

    local mapName = currentMapName()
    if mapName == "Lab" and (name:find("symbol", 1, true)
        or name:find("keypad", 1, true)
        or name:find("terminal", 1, true)) then
        return false
    end
    if mapName == "Camp" and name:find("terminal", 1, true) then
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
    if not part then return false end
    local cooldown = freeInteractionCooldowns[interactive]
    return not cooldown or cooldown <= os.clock()
end

function Solver.runFreeInteractionStep()
    local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local best
    local bestPart
    local bestDistance = math.huge

    for interactive in pairs(interactives) do
        if Solver.isFreeProgressInteraction(interactive) then
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

    local before = progressFingerprint()
    beginAutomationMove(bestPart.CFrame + bestPart.CFrame.LookVector * -2 + Vector3.new(0, 1.5, 0))
    task.wait(0.025)
    local host = interactionHost(best)
    local solved = solveCodePanel(host)
    if not solved then
        if best:IsA("ClickDetector") and fireclickdetector then
            pcall(fireclickdetector, best)
        elseif best:IsA("ProximityPrompt") and fireproximityprompt then
            pcall(fireproximityprompt, best)
        end
    end
    task.wait(0.06)
    local progressed = solved or progressFingerprint() ~= before
    freeInteractionCooldowns[best] = os.clock() + (progressed and 0.18 or 2.5)
    endAutomationMove()
    return true
end

function Solver.targetFromRequirement(value)
    local host = requirementHost(value)
    if host and getPart(host) then return host end

    local current = value and value.Parent
    local fallback
    for _ = 1, 7 do
        if not current or current == workspace then break end
        if items[current] then return nil end
        if current:IsA("Model") or current:IsA("BasePart") then
            local part = getPart(current)
            if part then
                fallback = fallback or current
                local required = current:FindFirstChild("ToolRequired")
                if required and required:IsA("StringValue") then return current end
            end
        end
        current = current.Parent
    end
    return fallback
end

function Solver.readableTargetName(id, target)
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

findItemById = function(id)
    local bucket = itemsById[id]
    if not bucket then return nil, math.huge end
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
        elseif not isWorldItem(item) then
            bucket[item] = nil
            items[item] = nil
        end
    end
    if next(bucket) == nil then itemsById[id] = nil end
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

Synth = {}
syntheticCompleted = {}

function Synth.syntheticTarget(id)
    local map = currentMapModel()
    if not map then return nil end

    local best
    local bestScore = -math.huge
    for _, object in ipairs(map:GetDescendants()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            local part = getPart(object)
            if part then
                local text = string.lower(object.Name)
                local score = 0
                if text:find("gear", 1, true) then score += 12 end
                if text:find("well", 1, true) then score += 10 end
                if text:find("machine", 1, true) then score += 4 end
                if text:find("event", 1, true) then score += 3 end
                if text:find("water", 1, true) then score += 3 end
                if requirementEventMesh(object) then score += 8 end
                if object:FindFirstChildWhichIsA("ClickDetector", true)
                    or object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or object:FindFirstChildWhichIsA("TouchTransmitter", true) then
                    score += 4
                end

                local required = object:FindFirstChild("ToolRequired", true)
                if required and required:IsA("StringValue") then
                    local requiredId = idFromText(required.Value)
                    if requiredId == id then score += 20 end
                end

                if score > bestScore then
                    best = object
                    bestScore = score
                end
            end
        end
    end

    return bestScore >= 6 and best or nil
end

function Synth.syntheticObjective(id, parentId)
    if syntheticCompleted[id] then return nil end

    local owned = findOwnedById and findOwnedById(id)
    local worldItem = findItemById and findItemById(id)

    local target = Synth.syntheticTarget(id)
    local part = target and getPart(target)
    if not target or not part then
        -- Still expose the prerequisite so the solver collects it first.
        local item = worldItem
        local itemPart = item and getPart(item)
        return {
            Id = id,
            ItemName = displayNames[id] or id,
            Target = item or currentMapModel(),
            Part = itemPart or (currentMapModel() and getPart(currentMapModel())),
            TargetName = owned or worldItem and "Gear mechanism" or "Waiting for gear / mechanism",
            Requirement = nil,
            Synthetic = true,
            ParentId = parentId,
            NeedsTarget = true,
        }
    end

    return {
        Id = id,
        ItemName = displayNames[id] or id,
        Target = target,
        Part = part,
        TargetName = Solver.readableTargetName(id, target),
        Requirement = nil,
        Synthetic = true,
        ParentId = parentId,
    }
end

function Synth.reconcileSyntheticState()
    local mapName = currentMapName()
    if mapName ~= "House" then return end

    -- In House the White Key is the output of the well/gear mechanism.
    -- Once it exists as a real world pickup, both gear stages are complete,
    -- regardless of whether Piggy removed/renamed the individual gear events.
    local whiteKey = findItemById and findItemById("WhiteKey")
    if whiteKey and isWorldItem(whiteKey) then
        syntheticCompleted.RedGear = true
        syntheticCompleted.GreenGear = true
        return
    end

    -- If a gear no longer exists anywhere and is no longer owned after it
    -- was previously available, treat its placement as complete.
    for _, id in ipairs({"RedGear", "GreenGear"}) do
        if not syntheticCompleted[id] then
            local owned = findOwnedById and findOwnedById(id)
            local world = findItemById and findItemById(id)
            if not owned and not world and not requirementExists(id) then
                -- Do not mark it from absence alone at map start; only the
                -- WhiteKey output above is authoritative.
            end
        end
    end
end

function Solver.collectObjectives()
    Synth.reconcileSyntheticState()
    local result = {}
    local seen = {}
    for value in pairs(requirements) do
        if value.Parent and isObjectiveRequirement(value) and not belongsToItem(value) then
            local id = idFromText(value.Value)
            if id then
                local target = Solver.targetFromRequirement(value)
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
                            TargetName = Solver.readableTargetName(id, target),
                            Requirement = value,
                        }
                    end
                end
            end
        end
    end

    local profile = mapProfiles[currentMapName()]
    if profile and profile.Synthetic then
        local snapshot = {}
        for _, objective in ipairs(result) do snapshot[#snapshot + 1] = objective end

        for _, parent in ipairs(snapshot) do
            local chain = profile.Synthetic[parent.Id]
            if chain then
                for _, dependency in ipairs(chain) do
                    if not syntheticCompleted[dependency] then
                        local alreadyActive = false
                        for _, existing in ipairs(result) do
                            if existing.Id == dependency then
                                alreadyActive = true
                                break
                            end
                        end
                        if not alreadyActive then
                            local synthetic = Synth.syntheticObjective(dependency, parent.Id)
                            if synthetic and synthetic.Part then
                                result[#result + 1] = synthetic
                            end
                        end
                    end
                end
            end
        end
    end

    return result
end

blockerPriority = {
    Crowbar = 1,
    Hammer = 2,
    Scissors = 3,
    Screwdriver = 4,
    Wrench = 5,
    Mop = 6,
    Blowtorch = 7,
    FireExtinguisher = 8,
    Axe = 9,
    Shovel = 10,
    Dynamite = 11,
    TNT = 12,
    Battery = 13,
    Batteries = 13,
    RedWire = 14,
    GreenWire = 14,
    BlueWire = 14,
    YellowWire = 14,
    Plank = 20,
    RedGear = 21,
    GreenGear = 21,
    WhiteGear = 21,
    RedEgg = 21,
    GreenEgg = 21,
    RemoteControl = 22,
    KeyCode = 30,
}

function Solver.isLockItem(id)
    local value = tostring(id or "")
    return value:find("Key", 1, true) ~= nil
        or value:find("Keycard", 1, true) ~= nil
        or id == "ElevatorKey"
end

function Solver.objectiveDistance(a, b)
    if not a or not b or not a.Part or not b.Part then return math.huge end
    return (a.Part.Position - b.Part.Position).Magnitude
end

function Solver.blockingObjectiveFor(objective, objectives)
    local profile = mapProfiles[currentMapName()]
    local synthetic = profile and profile.Synthetic and profile.Synthetic[objective.Id]
    if synthetic then
        for _, dependency in ipairs(synthetic) do
            if not syntheticCompleted[dependency] then
                for _, candidate in ipairs(objectives) do
                    if candidate ~= objective and candidate.Id == dependency then
                        return candidate
                    end
                end
            end
        end
    end

    local dependencies = profile and profile.Depends and profile.Depends[objective.Id]
    if dependencies then
        for _, dependency in ipairs(dependencies) do
            for _, candidate in ipairs(objectives) do
                if candidate ~= objective and candidate.Id == dependency then
                    return candidate
                end
            end
        end
    end

    if not Solver.isLockItem(objective.Id) then return nil end

    local best
    local bestPriority = math.huge
    for _, candidate in ipairs(objectives) do
        if candidate ~= objective then
            local priority = blockerPriority[candidate.Id]
            if priority and Solver.objectiveDistance(objective, candidate) <= 18 then
                if objectiveStillActive == nil or Solver.objectiveStillActive(candidate) then
                    if priority < bestPriority then
                        best = candidate
                        bestPriority = priority
                    end
                end
            end
        end
    end
    return best
end

function Solver.profilePriority(id)
    local profile = mapProfiles[currentMapName()]
    local priority = profile and profile.Priority and profile.Priority[id]
    return priority or blockerPriority[id] or 100
end

function Solver.chooseObjective(objectives)
    local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best
    local bestScore = math.huge
    for _, objective in ipairs(objectives) do
        local blocker = Solver.blockingObjectiveFor(objective, objectives)
        local owned = findOwnedById(objective.Id)
        local worldItem, worldDistance = findItemById(objective.Id)
        local score
        if blocker then
            score = 1000000 + Solver.profilePriority(blocker.Id)
        elseif owned then
            score = Solver.profilePriority(objective.Id)
        elseif worldItem then
            score = 200 + Solver.profilePriority(objective.Id) + (worldDistance or 0) * 0.01
        else
            score = 100000
            if root and objective.Part then
                score = score + (objective.Part.Position - root.Position).Magnitude
            end
            score = score + Solver.profilePriority(objective.Id)
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

function Solver.objectiveText(objective)
    if not objective then return "Current objective: none detected" end
    return "Current objective: " .. objective.ItemName .. " -> " .. objective.TargetName
end

function Solver.remainingText(objectives)
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

function Solver.refreshObjectiveState()
    local ok, objectives, objective = pcall(function()
        local found = Solver.collectObjectives()
        local selected = Solver.chooseObjective(found)
        return found, selected
    end)

    if not ok then
        currentObjective = nil
        if objectiveMapLabel then objectiveMapLabel:Set("Map: " .. currentMapName() .. " | scanner recovered") end
        if objectiveCurrentLabel then objectiveCurrentLabel:Set("Current objective: scanner error") end
        if objectiveNeededLabel then objectiveNeededLabel:Set("Items needed: retrying automatically") end
        if objectiveStatusLabel then objectiveStatusLabel:Set("Status: " .. tostring(objectives)) end
        return {}, nil
    end

    currentObjective = objective
    if objectiveMapLabel then
        objectiveMapLabel:Set("Map: " .. currentMapName()
            .. " | active objectives: " .. tostring(#objectives))
    end
    if objectiveCurrentLabel then objectiveCurrentLabel:Set(Solver.objectiveText(currentObjective)) end
    if objectiveNeededLabel then objectiveNeededLabel:Set(Solver.remainingText(objectives)) end
    if objectiveStatusLabel then
        if not currentObjective then
            local profile = mapProfiles[currentMapName()]
            if profile and profile.Puzzle then
                objectiveStatusLabel:Set("Status: item objectives clear, puzzle: " .. profile.Puzzle)
            else
                objectiveStatusLabel:Set("Status: objectives clear, checking mechanics / escape")
            end
        elseif findOwnedById(currentObjective.Id) then
            objectiveStatusLabel:Set("Status: item owned, apply it to " .. currentObjective.TargetName)
        elseif findItemById(currentObjective.Id) then
            objectiveStatusLabel:Set("Status: collect " .. currentObjective.ItemName .. " | pickup: " .. lastPickupStatus)
        else
            objectiveStatusLabel:Set("Status: waiting for " .. currentObjective.ItemName .. " to unlock / spawn | pickup: " .. lastPickupStatus)
        end
    end
    return objectives, currentObjective
end

function Solver.equipRequired(id)
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
        task.wait(0.04)
        local equipped = character:FindFirstChildWhichIsA("Tool")
        if equipped and (itemId(equipped) == id or aliases[token(equipped.Name)] == id) then
            object = equipped
        end
    end
    return object
end

function Solver.objectiveStillActive(objective)
    local requirement = objective and objective.Requirement
    local map = currentMapModel()
    return requirement
        and requirement.Parent
        and map
        and requirement:IsDescendantOf(map)
        and idFromText(requirement.Value) == objective.Id
end

function Solver.objectiveEventParts(objective)
    local result = {}
    local seen = {}

    local function add(part)
        if not part or not part:IsA("BasePart") or seen[part] then return end
        seen[part] = true
        result[#result + 1] = part
    end

    local requirement = objective and objective.Requirement
    if requirement and requirement.Parent then
        if requirement.Parent:IsA("BasePart") then
            add(requirement.Parent)
        else
            add(getPart(requirement.Parent))
        end
    end

    local target = objective and objective.Target
    if target then
        if target:IsA("BasePart") then add(target) end
        for _, descendant in ipairs(target:GetDescendants()) do
            if descendant:IsA("BasePart") then
                local hasInteraction = descendant:FindFirstChildWhichIsA("ClickDetector", true)
                    or descendant:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or descendant:FindFirstChildWhichIsA("TouchTransmitter", true)
                local required = descendant:FindFirstChild("ToolRequired")
                if hasInteraction or required or requirementEventMesh(descendant) then
                    add(descendant)
                end
            end
        end
        add(getPart(target))

        if objective.Synthetic then
            local parent = target.Parent
            if parent and parent ~= workspace then
                for _, sibling in ipairs(parent:GetChildren()) do
                    if sibling:IsA("BasePart") then
                        local hasInteraction = sibling:FindFirstChildWhichIsA("ClickDetector", true)
                            or sibling:FindFirstChildWhichIsA("ProximityPrompt", true)
                            or sibling:FindFirstChildWhichIsA("TouchTransmitter", true)
                        if hasInteraction or requirementEventMesh(sibling) then add(sibling) end
                    elseif sibling:IsA("Model") then
                        for _, part in ipairs(sibling:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local hasInteraction = part:FindFirstChildWhichIsA("ClickDetector", true)
                                    or part:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    or part:FindFirstChildWhichIsA("TouchTransmitter", true)
                                if hasInteraction or requirementEventMesh(part) then add(part) end
                            end
                        end
                    end
                end
            end
        end
    end

    return result
end

function Solver.objectiveNeedsActivation(objective)
    if not objective then return false end
    if objective.Synthetic then
        return not syntheticCompleted[objective.Id]
    end
    return Solver.objectiveStillActive(objective)
end

function Solver.ensureEquipped(id, timeout)
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then return nil end

    local deadline = os.clock() + (timeout or 0.65)
    repeat
        local tool = findOwnedById(id)
        if tool and tool.Parent == character then return tool end

        if tool and tool.Parent then
            pcall(function()
                humanoid:EquipTool(tool)
            end)
        end

        task.wait(0.04)
        tool = findOwnedById(id)
        if tool and tool.Parent == character then return tool end
    until os.clock() >= deadline or not autoComplete

    return nil
end

function Solver.activateObjective(objective)
    if not objective or not objective.Target or not objective.Target.Parent then return false end

    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then return false end

    local tool = Solver.ensureEquipped(objective.Id, 0.7)
    if not tool or tool.Parent ~= character then
        lastPickupStatus = "failed to equip " .. (displayNames[objective.Id] or tostring(objective.Id))
        return false
    end

    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
    local eventParts = Solver.objectiveEventParts(objective)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart and #eventParts > 1 then
        table.sort(eventParts, function(a, b)
            return (a.Position - rootPart.Position).Magnitude < (b.Position - rootPart.Position).Magnitude
        end)
    end
    local before = progressFingerprint()
    local targetBefore = objective.Target and tostring(objective.Target:GetFullName()) or ""
    local targetPartBefore = objective.Part and objective.Part.Parent and table.concat({
        tostring(objective.Part.CFrame),
        tostring(objective.Part.Transparency),
        tostring(objective.Part.CanCollide),
    }, "|") or ""
    local toolParent = tool and tool.Parent
    if #eventParts == 0 then return false end

    local ok = pcall(function()
        for _ = 1, 2 do
            if not autoComplete or not Solver.objectiveNeedsActivation(objective) then break end

            for _, eventPart in ipairs(eventParts) do
                if not autoComplete then break end
                if not Solver.objectiveNeedsActivation(objective) then break end
                if not eventPart.Parent then continue end

                tool = Solver.ensureEquipped(objective.Id, 0.35)
                if not tool or tool.Parent ~= character then
                    lastPickupStatus = "tool unequipped before interaction"
                    break
                end
                handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)

                beginAutomationMove(eventPart.CFrame + eventPart.CFrame.LookVector * -1.5 + Vector3.new(0, 1, 0))
                task.wait(0.04)
                automationDeadline = os.clock() + 2

                local touchPart = handle
                if not touchPart or not touchPart.Parent then
                    touchPart = character:FindFirstChild("HumanoidRootPart")
                end
                if touchPart and firetouchinterest then
                    pcall(function()
                        firetouchinterest(touchPart, eventPart, 0)
                        task.wait(0.02)
                        firetouchinterest(touchPart, eventPart, 1)
                    end)
                end

                if tool.Parent == character then
                    pcall(function() tool:Activate() end)
                end

                local click = eventPart:FindFirstChildWhichIsA("ClickDetector", true)
                local prompt = eventPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                if click and fireclickdetector then pcall(fireclickdetector, click) end
                if prompt and fireproximityprompt then pcall(fireproximityprompt, prompt) end

                local interactionBefore = before
                local waitDeadline = os.clock() + 0.28
                repeat
                    task.wait(0.025)
                    if not Solver.objectiveNeedsActivation(objective)
                        or not findOwnedById(objective.Id)
                        or progressFingerprint() ~= interactionBefore then
                        break
                    end
                until os.clock() >= waitDeadline

                if not Solver.objectiveNeedsActivation(objective)
                    or not findOwnedById(objective.Id)
                    or progressFingerprint() ~= interactionBefore then
                    break
                end
            end

            if not Solver.objectiveNeedsActivation(objective)
                or not findOwnedById(objective.Id)
                or progressFingerprint() ~= before then
                break
            end
        end
    end)

    task.wait(0.05)
    local completed = objective.Synthetic and false or not Solver.objectiveStillActive(objective)
    local toolConsumed = tool and (not tool.Parent or tool.Parent ~= toolParent)
        and not findOwnedById(objective.Id)

    local targetChanged = false
    if objective.Synthetic then
        if not objective.Target or not objective.Target.Parent then
            targetChanged = true
        elseif objective.Part and objective.Part.Parent then
            local now = table.concat({
                tostring(objective.Part.CFrame),
                tostring(objective.Part.Transparency),
                tostring(objective.Part.CanCollide),
            }, "|")
            targetChanged = now ~= targetPartBefore
        elseif tostring(objective.Target:GetFullName()) ~= targetBefore then
            targetChanged = true
        end
    end

    local globalProgress = progressFingerprint() ~= before
    local progressed = completed or toolConsumed
        or (objective.Synthetic and targetChanged)
        or (not objective.Synthetic and globalProgress)

    if objective.Synthetic and (toolConsumed or targetChanged) then
        syntheticCompleted[objective.Id] = true
        completed = true
        itemUiDirty = true
    end

    if currentMapName() == "House" then
        local whiteKey = findItemById and findItemById("WhiteKey")
        if whiteKey and isWorldItem(whiteKey) then
            syntheticCompleted.RedGear = true
            syntheticCompleted.GreenGear = true
            completed = objective.Synthetic and true or completed
            progressed = true
            itemUiDirty = true
        end
    end

    endAutomationMove()
    return ok and completed, ok and progressed
end

Round = {}

function Round.isEscapeRelatedPart(part)
    if not part or not part.Parent then return false end
    if escapeTargets[part] then return true end

    local current = part
    for _ = 1, 4 do
        if not current or current == workspace then break end
        local lower = string.lower(current.Name)
        if lower:find("escape", 1, true)
            or lower:find("exit", 1, true)
            or lower:find("final", 1, true) then
            return true
        end
        current = current.Parent
    end

    return false
end

function Round.nearEscapeTrigger(distanceLimit)
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local limit = distanceLimit or 12
    for part in pairs(escapeTargets) do
        if part.Parent and (part.Position - root.Position).Magnitude <= limit then
            return true, part
        end
    end

    return false
end

function Round.finishRun(reason)
    if runFinished then return end
    runFinished = true
    finishedMapInstance = currentMapModel()
    autoCompleteBusy = false
    pickupBusy = false
    releaseAutomation()
    clearKind("Objective")
    objectiveVisualTarget = nil
    currentObjective = nil
    escapeTouchOverride = false
    setCharacterTouch(true)

    if objectiveCurrentLabel then objectiveCurrentLabel:Set("Current objective: waiting for next round") end
    if objectiveNeededLabel then objectiveNeededLabel:Set("Items needed: none") end
    if objectiveStatusLabel then objectiveStatusLabel:Set("Status: round completed" .. (reason and " | " .. reason or "")) end
end

function Round.exitRequirementActive()
    for value in pairs(requirements) do
        if value.Parent and isObjectiveRequirement(value) then
            local id = idFromText(value.Value)
            if id == "WhiteKey" or id == "KeyCode" or id == "BlueKeycard" then
                local host = requirementHost(value)
                local part = host and getPart(host)
                if part and Round.isEscapeRelatedPart(part) then return true end
            end
        end
    end
    return false
end

function Round.autoEscapeStep()
    if runFinished then return false end
    local now = os.clock()
    if now - lastEscapeAttempt < 0.75 then return false end
    lastEscapeAttempt = now
    escapeAttempts += 1

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

    if finishedEscapePart and best == finishedEscapePart then
        return false
    end

    local beforePosition = best.Position
    local beforeTransparency = best.Transparency
    local beforeCollision = best.CanCollide
    local beforeRequirement = Round.exitRequirementActive()

    escapeTouchOverride = true
    setCharacterTouch(false)

    beginAutomationMove(best.CFrame + Vector3.new(0, 2, 0))
    task.wait(0.025)

    local character = localPlayer.Character
    if character then
        for _, bodyPart in ipairs(character:GetDescendants()) do
            if bodyPart:IsA("BasePart") then
                scope:Restore(bodyPart, "CanTouch")
            end
        end
    end

    if firetouchinterest then
        for _ = 1, 3 do
            Common.Touch(root, best)
            task.wait(0.04)
        end
    end

    local click = best:FindFirstChildWhichIsA("ClickDetector", true)
    local prompt = best:FindFirstChildWhichIsA("ProximityPrompt", true)
    if click and fireclickdetector then pcall(fireclickdetector, click) end
    if prompt and fireproximityprompt then pcall(fireproximityprompt, prompt) end

    task.wait(0.3)
    endAutomationMove()
    escapeTouchOverride = false

    local exitStillLocked = Round.exitRequirementActive()
    local targetChanged = not best.Parent
        or best.Position ~= beforePosition
        or best.Transparency ~= beforeTransparency
        or best.CanCollide ~= beforeCollision
    local requirementCleared = beforeRequirement and not exitStillLocked

    if targetChanged or requirementCleared then
        finishedEscapePart = best
        Round.finishRun("exit reached")
        return true
    end

    -- Piggy can leave stale ToolRequired/door parts around after the server
    -- has accepted the escape. Never hammer the same door indefinitely.
    if escapeAttempts >= 2 then
        finishedEscapePart = best
        Round.finishRun("exit interaction accepted")
        return true
    end

    return true
end

function Round.resetRoundAutomation()
    runFinished = false
    finishedMapInstance = nil
    finishedEscapePart = nil
    escapeAttempts = 0
    lastEscapeAttempt = 0
    syntheticCompleted = {}
    objectiveFailures = setmetatable({}, {__mode = "k"})
    objectiveCooldowns = setmetatable({}, {__mode = "k"})
    freeInteractionCooldowns = setmetatable({}, {__mode = "k"})
    solvedPuzzles = {}
    currentObjective = nil
    objectiveVisualTarget = nil
    itemUiDirty = true
    clearKind("Objective")
    releaseAutomation()
end

function Round.updateRoundState()
    if not runFinished then return end
    local map = currentMapModel()

    -- Stay completely idle while the completed map is still the active instance.
    if map and map == finishedMapInstance and map.Parent then return end

    -- A different map instance means a fresh round. Keep Full Run enabled.
    if map and map ~= finishedMapInstance then
        Round.resetRoundAutomation()
    end
end

function Round.autoCompleteStep()
    if not autoComplete then return end
    if runFinished then
        Round.updateRoundState()
        return
    end
    if autoCompleteBusy then return end
    autoCompleteBusy = true

    local ok, errorMessage = pcall(function()
        if currentMapName() == "House" then
            local ownedWhite = findOwnedById and findOwnedById("WhiteKey")
            local worldWhite = findItemById and findItemById("WhiteKey")
            if worldWhite and not ownedWhite then
                syntheticCompleted.RedGear = true
                syntheticCompleted.GreenGear = true
                lastPickupStatus = "White Key spawned: collecting"
                local picked = grabItem(worldWhite, false, "WhiteKey")
                if picked then
                    lastPickupStatus = "White Key collected"
                end
                Solver.refreshObjectiveState()
                return
            elseif ownedWhite then
                syntheticCompleted.RedGear = true
                syntheticCompleted.GreenGear = true
            end
        end

        local objectives, objective = Solver.refreshObjectiveState()

        local profile = mapProfiles[currentMapName()]
        local puzzleBefore = profile and profile.PuzzleBefore
        local puzzleIsNext = objective and puzzleBefore and table.find(puzzleBefore, objective.Id) ~= nil

        if #objectives == 0 or puzzleIsNext then
            if solveSpecialPuzzle() then
                task.wait(0.03)
                Solver.refreshObjectiveState()
                return
            end
            if #objectives == 0 then
                if Solver.runFreeInteractionStep() then
                    task.wait(0.03)
                    Solver.refreshObjectiveState()
                else
                    Round.autoEscapeStep()
                end
                return
            end
        end

        if not objective then return end

        local required = Solver.equipRequired(objective.Id)
        if required then
            if objective.Synthetic and objective.NeedsTarget then
                local target = Synth.syntheticTarget(objective.Id)
                if target and getPart(target) then
                    objective.Target = target
                    objective.Part = getPart(target)
                    objective.TargetName = Solver.readableTargetName(objective.Id, target)
                    objective.NeedsTarget = nil
                end
            end

            local completed, progressed = Solver.activateObjective(objective)
            if objective.Requirement then
                if progressed then
                    objectiveFailures[objective.Requirement] = nil
                    objectiveCooldowns[objective.Requirement] = os.clock() + (completed and 0.08 or 0.12)
                else
                    local failures = math.min((objectiveFailures[objective.Requirement] or 0) + 1, 6)
                    objectiveFailures[objective.Requirement] = failures
                    objectiveCooldowns[objective.Requirement] = os.clock() + math.min(0.35 * (2 ^ (failures - 1)), 4)
                end
            end
            if not completed and not progressed then
                if not solveSpecialPuzzle() then
                    Solver.runFreeInteractionStep()
                end
            end
        else
            if not solveSpecialPuzzle() then
                Solver.runFreeInteractionStep()
            end
        end

        Solver.refreshObjectiveState()
    end)

    releaseAutomation()

    if not ok then
        lastPickupStatus = "solver recovered: " .. tostring(errorMessage)
        if objectiveStatusLabel then
            objectiveStatusLabel:Set("Status: solver recovered from an error, retrying")
        end
    end
end

godParts = {
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

