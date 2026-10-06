local Solver={}
Solver.__index=Solver

local PRIORITY={
    GreenKey=10,RedKey=20,BlueKey=30,YellowKey=40,OrangeKey=50,PurpleKey=60,
    Plank=70,Hammer=80,Wrench=90,RedGear=100,GreenGear=101,WhiteGear=102,
    Screwdriver=110,Scissors=120,Shovel=130,KeyCode=180,WhiteKey=200,
}

function Solver.new(core)
    return setmetatable({Core=core,HouseGears={RedGear=false,GreenGear=false},RoundMap=nil,Finished=false},Solver)
end

function Solver:ResetIfNeeded()
    local map=self.Core:DetectMap()
    if map~=self.RoundMap then
        self.RoundMap=map
        self.Finished=false
        self.HouseGears={RedGear=false,GreenGear=false}
    end
end

function Solver:HouseWhiteKeyExists()
    self.Core:Scan()
    return self.Core:FindItem("WhiteKey")~=nil or self.Core:Owned("WhiteKey")~=nil
end

function Solver:FindGearTarget(id)
    local map=self.Core.Map
    if not map then return nil end
    local best,score
    for _,obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local part=self.Core:GetPart(obj)
            if part then
                local s=0
                local name=string.lower(obj.Name)
                if name:find("gear",1,true) then s+=10 end
                if name:find("well",1,true) then s+=8 end
                local req=obj:FindFirstChild("ToolRequired",true)
                if req and req:IsA("StringValue") and self.Core:ResolveId(req.Value)==id then s+=30 end
                if s>0 and (not score or s>score) then best,score=obj,s end
            end
        end
    end
    return best
end

function Solver:UseGear(id)
    if self:HouseWhiteKeyExists() then self.HouseGears.RedGear=true self.HouseGears.GreenGear=true return true end
    for _,req in ipairs(self.Core.Requirements) do
        if req.Id==id then
            local ok=self.Core:Use(req)
            if ok then self.HouseGears[id]=true end
            return ok
        end
    end
    if not self.Core:Owned(id) and not self.Core:Pickup(id) then return false end
    local tool=self.Core:Equip(id)
    local target=self:FindGearTarget(id)
    local part=target and self.Core:GetPart(target)
    if not tool or not part then return false end
    self.Core:MoveTo(part.CFrame+Vector3.new(0,1.5,0))
    task.wait(0.06)
    tool=self.Core:Equip(id)
    if not tool then return false end
    local handle=tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart",true)
    if handle and firetouchinterest then pcall(function() firetouchinterest(handle,part,0); task.wait(0.03); firetouchinterest(handle,part,1) end) end
    if tool.Parent==self.Core.Player.Character then pcall(function() tool:Activate() end) end
    task.wait(0.2)
    self.Core:Scan()
    if self:HouseWhiteKeyExists() or not self.Core:Owned(id) then self.HouseGears[id]=true return true end
    return false
end

function Solver:Select()
    self.Core:Scan()
    local list={}
    for _,req in ipairs(self.Core.Requirements) do
        if self.Core:RequirementActive(req) then list[#list+1]=req end
    end
    table.sort(list,function(a,b) return (PRIORITY[a.Id] or 150)<(PRIORITY[b.Id] or 150) end)
    return list[1],list
end

function Solver:Step()
    self:ResetIfNeeded()
    if self.Finished then return "waiting for next round" end
    if not self.Core.Map then return "waiting for map" end

    if self.Core.MapName=="House" and not self:HouseWhiteKeyExists() then
        local redAvailable=self.Core:Owned("RedGear") or self.Core:FindItem("RedGear")
        local greenAvailable=self.Core:Owned("GreenGear") or self.Core:FindItem("GreenGear")

        if not self.HouseGears.RedGear and redAvailable then
            self:UseGear("RedGear")
            return "House: Red Gear"
        end
        if not self.HouseGears.GreenGear and greenAvailable then
            self:UseGear("GreenGear")
            return "House: Green Gear"
        end
    end

    local req,list=self:Select()
    if req then
        local ok=self.Core:Use(req)
        return (ok and "used " or "working on ")..self.Core:Display(req.Id),req,list
    end
    return "objectives clear",nil,list
end

return Solver
