return function(ctx)
    local tab = ctx.Window:CreateTab("Items", "B")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
    local selectedFood = "Apple"
    local selectedCharacter = "Gun"
    local selectedWeapon = "Bat"
    local selectedItem = "Key"

    tab:CreateSection("Character")
    tab:CreateDropdown("Role", {"Gun", "SwatGun"}, selectedCharacter, function(value)
        selectedCharacter = value
    end)
    tab:CreateButton("Select role", function()
        local remote = remotes:FindFirstChild("OutsideRole")
        if remote then remote:FireServer(selectedCharacter, true) end
    end)

    tab:CreateSection("Food")
    tab:CreateDropdown("Food", {"Apple", "BloxyCola", "Chips", "Cookie", "Cure", "Lollipop", "MedKit", "Pizza"}, selectedFood, function(value)
        selectedFood = value
    end)
    tab:CreateButton("Get food", function()
        local remote = remotes:FindFirstChild("GiveTool")
        if remote then remote:FireServer(selectedFood) end
    end)

    tab:CreateSection("Weapons")
    tab:CreateDropdown("Weapon", {"Bat", "Hammer", "LinkedSword", "TeddyBloxpin"}, selectedWeapon, function(value)
        selectedWeapon = value
    end)
    tab:CreateButton("Get weapon", function()
        if selectedWeapon == "Hammer" then
            local remote = remotes:FindFirstChild("BasementWeapon")
            if remote then remote:FireServer(true, "Hammer") end
        else
            local remote = remotes:FindFirstChild("GiveTool")
            if remote then remote:FireServer(selectedWeapon) end
        end
    end)

    tab:CreateSection("Other")
    tab:CreateDropdown("Item", {"Key", "Plank"}, selectedItem, function(value)
        selectedItem = value
    end)
    tab:CreateButton("Get item", function()
        local remote = remotes:FindFirstChild("GiveTool")
        if remote then remote:FireServer(selectedItem) end
    end)
end
