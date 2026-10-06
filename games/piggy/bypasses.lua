function setCharacterTouch(enabled)
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

function disableEnemyTouchTransmitters(model)
    if not model or not model.Parent then return end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") and descendant.Parent and not disabledEnemyTouches[descendant] then
            local parent = descendant.Parent
            local ok = pcall(function() descendant.Parent = nil end)
            if ok then disabledEnemyTouches[descendant] = parent end
        end
    end
end

function restoreEnemyTouchTransmitters()
    for transmitter, parent in pairs(disabledEnemyTouches) do
        if transmitter and parent and parent.Parent then
            pcall(function() transmitter.Parent = parent end)
        end
        disabledEnemyTouches[transmitter] = nil
    end
end

function applyGodMode()
    if not godMode then return end

    local allowEscapeTouch = escapeTouchOverride or Round.nearEscapeTrigger(12)
    if allowEscapeTouch then
        setCharacterTouch(false)
    else
        setCharacterTouch(true)
    end

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

Actions = {}

function Actions.applyNoclip()
    local character = localPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then scope:Set(part, "CanCollide", false) end
    end
end

function Actions.restoreNoclip()
    local character = localPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then scope:Restore(part, "CanCollide") end
    end
end

function Actions.applyTrapBypass(value)
    for trap in pairs(traps) do
        if trap.Parent then
            if Round.isEscapeRelatedPart(trap) then
                scope:Restore(trap, "CanTouch")
            elseif value then
                scope:Set(trap, "CanTouch", false)
            else
                scope:Restore(trap, "CanTouch")
            end
        end
    end
end

function Actions.applyDoors(value)
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

function Actions.applyBotFreeze(value)
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

