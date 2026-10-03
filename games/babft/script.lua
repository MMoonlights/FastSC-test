return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local main = ctx.Window:CreateTab("Farm", "B")
    local misc = ctx.Window:CreateTab("Misc", "M")
    local TweenService = game:GetService("TweenService")
    local selectedTeam = "White"
    local selectedChest = "Common Chest"
    local quantity = 1

    local zones = {
        White = "WhiteZone",
        Black = "BlackZone",
        Green = "CamoZone",
        Magenta = "MagentaZone",
        Red = "Really redZone",
        Yellow = "New YellerZone",
        Blue = "Really blueZone",
    }

    local function tweenTo(cframe, speed)
        local root = Common.Root()
        local duration = (root.Position - cframe.Position).Magnitude / speed
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = cframe})
        tween:Play()
        tween.Completed:Wait()
    end

    local function endTrigger()
        local stages = workspace:FindFirstChild("BoatStages")
        local normal = stages and stages:FindFirstChild("NormalStages")
        local ending = normal and normal:FindFirstChild("TheEnd")
        local chest = ending and ending:FindFirstChild("GoldenChest")
        return chest and chest:FindFirstChild("Trigger")
    end

    main:CreateSection("Auto farm")
    main:CreateToggle("Teleport + tween farm", false, function(enabled)
        if enabled then
            scope:Loop("farmTp", 1, function(token)
                local root = Common.Root()
                root.CFrame = CFrame.new(-51.3946571, 22, 814.888123)
                tweenTo(CFrame.new(-77.0485153, 20, 8625.86719), 785)
                local trigger = endTrigger()
                if trigger then root.CFrame = trigger.CFrame end
                local waited = 0
                while token.Alive and waited < 17 do
                    task.wait(0.25)
                    waited += 0.25
                end
            end)
        else
            scope:StopTask("farmTp")
        end
    end)
    main:CreateToggle("Tween farm", false, function(enabled)
        if enabled then
            scope:Loop("farmTween", 1, function(token)
                tweenTo(CFrame.new(-77.0485153, 20, 8625.86719), 600)
                local trigger = endTrigger()
                if trigger then Common.Root().CFrame = trigger.CFrame end
                local waited = 0
                while token.Alive and waited < 17 do
                    task.wait(0.25)
                    waited += 0.25
                end
            end)
        else
            scope:StopTask("farmTween")
        end
    end)

    main:CreateSection("Teams")
    main:CreateDropdown("Team", {"White", "Black", "Green", "Magenta", "Red", "Yellow", "Blue"}, selectedTeam, function(value)
        selectedTeam = value
    end)
    main:CreateButton("Teleport to team zone", function()
        local zone = workspace:FindFirstChild(zones[selectedTeam])
        if zone then
            local part = zone:FindFirstChildWhichIsA("BasePart", true)
            if part then Common.Root().CFrame = part.CFrame + Vector3.new(0, 4, 0) end
        end
    end)

    misc:CreateSection("Quests")
    local function quest(id)
        local clear = workspace:FindFirstChild("ClearAllPlayersBoatParts")
        local maker = workspace:FindFirstChild("QuestMakerEvent")
        if clear then clear:FireServer() end
        if maker then maker:FireServer(id) end
    end
    misc:CreateButton("Cloud quest", function() quest(1) end)
    misc:CreateButton("Target quest", function() quest(2) end)
    misc:CreateButton("Find me quest", function() quest(4) end)
    misc:CreateButton("The Box quest", function() quest(6) end)
    misc:CreateButton("Cancel quest", function() quest(0) end)

    misc:CreateSection("Chests")
    misc:CreateDropdown("Chest", {"Common Chest", "Uncommon Chest", "Rare Chest", "Epic Chest", "Legendary Chest"}, selectedChest, function(value)
        selectedChest = value
    end)
    misc:CreateInput("Quantity", "1", function(value)
        quantity = math.max(1, tonumber(value) or 1)
    end)
    misc:CreateButton("Purchase chests", function()
        local remote = workspace:FindFirstChild("ItemBoughtFromShop")
        if remote and remote:IsA("RemoteFunction") then
            pcall(function() remote:InvokeServer(selectedChest, quantity) end)
        end
    end)

    misc:CreateSection("Codes")
    misc:CreateButton("Redeem all known codes", function()
        local remote = workspace:FindFirstChild("CheckCodeFunction")
        if not remote then return end
        local codes = {"Squid Army", "hi", "=D", "=P", "chillthrill709 was here", "Lurking Legend", "Be a big f00t print", "GGGOOOAAALLL", "1B", "voted code", "1M Likes", "Lurking Code", "Fireworks", "2M members", "Hatched code", "Happy Easter"}
        task.spawn(function()
            for _, code in ipairs(codes) do
                pcall(function() remote:InvokeServer(code) end)
                task.wait(0.05)
            end
        end)
    end)
end
