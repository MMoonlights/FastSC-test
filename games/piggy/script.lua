return function(ctx)
    local Module=assert(ctx.Module,"FastSC module loader is unavailable")
    local Core=Module("games/piggy/core.lua")
    local Solver=Module("games/piggy/solver.lua")
    local SetupItems=Module("games/piggy/items.lua")
    local SetupESP=Module("games/piggy/esp.lua")
    local SetupPlayer=Module("games/piggy/player.lua")

    local core=Core.new(ctx)
    local solver=Solver.new(core)
    local scope=ctx.Scope
    local running=false
    local busy=false

    local rage=ctx.Window:CreateTab("Rage")
    local itemsTab=ctx.Window:CreateTab("Items")
    local espTab=ctx.Window:CreateTab("ESP")
    local playerTab=ctx.Window:CreateTab("Player")

    rage:CreateSection("Piggy")
    rage:CreateLabel("Book 1, Book 2 and extra Piggy places")
    local mapLabel=rage:CreateLabel("Map: scanning...")
    local objectiveLabel=rage:CreateLabel("Objective: scanning...")
    local statusLabel=rage:CreateLabel("Status: idle")

    local function refresh()
        local ok,err=pcall(function()
            core:Scan()
            local req,list=solver:Select()
            mapLabel:Set("Map: "..tostring(core.MapName).." | active: "..tostring(#(list or {})))
            if req then
                objectiveLabel:Set("Objective: "..core:Display(req.Id))
            elseif core.MapName=="House" and not solver:HouseWhiteKeyExists() then
                if not solver.HouseGears.RedGear and (core:Owned("RedGear") or core:FindItem("RedGear")) then
                    objectiveLabel:Set("Objective: Red Gear -> well")
                elseif not solver.HouseGears.GreenGear and (core:Owned("GreenGear") or core:FindItem("GreenGear")) then
                    objectiveLabel:Set("Objective: Green Gear -> well")
                else
                    objectiveLabel:Set("Objective: waiting for progression")
                end
            else
                objectiveLabel:Set("Objective: none")
            end
            statusLabel:Set("Status: "..tostring(core.LastStatus or "idle"))
        end)
        if not ok then statusLabel:Set("Status: scanner error: "..tostring(err)) end
    end

    local function step()
        if not running or busy then return end
        busy=true
        local ok,result=pcall(function() return solver:Step() end)
        if ok then core.LastStatus=result or core.LastStatus
        else core.LastStatus="solver error: "..tostring(result) end
        busy=false
        refresh()
    end

    rage:CreateButton("Refresh objectives",refresh)
    rage:CreateButton("Complete one objective pass",function()
        if not running then
            running=true
            core.Running=true
            core:SetFlight(true)
            step()
            running=false
            core.Running=false
            core:ResetMotion()
        else
            step()
        end
    end)

    rage:CreateToggle("Auto Object / Full run",false,function(value)
        running=value
        core.Running=value
        busy=false
        if value then
            solver:ResetIfNeeded()
            core:SetFlight(true)
            scope:Loop("piggyFullRun",0.12,step)
        else
            scope:StopTask("piggyFullRun")
            core.Generation+=1
            core:ResetMotion()
        end
        refresh()
    end)

    local function setup(name,fn,...)
        local ok,err=pcall(fn,...)
        if not ok then
            core.LastStatus=name.." module error: "..tostring(err)
            statusLabel:Set("Status: "..core.LastStatus)
        end
    end

    setup("Items",SetupItems,ctx,core,itemsTab)
    setup("ESP",SetupESP,ctx,core,espTab)
    setup("Player",SetupPlayer,ctx,core,playerTab)

    scope:Connect(core.Player.CharacterAdded,function()
        task.wait(0.4)
        solver.RoundMap=nil
        solver:ResetIfNeeded()
        if running then core:SetFlight(true) end
        refresh()
    end)

    scope:AddRestore(function()
        running=false
        busy=false
        core.Running=false
        core:ResetMotion()
    end)

    refresh()
end
