local Core = {}
Core.__index = Core

local Players = game:GetService("Players")

local ALIASES = {
    greenkey="GreenKey", redkey="RedKey", bluekey="BlueKey", yellowkey="YellowKey",
    orangekey="OrangeKey", purplekey="PurpleKey", whitekey="WhiteKey",
    hammer="Hammer", wrench="Wrench", plank="Plank", keycode="KeyCode",
    redgear="RedGear", greengear="GreenGear", whitegear="WhiteGear",
    screwdriver="Screwdriver", scissors="Scissors", shovel="Shovel",
    candle="Candle", tnt="TNT", dynamite="Dynamite", battery="Battery",
    coin="Coin", token="Coin", gas="Gas", gasoline="Gas",
    bluekeycard="BlueKeycard", redkeycard="RedKeycard", greenkeycard="GreenKeycard",
    orangekeycard="OrangeKeycard", fireextinguisher="FireExtinguisher",
    watergun="WaterGun", mallet="Mallet", mop="Mop", mirror="Mirror",
    blowtorch="Blowtorch", ladder="Ladder", rope="Rope", grapplinghook="GrapplingHook",
    remotcontrol="RemoteControl", remotecontrol="RemoteControl",
    redegg="RedEgg", greenegg="GreenEgg", torch="Torch",
    emptyvial="EmptyVial", greenvial="GreenVial", purplevial="PurpleVial",
    tankbullet="TankBullet", tankshell="TankBullet", woodensword="WoodenSword",
    pipe="Pipe", elevatorKey="ElevatorKey",
}

local DISPLAY = {
    GreenKey="Green Key", RedKey="Red Key", BlueKey="Blue Key", YellowKey="Yellow Key",
    OrangeKey="Orange Key", PurpleKey="Purple Key", WhiteKey="White Key",
    RedGear="Red Gear", GreenGear="Green Gear", WhiteGear="White Gear",
    KeyCode="Key Code", BlueKeycard="Blue Keycard", RedKeycard="Red Keycard",
    GreenKeycard="Green Keycard", OrangeKeycard="Orange Keycard",
}

local function token(v)
    return string.lower(tostring(v or "")):gsub("[^%w]", "")
end

function Core.new(ctx)
    return setmetatable({
        Ctx=ctx, Scope=ctx.Scope, Common=ctx.Common,
        Player=Players.LocalPlayer, Items={}, Requirements={},
        Running=false, Busy=false, Finished=false, Map=nil, MapName="Unknown",
        LastStatus="idle", LastTarget=nil, Generation=0,
    }, Core)
end

function Core:ResolveId(v)
    local t=token(v)
    return ALIASES[t] or (t ~= "" and (t:gsub("^%l", string.upper))) or nil
end

function Core:Display(id)
    return DISPLAY[id] or tostring(id or "Unknown")
end

function Core:GetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true) end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

function Core:DetectMap()
    local known={"House","Station","Gallery","Forest","School","Hospital","Metro","Carnival","City","Mall","Outpost","Plant","Alleys","Store","Refinery","The Safe Place","Sewers","Factory","Port","Ship","Docks","Temple","Camp","Lab","Distorted Memory","Winter Holiday","Heist","Distraction","Breakout","Mansion","Distorted Holiday","Holiday Spirit","The Hunt"}
    for _,name in ipairs(known) do
        local obj=workspace:FindFirstChild(name)
        if obj then self.Map,self.MapName=obj,name return obj,name end
    end
    local best,bestScore
    for _,obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local score=0
            if obj:FindFirstChild("Events") then score+=5 end
            if obj:FindFirstChild("ToolRequired",true) then score+=5 end
            if obj:FindFirstChild("ItemPickupScript",true) or obj:FindFirstChild("NewItemPickupScript",true) then score+=4 end
            if not bestScore or score>bestScore then best,bestScore=obj,score end
        end
    end
    if best and bestScore>=5 then self.Map,self.MapName=best,best.Name return best,best.Name end
    self.Map,self.MapName=nil,"Unknown"
end

function Core:IsPickup(obj)
    if not obj then return false end
    return obj:FindFirstChild("ItemPickupScript") or obj:FindFirstChild("NewItemPickupScript")
end

function Core:ItemId(obj)
    if not obj then return nil end
    local id=self:ResolveId(obj.Name)
    if id then return id end
    for _,d in ipairs(obj:GetDescendants()) do
        if d:IsA("StringValue") and (d.Name=="ItemName" or d.Name=="Name") then
            id=self:ResolveId(d.Value)
            if id then return id end
        end
    end
end

function Core:Scan()
    self:DetectMap()
    self.Items={}
    self.Requirements={}
    local map=self.Map
    if not map then return end
    for _,d in ipairs(map:GetDescendants()) do
        if d:IsA("StringValue") and d.Name=="ToolRequired" then
            local id=self:ResolveId(d.Value)
            if id and id~="Ammo" and id~="Gun" and id~="Grass" and id~="Bone" then
                self.Requirements[#self.Requirements+1]={Id=id,Value=d,Host=d.Parent}
            end
        end
        if self:IsPickup(d) then
            local item=d.Parent
            local id=self:ItemId(item)
            if id then
                self.Items[id]=self.Items[id] or {}
                self.Items[id][item]=true
            end
        end
    end
end

function Core:Owned(id)
    local char=self.Player.Character
    local bp=self.Player:FindFirstChild("Backpack")
    for _,container in ipairs({char,bp}) do
        if container then
            for _,obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") and self:ItemId(obj)==id then return obj end
            end
        end
    end
end

function Core:FindItem(id)
    local bucket=self.Items[id]
    if not bucket then return nil end
    local root=self.Player.Character and self.Player.Character:FindFirstChild("HumanoidRootPart")
    local best,dist
    for item in pairs(bucket) do
        local part=item.Parent and self:GetPart(item)
        if part then
            local d=root and (part.Position-root.Position).Magnitude or 0
            if not dist or d<dist then best,dist=item,d end
        end
    end
    return best
end

function Core:MoveTo(cf)
    local char=self.Player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    self.LastTarget=cf
    pcall(function() char:PivotTo(cf) end)
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    return true
end

function Core:Pickup(id)
    if self:Owned(id) then return true end
    local item=self:FindItem(id)
    if not item then self.LastStatus="waiting for "..self:Display(id) return false end
    local part=self:GetPart(item)
    if not part then return false end
    self:MoveTo(part.CFrame+Vector3.new(0,2.5,0))
    task.wait(0.05)
    local click=item:FindFirstChildWhichIsA("ClickDetector",true)
    local prompt=item:FindFirstChildWhichIsA("ProximityPrompt",true)
    if click and fireclickdetector then pcall(fireclickdetector,click) end
    if prompt and fireproximityprompt then pcall(fireproximityprompt,prompt) end
    local untilAt=os.clock()+0.8
    repeat task.wait(0.04) until self:Owned(id) or os.clock()>=untilAt
    return self:Owned(id)~=nil
end

function Core:Equip(id)
    local char=self.Player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local untilAt=os.clock()+0.7
    repeat
        local tool=self:Owned(id)
        if tool and tool.Parent==char then return tool end
        if tool then pcall(function() hum:EquipTool(tool) end) end
        task.wait(0.04)
    until os.clock()>=untilAt
end

function Core:RequirementActive(req)
    return req and req.Value and req.Value.Parent and self:ResolveId(req.Value.Value)==req.Id
end

function Core:Use(req)
    if not self:RequirementActive(req) then return true end
    if not self:Owned(req.Id) and not self:Pickup(req.Id) then return false end
    local tool=self:Equip(req.Id)
    if not tool then self.LastStatus="equip failed: "..self:Display(req.Id) return false end
    local host=req.Host
    local part=self:GetPart(host)
    if not part then return false end
    self:MoveTo(part.CFrame+part.CFrame.LookVector*-1.5+Vector3.new(0,1,0))
    task.wait(0.06)
    tool=self:Equip(req.Id)
    if not tool then return false end
    local handle=tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart",true)
    if handle and firetouchinterest then pcall(function() firetouchinterest(handle,part,0); task.wait(0.02); firetouchinterest(handle,part,1) end) end
    if tool.Parent==self.Player.Character then pcall(function() tool:Activate() end) end
    local click=host:FindFirstChildWhichIsA("ClickDetector",true)
    local prompt=host:FindFirstChildWhichIsA("ProximityPrompt",true)
    if click and fireclickdetector then pcall(fireclickdetector,click) end
    if prompt and fireproximityprompt then pcall(fireproximityprompt,prompt) end
    local untilAt=os.clock()+0.4
    repeat task.wait(0.04) until not self:RequirementActive(req) or os.clock()>=untilAt
    return not self:RequirementActive(req)
end

return Core
