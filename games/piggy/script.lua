return function(ctx)
    local Module=assert(ctx.Module,"FastSC module loader is unavailable")
    local Core=Module("games/piggy/core.lua")
    local Solver=Module("games/piggy/solver.lua")

    local core=Core.new(ctx)
    local solver=Solver.new(core)
    local scope=ctx.Scope

    local tab=ctx.Window:CreateTab("Rage")
    local itemsTab=ctx.Window:CreateTab("Items")
    local espTab=ctx.Window:CreateTab("ESP")
    local playerTab=ctx.Window:CreateTab("Player")

    tab:CreateSection("Piggy")
    tab:CreateLabel("Book 1, Book 2 and extra Piggy places")

    local mapLabel=tab:CreateLabel("Map: scanning...")
    local objectiveLabel=tab:CreateLabel("Objective: scanning...")
    local statusLabel=tab:CreateLabel("Status: idle")

    local running=false
    local busy=false

    local function refresh()
        core:Scan()
        local req,list=solver:Select()
        mapLabel:Set("Map: "..tostring(core.MapName).." | active objectives: "..tostring(#(list or {})))
        if req then
            objectiveLabel:Set("Objective: "..core:Display(req.Id))
        elseif core.MapName=="House" and not solver:HouseWhiteKeyExists() then
            if not solver.HouseGears.RedGear then objectiveLabel:Set("Objective: Red Gear -> well")
            elseif not solver.HouseGears.GreenGear then objectiveLabel:Set("Objective: Green Gear -> well")
            else objectiveLabel:Set("Objective: waiting for White Key") end
        else
            objectiveLabel:Set("Objective: none")
        end
        statusLabel:Set("Status: "..tostring(core.LastStatus or "idle"))
    end

    local function step()
        if not running or busy then return end
        busy=true
        local ok,result=pcall(function() return solver:Step() end)
        if ok then
            core.LastStatus=result or core.LastStatus
        else
            core.LastStatus="solver error: "..tostring(result)
        end
        refresh()
        busy=false
    end

    tab:CreateButton("Refresh objectives",refresh)
    tab:CreateButton("Complete one objective pass",step)
    tab:CreateToggle("Auto Object / Full run",false,function(value)
        running=value
        core.Running=value
        if value then
            solver:ResetIfNeeded()
            scope:Loop("piggyFullRun",0.12,step)
        else
            scope:StopTask("piggyFullRun")
            core.Generation+=1
            busy=false
        end
        refresh()
    end)

    itemsTab:CreateSection("Items")
    itemsTab:CreateButton("Refresh item scanner",function()
        core:Scan()
        core.LastStatus="items rescanned"
        refresh()
    end)

    espTab:CreateSection("ESP")
    espTab:CreateLabel("ESP is being moved to the modular Piggy runtime.")

    playerTab:CreateSection("Player")
    playerTab:CreateLabel("Player utilities are being moved to the modular Piggy runtime.")

    scope:Connect(game:GetService("Players").LocalPlayer.CharacterAdded,function()
        task.wait(0.5)
        solver.RoundMap=nil
        solver:ResetIfNeeded()
        refresh()
    end)

    refresh()
end
