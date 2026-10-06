function Actions.setupVisualTab(tab)
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

function Actions.setupItemTab(tab)
    tab:CreateSection("Items")
    local names = itemNames()
    itemDropdown = tab:CreateDropdown("Item", names, names[1], function(value)
        selectedItem = value
    end)
    itemDropdownSignature = table.concat(names, "\0")
    selectedItem = names[1]
    tab:CreateButton("Refresh item list", function()
        itemUiDirty = true
        refreshItemDropdown()
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

function Actions.setupObjectiveHelper(tab)
    tab:CreateSection("Objective Helper")
    objectiveMapLabel = tab:CreateLabel("Map: " .. currentMapName())
    objectiveCurrentLabel = tab:CreateLabel("Current objective: scanning...")
    objectiveNeededLabel = tab:CreateLabel("Items needed: scanning...")
    objectiveStatusLabel = tab:CreateLabel("Status: scanning map...")
    objectivePuzzleLabel = tab:CreateLabel("Puzzle: " .. tostring(getPuzzleStatus and getPuzzleStatus() or "idle"))
    tab:CreateToggle("Objective ESP", false, function(value)
        objectiveEsp = value
        if not value then
            clearKind("Objective")
            objectiveVisualTarget = nil
        end
    end)
    tab:CreateButton("Refresh objectives", Solver.refreshObjectiveState)
    tab:CreateButton("Solve map puzzle now", function()
        releaseAutomation()
        local solved = solveSpecialPuzzle(true)
        if objectivePuzzleLabel and getPuzzleStatus then
            objectivePuzzleLabel:Set("Puzzle: " .. tostring(getPuzzleStatus()))
        end
        if solved then Solver.refreshObjectiveState() end
    end)
    tab:CreateButton("Teleport to required item", function()
        local _, objective = Solver.refreshObjectiveState()
        if not objective then return end
        local item = findItemById(objective.Id)
        if item then teleportItem(item) end
    end)
    tab:CreateButton("Teleport to objective target", function()
        local _, objective = Solver.refreshObjectiveState()
        local part = objective and getPart(objective.Target)
        if part then Common.Root().CFrame = part.CFrame + Vector3.new(0, 2.5, 0) end
    end)
    Solver.refreshObjectiveState()
end

function Actions.setupPlayerTab(tab, rage)
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
        if value then Actions.applyNoclip() else Actions.restoreNoclip() end
    end)
end

if mode == "Rage" then
    local rage = ctx.Window:CreateTab("Rage")
    local itemsTab = ctx.Window:CreateTab("Items")
    local visualsTab = ctx.Window:CreateTab("ESP")
    local playerTab = ctx.Window:CreateTab("Player")

    rage:CreateSection(bookName)
    rage:CreateLabel("Universe support: Book 1, Book 2 and extra Piggy places")
    Actions.setupObjectiveHelper(rage)
    rage:CreateToggle("Auto Object / Full run", false, function(value)
        autoComplete = value
        releaseAutomation()
        if value then
            Round.resetRoundAutomation()
            autoGrab = false
            autoInteract = false
            scope:StopTask("autoGrab")
            scope:StopTask("autoInteract")
            scope:Loop("autoComplete", 0.05, Round.autoCompleteStep)
        else
            scope:StopTask("autoComplete")
        end
    end)
    rage:CreateToggle("Auto grab items", false, function(value)
        autoGrab = value
        releaseAutomation()
        if value then
            autoComplete = false
            autoInteract = false
            scope:StopTask("autoComplete")
            scope:StopTask("autoInteract")
            scope:Loop("autoGrab", 0.08, function()
                local item = nearestItem()
                if item then grabItem(item, false, itemId(item)) end
            end)
        else
            scope:StopTask("autoGrab")
        end
    end)
    rage:CreateToggle("Auto interact", false, function(value)
        autoInteract = value
        releaseAutomation()
        if value then
            autoComplete = false
            autoGrab = false
            scope:StopTask("autoComplete")
            scope:StopTask("autoGrab")
            scope:Loop("autoInteract", 0.08, function()
                local list = interactiveList()
                if #list == 0 then return end
                completeCursor = completeCursor % #list + 1
                triggerInteractive(list[completeCursor], false)
            end)
        else
            scope:StopTask("autoInteract")
        end
    end)
    rage:CreateButton("Complete one objective pass", Round.autoCompleteStep)
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
        Actions.applyTrapBypass(value)
    end)
    rage:CreateToggle("Remove doors locally", false, function(value)
        doorsRemoved = value
        Actions.applyDoors(value)
    end)
    rage:CreateToggle("Freeze Piggy / bots", false, function(value)
        botsFrozen = value
        Actions.applyBotFreeze(value)
    end)

    Actions.setupItemTab(itemsTab)
    Actions.setupVisualTab(visualsTab)
    Actions.setupPlayerTab(playerTab, true)
else
    local main = ctx.Window:CreateTab("Legit", "L")
    local visualsTab = ctx.Window:CreateTab("ESP", "E")
    local playerTab = ctx.Window:CreateTab("Player", "P")

    main:CreateSection(bookName)
    main:CreateLabel("Item names are resolved from Piggy mesh, color and metadata signatures")
    Actions.setupObjectiveHelper(main)
    Actions.setupItemTab(main)
    Actions.setupVisualTab(visualsTab)
    Actions.setupPlayerTab(playerTab, false)
end

scope:Connect(UserInputService.JumpRequest, function()
    if infiniteJump then
        local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

scope:Loop("objectiveHelper", 0.1, function()
    Solver.refreshObjectiveState()
    if objectivePuzzleLabel and getPuzzleStatus then
        objectivePuzzleLabel:Set("Puzzle: " .. tostring(getPuzzleStatus()))
    end
end)
scope:Loop("itemUiRefresh", 0.1, refreshItemDropdown)

scope:Loop("playerState", 0.05, function()
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if speedEnabled and humanoid then scope:Set(humanoid, "WalkSpeed", speedValue) end
    if jumpEnabled and humanoid then scope:Set(humanoid, "JumpPower", jumpValue) end
    if noclip then Actions.applyNoclip() end
    if godMode then applyGodMode() end
end)

scope:Loop("rageRefresh", 0.5, function()
    if trapBypass then Actions.applyTrapBypass(true) end
    if doorsRemoved then Actions.applyDoors(true) end
    if botsFrozen then Actions.applyBotFreeze(true) end
end)

scope:AddRestore(function()
    autoComplete = false
    autoGrab = false
    autoInteract = false
    escapeTouchOverride = false
    releaseAutomation()
    clearKind()
    setCharacterTouch(false)
    restoreEnemyTouchTransmitters()
    Actions.restoreNoclip()
    Actions.applyTrapBypass(false)
    Actions.applyDoors(false)
    Actions.applyBotFreeze(false)
    if fullbright then
        scope:Restore(Lighting, "Brightness")
        scope:Restore(Lighting, "GlobalShadows")
        scope:Restore(Lighting, "Ambient")
        scope:Restore(Lighting, "OutdoorAmbient")
    end
end)
