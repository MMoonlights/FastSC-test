return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local localPlayer = Players.LocalPlayer

    local function setupEmotes(tab)
        local animations = ReplicatedStorage:FindFirstChild("Animations")
        local emotes = animations and animations:FindFirstChild("Emotes")
        if not emotes then
            tab:CreateLabel("Emotes are not available in this place")
            return
        end
        local names = {}
        for _, animation in ipairs(emotes:GetChildren()) do names[#names + 1] = animation.Name end
        table.sort(names)
        local selected = names[1]
        local track
        tab:CreateDropdown("Emote", names, selected, function(value) selected = value end)
        tab:CreateToggle("Play emote", false, function(enabled)
            if track then pcall(function() track:Stop() end) track = nil end
            if enabled and selected then
                local animation = emotes:FindFirstChild(selected)
                local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if animation and humanoid then
                    track = humanoid:LoadAnimation(animation)
                    track:Play()
                end
            end
        end)
        scope:AddRestore(function()
            if track then pcall(function() track:Stop() end) end
        end)
    end

    if game.PlaceId == 99567941238278 then
        local lobby = ctx.Window:CreateTab("Lobby", "I")
        lobby:CreateSection("Number selector")
        local values = {}
        for i = 1, 456 do values[#values + 1] = string.format("%03d", i) end
        local saved = ctx.Config.Get("InkSavedNumbers", {})
        local savedStrings = {}
        for _, value in ipairs(saved) do savedStrings[#savedStrings + 1] = string.format("%03d", tonumber(value) or 0) end
        local selected = savedStrings
        local enabled = ctx.Config.Get("InkNumberSelectorEnabled", false)
        lobby:CreateMultiDropdown("Allowed numbers", values, savedStrings, function(list)
            selected = list
            local raw = {}
            for _, value in ipairs(list) do raw[#raw + 1] = tonumber(value) end
            ctx.Config.Set("InkSavedNumbers", raw)
        end)
        lobby:CreateToggle("Auto reroll number", enabled, function(value)
            enabled = value
            ctx.Config.Set("InkNumberSelectorEnabled", value)
        end)
        lobby:CreateLabel("When enabled, the lobby leave button is pressed until your PlayerTagValue matches a selected number")

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local clickedButton = remotes and remotes:FindFirstChild("ClickedButton")
        scope:Loop("numberSelector", 0.6, function()
            if not enabled or #selected == 0 or not clickedButton then return end
            local tag = localPlayer:FindFirstChild("PlayerTagValue")
            local current = tag and string.format("%03d", tonumber(tag.Value) or 0)
            if current and table.find(selected, current) then return end
            local character = localPlayer.Character
            if character then
                character:PivotTo(CFrame.new(198.660477, 55.9304161, 6.81963682))
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
            pcall(function() clickedButton:FireServer({buttonname = "leave"}) end)
        end)

        lobby:CreateSection("Emotes")
        setupEmotes(lobby)
        return
    end

    local games = ctx.Window:CreateTab("Games", "I")
    local combat = ctx.Window:CreateTab("Combat", "C")
    local playerTab = ctx.Window:CreateTab("Player", "P")
    local visual = ctx.Window:CreateTab("Visual", "V")
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local clickedButton = remotes:FindFirstChild("ClickedButton")
    local temporaryReached = remotes:FindFirstChild("TemporaryReachedBindable")
    local usedTool = remotes:FindFirstChild("UsedTool")
    local replication = ReplicatedStorage:FindFirstChild("Replication")
    local replicationEvent = replication and replication:FindFirstChild("Event")
    local state = {
        Universal = false,
        AutoRLGL = false,
        CarryEnd = false,
        CarryStart = false,
        RedLightGod = false,
        Dalgona = false,
        KillAura = false,
        BigHRP = false,
        AutoBackstab = false,
        AntiDeath = false,
        Tug = false,
        ShowHiders = false,
        ShowHunters = false,
        JumpRope = false,
        Glass = false,
        RebelESP = false,
        BringNPC = false,
        WalkSpeed = false,
        WalkSpeedValue = 16,
        JumpPower = false,
        JumpPowerValue = 50,
        TouchFling = false,
        AntiFling = false,
        Noclip = false,
    }
    local originalHitboxes = {}
    local hnsObjects = {}
    local rebelObjects = {}
    local safePart
    local safeCFrame
    local lastJumpRope = false
    local dalgonaDone = false
    local redLightGreen = true
    local redLightConnection
    local redLightRestore
    local lastHitboxUpdate = 0
    local lastVisualUpdate = 0

    local function liveCharacter()
        local live = workspace:FindFirstChild("Live")
        return live and live:FindFirstChild(localPlayer.Name)
    end

    local function tweenCharacter(character, cframe, duration)
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local tween = TweenService:Create(root, TweenInfo.new(duration or 1, Enum.EasingStyle.Linear), {CFrame = cframe})
        tween:Play()
        return tween
    end

    local function completeDalgona()
        if not (getreg and islclosure and getfenv and setupvalue) then return false end
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local gameModules = modules and modules:FindFirstChild("Games")
        local client = gameModules and gameModules:FindFirstChild("DalgonaClient")
        if not client then return false end
        for _, fn in ipairs(getreg()) do
            if typeof(fn) == "function" and islclosure(fn) then
                local ok, env = pcall(getfenv, fn)
                if ok and env and env.script == client then
                    local info = debug and debug.getinfo and debug.getinfo(fn)
                    if info and info.nups == 73 then
                        pcall(setupvalue, fn, 31, 9000000000)
                        return true
                    end
                end
            end
        end
        return false
    end

    games:CreateSection("Universal")
    games:CreateToggle("Universal auto helper", false, function(value) state.Universal = value end)

    games:CreateSection("Red Light Green Light")
    games:CreateToggle("Auto finish", false, function(value) state.AutoRLGL = value end)
    games:CreateToggle("Help injured to end", false, function(value) state.CarryEnd = value end)
    games:CreateToggle("Carry injured to start", false, function(value)
        state.CarryStart = value
        if value then
            local character = liveCharacter()
            safeCFrame = character and character:GetPivot() or safeCFrame
        end
    end)
    if getrawmetatable and setreadonly and getnamecallmethod and newcclosure then
        games:CreateToggle("Doll ignore", false, function(value)
            state.RedLightGod = value
            if value and not redLightRestore then
                local effects = remotes:FindFirstChild("Effects")
                if effects and not redLightConnection then
                    redLightConnection = scope:Connect(effects.OnClientEvent, function(payload)
                        if type(payload) == "table" and payload.EffectName == "TrafficLight" then
                            redLightGreen = payload.GreenLight == true
                            local root = Common.Root()
                            if redLightGreen then safeCFrame = root.CFrame end
                        end
                    end)
                end
                redLightRestore = scope:HookNamecall(game, function(old, object, method, ...)
                    local args = {...}
                    if state.RedLightGod and tostring(object) == "rootCFrame" and method == "FireServer" and not redLightGreen and safeCFrame then
                        args[1] = safeCFrame
                        return old(object, unpack(args))
                    end
                    return old(object, ...)
                end)
            elseif not value then
                if redLightRestore then redLightRestore() redLightRestore = nil end
                if redLightConnection then redLightConnection:Disconnect() redLightConnection = nil end
            end
        end)
    else
        games:CreateLabel("Doll ignore is unavailable on this executor")
    end

    games:CreateSection("Dalgona")
    games:CreateToggle("Auto complete Dalgona", false, function(value)
        state.Dalgona = value
        dalgonaDone = false
        if value then completeDalgona() end
    end)

    games:CreateSection("Tug of War")
    games:CreateToggle("Auto pull", false, function(value) state.Tug = value end)

    games:CreateSection("Jump Rope")
    games:CreateToggle("Auto teleport", false, function(value)
        state.JumpRope = value
        if not value then lastJumpRope = false end
    end)

    games:CreateSection("Glass Bridge")
    games:CreateToggle("Glass bridge visual", false, function(value)
        state.Glass = value
        local bridge = workspace:FindFirstChild("GlassBridge")
        local holder = bridge and bridge:FindFirstChild("GlassHolder")
        if holder then
            for _, item in ipairs(holder:GetDescendants()) do
                if item.Name == "glasspart" and item:IsA("BasePart") then
                    if value then
                        scope:Set(item, "Color", item:GetAttribute("exploitingisevil") and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(0, 255, 140))
                        scope:Set(item, "Transparency", 0)
                        scope:Set(item, "Material", Enum.Material.ForceField)
                    else
                        scope:Restore(item, "Color")
                        scope:Restore(item, "Transparency")
                        scope:Restore(item, "Material")
                    end
                end
            end
        end
    end)

    combat:CreateSection("Aura")
    combat:CreateToggle("Kill aura", false, function(value) state.KillAura = value end)
    combat:CreateToggle("Hitbox expander", false, function(value)
        state.BigHRP = value
        if not value then
            for part, data in pairs(originalHitboxes) do
                if part and part.Parent then
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                    part.CanCollide = data.CanCollide
                end
                originalHitboxes[part] = nil
            end
        end
    end)
    combat:CreateToggle("Auto teleport behind players", false, function(value) state.AutoBackstab = value end)
    combat:CreateToggle("Anti die", false, function(value)
        state.AntiDeath = value
        if value then
            local root = Common.Root()
            safeCFrame = root.CFrame
        elseif safeCFrame then
            Common.Root().CFrame = safeCFrame
        end
    end)

    visual:CreateSection("Hide and Seek")
    visual:CreateToggle("Reveal hiders", false, function(value) state.ShowHiders = value end)
    visual:CreateToggle("Reveal hunters", false, function(value)
        state.ShowHunters = value
    end)

    visual:CreateSection("Rebel")
    visual:CreateToggle("NPC visual / hitbox", false, function(value) state.RebelESP = value end)
    visual:CreateToggle("Bring NPCs to front", false, function(value) state.BringNPC = value end)

    playerTab:CreateSection("Movement")
    playerTab:CreateToggle("WalkSpeed", false, function(value)
        state.WalkSpeed = value
        if not value then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then scope:Restore(humanoid, "WalkSpeed") end
        end
    end)
    playerTab:CreateSlider("WalkSpeed value", {Min = 1, Max = 100, Default = 16}, function(value) state.WalkSpeedValue = value end)
    playerTab:CreateToggle("JumpPower", false, function(value)
        state.JumpPower = value
        if not value then
            local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then scope:Restore(humanoid, "JumpPower") end
        end
    end)
    playerTab:CreateSlider("JumpPower value", {Min = 10, Max = 150, Default = 50}, function(value) state.JumpPowerValue = value end)
    playerTab:CreateToggle("No clip", false, function(value)
        state.Noclip = value
        if not value and localPlayer.Character then
            for _, part in ipairs(localPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then scope:Restore(part, "CanCollide") end
            end
        end
    end)
    playerTab:CreateToggle("Touch fling", false, function(value) state.TouchFling = value end)
    playerTab:CreateToggle("Anti fling", false, function(value)
        state.AntiFling = value
        if value then safeCFrame = Common.Root().CFrame end
    end)

    playerTab:CreateSection("Emotes")
    setupEmotes(playerTab)

    local weapons = {"Fork", "Bottle", "Knife", "Fists"}
    local function equippedWeapon(character)
        for _, name in ipairs(weapons) do
            local tool = character and character:FindFirstChild(name)
            if tool then return tool end
        end
    end
    local function backpackWeapon()
        local backpack = localPlayer:FindFirstChild("Backpack")
        if not backpack then return nil end
        for _, name in ipairs(weapons) do
            local tool = backpack:FindFirstChild(name)
            if tool then return tool end
        end
    end
    local function nearestPlayer(maxDistance)
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best
        local distance = maxDistance or math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and Common.Alive(player) then
                if workspace:FindFirstChild("HideAndSeekMap") then
                    local hunter = localPlayer:GetAttribute("IsHunter")
                    local hider = localPlayer:GetAttribute("IsHider")
                    if hunter and not player:GetAttribute("IsHider") then continue end
                    if hider then continue end
                end
                local targetRoot = player.Character.HumanoidRootPart
                local current = (targetRoot.Position - root.Position).Magnitude
                if current < distance then best = player.Character distance = current end
            end
        end
        return best
    end

    local function clearTag(character)
        local data = hnsObjects[character]
        if data then
            pcall(function() data.Highlight:Destroy() end)
            pcall(function() data.Gui:Destroy() end)
            hnsObjects[character] = nil
        end
    end

    local function tagCharacter(character, player, kind)
        local current = hnsObjects[character]
        if current and current.Kind == kind then return end
        clearTag(character)
        local color = kind == "Hider" and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(255, 80, 80)
        local highlight = Instance.new("Highlight")
        highlight.Name = "FastSC_HNS"
        highlight.Adornee = character
        highlight.FillColor = color
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
        local head = character:FindFirstChild("Head")
        local gui = Instance.new("BillboardGui")
        gui.Name = "FastSC_HNS"
        gui.Adornee = head
        gui.Size = UDim2.new(0, 200, 0, 42)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = character
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.TextStrokeTransparency = 0.4
        label.Text = player.DisplayName .. " - " .. string.upper(kind)
        label.Parent = gui
        hnsObjects[character] = {Kind = kind, Highlight = highlight, Gui = gui}
    end

    local function clearRebel(model)
        local data = rebelObjects[model]
        if data then
            pcall(function() data:Destroy() end)
            rebelObjects[model] = nil
        end
    end

    scope:Loop("runtime", 0.05, function()
        local now = os.clock()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local live = workspace:FindFirstChild("Live")
        local activeCharacter = live and live:FindFirstChild(localPlayer.Name) or character
        local activeRoot = activeCharacter and activeCharacter:FindFirstChild("HumanoidRootPart")

        if state.WalkSpeed and humanoid then scope:Set(humanoid, "WalkSpeed", state.WalkSpeedValue) end
        if state.JumpPower and humanoid then scope:Set(humanoid, "JumpPower", state.JumpPowerValue) end
        if state.Noclip and character then
            for _, part in ipairs(character:GetChildren()) do if part:IsA("BasePart") then scope:Set(part, "CanCollide", false) end end
        end
        if state.AntiFling and root then
            if not safeCFrame then safeCFrame = root.CFrame end
            if (root.Position - safeCFrame.Position).Magnitude > 10 or root.AssemblyLinearVelocity.Magnitude > 150 then
                root.CFrame = safeCFrame
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            else
                safeCFrame = root.CFrame
            end
        end
        if state.TouchFling and character then
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    local velocity = part.AssemblyLinearVelocity
                    part.AssemblyLinearVelocity = Vector3.new(math.random(9999, 99999), math.random(9999, 99999), math.random(9999, 9999))
                    task.defer(function()
                        if part and part.Parent then part.AssemblyLinearVelocity = velocity end
                    end)
                end
            end
        end

        if state.BigHRP and now - lastHitboxUpdate >= 0.12 then
            lastHitboxUpdate = now
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        if not originalHitboxes[targetRoot] then
                            originalHitboxes[targetRoot] = {Size = targetRoot.Size, Transparency = targetRoot.Transparency, CanCollide = targetRoot.CanCollide}
                        end
                        targetRoot.Size = Vector3.new(6, 6, 6)
                        targetRoot.Transparency = 0.2
                        targetRoot.CanCollide = false
                    end
                end
            end
        end
        if state.AntiDeath and humanoid and root and humanoid.Health <= (workspace:FindFirstChild("HideAndSeekMap") and 50 or 30) then
            if not safePart then
                safePart = Instance.new("Part")
                safePart.Anchored = true
                safePart.CanCollide = true
                safePart.Size = Vector3.new(10, 1, 10)
                safePart.Position = Vector3.new(10000, 1000, 10000)
                safePart.Parent = workspace
                scope:TrackInstance(safePart)
            end
            root.CFrame = safePart.CFrame + Vector3.new(0, 5, 0)
        end
        if state.AutoBackstab and humanoid and humanoid.Health > 30 and root then
            local target = nearestPlayer(100)
            local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local behind = targetRoot.CFrame * CFrame.new(0, 0, 2)
                root.CFrame = CFrame.lookAt(behind.Position, targetRoot.Position)
            end
        end
        if state.KillAura and humanoid and root then
            local tool = equippedWeapon(character) or backpackWeapon()
            if tool and tool.Parent ~= character then humanoid:EquipTool(tool) end
            local target = nearestPlayer(8)
            local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
            if targetRoot and tool then
                root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
                if replicationEvent then pcall(function() replicationEvent:FireServer("Clicked") end) end
                if usedTool then
                    pcall(function() usedTool:FireServer("UsingMoveCustom", tool, true, {Clicked = true}) end)
                end
            end
        end

        local rlgl = workspace:FindFirstChild("RedLightGreenLight")
        local doll = workspace:FindFirstChild("SQUIDDOLL123")
        if state.AutoRLGL and rlgl and doll and doll.PrimaryPart and activeCharacter and not activeCharacter:FindFirstChild("SafeRedLightGreenLight") then
            tweenCharacter(activeCharacter, doll.PrimaryPart.CFrame + Vector3.new(0, 25, 0), 4)
        end
        if (state.CarryEnd or state.CarryStart) and rlgl and live and activeCharacter and fireproximityprompt then
            for _, model in ipairs(live:GetChildren()) do
                if model:IsA("Model") and model ~= activeCharacter and model:FindFirstChild("InjuredWalking") and not model:FindFirstChild("IsBeingHeld") and not model:FindFirstChild("HoldingPlayer") then
                    local targetRoot = model:FindFirstChild("HumanoidRootPart")
                    local prompt = targetRoot and targetRoot:FindFirstChild("CarryPrompt")
                    if prompt then
                        activeCharacter:PivotTo(targetRoot.CFrame + Vector3.new(0, 2, 0))
                        pcall(fireproximityprompt, prompt)
                        task.wait(0.15)
                        if state.CarryEnd and doll and doll.PrimaryPart then
                            activeCharacter:PivotTo(doll.PrimaryPart.CFrame + Vector3.new(0, 25, 0))
                        elseif state.CarryStart and safeCFrame then
                            activeCharacter:PivotTo(safeCFrame)
                        end
                        if clickedButton then pcall(function() clickedButton:FireServer({tryingtoleave = true}) end) end
                        break
                    end
                end
            end
        end
        if state.Tug and workspace:FindFirstChild("TugOfWar") and temporaryReached then
            pcall(function() temporaryReached:FireServer({GameQTE = true}) end)
        end
        if state.JumpRope and workspace:FindFirstChild("JumpRope") and activeCharacter and not lastJumpRope then
            activeCharacter:PivotTo(CFrame.new(739.3626, 199.1441, 922.1797))
            lastJumpRope = true
        elseif not workspace:FindFirstChild("JumpRope") then
            lastJumpRope = false
        end
        if state.Dalgona and workspace:FindFirstChild("Dalgona") and not dalgonaDone then
            dalgonaDone = completeDalgona()
        elseif not workspace:FindFirstChild("Dalgona") then
            dalgonaDone = false
        end

        if state.Universal then
            if rlgl and doll and doll.PrimaryPart and activeCharacter and not activeCharacter:FindFirstChild("SafeRedLightGreenLight") then
                tweenCharacter(activeCharacter, doll.PrimaryPart.CFrame + Vector3.new(0, 25, 0), 1)
            end
            if workspace:FindFirstChild("TugOfWar") and temporaryReached then
                pcall(function() temporaryReached:FireServer({GameQTE = true}) end)
            end
            if workspace:FindFirstChild("JumpRope") and activeCharacter then
                activeCharacter:PivotTo(CFrame.new(739.3626, 199.1441, 922.1797))
            end
            if workspace:FindFirstChild("Dalgona") then completeDalgona() end
        end

        if now - lastVisualUpdate >= 0.2 then
            lastVisualUpdate = now
            local hns = workspace:FindFirstChild("HideAndSeekMap")
            if hns and live then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character and live:FindFirstChild(player.Name) then
                        local kind
                        if state.ShowHiders and player:GetAttribute("IsHider") then kind = "Hider" end
                        if state.ShowHunters and player:GetAttribute("IsHunter") then kind = "Hunter" end
                        if kind then tagCharacter(player.Character, player, kind) else clearTag(player.Character) end
                    end
                end
            else
                for character2 in pairs(hnsObjects) do clearTag(character2) end
            end

            if live then
                for _, model in ipairs(live:GetChildren()) do
                    if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) and model ~= character then
                        local head = model:FindFirstChild("Head")
                        local targetRoot = model:FindFirstChild("HumanoidRootPart")
                        if state.RebelESP and head then
                            scope:Set(head, "Size", Vector3.new(9.6, 9.6, 9.6))
                            local highlight = rebelObjects[model]
                            if not highlight or not highlight.Parent then
                                highlight = Instance.new("Highlight")
                                highlight.Name = "FastSC_Rebel"
                                highlight.Adornee = model
                                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.Parent = model
                                rebelObjects[model] = highlight
                            end
                        else
                            if head then scope:Restore(head, "Size") end
                            clearRebel(model)
                        end
                        if state.BringNPC and targetRoot and root then
                            targetRoot.CFrame = root.CFrame + root.CFrame.LookVector * 5
                        end
                    end
                end
            end
        end
    end)

    scope:AddRestore(function()
        if redLightRestore then redLightRestore() redLightRestore = nil end
        for part, data in pairs(originalHitboxes) do
            if part and part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                    part.CanCollide = data.CanCollide
                end)
            end
        end
        for character in pairs(hnsObjects) do clearTag(character) end
        for model in pairs(rebelObjects) do clearRebel(model) end
    end)
end
