scope = ctx.Scope
Common = ctx.Common
mode = ctx.Mode or "Legit"
Players = game:GetService("Players")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
Lighting = game:GetService("Lighting")
localPlayer = Players.LocalPlayer
items = {}
interactives = {}
traps = {}
doors = {}
bots = {}
visuals = {}
requirements = {}
escapeTargets = {}
escapeTouchOverride = false
selectedItem = nil
infiniteJump = false
itemEsp = false
playerEsp = false
piggyEsp = false
trapEsp = false
speedEnabled = false
speedValue = mode == "Rage" and 60 or 24
jumpEnabled = false
jumpValue = mode == "Rage" and 90 or 60
noclip = false
fullbright = false
godMode = false
trapBypass = false
doorsRemoved = false
botsFrozen = false
autoGrab = false
autoComplete = false
autoInteract = false
completeCursor = 0
removeVisual = nil
refreshVisuals = nil
objectiveCurrentLabel = nil
objectiveNeededLabel = nil
objectiveStatusLabel = nil
objectivePuzzleLabel = nil
currentObjective = nil
findOwnedById = nil
findItemById = nil
lastPickupStatus = "idle"
objectiveEsp = false
objectiveVisualTarget = nil
autoCompleteBusy = false
runFinished = false
finishedMapInstance = nil
finishedEscapePart = nil
escapeAttempts = 0
lastEscapeAttempt = 0
pickupBusy = false
pickupRetryAt = {}
pickupFailuresById = {}
objectiveCooldowns = setmetatable({}, {__mode = "k"})
objectiveFailures = setmetatable({}, {__mode = "k"})
disabledEnemyTouches = setmetatable({}, {__mode = "k"})
freeInteractionCooldowns = setmetatable({}, {__mode = "k"})
objectiveMapLabel = nil
itemsById = {}
itemIndexedId = setmetatable({}, {__mode = "k"})
trackedItemSignals = setmetatable({}, {__mode = "k"})
requirementCounts = {}
requirementIdByValue = setmetatable({}, {__mode = "k"})
trackedRequirements = setmetatable({}, {__mode = "k"})
itemDropdown = nil
itemDropdownSignature = ""
itemUiDirty = true

bookName = "Piggy universe"
if game.PlaceId == 4623386862 then
    bookName = "Book 1"
elseif game.PlaceId == 5661005779 then
    bookName = "Book 2"
end

mapNames = {
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
    "DistortedHoliday",
    "Distorted Holiday",
    "HolidaySpirit",
    "Holiday Spirit",
    "The Hunt",
}

dynamicMapCache = nil

function currentMapModel()
    for _, name in ipairs(mapNames) do
        local map = workspace:FindFirstChild(name)
        if map then return map, name end
    end
    for _, child in ipairs(workspace:GetChildren()) do
        local lower = string.lower(child.Name)
        for _, name in ipairs(mapNames) do
            if lower == string.lower(name) then
                dynamicMapCache = child
                return child, name
            end
        end
    end

    if dynamicMapCache and dynamicMapCache.Parent == workspace then
        return dynamicMapCache, dynamicMapCache.Name
    end

    local best
    local bestScore = 0
    for _, child in ipairs(workspace:GetChildren()) do
        if (child:IsA("Model") or child:IsA("Folder"))
            and not Players:GetPlayerFromCharacter(child)
            and child.Name ~= "PiggyNPC" then
            local score = 0
            if child:FindFirstChild("Events") or child:FindFirstChild("events") then score += 8 end
            if child:FindFirstChild("ItemFolder") or child:FindFirstChild("ItemFolder1")
                or child:FindFirstChild("Items") then score += 5 end
            if child:FindFirstChild("ToolRequired", true) then score += 6 end
            if child:FindFirstChild("ItemPickupScript", true)
                or child:FindFirstChild("NewItemPickupScript", true) then score += 5 end
            if score > bestScore then
                best = child
                bestScore = score
            end
        end
    end
    if best and bestScore >= 6 then
        dynamicMapCache = best
        return best, best.Name
    end
end

function currentMapName()
    local _, name = currentMapModel()
    return name or "Unknown"
end

function getPart(object)
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

function playerCharacterAncestor(instance)
    local current = instance
    while current and current ~= workspace do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            return current
        end
        current = current.Parent
    end
end

function isWorldItem(item)
    if not item or not item.Parent then return false end
    if playerCharacterAncestor(item) then return false end
    local backpack = localPlayer:FindFirstChild("Backpack")
    if backpack and item:IsDescendantOf(backpack) then return false end
    return item:IsDescendantOf(workspace)
end

automationActive = false
automationTarget = nil
automationDeadline = 0
automationGeneration = 0
automationLastCorrection = 0
automationLastMoveAt = 0
automationLastTarget = nil
automationHold = false
automationHoldTarget = nil

function automationPhysics(character, root, humanoid)
    if not root then return end

    -- Full Run must never Anchor the character. Piggy's pickup handling can
    -- reject/ignore interactions from an anchored character even when the
    -- detector itself fires. Keep the player suspended with velocity + CFrame
    -- correction instead, like the older working flight controller.
    scope:Set(root, "Anchored", false)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end
end

function setAutomationHold(enabled)
    automationHold = enabled == true

    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if automationHold then
        if root then
            automationHoldTarget = root.CFrame
            automationPhysics(character, root, humanoid)
        end
    else
        automationHoldTarget = nil
        if root then
            scope:Restore(root, "Anchored")
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if humanoid then
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
    end
end

function zeroCharacterVelocity(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function setAutomationCollision(enabled)
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

function beginAutomationMove(target)
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root then return false end

    local now = os.clock()
    local sameTarget = automationLastTarget
        and (automationLastTarget.Position - target.Position).Magnitude < 1.25
        and now - automationLastMoveAt < 0.35

    automationActive = true
    automationTarget = target
    automationHoldTarget = target
    automationDeadline = now + 3

    setAutomationCollision(true)
    automationPhysics(character, root, humanoid)
    if humanoid then scope:Set(humanoid, "AutoRotate", false) end

    if not sameTarget or (root.Position - target.Position).Magnitude > 0.35 then
        zeroCharacterVelocity(character)
        pcall(function() character:PivotTo(target) end)
        root.CFrame = target
        automationLastMoveAt = now
        automationLastTarget = target
    end

    return true
end

function endAutomationMove()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if automationHold and root then
        automationHoldTarget = root.CFrame
    end

    automationTarget = nil
    automationActive = false
    automationDeadline = 0
    zeroCharacterVelocity(character)

    if automationHold then
        automationPhysics(character, root, humanoid)
    elseif root then
        scope:Restore(root, "Anchored")
    end

    if humanoid then
        scope:Restore(humanoid, "AutoRotate")
        if not automationHold then
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
    end

    if not noclip then setAutomationCollision(false) end
end

function releaseAutomation()
    automationGeneration += 1
    autoCompleteBusy = false
    pickupBusy = false
    endAutomationMove()

    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.Jump = false
        scope:Restore(humanoid, "AutoRotate")
    end

    if automationHold then
        if root then
            automationHoldTarget = root.CFrame
            automationPhysics(character, root, humanoid)
        end
    elseif humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end

    if not noclip then setAutomationCollision(false) end
    zeroCharacterVelocity(character)
end

scope:Connect(RunService.PreSimulation, function()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local now = os.clock()

    if automationActive and automationDeadline > 0 and now > automationDeadline then
        -- The solver coroutine owns its busy flags. Only stop this movement hold.
        endAutomationMove()
        return
    end

    if automationHold and root then
        automationPhysics(character, root, humanoid)

        local target = automationTarget or automationHoldTarget
        if target then
            local drift = (root.Position - target.Position).Magnitude
            if drift > 0.18 and now - automationLastCorrection >= 0.03 then
                automationLastCorrection = now
                zeroCharacterVelocity(character)
                pcall(function() character:PivotTo(target) end)
                root.CFrame = target
            end
        else
            automationHoldTarget = root.CFrame
        end
    elseif automationActive and root and automationTarget then
        local drift = (root.Position - automationTarget.Position).Magnitude
        if drift > 1.5 and now - automationLastCorrection >= 0.08 then
            automationLastCorrection = now
            zeroCharacterVelocity(character)
            pcall(function() character:PivotTo(automationTarget) end)
            root.CFrame = automationTarget
        end
    end
end)

function hasAncestorName(instance, word)
    word = string.lower(word)
    local current = instance
    while current and current ~= workspace do
        if string.find(string.lower(current.Name), word, 1, true) then return true end
        current = current.Parent
    end
    return false
end

pickupScriptNames = {
    ItemPickupScript = true,
    NewItemPickupScript = true,
}

function hasPickupScript(container)
    if not container then return false end
    for name in pairs(pickupScriptNames) do
        if container:FindFirstChild(name) then return true end
    end
    return false
end

function genericPickupParent(instance)
    if not instance or instance.Name ~= "Script" or not instance:IsA("Script") then return nil end
    local parent = instance.Parent
    local folder = parent and parent.Parent
    if not parent or not folder or not folder:IsA("Folder") then return nil end
    if parent:FindFirstChildOfClass("Sound") then return nil end

    local hasItemVisual = parent:FindFirstChildWhichIsA("SpecialMesh", true)
        or parent:FindFirstChildWhichIsA("MeshPart", true)
        or parent:FindFirstChildWhichIsA("ParticleEmitter", true)
    local folderName = string.lower(folder.Name)
    local looksLikeItemFolder = folderName:find("item", 1, true)
        or folderName:find("pickup", 1, true)
        or folderName:find("spawn", 1, true)

    if hasItemVisual and looksLikeItemFolder then return parent end
    return nil
end

function itemObjectFrom(instance)
    if pickupScriptNames[instance.Name] and instance.Parent then
        return instance.Parent
    end

    local generic = genericPickupParent(instance)
    if generic then return generic end

    local current = instance
    while current and current ~= workspace do
        if hasPickupScript(current) then return current end
        current = current.Parent
    end
end

itemNameCache = setmetatable({}, {__mode = "k"})

