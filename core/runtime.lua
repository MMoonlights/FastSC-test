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

local function cancelThread(thread)
    if thread and task.cancel and coroutine.status(thread) ~= "dead" then
        pcall(task.cancel, thread)
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
        PropertyRestores = setmetatable({}, {__mode = "k"}),
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
    if not instance then return false end
    local properties = self.PropertyRestores[instance]
    if not properties then
        properties = {}
        self.PropertyRestores[instance] = properties
    end
    if properties[property] == nil then
        local ok, old = pcall(function() return instance[property] end)
        if ok then
            properties[property] = {Value = old}
        end
    end
    return pcall(function() instance[property] = value end)
end

function Scope:Restore(instance, property)
    local properties = instance and self.PropertyRestores[instance]
    local saved = properties and properties[property]
    if not saved then return false end
    pcall(function() instance[property] = saved.Value end)
    properties[property] = nil
    if next(properties) == nil then
        self.PropertyRestores[instance] = nil
    end
    return true
end

function Scope:RestoreInstance(instance)
    local properties = instance and self.PropertyRestores[instance]
    if not properties then return end
    for property, saved in pairs(properties) do
        pcall(function() instance[property] = saved.Value end)
        properties[property] = nil
    end
    self.PropertyRestores[instance] = nil
end

function Scope:AddRestore(callback)
    self.Restores[#self.Restores + 1] = callback
    return callback
end

-- Backward-compatible cleanup alias for older cached feature modules.
function Scope:Add(callback)
    return self:AddRestore(callback)
end

function Scope:Spawn(key, callback)
    if not self.Alive then return nil end
    if key then self:StopTask(key) end
    local token = {Alive = true}
    local thread
    thread = task.spawn(function()
        pcall(callback, token)
        if key and self.Tasks[key] == token then
            self.Tasks[key] = nil
        end
    end)
    token.Thread = thread
    if key then self.Tasks[key] = token end
    return token
end

function Scope:Loop(key, interval, callback)
    return self:Spawn(key, function(token)
        while self.Alive and token.Alive do
            pcall(callback, token)
            if not self.Alive or not token.Alive then break end
            task.wait(interval or 0)
        end
    end)
end

function Scope:StopTask(key)
    local token = self.Tasks[key]
    if not token then return end
    token.Alive = false
    self.Tasks[key] = nil
    cancelThread(token.Thread)
end

function Scope:BindRenderStep(name, priority, callback)
    if not self.Alive then return nil end
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

function Scope:HookNamecall(object, callback)
    if not (getrawmetatable and setreadonly and getnamecallmethod and newcclosure) then return nil end
    local meta = getrawmetatable(object)
    local old = meta.__namecall
    local active = true
    local hooked
    local ok = pcall(function()
        hooked = newcclosure(function(target, ...)
            return callback(old, target, getnamecallmethod(), ...)
        end)
        setreadonly(meta, false)
        meta.__namecall = hooked
        setreadonly(meta, true)
    end)
    if not ok then return nil end
    local function restore()
        if not active then return end
        active = false
        pcall(function()
            setreadonly(meta, false)
            if meta.__namecall == hooked then meta.__namecall = old end
            setreadonly(meta, true)
        end)
    end
    self:AddRestore(restore)
    return restore
end

function Scope:Destroy()
    if not self.Alive then return end
    self.Alive = false
    for key, token in pairs(self.Tasks) do
        token.Alive = false
        cancelThread(token.Thread)
        self.Tasks[key] = nil
    end
    for key in pairs(self.RenderSteps) do
        pcall(function() RunService:UnbindFromRenderStep(key) end)
        self.RenderSteps[key] = nil
    end
    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end
    for i = #self.Drawings, 1, -1 do
        local drawing = self.Drawings[i]
        pcall(function()
            if drawing.Remove then drawing:Remove() elseif drawing.Destroy then drawing:Destroy() end
        end)
        self.Drawings[i] = nil
    end
    for instance, properties in pairs(self.PropertyRestores) do
        for property, saved in pairs(properties) do
            pcall(function() instance[property] = saved.Value end)
        end
        self.PropertyRestores[instance] = nil
    end
    for i = #self.Restores, 1, -1 do
        pcall(self.Restores[i])
        self.Restores[i] = nil
    end
    for i = #self.Instances, 1, -1 do
        local instance = self.Instances[i]
        pcall(function() instance:Destroy() end)
        self.Instances[i] = nil
    end
end

return Runtime
