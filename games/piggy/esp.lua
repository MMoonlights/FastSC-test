return function(ctx,core,tab)
    local Players=game:GetService("Players")
    local Lighting=game:GetService("Lighting")
    local scope=ctx.Scope
    local visuals={}
    local itemEsp=false
    local playerEsp=false
    local piggyEsp=false

    local function clear(kind)
        for key,v in pairs(visuals) do
            if not kind or v.Kind==kind then
                if v.Highlight then pcall(function() v.Highlight:Destroy() end) end
                if v.Billboard then pcall(function() v.Billboard:Destroy() end) end
                visuals[key]=nil
            end
        end
    end

    local function add(key,adornee,text,kind)
        if not adornee or visuals[key] then return end
        local h=Instance.new("Highlight")
        h.Name="FastSC_"..kind
        h.Adornee=adornee
        h.FillTransparency=0.75
        h.OutlineTransparency=0
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent=adornee

        local part=core:GetPart(adornee)
        local b
        if part then
            b=Instance.new("BillboardGui")
            b.Name="FastSCLabel"
            b.Adornee=part
            b.Size=UDim2.fromOffset(180,28)
            b.StudsOffset=Vector3.new(0,2.5,0)
            b.AlwaysOnTop=true
            local label=Instance.new("TextLabel")
            label.BackgroundTransparency=1
            label.Size=UDim2.fromScale(1,1)
            label.Text=text
            label.TextScaled=true
            label.TextStrokeTransparency=0
            label.Font=Enum.Font.GothamBold
            label.Parent=b
            b.Parent=part
        end
        visuals[key]={Highlight=h,Billboard=b,Kind=kind}
    end

    local function refresh()
        if itemEsp then
            core:Scan()
            for id,bucket in pairs(core.Items) do
                for item in pairs(bucket) do
                    if item.Parent then add(item,item,core:Display(id),"Item") end
                end
            end
        end
        if playerEsp then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=core.Player and p.Character then add(p,p.Character,p.Name,"Player") end
            end
        end
        if piggyEsp then
            for _,obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj~=core.Player.Character then
                    local n=string.lower(obj.Name)
                    if n:find("piggy",1,true) or n:find("bot",1,true) then
                        add(obj,obj,obj.Name,"Piggy")
                    end
                end
            end
        end
        for key,v in pairs(visuals) do
            local alive=typeof(key)=="Instance" and key.Parent~=nil
            if typeof(key)=="Instance" and key:IsA("Player") then alive=key.Parent~=nil and key.Character~=nil end
            if not alive then
                if v.Highlight then pcall(function() v.Highlight:Destroy() end) end
                if v.Billboard then pcall(function() v.Billboard:Destroy() end) end
                visuals[key]=nil
            end
        end
    end

    tab:CreateSection("ESP")
    tab:CreateToggle("Item ESP",false,function(v) itemEsp=v if not v then clear("Item") else refresh() end end)
    tab:CreateToggle("Piggy / Bot ESP",false,function(v) piggyEsp=v if not v then clear("Piggy") else refresh() end end)
    tab:CreateToggle("Player ESP",false,function(v) playerEsp=v if not v then clear("Player") else refresh() end end)
    tab:CreateToggle("Fullbright",false,function(v)
        if v then
            scope:Set(Lighting,"Brightness",4)
            scope:Set(Lighting,"GlobalShadows",false)
            scope:Set(Lighting,"Ambient",Color3.new(1,1,1))
            scope:Set(Lighting,"OutdoorAmbient",Color3.new(1,1,1))
        else
            scope:Restore(Lighting,"Brightness")
            scope:Restore(Lighting,"GlobalShadows")
            scope:Restore(Lighting,"Ambient")
            scope:Restore(Lighting,"OutdoorAmbient")
        end
    end)

    scope:Loop("piggyEspRefresh",0.35,refresh)
    scope:Add(function() clear() end)
end
