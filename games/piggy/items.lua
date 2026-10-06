return function(ctx,core,tab)
    local selected

    local function names()
        core:Scan()
        local out={}
        for id,bucket in pairs(core.Items) do
            if next(bucket) then out[#out+1]=core:Display(id) end
        end
        table.sort(out)
        if #out==0 then out[1]="No items" end
        return out
    end

    local function idFromDisplay(name)
        core:Scan()
        for id in pairs(core.Items) do
            if core:Display(id)==name then return id end
        end
    end

    tab:CreateSection("Items")
    local list=names()
    selected=list[1]
    local dropdown=tab:CreateDropdown("Item",list,selected,function(v) selected=v end)

    tab:CreateButton("Refresh item list",function()
        local nextList=names()
        selected=nextList[1]
        if dropdown.SetValues then dropdown:SetValues(nextList) end
        if dropdown.Set then dropdown:Set(selected) end
    end)

    tab:CreateButton("Grab selected item",function()
        local id=idFromDisplay(selected)
        if id then core:Pickup(id) end
    end)

    tab:CreateButton("Teleport to selected item",function()
        local id=idFromDisplay(selected)
        local item=id and core:FindItem(id)
        local part=item and core:GetPart(item)
        if part then core:MoveTo(part.CFrame+Vector3.new(0,2.5,0),0.3) end
    end)

    tab:CreateButton("Grab nearest item",function()
        core:Scan()
        local root=core.Player.Character and core.Player.Character:FindFirstChild("HumanoidRootPart")
        local bestId,bestDistance
        for id in pairs(core.Items) do
            local item=core:FindItem(id)
            local part=item and core:GetPart(item)
            if part then
                local distance=root and (part.Position-root.Position).Magnitude or 0
                if not bestDistance or distance<bestDistance then bestId,bestDistance=id,distance end
            end
        end
        if bestId then core:Pickup(bestId) end
    end)
end
