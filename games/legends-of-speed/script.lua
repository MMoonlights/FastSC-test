return function(ctx)
    local scope = ctx.Scope
    local tab = ctx.Window:CreateTab("Farm", "L")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local orbEvent = ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("orbEvent")

    tab:CreateSection("Automation")
    tab:CreateToggle("Auto farm", false, function(enabled)
        if enabled then
            scope:Loop("autoFarm", 0.03, function()
                orbEvent:FireServer("collectOrb", "Orange Orb", "City")
                orbEvent:FireServer("collectOrb", "Gem", "City")
                local root = ctx.Common.Root()
                local hoops = Workspace:FindFirstChild("Hoops")
                if hoops then
                    for _, hoop in ipairs(hoops:GetChildren()) do
                        if hoop.Name == "Hoop" and hoop:IsA("BasePart") then
                            hoop.CFrame = root.CFrame
                        end
                    end
                end
            end)
        else
            scope:StopTask("autoFarm")
        end
    end)

    tab:CreateSection("Instant collect")
    local function collect(name, amount)
        task.spawn(function()
            for i = 1, amount do
                orbEvent:FireServer("collectOrb", name, "City")
                if i % 250 == 0 then task.wait() end
            end
        end)
    end
    tab:CreateButton("Collect red orbs", function() collect("Red Orb", 7500) end)
    tab:CreateButton("Collect orange orbs", function() collect("Orange Orb", 7500) end)
    tab:CreateButton("Collect blue orbs", function() collect("Blue Orb", 7500) end)
    tab:CreateButton("Collect gems", function() collect("Gem", 1000) end)
end
