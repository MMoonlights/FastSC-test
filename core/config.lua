local Config = {}

local HttpService = game:GetService("HttpService")
local folder = "FastSC"
local file = folder .. "/config.json"
local data = {}

local function ensureFolder()
    if makefolder and isfolder and not isfolder(folder) then
        pcall(makefolder, folder)
    end
end

function Config.Load()
    ensureFolder()
    if isfile and readfile and isfile(file) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(file))
        end)
        if ok and type(decoded) == "table" then
            data = decoded
        end
    end
    return data
end

function Config.Get(key, default)
    local value = data[key]
    if value == nil then return default end
    return value
end

function Config.Set(key, value)
    data[key] = value
    ensureFolder()
    if writefile then
        pcall(function()
            writefile(file, HttpService:JSONEncode(data))
        end)
    end
    return value
end

function Config.All()
    return data
end

return Config
