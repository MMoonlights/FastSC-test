local Runtime = {}
local Scope = {}
Scope.__index = Scope

local RunService = game:GetService("RunService")

local function disconnect(value)
    if typeof(value) == "RBXScriptConnection" then
        pcall(function() value:Disconnect() end)
    elseif type(value) == "table" and type(value.Disconnect) == "function" then
        pcall(function() value:Disconnect() end)
    end
end

function Runtime.new(name)
    return setmetatable({
        Name = name or "scope",
        Alive = true,
        Connections = {},
        Instances = {},
        Drawings = {},
        Tasks = {},
        Restores = {},
        RenderSteps = {},
    }, Scope)
end

function Scope:Connect(signal, callback)
    if not self.Alive then return nil end
    local connection = signal:Connect(callback)
    self.Connections[#self.Connections + 1] = connection
    return connection
end

function Scope:TrackConnection(connection)
    if connection then
        self.Connections[#self.Connections + 1] = connection
    end
    return connection
end

function Scope:TrackInstance(instance)
    if instance then
        self.Instances[#self.Instances + 1] = instance
    end
    return instance
end

function Scope:TrackDrawing(drawing)
    if drawing then
        self.Drawings[#self.Drawings + 1] = drawing
    end
    return drawing
end

function Scope:Set(instance, property, value)
    if not instance then return end
    local ok, old = pcall(function() return instance[property] end)
    if ok then
        self.Restores[#self.Restores + 1] = function()
            if instance and instance.Parent then
                pcall(function() instance[property] = old end)
            end
        end
    end
    pcall(function() instance[property] = value end)
end

function Scope:AddRestore(callback)
    self.Restores[#self.Restores + 1] = callback
    return callback
end

function Scope:Spawn(key, callback)
    if not self.Alive then return nil end
    if key then self:StopTask(key) end
    local token = {Alive = true}
    if key then self.Tasks[key] = token end
    task.spawn(function()
        pcall(callback, token)
        if key and self.Tasks[key] == token then
            self.Tasks[key] = nil
        end
    end)
    return token
end

function Scope:Loop(key, interval, callback)
    return self:Spawn(key, function(token)
        while self.Alive and token.Alive do
            local ok = pcall(callback, token)
            if not ok and not self.Alive then break end
            task.wait(interval or 0)
        end
    end)
end

function Scope:StopTask(key)
    local token = self.Tasks[key]
    if token then
        token.Alive = false
        self.Tasks[key] = nil
    end
end

function Scope:BindRenderStep(name, priority, callback)
    if not self.Alive then return end
    local key = "FastSC_" .. self.Name .. "_" .. name
    pcall(function() RunService:UnbindFromRenderStep(key) end)
    RunService:BindToRenderStep(key, priority or Enum.RenderPriority.Character.Value + 1, callback)
    self.RenderSteps[key] = true
    return key
end

function Scope:UnbindRenderStep(name)
    local key = name
    if not self.RenderSteps[key] then
        key = "FastSC_" .. self.Name .. "_" .. name
    end
    pcall(function() RunService:UnbindFromRenderStep(key) end)
    self.RenderSteps[key] = nil
end

function Scope:Destroy()
    if not self.Alive then return end
    self.Alive = false
    for _, token in pairs(self.Tasks) do
        token.Alive = false
    end
    table.clear(self.Tasks)
    for key in pairs(self.RenderSteps) do
        pcall(function() RunService:UnbindFromRenderStep(key) end)
    end
    table.clear(self.RenderSteps)
    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
    end
    table.clear(self.Connections)
    for i = #self.Drawings, 1, -1 do
        local drawing = self.Drawings[i]
        pcall(function()
            if drawing.Remove then drawing:Remove() elseif drawing.Destroy then drawing:Destroy() end
        end)
    end
    table.clear(self.Drawings)
    for i = #self.Instances, 1, -1 do
        local instance = self.Instances[i]
        pcall(function() instance:Destroy() end)
    end
    table.clear(self.Instances)
    for i = #self.Restores, 1, -1 do
        pcall(self.Restores[i])
    end
    table.clear(self.Restores)
end

return Runtime
