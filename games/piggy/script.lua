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
    local requirements = {}
    local escapeTargets = {}
    local escapeTouchOverride = false
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
    local freeInteractionCooldowns = setmetatable({}, {__mode = "k"})
    local objectiveMapLabel
    local itemsById = {}
    local itemIndexedId = setmetatable({}, {__mode = "k"})
    local trackedItemSignals = setmetatable({}, {__mode = "k"})
    local requirementCounts = {}
    local requirementIdByValue = setmetatable({}, {__mode = "k"})
    local trackedRequirements = setmetatable({}, {__mode = "k"})
    local itemDropdown
    local itemDropdownSignature = ""
    local itemUiDirty = true

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

    local function currentMapModel()
        for _, name in ipairs(mapNames) do
            local map = workspace:FindFirstChild(name)
            if map then return map, name end
        end
        for _, child in ipairs(workspace:GetChildren()) do
            local lower = string.lower(child.Name)
            for _, name in ipairs(mapNames) do
                if lower == string.lower(name) then return child, name end
            end
        end
    end

    local function currentMapName()
        local _, name = currentMapModel()
        return name or "Unknown"
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
    local automationDeadline = 0

    local function zeroCharacterVelocity(character)
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

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
        automationDeadline = os.clock() + 2
        setAutomationCollision(true)
        if humanoid then scope:Set(humanoid, "AutoRotate", false) end
        zeroCharacterVelocity(character)
        pcall(function() character:PivotTo(target) end)
        root.CFrame = target
        return true
    end

    local function endAutomationMove()
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        automationTarget = nil
        automationActive = false
        automationDeadline = 0
        zeroCharacterVelocity(character)
        if humanoid then scope:Restore(humanoid, "AutoRotate") end
        if not noclip then setAutomationCollision(false) end
    end

    local function releaseAutomation()
        autoCompleteBusy = false
        pickupBusy = false
        endAutomationMove()
    end

    scope:Connect(RunService.PreSimulation, function()
        if not automationActive then return end
        if automationDeadline > 0 and os.clock() > automationDeadline then
            endAutomationMove()
            pickupBusy = false
            autoCompleteBusy = false
            return
        end
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        zeroCharacterVelocity(character)
        if automationTarget then
            pcall(function() character:PivotTo(automationTarget) end)
            root.CFrame = automationTarget
        end
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
        RedEgg = "Red Egg",
        GreenEgg = "Green Egg",
        BlueEgg = "Blue Egg",
        KeyCode = "Key Code",
        Coin = "Coin",
        Torch = "Torch",
        Mirror = "Mirror",
        PurpleVial = "Purple Vial",
        TankBullet = "Tank Bullet",
        Apple = "Apple",
        Rose = "Rose",
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
        RemoteControl = "Remote Control",
        Mop = "Mop",
        ElevatorKey = "Elevator Key",
        Presents = "Presents",
        Dreidel = "Dreidel",
        FencingSword = "Fencing Sword",
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

    aliases[token("Remote")] = "RemoteControl"
    aliases[token("TV Remote")] = "RemoteControl"
    aliases[token("Remote Control")] = "RemoteControl"
    aliases[token("Fencing Foil")] = "FencingSword"
    aliases[token("Fencing Sword")] = "FencingSword"
    aliases[token("Present")] = "Presents"
    aliases[token("Presents")] = "Presents"
    aliases[token("Elevator Key")] = "ElevatorKey"
    aliases[token("Mop")] = "Mop"
    aliases[token("Pink Vial")] = "PurpleVial"
    aliases[token("Purple Vial")] = "PurpleVial"
    aliases[token("Gasoline")] = "Gas"
    aliases[token("Gas Can")] = "Gas"
    aliases[token("Gas Canister")] = "Gas"
    aliases[token("Tank Shell")] = "TankBullet"
    aliases[token("Tank Bullet")] = "TankBullet"
    aliases[token("Cannon Shell")] = "TankBullet"
    aliases[token("Coin")] = "Coin"
    aliases[token("Token")] = "Coin"
    aliases[token("Torch")] = "Torch"
    aliases[token("Mirror")] = "Mirror"
    aliases[token("Red Egg")] = "RedEgg"
    aliases[token("Green Egg")] = "GreenEgg"
    aliases[token("Blue Egg")] = "BlueEgg"

    local mapProfiles = {
        House = {
            Gates = {
                WhiteKey = {Present = {"RedGear", "GreenGear"}},
            },
            Depends = {
                WhiteKey = {"RedGear", "GreenGear", "Hammer", "Wrench", "KeyCode"},
            },
            Priority = {
                GreenKey = 10, RedKey = 20, BlueKey = 30, YellowKey = 35, OrangeKey = 40,
                RedGear = 45, GreenGear = 45, Hammer = 55, Wrench = 56, KeyCode = 57, WhiteKey = 100,
            },
        },
        Station = {
            Gates = {
                Gas = {Present = {"Battery"}},
            },
            Depends = {
                WhiteKey = {"Hammer", "Wrench"},
                Gas = {"Battery", "Hammer", "Wrench"},
            },
            Counters = {
                Battery = 2,
            },
            Priority = {
                GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25, YellowKey = 30,
                Battery = 35, Plank = 40, Hammer = 45, Wrench = 46, WhiteKey = 60, Gas = 100,
            },
        },
        Gallery = {
            Gates = {
                WhiteKey = {Present = {"RedEgg", "GreenEgg"}},
            },
            Depends = {
                WhiteKey = {"RedEgg", "GreenEgg", "Hammer", "Wrench"},
            },
            Priority = {
                RedKey = 10, BlueKey = 15, GreenKey = 20, OrangeKey = 25, YellowKey = 30,
                Plank = 35, Hammer = 40, Wrench = 41, RedEgg = 50, GreenEgg = 50, WhiteKey = 100,
            },
        },
        Forest = {
            Gates = {
                WhiteKey = {Present = {"Torch"}, Active = {"Torch"}},
            },
            Depends = {
                WhiteKey = {"Torch", "Hammer", "Wrench"},
            },
            Priority = {
                GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25, YellowKey = 30,
                Plank = 35, Hammer = 40, Wrench = 45, Torch = 50, WhiteKey = 100,
            },
        },
        School = {
            Depends = {
                RedGear = {"Book"},
                GreenGear = {"Book"},
                WhiteKey = {"Book", "RedGear", "GreenGear", "Hammer", "Wrench"},
            },
            Priority = {
                GreenKey = 10, BlueKey = 15, OrangeKey = 20, Book = 25,
                RedGear = 35, GreenGear = 36, RedKey = 40, YellowKey = 45,
                Hammer = 55, Wrench = 56, WhiteKey = 100,
            },
        },
        Hospital = {
            Gates = {
                WhiteKey = {Present = {"EmptyVial", "GreenVial", "PurpleVial"}},
            },
            Depends = {
                WhiteKey = {"GreenVial", "PurpleVial", "Hammer"},
            },
            Counters = {
                EmptyVial = 2,
            },
            Priority = {
                GreenKeycard = 10, BlueKeycard = 15, RedKeycard = 20, OrangeKeycard = 25,
                Hammer = 30, Plank = 35, EmptyVial = 40, GreenVial = 50, PurpleVial = 51,
                YellowKey = 60, WhiteKey = 100,
            },
        },
        Metro = {
            Gates = {
                BlueKeycard = {Present = {"Coin"}},
            },
            Depends = {
                BlueKeycard = {"Coin"},
                WhiteKey = {"BlueKeycard", "Hammer", "Wrench"},
            },
            Counters = {
                Coin = 2,
            },
            Priority = {
                GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25,
                Coin = 35, Hammer = 45, BlueKeycard = 55, Wrench = 60, WhiteKey = 100,
            },
        },
        Carnival = {
            Gates = {
                Hammer = {Present = {"Mallet"}},
                KeyCode = {Present = {"WaterGun"}},
            },
            Depends = {
                Hammer = {"Mallet"},
                KeyCode = {"WaterGun"},
                WhiteKey = {"OrangeKey", "Hammer", "Wrench", "KeyCode"},
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, RedKey = 20, YellowKey = 25, OrangeKey = 30,
                Mallet = 35, Hammer = 40, Wrench = 45, WaterGun = 50, KeyCode = 55, WhiteKey = 100,
            },
        },
        City = {
            Gates = {
                KeyCode = {Active = {"FireExtinguisher", "Plank"}},
            },
            Depends = {
                KeyCode = {"FireExtinguisher", "Plank", "Wrench"},
            },
            Priority = {
                GreenKeycard = 10, RedKeycard = 15, OrangeKeycard = 20, BlueKeycard = 25,
                Plank = 35, FireExtinguisher = 40, Wrench = 45, Dynamite = 50, KeyCode = 100,
            },
        },
        Mall = {
            Gates = {
                WhiteKey = {Present = {"Coin"}},
            },
            Depends = {
                WhiteKey = {"Coin", "Crowbar", "Wrench"},
            },
            Counters = {
                Coin = 2,
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25,
                Wrench = 35, Crowbar = 40, Coin = 45, WhiteKey = 100,
            },
        },
        Outpost = {
            Gates = {
                Gas = {Active = {"FireExtinguisher"}},
                TankBullet = {Active = {"Wrench"}},
                BlueKeycard = {Present = {"Gas", "TankBullet"}},
            },
            Depends = {
                Gas = {"FireExtinguisher"},
                TankBullet = {"Wrench"},
                BlueKeycard = {"Gas", "TankBullet", "Wrench", "FireExtinguisher"},
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25, YellowKey = 30,
                Wrench = 35, FireExtinguisher = 40, Gas = 50, TankBullet = 60, BlueKeycard = 100,
            },
        },
        Plant = {
            Gates = {
                PurpleVial = {Present = {"Battery"}},
                Dynamite = {Present = {"GreenVial", "PurpleVial"}},
                WhiteKey = {Present = {"Torch"}, Active = {"Torch"}},
                Mallet = {Present = {"Coin"}},
            },
            Depends = {
                GreenVial = {"OrangeKeycard", "YellowKey", "Plank", "Hammer"},
                PurpleVial = {"RedKey", "BlueKey", "Battery"},
                Dynamite = {"GreenVial", "PurpleVial"},
                WhiteKey = {"Torch"},
                Mallet = {"Coin"},
            },
            Counters = {
                Battery = 2,
                Coin = 2,
            },
            Priority = {
                OrangeKeycard = 10, YellowKey = 15, Plank = 20, Hammer = 25, GreenVial = 30,
                GreenKeycard = 35, RedKey = 40, BlueKey = 41, Battery = 45, PurpleVial = 50,
                Dynamite = 60, Torch = 70, WhiteKey = 75, Coin = 80, Mallet = 90,
            },
        },
        Alleys = {
            Puzzle = "DigitCode",
            Depends = {
                Screwdriver = {"YellowKey"},
                WhiteKey = {"OrangeKey", "Scissors", "Mop", "Screwdriver", "PurpleKey", "KeyCode"},
            },
            Priority = {
                OrangeKey = 10, Scissors = 15, BlueKey = 20, GreenKey = 25, RedKey = 30,
                YellowKey = 35, Screwdriver = 40, Mop = 45, PurpleKey = 50, KeyCode = 60, WhiteKey = 100,
            },
        },
        Store = {
            Gates = {
                YellowKey = {Active = {"RemoteControl"}},
            },
            Depends = {
                YellowKey = {"RemoteControl"},
                Ladder = {"YellowKey"},
                Battery = {"Ladder"},
            },
            Counters = {
                RemoteControl = 4,
                Battery = 2,
            },
            Priority = {
                GreenKey = 10, OrangeKey = 15, RedKey = 20, BlueKey = 25,
                RemoteControl = 30, YellowKey = 40, Ladder = 45, Carrot = 50,
                PurpleKey = 55, Battery = 100,
            },
        },
        Refinery = {
            Depends = {
                Screwdriver = {"RedKey"},
                WhiteKey = {"OrangeKey", "Scissors", "GreenKey", "Carrot"},
            },
            Priority = {
                Scissors = 10, GreenKey = 15, BlueKey = 20, RedKey = 25, YellowKey = 30,
                Screwdriver = 35, Carrot = 40, Battery = 45, GreenKeycard = 50,
                SmokeGrenade = 55, OrangeKey = 60, PurpleKey = 65, WhiteKey = 100,
            },
        },
        SafePlace = {
            Depends = {
                Hammer = {"Screwdriver", "Ladder"},
                Blowtorch = {"FireExtinguisher", "Screwdriver", "Ladder"},
                WhiteKey = {"YellowKey", "Hammer", "Blowtorch"},
            },
            Priority = {
                Screwdriver = 10, Ladder = 15, RedKey = 20, YellowKey = 25,
                FireExtinguisher = 30, Hammer = 35, PurpleKey = 40, Blowtorch = 50, WhiteKey = 100,
            },
        },
        Sewers = {
            Gates = {
                Mop = {Present = {"WhiteGear"}},
                WhiteKey = {Present = {"Mop"}},
            },
            Depends = {
                Mop = {"GreenKey", "OrangeKey", "Plank", "WhiteGear", "Screwdriver", "YellowKey"},
                WhiteKey = {"Mop", "Screwdriver"},
            },
            Counters = {
                WhiteGear = 2,
            },
            Priority = {
                GreenKey = 10, OrangeKey = 15, Plank = 20, Screwdriver = 25, WhiteGear = 30,
                BlueKey = 40, YellowKey = 45, Mop = 50, RedKey = 55, WhiteKey = 100,
            },
        },
        Factory = {
            Counters = {
                WoodenSword = 3,
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, RedKey = 20, YellowKey = 25,
                Ladder = 30, Scissors = 35, Shovel = 40, Axe = 45, FireExtinguisher = 50,
                PurpleKey = 55, Screwdriver = 60, OrangeKey = 65, WoodenSword = 100,
            },
        },
        Port = {
            Depends = {
                GrapplingHook = {"RedKey"},
                Battery = {"Plank", "GrapplingHook", "Shovel"},
            },
            Counters = {
                Battery = 4,
            },
            Priority = {
                RedKey = 10, BlueKey = 15, OrangeKey = 20, GreenKey = 25, PurpleKey = 30,
                Plank = 35, YellowKey = 40, GrapplingHook = 45, Shovel = 50, Battery = 100,
            },
        },
        Ship = {
            Puzzle = "ColorCode",
            Depends = {
                WhiteKey = {"Screwdriver", "Wrench"},
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25, PurpleKey = 30,
                Screwdriver = 35, Wrench = 40, YellowKey = 45, WhiteKey = 100,
            },
        },
        Docks = {
            Puzzle = "RomanCode",
            Depends = {
                Plank = {"Hammer"},
                WhiteKey = {"GreenKey", "Hammer", "Plank", "Candle"},
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25,
                Hammer = 30, Plank = 35, Candle = 40, YellowKey = 45, WhiteKey = 100,
            },
        },
        Temple = {
            Puzzle = "ShapeWheel",
            Depends = {
                Hammer = {"RedKey"},
                Plank = {"Hammer"},
                WhiteKey = {"Shovel", "Hammer", "Plank", "Candle"},
            },
            Priority = {
                BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25,
                Shovel = 30, YellowKey = 35, Hammer = 40, Plank = 45, Candle = 50, WhiteKey = 100,
            },
        },
        Camp = {
            Puzzle = "LightCircle",
            Depends = {
                ElevatorKey = {"RedKey"},
            },
            Priority = {
                GreenKey = 10, OrangeKey = 15, BlueKey = 20, RedKey = 25,
                Ladder = 30, Shovel = 35, PurpleKey = 40, TNT = 45, Rope = 50,
                YellowKey = 55, ElevatorKey = 100,
            },
        },
        Lab = {
            Puzzle = "ReactorLevers",
            Depends = {
                BlueKeycard = {"Wrench"},
            },
            Priority = {
                GreenKey = 10, PurpleKey = 15, YellowKey = 20, Wrench = 25,
                BlueKey = 30, RedKeycard = 35, OrangeKeycard = 40, BlueKeycard = 45,
                Dynamite = 60, Screwdriver = 65, Hammer = 70, Mop = 75, WoodenSword = 80,
            },
        },
    }

    mapProfiles["The Safe Place"] = mapProfiles.SafePlace

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

    local function meshSignatures(item)
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

    local function hasMeshSignature(signatures, meshIds, textureIds)
        for _, signature in ipairs(signatures) do
            if meshIds and table.find(meshIds, signature.MeshId) then return signature end
            if textureIds and table.find(textureIds, signature.TextureId) then return signature end
        end
    end

    local function signatureId(item)
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
        return (requirementCounts[id] or 0) > 0
    end

    local function updateRequirement(value)
        local old = requirementIdByValue[value]
        if old then
            requirementCounts[old] = math.max(0, (requirementCounts[old] or 1) - 1)
            if requirementCounts[old] == 0 then requirementCounts[old] = nil end
        end
        local id = aliases[token(value.Value)]
        requirementIdByValue[value] = id
        if id then requirementCounts[id] = (requirementCounts[id] or 0) + 1 end
        itemUiDirty = true
    end

    local function trackRequirement(value)
        requirements[value] = true
        if not trackedRequirements[value] then
            trackedRequirements[value] = true
            updateRequirement(value)
            scope:Connect(value:GetPropertyChangedSignal("Value"), function()
                updateRequirement(value)
            end)
        end
    end

    local function untrackRequirement(value)
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

    local function itemStagePresent(id)
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

    local function ancestorRequirementLocks(item)
        local current = item.Parent
        for _ = 1, 5 do
            if not current or current == workspace then break end
            for _, child in ipairs(current:GetChildren()) do
                if child:IsA("StringValue") then
                    local id = aliases[token(child.Value)]
                    if id and requirementExists(id) then
                        return true
                    end
                end
            end
            current = current.Parent
        end
        return false
    end

    local function isAvailableWorldItem(item)
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

    local function removeIndexedBucket(item)
        local id = itemIndexedId[item]
        if not id then return end
        local bucket = itemsById[id]
        if bucket then
            bucket[item] = nil
            if next(bucket) == nil then itemsById[id] = nil end
        end
        itemIndexedId[item] = nil
    end

    local function indexItem(item)
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

    local function unindexItem(item)
        removeIndexedBucket(item)
        items[item] = nil
        itemNameCache[item] = nil
        itemUiDirty = true
    end

    local function watchItemSignature(instance, item)
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

    local function unregister(instance)
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

    local function refreshItemDropdown()
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

    local function findItemByName(name)
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

    local solveCodePanel, solveSpecialPuzzle = (function()
    local puzzleBusy = false
    local puzzleRetryAt = 0
    local solvedPuzzles = {}

    local canonicalRoots = {
        DigitCode = {"digitcodepad", "digitcode", "numbercodepad", "codepad"},
        ColorCode = {"colorcodepad", "colorcode"},
        RomanCode = {"romannumeralpuzzlemain", "romannumeralpuzzle", "romannumeral"},
        ShapeWheel = {"shapecodewheel", "shapewheel", "shapecode"},
        LightCircle = {"lightcirclepuzzle", "lightcircle"},
        ReactorGrid = {"ninesquarespuzzle", "ninesquares", "leverpuzzle"},
    }

    local function shortValue(instance)
        if instance:IsA("StringValue") then return tostring(instance.Value) end
        if instance:IsA("IntValue") or instance:IsA("NumberValue") then return tostring(instance.Value) end
        if instance:IsA("TextLabel") or instance:IsA("TextBox") then return tostring(instance.Text) end
    end

    local function normalizedShortValue(instance)
        local value = shortValue(instance)
        if not value then return nil end
        value = value:gsub("^%s+", ""):gsub("%s+$", "")
        if #value == 0 or #value > 24 then return nil end
        return value
    end

    local function ancestorText(instance, depth)
        local chunks = {}
        local current = instance
        for _ = 1, depth or 5 do
            if not current or current == workspace then break end
            chunks[#chunks + 1] = string.lower(current.Name)
            current = current.Parent
        end
        return table.concat(chunks, " ")
    end

    local function mapAndEvents()
        local map = currentMapModel()
        if not map then return nil, nil end
        local events = map:FindFirstChild("Events") or map:FindFirstChild("events") or map
        return map, events
    end

    local function controlPosition(control)
        if not control or not control.Parent then return nil end
        if control.Parent:IsA("BasePart") then return control.Parent.Position end
        local model = control.Parent:FindFirstAncestorOfClass("Model")
        local part = model and getPart(model)
        return part and part.Position
    end

    local function clickControl(control)
        if not control or not control.Parent then return false end
        if control:IsA("ClickDetector") and fireclickdetector then
            pcall(function()
                control.MaxActivationDistance = math.huge
                fireclickdetector(control)
            end)
            return true
        end
        if control:IsA("ProximityPrompt") and fireproximityprompt then
            pcall(function()
                control.HoldDuration = 0
                fireproximityprompt(control)
            end)
            return true
        end
        return false
    end

    local function controlsUnder(root)
        local result = {}
        local seen = {}
        if not root then return result end
        for _, descendant in ipairs(root:GetDescendants()) do
            if descendant:IsA("ClickDetector") or descendant:IsA("ProximityPrompt") then
                local part = descendant.Parent
                if part and not seen[part] and controlPosition(descendant) then
                    seen[part] = true
                    result[#result + 1] = descendant
                end
            end
        end
        return result
    end

    local function findCanonicalRoot(kind)
        local map = currentMapModel()
        if not map then return nil end
        local names = canonicalRoots[kind]
        if not names then return nil end
        local best
        local bestLength = math.huge
        for _, descendant in ipairs(map:GetDescendants()) do
            if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("BasePart") then
                local name = token(descendant.Name)
                for _, wanted in ipairs(names) do
                    if name == wanted or name:find(wanted, 1, true) then
                        local controls = controlsUnder(descendant)
                        if #controls > 0 and #controls < bestLength then
                            best = descendant
                            bestLength = #controls
                        end
                    end
                end
            end
        end
        return best
    end

    local function uniqueControls(controls)
        local result = {}
        local seen = {}
        for _, control in ipairs(controls) do
            local part = control and control.Parent
            if part and not seen[part] and controlPosition(control) then
                seen[part] = true
                result[#result + 1] = control
            end
        end
        return result
    end

    local function boundsScore(controls)
        if #controls == 0 then return math.huge end
        local minV = Vector3.new(math.huge, math.huge, math.huge)
        local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
        for _, control in ipairs(controls) do
            local p = controlPosition(control)
            if not p then return math.huge end
            minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
            maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
        end
        return (maxV - minV).Magnitude
    end

    local function compactSubset(controls, expected)
        controls = uniqueControls(controls)
        if #controls <= expected then return controls end
        local best
        local bestScore = math.huge
        for _, seed in ipairs(controls) do
            local seedPos = controlPosition(seed)
            local ranked = {}
            for _, control in ipairs(controls) do
                local pos = controlPosition(control)
                if pos then
                    ranked[#ranked + 1] = {Control = control, Distance = (pos - seedPos).Magnitude}
                end
            end
            table.sort(ranked, function(a, b) return a.Distance < b.Distance end)
            local group = {}
            for index = 1, math.min(expected, #ranked) do
                group[index] = ranked[index].Control
            end
            local score = boundsScore(group)
            if #group == expected and score < bestScore then
                best = group
                bestScore = score
            end
        end
        return best or {}
    end

    local function keywordScore(instance, keywords)
        local text = ancestorText(instance, 6)
        local score = 0
        for _, word in ipairs(keywords or {}) do
            if text:find(word, 1, true) then score += 1 end
        end
        return score
    end

    local function groupedControls(expected, keywords, allowDouble)
        local _, events = mapAndEvents()
        if not events then return {}, nil end
        local controls = controlsUnder(events)
        local groups = {}

        for _, control in ipairs(controls) do
            local current = control.Parent
            for _ = 1, 6 do
                if not current or current == events.Parent then break end
                local group = groups[current]
                if not group then
                    group = {}
                    groups[current] = group
                end
                group[#group + 1] = control
                if current == events then break end
                current = current.Parent
            end
        end

        local bestControls
        local bestRoot
        local bestScore = math.huge

        for root, group in pairs(groups) do
            group = uniqueControls(group)
            local count = #group
            local countDelta = math.abs(count - expected)
            if allowDouble then countDelta = math.min(countDelta, math.abs(count - expected * 2)) end
            if count >= expected and count <= expected * 3 then
                local words = keywordScore(root, keywords)
                local score = countDelta * 1000 + boundsScore(group) - words * 250
                if score < bestScore then
                    bestControls = group
                    bestRoot = root
                    bestScore = score
                end
            end
        end

        if bestControls then return bestControls, bestRoot end
        return compactSubset(controls, expected), events
    end

    local function selectPuzzleControls(kind, expected, keywords, allowDouble)
        local root = findCanonicalRoot(kind)
        if root then
            local controls = controlsUnder(root)
            if #controls >= expected then
                return controls, root
            end
        end
        return groupedControls(expected, keywords, allowDouble)
    end

    local function progressFingerprint()
        local map = currentMapModel()
        if not map then return "none" end
        local chunks = {}
        for value in pairs(requirements) do
            if value.Parent then
                chunks[#chunks + 1] = "r:" .. tostring(value.Value) .. ":" .. tostring(value.Parent)
            end
        end
        for _, descendant in ipairs(map:GetDescendants()) do
            if descendant:IsA("BasePart") then
                local text = ancestorText(descendant, 4)
                if text:find("door", 1, true)
                    or text:find("exit", 1, true)
                    or text:find("gate", 1, true)
                    or text:find("barrier", 1, true)
                    or text:find("safe", 1, true) then
                    local p = descendant.Position
                    chunks[#chunks + 1] = table.concat({
                        "p", tostring(descendant),
                        string.format("%.2f", p.X),
                        string.format("%.2f", p.Y),
                        string.format("%.2f", p.Z),
                        tostring(descendant.CanCollide),
                        string.format("%.2f", descendant.Transparency),
                    }, ":")
                end
            elseif descendant:IsA("BoolValue") then
                local n = string.lower(descendant.Name)
                if n:find("open", 1, true)
                    or n:find("unlock", 1, true)
                    or n:find("complete", 1, true)
                    or n:find("solved", 1, true) then
                    chunks[#chunks + 1] = "b:" .. tostring(descendant) .. ":" .. tostring(descendant.Value)
                end
            end
        end
        table.sort(chunks)
        return table.concat(chunks, "|")
    end

    local function localSolved(root)
        if not root or not root.Parent then return true end
        for _, descendant in ipairs(root:GetDescendants()) do
            local value = normalizedShortValue(descendant)
            if value then
                local lower = string.lower(value)
                if lower == "open"
                    or lower == "opened"
                    or lower == "correct"
                    or lower == "complete"
                    or lower == "completed"
                    or lower == "unlocked"
                    or lower == "solved" then
                    return true
                end
            end
            if descendant:IsA("BoolValue") and descendant.Value then
                local n = string.lower(descendant.Name)
                if n:find("open", 1, true)
                    or n:find("unlock", 1, true)
                    or n:find("complete", 1, true)
                    or n:find("solved", 1, true) then
                    return true
                end
            end
        end
        return false
    end

    local function waitForSolved(before, root, timeout)
        local deadline = os.clock() + (timeout or 0.4)
        repeat
            if localSolved(root) then return true end
            if progressFingerprint() ~= before then return true end
            task.wait(0.02)
        until os.clock() >= deadline
        return false
    end

    local function planarCoordinates(positions)
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        for _, p in ipairs(positions) do
            minX, minY, minZ = math.min(minX, p.X), math.min(minY, p.Y), math.min(minZ, p.Z)
            maxX, maxY, maxZ = math.max(maxX, p.X), math.max(maxY, p.Y), math.max(maxZ, p.Z)
        end
        local ranges = {
            {Axis = "X", Range = maxX - minX},
            {Axis = "Y", Range = maxY - minY},
            {Axis = "Z", Range = maxZ - minZ},
        }
        table.sort(ranges, function(a, b) return a.Range > b.Range end)
        local a, b = ranges[1].Axis, ranges[2].Axis
        local function coord(p, axis)
            if axis == "X" then return p.X end
            if axis == "Y" then return p.Y end
            return p.Z
        end
        return function(p) return coord(p, a), coord(p, b) end
    end

    local function linearOrder(objects, positionGetter)
        local positions = {}
        for _, object in ipairs(objects) do
            local p = positionGetter(object)
            if not p then return objects end
            positions[#positions + 1] = p
        end
        local a, b = positions[1], positions[1]
        local maxDistance = -1
        for i = 1, #positions do
            for j = i + 1, #positions do
                local d = (positions[i] - positions[j]).Magnitude
                if d > maxDistance then
                    maxDistance = d
                    a, b = positions[i], positions[j]
                end
            end
        end
        local axis = b - a
        if axis.Magnitude < 0.001 then return objects end
        axis = axis.Unit
        local absX, absY, absZ = math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)
        if (absX >= absY and absX >= absZ and axis.X < 0)
            or (absY >= absX and absY >= absZ and axis.Y < 0)
            or (absZ >= absX and absZ >= absY and axis.Z < 0) then
            axis = -axis
        end
        table.sort(objects, function(left, right)
            return positionGetter(left):Dot(axis) < positionGetter(right):Dot(axis)
        end)
        return objects
    end

    local function circularOrder(controls)
        local entries = {}
        local positions = {}
        local center = Vector3.zero
        for _, control in ipairs(controls) do
            local p = controlPosition(control)
            if p then
                positions[#positions + 1] = p
                center += p
                entries[#entries + 1] = {Control = control, Position = p}
            end
        end
        if #entries == 0 then return entries end
        center /= #entries
        local project = planarCoordinates(positions)
        local cu, cv = project(center)
        table.sort(entries, function(a, b)
            local au, av = project(a.Position)
            local bu, bv = project(b.Position)
            return math.atan2(av - cv, au - cu) < math.atan2(bv - cv, bu - cu)
        end)
        return entries
    end

    local function gridOrder(objects, positionGetter)
        if #objects ~= 9 then return objects end
        local positions = {}
        for _, object in ipairs(objects) do
            local p = positionGetter(object)
            if not p then return objects end
            positions[#positions + 1] = p
        end
        local project = planarCoordinates(positions)
        local entries = {}
        for _, object in ipairs(objects) do
            local u, v = project(positionGetter(object))
            entries[#entries + 1] = {Object = object, U = u, V = v}
        end
        table.sort(entries, function(a, b)
            if math.abs(a.V - b.V) > 0.5 then return a.V > b.V end
            return a.U < b.U
        end)
        local result = {}
        for index, entry in ipairs(entries) do result[index] = entry.Object end
        return result
    end

    local function collapseSlotControls(controls, slots)
        controls = uniqueControls(controls)
        if #controls == slots then
            return linearOrder(controls, controlPosition)
        end
        if #controls >= slots * 2 then
            local unused = {}
            for _, control in ipairs(controls) do unused[control] = true end
            local chosen = {}
            while #chosen < slots and next(unused) do
                local first = next(unused)
                unused[first] = nil
                local firstPos = controlPosition(first)
                local nearest
                local nearestDistance = math.huge
                for candidate in pairs(unused) do
                    local pos = controlPosition(candidate)
                    if pos then
                        local d = (pos - firstPos).Magnitude
                        if d < nearestDistance then
                            nearest = candidate
                            nearestDistance = d
                        end
                    end
                end
                if nearest then unused[nearest] = nil end
                chosen[#chosen + 1] = first
            end
            if #chosen == slots then
                return linearOrder(chosen, controlPosition)
            end
        end
        return compactSubset(controls, slots)
    end

    local function cyclePuzzleControls(controls, states, limit, root)
        controls = collapseSlotControls(controls, #controls >= 3 and 3 or #controls)
        if #controls == 0 then return false end
        local before = progressFingerprint()
        local maxSteps = limit or (states ^ #controls)
        local counters = table.create(#controls, 0)
        for _ = 1, maxSteps do
            local carry = true
            for index = 1, #controls do
                if carry then
                    clickControl(controls[index])
                    counters[index] += 1
                    if counters[index] >= states then
                        counters[index] = 0
                    else
                        carry = false
                    end
                end
            end
            task.wait(0.005)
            if localSolved(root) or progressFingerprint() ~= before then return true end
        end
        return false
    end

    local function cyclePuzzle(keywords, expected, states, limit, kind)
        local controls, root = selectPuzzleControls(kind, expected, keywords, expected == 3)
        controls = collapseSlotControls(controls, expected)
        if #controls ~= expected then return false end
        local before = progressFingerprint()
        local maxSteps = limit or (states ^ expected)
        local counters = table.create(expected, 0)
        for _ = 1, maxSteps do
            local carry = true
            for index = 1, expected do
                if carry then
                    clickControl(controls[index])
                    counters[index] += 1
                    if counters[index] >= states then
                        counters[index] = 0
                    else
                        carry = false
                    end
                end
            end
            task.wait(0.005)
            if localSolved(root) or progressFingerprint() ~= before then return true end
        end
        return false
    end

    local function readPanelCode(host)
        if not host then return nil end
        local found = {}
        for _, descendant in ipairs(host:GetDescendants()) do
            local value = normalizedShortValue(descendant)
            if value then
                local digits = value:gsub("%D", "")
                if #digits >= 2 and #digits <= 8 then
                    found[digits] = true
                end
            end
        end
        local only
        local count = 0
        for digits in pairs(found) do
            only = digits
            count += 1
            if count > 1 then return nil end
        end
        return only
    end

    local function readGlobalMapCode(exclude)
        local map = currentMapModel()
        if not map then return nil end
        local found = {}
        for _, descendant in ipairs(map:GetDescendants()) do
            if not exclude or not descendant:IsDescendantOf(exclude) then
                local value = normalizedShortValue(descendant)
                local name = string.lower(descendant.Name)
                if value and (name:find("code", 1, true)
                    or name:find("password", 1, true)
                    or name:find("pin", 1, true)
                    or name:find("digit", 1, true)
                    or ancestorText(descendant, 3):find("hint", 1, true)) then
                    local digits = value:gsub("%D", "")
                    if #digits >= 2 and #digits <= 8 then found[digits] = true end
                end
            end
        end
        local only
        local count = 0
        for digits in pairs(found) do
            only = digits
            count += 1
            if count > 1 then return nil end
        end
        return only
    end

    local function numericButtons(host)
        local buttons = {}
        for _, control in ipairs(controlsUnder(host)) do
            local source = tostring(control.Parent and control.Parent.Name or "")
            if control:IsA("ProximityPrompt") then
                source = source .. " " .. tostring(control.ObjectText or "") .. " " .. tostring(control.ActionText or "")
            end
            local label = control.Parent and control.Parent:FindFirstChildWhichIsA("TextLabel", true)
            if label then source = source .. " " .. tostring(label.Text) end
            local digit = source:match("(%d)")
            if digit and #digit == 1 and not buttons[digit] then buttons[digit] = control end
        end
        return buttons
    end

    local function solveCodePanel(host)
        if not host then return false end
        local code = readPanelCode(host) or readGlobalMapCode(host)
        if not code then return false end
        local buttons = numericButtons(host)
        for index = 1, #code do
            if not buttons[code:sub(index, index)] then return false end
        end
        local before = progressFingerprint()
        for index = 1, #code do
            clickControl(buttons[code:sub(index, index)])
            task.wait(0.02)
        end
        return waitForSolved(before, host, 0.45)
    end

    local puzzleColors = {
        Red = Color3.fromRGB(255, 0, 0),
        Yellow = Color3.fromRGB(255, 255, 0),
        Blue = Color3.fromRGB(0, 85, 255),
        Green = Color3.fromRGB(0, 255, 0),
    }

    local function nearestPuzzleColor(color)
        local best
        local distance = math.huge
        for name, reference in pairs(puzzleColors) do
            local dr = color.R - reference.R
            local dg = color.G - reference.G
            local db = color.B - reference.B
            local d = dr * dr + dg * dg + db * db
            if d < distance then
                best = name
                distance = d
            end
        end
        return best, distance
    end

    local function coloredPartCandidates(exclude)
        local map = currentMapModel()
        local result = {}
        if not map then return result end
        for _, part in ipairs(map:GetDescendants()) do
            if part:IsA("BasePart") and (not exclude or not part:IsDescendantOf(exclude)) then
                local colorName, distance = nearestPuzzleColor(part.Color)
                local light = part:FindFirstChildWhichIsA("PointLight", true)
                    or part:FindFirstChildWhichIsA("SurfaceLight", true)
                local text = ancestorText(part, 4)
                if distance < 0.36
                    and part.Transparency < 0.9
                    and (part.Material == Enum.Material.Neon
                        or light
                        or text:find("screen", 1, true)
                        or text:find("monitor", 1, true)
                        or text:find("display", 1, true)
                        or text:find("control", 1, true)) then
                    result[#result + 1] = {Part = part, Color = colorName}
                end
            end
        end
        return result
    end

    local function coloredGroupOfFour(exclude)
        local candidates = coloredPartCandidates(exclude)
        local groups = {}
        for _, entry in ipairs(candidates) do
            local current = entry.Part.Parent
            for _ = 1, 5 do
                if not current or current == workspace then break end
                local group = groups[current]
                if not group then group = {}; groups[current] = group end
                group[#group + 1] = entry
                current = current.Parent
            end
        end
        local best
        local bestScore = math.huge
        for root, entries in pairs(groups) do
            local unique = {}
            local seen = {}
            for _, entry in ipairs(entries) do
                if not seen[entry.Part] then
                    seen[entry.Part] = true
                    unique[#unique + 1] = entry
                end
            end
            if #unique >= 4 and #unique <= 8 then
                local parts = {}
                for _, entry in ipairs(unique) do parts[#parts + 1] = entry.Part end
                local score = math.abs(#unique - 4) * 1000 + boundsScore((function()
                    local fake = {}
                    for _, part in ipairs(parts) do
                        local control = part:FindFirstChildWhichIsA("ClickDetector") or part:FindFirstChildWhichIsA("ProximityPrompt")
                        if control then fake[#fake + 1] = control end
                    end
                    return fake
                end)()) - keywordScore(root, {"control", "monitor", "screen", "display"}) * 200
                if score < bestScore then
                    best = unique
                    bestScore = score
                end
            end
        end
        if not best then return nil end
        while #best > 4 do table.remove(best) end
        return best
    end

    local function solveShipColorCode()
        local pad = findCanonicalRoot("ColorCode")
        local padControls = pad and controlsUnder(pad) or selectPuzzleControls("ColorCode", 4, {"color", "code", "button"}, false)
        padControls = uniqueControls(padControls)
        if #padControls < 4 then return false end

        local byColor = {}
        for _, control in ipairs(padControls) do
            local part = control.Parent
            if part and part:IsA("BasePart") then
                local name, distance = nearestPuzzleColor(part.Color)
                if distance < 0.45 and not byColor[name] then byColor[name] = control end
            end
        end
        if not (byColor.Red and byColor.Yellow and byColor.Blue and byColor.Green) then return false end

        local clues = coloredGroupOfFour(pad)
        if not clues or #clues ~= 4 then return false end
        local parts = {}
        local colorByPart = {}
        for _, entry in ipairs(clues) do
            parts[#parts + 1] = entry.Part
            colorByPart[entry.Part] = entry.Color
        end
        linearOrder(parts, function(part) return part.Position end)

        local forward = {}
        for _, part in ipairs(parts) do forward[#forward + 1] = colorByPart[part] end
        local reverse = {}
        for index = #forward, 1, -1 do reverse[#reverse + 1] = forward[index] end

        local before = progressFingerprint()
        for _, sequence in ipairs({forward, reverse}) do
            for _, colorName in ipairs(sequence) do
                clickControl(byColor[colorName])
                task.wait(0.035)
            end
            if waitForSolved(before, pad, 0.55) then return true end
            task.wait(0.15)
        end
        return false
    end

    local function partLit(part)
        if not part or not part:IsA("BasePart") then return false end
        local light = part:FindFirstChildWhichIsA("PointLight", true)
            or part:FindFirstChildWhichIsA("SurfaceLight", true)
        if light and light.Enabled and light.Brightness > 0 then return true end
        if part.Material == Enum.Material.Neon then
            return math.max(part.Color.R, part.Color.G, part.Color.B) > 0.55
        end
        return false
    end

    local function campSolved(root, entries)
        local lit = 0
        for _, entry in ipairs(entries) do
            if partLit(entry.Control.Parent) then lit += 1 end
        end
        if lit == 0 then return true end
        if root then
            for _, part in ipairs(root:GetDescendants()) do
                if part:IsA("BasePart") then
                    local n = string.lower(part.Name)
                    if n:find("center", 1, true) or n:find("middle", 1, true) or n:find("indicator", 1, true) then
                        if part.Color.G > part.Color.R * 1.3 and part.Color.G > part.Color.B * 1.3 then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    local function solveCampLightCircle()
        local controls, root = selectPuzzleControls("LightCircle", 8, {"light", "circle", "roulette", "button"}, false)
        controls = compactSubset(controls, 8)
        if #controls ~= 8 then return false end
        local entries = circularOrder(controls)
        if #entries ~= 8 then return false end

        local startIndex
        local bestBrightness = -1
        for index, entry in ipairs(entries) do
            local part = entry.Control.Parent
            if part and part:IsA("BasePart") then
                local brightness = math.max(part.Color.R, part.Color.G, part.Color.B)
                if partLit(part) and brightness > bestBrightness then
                    startIndex = index
                    bestBrightness = brightness
                end
            end
        end
        if not startIndex then return false end

        local before = progressFingerprint()
        for _, direction in ipairs({1, -1}) do
            local clicked = {}
            for _, offset in ipairs({2, 5, 6}) do
                local index = ((startIndex - 1 + direction * offset) % 8) + 1
                clicked[#clicked + 1] = entries[index].Control
                clickControl(entries[index].Control)
                task.wait(0.03)
            end
            if campSolved(root, entries) or waitForSolved(before, root, 0.3) then return true end
            for _, control in ipairs(clicked) do
                clickControl(control)
                task.wait(0.02)
            end
        end

        local previousGray = 0
        for step = 1, 255 do
            local gray = bit32.bxor(step, bit32.rshift(step, 1))
            local changed = bit32.bxor(gray, previousGray)
            previousGray = gray
            for bit = 0, 7 do
                if bit32.band(changed, bit32.lshift(1, bit)) ~= 0 then
                    clickControl(entries[bit + 1].Control)
                    break
                end
            end
            task.wait(0.006)
            if campSolved(root, entries) or progressFingerprint() ~= before then return true end
        end
        return false
    end

    local function colorIsGreen(part)
        return part
            and part:IsA("BasePart")
            and part.Color.G > 0.45
            and part.Color.G > part.Color.R * 1.25
            and part.Color.G > part.Color.B * 1.15
    end

    local function findLabGrid()
        local root = findCanonicalRoot("ReactorGrid")
        local map = currentMapModel()
        local searchRoot = root or map
        if not searchRoot then return nil, {} end

        local candidates = {}
        for _, part in ipairs(searchRoot:GetDescendants()) do
            if part:IsA("BasePart") then
                local green = colorIsGreen(part)
                local red = part.Color.R > 0.4 and part.Color.R > part.Color.G * 1.2
                if green or red then candidates[#candidates + 1] = part end
            end
        end

        local groups = {}
        for _, part in ipairs(candidates) do
            local current = part.Parent
            for _ = 1, 5 do
                if not current or current == workspace then break end
                local group = groups[current]
                if not group then group = {}; groups[current] = group end
                group[#group + 1] = part
                current = current.Parent
            end
        end

        local bestRoot
        local bestParts
        local bestScore = math.huge
        for groupRoot, parts in pairs(groups) do
            local unique = {}
            local seen = {}
            for _, part in ipairs(parts) do
                if not seen[part] then seen[part] = true; unique[#unique + 1] = part end
            end
            if #unique >= 9 and #unique <= 12 then
                local score = math.abs(#unique - 9) * 1000 - keywordScore(groupRoot, {"square", "grid", "panel", "code"}) * 250
                if score < bestScore then
                    bestRoot = groupRoot
                    bestParts = unique
                    bestScore = score
                end
            end
        end

        if not bestParts then return root, {} end
        while #bestParts > 9 do table.remove(bestParts) end
        return bestRoot or root, gridOrder(bestParts, function(part) return part.Position end)
    end

    local function activateLabPower()
        local _, events = mapAndEvents()
        if not events then return false end
        local candidates = {}
        for _, control in ipairs(controlsUnder(events)) do
            local text = ancestorText(control, 6)
            if text:find("aux", 1, true)
                or text:find("power", 1, true)
                or text:find("reactor", 1, true) then
                candidates[#candidates + 1] = control
            end
        end
        local used = {}
        for _, control in ipairs(candidates) do
            local host = control.Parent
            if host and not used[host] then
                used[host] = true
                clickControl(control)
                task.wait(0.15)
                if table.getn(used) >= 2 then break end
            end
        end
        if next(used) then
            task.wait(4.2)
            return true
        end
        return false
    end

    local function transformGridIndex(index, transform)
        local row = math.floor((index - 1) / 3)
        local col = (index - 1) % 3
        local r, c = row, col
        if transform >= 4 then c = 2 - c end
        local rotations = transform % 4
        for _ = 1, rotations do
            r, c = c, 2 - r
        end
        return r * 3 + c + 1
    end

    local function solveLabLevers()
        local gridRoot, grid = findLabGrid()
        if #grid ~= 9 then
            activateLabPower()
            gridRoot, grid = findLabGrid()
        end
        if #grid ~= 9 then return false end

        local green = {}
        for index, part in ipairs(grid) do
            if colorIsGreen(part) then green[#green + 1] = index end
        end
        if #green ~= 3 then
            activateLabPower()
            gridRoot, grid = findLabGrid()
            green = {}
            for index, part in ipairs(grid) do
                if colorIsGreen(part) then green[#green + 1] = index end
            end
        end
        if #green ~= 3 then return false end

        local controls, leverRoot = selectPuzzleControls(nil, 9, {"lever", "switch"}, false)
        controls = uniqueControls(controls)
        local filtered = {}
        for _, control in ipairs(controls) do
            if not gridRoot or not control:IsDescendantOf(gridRoot) then filtered[#filtered + 1] = control end
        end
        if #filtered < 9 then
            filtered = compactSubset(controls, 9)
        elseif #filtered > 9 then
            filtered = compactSubset(filtered, 9)
        end
        if #filtered ~= 9 then return false end
        local ordered = gridOrder(filtered, controlPosition)
        if #ordered ~= 9 then return false end

        local before = progressFingerprint()
        for transform = 0, 7 do
            local chosen = {}
            for _, index in ipairs(green) do
                chosen[#chosen + 1] = ordered[transformGridIndex(index, transform)]
            end
            for _, control in ipairs(chosen) do
                clickControl(control)
                task.wait(0.04)
            end
            if waitForSolved(before, leverRoot, 0.45) then return true end
            for _, control in ipairs(chosen) do
                clickControl(control)
                task.wait(0.025)
            end
        end
        return false
    end

    local function solveDigitCode()
        local root = findCanonicalRoot("DigitCode")
        if root and solveCodePanel(root) then return true end
        local controls, groupRoot = selectPuzzleControls("DigitCode", 3, {"digit", "number", "code", "keypad"}, true)
        controls = collapseSlotControls(controls, 3)
        if #controls ~= 3 then return false end
        return cyclePuzzle({"digit", "number", "code", "keypad"}, 3, 10, 1000, "DigitCode")
    end

    local function solveRomanCode()
        local controls, root = selectPuzzleControls("RomanCode", 3, {"roman", "numeral", "code"}, true)
        controls = collapseSlotControls(controls, 3)
        if #controls ~= 3 then return false end
        local before = progressFingerprint()
        local counters = {0, 0, 0}
        for _ = 1, 64 do
            local carry = true
            for index = 1, 3 do
                if carry then
                    clickControl(controls[index])
                    counters[index] += 1
                    if counters[index] >= 4 then counters[index] = 0 else carry = false end
                end
            end
            task.wait(0.008)
            if localSolved(root) or progressFingerprint() ~= before then return true end
        end
        return false
    end

    local function solveShapeWheel()
        local controls, root = selectPuzzleControls("ShapeWheel", 3, {"shape", "wheel", "symbol"}, true)
        controls = collapseSlotControls(controls, 3)
        if #controls ~= 3 then return false end
        local before = progressFingerprint()
        local counters = {0, 0, 0}
        for _ = 1, 64 do
            local carry = true
            for index = 1, 3 do
                if carry then
                    clickControl(controls[index])
                    counters[index] += 1
                    if counters[index] >= 4 then counters[index] = 0 else carry = false end
                end
            end
            task.wait(0.008)
            if localSolved(root) or progressFingerprint() ~= before then return true end
        end
        return false
    end

    local function solveSpecialPuzzle()
        local mapName = currentMapName()
        local profile = mapProfiles[mapName]
        local puzzle = profile and profile.Puzzle
        if not puzzle or solvedPuzzles[mapName .. ":" .. puzzle] then return false end
        if puzzleBusy or os.clock() < puzzleRetryAt then return false end

        puzzleBusy = true
        local ok, solved = pcall(function()
            if puzzle == "DigitCode" then return solveDigitCode() end
            if puzzle == "ColorCode" then return solveShipColorCode() end
            if puzzle == "RomanCode" then return solveRomanCode() end
            if puzzle == "ShapeWheel" then return solveShapeWheel() end
            if puzzle == "LightCircle" then return solveCampLightCircle() end
            if puzzle == "ReactorLevers" then return solveLabLevers() end
            return false
        end)
        puzzleBusy = false

        if ok and solved then
            solvedPuzzles[mapName .. ":" .. puzzle] = true
            puzzleRetryAt = os.clock() + 0.2
            return true
        end
        puzzleRetryAt = os.clock() + 0.8
        return false
    end

    return solveCodePanel, solveSpecialPuzzle
end)()
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
        if not part then return false end
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
        local host = interactionHost(best)
        local solved = solveCodePanel(host)
        if not solved then
            if best:IsA("ClickDetector") and fireclickdetector then
                pcall(fireclickdetector, best)
            elseif best:IsA("ProximityPrompt") and fireproximityprompt then
                pcall(fireproximityprompt, best)
            end
        end
        freeInteractionCooldowns[best] = os.clock() + 0.8
        task.wait(0.06)
        endAutomationMove()
        return true
    end

    local function targetFromRequirement(value)
        if value and value.Parent and value.Name == "ToolRequired" then
            local direct = value.Parent
            if direct:IsA("BasePart") or getPart(direct) then
                return direct
            end
        end

        local current = value.Parent
        local fallback
        for _ = 1, 5 do
            if not current or current == workspace then break end
            if items[current] then return nil end
            if current:IsA("Model") or current:IsA("BasePart") then
                local part = getPart(current)
                if part then
                    fallback = fallback or current
                    local mesh = current:FindFirstChildWhichIsA("SpecialMesh", true)
                    local eventMesh = mesh
                        and cleanAssetId(mesh.MeshId) == "524497312"
                        and (mesh.Scale - Vector3.new(0.75, 0.5, 0.75)).Magnitude <= 0.05
                    if eventMesh then return current end

                    local required = current:FindFirstChild("ToolRequired")
                    if required and required:IsA("StringValue") then return current end

                    local lower = string.lower(current.Name)
                    local hasInteraction = current:FindFirstChildWhichIsA("ClickDetector", true)
                        or current:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local isNamed = lower:find("door", 1, true)
                        or lower:find("gate", 1, true)
                        or lower:find("panel", 1, true)
                        or lower:find("lock", 1, true)
                        or lower:find("power", 1, true)
                        or lower:find("safe", 1, true)
                    if hasInteraction or isNamed then return current end
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

    local blockerPriority = {
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

    local function isLockItem(id)
        local value = tostring(id or "")
        return value:find("Key", 1, true) ~= nil
            or value:find("Keycard", 1, true) ~= nil
            or id == "ElevatorKey"
    end

    local function objectiveDistance(a, b)
        if not a or not b or not a.Part or not b.Part then return math.huge end
        return (a.Part.Position - b.Part.Position).Magnitude
    end

    local function blockingObjectiveFor(objective, objectives)
        local profile = mapProfiles[currentMapName()]
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

        if not isLockItem(objective.Id) then return nil end

        local best
        local bestPriority = math.huge
        for _, candidate in ipairs(objectives) do
            if candidate ~= objective then
                local priority = blockerPriority[candidate.Id]
                if priority and objectiveDistance(objective, candidate) <= 18 then
                    if objectiveStillActive == nil or objectiveStillActive(candidate) then
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

    local function profilePriority(id)
        local profile = mapProfiles[currentMapName()]
        local priority = profile and profile.Priority and profile.Priority[id]
        return priority or blockerPriority[id] or 100
    end

    local function chooseObjective(objectives)
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local best
        local bestScore = math.huge
        for _, objective in ipairs(objectives) do
            local blocker = blockingObjectiveFor(objective, objectives)
            local owned = findOwnedById(objective.Id)
            local worldItem, worldDistance = findItemById(objective.Id)
            local score
            if blocker then
                score = 1000000 + profilePriority(blocker.Id)
            elseif owned then
                score = blockerPriority[objective.Id] or 100
            elseif worldItem then
                score = 200 + profilePriority(objective.Id) + (worldDistance or 0) * 0.01
            else
                score = 100000
                if root and objective.Part then
                    score = score + (objective.Part.Position - root.Position).Magnitude
                end
                score = score + profilePriority(objective.Id)
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
        local ok, objectives, objective = pcall(function()
            local found = collectObjectives()
            local selected = chooseObjective(found)
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
        if objectiveCurrentLabel then objectiveCurrentLabel:Set(objectiveText(currentObjective)) end
        if objectiveNeededLabel then objectiveNeededLabel:Set(remainingText(objectives)) end
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
            task.wait(0.04)
            local equipped = character:FindFirstChildWhichIsA("Tool")
            if equipped and (itemId(equipped) == id or aliases[token(equipped.Name)] == id) then
                object = equipped
            end
        end
        return object
    end

    local function objectiveStillActive(objective)
        local requirement = objective and objective.Requirement
        return requirement
            and requirement.Parent
            and idFromText(requirement.Value) == objective.Id
    end

    local function activateObjective(objective)
        if not objective or not objective.Target or not objective.Target.Parent then return false end

        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local tool = findOwnedById(objective.Id)
        if not character or not humanoid or not tool then return false end

        if tool.Parent ~= character then
            humanoid:EquipTool(tool)
            task.wait(0.03)
            tool = findOwnedById(objective.Id) or character:FindFirstChildWhichIsA("Tool")
        end

        local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true))
        local eventPart
        if objective.Requirement and objective.Requirement.Parent and objective.Requirement.Parent:IsA("BasePart") then
            eventPart = objective.Requirement.Parent
        else
            eventPart = getPart(objective.Target)
        end
        if not eventPart then return false end

        local target = eventPart.CFrame + Vector3.new(1, 0, 1)
        beginAutomationMove(target)
        task.wait(0.02)

        local touched = false
        local ok = pcall(function()
            for _ = 1, 8 do
                if not objectiveStillActive(objective) then break end
                automationDeadline = os.clock() + 2
                humanoid.Jump = true

                if handle and firetouchinterest then
                    firetouchinterest(handle, eventPart, 0)
                    task.wait(0.025)
                    firetouchinterest(handle, eventPart, 1)
                    touched = true
                else
                    local root = character:FindFirstChild("HumanoidRootPart")
                    if root and firetouchinterest then
                        firetouchinterest(root, eventPart, 0)
                        task.wait(0.025)
                        firetouchinterest(root, eventPart, 1)
                        touched = true
                    end
                end

                pcall(function() tool:Activate() end)

                local click = eventPart:FindFirstChildWhichIsA("ClickDetector", true)
                local prompt = eventPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                if click and fireclickdetector then pcall(fireclickdetector, click) end
                if prompt and fireproximityprompt then pcall(fireproximityprompt, prompt) end
                task.wait(0.035)
            end
        end)

        humanoid.Jump = false
        task.wait(0.04)
        local completed = not objectiveStillActive(objective)
        endAutomationMove()
        return ok and completed
    end

    local function isEscapeRelatedPart(part)
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

    local function nearEscapeTrigger(distanceLimit)
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

        task.wait(0.2)
        endAutomationMove()
        escapeTouchOverride = false
        return true
    end

    local function autoCompleteStep()
        if autoCompleteBusy then return end
        autoCompleteBusy = true

        local ok, errorMessage = pcall(function()
            local objectives, objective = refreshObjectiveState()

            if #objectives == 0 then
                if solveSpecialPuzzle() then
                    task.wait(0.03)
                    refreshObjectiveState()
                elseif runFreeInteractionStep() then
                    task.wait(0.03)
                    refreshObjectiveState()
                else
                    autoEscapeStep()
                end
                return
            end

            if not objective then return end

            local required = equipRequired(objective.Id)
            if required then
                local completed = activateObjective(objective)
                if objective.Requirement then
                    objectiveCooldowns[objective.Requirement] = os.clock() + (completed and 0.08 or 0.3)
                end
                if not completed then
                    runFreeInteractionStep()
                end
            else
                if not solveSpecialPuzzle() then
                    runFreeInteractionStep()
                end
            end

            refreshObjectiveState()
        end)

        releaseAutomation()

        if not ok then
            lastPickupStatus = "solver recovered: " .. tostring(errorMessage)
            if objectiveStatusLabel then
                objectiveStatusLabel:Set("Status: solver recovered from an error, retrying")
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

        local allowEscapeTouch = escapeTouchOverride or nearEscapeTrigger(12)
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
                if isEscapeRelatedPart(trap) then
                    scope:Restore(trap, "CanTouch")
                elseif value then
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
        refreshObjectiveState()
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
        rage:CreateToggle("Auto Object / Full run", false, function(value)
            autoComplete = value
            releaseAutomation()
            if value then
                autoGrab = false
                autoInteract = false
                scope:StopTask("autoGrab")
                scope:StopTask("autoInteract")
                scope:Loop("autoComplete", 0.05, autoCompleteStep)
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

    scope:Loop("objectiveHelper", 0.1, refreshObjectiveState)
    scope:Loop("itemUiRefresh", 0.1, refreshItemDropdown)

    scope:Loop("playerState", 0.05, function()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if speedEnabled and humanoid then scope:Set(humanoid, "WalkSpeed", speedValue) end
        if jumpEnabled and humanoid then scope:Set(humanoid, "JumpPower", jumpValue) end
        if noclip then applyNoclip() end
        if godMode then applyGodMode() end
    end)

    scope:Loop("rageRefresh", 0.5, function()
        if trapBypass then applyTrapBypass(true) end
        if doorsRemoved then applyDoors(true) end
        if botsFrozen then applyBotFreeze(true) end
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
